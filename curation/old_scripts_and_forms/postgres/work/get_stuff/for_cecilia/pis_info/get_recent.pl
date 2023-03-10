#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pis;
my $result = $conn->exec( "SELECT joinkey FROM two_pis;" );
while (my @row = $result->fetchrow) { if ($row[0]) { $pis{$row[0]}++; } }

my %data;
$result = $conn->exec( "SELECT * FROM two_standardname ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
$result = $conn->exec( "SELECT * FROM two_email ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
$result = $conn->exec( "SELECT * FROM two_street ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
$result = $conn->exec( "SELECT * FROM two_city ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
$result = $conn->exec( "SELECT * FROM two_state ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
$result = $conn->exec( "SELECT * FROM two_post ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
$result = $conn->exec( "SELECT * FROM two_country ORDER BY joinkey, two_order;" );
while (my @row = $result->fetchrow) { if ($row[2]) { $data{$row[0]} .= "$row[2]\n"; } }
foreach my $joinkey (sort keys %pis) {
  print "$data{$joinkey}\n";
} # foreach my $joinkey (sort keys %pis)

__END__

