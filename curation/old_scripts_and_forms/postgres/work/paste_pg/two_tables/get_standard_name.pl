#!/usr/bin/perl -w

# To create full data set ./get_person_ace.pl > full_person.ace
# fixed Fax entries that had an extra \tOther_phone in them
# added &left_fieldPrint(); for those who have left the field
# added ``AND two IS NOT NULL'' to filter those that do not
# wish to be in wormbase.   2002 12 19
#
# Updated to have a delete_Person.ace file to append to beginning
# of file for next time, to delete entries before inserting new
# ones.  Fixed spaces at end or beginning of entries.  Fixed
# middlename problem that wasn't outputting some standard_names
# because they contained the word NULL.  2003 02 20
#
# Added two_wormbase_comment for comments that go to wormbase.
# 2003 02 28

use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $highest_two_val = '3000';
my $lowest_two_val = '0';

my $result;
for (my $i = $lowest_two_val; $i < $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
    # added two IS NOT NULL because there are three people that do not want to be displayed
  $result = $conn->exec( "SELECT * FROM two WHERE joinkey = '$joinkey' AND two IS NOT NULL;" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 				# if two exists
#       print "Person\tWBPerson$i -O \"$row[2]\"\n"; 
      &namePrint($joinkey);
#       print "\n";  				# divider between Persons
    }
  }
} # for (my $i = 0; $i < $highest_two_val; $i++)


sub namePrint {
  my $joinkey = shift;
  my $firstname; my $lastname; my $thestandard_name; 
  my $timefirst; my $timelast; my $timestamp;
  $result = $conn->exec ( "SELECT * FROM two_firstname WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow;
  if ($row[3]) {
    $firstname = $row[2];
    $timefirst = $row[3];
    if ($firstname !~ m/NULL/) { 
      $firstname =~ s/\s+/ /g; $firstname =~ s/^\s+//g; $firstname =~ s/\s+$//g; }
  }
  $result = $conn->exec ( "SELECT * FROM two_lastname WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) { 
    $lastname = $row[2];
    $timelast = $row[3];
    if ($lastname !~ m/NULL/) { 
      $lastname =~ s/\s+/ /g; $lastname =~ s/^\s+//g; $lastname =~ s/\s+$//g; }
  }
  $thestandard_name = $firstname . " " . $lastname;
  my $ftime = $timefirst;
  my $ltime = $timelast;
  ($ftime) = $ftime =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
  $ftime =~ s/\D//g;
  ($ltime) = $ltime =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
  $ltime =~ s/\D//g;
  if ($ftime > $ltime) { $timestamp = $timefirst; } else { $timestamp = $timelast; }
  $result = $conn->exec ( "INSERT INTO two_thestandardname VALUES ('$joinkey', '1', '$thestandard_name', '$timestamp');" );
  print "\$result = \$conn->exec ( \"INSERT INTO two_thestandardname VALUES ('$joinkey', '1', '$thestandard_name', '$timestamp');\" );\n";
} # sub namePrint	

