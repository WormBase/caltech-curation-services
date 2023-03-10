#!/usr/bin/perl -w

# Populate obo_{name|syn|data}_<obotable> tables in postgres based off webpages where the obos are stored.  


use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use LWP;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;



# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"', 'acedb');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
# my @users_select = ('acedb');
my @users_select = ();


# enter obotable - URL hash entries here
my %obos;
$obos{integrationmethod}          = 1;

my %data;
@{ $data{integrationmethod} }      = ( "Gamma_irradiation", "X-ray", "Spontaneous", "UV", "UV_TMP", "MMS_mutagenesis", "Single_copy_insertion", "Particle_bombardment", "EMS_mutagenesis" );


# uncomment and run only once for each obotable to create the related tables 
foreach my $obotable (sort keys %obos) { 
#   &createTable($obotable); 
#   &populateTables($obotable); 
}

sub createTable {							# create postgres tables for a given obotable
  my ($obotable) = @_;
  my @tables = qw( name syn data );
  foreach my $table_type (@tables) {
    my $table = 'obo_' . $table_type . '_' . $obotable;
    $result = $dbh->do("DROP TABLE $table; ");
    $result = $dbh->do( "CREATE TABLE $table ( joinkey text, $table text, obo_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
    $result = $dbh->do( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
    $result = $dbh->do("REVOKE ALL ON TABLE $table FROM PUBLIC; ");
    foreach my $user (@users_select) {
      $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
    foreach my $user (@users_all) {
      $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  } # foreach my $table_type (@tables)
} # sub createTable


sub populateTables {
  my @pgcommands;
  my ($obotable) = @_;
  foreach my $value (@{ $data{$obotable} }) {
    push @pgcommands, qq(INSERT INTO obo_name_$obotable VALUES ('$value', '$value'););
    push @pgcommands, qq(INSERT INTO obo_data_$obotable VALUES ('$value', 'id: $value'););
  } # foreach my $value (@{ $data{$obotable} })
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
    $result = $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands) 
} # sub populateTables
