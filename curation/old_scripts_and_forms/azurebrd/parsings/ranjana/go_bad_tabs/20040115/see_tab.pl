#!/usr/bin/perl

# find out if a file has 14 tabs in each line.  if not output the offending line
# number, with a count of tabs, and the line itself.   
# usage : ./see_tab.pl filename
# 2003 10 13
#
# Ignore lines that don't begin with WB.  2003 11 04
#
# Get rid of extra tabs after paper and get rid of space and : after GO code.  
# Output to separate file.  2004 01 20

my $infile = $ARGV[0];
my $outfile = $ARGV[1];
my $count = 0;

my $goodlines = 0;
my $badlines = 0;

unless ($ARGV[1]) { print "Need to name output file in format ./see_tab.pl input output > errors\n"; die; }

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  $count++;
  unless ($_ =~ m/^WB/) { print OUT; next; }	# output wrong lines but don't change them
  my (@tab) = $_ =~ m/\t/g;			# count tabs in array
  if (scalar(@tab) == 14) { $goodlines++; }
  else { 					# incorrect number of tabs
    if ($_ =~ m/^(WB\tCE\d{5}\t[^\t]*?\t\tGO:\d{7}) :(\t[^\t]*?.*)/) { 
      $_ = "$1$2\n"; }				# extra space and colon
    if ($_ =~ m/^(WB\tCE\d{5}\t[^\t]*?\t\tGO:\d{7}\t[^\t]*?)\t\t([A-Z]{1,3}\t.*)/) { 
      print "$count " . scalar(@tab) . " CHANGED $_ TO $1\t$2\n";
      $_ = "$1\t$2\n"; }			# extra tab
    elsif ($_ =~ m/^(WB\tCE\d{5}\t[^\t]*?\t\tGO:\d{7}\t[^\t]*?)\t\t\t([A-Z]{1,3}\t.*)/) { 
      print "$count " . scalar(@tab) . " CHANGED $_ TO $1\t$2\n";
      $_ = "$1\t$2\n"; }			# two extra tabs
    else {
      print "$count " . scalar(@tab) . " CAN'T FIX IT\t$_"; $badlines++; }	# error message
  }
  my (@tab2) = $_ =~ m/\t/g;
#   print OUT scalar(@tab) . " " . scalar(@tab2) . $_;
  print OUT $_;
}
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";

if ($goodlines) { print "There are $goodlines good lines\n"; }
if ($badlines) { print "There are $badlines bad lines\n"; }
