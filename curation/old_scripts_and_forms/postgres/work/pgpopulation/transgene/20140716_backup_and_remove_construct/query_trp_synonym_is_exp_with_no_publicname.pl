#!/usr/bin/perl -w

# query to get pgids where trp_synonym ~ Expr and there is no trp_publicname  2014 07 16

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pgids;
$result = $dbh->prepare( "SELECT * FROM trp_synonym WHERE trp_synonym ~ 'Expr' AND joinkey NOT IN (SELECT joinkey FROM trp_publicname);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgids{$row[0]}++; } }

my $pgids = join",", sort {$a<=>$b} keys %pgids;
print "$pgids\n";

