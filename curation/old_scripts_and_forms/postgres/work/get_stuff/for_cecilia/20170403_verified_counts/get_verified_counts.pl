#!/usr/bin/perl -w

# get counts of sent and verified and by whom by month  2017 04 03

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %verified;
my %sent;

my $current_year = 2017;
# my $current_year = 2003;

print qq(Date\tsent\tN ceci\tN ray\tN ppl\tY ceci\tY ray\tY ppl\n);
for my $year (2003 .. $current_year) {
  for my $month (1 .. 12) {
    ($month) = &padMonth($month);
    my $date = $year . '-' . $month . '-01';
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_sent WHERE pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow();
    my $sent = $row[0];
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'NO  Cecilia' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow();
    my $no_ceci = $row[0];
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'NO  Raymond' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow();
    my $no_ray = $row[0];
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'NO' AND pap_author_verified !~ 'NO  Cecilia' AND pap_author_verified !~ 'NO  Raymond' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow();
    my $no_else = $row[0];
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'YES  Cecilia' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow();
    my $yes_ceci = $row[0];
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'YES  Raymond' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow();
    my $yes_ray = $row[0];
    $result = $dbh->prepare( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'YES' AND pap_author_verified !~ 'YES  Cecilia' AND pap_author_verified !~ 'YES  Raymond' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " );
#     print qq( "SELECT COUNT(*) FROM pap_author_verified WHERE pap_author_verified ~ 'YES [A-Z]' AND pap_timestamp > TIMESTAMP '$date' AND pap_timestamp <= TIMESTAMP '$date' + interval '1 month' " \n);
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    @row = $result->fetchrow();
    my $yes_else = $row[0];
    print qq($date\t$sent\t$no_ceci\t$no_ray\t$no_else\t$yes_ceci\t$yes_ray\t$yes_else\n);
  }
}

sub padMonth {
  my $count = shift;
  if ($count < 10) { $count = '0' . $count; }
  return $count;
}

__END__

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

