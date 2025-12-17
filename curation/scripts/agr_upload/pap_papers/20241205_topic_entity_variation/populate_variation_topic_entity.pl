#!/usr/bin/env perl

# modified populate_transgene_topic_entity.pl for allele / variation data.  2024 12 05
#
# allow negative data when there is no contributor, using unknown_author  2025 06 02
#
# Populate afpContributor from pap_species and pap_gene too, even though we don't know if that help.  2025 06 04
# When reading afp variation or othervariation, always derive valid paper.  2025 06 04
#
# Commented out code for afpVersion, but variation doesn't need it.  removed timestamp requirement for tfp_ query.  2025 06 06
#
# Add data novelty but this explicitly processes afp_othervariation, so the code is different from strain and transgene, but the output should be the same.  remove novel_topic_data.
# Using UTC in timestamp queries to work with ABC timestamp API schema.  2025 11 05
#
# Additional logging of api results.
# curl is unsafe if json payload has singlequotes, updated to use LWP::UserAgent and HTTP::Request 2025 11 09
#
# No longer skip negative topics if there's afp variation data.  Instead separate data checks for separate 
# ABC data rows for dataNoveltyExisting vs dataNoveltyNewToDb based off of afpVariation and afpOthervariation
# 2025 12 01
#
# Use cognito token instead of okta.  2025 12 09
#
# note object delimiter is now linebreak.  2025 12 10
#
# note parsing to be more readable at ABC.  2025 12 17


# If reloading, drop all TET from WB sources manually (don't have an API for delete with sql), make sure it's the correct database.

# delete command
# DELETE FROM topic_entity_tag WHERE topic = 'ATP:0000285' AND topic_entity_tag_source_id IN ( SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = ( SELECT mod_id FROM mod WHERE abbreviation = 'WB' )) AND created_by != 'default_user';

# select command if wanting to check
#  SELECT * FROM topic_entity_tag WHERE topic = 'ATP:0000285' AND topic_entity_tag_source_id IN (
#    SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = (
#    SELECT mod_id FROM mod WHERE abbreviation = 'WB' ))
#    AND created_by != 'default_user';


use strict;
use diagnostics;
use DBI;
use JSON;
use LWP::UserAgent;
use HTTP::Request;
use Jex;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

use constant FALSE => \0;
use constant TRUE => \1;

my $start_time = time;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $output_format = 'json';
# my $output_format = 'api';
my $tag_counter = 0;
my $success_counter = 0;
my $exists_counter = 0;
my $unexpected_counter = 0;
my $failure_counter = 0;

my @output_json;

my $pgDate = &getPgDate();

my $mod = 'WB';
my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
# my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
# my $okta_token = &generateOktaToken();
my $cognito_token = &generateCognitoToken();

my $dataNoveltyExisting = 'ATP:0000334';        # existing data
my $dataNoveltyNewToDb =  'ATP:0000228';        # new to database

my %variation;
my %variationTaxon;

my %theHash;
my %afpToEmail;
my %emailToWbperson;
# my %afpVersion;	# afpVersion not needed, variation only has ACK
my %afpContributor;
my %afpLasttouched;
my %afpOthervariation;
my %tfpVariation;
my %afpVariation;
my %wbpToAgr;
my %papValid;
my %papMerge;
my %afpNeg;
my %ackNeg;

&populateAbcXref();
&populatePapValid();
&populatePapMerge(); 
# &populateAfpVersion();
&populateAfpContributor();
&populateAfpLasttouched();
&populateVariation();
&populateAfpEmail();
&populateEmailToWbperson();
&populateAfpVariation();
&populateAfpOthervariation();
&populateTfpVariation();

my $abc_location = 'stage';
if ($baseUrl =~ m/dev4002/) { $abc_location = '4002'; }
elsif ($baseUrl =~ m/prod/) { $abc_location = 'prod'; }

my $date = &getSimpleSecDate();
my $outfile = 'populate_variation_topic_entity.' . $date . '.' . $output_format . '.' . $abc_location;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $perrfile = 'populate_variation_topic_entity.' . $date . '.err.processing';
open (PERR, ">$perrfile") or die "Cannot create $perrfile : $!";

my $errfile = 'populate_variation_topic_entity.' . $date . '.err.' . $abc_location;
if ($output_format eq 'api') {
  open (ERR, ">$errfile") or die "Cannot create $outfile : $!";
}

&outputAfpData();
&outputTfpData();
&outputNegData();

if ($output_format eq 'json') {
  # to print to screen
  #   my $json = encode_json \@output_json;         # for single json file output
  #   print qq($json\n);                            # for single json file output
  my $json = to_json( \@output_json, { pretty => 1 } );
  print OUT qq($json);                            # for single json file output
}

if ($output_format eq 'api') {
  print OUT qq(Tags\t$tag_counter\tSuccess\t$success_counter\tExists\t$exists_counter\tUnexpected\t$unexpected_counter\tFailure\t$failure_counter\n);
  print ERR qq(Tags\t$tag_counter\tSuccess\t$success_counter\tExists\t$exists_counter\tUnexpected\t$unexpected_counter\tFailure\t$failure_counter\n);
  close (ERR) or die "Cannot close $errfile : $!";
}
close (OUT) or die "Cannot close $outfile : $!";
close (PERR) or die "Cannot close $errfile : $!";


sub populateVariation {
  my %variationToSpecies;
  my %species;
  my $result = $dbh->prepare( "SELECT * FROM obo_data_variation;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[1] =~ m/species: "(.*?)"/) {
      $species{$1}++;
      $variationToSpecies{$row[0]} = $1; } }

  my $species_string = join"', '", sort keys %species;

  my %speciesToTaxon;
  $result = $dbh->prepare( " SELECT * FROM obo_name_ncbitaxonid WHERE obo_name_ncbitaxonid IN ( '$species_string' ); " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $speciesToTaxon{$row[1]} = 'NCBITaxon:' . $row[0];
  }

  foreach my $variation (sort keys %variationToSpecies) {
    if ($speciesToTaxon{$variationToSpecies{$variation}}) { 
      $variationTaxon{"WB:$variation"} = $speciesToTaxon{$variationToSpecies{$variation}};
    }
  }
#   $result = $dbh->prepare( "SELECT trp_name, trp_species FROM trp_name, trp_species WHERE trp_name.joinkey = trp_species.joinkey;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) {
#     $trpTaxon{"WB:$row[0]"} = $speciesToTaxon{$row[1]};
#   }
} # sub populateVariation

sub populateAfpEmail {
  my $result = $dbh->prepare( "SELECT * FROM afp_email;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $afpToEmail{$row[0]} = $row[1]; 
  }
}

sub populateEmailToWbperson {
  my $result = $dbh->prepare( "SELECT * FROM two_email;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $lcemail = lc($row[2]);
    my $who = $row[0]; $who =~ s/two/WBPerson/;
    $emailToWbperson{$lcemail} = $who; 
  }
}

# sub populateAfpVersion {
#   my $result = $dbh->prepare( "SELECT joinkey, afp_version FROM afp_version" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) {
# #     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
#     next unless ($row[1]);
#     $afpVersion{$row[0]} = $row[1];
# } }

sub populateAfpContributor {
  my $result = $dbh->prepare( "SELECT joinkey, pap_curator, pap_timestamp AT TIME ZONE 'UTC' FROM pap_species WHERE pap_evidence ~ 'from author first pass'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2]; }
  $result = $dbh->prepare( "SELECT joinkey, pap_curator, pap_timestamp AT TIME ZONE 'UTC' FROM pap_gene WHERE pap_evidence ~ 'from author first pass'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2]; }
  $result = $dbh->prepare( "SELECT joinkey, afp_contributor, afp_timestamp AT TIME ZONE 'UTC' FROM afp_contributor ORDER BY afp_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2];
} }

sub populateAfpLasttouched {
  my $result = $dbh->prepare( "SELECT joinkey, afp_timestamp AT TIME ZONE 'UTC' FROM afp_lasttouched" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpLasttouched{$row[0]} = $row[1];
} }

sub deriveValidPap {
  my ($joinkey) = @_;
  if ($papValid{$joinkey}) { return $joinkey; }
    elsif ($papMerge{$joinkey}) {
      ($joinkey) = &deriveValidPap($papMerge{$joinkey});
      return $joinkey; }
    else { return 'NOTVALID'; }
} # sub deriveValidPap

sub populateTfpVariation {
  my $result = $dbh->prepare( "SELECT joinkey, tfp_variation, tfp_timestamp AT TIME ZONE 'UTC' FROM tfp_variation;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts) = @row;
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    $tfpVariation{$joinkey}{data} = $trText;
    $tfpVariation{$joinkey}{timestamp} = $ts; } }

sub populateAfpVariation {
  my $result = $dbh->prepare( "SELECT joinkey, afp_variation, afp_timestamp AT TIME ZONE 'UTC' FROM afp_variation;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $varText, $ts) = @row;
    ($joinkey) = &deriveValidPap($joinkey);
    $afpVariation{$joinkey}{data} = $varText;
    $afpVariation{$joinkey}{timestamp} = $ts;
    next unless $papValid{$joinkey};
    next unless $varText;
    my $tsdigits = &tsToDigits($ts);
    next unless ($afpLasttouched{$joinkey});
#     my (@wbvars) = $varText =~ m/(WBVar\d+)/g;
    my (@pairs) = split/ \| /, $varText;
    my @notes;
    foreach my $pair (@pairs) {
      my ($wbvar, $name) = split/;%;/, $pair;
      push @notes, "$name ( WB:$wbvar )";
    }
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
#       foreach my $wbvar (@wbvars) { # }
#         my $obj = 'WB:' . $wbvar;
    my $note = join"\n", @notes;
    foreach my $aut (@auts) {
      foreach my $pair (@pairs) {
        my ($wbvar, $name) = split(/;%;/, $pair);
        my $obj = 'WB:' . $wbvar;
        if ($afpContributor{$joinkey}{$aut}) {
          $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $afpContributor{$joinkey}{$aut}; }
        else {
          $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp} = $ts; }
        $theHash{'ack'}{$joinkey}{$obj}{$aut}{name} = $name;
        $theHash{'ack'}{$joinkey}{$obj}{$aut}{note} = $note;  # there can be only one entry for a given paper afp_variation
#         my $note = $varText; $note =~ s/;%;/; /g;
#         push @{ $theHash{'ack'}{$joinkey}{$obj}{$aut}{note} }, $note;
    } }
  }
} # sub populateAfpVariation

sub populateAfpOthervariation {
  my $result = $dbh->prepare( "SELECT joinkey, afp_othervariation, afp_timestamp AT TIME ZONE 'UTC' FROM afp_othervariation" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey) = &deriveValidPap($row[0]);
    next unless $papValid{$joinkey};
    next unless ($afpLasttouched{$joinkey});
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
    foreach my $aut (@auts) {
      my (@names) = $row[1] =~ m/"name":"(.*?)"/g;
      my $note = join"\n", @names;
      $afpOthervariation{$joinkey}{$aut}{note} = $note;
      $afpOthervariation{$joinkey}{$aut}{data} = $row[1];
      $afpOthervariation{$joinkey}{$aut}{timestamp} = $row[2]; }
} }


sub outputNegData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider\n);
    return;
  }

  $source_evidence_assertion = 'ATP:0000035';
  $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_ack) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider\n);
    return;
  }

  # This is negative ack data where author removed something that tfp said
  foreach my $joinkey (sort keys %tfpVariation) {
    next unless ($afpLasttouched{$joinkey});	# must be a final author submission
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
    my $data = $tfpVariation{$joinkey}{data};
    if ($data) {				# there is tfp variation data
      my (@wbvars) = $data =~ m/(WBVar\d+)/g;
      if ($theHash{'ack'}{$joinkey}) {		# negative ack entity
        my $data = $tfpVariation{$joinkey}{data};
        my (@pairs) = split/ \| /, $data;
        foreach my $pair (@pairs) {
          my ($wbvar, $name) = split(/;%;/, $pair);
          my $obj = 'WB:' . $wbvar;
          unless ($theHash{'ack'}{$joinkey}{$obj}) {
            foreach my $aut (@auts) {
              my %object;
              $object{'topic_entity_tag_source_id'}   = $source_id_ack;
              $object{'force_insertion'}              = TRUE;
              $object{'negated'}                      = TRUE;
              $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#               $object{'wbpaper_id'}                   = $joinkey;		# for debugging
#               $object{'NEGATIVE ACK ENTITY'}          = $joinkey;		# for debugging
              $object{'data_novelty'}                 = $dataNoveltyExisting;
              my $ts = $theHash{'ack'}{$joinkey}{$obj}{$aut}{timestamp};
              if ( $afpContributor{$joinkey}{$aut} ) { $ts = $afpContributor{$joinkey}{$aut}; }
              $object{'date_updated'}		  = $ts;
              $object{'date_created'}		  = $ts;
              $object{'created_by'}                   = $aut;
              $object{'updated_by'}                   = $aut;
              $object{'topic'}                        = 'ATP:0000285';
              $object{'entity_type'}                  = 'ATP:0000285';
              $object{'entity_id_validation'}         = 'alliance';
              $object{'entity'}                       = $obj;
              $object{'entity_published_as'}       = $name;
              if ($variationTaxon{$obj}) { 	    # if there's a variation taxon, go with that value instead of default
                $object{'species'}                    = $variationTaxon{$obj}; }
              else {
                print PERR qq(ERROR no taxon for WBPaper$joinkey Variation $obj\n);
                next; }
              if ($output_format eq 'json') {
                push @output_json, \%object; }
              else {
                my $object_json = encode_json \%object;
                &createTag($object_json); }
    } } } } }
    else {						# there is no tfp variation data
      my %object;
      $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
      $object{'force_insertion'}              = TRUE;
      $object{'negated'}                      = TRUE;
      $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#       $object{'wbpaper_id'}                   = $joinkey;		# for debugging
#       $object{'NEGATIVE TFP TOPIC'}           = $joinkey;		# for debugging
      $object{'data_novelty'}                 = $dataNoveltyExisting;
      $object{'date_updated'}		      = $tfpVariation{$joinkey}{timestamp};
      $object{'date_created'}		      = $tfpVariation{$joinkey}{timestamp};
      $object{'created_by'}                   = 'ACKnowledge_pipeline';
      $object{'updated_by'}                   = 'ACKnowledge_pipeline';
      $object{'topic'}                        = 'ATP:0000285';
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
    }
  } # foreach my $joinkey (sort keys %tfpVariation)

  # This is negative acknowledge author topic
  foreach my $joinkey (sort keys %afpLasttouched) {
    # next unless ($afpContributor{$joinkey});	# explicitly okay to have submissions with unknown author
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
    foreach my $aut (@auts) {
      # separate data checks for separate ABC data rows for dataNoveltyExisting vs dataNoveltyNewToDb based off of afpVariation and afpOthervariation
      unless ($afpVariation{$joinkey}{data}) {	# author did not sent afpVariation, so create negative topic for existing data
        my %object;
        $object{'topic_entity_tag_source_id'}   = $source_id_ack;
        $object{'force_insertion'}              = TRUE;
        $object{'negated'}                      = TRUE;
        $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#         $object{'wbpaper_id'}                   = $joinkey;		# for debugging
#         $object{'NEGATIVE ACK TOPIC EXISTING'}  = $joinkey;		# for debugging
        $object{'data_novelty'}                 = $dataNoveltyExisting;
        my $ts = $afpContributor{$joinkey}{$aut};
        $object{'date_updated'}		  = $ts;
        $object{'date_created'}		  = $ts;
        $object{'created_by'}                   = $aut;
        $object{'updated_by'}                   = $aut;
        $object{'topic'}                        = 'ATP:0000285';
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); } }
      if ($afpOthervariation{$joinkey}{$aut}{data} eq '[{"id":1,"name":""}]') {	# author did not send other variation, so create negative topic for new data
        my %object;
        $object{'topic_entity_tag_source_id'}   = $source_id_ack;
        $object{'force_insertion'}              = TRUE;
        $object{'negated'}                      = TRUE;
        $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#         $object{'wbpaper_id'}                   = $joinkey;		# for debugging
#         $object{'NEGATIVE ACK TOPIC NEW TO DB'} = $joinkey;		# for debugging
        $object{'data_novelty'}                 = $dataNoveltyNewToDb;
        my $ts = $afpContributor{$joinkey}{$aut};
        $object{'date_updated'}		  = $ts;
        $object{'date_created'}		  = $ts;
        $object{'created_by'}                   = $aut;
        $object{'updated_by'}                   = $aut;
        $object{'topic'}                        = 'ATP:0000285';
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); } } }
  }
} # sub outputNegData

sub outputTfpData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider\n);
    return;
  }
  foreach my $joinkey (sort keys %tfpVariation) {
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my $data = $tfpVariation{$joinkey}{data};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = FALSE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;		# for debugging
    $object{'data_novelty'}                 = $dataNoveltyExisting;
    $object{'date_updated'}		    = $tfpVariation{$joinkey}{timestamp};
    $object{'date_created'}		    = $tfpVariation{$joinkey}{timestamp};
    $object{'created_by'}                   = 'ACKnowledge_pipeline';
    $object{'updated_by'}                   = 'ACKnowledge_pipeline';
    $object{'topic'}                        = 'ATP:0000285';
    if ($data eq '') {
      $object{'negated'}                    = TRUE;
#       $object{'BLAH'}                       = 'TFP neg';
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); } }
    else {
#       my (@wbvars) = $data =~ m/(WBVar\d+)/g;
#       foreach my $wbvar (@wbvars) {
      my (@pairs) = split/ \| /, $data;
      foreach my $pair (@pairs) {
        my ($wbvar, $name) = split(/;%;/, $pair);
        my $obj = 'WB:' . $wbvar;
#         $object{'BLAH'}                      = 'TFP yes';
        $object{'entity_type'}               = 'ATP:0000285';
        $object{'entity_id_validation'}      = 'alliance';
        $object{'entity'}                    = $obj;
        $object{'entity_published_as'}       = $name;
        if ($variationTaxon{$obj}) { 	    # if there's a variation taxon, go with that value instead of default
          $object{'species'}                 = $variationTaxon{$obj}; }
        else {
          print PERR qq(ERROR no taxon for WBPaper$joinkey Variation $obj\n);
          next; }
        if ($output_format eq 'json') {
          push @output_json, { %object }; }
        else {
          my $object_json = encode_json { %object };
          &createTag($object_json); }
    } }
  }

} # sub outputTfpData

sub outputAfpData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ATP:0000035';
  my $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);

  unless ($source_id_ack) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider\n);
    return;
  }

  foreach my $datatype (sort keys %theHash) {
    foreach my $joinkey (sort keys %{ $theHash{$datatype} }) {
      unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
#       next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
      foreach my $obj (sort keys %{ $theHash{$datatype}{$joinkey} }) {
        foreach my $curator (sort keys %{ $theHash{$datatype}{$joinkey}{$obj} }) {
          my %object;
          $object{'topic_entity_tag_source_id'}   = $source_id_ack;
          $object{'force_insertion'}              = TRUE;
          $object{'negated'}                      = FALSE;
          $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#           $object{'wbpaper_id'}                   = $joinkey;		# for debugging
          $object{'data_novelty'}                 = $dataNoveltyExisting;
          $object{'topic'}                        = 'ATP:0000285';
          $object{'entity_type'}                  = 'ATP:0000285';
          $object{'entity_id_validation'}         = 'alliance';
          $object{'entity'}                       = $obj;
          $object{'entity_published_as'}          = $theHash{$datatype}{$joinkey}{$obj}{$curator}{name};
          if ($variationTaxon{$obj}) { 			# if there's a variation taxon, go with that value instead of default
            $object{'species'}                    = $variationTaxon{$obj}; }
          else {
            print PERR qq(ERROR no taxon for WBPaper$joinkey Variation $obj\n);
            next; }
          if ($theHash{$datatype}{$joinkey}{$obj}{$curator}{note}) {
            $object{'note'}                     = $theHash{$datatype}{$joinkey}{$obj}{$curator}{note}; }
          $object{'created_by'}                 = $curator;
          $object{'updated_by'}                 = $curator;
          $object{'date_created'}               = $theHash{$datatype}{$joinkey}{$obj}{$curator}{timestamp};
          $object{'date_updated'}               = $theHash{$datatype}{$joinkey}{$obj}{$curator}{timestamp};
          if ($output_format eq 'json') {
            push @output_json, \%object; }
          else {
            my $object_json = encode_json \%object;
            &createTag($object_json); }
  } } } }

  foreach my $joinkey (sort keys %afpOthervariation) {
    foreach my $curator (sort keys %{ $afpOthervariation{$joinkey} }) {
      next if ($afpOthervariation{$joinkey}{$curator}{data} eq '[{"id":1,"name":""}]');
      my %object;
      $object{'topic_entity_tag_source_id'}   = $source_id_ack;
      $object{'force_insertion'}              = TRUE;
#       $object{'novel_topic_data'}             = TRUE;
      $object{'negated'}                      = FALSE;
      $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#       $object{'wbpaper_id'}                   = $joinkey;		# for debugging
#       $object{'AFP OTHER VARIATION POSITIVE TOPIC'}                   = $joinkey;		# for debugging
      $object{'data_novelty'}                 = $dataNoveltyNewToDb;
      $object{'topic'}                        = 'ATP:0000285';
      if ($afpOthervariation{$joinkey}{$curator}{note}) {
        $object{'note'}                     = $afpOthervariation{$joinkey}{$curator}{note}; }
      $object{'created_by'}                 = $curator;
      $object{'updated_by'}                 = $curator;
      $object{'date_created'}               = $afpOthervariation{$joinkey}{$curator}{timestamp};
      $object{'date_updated'}               = $afpOthervariation{$joinkey}{$curator}{timestamp};
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); } }
  } # foreach my $joinkey (sort keys %afpOthervariation)
} # sub outputAfpData


sub tsToDigits {
  my $timestamp = shift;
  my $tsdigits = '';
  if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { $tsdigits = $1 . $2 . $3; }
  return $tsdigits;
}

sub generateCognitoToken {
  my $cognito_result = `curl -X POST "$ENV{COGNITO_TOKEN_URL}" \ -H "Content-Type: application/x-www-form-urlencoded" \ -d "grant_type=client_credentials" \ -d "client_id=$ENV{COGNITO_ADMIN_CLIENT_ID}" \ -d "client_secret=$ENV{COGNITO_ADMIN_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $cognito_result;
  my $cognito_token = $$hash_ref{'access_token'};
#   print $cognito_token;
  return $cognito_token;
}

sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}

sub createTag {
  my ($object_json) = @_;
  $tag_counter++;
  if ($tag_counter % 1000 == 0) {
    my $date = &getSimpleSecDate();
    print qq(counter\t$tag_counter\t$date\n);
    my $now = time;
    if ($now - $start_time > 82800) {           # if 23 hours went by, update cognito token
      $cognito_token = &generateCognitoToken();
      $start_time = $now;
    }
  }
  my $url = $baseUrl . 'topic_entity_tag/';

  my $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new(POST => $url);
  $req->header('accept' => 'application/json');
  $req->header('Authorization' => "Bearer $cognito_token");
  $req->header('Content-Type' => 'application/json');
  $req->content($object_json);
  my $res = $ua->request($req);

  print OUT qq(create $object_json\n);
  my $api_json = $res->decoded_content;
  print OUT qq($api_json\n);
  if ($res->is_success) {
    if ($api_json =~ /"status":"success"/) {
      $success_counter++;
    }
    elsif ($api_json =~ /"status":"exists"/) {
      $exists_counter++;
      print ERR qq(create $object_json\n);
      print ERR qq($api_json\n);
    }
    else {
      $unexpected_counter++;
      print ERR qq(create $object_json\n);
      print ERR qq($api_json\n);
    }
  } else {
    $failure_counter++;
    print ERR qq(HTTP Error: $res->status_line\n);
  }
}

sub getSourceId {
  my ($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_evidence_assertion . '/' . $source_method . '/' . $data_provider . '/' . $secondary_data_provider;
#   my ($source_type, $source_method) = @_;
#   my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
  # print qq($url\n);
  my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $cognito_token' -H 'Content-Type: application/json'`;
  my $hash_ref = decode_json $api_json;
  if ($$hash_ref{'topic_entity_tag_source_id'}) {
    my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
    # print qq($source_id\n);
    return $source_id; }
  else { return ''; }
}

sub populatePapValid {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    $papValid{$row[0]}++; }
}

sub populatePapMerge {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^[0-9]{8}\$';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    $papMerge{$row[1]} = $row[0]; }
}

sub populateAbcXref {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'AGRKB';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $wbpToAgr{$row[0]} = $row[1]; }
} # sub populateAbcXref


