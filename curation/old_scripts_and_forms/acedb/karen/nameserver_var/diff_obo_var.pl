#!/usr/bin/perl

# compare two files to see what's in one and not other (and viceversa), for some reason 
# diff -y --suppress-common-lines obo_var_taz obo_var_mango > diff_obo_var 
# does not work  2011 05 09


my %mango; my %taz;

my $infile = 'obo_var_mango';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) { chomp; $mango{$_}++; }
close (IN) or die "Cannot close $infile : $!";

$infile = 'obo_var_taz';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) { chomp; $taz{$_}++; }
close (IN) or die "Cannot close $infile : $!";

print "In taz, not mango:\n";
foreach my $var (sort keys %taz) { unless ($mango{$var}) { print "$var\n"; } }

print "\n\nIn mango, not taz:\n";
foreach my $var (sort keys %mango) { unless ($taz{$var}) { print "$var\n"; } }
