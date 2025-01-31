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
# modified for topic entity species.  2024 03 21
#
# modified to work with cron by writing output to logfiles.  2024 04 04
#
# before 2019 02 05 pap_species didn't have evidence, so treating as if Kimberly did those manually, without a note.
# testing against stage, then will run on prod to fix the data, then will uncomment from this script which is live
# in a cronjob.  2025 01 22
#
# send pap_species without evidence as Kimberly.  2025 01 31
#
# can test every minute with
# * * * * * /usr/lib/scripts/agr_upload/pap_papers/20240321_topic_entity_species/populate_species_topic_entity.pl
# updated to send emails with outreach@wormbase.org email  setting cronjob for live runs, since Kimberly signed off on this.
# 0 13 * * 6 /usr/lib/scripts/agr_upload/pap_papers/20240321_topic_entity_species/populate_species_topic_entity.pl
# 2024 09 10



# cronjob (TODO change when)
# 0 13 * * 6 /usr/lib/scripts/agr_upload/pap_papers/20240321_topic_entity_species/populate_species_topic_entity.pl


# if single json output
# ./populate_species_topic_entity.pl | json_pp

# if creating data through ABC API
# ./populate_species_topic_entity.pl


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

my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/postgres/agr_upload/pap_papers/20240321_topic_entity_species/cron_files/";
# my $outfile = $outDir . 'test_outfile';
# open (OUT, ">>$outfile") or die "Cannot append to $outfile : $!";
# print OUT qq($start_time\n);
# close (OUT) or die "Cannot close to $outfile : $!";

# my $destination = '4002';
# my $destination = 'stage';
my $destination = 'prod';

my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
if ($destination eq 'stage') {
  $baseUrl = 'https://stage-literature-rest.alliancegenome.org/'; }
if ($destination eq 'prod') {
  $baseUrl = 'https://literature-rest.alliancegenome.org/'; }

if ($ENV{ENV_STATE} ne 'prod') { die; }		# cronjob should only run from caltech prod


# my $output_format = 'json';
my $output_format = 'api';
my $tag_counter = 0;

my $logfile = ''; my $jsonfile = '';
my $simpledate = &getSimpleDate;
if ($output_format eq 'api') {
  $logfile = $outDir . 'populate_species_topic_entity.api.' . $destination . '.' . $simpledate . '.api';
  open (LOG, ">$logfile") or die "Cannot create $logfile : $!";
} else {
  $jsonfile = $outDir . 'populate_species_topic_entity.api.' . $destination . '.' . $simpledate . '.json';
  open (JSON, ">$jsonfile") or die "Cannot create $jsonfile : $!";
}

my @output_json;

my $source_error_body = '';
my $taxon_error_body = '';


my $mod = 'WB';
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
# my @wbpapers = qw( 00038491 00055090 );	# large gene set
my @wbpapers = qw( 00004952 00005199 00046571 00057043 00064676 );	# test species set

# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 
# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049

# taxon file url  https://purl.obolibrary.org/obo/ncbitaxon.obo

my %datatypesAfpCfp;
my %datatypes;
my %entitytypes;
my %wbpToAgr;

my %chosenPapers;

# my %infOther;
# my %curConf;

my %papAck;
my %papEditor;
my %papScript;
my %tfpSpecies;

# my $speciesTopic = 'ATP:0000142';	# entity
my $speciesTopic = 'ATP:0000123';	# species	# 2024 04 29
my $entityType = 'ATP:0000123';		# species
my $entity_id_validation = 'alliance';

# foreach my $joinkey (@wbpapers) { $chosenPapers{$joinkey}++; }
$chosenPapers{all}++;

# UNCOMMENT to populate
&populateAbcXref();
&populatePapSpecies();
&outputPapAck();
&outputPapScript();
&outputPapEditor();
&populateTfpSpecies();
&outputTfpSpecies();

if ($output_format eq 'json') {
  my $json = encode_json \@output_json;		# for single json file output
  print JSON qq($json\n);				# for single json file output
}

if ($output_format eq 'api') {
  close (LOG) or die "Cannot close $logfile : $!";
} else {
  close (JSON) or die "Cannot close $jsonfile : $!";
}

# foreach my $oj (@output_json) {
#   print qq(OJ $oj\n);
# } 

&sendErrorEmails();


sub outputPapAck {
  my $source_evidence_assertion = 'ATP:0000035';
  my $source_method = 'ACKnowledge_form';
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) {
    $source_error_body .= qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
#     print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %papAck) {
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    foreach my $taxon (sort keys %{ $papAck{$joinkey} }) {
      my %object;
      $object{'negated'}                    = FALSE;
      $object{'force_insertion'}            = TRUE;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $speciesTopic;
      $object{'entity_type'}                = $entityType;
      $object{'entity_id_validation'}       = $entity_id_validation;
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'entity'}                     = $taxon;
      if ($papAck{$joinkey}{$taxon}{note}) {
        $object{'note'}                     = $papAck{$joinkey}{$taxon}{note}; }
      $object{'created_by'}                 = $papAck{$joinkey}{$taxon}{curator};
      $object{'updated_by'}                 = $papAck{$joinkey}{$taxon}{curator};
      $object{'date_created'}               = $papAck{$joinkey}{$taxon}{timestamp};
      $object{'date_updated'}               = $papAck{$joinkey}{$taxon}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
} } }

sub outputPapScript {
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'script_species';
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) {
    $source_error_body .= qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
#     print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %papScript) {
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    foreach my $taxon (sort keys %{ $papScript{$joinkey} }) {
      my %object;
      $object{'negated'}                    = FALSE;
      $object{'force_insertion'}            = TRUE;
# unless ($wbpToAgr{$joinkey}) { print qq(ERROR $joinkey NOT IN wbpToAgr\n); }
# WBPaper00027303 WBPaper00027314 WBPaper00029014 WBPaper00041926   don't map to AGRKB 2024 03 19
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $speciesTopic;
      $object{'entity_type'}                = $entityType;
      $object{'entity_id_validation'}       = $entity_id_validation;
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'entity'}                     = $taxon;
      if ($papScript{$joinkey}{$taxon}{note}) {
        $object{'note'}                     = $papScript{$joinkey}{$taxon}{note}; }
      $object{'created_by'}                 = $papScript{$joinkey}{$taxon}{curator};
      $object{'updated_by'}                 = $papScript{$joinkey}{$taxon}{curator};
      $object{'date_created'}               = $papScript{$joinkey}{$taxon}{timestamp};
      $object{'date_updated'}               = $papScript{$joinkey}{$taxon}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
} } }

sub outputPapEditor {
  my $source_evidence_assertion = 'ATP:0000036';
  my $source_method = 'paper_editor_species';
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) {
    $source_error_body .= qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
#     print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %papEditor) {
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    foreach my $taxon (sort keys %{ $papEditor{$joinkey} }) {
      my %object;
      $object{'negated'}                    = FALSE;
      $object{'force_insertion'}            = TRUE;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $speciesTopic;
      $object{'entity_type'}                = $entityType;
      $object{'entity_id_validation'}       = $entity_id_validation;
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'entity'}                     = $taxon;
      if ($papEditor{$joinkey}{$taxon}{note}) {
        $object{'note'}                     = $papEditor{$joinkey}{$taxon}{note}; }
      $object{'created_by'}                 = $papEditor{$joinkey}{$taxon}{curator};
      $object{'updated_by'}                 = $papEditor{$joinkey}{$taxon}{curator};
      $object{'date_created'}               = $papEditor{$joinkey}{$taxon}{timestamp};
      $object{'date_updated'}               = $papEditor{$joinkey}{$taxon}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
} } }

sub outputTfpSpecies {
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'ACKnowledge_pipeline';
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) {
    $source_error_body .= qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
#     print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %tfpSpecies) {
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    foreach my $taxon (sort keys %{ $tfpSpecies{$joinkey} }) {
      my %object;
      $object{'negated'}                    = FALSE;
      $object{'force_insertion'}            = TRUE;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $speciesTopic;
      $object{'entity_type'}                = $entityType;
      $object{'entity_id_validation'}       = $entity_id_validation;
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'entity'}                     = $taxon;
      if ($tfpSpecies{$joinkey}{$taxon}{note}) {
        $object{'note'}                     = $tfpSpecies{$joinkey}{$taxon}{note}; }
      $object{'created_by'}                 = $tfpSpecies{$joinkey}{$taxon}{curator};
      $object{'updated_by'}                 = $tfpSpecies{$joinkey}{$taxon}{curator};
      $object{'date_created'}               = $tfpSpecies{$joinkey}{$taxon}{timestamp};
      $object{'date_updated'}               = $tfpSpecies{$joinkey}{$taxon}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
} } }


sub populatePapSpecies {
#  joinkey | pap_species | pap_order | pap_curator | pap_timestamp | pap_evidence
#   $result = $dbh->prepare( "SELECT joinkey, pap_species, pap_timestamp, pap_curator, pap_evidence FROM pap_species WHERE pap_timestamp > now() - interval '1 week'");
  $result = $dbh->prepare( "SELECT joinkey, pap_species, pap_timestamp, pap_curator, pap_evidence FROM pap_species WHERE pap_timestamp > now() - interval '2 weeks'");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey, $taxon, $ts, $two, $evi) = @row;
    $taxon = 'NCBITaxon:' . $taxon;
    $two =~ s/two/WBPerson/;
    if ($evi) { $evi =~ s/\n/ /g; $evi =~ s/ $//g; }
      else { $evi = ''; }
    if ($evi =~ m/(Manually_connected.*".*")/) {
      $papEditor{$joinkey}{$taxon}{note} = $1;
      $papEditor{$joinkey}{$taxon}{curator} = $two;
      $papEditor{$joinkey}{$taxon}{timestamp} = $ts; }
    elsif ($evi =~ m/Inferred_automatically/) { 	# this has to be more specific later
      $papAck{$joinkey}{$taxon}{curator} = $two;
      $papAck{$joinkey}{$taxon}{timestamp} = $ts; }
    elsif ( ($ts =~ m/2016-05-20/) || ($ts =~ m/2017-08-01/) || ($ts =~ m/2019-09-19/) || ($ts =~ m/2022-04-08/) ) {
      $papScript{$joinkey}{$taxon}{curator} = 'caltech_pipeline';
      $papScript{$joinkey}{$taxon}{timestamp} = $ts; }
    else {	# before 2019 02 05 pap_species didn't have evidence, so treating as if Kimberly did those manually, without a note
      $papEditor{$joinkey}{$taxon}{curator} = 'WBPerson1843';
      $papEditor{$joinkey}{$taxon}{timestamp} = $ts; }
} }

sub populateTfpSpecies {
  my %taxonNameToId;
#   $result = $dbh->prepare( "SELECT * FROM obo_name_ncbitaxonid" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) { $taxonNameToId{$row[1]} = 'NCBITaxon:' . $row[0]; }

  # Kimberly updated the pap_species_index to have all the entries it needs on caltech prod.  2024 03 22
  $result = $dbh->prepare( "SELECT * FROM pap_species_index ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    if ($row[1] && $row[0]) {
      $taxonNameToId{$row[1]} = 'NCBITaxon:' . $row[0]; } }

#   my $taxon_file = '/usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240321_topic_entity_species/ncbitaxon.obo';
#   if (-e $taxon_file) {
#     $/ = "";
#     open (IN, "<$taxon_file") or warn "Cannot open $taxon_file : $!";
#     while (my $para = <IN>) {
#       my ($id, $name) = ('', '');
#       if ($para =~ m/id: (.*)/) { $id = $1; }
#       if ($para =~ m/name: (.*)/) { $name = $1; }
#       $taxonNameToId{$name} = $id;
#     } # while (my $para = <IN>)
#     close (IN) or warn "Cannot close $taxon_file : $!";
#     $/ = "\n"; }


  my %noTaxon;
#   $result = $dbh->prepare( "SELECT joinkey, tfp_species, tfp_timestamp FROM tfp_species WHERE tfp_timestamp > now() - interval '1 week'");
  $result = $dbh->prepare( "SELECT joinkey, tfp_species, tfp_timestamp FROM tfp_species WHERE tfp_timestamp > now() - interval '2 weeks'");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey, $name, $ts) = @row;
    my (@names) = split(' \| ', $name);
    foreach my $name (@names) {
      if ($taxonNameToId{$name}) {
        $tfpSpecies{$joinkey}{$taxonNameToId{$name}}{curator} = 'ACKnowledge_pipeline';
        $tfpSpecies{$joinkey}{$taxonNameToId{$name}}{timestamp} = $ts; }
      else {
        $noTaxon{$name}++;
#         print qq(ERR $name in $joinkey not an ncbi taxon ID\n);
    } }
  }
  foreach my $taxon (sort keys %noTaxon) { 
    $taxon_error_body .= qq(NO TAXON $taxon\n);
#     print qq(NO TAXON $taxon\n);
  }
} # sub populateTfpSpecies



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
#     print qq(counter\t$tag_counter\t$date\n);
    my $now = time;
    if ($now - $start_time > 82800) {		# if 23 hours went by, update okta token
      $okta_token = &generateOktaToken();
      $start_time = $now;
    }
  }
  my $url = $baseUrl . 'topic_entity_tag/';
# PUT THIS BACK
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$object_json'`;
  print LOG qq(create $object_json\n);
  print LOG qq($api_json\n);
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

sub sendErrorEmails {
  my $user = 'populate_species_topic_entity';
#   my $email = 'azurebrd@tazendra.caltech.edu';
  my $email = 'vanauken@caltech.edu';
  my $cc = '';
  if ($source_error_body) { 
    my $subject = 'source error populate_species_topic_entity cronjob';
    my $body = $source_error_body;
    &mailSendmail($user, $email, $subject, $body, $cc);
  }
  if ($taxon_error_body) {
    my $subject = 'failed taxon mappings populate_species_topic_entity cronjob';
    my $body = $taxon_error_body;
    &mailSendmail($user, $email, $subject, $body, $cc);
  }
} # sub sendErrorEmails

sub mailSendmail {
  my ($user, $email, $subject, $body, $cc) = @_;
  if ($ENV{DEVELOPMENT} eq 'true') { $subject = '[dev] ' . $subject; }
  $email =~ s/\s+//g;
  my @recipients = split/,/, $email;
  $cc =~ s/\s+//g;
  my @cc_recipients = split/,/, $cc;
  my $smtp = Net::SMTP::SSL->new(
    'smtp.gmail.com',                       # Gmail SMTP server address
    Port => 465,                            # Gmail SMTP SSL port
#     Debug => 1,                             # Enable debugging if needed
  ) or die "Could not connect to Gmail SMTP server";

  $smtp->auth($ENV{MAILER_USERNAME}, $ENV{MAILER_PASSWORD});
  $smtp->mail($ENV{MAILER_USERNAME});
  # $smtp->to(@recipients);                     # might be an alternate way to send
  $smtp->recipient(@recipients);
  $smtp->cc(@cc_recipients);                    # don't send cc
  $smtp->data();
  $smtp->datasend("From: <$ENV{MAILER_USERNAME}> \n");
  $smtp->datasend("To: <$email> \n");
  if ($cc) { $smtp->datasend("cc: <$cc> \n"); }
  $smtp->datasend("Subject: $subject\n");
  $smtp->datasend("Content-Type: text/html; charset=iso-8859-1 \n\n");
  $smtp->datasend($body);
  $smtp->dataend();
  $smtp->quit;
} # sub mailSendmail
