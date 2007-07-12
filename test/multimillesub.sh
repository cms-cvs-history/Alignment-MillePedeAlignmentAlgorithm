#!/bin/zsh 
# $Revision: 1.6.2.5 $ from $Date: 2007/06/21 12:57:13 $ by $Author: flucke $
if  [ $# -lt 3 -o $# -gt 4 ]; then     
    echo
    echo "Wrong number of arguments!"
    echo "syntax:"
    echo "       $0 JobName evts/files_per_job max_evts/files [first_evt/files]" 
    echo "Before using this script properly:"
    echo "  Edit it and set a couple of variables in the general settings!"
    echo
    exit 1
fi

JOB_NAME=$1
integer EVTS_PER_JOB=$2
integer ALL_EVTS=$3
integer FIRST_EVT=0
if [ $# = 4 ]; then
    FIRST_EVT=$4
fi

############################################################
###
### General settings.
###
############################################################

DO_SUBMIT=1 # if 0, do all but commit jobs
#FILES_FILE=RERECO_131_mutracks_1_202.txt # file where to find file names to run on. 
FILES_FILE=RERECO_131_mutracks_1_202_merged.txt # file where to find file names to run on. 
            # if empty: assume files in cfg and select via events
if [ $#FILES_FILE != 0 ]; then
    integer FILES_PER_JOB=$EVTS_PER_JOB
    EVTS_PER_JOB=-1
#    integer ALL_FILES=$ALL_EVTS
    integer FIRST_FILE=$FIRST_EVT
    FIRST_EVT=0
    ALL_FILES_ARRAY=(`cat $FILES_FILE | grep -v "^\#"`) # exclude only lines starting with '#'
    echo Split jobs on file level!
else
    echo Split jobs on event level!
fi 

# FIXME: 
# These switches between normal and dedicated queue don't work fully automatically, cf. below!
QUEUE=dedicated
BSUB_OPT_R=cmsalca #"\"type==SLC3&&swp>500&&pool>1000\""
#QUEUE=1nh
#BSUB_OPT_R="type==SLC3&&swp>450&&pool>750"

CMSSW_VERS=CMSSW_1_3_3
BASE_DIR=${HOME}/scratch0/${CMSSW_VERS}

OUT_DIR=$JOB_NAME # directory 
RESULTHOST=pccmsuhh04
RESULTDIR=$RESULTHOST:/scratch/flucke/lxbatch/$OUT_DIR
CP_RESULT=scp
CP_RESULT_OPT="-r"

# Must be cd-able (scripts are copied here and executed):
SUBMIT_DIR=${HOME}/scratch0/submit/${OUT_DIR}

INPUTTAG=ctfWithMaterialTracks #AlCaRecoCSA06ZMuMu

ALIGN_SEL="\"PixelHalfBarrelLayers,fff00f\""  # fix pixel
ALIGN_SEL=${ALIGN_SEL}", \"TIBRodsDS,111001,geomSel\"" # 4 params for double sided barrel
ALIGN_SEL=${ALIGN_SEL}", \"TIBRodsSS,1f1001,geomSel\""   # fix global z/local y for...
ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsLayers11,111001,geomSel\"" # 4 params for double sided barrel
ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers22,111001,geomSel\"" # 4 params for double sided barrel
ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers15,1f1001,geomSel\"" #  ...single sided TIB and TOB
ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers66,cfc00c,geomSel\"" # (except of fixed last layer)

## CSA06
#ALIGN_SEL="\"TOBDSRods,111111\",\"TOBSSRodsLayers15,1ff111\""
#ALIGN_SEL=${ALIGN_SEL}", \"TIBDSDets,111111\", \"TIBSSDets,1ff111\""
#ALIGN_SEL=${ALIGN_SEL}", \"TOBSSRodsLayers66,ffffff\""
#ALIGN_SEL=${ALIGN_SEL}", \"PixelHalfBarrelLayers,ffffff\""

## NOTE 2006/11 A with hierarchy
#ALIGN_SEL="\"PixelHalfBarrels,rrrrrr\""
##ALIGN_SEL=${ALIGN_SEL}", \"PixelHalfBarrelLayers,111001\""
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelRodsLayers12,111001\"" # 4 params for double sided barrel
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelRodsLayers35,101001\"" # 3 params for single sided barrel
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers66,c0c00c\"" # (except of fixed last layer)
##ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers66,C0C00C\"" # (except of fixed last layer, not in hierar.)
##ALIGN_SEL=${ALIGN_SEL}", \"TIBHalfBarrels,111001\""
##ALIGN_SEL=${ALIGN_SEL}", \"TOBHalfBarrels,111001\""

## NOTE 2006/11 A
#ALIGN_SEL="\"PixelHalfBarrelLadders,fff00f\""  # fix pixel
#ALIGN_SEL="\"PixelHalfBarrelLayers,fff00f\""  # fix pixel
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelRodsDS,111001,geomSel\"" # 4 params for double sided barrel
#ALIGN_SEL=${ALIGN_SEL}", \"TIBRodsSS,1f1001,geomSel\""   # fix global z/local y for...
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers15,1f1001,geomSel\"" #  ...single sided TIB and TOB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers66,cfc00c,geomSel\"" # (except of fixed last layer)

#ALIGN_SEL="\"PixelHalfBarrelLadders,fff00f\""
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelLayersSS,110000\""
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelLayersDS,111000\""
#ALIGN_SEL=${ALIGN_SEL}", \"TOBHalfBarrels,111000\""
#ALIGN_SEL=${ALIGN_SEL}", \"TIBHalfBarrels,111000\""

#ALIGN_SEL=${ALIGN_SEL}", \"TIBDetsLayers11,111001\""
#ALIGN_SEL=${ALIGN_SEL}", \"TIBRodsSS,101001\""
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsDS,111001\""
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers35,101001\""
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers66,c0c00c\""

## private mix Rod
#ALIGN_SEL="\"PixelHalfBarrelLadders,111001\""  # fix pixel
#ALIGN_SEL=${ALIGN_SEL}", \"TIBRods,fff00f,geomSel\""   # fix global z/local y for...
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers12,111001,geomSel\"" #  ...single sided TIB and TOB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers35,1f1001,geomSel\"" #  ...single sided TIB and TOB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsLayers66,cfc00c,geomSel\"" # (except of fixed last layer)

# NOTE 2006/11 B(?)
#ALIGN_SEL="\"PixelHalfBarrelLayers,ccc00c\""  # fix pixel
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelDetsDS,111001,geomSel2\"" # 4 params for double sided barrel
#ALIGN_SEL=${ALIGN_SEL}", \"TIBDetsSS,1f1001,geomSel2\""   # fix global z/local y for...
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsSSLayers15,1f1001,geomSel2\"" #  ...single sided TIB and TOB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsSSLayers66,cfc00c,geomSel2\"" # (except of fixed last layer)
## ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers66,fff001,geomSel\"" # (except of fixed last layer)

# TOB dets, TIB fixed
#ALIGN_SEL="\"PixelHalfBarrelLayers,fff00f\"" # no geomsel
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsDS,111001,geomSel\"" 
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsSS,1f1001,geomSel\""
#ALIGN_SEL=${ALIGN_SEL}", \"TIBRods,fff00f,geomSel\""

#ALIGN_SEL="\"PixelHalfBarrelLayers,fff000\""  # fix pixel
#ALIGN_SEL=${ALIGN_SEL}", \"BarrelRodsDS,111000,geomSel\"" # 4 params for double sided barrel
#ALIGN_SEL=${ALIGN_SEL}", \"TIBRodsSS,1f1000,geomSel\""   # fix global z/local y for...
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers15,1f1000,geomSel\"" #  ...single sided TIB and TOB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBRodsSSLayers66,cfc000,geomSel\"" # (except of fixed last layer)

#ALIGN_SEL="\"PixelHalfBarrelDets,fff00f,geomSel\""  # fix pixel
#ALIGN_SEL=${ALIGN_SEL}", \"TIBDetsDS,111001,geomSel\""
#ALIGN_SEL=${ALIGN_SEL}", \"TIBDetsSS,1f1001,geomSel\""
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDets,fff00f,geomSel\"" # fix TOB

#ALIGN_SEL="\"PixelHalfBarrelDets,fff00f,geomSel\""  # fix pixel
#ALIGN_SEL=${ALIGN_SEL}", \"TIBDets,fff00f,geomSel\"" # and TIB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsDS,111001,geomSel\"" # 4 params for double sided TOB
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsSSLayers15,1f1001,geomSel\"" # single sided TOB free
#ALIGN_SEL=${ALIGN_SEL}", \"TOBDetsSSLayers66,cfc00c,geomSel\"" # (except of fixed last layer)

# the following is put into PSet geomSel...  
ALIGN_ETA_SEL="-0.9, 0.9"
ALIGN_Z_SEL="" # empty array means no restriction: 
ALIGN_R_SEL=""
ALIGN_PHI_SEL= #"1.63, 1.55" 
#... and PSet geomSel2
ALIGN_ETA_SEL2="-999., -0.9, 0.9, 999." 
ALIGN_Z_SEL2="" # empty array means no restriction: 
ALIGN_R_SEL2=""
ALIGN_PHI_SEL2= #"1.55, 1.63"

DO_MISALIGN=true # false echo NO misalignment!

############################################################
###
### End of general settings.
###
############################################################

##############################################################
###
### General actions: Tar/copy libs/configs to store with output,
###                  cd to special dir where jobs are started.
###
##############################################################

# THE_TAR=all.tar
THE_TAR=all.tgz

mkdir $SUBMIT_DIR # Do not use -p option: Next check does not work then!
if [ $? -ne 0 ] ; then 
    echo Exit due to re-use of $SUBMIT_DIR !
    exit
fi
ssh $RESULTHOST mkdir -p /scratch/flucke/lxbatch/$OUT_DIR
if [ $? -ne 0 ] ; then 
    echo Problems creating /scratch/flucke/lxbatch/$OUT_DIR on $RESULTHOST !
    exit
fi
cp $0 $SUBMIT_DIR
cd $BASE_DIR
#tar rf $THE_TAR src/*/*/*/*.cf? lib/* module/*
#gzip $THE_TAR
#$CP_RESULT $CP_RESULT_OPT $THE_TAR.gz $RESULTDIR #> /dev/null
tar czf $THE_TAR src/*/*/*/*.cf? lib/* module/*
$CP_RESULT $CP_RESULT_OPT $THE_TAR $RESULTDIR #> /dev/null
#rm $THE_TAR.gz
cd $SUBMIT_DIR

echo

CONFIG_TEMPLATE=alignment_template.cfg
############################################################
###
### Start writing config template.
###
############################################################
cat >! $CONFIG_TEMPLATE <<EOF
process Alignment = {
    # include "FWCore/MessageLogger/data/MessageLogger.cfi"
    service = MessageLogger { 
        untracked vstring destinations = { "LOGFILE"}
	untracked vstring statistics = { "LOGFILE"}
	untracked vstring categories = { "Alignment"}
	untracked PSet LOGFILE  = { 
	    untracked string threshold = "DEBUG" 
	    untracked PSet INFO = { untracked int32 limit = 10 }
	    untracked PSet WARNING = { untracked int32 limit = 10 }
	    untracked PSet ERROR = { untracked int32 limit = -1 }
	    untracked PSet DEBUG = { untracked int32 limit = 10 }
	    untracked PSet Alignment = { untracked int32 limit = -1}
	    # untracked bool noLineBreaks = true 
	}
    }
    # initialize magnetic field
    include "MagneticField/Engine/data/volumeBasedMagneticField.cfi"
    # ideal geometry and interface
    include "Geometry/CMSCommonData/data/cmsIdealGeometryXML.cfi"
    include "Geometry/TrackerNumberingBuilder/data/trackerNumberingGeometry.cfi"
    # track selection for alignment
    module AlignmentTracks = AlignmentTrackSelectorModule {
        InputTag src = $INPUTTAG # FIXME: templetise?
        bool filter = false
        bool applyBasicCuts = true
        double ptMin   = 10. #5. 
        double ptMax   = 999.
        double etaMin  = -2.4
        double etaMax  =  2.4
        double phiMin  = -3.1416
        double phiMax  =  3.1416
        double nHitMin = 10
        double nHitMax = 99
        double chi2nMax= 999. #999999.
        bool applyNHighestPt = false
        int32 nHighestPt = 2
        bool applyMultiplicityFilter = true
        int32 minMultiplicity = 1
    }
    
    # Alignment producer
    include "Alignment/TrackerAlignment/data/Scenarios.cff"
    include "Alignment/CommonAlignmentProducer/data/AlignmentProducer.cff"
    replace AlignmentProducer.ParameterBuilder.Selector = {
        vstring alignParams = {
            $ALIGN_SEL
        }
        PSet geomSel = {
            vdouble etaRanges = {$ALIGN_ETA_SEL}  vdouble phiRanges = {$ALIGN_PHI_SEL}
            vdouble zRanges   = {$ALIGN_Z_SEL}    vdouble rRanges   = {$ALIGN_R_SEL}
	    vdouble xRanges = {}  vdouble yRanges = {}
        }
        PSet geomSel2 = {
            vdouble etaRanges = {$ALIGN_ETA_SEL2}  vdouble phiRanges = {$ALIGN_PHI_SEL2}
            vdouble zRanges   = {$ALIGN_Z_SEL2}    vdouble rRanges   = {$ALIGN_R_SEL2}
	    vdouble xRanges = {}  vdouble yRanges = {}
        }
    }

    replace AlignmentProducer.doMisalignmentScenario = $DO_MISALIGN
    replace MisalignmentScenarioSettings.setError = false #replace in block defined Scenarios.cff
    replace AlignmentProducer.MisalignmentScenario.TPBs.scale = 0.
#    replace AlignmentProducer.MisalignmentScenario.TPBs = {
#	string distribution = "flat"
#        double dXlocal = 0.03 double dYlocal = 0.03 double dZlocal = 0.05 
#	double phiXlocal = 0.0002 double phiYlocal = 0.0002 double phiZlocal = 0.0008
##	PSet PixelHalfBarrelLayers = {
##	    double dXlocal = 0.03 double dYlocal = 0.05 double dZlocal = 0.1 
##	    double phiXlocal = 0.0001 double phiYlocal = 0.00004 double phiZlocal = 0.00008
##	    }
#    }
#    replace AlignmentProducer.MisalignmentScenario.TPBs.Dets = { double scale = 0.}
    replace AlignmentProducer.MisalignmentScenario.TPEs.scale = 0.
    replace AlignmentProducer.MisalignmentScenario.TECs.scale = 0.
    replace AlignmentProducer.MisalignmentScenario.TIDs.scale = 0.
    replace AlignmentProducer.MisalignmentScenario.TIBs.Dets = { double scale = 0.}
##    replace AlignmentProducer.MisalignmentScenario.TIBs.scale = 0.
##    replace AlignmentProducer.MisalignmentScenario.TIBs.phiZ = 0.
#    replace AlignmentProducer.MisalignmentScenario.TIBs.scale = 0.
    replace AlignmentProducer.MisalignmentScenario.TOBs.Dets = { double scale = 0.}
##    replace AlignmentProducer.MisalignmentScenario.TOBs.phiZ = 0.
##    replace AlignmentProducer.MisalignmentScenario.TOBs.scale = 0.
#   replaces AlignmentProducer.MisalignmentScenario:
#    include "Alignment/MillePedeAlignmentAlgorithm/test/myMisalignmentScenario.cff"
#    include "Alignment/MillePedeAlignmentAlgorithm/test/MisalignBarrelLayer.cff" 
#    replace AlignmentProducer.MisalignmentScenario = {
#	using MisalignBarrelLayer # setError already false!
#    }
    replace AlignmentProducer.algoConfig = {
	using MillePedeAlignmentAlgorithm
    }
    replace MillePedeAlignmentAlgorithm.mode = "MODE"
    replace MillePedeAlignmentAlgorithm.fileDir = "OUT_DIR"
    replace MillePedeAlignmentAlgorithm.binaryFile = "ONE_BINARY_FILE"
    replace MillePedeAlignmentAlgorithm.mergeBinaryFiles = {MERGE_BINARY_FILES}
    replace MillePedeAlignmentAlgorithm.treeFile = "ONE_TREE_FILE"
    replace MillePedeAlignmentAlgorithm.mergeTreeFiles = {MERGE_TREE_FILES}
    replace MillePedeAlignmentAlgorithm.monitorFile = "millePedeMonitorSUFFIX.root"

    replace MillePedeAlignmentAlgorithm.pedeSteerer.steerFile = "pedeSteerSUFFIX"
    replace MillePedeAlignmentAlgorithm.pedeSteerer.pedeDump = "pedeSUFFIX.dump"
    replace MillePedeAlignmentAlgorithm.pedeSteerer.method = "inversion  9  0.8"
    replace MillePedeAlignmentAlgorithm.pedeSteerer.options = {
	 "chisqcut  20.0  4.5" }  #{ "outlierdownweighting 3", "dwfractioncut 0.1" }
#    include "Alignment/MillePedeAlignmentAlgorithm/data/PresigmaScenarios.cff"
#    replace MillePedeAlignmentAlgorithm.pedeSteerer.Presigmas += TrackerShortTermPresigmas.Presigmas

# refitting for normal tracks...
    include "RecoTracker/TrackProducer/data/RefitterWithMaterial.cff"
    include "RecoTracker/TransientTrackingRecHit/data/TransientTrackingRecHitBuilderWithoutRefit.cfi"
    replace TrackRefitter.src = "AlignmentTracks"
    replace TrackRefitter.TrajectoryInEvent = true
    replace TrackRefitter.TTRHBuilder = "WithoutRefit"# TransientTrackingRecHitBuilder: no refit of hits...
    replace ttrhbwor.Matcher = "StandardMatcher" # ... but with matching for strip stereo!
    
    # input file
    # source = EmptySource {untracked int32 maxEvents = EVTS_PER_JOB}
    source = PoolSource { 
	untracked vstring fileNames = { 
	    "rfio:/castor/cern.ch/user/r/rwolf/mc-physval-120-ZToMuMu-NoPU/RERECO_131_mutracks_151_202.root"
        }
 	untracked int32 maxEvents   = EVTS_PER_JOB
	untracked uint32 skipEvents = SKIP_EVTS
    }
    FILE_REPLACE
#    SOURCE_REPLACE

    path p = { AlignmentTracks, TrackRefitter }

}
EOF

$CP_RESULT $CP_RESULT_OPT $CONFIG_TEMPLATE $RESULTDIR #> /dev/null

##############################################################
###
### Start loop producing submit files.
###
##############################################################
ALL_BINARY_FILES=() # empty array
ALL_TREE_FILES=()   # empty array
integer ROUND=1
integer LAST_ROUND=$ROUND # just initialise with some number...
if [ $#FILES_FILE != 0 ]; then  
    LAST_ROUND=$[$[$#ALL_FILES_ARRAY-1]/$FILES_PER_JOB]+1
    if [ $LAST_ROUND -gt $[$[$ALL_EVTS-1]/$FILES_PER_JOB]+1 ]; then 
	LAST_ROUND=$[$[$ALL_EVTS-1]/$FILES_PER_JOB]+1
    fi
else
    LAST_ROUND=$ALL_EVTS/$EVTS_PER_JOB
fi
SKIP_EVTS=$FIRST_EVT

#while [ $SKIP_EVTS -lt $ALL_EVTS ]; do
while [ $ROUND -le $LAST_ROUND ]; do
FILE_REPLACE=
if [ $#FILES_FILE != 0 ]; then
    FILE_REPLACE="replace PoolSource.fileNames = {"
    integer COUNTER=$[$[$ROUND-1]*$FILES_PER_JOB]+1
    integer CURRENT_LAST_FILE=$[$[$COUNTER+$FILES_PER_JOB]-1]
    if [ $ALL_EVTS -lt $CURRENT_LAST_FILE ]; then ; CURRENT_LAST_FILE=$ALL_EVTS; fi
    if [ $#ALL_FILES_ARRAY -lt $CURRENT_LAST_FILE ]; then ; CURRENT_LAST_FILE=$#ALL_FILES_ARRAY; fi
    while [ $COUNTER -le $CURRENT_LAST_FILE ]; do
	FILE_REPLACE=${FILE_REPLACE}"\n\\\"$ALL_FILES_ARRAY[$COUNTER]\\\""
	if [ $COUNTER -lt $CURRENT_LAST_FILE ]; then; FILE_REPLACE=${FILE_REPLACE}, ; fi
	COUNTER=$COUNTER+1
    done
    FILE_REPLACE=${FILE_REPLACE}"\n}"
fi

SUFFIX=_${ROUND}
NAME=${OUT_DIR}${SUFFIX}  #mille${SUFFIX}
CONFIG=alignment${SUFFIX}.cfg
LOGFILE=alignment${SUFFIX}.log
MILLE_BINARY=milleBinary${SUFFIX}.dat
ONE_TREE_FILE=treeFile${SUFFIX}.root
ALL_BINARY_FILES[$ROUND]=\"$MILLE_BINARY\",
ALL_TREE_FILES[$ROUND]=\"$ONE_TREE_FILE\",

FULL_SUB_COMMAND="bsub -J $NAME -R $BSUB_OPT_R -q $QUEUE $NAME.sh"  # for cmsalca
#FULL_SUB_COMMAND="bsub -J $NAME -R \"$BSUB_OPT_R\" -q $QUEUE $NAME.sh"  # FIXME does not work...for SLC3&&...


cat >! $NAME.sh <<EOF2
#!/bin/zsh 
## BSUB -J "gfTest" 

date
echo The local directory is \$(pwd)
echo old CMSSW_BASE: \$CMSSW_BASE
############################################################
###
### Setup environment.
###
############################################################

scramv1 project CMSSW ${CMSSW_VERS} > /dev/null
cd ${CMSSW_VERS}
echo CMMSW area created in \$(pwd) .
#echo Copy $RESULTDIR/$THE_TAR.gz...
echo Copy $RESULTDIR/$THE_TAR...
echo ...to \$(pwd) and unpack.
#$CP_RESULT $CP_RESULT_OPT $RESULTDIR/$THE_TAR.gz .
$CP_RESULT $CP_RESULT_OPT $RESULTDIR/$THE_TAR .
#gunzip $THE_TAR.gz
# tar xf $THE_TAR
tar xzf $THE_TAR
rm $THE_TAR
eval \`scramv1 runtime -sh\`
rehash
echo

mkdir -p $OUT_DIR
ls -lha 
echo

############################################################
###
### Get config template and create config file.
###
############################################################

$CP_RESULT $CP_RESULT_OPT $RESULTDIR/$CONFIG_TEMPLATE .
sed -e "s|LOGFILE|$LOGFILE|g"           $CONFIG_TEMPLATE > ${CONFIG}0.tmp
sed -e "s|OUT_DIR|$OUT_DIR|g"           ${CONFIG}0.tmp > ${CONFIG}1.tmp
sed -e "s|ONE_TREE_FILE|$ONE_TREE_FILE|g" ${CONFIG}1.tmp > ${CONFIG}2.tmp
sed -e "s|MERGE_TREE_FILES||g"          ${CONFIG}2.tmp > ${CONFIG}3.tmp
sed -e "s|ONE_BINARY_FILE|$MILLE_BINARY|g" ${CONFIG}3.tmp > ${CONFIG}4.tmp
sed -e "s|MERGE_BINARY_FILES||g"        ${CONFIG}4.tmp > ${CONFIG}5.tmp
sed -e "s|SUFFIX|$SUFFIX|g"             ${CONFIG}5.tmp > ${CONFIG}6.tmp
sed -e "s|EVTS_PER_JOB|$EVTS_PER_JOB|g" ${CONFIG}6.tmp > ${CONFIG}7.tmp
sed -e "s|SKIP_EVTS|$SKIP_EVTS|g"       ${CONFIG}7.tmp > ${CONFIG}8.tmp
sed -e "s|FILE_REPLACE|$FILE_REPLACE|g" ${CONFIG}8.tmp > ${CONFIG}9.tmp
sed -e "s|MODE|mille|g"                 ${CONFIG}9.tmp > ${CONFIG}
rm ${CONFIG}[0-9].tmp

############################################################
###
### End writing config file, start program and copy results.
###
############################################################

cmsRun $CONFIG
CMSRUN_RESULT=\$?
mv $CONFIG $OUT_DIR
mv *.log $OUT_DIR
echo
echo "cmsRun finished with \${CMSRUN_RESULT}, results/cfg/log in ${OUT_DIR}:"
ls -lha ${OUT_DIR}
echo
integer COPY_PROBLEMS=0
echo Now copy results to $RESULTDIR .
for i ( ${OUT_DIR}/* ); do
    integer TRIES=0
    $CP_RESULT $CP_RESULT_OPT \$i $RESULTDIR
    while [ \$? -ne 0 ] ; do 
	if [ \$TRIES -ge 20 ] ; then
	    echo ERROR: Finally give up copying \$i.
	    COPY_PROBLEMS=\${COPY_PROBLEMS}+1
	    break
	fi
	TRIES=\$TRIES+1
	echo WARNING: Problems copying \$i, try again soon.
        sleep \$[\$TRIES*5]
	$CP_RESULT $CP_RESULT_OPT \$i $RESULTDIR
    done
done
echo
date

if [ $DO_SUBMIT -ne 0 ]; then
 exit \${COPY_PROBLEMS}
fi
EOF2

############################################################
###
### End writing single sub file: Finally sumbit job!
###
############################################################

chmod 740 $NAME.sh # make executable
# FIXME: $BSUB_OPT_R replacement does not work properly!
#bsub -J $NAME -R "$BSUB_OPT_R" -q $QUEUE $NAME.sh  # for SLC3&&...
#bsub -J $NAME -R $BSUB_OPT_R -q $QUEUE $NAME.sh    # for cmsalca
if [ $DO_SUBMIT -eq 0 ]; then
    echo not submitted
else
    `echo $FULL_SUB_COMMAND`
fi
echo "# submitted via:" >> $NAME.sh
echo "#    $FULL_SUB_COMMAND" >> $NAME.sh
$CP_RESULT $CP_RESULT_OPT $NAME.sh $RESULTDIR > /dev/null
if [ $? -ne 0 ] ; then
    echo Problem copying script $NAME.sh to $RESULTDIR .
else 
    echo Copied script $NAME.sh to $RESULTDIR .
fi

if [ $#FILES_FILE -eq 0 ]; then
    SKIP_EVTS=$[$SKIP_EVTS+$EVTS_PER_JOB]
fi
if [ $DO_SUBMIT -ne 0 ]; then
    sleep 10
fi
ROUND=$[$ROUND+1]
done # while loop

echo
echo Submitted from $(pwd) .

############################################################
###
### Creating config for merging/pede run.
###
############################################################
for i in $ALL_BINARY_FILES ; do
    BINARY_FILES=${BINARY_FILES}$i
done
BINARY_FILES[$#BINARY_FILES]= # get rid of comma at end
for i in $ALL_TREE_FILES ; do
    TREE_FILES=${TREE_FILES}$i
done
TREE_FILES[$#TREE_FILES]= # get rid of comma at end

sed -e "s|LOGFILE|alignment_merge.log|g"        $CONFIG_TEMPLATE > ${CONFIG}0.tmp
sed -e "s|OUT_DIR|${RESULTDIR/$RESULTHOST:/}|g" ${CONFIG}0.tmp > ${CONFIG}1.tmp
sed -e "s|ONE_TREE_FILE|treeFile_merge.root|g"  ${CONFIG}1.tmp > ${CONFIG}2.tmp
sed -e "s|MERGE_TREE_FILES|$TREE_FILES|g"       ${CONFIG}2.tmp > ${CONFIG}3.tmp
sed -e "s|ONE_BINARY_FILE||g"                   ${CONFIG}3.tmp > ${CONFIG}4.tmp
sed -e "s|MERGE_BINARY_FILES|$BINARY_FILES|g"   ${CONFIG}4.tmp > ${CONFIG}5.tmp
sed -e "s|SUFFIX|_merge|g"                      ${CONFIG}5.tmp > ${CONFIG}6.tmp
sed -e "s|EVTS_PER_JOB|0|g"                     ${CONFIG}6.tmp > ${CONFIG}7.tmp
sed -e "s|SKIP_EVTS|0|g"                        ${CONFIG}7.tmp > ${CONFIG}8.tmp
sed -e "s|FILE_REPLACE||g"                      ${CONFIG}8.tmp > ${CONFIG}9.tmp
sed -e "s|MODE|pede|g"                          ${CONFIG}9.tmp > alignment_merge.cfg
rm ${CONFIG}[0-9].tmp
$CP_RESULT $CP_RESULT_OPT alignment_merge.cfg $RESULTDIR #> /dev/null
rm $CONFIG_TEMPLATE

#cd - # back from $SUBMIT_DIR - redundant...
