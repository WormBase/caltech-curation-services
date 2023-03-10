#!/usr/bin/perl -w

# populate ali_alleleinfo with geneace alleles, for Mary Ann to compare 
# against allele_phenotype and go_curation allele data that may not be 
# in geneace.
# Uses quote and tab delimited file called Variation_gene.xt  2008 02 22
#
# Adapted to also insert Transgene data.  2008 02 29

use strict;
use diagnostics;
use Pg;
use Jex;

my $time = &getSimpleSecDate;

my $outfile = 'pgcommands.' . $time;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $infile = 'Variation_gene.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
my $result = $conn->exec( "DELETE FROM ali_alleleinfo;" );
my $junk = <IN>;
while (my $line = <IN>) { 
  chomp $line;
  $line =~ s/\"//g;
  next if ($line =~ m/\\/);	# ignore these instead of trying to put them in
#   if ($line =~ m/\\/) { $line =~ s/\\/\\\\/g; }
  my ($variation, $wbgene, $pubname) = split/\t/, $line;
  if ($variation) { $variation = "'" . $variation . "'"; }
  if ($wbgene) { 
      $wbgene =~ s/WBGene//g;
      $wbgene = "'" . $wbgene . "'"; } 
    else { $wbgene = 'NULL'; }
  if ($pubname) { $pubname = "'" . $pubname . "'"; } else { $pubname = 'NULL'; }
  my $command = "INSERT INTO ali_alleleinfo VALUES ($variation, $wbgene, $pubname);";
  print OUT "$command\n";
  $result = $conn->exec( $command );
} # while (my $line = <IN>) 
close (IN) or die "Cannot close $infile : $!"; 

$infile = 'transgene_summary_reference.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
$result = $conn->exec( "DELETE FROM tra_transgeneinfo;" );
$junk = <IN>;
while (my $line = <IN>) { 
  chomp $line;
  $line =~ s/\"//g;
  if ($line =~ m/\\/) { $line =~ s/\\/\\\\/g; }
  my ($transgene, $summary, $reference) = split/\t/, $line;
  if ($transgene) { $transgene = "'" . $transgene . "'"; }
  if ($summary) { $summary = "'" . $summary . "'"; } 
    else { $summary = 'NULL'; }
  if ($reference) { $reference = "'" . $reference . "'"; } else { $reference = 'NULL'; }
  my $command = "INSERT INTO tra_transgeneinfo VALUES ($transgene, $summary, $reference);";
  print OUT "$command\n";
  $result = $conn->exec( $command );
} # while (my $line = <IN>) 
close (IN) or die "Cannot close $infile : $!"; 

close (OUT) or die "Cannot close $outfile : $!"; 

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

