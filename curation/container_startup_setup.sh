#!/usr/bin/env bash

# This is the main script called by the Dockerfile to set up the container when started

# backups

restic -r ${RESTIC_REPOSITORY}/daily_backups init
restic -r ${RESTIC_REPOSITORY}/monthly_backups init
restic -r ${RESTIC_REPOSITORY}/volumes_backups init

updatedb

export DEV_STRING=''
if [[ "${ENV_STATE}" == "dev" ]]
then
  export DEV_STRING='-dev'
fi

# set apache env variables
echo "export CALTECH_CURATION_FILES_INTERNAL_PATH=${CALTECH_CURATION_FILES_INTERNAL_PATH}" >> /etc/apache2/envvars
echo "export HOST_NAME=${HOST_NAME}" >> /etc/apache2/envvars
echo "export SSL_PORT=${SSL_PORT}" >> /etc/apache2/envvars
echo "export API_SERVER=${API_SERVER}" >> /etc/apache2/envvars
echo "export API_PORT=${API_PORT}" >> /etc/apache2/envvars
echo "export IP_INSIDE_DOCKER=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | cut -d "/" -f 1)" >> /etc/apache2/envvars
echo "export IP_OUTSIDE_DOCKER=$(nslookup caltech-curation${DEV_STRING}.textpressolab.com | awk '/^Address: / { print $2 }' | head -n1)" >> /etc/apache2/envvars
# listen on additional ssl port in case it is not the standard one
if [[ "${SSL_PORT}" -ne "443" ]]
then echo "Listen ${SSL_PORT}" > /etc/apache2/additional_listeners.conf
fi

# symlink Daniel's pdf upload folder to folder used by agr bulk uploader
mkdir -p "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/files"
mkdir -p "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs"
if [[ ! -f /usr/files_to_upload ]]
then
  ln -sf "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/files" /usr/files_to_upload
fi
chmod +x /usr/lib/scripts/agr_ref_files_bulk_uploader/upload_files_and_save_logs.sh
setfacl -R -d -m user:acedb:rwX "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/files"

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

# set up citace user home dir
mkdir -p "${CALTECH_CURATION_FILES_INTERNAL_PATH}/citace"
if [[ ! -f /home/citace ]]
then
  ln -sf "${CALTECH_CURATION_FILES_INTERNAL_PATH}/citace" /home/citace
fi

if [[ "${ENV_STATE}" == "prod" ]]
then
  declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env
  chmod 0644 /etc/cron.d/curation_crontab
  crontab /etc/cron.d/curation_crontab
  cron
fi

tail -f /dev/null