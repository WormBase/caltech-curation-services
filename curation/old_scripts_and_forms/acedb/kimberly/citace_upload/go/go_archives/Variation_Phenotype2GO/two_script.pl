#!/usr/bin/perl

# combine phenotype2GO_mapping_new_phenotype_id.ace with latest variation_phenotype2go_mappings.full.date to make 
# phenotype2go_mappings.ace   2009 08 12

use strict;
use LWP::Simple;


# my (@infile) = </home/acedb/ranjana/Variation_Phenotype2GO/variation_phenotype2go_mappings.full.*>;
# my $infile = pop @infile;
my $infile = $ARGV[0];
my $otherfile = 'phenotype2GO_mapping_new_phenotype_id.ace';

my %data;
$/ = "";
open (IN, "<$otherfile") or die "Cannot open $otherfile : $!";
while (my $para = <IN>) {
  my ($phen) = $para =~ m/(WBPhenotype:\d+)/;
  my (@go) = $para =~ m/(GO:\d+)/g;
  foreach (@go) { $data{$phen}{$_}++; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $otherfile : $!";

$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($phid) = $para =~ m/(WBPhenotype:\d+)/;
  my ($goid) = $para =~ m/(GO:\d+)/;
  if ($goid) { $data{$phid}{$goid}++; }
}
close (IN) or die "Cannot close $infile : $!";
# $/ = "\n";
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   my ($phid, $phname, $goid, $goname) = split/\t/, $line;
#   if ($goid) { $data{$phid}{$goid}++; }
# }
# close (IN) or die "Cannot close $infile : $!";

my $outfile = 'phenotype2go_mappings.ace';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
foreach my $phid (sort keys %data) {
  print OUT "Phenotype : \"$phid\"\n";
  foreach my $goid (sort keys %{ $data{$phid} }) {
    print OUT "GO_term \"$goid\"\n";
  } # foreach my $goid (sort keys %{ $data{$phid} })
  print OUT "\n";
} # foreach my $phid (sort keys %data)
close (OUT) or die "Cannot close $outfile : $!";



__END__

my $pho_file = get "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/phenotype_ontology_obo.cgi";
my $goe_file = get "http://www.geneontology.org/ontology/gene_ontology_edit.obo";

my %go;
my (@go_terms) = split/\[Term\]/, $goe_file;
foreach my $term (@go_terms) {
  my ($id) = $term =~ m/id: (GO:\d+)/;
  next unless $id;
  my ($name) = $term =~ m/name: (.*?)\n/s;
  $go{$id} = $name;
}

my $outfile = 'variation_phenotype2go_mappings';
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
  else {
    print OUT "$id\t$name\n"; }
}

close (OUT) or die "Cannot close $outfile : $!";
