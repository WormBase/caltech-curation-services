#!/usr/bin/perl -w
#
# check which one entries merge ace entries (and will need to make sure i don't
# break stuff dealing with it)

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/authorperson/update_first/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# print OUT "GENE FUNCTION\n\n";
my %hash;

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    push @{ $hash{$row[0]} }, $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $one (sort keys %hash) {
  my $ace = 0;
  foreach my $key ( @{ $hash{$one} } ) {
    if ($key =~ m/ace/) { $ace++; }
  } # foreach ( @{ $hash{$one} } )
  if ($ace > 1) { print "$one : $ace\n"; }
} # foreach my $one (sort keys %hash)

close (OUT) or die "Cannot close $outfile : $!";
