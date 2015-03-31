#!/bin/bash
# Edit the following two lines where necessary
LD_LIBRARY_PATH=/usr/local/cuda/lib64
export OMP_NUM_THREADS=64

APP=/home/tjl10/CSR/build/cudaSirecon/cudaSireconDriver

# Edit the following two lines for your account and folder structure
OTF_FOLDER='/home/tjl10/OTFs' 				# folder where OTF files live
# OTF files must follow the naming convention [EMISSIONWAVE].otf
CONFIG_FOLDER='/home/tjl10/SIconfig' 		# folder wher config files live
# config files must follow the naming convention [EMISSIONWAVE]config

INPUT=$1

WAVE=${INPUT: -6:3}												# file to reconstruct
CONFIG=${CONFIG_FOLDER}/${WAVE}config 						# config folder
OUTPUT=${INPUT/.dv/-PROC.dv} 									# file to output to
OTF=${OTF_FOLDER}/${WAVE}.otf 								# OTF file
LOG=${INPUT/.dv/-LOG.txt}										# log file


echo "Input file: "$INPUT
echo "Output file: "$OUTPUT
echo "OTF used: "$OTF
echo "Wavelength: "$WAVE

# Create your own config files or edit 488config to change parameter setting. Or use command line options;
$APP -c $CONFIG $INPUT $OUTPUT $OTF | tee $LOG

