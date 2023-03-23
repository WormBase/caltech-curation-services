#!/usr/bin/perl

# take any flagged positive not curated pictures, and filter through Daniela's journals with permission.  2013 08 25
#
# added pmid mappings.  2013 10 10 
#
# allow command line flag 'file' to work off of a file that Daniela can edit.  2014 10 09


use strict;
use diagnostics;
use LWP::Simple;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $flag_curationStatus_vs_File = 'curationStatus';

if ($ARGV[0]) { $flag_curationStatus_vs_File = $ARGV[0]; }

my $url = 'http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_curator=two1&listDatatype=picture&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_svm=on';
my $infile = 'journal_with_permission_expr';
if ($flag_curationStatus_vs_File eq 'file') {
  $infile = 'journal_with_permission';
  $url = 'http://tazendra.caltech.edu/~acedb/draciti/papers_with_topic_pictures.txt'; }

print qq(using url source : $url\n\n);

my %journals;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/\s+$/) { $line =~ s/\s+$//; }
  if ($line =~ m/^\s+/) { $line =~ s/^\s+//; }
  $journals{$line}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";
my $journals = join"','", sort keys %journals;

my $data = get $url;
my (@ids) = $data =~ m/">(\d+)<\/a>/g;							# curation status has papers in hyperlinks
if ($flag_curationStatus_vs_File eq 'file') { 
  (@ids) = $data =~ m/(\d+)/g; }								# file just has wbpapers
my $flagged_count = scalar @ids;
# foreach (@ids) { print "$_\n"; }
my $ids = join"','", @ids;

my $flagged_and_permission = 0;
my %papToJournal; my %papToPmid;
my $result = $dbh->prepare( "SELECT * FROM pap_journal WHERE joinkey IN ('$ids') AND pap_journal IN ('$journals')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $flagged_and_permission++;
    $papToJournal{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey IN ('$ids') AND pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $papToPmid{$row[0]} = $row[1]; } }

foreach my $pap (sort keys %papToJournal) {
  my $pmid = 'noPmid';
  if ($papToPmid{$pap}) { $pmid = $papToPmid{$pap}; }
  print qq(WBPaper$pap\t$pmid\t$papToJournal{$pap}\n);
} # foreach my $pap (sort keys %papToJournal)

print "There are $flagged_count flagged with $flagged_and_permission with permission\n";

__END__

