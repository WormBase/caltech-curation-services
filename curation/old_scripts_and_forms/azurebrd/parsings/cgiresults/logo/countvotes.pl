#!/usr/bin/perl -w

# count votes for logos, banners, and authors for the wormbase logo competition
# take one.  2002 08 04

use strict;

my $infile = 'logo';

my %lines;	# lines of file
my %votes;	# votes 

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  if ($_ =~ m/.*?\t([\w\.]+?@[\w\.]+)\t.*/) { $lines{$1} = $_; } # print "$_"
} # while (<IN>)

foreach my $line ( sort keys %lines ) {
  my @votes = split/\t/, $lines{$line};
#   for (my $i = 2 .. 7) {
#   } # for (my $i = 2 .. 7)
  if ($votes[2]) {
    $votes{logo}{$votes[2]} += 3;
    if ($votes[2] =~ m/^.....?\d\d$/) {
      my ($auth) = $votes[2] =~ m/^..(...?)\d\d$/;
      $votes{author}{$auth} += 3;
    } else { print "ERR $line :$votes[2]:\n"; }
  } # if ($votes[2])
  if ($votes[3]) {
    $votes{logo}{$votes[3]} += 2;
    if ($votes[3] =~ m/^.....?\d\d$/) {
      my ($auth) = $votes[3] =~ m/^..(...?)\d\d$/;
      $votes{author}{$auth} += 2;
    } else { print "ERR $line :$votes[3]:\n"; }
  } # if ($votes[3])
  if ($votes[4]) {
    $votes{logo}{$votes[4]} += 1;
    if ($votes[4] =~ m/^.....?\d\d$/) {
      my ($auth) = $votes[4] =~ m/^..(...?)\d\d$/;
      $votes{author}{$auth} += 1;
    } else { print "ERR $line :$votes[4]:\n"; }
  } # if ($votes[4])
  if ($votes[5]) {
    $votes{banner}{$votes[5]} += 3;
    if ($votes[5] =~ m/^.....?\d\d$/) {
      my ($auth) = $votes[5] =~ m/^..(...?)\d\d$/;
      $votes{author}{$auth} += 3;
    } else { print "ERR $line :$votes[5]:\n"; }
  } # if ($votes[5])
  if ($votes[6]) {
    $votes{banner}{$votes[6]} += 2;
    if ($votes[6] =~ m/^.....?\d\d$/) {
      my ($auth) = $votes[6] =~ m/^..(...?)\d\d$/;
      $votes{author}{$auth} += 2;
    } else { print "ERR $line :$votes[6]:\n"; }
  } # if ($votes[6])
  if ($votes[7]) {
    $votes{banner}{$votes[7]} += 1;
    if ($votes[7] =~ m/^.....?\d\d$/) {
      my ($auth) = $votes[7] =~ m/^..(...?)\d\d$/;
      $votes{author}{$auth} += 1;
    } else { print "ERR $line :$votes[7]:\n"; }
  } # if ($votes[7])
} # foreach my $line ( sort keys %lines )

foreach my $type ( sort keys %votes ) {
  print $type . " :\n";
  foreach my $votes ( sort keys %{ $votes{$type} } ) {
    unless ($votes eq '') {
      print "$votes : $votes{$type}{$votes}\n";
    } # unless ($votes eq '') 
  } # foreach my $votes ( sort keys %{ $votes{$type} } )
} # foreach my $type ( sort keys %logo )
