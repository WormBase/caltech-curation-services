#!/usr/bin/perl

# Enter data from horvitz from his word .doc file  2003 10 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $infile = 'Horvitz_10_8_03.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp ($line);
  if ($line) {
    my ($name, $role, $y1, $y2); 
    my @line = split/\t/, $line;
    if ($line[0]) { $name = $line[0]; }
    if ($line[1]) { $role = $line[1]; }
    if ($line[2]) { $y1 = $line[2]; }
    if ($line[3]) { $y2 = $line[3]; }
    if ($y1) { $y1 = "\'$y1\'"; } else { $y1 = "NULL"; }
    if ($y2) { $y2 = "\'$y2\'"; } else { $y2 = "NULL"; }
    my ($last, $first) = split/, /, $name;
#     print "two268\tBob Horvitz\t$first $last\t\\N\t$role\t$y1\t$y2\tBob Horvitz\n";
#     print "\\N\t$first $last\tBob Horvitz\t$two268\twith$role\t$y1\t$y2\tBob Horvitz\n";
    print "INSERT INTO two_lineage VALUES ('two268', 'Bob Horvitz', '$first $last', NULL, '$role', $y1, $y2, 'Bob Horvitz', CURRENT_TIMESTAMP); \n";
    print "INSERT INTO two_lineage VALUES (NULL, '$first $last', 'Bob Horvitz', 'two268', 'with$role', $y1, $y2, 'Bob Horvitz', CURRENT_TIMESTAMP); \n";

    my $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two268', 'Bob Horvitz', '$first $last', NULL, '$role', $y1, $y2, 'Bob Horvitz', CURRENT_TIMESTAMP);" );
    $result = $conn->exec( "INSERT INTO two_lineage VALUES (NULL, '$first $last', 'Bob Horvitz', 'two268', 'with$role', $y1, $y2, 'Bob Horvitz', CURRENT_TIMESTAMP);" );

#     $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two$main', '$hash{$key}', 'two$key', 'with$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21');" );
#     $result = $conn->exec( "INSERT INTO two_lineage VALUES ('two$key', '$hash{$key}', 'two$main', '$others{$key}', NULL, NULL, 'Original - Andrew Hallman', '2003-08-21')" );
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

