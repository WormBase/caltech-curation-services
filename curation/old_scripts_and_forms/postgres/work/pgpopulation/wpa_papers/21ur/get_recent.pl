#!/usr/bin/perl -w

# add all (5355) 21ur locus names to paper 28915 for Anthony.  2008 06 13

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %locus;
my $result = $conn->exec( "SELECT * FROM gin_locus WHERE gin_locus ~ '21ur' ORDER BY gin_locus;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
#     $row[1] =~ s///g;
#     my ($num) = $row[1] =~ m/21ur-(\d+)/;
    $locus{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $curator = 'two1847';

foreach my $num (sort {$a <=> $b} keys %locus) {
  my $gene = "WBGene$num";
  my $command = "INSERT INTO wpa_gene VALUES ('00028915', '$gene', 'Person_evidence \"WBPerson1847\"', 'valid', '$curator', CURRENT_TIMESTAMP)";
  print "$command\n";
  $result = $conn->exec( $command );
}

__END__

