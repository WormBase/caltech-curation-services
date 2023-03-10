#!/usr/bin/perl -w

# for papers that have a PMID but no DOI, get the DOI from http://www.pmid2doi.org/
# for Kimberly and Daniela.  2014 01 07
#
# used by :
# /home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/get_new_elegans_xml.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use JSON;

my $json = JSON->new->allow_nonref;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %highestOrder;
my %pmidToDoi;
my %pmidToPap;
my @pmids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ '^doi') AND joinkey NOT IN (SELECT joinkey FROM pap_status WHERE pap_status = 'invalid')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[1] =~ s/pmid//g;
    $row[1] =~ s/ //g;
    $pmidToPap{$row[1]} = $row[0]; 
    push @pmids, $row[1];
#     print "$row[0]\t$row[1]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey NOT IN (SELECT joinkey FROM pap_status WHERE pap_status = 'invalid')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0] && $row[2]) { 
    my $joinkey = $row[0];
    my $order   = $row[2];
    my $highestSoFar = 0; my $replace = 0;
    if ($highestOrder{$joinkey}) { if ($order > $highestOrder{$joinkey}) { $replace++; } }
      else { $replace++; }
    if ($replace) { $highestOrder{$joinkey} = $order; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)


my $max = 100;
while (scalar @pmids > 0) {
  my @temp;
  for (1 .. $max) { 
    my $pmid = shift @pmids;
    if ($pmid) { push @temp, $pmid; }
  }
  my $query = join",", @temp;
  my $url = 'http://www.pmid2doi.org/rest/json/batch/doi?pmids=[' . $query . ']';
#   print "URL $url URL\n";

  my $page_data = get $url;
#   print "P $page_data P\n";

  my $perl_scalar = $json->decode( $page_data );
  my @jsonArray = @$perl_scalar;
  foreach my $entry (@jsonArray) {
    my $pmid = $entry->{"pmid"};
    my $doi  = $entry->{"doi"};
    $pmidToDoi{$pmid} = $doi;
  } # foreach my $entry (@jsonArray)

#   last;
}

my @pgcommands; 
my $pap_curator = 'two1843';
my $timestamp = 'CURRENT_TIMESTAMP';

foreach my $pmid (sort keys %pmidToDoi) {
  my $joinkey = $pmidToPap{$pmid};
  my $order   = $highestOrder{$joinkey} + 1;
  if ($pmidToDoi{$pmid} =~ m/&lt;/)     { $pmidToDoi{$pmid} =~ s/&lt;/</g;     }
  if ($pmidToDoi{$pmid} =~ m/&gt;/)     { $pmidToDoi{$pmid} =~ s/&gt;/>/g;     }
  if ($pmidToDoi{$pmid} =~ m/&amp;lt;/) { $pmidToDoi{$pmid} =~ s/&amp;lt;/</g; }
  if ($pmidToDoi{$pmid} =~ m/&amp;gt;/) { $pmidToDoi{$pmid} =~ s/&amp;gt;/>/g; }
#   print "$joinkey\t$order\tpmid$pmid\tdoi$pmidToDoi{$pmid}\n";
  push @pgcommands, qq(INSERT INTO pap_identifier   VALUES ('$joinkey', 'doi$pmidToDoi{$pmid}', $order, '$pap_curator', $timestamp) );
  push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$joinkey', 'doi$pmidToDoi{$pmid}', $order, '$pap_curator', $timestamp) );
} # foreach my $pmid (sort keys %pmidToDoi)

foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
# UNCOMMENT TO POPULATE
  my $result2 = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

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

