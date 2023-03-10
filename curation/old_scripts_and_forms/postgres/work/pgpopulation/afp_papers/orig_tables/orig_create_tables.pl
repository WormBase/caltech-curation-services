#!/usr/bin/perl -w

# create afp tables for author first pass flagging  
#
# use numeric to get 17 digit precision with 7 decimals  (as opposed to 15 digit
# with float)  2008 06 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( genesymbol mappingdata genefunction newmutant rnai lsrnai geneinteractions geneproduct expression sequencefeatures generegulation overexpression mosaic site microarray invitro covalent structureinformation structurecorrectionsanger sequencechange massspec ablationdata cellfunction phylogenetic othersilico chemicals transgene antibody newsnp rgngene nematode humandiseases supplemental review comment );

my $table = 'afp_passwd';

my $result = $conn->exec( "DROP TABLE $table" );
$result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table numeric(17,7), afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
$result = $conn->exec( "CREATE UNIQUE INDEX ${table}_idx ON $table USING btree (joinkey);" );
$result = $conn->exec( "CREATE UNIQUE INDEX ${table}_idx ON $table USING btree (joinkey);" );
$result = $conn->exec("REVOKE ALL ON TABLE wpa_title FROM PUBLIC; ");
$result = $conn->exec("REVOKE ALL ON TABLE wpa_title FROM postgres; ");
$result = $conn->exec("GRANT ALL ON TABLE wpa_title TO postgres; ");
$result = $conn->exec("GRANT ALL ON TABLE wpa_title TO acedb; ");
$result = $conn->exec("GRANT ALL ON TABLE wpa_title TO apache; ");
$result = $conn->exec("GRANT ALL ON TABLE wpa_title TO azurebrd; ");
$result = $conn->exec("GRANT ALL ON TABLE wpa_title TO cecilia; ");

foreach my $table (@tables) {
  $table = 'afp_' . $table;
  $result = $conn->exec( "DROP TABLE $table" );
  $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table text, afp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) );" );
  $result = $conn->exec( "CREATE UNIQUE INDEX ${table}_idx ON $table USING btree (joinkey);" );
  $result = $conn->exec( "CREATE UNIQUE INDEX ${table}_idx ON $table USING btree (joinkey);" );
  $result = $conn->exec("REVOKE ALL ON TABLE wpa_title FROM PUBLIC; ");
  $result = $conn->exec("REVOKE ALL ON TABLE wpa_title FROM postgres; ");
  $result = $conn->exec("GRANT ALL ON TABLE wpa_title TO postgres; ");
  $result = $conn->exec("GRANT ALL ON TABLE wpa_title TO acedb; ");
  $result = $conn->exec("GRANT ALL ON TABLE wpa_title TO apache; ");
  $result = $conn->exec("GRANT ALL ON TABLE wpa_title TO azurebrd; ");
  $result = $conn->exec("GRANT ALL ON TABLE wpa_title TO cecilia; ");
}

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

