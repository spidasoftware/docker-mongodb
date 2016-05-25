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

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && \
  	echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
  	apt-get update && \
  	apt-get install -y mongodb-org=3.2.6 mongodb-org-server=3.2.6 mongodb-org-shell=3.2.6 mongodb-org-mongos=3.2.6 mongodb-org-tools=3.2.6 && \
  	apt-get install cron vim -y && \
  	rm -rf /var/lib/apt/lists/*

COPY backup.sh /backup.sh
COPY restore.sh /restore.sh
COPY crontab /etc/cron.d/mongodb-backup-cron
COPY mongodb-entrypoint.sh /mongodb-entrypoint.sh

WORKDIR /data

VOLUME ["/backups"]
VOLUME ["/data/db"]

# process:27017, http:28017
EXPOSE 27017
EXPOSE 28017

ENTRYPOINT ["/mongodb-entrypoint.sh"]
CMD ["mongod", "--auth"]
