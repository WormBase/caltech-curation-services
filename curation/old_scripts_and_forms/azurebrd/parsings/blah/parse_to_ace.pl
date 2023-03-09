#!/usr/bin/perl

# take andrei's dump of comma-separated files (from somewhere, don't know where)
# and create .ace objects for interaction.  genetic is the same whether geneA
# then geneB so exclude backwards.  regulation is directional, so don't exclude
# backwards.  2004 11 10

use strict;
use diagnostics;
use LWP;

my %theHash;
my %convertToWBPaper;
&populateWBPaperHash();

my $infile = 'curation_dumps_to_ace.csv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;	# eat description line
while (<IN>) {
  chomp;
  my ($geneA, $geneB, $int, $paper) = split/,/, $_;
  $paper =~ s/ //g;
  if ($int eq 'Genetic') {
    my $key = $geneA . 'DIVIDER' . $geneB;
    my $backkey = $geneB . 'DIVIDER' . $geneA;
    unless ($theHash{gen}{$paper}{exists}{$key}) {	# unless already found it
      $theHash{gen}{$paper}{good}{$key}++;		# add to good list
      $theHash{gen}{$paper}{exists}{$key}++;		# set to exist to not duplicate it
      $theHash{gen}{$paper}{exists}{$backkey}++; }	# set to exist to not duplicate it
  } # if ($int eq 'Genetic')
  elsif ($int eq 'Regulation') {
    my $key = $geneA . 'DIVIDER' . $geneB;
    $theHash{reg}{$paper}{good}{$key}++;		# add to good list
  } # elsif ($int eq 'Regulation')
  else { print "ERR Not a valid Interaction Type $_\n"; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

my $count = 0;
foreach my $paper (sort keys %{ $theHash{gen} } ) {
  foreach my $key (sort keys %{ $theHash{gen}{$paper}{good} } ) {
    $count++; my $count_val;
    if ($count < 10) { $count_val = '000000' . $count; }
    elsif ($count < 100) { $count_val = '00000' . $count; }
    elsif ($count < 1000) { $count_val = '0000' . $count; }
    elsif ($count < 10000) { $count_val = '000' . $count; }
    elsif ($count < 100000) { $count_val = '00' . $count; }
    elsif ($count < 1000000) { $count_val = '0' . $count; }
    else { print "ERR Interaction number exists max allowed\n"; }
    my ($geneA, $geneB) = split/DIVIDER/, $key;
    print "Interaction\tWBInteraction$count_val\n";
    print "Interactor\t$geneA\tGenetic\n";
    print "Interactor\t$geneB\n";
    if ($convertToWBPaper{$paper}) { 
      print "Paper $convertToWBPaper{$paper}\n"; }
    else { print "ERR No Paper Convertion for $paper\n"; }
    print "\n";
  } # foreach my $paper (sort keys %{ $theHash{gen}{$paper}{good} } )
} # foreach my $paper (sort keys %{ $theHash{gen} } )
foreach my $paper (sort keys %{ $theHash{reg} } ) {
  foreach my $key (sort keys %{ $theHash{reg}{$paper}{good} } ) {
    $count++; my $count_val;
    if ($count < 10) { $count_val = '000000' . $count; }
    elsif ($count < 100) { $count_val = '00000' . $count; }
    elsif ($count < 1000) { $count_val = '0000' . $count; }
    elsif ($count < 10000) { $count_val = '000' . $count; }
    elsif ($count < 100000) { $count_val = '00' . $count; }
    elsif ($count < 1000000) { $count_val = '0' . $count; }
    else { print "ERR Interaction number exists max allowed\n"; }
    my ($geneA, $geneB) = split/DIVIDER/, $key;
    print "Interaction\tWBInteraction$count_val\n";
    print "Interactor\t$geneA\tRegulation\n";
    print "Interactor\t$geneB\n";
    if ($convertToWBPaper{$paper}) { 
      print "Paper $convertToWBPaper{$paper}\n"; }
    else { print "ERR No Paper Convertion for $paper\n"; }
    print "\n";
  } # foreach my $paper (sort keys %{ $theHash{reg}{$paper}{good} } )
} # foreach my $paper (sort keys %{ $theHash{reg} } )
  
sub populateWBPaperHash {
      my $u = "http://minerva.caltech.edu/~acedb/paper2wbpaper.txt";
      my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
      my $request = HTTP::Request->new(GET => $u); #grabs url
      my $response = $ua->request($request);       #checks url, dies if not valid.
      die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
      my @tmp = split /\n/, $response->content;    #splits by line
      foreach (@tmp) {
        if ($_ =~m/^(.*?)\t(.*?)$/) {
          $convertToWBPaper{$1} = $2; } }
} # sub populateWBPaperHash




# GeneA,GeneB,Interaction_type,Paper
# dpy-22,lin-14,Genetic,cgc1011 
# dpy-22,lin-14,Genetic,cgc1011 
# dpy-22,lin-14,Genetic,cgc1011 
# dpy-21,lin-14,Genetic,cgc1011 
# sdc-1,sdc-2,Genetic,cgc1171 
# dpy-21,lin-14,Regulation,cgc1011 
# dpy-21,lin-14,Regulation,cgc1011 
# dpy-21,lin-14,Regulation,cgc1011 
# dpy-21,lin-14,Regulation,cgc1011 
# dpy-21,lin-14,Regulation,cgc1011 
# dpy-21,fin-14,Regulation,cgc1011 
# dpy-26,lin-14,Regulation,cgc1011 
# dpy-27,lin-14,Regulation,cgc1011 
# dpy-28,lin-14,Regulation,cgc1011 
# dpy-21,lin-14,Regulation,cgc1011 
# dpy-21,lin-14,Regulation,cgc1011 
# pal-1,mab-5,Regulation,cgc1409 
my $search = 'unctional annot';
