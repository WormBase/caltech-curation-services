#!/usr/bin/perl

# citace didn't match paperdump, use this to parse citace dump to look like postgres paper dump
# don't know what caused things to be out sync, but horvitz's 602 papers weren't in as well as
# many other things.  2004 02 07.

use diagnostics;

my $infile = 'citacePersonPaper20040207.ace';

open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  if ( ($_ =~ m/^Person/) || ($_ =~ m/^Paper/) || ($_ =~ m/^\s*$/) || ($_ =~ m/^Possibly_publishes_as/) ) { 
    if ($_ =~ m/^Person/) { $_ =~ s/\"//g; }
    $_ =~ s/\t /	/g;
    $_ =~ s/ : /	/g;
    print; }
}

