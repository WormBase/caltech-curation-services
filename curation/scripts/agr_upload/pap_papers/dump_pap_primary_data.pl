#!/usr/bin/env perl

# dump pap_primary_data for ABC.  2023 06 07

# modified  dump_agr_literature.pl

# ./dump_pap_primary_data.pl
# symlinked to
# https://tazendra.caltech.edu/~postgres/agr/lit/wb_curatability_reference_type.tsv

#  primary        = 'experimental'     = 'ATP:0000103'
#  not_primary    = 'not_experimental' = 'ATP:0000104'
#  not_designated = 'meeting'          = 'ATP:0000106'


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Jex;
use Dotenv -load => '/usr/lib/.env';

# use JSON::PP;

# use lib qw( /home/postgres/work/citace_upload/papers/ );
# use get_brief_citation;

# my $json = JSON::PP->new->ascii->pretty->allow_nonref;


# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my %mapToAtp;
$mapToAtp{'primary'}        = 'ATP:0000103';
$mapToAtp{'not_primary'}    = 'ATP:0000104';
$mapToAtp{'not_designated'} = 'ATP:0000106';


my $outfile = 'wb_curatability_reference_type.tsv';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %valid;
$result = $dbh->prepare( "SELECT * FROM pap_primary_data ORDER BY joinkey");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  unless ($mapToAtp{$row[1]}) { print qq(ERR not ATP value : @row\n); next; }
  print OUT qq(WBPaper$row[0]\t$mapToAtp{$row[1]}\n);
}

close (OUT) or die "Cannot close $outfile : $!";




__END__

my %tableToTag;
&populateTableToTag();

my %typeToCategory;
&populateTypeToAllianceCategory();

my $today_date = &getSimpleDate();

# my @normal_tables = qw( status type title journal publisher pages volume year month day abstract editor affiliation fulltext_url contained_in identifier remark erratum_in retraction_in curation_flags author gene species );
# my @normal_tables = qw( status type title journal publisher pages volume year month day abstract editor affiliation fulltext_url contained_in identifier remark erratum_in retraction_in curation_flags author species );
my @normal_tables = qw( status type title journal publisher pages volume year month day abstract identifier author );
my @not_used_tables = qw( editor affiliation fulltext_url contained_in remark erratum_in retraction_in curation_flags species );

my %indices;
$result = $dbh->prepare( "SELECT * FROM pap_type_index");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $indices{type}{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_species_index");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $indices{species}{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_index");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $indices{author}{$row[0]} = $row[1]; }

# don't need person data yet
# $result = $dbh->prepare( "SELECT pap_author_verified.author_id, pap_author_possible.pap_author_possible, pap_author_verified.pap_author_verified FROM pap_author_verified, pap_author_possible WHERE pap_author_verified.pap_author_verified ~ 'YES' AND pap_author_possible.pap_author_possible ~ 'two' AND pap_author_verified.author_id = pap_author_possible.author_id AND pap_author_verified.pap_join = pap_author_possible.pap_join;");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) {
#   $row[1] =~ s/two/WBPerson/;
#   $indices{person}{$row[0]} = $row[1]; }

my $joinkeys = '';
# my @joinkeys = qw( 00000003 00000005 00000006 00000008 00000011 00000053 00000054 00035698 00061299 );
# # my @joinkeys = qw( 00000003 00035698 );
# # my @joinkeys = qw( 00000003 00000008 );
# $joinkeys = join"','", @joinkeys;

my %hash;
foreach my $table (@normal_tables) {
  $result = $dbh->prepare( "SELECT * FROM pap_$table");
  if ($joinkeys) { 
    $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE joinkey IN ('$joinkeys')"); }
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    unless ($row[2]) { $row[2] = 0; }
    if ($table eq 'type') {            $hash{$table}{$row[0]}{$row[2]}{curator} = $row[3];       }
      elsif ($table eq 'gene') {       $hash{$table}{$row[0]}{$row[2]}{evi}     = $row[5];       }
      elsif ($table eq 'species') {    $hash{$table}{$row[0]}{$row[2]}{evi}     = $row[5];       }
    $hash{$table}{$row[0]}{$row[2]}{data} = $row[1]; }
}

my %multipleIdentifiers;

my %json;
my @json_data;
# my @requiredTags = ( "primaryId", "title", "datePublished", "citation", "allianceCategory" );	# datePublished not required 2022 10 19
my @requiredTags = ( "primaryId", "title", "citation", "allianceCategory" );
foreach my $joinkey (sort keys %{ $hash{status} }) {
  next if ($hash{status}{$joinkey}{0}{data} ne 'valid');
  my @authors;
  my %entry = ();
  my $referenceId = &getReferenceId(\%hash, $joinkey);
  $entry{'primaryId'} = $referenceId;
  foreach my $table (@normal_tables) {
    next unless ($tableToTag{$table});
    my $tag = $tableToTag{$table};
    foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
      my $data = $hash{$table}{$joinkey}{$order}{data};
      if ($tag eq 'datePublished') { $data = &getDatePublished(\%hash, $joinkey, $data); }
      $entry{$tag} = $data;
  } }
  $entry{'allianceCategory'} = &getAllianceCategory(\%hash, $joinkey);
  $entry{'MODReferenceTypes'} = &getMODReferenceTypes(\%hash, $joinkey);
  $entry{'authors'} = &getAuthors(\%hash, $joinkey, $referenceId);
  $entry{'tags'} = &getTags(\%hash, $joinkey, $referenceId);
  $entry{'crossReferences'} = &getCrossReferences(\%hash, $joinkey);
  $entry{'citation'} = &getCitation(\%hash, $joinkey);
# need language?

  foreach my $reqTag (@requiredTags) {
    if (!(exists $entry{$reqTag})) {
#       print STDERR qq(ERROR $referenceId missing $reqTag\n);
      $entry{$reqTag} = 'Unknown'; } }

  push @json_data, \%entry;
}

foreach my $xref (sort keys %multipleIdentifiers) {
  my @paps = sort keys %{ $multipleIdentifiers{$xref} };
  if (scalar @paps > 1) {
    print qq(Multiple Papers for same identifier : $xref : @paps\n);
  }
#     $multipleIdentifiers{$xref}{$joinkey}++;
}

my %metaData;
$metaData{'dataProvider'}{'type'} = 'curated';
$metaData{'dataProvider'}{'crossReference'}{'id'} = 'WB';
$metaData{'dataProvider'}{'crossReference'}{'pages'}[0] = 'homepage';

$result = $dbh->prepare( "SELECT CURRENT_TIMESTAMP(3);");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my @row = $result->fetchrow(); my $date = $row[0];
$date =~ s/ /T/; $date .= ':00';
$metaData{'dateProduced'} = $date;
$json{metaData} = \%metaData;

my $outfile1 = '/home/postgres/work/agr_upload/pap_papers/agr_wb_literature.json';
# my $outfile1 = '/home/postgres/work/agr_upload/pap_papers/agr_wb_literature.json.future';
my $outfile2 = '/home/postgres/work/agr_upload/pap_papers/agr_wb_literature.json.' . $today_date;
open(OU1, ">$outfile1") or die "Cannot create $outfile1 : $!";
# open(OU2, ">$outfile2") or die "Cannot create $outfile2 : $!";	# don't dump date copy, Kimberly doesn't need that.  2022 11 21
$json{data} = \@json_data;
my $json_output = $json->encode( \%json );
print OU1 $json_output;
# print OU2 $json_output;
close(OU1) or die "Cannot close $outfile1 : $!";
# close(OU2) or die "Cannot close $outfile2 : $!";

sub getReferenceId {	# 00000008
  my ($hashRef, $joinkey) = @_;
  my %hash = %$hashRef;
  my $table = 'identifier';
  foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
    if ($hash{$table}{$joinkey}{$order}{data}) {
      if ($hash{$table}{$joinkey}{$order}{data} =~ m/pmid(\d+)/) {
        return "PMID:$1"; } } }
  return "WB:WBPaper$joinkey";
} # sub getReferenceId

sub getCrossReferences {	# 00000008
  my ($hashRef, $joinkey) = @_;
  my %hash = %$hashRef;
  my $table = 'identifier';
  my @data;
  my %filteredXref;
  my %pmids;
  my %dois;
  my %wbgs;
  my %cgcs;
  my %wms;
  my $is_meeting = 0;
  foreach my $order (sort keys %{ $hash{'type'}{$joinkey} }) {
    if ($hash{'type'}{$joinkey}{$order}{'data'} eq '3') { $is_meeting++; } }
  foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
    if ($hash{$table}{$joinkey}{$order}{data}) {
      my $identifier = $hash{$table}{$joinkey}{$order}{data};
      if ($identifier =~ m/pmid(\d+)/) {
        $pmids{"PMID:$1"}++;
        $filteredXref{"PMID:$1"}++;
#         my %entry;
#         $entry{'id'} = "PMID:$1"; 
#         push @data, \%entry;
      }
      elsif ($identifier =~ m/doi(.*)/) {
        $dois{"DOI:$1"}++;
        $filteredXref{"DOI:$1"}++;
#         my %entry;
#         $entry{'id'} = "DOI:$1"; 
#         push @data, \%entry;
      }
      elsif ($identifier =~ m/cgc(.*)/) {
        $cgcs{"CGC:$identifier"}++;
        $filteredXref{"CGC:$identifier"}++; }
      elsif ($identifier =~ m/wbg(.*)/) {
        $wbgs{"WBG:$identifier"}++;
        $filteredXref{"WBG:$identifier"}++; }
# There are 95 WM: identifiers that map to multiple papers.  Disabling until fixed.  2023 02 23
      elsif ($is_meeting) {
        if ($identifier !~ m/^000/) {			# skip merged WBPaper IDs.
          $wms{"WM:$identifier"}++;
          $filteredXref{"WM:$identifier"}++; } }
  } }
  my %entry;
  $entry{'id'} = "WB:WBPaper$joinkey";
  if (scalar keys %dois > 1) {
    my $dois = join", ", sort keys %dois;
    print qq($joinkey multiple DOIs $dois\n); }
  if (scalar keys %pmids > 1) {
    my $pmids = join", ", sort keys %pmids;
    print qq($joinkey multiple PMIDs $pmids\n); }
  if (scalar keys %wbgs > 1) {
    my $wbgs = join", ", sort keys %wbgs;
    print qq($joinkey multiple WBGs $wbgs\n); }
# multiple cgc is correct, don't need to output
#   if (scalar keys %cgcs > 1) {
#     my $cgcs = join", ", sort keys %cgcs;
#     print qq($joinkey multiple CGCs $cgcs\n); }
  if (scalar keys %wms > 1) {
    my $wms = join", ", sort keys %wms;
    print qq($joinkey multiple WMs $wms\n); }
  foreach my $xref (sort keys %filteredXref) {
    $multipleIdentifiers{$xref}{$joinkey}++;
    my %entry;
    $entry{'id'} = $xref;
    push @data, \%entry;
  }
  my @pages = ('reference');
  $entry{'pages'} = \@pages;
  push @data, \%entry;
  return \@data;
} # sub getCrossReferences

sub getTags {
  my ($hashRef, $joinkey, $referenceId) = @_;
  my %hash = %$hashRef;
  my @tags;
  my %tag;
  $tag{'tagName'} = 'inCorpus';
  $tag{'tagSource'} = 'WB';
  $tag{'referenceId'} = $referenceId;
  push @tags, \%tag;
  return \@tags;
} # sub getTags

sub getAuthors {
  my ($hashRef, $joinkey, $referenceId) = @_;
  my %hash = %$hashRef;
  my @authors; 
  my $table = 'author';
  foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
    my %author;
    my $name = 'Unknown';
    $author{'authorRank'} = $order + 0;
    if ($hash{$table}{$joinkey}{$order}{data}) {
      my $aid = $hash{$table}{$joinkey}{$order}{data};
      if ($indices{author}{$aid}) { $name = $indices{author}{$aid}; } }
    $author{'name'} = $name;
    $author{'referenceId'} = $referenceId;
    push @authors, \%author;
  }
  return \@authors;
} # sub getAuthors

sub getCitation {
  my ($hashRef, $joinkey) = @_;
  my %hash = %$hashRef;
  my ($author, $year, $journal, $title);
  if ($hash{year}{$joinkey}{0}{data}) {		$year = $hash{year}{$joinkey}{0}{data}; }
  if ($hash{journal}{$joinkey}{0}{data}) {	$journal = $hash{journal}{$joinkey}{0}{data}; }
  if ($hash{title}{$joinkey}{0}{data}) {	$title = $hash{title}{$joinkey}{0}{data} || 'Unknown'; }
  if ($hash{author}{$joinkey}{1}{data}) {	$author = $indices{author}{$hash{author}{$joinkey}{1}{data}}; }	# 00000011
  if ($hash{author}{$joinkey}{2}{data}) {	$author .= " et al."; }
  my $data = &getBriefCitation( $author, $year, $journal, $title ); 	# from package
  $data =~ s/\\"/"/g;
  unless ($data) { $data = 'Unknown'; }
  return $data;
} # sub getCitation


sub getDatePublished {
  my ($hashRef, $joinkey, $data) = @_;
  my %hash = %$hashRef;
  if ($hash{month}{$joinkey}{0}{data}) {	# 00000053
    my $month = $hash{month}{$joinkey}{0}{data};
    if ($month < 10) { $month = "0$month"; }
    $data .= "-$month"; }
  if ($hash{day}{$joinkey}{0}{data}) {		# 00000054
    my $day = $hash{day}{$joinkey}{0}{data};
    if ($day < 10) { $day = "0$day"; }
    $data .= "-$day"; }
  unless ($data) { $data = 'Unknown'; }
  return $data;
} # sub getDatePublished

sub getMODReferenceTypes {	# 00061299
  my ($hashRef, $joinkey) = @_;
  my %hash = %$hashRef;
  my $table = 'type';
  my @data;
  foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
    if ($hash{$table}{$joinkey}{$order}{data}) {
      my $type = $hash{$table}{$joinkey}{$order}{data};
      if ($indices{type}{$type}) { 
        my %entry;
        $entry{'referenceType'} = $indices{type}{$type};
        $entry{'source'} = 'WB';
        push @data, \%entry;
  } } }
  return \@data;
} # sub MODReferenceTypes

sub getAllianceCategory {
  my ($hashRef, $joinkey) = @_;
  my %hash = %$hashRef;
  my $table = 'type';
  foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
    if ($hash{$table}{$joinkey}{$order}{data}) {
      my $type = $hash{$table}{$joinkey}{$order}{data};
      if ($typeToCategory{$indices{type}{$type}}) { return $typeToCategory{$indices{type}{$type}}; } } }
  return 'Unknown';
} # sub getAllianceCategory

#       "enum": ["Research Article","Review Article","Thesis","Book","Other","Preprint","Conference Publication","Personal Communication","Direct Data Submission","Internal Process Reference", "Unknown","Retraction"],
sub populateTypeToAllianceCategory {
  $typeToCategory{'Journal_article'}            = 'Research Article';
  $typeToCategory{'Review'}                     = 'Review Article';
  $typeToCategory{'Meeting_abstract'}           = 'Conference Publication';
  $typeToCategory{'Gazette_article'}            = 'Conference Publication';
  $typeToCategory{'Book_chapter'}               = 'Book';
  $typeToCategory{'News'}                       = 'Unknown';
  $typeToCategory{'Email'}                      = 'Personal Communication';
  $typeToCategory{'Book'}                       = 'Book';
  $typeToCategory{'Historical_article'}         = 'Unknown';
  $typeToCategory{'Comment'}                    = 'Personal Communication';
  $typeToCategory{'Letter'}                     = 'Personal Communication';
  $typeToCategory{'Monograph'}                  = 'Unknown';
  $typeToCategory{'Editorial'}                  = 'Unknown';
  $typeToCategory{'Published_erratum'}          = 'Unknown';
  $typeToCategory{'Retracted_publication'}      = 'Retraction';
  $typeToCategory{'Technical_report'}           = 'Unknown';
  $typeToCategory{'Other'}                      = 'Unknown';
  $typeToCategory{'WormBook'}                   = 'Unknown';
  $typeToCategory{'Interview'}                  = 'Personal Communication';
  $typeToCategory{'Lectures'}                   = 'Personal Communication';
  $typeToCategory{'Congresses'}                 = 'Unknown';
  $typeToCategory{'Interactive_tutorial'}       = 'Unknown';
  $typeToCategory{'Biography'}                  = 'Unknown';
  $typeToCategory{'Directory'}                  = 'Unknown';
  $typeToCategory{'Method'}                     = 'Unknown';
  $typeToCategory{'Retraction_of_publication'}  = 'Retraction';
  $typeToCategory{'Micropublication'}           = 'Research Article';
} # sub populateTypeToAllianceCategory

  
sub populateTableToTag {
  $tableToTag{title}      = 'title';
  $tableToTag{year}       = 'datePublished';
  $tableToTag{volume}     = 'volume';
  $tableToTag{pages}      = 'pages';
  $tableToTag{abstract}   = 'abstract';
  $tableToTag{publisher}  = 'publisher';	# 00035698
  $tableToTag{journal}    = 'resourceAbbreviation';

#   $tableToTag{type}       = 'Type';
#   $tableToTag{journal}    = 'Journal';
#   $tableToTag{editor}     = 'Editor';
#   $tableToTag{affiliation}        = 'Affiliation';
#   $tableToTag{fulltext_url}       = 'URL';
#   $tableToTag{contained_in}       = 'Contained_in';
#   $tableToTag{identifier} = 'Name';
#   $tableToTag{remark}     = 'Remark';
#   $tableToTag{erratum_in} = 'Erratum_in';
#   $tableToTag{retraction_in}      = 'Retraction_in';
#   $tableToTag{gene}       = 'Gene';
#   $tableToTag{curation_flags}     = 'Curation_pipeline';
#   $tableToTag{species}    = 'Species';
} # sub populateTableToTag


__END__

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

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

