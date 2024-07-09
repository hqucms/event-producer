import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer(
    "ExternalLHEProducer", args=cms.vstring(
        '__GRIDPACKDIR__/ttH_slc7_amd64_gcc700_CMSSW_10_6_30_patch1_my_ttH_ttTo2L2Nu_hdamp_NNPDF31_13TeV_M120.tgz'),
    nEvents=cms.untracked.uint32(5000),
    generateConcurrently=cms.untracked.bool(True),
    numberOfParameters=cms.uint32(1),
    outputFile=cms.string('cmsgrid_final.lhe'),
    scriptName=cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh'))

# Link to datacards:
# https://github.com/cms-sw/genproductions/blob/master/bin/Powheg/production/2017/13TeV/Higgs/ttH_ttTo2L2Nu_hdamp_NNPDF31_13TeV_M125/ttH_ttTo2L2Nu_hdamp_NNPDF31_13TeV_M125.input

from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *
from Configuration.Generator.Pythia8PowhegEmissionVetoSettings_cfi import *
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
                             pythia8PowhegEmissionVetoSettingsBlock,
                             pythia8PSweightsSettingsBlock,
                             processParameters=cms.vstring(
                                 'POWHEG:nFinal = 3',  # Number of final state particles
                                 # (BEFORE THE DECAYS) in the LHE
                                 # other than emitted extra parton
                                 '23:mMin = 0.05',
                                 '24:mMin = 0.05',
                                 '25:m0 = 120.0',
                                 # H->bb or H->cc decays
                                 '25:onMode = off',
                                 '25:oneChannel = 1 0.5 100 5 -5',
                                 '25:addChannel = 1 0.5 100 4 -4',
                                 'ResonanceDecayFilter:filter = on'
                             ),
                             parameterSets=cms.vstring('pythia8CommonSettings',
                                                       'pythia8CP5Settings',
                                                       'pythia8PSweightsSettings',
                                                       'pythia8PowhegEmissionVetoSettings',
                                                       'processParameters'
                                                       )
                         )
                         )

ProductionFilterSequence = cms.Sequence(generator)
