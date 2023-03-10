#!/usr/bin/perl -w

# see which paper-gene connections don't have valid genes in gin_wbgene  2009 05 01

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %good;
my $result = $dbh->prepare( 'SELECT gin_wbgene FROM gin_wbgene;' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $good{$row[0]}++; } }

my %hash;
$result = $dbh->prepare( 'SELECT * FROM wpa_gene ORDER BY wpa_timestamp;' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[3] eq 'valid') { $hash{$row[1]}{$row[0]}++; }
    else { delete $hash{$row[1]}{$row[0]}; }
}
foreach my $gene (sort keys %hash) {
  foreach my $pap (sort keys %{ $hash{$gene} }) {
    my ($wbg) = $gene =~ m/(WBGene\d+)/;
    unless ($good{$wbg}) {
      print "Invalid gene $gene in paper $pap\n"; 
    }
  } # foreach my $gene (sort keys %{ $hash{$pap} })
} # foreach my $pap (sort keys %hash)


__END__

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
