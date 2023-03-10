#!/usr/bin/perl -w

# remove all NULLs from two_middlename

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;

$result = $dbh->prepare( "SELECT * FROM two_middlename WHERE two_middlename = 'NULL'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    push @pgcommands, qq(INSERT INTO h_two_middlename VALUES('$row[0]', '$row[1]', NULL, 'two1'););
    push @pgcommands, qq(DELETE FROM two_middlename WHERE joinkey = '$row[0]' AND two_order = '$row[1]';);
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

