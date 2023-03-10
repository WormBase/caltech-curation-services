#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $infile = 'elegans_status_dead_WS212';
# my $infile = 'just52';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my $to_print = "";
  my %hash;
  my $result = $dbh->prepare( "SELECT * FROM wpa_gene WHERE wpa_gene ~ '$line' ORDER BY wpa_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $row = join"\t", @row;
    $to_print .= "$line\t$row\n";
    if ($row[3] eq 'valid') { $hash{$row[0]}{$row[1]}{$row[2]}++; }
      else { delete $hash{$row[0]}{$row[1]}{$row[2]}; }
  }
  foreach my $paper (sort keys %hash) {
    foreach my $gene (sort keys %{ $hash{$paper} }) {
      foreach my $evi (sort keys %{ $hash{$paper}{$gene} }) {
        $to_print .= "STILL VALID $paper\t$gene\t$evi\n";
      } # foreach my $evi (sort keys %{ $hash{$paper}{$gene} })
    } # foreach my $gene (sort keys %{ $hash{$paper} })
  } # foreach my $paper (sort keys %hash)
  if ($to_print) { print "$to_print\n\n"; }
    else { print "$line is not in postgres\n\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

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
