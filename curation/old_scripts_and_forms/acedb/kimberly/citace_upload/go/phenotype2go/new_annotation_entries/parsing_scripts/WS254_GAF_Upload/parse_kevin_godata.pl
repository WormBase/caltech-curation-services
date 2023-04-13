#!/usr/bin/perl

use strict;
use diagnostics;


my %ptg;
# my $ptgfile = 'phenotype2go.WS247.wb';	# 2015 02 25 run
# my $ptgfile = 'phenotype2go.WS248.wb';	# 2015 04 20 run
# my $ptgfile = 'phenotype2go.latest';		# 2015 07 24 latest
# my $ptgfile = 'phenotype2go.WS249.wb';          # 2015 07 24 run
my $ptgfile = 'phenotype2go.WS253.wb';		#2016 07 15 run
open (IN, "<$ptgfile") or die "Cannot open $ptgfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@row) = split/\t/, $line;
  next unless ($row[0] eq 'WB');
  my $wbgene = $row[1]; 
  if ($row[5] =~ m/(pmid:\d+)/i) { 
    my $pmid = $1; 
    ($pmid) = uc($pmid);
#     $ptg{$wbgene}{$pmid} = $line;
    $ptg{$wbgene}{$pmid}{$line}++;
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $ptgfile : $!";

my %uniToWBGene;
my $gp2file = 'gp2protein.wb';
open (IN, "<$gp2file") or die "Cannot open $gp2file : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($gene, $uniprots) = split/\t/, $line;
  next unless ($uniprots);
  my ($wbgene)   =     $gene =~ m/(WBGene\d+)/;
  my (@uniprots) = $uniprots =~ m/UniProtKB:(\w+)/g;
  foreach (@uniprots) { $uniToWBGene{$_} = $wbgene; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $gp2file : $!";


my %gpa;
# my $gpafile = 'gp_association.6239_wormbase';
my $replacedfile = 'gene_association.goa_worm.replaced';
my $gpafile = 'gene_association.goa_worm';
open (IN, "<$gpafile") or die "Cannot open $gpafile : $!";
open (OUT, ">$replacedfile") or die "Cannot write $replacedfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@row) = split/\t/, $line;
  next unless ($row[0] eq 'UniProtKB');
  next unless ($row[8] eq 'P');
  my $uniprot = $row[1];
  if ($uniToWBGene{$uniprot}) {
      $row[1] = $uniToWBGene{$uniprot}; 
      my $wbgene = $row[1];
      my $replaceLine = join"\t", @row;
      print OUT qq($replaceLine\n);
      if ($row[5] =~ m/(pmid:\d+)/i) { 
        my $pmid = $1;
        ($pmid) = uc($pmid);
        $gpa{$wbgene}{$pmid}++;
      }
    }
    else { print "ERR $uniprot no match in $gp2file\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $gpafile : $!";
close (OUT) or die "Cannot close $replacedfile : $!";

my $redundantfile = 'redundantGpaEntries';
open (RED, ">$redundantfile") or die "Cannot write $redundantfile : $!";
my $newgpafile = 'newGpaEntries';
open (NEW, ">$newgpafile") or die "Cannot write $newgpafile : $!";
foreach my $wbgene (sort keys %ptg) {
  foreach my $pmid (sort keys %{ $ptg{$wbgene} }) {
    if ($gpa{$wbgene}{$pmid}) { print RED qq($ptg{$wbgene}{$pmid}\n); }
      else { 
#         print NEW qq($ptg{$wbgene}{$pmid}\n);
        foreach my $line (sort keys %{ $ptg{$wbgene}{$pmid} }) {
          print NEW qq($line\n); } }
  } # foreach my $pmid (sort keys %{ $ptg{$wbgene} })
} # foreach my $wbgene (sort keys %ptg)
close (RED) or die "Cannot close $redundantfile : $!";
close (NEW) or die "Cannot close $newgpafile : $!";

__END__

gp2protein.wb
phenotype2go.WS246.wb
gene_association.goa_worm
