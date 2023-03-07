#!/usr/bin/env perl

# remove okay characters and separate .ace objects by bad characters.  2012 10 10

use strict;

my $infile = 'pictures.ace';

if ($ARGV[0]) { $infile = $ARGV[0]; }

my @paras;

$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) { push @paras, $para; }
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my %badChars;
foreach my $para (@paras) {
  my $badChars = $para;
  if ($badChars =~ m/[\w\-.,;:?\/\\@#\$\%\^&*\>\<(){}[\]+=!~|' \t\n\r\f\"≥]/) {
    $badChars =~ s/[\w\-.,;:?\/\\@#\$\%\^&*\>\<(){}[\]+=!~|' \t\n\r\f\"≥]//g; }    # based on untaint to strip non utf stuff : DBD::Pg::db do failed: ERROR:  invalid byte sequence for encoding "UTF8": 0xc561
  if ($badChars) { 
    my @badChars = split//, $badChars;
    foreach (@badChars) { $badChars{$_}{$para}++; }
  }
} # foreach my $para (@paras)

foreach my $badChar (sort keys %badChars) { 
  print "CHAR $badChar :\n";
  foreach my $para (sort keys %{ $badChars{$badChar} }) { 
    print "$para";
  } # foreach my $para (sort keys %{ $badChars{$badChar} })
  print "\n";
} # foreach my $badChar (sort keys %badChars) 
