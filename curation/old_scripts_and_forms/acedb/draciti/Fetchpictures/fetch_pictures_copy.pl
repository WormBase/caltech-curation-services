#!/usr/bin/perl 

use strict;
use diagnostics;
use LWP::Simple;
# use Encode qw( from_to is_utf8 );

# my $root_infile = 'Development';
# my $root_infile = 'JBC/JBC';
my $root_infile = 'Mol_Biol_Cell/Molbiolcell';
# my $root_infile = 'Springer/Springer';

$/ = undef;
my $infile = $root_infile . '.xml';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my (@entries) = split/<PubmedArticle>/, $allfile;

my %pmid_to_wbpaper;
$/ = "";
$infile = $root_infile . '.ace';
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
# my $maxToProcess = 2;

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
  my $url = '';
  my $paper_dir = $pmid;  
  if ($pmid_to_wbpaper{$pmid}) { $paper_dir = $pmid_to_wbpaper{$pmid}; }
#   return unless ($paper_dir eq 'WBPaper00025218');	# sample that wasn't working 2011 05 26
#   return unless ($paper_dir eq 'WBPaper00002785');
  print "$paper_dir\t$pmid\t$url_constructor\n";

  unless (-d $paper_dir) { `mkdir $paper_dir`; }

  &getUrlAndFigures($url_constructor, $paper_dir, $pmid);
  
  my $outfile = $paper_dir . '/' . 'url_accession.txt';
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT "$url_constructor\n";
  close (OUT) or die "Cannot close $outfile : $!";
  sleep(2);
#   print $all_figs_page;
#   print "DIVIDER\n\n\n";
} # sub processPmid

sub getUrlAndFigures {
  my ($url_constructor, $paper_dir, $pmid) = @_;
  my $url = '';
  if ($root_infile eq 'Development') {
    $url = 'http://dev.biologists.org/content/' . $url_constructor . '.figures-only'; }
  elsif ($root_infile eq 'JBC/JBC') {
    $url = 'http://www.jbc.org/content/' . $url_constructor . '.long'; }
  elsif ($root_infile eq 'Mol_Biol_Cell/Molbiolcell') {
    $url = 'http://www.molbiolcell.org/cgi/content/full/' . $url_constructor; }
  my $all_figs_page = get $url;
# print "URL $url U\n";
#   if ( $all_figs_page =~ m/<div class="fig\-caption">(.*?)<\/div>/sg ) { print "MATCH\n"; }
# print "ALL $all_figs_page FIGS\n";

  if ( ($root_infile eq 'Development') || ($root_infile eq 'JBC/JBC') ) {
    my (@figcaptions) = $all_figs_page =~ m/<div class=\"fig\-caption\">(.*?)<\/div>/sg;
    foreach my $figcap (@figcaptions) {
#       print "FIGCAP $figcap\n\n\n";
      my ($number, $text);
      if ($root_infile eq 'Development') {
        if ($figcap =~ m/<span class="fig\-label">.*?Fig\. (\d+)\..*?<\/span>/s) { $number = $1; } }
      elsif ($root_infile eq 'JBC/JBC') {
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+)\..*?<\/span>/s) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+).*?<\/span>/is) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+)\..*?<\/span>/s) { $number = $1; }
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+).*?<\/span>/s) { $number = $1; } }
      
      if ($figcap =~ m/<p[^>]*?>(.*?)<\/p>/s) { $text = $1; }
      if ($text =~ m/<[^>]*>/) { $text =~ s/<[^>]*>//g; }
#       if ($text) { unless (is_utf8($text)) { from_to($text, "iso-8859-1", "utf8"); } }           # may have non utf8 stuff
#       print "$number\t$text\n";
      my $outfile = $paper_dir . '/' . 'F' . $number . '.large.txt';
      open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
      print OUT "Figure $number. ";
      $text =~ s/\n/ /g;
      $text =~ s/ +/ /g;
      print OUT $text;
      close (OUT) or die "Cannot close $outfile : $!";
      my $image_url = '';
      if ($root_infile eq 'Development') {
        $image_url = 'http://dev.biologists.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      elsif ($root_infile eq 'JBC/JBC') {
        $image_url = 'http://www.jbc.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      print "$image_url\n";
      my $image = get $image_url;
      $outfile = $paper_dir . '/' . 'F' . $number . '.large.jpg';
      open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
      print OUT $image;
      close (OUT) or die "Cannot close $outfile : $!";
    }
  }
  elsif ($root_infile eq 'Mol_Biol_Cell/Molbiolcell') {
    my (@figcaptions) = $all_figs_page =~ m/<STRONG>View larger version<\/STRONG> \(\d+[A-Z]+\):<BR>\n<NOBR><A HREF=\"(.*?)\">/sg;
    foreach my $figcap (@figcaptions) {
      my $fig_link_url = 'http://www.molbiolcell.org' . $figcap;
      my $fig_link_page = get $fig_link_url;
      my $number = 0;
      if ($fig_link_page =~ m/<STRONG>Figure (\d+).<\/STRONG>/i) { $number = $1; }
      if ($fig_link_page =~ m/<BR CLEAR=left>(.*?)<P>/si) {
        my $text = $1;
        my $outfile = $paper_dir . '/' . 'F' . $number . '.large.txt';
        open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
        print OUT "Figure $number. ";
        $text =~ s/\n/ /g;
        $text =~ s/ +/ /g;
        print OUT $text;
        close (OUT) or die "Cannot close $outfile : $!"; }
      if ($fig_link_page =~ m/Click on image to view larger version\.<P>\n<BR><A HREF=\"(.*?)\"><IMG/si) {
        my $image_url = 'http://molbiolcell.org' . $1;
        print "$image_url\n";
        my $image = get $image_url;
        my $outfile = $paper_dir . '/' . 'F' . $number . '.large.jpg';
        open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
        print OUT $image;
        close (OUT) or die "Cannot close $outfile : $!";
      }
    } # foreach my $figcap (@figcaptions)
  } # elsif ($root_infile eq 'Mol_Biol_Cell/Molbiolcell')
} # sub getFromFiguresOnly
