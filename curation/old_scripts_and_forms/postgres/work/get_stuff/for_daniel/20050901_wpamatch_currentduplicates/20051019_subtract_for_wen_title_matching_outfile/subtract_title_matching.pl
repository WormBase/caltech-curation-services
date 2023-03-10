#!/usr/bin/perl

# take out those already done from daniel's list.  2005 10 19

my $long_file = 'long_list';
my $done_file = 'done_list';

my %done;
open (IN, "<$done_file") or die "Cannot open $done_file : $!";
while (my $line = <IN>) {
  if ($line =~ m/^(\d{8})\t(\d{8})/) { $done{$1}++; $done{$2}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $done_file : $!";

$/ = "";
open (IN, "<$long_file") or die "Cannot open $long_list : $!";
while (my $para = <IN>) {
  if ($para =~ m/^J (\d{8})/) { 
    my $paper = $1;
    if ($done{$paper}) { next; }
    else { print "$para"; } }
  else { print "BAD PARA $para"; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $long_list : $!";
