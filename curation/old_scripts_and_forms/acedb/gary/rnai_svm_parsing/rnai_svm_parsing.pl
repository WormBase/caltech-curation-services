#!/usr/bin/perl -w

# get svm results for rnai, put in cfp_rnai and gary's textfile of low results.  2011 12 01
#
# changed caprica to 131.215.52.209  2012 01 26

use strict;
use diagnostics;
use DBI;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my $url = 'http://caprica.caltech.edu/celegans/svm_results/';
my $url = 'http://131.215.52.209/celegans/svm_results/';
my $top = get $url;
my (@links) = $top =~ m/<a href="(\d{8})\/">/g;
my @urls;
foreach my $subdir (@links) {
  my $link = $url . $subdir;
  push @urls, $link;
}

my %old; my %yes;		# skip values under old, append to yes
my $text_file = '/home/postgres/work/pgpopulation/svm/gary_rnai/low';
open (IN, "<$text_file") or die "Cannot open $text_file : $!"; 
while (my $line = <IN>) { my ($paperID) = $line =~ m/WBPaper(\d+)/; $old{$1}++; }
close (IN) or die "Cannot close $text_file : $!"; 

$result = $dbh->prepare( "SELECT * FROM cfp_rnai" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[1] =~ m/^yes$/i) { $yes{$row[0]} = $row[1]; }
    else { $old{$row[0]}++; } }

my %data;
foreach my $url (@urls) {
  my $date_link = get $url;
  my ($rnai_subdir) = $date_link =~ m/<a href="(\w+_rnai)">/;
  next unless ($rnai_subdir);
  my $data_url = $url . '/' . $rnai_subdir;
  my $data = get $data_url;
  my (@data) = split/\n/, $data;
  foreach my $data (@data) {
    my ($paper, $score, @junk) = split/\t/, $data;
    $score =~ s/\"//g;
    my ($paperID) = $paper =~ m/WBPaper(\d+)/;
    next unless ($paperID);		# some files have headers
    $data{$paperID}{$score}++;
  }
#   print "$data\n";
#   last;		# to only do one directory
} # foreach my $url (@urls)

foreach my $paper (sort keys %data) {
  next if ($old{$paper});
#   if ($old{$paper}) { print "OLD $paper\n"; next; }
  my $real_score = '';
  if ($data{$paper}{high}) { $real_score = 'high'; }
  elsif ($data{$paper}{medium}) { $real_score = 'medium'; }
  elsif ($data{$paper}{low}) { $real_score = 'low'; }
#   unless ($real_score) { foreach my $not_score (sort keys %{ $data{$paper} }) { print "NOT SCORE $paper $not_score\n"; } }
  if ($real_score eq 'low') { &appendToTextFile("WBPaper$paper"); }
    else {
      if ($yes{$paper}) { $real_score = $yes{$paper} . " -- " . $real_score; }
      &appendToPostgres($paper, $real_score); }
} # foreach my $paper (sort keys %data)

sub appendToPostgres {
  my ($paper, $score) = @_;
  my @pgcommands; 
  push @pgcommands, "DELETE FROM cfp_rnai WHERE joinkey = '$paper'";
  push @pgcommands, "INSERT INTO cfp_rnai_hst VALUES ('$paper', '$score', 'two557')";
  push @pgcommands, "INSERT INTO cfp_rnai VALUES ('$paper', '$score', 'two557')";
#   print "$paper\t$score\n";
  foreach my $pgcommand (@pgcommands) {
#     print "$pgcommand\n";
    $result = $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # sub appendToPostgres

sub appendToTextFile {
  my $paper = shift;
  open (OUT, ">>$text_file") or die "Cannot append to $text_file : $!"; 
  print OUT "$paper\n";
  close (OUT) or die "Cannot close $text_file : $!"; 
} # sub appendToTextFile

