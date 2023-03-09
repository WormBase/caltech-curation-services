#!/usr/bin/perl

# Get all the original Person (Mentorship) Lineage Data and re-enter it
# via Supervised to attach #role data to it.  
# output > to Fix_role_supervised.ace
# Also, (manually) delete 3 people wrongly associated to Sternberg.
# 2003 10 11

use strict;
use diagnostics;

$/ = '';

my %hash;	# key supervisor  key supervisee  value role

my $infile = 'Lineage.ace';
open (IN,"<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my ($main) = $entry =~ m/Person\t(.*)/;
  my (@others) = $entry =~ m/Supervised_by\t(.*?)\t(.*)/g;
  while (scalar(@others) > 1) {
    my $other = shift @others;
    my $role = shift @others;
    $hash{$other}{$main} = $role;
# print "MAIN $main, OTH $other, ROL $role\n";
  } # while (scalar(@others) > 0)
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $supsor (sort keys %hash) {
  print "Person\t$supsor\n";
  foreach my $supee (sort keys %{ $hash{$supsor} }) {
    print "Supervised\t$supee\t$hash{$supsor}{$supee}\n";
  } # foreach my $supee (sort keys %{ $hash{$supsor} })
  print "\n";
} # foreach my $supsor (sort keys %hash)
