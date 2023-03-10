#!/usr/bin/perl 

my $infile = 'contact_details.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ($_ =~ m/^Author/) { print "\n$_"; }
  elsif ($_ =~ m/^Contact_details_confirmed/) { print "-D $_"; }
} # while (<IN>)
