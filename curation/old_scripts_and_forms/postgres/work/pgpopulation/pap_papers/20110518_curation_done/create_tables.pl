#!/usr/bin/perl -w

# create new pap tables to replace old pap_ tables and wpa_ tables with data from 
# wpa_ tables  2009 12 10
#
# fixed Year / Month / Day not going in right from mis-parsed XML.
# check WBPaper00002006  xml 8041603 for Year / Month / Day  2010 02 19


use strict;
use diagnostics;
use DBI;
use Jex;		# filter for Pg

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $result;

my @pap_tables = qw( curation_done );

# TO CREATE THE TABLES

# foreach my $table (@pap_tables) { 
#   $result = $dbh->do( "DROP TABLE h_pap_$table" );
#   $result = $dbh->do( "DROP TABLE pap_$table" ); }

foreach my $table (@pap_tables) {
  my $papt = 'pap_' . $table;
  $result = $dbh->do( "CREATE TABLE $papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone )" ); 
  $result = $dbh->do( "CREATE INDEX ${papt}_idx ON $papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE $papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO cecilia;" );
  $result = $dbh->do( "GRANT ALL ON TABLE $papt TO \"www-data\";" );

  
  $result = $dbh->do( "CREATE TABLE h_$papt ( joinkey text, $papt text, pap_order integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone )" ); 
  $result = $dbh->do( "CREATE INDEX h_${papt}_idx ON h_$papt USING btree (joinkey);" );
  $result = $dbh->do( "REVOKE ALL ON TABLE h_$papt FROM PUBLIC;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO postgres;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO acedb;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO apache;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO azurebrd;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO cecilia;" );
  $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO \"www-data\";" );
} # foreach my $table (@pap_tables)

