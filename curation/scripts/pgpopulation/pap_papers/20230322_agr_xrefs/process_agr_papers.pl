#!/usr/bin/env perl

# read agr wb reference json and extract agr IDs to connect to existing WBPaper IDs.
# 60010 AGR IDs loaded into pap_identifier on dockerized on 2023 03 22, against postgres dump from 20230215.
# 2023 03 22


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
# use JSON::Parse 'parse_json';
use JSON::XS;
# use JSON;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $infile = 'files/reference_WB_nightly.json';
# my $infile = '/usr/lib/scripts/pgpopulation/pap_papers/20230322_agr_xrefs/reference_WB_nightly.json';

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
print "Start reading $infile\n";
my $json_data = <IN>;
print "Done reading $infile\n";
close (IN) or die "Cannot open $infile : $!";

print "Start decoding json\n";
# my %perl = parse_json($json_data);	# JSON::Parse, not installed in dockerized
my $perl = decode_json($json_data);	# JSON  very very slow on dockerized, but fast on tazendra
# my $perl = JSON::XS->new->utf8->decode ($json_data);

print "Done decoding json\n";
my %agr = %$perl;
foreach my $key (sort keys %agr) {
  print qq($key\n);
}

my %wbps;
my %wbpToAgr;

my $count = 0;
foreach my $papobj_href (@{ $agr{data} }) {
#   print qq(papobj_href\n);
  my %papobj = %$papobj_href;
#   $count++; last if ($count > 10);
  my $agr = $papobj{curie};
  my $wbp = '';
#   print qq($agr\n);
  my %xrefs;
  foreach my $xref_href (@{ $papobj{cross_references} }) {
    my %xref = %$xref_href;
    if ($xref{curie} =~ m/^WB:WBPaper(\d+)/) { $wbp = $1; }
#     print qq($xref{curie}\n);
  }
#   print qq(\n);
  if ($wbp) { 
    $wbps{$wbp}++;
    print qq($wbp : $agr\n);
    $wbpToAgr{$wbp} = $agr;
  }
}

foreach my $wbp (sort keys %wbps) {
  if ($wbps{$wbp} > 1) { print qq(ERR : Too many wbps $wbp $wbps{$wbp}\n); }
}

my %valid;
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

my %highestPapIdent;
$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $highestPapIdent{$row[0]} = $row[2];
}

my @pgcommands;
foreach my $joinkey (sort keys %wbpToAgr) {
  next unless $valid{$joinkey};
  my $order = 1;
  if ($highestPapIdent{$joinkey}) {
    $order = $highestPapIdent{$joinkey} + 1;
    # print qq(ERR : No order for $joinkey\n);
  }
  push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$joinkey', '$wbpToAgr{$joinkey}', $order, 'two1823'););
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment LIMIT 5" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


how to set directory to output files at curator / web-accessible
  my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";

how to set base url for a form
  my $baseUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms";

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

