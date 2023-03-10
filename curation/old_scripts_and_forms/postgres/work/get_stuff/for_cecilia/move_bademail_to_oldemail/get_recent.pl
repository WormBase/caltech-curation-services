#!/usr/bin/perl -w
#
# Get list of emails from Cecilia that bounced when sending emails to everyone, then look for them
# in two_email, find the highest two_order in two_old_email for that joinkey, then append the
# address to the two_old_email table (new entry), and delete from the two_email table.
# 2004 05 18

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $infile = 'email_to_oldemail';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  if ($_ =~ m/\w/) { 
    my $oldemail = $_;
    my $result = $conn->exec( "SELECT joinkey FROM two_email WHERE two_email ~ \'$oldemail\';" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        my $joinkey = $row[0];
#         print "-=$oldemail=-\n";
        my $result2 = $conn->exec( "SELECT two_order FROM two_old_email WHERE joinkey = \'joinkey\' ORDER BY two_order DESC;" );
        my @row2 = $result2->fetchrow;
        my $order = $row2[0];
        $order++;
        $result2 = $conn->exec( "INSERT INTO two_old_email VALUES (\'$joinkey\', \'$order\', \'$oldemail\', CURRENT_TIMESTAMP);" );
        $result2 = $conn->exec( "DELETE FROM two_email WHERE two_email ~ \'$oldemail\';" );
      } # if ($row[0])
    } # while (my @row = $result->fetchrow)
  } # if ($_)
} # while (<IN>)
 
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";

