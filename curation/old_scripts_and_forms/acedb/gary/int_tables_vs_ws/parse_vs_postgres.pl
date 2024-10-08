#!/usr/bin/perl -w

# compare WS dumps vs PG for int_ tables.  2010 09 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $rnaifile = 'allrnaiIDs.txt';
my $intfile = 'interactionIDs_WS218';

my %hash;
open (IN, "<$rnaifile") or die "cannot open $rnaifile : $!";
while (my $line=<IN>) {
  chomp $line;
  $line =~ s/\t//;
  $hash{rnai}{ws}{$line}++;
}
close (IN) or die "cannot close $intfile : $!";
open (IN, "<$intfile") or die "cannot open $intfile : $!";
while (my $line=<IN>) {
  chomp $line;
  $line =~ s/\t//;
  $hash{int}{ws}{$line}++;
}
close (IN) or die "cannot close $rnaifile : $!";

my $result = $dbh->prepare( "SELECT * FROM int_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{int}{pg}{$row[1]}++; }

$result = $dbh->prepare( "SELECT * FROM int_rnai" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $hash{rnai}{pg}{$row[1]}++; }

foreach my $id (sort keys %{ $hash{rnai}{pg} }) {
  if ($hash{rnai}{ws}{$id}) { print "$id in PG and in WS\n"; } }
foreach my $id (sort keys %{ $hash{rnai}{pg} }) {
  unless ($hash{rnai}{ws}{$id}) { print "$id in PG but NOT in WS\n"; } }
foreach my $id (sort keys %{ $hash{rnai}{ws} }) {
  unless ($hash{rnai}{pg}{$id}) { print "$id in WS but NOT in PG\n"; } }

foreach my $id (sort keys %{ $hash{int}{pg} }) {
  if ($hash{int}{ws}{$id}) { print "$id in PG and in WS\n"; } }
foreach my $id (sort keys %{ $hash{int}{pg} }) {
  unless ($hash{int}{ws}{$id}) { print "$id in PG but NOT in WS\n"; } }
foreach my $id (sort keys %{ $hash{int}{ws} }) {
  unless ($hash{int}{pg}{$id}) { print "$id in WS but NOT in PG\n"; } }

__END__

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

