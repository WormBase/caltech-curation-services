#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT DISTINCT(joinkey) FROM alp_phenotype WHERE alp_phenotype IS NOT NULL ORDER BY joinkey;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $joinkey = $row[0];
#     print "Look at $joinkey\n";
    my $result2 = $conn->exec( "SELECT * FROM alp_term WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
    %hash = ();
    while (my @row2 = $result2->fetchrow) {
      $hash{$row2[1]}{$row2[2]} = $row2[3];
    }
    foreach my $box (sort keys %hash) {
      foreach my $column (sort keys %{ $hash{$box}} ) {
        unless ($hash{$box}{$column}) { print "Allele $joinkey has no phenotype term on box $box column $column .\n"; }
      } # foreach my $column (sort keys %{ $hash{$box}} )
    } # foreach my $box (sort keys %hash)
    $result2 = $conn->exec( "SELECT alp_term FROM alp_term WHERE joinkey = '$joinkey' ORDER BY alp_timestamp DESC;" );
    my @row2 = $result2->fetchrow;
    unless ($row2[0]) { print "Allele $joinkey has no phenotype terms at all\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

