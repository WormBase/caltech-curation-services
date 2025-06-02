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
#
# Derive merged papers from pap_identifier.  2024 07 26
#
# Output tfp positive data.  If no species or taxon for gene, output to processing log.  Have standardized
# processing logs and api error logs.  2024 10 16
#
# No longer output negative tfp data when ack author has positive gene entities and tfp didn't find it.  2024 11 21
#
# One source was wrong from copy-paste.  2024 11 22
#
# Added another set of negative data, from stuff that is curation done, but doesn't have pap gene.  2024 12 05
#
# Decided not to have negative tfp entities when author says something and tfp doesn't.
# Compared negative gene processing to negative variation processing and made gene like variation.
# Add afp_lasttouched for some skip logic in negative data.  2025 01 31
#
# Outputting tfp data, do not skip if there is no contributor, using unknown_author.  2025 06 02



# If reloading, drop all TET from WB sources manually (don't have an API for delete with sql), make sure it's the correct database.

# delete command
# DELETE FROM topic_entity_tag WHERE topic = 'ATP:0000005' AND topic_entity_tag_source_id IN ( SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = ( SELECT mod_id FROM mod WHERE abbreviation = 'WB' ));

# select command if wanting to check
# SELECT * FROM topic_entity_tag WHERE topic = 'ATP:0000005' AND topic_entity_tag_source_id IN (
#   SELECT topic_entity_tag_source_id FROM topic_entity_tag_source WHERE secondary_data_provider_id = (
#   SELECT mod_id FROM mod WHERE abbreviation = 'WB' ));


# Run like
# ./populate_gene_topic_entity.pl



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
my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
# my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
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
# my @wbpapers = qw( 00003000 );		# cfp
# my @wbpapers = qw( 00006103 );		# inferred auto note
# my @wbpapers = qw( 00005988 );		# abstract2acePMID
# my @wbpapers = qw( 00013393 );		# abstract2aceCGC
# my @wbpapers = qw( 00024745 );		# abstract2ace other
# my @wbpapers = qw( 00006103 );		# fix_dead_genes
# my @wbpapers = qw( 00000119 );		# geneChecker
# my @wbpapers = qw( 00003000 );		# update2_gene_cds_script
# my @wbpapers = qw( 00006103 );		# update_oldwbgenes_papers_script
# my @wbpapers = qw( 00038491 );		# Table S1 sheet B
# my @wbpapers = qw( 00000465 );		# update_of_dead_and_merged_genes_Mary_Ann
# my @wbpapers = qw( 00018874 );		# automatic_update_merge_script
# my @wbpapers = qw( 00044280 );		# briggsae genes
# my @wbpapers = qw( 00003000 00003823 00004455 00004952 00005199 00005707 00006103 00006202 00006320 00017095 00018874 00025176 00027230 00044280 00046571 00057043 00063127 00064676 00064771 00065877 00066211 );		# kimberly 2024 04 18 set
# my @wbpapers = qw( 00000119 00000465 00003000 00003823 00004455 00004952 00005199 00005707 00005988 00006103 00006202 00006320 00013393 00017095 00024745 00025176 00027230 00038491 00044280 00046571 00057043 00063127 00064676 00064771 00065877 00066211 );		# kimberly 2024 05 13 set
# my @wbpapers = qw( 00065553 00065560 00066296 00066355 00066405 00066410 00066411 00066419 00066461 00066469 00066891 00066862 00066767 00053843 );	# kimberly negative gene set  2024 10 02
my @wbpapers = qw( 00065553 00065560 00066296 00066355 00066405 00066410 00066411 00066419 00066461 00066469 00066891 00066862 00066767 00053843 00004452 00017615 00005440 00005870 00006533 00025104 00027167 );	# kimberly negative gene set  2025 02 07

# ( '00065553', '00065560', '00066296', '00066355', '00066405', '00066410', '00066411', '00066419', '00066461', '00066469' );	# kimberly negative gene set  2024 10 02

# my @wbpapers = qw( 00065560 );	# sample paper that has multiple entries in API for WB:WBGene00004796 AGRKB:101000000965217 because the gene showed as both a gene name and a sequence name

# my @wbpapers = qw( 00065560 );	# sample paper where author removed tfp data

# my @wbpapers = qw( 00066891 00066862 00066767	)	# tfp negative
# SELECT * FROM tfp_genestudied WHERE tfp_genestudied = '' AND tfp_timestamp > '2019-03-22 00:00' AND joinkey IN ( '00066891', '00066862', '00066767' );

# my @wbpapers = qw( 00053843 );	# added by the author not found by ACKnowledge pipeline, i.e. tfp_genestudied does not have the value but afp_genestudied does.

# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 
# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049

my %datatypesAfpCfp;
my %datatypes;
my %entitytypes;
my %wbpToAgr;
my %papValid;
my %papMerge;
my %meetings;
my %geneToTaxon;
my %manConn;
my %papGenePublished;
my %tfpGene;
my %gin;
my %speciesToTaxon;


my %chosenPapers;
my %ginValidation;
# my %ginTaxon;

my %theHash;
my %infOther;
my %curConfMan;
my %curConfNoMan;
my %perEvi;
my %noEvi;
my %cfp;
my %afp;
my %ack;
my %absReadMeet;
my %absReadNoMeet;
my %afpContributor;
my %afpLasttouched;
my %ackPapGene;
my %tfpPapGene;
my %ackNegGeneTopic;
my %tfpNegGeneTopic;
my %curNegGeneTopic;

my $abc_location = 'stage';
if ($baseUrl =~ m/dev4002/) { $abc_location = '4002'; }
elsif ($baseUrl =~ m/prod/) { $abc_location = 'prod'; }

my $date = &getSimpleSecDate();
my $outfile = 'populate_gene_topic_entity.' . $date . '.' . $output_format . '.' . $abc_location;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $perrfile = 'populate_gene_topic_entity.' . $date . '.err.processing';
open (PERR, ">$perrfile") or die "Cannot create $perrfile : $!";

my $errfile = 'populate_gene_topic_entity.' . $date . '.err.' . $abc_location;
if ($output_format eq 'api') {
  open (ERR, ">$errfile") or die "Cannot create $outfile : $!";
}

# my $geneTopic = 'ATP:0000142';
my $geneTopic = 'ATP:0000005';
my $entityType = 'ATP:0000005';

foreach my $joinkey (@wbpapers) { $chosenPapers{$joinkey}++; }
# $chosenPapers{all}++;


&populateAbcXref();
&populatePapValid();
&populatePapMerge();
&populateMeetings();
&populateGeneTaxon();
&populatePapGene();
&populateGinValidation();
&populateGinTaxon();
&populateAfpContributor();
&populateAfpLasttouched();
&populateTfpGenestudied();
&populateNegativeData();

# PUT THIS BACK
&outputTfpData();
&outputTheHash();
&outputNegativeData();

if ($output_format eq 'json') {
  my $json = to_json( \@output_json, { pretty => 1 } );
  print OUT qq($json\n);				# for single json file output
}

close (OUT) or die "Cannot close $outfile : $!";
if ($output_format eq 'api') {
  close (ERR) or die "Cannot close $errfile : $!";
}
close (PERR) or die "Cannot close $perrfile : $!";

# foreach my $oj (@output_json) {
#   print qq(OJ $oj\n);
# } 


sub outputTheHash {
  # my $source_type = 'script';
  # my $source_method = 'gene_paper_association_script';
  # my $source_id = &getSourceId($source_type, $source_method);

  my %datatypeToSourceId;

  foreach my $datatype (sort keys %theHash) {
    my $source_evidence_assertion = 'ECO:0008021';
    my $source_method = 'paper_editor_genes_script';
    my $data_provider = $mod;
    my $secondary_data_provider = $mod;
    if ($datatype eq 'noEvi')              { $source_evidence_assertion = 'ECO:0006151'; $source_method = 'unknown'; }
#       elsif ($datatype eq 'infOther')      { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'script_gene'; }	# this source doesn't exist, and it's for unaccounted for data, but if we ever get this data, it just fails
      elsif ($datatype eq 'curConfNoMan')  { $source_evidence_assertion = 'ATP:0000036'; $source_method = 'genes_curator'; }
      elsif ($datatype eq 'curConfMan')    { $source_evidence_assertion = 'ATP:0000036'; $source_method = 'paper_editor_genes_curator'; }
      elsif ($datatype eq 'perEvi')        { $source_evidence_assertion = 'ATP:0000035'; $source_method = 'author_first_pass'; }
      elsif ($datatype eq 'cfp')           { $source_evidence_assertion = 'ATP:0000036'; $source_method = 'genes_curator'; }
      elsif ($datatype eq 'afp')           { $source_evidence_assertion = 'ATP:0000035'; $source_method = 'author_first_pass'; }
      elsif ($datatype eq 'ack')           { $source_evidence_assertion = 'ATP:0000035'; $source_method = 'ACKnowledge_form'; }
      elsif ($datatype eq 'absReadMeet')   { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'script_gene_meeting_abstract'; }
      elsif ($datatype eq 'absReadNoMeet') { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'paper_editor_genes_script'; }
      elsif ($datatype eq 'abs2aceCgc')    { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'abstract2aceCGC_script'; }
      elsif ($datatype eq 'abs2acePmid')   { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'abstract2acePMID_script'; }
      elsif ($datatype eq 'fixDead')       { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'fix_dead_genes_script'; }
      elsif ($datatype eq 'geneChecker')   { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'geneChecker_script'; }
      elsif ($datatype eq 'update2gcds')   { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'update2_gene_cds_script'; }
      elsif ($datatype eq 'updateOldWbg')  { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'update_oldwbgenes_papers_script'; }
      elsif ($datatype eq 'supTable')      { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'parsing_supplementary_tables_ortholist'; }
      elsif ($datatype eq 'maryAnnDead')   { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'update_of_dead_and_merged_genes_Mary_Ann'; }
      elsif ($datatype eq 'autoEimear')    { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'automatic_update_merge_script'; }
    my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    unless ($source_id) {
      print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
      return;
    }
    $datatypeToSourceId{$datatype} = $source_id;
    # print qq($source_id\t$datatype\n);
  }

  foreach my $datatype (sort keys %theHash) {
    foreach my $joinkey (sort keys %{ $theHash{$datatype} }) {
      next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
      my ($actual_joinkey) = &deriveValidPap($joinkey);
      next unless $papValid{$actual_joinkey};
      foreach my $gene (sort keys %{ $theHash{$datatype}{$joinkey} }) {
        my $entity_id_validation = 'alliance';
        if ($ginValidation{$gene}) { $entity_id_validation = $ginValidation{$gene}; }
          else { print PERR qq(ERROR $gene not in pap_species table\n); }
        foreach my $curator (sort keys %{ $theHash{$datatype}{$joinkey}{$gene} }) {
          my $who = $curator;
          if ( ($datatype eq 'infOther')      || ($datatype eq 'absReadMeet')   || ($datatype eq 'absReadNoMeet') || ($datatype eq 'abs2aceCgc')    ||
               ($datatype eq 'abs2acePmid')   || ($datatype eq 'fixDead')       || ($datatype eq 'geneChecker')   || ($datatype eq 'update2gcds')   ||
               ($datatype eq 'updateOldWbg')  || ($datatype eq 'supTable')      || ($datatype eq 'maryAnnDead')   || ($datatype eq 'autoEimear') ) {
            $who = 'caltech_pipeline'; }
          my %object;
          $object{'force_insertion'}            = TRUE;
          $object{'negated'}                    = FALSE;
          $object{'reference_curie'}            = $wbpToAgr{$actual_joinkey};
          $object{'topic'}                      = $geneTopic;
          $object{'entity_type'}                = $entityType;
          $object{'entity_id_validation'}       = $entity_id_validation;
          $object{'topic_entity_tag_source_id'} = $datatypeToSourceId{$datatype};
          $object{'entity'}                     = "WB:WBGene$gene";
          if ($geneToTaxon{$gene}) {
            $object{'species'}                  = $geneToTaxon{$gene}; }
          if ( ($datatype eq 'curConfMan') && ($papGenePublished{$joinkey}{$gene}) ) {
            my $published_as = join' | ', @{ $papGenePublished{$joinkey}{$gene} };
            $object{'entity_published_as'}      = $published_as; }
          if ($theHash{$datatype}{$joinkey}{$gene}{$curator}{note}) {
            my $note = join' | ', @{ $theHash{$datatype}{$joinkey}{$gene}{$curator}{note} };
            $object{'note'}                     = $note; }
          $object{'created_by'}                 = $who;
          $object{'updated_by'}                 = $who;
          $object{'date_created'}               = $theHash{$datatype}{$joinkey}{$gene}{$curator}{timestamp};
          $object{'date_updated'}               = $theHash{$datatype}{$joinkey}{$gene}{$curator}{timestamp};
          if ($output_format eq 'json') {
            push @output_json, \%object; }
          else {
            my $object_json = encode_json \%object;
            &createTag($object_json); }
    } } }
} } # sub outputTheHash

sub populateTfpGenestudied {
  my $result = $dbh->prepare( "SELECT * FROM tfp_genestudied WHERE tfp_timestamp > '2019-03-22 00:00';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts) = @row;
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    ($joinkey) = &deriveValidPap($joinkey);
    next unless $papValid{$joinkey};
    $tfpGene{$joinkey}{data} = $trText;
    $tfpGene{$joinkey}{timestamp} = $ts; } }

sub outputTfpData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ECO:0008021';
  my $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }
  foreach my $joinkey (sort keys %tfpGene) {
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    my $data = $tfpGene{$joinkey}{data};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = FALSE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
#     $object{'wbpaper_id'}                   = $joinkey;               # for debugging
    $object{'date_updated'}                 = $tfpGene{$joinkey}{timestamp};
    $object{'date_created'}                 = $tfpGene{$joinkey}{timestamp};
    $object{'created_by'}                   = 'ACKnowledge_pipeline';
    $object{'updated_by'}                   = 'ACKnowledge_pipeline';
    $object{'topic'}                        = 'ATP:0000005';
    if ($data eq '') {
      $object{'negated'}                    = TRUE;
#       $object{'BLAH'}                       = 'TFP neg';
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); } }
    else {
      my @data = split(/ | /, $data);
      foreach my $data (@data) {
        my ($geneInt) = $data =~ m/(\d{8})/;
        next unless ($geneInt);
        my $geneTaxon = '';
        my $geneSpecies = $gin{$geneInt};
        if ($geneSpecies) { $geneTaxon = $speciesToTaxon{$geneSpecies}; }
        unless ($geneSpecies && $geneTaxon) {	# if no geneSpecies or geneTaxon, skip, and add to error log
          print PERR qq(ERROR no species or taxon for WBGene$geneInt\n);
          next; }
        my $obj = 'WB:WBGene' . $geneInt;
#         $object{'BLAH'}                      = 'TFP yes';
        $object{'entity_type'}               = 'ATP:0000005';
        $object{'entity_id_validation'}      = 'alliance';
        $object{'entity'}                    = $obj;
        $object{'species'}                   = $geneTaxon;
        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); }
    } }
  }
} # sub outputTfpData

sub outputNegativeData {
  my $data_provider = $mod;
  my $secondary_data_provider = $mod;
  my $source_evidence_assertion = 'ATP:0000035';
  my $source_method = 'ACKnowledge_form';
  my $source_id_ack = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_ack) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ECO:0008021';
  $source_method = 'ACKnowledge_pipeline';
  my $source_id_tfp = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_tfp) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  $source_evidence_assertion = 'ATP:0000036';
  $source_method = 'paper_editor_genes_curator';
  my $source_id_cur_conf = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id_cur_conf) {
    print PERR qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
    return;
  }

  # This is negative ack data where author removed something that tfp said
  foreach my $joinkey (sort keys %tfpPapGene) {
    next unless ($afpLasttouched{$joinkey});    # must be a final author submission
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB\n); next; }
    foreach my $geneInt (sort keys %{ $tfpPapGene{$joinkey}{genes} }) {
      next if ($ackNegGeneTopic{$joinkey});			# if author sent nothing, don't create a negative entity
      next if ($ackPapGene{$joinkey}{genes}{$geneInt});		# if author sent this entity, don't create a negative entity
      next unless ($geneInt);					# must have a wbgene
      my @auts;
      if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
      if (scalar @auts < 1) { push @auts, 'unknown_author'; }
      foreach my $aut (@auts) {
        my %object;
        $object{'negated'}                    = TRUE;
        $object{'force_insertion'}            = TRUE;
        $object{'reference_curie'}            = $wbpToAgr{$joinkey};
        $object{'topic'}                      = 'ATP:0000005';
        $object{'entity_type'}                = 'ATP:0000005';
        $object{'entity_id_validation'}       = 'alliance';
        $object{'topic_entity_tag_source_id'} = $source_id_ack;
        $object{'created_by'}                 = $aut;
        $object{'updated_by'}                 = $aut;
        my $ts = $ackPapGene{$joinkey}{timestamp};
        if ( $afpContributor{$joinkey}{$aut} ) { $ts = $afpContributor{$joinkey}{$aut}; }
        $object{'date_created'}               = $ts;
        $object{'date_updated'}               = $ts;
        # $object{'datatype'}                 = 'ack neg entity data';	# for debugging
        # $object{'wbpaper'}                  = $joinkey;			# for debugging
        my $obj = 'WB:WBGene' . $geneInt;
        $object{'entity'}                     = $obj;
        my $geneTaxon = '';
        my $geneSpecies = $gin{$geneInt};
        if ($geneSpecies) { $geneTaxon = $speciesToTaxon{$geneSpecies}; }
        unless ($geneSpecies && $geneTaxon) {	# if no geneSpecies or geneTaxon, skip, and add to error log
          print PERR qq(ERROR no species or taxon for WBGene$geneInt\n);
          next; }
        $object{'species'}                    = $geneTaxon;

        if ($output_format eq 'json') {
          push @output_json, \%object; }
        else {
          my $object_json = encode_json \%object;
          &createTag($object_json); }
  } } }

  # This is negative tfp topic data where tfp is empty
  foreach my $joinkey (sort keys %tfpNegGeneTopic) {
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB tfpNegGeneTopic\n); next; }
    my $ts = $tfpNegGeneTopic{$joinkey};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_tfp;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = TRUE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
    # $object{'wbpaper_id'}                   = $joinkey;               # for debugging
    $object{'date_updated'}                 = $ts;
    $object{'date_created'}                 = $ts;
    $object{'created_by'}                   = 'ACKnowledge_pipeline';
    $object{'updated_by'}                   = 'ACKnowledge_pipeline';
    $object{'topic'}                        = 'ATP:0000005';
    if ($output_format eq 'json') {
      push @output_json, \%object; }
    else {
      my $object_json = encode_json \%object;
      &createTag($object_json); }
  }

  # This is negative ack topic data where ack is empty regardless of tfp empty or not
  foreach my $joinkey (sort keys %ackNegGeneTopic) {
    next unless ($afpContributor{$joinkey});    # must be an author that did that submission
    # next if ($tfpNegGeneTopic{$joinkey});	# explicitly not skipping because always treat empty ack author data as negative topic
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB ackNegGeneTopic\n); next; }
    my @auts;
    if ($afpContributor{$joinkey}) { foreach my $who (sort keys %{ $afpContributor{$joinkey} }) { push @auts, $who; } }
    if (scalar @auts < 1) { push @auts, 'unknown_author'; }
    foreach my $aut (@auts) {
      my $ts = $ackNegGeneTopic{$joinkey};
      if ( $afpContributor{$joinkey}{$aut} ) { $ts = $afpContributor{$joinkey}{$aut}; }
      my %object;
      $object{'topic_entity_tag_source_id'}   = $source_id_ack;
      $object{'force_insertion'}              = TRUE;
      $object{'negated'}                      = TRUE;
      $object{'reference_curie'}              = $wbpToAgr{$joinkey};
      # $object{'wbpaper_id'}                   = $joinkey;               # for debugging
      $object{'date_updated'}                 = $ts;
      $object{'date_created'}                 = $ts;
      $object{'created_by'}                   = $aut;
      $object{'updated_by'}                   = $aut;
      $object{'topic'}                        = 'ATP:0000005';
      if ($output_format eq 'json') {
        push @output_json, \%object; }
      else {
        my $object_json = encode_json \%object;
        &createTag($object_json); }
  } }

  # pap_curation_done = 'genestudied' paper not in pap_gene
  foreach my $joinkey (sort keys %curNegGeneTopic) {
    unless ($wbpToAgr{$joinkey}) { print PERR qq(ERROR paper $joinkey NOT AGRKB curNegGeneTopic\n); next; }
    my $ts = $curNegGeneTopic{$joinkey};
    my %object;
    $object{'topic_entity_tag_source_id'}   = $source_id_cur_conf;
    $object{'force_insertion'}              = TRUE;
    $object{'negated'}                      = TRUE;
    $object{'reference_curie'}              = $wbpToAgr{$joinkey};
    # $object{'wbpaper_id'}                   = $joinkey;               # for debugging
    $object{'date_updated'}                 = $curNegGeneTopic{$joinkey}{timestamp};
    $object{'date_created'}                 = $curNegGeneTopic{$joinkey}{timestamp};
    $object{'created_by'}                   = $curNegGeneTopic{$joinkey}{who};
    $object{'updated_by'}                   = $curNegGeneTopic{$joinkey}{who};
    $object{'topic'}                        = 'ATP:0000005';
    if ($output_format eq 'json') {
      push @output_json, \%object; }
    else {
      my $object_json = encode_json \%object;
      &createTag($object_json); }
  }
} # sub outputNegativeData

sub populateNegativeData {
  $result = $dbh->prepare( "SELECT * FROM afp_genestudied WHERE afp_genestudied != '' AND afp_timestamp > '2019-03-22 00:00' AND joinkey IN (SELECT joinkey FROM afp_lasttouched WHERE afp_timestamp > '2019-03-22 00:00'); " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    my @data = split(/ | /, $row[1]);
    foreach my $data (@data) {
      my ($geneInt) = $data =~ m/(\d{8})/;
      next unless ($geneInt);
      $ackPapGene{$row[0]}{genes}{$geneInt}++;
      $ackPapGene{$row[0]}{timestamp} = $row[2]; } }
  $result = $dbh->prepare( "SELECT * FROM tfp_genestudied WHERE tfp_genestudied != '' AND tfp_timestamp > '2019-03-22 00:00' AND joinkey IN (SELECT joinkey FROM afp_lasttouched WHERE afp_timestamp > '2019-03-22 00:00');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    my @data = split(/ | /, $row[1]);
    foreach my $data (@data) {
      my ($geneInt) = $data =~ m/(\d{8})/;
      next unless ($geneInt);
      $tfpPapGene{$row[0]}{genes}{$geneInt}++;
      $tfpPapGene{$row[0]}{timestamp} = $row[2]; } }

  $result = $dbh->prepare( "SELECT * FROM afp_genestudied WHERE afp_genestudied = '' AND afp_timestamp > '2019-03-22 00:00' AND joinkey IN (SELECT joinkey FROM afp_lasttouched WHERE afp_timestamp > '2019-03-22 00:00');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $ackNegGeneTopic{$row[0]} = $row[2]; }
  $result = $dbh->prepare( "SELECT * FROM tfp_genestudied WHERE tfp_genestudied = '' AND tfp_timestamp > '2019-03-22 00:00';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $tfpNegGeneTopic{$row[0]} = $row[2]; }

#   SELECT * FROM afp_genestudied WHERE afp_genestudied = '' AND afp_timestamp > '2019-03-22 00:00' AND joinkey IN (SELECT joinkey FROM afp_lasttouched) AND joinkey IN ( '00065553', '00065560', '00066296', '00066355', '00066405', '00066410', '00066411', '00066419', '00066461', '00066469' );
#   SELECT * FROM tfp_genestudied WHERE tfp_genestudied = '' AND tfp_timestamp > '2019-03-22 00:00' AND joinkey IN ( '00065553', '00065560', '00066296', '00066355', '00066405', '00066410', '00066411', '00066419', '00066461', '00066469' );

  $result = $dbh->prepare( "SELECT joinkey FROM pap_curation_done WHERE pap_curation_done = 'genestudied' AND joinkey NOT IN (SELECT joinkey FROM pap_gene); " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $row[3] =~ s/two/WBPerson/;
    $curNegGeneTopic{$row[0]}{who} = $row[3];
    $curNegGeneTopic{$row[0]}{timestamp} = $row[4]; }

} # sub populateNegativeData

sub populateAfpContributor {
  $result = $dbh->prepare( "SELECT * FROM afp_contributor" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey) = &deriveValidPap($row[0]);
    next unless $papValid{$joinkey};
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpContributor{$row[0]}{$who} = $row[2];
} }

sub populateAfpLasttouched {
  my $result = $dbh->prepare( "SELECT joinkey, afp_timestamp FROM afp_lasttouched" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
#     next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my $who = $row[1]; $who =~ s/two/WBPerson/;
    $afpLasttouched{$row[0]} = $row[1];
} }

sub populateGinTaxon {
  my $result = $dbh->prepare( "SELECT * FROM gin_species;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $gin{$row[0]} = $row[1];
  }

  $result = $dbh->prepare( " SELECT * FROM obo_name_ncbitaxonid WHERE obo_name_ncbitaxonid IN ( SELECT DISTINCT(gin_species) FROM gin_species ); " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $speciesToTaxon{$row[1]} = 'NCBITaxon:' . $row[0];
  }

#   $result = $dbh->prepare( "SELECT trp_name, trp_species FROM trp_name, trp_species WHERE trp_name.joinkey = trp_species.joinkey;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) {
#     $ginTaxon{"WB:$row[0]"} = $speciesToTaxon{$row[1]};
#   }
} # sub populateGinTaxon

sub populateGinValidation {
  $result = $dbh->prepare( "SELECT * FROM gin_species;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[1] eq 'Caenorhabditis elegans') { $ginValidation{$row[0]} = 'alliance'; }
      else { $ginValidation{$row[0]} = 'WB'; } } }
    

sub populatePapGene {
  $result = $dbh->prepare( "SELECT joinkey, pap_gene, pap_timestamp, pap_curator, pap_evidence FROM pap_gene WHERE pap_evidence ~ 'Manually_connected'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  # this is happening twice, because we need to know what is manConn before processing all data, to bin based on manConn
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey, $gene, $ts, $two, $evi) = @row;
    if ($evi =~ m/(Manually_connected.*".*")/) {
      $manConn{$joinkey}{$gene} = $1; }
  }
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
      if ($manConn{$joinkey}{$gene}) { 
#         $theHash{'curConfMan'}{$joinkey}{$gene}{$1}{curator} = $1;
        push @{ $theHash{'curConfMan'}{$joinkey}{$gene}{$1}{note} }, $manConn{$joinkey}{$gene};
        $theHash{'curConfMan'}{$joinkey}{$gene}{$1}{timestamp} = $ts; }
      else {
#         $theHash{'curConfNoMan'}{$joinkey}{$gene}{$1}{curator} = $1;
        $theHash{'curConfNoMan'}{$joinkey}{$gene}{$1}{timestamp} = $ts; } }
    elsif ($evi =~ m/Person_evidence.*(WBPerson\d+)/) {
#       $theHash{'perEvi'}{$joinkey}{$gene}{$1}{curator} = $1;
      $theHash{'perEvi'}{$joinkey}{$gene}{$1}{timestamp} = $ts; }
    elsif ($evi =~ m/Inferred_automatically/) { 	# this has to be more specific later
      if ($evi =~ m/Inferred_automatically\s+"(Abstract read .*?)"/) {
        if ($meetings{$joinkey}) {
          $theHash{'absReadMeet'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
          push @{ $theHash{'absReadMeet'}{$joinkey}{$gene}{$two}{note} }, $1; }
        else {
          $theHash{'absReadNoMeet'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
          push @{ $theHash{'absReadNoMeet'}{$joinkey}{$gene}{$two}{note} }, $1; } }
      elsif ($evi =~ m/Inferred_automatically\s+"(from curator first pass .*?)"/) {
        $theHash{'cfp'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'cfp'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(from author first pass .*?)"/) {
        my $tsdigits = &tsToDigits($ts);
        if ($tsdigits < '20190322') {
          $theHash{'afp'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
          push @{ $theHash{'afp'}{$joinkey}{$gene}{$two}{note} }, $1; }
        else {
          $theHash{'ack'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
          push @{ $theHash{'ack'}{$joinkey}{$gene}{$two}{note} }, $1; } }
      elsif ($evi =~ m/Inferred_automatically\s+"(abstract2aceCGC.pl.*)"/) {
        $theHash{'abs2aceCgc'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'abs2aceCgc'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(abstract2acePMID.pl.*)"/) {
        $theHash{'abs2acePmid'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'abs2acePmid'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(abstract2ace.*)"/) {
        $theHash{'absReadMeet'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'absReadMeet'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(fix_dead_genes.*)"/) {
        $theHash{'fixDead'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'fixDead'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(geneChecker.*)"/) {
        $theHash{'geneChecker'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'geneChecker'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*update2_gene_cds.*)"/) {
        $theHash{'update2gcds'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'update2gcds'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*update2_gene_cds.*)"/) {
        $theHash{'update2gcds'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'update2gcds'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*update_oldwbgenes_papers.*)"/) {
        $theHash{'updateOldWbg'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'updateOldWbg'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*Table S1 sheet B.*)"/) {
        $theHash{'supTable'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'supTable'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*Table S5 sheet C.*)"/) {
        $theHash{'supTable'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'supTable'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*Mary Ann Tuli dead and merged gene dump 2006 09 29.*)"/) {
        $theHash{'maryAnnDead'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'maryAnnDead'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*Eimear Kenny, 02-09-05.*)"/) {
        $theHash{'autoEimear'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'autoEimear'}{$joinkey}{$gene}{$two}{note} }, $1; }
      elsif ($evi =~ m/Inferred_automatically\s+"(.*abstract2aceLeonsFormat.pl eek.*)"/) {
        $theHash{'autoEimear'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'autoEimear'}{$joinkey}{$gene}{$two}{note} }, $1; }
      else {
        print PERR qq(ATTN Kimberly, unaccounted for type of data infOther : paper $joinkey, gene $gene, curator $two\n); }
# these were things we tried to account for, but we don't have a source for, so instead going to processing error log
#       elsif ($evi =~ m/Inferred_automatically\s+"(.*?)"/) {
#         $theHash{'infOther'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
#         push @{ $theHash{'infOther'}{$joinkey}{$gene}{$two}{note} }, $1; }
#       else {	# this should never happen
#         $theHash{'infOther'}{$joinkey}{$gene}{$two}{timestamp} = $ts; }
    }
    elsif ($evi =~ m/Published_as\s+"(.*?)"/) {
      push @{ $papGenePublished{$joinkey}{$gene} }, $1; }
    elsif ($evi =~ m/Manually_connected.*"(.*?)"/) {
      $manConn{$joinkey}{$gene} = $1; }
    elsif ($evi =~ m/Author_evidence/) {	# ignore these, should be removed from postgres
      1; }
    else {
#       $theHash{'noEvi'}{$joinkey}{$gene}{$two}{curator} = $two;
      $theHash{'noEvi'}{$joinkey}{$gene}{$two}{timestamp} = $ts; }
} }


sub populateGeneTaxon {
  my %taxonNameToId;

  # Kimberly updated the pap_species_index to have all the entries it needs on caltech prod.  2024 03 22
  $result = $dbh->prepare( "SELECT * FROM pap_species_index ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[1] && $row[0]) {
      $taxonNameToId{$row[1]} = 'NCBITaxon:' . $row[0]; } }

  $result = $dbh->prepare( "SELECT * FROM gin_species;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 	# only molecules with papers are curated
  while (my @row = $result->fetchrow) { 
    next unless ($taxonNameToId{$row[1]});
    $geneToTaxon{$row[0]} = $taxonNameToId{$row[1]}; }
} # sub populateGeneTaxon



sub populateMeetings {
  $result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '3';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    $meetings{$row[0]}++; }
} # sub populateAbcXref

sub deriveValidPap {
  my ($joinkey) = @_;
  if ($papValid{$joinkey}) { return $joinkey; }
    elsif ($papMerge{$joinkey}) {
      ($joinkey) = &deriveValidPap($papMerge{$joinkey});
      return $joinkey; }
    else { return 'NOTVALID'; }
} # sub deriveValidPap

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
  print OUT qq(create $object_json\n);
  print OUT qq($api_json\n);
  if ($api_json !~ /success/) {
    print ERR qq(create $object_json\n);
    print ERR qq($api_json\n);
  }
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

