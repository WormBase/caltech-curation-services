#!/usr/bin/perl -w

# for Wen, rollback to a day ago data that changed for this table on 2010 03 26

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my $result = $dbh->prepare( "SELECT * FROM trp_other_reporter_hst WHERE trp_timestamp < '2010-03-26' AND joinkey IN (SELECT joinkey FROM trp_other_reporter_hst WHERE trp_timestamp > '2010-03-26') ORDER BY joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $result2 = $dbh->do( "UPDATE trp_other_reporter SET trp_other_reporter = '$row[1]' WHERE joinkey = '$row[0]';" );
  $result2 = $dbh->do( "UPDATE trp_other_reporter SET trp_timestamp = '$row[2]' WHERE joinkey = '$row[0]';" );
  $result2 = $dbh->do( "UPDATE trp_other_reporter SET trp_timestamp = '$row[2]' WHERE joinkey = '$row[0]';" );
  # also need to delete, but did this from psql afterwards with a
  # DELETE FROM trp_other_reporter_hst WHERE trp_timestamp > '2010-03-26';
} # while (@row = $result->fetchrow)

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
