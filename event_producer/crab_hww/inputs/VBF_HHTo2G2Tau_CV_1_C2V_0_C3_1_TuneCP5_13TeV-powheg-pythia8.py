import FWCore.ParameterSet.Config as cms

# adapted from https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/HIG-RunIISummer20UL18wmLHEGEN-03452

externalLHEProducer = cms.EDProducer(
    "ExternalLHEProducer", args=cms.vstring(
        '/cvmfs/cms.cern.ch/phys_generator/gridpacks/2017/13TeV/madgraph/V5_2.6.5/VBFHH/VBF_HH_CV_1_C2V_0_C3_1_13TeV-madgraph_slc7_amd64_gcc700_CMSSW_10_6_19_tarball.tar.xz'),
    nEvents=cms.untracked.uint32(__NEVENT__),
    generateConcurrently=cms.untracked.bool(True),
    numberOfParameters=cms.uint32(1),
    outputFile=cms.string('cmsgrid_final.lhe'),
    scriptName=cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh'))

# Link to datacards:
# https://github.com/cms-sw/genproductions/tree/d8108bb9d9db0b61a755c3625e73ee53c7d900dc/bin/Powheg/production/2017/13TeV/ggHH_EWChL

import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *

generator = cms.EDFilter("Pythia8ConcurrentHadronizerFilter",
                         maxEventsToPrint=cms.untracked.int32(1),
                         pythiaPylistVerbosity=cms.untracked.int32(1),
                         filterEfficiency=cms.untracked.double(1.0),
                         pythiaHepMCVerbosity=cms.untracked.bool(False),
                         comEnergy=cms.double(13000.),
                         PythiaParameters=cms.PSet(
                             pythia8CommonSettingsBlock,
                             pythia8CP5SettingsBlock,
                             pythia8PSweightsSettingsBlock,
                             processParameters=cms.vstring(
                                 '25:m0 = 125.0',
                                 '25:onMode = off',
                                 '25:onIfMatch = 5 -5',
                                 '25:onIfMatch = 15 -15',
                                 'ResonanceDecayFilter:filter = on',
                                 # off: require at least the specified number of daughters, on: require exactly the specified number of daughters
                                 'ResonanceDecayFilter:exclusive = on',
                                 # list of mothers not specified -> count all particles in hard process+resonance decays (better to avoid specifying mothers when including leptons from the lhe in counting, since intermediate resonances are not gauranteed to appear in general
                                 'ResonanceDecayFilter:mothers = 25',
                                 'ResonanceDecayFilter:daughters = 5,5,15,15',
                             ),
                             parameterSets=cms.vstring('pythia8CommonSettings',
                                                       'pythia8CP5Settings',
                                                       'pythia8PSweightsSettings',
                                                       'processParameters'
                                                       )
                         )
                         )

ProductionFilterSequence = cms.Sequence(generator)
