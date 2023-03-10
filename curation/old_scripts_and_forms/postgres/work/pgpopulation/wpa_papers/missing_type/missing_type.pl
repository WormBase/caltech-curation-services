#!/usr/bin/perl -w

# look at paper types, if any wm\d or ^wbg\d  wpa_identifiers don't have a type, make them a gazette / meeting respectively.  for Karen.  2009 02 12

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %type;

my $result = $conn->exec( "SELECT * FROM wpa_type ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $type{$row[0]} = $row[1]; }
      else { delete $type{$row[0]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'wm[0-9]' ORDER BY wpa_timestamp;" );
# while (my @row = $result->fetchrow) {
#   unless ($type{$row[0]}) {
#     my $command = "INSERT INTO wpa_type VALUES ('$row[0]', '3', NULL, 'valid', 'two712');";
#     print "$command\n";
# #     my $result2 = $conn->exec( $command );
#   }
# } # while (my @row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ '^wbg[0-9]' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  unless ($type{$row[0]}) {
    my $command = "INSERT INTO wpa_type VALUES ('$row[0]', '4', NULL, 'valid', 'two712');";
    print "$command\n";
    my $result2 = $conn->exec( $command );
  }
} # while (my @row = $result->fetchrow)

__END__

    $row[0] =~ s///g;
