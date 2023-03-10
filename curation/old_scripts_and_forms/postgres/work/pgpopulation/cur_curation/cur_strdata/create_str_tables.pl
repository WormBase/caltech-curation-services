#!/usr/bin/perl -w

# create  svm_result  postgres table to store postgres svm results.  2012 07 02
#
# cur_svmdata no longer has a cur_paper_modifier column.  2012 12 02
#
# cur_strdata is for textpresso string searches.
#   http://wiki.wormbase.org/index.php/New_2012_Curation_Status#Datatypes_for_Textpresso_String_Searches
# cur_date and cur_version are currently all going to be blank, but might be used in the future (maybe)
# 2014 11 04



use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');


  my $table = 'cur_strdata';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_datatype text, 
                         cur_date text, 
                         $table text, 
                         cur_version text, 
                         cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${table}_datatype_idx ON $table USING btree (cur_datatype); ");
  $result = $dbh->do( "CREATE INDEX ${table}_paper_idx ON $table USING btree (cur_paper); ");


