#!/usr/bin/perl

# for Kimberly, for Aric Daul  2017 02 09

# run every third month on the 1st at 3 am
# 0 3 1 3,6,9,12 * /home/azurebrd/work/get_kimberly_cgc_strains/wrapper.pl




use strict;

my $directory = '/home/azurebrd/work/get_kimberly_cgc_strains';

chdir $directory or die "Cannot change directory to $directory : $!";

`./01get_cgc_data.pl`;
`./02get_cgc_strains_in_papers.pl`;

