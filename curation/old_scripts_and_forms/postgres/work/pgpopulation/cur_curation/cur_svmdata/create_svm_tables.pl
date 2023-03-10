#!/usr/bin/perl -w

# create  svm_result  postgres table to store postgres svm results.  2012 07 02
#
# cur_svmdata no longer has a cur_paper_modifier column.  2012 12 02


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');


  my $table = 'cur_svmdata';
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

  $table = 'cur_curdata';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_datatype text, 
                         cur_curator text, 
                         $table text, 
                         cur_selcomment text, 
                         cur_txtcomment text, 
                         cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${table}_datatype_idx ON $table USING btree (cur_datatype); ");
  $result = $dbh->do( "CREATE INDEX ${table}_paper_idx ON $table USING btree (cur_paper); ");

  $table = 'cur_curdata_hst';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_datatype text, 
                         cur_curator text, 
                         $table text, 
                         cur_selcomment text, 
                         cur_txtcomment text, 
                         cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${table}_datatype_idx ON $table USING btree (cur_datatype); ");
  $result = $dbh->do( "CREATE INDEX ${table}_paper_idx ON $table USING btree (cur_paper); ");

__END__

  my $table = 'cur_svmdata';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_paper_modifier text, 
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


INSERT INTO cur_curdata VALUES ('00000124', 'antibody',  'two1823' , 'positive', '2',  'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000124', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000123', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00030869', 'antibody',  'two1'    , 'positive', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000003', 'antibody',  'two1'    , 'positive', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00004558', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00004568', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00041460', 'otherexpr', 'two12028', 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000072', 'otherexpr', 'two12028', 'positive', '1',  'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000566', 'otherexpr', 'two12028', 'positive', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000599', 'otherexpr', 'two12028', 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_curdata VALUES ('00000633', 'otherexpr', 'two12028', 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');

