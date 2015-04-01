 #!/bin/bash

# this file is meant to be run on the local computer as follows
# orchSIR.sh path/to/file/to/be/reconstructed


# variables
FILE=$1
ORCHESTRA_USER='tjl10'
HOST='orchestra.med.harvard.edu'
UPLOAD_DIR='~/files'
FNAME=$(basename $FILE)
PROC=${FNAME/.dv/-PROC.dv}
LOG=${FNAME/.dv/-job.log}
FDIR=$(dirname $FILE)

############################
# UPLOAD FILE TO ORCHESTRA #
############################

scp -c arcfour128 $FILE $ORCHESTRA_USER@$HOST:$UPLOAD_DIR

#############################
# START REMOTE RECON SCRIPT #
#############################

ssh $ORCHESTRA_USER@$HOST ". /opt/lsf/conf/profile.lsf; ~/orchSIR/recon.sh $UPLOAD_DIR/$FNAME;"

wait

#################################
# DOWNLOAD RESULT WHEN FINISHED #
#################################

echo "downloading processed files..."

scp -c arcfour128 $ORCHESTRA_USER@$HOST:$UPLOAD_DIR/\{$PROC,$LOG\} $FDIR


#############################
# CLEAN UP SERVER WHEN DONE #
#############################

echo "files downloaded... removing from orchestra..."

ssh $ORCHESTRA_USER@$HOST "rm -f $UPLOAD_DIR/{$FNAME,$PROC,$LOG};"

echo "done!"