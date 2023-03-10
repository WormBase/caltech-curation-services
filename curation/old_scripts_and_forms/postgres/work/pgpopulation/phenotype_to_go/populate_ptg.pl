#!/usr/bin/perl -w

# populate app_ tables based on alp_ tables.  
# Drop and Create the tables and indices with psql -e testdb < app_tables
# Then copy the data with perl.  2007 05 03
#
# added obj_remark table.  2007 08 22
#
# added obj_remark table to the actual table list in app_tables.
# added paper_remark table (DIFFERENT)  2007 08 28
#
# starting over again with unique ID tables and shadow tables.  2008 01 16
#
# prepopulate curation_status with alp_paper papers as happy, and if any from
# alp_finished exist with timestamp use that instead.  2008 03 05
# 
# modified for gop_project  2009 10 22
#
# modified for ptg_  2009 11 17


use strict;
use diagnostics;
use Pg;
use LWP::Simple;
use Jex;	# &getPgDate();

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( term goid curator lastupdate );

foreach my $table (@tables) { &createTable($table); }

sub createTable {
  my $table = shift;
  my $result = $conn->exec( "DROP TABLE ptg_${table}_hst;" );
  $result = $conn->exec( "CREATE INDEX ptg_${table}_idx ON ptg_$table USING btree (joinkey); ");
  $result = $conn->exec( "CREATE TABLE ptg_${table}_hst (
    joinkey text, 
    ptg_${table}_hst text,
    ptg_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE ptg_${table}_hst FROM PUBLIC; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_${table}_hst TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_${table}_hst TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_${table}_hst TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_${table}_hst TO azurebrd; ");
  $result = $conn->exec( "CREATE INDEX ptg_${table}_hst_idx ON ptg_${table}_hst USING btree (joinkey); ");

  $result = $conn->exec( "DROP TABLE ptg_$table;" );
  $result = $conn->exec( "CREATE TABLE ptg_$table (
    joinkey text, 
    ptg_$table text,
    ptg_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE ptg_$table FROM PUBLIC; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_$table TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_$table TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_$table TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE ptg_$table TO azurebrd; ");
}


__END__

