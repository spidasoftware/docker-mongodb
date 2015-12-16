#
# MongoDB Dockerfile (adapted from: https://github.com/dockerfile/mongodb)
# 
# To run :
# docker run -d -p 27017:27017 --name mongodb ${machineUUID}
#
# To run with mounted directory for storage: 
# docker run -d -p 27017:27017 -v <db-dir>:/data/db --name mongodb ${machineUUID}
#
# To test backup and restore, run this command inside container:
# cd /backups;./backup.sh;mongo --verbose 127.0.0.1:27017/calcdb -u minmaster -p f1faa381-7568-46c8-8332-d4322376083a --eval "db.dropDatabase()";./restore.sh


FROM ubuntu:14.04

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 && \
  	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' > /etc/apt/sources.list.d/mongodb.list && \
  	apt-get update && \
  	apt-get install -y mongodb-org=2.6.7 mongodb-org-server=2.6.7 mongodb-org-shell=2.6.7 mongodb-org-mongos=2.6.7 mongodb-org-tools=2.6.7 && \
  	apt-get install cron vim -y && \
  	rm -rf /var/lib/apt/lists/*

COPY backup.sh /backup.sh
COPY restore.sh /restore.sh
COPY crontab /etc/cron.d/mongodb-backup-cron
COPY mongodb-entrypoint.sh /mongodb-entrypoint.sh
COPY createMongoUser.js /usr/local/bin/createMongoUser.js

# Allows connecting from any IP during development.
# RUN sed -i 's/bind_ip/#bind_ip/g' /etc/mongod.conf

WORKDIR /data

VOLUME ["/backups"]
VOLUME ["/data/db"]

# process:27017, http:28017
EXPOSE 27017
EXPOSE 28017

ENTRYPOINT ["/mongodb-entrypoint.sh"]
CMD ["mongod", "--auth"]
