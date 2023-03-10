#!/usr/bin/perl -w

# compare pdfs in http://tazendra.caltech.edu/~azurebrd/cgi-bin/allpdfs.cgi
# vs pap_electronic_path  and see whether to update Daniel's linker.pl
#
# allpdfs.cgi doesn't have directories to supplementals.
# allpdfs.cgi?action=textpresso has direct links to each supplemental file, but 
# pap_electronic_path has just a link to the directory
# /home/acedb/daniel/Reference/wb/supplemental/00004542
# so they don't match up.
# might be other issues
# 
# 2021 05 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %web;
my %pg;

# my $allpdfs_file = 'allpdfs.cgi';
# open (IN, "<$allpdfs_file") or die "Cannot open $allpdfs_file : $!";
# while (my $line = <IN>) {
#   if ($line =~ m/<A HREF=\"http:\/\/tazendra.caltech.edu.*>(.*?)<\/A><BR>/) { 
#     $web{$1}++; }
# }
# close (IN) or die "Cannot close $allpdfs_file : $!";

# supplemental    pubmed  <a href="http://tazendra.caltech.edu/~acedb/daniel/15854913_Guse05_supp.pdf">http://tazendra.caltech.edu/~acedb/daniel/15854913_Guse05_supp.pdf</a><br/>
my $allpdfs_file = 'allpdfs.cgi?action=textpresso';
open (IN, "<$allpdfs_file") or die "Cannot open $allpdfs_file : $!";
while (my $line = <IN>) {
  if ($line =~ m/>http:\/\/tazendra.caltech.edu\/~acedb\/daniel\/(.*?)<\/a><br\/>/) { 
    $web{$1}++; }
}
close (IN) or die "Cannot close $allpdfs_file : $!";

$result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $path = $row[1];
    my ($filename) = $row[1] =~ m/\/([^\/]*?)$/;
#     print qq(FN $filename\n);
    $pg{$filename}++;
} }

foreach my $name (sort keys %pg) {
  unless ($web{$name}) {
    print qq($name\tin pg not on web\n);
} }

foreach my $name (sort keys %web) {
  unless ($pg{$name}) {
    print qq($name\tin web not on pg\n);
} }

# foreach my $name (sort keys %web) {
#   print qq($name\n);
# } # foreach my $name (sort keys %web)

__END__

$result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

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

