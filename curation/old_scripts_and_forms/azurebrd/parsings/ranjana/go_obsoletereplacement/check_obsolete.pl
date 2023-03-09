#!/usr/bin/perl

# take the go.go file with all the GO terms, and compare them to postgres's 
# got_obsoleteterm table which is updated every 1st and 15th each month
# by cron.  output line numbers and lines, then output all obsolete terms
# for ranjana to replace.  2003 08 26
#
# edited to only count from line 19222 onward (ignoring IEAs which are 
# automatic by sanger [or some such says Ranjana]) and output in tab delimited
# format goid, term, line number, and locus.  2003 08 26

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile2";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %obsolete;
my %list;		# list of unique obsoletes in file

my $result = $conn->exec( "SELECT * FROM got_obsoleteterm;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $obsolete{$row[0]} = $row[1];
  if ($row[0] eq 'GO:0000003') { print "$row[0]\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $infile = 'gene_association.wb';
my $count = 0;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  $count++;
  next unless ($count > 19222);
  my ($a, $b, $locus, $d, $goterm, @stuff) = split /\t/, $_;
  if ($obsolete{$goterm}) { push @{ $list{$goterm}}, "$count $locus"; }
#   if ($obsolete{$goterm}) { print OUT "$count\t$_"; $list{$goterm}++; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $obs (sort keys %list) {
#   print OUT "$obs\t$obsolete{$obs}\t\n";
  foreach my $locus (@{ $list{$obs} }) { print OUT "$obs\t$obsolete{$obs}\t$locus\n"; }
} # foreach my $obs (sort keys %list)

# print OUT scalar(keys %list) . "\n";

close (OUT) or die "Cannot close $outfile : $!";
