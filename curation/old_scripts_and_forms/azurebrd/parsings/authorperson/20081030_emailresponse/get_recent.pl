#!/usr/bin/perl -w

# see how many people have been sent an email to confirm papers since a date,
# and how many of those verified.  2008 10 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $hash{possible}{$row[0]}{$row[2]} = $row[1]; } else { delete $hash{possible}{$row[0]}{$row[2]}; }
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM wpa_author_sent WHERE wpa_timestamp > '2008-10-01' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $hash{sent}{$row[0]}{$row[2]} = $row[1]; } else { delete $hash{sent}{$row[0]}{$row[2]}; } }
$result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE wpa_timestamp > '2008-10-01' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $hash{verified}{$row[0]}{$row[2]} = $row[1]; } else { delete $hash{verified}{$row[0]}{$row[2]}; } }

foreach my $aid (sort keys %{ $hash{sent} }) {
  foreach my $join (sort keys %{ $hash{sent}{$aid} }) {
    my $two = $hash{possible}{$aid}{$join};
    $hash{two}{$two}++;
    if ( $hash{verified}{$aid}{$join} ) { $hash{ver}{$two}++; } } }
my $tc = 0; my $vc = 0;
foreach my $two (sort keys %{ $hash{two} }) {
  $tc++; if ($hash{ver}{$two}) { $vc++; }
}
print "TC $tc VC $vc\n"; 

__END__

