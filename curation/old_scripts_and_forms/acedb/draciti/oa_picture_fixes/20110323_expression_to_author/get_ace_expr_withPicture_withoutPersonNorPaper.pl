#!/usr/bin/perl

# get list of Expr .ace objects  that have Picture but don't have Reference (none of them have WBPerson)

use strict;

$/ = "";
my $infile = 'ExprWS221.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  next unless ($para =~ m/Picture\t/);
  if ($para !~ m/Reference\t/) { print "$para"; }
}
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";
