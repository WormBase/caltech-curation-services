#!/usr/bin/perl -w

# form was creating extra pap_author_possible + new pap_join for some authors.
# this is to find those that might still be duplicate.  2014 11 24

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %posJoin; my %posPerson; my %noEmail; my %no; my %yes; my %pap;
$result = $dbh->prepare( "SELECT * FROM pap_author" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $pap{$row[1]} = $row[0]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_possible" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $posPerson{$row[0]}{$row[1]}++; 
  $posJoin{$row[0]}{$row[2]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_author_sent WHERE pap_author_sent ~ 'NO EMAIL'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $noEmail{$row[0]}{$row[2]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'NO'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $no{$row[0]}{$row[2]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'YES'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $yes{$row[0]}{$row[2]}++; }

my $count = 0;
foreach my $aid (sort {$a<=>$b} keys %posJoin) {
  foreach my $person (sort keys %{ $posPerson{$aid} }) {	# authors with same person in multiple joins
    if ($posPerson{$aid}{$person} > 1) { print qq($pap{$aid} POS $aid has $person multiple times\n); } }

    # alternately find some authorID that have been verified yes by a join and not verified by another join
  next unless ($yes{$aid});				# skip those that are not verified, those still need to be connected
  foreach my $join (sort keys %{ $posJoin{$aid} }) {
    next if ($noEmail{$aid}{$join});			# skip aid-join if no email
    next if ($no{$aid}{$join});				# skip aid-join if verified NO
    unless ($yes{$aid}{$join}) { 			# this aid-join is not verified YES, tell us
#       $count++; last if ($count > 10);
      print qq($pap{$aid} POS $aid JOIN $join not verified\n); 
    }
  } # foreach my $join (sort keys %{ $posJoin{$aid} })
} # foreach my $aid (sort keys %posJoin)

