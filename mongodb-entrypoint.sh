#!/bin/bash

if [ ! -f /data/db/.mongodb_password_set ]; then
	echo "Setting password..."

	mongod --smallfiles --nojournal &

	RET=1
	while [[ RET -ne 0 ]]; do
	    echo "=> Waiting for confirmation of MongoDB service startup"
	    sleep 5
	    mongo admin --eval "help" >/dev/null 2>&1
	    RET=$?
	done

	echo "=> Creating an admin user in MongoDB"
	mongo --eval "var mongoPassword='$MONGODB_PASSWORD'" /usr/local/bin/createMongoUser.js
	mongo admin --eval "db.shutdownServer();"

	echo "=> Done!"
	touch /data/db/.mongodb_password_set
fi
if [ ! -f /.env_set ]; then
	echo "MONGODB_PASSWORD=$MONGODB_PASSWORD" >> /etc/environment
	touch /.env_set
fi

cron
echo "$(date) container started. cron job: $(cat /etc/cron.d/mongodb-backup-cron | head -1)" >> /backups/backup.log

exec "$@"