#!/usr/bin/perl

# script to match existing acedb med papers with cgc papers based on various
# title volume page first author   for eimear.  2003 10 13
#
# adapted to only use cgc's for daniel.  2004 02 18
#
# added pages and first letter of title for daniel
# added pages and first letter of title and first letter of author for daniel
# re-ran it for cgc and pmid (printing bad for those in ref_xref)
# 2004 03 02


use strict;
use diagnostics;

# just in case need to look at cgc-pmid that already done in postgres
# use Pg;
# 
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;
# 
# my %xref;
# 
# my $result = $conn->exec( "SELECT * FROM ref_xref;" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $xref{$row[1]} = $row[0];
# } }




my %hash;
my %all_med;		# hash of medline papers, key med number

# my $infile = 'cgc_med_papers.ace';
my $infile = 'citacePersonPaper20040218.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  next unless ($entry =~ m/^Paper : \"\[cgc/);
#   next unless ( ($entry =~ m/^Paper : \"\[cgc/) || ($entry =~ m/^Paper : \"\[pmid/) );

# ONE : find completely same entry  :  Gives Person or Sequence only entries
#   $entry =~ s/^Paper : \"\[(.*?)\]\"\n//g;
#   push @{ $hash{$entry} }, $1;

# TWO : titles match
  next unless ($entry =~ m/Title/);
  my ($title) = $entry =~ m/Title\t \"(.*?)\"/;
  my ($paper) = $entry =~ m/Paper : \"\[(.*?)\]\"/;
#   push @{ $hash{$title} }, $paper;
  if ($paper =~ m/med/) { $all_med{$paper}++; }

# THREE : volume and title match
  next unless ($entry =~ m/Volume/);
  my ($volume) = $entry =~ m/Volume\t \"(.*?)\"/;
  my $key = $volume . $title;
#   push @{ $hash{$key} }, $paper;

# FOUR : page and volume and title match
  next unless ($entry =~ m/Page/);
#   my ($page) = $entry =~ m/Page(?:\s+)\"(.*?)\"/;

  my $page;
  if ($entry =~ m/Page(?:\s+)\"(.*?)\"\s\"(.*?)\"/) {
    my ($page1, $page2) = $entry =~ m/Page(?:\s+)\"(.*?)\"\s\"(.*?)\"/;
    $page = "$page1 $page2"; }
  else {
    ($page) = $entry =~ m/Page(?:\s+)\"(.*?)\"/; }
  $key = "$volume $page $title";
#   push @{ $hash{$key} }, $paper;

# FIVE : first author and page and volume and title match
  next unless ($entry =~ m/Author/);
  my ($author) = $entry =~ m/Author(?:\s+)\"(.*?)\"/;
  $key = "$author ";		# don't understand why get errors if in one line 
  $key .= "$volume $page $title";
#   push @{ $hash{$key} }, $paper;

# SIX : first author and page and volume match
  $key = "$author ";		# don't understand why get errors if in one line 
  $key .= "$volume $page";
#   push @{ $hash{$key} }, $paper;

# SEVEN : first author and page and volume and 10chars of title match
  $title = lc($title);
  $title =~ s/caenorhabditis/c./g;
  $title =~ s/\.//g;
  my $title30 = $title;
  if ($title =~ m/.{30}/) { ($title30) = $title =~ m/^(.{30})/g; }
  $key = "$author ";		# don't understand why get errors if in one line 
  $key .= "$volume $page $title30";
#   push @{ $hash{$key} }, $paper;

# EIGHT : page and first of title
  my $title1 = $title;
  if ($title =~ m/.{1}/) { ($title1) = $title =~ m/^(.{1})/g; }
  $key = "$page $title1";
#   push @{ $hash{$key} }, $paper;

# NINE : page and first of title and first of author
  my $author1 = $author;
  if ($author =~ m/.{1}/) { ($author1) = $author =~ m/^(.{1})/g; }
  $author1 = lc($author1);
  $key = "$page $title1 $author1";
#   push @{ $hash{$key} }, $paper;

} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $entry (sort keys %hash) {
  if (scalar( @{ $hash{$entry} }) > 1) { 
# just in case need to look at cgc-pmid that already done in postgres
#     my $bad = 0;
#     foreach (@ {$hash{$entry}}) { if ($xref{$_}) { print "BAD\n"; } }
    foreach (@ {$hash{$entry}}) { 
      print "$_\n"; 
      delete $all_med{$_}; 
    }
    print "$entry\n\n"; 
  }
} # foreach my $entry (sort keys %hash)

# foreach my $med_left (sort keys %all_med) {
#   print "$med_left\n";
# } # foreach my $med_left (sort keys %all_med)
