#!/usr/bin/env perl

# parse pato.obo into pato.ace for Chris.  2015 09 24

use strict;
use LWP::Simple;

my $url  = 'https://github.com/pato-ontology/pato/raw/master/pato.obo';
my $data = get $url;

my $version = '';
my (@entries) = split/\[Term\]/, $data;
my $header = shift @entries;
if ($header =~ m/data-version: (.*?)\n/) { $version = "PATO ontology $1"; }

my $outfile = 'pato.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $entry (@entries) {
  my ($id, $name, $def, $altid, $syn, $status, $parent);
  if ($entry =~ m/id: (PATO:\d+)/) {    $id = $1;     }
  next unless $id;
  if ($entry =~ m/name: (.*)/) {        $name = $1;   }
  if ($entry =~ m/alt_id: (.*)/) {      $altid = $1;  }
  if ($entry =~ m/synonym: "(.*?)"/) {  $syn = $1;    }
  if ($entry =~ m/def: "(.*?)"/) {      $def = $1;    }
  if ($entry =~ m/is_obsolete: true/) { $status = "Obsolete"; } else { $status = "Valid"; }
  if ($entry =~ m/is_a: ([^\s]+)/) {    $parent = $1; }
  print OUT qq(PATO_term : "$id"\n);
  if ($name) {    print OUT qq(Name\t"$name"\n);       }
  if ($def) {     print OUT qq(Definition\t"$def"\n);  }
  if ($altid) {   print OUT qq(Alt_id\t"$altid"\n);    }
  if ($syn) {     print OUT qq(Synonym\t"$syn"\n);     }
  if ($status) {  print OUT qq(Status\t"$status"\n);   }
  if ($parent) {  print OUT qq(Parent\t"$parent"\n);   }
  if ($version) { print OUT qq(Version\t"$version"\n); }
  print OUT "\n";
} # foreach my $entry (@entries)

close (OUT) or die "Cannot close $outfile : $!";
