#!/usr/bin/perl 

use strict;
use diagnostics;
use LWP::Simple;
# use Encode qw( from_to is_utf8 );


$/ = undef;
my $infile = 'Development.xml';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my (@entries) = split/<PubmedArticle>/, $allfile;

my %pmid_to_wbpaper;
$/ = "";
$infile = 'Development.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($wbp, $pmid);
  if ($para =~ m/\"(WBPaper\d{8})\"/) { $wbp = $1; }
  if ($para =~ m/\"PMID\"\s\"(\d+)\"/) { $pmid = $1; }
  $pmid_to_wbpaper{$pmid} = $wbp;
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";


my $maxToProcess = 1000;

my $count = 0;
foreach my $entry (@entries) {
  my ($pmid, $vol, $issue, $medpg);
  if ($entry =~ m/<PMID[^>]*?>(.*?)<\/PMID>/) { $pmid = $1; }
  if ($entry =~ m/<Volume>(.*?)<\/Volume>/) { $vol = $1; }
  if ($entry =~ m/<Issue>(.*?)<\/Issue>/) { $issue = $1; }
  if ($entry =~ m/<MedlinePgn>(.*?)<\/MedlinePgn>/) { $medpg = $1; }
  if ($medpg) { if ($medpg =~ m/\-.*/) { $medpg =~ s/\-.*$//; } }
  if ($vol && $issue && $medpg && $pmid) { 
    $count++;
    last if ($count > $maxToProcess);
    my $url_constructor = $vol . '/' . $issue . '/' . $medpg;
    &processPmid($pmid, $url_constructor);
  }
#     else { print "ERR V $vol I $issue M $medpg FOR ENTRY $entry\n"; }
}

sub processPmid {
  my ($pmid, $url_constructor) = @_;
  my $url = 'http://dev.biologists.org/content/' . $url_constructor . '.figures-only';
  my $all_figs_page = get $url;
  my $paper_dir = $pmid;  
  if ($pmid_to_wbpaper{$pmid}) { $paper_dir = $pmid_to_wbpaper{$pmid}; }
  print "$paper_dir\t$pmid\t$url_constructor\n";
  unless (-d $paper_dir) { `mkdir $paper_dir`; }
#   if ( $all_figs_page =~ m/<div class="fig\-caption">(.*?)<\/div>/sg ) { print "MATCH\n"; }
  my (@figcaptions) = $all_figs_page =~ m/<div class=\"fig\-caption\">(.*?)<\/div>/sg;
  foreach my $figcap (@figcaptions) {
    print "FIGCAP $figcap\n\n\n";
    my ($number, $text);
    if ($figcap =~ m/<span class="fig\-label">.*?Fig\. (\d+)\..*?<\/span>/s) { $number = $1; }
    if ($figcap =~ m/<p[^>]*?>(.*?)<\/p>/s) { $text = $1; }
    if ($text =~ m/<[^>]*>/) { $text =~ s/<[^>]*>//g; }
#     if ($text) { unless (is_utf8($text)) { from_to($text, "iso-8859-1", "utf8"); } }           # may have non utf8 stuff
#     print "$number\t$text\n";
    my $outfile = $paper_dir . '/' . 'F' . $number . '.large.txt';
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
    print OUT $text;
    close (OUT) or die "Cannot close $outfile : $!";
    my $image_url = 'http://dev.biologists.org/content/' . $url_constructor . '/F' . $number . '.large.jpg';
    my $image = get $image_url;
    $outfile = $paper_dir . '/' . 'F' . $number . '.large.jpg';
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
    print OUT $image;
    close (OUT) or die "Cannot close $outfile : $!";
  }
  my $outfile = $paper_dir . '/' . 'url_accession.txt';
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT "$url_constructor\n";
  close (OUT) or die "Cannot close $outfile : $!";
  sleep(2);
#   print $all_figs_page;
#   print "DIVIDER\n\n\n";
} # sub processPmid
