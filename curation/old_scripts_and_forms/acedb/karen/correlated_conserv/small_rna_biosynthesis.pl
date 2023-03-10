#!/usr/bin/perl
#  ./small_rna_biosynthesis.pl --gene WBGene00002335 --gene WBGene00000003
#If you're going to have a lot of genes and would rather just edit the script instead of entering them through the command line, change the line :
#  my @genes;
#with
#  my @genes = qw( WBGene00000003 WBGene00002335 );

use Ace;
use Getopt::Long;

my @genes;
my $database;

GetOptions('gene=s' => \@genes,
           'database=s' => \$database,
)||die(@!);

my $db = $database ?
         Ace->connect(-path => $database)||die(Ace->error) :
         Ace->connect(-host => 'mining.wormbase.org',-port => 2005)||die(Ace->error);

my %matrix;
my @rgenes;
foreach my $g(@genes){
         my $gene = $db->fetch(Gene => $g);
         my @paralogs = $gene->Paralog ||1;
         $matrix{$gene->Species}{"$gene"}= scalar @paralogs;
         map {$matrix{$_->Species}{$gene}++} $gene->Ortholog; # core species
         map {$matrix{$_->Species}{$gene}++} $gene->Ortholog_other; # other species
         push @rgenes,$gene; # push a full-fat gene object into the list
}

# dump as tab separated values
print "\"Gene\"\t";
printf "\"%s\"\n",join("\"\t\"",sort(keys %matrix));
foreach $g(@rgenes){
  print "\"$g(${\$g->Public_name})\"\t";
  foreach my $s(sort(keys %matrix)){
     print ($matrix{$s}{$g}||'0');
     print "\t";
  }
  print "\n";
}
