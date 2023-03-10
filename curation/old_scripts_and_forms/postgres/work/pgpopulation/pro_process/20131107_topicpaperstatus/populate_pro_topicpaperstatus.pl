#!/usr/bin/perl -w

# populate pro_topicpaperstatus based on pro_curator  2013 11 07
# live on tazendra.  2013 11 07

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %joinkeys;
$result = $dbh->prepare( "SELECT joinkey FROM pro_curator ORDER BY joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $joinkeys{$row[0]}++; }

$result = $dbh->prepare( "SELECT joinkey FROM pro_topicpaperstatus ORDER BY joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { delete $joinkeys{$row[0]}; }


my @pgcommands;
foreach my $joinkey (sort {$a<=>$b} keys %joinkeys) {
  push @pgcommands, qq(INSERT INTO pro_topicpaperstatus VALUES ('$joinkey', 'relevant'););
  push @pgcommands, qq(INSERT INTO pro_topicpaperstatus_hst VALUES ('$joinkey', 'relevant'););
} # foreach my $joinkey (sort {$a<=>$b} keys %joinkeys)

foreach my $command (@pgcommands) {
  print "$command\n";
#   $dbh->do( $command );
} # foreach my $command (@pgcommands)

