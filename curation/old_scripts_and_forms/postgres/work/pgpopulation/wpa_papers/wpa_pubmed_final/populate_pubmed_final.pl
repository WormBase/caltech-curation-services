#!/usr/bin/perl -w

# populate wpa_pubmed_final with pmid if there is one, "no_pmid" if there isn't.  replace pmid# values with "final" / "not_final" after getting the xml.  2009 12 08

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my %exists;

my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER by wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    if ($row[3] eq 'valid') { $hash{$row[0]}{$row[1]}{when} = $row[5]; $hash{$row[0]}{$row[1]}{who} = $row[4]; }
      else { delete $hash{$row[0]}{$row[1]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM wpa ORDER by wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $exists{$row[0]}{when} = $row[5]; $exists{$row[0]}{who} = $row[4]; }
    else { delete $exists{$row[0]}; }
}

foreach my $joinkey (sort keys %exists) {
  if ($hash{$joinkey}) {
    foreach my $pmid (sort keys %{ $hash{$joinkey} }) {
      $result = $dbh->do( "INSERT INTO wpa_pubmed_final VALUES ('$joinkey', '$pmid', NULL, 'valid', '$hash{$joinkey}{$pmid}{who}', '$hash{$joinkey}{$pmid}{when}');" );
      $result = $dbh->do( "INSERT INTO wpa_pubmed_final_hst VALUES ('$joinkey', '$pmid', NULL, 'valid', '$hash{$joinkey}{$pmid}{who}', '$hash{$joinkey}{$pmid}{when}');" );
    } # foreach my $pmid (sort keys %{ $hash{$joinkey} })
  } else {
      $result = $dbh->do( "INSERT INTO wpa_pubmed_final VALUES ('$joinkey', 'no_pmid', NULL, 'valid', '$exists{$joinkey}{who}', '$exists{$joinkey}{when}');" );
      $result = $dbh->do( "INSERT INTO wpa_pubmed_final_hst VALUES ('$joinkey', 'no_pmid', NULL, 'valid', '$exists{$joinkey}{who}', '$exists{$joinkey}{when}');" );
  }
} # foreach my $joinkey (sort keys %hash)

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
