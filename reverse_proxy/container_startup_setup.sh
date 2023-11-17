#!/usr/bin/env bash
export DOLLAR='$'
export DEV_STRING=''
if [[ "${ENV_STATE}" == "dev" ]]
then
  export DEV_STRING='-dev'
fi
envsubst '$DEV_STRING' < nginx.conf > /etc/nginx/nginx.conf
nginx -g "daemon off;"