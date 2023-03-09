#!/usr/bin/perl -w

# take citaceminus dump, -D Status, and compare that WBGenes are in postgres, and -D them if so.
# 2010 02 19

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pg;

my $result = $dbh->prepare( "SELECT * FROM pap_gene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $pg{$row[0]}{$row[1]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# delete $pg{"00031448"}{"00012885"};	# to test

my %data;
my $infile = "cminus212Paper.ace";
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  next unless ($entry =~ m/Paper : \"WBPaper\d+\"/);
  my ($paper) = $entry =~ m/Paper : \"WBPaper(\d+)\"/;
  if ($entry =~ m/Status.*Valid/) { $data{$paper}{status} = 'Valid'; }
  if ($entry =~ m/Status.*Invalid/) { $data{$paper}{status} = 'Invalid'; }
  if ($entry =~ m/WBGene\d+/) {
    my (@genes) = $entry =~ m/WBGene(\d+)/g;
    foreach (@genes) { $data{$paper}{genes}{$_}++; }
  }
}
close (IN) or die "Cannot close $infile : $!";

foreach my $paper (sort keys %data) {
  print "Paper : \"WBPaper$paper\"\n";
  print "-D $data{$paper}{status}\n";
  foreach my $gene (sort keys %{ $data{$paper}{genes} }) {
    if ($pg{$paper}{$gene}) {
      print "-D Gene \"WBGene$gene\"\n"; }
    else {
      print "NOT IN POSTGRES WBGene$gene\n"; }
  }
  print "\n";
}

__END__


my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

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
