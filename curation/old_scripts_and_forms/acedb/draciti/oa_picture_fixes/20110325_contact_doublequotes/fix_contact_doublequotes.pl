#!/usr/bin/perl -w

# many pic_contact don't have doublequotes in postgres, but they should because it's an ontology field.  2011 03 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $query = "SELECT * FROM pic_contact WHERE pic_contact IS NOT NULL AND pic_contact !~ '\"'";
my @pgcommands;
my $result = $dbh->prepare( "$query" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $value = '"' . $row[1] . '"';
  push @pgcommands, "UPDATE pic_contact SET pic_contact = '$value' WHERE joinkey = '$row[0]' AND pic_contact = '$row[1]'";
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO RUN
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__
