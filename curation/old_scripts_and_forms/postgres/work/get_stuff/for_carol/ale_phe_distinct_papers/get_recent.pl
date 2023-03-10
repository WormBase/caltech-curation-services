#!/usr/bin/perl -w

# get how many distinct WBPapers are in the allele-phenotype form  2007 03 13

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pap;
my $result = $conn->exec( "SELECT * FROM alp_paper;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[2] =~ m/WBPaper(\d+)/) { $pap{$1}++; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my (@paps) = sort keys %pap;
print "There are " . scalar(@paps) . " distinct papers in the allele phenotype form\n";

__END__

