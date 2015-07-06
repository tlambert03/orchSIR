 #!/bin/bash

# this file is meant to be run on the local computer as follows
# orchSIR.sh path/to/file/to/be/reconstructed


# variables
FILE=$1
OTF=${2:-0}
ORCHESTRA_USER='tjl10'
HOST='orchestra.med.harvard.edu'
UPLOAD_DIR='~/files'
FNAME=$(basename $FILE)
OTF_DIR='~/OTFs'
OTF_NAME=$(basename $OTF)
PROC=${FNAME/.dv/-PROC.dv}
LOG=${FNAME/.dv/-job.log}
FDIR=$(dirname $FILE)

############################
# UPLOAD FILE TO ORCHESTRA #
############################

echo "uploading files to orchestra..."

scp -c arcfour128 $FILE $ORCHESTRA_USER@$HOST:$UPLOAD_DIR
if [ $OTF != 0 ]; then scp -c arcfour128 $OTF $ORCHESTRA_USER@$HOST:$OTF_DIR; fi

#############################
# START REMOTE RECON SCRIPT #
#############################

echo "running remote reconstruction script..."

if [ $OTF = 0 ]; then
	ssh $ORCHESTRA_USER@$HOST ". /opt/lsf/conf/profile.lsf; ~/orchSIR/recon.sh $UPLOAD_DIR/$FNAME;"
else
	ssh $ORCHESTRA_USER@$HOST ". /opt/lsf/conf/profile.lsf; ~/orchSIR/recon.sh $UPLOAD_DIR/$FNAME $OTF_DIR/$OTF_NAME;"
fi


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