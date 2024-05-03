#!/usr/bin/env perl

# DELETE these and insert blank to h_pap_gene, for Kimberly.  2024 01 29
# SELECT * FROM pap_gene WHERE pap_gene = '' AND pap_evidence !~ 'afp' ORDER BY pap_timestamp DESC;


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;

$result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_gene = '' AND pap_evidence !~ 'afp' ORDER BY pap_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s/
//g;
    $row[2] =~ s/
//g;
    push @pgcommands, qq(INSERT INTO h_pap_gene VALUES ('$row[0]', null, '$row[2]', 'two1843', 'now', null));
    push @pgcommands, qq(DELETE FROM pap_gene WHERE joinkey = '$row[0]' AND pap_order = '$row[2]');
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
}

__END__

SELECT * FROM pap_gene WHERE pap_gene = '' AND pap_evidence !~ 'afp' ORDER BY pap_timestamp DESC;

__END__

how to set directory to output files at curator / web-accessible
  my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";

how to set base url for a form
  my $baseUrl = $ENV{THIS_HOST_AS_BASE_URL} . "pub/cgi-bin/forms";

how to import modules in dockerized system
  use lib qw(  /usr/lib/scripts/perl_modules/ );                  # for general ace dumping functions
  use ace_dumper;

how to queue a bunch of insertions
  my @pgcommands;
  push @pgcommands, qq(INSERT INTO obo_name_hgnc VALUES $name_commands;);
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

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

