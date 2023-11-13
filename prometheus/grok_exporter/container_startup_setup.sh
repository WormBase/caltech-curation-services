#!/usr/bin/env bash

# This is the main script called by the Dockerfile to set up the container when started

mkdir -p /grok/log/afp
mkdir -p /grok/log/ntt_extr/email_addr
mkdir -p /grok/log/ntt_extr/expr_cluster

touch /grok/log/ntt_extr/email_addr/email_ext_pipeline.log
touch /grok/log/ntt_extr/expression_cluster/expr-cluster_ext_pipeline.log

./grok_exporter -config=/grok/config.yml