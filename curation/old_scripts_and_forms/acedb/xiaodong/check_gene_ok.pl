#!/usr/bin/perl

use strict;
use LWP::Simple;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %sanger_hash;


my $result = $conn->exec( "SELECT * FROM gin_synonyms;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $wbgene = 'WBGene' . $row[0];
    $sanger_hash{$wbgene} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM gin_locus;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $wbgene = 'WBGene' . $row[0];
    $sanger_hash{$wbgene} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)


# # my $sanger_genes = get "http://www.sanger.ac.uk/tmp/Projects/C_elegans/LOCI/genes2molecularnamestest.txt";
# my $sanger_genes = get "http://tazendra.caltech.edu/~azurebrd/var/out/genes2molecularnamestest.txt";
# my @lines = split/\n/, $sanger_genes;
# foreach my $line (@lines) {
#   my ($wbgene, $genename, $cosmid) = $line =~ m/^(WBGene\d+)\t(.*?)\t(.*?)$/;
#   $sanger_hash{$wbgene} = $genename;
# } # foreach my $line (@lines)


my $infile = '03282008_upload.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/WBGene\d+/) { 
    my (@ace_gene) = $line =~ m/(WBGene\d+)/g; 
    foreach my $ace_gene (@ace_gene) { 
      if ($sanger_hash{$ace_gene}) { print "ACE in sanger list : $ace_gene : the locus is $sanger_hash{$ace_gene}\n"; }
        else { print "ACE NOT in sanger list : $ace_gene\n"; }
    }
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

