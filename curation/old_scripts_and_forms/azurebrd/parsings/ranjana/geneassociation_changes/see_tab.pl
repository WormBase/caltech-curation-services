#!/usr/bin/perl

# find out if a file has 14 tabs in each line.  if not output the offending line
# number, with a count of tabs, and the line itself.   
# usage : ./see_tab.pl filename
# 2003 10 13

my $infile = $ARGV[0];
my $count = 0;

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  $count++;
  my (@tab) = $_ =~ m/\t/g;
  unless (scalar(@tab) == 14) { print "$count " . scalar(@tab) . "\t$_"; }
}
close (IN) or die "Cannot close $infile : $!";
