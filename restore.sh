#!/bin/bash

set -u # Treat unset variables as an error when substituting.

#restore from backup dir arg passed in
ALL_BAKS=/backups
pushd $ALL_BAKS

DIR=$1

#if no arg restore from latest backup
if [[ $# -eq 0 ]]; then
	echo "No directory specified. Restoring from latest backup..."
	DIR=$(ls -td /backups/mongodump-* | head -n 1) #find latest backup
fi

#if no backup dir found exit
if [ -z "$DIR" ]; then
	echo "No backup directory found."
	exit
fi

#NOTE: --drop will clear existing collections before restore
mongorestore --verbose --drop --username $MONGODB_USERNAME --password $MONGODB_PASSWORD --gzip $DIR

popd