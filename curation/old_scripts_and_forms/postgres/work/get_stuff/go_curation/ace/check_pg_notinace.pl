#!/usr/bin/perl

# get the sequences from the ace file wen gave me.  get the sequences from the 
# pg outfile dump.  see which ones are in the pg that are not in ace and print
# to screen.  2002 11 27

use strict;
use diagnostics;

my $pg_file = 'outfile.ace';
my $ace_file = 'ace_seq.ace';

my %ace;
my %pg;
my %pg_count;

open (ACE, "<$ace_file") or die "Cannot open $ace_file : $!";
while (<ACE>) {
  $_ =~ m/"(.*)"/g;
  $ace{$1}++;
} # while (<ACE>)
close (ACE) or die "Cannot close $ace_file : $!";

$/ = "";
open (PG, "<$pg_file") or die "Cannot open $pg_file : $!";
while (<PG>) {
  if ($_ =~ m/^Sequence : "(.*)"/) {
    $pg_count{$1}++;
    $pg{$1} = $_;
  }
} # while (<PG>)
close (PG) or die "Cannot close $pg_file : $!";

# foreach (sort keys %pg_count) {
#   if ($pg_count{$_} > 1) { print "$_ has $pg_count{$_} entries\n"; }
# } # foreach (sort keys %pg_count)

my $count = 0;

foreach (sort keys %pg) { 
  unless ($ace{$_}) {
    print "$pg{$_}";
    $count++;
  } # unless ($ace{$_})
} # foreach (sort keys %pg)

print "THERE ARE $count SEQUENCE ENTRIES MISSING\n";
