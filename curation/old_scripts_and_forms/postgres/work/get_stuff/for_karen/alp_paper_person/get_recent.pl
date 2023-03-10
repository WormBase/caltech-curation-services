#!/usr/bin/perl -w

# get allele phenotype connections that have both paper and person  2008 01 11

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;

my $result = $conn->exec( "SELECT * FROM alp_person ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $hash{$row[0]}{$row[1]}{person} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $hash{$row[0]}{$row[1]}{paper} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $allele (sort keys %hash) {
  foreach my $box (sort keys %{ $hash{$allele} }) {
    if ( ($hash{$allele}{$box}{person}) && ($hash{$allele}{$box}{paper}) ) {
      print "$allele $box $hash{$allele}{$box}{person} $hash{$allele}{$box}{paper}\n"; 
    } # if ( ($hash{$allele}{$box}{person}) && ($hash{$allele}{$box}{paper}) )
  } # foreach my $box (sort keys %{ $hash{$allele} })
} # foreach my $allele (sort keys %hash)

__END__

