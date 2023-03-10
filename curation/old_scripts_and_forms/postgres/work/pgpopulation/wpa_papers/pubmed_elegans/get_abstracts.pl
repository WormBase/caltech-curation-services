#!/usr/bin/perl

# get abstracts based on pmids from file ``pmids'' from pubmed, with a 5 second delay between requests.  2009 01 28

use strict;
use diagnostics;
use LWP::UserAgent;


my $infile = 'pmids';
my $logfile = 'abstracts';
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (LOG, ">$logfile") or die "Cannot create $logfile : $!";
while (my $line = <IN>) {
  if ($line =~ m/false positive : (\d+)/) {
    my $pmid = $1;
    &slp();
    my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$pmid\&retmode\=xml";
    my $page = getPubmedPage($url);
    &processPubmedPage($page, $pmid);
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (LOG) or die "Cannot close $logfile : $!";


sub slp {
#     my $rand = int(rand 15) + 5;      # random 5-20 seconds
    my $rand = 5;                       # just 5 seconds
#     print LOG "Sleeping for $rand seconds...\n";
    sleep $rand;
#     print LOG "done.\n";
} # sub slp

sub processPubmedPage {
  my $page = shift; my $pmid = shift; 
  $page =~ s/\n//g;
  return if $page =~ /\<Error\>.+?\<\/Error\>/i;

  print LOG "PMID : $pmid\n";
  my ($abstract) = $page =~ /\<AbstractText\>(.+?)\<\/AbstractText\>/i;
  print LOG "ABSTRACT : $abstract\n";
  print LOG "\n";
}

sub getPubmedPage {
    my $u = shift;
    my $page = "";
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
#    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    $page = $response->content;    #splits by line
    $page = &filterForeign($page);
    return $page;
} # sub getPubmedPage


sub filterForeign {		# take out foreign characters before they can get into postgres  for Cecilia  2006 05 04
  my $change = shift;
  if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
    if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
    if ($change =~ m/„/) { $change =~ s/„/"/g; }
    if ($change =~ m/…/) { $change =~ s/…/.../g; }
    if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
    if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
    if ($change =~ m/‹/) { $change =~ s/‹/</g; }
    if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
    if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
    if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
    if ($change =~ m/’/) { $change =~ s/’/'/g; }
    if ($change =~ m/“/) { $change =~ s/“/"/g; }
    if ($change =~ m/”/) { $change =~ s/”/"/g; }
    if ($change =~ m/—/) { $change =~ s/—/-/g; }
    if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
    if ($change =~ m/š/) { $change =~ s/š/s/g; }
    if ($change =~ m/›/) { $change =~ s/›/>/g; }
    if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
    if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
    if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
    if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
    if ($change =~ m/«/) { $change =~ s/«/"/g; }
    if ($change =~ m/­/) { $change =~ s/­/-/g; }
    if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
    if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
    if ($change =~ m/·/) { $change =~ s/·/-/g; }
    if ($change =~ m/»/) { $change =~ s/»/"/g; }
    if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
    if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
    if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
    if ($change =~ m/À/) { $change =~ s/À/A/g; }
    if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
    if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
    if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
    if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
    if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
    if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
    if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
    if ($change =~ m/È/) { $change =~ s/È/E/g; }
    if ($change =~ m/É/) { $change =~ s/É/E/g; }
    if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
    if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
    if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
    if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
    if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
    if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
    if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
    if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
    if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
    if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
    if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
    if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
    if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
    if ($change =~ m/×/) { $change =~ s/×/x/g; }
    if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
    if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
    if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
    if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
    if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
    if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
    if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
    if ($change =~ m/à/) { $change =~ s/à/a/g; }
    if ($change =~ m/á/) { $change =~ s/á/a/g; }
    if ($change =~ m/â/) { $change =~ s/â/a/g; }
    if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
    if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
    if ($change =~ m/å/) { $change =~ s/å/a/g; }
    if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
    if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
    if ($change =~ m/è/) { $change =~ s/è/e/g; }
    if ($change =~ m/é/) { $change =~ s/é/e/g; }
    if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
    if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
    if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
    if ($change =~ m/í/) { $change =~ s/í/i/g; }
    if ($change =~ m/î/) { $change =~ s/î/i/g; }
    if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
    if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
    if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
    if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
    if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
    if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
    if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
    if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
    if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
    if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
    if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
    if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
    if ($change =~ m/û/) { $change =~ s/û/u/g; }
    if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
    if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
  }
  if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; }
  return $change;
} # sub filterForeign
