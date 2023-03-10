#!/usr/bin/perl -w

# populate two_old_institution data based on two_institution data.  2008 07 16

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM two_institution WHERE two_order > 1;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    my $joinkey = $row[0];
    my $order = $row[1];
    $order--; $order--;
    my $olddata = $row[2];
    my $oldt = $row[3];
    my $curt = $row[4];
    my (@data) = split";", $olddata;
    foreach my $data (@data) {
      $data =~ s/^\s+//g; $data =~ s/\s+$//g;
      $data =~ s/^Formerly at //g;
      $data =~ s/^Lab formerly at //g;
      $data =~ s/'/''/g;
      $order++;
      my $command = "INSERT INTO two_old_institution VALUES ('$joinkey', '$order', '$data', '$oldt', '$curt');";
      print "$command\n";
    } # foreach my $data (@data)
#     print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

