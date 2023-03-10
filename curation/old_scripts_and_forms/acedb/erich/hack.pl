#!/usr/bin/perl

use strict;
use warnings;

my %seen_wbpaper = ();

while (my $input = <>) { 
    if ($input =~ /\A (\d+) \s*/xms) { 
        my $paper = "WBPaper" . $1;
        $seen_wbpaper{$paper} = 1;
    }
}

foreach my $paper (sort keys %seen_wbpaper) {
    print "$paper\n";
}

