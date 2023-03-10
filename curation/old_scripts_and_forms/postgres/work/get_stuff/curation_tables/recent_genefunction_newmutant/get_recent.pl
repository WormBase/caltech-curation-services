#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/recent_genefunction_newmutant/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

print OUT "GENE FUNCTION\n\n";

my $result = $conn->exec( "SELECT cur_genefunction.joinkey, cur_genefunction.cur_genefunction, cur_genefunction.cur_timestamp FROM cur_genefunction, cur_curator WHERE cur_genefunction.joinkey ~ 'pmid' AND cur_curator.joinkey = cur_genefunction.joinkey AND cur_curator.cur_curator ~ 'Andrei' AND cur_genefunction.cur_timestamp > '2002-01-02';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print OUT "GENE FUNCTION\t$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

print OUT "\n\nNEW MUTANT\n\n";

my $result = $conn->exec( "SELECT cur_newmutant.joinkey, cur_newmutant.cur_newmutant, cur_newmutant.cur_timestamp FROM cur_newmutant, cur_curator WHERE cur_newmutant.joinkey ~ 'pmid' AND cur_curator.joinkey = cur_newmutant.joinkey AND cur_curator.cur_curator ~ 'Andrei' AND cur_newmutant.cur_timestamp > '2002-01-02';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print OUT "NEW MUTANT\t$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

close (OUT) or die "Cannot close $outfile : $!";
