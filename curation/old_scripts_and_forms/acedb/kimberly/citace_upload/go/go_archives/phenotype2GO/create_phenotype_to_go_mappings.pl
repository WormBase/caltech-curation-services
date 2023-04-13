#!/usr/bin/perl

# create phenotype to go mappings based on PhenoNameGO.ace and obos from
# gene_ontology and phenotype_ontology.  2007 10 18

use strict;
use LWP::Simple;
use Jex;

my $directory = '/home/acedb/ranjana/phenotype2GO';
chdir ($directory) or die "Cannot change to $directory : $!";

my $date = &getSimpleDate();
my $outfile = 'phenotype_to_go_mappings.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


my $obofile = '/home2/acedb/ranjana/GO/ontology/gene_ontology_edit.obo';
my %gobo;
$/ = '';
open (IN, "<$obofile") or die "Cannot open $obofile : $!";
while (my $entry = <IN>) {
  my ($id) = $entry =~ m/id: (.*?)\n/;
  my ($name) = $entry =~ m/name: (.*?)\n/;
  my ($def) = $entry =~ m/def: (.*?)\n/;
  unless ($def) { $def = 'No GO definition'; }
  $gobo{$id}{name} = $name;
  $gobo{$id}{def} = $def;
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $obofile : $!";

my %phenobo;
my $phenobo = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
my (@phens) = split/\n\n/, $phenobo;
foreach my $phen (@phens) {
  my ($id) = $phen =~ m/id: (.*?)\n/;
  my ($def) = $phen =~ m/def: (.*?)\n/;
  unless ($def) { $def = 'No phenotype definition'; }
  $phenobo{$id} = $def;
} # foreach my $phen (@phens)

undef $/;
my $inputfile = 'PhenoNameGO.ace';
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
my $wholeinput = <IN>;
close (IN) or die "Cannot close $inputfile : $!";
my (@entries) = split/Phenotype : /, $wholeinput;
foreach my $entry (@entries) {
  my ($phen_id) = $entry =~ m/^\"(.*?)\"/;
  my ($phen_name) = $entry =~ m/Primary_name\s+\"(.*?)\"/;
  my ($go_id) = $entry =~ m/GO_term\s+\"(.*?)\"/;
  unless ($gobo{$go_id}{def}) { $gobo{$go_id}{def} = 'No GO definition'; }
  print OUT "$phen_id\t$phen_name\t$go_id\t$gobo{$go_id}{name}\n";
  print OUT "$phenobo{$phen_id}\n";
  print OUT "$gobo{$go_id}{def}\n";
  print OUT "\n";
} # while (my $entry = <IN>)

close (OUT) or die "Cannot close $outfile : $!";

__END__

same go name
phen def
go def
