#!/usr/bin/perl -w

# Take most alp_remark data and put into the new alp_obj_remark field instead.
# 2007 08 22

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %exist;
my $result = $conn->exec( "SELECT * FROM alp_remark ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    if ($row[2]) { $exist{$row[0]}{$row[1]}{data} = $row[2];
                   $exist{$row[0]}{$row[1]}{time} = $row[3]; }
      else { delete $exist{$row[0]}{$row[1]}{data};
             delete $exist{$row[0]}{$row[1]}{time}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $join (sort keys %exist) {
  foreach my $box (sort keys %{ $exist{$join} }) {
    my $data = $exist{$join}{$box}{data};
    my $time = $exist{$join}{$box}{time};
    if ($data) { 
      if ($join eq 'it150') { print "-- Skipping J $join B $box D $data T $time E\n"; next; }
      if ($join eq 'e408') { print "-- Skipping J $join B $box D $data T $time E\n"; next; }
      my $command = "INSERT INTO alp_obj_remark VALUES ('$join', '$box', '1', '$data', '$time');";
      print "$command\n";
# UNCOMMENT TO CHANGE PG
#       $result = $conn->exec( $command );
      $command = "INSERT INTO alp_remark VALUES ('$join', '$box', NULL, '$time');";
      print "$command\n";
# UNCOMMENT TO CHANGE PG
#       $result = $conn->exec( $command );
      print "-- J $join B $box D $data T $time E\n"; 
    } # if ($data)
  } # foreach my $box (sort keys %{ $exist{$join} })
} # foreach my $join (sort keys %exist)

__END__

