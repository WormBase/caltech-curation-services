#!/usr/bin/perl -w

# Quick PG query to get some data for Andrei  2005 05 19

use strict;
use diagnostics;
use Pg;
use LWP;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %convertToWBPaper;
&readConvertions();

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @tables = qw(cur_rnai cur_cellname cur_cellfunction cur_ablationdata);

foreach my $table (@tables) {
  print OUT "$table\n";
  my $result = $conn->exec( "SELECT joinkey FROM $table WHERE $table IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      if ($convertToWBPaper{$row[0]}) {
        print OUT "$convertToWBPaper{$row[0]}\n"; }
      else { print OUT "$row[0]\n"; }
  } }
  print OUT "\n\n";
}
  
sub readConvertions {
  my $u = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ",
$response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) { 
      $convertToWBPaper{$1} = $2; } }
} # sub readConvertions
