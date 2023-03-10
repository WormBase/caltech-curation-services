#!/usr/bin/perl -w

# change postgres tables from storing molecules as pgids to storing them as wbmolIDs.  2012 10 22
#
# live run on tazendra.  2012 10 23

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my @tables = qw( app_molecule grg_moleculeregulator pro_molecule rna_molecule app_molecule_hst grg_moleculeregulator_hst pro_molecule_hst rna_molecule_hst );

my %map;
$result = $dbh->prepare( "SELECT * FROM mop_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $map{$row[0]} = $row[1]; }

foreach my $table (@tables) {
#   print "TABLE $table\n";
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    next unless $row[1];
    my $oldObjs = $row[1];
    $oldObjs =~ s/^\"//; $oldObjs =~ s/\"$//;
    my (@objs) = split/","/, $oldObjs;
    my @newObjs;
    foreach my $obj (@objs) {
      if ($map{$obj}) { push @newObjs, $map{$obj}; }
        else { print "No mapping for $obj in $table @row\n"; }
    } # foreach my $obj (@objs)
    if (scalar @newObjs > 0) {
      my $newObjs = join'","', @newObjs;
      $newObjs = '"' . $newObjs . '"';
      push @pgcommands, "UPDATE $table SET $table = '$newObjs' WHERE $table = '$row[1]' AND joinkey = '$row[0]';"; }
  } # while (@row = $result->fetchrow)
#   print "ENDTABLE $table\n";
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO UPDATE POSTGRES
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__

