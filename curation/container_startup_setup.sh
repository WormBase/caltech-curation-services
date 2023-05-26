#!/usr/bin/env bash

# This is the main script called by the Dockerfile to set up the container when started

# backups

restic -r ${RESTIC_REPOSITORY}/daily_backups init
restic -r ${RESTIC_REPOSITORY}/monthly_backups init

updatedb

# set apache env variables
echo "export CALTECH_CURATION_FILES_INTERNAL_PATH=${CALTECH_CURATION_FILES_INTERNAL_PATH}" >> /etc/apache2/envvars
echo "export HOST_NAME=${HOST_NAME}" >> /etc/apache2/envvars
echo "export SSL_PORT=${SSL_PORT}" >> /etc/apache2/envvars
echo "export IP_INSIDE_DOCKER=$(ip -4 -br address | awk '{if (NR!=1) print $3}' | cut -d '/' -f1)" >> /etc/apache2/envvars

# listen on additional ssl port in case it is not the standard one
if [[ "${SSL_PORT}" -ne "443" ]]
then echo "Listen ${SSL_PORT}" > /etc/apache2/additional_listeners.conf
fi

# X11 forwarding config for ssh
mkdir /var/run/sshd
sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config
sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config
grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config

# set ssh host key to mounted volume
echo "HostKey ${CALTECH_CURATION_FILES_INTERNAL_PATH}/ssh_host_key/id_rsa" >> /etc/ssh/sshd_config

# start services
service apache2 start
service ssh start
chmod -R 777 ${CALTECH_CURATION_FILES_INTERNAL_PATH}

# set complete host name and configure sendmail
echo "$(ip -4 -br address | awk '{if (NR!=1) print $3}' | cut -d '/' -f1) ${HOSTNAME} ${HOST_NAME}" >> /etc/hosts
yes | sendmailconfig

# set up citace user home dir
mkdir -p "${CALTECH_CURATION_FILES_INTERNAL_PATH}/citace"
ln -s "${CALTECH_CURATION_FILES_INTERNAL_PATH}/citace" /home/citace

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env
chmod 0644 /etc/cron.d/curation_crontab
crontab /etc/cron.d/curation_crontab
cron

tail -f /dev/null