#! /usr/bin/perl

use strict;

open IN, "<", "./interaction.ace.20110224";
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
