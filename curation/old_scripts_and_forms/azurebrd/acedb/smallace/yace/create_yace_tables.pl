#!/usr/bin/perl -w

# create <datatype>_<table> table, <datatype>_<table>_idx index, for yacedb tables.  all tables have joinkey, order, data, evidence.  2014 03 15


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=yaceadb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');

my %tables;
$tables{gin}{cgc_name}			= 'UNIQUE';
$tables{gin}{sequence_name}		= 'UNIQUE';
$tables{gin}{public_name}		= 'UNIQUE';
$tables{gin}{experimental_info}		= 'normal';
$tables{gin}{concise_description}	= 'normal';
$tables{gin}{reference}			= 'normal';

$tables{rna}{evidence}			= 'normal';
$tables{rna}{delivered_by}		= 'UNIQUE';
$tables{rna}{strain}			= 'normal';
$tables{rna}{gene}			= 'normal';
$tables{rna}{phenotype}			= 'normal';
$tables{rna}{phenotype_not_observed}	= 'normal';
$tables{rna}{reference}			= 'normal';

$tables{phe}{description}		= 'UNIQUE';
$tables{phe}{primary_name}		= 'UNIQUE';
$tables{phe}{rnai}			= 'normal';
$tables{phe}{not_in_rnai}		= 'normal';

$tables{pap}{author}			= 'normal';
$tables{pap}{title}			= 'UNIQUE';
$tables{pap}{journal}			= 'UNIQUE';
$tables{pap}{volume}			= 'UNIQUE';
$tables{pap}{page}			= 'UNIQUE';
$tables{pap}{brief_citation}		= 'UNIQUE';
$tables{pap}{abstract}			= 'normal';
$tables{pap}{gene}			= 'normal';
$tables{pap}{rnai}			= 'normal';

$tables{evi}{paper_evidence}		= 'normal';
$tables{evi}{person_evidence}		= 'normal';
$tables{evi}{curator_confirmed}		= 'normal';
$tables{evi}{inferred_automatically}	= 'normal';
$tables{evi}{rnai_evidence}		= 'normal';
$tables{evi}{date_last_updated}		= 'UNIQUE';

foreach my $datatype (sort keys %tables) {
  foreach my $table (sort keys %{ $tables{$datatype} }) {
    my $indexType = $tables{$datatype}{$table};						# some tables are unique per object
    my $joinkeyType = 'text'; if ($datatype eq 'evi') { $joinkeyType = 'integer'; }	# most tables use text, but evidence table is integer
    $result = $dbh->do( "DROP TABLE ${datatype}_${table};" );
#     $result = $dbh->do( "CREATE TABLE ${datatype}_${table} (
#                            joinkey $joinkeyType, 
#                            ${datatype}_order integer,
#                            ${datatype}_${table} text,
#                            ${datatype}_evidence integer,
#                            ${datatype}_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
    $result = $dbh->do( "CREATE TABLE ${datatype}_${table} (
                           joinkey $joinkeyType, 
                           ${datatype}_order integer,
                           ${datatype}_${table} text,
                           ${datatype}_evi integer ); " );
    $result = $dbh->do( "REVOKE ALL ON TABLE ${datatype}_${table} FROM PUBLIC; ");
    foreach my $user (@users_select) { 
      $result = $dbh->do( "GRANT SELECT ON TABLE ${datatype}_${table} TO $user; "); }
    foreach my $user (@users_all) { 
      $result = $dbh->do( "GRANT ALL ON TABLE ${datatype}_${table} TO $user; "); }
    if ($indexType eq 'normal') { $indexType = ''; }
    $result = $dbh->do( "CREATE $indexType INDEX ${datatype}_${table}_idx ON ${datatype}_${table} USING btree (joinkey); ");
  } # foreach my $table (sort keys %{ $tables{$datatype} })
} # foreach my $datatype (sort keys %tables)


__END__


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


# the code for the datatype, by convention all datatypes have three letters.
# my $datatype = 'tst';

# put tables here for each OA field.  Skip field 'id', fields of type 'queryonly', and any other fields that should not have a corresponding postgres table.
# my @tables = qw( name animals dataflag datatext curator remark nodump person otherpersons date );
# 
# foreach my $table (@tables) { &createTable($table); }

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
