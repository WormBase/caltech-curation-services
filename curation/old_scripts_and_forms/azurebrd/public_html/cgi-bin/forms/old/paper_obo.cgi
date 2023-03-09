#!/usr/bin/perl

# display WBPaper's obo  

# for carol  2007 04 11

# Added recent date change based on latest change to tables.  for Mark Gibson  2007 10 10
#
# Added /home/acedb/karen/populate_gin_variation/transgene_summary_reference.txt
# data for Karen.  2008 02 20
#
# Made ids synonyms for typing in.  2008 02 21
#
# Use the ID as a name and put the title as a synonym.  for Karen.  2008 02 28
#
# Exclude papers with type 3 or 4 for Karen  2008 08 05
#
# Converted from wpa to pap tables, although they're not live.  2010 06 22




use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";



my $query = new CGI;	# new CGI form

# my $start_time = time;

print "Content-type: text/plain\n\n";

# my $obo_date;
my $obo_date = &getOboDate();	# trasgene file could have a newer date.
my $datenumber;


my $latest_timestamp = '';

my $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid' ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my %papers;
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $papers{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM pap_type ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
my %type;
while (my @row = $result->fetchrow) {		# exclude type 3 and 4 abstracts for Karen  2008 08 05
  if ($row[0]) { 
    $type{$row[0]}++; } }
foreach my $paper (sort keys %type) { 
  my $type = $type{$paper}; if (($type eq '3') || ($type eq '4')) { delete $papers{$paper}; } }

my %ids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $ids{$row[0]}{$row[1]}++; } }

my %title;
$result = $dbh->prepare( "SELECT * FROM pap_title ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $title{$row[0]}{$row[1]}++; } }

# $result = $dbh->prepare( "SELECT wpa_timestamp FROM wpa ORDER BY wpa_timestamp DESC;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# my @row = $result->fetchrow();
# # &getLateDate($row[0]);
# $result = $dbh->prepare( "SELECT wpa_timestamp FROM wpa_identifier ORDER BY wpa_timestamp DESC;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# @row = $result->fetchrow();
# # &getLateDate($row[0]);
# $result = $dbh->prepare( "SELECT wpa_timestamp FROM wpa_title ORDER BY wpa_timestamp DESC;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# @row = $result->fetchrow();
# # &getLateDate($row[0]);

sub getLateDate {
  my $date = shift;
  my ($short) = $date =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d:\d\d:\d\d)/;
  my $number = $short;
  $number =~ s/\D//g;
  if ($number > $datenumber)  { $datenumber = $number; $obo_date = $short; }
} # sub getLateDate

# $obo_date = &convertDateObo($obo_date);

sub convertDateObo {
  my $bad_date = shift;
  my ($year, $month, $day, $hour, $minute) = $bad_date =~ m/^(\d\d\d\d)\-(\d\d)\-(\d\d) (\d\d):(\d\d)/;
  my $good_date = "${day}:${month}:${year} ${hour}:${minute}";
  return $good_date;
} # sub convertDateObo

my %pap_transgene;
my $infile = '/home/acedb/karen/populate_gin_variation/transgene_summary_reference.txt';
open (IN, "$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($transgene, $reference, $summary) = split/\t/, $line;
  if ($reference =~ m/WBPaper(\d+)/) { my $id = $1; my $data = "$transgene\t$summary"; $data =~ s/\"//g; $pap_transgene{$id}{$data}++; } }
close (IN) or die "Cannot close $infile : $!";

print "default-namespace: wbpaper\n";
print "date: $obo_date\n\n";

my ($var, $short) = &getHtmlVar($query, 'short');
if ($short) { if ($short =~ m/(\d+)/) { $short = $1; } else { $short = 10; } }
my $count = 0;

# print "[Term]\nid: WBPaper12345\nname: WBPaper12345\n";
# print "synonym: \"testing this synonym\" \[\]\n";
# print "xref: xref_test\n\n";

foreach my $id (sort keys %papers) {
  print "[Term]\nid: WBPaper$id\n";
  print "name: WBPaper$id\n";
  if ($title{$id}) { 
      my (@title) = keys %{ $title{$id} };
      my $title = $title[0];
      if ($title =~ m/\"/) { $title =~ s/\"/\\\"/g; }
      if ($title =~ m//) { $title =~ s///g; }
      if ($title =~ m/\n/) { $title =~ s/\n//g; }
      print "synonym: \"$title\" \[\]\n"; } 
  foreach my $syn (sort keys %{ $ids{$id} }) {
    if ($syn =~ m/pmid/) { $syn =~ s/pmid/PMID:/g; print "xref: $syn\n"; }
#     print "xref: $syn\n";
    print "synonym: \"$syn\" \[\]\n"; }
  foreach my $transgene (sort keys %{ $pap_transgene{$id}}) { print "transgene: $transgene\n"; }
  print "\n";
  if ($short) { $count++; }
  last if ( defined ($short) && ($short <= $count) ); 
} # foreach my $id (sort keys %persons)

# my $end_time = time;
# my $diff_time = $end_time - $start_time;
# print "TIME $diff_time SEC<BR>\n";

__END__



__END__

my $directory = '/home/postgres/work/citace_upload/allele_phenotype/temp';
chdir($directory) or die "Cannot go to $directory ($!)";
`cvs -d /var/lib/cvsroot checkout PhenOnt`;
my $file = $directory . '/PhenOnt/PhenOnt.obo';
$/ = "";
open (IN, "<$file") or die "Cannot open $file : $!";
while (my $para = <IN>) { print "$para\n"; }
close (IN) or die "Cannot close $file : $!";
$directory .= '/PhenOnt';
`rm -rf $directory`;

