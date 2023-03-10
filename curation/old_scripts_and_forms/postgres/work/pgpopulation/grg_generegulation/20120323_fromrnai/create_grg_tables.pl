#!/usr/bin/perl -w

# create grg_ tables  2010 09 09

# added some more tables.  2010 09 20, 2010 09 21

# create a grg_intid table for interaction ids.  2012 02 21

# create a grg_fromrnai table to flag that this data came from rnai curation.  2012 03 23


use strict;
use diagnostics;
use DBI;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


my @tables = qw( fromrnai );

foreach my $table (@tables) {
  &createTable($table);				# only create table once
} # foreach my $type (sort keys %obos) 


sub createTable {
  my $root = shift;
  my (@types) = ( '', '_hst' );
  foreach my $type (@types) {
    my $table = 'grg_' . $root . $type;
#     print "CREATE TABLE $table ( joinkey text, $table text, grg_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );\n";
#     print "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);\n";
    $result = $dbh->do("DROP TABLE $table; ");
    $result = $dbh->do( "CREATE TABLE $table ( joinkey text, $table text, grg_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
    $result = $dbh->do( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
    $result = $dbh->do("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO postgres; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO acedb; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO apache; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO azurebrd; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO cecilia; ");
    $result = $dbh->do("GRANT ALL ON TABLE $table TO \"www-data\"; ");
  }
} # sub createTable

