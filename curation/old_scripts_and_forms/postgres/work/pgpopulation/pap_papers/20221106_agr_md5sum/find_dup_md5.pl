#!/usr/bin/perl

use strict;
use diagnostics;
use LWP::UserAgent;

my %convertToWBPaper;
my %backwards;
&readConversions;

my %md5;


my $infile = 'md5_all';
open (IN, "<$infile");
while (my $line = <IN>) {
  chomp $line;
  my ($md5, $path) = split/\t/, $line;
  push @{ $md5{$md5} }, $path;
}
close (IN);

my $log_diff = 'log_md5_dup_diff_papid';
my $log_same = 'log_md5_dup_same_papid';
open (DIF, ">$log_diff") or die "Cannot create $log_diff : $!";
open (SAM, ">$log_same") or die "Cannot create $log_same : $!";

my $count_diff = 0;
my $count_same = 0;
foreach my $md5 (sort keys %md5) {
  if (scalar @{ $md5{$md5} } > 1) { 
    my %pap;
#     my $paths = join"\t", @{ $md5{$md5} };
#     print qq($md5\t$paths\n);
    foreach my $path (@{ $md5{$md5} }) {
      my $papid = &resolvePathToJoinkey($path);
      if ($papid) {
        $pap{$papid}{$path}++; }
    }
    if (scalar keys %pap > 1) { 
      foreach my $papid (sort keys %pap) {
        $count_diff++;
        my $paths = join"\t", sort keys %{ $pap{$papid} };
        print DIF qq($md5\t$papid\t$paths\n);
      }
      print DIF qq(\n); }
    else {
      foreach my $papid (sort keys %pap) {
        $count_same++;
        my $paths = join"\t", sort keys %{ $pap{$papid} };
        print SAM qq($md5\t$papid\t$paths\n);
    } }
  }
} # foreach my $md5 (sort keys %md5)

print DIF qq($count_diff\n);
print SAM qq($count_same\n);
close (DIF) or die "Cannot close $log_diff : $!";
close (SAM) or die "Cannot close $log_same : $!";

sub resolvePathToJoinkey {
  my $path = shift;
  my $papid = 0;
  my $wb_class = 'main';
  if ($path =~ m/supplement/) { $wb_class = 'supplement'; }
  if ($path =~ m/^wb\/[a-z]+\/(\d{8})[^\d]/) { $papid = $1; }
    elsif ($path =~ m/^pubmed/) { $papid = &getPapJoinkeyFromPmid($path); }
    elsif ($path =~ m/^cgc/) { $papid = &getPapJoinkeyFromCgc($path); }
  return $papid;
#   if ($papid > 0) {
#     my $wbp = 'WB:WBPaper' . $papid;
#   }
}


sub getPapJoinkeyFromPmid {
  my $file = shift;
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
#   if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  my ($pmid) = $file_name =~ m/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  my $wbid = 0;
  if ($convertToWBPaper{$pmid}) {
    $wbid = $convertToWBPaper{$pmid};
    $wbid =~ s/WBPaper//g;
    return $wbid;
} }

sub getPapJoinkeyFromCgc {
  my $file = shift;
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
#   if ($file_name !~ m/\.pdf$/i) { next; }               # skip non-pdfs
  my ($cgc) = $file_name =~ m/^_*(\d+).*/;      # some files start with _ for some reason
  $cgc = 'cgc' . $cgc;
  my $wbid = 0;
  if ($convertToWBPaper{$cgc}) {
    $wbid = $convertToWBPaper{$cgc};
    $wbid =~ s/WBPaper//g;
    return $wbid;
  }
}

sub readConversions {
#   my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";
  my $u = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=WpaXrefBackwards";
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
} # sub readConversions
