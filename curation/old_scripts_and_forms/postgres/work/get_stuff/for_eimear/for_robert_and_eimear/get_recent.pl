#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_robert_and_eimear/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";

my %hash;

my $result = $conn->exec( "SELECT * FROM ref_journal;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $hash{$row[1]}++;
#     print OUT "STRUCTURE CORRECTION\t$row[0]\t$row[1]\t$row[2]\n\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach $_ (sort by_count_then_name keys %hash) {
  print OUT "$_ : $hash{$_}\n";
} # foreach $_ (%hash)

sub by_count_then_name {
  $hash{$b} <=> $hash{$a} || $a cmp $b
}

close (OUT) or die "Cannot close $outfile : $!";
