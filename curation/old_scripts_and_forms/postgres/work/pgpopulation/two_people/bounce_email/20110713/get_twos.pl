#!/usr/bin/perl -w

# find the two and order for some bounced email addresses  2010 03 29
#
# strip Mail/bounce/\d+:To: 
# strip < and >
# filter through hash.  2011 07 13

use strict;
use diagnostics;
use DBI;
use Tie::IxHash;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %matches; tie %matches, "Tie::IxHash";
my $infile = 'bouncey';
open (IN, "<$infile") or die "Cannot cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/Mail\/bounce\/\d+:To: (.*?)$/) { $line = $1; }
  my $data = '';
  my ($email) = lc($line);
  if ($email =~ m/</) { $email =~ s/<//g; }
  if ($email =~ m/>/) { $email =~ s/>//g; }
  my $result = $dbh->prepare( "SELECT * FROM two_email WHERE LOWER (two_email) = '$email'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my $match = 0;
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $matches{"$row[0]\t$row[1]\t$row[2]\n"}++;
      $match++;
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  unless ($match) { $matches{"NO MATCH FOR $line\n"}++; }
#   unless ($data) { $data = "NO MATCH FOR $line\n"; }
#   print "$data";
}
close (IN) or die "Cannot cannot close $infile : $!";

foreach my $match (keys %matches) {
  print "$match";
}

# my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

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
