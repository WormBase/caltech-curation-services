#!/usr/bin/perl -w

# Read Citace dump of Persons with Lineage, and parse out leaving 
# only the Lineage data in the dumper's format for ./find_diff.pl
# to sort it out.  This creates a proper .ace file (find_diff), but 
# for some reason, acedb won't read in the #Role for some lines
# so the find_diff output has to be a set of -D followed by a full
# set of insertions.  2003 12 01

use strict;
use diagnostics;
use Jex;

my $infile = $ARGV[0];

$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ($_ =~ m/WBPerson(\d+)/) { 
    my @lines = split /\n/, $_;
    if (@lines) { 
      foreach my $line (@lines) {
        $line =~ s/\"//g;
        if ($line =~ m/Person :/) { print "$line\n"; }
        $line =~ s/ WBPerson/WBPerson/g;
        $line =~ s/ +/ /g;
        $line =~ s/ /\t/g;
        if ($line =~ m/Supervised/) { print "$line\n"; }
        if ($line =~ m/Worked_with/) { print "$line\n"; }
      } # foreach my $line (@lines)
      print "\n";
    }
  }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";
