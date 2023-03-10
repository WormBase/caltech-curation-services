#!/usr/bin/perl -w

# Get author_id and wpa_join from wpa_author_verified where it has been
# verified.  Grab the two_number by matching it with two_standardname.
# Get the wpa_author_possible for those author_id and wpa_join where
# the wpa_author_possible IS NULL.  Output to screen for Cecilia.
# 2005 11 18
#
# This program outputs pairs when there's a possible and a null
# under wpa_author_possible.  If it outputs a single line then
# that is probably missing a two number (in fact, how could it 
# not ?).  Run this again to find problems, but this won't fix them.
# 2005 11 21


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %verified;
my $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE wpa_author_verified IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
    my $author_id = $row[0];
    my $verified = $row[1];
    my $join = $row[2];
    my $standardname = ''; my $two_num; my $verified_count;
    if ($verified =~ m/NO\s+(.*?)$/) { $standardname = $1; }
    elsif ($verified =~ m/YES\s+(.*?)$/) { $standardname = $1; }
    my $result3 = $conn->exec( "SELECT joinkey FROM two_standardname WHERE two_standardname = '$standardname' ORDER BY two_timestamp DESC;" );
    my @row3 = $result3->fetchrow; if ($row3[0]) { $two_num = $row3[0]; } 
    $result3 = $conn->exec( "SELECT COUNT(*) FROM wpa_author_verified WHERE author_id = '$author_id' AND wpa_join = '$join';" );
    @row3 = $result3->fetchrow; if ($row3[0]) { $verified_count = $row3[0]; } 
    my $result2 = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$author_id' AND wpa_join = '$join' AND wpa_author_possible IS NULL;" );
    my $possible_null = 0;
    while (my @row2 = $result2->fetchrow) {
      if ($row2[0]) { 
#         print "$two_num\tver_count $verified_count\t$standardname\t$verified\t@row2\n"; 
        $possible_null++; } }
    if ($possible_null) { 
      my $result4 = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$author_id' AND wpa_join = '$join';" );
      my $printed_something = 0;
      while (my @row4 = $result4->fetchrow) {
        if ($row4[0]) { 
          $printed_something++;
          if ($row4[2] =~ m/two/) { unless ($row4[2] ne $two_num) { print "ERR $two_num not equal to $row4[2]\n"; } }
          print "$two_num\tver_count $verified_count\t$standardname\t$verified\t@row4\n"; } } 
      if ($printed_something) { print "\n"; } }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

