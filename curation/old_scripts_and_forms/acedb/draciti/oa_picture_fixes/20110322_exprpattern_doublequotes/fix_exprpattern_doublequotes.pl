#!/usr/bin/perl -w

# many pic_exprpattern don't have doublequotes in postgres, but they should because it's an ontology field.  2011 03 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $query = "SELECT * FROM pic_exprpattern WHERE pic_exprpattern IS NOT NULL AND pic_exprpattern !~ '\"'";
my @pgcommands;
my $result = $dbh->prepare( "$query" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $value = '"' . $row[1] . '"';
  push @pgcommands, "UPDATE pic_exprpattern SET pic_exprpattern = '$value' WHERE joinkey = '$row[0]' AND pic_exprpattern = '$row[1]'";
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO RUN
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__
