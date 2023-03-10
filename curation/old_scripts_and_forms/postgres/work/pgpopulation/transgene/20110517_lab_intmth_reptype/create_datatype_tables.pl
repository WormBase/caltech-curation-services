#!/usr/bin/perl -w

# create <datatype>_<table> table, <datatype>_<table>_hst history table, <datatype>_<table>_idx index, <datatype>_<table>_hst_idx index. 


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');

# the code for the datatype, by convention all datatypes have three letters.
my $datatype = 'trp';

# put tables here for each OA field.  Skip field 'id', fields of type 'queryonly', and any other fields that should not have a corresponding postgres table.
my @tables = qw( laboratory integration_method reporter_type person paper );

# make backup copy to .pg files
# COPY trp_integrated_by TO '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/integrated_by.pg';
# COPY trp_integrated_by_hst TO '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/integrated_by_hst.pg';
# COPY trp_location TO '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/location.pg';
# COPY trp_location_hst TO '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/location_hst.pg';
# COPY trp_reference TO '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/reference.pg';
# COPY trp_reference_hst TO '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/reference_hst.pg';

# copy to new tables
# COPY trp_integration_method FROM '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/integrated_by.pg';
# COPY trp_integration_method_hst FROM '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/integrated_by_hst.pg';
# COPY trp_laboratory FROM '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/location.pg';
# COPY trp_laboratory_hst FROM '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/location_hst.pg';
# COPY trp_paper FROM '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/reference.pg';
# COPY trp_paper_hst FROM '/home/postgres/work/pgpopulation/transgene/20110517_lab_intmth_reptype/reference_hst.pg';

# need to delete from oac_ tables otherwise it fails when loading the editor frame
#   DELETE FROM oac_column_width    WHERE oac_datatype = 'trp' AND (oac_table = 'integrated_by' OR oac_table = 'location' OR oac_table = 'movie' OR oac_table = 'picture' OR oac_table = 'reference');
#   DELETE FROM oac_column_order    WHERE oac_datatype = 'trp' AND (oac_table = 'integrated_by' OR oac_table = 'location' OR oac_table = 'movie' OR oac_table = 'picture' OR oac_table = 'reference');
#   DELETE FROM oac_column_showhide WHERE oac_datatype = 'trp' AND (oac_table = 'integrated_by' OR oac_table = 'location' OR oac_table = 'movie' OR oac_table = 'picture' OR oac_table = 'reference');

# drop old tables
# DROP TABLE trp_integrated_by ;
# DROP TABLE trp_integrated_by_hst ;
# DROP TABLE trp_location ;
# DROP TABLE trp_location_hst ;
# DROP TABLE trp_reference ;
# DROP TABLE trp_reference_hst ;

foreach my $table (@tables) { &createTable($table); }


sub createTable {
  my $table = shift;
  my $result;
  $result = $dbh->do( "DROP TABLE ${datatype}_${table}_hst;" );
  $result = $dbh->do( "CREATE TABLE ${datatype}_${table}_hst (
                         joinkey text, 
                         ${datatype}_${table}_hst text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_${table}_hst FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table}_hst TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table}_hst TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_hst_idx ON ${datatype}_${table}_hst USING btree (joinkey); ");

  $result = $dbh->do( "DROP TABLE ${datatype}_$table;" );
  $result = $dbh->do( "CREATE TABLE ${datatype}_$table (
                         joinkey text, 
                         ${datatype}_$table text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_$table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table} TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table} TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_idx ON ${datatype}_$table USING btree (joinkey); ");
} # sub createTable


__END__


=head1 NAME

create_datatype_tables.pl - script to create postgres data tables and history tables for ontology annotator datatype-field tables.


=head1 SYNOPSIS

Edit the arrays of users to grant permission to (both 'select' and 'all'), edit the datatype, edit the array of tables that list the table values, then run with

  ./create_datatype_tables.pl


=head1 DESCRIPTION

The ontology_annotator.cgi requires some postgres data tables and postgres history tables for almost all fields.  The 'id' field is required and doesn't have a corresponding set of postgres tables.  Fields of type 'queryonly' also don't have a corresponding set of postgres tables.  The tables have columns:

=over 4 

=item * joinkey  a text field that corresponds to the ontology annotator's pgid.

=item * <datatype>_<table>  a text field that stores the corresponding data.

=item * <datatype>_timestamp  a timestamp field with default 'now'.

=back

History tables are the same as normal tables with '_hst' appended to the table name, the second column name, and the index name.

For each table, the postgres table is '<datatype>_<table>', the history table is '<datatype>_<table>_hst' ;  the indices are '<datatype>_<table>_idx' and '<datatype>_<table>_hst_idx', indexing on the data column.  Tables are dropped in case they already exist and are then re-created, access is granted to postgres users, indices are created.

Edit the arrays of postgres database users to grant permission to (both 'select' and 'all'), edit the datatype, edit the array of tables that list the table values, then run with

  ./create_datatype_tables.pl
