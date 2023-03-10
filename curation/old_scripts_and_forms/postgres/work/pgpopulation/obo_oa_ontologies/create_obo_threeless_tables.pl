#!/usr/bin/perl -w

# create obo_<name|syn|data>_app_<rearrangement|transgene|variation>  2010 09 08
#
# create obo_<name|syn|data>_pic_<exprpattern>  2010 10 29
#
# create obo_<name|syn|data>_pic_<picturesource>  2010 11 15
#
# UNCOMMENT and run this on tazendra when live
# delete obo_<name|syn|data>_<threetype>_<oldobotable>
# create obo_<name|syn|data>_<obotables>  2011 02 22
#
# created tables, still need to delete old tables when live.  2011 02 23


use strict;
use diagnostics;
use DBI;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";

my %delete;
$delete{app}{anat_term} = '';
$delete{app}{entity} = '';
$delete{app}{lifestage} = '';
$delete{app}{quality} = '';
$delete{app}{rearrangement} = '';
$delete{app}{term} = '';
$delete{app}{variation} = '';
$delete{gop}{goid} = '';
$delete{int}{sentid} = '';
$delete{mop}{chebi} = '';
$delete{pic}{exprpattern} = '';
$delete{trp}{clone} = '';
$delete{trp}{location} = '';
$delete{pic}{picturesource} = '';
$delete{app}{tempname} = '';
foreach my $type (sort keys %delete) {
  foreach my $field (sort keys %{ $delete{$type} }) {
    &deleteTable($type, $field);				# only delete table after new ones populated
  } # foreach my $field (sort keys %{ $delete{$type} }) 
} # foreach my $type (sort keys %delete) 

sub deleteTable {
  my ($type, $field) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
    my $table = 'obo_' . $table_type . '_' . $type . '_' . $field;
    print "DROP TABLE $table;\n";
# UNCOMMENT THIS ON TAZENDRA WHEN LIVE  2011 02 22
#     $result = $dbh->do("DROP TABLE $table; ");
  }
}

my %obos;
$obos{anatomy} = '';
$obos{entity} = '';
$obos{lifestage} = '';
$obos{quality} = '';
$obos{rearrangement} = '';
$obos{phenotype} = '';
$obos{variation} = '';
$obos{goid} = '';
$obos{intsentid} = '';
$obos{chebi} = '';
$obos{exprpattern} = '';
$obos{clone} = '';
$obos{laboratory} = '';
$obos{picturesource} = '';


foreach my $field (sort keys %obos) {
  &createTable($field);				# only create table once
} # foreach my $type (sort keys %obos) 


sub createTable {
  my ($field) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
#     my $table = 'obo_' . $table_type . '_' . $type . '_' . $field;
    my $table = 'obo_' . $table_type . '_' . $field;
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

