#
# MongoDB Dockerfile (adapted from: https://github.com/dockerfile/mongodb)
# 
# To run :
# docker run -d -p 27017:27017 --name mongodb ${machineUUID}
#
# To run with mounted directory for storage: 
# docker run -d -p 27017:27017 -v <db-dir>:/data/db --name mongodb ${machineUUID}

FROM ubuntu:14.04

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# these can be overridden in .docker-common.env but they are not set there by default
ENV MONGODB_USERNAME=minmaster
ENV MONGODB_DATABASE=spidadb
# MONGODB_PASSWORD is set in .docker-common.env

RUN echo postfix postfix/mailname string willbechanged.spidastudio.com | debconf-set-selections && \
  echo postfix postfix/main_mailer_type string 'Local Only' | debconf-set-selections && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv D68FA50FEA312927 && \
  echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list && \
  apt-get update && \
  apt-get install -y mongodb-org=3.2.6 mongodb-org-server=3.2.6 mongodb-org-shell=3.2.6 mongodb-org-mongos=3.2.6 mongodb-org-tools=3.2.6 && \
  apt-get install cron vim postfix libsasl2-modules mailutils -y && \
  rm -rf /var/lib/apt/lists/* && \
  sed -i -r "s/default_transport = error/#default_transport = error/" /etc/postfix/main.cf && \
  sed -i -r "s/relay_transport = error/#relay_transport = error/" /etc/postfix/main.cf && \
  postconf -e "relayhost = [smtp.sendgrid.net]:2525" && \
  postconf -e "smtp_tls_security_level = encrypt" && \
  postconf -e "smtp_sasl_auth_enable = yes" && \
  postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd" && \
  postconf -e "header_size_limit = 4096000" && \
  postconf -e "smtp_sasl_security_options = noanonymous"

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
