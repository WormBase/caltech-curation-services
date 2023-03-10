#!/usr/bin/perl -w

# Look at merged two entries between two5593 to two5644, and try to figure out
# which ones need to be simply moved, and which ones have to be handled more
# carefully due to existing wpa_author_possible, wpa_author_sent, and possibly
# them having replied and having wpa_author_verified.  2006 11 22

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @twos;
my $infile = 'merged_simple';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { if ($line =~ m/(two\d+)/) { push @twos, $1; } }
close (IN) or die "Cannot close $infile : $!";

my @tables = qw( two_status two_comment two_lastname two_firstname two_standardname two_city two_state two_post two_institution two_country two_mainphone two_email two_street );

my $result = $conn->exec( "SELECT two FROM two ORDER BY two DESC;" );
my @row = $result->fetchrow;
my $two_num = $row[0];

foreach my $two (@twos) {
  print "T $two T\n"; 
  $two_num++;
  my $joinkey = 'two' . $two_num;
  my $pgcommand = "INSERT INTO two VALUES ('$joinkey', '$two_num', CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
  $result = $conn->exec( $pgcommand );
  foreach my $table (@tables) {
    $pgcommand = "UPDATE $table SET joinkey = '$joinkey' WHERE joinkey = '$two' AND two_timestamp ~ '2006-11-17';";
    print "$pgcommand\n";
    $result = $conn->exec( $pgcommand );
  } # foreach my $table (@tables)
}

__END__

for my $two (5593 .. 5644) {
  my $joinkey = 'two' . $two;
  my $result = $conn->exec( "SELECT two_standardname, two_timestamp FROM two_standardname WHERE joinkey = '$joinkey';" );
  while (my @row = $result->fetchrow) {
    print "$joinkey\t$row[0]\t$row[1]\n";
  }
  $result = $conn->exec( "SELECT author_id FROM wpa_author_possible WHERE wpa_author_possible = '$joinkey';" );
  while (my @row = $result->fetchrow) {
    my $aid = $row[0];
    my $result2 = $conn->exec( "SELECT joinkey FROM wpa_author WHERE wpa_author = '$aid';" );
    my @row2 = $result2->fetchrow; my $paper = $row2[0];
    $result2 = $conn->exec( "SELECT wpa_author_index FROM wpa_author_index WHERE author_id = '$aid';" );
    while (@row2 = $result2->fetchrow) {
      my $aname = $row2[0];
      print "Paper $paper\tAID $row[0]\tANAME $aname\n";
    }
  }
  print "\n";
}

__END__

