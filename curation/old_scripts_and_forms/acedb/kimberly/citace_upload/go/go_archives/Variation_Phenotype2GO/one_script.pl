#!/usr/bin/perl

use strict;
use LWP::Simple;
use Jex;

my $pho_file = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
my $goe_file = get "http://www.geneontology.org/ontology/gene_ontology_edit.obo";

my $date = &getSimpleDate();

my %go;
my (@go_terms) = split/\[Term\]/, $goe_file;
foreach my $term (@go_terms) {
  my ($id) = $term =~ m/id: (GO:\d+)/;
  next unless $id;
  my ($name) = $term =~ m/name: (.*?)\n/s;
  $go{$id} = $name;
}

my $outfile = 'variation_phenotype2go_mappings.full.' . $date;
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

my (@ph_terms) = split/\[Term\]/, $pho_file;
foreach my $term (@ph_terms) {
  my ($id) = $term =~ m/id: (WBPhenotype:\d+)/;
  next unless $id;
  my ($name) = $term =~ m/name: (.*?)\n/s;
  my (@gos) = $term =~ m/(GO:\d+)/g;
#   my $gos = join ", ", @gos;
  if ($gos[0]) { foreach my $go (@gos) {
    print OUT "$id\t$name\t$go\t$go{$go}\n"; } }
#   else {
#     print OUT "$id\t$name\n"; }
}

close (OUT) or die "Cannot close $outfile : $!";
