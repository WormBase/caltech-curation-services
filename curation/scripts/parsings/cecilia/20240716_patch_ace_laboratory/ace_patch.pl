#!/usr/bin/env perl

# diff two files and try to generate a -D for object level deletion and normal create lines for object level creation.
# But does not delete whole objects that have been removed, maybe it should, but this is a quick and dirty script.
# 2024 07 16

use Dotenv -load => '/usr/lib/.env';
use strict;

my $new_file = 'laboratories.ace2024July8';
my $old_file = 'laboratory.ace';
my $out_file = 'laboratory_patch_20240708.ace';

open (OUT, ">$out_file") or die "Cannot create $out_file : $!";
$/ = "";
open (NEW, "<$new_file") or die "Cannot open $new_file : $!";
open (OLD, "<$old_file") or die "Cannot open $old_file : $!";

my %new; my %old; my %any;
while (my $para = <NEW>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  $any{$header}++;
  foreach my $line (@lines) {
    $new{$header}{$line}++;
  }
}
while (my $para = <OLD>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  $any{$header}++;
  foreach my $line (@lines) {
    $old{$header}{$line}++;
  }
}

close (NEW) or die "Cannot close $new_file : $!";
close (OLD) or die "Cannot close $old_file : $!";
$/ = "\n";

foreach my $header (sort keys %any) {
  my $output = '';
  foreach my $line (sort keys %{ $old{$header} }) {
    unless ($new{$header}{$line}) {
      $output .= qq(-D $line\n);
    }
  }
  foreach my $line (sort keys %{ $new{$header} }) {
    unless ($old{$header}{$line}) {
      $output .= qq($line\n);
    }
  }
  if ($output) {
    print OUT qq($header\n);
    print OUT qq($output\n);
  }
}

close (OUT) or die "Cannot close $out_file : $!";
