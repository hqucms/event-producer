## HWW training sample producer with `crab`

1. Setup the CMSSW env:

```bash
cmsrel CMSSW_10_6_30
cd CMSSW_10_6_30/src
cmsenv
```

2. Clone the repo:

```bash
git clone git@github.com:hqucms/event-producer.git -b Run2UL
cd event-producer/event_producer/crab-prod
```

4. Setup crab env and proxy:

```bash
source /cvmfs/cms.cern.ch/common/crab-setup.sh
voms-proxy-init -rfc -voms cms -valid 192:00
```

Auto-producing CRAB config and submitting (resubmitting) jobs using a script.

```shell
./crab.py --private-mc -p FAKEMiniAODv2_cfg.py --site T2_CH_CERN -o /store/group/cmst3/group/some/path/to/final/dist/2017/mc -t RunIISummer20UL17MiniAODv2 -i samples/mc_2017.conf -e exe.sh --script-args beginseed=0 -s EventBased -n 1000 --max-units 1000000 --input-files inputs --max-memory 10000 --num-cores 4 --work-area crab_projects_2017_mc_run1 --dryrun
```

Note:

The script is borrowed and modified from https://github.com/hqucms/DNNTuples/blob/94X/Ntupler/run/crab.py.

Important/additional custom arguments include:

- `-i`: sample configuration
- `-e`: execute a custom script (we merge all steps into a single script)
- `--script-args`: arguments sent to the script which should correspond to those booked in the script (the variables JOBNUM, NEVENT, NTHREAD, PROCNAME are hard coded by the script and should be omitted in the command)
- `--input-files`: always send `inputs` that contain the fragment with proper names corresponding to the configuration file
- `--output-files`: specify more files here if additional files besides the output file booked in the PSet.py (in our case is `miniv2.root`, if reading the file `FAKEMiniAODv2_cfg.py`) need to be transferred back

Remember to change the `beginseed` in our script arguments when generating a second routine.
