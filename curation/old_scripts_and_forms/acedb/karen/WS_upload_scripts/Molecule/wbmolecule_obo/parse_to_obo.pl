#!/usr/bin/perl

# generate a WBMol obo file from a tsv file that Karen told me to DL.  2010 04 14

use strict;
use diagnostics;

print "default-namespace: wbmol\n";
print "date: 14:04:2010 13:14\n";
print "\n\n";


my $count = 0;
my $infile = 'CTD_chemicals.tsv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($pub, $casrn, $mesh) = split/\t/, $line;
  $count++; my $id = &padZeros($count);
  print "[Term]\n";
  print "id: WBMol:$id\n";
  print "name: $pub\n";
  print "xref: CasRN: \"$casrn\"\n";
  print "xref: MeSH_UID: \"$mesh\"\n";
  print "\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

