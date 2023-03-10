#!/usr/bin/perl -w

# rename from neuro2008aging14690 to aging2008aging14690 style names.  for Andrei.  2009 02 08


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT wpa_identifier FROM wpa_identifier WHERE wpa_identifier ~ 'neuro' AND wpa_identifier ~ 'aging';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    print "$row[0]\n";
    my $newname = $row[0];
    $newname =~ s/neuro/aging/g;
# UNCOMMENT TO MAKE CHANGES
#     my $result2 = $conn->exec( "UPDATE wpa_identifier SET wpa_identifier = '$newname' WHERE wpa_identifier = '$row[0]';" );
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

