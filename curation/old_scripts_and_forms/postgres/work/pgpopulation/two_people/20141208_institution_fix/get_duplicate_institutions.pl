#!/usr/bin/perl -w

# query institutions by person and see if any are duplicate, because some people have different institutions that get mapped to the same one later.  2015 07 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %inst;
$result = $dbh->prepare( "SELECT * FROM two_institution WHERE joinkey IN (SELECT joinkey FROM two_status WHERE two_status = 'Valid') ORDER BY two_institution" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $inst{$row[0]}{inst}{$row[2]}++; }

$result = $dbh->prepare( "SELECT * FROM two_old_institution WHERE joinkey IN (SELECT joinkey FROM two_status WHERE two_status = 'Valid') ORDER BY two_old_institution" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";  
while (my @row = $result->fetchrow) { $inst{$row[0]}{oldinst}{$row[2]}++; }

foreach my $two (sort keys %inst) {
  foreach my $inst (sort keys %{ $inst{$two}{inst} }) {
    if ($inst{$two}{inst}{$inst} > 1) { print "TWO $two COUNT $inst{$two}{inst}{$inst} INST $inst\n"; } }
  foreach my $oldinst (sort keys %{ $inst{$two}{oldinst} }) {
    if ($inst{$two}{oldinst}{$oldinst} > 1) { print "TWO $two COUNT $inst{$two}{oldinst}{$oldinst} OLD INST $oldinst\n"; } }
#   my $twos = join", ", keys %{ $inst{$inst}{inst} };
#   my $oldtwos = join", ", keys %{ $inst{$inst}{oldinst} };
#   print "$twos\t$oldtwos\t$inst";
#   if ($inst =~ m/;/) { print "\t$inst"; }
#   print "\n";
} # foreach my $inst (sort keys %inst)

