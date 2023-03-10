#!/usr/bin/perl -w

# check rna_ tables for pgids that have data that don't have an rna_name value.  for Chris.  2012 11 01

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my %hash;
my %name;

my @tables = qw( curator paper name laboratory date pcrproduct dnatext sequence strain genotype treatment lifestage temperature deliverymethod species remark nodump phenotype penfromto penetrance heatsens coldsens quantfromto quantdesc phenremark molecule phenotypenot person historyname movie database exprprofile );

foreach my $table (@tables) { 
  $result = $dbh->prepare( "SELECT * FROM rna_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      if ($table eq 'name') { $name{$row[0]}++; }
        else { $hash{$row[0]}++; } } } }

foreach my $pgid (sort {$a<=>$b} keys %hash) {
  unless ($name{$pgid}) { print "$pgid has no rna_name\n"; }
} # foreach my $pgid (sort {$a<=>$b} keys %hash)
