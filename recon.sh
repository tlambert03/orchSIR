 #!/bin/bash

#change these to be appropriate for your account and folder sctructure:
PRIISM_FOLDER='/home/tjl10/priism-4.4.1/'

# this should point to the Priism_setup file in the priism folder in your home directory
. $PRIISM_FOLDER/Priism_setup.sh
# this is required for using the priism command line arguments
. /opt/intel/bin/compilervars.sh intel64


numwaves() {
    echo "$(echo | header $RAW_FILE | grep "Number of Wavelengths" | awk -F'    ' '{print $2}')"
}

waves() {
    echo "$(echo | header $RAW_FILE | grep "Wavelengths (nm)" | awk -F'   ' '{print $2}')"
}

RAW_FILE=$1 # the grabs the input file
echo "processing ${RAW_FILE}"
OUTPUT=${RAW_FILE/.dv/-PROC.dv}
echo "Output will be: ${OUTPUT}"
NUMWAVES=$(numwaves $RAW_FILE)
WAVES=$(waves $RAW_FILE)
echo "${NUMWAVES} wavelengths: ${WAVES}"
LOGFILE=${RAW_FILE/.dv/-job.log}

#split file into wavelengths
echo "splitting file into ${NUMWAVES} wavelengths"
JOB1="$(basename $RAW_FILE)_SPLT"
bsub -q priority -W 0:05 -J $JOB1 -R 'rusage[mem=2000]' -o $LOGFILE ./splitfile.sh $RAW_FILE;

#reconstruct the wavelengths
FILELIST=""
for w in $WAVES; do
    CPY=${RAW_FILE/.dv/-$w.dv}
    FNAME=$(basename $CPY)
    JOB2="${FNAME}_SIR"
    echo "sending jobname: "$JOB2
    bsub -K -q priority -W 0:05 -R 'rusage[ngpus=1]' -w "done($JOB1)" -J $JOB2 -o $LOGFILE ./reconstruct.sh $CPY &
    FILELIST=${FILELIST}" ${CPY/.dv/-PROC.dv}"
done
FILELIST=${FILELIST:1}

wait

# echo "sending merge job"
# bsub -K -q priority -W 0:05 -w "done($JOB2)" -R 'rusage[mem=2000]' -J "${RAW_FILE}_MRG" -o $LOGFILE mergemrc -append_waves $OUTPUT ${FILELIST}
mergemrc -append_waves $OUTPUT ${FILELIST}


echo "merging channels finished... cleaning up channel files"

# cleanup
for w in $WAVES; do
    CPY=${RAW_FILE/.dv/-$w.dv}
    # make a duplicate file containing just one of the wavelengths
    rm -f $CPY;
    PROC=${CPY/.dv/-PROC.dv}
    rm -f $PROC;
    LOG=${CPY/.dv/-LOG.txt}
    rm -f $LOG;
done



