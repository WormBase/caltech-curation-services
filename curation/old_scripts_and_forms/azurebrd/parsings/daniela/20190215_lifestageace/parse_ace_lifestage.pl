#!/usr/bin/perl

use strict;

# my %orphans;
# my $listfile = 'list';
# open (IN, "<$listfile") or die "Cannot open $listfile : $!";
# while (my $line = <IN>) { chomp $line; $line =~ s/_/:/; $orphans{$line}++; }
# close (IN) or die "Cannot close $listfile : $!";

my $acefile = 'cminus_LifeStage_02_2019backup.ace';
open (IN, "<$acefile") or die "Cannot open $acefile : $!";
while (my $line = <IN>) {
  if ($line =~ m/^Life_stage/) { print $line; }
    elsif ($line eq "\n") { print $line; }
    elsif ($line =~ m/^Public_name/) { print qq(-D $line); }
    elsif ($line =~ m/^Sub_stage/) { print qq(-D $line); }
    elsif ($line =~ m/^Contained_in/) { print qq(-D $line); }
    elsif ($line =~ m/^Preceded_by/) { print qq(-D $line); }
    elsif ($line =~ m/^Followed_by/) { print qq(-D $line); }
    elsif ($line =~ m/^Remark/) { print qq(-D $line); }
    elsif ($line =~ m/^Definition/) { print qq(-D $line); }
    elsif ($line =~ m/^Other_name/) { print qq(-D $line); }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $acefile : $!";
