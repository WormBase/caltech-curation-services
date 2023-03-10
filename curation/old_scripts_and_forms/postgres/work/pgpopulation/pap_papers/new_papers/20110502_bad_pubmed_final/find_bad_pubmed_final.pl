#!/usr/bin/perl -w

# Look at downloaded .xml files to see if they're really final or not, because the previous pattern matching was failing.  2011 05 02

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $directory1 = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/';
my $directory2 = '/home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final/xml/';


$/ = undef;

my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN (SELECT joinkey FROM pap_pubmed_final WHERE pap_pubmed_final = 'final')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $joinkey = $row[0];
  my $pmid = $row[1];
  my ($filename) = $pmid =~ m/(\d+)/;
  my $xmlfile = $directory1 . $filename;
  my $found = 0;
  if (-e $xmlfile) { $found++; }
    else { $xmlfile = $directory2 . $filename;
           if (-e $xmlfile) { $found++; } }
  unless ($found) { print "NO FILE $xmlfile\n"; next; }
  open (IN, "<$xmlfile") or die "Cannot open $xmlfile : $!";
  my $page = <IN>;
  close (IN) or die "Cannot close $xmlfile : $!";
  my $pubmed_final = 'not_final';
  my $medline_citation = '';
  if ($page =~ m/(\<MedlineCitation.*?>)/) { $medline_citation = $1; }
  if ($medline_citation =~ /\<MedlineCitation .*Status=\"MEDLINE\"\>/i) { $pubmed_final = 'final'; }    # final version
  elsif ($medline_citation =~ /\<MedlineCitation .*Status=\"PubMed-not-MEDLINE\"\>/i) { $pubmed_final = 'final'; }      # final version
  elsif ($medline_citation =~ /\<MedlineCitation .*Status=\"OLDMEDLINE\"\>/i) { $pubmed_final = 'final'; }      # final version
  print "$joinkey\t$pmid\t$pubmed_final\n";
} # while (@row = $result->fetchrow)

$/ = "\n";

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

