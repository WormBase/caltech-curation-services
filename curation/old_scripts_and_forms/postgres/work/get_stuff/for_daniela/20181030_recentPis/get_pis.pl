#!/usr/bin/perl -w

# for each lab get oldest PI, cull to last 5 years, remove any that are connected to other labs older than that.

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %labToPersonToDate;
my %labToPerson;
my %personToOldestDate;
my %personToLabs;

my %personToName;
my %personToEmail;

$result = $dbh->prepare( "SELECT * FROM two_standardname ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $personToName{$row[0]} = $row[2]; }

$result = $dbh->prepare( "SELECT * FROM two_email ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $personToEmail{$row[0]} = $row[2]; }


$result = $dbh->prepare( "SELECT * FROM two_pis ORDER BY two_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $labToPersonToDate{$row[2]}{$row[0]} = $row[4];
    $labToPerson{$row[2]} = $row[0];
    $personToOldestDate{$row[0]} = $row[4];
    $personToLabs{$row[0]}{$row[2]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $lab (sort keys %labToPerson) {
  next unless ($lab =~ m/[A-Z]/);
  my $person = $labToPerson{$lab};
  my $personTimestamp = $labToPersonToDate{$lab}{$person};
  my ($year, $month, $day) = $personTimestamp =~ m/^(\d\d\d\d)-(\d\d)-(\d\d)/;
  my $isGood = 0;
  my $stillGood = 1;
  if ($year > 2015) { $isGood++; }
    elsif ($year > 2014) { if ($month > 10) { $isGood++; } }
  if ($isGood) { 
    foreach my $otherLab (sort keys %{ $personToLabs{$person} }) {
      if ($lab ne $otherLab) {
        my $otherPersonTimestamp = $labToPersonToDate{$otherLab}{$person};
        my ($otherYear, $otherMonth, $otherDay) = $otherPersonTimestamp =~ m/^(\d\d\d\d)-(\d\d)-(\d\d)/;
        if ($otherYear < 2014) { $stillGood = 0; }
          elsif ($otherYear < 2015) { if ($otherMonth < 10) { $stillGood = 0; } }
      }
    }
    if ($stillGood > 0) {
      print qq($lab\t$person\t$personToName{$person}\t$personToEmail{$person}\t$personTimestamp\n);
    }
  }
} # foreach my $lab (sort keys %labToPerson)

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

