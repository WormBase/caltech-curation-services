#!/usr/bin/perl -w

# make invalid some papers that only have medline data.  if they have a
# duplicate wbpaper, then add their WBPaperID as a wpa_identifier for the other
# WBPaper with the same medline ID.   2008 03 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $infile = 'InvalidMedlinePaper.ace';
$/ = '';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  my $invflag = 0; my $goodflag = 0;
  if ($entry =~ m/Paper : \"WBPaper(\d+)\"/) { 
    my $invalid = $1;
    if ($entry =~ m/Medline_name\s+\"(\d+)\"/) { 
      my $medline = $1;
      my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier = 'med$medline';" );
      while (my @row = $result->fetchrow()) {
        my $joinkey = $row[0];
        if ($row[0] eq $invalid) { 
#               $invflag++; 
            my $wpa = $joinkey; $wpa++; $wpa--;
            my $command = "INSERT INTO wpa VALUES ('$joinkey', '$wpa', NULL, 'invalid', 'two101');";
            print "$command\n";
            my $result2 = $conn->exec( $command );
          }
          else { 
#             $goodflag++;
            my $command = "INSERT INTO wpa_identifier VALUES ('$joinkey', 'WBPaper$invalid', NULL, 'valid', 'two101');";
            print "$command\n";
            my $result2 = $conn->exec( $command );
          }
      } # while (my @row = $result->fetchrow())
#       print "P $invalid M $medline I $invflag G $goodflag E\n"; 
#       if ( ($invflag != 1) || ($goodflag != 1) ) { print "P $invalid M $medline I $invflag G $goodflag E\n";  }
  } }    
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

