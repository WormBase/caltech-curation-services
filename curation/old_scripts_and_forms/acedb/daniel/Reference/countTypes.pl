#!/usr/bin/perl

# Count types of convertible and non-convertible files for Daniel.
# Look at /home/acedb/daniel/Reference/  cgc/ and pubmid/
# convertible in pdf/  non-con in libpdf/ and tifpdf/
# if there's a convertible copy, don't count it if also non-con.
# convert cgcs and pmids to wbpaper, but output as cgc if exists.
# filter to wbpaper so as not to count multiple times.
# 2005 06 21
#
# Added wb/libpdf/ and wb/pdf/  2005 10 27


# total number of unique (papers) PDFs.  So count each cgc number once, and don't
# count PMID if converts to the same one.  cgc/  pubmed/  
# 
# look at pdf directory and look for _ocr.pdf  count those.  only count once,
# don't count PMID if converts to same cgc.
# 
# 
# libpdf/ + tifpdf/  count nubmers, ignore duplicates the same way.  don't count
# those in cgc/ pubmed/
# 
# summary of :
# total # of papers
# How many from   tifpdf or libpdf
# How many are PDF  cgc/ pubmid/
# How many are _ocr.pdf

# Look at :
# /home/acedb/daniel/Reference/cgc/
# /home/acedb/daniel/Reference/pubmed/
# /home/acedb/daniel/Reference/wb/		# added 2005 10 27
# convertibles are in : pdf/
# non-convertible are in : libpdf/ and tifpdf/
# don't look at : html/

use strict;
use LWP::UserAgent;


my %convertToWBPaper;
my %backwards;
my %bracket;
&readConvertions;

my %convertible;
my %nonconvertible;
my %ocr;

my %no_wbpaper;

sub readConvertions {
#   my $u = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt";
  my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      my $other = $1; my $wbid = $2;
      unless ($backwards{$wbid}) { $backwards{$wbid} = $other; }
      $convertToWBPaper{$other} = $wbid; } }
} # sub readConvertions

# /home/acedb/daniel/Reference/cgc/
# /home/acedb/daniel/Reference/pubmed/

# foreach (@Reference, @Reference2, @Reference3)

my @Reference; my @Reference2;
my @directory; my @file;

@Reference = </home/acedb/daniel/Reference/cgc/pdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
}
foreach (@file) {
  my $ocr_flag = 0;
  my ($file) = $_ =~ m/.*\/(.*)/;
  if ($file =~ m/_ocr\.pdf/) { $ocr_flag++; }
  my ($cgc) = $_ =~ m/.*\/(\d+).*/;
#   print "FILE : $cgc";
#   $cgc = 'cgc' . $cgc;
#   if ($convertToWBPaper{$cgc}) { print "\t$convertToWBPaper{$cgc}"; }
#   print "\n";
  $cgc = 'cgc' . $cgc;
  if ($convertToWBPaper{$cgc}) {
    my $wbid = $convertToWBPaper{$cgc};
    if ($ocr_flag) { $ocr{$wbid}++; }
    $convertible{$wbid}++; }
  else { 
#     print "NO $cgc $file\n"; 
    my $line = "NO $cgc $file";
    $no_wbpaper{$line}++; }
}

@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/wb/pdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }
foreach (@file) {
  my $ocr_flag = 0;
  my ($file) = $_ =~ m/.*\/(.*)/;
  if ($file =~ m/_ocr\.pdf/) { $ocr_flag++; }
  my ($wbid) = $_ =~ m/.*\/(\d+).*/;
  $wbid = 'WBPaper' . $wbid;
  if ($ocr_flag) { $ocr{$wbid}++; }
  $convertible{$wbid}++; 
}

@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/pubmed/libpdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }
foreach (@file) {
  my $ocr_flag = 0;
  my ($file) = $_ =~ m/.*\/(.*)/;
  if ($file =~ m/_ocr\.pdf/) { $ocr_flag++; }
  my ($wbid) = $_ =~ m/.*\/(\d+).*/;
  $wbid = 'WBPaper' . $wbid;
  if ($ocr_flag) { $ocr{$wbid}++; }
  if ($convertible{$wbid}) { next; }
    else { $nonconvertible{$wbid}++; } 
}

@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/pubmed/pdf/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }
foreach (@file) {
  my $ocr_flag = 0;
  my ($file) = $_ =~ m/.*\/(.*)/;
  if ($file =~ m/_ocr\.pdf/) { $ocr_flag++; }
  my ($pmid) = $_ =~ m/.*\/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  if ($convertToWBPaper{$pmid}) {
    my $wbid = $convertToWBPaper{$pmid};
    if ($ocr_flag) { $ocr{$wbid}++; }
    $convertible{$wbid}++; }
  else { 
#     print "NO $pmid $file\n"; 
    my $line = "NO $pmid $file";
    $no_wbpaper{$line}++; }
}

@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/pubmed/tifpdf/*>;
@Reference2 = </home/acedb/daniel/Reference/pubmed/libpdf/*>;
foreach (@Reference, @Reference2) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }
foreach (@file) {
  my $ocr_flag = 0;
  my ($file) = $_ =~ m/.*\/(.*)/;
  if ($file =~ m/_ocr\.pdf/) { $ocr_flag++; }
  my ($pmid) = $_ =~ m/.*\/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  if ($convertToWBPaper{$pmid}) {
    my $wbid = $convertToWBPaper{$pmid};
    if ($ocr_flag) { $ocr{$wbid}++; }
    if ($convertible{$wbid}) { next; }
    else { $nonconvertible{$wbid}++; } }
  else {
#     print "NO $pmid $file\n"; 
    my $line = "NO $pmid $file";
    $no_wbpaper{$line}++; }
}

@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/cgc/tifpdf*>;
@Reference2 = </home/acedb/daniel/Reference/cgc/libpdf/*>;
foreach (@Reference, @Reference2) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
}
foreach (@file) {
  my $ocr_flag = 0;
  my ($file) = $_ =~ m/.*\/(.*)/;
  if ($file =~ m/_ocr\.pdf/) { $ocr_flag++; }
  my ($cgc) = $_ =~ m/.*\/(\d+).*/;
  $cgc = 'cgc' . $cgc;
  if ($convertToWBPaper{$cgc}) {
    my $wbid = $convertToWBPaper{$cgc};
    if ($ocr_flag) { $ocr{$wbid}++; }
    if ($convertible{$wbid}) { next; }
    else { $nonconvertible{$wbid}++; } }
  else {
#     print "NO $cgc $file\n"; 
    my $line = "NO $cgc $file";
    $no_wbpaper{$line}++; }
}

foreach my $wbpaper (sort keys %convertible) {
#   print "CON\t$wbpaper\t$backwards{$wbpaper}\n";
  my $other = $backwards{$wbpaper};
  if ($other =~ m/cgc/) { 
    my ($value) = $other =~ m/cgc(\d+)/;
    if ($value < 1000) { $bracket{1000}{con}++; }
    elsif ($value < 2000) { $bracket{2000}{con}++; }
    elsif ($value < 3000) { $bracket{3000}{con}++; }
    elsif ($value < 4000) { $bracket{4000}{con}++; }
    elsif ($value < 5000) { $bracket{5000}{con}++; }
    elsif ($value < 6000) { $bracket{6000}{con}++; }
    elsif ($value < 7000) { $bracket{7000}{con}++; }
    elsif ($value < 8000) { $bracket{8000}{con}++; }
    else { $bracket{9000}{con}++; }
  } else { $bracket{other}{con}++; }
}

foreach my $wbpaper (sort keys %nonconvertible) {
#   print "NON\t$wbpaper\t$backwards{$wbpaper}\n";
  my $other = $backwards{$wbpaper};
  if ($other =~ m/cgc/) { 
    my ($value) = $other =~ m/cgc(\d+)/;
    if ($value < 1000) { $bracket{1000}{non}++; }
    elsif ($value < 2000) { $bracket{2000}{non}++; }
    elsif ($value < 3000) { $bracket{3000}{non}++; }
    elsif ($value < 4000) { $bracket{4000}{non}++; }
    elsif ($value < 5000) { $bracket{5000}{non}++; }
    elsif ($value < 6000) { $bracket{6000}{non}++; }
    elsif ($value < 7000) { $bracket{7000}{non}++; }
    elsif ($value < 8000) { $bracket{8000}{non}++; }
    else { $bracket{9000}{non}++; }
  } else { $bracket{other}{non}++; }
}

print "These don't have a matching WBPaper :\n";
foreach my $line (sort keys %no_wbpaper) { print "$line\n"; }
print "\n\n";

print "====================================================\n";
print "Range    	Convertible	Non-Convertible (%)\n";
print "====================================================\n";

my $tnon; my $tcon; my $ttot;
foreach my $bracket (sort keys %bracket) {
  my $range = '1-999';
  if ($bracket eq '1000') { $range = '0001-0999'; }
  elsif ($bracket eq '2000') { $range = '1000-1999'; }
  elsif ($bracket eq '3000') { $range = '2000-2999'; }
  elsif ($bracket eq '4000') { $range = '3000-3999'; }
  elsif ($bracket eq '5000') { $range = '4000-4999'; }
  elsif ($bracket eq '6000') { $range = '5000-5999'; }
  elsif ($bracket eq '7000') { $range = '6000-6999'; }
  elsif ($bracket eq '8000') { $range = '7000-7999'; }
  elsif ($bracket eq '9000') { $range = '8000+    '; }
  elsif ($bracket eq 'other') { $range = 'non-cgc  '; }
  else { $range = 'ERROR'; }   
# print "BRACKET $bracket\n";
  my $non = $bracket{$bracket}{non};
  $tnon += $non;
  my $con = $bracket{$bracket}{con};
  $tcon += $con;
  my $tot = $non + $con;
  $ttot += $tot;
  my $perc = $non / $tot * 100;
  ($perc) = $perc =~ m/^(.{5})/;
  print "$range\t$con          \t$non (${perc}%)\n";
} # foreach my $bracket (sort keys %bracket)

my $perc = $tnon / $ttot * 100;
print "====================================================\n";
print "Total          \t$tcon         \t$tnon (${perc}%)\n";
print "====================================================\n\n";

print "There are " . scalar(keys %ocr) . " non-duplicate OCR papers\n";


