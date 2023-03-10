#!/usr/bin/perl -w

# convert old-paper-style Cecilia file into new-paper-style (WBPaper)
# 2004 09 02

use strict;
use diagnostics;
use Pg;
use Jex;
use LWP;

my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper
&readConvertions();

print "Need input file\n" unless ($ARGV[0]) ;

my $inputfile = $ARGV[0];
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
while (<IN>) {
  if ($_ =~ m/Paper\t\"?\[(.*?)\]\"?/) {
    if ($convertToWBPaper{$1}) { print "Paper\t$convertToWBPaper{$1}\n"; }
    else { print STDERR "NO Convertion for $1\n"; }
  } else { print; }
}

sub readConvertions {
  my $u = "http://minerva.caltech.edu/~acedb/paper2wbpaper.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      $convertToWBPaper{$1} = $2; } }
} # sub readConvertions

