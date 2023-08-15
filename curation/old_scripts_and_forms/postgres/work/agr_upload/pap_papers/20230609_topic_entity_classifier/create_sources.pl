#!/usr/bin/perl -w

# generate topic entity classifiers for Kimberly for ABC  https://agr-jira.atlassian.net/browse/SCRUM-2664  2023 06 09
#
# create sources at ABC if they don't already exist.
# does not handle cur_svmdata nor cur_nncdata until confirmation.  2023 08 15

# ./create_sources.pl


use strict;
use diagnostics;
use DBI;
use JSON;
use Encode qw( from_to is_utf8 );
use Storable qw(dclone);

use constant FALSE => \0;
use constant TRUE => \1;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $mod = 'WB';
my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
# my $okta_token = &generateOktaToken();
my $okta_token = 'use_above_when_live';


# my $source_json = '{
#   "source_type": "professional_biocurator",
#   "source_method": "wormbase_curation_status",
#   "validation_type": "curator",
#   "evidence": "eco_string",
#   "mod_abbreviation": "WB",
#   "description": "cur_curdata",
#   "created_by": "default_user",
#   "updated_by": "default_user"
# }';
my %source_default = (
  "source_type"      => "professional_biocurator",
  "source_method"    => "wormbase_curation_status",
  "evidence"         => "eco_string",
  "mod_abbreviation" => $mod,
  "created_by"       => "default_user",
  "updated_by"       => "default_user"
);

my $source_type = 'professional_biocurator';
my $source_method = 'wormbase_curation_status';
my $source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'cur_curdata';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

$source_type = 'professional_biocurator';
$source_method = 'wormbase_oa';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curation_tools';
  $source_json{description}     = 'caltech curation tools';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

$source_type = 'professional_biocurator';
$source_method = 'cfp';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'cfp curator';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

$source_type = 'professional_biocurator';
$source_method = 'afp';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'afp curator';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

$source_type = 'author';
$source_method = 'afp';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'author';
  $source_json{description}     = 'afp author';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

$source_type = 'author';
$source_method = 'ACKnowledge';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'author';
  $source_json{description}     = 'ACKnowledge author';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

$source_type = 'TBD';
$source_method = 'script_antibody_data';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{description}     = 'script parsing antibody';	# script name here
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}

# TODO  create cur_svmdata and cur_nncdata, confirm that for each, we're creating a new source for each datatype


sub createSource {
  my ($source_type, $source_method, $source_json) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$source_json'`;
#   print qq(create $source_json\n);
#   print qq($api_json\n);
}

sub getSourceId {
  my ($source_type, $source_method) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
  # print qq($url\n);
  my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'`;
  my $hash_ref = decode_json $api_json;
  if ($$hash_ref{'topic_entity_tag_source_id'}) {
    my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
    # print qq($source_id\n);
    return $source_id; }
  else { return ''; }
}

sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}

