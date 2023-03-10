#!/usr/bin/perl

use strict;
use diagnostics;
use LWP::UserAgent;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my %validPaps;
&getValidPaps();

my %convertToWBPaper;
my %backwards;
&readConversions;


sub getValidPaps {
  $result = $dbh->prepare( "SELECT joinkey FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $validPaps{$row[0]}++; 
  }
}

my %md5;


my $infile = 'md5_all';
open (IN, "<$infile");
while (my $line = <IN>) {
  chomp $line;
  my ($md5, $path) = split/\t/, $line;
  my $papid = &resolvePathToJoinkey($path);
  if ($papid) { 
    unless ($validPaps{$papid}) {
      print qq(invalid\t$papid\t$line\n);
    }
  } else {
    print qq(no WBPaper\t$line\n);
  }
}
close (IN);


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
#   if ($file_name !~ m/\.pdf$/i) { return; }               # skip non-pdfs
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
#   if ($file_name !~ m/\.pdf$/i) { return; }               # skip non-pdfs
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
