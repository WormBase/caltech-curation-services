#!/usr/bin/perl

# find out if a file has 14 tabs in each line.  if not output the offending line
# number, with a count of tabs, and the line itself.   
# usage : ./see_tab.pl filename
# 2003 10 13
#
# Ignore lines that don't begin with WB.  2003 11 04

my $infile = $ARGV[0];
my $count = 0;

my $goodlines = 0;
my $badlines = 0;

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  unless ($_ =~ m/^WB/) { next; }
  $count++;
  my (@tab) = $_ =~ m/\t/g;
  if (scalar(@tab) == 14) { $goodlines++; }
    else { print "$count " . scalar(@tab) . "\t$_"; $badlines++; }
}
close (IN) or die "Cannot close $infile : $!";

if ($goodlines) { print "There are $goodlines good lines\n"; }
if ($badlines) { print "There are $badlines bad lines\n"; }
