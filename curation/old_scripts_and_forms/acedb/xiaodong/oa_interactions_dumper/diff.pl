#! /usr/bin/perl

use strict;

open IN, "<", "./missingInteraction.ace";
#open OUT, ">" ,"./"

while(<IN>)
{
	my $line = $_;
	chomp($line);
	
	if($line =~ /(WBInteraction\d+)/)
	{
		print "$1\n";
	}
}
