#!/usr/bin/perl -w

# get papers with multiple wpa_identifier that are pmids  2009 12 16
# changed for cgc also  2009 12 17

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $hash{$row[0]}{$row[1]}++; }
      else { delete $hash{$row[0]}{$row[1]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pap (sort {$a<=>$b} keys %hash) {
  my @pmids = keys %{ $hash{$pap} };
  if (scalar @pmids > 1) { 
    my $pmids = join", ", @pmids;
    print "$pap\t$pmids\n";
  }
} # foreach my $pap (sort {$a<=>$b} keys %hash)


%hash = ();
$result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'cgc' ORDER BY wpa_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $hash{$row[0]}{$row[1]}++; }
      else { delete $hash{$row[0]}{$row[1]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pap (sort {$a<=>$b} keys %hash) {
  my @cgc = keys %{ $hash{$pap} };
  if (scalar @cgc > 1) { 
    my $cgc = join", ", @cgc;
    print "$pap\t$cgc\n";
  }
} # foreach my $pap (sort {$a<=>$b} keys %hash)
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
