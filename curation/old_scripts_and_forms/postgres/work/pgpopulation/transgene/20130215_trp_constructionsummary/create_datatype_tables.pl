#!/usr/bin/perl -w

# create <datatype>_<table> table, <datatype>_<table>_hst history table, <datatype>_<table>_idx index, <datatype>_<table>_hst_idx index. 
#
# create trp_constructionsummary and move trp_remark into it.  copy-pasted and checked pairs of psql commands after end.  2013 02 15


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
my @tables = qw( constructionsummary );

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

COPY trp_remark TO '/home/postgres/work/pgpopulation/transgene/20130215_trp_constructionsummary/old_remark.pg';
COPY trp_remark_hst TO '/home/postgres/work/pgpopulation/transgene/20130215_trp_constructionsummary/old_remark_hst.pg';

COPY trp_constructionsummary FROM '/home/postgres/work/pgpopulation/transgene/20130215_trp_constructionsummary/old_remark.pg';
COPY trp_constructionsummary_hst FROM '/home/postgres/work/pgpopulation/transgene/20130215_trp_constructionsummary/old_remark_hst.pg';

DELETE FROM trp_remark ;
DELETE FROM trp_remark_hst ;
