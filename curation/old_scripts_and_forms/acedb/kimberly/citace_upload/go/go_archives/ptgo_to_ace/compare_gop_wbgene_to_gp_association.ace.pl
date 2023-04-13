#!/usr/bin/perl -w

# compare the genes in gop_wbgene vs the genes in gp_association.ace .  2013 11 19


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %gop; my %ace;
my $result = $dbh->prepare( "SELECT * FROM gop_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gop{$row[1]}++; }

my $infile = 'gp_association.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) { if ($entry =~ m/^Gene : \"(WBGene\d+)\"/) { $ace{$1}++; } }
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $gop (sort keys %gop) { 
  unless ($ace{$gop}) { print qq($gop in gop_wbgene, not in $infile\n); } }

foreach my $ace (sort keys %ace) { 
  unless ($gop{$ace}) { print qq($ace in $infile, not in gop_wbgene\n); } }

