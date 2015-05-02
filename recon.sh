 #!/bin/bash

# this file is the master script run on the cluster that starts all the appropriate sub jobs:
# 1. splits the multi-channel file into single-wave parts
# 2. reconstructus each channel using the appropriate OTF and config file
# 3. recombines the reconstructed files into a single multi-wave file
# 4. cleans up

#change these to be appropriate for your account and folder sctructure:
PRIISM_FOLDER='/home/tjl10/priism-4.4.1/'
ORCH_SIR_FOLDER='/home/tjl10/orchSIR/'


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
OTF=${2:-0}
OUTPUT=${RAW_FILE/.dv/-PROC.dv}
NUMWAVES=$(numwaves $RAW_FILE)
WAVES=$(waves $RAW_FILE)
LOGFILE=${RAW_FILE/.dv/-job.log}

echo "processing ${RAW_FILE}..."
echo "Output will be: ${OUTPUT}"
if [ $OTF != 0 ]; then echo "OTF provided: ${OTF}"; fi
    
if [ $NUMWAVES -gt 1 ]; then

    # MULTI-CHANNEL FILE #

    ###############################
    # SPLIT FILE INTO WAVELENGTHS #
    ###############################

    echo "splitting file into ${NUMWAVES} wavelengths: ${WAVES}"
    JOB1="$(basename $RAW_FILE)_SPLT"
    bsub -q priority -W 0:05 -J $JOB1 -R 'rusage[mem=2000]' -o $LOGFILE $ORCH_SIR_FOLDER/splitfile.sh $RAW_FILE;

    ###############################
    # RECONSTRUCT EACH WAVELENGTH #
    ###############################

    FILELIST=""
    for w in $WAVES; do
        CPY=${RAW_FILE/.dv/-$w.dv}
        FNAME=$(basename $CPY)
        JOB2="${FNAME}_SIR"
        echo "sending jobname: "$JOB2
        bsub -K -q priority -W 0:03 -R 'rusage[ngpus=1]' -w "done($JOB1)" -J $JOB2 -o $LOGFILE ${ORCH_SIR_FOLDER}/reconstruct.sh $CPY $OTF &
        FILELIST=${FILELIST}" ${CPY/.dv/-PROC.dv}"
    done
    FILELIST=${FILELIST:1}

    wait

    #########################################
    # MERGE SINGLE-WAVE RECONSTRUCTED FILES #
    #########################################

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


else

    # SINGLE-CHANNEL FILE #

    FNAME=$(basename $RAW_FILE)
    echo "Reconstructing single channel image with wavelength: ${WAVES}"
    bsub -K -q priority -W 0:03 -R 'rusage[ngpus=1]' -J "${FNAME}_SIR" -o $LOGFILE ${ORCH_SIR_FOLDER}/reconstruct.sh $RAW_FILE $OTF

    wait
    
    # cleanup CUDA_SIMrecon log file
    LOG=${RAW_FILE/.dv/-LOG.txt}
    rm -f $LOG;
fi
