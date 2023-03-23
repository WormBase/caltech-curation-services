#!/usr/bin/perl -w

# find pgids for Expr objects in file.  for Daniela.  2014 07 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %expr;
my $infile = 'Curated_by.ace.edited';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/Expr_pattern : "(Expr\d+)"/) { $expr{$1}++; }
} # while (my $line = <IN>) {
close (IN) or die "Cannot close $infile : $!";

my $exprs = join"','", sort keys %expr;

my %pgids;
my $result = $dbh->prepare( "SELECT * FROM exp_name WHERE exp_name IN ('$exprs')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgids{$row[0]}++; } }

my $pgids = join",", sort {$a<=>$b} keys %pgids;
print "$pgids\n";

