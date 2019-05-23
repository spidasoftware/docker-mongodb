#!/bin/bash

set -u # Treat unset variables as an error when substituting.

#Handle unclean shutdown
if [ -s /data/db/mongod.lock ]; then
	echo 'Unclean shutdown detected.  DB may be in inconsistant state. Repairing..'
	mongod --dbpath /data/db --repair
	echo 'Repair complete'
fi

if [ ! -f /data/db/.mongodb_password_set ]; then
	echo "Setting password..."
	 
	mongod --fork --logpath /var/log/mongodb/mongodb.log

	RET=1
	while [[ RET -ne 0 ]]; do
	    echo "=> Waiting for confirmation of MongoDB service startup"
	    sleep 5
	    mongo admin --eval "help" >/dev/null 2>&1
	    RET=$?
	done

	echo "=> Creating an admin user in MongoDB"
	mongo admin --eval "db.dropUser('$MONGODB_USERNAME');"
	mongo admin --eval "db.createUser({user: '$MONGODB_USERNAME', pwd: '$MONGODB_PASSWORD', roles: [ 'root' ]});"
	mongo $MONGODB_DATABASE --eval "db.dropUser('$MONGODB_USERNAME');"
	mongo $MONGODB_DATABASE --eval "db.createUser({user: '$MONGODB_USERNAME', pwd: '$MONGODB_PASSWORD', roles: [ 'dbOwner', 'userAdmin' ]});"
	mongod --shutdown

	echo "=> Done!"
	touch /data/db/.mongodb_password_set
fi
if [ ! -f /.env_set ]; then
	echo "MONGODB_DATABASE=$MONGODB_DATABASE" >> /etc/environment
	echo "MONGODB_USERNAME=$MONGODB_USERNAME" >> /etc/environment
	echo "MONGODB_PASSWORD=$MONGODB_PASSWORD" >> /etc/environment
	touch /.env_set
fi

set +u # We're checking if it's set, don't treat unset variables as an error when substituting.
if [[ ! -z "$BACKUP_JOBS_SENDGRID_API_KEY" ]]; then
	echo [smtp.sendgrid.net]:2525 apikey:$BACKUP_JOBS_SENDGRID_API_KEY > /etc/postfix/sasl_passwd
	postmap /etc/postfix/sasl_passwd
	rm /etc/postfix/sasl_passwd
	chmod 600 /etc/postfix/sasl_passwd.db
	hostname > /etc/mailname

	service postfix start
fi
set -u # Treat unset variables as an error when substituting.

cron
echo "$(date) container started. cron job: $(cat /etc/cron.d/mongodb-backup-cron | head -1)" >> /backups/backup.log

exec "$@"
