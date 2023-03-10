#!/usr/bin/perl -w

# merge preparation data into treatment data, putting preparation before
# treatment.  keep timestamp if moving, assign current if merging.  2007 04 24

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT * FROM alp_preparation;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $join = $row[0];
    my $box = $row[1];
    my $col = $row[2];
    my $val = $row[3];
    my $time = $row[4];
    $hash{$join}{$box}{$col}{val} = $val;
    $hash{$join}{$box}{$col}{time} = $time;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $join (sort keys %hash) {
  foreach my $box (sort keys %{ $hash{$join} }) {
    foreach my $col (sort keys %{ $hash{$join}{$box} }) {
      my $val = $hash{$join}{$box}{$col}{val};
      my $time = $hash{$join}{$box}{$col}{time};
      my $result = $conn->exec( "SELECT * FROM alp_treatment WHERE joinkey = '$join' AND alp_box = '$box' AND alp_column = '$col' ORDER BY alp_timestamp DESC;" );
      my @row = $result->fetchrow;
      if ($row[0]) { 		# there's data
        my $tval = $row[3];
        my $ttime = $row[4];
        my $newval = "$val   $tval";
        my $command = "INSERT INTO alp_treatment VALUES ('$join', '$box', '$col', '$newval');";
        print "APPEND $val $time to $tval $ttime\n";
        print "$command\n";
        my $result2 = $conn->exec( $command );
      } else {
        my $command = "INSERT INTO alp_treatment VALUES ('$join', '$box', '$col', '$val', '$time');";
        print "Move $val $time to Treatment\n";
        print "$command\n";
        my $result2 = $conn->exec( $command );
      }
} } }

__END__

