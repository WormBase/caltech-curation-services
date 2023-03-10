#!/usr/bin/perl -w
#
# This script takes all the relevant postgreSQL paramters (the table names from
# the curation form)  and for each of these runs &PgCommand($_); which grabs all
# the values, and sticks the joinkeys into the HashOfHashes %HoH.  %HoH has as a
# first key, the name of the tables, as a second key, the joinkeys (pubID), and
# as a value the amount of times that key has been used (always 1 because of
# unique indexing except for the case of curator).  After the foreach loop has
# finished, all the joinkeys / table are stored in %HoH.
# For each curator_key (the keys from the %{ $HoH{$curator} } hash), %HoH is
# looped through for each $table ( $HoH{$table} ) to check if it has a second
# key value of $curator_key (that is, if that pubID is accounted for in that
# table).  If not, then the value is added to a %Missing (hash of hashes).
# For each of these %Missing entries, &PgOut($joinkey, $table); is called, which
# looks in the curator postgreSQL table, and outputs the CURATOR NAME, JOINKEY,
# and TABLE NAME.		2001-12-06

use strict;
use CGI;
use Fcntl;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @PGparameters = qw(curator newsymbol synonym mappingdata genefunction associationequiv associationnew expression rnai transgene overexpression mosaic antibody extractedallelename extractedallelenew newmutant sequencechange genesymbols geneproduct structurecorrection sequencefeatures cellname cellfunction ablationdata newsnp stlouissnp goodphoto comment);
# my %variables;

# my @PGparameters = qw(curator newsymbol mappingdata genefunction extractedallelenew structurecorrection sequencefeatures rnai comment);

my %HoH;
my %Missing;

foreach (@PGparameters) {
  &PgCommand($_);
} # foreach (@PGparameters)

foreach my $curator_key (sort keys %{ $HoH{curator} } ) {
  foreach my $table (@PGparameters) {
    unless ($HoH{$table}{$curator_key}) { 
#       print "$table doesn't have $curator_key\n";
      $Missing{$table}{$curator_key}++;
    }
  } # foreach (@PGparameters)
} # foreach my $curator_key (sort keys %{ $HoH{curator} } ) 

foreach my $table (sort keys %Missing) {
  foreach my $joinkey (sort keys %{ $Missing{$table} } ) {
    &PgOut($joinkey, $table);
  } # foreach my $joinkey (sort keys %{ $Missing{$table} } )
} # foreach my $table (sort keys %Missing)


sub PgOut {
  my ($joinkey, $table) = @_;
  my $result = $conn->exec( "SELECT * FROM curator WHERE joinkey = \'$joinkey\';" ); 
  my @row;
  while (@row = $result->fetchrow) {	# loop through all rows returned
    print "$row[1] curated $joinkey missing $table\n";
  } # while (@row = $result->fetchrow) 
} # sub PgOut 

sub PgCommand {
  my $table = shift;
  my $result = $conn->exec( "SELECT * FROM $table;" );
  my @row;
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $HoH{$table}{$row[0]}++;
  } # while (@row = $result->fetchrow) 
} # sub PgCommand 
