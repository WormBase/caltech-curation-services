#!/usr/bin/env perl

# generate topic entity classifiers for Kimberly for ABC  https://agr-jira.atlassian.net/browse/SCRUM-2664  2023 06 09
#
# create sources at ABC if they don't already exist.
# does not handle cur_svmdata nor cur_nncdata until confirmation.  2023 08 15
#
# handle second strdata for antibody from Valerio/Daniela pipeline, use for strdata after 2021-06-09
# handles nnc and svm, although Kimberly has not confirmed.  2023 08 16
#
# dockerized, filled in TDB for source_type for str, svm, nnc.  wrote to Valerio and Kimberly about the confirmation questions.  2023 10 04
#
# Updated to use new sources that Kimberly and Valerio worked out.  Still needs some new descriptions for each datatype for svm and nnc.  API still needs changes for this to post the data, so untested.  2024 03 05

# ./create_sources.pl


use strict;
use diagnostics;
use DBI;
use JSON;
use Encode qw( from_to is_utf8 );
use Storable qw(dclone);
use Dotenv -load => '/usr/lib/.env';

use constant FALSE => \0;
use constant TRUE => \1;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $mod = 'WB';
# my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
my $okta_token = &generateOktaToken();
# my $okta_token = 'use_above_when_live';




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
Is there a default ECO value, or does every source have an explicit one ?  Is there a highest level to default to in case we ever won't have one ?
# do we want those 2 values to be the default in case we ever don't have something, or something else ?
# It's more a placeholder to know what fields should exist, but we can get rid of it.
  "source_evidence_assertion"	=> "ATP:0000036",
  "source_method"    		=> "curation_status_form",
  "validation_type"		=> "professional_biocurator",
  "description"			=> "placeholder",

  "data_provider"		=> $mod,
  "secondary_data_provider"	=> $mod,
  "created_by"      		=> "00u2ao5gp6tZJ9xXU5d7",
  "updated_by"      		=> "00u2ao5gp6tZJ9xXU5d7"
);

How do we find a new sourceId now, Valerio ?  Before it was based on
my $source_evidence_assertion = 'ATP:0000035';
my $source_method = 'ACKnowledge';
my $data_provider = $mod;
my $secondary_data_provider = $mod;
my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= "author";
  $source_json{description}			= "Manual association of entities and topics with references by authors using the ACKnowledge form.
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000035';
$source_method = 'author_first_pass';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}  			= $source_method;
  $source_json{validation_type}			= 'author';
  $source_json{description}    			= 'Manual association of entities and topics with references by authors using the author first pass form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'ontology_annotator';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual association of topics with references by professional biocurators via data type curation using the ontology annotator form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'curation_status_form';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual validation of topic associations with references by professional biocurators using the curation status form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'curator_first_pass';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual association of topics with references by professional biocurators using the curator first pass form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'string_matching_antibody';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  delete $source_json{validation_type};
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{description}     		= 'String matching algorithm that identifies relevant words and/or phrases in C. elegans references to identify references describing production and/or use of antibodies.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

# for each nnc/svm, we're creating a new source for each datatype
$result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  print qq($row[0]\n);
  $source_evidence_assertion = 'ECO:0008025';
  $source_method = 'nnc_' . $row[0];
  $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) { 
    my %source_json = %{ dclone (\%source_default) };
    delete $source_json{validation_type};
    $source_json{source_evidence_assertion}	= $source_evidence_assertion;
    $source_json{source_method}   		= $source_method;
    $source_json{description}     		= 'Neural network document classifier trained on manually validated C. elegans references to identify references describing production and/or use of antibodies.';	# TODO  Kimberly will need to generate individual descriptions for each datatype ?
    my $source_json = encode_json \%source_json;
    &createSource($source_json);
  }
} # while (my @row = $result->fetchrow)

# That happens automatically from the API ?  Or you mean populate from another value ?

$result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_svmdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  print qq($row[0]\n);
  $source_evidence_assertion = 'ECO:0008019';
  $source_method = 'svm_' . $row[0];
  $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) { 
    my %source_json = %{ dclone (\%source_default) };
    delete $source_json{validation_type};
    $source_json{source_evidence_assertion}	= $source_evidence_assertion;
    $source_json{source_method}   		= $source_method;
    $source_json{description}     		= 'Support vector machine document classifier trained on manually validated C. elegans references to identify references that describe production and/or use of antibodies.';	# TODO  Kimberly will need to generate individual descriptions for each datatype ?
    my $source_json = encode_json \%source_json;
    &createSource($source_json);
  }
} # while (my @row = $result->fetchrow)



sub createSource {
  my ($source_json) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$source_json'`;
#   print qq(create $source_json\n);
#   print qq($api_json\n);
}

sub getSourceId {
What is it going to be ?
  my ($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_evidence_assertion . '/' . $source_method . '/' . $data_provider . '/' . $secondary_data_provider; 
#   my ($source_type, $source_method) = @_;
#   my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
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

__END__


my %datatypes;
my %datatypesAfpCfp;
&populateDatatypeStuff();

sub populateDatatypeStuff {
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $datatypesAfpCfp{$row[0]} = $row[0]; }
  $datatypesAfpCfp{'chemicals'}     = 'chemicals';              # added for Karen 2013 10 02
  $datatypesAfpCfp{'blastomere'}    = 'cellfunc';
  $datatypesAfpCfp{'exprmosaic'}    = 'siteaction';
  $datatypesAfpCfp{'geneticmosaic'} = 'mosaic';
  $datatypesAfpCfp{'laserablation'} = 'ablationdata';
  $datatypesAfpCfp{'humandisease'}  = 'humdis';                 # added mapping to correct table 2018 05 17
  $datatypesAfpCfp{'rnaseq'}        = 'rnaseq';                 # for new afp form 2018 10 31
  $datatypesAfpCfp{'chemphen'}      = 'chemphen';               # for new afp form 2018 10 31
  $datatypesAfpCfp{'envpheno'}      = 'envpheno';               # for new afp form 2018 10 31
  $datatypesAfpCfp{'timeaction'}    = 'timeaction';             # for new afp form 2018 11 13
  $datatypesAfpCfp{'siteaction'}    = 'siteaction';             # for new afp form 2018 11 13
  #   delete $datatypesAfpCfp{'catalyticact'};    # has svm but no afp / cfp      # afp got added, so cfp table also created.  2018 11 07
  delete $datatypesAfpCfp{'expression_cluster'};        # has svm but no afp / cfp      # should have been removed 2017 07 08, fixed 2017 08 04
  delete $datatypesAfpCfp{'genesymbol'};                # has svm but no afp / cfp      # added 2021 01 25
  delete $datatypesAfpCfp{'transporter'};               # has svm but no afp / cfp      # added 2021 01 25
  
  $datatypes{'antibody'}           = 'ATP:0000131';
  $datatypes{'blastomere'}         = 'ATP:0000143';
  $datatypes{'catalyticact'}       = 'ATP:0000061';
  $datatypes{'chemphen'}           = 'ATP:0000080';
  $datatypes{'envphen'}            = 'ATP:0000080';
  # $datatypes{'expression_cluster'} = 'no atp, skip';
  $datatypes{'expmosaic'}          = 'ATP:0000034';
  $datatypes{'geneint'}            = 'ATP:0000068';
  $datatypes{'geneprod'}           = 'ATP:0000069';
  $datatypes{'genereg'}            = 'ATP:0000024';
  $datatypes{'genesymbol'}         = 'ATP:0000048';
  $datatypes{'geneticablation'}    = 'ATP:0000032';
  $datatypes{'geneticmosaic'}      = 'ATP:0000034';
  $datatypes{'humandisease'}       = 'ATP:0000111';
  $datatypes{'laserablation'}      = 'ATP:0000032';
  $datatypes{'newmutant'}          = 'ATP:0000083';
  $datatypes{'optogenet'}          = 'ATP:0000145';
  $datatypes{'otherexpr'}          = 'ATP:0000041';
  $datatypes{'overexpr'}           = 'ATP:0000084';
  # $datatypes{'picture'}            = 'no atp, skip';
  $datatypes{'rnai'}               = 'ATP:0000082';
  $datatypes{'rnaseq'}             = 'ATP:0000146';
  # $datatypes{'seqchange'}          = 'no atp, skip';
  $datatypes{'siteaction'}         = 'ATP:0000033';
  # $datatypes{'strain'}             = 'ATP:0000027     not in WB';
  $datatypes{'structcorr'}         = 'ATP:0000054';
  # $datatypes{'timeaction'}         = 'no atp, skip';
  $datatypes{'transporter'}        = 'ATP:0000062';
} # sub populateDatatypeStuff

