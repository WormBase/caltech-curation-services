#!/bin/bash

export WB_DB_URI="datomic:ddb://us-east-1/WSNames/wormbase"
java -cp wb-names-export.jar clojure.main -m wormbase.names.export gene genes.csv    

# get latest dump of gene data from names service for populate_gin_nightly.pl
# 2020 07 02

# install java8
#
# sudo apt-get install awscli
# aws configure
#   AWS Access Key ID [None]: 
#   AWS Secret Access Key [None]: 
# (goes into ~/.aws/config   could also have in ~/.aws/credentials)
# 
# get the exporter :
# aws s3 ls s3://wormbase/names/exporter/
# aws s3 cp s3://wormbase/names/exporter/wb-names-export.jar wb-names-export.jar


