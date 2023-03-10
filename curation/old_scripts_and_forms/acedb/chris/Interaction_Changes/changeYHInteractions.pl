#!/usr/bin/perl

# parse YH data for new Interaction model.  2012 02 10

use strict;

$/ = "";
my $infile = 'Object_source_files/Interaction_YH_objects.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
# my $junk = <IN>;
while (my $object = <IN>) {
  my (@lines) = split/\n/, $object;
  my $header = shift @lines;
  my ($objName) = $header =~ m/\"(.*?)\"/;
  print "$header\n";
  foreach my $line (@lines) {
    my ($tag, @rest) = split/\t/, $line;
    my $rest = join"\t", @rest;
    if ($tag eq 'PCR_bait') { $line = "PCR_interactor\t" . $rest . "\tBait"; }
    elsif ($tag eq 'Sequence_bait') { $line = "Sequence_interactor\t" . $rest . "\tBait"; }
    elsif ($tag eq 'Bait_overlapping_CDS') { $line = "Interactor_overlapping_CDS\t" . $rest . "\tBait"; }
    elsif ($tag eq 'Bait_overlapping_gene') { $line = "Interactor_overlapping_gene\t" . $rest . "\tBait"; }
    elsif ($tag eq 'PCR_target') { $line = "PCR_interactor\t" . $rest . "\tTarget"; }
    elsif ($tag eq 'Sequence_target') { $line = "Sequence_interactor\t" . $rest . "\tTarget"; }
    elsif ($tag eq 'Target_overlapping_CDS') { $line = "Interactor_overlapping_CDS\t" . $rest . "\tTarget"; }
    elsif ($tag eq 'Target_overlapping_gene') { $line = "Interactor_overlapping_gene\t" . $rest . "\tTarget"; }
    elsif ($tag eq 'Y2H') { $line = "Yeast_two_hybrid\t" . $rest; }
    elsif ($tag eq 'Y1H') { $line = "Yeast_one_hybrid\t" . $rest; }
    elsif ($tag eq 'Directed_Y1H') { $line = "Directed_yeast_one_hybrid"; }
    elsif ($tag eq 'Reference') { $line = "Paper\t" . $rest; }
    elsif ($tag eq 'Interactome_core_1') {  $line = "Description\t\"Interactome core 1\""; }
    elsif ($tag eq 'Interactome_core_2') {  $line = "Description\t\"Interactome core 2\""; }
    elsif ($tag eq 'Interactome_noncore') { $line = "Description\t\"Interactome noncore\""; }
#     else { $line = "ERR unexpected line $line"; }
    print "$line\n";
  } # foreach my $line (@lines)
  print "Physical\n\n";
} # while (my $object = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";
