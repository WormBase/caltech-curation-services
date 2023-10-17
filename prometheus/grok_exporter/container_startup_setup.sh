#!/usr/bin/env bash

# This is the main script called by the Dockerfile to set up the container when started

mkdir -p /grok/log/afp
mkdir -p /grok/log/ntt_extr/email_addr

touch /grok/log/ntt_extr/email_addr/email_ext_pipeline.log

./grok_exporter -config=/grok/config.yml