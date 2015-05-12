#!/bin/bash
# this file simply starts Lin's program finding the appropriate OTF file and
# config file using the name of the input file...

export LD_LIBRARY_PATH=/opt/cuda-5.0/lib64:$LD_LIBRARY_PATH
export OMP_NUM_THREADS=64

PRIISM_FOLDER='/home/tjl10/priism-4.4.1/'

# this should point to the Priism_setup file in the priism folder in your home directory
. $PRIISM_FOLDER/Priism_setup.sh
# this is required for using the priism command line arguments
. /opt/intel/bin/compilervars.sh intel64

# Edit the following two lines where necessary

APP='/home/tjl10/CUDA_SIMrecon/build/cudaSirecon/cudaSireconDriver'

# Edit the following two lines for your account and folder structure
OTF_FOLDER='/home/tjl10/orchSIR/OTFs' 				# folder where OTF files live
# OTF files must follow the naming convention [EMISSIONWAVE].otf
CONFIG_FOLDER='/home/tjl10/orchSIR/SIconfig' 		# folder wher config files live
# config files must follow the naming convention [EMISSIONWAVE]config

#CORRECTION_FILE='/home/tjl10/orchSIR/cor/cam1cor.mrc'

INPUT=$1

waves() {
    echo "$(echo | header $INPUT | grep "Wavelengths (nm)" | awk -F'   ' '{print $2}')"
}

WAVE=$(waves $INPUT)										# file to reconstruct
CONFIG=${CONFIG_FOLDER}/${WAVE}config 						# config folder
#OUTPUT=${INPUT/.dv/-PROC.dv} 								# file to output to
DEFAULT_OTF=${OTF_FOLDER}/${WAVE}.otf 								# OTF file
LOG=${INPUT/.dv/-LOG.txt}									# log file

OTF=${2:-0}
if [ $OTF = 0 ]; then OTF=$DEFAULT_OTF; fi

#computed varibles
DATA_DIR=${INPUT%/*}
BASE_FILE=${INPUT##*/}
OTF_NAME=${OTF##*/}
OTF_DATE=$(date -r $OTF +%y%m%d)

OIFS=$IFS;
IFS="_";
keyArray=(${OTF_NAME%.otf});
OTF_WAVE=${keyArray[0]};
OTF_OIL=${keyArray[2]};
OTF_MEDIUM=${keyArray[3]};
OTF_ANGLE=${keyArray[4]};
OTF_BEAD=${keyArray[5]};
IFS=$OIFS;
OTF_KEY="d${OTF_DATE}w${OTF_WAVE}o${OTF_OIL: -2}${OTF_ANGLE}b${OTF_BEAD: -2}"

OUTPUT="${DATA_DIR}/${BASE_FILE%.dv}_${OUTPUT_TAG}${OTF_KEY}_SIR.dv"


echo "Input file: "$INPUT
echo "Output file: "$OUTPUT
echo "OTF used: "$OTF
echo "Wavelength: "$WAVE
echo "second arg: "$2

# Create your own config files or edit 488config to change parameter setting. Or use command line options;
$APP -c $CONFIG $INPUT $OUTPUT $OTF | tee $LOG
# $APP -c $CONFIG $INPUT $OUTPUT $OTF --usecorr $CORRECTION_FILE | tee $LOG
