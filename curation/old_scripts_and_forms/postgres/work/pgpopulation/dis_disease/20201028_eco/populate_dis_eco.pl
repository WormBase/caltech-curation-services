#!/usr/bin/perl -w

# populate dis_eco table with "ECO:0007013"  2020 10 28

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %valid;
$result = $dbh->prepare( "SELECT * FROM dis_curator" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $valid{$row[0]}++ }
} # while (@row = $result->fetchrow)

my @pgcommands;
foreach my $joinkey (sort {$a<=>$b} keys %valid) {
  my $pgcommand = qq(INSERT INTO dis_eco VALUES ('$joinkey', '"ECO:0007013"'));
  push @pgcommands, $pgcommand;
  $pgcommand = qq(INSERT INTO dis_eco_hst VALUES ('$joinkey', '"ECO:0007013"'));
  push @pgcommands, $pgcommand;
} # foreach my $joinkey (sort {$a<=>$b} keys %valid)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
#   UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands) 

__END__

