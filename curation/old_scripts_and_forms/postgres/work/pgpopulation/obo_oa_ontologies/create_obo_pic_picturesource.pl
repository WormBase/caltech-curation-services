#!/usr/bin/perl -w

# create obo_<name|syn|data>_app_<rearrangement|transgene|variation>  2010 09 08
#
# create obo_<name|syn|data>_pic_<exprpattern>  2010 10 29
#
# create obo_<name|syn|data>_pic_<picturesource>  2010 11 15


use strict;
use diagnostics;
use DBI;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


my %obos;
$obos{pic}{picturesource} = '';
# $obos{app}{transgene} = '';
# $obos{app}{variation} = '';

foreach my $type (sort keys %obos) {
  foreach my $field (sort keys %{ $obos{$type} }) {
    &createTable($type, $field);				# only create table once
  } # foreach my $field (sort keys %{ $obos{$type} }) 
} # foreach my $type (sort keys %obos) 


sub createTable {
  my ($type, $field) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
    my $table = 'obo_' . $table_type . '_' . $type . '_' . $field;
    $result = $dbh->do("DROP TABLE $table; ");
    $result = $dbh->do( "CREATE TABLE $table ( joinkey text, $table text, obo_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
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

