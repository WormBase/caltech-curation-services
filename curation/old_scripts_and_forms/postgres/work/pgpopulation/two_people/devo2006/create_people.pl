#!/usr/bin/perl -w

# Take the dev evo people stuff and create people for them after Cecilia went
# through them and took out people that already existed.  2006 11 17

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $result = $conn->exec( "SELECT two FROM two ORDER BY two DESC;" );
my @row = $result->fetchrow;
my $two_num = $row[0];


my $infile = 'Dev_Evol2006.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp ($line);
  $line =~ s/\"//g;
  my ($last, $first, $ad1, $ad2, $inst, $city, $state, $zip, $country, $phone, $email) = split/\t/, $line;
 
  $two_num++;
  my $joinkey = 'two' . $two_num;
  my $pgcommand = "INSERT INTO two VALUES ('$joinkey', '$two_num', CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_status VALUES ('$joinkey', '1', 'Valid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_comment VALUES ('$joinkey', 'Dev Evo 2006 list', CURRENT_TIMESTAMP );";
  print "$pgcommand\n";				# This didn't go in right originally
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_lastname VALUES ('$joinkey', '1', '$last', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_firstname VALUES ('$joinkey', '1', '$first', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  my $stdname = "$first $last";
  $pgcommand = "INSERT INTO two_standardname VALUES ('$joinkey', '1', '$stdname', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  if ($city) {
    $pgcommand = "INSERT INTO two_city VALUES ('$joinkey', '1', '$city', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($state) {
    $pgcommand = "INSERT INTO two_state VALUES ('$joinkey', '1', '$state', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($zip) {
    $pgcommand = "INSERT INTO two_post VALUES ('$joinkey', '1', '$zip', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($inst) {
    $pgcommand = "INSERT INTO two_institution VALUES ('$joinkey', '1', '$inst', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($country) {
    $pgcommand = "INSERT INTO two_country VALUES ('$joinkey', '1', '$country', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($phone) {
    $pgcommand = "INSERT INTO two_mainphone VALUES ('$joinkey', '1', '$phone', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($email) {
    $pgcommand = "INSERT INTO two_email VALUES ('$joinkey', '1', '$email', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }

  my @street = ();
  if ($ad2) { push @street, $ad2; }
  if ($inst) { push @street, $inst; }
  if ($ad1) { push @street, $ad1; }
  my $two_order = 0;
  while (@street) {
    my $val = shift @street;
    if ($val) { $two_order++;
      $pgcommand = "INSERT INTO two_street VALUES ('$joinkey', '$two_order', '$val', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
      print "$pgcommand\n";
#       $result = $conn->exec( $pgcommand );
    } }
      
  

} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


__END__

