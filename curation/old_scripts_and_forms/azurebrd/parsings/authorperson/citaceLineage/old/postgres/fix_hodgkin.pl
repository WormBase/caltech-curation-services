#!/usr/bin/perl -w
#
# Somehow two_othername fields of data sent by Hodgkin don't correspond to the
# two_number.  This was probably created when adding the extra field
# (two_sentname) to the two_lineage table (dumped data, changed it, read it
# again)
# 
# While the two_othername field doesn't dump into citace it's bad for it to 
# be wrong, so spent some time fixing it.  2003 10 28

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $outfile = 'outfile.fix_hodgkin';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $result = $conn->exec( "SELECT two_number, COUNT(*) FROM two_lineage WHERE two_timestamp ~ '2003-10-27 15' AND 2 > '1' GROUP BY two_number ORDER BY 2 DESC;" );
while (my @row = $result->fetchrow) {
  if (($row[1] < 10) && ($row[1] > 1)) {
    print OUT "two_number $row[0]\n"; 
    my $result2 = $conn->exec( "SELECT two_othername FROM two_lineage WHERE two_timestamp ~ '2003-10-27 15' AND two_number = '$row[0]' AND two_role !~ 'with'" );
    my @row2 = $result2->fetchrow;
    print OUT "NAME = $row2[0]\n";
    if ($row2[0]) { my $result3 = $conn->exec( "UPDATE two_lineage SET two_othername = '$row2[0]' WHERE two_number = '$row[0]' AND two_timestamp ~ '2003-10-27 15';" ); }
      else { print "NO NAME $row[0]\n"; }
  }
} # while (my @row = $result->fetchrow)
close (OUT) or die "Cannot close $outfile : $!";

# NO NAME two1651
# NO NAME two1791
# NO NAME two411
# These had no name and were fixed manually
