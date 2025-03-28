#!/usr/bin/env perl

# generate topic entity classifiers for Kimberly for ABC  
# some runs from the cronjob from 20240608 20240706 20240727 20240803 20240810 20240817 20240824
# had failures because ATP 123 didn't exist.  we don't know why that happenned, there were lots of
# issue around then.  this script reads from those logs and posts all the data from those days.
# 399 success, 761 exists when run against stage.




use strict;
use diagnostics;
use DBI;
use JSON;
use Jex;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';


# RUN THIS AGAINST PROD if ready
my $destination = '4002';
# my $destination = 'stage';
# my $destination = 'prod';

my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
if ($destination eq 'stage') {
  $baseUrl = 'https://stage-literature-rest.alliancegenome.org/'; }
if ($destination eq 'prod') {
  $baseUrl = 'https://literature-rest.alliancegenome.org/'; }


# my $output_format = 'json';
my $output_format = 'api';
my $tag_counter = 0;

my $logfile = ''; my $jsonfile = '';
my $simpledate = &getSimpleDate;
my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/postgres/agr_upload/pap_papers/20240321_topic_entity_species/";
if ($output_format eq 'api') {
  $logfile = $outDir . 'populate_species_topic_entity.api.' . $destination . '.' . $simpledate . '.api';
  open (LOG, ">$logfile") or die "Cannot create $logfile : $!";
} else {
  $jsonfile = $outDir . 'populate_species_topic_entity.api.' . $destination . '.' . $simpledate . '.json';
  open (JSON, ">$jsonfile") or die "Cannot create $jsonfile : $!";
}

my $okta_token = &generateOktaToken();

my @dates = qw( 20240608 20240706 20240727 20240803 20240810 20240817 20240824 );
foreach my $date (@dates) {
  my $infile = 'cron_files/populate_species_topic_entity.api.prod.' . $date . '.api';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    if ($line =~ m/^create ({.*})$/) {
#     $tag_counter++;
#     if ($tag_counter > 1) { last; }
    my $object_json = $1;
    my $url = $baseUrl . 'topic_entity_tag/';
    print LOG qq(DATE $date URL $url DATA $object_json\n);
# UNCOMMENT next 3 lines to populate
#     my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$object_json'`;
#     print LOG qq(create $object_json\n);
#     print LOG qq($api_json\n);
    }
  }
  close (IN) or die "Cannot close $infile : $!";
}

if ($output_format eq 'api') {
  close (LOG) or die "Cannot close $logfile : $!";
} else {
  close (JSON) or die "Cannot close $jsonfile : $!";
}

sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}

