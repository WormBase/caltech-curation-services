#!/usr/bin/perl -w

# create frm_wbperson and frm_email for ommitting/skipping persons and email from mass mailings.  
# re-create frm_ip_bock to have the same format.  for Chris and Valerio.  2020 03 19


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
my $datatype = 'frm';

# put tables here for each OA field.  Skip field 'id', fields of type 'queryonly', and any other fields that should not have a corresponding postgres table.
my @tables = qw( ip_block wbperson_skip email_skip );

foreach my $table (@tables) {
  &dropTable($table); 
  &createTable($table); 
}


sub dropTable {
  my $table = shift;
  my $result;
  $result = $dbh->do( "DROP TABLE IF EXISTS ${datatype}_$table;" );
}

sub createTable {
  my $table = shift;
  my $result;
  $result = $dbh->do( "CREATE TABLE ${datatype}_$table (
                         ${datatype}_$table text,
                         ${datatype}_curator text,
                         ${datatype}_comment text,
                         ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_$table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table} TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table} TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${datatype}_${table}_idx ON ${datatype}_$table USING btree (${datatype}_$table); ");
} # sub createTable


__END__

INSERT INTO frm_ip_block VALUES('46.161.41.199', 'two2987', 'manual', '2015-09-01 12:00:00-07');
INSERT INTO frm_ip_block VALUES('188.143.232.32', 'two2987', 'manual', '2016-03-19 12:00:00-07');
INSERT INTO frm_ip_block VALUES('188.143.232.19', 'two2987', 'manual', '2016-05-13 14:10:47.074011-07');
INSERT INTO frm_ip_block VALUES('5.188.211.16', 'two2987', 'manual', '2017-10-21 12:02:32.090584-07');
INSERT INTO frm_ip_block VALUES('5.188.211.26', 'two2987', 'manual', '2017-10-22 23:22:47.019419-07');
INSERT INTO frm_ip_block VALUES('5.188.211.10', 'two2987', 'manual', '2018-01-07 07:56:11.799944-08');

 SELECT * FROM frm_ip_block ;
  frm_ip_block  | frm_comment |         frm_timestamp         
----------------+-------------+-------------------------------
 46.161.41.199  | chris       | 2015-09-01 12:00:00-07
 188.143.232.32 | chris       | 2016-03-19 12:00:00-07
 188.143.232.19 | chris       | 2016-05-13 14:10:47.074011-07
 5.188.211.16   | chris       | 2017-10-21 12:02:32.090584-07
 5.188.211.26   | chris       | 2017-10-22 23:22:47.019419-07
 5.188.211.10   | chris       | 2018-01-07 07:56:11.799944-08
(6 rows)

