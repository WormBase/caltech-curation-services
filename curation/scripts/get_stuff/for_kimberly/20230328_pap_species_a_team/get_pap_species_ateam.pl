#!/usr/bin/env perl

# get pap_species to compare against a team  2023 03 28
#
# dockerized  2025 06 27


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::UserAgent;
use JSON;
use Dotenv -load => '/usr/lib/.env';

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

#     &checkTaxon(666666666);	# test failure output

my %taxa;
$result = $dbh->prepare( "SELECT DISTINCT(pap_species) FROM pap_species ORDER BY pap_species" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($row[0] eq '09');
    &checkTaxon($row[0]);
  } # if ($row[0])
} # while (@row = $result->fetchrow)

sub checkTaxon {
  my ($taxon) = @_;
  my $url = 'https://curation.alliancegenome.org/api/ncbitaxonterm/NCBITaxon%3A' . $taxon;
#   my $url = 'https://alpha-curation.alliancegenome.org/api/ncbitaxonterm/NCBITaxon%3A' . $taxon;
#   my $url = 'https://alpha-curation.alliancegenome.org/api/ncbitaxonterm/NCBITaxon%3A6239';
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get(
      $url,
      Authorization => 'Bearer eyJraWQiOiJ6Y040RU4wOUFwM3VpYjdNeUM5RFRSM2NGeVlEQ3dCdnJ5N3FYdGVtQkFzIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULm9LcGFxbnhkSmVzVmM3M2NSLUZuX1BNeWpWSkNadmlReW1PWUUtd0dOazgiLCJpc3MiOiJodHRwczovL2Rldi0zMDQ1NjU4Ny5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE3NTEwMDUzNzksImV4cCI6MTc1MTA5MTc3OSwiY2lkIjoiMG9hMWJuMXdqZFppSldhSmU1ZDciLCJ1aWQiOiIwMHUxY3R6dmpnTXBrODdRbTVkNyIsInNjcCI6WyJvcGVuaWQiLCJlbWFpbCJdLCJhdXRoX3RpbWUiOjE3NTA2OTcyMTcsInN1YiI6Imp1YW5jYXJsb3NAd29ybWJhc2Uub3JnIiwiR3JvdXBzIjpbIkV2ZXJ5b25lIiwiVGVzdGVyIiwiRGV2ZWxvcGVycyIsIldvcm1CYXNlRGV2ZWxvcGVyIiwiU3VwZXJBZG1pbiJdfQ.pnWuwLXTIWFlAfhmpAcr9sjH9RFXwdUarKweJBSON27UwMWTvCUFN71GGAyrHTO83vXGORau_8SWxmPz5OkF6nGEIaMZUTFKbaq_4ISmIvQCsf3unFvARYvvfmUWrrqLXyrtOYm7wlFsIu6rCPnLptQSCLGDpZQFa-OsonCuBNYxSLKeR2xJgKk9w-6DSKf_2YPDjqvouNOBVi7VINCkCIRiZRscqfuzJ99nXbDCBwUKdaN_23AlJuukQYs7MpB0Gv-fM42uLZc0x83HUBAazkVX23dZRb83fb2wAD-ktJzjrBTHNICF6ThUrorXYfFSPwDEa9bFMNCbSp2yzax5aQ'
  );
  
#   print qq(TAXON $taxon\n);
#   print qq(RESP $response\n);
#   my %hash = %$response;
#   foreach my $key (sort keys %hash) {
#     print qq($key\n);
#     print qq($hash{$key}\n);
#   }

#   my $href = decode_json $response;
#   my %hash = %$href;
  my %hash = %$response;
  my $result = 'none';
  my $match = 'BAD';
#   if ($hash{_content}{entity}{curie}) 
  if ($hash{_content}) {
    my $content = $hash{_content};
#     print qq(CONTENT $content\n);
    my $href = decode_json $content;
    my %content = %$href;
    my $isok = 'bad';
    if ($content{entity}{curie}) { 
      $result = $content{entity}{curie};
#       print qq(ENTITY\t$content{entity}{curie}\n);
    }
  }
  if ($result eq qq(NCBITaxon:$taxon)) { $match = 'GOOD'; }
  print qq($taxon\t$result\t$match\n);
#   foreach my $key (sort keys %hash) {
#     print qq($key\n);
#     print qq($hash{$key}\n);
#   }
}

__END__

_content
{"entity":{"internal":false,"obsolete":false,"curie":"NCBITaxon:10090","name":"Mus musculus"}}


__END__

curl -X 'GET' \
  'https://alpha-curation.alliancegenome.org/api/ncbitaxonterm/NCBITaxon%3A6239' \
  -H 'accept: application/json' \
  -H 'Authorization: Bearer eyJraWQiOiJDTFdfZHpCeEFzSEhScjFXUHpOdE5KekJUcDlZNHB6WGJEZjJfQjViSHZvIiwiYWxnIjoiUlMyNTYifQ.eyJ2ZXIiOjEsImp0aSI6IkFULlVrOWN3MFoyZUJOcExSNjdoZFhjbUU1YnRraktlbEdQYl9wRDNTaXlRT0kiLCJpc3MiOiJodHRwczovL2Rldi0zMDQ1NjU4Ny5va3RhLmNvbS9vYXV0aDIvZGVmYXVsdCIsImF1ZCI6ImFwaTovL2RlZmF1bHQiLCJpYXQiOjE2ODAwMjA0ODUsImV4cCI6MTY4MDEwNjg4NSwiY2lkIjoiMG9hMWJuMXdqZFppSldhSmU1ZDciLCJ1aWQiOiIwMHUxY3R6dmpnTXBrODdRbTVkNyIsInNjcCI6WyJvcGVuaWQiLCJlbWFpbCJdLCJhdXRoX3RpbWUiOjE2ODAwMjA0ODMsInN1YiI6Imp1YW5jYXJsb3NAd29ybWJhc2Uub3JnIiwiR3JvdXBzIjpbIldCU3RhZmYiLCJFdmVyeW9uZSIsIldvcm1CYXNlRGV2ZWxvcGVyIiwiU3VwZXJBZG1pbiJdfQ.fJcnV9M6tf7OX69qIlC49MXjPLe26jbcfofsaKpA0XyLjPd3lqaL_bDyLihSrrwQ_-qWcIfkZlZbvqcAlF8GXNwSbOt_Qn6NF-6-jNCg2-blWAN0NmBpk0SDF2Yi9vYttYFGFeTEe10xs38DgsbumzRcj0UGrwrUW5svUBWLflnnkQHIj07UntxCqiUz7bW8Uslq9qwy2ZYH79U1jOh_Ao-47Y4-lvRwnWHSxqvivHsOduL72sBZ8MjjvRAtID8PwNBIOFPttdgFWgWaMNpA6Q3jci75N5ht_0faG2rh83d2mcTaOTwWS5ZdaHpcdOsZKif7PzITAxcBq6gYhR1DEA'

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

