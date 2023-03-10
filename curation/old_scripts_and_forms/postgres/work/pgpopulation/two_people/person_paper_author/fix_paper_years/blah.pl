#!/usr/bin/perl 

# take papers from acedb and their years.  create insert file
# for those papers that are already in postgresql.  2003 07 03
 

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %year;
my %paper;

my $infile = "paper_year.ace";
$/ = "";
open (IN, "<$infile");
while (my $entry = <IN>) {
  my ($num, $year);
  if ($entry =~ m/Paper : \"\[(.*)\]\"/) { $num = $1; }
  if ($entry =~ m/Year\s+(.*)/) { $year = $1; }
  $year{$num} = $year;
}
close (IN);


my $result = $conn->exec( "SELECT * FROM pap_paper;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    my $joinkey = $row[0];
    $row[1] =~ s///g;
    my $paper = $row[1];
    $paper{$joinkey} = $paper;
  } # if ($row[0])
} # while (my @row = $result->fetchrow)

foreach my $num (sort keys %year) {
  if ($paper{$num}) { 
#     my $result = $conn->exec( "INSERT INTO pap_year VALUES ('$num', '$year{$num}') ); 
#   }
    print "\$result = \$conn->exec( \"INSERT INTO pap_year VALUES (\'$num\', \'$year{$num}\');\" );\n"; }
#   else { 
#     print "NO PAPER $num\n"; }
} # foreach my $year (sort keys %year)

