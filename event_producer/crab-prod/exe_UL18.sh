#!/bin/bash -x

## NOTE: difference made w.r.t. common exe script
## 3. seeds have width 100

if [ -d /afs/cern.ch/user/${USER:0:1}/$USER ]; then
  export HOME=/afs/cern.ch/user/${USER:0:1}/$USER # crucial on lxplus condor but cannot set on cmsconnect!
fi
env

JOBNUM=${1##*=}   # hard coded by crab
NEVENT=${2##*=}   # ordered by crab.py script
NTHREAD=${3##*=}  # ordered by crab.py script
PROCNAME=${4##*=} # ordered by crab.py script
BEGINSEED=${5##*=}

WORKDIR=$(pwd)

export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

############ LHEGEN ############
export RELEASE=CMSSW_10_6_28_patch1
if [ -r $RELEASE/src ]; then
  echo release $RELEASE already exists
else
  scram p CMSSW $RELEASE
fi
cd $RELEASE/src
eval $(scram runtime -sh)

# untar CMSSW code
# tar xaf $WORKDIR/inputs/cmssw.tar.gz

# copy the fragment
mkdir -p Configuration/GenProduction/python/
cp $WORKDIR/inputs/${PROCNAME}.py Configuration/GenProduction/python/${PROCNAME}.py
# replace the event number
grep -q "__NEVENT__" Configuration/GenProduction/python/${PROCNAME}.py || exit $?
sed "s/__NEVENT__/$NEVENT/g" -i Configuration/GenProduction/python/${PROCNAME}.py
eval $(scram runtime -sh)
scram b -j $NTHREAD

cd $WORKDIR

# SEED=$(($(date +%s) % 100000 + 1))
# SEED=$((${BEGINSEED} + ${JOBNUM}))
SEED=$(((${BEGINSEED} + ${JOBNUM}) * 100))

# [NOTE] need to specify seeds otherwise gridpacks will be chosen from the same routine!!
# remember to identify process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})"!!
cmsDriver.py Configuration/GenProduction/python/${PROCNAME}.py --python_filename wmLHEGEN_cfg.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:lhegen.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})" --step LHE,GEN --geometry DB:Extended --era Run2_2018 --mc --nThreads $NTHREAD -n $NEVENT || exit $?

############ SIM ############
export RELEASE=CMSSW_10_6_17_patch1
if [ -r $RELEASE/src ]; then
  echo release $RELEASE already exists
else
  scram p CMSSW $RELEASE
fi
cd $RELEASE/src
eval $(scram runtime -sh)
cd $WORKDIR

cmsDriver.py --python_filename SIM_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:sim.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --beamspot Realistic25ns13TeVEarly2018Collision --step SIM --geometry DB:Extended --filein file:lhegen.root --era Run2_2018 --runUnscheduled --mc --nThreads $NTHREAD -n $NEVENT || exit $?

############ DIGIPremix ############
export RELEASE=CMSSW_10_6_17_patch1
if [ -r $RELEASE/src ]; then
  echo release $RELEASE already exists
else
  scram p CMSSW $RELEASE
fi
cd $RELEASE/src
eval $(scram runtime -sh)
cd $WORKDIR

cmsDriver.py --python_filename DIGIPremix_cfg.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-DIGI --fileout file:digi.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --conditions 106X_upgrade2018_realistic_v11_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --geometry DB:Extended --filein file:sim.root --datamix PreMix --era Run2_2018 --runUnscheduled --mc --nThreads $NTHREAD -n $NEVENT >digi.log 2>&1 || exit $? # too many output, log into file

############ HLT ############
export RELEASE=CMSSW_10_2_16_UL
if [ -r $RELEASE/src ]; then
  echo release $RELEASE already exists
else
  scram p CMSSW $RELEASE
fi
cd $RELEASE/src
eval $(scram runtime -sh)
cd $WORKDIR

cmsDriver.py --python_filename HLT_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:hlt.root --conditions 102X_upgrade2018_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2018v32 --geometry DB:Extended --filein file:digi.root --era Run2_2018 --mc --nThreads $NTHREAD -n $NEVENT || exit $?

############ RECO ############
export RELEASE=CMSSW_10_6_17_patch1
if [ -r $RELEASE/src ]; then
  echo release $RELEASE already exists
else
  scram p CMSSW $RELEASE
fi
cd $RELEASE/src
eval $(scram runtime -sh)
cd $WORKDIR

cmsDriver.py --python_filename RECO_cfg.py --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:reco.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --geometry DB:Extended --filein file:hlt.root --era Run2_2018 --runUnscheduled --mc --nThreads $NTHREAD -n $NEVENT || exit $?

############ MiniAODv2 ############
export RELEASE=CMSSW_10_6_20
if [ -r $RELEASE/src ]; then
  echo release $RELEASE already exists
else
  scram p CMSSW $RELEASE
fi
cd $RELEASE/src
eval $(scram runtime -sh)
cd $WORKDIR

## for the last step, needs to run with -j FrameworkJobReport.xml
cmsDriver.py --python_filename MiniAODv2_cfg.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:mini.root --conditions 106X_upgrade2018_realistic_v16_L1v1 --step PAT --procModifiers run2_miniAOD_UL --geometry DB:Extended --filein file:reco.root --era Run2_2018 --runUnscheduled --no_exec --mc --nThreads $NTHREAD -n $NEVENT || exit $?
cmsRun -j FrameworkJobReport.xml MiniAODv2_cfg.py
