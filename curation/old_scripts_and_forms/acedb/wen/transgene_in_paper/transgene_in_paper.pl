#!/usr/bin/perl -w

# for wen to find textpresso transgene-paper connections that are not in WS
# 2008 04 10
#
# adapted to use textpresso output data, exclude obsoletes, and replace
# synonyms.  2008 06 23


use strict;
use LWP::Simple;

my %ws;
$/ = "";
# my $infile = 'WS190PaperTg.ace';
my $infile = 'WSPaperTg.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($paper) = $para =~ m/(WBPaper\d{8})/;
  my (@transgene) = $para =~ m/Transgene\s+\"(.*?)\"/g;
  foreach (@transgene) { $ws{$paper}{$_}++; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

my %syn;
my $syn_file = 'TgSynonym.ace';
open (SYN, "<$syn_file") or die "Cannot open $syn_file : $!";
while (my $para = <SYN>) { 
  my ($tran) = $para =~ m/Transgene\s+:\s+\"(.*?)\"/;
  my (@syn) = $para =~ m/Synonym\s+\"(.*?)\"/g;
  foreach my $syn (@syn) { $syn{$syn} = $tran; }
} # while (my $para = <SYN>) 
close (SYN) or die "Cannot close $syn_file : $!";

$/ = "\n";

my %obs;
my $obs_file = 'ObsoleteTg.txt';
open (OBS, "<$obs_file") or die "Cannot open $obs_file : $!";
while (my $line = <OBS>) { if ($line =~ m/(WBPaper\d+)\s+(\S+)\s+/) { $obs{$1}{$2}++; } }
close (OBS) or die "Cannot close $obs_file : $!";

my $tfile = get "http://textpresso-dev.caltech.edu/wen/transgenes_in_regular_papers.out";
my %tdata;
my (@tlines) = split/\n/, $tfile;
foreach my $line (@tlines) {
  my ($paper, @transgene) = split/\s+/, $line;
  if ($paper =~ m/(WBPaper\d+)/) { $paper = $1; }
  foreach my $tran (@transgene) {
    next if ($obs{$paper}{$tran});
    if ($syn{$tran}) { $tran = $syn{$tran}; }
    $tdata{$paper}{$tran}++;
  } # foreach my $tran (@transgene)
} # foreach my $line (@tlines)

foreach my $paper (sort keys %tdata) {
  foreach my $transgene (sort keys %{ $tdata{$paper} }) {
    unless ($ws{$paper}{$transgene}) { print "Transgene : \"$transgene\"\nPaper : \"$paper\"\n\n"; }
  } # foreach my $tran (sort keys %{ $tdata{$paper} })
} # foreach my $paper (sort keys %tdata)


# $infile = 'wen.out';
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) {
#   my ($paper, @transgene) = split/\s+/, $line;
#   foreach my $transgene (@transgene) {
#     unless ($ws{$paper}{$transgene}) { print "Transgene : \"$transgene\"\nPaper : \"$paper\"\n\n"; }
#   } # foreach my $transgene (@transgene)
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $infile : $!";

