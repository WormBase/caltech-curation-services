#!/usr/bin/env perl

# generate topic entity classifiers for Kimberly for ABC  https://agr-jira.atlassian.net/browse/SCRUM-2664  2023 06 09
#
# modified for cur_curdata for general topics without entities.  2023 08 15
#
# modified for cur_svmdata, cur_nncdata, cur_strdata, cfp_<*>   2023 08 17
#
# cur_strdata antibody only has data for the new pipeline, old data was overwritten or lost, only have 1 source now.
# dump afp_<datatype> data for afp_curator to curator/afp source, afp_author afp to author/afp source, 
# afp_author ack based on timestamp to author/ACKnowledge source.  2023 08 18
#
# account for okta tokens expire after 24 hours.  if % 1000 entries and >23 hours, reset okta token.  2023 08 21
#
# Needs to be modified for gene instead of entity/classifier.  2024 01 08
#
# Blind guessing at what to extract, it's very clearly wrong.
# https://agr-jira.atlassian.net/browse/SCRUM-3271?focusedCommentId=42377
# 2024 04 18


# if single json output
# ./populate_gene_topic_entity.pl | json_pp

# if creating data through ABC API
# ./populate_gene_topic_entity.pl


# to clean up, must delete validation first, then tags.
# DELETE FROM topic_entity_tag_validation WHERE validated_topic_entity_tag_id > 516 OR validating_topic_entity_tag_id > 516
# DELETE FROM topic_entity_tag WHERE topic_entity_tag_id > 516


use strict;
use diagnostics;
use DBI;
use JSON;
use Jex;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

use constant FALSE => \0;
use constant TRUE => \1;

my $start_time = time;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $output_format = 'json';
# my $output_format = 'api';
my $tag_counter = 0;

my @output_json;

my $mod = 'WB';
# my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
my $okta_token = &generateOktaToken();
# my $okta_token = 'use_above_when_live';

# my @wbpapers = qw( 00004952 00005199 00026609 00030933 00035427 );
# my @wbpapers = qw( 00004952 00005199 00046571 00057043 00064676 );
# my @wbpapers = qw( 00046571 );
# my @wbpapers = qw( 00005199 );
# my @wbpapers = qw( 00057043 );
# my @wbpapers = qw( 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049 );
# my @wbpapers = qw( 00055090 );
# my @wbpapers = qw( 00066031 );
# my @wbpapers = qw( 00038491 00055090 );	# papers with lots of genes  2024 03 12
my @wbpapers = qw( 00003000 00004455 00004952 00005199 00005707 00006103 00006320 00017095 00025176 00027230 00046571 00057043 00063127 00064676 00064771 00065877 00066211 );		# kimberly 2024 04 18 set

# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 
# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049

my %datatypesAfpCfp;
my %datatypes;
my %entitytypes;
my %wbpToAgr;

my %chosenPapers;

my %infOther;
my %curConf;

my $geneTopic = 'ATP:0000142';
my $entityType = 'ATP:0000005';
my $entity_id_validation = 'alliance';

foreach my $joinkey (@wbpapers) { $chosenPapers{$joinkey}++; }
# $chosenPapers{all}++;

&populateAbcXref();
&populatePapGene();
&outputInfOther();
&outputCurConf();

if ($output_format eq 'json') {
  my $json = encode_json \@output_json;		# for single json file output
  print qq($json\n);				# for single json file output
}

# foreach my $oj (@output_json) {
#   print qq(OJ $oj\n);
# } 


sub outputCurConf {
  # old source
  # my $source_type = 'professional_biocurator';
  # my $source_method = 'paper_editor';
  # my $source_id = &getSourceId($source_type, $source_method);
  
  my $source_evidence_assertion = 'ATP:0000036';
  my $source_method = 'paper_editor_genes_curator';
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  my $timestamp = &getPgDate();
  unless ($source_id) {
    print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

#   { "source_type": "professional_biocurator", "source_method": "wormbase_oa", "evidence": "eco_string", "description": "caltech curation tools", "mod_abbreviation": "WB" }
  foreach my $joinkey (sort keys %curConf) {
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    foreach my $gene (sort keys %{ $curConf{$joinkey} }) {
      my %object;
      $object{'negated'}                    = FALSE;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $geneTopic;
      $object{'entity_type'}                = $entityType;
      $object{'entity_id_validation'}       = $entity_id_validation;
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'entity'}                     = "WB:WBGene$gene";
      $object{'created_by'}                 = $curConf{$joinkey}{$gene}{curator};
      $object{'updated_by'}                 = $curConf{$joinkey}{$gene}{curator};
      $object{'date_created'}               = $curConf{$joinkey}{$gene}{timestamp};
      $object{'date_updated'}               = $curConf{$joinkey}{$gene}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub outputInfOther {
  # my $source_type = 'script';
  # my $source_method = 'gene_paper_association_script';
  # my $source_id = &getSourceId($source_type, $source_method);

  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'paper_editor_genes_script';
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  my $timestamp = &getPgDate();
  unless ($source_id) {
    print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

#   { "source_type": "professional_biocurator", "source_method": "wormbase_oa", "evidence": "eco_string", "description": "caltech curation tools", "mod_abbreviation": "WB" }
  foreach my $joinkey (sort keys %infOther) {
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    foreach my $gene (sort keys %{ $infOther{$joinkey} }) {
      my %object;
      $object{'negated'}                    = FALSE;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $geneTopic;
      $object{'entity_type'}                = $entityType;
      $object{'entity_id_validation'}       = $entity_id_validation;
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'entity'}                     = "WB:WBGene$gene";
      $object{'created_by'}                 = $infOther{$joinkey}{$gene}{curator};
      $object{'updated_by'}                 = $infOther{$joinkey}{$gene}{curator};
      $object{'date_created'}               = $infOther{$joinkey}{$gene}{timestamp};
      $object{'date_updated'}               = $infOther{$joinkey}{$gene}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub populatePapGene {
  $result = $dbh->prepare( "SELECT joinkey, pap_gene, pap_timestamp, pap_curator, pap_evidence FROM pap_gene" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey, $gene, $ts, $two, $evi) = @row;
    $two =~ s/two/WBPerson/;
    if ($evi) { $evi =~ s/\n/ /g; $evi =~ s/ $//g; }
      else { $evi = ''; }
    if ($evi =~ m/Curator_confirmed.*(WBPerson\d+)/) {
      $curConf{$joinkey}{$gene}{curator} = $1;
      $curConf{$joinkey}{$gene}{timestamp} = $ts; }
    elsif ($evi =~ m/Inferred_automatically/) { 	# this has to be more specific later
      $infOther{$joinkey}{$gene}{curator} = $two;
      $infOther{$joinkey}{$gene}{timestamp} = $ts; }
    else {
      # stuff without evidence
    }
} }



sub populateAbcXref {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'AGRKB';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 	# only molecules with papers are curated
  while (my @row = $result->fetchrow) { 
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $wbpToAgr{$row[0]} = $row[1]; }
} # sub populateAbcXref


sub getSourceId {
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

# old source format
# sub getSourceId {
#   my ($source_type, $source_method) = @_;
#   my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
# #   print qq($url\n);
#   my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'`;
#   my $hash_ref = decode_json $api_json;
#   my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
#   if ($$hash_ref{'topic_entity_tag_source_id'}) {
#     my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
#     # print qq($source_id\n);
#     return $source_id; }
#   else { return ''; }
# #   print qq($source_id\n);
# }

sub createTag {
  my ($object_json) = @_;
  $tag_counter++;
  if ($tag_counter % 1000 == 0) { 
    my $date = &getSimpleSecDate();
    print qq(counter\t$tag_counter\t$date\n);
    my $now = time;
    if ($now - $start_time > 82800) {		# if 23 hours went by, update okta token
      $okta_token = &generateOktaToken();
      $start_time = $now;
    }
  }
  my $url = $baseUrl . 'topic_entity_tag/';
# PUT THIS BACK
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$object_json'`;
  print qq(create $object_json\n);
  print qq($api_json\n);
}


sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}

# sub generateXrefJsonFile {
#   my $okta_token = &generateOktaToken();
#   `curl -X 'GET' 'https://stage-literature-rest.alliancegenome.org/bulk_download/references/external_ids/' -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'  > $xref_file_path`;
# }

sub tsToDigits {
  my $timestamp = shift;
  my $tsdigits = '';
  if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { $tsdigits = $1 . $2 . $3; }
  return $tsdigits;
}

