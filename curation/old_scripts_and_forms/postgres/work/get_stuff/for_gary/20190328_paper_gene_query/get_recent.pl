#!/usr/bin/perl -w

# query paper-gene links for Gary from a flatfile

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;

my $infile = 'rnaiAndAllelePapers';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $paper = <IN>) {
  chomp $paper;
  $result = $dbh->prepare( "SELECT pap_gene FROM pap_gene WHERE joinkey = '$paper'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $data{"WBPaper$paper"}{"WBGene$row[0]"}++; }
  } # while (@row = $result->fetchrow)
} # while (my $line = <IN>)
close (IN) or die "Cannot open $infile : $!";

foreach my $paper (sort keys %data) {
  foreach my $gene (sort keys %{ $data{$paper} }) {
    print qq($paper\t$gene\n);
  } # foreach my $gene (sort keys %{ $data{$paper} })
} # foreach my $paper (sort keys %data)


