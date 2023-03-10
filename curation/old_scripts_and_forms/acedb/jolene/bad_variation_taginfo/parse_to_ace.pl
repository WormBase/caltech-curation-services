#!/usr/bin/perl

# parse Jolene's .txt files into Remark for .ace  2010 07 23

use strict;

my @files = qw( Cold_sensitive Completely_penetrant Dominant Gain_of_function Heat_sensitive Loss_of_function Maternal Partially_penetrant Recessive Semi_dominant );

my $outfile = 'remark.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
foreach my $type (@files) {
  my $file = $type . '.txt';
  open (IN, "<$file") or die "Cannot open $file : $!";
  my $line = <IN>;
  $line = <IN>;
  while (my $line = <IN>) {
    chomp $line;
    my ($id, $remark, $evi_tag, $evi) = split/\t/, $line;
    print OUT "Variation : $id\n";
    print OUT "Remark\t\"Legacy information.  ${type}.  ";
    if ($remark) { print OUT "$remark  "; }
    print OUT "From obsolete tag info (by jolenef, 2010 07 23)\"";
    if ($evi) { print OUT "\t$evi_tag\t\"$evi\""; }
    print OUT "\n\n";
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $file : $!";
}
close (OUT) or die "Cannot close $outfile : $!";
