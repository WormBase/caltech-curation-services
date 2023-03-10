#!/usr/bin/perl -w
#
use constant LIB_DIR => "/home/acedb/papers/perl-lib";
use lib LIB_DIR;
use WBAce::ReadSangerLocus;
use WBAce::ReadWBPaper;


my $wbpaper = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt";

print "Reading WBPaper identifiers names .....";
my ($WBPaper, $highest) = readWBPaper($wbpaper);
print "done\n";
for (keys %$WBPaper) {print "KEY: $_; VALUE: $$WBPaper{$_}\n"}
$count = scalar (keys %$WBPaper);
print "COUNT: $count; HIGHEST: $highest\n";
