#!/usr/bin/env perl

# look at grg_transregulatorallele and look for dead variations from obo_data_variation  2012 02 22
#
# dockerized into curation/scripts/citace_upload/ontology_check/ from acedb/chris/ because it's
# used for checking something about an ontology.  2023 03 13

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %deadVar;
my $result = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE obo_data_variation ~ 'Dead'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $deadVar{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM grg_transregulatorallele" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my ($pgid, $vars) = ($row[0], $row[1]);
  my (@vars) = $vars =~ m/(WBVar\d+)/;
  my $dead = 0; my %dead;
  foreach my $var (@vars) { if ($deadVar{$var}) { $dead++; $dead{$var}++; } }
  if ($dead) {
    my (@dead) = sort keys %dead;
    my $dVars = join",", @dead;
    print "PGID\t$pgid\t$dVars\n"; 
} }


__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

