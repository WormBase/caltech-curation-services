#!/usr/bin/env perl

# check .ace file for Ranjana bassed on http://wiki.wormbase.org/index.php/OA_and_scripts_for_disease_data#Dumping_Disease_model_annotation_data
# 2017 06 13
#
# Output to latest file locally, and also to files/<file>.date  2023 03 27


use strict;
use Jex;

my $infile = $ARGV[0];

unless ($infile) { die "Need to enter an inputfile ./check_disease_annotation.pl <filename>\n"; }

my $date = &getSimpleDate();

my $outfile = $infile . '.errors';
my $outfile2 = 'files/' . $infile . '.errors.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!";

$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
my @regularTags = qw( Disease_term Association_type Evidence_code Paper_evidence Curator_confirmed Date_last_updated );
while (my $entry = <IN>) {
  my @lines = split/\n/, $entry;
  my $name = $lines[0];
  next unless ($name =~ m/Disease_model_annotation/);
  foreach my $tag (@regularTags) {
    unless ($entry =~ m/$tag/) { 
      print OUT qq($tag missing from $name\n);
      print OU2 qq($tag missing from $name\n); } }
  unless ( ($entry =~ m/Strain/) || ($entry =~ m/Variation/) || ($entry =~ m/Transgene/) || ($entry =~ m/Disease_relevant_gene/) ) {
    print OUT qq(Strain + Variation + Transgene + Disease_relevant_gene missing from $name\n);
    print OU2 qq(Strain + Variation + Transgene + Disease_relevant_gene missing from $name\n); }
  unless ($entry =~ m/Modifier_association_type/) {
    if ( ($entry =~ m/Modifier_transgene/) || ($entry =~ m/Modifier_variation/) || ($entry =~ m/Modifier_strain/) ||
         ($entry =~ m/Modifier_Gene/) || ($entry =~ m/Modifier_molecule/) || ($entry =~ m/Other_modifier/) ) {
      print OUT qq(Modifier_association_type missing from $name\n);
      print OU2 qq(Modifier_association_type missing from $name\n); } }
}
close (IN) or die "Cannot close $infile : $!";

close (OUT) or die "Cannot close $outfile : $!";
close (OU2) or die "Cannot close $outfile2 : $!";
