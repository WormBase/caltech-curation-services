#!/usr/bin/perl -w
#
# Purpose: Reads in year, volume and page information to create a data file
#          needed for downloading pdfs
#
# Author:  Hans-Michael Muller
# Date:    February 2006

if (@ARGV < 4) { die "

USAGE: $0 <year directory> <citation directory> <journal directory> <output file>

SAMPLE INPUT:  $0 year citation journal
\n
";}
##############################################################################
use strict;

my $yeardir = $ARGV[0];
my $citationdir = $ARGV[1];
my $journaldir = $ARGV[2];
my $output_file = $ARGV[3];

my @yearfiles = <$yeardir/*>;

open (OUT, ">$output_file");
foreach my $file (@yearfiles) {
    (my $pmid = $file) =~ s/$yeardir\///;
    open (YEAR, "<$file");
    my $year = <YEAR>;
    chomp $year;
    close (YEAR);
    open (CIT, "<$citationdir/$pmid");
    my $volume = <CIT>;
    chomp $volume;
    $volume =~ s/V: //;
    my $issue = <CIT>;
    chomp $issue;
    $issue =~ s/I: //;
    my $page = <CIT>;
    chomp $page;    
    close (CIT);
    my @splits = split(/-/, $page);
#    $splits[0] =~ s/P: (\d+)/$1/;
    $splits[0] =~ s/P: (\w+)/$1/;
    open (JOU, "<$journaldir/$pmid");
    my $journal = <JOU>;
    chomp $journal;
    close (JOU);
    print OUT $journal, "\t", $pmid, "\t", $year, "\t", $volume, "\t", $issue, "\t", $splits[0], "\n";
}
close (OUT);
