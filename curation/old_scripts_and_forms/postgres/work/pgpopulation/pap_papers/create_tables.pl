#!/usr/bin/perl -w

# create new pap tables to replace old pap_ tables and wpa_ tables with data from 
# wpa_ tables  2009 12 10
#
# fixed Year / Month / Day not going in right from mis-parsed XML.
# check WBPaper00002006  xml 8041603 for Year / Month / Day  2010 02 19

# FORM :
# primary_data top field
# year / month / day  dropdowns

# TODO :
# populate contains / book_chapter stuff before merge http://www.wormbase.org/wiki/index.php/In_book	- done
# create new table and populate primary data based on type  http://www.wormbase.org/wiki/index.php/Primary_data_Tag - done
# put that on top of the form -- not anymore, put with curation flags 2010 03 09
# contained_in is primary way for book chapter
#
# probably drop pap_erratum_for and pap_contains tables.  2010 02 17
#
# dump Brief_citation	- done
# need to populate internal_comment off of wpa_comments 	- done 2010 02 19
#
# TODO fix that problem with some genes dumping / not dumping because of invalidating of gene-evidence instead 
# of invalidating gene.  When doing that, move functional_annotation to pap_curation_flags (from pap_ignore, 
# then get rid of pap_ignore)  2010 04 01

use strict;
use diagnostics;
use DBI;
use Jex;		# filter for Pg

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $result;


# unique (single value) tables :  status title journal publisher pages volume year month day pubmed_final primary_data abstract );

my %single;
$single{'status'}++;
$single{'title'}++;
$single{'journal'}++;
$single{'publisher'}++;
$single{'volume'}++;
$single{'pages'}++;
$single{'year'}++;
$single{'month'}++;
$single{'day'}++;
$single{'pubmed_final'}++;
$single{'primary_data'}++;
$single{'abstract'}++;

# multivalue tables :  editor type author affiliation fulltext_url contained_in gene identifier ignore remark erratum_in internal_comment curation_flags 

my %multi;
$multi{'editor'}++;
$multi{'type'}++;
$multi{'author'}++;
$multi{'affiliation'}++;
$multi{'fulltext_url'}++;
$multi{'contained_in'}++;
$multi{'gene'}++;
$multi{'identifier'}++;
# $multi{'ignore'}++;
$multi{'remark'}++;
$multi{'erratum_in'}++;
$multi{'internal_comment'}++;
$multi{'curation_flags'}++;
$multi{'electronic_path'}++;
$multi{'author_possible'}++;
$multi{'author_sent'}++;
$multi{'author_verified'}++;


my %primary_data;		# primary data or not
$primary_data{1} = 'primary';		# Journal_article
$primary_data{11} = 'primary';		# Letter
$primary_data{14} = 'primary';		# Published_erratum
$primary_data{2} = 'not_primary';	# Review
$primary_data{5} = 'not_primary';	# Book_chatper
$primary_data{6} = 'not_primary';	# News
$primary_data{8} = 'not_primary';	# Book
$primary_data{9} = 'not_primary';	# Historical_article
$primary_data{10} = 'not_primary';	# Comment
$primary_data{12} = 'not_primary';	# Monograph
$primary_data{13} = 'not_primary';	# Editorial
$primary_data{15} = 'not_primary';	# Retracted_publication
$primary_data{16} = 'not_primary';	# Technical_report
$primary_data{18} = 'not_primary';	# WormBook
$primary_data{19} = 'not_primary';	# Interview
$primary_data{20} = 'not_primary';	# Lectures
$primary_data{21} = 'not_primary';	# Congresses
$primary_data{22} = 'not_primary';	# Interactive_tutorial
$primary_data{23} = 'not_primary';	# Biography
$primary_data{24} = 'not_primary';	# Directory
$primary_data{3} = 'not_designated';	# Meeting_abstract
$primary_data{4} = 'not_designated';	# Gazette_article
$primary_data{7} = 'not_designated';	# Email
$primary_data{17} = 'not_designated';	# Other


# non-xml to copy over :  abstract  affiliation  author  a/i a/p a/s a/v  contained_in/contains  editor  electronic_path_type -> electronic_path   fulltext_url  gene  identifier  ignore  publisher  remark   rnai_int_done/rnai_curation/transgene_curation/allele_curation -> curation_flags  status
# unless-xml to copy over :  journal  pages  title  volume  year  type  primary_data (based on type)
# ``manual'' add erratum_in/erratum_for


# special tables :
# gene -> need evidence : joinkey, gene, order, curator, timestamp, evidence
# electronic_path -> from electronic_path_type, which has wpa_type instead of order
# author_index -> author_id instead of joinkey
# author_possible -> author_id instead of joinkey
# author_sent -> author_id instead of joinkey
# author_verified -> author_id instead of joinkey
# type_index -> index, type_id instead of joinkey

# author_index author_possible author_sent author_verified electronic_path gene type_index

# my @pap_tables = qw( abstract affiliation author contained_in editor fulltext_url identifier ignore journal pages publisher pubmed_final remark title type volume year month day erratum_in internal_comment curation_flags primary_data status );
my @pap_tables = qw( abstract affiliation author contained_in editor fulltext_url identifier journal pages publisher pubmed_final remark title type volume year month day erratum_in internal_comment curation_flags primary_data status );


# &populateStatusIdentifier();

my %idents;
my %all_ids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  $all_ids{$row[0]}{$row[1]}++;
  if ($row[1] =~ m/pmid(\d+)/) { $idents{$1} = $row[0]; }
}


# running all these takes plus the status identifier takes about 30 minutes.  2010 02 23
# &populateFromXml();		# populate paper data from pubmed xml
# &populateUnlessXml();		# populate data from wpa for fields that would be gotten from xml
# &populateExtraTypes();	# only run after populateFromXml + populateUnlessXML, populate manual Kimberly data for Type information that is not in XML / unlessXml
# &populateNonXml();		# populate data from wpa for fields that do not exist in xml (and are not special tables)
# &populateAuthorSub();		# populate author index/possible/sent/verified data (special tables)
# &populateGene();		# populate gene data (special table)
# &populateCurationFlags();	# populate curation flags (special table) from rnai_curation / rnai_int_done / p2go
# &populateElectronicPath();	# populate electronic path data (special table)
# &populateErratum();		# populate erratum_in table from manual stuff

# &checkAffiliationWrong();	# some affiliation stuff wasn't getting in because of non-utf8 characters
# &getOddJournals();		# not necessary, for Kimberly to extract odd journals
# &populateTypeIndex();		# only run once, to populate type index

sub populateCurationFlags {
#   my @curation_flags = qw( rnai_int_done rnai_curation );
  my @curation_flags = qw( rnai_curation );		# only rnai_curation for gary and chris  2010 04 22
  
  $result = $dbh->do( "DELETE FROM h_pap_curation_flags" );
  $result = $dbh->do( "DELETE FROM pap_curation_flags" );

  my %hash; my %data;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'");	
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{status}{$row[0]}++; }

  foreach my $type (@curation_flags) {
    $result = $dbh->prepare( "SELECT * FROM wpa_$type ORDER BY wpa_timestamp" );	# in order to store latest timestamp (gary doesn't care which)
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless ($row[1]);	# these two tables are always valid, and data order is always null
      $data{$row[0]}{$type}{curator} = $row[4];
      $data{$row[0]}{$type}{timestamp} = $row[5]; } }

  my %validHash;
  $result = $dbh->prepare( "SELECT * FROM wpa_ignore ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless $row[1];
    if ($row[3] eq 'valid') { 
        $validHash{$row[0]}{$row[1]}{data} = $row[1];
        if ($row[4]) { $validHash{$row[0]}{$row[1]}{curator} = $row[4]; }
        if ($row[5]) { $validHash{$row[0]}{$row[1]}{timestamp} = $row[5]; } }
      else { 
        delete $validHash{$row[0]}{$row[1]}; } }
  foreach my $joinkey (sort keys %validHash) {
    foreach my $data (sort keys %{ $validHash{$joinkey} }) {
      if ($data) {
        if ($data ne 'functional annotation only') { 1; } # { print "$joinkey DATA $data\n"; }
          else {
            $data{$joinkey}{functional_annotation}{curator} = $validHash{$joinkey}{$data}{curator};
            $data{$joinkey}{functional_annotation}{timestamp} = $validHash{$joinkey}{$data}{timestamp}; } }
    } # foreach my $data (sort keys %{ $validHash{$joinkey} })
  } # foreach my $joinkey (sort keys %validHash)
  

  $data{"00004402"}{"Phenotype2GO"}{"curator"} = "two1843";	# manual ranjana / kimberly data
  $data{"00004403"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00004540"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00004651"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00004769"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00005599"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00005654"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00006395"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00024497"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00024925"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00025054"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00026763"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00005736"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00026593"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00028783"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00029254"}{"Phenotype2GO"}{"curator"} = "two1843";
  $data{"00030951"}{"Phenotype2GO"}{"curator"} = "two1843";

  my @data_types = qw( functional_annotation rnai_curation Phenotype2GO );
  foreach my $joinkey (sort keys %{ $hash{status} }) {
    my $order = 0;
    foreach my $type (@data_types) {
      next unless ($data{$joinkey}{$type}{curator});
      $order++;
      my $curator = $data{$joinkey}{$type}{curator};
      my $timestamp = 'CURRENT_TIMESTAMP';
      if ($data{$joinkey}{$type}{timestamp}) {
        $timestamp = "'$data{$joinkey}{$type}{timestamp}'"; }

#       print "$joinkey\t$type\t$order\t$curator\t$timestamp\n";
      $result = $dbh->do( "INSERT INTO pap_curation_flags VALUES ('$joinkey', '$type', $order, '$curator', $timestamp)" );
      $result = $dbh->do( "INSERT INTO h_pap_curation_flags VALUES ('$joinkey', '$type', $order, '$curator', $timestamp)" );
    }
  } # foreach my $type (@curation_flags)
} # sub populateCurationFlags


sub populateAuthorSub {		# populate author index/possible/sent/verified data (special tables)
  my @subtables = qw( index possible sent verified );
  my %hash;

  foreach my $type (@subtables) {
    $result = $dbh->do( "DROP TABLE h_pap_author_$type" );
    $result = $dbh->do( "DROP TABLE pap_author_$type" );

    my $papt = 'pap_author_' . $type;
    $result = $dbh->do( "CREATE TABLE $papt ( author_id text, $papt text, pap_join integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone)" ); 
    $result = $dbh->do( "CREATE INDEX ${papt}_idx ON $papt USING btree (author_id);" );
    $result = $dbh->do( "REVOKE ALL ON TABLE $papt FROM PUBLIC;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO postgres;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO acedb;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO apache;" );
#     $result = $dbh->do( "GRANT ALL ON TABLE $papt TO "www-data";" );	# not sure this works
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO azurebrd;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO cecilia;" );
    
    $result = $dbh->do( "CREATE TABLE h_$papt ( author_id text, $papt text, pap_join integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone)" ); 
    $result = $dbh->do( "CREATE INDEX h_${papt}_idx ON $papt USING btree (author_id);" );
    $result = $dbh->do( "REVOKE ALL ON TABLE h_$papt FROM PUBLIC;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO postgres;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO acedb;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO apache;" );
#     $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO "www-data";" );	# not sure this works  2010 06 25
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO azurebrd;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO cecilia;" );

    $result = $dbh->prepare( "SELECT * FROM wpa_author_$type ORDER BY wpa_timestamp" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless ($row[1]);
      unless ($row[2]) { $row[2] = 'NULL'; }
      if ($type eq 'index') { $row[2] = 'NULL'; }
      if ($row[3] eq 'valid') { 
          $hash{$row[0]}{$row[2]}{$type}{$row[1]}{data} = $row[1];
          if ($row[4]) { $hash{$row[0]}{$row[2]}{$type}{$row[1]}{curator} = $row[4]; }
          if ($row[5]) { $hash{$row[0]}{$row[2]}{$type}{$row[1]}{timestamp} = $row[5]; } }
        else { 
          delete $hash{$row[0]}{$row[2]}{$type}{$row[1]}; } }
  }

# print "T $type\n";
#   my %one_data;				# store just most recent data for a given type-aid-join
  foreach my $author_id (sort keys %hash) {
# print "AID $author_id\n";
    my $count = 0;
    foreach my $join (sort keys %{ $hash{$author_id} }) {
# print "JOIN $join\n";
      my $order = 'NULL';
      if ($join ne 'NULL') { $count++; $order = "'$count'"; }
      foreach my $type (sort keys %{ $hash{$author_id}{$join} }) {
        my $papt = 'pap_author_' . $type;
        my %tempHash;			# a given aid + join will sometimes have multiple data, so only store the latest one by storing by timestamp and getting reverse keys sort
# my @data = keys %{ $hash{$author_id}{$join}{$type} };
# if (scalar(@data) > 1) { print "ERR " . scalar(@data) . " for $author_id $order $type\n"; }
        foreach my $data (sort keys %{ $hash{$author_id}{$join}{$type} }) {
          next unless $data;
          my $curator = $hash{$author_id}{$join}{$type}{$data}{curator};
          my $timestamp = $hash{$author_id}{$join}{$type}{$data}{timestamp};
          my $time = $timestamp; $time =~ s/\D//g; 
          ($data) = &filterForPg($data);
          unless ($curator) { 
            print "NO CURATOR $author_id T $type D $data\n"; 
            $curator = 'two1841'; }
          unless ($timestamp) { 
            print "NO TIMESTAMP $author_id T $type D $data\n"; }
          $tempHash{$timestamp}{curator} = $curator;
          $tempHash{$timestamp}{data} = $data;
#           print "DATA\t$type\t$author_id\t$data\t$order\t$curator\t$timestamp\n";
          $result = $dbh->do( "INSERT INTO h_$papt VALUES ('$author_id', '$data', $order, '$curator', '$timestamp')" );		# enter all (valid) data to history
        }
        foreach my $timestamp (reverse sort keys %tempHash) {	# get the most recent timestamp off of reverse alpha sort
          my $curator = $tempHash{$timestamp}{curator};
          my $data = $tempHash{$timestamp}{data};
# these three lines are to help fix wrong stuff below
#           $one_data{$type}{$author_id}{$join}{data} = $data;
#           $one_data{$type}{$author_id}{$join}{curator} = $curator;
#           $one_data{$type}{$author_id}{$join}{timestamp} = $timestamp;
#           print "FINAL\t$type\t$author_id\t$data\t$order\t$curator\t$timestamp\n";
          $result = $dbh->do( "INSERT INTO $papt VALUES ('$author_id', '$data', $order, '$curator', '$timestamp')" );			# enter most recent data to current field
          last;				# only get the latest value, so skip all others
        }
  } } }


# fix aid 112313 that was connected the same way multiple times, don't copy all the multiples
# to find entries with multiple joins for a single aid-possible.  then fixed results manually  2010 04 22
#   my %filterHash;
#   foreach my $aid (sort keys %{ $one_data{possible} }) {
#     foreach my $join (sort keys %{ $one_data{possible}{$aid} }) {
#       my $possible = ''; my $verified = ''; my $pos_time = ''; my $ver_time = '';
#       if ($one_data{possible}{$aid}{$join}{data}) { $possible = $one_data{possible}{$aid}{$join}{data}; }
#       if ($one_data{possible}{$aid}{$join}{timestamp}) { $pos_time = $one_data{possible}{$aid}{$join}{timestamp}; }
#       if ($one_data{verified}{$aid}{$join}{data}) { $verified = $one_data{verified}{$aid}{$join}{data}; }
#       if ($one_data{verified}{$aid}{$join}{timestamp}) { $ver_time = $one_data{verified}{$aid}{$join}{timestamp}; }
#       my $key = "$pos_time\t$verified\t$ver_time";
#       $filterHash{$aid}{$possible}{$key}{$join}++;
#     } # foreach my $join (sort keys %{ $one_data{possible}{$aid} })
#   } # foreach my $aid (sort keys %{ $one_data{possible} })
# 
#   foreach my $aid (sort {$a<=>$b} keys %filterHash) {
#     foreach my $possible (sort keys %{ $filterHash{$aid} }) {
#       my (@keys) = keys %{ $filterHash{$aid}{$possible} };
#       if (scalar(@keys) > 1) { 
#         foreach my $keys (sort keys %{ $filterHash{$aid}{$possible} }) {
#           foreach my $join (sort {$a<=>$b} keys %{ $filterHash{$aid}{$possible}{$keys} }) {
#             print "MULT $aid AID $possible POS $keys PT_VER_VT $join JOIN\n";
#   } } } } } 
# 
# to find type-aid-join with multiple values (solve by sorting by timestamp, keeping the most recent one)
#   foreach my $aid (sort keys %hash) {
#     my $count = 0;
#     foreach my $type (@subtables) {
#       foreach my $join (sort keys %{ $hash{$aid} }) {
#         my %index;
#         my $order = 'NULL';
#         if ($join ne 'NULL') { $count++; $order = "'$count'"; }
#         my (@index) = sort keys %{ $hash{$aid}{$join}{$type} };
#         if (scalar(@index) > 1) {
#           my $too_many = join"\t", @index;
#           print "TOO MANY $type AID $aid JOIN $join -=${too_many}=-\n"; 
#           print "OD $one_data{$type}{$aid}{$join}{data} $one_data{$type}{$aid}{$join}{curator} $one_data{$type}{$aid}{$join}{timestamp} OD\n"; 
#   } } } }
} # sub populateAuthorSub

sub populateGene {		# put locus in evidence column "Inferred_manually"
  $result = $dbh->do( "DROP TABLE h_pap_gene" );
  $result = $dbh->do( "DROP TABLE pap_gene" );

  my $papt = 'pap_gene';
  $result = $dbh->do( "CREATE TABLE $papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone , pap_evidence text)" ); 
  $result = $dbh->do( "CREATE INDEX ${papt}_idx ON $papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE $papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO cecilia;" );
  
  $result = $dbh->do( "CREATE TABLE h_$papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone , pap_evidence text)" ); 
  $result = $dbh->do( "CREATE INDEX h_${papt}_idx ON h_$papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE h_$papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO cecilia;" );

  my %hash;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'; ");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{status}{$row[0]}++; }

  my $type = 'gene';
  $result = $dbh->prepare( "SELECT * FROM wpa_$type ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($row[1]);
    unless ($row[2]) { $row[2] = 'NULL'; }
    my $key = "$row[1]KEY$row[2]";
    if ($row[3] eq 'valid') { 
        $hash{$type}{$row[0]}{$key}{data} = $row[1];
        if ($row[4]) { $hash{$type}{$row[0]}{$key}{curator} = $row[4]; }
        if ($row[5]) { $hash{$type}{$row[0]}{$key}{timestamp} = $row[5]; } }
      else { 
        delete $hash{$type}{$row[0]}{$key}; } }

  my %stuff; 				# use this hash to filter new Manually_connected evidence to store locus where it wasn't Inferred_automatically (instead of in the gene column)
  foreach my $joinkey (sort keys %{ $hash{status} }) {
    foreach my $key (sort keys %{ $hash{$type}{$joinkey} }) {
      my ($genedata, $evi) = split/KEY/, $key;
      my ($geneid) = $genedata =~ m/WBGene(\d+)/;
      next unless ($geneid); 		# there's 3 entries without any data
      my $locus = '';
      if ($genedata =~ m/\(([^\(\)]*?)\)/) {	# if there's a locus (innermost stuff in parenthesis)
        $locus = $1; 
# print "J $joinkey KEY $key G $geneid L $locus E $evi C $hash{$type}{$joinkey}{$key}{curator} T $hash{$type}{$joinkey}{$key}{timestamp} E\n";
        if ($evi =~ m/$locus/) { 		# the locus mentioned in evidence, stays the same
            $stuff{$joinkey}{$geneid}{$evi}{curator} = $hash{$type}{$joinkey}{$key}{curator};
            $stuff{$joinkey}{$geneid}{$evi}{timestamp} = $hash{$type}{$joinkey}{$key}{timestamp}; }
          else { # if ($evi =~ m/$locus/)	# locus not in evidence
            if ($evi =~ m/Inferred_automatically\t\"(.*?)\"/) {	# if inferred automatically, add to evidence
                $evi = "Inferred_automatically\t\"$locus $1\"";
                $stuff{$joinkey}{$geneid}{$evi}{curator} = $hash{$type}{$joinkey}{$key}{curator};
                $stuff{$joinkey}{$geneid}{$evi}{timestamp} = $hash{$type}{$joinkey}{$key}{timestamp}; }
              else { 				# not inferred automatically, store it
                $stuff{$joinkey}{$geneid}{$evi}{curator} = $hash{$type}{$joinkey}{$key}{curator};
                $stuff{$joinkey}{$geneid}{$evi}{timestamp} = $hash{$type}{$joinkey}{$key}{timestamp};
                $evi = "Manually_connected\t\"$locus\""; 		# and also add manual
                $stuff{$joinkey}{$geneid}{$evi}{curator} = $hash{$type}{$joinkey}{$key}{curator};
                $stuff{$joinkey}{$geneid}{$evi}{timestamp} = $hash{$type}{$joinkey}{$key}{timestamp}; }
        } # else # if ($evi =~ m/$locus/)	
      } # if ($genedata =~ m/\((.*?)\)/)
      else {	# if there is no locus, store the entry
        $stuff{$joinkey}{$geneid}{$evi}{curator} = $hash{$type}{$joinkey}{$key}{curator};
        $stuff{$joinkey}{$geneid}{$evi}{timestamp} = $hash{$type}{$joinkey}{$key}{timestamp}; }
    } # foreach my $gene_data (sort keys %{ $hash{$type}{$joinkey} })
  } # foreach my $joinkey (sort keys %{ $hash{status} })

  foreach my $joinkey (sort keys %stuff) {
    my $count = 0;
    foreach my $geneid (sort keys %{ $stuff{$joinkey} }) {
      foreach my $evi (sort keys %{ $stuff{$joinkey}{$geneid} }) {
        $count++; my $order = "'$count'";
        my $curator = $stuff{$joinkey}{$geneid}{$evi}{curator};
        my $timestamp = $stuff{$joinkey}{$geneid}{$evi}{timestamp};
        if ($evi ne 'NULL') { $evi = "'$evi'"; }
#         print "GENE\t$joinkey\t$geneid\t$order\t$curator\t$timestamp\t$evi\n";
        $result = $dbh->do( "INSERT INTO pap_gene VALUES ('$joinkey', '$geneid', $order, '$curator', '$timestamp', $evi)" );
        $result = $dbh->do( "INSERT INTO h_pap_gene VALUES ('$joinkey', '$geneid', $order, '$curator', '$timestamp', $evi)" );
      } # foreach my $evi (sort keys %{ $stuff{$joinkey}{$geneid} })
    } # foreach my $geneid (sort keys %{ $stuff{$joinkey} })
  } # foreach my $joinkey (sort keys %stuff)
} # sub populateGene


sub populateElectronicPath {		# should we split locus into another column, strip, or leave as is ?
  $result = $dbh->do( "DROP TABLE h_pap_electronic_path" );
  $result = $dbh->do( "DROP TABLE pap_electronic_path" );

  my $papt = 'pap_electronic_path';
  $result = $dbh->do( "CREATE TABLE $papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone)" ); 
  $result = $dbh->do( "CREATE INDEX ${papt}_idx ON $papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE $papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO cecilia;" );
  
  $result = $dbh->do( "CREATE TABLE h_$papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone)" ); 
  $result = $dbh->do( "CREATE INDEX h_${papt}_idx ON h_$papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE h_$papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO cecilia;" );

  my %hash;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'; ");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{status}{$row[0]}++; }

  my $type = 'electronic_path_type';
  $result = $dbh->prepare( "SELECT * FROM wpa_$type ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($row[1]);
    if ($row[3] eq 'valid') { 
        $hash{$type}{$row[0]}{$row[2]}{$row[1]}{data} = $row[1];
        if ($row[4]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{curator} = $row[4]; }
        if ($row[5]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{timestamp} = $row[5]; } }
      else { 
        delete $hash{$type}{$row[0]}{$row[2]}{$row[1]}; } }
#         $hash{$type}{$row[0]}{$row[2]}{$row[1]}{data} = $row[1];
#         if ($row[4]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{curator} = $row[4]; }
#         if ($row[5]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{timestamp} = $row[5]; }

  foreach my $joinkey (sort keys %{ $hash{status} }) {
    my $count = 0;
    foreach my $pdf_type (sort keys %{ $hash{$type}{$joinkey} }) {
      foreach my $data (sort keys %{ $hash{$type}{$joinkey}{$pdf_type} }) {
        next unless $data;
        my $curator = $hash{$type}{$joinkey}{$pdf_type}{$data}{curator};
        my $timestamp = $hash{$type}{$joinkey}{$pdf_type}{$data}{timestamp};
        $count++; my $order = "'$count'"; 
        ($data) = &filterForPg($data);
        unless ($curator) { 
#           print "NO CURATOR $joinkey T $type D $data\n"; 
          $curator = 'two1841'; }
#         print "$type\t$joinkey\t$data\t$order\t$curator\t$timestamp\n";
        $result = $dbh->do( "INSERT INTO $papt VALUES ('$joinkey', '$data', $order, '$curator', '$timestamp')" );
        $result = $dbh->do( "INSERT INTO h_$papt VALUES ('$joinkey', '$data', $order, '$curator', '$timestamp')" );
  } } }
} # sub populateElectronicPath


sub populateNonXml {		# populate tables that have data not in xml (and are not special)
#   my @not_xml_tables = qw( abstract affiliation author contained_in editor fulltext_url ignore publisher remark erratum_in internal_comment curation_flags );	# internal_comment and curation_flags are new tables, erratum_in is currently unclear because wiki says 3 entries, but type 14 says 21 entries, so ignoring it.
  my @not_xml_tables = qw( abstract affiliation author contained_in editor fulltext_url publisher remark internal_comment );
#   my @not_xml_tables = qw( internal_comment );

  my %type_map;			# most wpa tables map to same pap tables, but comment maps to internal_comment
  foreach my $type (@not_xml_tables) { $type_map{$type} = $type; }
  $type_map{internal_comment} = 'comments';

  foreach my $type (@not_xml_tables) {
#     if ($multi{$type}) { print "MULTI $type\n"; }
    $result = $dbh->do( "DELETE FROM pap_$type;" );
    $result = $dbh->do( "DELETE FROM h_pap_$type;" ); }

  my %hash;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'; ");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{status}{$row[0]}++; }

  foreach my $type (@not_xml_tables) {
    $result = $dbh->prepare( "SELECT * FROM wpa_$type_map{$type} ORDER BY wpa_timestamp" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless ($row[1]);
      unless ($row[2]) { $row[2] = 'NULL'; }
      if ($row[3] eq 'valid') { 
          $hash{$type}{$row[0]}{$row[2]}{$row[1]}{data} = $row[1];
          if ($row[4]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{curator} = $row[4]; }
          if ($row[5]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{timestamp} = $row[5]; } }
        else { 
#           $hash{$type}{$row[0]}{$row[2]}{$row[1]}{data} = $row[1];
#           if ($row[4]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{curator} = $row[4]; }
#           if ($row[5]) { $hash{$type}{$row[0]}{$row[2]}{$row[1]}{timestamp} = $row[5]; } 
          delete $hash{$type}{$row[0]}{$row[2]}{$row[1]}; } }

    foreach my $joinkey (sort keys %{ $hash{status} }) {
      my $count = 0;
      foreach my $old_order (sort keys %{ $hash{$type}{$joinkey} }) {
        foreach my $data (sort keys %{ $hash{$type}{$joinkey}{$old_order} }) {
          next unless $data;
          my $curator = $hash{$type}{$joinkey}{$old_order}{$data}{curator};
          my $timestamp = $hash{$type}{$joinkey}{$old_order}{$data}{timestamp};
          my $order = "NULL"; 
          if ($single{$type}) { 1; }
            elsif ($multi{$type}) { 
              if ($old_order ne "NULL") { $order = "'$old_order'"; }
                else { $count++; $order = "'$count'"; } }
            else { print "ERR neither single nor multi $type\n"; }
          ($data) = &filterForPg($data);
          unless ($curator) { 
#             print "NO CURATOR $joinkey T $type D $data\n"; 
            $curator = 'two1841'; }
#           print "$type\t$joinkey\t$data\t$order\t$curator\t$timestamp\n";
          if ( ($type eq 'contained_in') && ($data =~ m/WBPaper(\d+)/ ) ) { $data = $1; }	# strip WBPaper from it 2010 03 24
          $result = $dbh->do( "INSERT INTO pap_$type VALUES ('$joinkey', '$data', $order, '$curator', '$timestamp')" );
          $result = $dbh->do( "INSERT INTO h_pap_$type VALUES ('$joinkey', '$data', $order, '$curator', '$timestamp')" );
    } } }
  } # foreach my $type (@not_xml_tables)
} # sub populateNonXml

sub populateUnlessXml {		# populate stuff that would normally come from xml for papers that don't have pmid 
  my @unique_ref = qw( title journal volume pages year primary_data type );
#   my @unique_ref = qw( type primary_data );
  foreach my $type (@unique_ref) {
    $result = $dbh->do( "DELETE FROM pap_$type WHERE joinkey IN (SELECT joinkey FROM pap_status WHERE pap_status = 'valid' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid'));" );
    $result = $dbh->do( "DELETE FROM h_pap_$type WHERE joinkey IN (SELECT joinkey FROM pap_status WHERE pap_status = 'valid' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid'));" ); }

  my %hash;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid'); ");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{status}{$row[0]}++; }

  foreach my $type (@unique_ref) {
    next if ($type eq 'primary_data');	# infer this from type
    $result = $dbh->prepare( "SELECT * FROM wpa_$type ORDER BY wpa_timestamp" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
# if ($row[0] eq '00005120') { print "ROW @row ROW\n"; }
# if ($row[0] eq '00024942') { print "ROW @row ROW\n"; }
      if ($row[3] eq 'valid') { 
          $hash{$type}{$row[0]}{data} = $row[1];
          if ($row[4]) { $hash{$type}{$row[0]}{curator} = $row[4]; }
          if ($row[5]) { $hash{$type}{$row[0]}{timestamp} = $row[5]; } }
        else { 
          delete $hash{$type}{$row[0]}; }
#           $hash{$type}{$row[0]}{data} = $row[1];
#           if ($row[4]) { $hash{$type}{$row[0]}{curator} = $row[4]; }
#           if ($row[5]) { $hash{$type}{$row[0]}{timestamp} = $row[5]; } 
    }

    foreach my $joinkey (sort keys %{ $hash{status} }) {
# if ($joinkey eq '00005120') { print "IN ROW\n"; }
# if ($joinkey eq '00024942') { print "IN ROW\n"; }
      next unless $hash{$type}{$joinkey}{data};
      my $data = $hash{$type}{$joinkey}{data};
      if ($type eq 'pages') { if ($data =~ m/\/\//) { $data =~ s/\/\//-/g; } }
      if ($type eq 'volume') { if ($data =~ m/^(.*?)\/\/(.*?)$/) { $data = "$1($2)"; } }
      my $curator = $hash{$type}{$joinkey}{curator};
      unless ($curator) {
        print "NO CURATOR $type $joinkey $data\n"; 
        $curator = 'two1841'; }
      my $timestamp = $hash{$type}{$joinkey}{timestamp};
# if ($joinkey eq '00005120') { print "DATA $data $curator $timestamp\n"; }
# if ($joinkey eq '00024942') { print "DATA $data $curator $timestamp\n"; }
      my $order = "NULL";
      if ($type eq 'type') { 
        my $primary_data = '';
        if ($primary_data{$data}) { $primary_data = $primary_data{$data}; }
        $order = "'1'";	 
#         print "Joinkey\t$joinkey\tPrimary\t$primary_data\n"; 
        $result = $dbh->do( "INSERT INTO pap_primary_data VALUES ('$joinkey', '$primary_data', NULL, '$curator', '$timestamp')" );
        $result = $dbh->do( "INSERT INTO h_pap_primary_data VALUES ('$joinkey', '$primary_data', NULL, '$curator', '$timestamp')" );
      }		# order only exists for type, and is always 1 since there's no previous data
#       if ( ($type eq 'type') && ( ($data ne '3') && ($data ne '4') ) ) { print "NEWTYPE\n"; }
      ($data) = &filterForPg($data);
      next if ($data =~ m/^\s*\-C/);            # skip comments only
#       print "$type\t$joinkey\t$data\t$curator\t$timestamp\n";
      $result = $dbh->do( "INSERT INTO pap_$type VALUES ('$joinkey', '$data', $order, '$curator', '$timestamp')" );
      $result = $dbh->do( "INSERT INTO h_pap_$type VALUES ('$joinkey', '$data', $order, '$curator', '$timestamp')" );
    }
  }
} # sub populateUnlessXml

sub populateFromXml {		# POPULATE SOME REFERENCE FROM XML, not dealing with type
#   my @unique_ref = qw( title journal volume pages year month day affiliation pubmed_final primary_data type );	# kimberly doesn't want affiliation from xml
  my @unique_ref = qw( title journal volume pages year month day pubmed_final primary_data type );
  foreach my $type (@unique_ref) {
    $result = $dbh->do( "DELETE FROM pap_$type;" );
    $result = $dbh->do( "DELETE FROM h_pap_$type;" );
  }

#   my %affi;
#   
#   $result = $dbh->prepare( "SELECT * FROM pap_affiliation" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) { $affi{$row[0]} = $row[1]; }

  my %month_to_num;
  $month_to_num{Jan} = '1';
  $month_to_num{Feb} = '2';
  $month_to_num{Mar} = '3';
  $month_to_num{Apr} = '4';
  $month_to_num{May} = '5';
  $month_to_num{Jun} = '6';
  $month_to_num{Jul} = '7';
  $month_to_num{Aug} = '8';
  $month_to_num{Sep} = '9';
  $month_to_num{Oct} = '10';
  $month_to_num{Nov} = '11';
  $month_to_num{Dec} = '12';

  my %type_index;		# type to type_index mapping
  $type_index{"Journal_article"} = '1';  
  $type_index{"Review"} = '2';  
  $type_index{"Meeting_abstract"} = '3';  
  $type_index{"Gazette_article"} = '4';  
  $type_index{"Book_chapter"} = '5';  
  $type_index{"News"} = '6';  
  $type_index{"Email"} = '7';  
  $type_index{"Book"} = '8';  
  $type_index{"Historical_article"} = '9';  
  $type_index{"Comment"} = '10'; 
  $type_index{"Letter"} = '11'; 
  $type_index{"Monograph"} = '12'; 
  $type_index{"Editorial"} = '13'; 
  $type_index{"Published_erratum"} = '14'; 
  $type_index{"Retracted_publication"} = '15'; 
  $type_index{"Technical_report"} = '16'; 
  $type_index{"Other"} = '17'; 
  $type_index{"Wormbook"} = '18'; 
  $type_index{"Interview"} = '19'; 
  $type_index{"Lectures"} = '20'; 
  $type_index{"Congresses"} = '21'; 
  $type_index{"Interactive_tutorial"} = '22'; 
  $type_index{"Biography"} = '23'; 
  $type_index{"Directory"} = '24'; 

  my %specific_type;		# types that don't become "Other" and aren't only Journal_article
  $specific_type{2} = 'Review';
  $specific_type{6} = 'News';
  $specific_type{9} = 'Historical_article';
  $specific_type{10} = 'Comment';
  $specific_type{11} = 'Letter';
  $specific_type{12} = 'Monograph';
  $specific_type{13} = 'Editorial';
  $specific_type{14} = 'Published_erratum';
  $specific_type{15} = 'Retracted_publication';
  $specific_type{16} = 'Technical_report';
  $specific_type{19} = 'Interview';
  $specific_type{20} = 'Lectures';
  $specific_type{21} = 'Congresses';
  $specific_type{22} = 'Interactive_tutorial';
  $specific_type{23} = 'Biography';
  $specific_type{24} = 'Directory';
  
  my %final_pmid; my %entered_pmid;
  $/ = undef;
  my (@xml) = </home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final/xml/*>;
  my (@done_xml) = </home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/*>;
  foreach (@done_xml) { push @xml, $_; }
  foreach my $xml (@xml) {		# foreach xml that we have
    my ($id) = $xml =~ m/\/(\d+)$/;
    next if ($final_pmid{$id});		# skip XML that was already final by status medline

    open (IN, "<$xml") or die "Cannot open $xml : $!";
    my $xml_data = <IN>;
    close (IN) or die "Cannot close $xml : $!";

    my $pubmed_final = 'not_final';
    if ($xml_data =~ /\<MedlineCitation Owner=\"NLM\" Status=\"MEDLINE\"\>/) { 
      $pubmed_final = 'final'; 		# final version
      $final_pmid{$id}++; }		# store that the pmid already has a final version

    my $skip = 0;			# skip flag if bad
    if ($entered_pmid{$id}) { 
      if ($pubmed_final eq 'final') { print "ALREADY entered $id now MEDLINE fix double entries\n"; }
      else { $skip++; } } 			# print "ALREADY entered $id still BAD\n"; $skip++; 
    next if $skip;			# skip things already entered that are still bad
    $entered_pmid{$id}++;		# track what's been entered

    my ($title) = $xml_data =~ /\<ArticleTitle\>(.+?)\<\/ArticleTitle\>/i;
    my ($journal) = $xml_data =~ /<MedlineTA>(.+?)\<\/MedlineTA\>/i;
    my ($pages) = $xml_data =~ /\<MedlinePgn\>(.+?)\<\/MedlinePgn\>/i;
    my ($volume) = $xml_data =~ /\<Volume\>(.+?)\<\/Volume\>/i;
    my $year = ''; my $month = ''; my $day = '';
    if ( $xml_data =~ /\<PubDate\>(.+?)\<\/PubDate\>/si ) {
      my ($PubDate) = $xml_data =~ /\<PubDate\>(.+?)\<\/PubDate\>/si;
      if ( $PubDate =~ /\<Year\>(.+?)\<\/Year\>/i ) { $year = $1; }
      if ( $PubDate =~ /\<Month\>(.+?)\<\/Month\>/i ) { $month = $1; 
        if ($month_to_num{$month}) { $month = $month_to_num{$month}; } 
        else { 		# in one case 00013115 / pmid12167287, it says Jul-Sep
          foreach my $key (keys %month_to_num) {	# so see if it begins with any month and use that
            if ($month =~ m/^$key/) { $month = $month_to_num{$key}; } } } }
      if ( $PubDate =~ /\<Day\>(.+?)\<\/Day\>/i ) { $day = $1; } 
      if ($year eq '') {
        if ($PubDate =~ m/\<MedlineDate\>(.*?)\<\/MedlineDate\>/si) {
          my $medDate = $1;
          if ($medDate =~ m/(19\d{2})/) { $year = $1; }
            elsif ($medDate =~ m/(20\d{2})/) { $year = $1; }
          if ($medDate =~ m/([A-Z][a-z][a-z])/) { 
            my $maybeMonth = $1; 
            if ($month_to_num{$maybeMonth}) { $month = $month_to_num{$maybeMonth}; } } } }
    }
    my ($abstract) = $xml_data =~ /\<AbstractText\>(.+?)\<\/AbstractText\>/i;
#     my ($affiliation) = $xml_data =~ /\<Affiliation\>(.+?)\<\/Affiliation\>/i;
    my (@types) = $xml_data =~ /\<PublicationType\>(.+?)\<\/PublicationType\>/gi;
    ($title) = &filterForPg($title);
    ($journal) = &filterForPg($journal);
    ($pages) = &filterForPg($pages);
    ($volume) = &filterForPg($volume);
    ($year) = &filterForPg($year);
    ($month) = &filterForPg($month);
    ($day) = &filterForPg($day);
#     ($affiliation) = &filterForPg($affiliation);
    ($abstract) = &filterForPg($abstract);
    foreach (@types) { ($_) = &filterForPg($_); }
#   my ($doi) = $page =~ /\<ArticleId IdType=\"doi\"\>(.+?)\<\/ArticleId\>/i; $doi = 'doi' . $doi;
  
    my $curator = 'two10877';		# pubmed
    my $timestamp = 'CURRENT_TIMESTAMP';
  
    unless ($id) { print "XML $xml END\n"; }
  
    if ($idents{$id}) {		# if the pmid maps to a wbpaper joinkey
      my $joinkey = $idents{$id};
#       next unless $affiliation;
#       unless ($affi{$joinkey}) { print "$joinkey\t$id\t$affiliation\n"; }
#     print "Title $joinkey $id $title\n";
      if ($title) {
        $result = $dbh->do( "INSERT INTO pap_title VALUES ('$joinkey', '$title', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_title VALUES ('$joinkey', '$title', NULL, '$curator', $timestamp)" ); }
      if ($journal) {
        $result = $dbh->do( "INSERT INTO pap_journal VALUES ('$joinkey', '$journal', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_journal VALUES ('$joinkey', '$journal', NULL, '$curator', $timestamp)" ); }
      if ($pages) {
        $result = $dbh->do( "INSERT INTO pap_pages VALUES ('$joinkey', '$pages', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_pages VALUES ('$joinkey', '$pages', NULL, '$curator', $timestamp)" ); }
      if ($volume) {
        $result = $dbh->do( "INSERT INTO pap_volume VALUES ('$joinkey', '$volume', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_volume VALUES ('$joinkey', '$volume', NULL, '$curator', $timestamp)" ); }
      if ($year) {
        $result = $dbh->do( "INSERT INTO pap_year VALUES ('$joinkey', '$year', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_year VALUES ('$joinkey', '$year', NULL, '$curator', $timestamp)" ); }
      if ($month) {
        $result = $dbh->do( "INSERT INTO pap_month VALUES ('$joinkey', '$month', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_month VALUES ('$joinkey', '$month', NULL, '$curator', $timestamp)" ); }
      if ($day) {
        $result = $dbh->do( "INSERT INTO pap_day VALUES ('$joinkey', '$day', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_day VALUES ('$joinkey', '$day', NULL, '$curator', $timestamp)" ); }
#       if ($affiliation) {
#         $result = $dbh->do( "INSERT INTO pap_affiliation VALUES ('$joinkey', '$affiliation', NULL, '$curator', $timestamp)" );
#         $result = $dbh->do( "INSERT INTO h_pap_affiliation VALUES ('$joinkey', '$affiliation', NULL, '$curator', $timestamp)" ); }
      if ($pubmed_final) {
        $result = $dbh->do( "INSERT INTO pap_pubmed_final VALUES ('$joinkey', '$pubmed_final', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_pubmed_final VALUES ('$joinkey', '$pubmed_final', NULL, '$curator', $timestamp)" ); }
      if ($types[0]) {
        my %types;
        foreach my $type (@types) {
            ($type) = ucfirst(lc($type)); $type =~ s/\s+/_/g;
          if ($type_index{$type}) { 
# TEST THIS FOR 00026893  pmid15965246  which has extra types going in
            my $type_id = $type_index{$type};
            $types{$type_id}++;
# print "Joinkey\t$joinkey\tType\t$type\t$type_id\n"; 
          }	# else { $types{17}++; }	# other ????
        } # foreach my $type (@types)
        my $primary_data = '';
        my @actual_types;
        foreach my $type_id (keys %types) { 	# for each type_id, if it's specific, use that type_id
          if ($specific_type{$type_id}) { push @actual_types, $type_id; } }
        unless ($actual_types[0]) { 		# if there are no specific types and it's journal, use that
          if ($types{1}) { push @actual_types, 1; } }
        unless ($actual_types[0]) { 		# if there are no types, use Other
          push @actual_types, 17; }
        my $count = 0;
        foreach my $type_id (@actual_types) {
          $count++;
          $result = $dbh->do( "INSERT INTO pap_type VALUES ('$joinkey', '$type_id', '$count', '$curator', $timestamp)" );
          $result = $dbh->do( "INSERT INTO h_pap_type VALUES ('$joinkey', '$type_id', '$count', '$curator', $timestamp)" );
          if ($primary_data{$type_id}) {		# if there's a primary_data entry for this type_id
            next if $primary_data eq 'primary';		# skip if already primary
            if ($primary_data{$type_id} eq 'primary') { $primary_data = $primary_data{$type_id}; next; }
            next if $primary_data eq 'not_primary';	# skip if already not_primary
            if ($primary_data{$type_id} eq 'not_primary') { $primary_data = $primary_data{$type_id}; next; }
            $primary_data = $primary_data{$type_id};	# assign to not_designated by default
          }
# print "Joinkey\t$joinkey\tTypeID\t$type_id\n"; 
        }
# print "Joinkey\t$joinkey\tPrimary\t$primary_data\n"; 
        $result = $dbh->do( "INSERT INTO pap_primary_data VALUES ('$joinkey', '$primary_data', NULL, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO h_pap_primary_data VALUES ('$joinkey', '$primary_data', NULL, '$curator', $timestamp)" );
      } # if ($type)
    } # if ($idents{$id})

#   print "ID $id\n";
  } # foreach my $xml (@xml)
  $/ = "\n";
} # sub populateFromXml

sub populateExtraTypes {
  my %extraBook_chapter;
  $extraBook_chapter{"00002172"}++;
  $extraBook_chapter{"00002244"}++;
  $extraBook_chapter{"00002245"}++;
  $extraBook_chapter{"00002246"}++;
  $extraBook_chapter{"00002247"}++;
  $extraBook_chapter{"00002248"}++;
  $extraBook_chapter{"00002249"}++;
  $extraBook_chapter{"00002250"}++;
  $extraBook_chapter{"00002251"}++;
  $extraBook_chapter{"00002252"}++;
  $extraBook_chapter{"00002253"}++;
  $extraBook_chapter{"00002254"}++;
  $extraBook_chapter{"00002255"}++;
  $extraBook_chapter{"00002256"}++;
  $extraBook_chapter{"00002257"}++;
  $extraBook_chapter{"00002258"}++;
  $extraBook_chapter{"00002259"}++;
  $extraBook_chapter{"00002260"}++;
  $extraBook_chapter{"00002261"}++;
  $extraBook_chapter{"00002262"}++;
  $extraBook_chapter{"00002263"}++;
  $extraBook_chapter{"00002264"}++;
  $extraBook_chapter{"00002265"}++;
  $extraBook_chapter{"00002266"}++;
  $extraBook_chapter{"00002267"}++;
  $extraBook_chapter{"00002268"}++;
  $extraBook_chapter{"00002269"}++;
  $extraBook_chapter{"00024687"}++;
  $extraBook_chapter{"00029144"}++;
  $extraBook_chapter{"00031351"}++;
  $extraBook_chapter{"00032010"}++;

  my %extraBook_chapterAndWormBook;
  $extraBook_chapterAndWormBook{"00027222"}++;
  $extraBook_chapterAndWormBook{"00027223"}++;
  $extraBook_chapterAndWormBook{"00027224"}++;
  $extraBook_chapterAndWormBook{"00027225"}++;
  $extraBook_chapterAndWormBook{"00027226"}++;
  $extraBook_chapterAndWormBook{"00027227"}++;
  $extraBook_chapterAndWormBook{"00027228"}++;
  $extraBook_chapterAndWormBook{"00027229"}++;
  $extraBook_chapterAndWormBook{"00027230"}++;
  $extraBook_chapterAndWormBook{"00027231"}++;
  $extraBook_chapterAndWormBook{"00027232"}++;
  $extraBook_chapterAndWormBook{"00027233"}++;
  $extraBook_chapterAndWormBook{"00027234"}++;
  $extraBook_chapterAndWormBook{"00027235"}++;
  $extraBook_chapterAndWormBook{"00027236"}++;
  $extraBook_chapterAndWormBook{"00027237"}++;
  $extraBook_chapterAndWormBook{"00027238"}++;
  $extraBook_chapterAndWormBook{"00027239"}++;
  $extraBook_chapterAndWormBook{"00027240"}++;
  $extraBook_chapterAndWormBook{"00027241"}++;
  $extraBook_chapterAndWormBook{"00027242"}++;
  $extraBook_chapterAndWormBook{"00027243"}++;
  $extraBook_chapterAndWormBook{"00027244"}++;
  $extraBook_chapterAndWormBook{"00027245"}++;
  $extraBook_chapterAndWormBook{"00027246"}++;
  $extraBook_chapterAndWormBook{"00027247"}++;
  $extraBook_chapterAndWormBook{"00027248"}++;
  $extraBook_chapterAndWormBook{"00027249"}++;
  $extraBook_chapterAndWormBook{"00027250"}++;
  $extraBook_chapterAndWormBook{"00027251"}++;
  $extraBook_chapterAndWormBook{"00027252"}++;
  $extraBook_chapterAndWormBook{"00027253"}++;
  $extraBook_chapterAndWormBook{"00027254"}++;
  $extraBook_chapterAndWormBook{"00027255"}++;
  $extraBook_chapterAndWormBook{"00027256"}++;
  $extraBook_chapterAndWormBook{"00027257"}++;
  $extraBook_chapterAndWormBook{"00027258"}++;
  $extraBook_chapterAndWormBook{"00027259"}++;
  $extraBook_chapterAndWormBook{"00027260"}++;
  $extraBook_chapterAndWormBook{"00027261"}++;
  $extraBook_chapterAndWormBook{"00027262"}++;
  $extraBook_chapterAndWormBook{"00027263"}++;
  $extraBook_chapterAndWormBook{"00027264"}++;
  $extraBook_chapterAndWormBook{"00027265"}++;
  $extraBook_chapterAndWormBook{"00027266"}++;
  $extraBook_chapterAndWormBook{"00027267"}++;
  $extraBook_chapterAndWormBook{"00027268"}++;
  $extraBook_chapterAndWormBook{"00027269"}++;
  $extraBook_chapterAndWormBook{"00027270"}++;
  $extraBook_chapterAndWormBook{"00027271"}++;
  $extraBook_chapterAndWormBook{"00027272"}++;
  $extraBook_chapterAndWormBook{"00027273"}++;
  $extraBook_chapterAndWormBook{"00027274"}++;
  $extraBook_chapterAndWormBook{"00027275"}++;
  $extraBook_chapterAndWormBook{"00027276"}++;
  $extraBook_chapterAndWormBook{"00027277"}++;
  $extraBook_chapterAndWormBook{"00027278"}++;
  $extraBook_chapterAndWormBook{"00027279"}++;
  $extraBook_chapterAndWormBook{"00027280"}++;
  $extraBook_chapterAndWormBook{"00027281"}++;
  $extraBook_chapterAndWormBook{"00027282"}++;
  $extraBook_chapterAndWormBook{"00027283"}++;
  $extraBook_chapterAndWormBook{"00027284"}++;
  $extraBook_chapterAndWormBook{"00027285"}++;
  $extraBook_chapterAndWormBook{"00027286"}++;
  $extraBook_chapterAndWormBook{"00027287"}++;
  $extraBook_chapterAndWormBook{"00027288"}++;
  $extraBook_chapterAndWormBook{"00027289"}++;
  $extraBook_chapterAndWormBook{"00027290"}++;
  $extraBook_chapterAndWormBook{"00027291"}++;
  $extraBook_chapterAndWormBook{"00027292"}++;
  $extraBook_chapterAndWormBook{"00027293"}++;
  $extraBook_chapterAndWormBook{"00027294"}++;
  $extraBook_chapterAndWormBook{"00027295"}++;
  $extraBook_chapterAndWormBook{"00027296"}++;
  $extraBook_chapterAndWormBook{"00027297"}++;
  $extraBook_chapterAndWormBook{"00027298"}++;
  $extraBook_chapterAndWormBook{"00027299"}++;
  $extraBook_chapterAndWormBook{"00027300"}++;
  $extraBook_chapterAndWormBook{"00027301"}++;
  $extraBook_chapterAndWormBook{"00027302"}++;
  $extraBook_chapterAndWormBook{"00027304"}++;
  $extraBook_chapterAndWormBook{"00027305"}++;
  $extraBook_chapterAndWormBook{"00027306"}++;
  $extraBook_chapterAndWormBook{"00027307"}++;
  $extraBook_chapterAndWormBook{"00027309"}++;
  $extraBook_chapterAndWormBook{"00027310"}++;
  $extraBook_chapterAndWormBook{"00027311"}++;
  $extraBook_chapterAndWormBook{"00027312"}++;
  $extraBook_chapterAndWormBook{"00027313"}++;
  $extraBook_chapterAndWormBook{"00027314"}++;
  $extraBook_chapterAndWormBook{"00027315"}++;
  $extraBook_chapterAndWormBook{"00027316"}++;
  $extraBook_chapterAndWormBook{"00027317"}++;
  $extraBook_chapterAndWormBook{"00027318"}++;
  $extraBook_chapterAndWormBook{"00027319"}++;
  $extraBook_chapterAndWormBook{"00029012"}++;
  $extraBook_chapterAndWormBook{"00029016"}++;
  $extraBook_chapterAndWormBook{"00029019"}++;
  $extraBook_chapterAndWormBook{"00029022"}++;
  $extraBook_chapterAndWormBook{"00029033"}++;
  $extraBook_chapterAndWormBook{"00031286"}++;
  $extraBook_chapterAndWormBook{"00031287"}++;
  $extraBook_chapterAndWormBook{"00031288"}++;
  $extraBook_chapterAndWormBook{"00031289"}++;
  $extraBook_chapterAndWormBook{"00031290"}++;
  $extraBook_chapterAndWormBook{"00031291"}++;
  $extraBook_chapterAndWormBook{"00031292"}++;
  $extraBook_chapterAndWormBook{"00031388"}++;
  $extraBook_chapterAndWormBook{"00031293"}++;
  $extraBook_chapterAndWormBook{"00031414"}++;
  $extraBook_chapterAndWormBook{"00031415"}++;
  $extraBook_chapterAndWormBook{"00031646"}++;
  $extraBook_chapterAndWormBook{"00032172"}++;
  $extraBook_chapterAndWormBook{"00032226"}++;
  $extraBook_chapterAndWormBook{"00032944"}++;
  $extraBook_chapterAndWormBook{"00035143"}++;
  $extraBook_chapterAndWormBook{"00035958"}++;

  my %type;
  $result = $dbh->prepare( "SELECT * FROM pap_type" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $type{$row[1]}{$row[0]}++;
    if ($type{amount}{$row[0]}) {
      if ($type{amount}{$row[0]} < $row[2]) { $type{amount}{$row[0]} = $row[2]; } }
    else { $type{amount}{$row[0]} = $row[2]; }
  }

  my $curator = 'two1843';
  my $timestamp = 'CURRENT_TIMESTAMP';
  foreach my $joinkey (sort {$a<=>$b} keys %extraBook_chapter) {
    my $order = $type{amount}{$joinkey}; 
    if ($type{5}{$joinkey}) { print "Already 5 in $joinkey\n"; }
      else { $order++;
#         print "$joinkey\t5\t$order\ttwo1843\tCurrent\n";
        $result = $dbh->do( "INSERT INTO h_pap_type VALUES ('$joinkey', '5', $order, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO pap_type VALUES ('$joinkey', '5', $order, '$curator', $timestamp)" ); 
    }
  }
  foreach my $joinkey (sort {$a<=>$b} keys %extraBook_chapterAndWormBook) {
    my $order = $type{amount}{$joinkey}; 
    if ($type{5}{$joinkey}) { print "Already 5 in $joinkey\n"; }
      else { $order++;
#         print "$joinkey\t5\t$order\ttwo1843\tCurrent\n";
        $result = $dbh->do( "INSERT INTO h_pap_type VALUES ('$joinkey', '5', $order, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO pap_type VALUES ('$joinkey', '5', $order, '$curator', $timestamp)" ); 
    }
    if ($type{18}{$joinkey}) { print "Already 18 in $joinkey\n"; }
      else { $order++;
#         print "$joinkey\t18\t$order\ttwo1843\tCurrent\n";
        $result = $dbh->do( "INSERT INTO h_pap_type VALUES ('$joinkey', '18', $order, '$curator', $timestamp)" );
        $result = $dbh->do( "INSERT INTO pap_type VALUES ('$joinkey', '18', $order, '$curator', $timestamp)" ); 
    }
  }
} # sub populateExtraTypes

sub populateStatusIdentifier {		# TO POPULATE THE TABLES : status, identifier
#   my @status_identifier = qw( status identifier );
#   foreach my $table (@status_identifier) { # }
  foreach my $table (@pap_tables) { 
    $result = $dbh->do( "DELETE FROM h_pap_$table" );
    $result = $dbh->do( "DELETE FROM pap_$table" ); }
  
  my %hash;
  
  $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { 
        $hash{status}{$row[0]}{valid} = 'valid';
        $hash{status}{$row[0]}{data} = $row[1];
        if ($row[4]) { $hash{status}{$row[0]}{curator} = $row[4]; }
        if ($row[5]) { $hash{status}{$row[0]}{timestamp} = $row[5]; } }
      else { 
        $hash{status}{$row[0]}{valid} = 'invalid';
        $hash{status}{$row[0]}{data} = $row[1];
        if ($row[4]) { $hash{status}{$row[0]}{curator} = $row[4]; }
        if ($row[5]) { $hash{status}{$row[0]}{timestamp} = $row[5]; }
#         my (@values) = keys %{ $hash{status}{$row[0]} };
#         if (scalar @values < 1) { delete $hash{status}{$row[0]}; }
      }
  } # while (my @row = $result->fetchrow)
  
  $result = $dbh->prepare( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { 
        $hash{identifier}{$row[0]}{$row[1]}{curator} = $row[4];
        $hash{identifier}{$row[0]}{$row[1]}{timestamp} = $row[5]; }
      else { delete $hash{identifier}{$row[0]}{$row[1]}; }
  } # while (my @row = $result->fetchrow)

  my $type = 'status';
  foreach my $joinkey (sort keys %{ $hash{$type} }) {
    my $data = $hash{$type}{$joinkey}{data};
    my $valid = $hash{$type}{$joinkey}{valid};
    my $curator = $hash{$type}{$joinkey}{curator};
    my $timestamp = $hash{$type}{$joinkey}{timestamp};
#       print "$joinkey\t$data\t$curator\t$timestamp\n";
    $result = $dbh->do( "INSERT INTO pap_$type VALUES ('$joinkey', '$valid', NULL, '$curator', '$timestamp')" );
    $result = $dbh->do( "INSERT INTO h_pap_$type VALUES ('$joinkey', '$valid', NULL, '$curator', '$timestamp')" );
  }

  my %badPmid;			# no xml in pubmed
  $badPmid{'pmid12591608'}++;
  $badPmid{'pmid14532430'}++;
  $badPmid{'pmid14532626'}++;
  $badPmid{'pmid14532629'}++;
  $badPmid{'pmid14532633'}++;
  $badPmid{'pmid14532635'}++;
  $badPmid{'pmid14731937'}++;
  $badPmid{'pmid15577917'}++;
  $badPmid{'pmid15817570'}++;
  $badPmid{'pmid15902193'}++;
  $badPmid{'pmid16551030'}++;
  $badPmid{'pmid16551054'}++;
  $badPmid{'pmid16652241'}++;
  $badPmid{'pmid17154166'}++;
  $badPmid{'pmid17154292'}++;
  $badPmid{'pmid17169184'}++;
  $badPmid{'pmid17407201'}++;
  $badPmid{'pmid18023125'}++;
  $badPmid{'pmid18050406'}++;
  $badPmid{'pmid18050420'}++;
  $badPmid{'pmid18548071'}++;
  $badPmid{'pmid18677322'}++;
  $badPmid{'pmid18692560'}++;
  $badPmid{'pmid18711361'}++;
  $badPmid{'pmid18725909'}++;
  $badPmid{'pmid18841162'}++;
  $badPmid{'pmid94222994'}++;

  
  $type = 'identifier';
  foreach my $joinkey (sort keys %{ $hash{$type} }) {
    next unless ($hash{status}{$joinkey});
    next unless ($hash{status}{$joinkey}{valid} eq 'valid');
    my $order = 0;
    foreach my $data (sort keys %{ $hash{$type}{$joinkey} } ) {
      next unless $data;
      next if ($badPmid{$data});
      $order++;
      my $curator = $hash{$type}{$joinkey}{$data}{curator};
      my $timestamp = $hash{$type}{$joinkey}{$data}{timestamp};
#         print "$joinkey\t$data\t$curator\t$timestamp\n";
      my $actual_data = $data;
      if ($actual_data =~ m/WBPaper(\d+)/) { $actual_data = $1; }
      $result = $dbh->do( "INSERT INTO pap_$type VALUES ('$joinkey', '$actual_data', '$order', '$curator', '$timestamp')" );
      $result = $dbh->do( "INSERT INTO h_pap_$type VALUES ('$joinkey', '$actual_data', '$order', '$curator', '$timestamp')" );
    }
  }
} # sub populateStatusIdentifier

sub populateErratum {
  my %erratum_in;
  $erratum_in{"00001805"}{"00001892"}++;
  $erratum_in{"00003297"}{"00003344"}++;
  $erratum_in{"00003297"}{"00003456"}++;
  $erratum_in{"00003302"}{"00003457"}++;
  $erratum_in{"00003600"}{"00003688"}++;
  $erratum_in{"00003222"}{"00003750"}++;
  $erratum_in{"00003638"}{"00003800"}++;
  $erratum_in{"00004137"}{"00004301"}++;
  $erratum_in{"00004835"}{"00005285"}++;
  $erratum_in{"00005127"}{"00005304"}++;
  $erratum_in{"00005344"}{"00005412"}++;
  $erratum_in{"00004978"}{"00005701"}++;
  $erratum_in{"00005292"}{"00005746"}++;
  $erratum_in{"00024886"}{"00024897"}++;
  $erratum_in{"00003297"}{"00026886"}++;
  $erratum_in{"00024920"}{"00026902"}++;
  $erratum_in{"00026758"}{"00026911"}++;
  $erratum_in{"00026636"}{"00027056"}++;
  $erratum_in{"00026959"}{"00027096"}++;
  $erratum_in{"00031151"}{"00031373"}++;
  $erratum_in{"00030896"}{"00032419"}++;
  my $curator = 'two1843';
  my $timestamp = 'CURRENT_TIMESTAMP';
  foreach my $joinkey (sort keys %erratum_in) {
    my $order = 0;
    foreach my $erratum_in (sort keys %{ $erratum_in{$joinkey} }) {
      $order++;
      $result = $dbh->do( "INSERT INTO pap_erratum_in VALUES ('$joinkey', '$erratum_in', $order, '$curator', $timestamp)" );
      $result = $dbh->do( "INSERT INTO h_pap_erratum_in VALUES ('$joinkey', '$erratum_in', $order, '$curator', $timestamp)" );
    }
  }
} # sub populateErratum


sub populateTypeIndex {
  $result = $dbh->do( "DELETE FROM h_pap_type_index" );
  $result = $dbh->do( "DELETE FROM pap_type_index" ); 
  
  my %hash;
  
  $result = $dbh->prepare( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { 
        $hash{type_index}{$row[0]}{$row[1]}{curator} = $row[4];
        $hash{type_index}{$row[0]}{$row[1]}{timestamp} = $row[5]; }
      else { 
        delete $hash{type_index}{$row[0]}{$row[1]}; 
        my (@values) = keys %{ $hash{type_index}{$row[0]} };
        if (scalar @values < 1) { delete $hash{type_index}{$row[0]}; } } }
  
  foreach my $type (sort keys %hash) {
    foreach my $type_id (sort {$a<=>$b} keys %{ $hash{$type} }) {
      foreach my $data (sort keys %{ $hash{$type}{$type_id} } ) {
        next unless $data;
        my $curator = $hash{$type}{$type_id}{$data}{curator};
        my $timestamp = $hash{$type}{$type_id}{$data}{timestamp};
        print "$type_id\t$data\t$curator\t$timestamp\n";
        $result = $dbh->do( "INSERT INTO pap_$type VALUES ('$type_id', '$data', NULL, '$curator', '$timestamp')" );
        $result = $dbh->do( "INSERT INTO h_pap_$type VALUES ('$type_id', '$data', NULL, '$curator', '$timestamp')" );
} } } } # sub populateTypeIndex



sub getOddJournals {		# GET list of journals that are in valid papers, but aren't in pubmed
  my %hash;
  
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{status}{$row[0]}++; }
  
  $result = $dbh->prepare( "SELECT * FROM pap_journal" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    $hash{journal}{$row[0]} = $row[1]; 
    $hash{existingjournal}{$row[1]}++; }
  
  $result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { 
        $hash{wpatype}{$row[0]}{$row[1]}++; }
      else { delete $hash{wpatype}{$row[0]}{$row[1]}; }
  } # while (my @row = $result->fetchrow)
  
  $result = $dbh->prepare( "SELECT * FROM wpa_journal ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { 
        $hash{wpajournal}{$row[0]}{$row[1]}++; }
      else { delete $hash{wpajournal}{$row[0]}{$row[1]}; }
  } # while (my @row = $result->fetchrow)
  
  
  my %odd_journals;
  foreach my $joinkey (sort keys %{ $hash{status} }) {
    next if ($hash{journal}{$joinkey});
    next unless ($hash{wpatype}{$joinkey}{1});
    if ($hash{wpajournal}{$joinkey}) { 
      foreach my $journal (keys %{ $hash{wpajournal}{$joinkey} }) {
        next if ($hash{existingjournal}{$journal});
        $odd_journals{ $journal }{ $joinkey }++; 
  } } }
  foreach my $odd_journal (sort keys %odd_journals) {
    my @paps;
    foreach my $joinkey ( sort keys %{ $odd_journals{$odd_journal} } ) {
      my @ids = sort keys %{ $all_ids{$joinkey} };
      my $ids = join", ", @ids;
      push @paps, "$joinkey ( $ids )";
    }
    my $count = scalar(@paps);
    my $paps = join"\t", @paps;
    print "$odd_journal\t$count\t$paps\n";
  } # foreach my $odd_journal (sort keys %odd_journals)
} # sub getOddJournals

sub checkAffiliationWrong {
  my %hash;
  
  $result = $dbh->prepare( "SELECT * FROM pap_affiliation" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $hash{$row[0]} = $row[1]; }

  $/ = undef;
  my (@xml) = </home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final/xml/*>;
  my (@done_xml) = </home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/*>;
  foreach (@done_xml) { push @xml, $_; }
  foreach my $xml (@xml) {
    my ($id) = $xml =~ m/\/(\d+)$/;
    open (IN, "<$xml") or die "Cannot open $xml : $!";
    my $xml_data = <IN>;
    close (IN) or die "Cannot close $xml : $!";
    my ($affiliation) = $xml_data =~ /\<Affiliation\>(.+?)\<\/Affiliation\>/i;
    next unless $affiliation;
    if ($idents{$id}) {
      my $joinkey = $idents{$id};
      unless ($hash{$joinkey}) { print "$joinkey\t$id\t$affiliation\n"; }
    }
  }
  $/ = "\n";
} # sub checkAffiliationWrong



__END__


# TO CREATE THE TABLES

# foreach my $table (@pap_tables) { 
#   $result = $dbh->do( "DROP TABLE h_pap_$table" );
#   $result = $dbh->do( "DROP TABLE pap_$table" ); }

foreach my $table (@pap_tables) {
  my $papt = 'pap_' . $table;
  $result = $dbh->do( "CREATE TABLE $papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone )" ); 
  $result = $dbh->do( "CREATE INDEX ${papt}_idx ON $papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE $papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO cecilia;" );

  
  $result = $dbh->do( "CREATE TABLE h_$papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone )" ); 
  $result = $dbh->do( "CREATE INDEX h_${papt}_idx ON h_$papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE h_$papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO cecilia;" );
} # foreach my $table (@pap_tables)

__END__


abstract
affiliation
# allele_curation	# not really used
author
author_index
author_possible
author_sent
author_verified
# checked_out		# FP probably, not needed anymore
# comments		# rename as internal_comment 
contained_in
contains
# date_published	# only 5 entries, gone
editor
# electronic_path_md5	# not used
# electronic_path_type	# replaced with electronic path type
electronic_path
# electronic_type_index	# not used ?
# erratum		# gone need erratum_in / erratum_for
fulltext_url		# the URLs are here and dump to remark tag in .ace
gene
# hardcopy
identifier
ignore			# functional annotation only / non worm
# in_book		# gone, replaced by contained_in / contains
journal
# keyword		# need to dump these into static .ace file for constant appending post-dump
# nematode_paper	# possibly taxon in the future, gone for now
pages
publisher
pubmed_final
remark
# rnai_curation		# move into curation flags
# rnai_int_done		# move into curation flags
title
# transgene_curation	# not really used
type
type_index
volume
year

new :
erratum_in
erratum_for
internal_comment	# populate with  comments
curation_flags		# flag for ``Phenotype2GO'' or blank / rnai_curation / rnai_int_done
primary_data		# primary data / no primary data / not designated
status			# replaces wpa for valid / invalid for whole paper

# affiliation in paper model.  also in #affiliation on author tag, but no longer in postgres author data, and not dumped.

__END__

$result = $dbh->do( "DROP VIEW pap_view" ); 
my @old_pap = qw( pap_affiliation pap_contained pap_email pap_journal pap_paper pap_possible pap_type pap_year pap_author pap_contains pap_inbook pap_page pap_pmid pap_title pap_verified pap_volume );
foreach my $table (@old_pap) { $result = $dbh->do( "DROP TABLE $table" ); }

__END__

my @pap_tables = qw( passwd celegans cnonbristol nematode nonnematode genestudied genesymbol extvariation mappingdata newmutant rnai lsrnai overexpr chemicals mosaic siteaction timeaction genefunc humdis geneint funccomp geneprod otherexpr microarray genereg seqfeat matrices antibody transgene marker invitro domanal covalent structinfo massspec structcorr seqchange newsnp ablationdata cellfunc phylogenetic othersilico supplemental nocuratable comment );


my %dataTable = ();
$dataTable{passwd} = 'passwd';
$dataTable{celegans} = '';
$dataTable{cnonbristol} = '';
$dataTable{nematode} = 'nematode';
$dataTable{nonnematode} = '';
$dataTable{genestudied} = 'rgngene';
$dataTable{genesymbol} = 'genesymbol';
$dataTable{extvariation} = '';
$dataTable{mappingdata} = 'mappingdata';
$dataTable{newmutant} = 'newmutant';
$dataTable{rnai} = 'rnai';
$dataTable{lsrnai} = 'lsrnai';
$dataTable{overexpr} = 'overexpression';
$dataTable{chemicals} = 'chemicals';
$dataTable{mosaid} = 'mosaid';
$dataTable{siteaction} = 'site';
$dataTable{timeaction} = '';
$dataTable{genefunc} = 'genefunction';
$dataTable{humdis} = 'humandiseases';
$dataTable{geneint} = 'geneinteractions';
$dataTable{funccomp} = '';			# functionalcomplementation was in cur_ not in afp_ 
$dataTable{geneprod} = 'geneproduct';
$dataTable{otherexpr} = 'expression';
$dataTable{microarray} = 'microarray';
$dataTable{genereg} = 'generegulation';
$dataTable{seqfeat} = 'sequencefeatures';
$dataTable{matrices} = '';
$dataTable{antibody} = 'antibody';
$dataTable{transgene} = 'transgene';
$dataTable{marker} = '';
$dataTable{invitro} = 'invitro';
$dataTable{domanal} = 'structureinformation';
$dataTable{covalent} = 'covalent';
$dataTable{structinfo} = 'structureinformation';
$dataTable{massspec} = 'massspec';
$dataTable{structcorr} = 'structurecorrectionsanger';
$dataTable{seqchange} = 'sequencechange';
$dataTable{newsnp} = 'newsnp';
$dataTable{ablationdata} = 'ablationdata';
$dataTable{cellfunc} = 'cellfunction';
$dataTable{phylogenetic} = 'phylogenetic';
$dataTable{othersilico} = 'othersilico';
$dataTable{supplemental} = 'supplemental';
$dataTable{nocuratable} = 'review';
$dataTable{comment} = 'comment';

# UNCOMMENT to repopulate afp_ tables from original dumps.  2009 03 21
# foreach my $table (@afp_tables) {
#   my $table2 = 'afp_' . $table ;
#   $result = $conn->exec("DROP TABLE $table2; ");
#   $result = $conn->exec( "CREATE TABLE $table2 ( joinkey text, $table2 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text), afp_curator text, afp_approve text, afp_cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE UNIQUE INDEX ${table2}_idx ON $table2 USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table2 FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO cecilia; ");
#   my $table3 = $table . '_hst';
#   $result = $conn->exec("DROP TABLE $table3; ");
#   $result = $conn->exec( "CREATE TABLE $table3 ( joinkey text, $table3 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text), afp_curator text, afp_approve text, afp_cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE INDEX ${table3}_idx ON $table3 USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table3 FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table3 TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table3 TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table3 TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table3 TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table3 TO cecilia; ");
#   if ($dataTable{$table}) { 
#     my $infile = "/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_$dataTable{$table}.pg";
#     open (IN, "<$infile") or die "Cannot open $infile : $!";
#     while (my $line = <IN>) {
#       chomp $line;
#       my ($joinkey, $data, $timestamp) = split/\t/, $line;
#       $data =~ s/\'/''/g;  $data =~ s/\\r\\n/\n/g;	# replace singlequotes and newlines
#       $result = $conn->exec( "INSERT INTO afp_$table VALUES ( '$joinkey', '$data', '$timestamp', NULL, NULL, NULL)" );
#       $result = $conn->exec( "INSERT INTO afp_${table}_hst VALUES ( '$joinkey', '$data', '$timestamp', NULL, NULL, NULL)" );
#     } # while (my $line = <IN>)
#     close (IN) or die "Cannot close $infile : $!";
# #     $result = $conn->exec( "COPY afp_$table FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_$dataTable{$table}.pg'" );
# #     $result = $conn->exec( "COPY afp_${table}_hst FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_$dataTable{$table}.pg'" ); 
#   } # if ($dataTable{$table}) 
# } # foreach my $table (@afp_tables)

# afp_ablationdata.pg               afp_humandiseases.pg              afp_passwd.pg
# afp_antibody.pg                   afp_invitro.pg                    afp_phylogenetic.pg
# afp_cellfunction.pg               afp_lsrnai.pg                     afp_review.pg
# afp_chemicals.pg                  afp_mappingdata.pg                afp_rgngene.pg
# afp_comment.pg                    afp_massspec.pg                   afp_rnai.pg
# afp_covalent.pg                   afp_microarray.pg                 afp_sequencechange.pg
# afp_expression.pg                 afp_mosaic.pg                     afp_sequencefeatures.pg
# afp_genefunction.pg               afp_nematode.pg                   afp_site.pg
# afp_geneinteractions.pg           afp_newmutant.pg                  afp_structurecorrectionsanger.pg
# afp_geneproduct.pg                afp_newsnp.pg                     afp_structureinformation.pg
# afp_generegulation.pg             afp_othersilico.pg                afp_supplemental.pg
# afp_genesymbol.pg                 afp_overexpression.pg             afp_transgene.pg

__END__


my @tables = qw( genesymbol mappingdata genefunction newmutant rnai lsrnai geneinteractions geneproduct expression sequencefeatures generegulation overexpression mosaic site microarray invitro covalent structureinformation structurecorrectionsanger sequencechange massspec ablationdata cellfunction phylogenetic othersilico chemicals transgene antibody newsnp rgngene nematode humandiseases supplemental review comment );

my @newtables = qw( matrices timeaction celegans cnonbristol nematode nonnematode nocuratable domanal structcorr structinfo genestudied extvariation funccomp otherexpr marker siteaction email genefunc geneint geneprod seqfeat genereg overexpr seqchange cellfunc humdis );

my @tomove = qw( rgngene functionalcomplementation structureinformation structurecorrection site timeofaction domainanalysis otherexpression genefunction geneinteractions geneproduct sequencefeatures generegulation overexpression sequencechange cellfunction humandiseases );

my %moveHash;
# to delete
$moveHash{'siteofaction'} = 'siteaction';
$moveHash{'timeofaction'} = 'timeaction';
$moveHash{'domainanalysis'} = 'domanal';
$moveHash{'otherexpression'} = 'otherexpr';
$moveHash{'fxncomp'} = 'funccomp';
$moveHash{'genefunction'} = 'genefunc';
$moveHash{'geneinteractions'} = 'geneint';
$moveHash{'geneproduct'} = 'geneprod';
$moveHash{'sequencefeatures'} = 'seqfeat';
$moveHash{'generegulation'} = 'genereg';
$moveHash{'overexpression'} = 'overexpr';
$moveHash{'sequencechange'} = 'seqchange';
$moveHash{'cellfunction'} = 'cellfunc';
$moveHash{'humandiseases'} = 'humdis';

# foreach my $table (keys %moveHash) {
#   my $result = $conn->exec( "DROP TABLE afp_$table " );
#   $result = $conn->exec( "DROP TABLE afp_${table}_hst " );
# } # foreach my $table (keys %moveHash)

# to move
# $moveHash{'site'} = 'siteaction';
# $moveHash{'overexpression'} = 'overexpr';
# $moveHash{'genefunction'} = 'genefunc';
# $moveHash{'geneinteractions'} = 'geneint';
# $moveHash{'geneproduct'} = 'geneprod';
# $moveHash{'sequencefeatures'} = 'seqfeat';
# $moveHash{'generegulation'} = 'genereg';
# $moveHash{'overexpression'} = 'overexpr';
# $moveHash{'sequencechange'} = 'seqchange';
# $moveHash{'cellfunction'} = 'cellfunc';
# $moveHash{'humandiseases'} = 'humdis';

# foreach my $table (keys %moveHash) {
#   my $new = $moveHash{$table}; $new = 'afp_' . $new;
#   my $result = $conn->exec( "COPY $new FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_${table}.pg'" );
#   $result = $conn->exec( "COPY ${new}_hst FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/afp_${table}.pg'" );
# }

# afp_ablationdata.pg      afp_geneproduct.pg     afp_mosaic.pg          afp_rgngene.pg
# afp_antibody.pg          afp_generegulation.pg  afp_nematode.pg        afp_rnai.pg
# afp_cellfunction.pg      afp_genesymbol.pg      afp_newmutant.pg       afp_sequencechange.pg
# afp_chemicals.pg         afp_humandiseases.pg   afp_newsnp.pg          afp_sequencefeatures.pg
# afp_comment.pg           afp_invitro.pg         afp_othersilico.pg     afp_site.pg
# afp_covalent.pg          afp_lsrnai.pg          afp_overexpression.pg  afp_structurecorrectionsanger.pg
# afp_expression.pg        afp_mappingdata.pg     afp_passwd.pg          afp_structureinformation.pg
# afp_genefunction.pg      afp_massspec.pg        afp_phylogenetic.pg    afp_supplemental.pg
# afp_geneinteractions.pg  afp_microarray.pg      afp_review.pg          afp_transgene.pg



my $table = 'afp_passwd_hst';
my $result = '';

# foreach my $table (@newtables) {
#   $table = 'afp_' . $table ;
#   $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE UNIQUE INDEX ${table}_idx ON $table USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO cecilia; ");
#   my $table2 = $table . '_hst';
#   $result = $conn->exec( "CREATE TABLE $table2 ( joinkey text, $table2 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE INDEX ${table2}_idx ON $table2 USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table2 FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table2 TO cecilia; ");
# }


# foreach my $table (@tables) {
#   $table = 'afp_' . $table;
#   $result = $conn->exec( "COPY $table TO '/home/postgres/work/pgpopulation/afp_papers/orig_tables/${table}.pg'" );
#   my $table2 = $table . '_hst';
#   $result = $conn->exec( "COPY $table2 FROM '/home/postgres/work/pgpopulation/afp_papers/orig_tables/${table}.pg'" );
# }

# # my $result = $conn->exec( "DROP TABLE $table" );
# $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table numeric(17,7), afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
# $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
# $result = $conn->exec("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO postgres; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO acedb; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO apache; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO azurebrd; ");
# $result = $conn->exec("GRANT ALL ON TABLE $table TO cecilia; ");
# 
# foreach my $table (@tables) {
#   $table = 'afp_' . $table . '_hst';
# #   $result = $conn->exec( "DROP TABLE $table" );
#   $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
#   $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
#   $result = $conn->exec("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO postgres; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO acedb; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO apache; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO azurebrd; ");
#   $result = $conn->exec("GRANT ALL ON TABLE $table TO cecilia; ");
# }

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

