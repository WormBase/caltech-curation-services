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


# if single json output
# ./dump_classifier_topic_entity.pl | json_pp

# if creating data through ABC API
# ./dump_classifier_topic_entity.pl


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
my @wbpapers = qw( 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049 );

# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 
# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049

my %datatypesAfpCfp;
my %datatypes;
my %entitytypes;
my %wbpToAgr;

my %chosenPapers;

foreach my $joinkey (@wbpapers) { $chosenPapers{$joinkey}++; }
# $chosenPapers{all}++;

&populateDatatypesAndABC();


my %speciesToTaxon;
$result = $dbh->prepare( "SELECT * FROM obo_name_ncbitaxonid WHERE joinkey IN (SELECT DISTINCT(pap_species) FROM pap_species) " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $speciesToTaxon{$row[1]} = $row[0]; }

my %premadeComments;
&populatePremadeComments();



my $errfile = 'dump_classifier_topic_entity.err';
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my %strData;
my %svmData;
my %nncData;
my %curData;
my %cfpData;
my %tfpData;
my %afpContributor;
my %afpLasttouched;
my %afpAutData;
my %afpCurData;
my %oaData;
my %objsCurated;


# PUT THIS BACK
# &populateCurCurData();
# &outputCurCurData();
# &populateCurSvmData();
# &outputCurSvmData();
# &populateCurNncData();
# &outputCurNncData();
# &populateCurStrData();
# &outputCurStrData();
# &populateCfpData();
# &outputCfpData();
# &populateTfpData();
# &outputTfpData();
# &populateAfpData();
# &outputAfpAutData();
# &outputAfpCurData();
# &populateOaData();



if ($output_format eq 'json') {
  my $json = encode_json \@output_json;		# for single json file output
  print qq($json\n);				# for single json file output
}

close (ERR) or die "Cannot close $errfile : $!";


sub outputAfpCurData {
  my $source_type = 'professional_biocurator';
  my $source_method = 'afp';
  my $source_id = &getSourceId($source_type, $source_method);
  unless ($source_id) {
    print qq(ERROR no source_id for $source_type and $source_method);
    return;
  }
#   { "source_type": "professional_biocurator", "source_method": "wormbase_curation_status", "evidence": "eco_string", "description": "cur_curdata", "mod_abbreviation": "WB" }
  foreach my $datatype (sort keys %afpCurData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for afpCurData $datatype\n); 
      next;
    }
    foreach my $joinkey (sort keys %{ $afpCurData{$datatype} }) {
      my $negated = FALSE;
      if ($afpCurData{$datatype}{$joinkey}{negated}) { $negated = TRUE; }
      my %object;
      $object{'negated'}                    = $negated;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = $afpCurData{$datatype}{$joinkey}{curator};
      $object{'updated_by'}                 = $afpCurData{$datatype}{$joinkey}{curator};
      $object{'date_created'}               = $afpCurData{$datatype}{$joinkey}{timestamp};
      $object{'date_updated'}               = $afpCurData{$datatype}{$joinkey}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
} } }

sub outputAfpAutData {
  my $source_type   = 'author';
  my $source_method_ack = 'ACKnowledge';
  my $source_method_afp = 'afp';
  my $source_id_ack = &getSourceId($source_type, $source_method_ack);
  my $source_id_afp = &getSourceId($source_type, $source_method_afp);
  unless ($source_id_ack) {
    print qq(ERROR no source_id for $source_type and $source_method_ack);
    return;
  }
  unless ($source_id_afp) {
    print qq(ERROR no source_id for $source_type and $source_method_afp);
    return;
  }
#   { "source_type": "professional_biocurator", "source_method": "wormbase_curation_status", "evidence": "eco_string", "description": "cur_curdata", "mod_abbreviation": "WB" }
  foreach my $datatype (sort keys %afpAutData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for afpAutData $datatype\n); 
      next;
    }
    foreach my $joinkey (sort keys %{ $afpAutData{$datatype} }) {
      my @auts;
      if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
      if (scalar @auts < 1) { push @auts, 'default_user'; }
      foreach my $aut (@auts) {
        my %object;
        my $negated = FALSE;
        if ($afpAutData{$datatype}{$joinkey}{negated}) { $negated = TRUE; }
        my $source_id = $source_id_afp;
        if ($afpAutData{$datatype}{$joinkey}{source} eq 'ack') { $source_id = $source_id_ack; }
        if ($afpAutData{$datatype}{$joinkey}{note}) {
          $object{'note'}                     = $afpAutData{$datatype}{$joinkey}{note}; }
        $object{'negated'}                    = $negated;
        $object{'reference_curie'}            = $wbpToAgr{$joinkey};
        $object{'topic'}                      = $datatypes{$datatype};
        $object{'topic_entity_tag_source_id'} = $source_id;
        $object{'created_by'}                 = $aut;
        $object{'updated_by'}                 = $aut;
        $object{'date_created'}               = $afpAutData{$datatype}{$joinkey}{timestamp};
        $object{'date_updated'}               = $afpAutData{$datatype}{$joinkey}{timestamp};
        # $object{'datatype'}                 = $datatype;		# for debugging
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); }
} } } }


sub populateAfpData {
  &populateTfpData();
  &populateAfpContributor();
  &populateAfpLasttouched();
  foreach my $datatype (sort keys %datatypesAfpCfp) {
    $result = $dbh->prepare( "SELECT joinkey, afp_$datatypesAfpCfp{$datatype}, afp_timestamp AT TIME ZONE 'UTC', afp_curator, afp_approve, afp_cur_timestamp AT TIME ZONE 'UTC' FROM afp_$datatypesAfpCfp{$datatype}" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
      my $data = ''; my $negated = 0;
      if ($row[1]) { $data = $row[1]; }
        elsif ($tfpData{$datatype}{$row[0]}{data}) { $negated = 1; }
        else { next; }						# skip entry if no author data and no tfp_ data.
      # my $row = join"\t", @row;
      # print qq($datatype\tafp_$datatypesAfpCfp{$datatype}\t$row\n);
      my $tsdigits = &tsToDigits($row[2]);
      $data =~ s/
      if ($tsdigits < '20190322') { 
        $afpAutData{$datatype}{$row[0]}{note}      = $data;
        $afpAutData{$datatype}{$row[0]}{negated}   = 0;		# there was no tfp_ data to validate old afp
        $afpAutData{$datatype}{$row[0]}{source}    = 'afp';
        $afpAutData{$datatype}{$row[0]}{timestamp} = $row[2]; }
      else {
        $afpAutData{$datatype}{$row[0]}{note}      = $data;  
        $afpAutData{$datatype}{$row[0]}{negated}   = $negated;
        $afpAutData{$datatype}{$row[0]}{source}    = 'ack';
        $afpAutData{$datatype}{$row[0]}{timestamp} = $row[2]; }
      if ($row[3]) {
        my $curator = $row[3]; $curator =~ s/two/WBPerson/;
        my $negated = 0;
        if ($row[4] eq 'rejected') { $negated = 1; }
        $afpCurData{$datatype}{$row[0]}{curator}   = $curator;
        $afpCurData{$datatype}{$row[0]}{negated}   = $negated;
        $afpCurData{$datatype}{$row[0]}{timestamp} = $row[5]; }
} } }

sub populateAfpContributor {
  $result = $dbh->prepare( "SELECT joinkey, afp_contributor FROM afp_contributor" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who}++;
} }

sub populateAfpLasttouched {
  $result = $dbh->prepare( "SELECT * FROM afp_lasttouched" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $afpLasttouched{$row[0]} = $row[1]; } }

sub populateTfpData {
  return if (%tfpData);		# this called for generating tfpdata but also for afpdata, but don't need to read it twice if already has data
  foreach my $datatype (sort keys %datatypesAfpCfp) {
    $result = $dbh->prepare( "SELECT joinkey, tfp_$datatypesAfpCfp{$datatype}, tfp_timestamp FROM tfp_$datatypesAfpCfp{$datatype}" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
      next unless ($row[1]);
      $row[1] =~ s/
      $tfpData{$datatype}{$row[0]}{data} = $row[1];
      $tfpData{$datatype}{$row[0]}{timestamp} = $row[2];
} } }

sub outputTfpData {
  my $source_type = 'acknowledge_pipeline';
  foreach my $datatype (sort keys %tfpData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for cur_tfpdata $datatype\n); 
      next;
    }
    my $source_method = 'ACKnowledge';
    my $source_id = &getSourceId($source_type, $source_method);
    unless ($source_id) {
      print qq(ERROR no source_id for $source_type and $source_method);
      return;
    }
    foreach my $joinkey (sort keys %{ $tfpData{$datatype} }) {
      my %object;
      my $negated = FALSE;  
      $object{'negated'}                    = $negated;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = 'default_user';
      $object{'updated_by'}                 = 'default_user';
      $object{'date_created'}               = $tfpData{$datatype}{$joinkey}{timestamp};
      $object{'date_updated'}               = $tfpData{$datatype}{$joinkey}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}


# sub populateAfpData_CURATION_STATUS {
#   foreach my $datatype (sort keys %chosenDatatypes) {
#     next unless $datatypesAfpCfp{$datatype};
#     my $pgtable_datatype = $datatypesAfpCfp{$datatype};
#     $result = $dbh->prepare( "SELECT * FROM afp_$pgtable_datatype" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     while (my @row = $result->fetchrow) {
#       next unless ($curatablePapers{$row[0]});
#       $afpData{$datatype}{$row[0]} = $row[1]; }
#   } # foreach my $datatype (sort keys %chosenDatatypes)
# 
#   $result = $dbh->prepare( "SELECT * FROM afp_email" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) {
#     next unless ($curatablePapers{$row[0]});
#     $afpEmailed{$row[0]}++; }
#   $result = $dbh->prepare( "SELECT * FROM afp_lasttouched" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) {
#     next unless ($curatablePapers{$row[0]});
#     foreach my $datatype (sort keys %chosenDatatypes) {
#       $afpFlagged{$datatype}{$row[0]}++; } }
#   foreach my $datatype (sort keys %chosenDatatypes) {
#     foreach my $joinkey (sort keys %{ $afpFlagged{$datatype} }) {
#       if ($afpData{$datatype}{$joinkey}) { $afpPos{$datatype}{$joinkey}++; }
#         else { $afpNeg{$datatype}{$joinkey}++; } } }
# } # sub populateAfpData_CURATION_STATUS



sub outputCfpData {
  my $source_type = 'professional_biocurator';
  my $source_method = 'cfp';
  my $source_id = &getSourceId($source_type, $source_method);
  unless ($source_id) {
    print qq(ERROR no source_id for $source_type and $source_method);
    return;
  }
#   { "source_type": "professional_biocurator", "source_method": "wormbase_curation_status", "evidence": "eco_string", "description": "cur_curdata", "mod_abbreviation": "WB" }
  foreach my $datatype (sort keys %cfpData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for cfpData $datatype\n); 
      next;
    }
    foreach my $joinkey (sort keys %{ $cfpData{$datatype} }) {
      my $negated = FALSE;
      if ($cfpData{$datatype}{$joinkey}{data}) {
        if ($cfpData{$datatype}{$joinkey}{data} =~ m/false positive/i) { $negated = TRUE; } }
      my %object;
      $object{'negated'}                    = $negated;
      $object{'note'}                       = $cfpData{$datatype}{$joinkey}{data};
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = $cfpData{$datatype}{$joinkey}{curator};
      $object{'updated_by'}                 = $cfpData{$datatype}{$joinkey}{curator};
      $object{'date_created'}               = $cfpData{$datatype}{$joinkey}{timestamp};
      $object{'date_updated'}               = $cfpData{$datatype}{$joinkey}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub populateCfpData {
  foreach my $datatype (sort keys %datatypesAfpCfp) {
    $result = $dbh->prepare( "SELECT joinkey, cfp_$datatypesAfpCfp{$datatype}, cfp_curator, cfp_timestamp AT TIME ZONE 'UTC' FROM cfp_$datatypesAfpCfp{$datatype}" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
      next unless ($row[2]);
      my $curator = $row[2]; $curator =~ s/two/WBPerson/;
      $row[1] =~ s/
      $cfpData{$datatype}{$row[0]}{data} = $row[1];
      $cfpData{$datatype}{$row[0]}{curator} = $curator;
      $cfpData{$datatype}{$row[0]}{timestamp} = $row[3];
#       my $row = join"\t", @row;
#       print qq($datatype\tcfp_$datatypesAfpCfp{$datatype}\t$row\n);
} } }


sub outputCurStrData {
  my $source_type = 'string_matching';
  foreach my $datatype (sort keys %strData) {
    unless ($datatype eq 'antibody') {
      print ERR qq(Only allowed string type is antibody, no $datatype\n); 
      next;
    }
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for cur_strdata $datatype\n); 
      next;
    }
    my $source_method = 'script_antibody_data';
    my $source_id = &getSourceId($source_type, $source_method);
    unless ($source_id) {
      print qq(ERROR no source_id for $source_type and $source_method);
      return;
    }
    # only data for 1 source exists, everything has date after 2019 03 22
    # my $source_method_2 = 'script_antibody_data_2';
    # my $source_id_2 = &getSourceId($source_type, $source_method_2);
    # unless ($source_id_2) {
    #   print qq(ERROR no source_id for $source_type and $source_method_2);
    #   return;
    # }
    foreach my $joinkey (sort keys %{ $strData{$datatype} }) {
      my %object;
      # my $source_id = $source_id_1;
      # my $tsdigits = &tsToDigits($strData{$datatype}{$joinkey}{timestamp});
      # if ($tsdigits > '20190322') { $source_id = $source_id_2; }
      $object{'negated'}                    = FALSE;
      $object{'note'}                       = $strData{$datatype}{$joinkey}{result};
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = 'default_user';
      $object{'updated_by'}                 = 'default_user';
      $object{'date_created'}               = $strData{$datatype}{$joinkey}{timestamp};
      $object{'date_updated'}               = $strData{$datatype}{$joinkey}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub populateCurStrData {
  $result = $dbh->prepare( "SELECT cur_paper, cur_datatype, cur_date, cur_strdata, cur_version, cur_timestamp AT TIME ZONE 'UTC' FROM cur_strdata ORDER BY cur_timestamp" );     # in case multiple values get in for a paper-datatype (shouldn't happen), keep the latest
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $row[3] =~ s/
    $strData{$row[1]}{$row[0]}{date}       = $row[2];
    $strData{$row[1]}{$row[0]}{result}     = $row[3];
    $strData{$row[1]}{$row[0]}{version}    = $row[4];
    $strData{$row[1]}{$row[0]}{timestamp}  = $row[5]; }
} # sub populateCurStrData


sub outputCurNncData {
  my $source_type = 'neural_network';
  foreach my $datatype (sort keys %nncData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for cur_nncdata $datatype\n); 
      next;
    }
    my $source_method = 'nnc_' . $datatype;
    my $source_id = &getSourceId($source_type, $source_method);
    unless ($source_id) {
      print qq(ERROR no source_id for $source_type and $source_method);
      return;
    }
    foreach my $joinkey (sort keys %{ $nncData{$datatype} }) {
      my %object;
      my $negated = FALSE;  
      if ($nncData{$datatype}{$joinkey}{result} eq 'NEG') { $negated = TRUE; }
      $object{'negated'}                    = $negated;
      $object{'confidence_level'}           = $nncData{$datatype}{$joinkey}{result};
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = 'default_user';
      $object{'updated_by'}                 = 'default_user';
      $object{'date_created'}               = $nncData{$datatype}{$joinkey}{date};
      $object{'date_updated'}               = $nncData{$datatype}{$joinkey}{date};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub populateCurNncData {
  $result = $dbh->prepare( "SELECT cur_paper, cur_datatype, cur_date, cur_nncdata, cur_timestamp AT TIME ZONE 'UTC' FROM cur_nncdata ORDER BY cur_timestamp" );     # in case multiple values get in for a paper-datatype (shouldn't happen), keep the latest
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $row[3] =~ s/
    my $date = $row[5];
    if ($row[2] =~ m/^(\d{4})(\d{2})(\d{2})$/) {
        my ($year, $mon, $day) = $row[2] =~ m/^(\d{4})(\d{2})(\d{2})$/;
        $date = $year . '-' . $mon . '-' . $day . ' 00:00:01'; }
      else { print qq(NO DATE @row\n); }
    $nncData{$row[1]}{$row[0]}{date}       = $date;
    $nncData{$row[1]}{$row[0]}{result}     = $row[3];
    $nncData{$row[1]}{$row[0]}{timestamp}  = $row[4]; }
} # sub populateCurNncData


sub outputCurSvmData {
  my $source_type = 'support_vector_machine';
  foreach my $datatype (sort keys %svmData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for cur_svmdata $datatype\n); 
      next;
    }
    my $source_method = 'svm_' . $datatype;
    my $source_id = &getSourceId($source_type, $source_method);
    unless ($source_id) {
      print qq(ERROR no source_id for $source_type and $source_method);
      return;
    }
    foreach my $joinkey (sort keys %{ $svmData{$datatype} }) {
      my %object;
      my $negated = FALSE;  
      if ($svmData{$datatype}{$joinkey}{result} eq 'NEG') { $negated = TRUE; }
      $object{'negated'}                    = $negated;
      $object{'confidence_level'}           = $svmData{$datatype}{$joinkey}{result};
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = 'default_user';
      $object{'updated_by'}                 = 'default_user';
      $object{'date_created'}               = $svmData{$datatype}{$joinkey}{date};
      $object{'date_updated'}               = $svmData{$datatype}{$joinkey}{date};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub populateCurSvmData {
  $result = $dbh->prepare( "SELECT cur_paper, cur_datatype, cur_date, cur_svmdata, cur_version, cur_timestamp AT TIME ZONE 'UTC' FROM cur_svmdata ORDER BY cur_timestamp" );     # in case multiple values get in for a paper-datatype (shouldn't happen), keep the latest
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $row[3] =~ s/
    my $date = $row[5];
    if ($row[2] =~ m/^(\d{4})(\d{2})(\d{2})$/) {
        my ($year, $mon, $day) = $row[2] =~ m/^(\d{4})(\d{2})(\d{2})$/;
        $date = $year . '-' . $mon . '-' . $day . ' 00:00:01'; }
      else { print qq(NO DATE @row\n); }
    $svmData{$row[1]}{$row[0]}{date}       = $date;
    $svmData{$row[1]}{$row[0]}{result}     = $row[3];
    $svmData{$row[1]}{$row[0]}{version}    = $row[4];
    $svmData{$row[1]}{$row[0]}{timestamp}  = $row[5]; }
} # sub populateCurSvmData


sub outputCurCurData {
  my $source_type = 'professional_biocurator';
  my $source_method = 'wormbase_curation_status';
  my $source_id = &getSourceId($source_type, $source_method);
  unless ($source_id) {
    print qq(ERROR no source_id for $source_type and $source_method);
    return;
  }
#   { "source_type": "professional_biocurator", "source_method": "wormbase_curation_status", "evidence": "eco_string", "description": "cur_curdata", "mod_abbreviation": "WB" }
  foreach my $datatype (sort keys %curData) {
    unless ($datatypes{$datatype}) { 
      print ERR qq(no topic for cur_curdata $datatype\n); 
      next;
    }
    foreach my $joinkey (sort keys %{ $curData{$datatype} }) {
# next unless ($joinkey eq '00005199');	# selcomment + txtcomment
# next unless ($joinkey eq '00037049');	# timestamp with timezone to utc different date 2018-06-27 17:31:33.510441-07 -> 2018-06-28 00:31:33.510441
      my %object;
      my $negated = FALSE;  
      if ($curData{$datatype}{$joinkey}{donposneg} eq 'negative') { $negated = TRUE; }
      my @notes; my $note = undef;
      if ($curData{$datatype}{$joinkey}{selcomment}) { push @notes, $premadeComments{$curData{$datatype}{$joinkey}{selcomment}}; }
      if ($curData{$datatype}{$joinkey}{txtcomment}) { push @notes, $curData{$datatype}{$joinkey}{txtcomment}; }
      if (scalar @notes > 1) { $note = join "|", @notes; }
      $object{'negated'}                    = $negated;
      $object{'note'}                       = $note;
      $object{'reference_curie'}            = $wbpToAgr{$joinkey};
      $object{'topic'}                      = $datatypes{$datatype};
      $object{'topic_entity_tag_source_id'} = $source_id;
      $object{'created_by'}                 = $curData{$datatype}{$joinkey}{curator};
      $object{'updated_by'}                 = $curData{$datatype}{$joinkey}{curator};
      $object{'date_created'}               = $curData{$datatype}{$joinkey}{timestamp};
      $object{'date_updated'}               = $curData{$datatype}{$joinkey}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }
}

sub populateCurCurData {
  my $datatypeSource = 'caltech';
#   $result = $dbh->prepare( "SELECT * FROM cur_curdata WHERE cur_site = '$datatypeSource' ORDER BY cur_timestamp" );     # in case multiple values get in for a paper-datatype (shouldn't happen), keep the latest
  $result = $dbh->prepare( "SELECT cur_paper, cur_datatype, cur_site, cur_curator, cur_curdata, cur_selcomment, cur_txtcomment, cur_timestamp AT TIME ZONE 'UTC' FROM cur_curdata WHERE cur_site = '$datatypeSource' ORDER BY cur_timestamp" );     # in case multiple values get in for a paper-datatype (shouldn't happen), keep the latest
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
#     next unless ($chosenDatatypes{$row[1]});
    next if ( ($row[4] eq 'notvalidated') || ($row[4] eq '') );                                         # skip entries marked as notvalidated
# next unless ($row[0] eq '00005199');
# print qq(@row\n);
    $row[6] =~ s/
    my $curator = $row[3]; $curator =~ s/two/WBPerson/;
    $curData{$row[1]}{$row[0]}{site}       = $row[2];
    $curData{$row[1]}{$row[0]}{curator}    = $curator;
    $curData{$row[1]}{$row[0]}{donposneg}  = $row[4];
    $curData{$row[1]}{$row[0]}{selcomment} = $row[5];
    $curData{$row[1]}{$row[0]}{txtcomment} = $row[6];
# print qq($row[5] $row[6]\n);
    $curData{$row[1]}{$row[0]}{timestamp}  = $row[7]; }
} # sub populateCurCurData


sub getSourceId {
  my ($source_type, $source_method) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
#   print qq($url\n);
  my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'`;
  my $hash_ref = decode_json $api_json;
  my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
  if ($$hash_ref{'topic_entity_tag_source_id'}) {
    my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
    # print qq($source_id\n);
    return $source_id; }
  else { return ''; }
#   print qq($source_id\n);
}

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

sub populatePremadeComments {
  $premadeComments{"1"}  = "SVM Positive, Curation Negative";
  $premadeComments{"2"}  = "C. elegans as heterologous expression system";
  $premadeComments{"3"}  = "Curated for GO (by WB)";
  $premadeComments{"4"}  = "Curated for GO (by GOA)";
  $premadeComments{"5"}  = "Curated for GO (by IntAct)";
  $premadeComments{"6"}  = "Curated for BioGRID (by WB)";
  $premadeComments{"7"}  = "Curated for BioGRID (by BG)";
  $premadeComments{"8"}  = "Curated for GO (by WB), Curated for BioGRID (by WB)";
  $premadeComments{"9"}  = "Curated for GO (by WB), Curated for BioGRID (by BG)";
  $premadeComments{"10"} = "Curated for GO (by GOA), Curated for BioGRID (by WB)";
  $premadeComments{"11"} = "Curated for GO (by GOA), Curated for BioGRID (by BG)";
  $premadeComments{"12"} = "Curated for GO (by IntAct), Curated for BioGRID (by WB)";
  $premadeComments{"13"} = "Curated for GO (by IntAct), Curated for BioGRID (by BG)";
  $premadeComments{"14"} = "Curation Negative, no Strain name given in paper";
  $premadeComments{"15"} = "Toxicology";
  $premadeComments{"16"} = "Host-pathogen/virulence";
  $premadeComments{"17"} = "Disease model";
  $premadeComments{"18"} = "Non-genetic disease model";
  $premadeComments{"19"} = "Genetic disease model";
} # sub populatePremadeComments

sub populateDatatypesAndABC {
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
  
  $entitytypes{'species'}          = 'ATP:0000123';
  $entitytypes{'gene'}             = 'ATP:0000047';
  $entitytypes{'variation'}        = 'ATP:0000030';
  $entitytypes{'transgene'}        = 'ATP:0000099';
  $entitytypes{'chemical'}         = 'ATP:0000094';
  $entitytypes{'antibody'}         = 'ATP:0000096';

#   &populateAbcXrefSample();
# PUT THIS BACK, but change to read from db
  &populateAbcXref();
} # sub populateDatatypesAndABC

sub populateAbcXref {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'AGRKB';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 	# only molecules with papers are curated
  while (my @row = $result->fetchrow) { 
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $wbpToAgr{$row[0]} = $row[1]; }
} # sub populateAbcXref

sub populateAbcXrefFlatfile {
  # generated by get_pap_identifier_agrkb.pl  but make sure to get newest xrefs from correct ABC db first, then run it to update file.
  my $infile = 'files/wb_abc';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($wb, $agr) = split/\t/, $line;
    $wbpToAgr{$wb} = $agr;
  }
  close (IN) or die "Cannot close $infile : $!";
} # sub populateAbcXrefFlatfile

sub populateAbcXrefSample {
  $wbpToAgr{'00004952'} = 'AGRKB:101000000618370';
  $wbpToAgr{'00005199'} = 'AGRKB:101000000618566';
  $wbpToAgr{'00026609'} = 'AGRKB:101000000620861';
  $wbpToAgr{'00030933'} = 'AGRKB:101000000622619';
  $wbpToAgr{'00035427'} = 'AGRKB:101000000624596';
  $wbpToAgr{'00046571'} = 'AGRKB:101000000630958';
  $wbpToAgr{'00057043'} = 'AGRKB:101000000390100';
  $wbpToAgr{'00064676'} = 'AGRKB:101000000947815';
  $wbpToAgr{'00037049'} = 'AGRKB:101000000625405';
}

sub populateOaData {
  my %chosenDatatypes;
  foreach my $datatype (sort keys %datatypesAfpCfp) { $chosenDatatypes{$datatype}++; }

  if ($chosenDatatypes{'chemicals'}) {
      # there are 5 source for curated molecules, and 7 sources for papers related to curated molecules, from Karen 2013 11 02
    $result = $dbh->prepare( "SELECT * FROM mop_name WHERE joinkey IN (SELECT joinkey FROM mop_paper WHERE mop_paper IS NOT NULL AND mop_paper != '')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 	# only molecules with papers are curated
    while (my @row = $result->fetchrow) { $objsCurated{'chemicals'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM app_molecule WHERE joinkey NOT IN (SELECT joinkey FROM app_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my (@chemicals) = $row[1] =~ m/(WBMol:\d+)/g;
      foreach my $chemical (@chemicals) { $objsCurated{'chemicals'}{$chemical}++; } }
    $result = $dbh->prepare( "SELECT * FROM grg_moleculeregulator" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my (@chemicals) = $row[1] =~ m/(WBMol:\d+)/g;
      foreach my $chemical (@chemicals) { $objsCurated{'chemicals'}{$chemical}++; } }
    $result = $dbh->prepare( "SELECT * FROM pro_molecule" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my (@chemicals) = $row[1] =~ m/(WBMol:\d+)/g;
      foreach my $chemical (@chemicals) { $objsCurated{'chemicals'}{$chemical}++; } }
    $result = $dbh->prepare( "SELECT * FROM rna_molecule WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my (@chemicals) = $row[1] =~ m/(WBMol:\d+)/g;
      foreach my $chemical (@chemicals) { $objsCurated{'chemicals'}{$chemical}++; } }

    $result = $dbh->prepare( "SELECT * FROM mop_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'chemicals'}{$paper} = 'curated'; } }
    $result = $dbh->prepare( "SELECT * FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_molecule WHERE app_molecule IS NOT NULL AND app_molecule != '')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'chemicals'}{$paper} = 'curated'; } }
    $result = $dbh->prepare( "SELECT * FROM grg_paper WHERE joinkey IN (SELECT joinkey FROM grg_moleculeregulator WHERE grg_moleculeregulator IS NOT NULL AND grg_moleculeregulator != '')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'chemicals'}{$paper} = 'curated'; } }
    $result = $dbh->prepare( "SELECT * FROM pro_paper WHERE joinkey IN (SELECT joinkey FROM pro_molecule WHERE pro_molecule IS NOT NULL AND pro_molecule != '')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'chemicals'}{$paper} = 'curated'; } }
    $result = $dbh->prepare( "SELECT * FROM rna_paper WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey IN (SELECT joinkey FROM rna_molecule WHERE rna_molecule IS NOT NULL AND rna_molecule != '')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'chemicals'}{$paper} = 'curated'; } }
    $result = $dbh->prepare( "SELECT * FROM int_paper WHERE joinkey IN (SELECT joinkey FROM int_moleculeone WHERE int_moleculeone IS NOT NULL) OR joinkey IN (SELECT joinkey FROM int_moleculetwo WHERE int_moleculetwo IS NOT NULL) OR joinkey IN (SELECT joinkey FROM int_moleculenondir WHERE int_moleculenondir IS NOT NULL)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'chemicals'}{$paper} = 'curated'; } }
  } # if ($chosenDatatypes{'chemicals'})

  if ($chosenDatatypes{'newmutant'}) {
    $result = $dbh->prepare( "SELECT * FROM app_variation WHERE joinkey NOT IN (SELECT joinkey FROM app_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'newmutant'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM app_paper WHERE joinkey NOT IN (SELECT joinkey FROM app_needsreview) AND joinkey NOT IN (SELECT joinkey FROM app_curator WHERE app_curator = 'WBPerson29819') AND joinkey NOT IN (SELECT joinkey FROM app_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'newmutant'}{$paper} = 'curated'; } } }
  if ($chosenDatatypes{'overexpr'}) {
    $result = $dbh->prepare( "SELECT * FROM app_transgene WHERE joinkey NOT IN (SELECT joinkey FROM app_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'overexpr'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_transgene WHERE app_transgene IS NOT NULL AND app_transgene != '') AND joinkey NOT IN (SELECT joinkey FROM app_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'overexpr'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'antibody'}) {
    $result = $dbh->prepare( "SELECT * FROM abp_name" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'antibody'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM abp_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'antibody'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'otherexpr'}) {
    $result = $dbh->prepare( "SELECT * FROM exp_name WHERE joinkey NOT IN (SELECT joinkey FROM exp_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'otherexpr'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM exp_paper WHERE joinkey NOT IN (SELECT joinkey FROM exp_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'otherexpr'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'humandisease'}) {
    $result = $dbh->prepare( "SELECT * FROM dis_wbgene" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'humandisease'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM dis_paperdisrel" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'humandisease'}{$paper} = 'curated'; } }
    $result = $dbh->prepare( "SELECT * FROM dis_paperexpmod" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'humandisease'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'seqfeature'}) {
    $result = $dbh->prepare( "SELECT * FROM sqf_name" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'seqfeature'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM sqf_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'seqfeature'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'genereg'}) {
    $result = $dbh->prepare( "SELECT * FROM grg_intid WHERE joinkey NOT IN (SELECT joinkey FROM grg_nodump)" );	# genereg object counts were coming from grg_name instead of grg_intid.  2015 02 04
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'genereg'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM grg_paper WHERE joinkey NOT IN (SELECT joinkey FROM grg_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'genereg'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'geneint'}) {	# corresponds to int_type being genetic, meaning not physical nor predicted 2015 04 02
    my %int;
    $result = $dbh->prepare( "SELECT * FROM int_name;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $int{'name'}{$row[0]} = $row[1]; }
    $result = $dbh->prepare( "SELECT * FROM int_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $int{'paper'}{$row[0]} = $row[1]; }
    $result = $dbh->prepare( "SELECT * FROM int_type" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $int{'type'}{$row[0]} = $row[1]; }
    $result = $dbh->prepare( "SELECT * FROM int_nodump" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $int{'nodump'}{$row[0]} = $row[1]; }
    my %typeSkip; 
    $typeSkip{"Physical"}++;
    $typeSkip{"ProteinProtein"}++;
    $typeSkip{"ProteinDNA"}++;
    $typeSkip{"ProteinRNA"}++;
    $typeSkip{"Predicted"}++;
    foreach my $joinkey (sort keys %{ $int{'name'} }) {
      next unless $int{'type'}{$joinkey};
      next if ($typeSkip{$int{'type'}{$joinkey}});
      next if ($int{'nodump'}{$joinkey});
      $objsCurated{'geneint'}{$int{'name'}{$joinkey}}++; 
      if ($int{'paper'}{$joinkey}) {
        my (@papers) = $int{'paper'}{$joinkey} =~ m/WBPaper(\d+)/g;
        foreach my $paper (@papers) {
          $oaData{'geneint'}{$paper} = 'curated'; } } } }

  if ($chosenDatatypes{'geneprod'}) {	# corresponds to int_type being physical.  2015 04 02
    $result = $dbh->prepare( "SELECT * FROM int_name WHERE joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical' OR int_type = 'ProteinProtein' OR int_type = 'ProteinDNA' OR int_type = 'ProteinRNA') AND joinkey NOT IN (SELECT joinkey FROM int_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'geneprod'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM int_paper WHERE joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical' OR int_type = 'ProteinProtein' OR int_type = 'ProteinDNA' OR int_type = 'ProteinRNA') AND joinkey NOT IN (SELECT joinkey FROM int_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'geneprod'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'rnai'}) {
    $result = $dbh->prepare( "SELECT * FROM rna_name WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump)" );
#     $result = $dbh->prepare( "SELECT * FROM rna_name WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey NOT IN (SELECT joinkey FROM rna_fromgenereg)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'rnai'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM rna_paper WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey NOT IN (SELECT joinkey FROM rna_curator WHERE rna_curator = 'WBPerson29819')" );
#     $result = $dbh->prepare( "SELECT * FROM rna_paper WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey NOT IN (SELECT joinkey FROM rna_fromgenereg)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'rnai'}{$paper} = 'curated'; } } }


    # these are not in the OA but they're in postgres, so are here
  if ($chosenDatatypes{'picture'}) {
    $result = $dbh->prepare( "SELECT * FROM pic_name WHERE joinkey NOT IN (SELECT joinkey FROM pic_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'picture'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM pic_paper WHERE joinkey NOT IN (SELECT joinkey FROM pic_nodump)" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'picture'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'blastomere'}) {
    $result = $dbh->prepare( "SELECT * FROM wbb_wbbtf WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Blastomere_isolation')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'blastomere'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Blastomere_isolation')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'blastomere'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'exprmosaic'}) {
    $result = $dbh->prepare( "SELECT * FROM wbb_wbbtf WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Expression_mosaic')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'exprmosaic'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Expression_mosaic')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'exprmosaic'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'geneticablation'}) {
    $result = $dbh->prepare( "SELECT * FROM wbb_wbbtf WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Genetic_ablation')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'geneticablation'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Genetic_ablation')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'geneticablation'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'geneticmosaic'}) {
    $result = $dbh->prepare( "SELECT * FROM wbb_wbbtf WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Genetic_mosaic')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'geneticmosaic'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Genetic_mosaic')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'geneticmosaic'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'optogenetic'}) {
    $result = $dbh->prepare( "SELECT * FROM wbb_wbbtf WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Optogenetic')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'optogenetic'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Optogenetic')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'optogenetic'}{$paper} = 'curated'; } } }

  if ($chosenDatatypes{'laserablation'}) {
    $result = $dbh->prepare( "SELECT * FROM wbb_wbbtf WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Laser_ablation')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $objsCurated{'laserablation'}{$row[1]}++; }
    $result = $dbh->prepare( "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Laser_ablation')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'laserablation'}{$paper} = 'curated'; } } }
} # sub populateOaData

__END__
# SELECT cur_selcomment, COUNT(cur_selcomment) FROM cur_curdata GROUP BY cur_selcomment ORDER BY COUNT(cur_selcomment) DESC;
#   $premadeComments{"15"} = "Toxicology";
#   $premadeComments{"16"} = "Host-pathogen/virulence";
#   $premadeComments{"17"} = "Disease model";
#   $premadeComments{"18"} = "Non-genetic disease model";
#   $premadeComments{"19"} = "Genetic disease model";






# my @topic_types = qw( nnc svm afp cfp 
# my %exists;
# foreach my $datatype (sort keys %datatypes) {

my %confidence_to_atp;
$confidence_to_atp{'high'} = 'ATP:0000119';
$confidence_to_atp{'medium'} = 'ATP:0000120';
$confidence_to_atp{'low'} = 'ATP:0000121';
$confidence_to_atp{'neg'} = undef;

my %curdata_to_validated;
$curdata_to_validated{'curated'} = TRUE;
$curdata_to_validated{'positive'} = TRUE;
$curdata_to_validated{'negative'} = FALSE;
$curdata_to_validated{'notvalidated'} = undef;

my %geneToTaxon;
my %varToTaxon;

# Kimberly, we have the same source ECO for different flagging sources, and I don't think we can do that, so tacking on _nnc or whatever for now.  created_by is not an option for source in the API, so we'll need to talk to Valerio about how to enter that and whether we need to.  Only antibody has string data.  What's something that's flagged as negative from ACKnowledge/afp/cfp ?  I thought everything with a value was considered positive.  The curation status form looks whether there's a cfp_curator for a paper, and considers that flagged, then if a datatype for that paper has data it's positive, and if it doesn't it's negative, for the purposes for the big table where you can see percentages, but it's not really true negative data, it's extrapolated, and it can be wrong if a paper was flagged before a datatype was added to the flagging form (made up example: if a paper was flagged in 2005 and blastomeres were added to the form in 2015).  Do you want actual positive data only, or extrapolated negatives too.  If there's a value that the forms use that means negative, we can get that.

foreach my $joinkey (@wbpapers) {
  # topics
# UNCOMMENT THIS LATER
#   foreach my $datatype (sort keys %datatypes) {
#     my %object;
#     my $topic = $datatypes{$datatype};
#     my $source = 'ECO:0000000';
#     my $reference_curie = $wbpToAgr{$joinkey};
#     $object{'reference_curie'} = $wbpToAgr{$joinkey};
#     $object{'topic'} = $datatypes{$datatype};
#     if ($datatypesAfpCfp{$datatype}) {
#       $result = $dbh->prepare( "SELECT * FROM cfp_$datatypesAfpCfp{$datatype} WHERE joinkey = '$joinkey'" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) {
#         if ($row[0]) { 
#           my %source;
#           $source{'source'} = $source . '_cfp';
#           $source{'confidence_level'} = undef;
#           $source{'validation_type'} = 'manual';
#           $source{'validated'} = TRUE;	# not sure we can extrapolate false if cfp_curator but not cfp_$datatype
#           $source{'note'} = $row[1];
#           $source{'mod_abbreviation'} = 'WB';
#           push @{ $object{'sources'} }, \%source;
#           print qq(cfp $datatype $row[0] $row[1]\n);
#         } # if ($row[0])
#       } # while (@row = $result->fetchrow)
#       $result = $dbh->prepare( "SELECT * FROM afp_$datatypesAfpCfp{$datatype} WHERE joinkey = '$joinkey'" );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) {
#         if ($row[0]) { 
#           my %source;
#           $source{'source'} = $source . '_afp';
#           $source{'confidence_level'} = undef;
#           $source{'validation_type'} = 'manual';
#           $source{'validated'} = TRUE;	# not sure we can extrapolate false if afp_curator but not afp_$datatype
#           $source{'note'} = $row[1];
#           $source{'mod_abbreviation'} = 'WB';
#           push @{ $object{'sources'} }, \%source;
#           print qq(afp $datatype $row[0] $row[1]\n);
#         } # if ($row[0])
#       } # while (@row = $result->fetchrow)
#     } # if ($datatypesAfpCfp{$datatype})
#     $result = $dbh->prepare( "SELECT * FROM cur_curdata WHERE cur_datatype = '$datatype' AND cur_paper = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my %source;
#         $source{'source'} = $source . '_cur';
#         $source{'confidence_level'} = undef;
#         $source{'validation_type'} = 'manual';
#         $source{'validated'} = $curdata_to_validated{$row[4]};
#         if ($row[6]) { $source{'note'} = $row[6]; }
#           else { $source{'note'} = undef; }
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         print qq(cur $datatype $row[0] $row[4]\n);
#       } # if ($row[0])
#     } # while (@row = $result->fetchrow)
#     $result = $dbh->prepare( "SELECT * FROM cur_svmdata WHERE cur_datatype = '$datatype' AND cur_paper = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my %source;
#         $source{'source'} = $source . '_svm';
#         $source{'confidence_level'} = $confidence_to_atp{lc($row[3])};
# # This might be wrong, check Valerio/Kimberly
# #         $source{'validation_type'} = undef;
# #         $source{'validated'} = undef;
#         $source{'validation_type'} = 'svm';
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         print qq(svm $datatype $row[0] $row[3]\n);
#       } # if ($row[0])
#     } # while (@row = $result->fetchrow)
#     $result = $dbh->prepare( "SELECT * FROM cur_nncdata WHERE cur_datatype = '$datatype' AND cur_paper = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my %source;
#         $source{'source'} = $source . '_nnc';
#         $source{'confidence_level'} = $confidence_to_atp{lc($row[3])};
# # This might be wrong, check Valerio/Kimberly
# #         $source{'validation_type'} = undef;
# #         $source{'validated'} = undef;
#         $source{'validation_type'} = 'nnc';
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         print qq(nnc $datatype $row[0] $row[3]\n);
#       } # if ($row[0])
#     } # while (@row = $result->fetchrow)
#     if ($object{'sources'} && (scalar @{ $object{'sources'} } > 0)) {
#       my $json = encode_json \%object;
#       print qq($json\n); }
#   } # foreach my $datatype (sort keys %datatypes)

# my %entitytypes;
# $entitytypes{'species'}          = 'ATP:0000123';
# $entitytypes{'gene'}             = 'ATP:0000047';
# $entitytypes{'variation'}        = 'ATP:0000030';
# $entitytypes{'transgene'}        = 'ATP:0000099';
# $entitytypes{'chemical'}         = 'ATP:0000094';
# $entitytypes{'antibody'}         = 'ATP:0000096';
  # entities

#     my %object;
#     my $topic = 'ATP:0000142';
#     my $source = 'ECO:0000000';
#     my $reference_curie = $wbpToAgr{$joinkey};
#     $object{'reference_curie'} = $reference_curie;
#     $object{'topic'} = $topic;
#     $object{'entity_source'} = 'alliance';

    # TO FIX different rows in postgres could have the same paper-gene but different pap_evidence, each of which will create a source with the same data, which ABC won't allow
    # duplicate key value violates unique constraint \"source_topic_entity_tag_unique\"\nDETAIL:  Key (topic_entity_tag_id, mod_id, source)=(232, 2, ECO:0000000_pap_species) already exists.

    # TODO  extract tfp_species, map its data to a taxon and if joinkey+taxon match, create a source
#     my %agr_species;
#     $result = $dbh->prepare( "SELECT * FROM pap_species WHERE joinkey = '$joinkey'" );
#     print qq( SELECT * FROM pap_species WHERE joinkey = '$joinkey';\n );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         print qq(ROW @row\n);
#         my $entity = 'NCBITaxon:' . $row[1];
#         # my $entity_type = $entitytypes{'species'};
#         # my $species = 'NCBITaxon:' . $row[1];
#         # my $negated = FALSE;
#         my %source = ();
#         $source{'mod_abbreviation'} = 'WB';
#         $source{'confidence_level'} = undef;
#         if ($row[5]) {
#           if ($row[5] =~ m/Curator_confirmed.*(WBPerson\d+)/) {
#             # $source{'created_by'} = $1;
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0000302';
#             # $source{'source_detail'} = undef;
#             $source{'source'} = 'curator';
#             $source{'negated'} = FALSE;
#             # push @{ $object{'sources'} }, \%source;
#             push @{ $agr_species{$entity} }, \%source;
#           }
#           elsif ($row[5] =~ m/Inferred_automatically/) {
#             # $source{'created_by'} = $1;	# get from afp_contributor, loop separate source for each two#
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0000302';
#             # $source{'source_detail'} = 'ACKnowledge';
#             $source{'source'} = 'author';
#             $source{'negated'} = FALSE;
#             # push @{ $object{'sources'} }, \%source;
#             push @{ $agr_species{$entity} }, \%source;
#           }
#           elsif ($row[5] eq '') {
#             print qq(NO EVI\n);
#             # $source{'created_by'} = ???
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0007669';
#             # $source{'source_detail'} = 'string match to title, abstract, and gene-species association';
#             $source{'source'} = 'caltech script';
#             $source{'negated'} = FALSE;
#             # push @{ $object{'sources'} }, \%source;
#             push @{ $agr_species{$entity} }, \%source;
#     } } } }
#     foreach my $entity (sort keys %agr_species) {
#       my %object;
#       my $topic = 'ATP:0000142';
#       my $source = 'ECO:0000000';
#       my $reference_curie = $wbpToAgr{$joinkey};
#       $object{'reference_curie'} = $reference_curie;
#       $object{'topic'} = $topic;
#       $object{'entity_source'} = 'alliance';
#       $object{'entity'} = $entity;
#       $object{'entity_type'} = $entitytypes{'species'};
#       $object{'species'} = $entity;
#       if ($agr_species{$entity} && (scalar @{ $agr_species{$entity} } > 0)) {
#         foreach my $source_href (@{ $agr_species{$entity} }) {
#           push @{ $object{'sources'} }, $source_href; }
#         my $json = encode_json \%object;
#         print qq($json\n);
#         # $object{'sources'} = ();
#         # print qq(PAP_SPECIES\t);
#     } }

#     $result = $dbh->prepare( "SELECT * FROM pap_species WHERE joinkey = '$joinkey'" );
#     print qq( SELECT * FROM pap_species WHERE joinkey = '$joinkey';\n );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         print qq(ROW @row\n);
#         $object{'entity'} = 'NCBITaxon:' . $row[1];
#         $object{'entity_type'} = $entitytypes{'species'};
#         $object{'species'} = 'NCBITaxon:' . $row[1];
#         my %source = ();
#         $source{'mod_abbreviation'} = 'WB';
#         $source{'confidence_level'} = undef;
#         if ($row[5]) {
#           if ($row[5] =~ m/Curator_confirmed.*(WBPerson\d+)/) {
#             # $source{'created_by'} = $1;
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0000302';
#             # $source{'source_detail'} = undef;
#             $source{'source'} = 'curator';
#             $source{'negated'} = FALSE;
#             push @{ $object{'sources'} }, \%source; }
#           elsif ($row[5] =~ m/Inferred_automatically/) {
#             # $source{'created_by'} = $1;	# get from afp_contributor, loop separate source for each two#
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0000302';
#             # $source{'source_detail'} = 'ACKnowledge';
#             $source{'source'} = 'author';
#             $source{'negated'} = FALSE;
#             push @{ $object{'sources'} }, \%source; }
#           elsif ($row[5] eq '') {
#             print qq(NO EVI\n);
#             # $source{'created_by'} = ???
#             # $source{'date_created'} = $row[4];
#             # $source{'eco_source'} = 'ECO:0007669';
#             # $source{'source_detail'} = 'string match to title, abstract, and gene-species association';
#             $source{'source'} = 'caltech script';
#             $source{'negated'} = FALSE;
#             push @{ $object{'sources'} }, \%source; }
#         }
            
        
#         $source{'source'} = $source . '_pap_species';
#         $source{'confidence_level'} = undef;
#         $source{'validation_type'} = undef;
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         if ($row[5]) {
#           $source{'validation_type'} = 'manual';
#           $source{'validated'} = TRUE; }
#         push @{ $object{'sources'} }, \%source;

#         my $json = encode_json \%object;
#         $object{'sources'} = ();
#         # print qq(PAP_SPECIES\t);
#         print qq($json\n);
#     } }

# PUT THIS BACK
#     $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE joinkey = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my $gene = 'WB:WBGene' . $row[1];
#         my $taxon = '';
#         if ($geneToTaxon{$row[1]}) { $taxon = $geneToTaxon{$row[1]}; }
#           else {
#             my $result2 = $dbh->prepare( "SELECT * FROM gin_species WHERE joinkey = '$row[1]'" );
#             $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#             my @row2 = $result2->fetchrow();
#             my $species = $row2[1];
#             $geneToTaxon{$row[1]} = 'NCBITaxon:' . $speciesToTaxon{$species};
#             $taxon = 'NCBITaxon:' . $speciesToTaxon{$species}; }
#         $object{'entity'} = $gene;
#         $object{'entity_type'} = $entitytypes{'gene'};
#         $object{'species'} = $taxon;
#         my %source = ();
#         $source{'source'} = $source . '_pap_gene';
#         $source{'confidence_level'} = undef;
#         $source{'validation_type'} = undef;
#         $source{'validated'} = FALSE;
#         $source{'note'} = undef;
#         if ($row[5]) {
#           my $source = 'ECO:0008008';
#           if ( ($row[5] =~ m/Manually_connected/) || ($row[5] =~ m/Published_as/) || ($row[5] =~ m/Person_evidence/) ||
#                ($row[5] =~ m/Curator_confirmed/) || ($row[5] =~ m/Author_evidence/) ) { $source = 'manual'; }
#             elsif ( $row[5] =~ m/Inferred_automatically/) {
#               if ( ($row[5] =~ m/from curator first pass/) || ($row[5] =~ m/from author first pass/) ) { $source = 'manual'; } }
#           if ($source eq 'manual') {
#             $source{'validation_type'} = 'manual';
#             $source{'validated'} = TRUE; }
#           else {
#             $source{'source'} = $source; } }
#         $source{'mod_abbreviation'} = 'WB';
#         push @{ $object{'sources'} }, \%source;
#         my $json = encode_json \%object;
#         $object{'sources'} = ();
#         print qq(PAP_GENE\t);
#         print qq($json\n);
#     } }
# 
#     $result = $dbh->prepare( "SELECT * FROM afp_variation WHERE joinkey = '$joinkey'" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         my (@wbvar) = $row[1] =~ m/(WBVar\d+)/;
#         foreach my $wbvar (@wbvar) {
#           my $taxon = '';
#           if ($varToTaxon{$row[1]}) { $taxon = $varToTaxon{$row[1]}; }
#             else {
#               my $result2 = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE joinkey = '$row[1]'" );
#               $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#               my @row2 = $result2->fetchrow();
#               my ($species) = $row2[1] =~ m/species: "(.*)"/;
#               $varToTaxon{$row[1]} = 'NCBITaxon:' . $speciesToTaxon{$species};
#               $taxon = 'NCBITaxon:' . $speciesToTaxon{$species}; }
#           $object{'entity'} = 'WB:' . $wbvar;
#           $object{'entity_type'} = $entitytypes{'variation'};
#           $object{'species'} = $taxon;
#     } } }
} # foreach my $joinkey (@wbpapers)


__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';


