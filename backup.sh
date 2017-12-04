#!/bin/bash

set -u # Treat unset variables as an error when substituting.

echo_and_mail_error() {
	echo $1
	if [[ ! -z "$ALERT_EMAIL" ]]; then
		echo $1 | mailx -s "$(hostname) mongodb backup error" $ALERT_EMAIL
	fi
}

DAYS_TO_KEEP=7
ALL_BAKS=/backups
pushd $ALL_BAKS

BAK_LOG=/backups/backup.log
NEW_BAK=mongodump-`date +%Y-%m-%d-%I-%M-%S`

echo -e "\n\n$(date) Performing mongodb backup..."

if [[ $(find $BAK_LOG -type f -size +5M 2>/dev/null) ]]; then
    >$BAK_LOG #empty log file if it is getting too big
fi

DIRS_TO_DELETE=$(find $ALL_BAKS -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "mongodump-*")
if [ -n "$DIRS_TO_DELETE" ]; then 
	echo "$(date) Deleting backups older than $DAYS_TO_KEEP days [$DIRS_TO_DELETE]"
	find $ALL_BAKS -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "mongodump-*" -exec rm -rf '{}' ';'
	if [[ $? -ne 0 ]]; then
		echo_and_mail_error "error deleting old mongodb backups on $(hostname)"
	fi
fi

#If cron job running every minute during development, remove dirs older than 2 minutes
if [[ $(cat /etc/cron.d/mongodb-backup-cron | head -c 9) == "* * * * *" ]]; then
	DIRS_TO_DELETE=$(find $ALL_BAKS -maxdepth 1 -mmin +2 -name "mongodump-*")
	if [ -n "$DIRS_TO_DELETE" ]; then 
		echo "$(date) Deleting backups older than 2 minutes [$DIRS_TO_DELETE]"
		find $ALL_BAKS -maxdepth 1 -mmin +2 -name "mongodump-*" -exec rm -rf '{}' ';'
	fi
fi

echo "$(date) Beginning mongodump..."
mongodump --db $MONGODB_DATABASE --username $MONGODB_USERNAME --password $MONGODB_PASSWORD --gzip --out $NEW_BAK
if [[ $? -ne 0 ]]; then
	echo_and_mail_error "mongodump error during mongodb backup on $(hostname)"
fi

echo "$(date) Latest backup disk usage: $(du -hs $NEW_BAK)"
echo "$(date) Total backup disk usage: $(du -hs $ALL_BAKS)"
echo "$(date) Done."

popd