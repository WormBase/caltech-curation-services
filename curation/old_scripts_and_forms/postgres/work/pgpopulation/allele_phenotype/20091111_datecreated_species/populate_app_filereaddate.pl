#!/usr/bin/perl -w

# populate app_filereaddate based on date in app_nbp.  2009 11 12
#
# final run  2009 12 15

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %app_nbp;
my $result = $dbh->prepare( "SELECT * FROM app_nbp ORDER BY app_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($app_nbp{$row[0]});
    $app_nbp{$row[0]} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $joinkey (sort keys %app_nbp) {
  my $timestamp = $app_nbp{$joinkey};
  my ($date_created) = $timestamp =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
  $result = $dbh->do( "INSERT INTO app_filereaddate VALUES ('$joinkey', '$date_created', '$timestamp')" );
  $result = $dbh->do( "INSERT INTO app_filereaddate_hst VALUES ('$joinkey', '$date_created', '$timestamp')" );
} # foreach my $joinkey (sort keys %app_nbp)

__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

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
