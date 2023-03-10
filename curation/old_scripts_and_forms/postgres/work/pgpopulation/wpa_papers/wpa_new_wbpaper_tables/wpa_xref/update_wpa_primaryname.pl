#!/usr/bin/perl

# Take citace dump (from updated but not uploaded citace from 2005 06 17)
# Get data from wpa_xref table, create entry in wpa_primarytable.
# Take this primary data and see if it's a primary name in citace.
# If it's not, update wpa_primaryname to 'no' ;  then check if it exists in
# citace at all and print out whether it's just not primary or if it's also
# missing in citace.  UPDATE as necessary in the first pass.  2005 06 17
#
# Eimear says the paper2wbpaper.txt entries that don't exist in citace 
# at all are wrong and to be deleted.  Done.  2005 06 17


use strict;
use diagnostics;
use Pg;

my %cit_primary;
my %pg_primary;
my %not_primary;
my %xref;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "update_primary.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

$/ = '';
my $infile = 'citace_papers_20050617.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/Paper : "(WBPaper\d+)"/) { $cit_primary{$1}++; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";
undef $/;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $whole_citace = <IN>;	# slurp
close (IN) or die "Cannot close $infile : $!";

my $result = $conn->exec( "SELECT * FROM wpa_xref;" );
while (my @row = $result->fetchrow) { 
  if ($row[0]) { $xref{$row[0]} .= "\t$row[1]"; }
} # while (my @row = $result->fetchrow)

# This populates the wpa_primaryname table.
# foreach my $joinkey (sort keys %xref) {
#   my $result2 = $conn->exec( "INSERT INTO wpa_primaryname VALUES ('$joinkey', 'yes'); ");
# } # foreach my $joinkey (sort keys %xref)

$result = $conn->exec( "SELECT joinkey FROM wpa_primaryname;" );
while (my @row = $result->fetchrow) { 
  $pg_primary{$row[0]}++; 
  unless ($cit_primary{$row[0]}) { 
    $not_primary{$row[0]}++; 
# This sets those which are not primary as 'no' in wpa_primaryname.
#     my $result2 = $conn->exec( "UPDATE wpa_primaryname SET wpa_primaryname = 'no' WHERE joinkey = '$row[0]' ;" );
    if ($whole_citace =~ m/$row[0]/) { print OUT "Not primary $row[0]\n"; }
    else { 
      print OUT "Not in citace, delete from wpa_xref $row[0] $xref{$row[0]}\n"; 
# This deletes mappings that are not in citace at all from the wpa_xref tables.
#       my $result2 = $conn->exec( "DELETE FROM wpa_xref WHERE joinkey = '$row[0]' ;" );
    }
  }
}

