#!/usr/bin/perl

use strict;


my $to_sent = 'community_curation_source';
my %send;

my $paplist = 'paplist';
my %pap;

open (IN, "<$paplist") or die "Cannot open $paplist : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/WBPaper//;
  $pap{$line}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $paplist : $!";

open (IN, "<$to_sent") or die "Cannot open $to_sent : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@line) = split/\t/, $line;
  my $paps = $line[3];
  my (@paps) = split/, /, $paps;
  foreach (@paps) { $send{$_}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $to_sent : $!";

foreach my $pap (sort keys %pap) {
  unless ($send{$pap}) { print qq($pap list from PAPERS, not in form to send\n); }
} # foreach my $pap (sort keys %pap)

foreach my $send (sort keys %send) {
  unless ($pap{$send}) { print qq($send list from form to SEND, not in paper list\n); }
} # foreach my $send (sort keys %send)

__END__

longlist
parse_disparity.pl*
