#!/usr/bin/perl -w

# compare output from citace of genes with automated tag, and compare to postgres data.  2015 01 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %ace;
my $acefile = 'citace_genes_with_automated.ace';
open (IN, "<$acefile") or die "Cannot open $acefile : $!";
while (my $line = <IN>) { 
  if ($line =~ m/(WBGene\d+)/) { $ace{$1}++; } }
close (IN) or die "Cannot close $acefile : $!";

my %has_automated;
$result = $dbh->prepare( "SELECT * FROM con_wbgene WHERE joinkey IN (SELECT joinkey FROM con_desctype WHERE con_desctype ~ 'Automated')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $has_automated{$row[1]}++; } }

my %has_concise;
$result = $dbh->prepare( "SELECT * FROM con_wbgene WHERE joinkey IN (SELECT joinkey FROM con_desctype WHERE con_desctype ~ 'Concise')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $has_concise{$row[1]}++; } }

foreach my $gene (sort keys %has_automated) { 
  unless ($ace{$gene}) { 
    print qq(In postgres, not ace : $gene); 
    if ($has_concise{$gene}) { print qq(\thas concise); }
    print qq(\n);
  }
} # foreach my $gene (sort keys %has_automated)

foreach my $gene (sort keys %ace) { 
  unless ($has_automated{$gene}) { print qq(In ace, not postgres : $gene\n); }
} # foreach my $gene (sort keys %ace)
