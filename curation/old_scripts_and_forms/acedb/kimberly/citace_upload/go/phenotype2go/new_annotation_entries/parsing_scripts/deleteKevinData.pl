#!/usr/bin/perl -w

# delete Kevin Howe data in gop tables.  for Kimberly.  2015 07 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgids;
$result = $dbh->prepare( "SELECT joinkey FROM gop_curator WHERE gop_curator = 'WBPerson3111' ORDER BY joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { push @pgids, $row[0]; }
my $pgids = join"','", @pgids;

my @pgcommands;
my @tables = qw( wbgene qualifier goid paper goinference goontology dbtype lastupdate project curator with_wbvariation with_phenotype with_rnai );
foreach my $table (@tables) {
  push @pgcommands, qq(DELETE FROM gop_${table}_hst WHERE joinkey IN ('$pgids'););
  push @pgcommands, qq(DELETE FROM gop_${table}     WHERE joinkey IN ('$pgids'););
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO REMOVE DATA
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__
