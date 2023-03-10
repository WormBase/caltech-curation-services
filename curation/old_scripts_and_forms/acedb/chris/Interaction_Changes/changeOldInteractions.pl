#!/usr/bin/perl

# parse old Interaction data for new Interaction model.  2012 02 10

use strict;

my %subtags;
$subtags{"Genetic"} = "Genetic_interaction";
$subtags{"Regulatory"} = "Regulatory";
$subtags{"No_interaction"} = " No_interaction";
$subtags{"Predicted_interaction"} = "Predicted";
$subtags{"Physical_interaction"} = "Physical";
$subtags{"Suppression"} = "Suppression";
$subtags{"Enhancement"} = "Enhancement";
$subtags{"Synthetic"} = "Synthetic";
$subtags{"Epistasis"} = "Epistasis";
$subtags{"Mutual_enhancement"} = "Mutual_enhancement";
$subtags{"Mutual_suppression"} = "Mutual_suppression";


my $count = 0; my $max = 10;
$/ = "";
my $infile = './31465_interaction.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;
while (my $object = <IN>) {
#   $count++; last if ($count > $max);
  my (@lines) = split/\n/, $object;
  my $header = shift @lines;
  my ($objName) = $header =~ m/\"(.*?)\"/;
  print "$header\n";
  foreach my $line (@lines) {
    my ($tag, @rest) = split/\t/, $line;
    my $rest = join"\t", @rest;
    if ($rest =~ m/^\s+/) { $rest =~ s/^\s+//; } if ($rest =~ m/\s+$/) { $rest =~ s/\s+$//; }
    if ($tag eq 'Interactor') { $line = "Interactor_overlapping_gene\t" . $rest; }
    elsif ($subtags{$tag}) {
      my ($subtag, @rest2) = split/\s+/, $rest;
      my $rest2 = join" ", @rest2;
      if ($subtag eq 'Interaction_RNAi') { $line = "Interaction_RNAi\t$rest2\n$subtags{$tag}"; }
      elsif ($subtag eq 'Interaction_phenotype') { $line = "Interaction_phenotype\t$rest2\n$subtags{$tag}"; }
      elsif ($subtag eq 'Effector') { $line = "Interactor_overlapping_gene\t$rest2\tEffector\n$subtags{$tag}"; }
      elsif ($subtag eq 'Effected') { $line = "Interactor_overlapping_gene\t$rest2\tAffected\n$subtags{$tag}"; }
      elsif ($subtag eq 'Non_directional') { $line = "Interactor_overlapping_gene\t$rest2\tNon_directional\n$subtags{$tag}"; }
#       else { $line = "ST $subtag R2 $rest2 T $tag\n"; }
    }
    print "$line\n";
  } # foreach my $line (@lines)
  print "\n";
} # while (my $object = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";
