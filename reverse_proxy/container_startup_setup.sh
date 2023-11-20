#!/usr/bin/env bash
export DOLLAR='$'
export DEV_STRING=''
if [[ "${ENV_STATE}" == "dev" ]]
then
  cp nginx_dev.conf /etc/nginx/nginx.conf
else
  cp nginx_prod.conf /etc/nginx/nginx.conf
fi
nginx -g "daemon off;"