#!/usr/bin/perl -w

# Look at wpa_author_possible with multiple copies of the same author_id
# withouth any two# assigned, then delete latest duplicate along with all
# sent and verified for that wpa_join.  2005 10 21

use strict;
use diagnostics;
use Pg;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";


my %count;
my $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible IS NULL AND wpa_join IS NOT NULL;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $count{$row[0]}++; } }

my %theHash;
foreach my $aid (sort {$a<=>$b} keys %count) {
  if ($count{$aid} > 2) {
    my $result = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author = '$aid';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { print OUT "AID $aid in paper $row[0]\n"; } }
    $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        print OUT "AID $aid Possible @row\n"; } }
    $result = $conn->exec( "SELECT * FROM wpa_author_sent WHERE author_id = '$aid';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { my $stuff = join"\t", @row; print OUT "AID $aid Sent $stuff\n"; } }
    $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { my $stuff = join"\t", @row; print OUT "AID $aid Verified $stuff\n"; } } }
  elsif ($count{$aid} > 1) {
    my $ver_flag = 0;				# does this aid have any verified data
    my $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible IS NULL AND wpa_join IS NOT NULL AND author_id = '$aid';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        my $join = $row[2]; 
        my $result2 = $conn->exec( "SELECT * FROM wpa_author_verified WHERE wpa_join = '$join' AND author_id = '$aid';" );
        while (my @row2 = $result2->fetchrow) { 
          if ($row2[0]) { if ($row2[1]) { $ver_flag++; } } } } } 
    if ($ver_flag) { print OUT "AID $aid has verified data but no possible\n"; }
      else { 					# neither verified nor possible, delete multiples of aid
        my $pgcommand = "SELECT * FROM wpa_author_possible WHERE wpa_author_possible IS NULL AND wpa_join IS NOT NULL AND author_id = '$aid' ORDER BY wpa_timestamp DESC;" ;
        my $result = $conn->exec( "$pgcommand" );
        my @row = $result->fetchrow;
        my $join = $row[2]; my $timestamp = $row[5];
        $pgcommand = "DELETE FROM wpa_author_possible WHERE author_id = '$aid' AND wpa_join = '$join' AND wpa_timestamp = '$timestamp';" ;
        print OUT "$pgcommand\n";
        my $result2 = $conn->exec( "$pgcommand" );
        my @row2 = $result2->fetchrow;
        print OUT "possible @row2\n";
        $pgcommand = "DELETE FROM wpa_author_verified WHERE author_id = '$aid' AND wpa_join = '$join' ;" ;
        $result2 = $conn->exec( "$pgcommand" );
        print OUT "$pgcommand\n";
        $pgcommand = "DELETE FROM wpa_author_sent WHERE author_id = '$aid' AND wpa_join = '$join' ;" ;
        $result2 = $conn->exec( "$pgcommand" );
        print OUT "$pgcommand\n";
        # should delete wpa_author_sent too, but forgot, so did it manually with out put of this script
      }
        
#     $result = $conn->exec( "SELECT * FROM wpa_author_sent WHERE wpa_author_sent IS NULL AND wpa_join IS NOT NULL AND author_id = '$aid';" );
#     while (my @row = $result->fetchrow) { 
#       if ($row[0]) { $theHash{$row[0]}{$row[2]}{sent}{$row[5]}++; } }
#     $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE wpa_author_verified IS NULL AND wpa_join IS NOT NULL AND author_id = '$aid';" );
#     while (my @row = $result->fetchrow) { 
#       if ($row[0]) { $theHash{$row[0]}{$row[2]}{verified}{$row[5]}++; } }
  } # elsif ($count{$aid} > 1)
} # foreach my $aid (sort {$a<=>$b} keys %count)

foreach my $aid (sort keys %theHash) {
  foreach my $join (sort keys %{ $theHash{$aid} }) {
  } # foreach my $join (sort keys %theHash)
} # foreach my $aid (sort keys %theHash)

__END__

my %count;
my $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible IS NULL AND wpa_join IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { $count{$row[0]}{$row[2]}++; }
}

foreach my $aid (sort {$a<=>$b} keys %count) {
  foreach my $join (sort {$a<=>$b} keys %{ $count{$aid} }) {
    if ($count{$aid}{$join} > 1) { 
print "AID $aid JOIN $join\n";
      my $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' AND wpa_join = '$join' AND wpa_author_verified IS NOT NULL;" );
      while (my @row = $result->fetchrow) {
        if ($row[1]) { print "ERROR AID $aid JOIN $join verified $row[1]\n"; delete $count{$aid}{$join}; } } } } }

foreach my $aid (sort {$a<=>$b} keys %count) {
  foreach my $join (sort {$a<=>$b} keys %{ $count{$aid} }) {
    if ($count{$aid}{$join} > 1) {
print "2AID $aid JOIN $join\n";
      my $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' AND wpa_join = '$join' AND wpa_author_possible IS NULL ORDER BY wpa_timestamp;" );
      my @row = $result->fetchrow;
      if ($row[3] ne 'valid') { print "INVALID $aid\n"; } 
      my $pgcommand = "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' AND wpa_join = '$join' AND wpa_author_possible IS NULL AND wpa_timestamp = '$row[5]';" ;
      print OUT "$pgcommand\n";
         
} } }


close (OUT) or die "Cannot close $outfile : $!";
