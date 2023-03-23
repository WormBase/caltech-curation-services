#!/usr/bin/perl

# convert lifestage for WS230 from name to ID; add Public_name tag; convert Contained_in, Followed_by, Preceded_by, Sub_stage; Remark with goid.  2012 05 10

use strict;

my $mapfile = 'lifestageMappings';
my $acefile = 'Life_stageWS230.ace';

my %map;
open (IN, "<$mapfile") or die "Cannot open $mapfile : $!";
while (my $line = <IN>) {
  chomp $line;
  (my $id, my $name) = split/\t/, $line;
  $map{$name} = $id;
} # while (my $line = <IN>)
close (IN) or die "Cannot open $mapfile : $!";


$/ = "";
open (IN, "<$acefile") or die "Cannot open $acefile : $!";
while (my $para = <IN>) {
  next unless ($para =~ m/^Life_stage/);
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my ($objName) = $header =~ m/ : "(.*?)"/;
  unless ($map{$objName}) { 
    print "ERROR no mapping for $objName in $para\n"; 
    next; }
  print qq(-R Life_stage "$objName" "$map{$objName}"\n\n);
  my @output;
  print qq(Life_stage : "$map{$objName}"\n);
  print qq(Public_name\t "$objName"\n);
  foreach my $line (@lines) {
    if ($line =~ m/Contained_in\s+"(.*?)"/) {
      my $name = $1;
      print "-D $line\n";
      if ($map{$name}) { 
          $line =~ s/$name/$map{$name}/g;
          print "$line\n"; }
        else { print "ERROR no mapping for $name in $objName\n"; } }
    elsif ($line =~ m/Followed_by\s+"(.*?)"/) {
      my $name = $1;
      print "-D $line\n";
      if ($map{$name}) { 
          $line =~ s/$name/$map{$name}/g;
          print "$line\n"; }
        else { print "ERROR no mapping for $name in $objName\n"; } }
    elsif ($line =~ m/Preceded_by\s+"(.*?)"/) {
      my $name = $1;
      print "-D $line\n";
      if ($map{$name}) { 
          $line =~ s/$name/$map{$name}/g;
          print "$line\n"; }
        else { print "ERROR no mapping for $name in $objName\n"; } }
    elsif ($line =~ m/Sub_stage\s+"(.*?)"/) {
      my $name = $1;
      print "-D $line\n";
      if ($map{$name}) { 
          $line =~ s/$name/$map{$name}/g;
          print "$line\n"; }
        else { print "ERROR no mapping for $name in $objName\n"; } }
    elsif ($line =~ m/Remark\s+"goid:/) {
      print "-D $line\n"; }
  } # foreach my $line (@lines)
  print "\n\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot open $acefile : $!";
$/ = "\n";

