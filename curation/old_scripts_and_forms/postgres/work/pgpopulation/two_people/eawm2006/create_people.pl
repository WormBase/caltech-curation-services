#!/usr/bin/perl -w

# Take the eawm people stuff and create people for them after Cecilia went
# through them and took out people that already existed and PIs that don't
# match.  2006 11 08

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;
my $result = $conn->exec( "SELECT * FROM two_lastname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{main}{last} = $row[2]; } }
$result = $conn->exec( "SELECT * FROM two_firstname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{main}{first} = $row[2]; } }
$result = $conn->exec( "SELECT * FROM two_aka_lastname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{$row[1]}{last} = $row[2]; } }
$result = $conn->exec( "SELECT * FROM two_aka_firstname;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{$row[1]}{first} = $row[2]; } }

my %names;
foreach my $join (sort keys %hash) {
  foreach my $key (sort keys %{ $hash{$join} }) {
    my $first = $hash{$join}{$key}{first};
    my $last = ''; if ($hash{$join}{$key}{last}) { $last = $hash{$join}{$key}{last}; }
    my $init = ''; if ($first) { ($init) = $first =~ m/^(.)/; }
    my $name = "$last $init";
    $name = lc($name);
    $names{$name}{$join}++; } }

# foreach my $name (sort keys %names) {
#   print "$name\t";
#   foreach my $join (sort keys %{ $names{$name} }) { print "$join\t"; }
#   print "\n"; }

$result = $conn->exec( "SELECT two FROM two ORDER BY two DESC;" );
my @row = $result->fetchrow;
my $two_num = $row[0];


my $infile = 'eawm2006-editado.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp ($line);
  $line =~ s/\"//g;
  my ($a, $first_mid, $last, $inst, $pi_fm, $pi_l, $country, $address, $area, $phone, $ext, $fax, $email) = split/\t/, $line;
  my $first; my $mid;
  if ($first_mid =~ m/\s+/) { ($first, $mid) = $first_mid =~ m/^(\S+)\s+(.*?)$/; }
    else { $first = $first_mid; }
#   my ($init) = $first_mid =~ m/^(.)/;
#   my $name = "$last $init";
#   $name = lc($name);
#   if ($names{$name}) { 
#       my @joins;
#       foreach my $join (sort keys %{ $names{$name} }) { push @joins, $join; }
#       my $joins = join", ", @joins;
#       print "$first_mid $last MATCHES $joins\n"; }
#     else { print "NO MATCH $first_mid $last\n"; }

 
  my $lab_code = '';
  if ( $pi_fm && $pi_l ) {
    my $pi_join = '';
    if ($pi_l =~ m/(two\d+)/) { $pi_join = $1; }
    my ($init) = $pi_fm =~ m/^(.)/;
    my $name = "$pi_l $init";
    $name = lc($name);
    if ($names{$name}) { 
        my @joins;
        foreach my $join (sort keys %{ $names{$name} }) { push @joins, $join; }
        my $joins = join", ", @joins;
#         print "PI $pi_fm $pi_l MATCHES $joins\n"; 
        $pi_join = $joins; }
    if ($pi_join) { 
      my $result2 = $conn->exec( "SELECT two_pis FROM two_pis WHERE joinkey = '$pi_join';" );
      my @row2 = $result2->fetchrow;
      $lab_code = $row2[0]; 
      unless ($lab_code) { print "NO CODE $pi_join\n"; } } }
  
  my ($street, $city) = $address =~ m/^(.*),(.*?)$/;

  $two_num++;
  my $joinkey = 'two' . $two_num;
  my $pgcommand = "INSERT INTO two VALUES ('$joinkey', '$two_num', CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_status VALUES ('$joinkey', '1', 'Valid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_lastname VALUES ('$joinkey', '1', '$last', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO two_firstname VALUES ('$joinkey', '1', '$first', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  if ($mid) {
    $pgcommand = "INSERT INTO two_middlename VALUES ('$joinkey', '1', '$mid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n"; 
#     $result = $conn->exec( $pgcommand );
  }
  my $stdname = "$first_mid $last";
  $pgcommand = "INSERT INTO two_standardname VALUES ('$joinkey', '1', '$stdname', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
  print "$pgcommand\n";
#   $result = $conn->exec( $pgcommand );
  if ($lab_code) {
    $pgcommand = "INSERT INTO two_lab VALUES ('$joinkey', '1', '$lab_code', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n"; 
#   $result = $conn->exec( $pgcommand );
  }
  if ($country) {
    $pgcommand = "INSERT INTO two_country VALUES ('$joinkey', '1', '$country', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($email) {
    $pgcommand = "INSERT INTO two_email VALUES ('$joinkey', '1', '$email', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($city) {
    $pgcommand = "INSERT INTO two_city VALUES ('$joinkey', '1', '$city', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
  }
  if ($inst) {
    $pgcommand = "INSERT INTO two_institution VALUES ('$joinkey', '1', '$inst', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
    $pgcommand = "INSERT INTO two_street VALUES ('$joinkey', '1', '$inst', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
    print "$pgcommand\n";
#     $result = $conn->exec( $pgcommand );
    if ($street) {
      $pgcommand = "INSERT INTO two_street VALUES ('$joinkey', '2', '$street', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
      print "$pgcommand\n";
#       $result = $conn->exec( $pgcommand );
    }
  } else {
    if ($street) {
      $pgcommand = "INSERT INTO two_street VALUES ('$joinkey', '1', '$street', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );";
      print "$pgcommand\n";
#       $result = $conn->exec( $pgcommand );
    }
  }
  

#   my $mainphone; my $mainfax;
#   if ($area) {
#     if ($phone) { 
#       $mainphone = "$area $phone"; 
#       if ($ext) { $mainphone .= " $ext"; } }
#     if ($fax) { $mainfax = "$area $fax"; } }
#   print "M $mainphone\n";
#   print "F $mainfax\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";


__END__

