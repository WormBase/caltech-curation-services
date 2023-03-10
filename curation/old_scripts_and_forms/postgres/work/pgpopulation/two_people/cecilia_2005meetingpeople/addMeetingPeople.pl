#!/usr/bin/perl

# Create new meeting people.  Change zips with 4 digits to have a zero in front,
# this might be wrong for non-US addresses.  Add US when no country.  2005 07 25

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my @tables = qw( two two_firstname two_middlename two_lastname two_standardname two_street two_city two_state two_post two_country two_institution two_email );
# foreach my $table (@tables) {
#   for my $count (3211 .. 5000) { 
#     my $joinkey = 'two' . $count;
#     my $result = $conn->exec( "DELETE FROM $table WHERE joinkey = '$joinkey'" );
#   }   
# } # foreach my $table (@tables)

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $result = $conn->exec( "SELECT two FROM two ORDER BY two DESC; " );
my @row = $result->fetchrow;
my $latest_two = $row[0];

# my $infile = 'iwm2005_1stBatch.txt';
my $infile = 'IWM_editados_2nd_batch.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
<IN>;					# skip first line
while (my $line = <IN>) {
  chomp($line);
  my ($first, $mid, $last, $full, $dept, $inst, $street, $city, $state, $zip, $prov, $country, $email) = split/\t/, $line;
  if ( ($last eq '') && ($first eq '') ) { print "BAD LINE $line\n"; next; }
  $latest_two++;
  my $joinkey = 'two' . $latest_two;
#   my $result = $conn->exec( "DELETE FROM two WHERE joinkey = '$joinkey'" );
  my $result = $conn->exec( "INSERT INTO two VALUES ('$joinkey', '$latest_two', CURRENT_TIMESTAMP)" );
  print OUT "my \$result = \$conn->exec( \"INSERT INTO two VALUES ('$joinkey', '$latest_two', CURRENT_TIMESTAMP) \" );\n"; 
  if ($first) { &addPg('two_firstname', $joinkey, $first); }
  if ($mid) { &addPg('two_middlename', $joinkey, $mid); }
  if ($last) { &addPg('two_lastname', $joinkey, $last); }
  if ($full) { &addPg('two_standardname', $joinkey, $full); }
  my $two_street = '';
  if ($dept) { $two_street .= "$dept\n"; }
  if ($inst) { $two_street .= "$inst\n"; }
  if ($street) { $two_street .= "$street\n"; }
  if ($two_street) { &addPg('two_street', $joinkey, $two_street); }
  if ($city) { &addPg('two_city', $joinkey, $city); }
  if ($state) { &addPg('two_state', $joinkey, $state); }
  if ($prov) { &addPg('two_state', $joinkey, $prov); }
  if ($zip) { &addPg('two_post', $joinkey, $zip); }
  if ($country) { &addPg('two_country', $joinkey, $country); } else { &addPg('two_country', $joinkey, 'United States of America'); }
  if ($inst) { &addPg('two_institution', $joinkey, $inst); }
  if ($email) { &addPg('two_email', $joinkey, $email); }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

close (OUT) or die "Cannot close $outfile : $!";

sub addPg {
  my ($table, $joinkey, $value) = @_;
#     my $result = $conn->exec( "DELETE FROM $table WHERE joinkey = '$joinkey'" );
  if ($value =~ m/\"/) { $value =~ s/\"//g; } if ($value =~ m/^\s+/) { $value =~ s/^\s+//g; } if ($value =~ m/\s+$/) { $value =~ s/\s+$//g; }
  if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  if ( ($table eq 'two_firstname') || ($table eq 'two_middlename') || ($table eq 'two_lastname') || 
       ($table eq 'two_standardname') || ($table eq 'two_post') || ($table eq 'two_state') ) {
    if ($value =~ m/\./) { $value =~ s/\.//g; } }
  if ($table eq 'two_post') { if ($value =~ m/^\d{4}$/) { $value = '0' . $value; } }
  if ($table ne 'two_street') {
    my $result = $conn->exec( "INSERT INTO $table VALUES ('$joinkey', 1, '$value', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" );
    print OUT "my \$result = \$conn->exec( \"INSERT INTO $table VALUES ('$joinkey', 1, '$value', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) \" );\n"; 
  } else {
    my (@lines) = split/\n/, $value; my $count = 0;
    foreach my $line (@lines) {
      $count++;
      my $result = $conn->exec( "INSERT INTO $table VALUES ('$joinkey', $count, '$line', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)" );
      print OUT "my \$result = \$conn->exec( \"INSERT INTO $table VALUES ('$joinkey', $count, '$line', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) \" );\n"; 
    } # foreach my $line (@lines)
  }
} # sub addPg

# FName	MName	LName	FullName	Dept	Inst	Street	City	State	Zip	Province	Country	Email
# Allison	Lynn	Abbott	Allison Lynn Abbott	Genetics	DartmouthMedical School	"Vail Building, 609"	Hanover	NH	3755			allison.abbott@dartmouth.edu
