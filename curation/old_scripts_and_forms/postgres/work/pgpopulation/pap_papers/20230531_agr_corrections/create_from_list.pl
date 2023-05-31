#!/usr/bin/perl -w

# Create PMIDs from a list that came from Alliance recursive corrections.  2023 05 31
#
# 19322353, primary, author_person, Caenorhabditis elegans 6239.

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use pap_match qw( processXmlIds );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pmids = qw( 27154433 29195124 19322353 25699681 25742442 25995025 26018900 26075908 26123112 26186524 26199050 26200340 26272998 26354977 26366869 26394001 26394399 26448567 26472915 26496836 26527203 26754975 26773128 26779766 26812166 26858445 26887572 26940883 26998588 27053124 27091988 27161120 27186651 27199683 27259058 27270701 27315557 27546571 27611795 27681440 27716778 27767314 27851730 28135330 28253172 28265088 28446204 28722650 28903539 28958135 28973870 28980937 29186542 29300951 29378783 29398010 29449617 29520042 29595188 29596525 29611099 29618594 29727664 29972787 30014746 30054291 30161120 30264564 30643216 30778531 30860672 30936176 31112701 31164751 31189735 31211967 31420004 31488913 31527152 31582857 31641239 31644902 31791661 31874958 31904130 31970719 32066719 32127597 32240648 32246130 32259491 32392217 32482730 32499511 32517851 32541926 32636309 32694680 32788717 32792670 32818474 32820264 32842787 32857619 32957446 32958656 32968790 33049908 33061934 33077719 33219230 33315465 33433002 33461481 33526707 33710400 33846265 33854240 34021339 34100189 34137639 34145433 34163038 34312490 34357389 34370007 34370030 34385439 34524417 34548611 34605047 34614410 34625497 34873162 34880238 34907327 34932600 35411089 35665632 );

my @pairs;
foreach my $pmid (@pmids) {
  push @pairs, "$pmid, primary, author_person, Caenorhabditis elegans 6239"; }
my $list = join"\t", @pairs;

my $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads';
my ($link_text) = &processXmlIds('two1843', '', $list, $directory);

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

