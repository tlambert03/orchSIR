 #!/bin/bash

FILE=$1
ORCHESTRA_USER='tjl10'
HOST='orchestra.med.harvard.edu'
UPLOAD_DIR='~/files'

scp $FILE $ORCHESTRA_USER@$HOST:$UPLOAD_DIR

FNAME=$(basename $FILE)
PROC=${FNAME/.dv/-PROC.dv}
LOG=${FNAME/.dv/-job.log}
FDIR=$(dirname $FILE)

ssh $ORCHESTRA_USER@$HOST ". /opt/lsf/conf/profile.lsf; ~/orchSIR/recon.sh $UPLOAD_DIR/$FNAME;"

wait

echo "downloading processed files..."

scp $ORCHESTRA_USER@$HOST:$UPLOAD_DIR/$PROC $FDIR/$PROC
scp $ORCHESTRA_USER@$HOST:$UPLOAD_DIR/$LOG $FDIR/$LOG

echo "files downloaded... removing from orchestra..."

ssh $ORCHESTRA_USER@$HOST "rm -f $UPLOAD_DIR/$FNAME; rm -f $UPLOAD_DIR/$PROC; rm -f $UPLOAD_DIR/$LOG;"

echo "done!"