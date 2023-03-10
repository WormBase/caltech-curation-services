#!/usr/bin/perl -w

# create afp tables for author first pass flagging  
#
# use numeric to get 17 digit precision with 7 decimals  (as opposed to 15 digit
# with float)  2008 06 30
#
# had messed up the revoke and grant, fixed. 
# created _hst tables without UNIQUE index.
# copied data from tables to _hst tables, backup in orig_tables/$table.pg
#
# rewrote script to recreate and repopulate the tables from original afp_ dumps.
# 2009 03 21
#
# real run  2009 04 06
#
# modified to create a few journal first pass tables for tables that will only show
# in journal first passing (currently just for genetics)   
# these tables do NOT need curator confirmation, but who knows if people will change
# their mind about that, so adding them in now since it will only take up more space 
# and potentially save a lot of work later.
# 2009 05 03


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
# $result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result;

my @afp_tables = qw( newstrains newbalancers newprotein newcell authors );

foreach my $table (@afp_tables) {
  my $table2 = 'afp_' . $table ;
  $result = $dbh->do("DROP TABLE $table2; ");
  $result = $dbh->do( "CREATE TABLE $table2 ( joinkey text, $table2 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text), afp_curator text, afp_approve text, afp_cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
  $result = $dbh->do( "CREATE UNIQUE INDEX ${table2}_idx ON $table2 USING btree (joinkey);" );
  $result = $dbh->do("REVOKE ALL ON TABLE $table2 FROM PUBLIC; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table2 TO postgres; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table2 TO acedb; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table2 TO apache; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table2 TO azurebrd; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table2 TO cecilia; ");
  my $table3 = $table2 . '_hst';
  $result = $dbh->do("DROP TABLE $table3; ");
  $result = $dbh->do( "CREATE TABLE $table3 ( joinkey text, $table3 text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text), afp_curator text, afp_approve text, afp_cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
  $result = $dbh->do( "CREATE INDEX ${table3}_idx ON $table3 USING btree (joinkey);" );
  $result = $dbh->do("REVOKE ALL ON TABLE $table3 FROM PUBLIC; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table3 TO postgres; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table3 TO acedb; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table3 TO apache; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table3 TO azurebrd; ");
  $result = $dbh->do("GRANT ALL ON TABLE $table3 TO cecilia; ");
} # foreach my $table (@afp_tables)

