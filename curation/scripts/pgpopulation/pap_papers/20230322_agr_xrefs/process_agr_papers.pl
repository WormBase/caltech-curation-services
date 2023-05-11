#!/usr/bin/env perl

# read agr wb reference json and extract agr IDs to connect to existing WBPaper IDs.
# 60010 AGR IDs loaded into pap_identifier on dockerized on 2023 03 22, against postgres dump from 20230215.
# 2023 03 22


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
# use JSON::Parse 'parse_json';
# use JSON::XS;
use JSON;
use Jex;
use Text::Unaccent;
use Dotenv -load => '/usr/lib/.env';
use utf8;

binmode STDOUT, ':utf8';

# my $line = 'Z\u00fcmr\u00fct Duygu';	# from AGRKB:101000000258056  PMID:23449592
# 
# 
#   my $unaccented = utf8::decode($line);
# print qq(UTF8 $unaccented\n);
# 
#   my $unaccented = unac_string_utf16($line);
# print qq($unaccented\n);
#   my $unaccented = unac_string("iso-8859-1", $line);                # for IWM Kimberly files
# print qq($unaccented\n);
#   my $unaccented = unac_string("utf-8", $line);               # for WBG Daniel files
# print qq($unaccented\n);
# 
# __END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my $infile = 'temp.json';
my $infile = 'files/reference_WB_20230428.json';
# my $infile = 'files/reference_WB_comcor.json';
# my $infile = 'files/reference_WB_doublequotes.json';
# my $infile = 'files/reference_WB_accents.json';
# my $infile = 'files/reference_WB_nightly.json';
# my $infile = '/usr/lib/scripts/pgpopulation/pap_papers/20230322_agr_xrefs/reference_WB_nightly.json';

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
print "Start reading $infile\n";
my $json_data = <IN>;
print "Done reading $infile\n";
close (IN) or die "Cannot open $infile : $!";

my $unaccent_json_data = unac_string("utf-8", $json_data);

print "Start decoding json\n";
# my %perl = parse_json($json_data);	# JSON::Parse, not installed in dockerized
# my $perl = JSON::XS->new->utf8->decode ($json_data);
# my $perl = decode_json($json_data);	# JSON  very very slow on dockerized without JSON::XS, but fast on tazendra.  with JSON::XS installed is fast even without directly calling JSON::XS->new like below, and without use JSON::XS, just use JSON
my $perl = decode_json($unaccent_json_data);	# escape accent characters

print "Done decoding json\n";
my %agr = %$perl;
foreach my $key (sort keys %agr) {
  print qq($key\n);
}

my %agrs;
my %wbps;
my %wbpToAgr;
my %doiToAgr;
my %pmidToAgr;
my %agrToWbp;
my %agrToDoi;
my %agrToPmid;
my %agrCategory;
my %agrObsId;

my %agrData;
my %pgData;

my @pgtables = qw( identifier status erratum_in retraction_in title journal publisher editor pages volume year month day contained_in abstract fulltext_url type gene species author );
# &populatePgData('all');

my %simpleFields;
$simpleFields{'title'} = 'title';
$simpleFields{'journal'} = 'resource_title';
$simpleFields{'publisher'} = 'publisher';
$simpleFields{'pages'} = 'page_range';
$simpleFields{'volume'} = 'volume';
$simpleFields{'abstract'} = 'abstract';

# special fields: 
# identifier - cross_reference
# status - cross_reference
# erratum_in - comments_and_corrections
# retraction_in - comments_and_corrections
# contained_in - N/A
# editors - N/A
# year;month;day - date_published
# author - authors
# fulltext_url - N/A
# remark - N/A
# type - mod_reference_types
# gene - topic_entity_tag = gene
# species topic_entity_tag = species


my %valid; my %invalid;
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $invalid{$row[0]}++; }

my %pgIdentToWbp;
$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $pgIdentToWbp{$row[1]} = $row[0]; }

my %type_index;               # type to type_index mapping
$result = $dbh->prepare( "SELECT * FROM pap_type_index;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $type_index{$row[1]} = $row[0]; }

my %type_override_journal;
$type_override_journal{'Review'}++;
$type_override_journal{'Comment'}++;
$type_override_journal{'News'}++;
$type_override_journal{'Letter'}++;
$type_override_journal{'Editorial'}++;
$type_override_journal{'Congresses'}++;
$type_override_journal{'Historical_article'}++;
$type_override_journal{'Biography'}++;
$type_override_journal{'Interview'}++;
$type_override_journal{'Lectures'}++;
$type_override_journal{'Interactive_tutorial'}++;
$type_override_journal{'Retracted_publication'}++;
$type_override_journal{'Technical_report'}++;
$type_override_journal{'Directory'}++;
$type_override_journal{'Monograph'}++;
$type_override_journal{'Published_erratum'}++;

my %agrComCor;
# $agrComCor{$type}{$wbp} = $otherAgr;

my $count = 0;
foreach my $papobj_href (@{ $agr{data} }) {
#   print qq(papobj_href\n);
  my %papobj = %$papobj_href;
#   $count++; last if ($count > 400);
  my $agr = $papobj{curie};
  $agrs{$agr}++;
  if ($papobj{category}) { $agrCategory{$agr} = $papobj{category}; }
  my $wbp = ''; my $doi = ''; my $pmid = '';
#   print qq($agr\n);
  my %xrefs;
  foreach my $xref_href (@{ $papobj{cross_references} }) {
    my %xref = %$xref_href;
    # my $is_obs = 0;
    # if ($xref{is_obsolete}) { print qq(OBS $xref{curie}\n); } else { print qq(NOT OBS $xref{curie}\n); }
    if ($xref{curie} =~ m/^WB:WBPaper(\d+)/) {
      $wbp = $1;           $agrToWbp{$agr}  = $wbp;  $wbpToAgr{$wbp}   = $agr;
      if ($xref{is_obsolete}) { $agrObsId{$wbp}++; } }
    if ($xref{curie} =~ m/^DOI:(.*)/) {
      $doi = 'doi' . $1;   $agrToDoi{$agr}  = $doi;  $doiToAgr{$doi}   = $agr;
      if ($xref{is_obsolete}) { $agrObsId{$doi}++; } }
    if ($xref{curie} =~ m/^PMID:(\d+)/) {
      $pmid = 'pmid' . $1; $agrToPmid{$agr} = $pmid; $pmidToAgr{$pmid} = $agr;
      if ($xref{is_obsolete}) { $agrObsId{$pmid}++; } }
#     print qq($xref{curie}\n);
  }
# PUT THIS BACK
#   &comparePgAgr($papobj_href);
#   print qq(\n);
  if ($wbp) { 
    $wbps{$wbp}++;
#     print qq($wbp : $agr\n);
  } else {
    $agrData{$agr} = $papobj_href;
    # $agrData{$agr} = \%papobj;
  }
}

# PUT THIS BACK
# &compareCommentsCorrections(); 
&compareIdentifiers();
# &processCreate();

foreach my $wbp (sort keys %wbps) {
  if ($wbps{$wbp} > 1) { print qq(ERR : Too many wbps $wbp $wbps{$wbp}\n); }
}

sub populatePgData {
  # 20 seconds to read all postgres data for all joinkeys
  my ($all_or_joinkey) = @_;
  my $start = &getSimpleSecDate();
  print qq($start start read pg\n);
  foreach my $table (@pgtables) {
    my $pgquery = qq(SELECT * FROM pap_$table);
    if (($all_or_joinkey ne '') && ($all_or_joinkey ne 'all')) { $pgquery .= qq( WHERE joinkey = '$all_or_joinkey'); }
    $result = $dbh->prepare( $pgquery );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      unless ($row[2]) { $row[2] = 0; }
      $pgData{$table}{$row[0]}{$row[2]} = $row[1]; }
  }
  my $end = &getSimpleSecDate();
  print qq($end end read pg\n);
} # sub populatePgData

sub comparePgAgr {
  my ($papobj_href) = @_;
  my %papobj = %$papobj_href;
  my $agr = $papobj{curie};
  
  my $wbp = &resolveAgrToWbp($agr);
  if ($wbp) {
    print qq($agr is $wbp\n);
    &populatePgData($wbp);
# PUT THIS BACK
    foreach my $field (sort keys %simpleFields) {
      my $agrField = $simpleFields{$field};
      &compareSimple($wbp, $field, $papobj{$agrField}, $pgData{$field}{$wbp}{0});
    }
    &compareAuthors($wbp, $papobj{authors});
    &compareDatePublished($wbp, $papobj{date_published});
    &comparePubTypes($wbp, $papobj{pubmed_types});
    &extractCommentsCorrections($wbp, $papobj{comment_and_corrections});
  }
} # sub comparePgAgr

sub compareIdentifiers {
  my %agrToCreate;
  foreach my $wbp (sort keys %wbpToAgr) {
    if ($agrObsId{$wbp}) {		# wbpaper id obsolete at abc
      if ($valid{$wbp}) { 		# at caltech is valid
        print qq(MERGE conflict  WBPaper$wbp at ABC is $wbpToAgr{$wbp} and obsolete, but valid at Caltech postgres\n); }
    } else {				# wbpaper id valid at abc
      if ($pgIdentToWbp{$wbp}) { 	# at caltech is ident for another paper
        print qq(MERGE conflict  WBPaper$wbp at ABC is $wbpToAgr{$wbp} and valid, but at Caltech postgres in alternate identifier for WBPaper$pgIdentToWbp{$wbp}\n); }
    }
    if ( (!$invalid{$wbp}) && (!$valid{$wbp}) && (!$pgIdentToWbp{$wbp}) ) {	# if completely new, create it
      $agrToCreate{$wbpToAgr{$wbp}}++;
      print qq(CREATE new WBPaper$wbp from $wbpToAgr{$wbp}\n); }
  }
  foreach my $wbp (sort keys %valid) {
    unless ($wbpToAgr{$wbp}) { print qq(MERGE conflict primary WBPaper$wbp not in ABC\n); } }
  foreach my $wbp (sort keys %pgIdentToWbp) {
    if ($wbp =~ m/^\d{8}$/) {
      unless ($wbpToAgr{$wbp}) { print qq(MERGE conflict secondary WBPaper$wbp for WBPaper$pgIdentToWbp{$wbp} not in ABC\n); } } }

  # Kimberly : Do we need other kinds of checks ?
  # CREATE should handle new papers and add their xrefs
  # How to handle xrefs in ABC not in WB ?  If main wbp already in, add it ?
} # sub compareIdentifiers

sub compareCommentsCorrections {	# data is wrong from abc exporter, wbp and other wbp are the same curie in all cases
  # print qq(compareCommentsCorrections\n);
  my %agrErratumIn;
  my %agrRetractionIn;
  foreach my $type (sort keys %agrComCor) {
    print qq(comcorType : $type\n);
    foreach my $wbp (sort keys %{ $agrComCor{$type} }) {
      my $otherAgr = $agrComCor{$type}{$wbp};
      my $otherWbp = 'no match';
      $otherWbp = &resolveAgrToWbp($otherAgr);
      print qq($wbp\t$type\t$otherAgr\t$otherWbp\n);
      if (($type eq 'ErratumIn') && ($otherWbp)) { $agrErratumIn{$wbp}{$otherWbp}++; }
        elsif (($type eq 'ErratumFor') && $otherWbp) { $agrErratumIn{$otherWbp}{$wbp}++; }
        elsif (($type eq 'RetractionIn') && ($otherWbp)) { $agrRetractionIn{$wbp}{$otherWbp}++; }
        elsif (($type eq 'RetractionOf') && $otherWbp) { $agrRetractionIn{$otherWbp}{$wbp}++; }
    } # foreach my $wbp (sort keys %{ $agrComCor{$type} })
  } # foreach my $type (sort keys %agrComCor)

  foreach my $wbp (sort keys %agrErratumIn) {
    my @data;
    foreach (sort {$a<=>$b} keys %{ $agrErratumIn{$wbp} }) { push @data, $_; }
    my $agrErratumIn = join", ", @data;

    my %pgErratumIn; my @pgErratumIn = ();
    foreach my $order (sort keys %{ $pgData{erratum_in}{$wbp} }) { $pgErratumIn{$pgData{erratum_in}{$wbp}{$order}}++; }
    foreach (sort {$a<=>$b} keys %pgErratumIn) { push @pgErratumIn, $_; }
    my $pgErratumIn = join", ", @pgErratumIn;
    # print qq($pgErratumIn\n);
  
    if ($agrErratumIn ne $pgErratumIn) {
      print qq(DIFF\t$wbp\tpap_erratum_in\t$agrErratumIn\t$pgErratumIn\n);
    }
  }

  foreach my $wbp (sort keys %agrRetractionIn) {
    my @data;
    foreach (sort {$a<=>$b} keys %{ $agrRetractionIn{$wbp} }) { push @data, $_; }
    my $agrRetractionIn = join", ", @data;

    my %pgRetractionIn; my @pgRetractionIn = ();
    foreach my $order (sort keys %{ $pgData{retraction_in}{$wbp} }) { $pgRetractionIn{$pgData{retraction_in}{$wbp}{$order}}++; }
    foreach (sort {$a<=>$b} keys %pgRetractionIn) { push @pgRetractionIn, $_; }
    my $pgRetractionIn = join", ", @pgRetractionIn;
    # print qq($pgRetractionIn\n);
  
    if ($agrRetractionIn ne $pgRetractionIn) {
      print qq(DIFF\t$wbp\tpap_retraction_in\t$agrRetractionIn\t$pgRetractionIn\n);
    }
  }


  # TODO clean up data, not sure if it makes sense that pap_erratum_in have papers going both ways from these queries :
  # SELECT * FROM pap_erratum_in WHERE joinkey IN (SELECT joinkey FROM pap_erratum_in  GROUP BY joinkey HAVING COUNT(*) > 1) ORDER BY joinkey;
  # SELECT * FROM pap_erratum_in WHERE pap_erratum_in IN (SELECT pap_erratum_in FROM pap_erratum_in  GROUP BY pap_erratum_in HAVING COUNT(*) > 1) ORDER BY pap_erratum_in;
  # Once cleaned up aggregate ErratumFor with ErratumIn ?
} # sub compareCommentsCorrections

sub extractCommentsCorrections {	# data is wrong from abc exporter, wbp and other wbp are the same curie in all cases
  my ($wbp, $thisAgrComCor_href) = @_;
  if ($thisAgrComCor_href) {
    my %thisAgrComCor = %$thisAgrComCor_href;
    foreach my $type (sort keys %thisAgrComCor) {
      my $otherAgr = $thisAgrComCor{$type}{'reference_curie'};
      # can't do this here, the other Agr hasn't been processed yet, so we don't know what the WBPaper is, must add to %agrComCor to process after all json is done
      # my $otherWbp = 'no match';
      # $otherWbp = &resolveAgrToWbp($otherAgr);
      # print qq($wbp\t$type\t$otherAgr\t$otherWbp\n);
      $agrComCor{$type}{$wbp} = $otherAgr;
    } # foreach my $type (sort keys %thisAgrComCor)
  }
} # sub extractCommentsCorrections

sub comparePubTypes {
  my ($wbp, $agrPubTypes_href) = @_;
  my $agrPubTypes = '';
  if ($agrPubTypes_href) {
    my @agrPubTypes = @$agrPubTypes_href;

    my %filtered_data; my $override_journal_flag = 0;
    foreach my $data (@agrPubTypes) {
      my ($type) = ucfirst(lc($data)); $type =~ s/\s+/_/g;
      if ($type_override_journal{$type}) { $override_journal_flag++; }      # if it's a type to override, set flag
      if ($type_index{$type}) { $data = $type_index{$type}; $filtered_data{$data}++; } }
    if ($override_journal_flag) { delete $filtered_data{'1'}; }             # if meant to override remove type 1
    my @data = ();                                                     # reset data and populate from filtered_data
    foreach (sort {$a<=>$b} keys %filtered_data) { push @data, $_; }
    $agrPubTypes = join", ", @data;
    # print qq($agrPubTypes\n);
  }

  my %pgPubTypes; my @pgPubTypes = ();
  foreach my $order (sort keys %{ $pgData{type}{$wbp} }) { $pgPubTypes{$pgData{type}{$wbp}{$order}}++; }
  foreach (sort {$a<=>$b} keys %pgPubTypes) { push @pgPubTypes, $_; }
  my $pgPubTypes = join", ", @pgPubTypes;
  # print qq($pgPubTypes\n);

  if ($agrPubTypes ne $pgPubTypes) {
    print qq(DIFF\t$wbp\tpap_type\t$agrPubTypes\t$pgPubTypes\n);
  }
} # sub comparePubTypes

sub compareDatePublished {
  my ($wbp, $agrDate) = @_;
  unless ($agrDate) { $agrDate = ''; }
  my ($year, $month, $day) = ('1970', '01', '01');
  if ($pgData{year}{$wbp}{0}) { $year = $pgData{year}{$wbp}{0}; }
  if ($pgData{month}{$wbp}{0}) { $month = $pgData{month}{$wbp}{0}; if ($month < 10) { $month = '0' . $month; } }
  if ($pgData{day}{$wbp}{0}) { $day = $pgData{day}{$wbp}{0}; if ($day < 10) { $day = '0' . $day; } }
  my $pgDate = $year . '-' . $month . '-' . $day;
  if ($agrDate ne $pgDate) {
    print qq(DIFF\t$wbp\tdate_published\t$agrDate\t$pgDate\n);
  }
} # sub compareDatePublished

sub compareAuthors {
  my ($wbp, $agrAuthors_href) = @_;
  my $max_order = 0;
  my %agrAut;
  if ($agrAuthors_href) {
    my @agrAuthors = @$agrAuthors_href;
    foreach my $agr_aut_href (@agrAuthors) {
      my %agr_aut = %$agr_aut_href;
      my $agr_order = $agr_aut{order};
      if ($agr_order > $max_order) { $max_order = $agr_order; }
      my $agr_name = $agr_aut{name};
      if ($agr_aut{last_name}) {
        my $last_name = $agr_aut{last_name};
        my $first_init = '';
        if ($agr_aut{first_name}) {
          my $first_name = $agr_aut{first_name};
          my @firsts = split/[ \-]/, $first_name;
          foreach my $first (@firsts) {
            my ($first_char) = $first =~ m/^(.)/; $first_init .= ucfirst($first_char); } }
        if ($first_init) { $agr_name = $last_name . ' ' . $first_init; }
          else { $agr_name = $last_name; }
      }
      $agrAut{$agr_order} = $agr_name;
  } }
  my %pgAut;
  my @author_ids = ();
  foreach my $pg_order (sort {$a<=>$b} keys %{ $pgData{author}{$wbp} }) {
    # print qq($pg_order\t$pgData{author}{$wbp}{$pg_order}\n);
    push @author_ids, $pgData{author}{$wbp}{$pg_order};
  }
  my $aids = join"','", @author_ids;
  my %aids;
  $result = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id IN ('$aids')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $aids{$row[0]} = $row[1]; }
  foreach my $pg_order (sort {$a<=>$b} keys %{ $pgData{author}{$wbp} }) {
    if ($pg_order > $max_order) { $max_order = $pg_order; }
    my $aid = $pgData{author}{$wbp}{$pg_order};
    my $name = $aids{$aid};
    $pgAut{$pg_order} = $name;
  }
  for my $order (1 .. $max_order) {
    my $agrAut = ''; my $pgAut = '';
    if ($agrAut{$order}) { $agrAut = $agrAut{$order}; }
    if ($pgAut{$order}) { $pgAut = $pgAut{$order}; }
    if ($agrAut ne $pgAut) {
      print qq(DIFF\t$wbp\tauthor\t$order\t$agrAut\t$pgAut\n);
    }
  }
} # sub compareAuthors

sub compareSimple {
  my ($wbp, $field, $agrValue, $pgValue) = @_;
  unless ($agrValue) { $agrValue = ''; }
  unless ($pgValue) { $pgValue = ''; }
  if ($agrValue ne $pgValue) {
    print qq(DIFF\t$wbp\t$field\t$agrValue\t$pgValue\n);
  }
} # sub compareSimple

sub resolveAgrToWbp {
  my $agr = shift;
  my $wbp = '';
#   my $good = 0; my $skip = 0;
  if ($agrToWbp{$agr}) {					# AGRKB maps to WBPaper ID
    if ($valid{$agrToWbp{$agr}}) { 
#         $good++;
        $wbp = $agrToWbp{$agr}; }				# WBPaper is valid
      else {  
#         $skip++;
        print qq(ERR $agr\t$agrToWbp{$agr}\tnot valid\n); } }	# WBPaper is not valid
  if ($wbp eq '') {
    if ($agrToDoi{$agr}) { 
      my $doi = $agrToDoi{$agr};
      if ($pgIdentToWbp{$doi}) {
        if ($valid{$pgIdentToWbp{$agr}}) { 
#             $good++;
            $wbp = $pgIdentToWbp{$agr}; }				# WBPaper is valid
          else {  
#             $skip++;
            print qq(ERR $agr\t$doi\t$pgIdentToWbp{$doi}\tnot valid\n); } } } }	# WBPaper is not valid
#     next if $good;
  if ($wbp eq '') {
    if ($agrToPmid{$agr}) { 
      my $pmid = $agrToPmid{$agr};
      if ($pgIdentToWbp{$pmid}) {
        if ($valid{$pgIdentToWbp{$agr}}) { 
#             $good++;
            $wbp = $pgIdentToWbp{$agr}; }				# WBPaper is valid
          else {  
#             $skip++;
            print qq(ERR $agr\t$pmid\t$pgIdentToWbp{$pmid}\tnot valid\n); } } } }	# WBPaper is not valid
  return $wbp;
} # sub resolveAgrToWbp



sub processCreate {	# this is not well defined and probably not doing the right thing
  my %agrToProcess;
  foreach my $agr (sort keys %agrs) {
  #   my $good = 0; my $skip = 0;
  #   if ($agrToWbp{$agr}) {						# AGRKB maps to WBPaper ID
  #     if ($valid{$agrToWbp{$agr}}) { $good++; }				# WBPaper is valid
  #       else { print qq(ERR $agr\t$agrToWbp{$agr}\tnot valid\n); $skip++; } }	# WBPaper is not valid
  #   next if $good; next if $skip;
  #   if ($agrToDoi{$agr}) { 
  #     my $doi = $agrToDoi{$agr};
  #     if ($pgIdentToWbp{$doi}) {
  #       $good++;
  #       print qq($agr\t$doi\t$pgIdentToWbp{$doi}\n); } }
  #   next if $good;
  #   if ($agrToPmid{$agr}) {
  #     my $pmid = $agrToPmid{$agr};
  #     if ($pgIdentToWbp{$pmid}) {
  #       $good++;
  #       print qq($agr\t$pmid\t$pgIdentToWbp{$pmid}\n); } }
  #   next if $good;
    my $wbp = &resolveAgrToWbp($agr);
    unless ($wbp) {
      if ($agrToPmid{$agr}) {	# this is for figuring out corrections that need to be manually created by Kimberly, they have a PMID
        my $pmid = $agrToPmid{$agr}; $pmid =~ s/pmid//;
        print qq(Needs\t$agr\t$pmid\t$agrCategory{$agr}\n);
      }
      print qq(Needs $agr $agrCategory{$agr}\n);
      $agrToProcess{$agr}++;
    }
  }

# foreach my $agr (sort keys %agrToProcess) {
#   print qq($agr\n);
#   my $papobj_href = $agrData{$agr};
#   # print qq($papobj_href\n);
#   my %papobj = %$papobj_href;
#   print qq($papobj{curie}\n);
#   print qq($papobj{category}\n);
#   print qq(\n);
# }
} # sub processCreate


__END__

 grep abstract agr_pg_doublequotes | wc -l
 grep abstract agr_pubmed_types | wc -l
 grep title agr_pg_doublequotes | wc -l
 grep title agr_pubmed_types | wc -l
 grep journal agr_pg_doublequotes | wc -l
 grep journal agr_pubmed_types | wc -l
 grep publisher agr_pg_doublequotes | wc -l
 grep publisher agr_pubmed_types | wc -l
 grep pages agr_pg_doublequotes | wc -l
 grep pages agr_pubmed_types | wc -l
 grep volume agr_pg_doublequotes | wc -l
 grep volume agr_pubmed_types | wc -l
 grep author agr_pg_doublequotes | wc -l
 grep author agr_pubmed_types | wc -l
 grep date_published agr_pg_doublequotes | wc -l
 grep date_published agr_pubmed_types | wc -l




my %highestPapIdent;
$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  $highestPapIdent{$row[0]} = $row[2];
}

my @pgcommands;
foreach my $joinkey (sort keys %wbpToAgr) {
  next unless $valid{$joinkey};
  my $order = 1;
  if ($highestPapIdent{$joinkey}) {
    $order = $highestPapIdent{$joinkey} + 1;
    # print qq(ERR : No order for $joinkey\n);
  }
  push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$joinkey', '$wbpToAgr{$joinkey}', $order, 'two1823'););
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment LIMIT 5" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


how to set directory to output files at curator / web-accessible
  my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";

how to set base url for a form
  my $baseUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms";

how to import modules in dockerized system
  use lib qw(  /usr/lib/scripts/perl_modules/ );                  # for general ace dumping functions
  use ace_dumper;

how to queue a bunch of insertions
  my @pgcommands;
  push @pgcommands, qq(INSERT INTO obo_name_hgnc VALUES $name_commands;);
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)


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

