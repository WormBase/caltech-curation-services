#!/usr/bin/perl

# Take result of :
# grep @ WBPaper0003[12]* 
# in textpresso-dev@textpresso.org at 
# /data2/data-processing/data/celegans/Data/processedfiles/body/ 
# and process to find email addresses.  2008 08 08
#
# Use the textpresso cronjob output (everyday 2 am) instead of the static file.
# 2008 10 17

use strict;
use diagnostics;
use LWP::Simple;

my %emails;

# my $infile = 'textpresso_grep_@';
# my $infile = 'grep_output';
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) { 
my $infile = get "http://textpresso-dev.caltech.edu/azurebrd/grep_output";
my (@lines) = split/\n/, $infile;
foreach my $line (@lines) {
#   my ($paper) = $line =~ m/^WBPaper(\d+):/;
  my ($paper) = $line =~ m/^\/data2\/data-processing\/data\/celegans\/Data\/processedfiles\/body\/WBPaper(\d+):/;
  next unless $paper;
  next if ($emails{$paper});
  my ($email) = $line =~ m/((?:[\w\-]+ \. )*[\w\-]+\s*\@\s*[\w\-]+(?: \. [\w\-]+)+) \S/;
  $email =~ s/\s+//g;
  $emails{$paper} = $email;
} # while (my $line = <IN>)
# close (IN) or die "Cannot close $infile : $!";

foreach my $paper (sort {$a<=>$b} keys %emails) {
  print "$paper\t$emails{$paper}\n";
} # foreach my $paper (sort {$a<=>$b} keys %emails)


__END__ 

WBPaper00031000:In addition , mutations in unc-80 *Correspondence : schuske@biology . utah . edu suppressed both a hypomorphic allele of unc-26 ( e314 ) and , to a lesser degree , a null allele of unc-26 ( s1710 ) . 
WBPaper00031001:A critical component of the timekeeping mechanism of this rhythm is the inositol-1 , 4 , 5 *Correspondence : jorgensen@biology . utah . edu trisphosphate ( IP3 ) receptor [ 4 , 5 ] . 
