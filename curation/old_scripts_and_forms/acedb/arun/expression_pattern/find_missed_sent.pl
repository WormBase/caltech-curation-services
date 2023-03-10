#!/usr/bin/perl -w
my $infile = "development_legends.txt";
open(IN, "<$infile") or die($!);
while (my $line = <IN>) {
	if ($line !~ /(xpress|localiz|present|observ|detect|stain|in situ|in-situ|western|label|antibod|orthern)/i) {
		print "$line\n";
	}
}
close(IN);
