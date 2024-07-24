#!/usr/bin/env perl

# Looking at afp_transgene from old afp, before 2019-03-22
# Stripping out anything in square brackets (sometimes they put things in parenthesis or mismatch, so it fails)
# Replacing ~~ with space
# Replacing multispace with single space
# Getting rid of anything that isn't a letter number or space
# Splitting words by spaces
# Looking for [a-z]+(Ex|Is)\d+   lowercase letters, Ex or Is, digits
# If it matches the pattern, and in trp_name + trp_publicname, then it's a YESMATCH.  If not in trp tables it's a NOMATCH
# Otherwise checked is getting ignored, any other string is a BAD
# 53 entries have YESMATCH
# 15 entries have NOMATCH
# 37 entries have BAD
# Some entries could have multiple.   File is broken up in paragraphs with the WBPaper ID, types of matches, and ORIG for original entry.
#
# For Kimberly to transfer old afp to abc TET.  Analysis of data first.  2024 06 30
#
# Update script to fix afp_transgene data if it has mappings.
# Convert to acknowledge format   WBTransgene00020977;%;ltSi560 | WBTransgene00014794;%;oxEx1578 | WBTransgene00025194;%;bsSi28 | WBTransgene00001903;%;qIs51
# but add  | ORIGINAL COMMENT <comment>
# 2024 07 22

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

my %trp;

&populateTrp();
&populateAfpTransgene();

sub populateTrp {
  my $result = $dbh->prepare( "SELECT trp_name, trp_publicname FROM trp_name, trp_publicname WHERE trp_name.joinkey = trp_publicname.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $trp{$row[1]} = $row[0];
  }
}

sub populateAfpTransgene {
  my @pgcommands;
  my $result = $dbh->prepare( "SELECT * FROM afp_transgene WHERE afp_timestamp < '2019-03-22 00:00';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $trText, $ts, $curator, $approve, $curts) = @row;
#     print qq($joinkey\t$trText\n);
    my $trTextOrig = $trText;
    $trText =~ s/\[[^\]]*\]//g;
    $trText =~ s/~~/ /g;
    $trText =~ s/\s+/ /g;
    $trText =~ s/[^A-Za-z0-9 ]//g;
    my (@words) = split/\s+/, $trText;
    my %nomatch;
    my %match;
    my %bad;
    foreach my $word (@words) {
      $word =~ s/\s+//g;
      if ($word =~ m/[a-z]+(Ex|Is)\d+/) { 
#           if ($trp{$word}) { $match{"$word - $trp{$word}"}++; }
          if ($trp{$word}) { $match{"$trp{$word};%;$word"}++; }
          else { $nomatch{$word}++; } }
        elsif ($word eq 'checked') { 1; }
        else { $bad{$word}++; }
    }
    my $match = join" | ", sort keys %match;
    my $nomatch = join"\t", sort keys %nomatch;
    my $bad = join"\t", sort keys %bad;
    print qq($joinkey\n);
    if ($match) { 
      my $newValue = qq($match | ORIGINAL COMMENT $trTextOrig);
      push @pgcommands, qq(UPDATE afp_transgene SET afp_transgene = '$newValue' WHERE joinkey = '$joinkey');
      print qq(YESMATCH $match | ORIGINAL COMMENT $trTextOrig\n); }
    if ($nomatch) { print qq(NOMATCH $nomatch\n); }
    if ($bad) { print qq(BAD $bad\n); }
    print qq(ORIG $trTextOrig\n\n);
#     print qq($joinkey\t$trText\n);
  }

  foreach my $pgcommand (@pgcommands) {
    print qq( $pgcommand \n);
# UNCOMMENT TO UPDATE
#     $dbh->do( $pgcommand );
  }
}

__END__

backup tables before running this

touch /usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240630_topic_entity_transgenes/afp_transgene.pg
chmod 777 /usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240630_topic_entity_transgenes/afp_transgene.pg
COPY afp_transgene TO '/usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240630_topic_entity_transgenes/afp_transgene.pg';

touch /usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240630_topic_entity_transgenes/afp_transgene_hst.pg
chmod 777 /usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240630_topic_entity_transgenes/afp_transgene_hst.pg
COPY afp_transgene_hst TO '/usr/caltech_curation_files/postgres/agr_upload/pap_papers/20240630_topic_entity_transgenes/afp_transgene_hst.pg';

__END__

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
my @wbpapers = qw( 00000119 00000465 00003000 00003823 00004455 00004952 00005199 00005707 00005988 00006103 00006202 00006320 00013393 00017095 00024745 00025176 00027230 00038491 00044280 00046571 00057043 00063127 00064676 00064771 00065877 00066211 );		# kimberly 2024 05 13 set

# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 
# 00004952 00005199 00026609 00030933 00035427 00046571 00057043 00064676 00037049

my %datatypesAfpCfp;
my %datatypes;
my %entitytypes;
my %wbpToAgr;
my %meetings;
my %geneToTaxon;
my %manConn;
my %papGenePublished;

my %chosenPapers;
my %ginValidation;

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

# my $geneTopic = 'ATP:0000142';
my $geneTopic = 'ATP:0000005';
my $entityType = 'ATP:0000005';

foreach my $joinkey (@wbpapers) { $chosenPapers{$joinkey}++; }
# $chosenPapers{all}++;

&populateAbcXref();
&populateMeetings();
&populateGeneTaxon();
&populatePapGene();
&populateGinValidation();
# &outputInfOther();
# &outputCurConf();
&outputTheHash();

if ($output_format eq 'json') {
  my $json = encode_json \@output_json;		# for single json file output
  print qq($json\n);				# for single json file output
}

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
      elsif ($datatype eq 'infOther')      { $source_evidence_assertion = 'ECO:0008021'; $source_method = 'script_gene'; }
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
      print qq(ERROR no source_id for $source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
      return;
    }
    $datatypeToSourceId{$datatype} = $source_id;
    # print qq($source_id\t$datatype\n);
  }

  foreach my $datatype (sort keys %theHash) {
    foreach my $joinkey (sort keys %{ $theHash{$datatype} }) {
      next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
      foreach my $gene (sort keys %{ $theHash{$datatype}{$joinkey} }) {
        my $entity_id_validation = 'alliance';
        if ($ginValidation{$gene}) { $entity_id_validation = $ginValidation{$gene}; }
          else { print qq(ERROR $gene not in pap_species table\n); }
        foreach my $curator (sort keys %{ $theHash{$datatype}{$joinkey}{$gene} }) {
          my %object;
          $object{'force_insertion'}            = TRUE;
          $object{'negated'}                    = FALSE;
          $object{'reference_curie'}            = $wbpToAgr{$joinkey};
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
          $object{'created_by'}                 = $curator;
          $object{'updated_by'}                 = $curator;
          $object{'date_created'}               = $theHash{$datatype}{$joinkey}{$gene}{$curator}{timestamp};
          $object{'date_updated'}               = $theHash{$datatype}{$joinkey}{$gene}{$curator}{timestamp};
          if ($output_format eq 'json') {
            push @output_json, \%object; }
          else {
            my $object_json = encode_json \%object;
            &createTag($object_json); }
    } } }
} }

sub populateGinValidation {
  $result = $dbh->prepare( "SELECT * FROM gin_species;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[1] eq 'Caenorhabditis elegans') { $ginValidation{$row[0]} = 'alliance'; }
      else { $ginValidation{$row[0]} = 'WB'; } } }
    

sub populatePapGene {
  $result = $dbh->prepare( "SELECT joinkey, pap_gene, pap_timestamp, pap_curator, pap_evidence FROM pap_gene WHERE pap_evidence ~ 'Manually_connected'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
    next unless ($row[1]);
    my ($joinkey, $gene, $ts, $two, $evi) = @row;
    if ($evi =~ m/Manually_connected.*"(.*?)"/) {
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
      elsif ($evi =~ m/Inferred_automatically\s+"(.*?)"/) {
        $theHash{'infOther'}{$joinkey}{$gene}{$two}{timestamp} = $ts;
        push @{ $theHash{'infOther'}{$joinkey}{$gene}{$two}{note} }, $1; }
      else {	# this should never happen
        $theHash{'infOther'}{$joinkey}{$gene}{$two}{timestamp} = $ts; }
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

