#!/usr/bin/perl

# Grab name and synonym data ``that cannot be identified as unique within 29
# characters''.  For Carol  2005 09 06

my $infile = 'WORManat1_1417_5.obo';

my %name;
my %synonym;

$/ = '';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $wholefile = <IN>;
close (IN) or die "Cannot close $infile : $!";
$wholefile =~ s///g;

my @paras = split/\n\n/, $wholefile;
foreach my $paragraph (@paras) {
  if ($paragraph =~ m/name: (.{0,29})/) { $name{$1}++; }
  if ($paragraph =~ m/synonym: (.{0,29})/) { $synonym{$1}++; }
} # while (<IN>)

foreach my $name (sort keys %name) { 
  if ($name{$name} > 1) { print "NAME $name{$name} : $name\n"; } }

foreach my $synonym (sort keys %synonym) { 
  if ($synonym{$synonym} > 1) { print "SYNONYM $synonym{$synonym} : $synonym\n"; } }


