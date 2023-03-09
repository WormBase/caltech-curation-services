#!/usr/bin/perl

# the output from the mysql query only found matches for 61 of the 168
# clones.  this script figures out which ones are the missing ones.
# 2002 01 17

my $all_clones = 'old/clones.txt';
my $good_clones = 'clone_positions.out';
# my $good_clones = 'boo';

my %good;

open (GOO, "<$good_clones") or die "Cannot open $good_clones : $!";
while (<GOO>) {
  my ($clone, @junk) = split/\t/, $_;
  $good{$clone}++;
} # while (<GOO>)
close (GOO) or die "Cannot close $good_clones : $!";

open (ALL, "<$all_clones") or die "Cannot open $all_clones : $!";
while (<ALL>) {
  chomp;
  unless ($good{$_}) { print "$_\n"; }
} # while (<ALL>)
