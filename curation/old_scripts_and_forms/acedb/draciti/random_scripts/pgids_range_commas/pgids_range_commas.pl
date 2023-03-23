#!/usr/bin/perl

use strict;

my @array;
for my $i (7200 .. 7500) { push @array, $i; }

my $pgids = join",", @array;
print $pgids;
