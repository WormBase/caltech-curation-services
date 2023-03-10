#!/usr/bin/perl -w
#
# This script is made obsolete by check_bad_counts.pl
#
# This script takes all the relevant postgreSQL parameters (the table names 
# from the curation form)  and gets count numbers, keeping track of the highest
# count.  The ``curator'' field should be excluded, as it is the only one
# without a UNIQUE index, and as such can have multiple entries / joinkey.  At
# this stage (2001-12-06) things have been curated only once, and I wanted to
# catch all values, so left the ``curator'' field in.  (Didn't write an unless
# for it) 	2001-12-06

use strict;
use CGI;
use Fcntl;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @PGparameters = qw(curator newsymbol synonym mappingdata genefunction associationequiv associationnew expression rnai transgene overexpression mosaic antibody extractedallelename extractedallelenew newmutant sequencechange genesymbols geneproduct structurecorrection sequencefeatures cellname cellfunction ablationdata newsnp stlouissnp goodphoto comment);

# my @PGparameters = qw(curator newsymbol mappingdata genefunction extractedallelenew structurecorrection sequencefeatures comment);

my %tables;
my $highest = 0;

foreach (@PGparameters) {
  &PgCommand($_);
} # foreach (@PGparameters)

foreach my $table (sort keys %tables) {
  if ($tables{$table} < $highest) { print "$table has $tables{$table}\n"; }
} # foreach my $table (sort keys %tables) 


sub PgCommand {
  my $table = shift;
  my $result = $conn->exec( "SELECT COUNT(*) FROM $table;" );
  my @row;
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $tables{$table} = $row[0];
# insert unless($table eq 'curator') { } here
    if ($row[0] > $highest) { $highest = $row[0]; }
#     print "$table : $row[0]\n";
  } # while (@row = $result->fetchrow) 
} # sub PgCommand 
