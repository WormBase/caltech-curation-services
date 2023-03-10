#!/usr/bin/perl -w

# Script to match titles to find duplicate papers.  I was correct in
# believing this was a bad method, since there are 1026 titles that
# match multiple wbpapers.  2005 08 10

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %titles;

my $result = $conn->exec( "SELECT * FROM wpa_title ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $titles{join}{$row[0]} = $row[1]; } 
    else { $titles{join}{$row[0]} = ''; } }
}

$result = $conn->exec( "SELECT * FROM wpa_type WHERE wpa_type = '3';" );
while (my @row = $result->fetchrow) { delete $titles{join}{$row[0]}; }


foreach my $joinkey (sort keys %{ $titles{join} }) {
  if ($titles{join}{$joinkey}) {
    my $title = $titles{join}{$joinkey};
    $title = lc($title);
    if ($title =~ m/\bc\.? elegans/) { $title =~ s/c\.? elegans/caenorhabditis elegans/g; }
    if ($title =~ m/\W/) { $title =~ s/\W//g; }
    push @{ $titles{key}{$title} }, $joinkey;
  } # if ($titles{$joinkey})
} # foreach my $joinkey (sort keys %titles)

foreach my $key (sort keys %{ $titles{key} }) {
  if (scalar( @{ $titles{key}{$key} } ) > 1) {
    my $keys = join"\t", @{ $titles{key}{$key} };
    print OUT "$keys\t$key\n"; }
} # foreach my $key (sort keys %{ $titles{key} })


close (OUT) or die "Cannot close $outfile : $!";
