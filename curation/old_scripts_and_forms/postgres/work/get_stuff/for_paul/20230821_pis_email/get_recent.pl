#!/usr/bin/perl -w

# get snail mail for PIs.  2009 09 18
#
# modified to get emails and lab codes.  2023 08 21

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my @fields = qw( pis standardname email street city state post country );
foreach my $field (@fields) {
  my $result = $dbh->prepare( "SELECT * FROM two_$field" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      if ($row[2]) { $row[2] =~ s///g; $hash{$field}{$row[0]}{$row[1]} = $row[2]; }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

foreach my $joinkey (sort keys %{ $hash{pis} }) {
  print "$hash{standardname}{$joinkey}{1}\n";
  my $address = "";
  if ($hash{pis}{$joinkey}) {
    foreach my $join (sort {$a<=>$b} keys %{ $hash{pis}{$joinkey} }) {
      $address .= "Lab code: $hash{pis}{$joinkey}{$join}\n"; } }
  if ($hash{email}{$joinkey}) {
    foreach my $join (sort {$a<=>$b} keys %{ $hash{email}{$joinkey} }) {
      $address .= "Email: $hash{email}{$joinkey}{$join}\n"; } }
  if ($hash{street}{$joinkey}) {
    foreach my $join (sort {$a<=>$b} keys %{ $hash{street}{$joinkey} }) {
      $address .= "$hash{street}{$joinkey}{$join}\n"; } }
  if ($hash{city}{$joinkey}{1}) { $address .= "$hash{city}{$joinkey}{1}, "; }
  if ($hash{state}{$joinkey}{1}) { $address .= "$hash{state}{$joinkey}{1}  "; }
  if ($hash{post}{$joinkey}{1}) { $address .= "$hash{post}{$joinkey}{1}\n"; }
  if ($hash{country}{$joinkey}{1}) { $address .= "$hash{country}{$joinkey}{1}\n"; }
  if ($address) { print $address; }
  print "\n";
}



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
