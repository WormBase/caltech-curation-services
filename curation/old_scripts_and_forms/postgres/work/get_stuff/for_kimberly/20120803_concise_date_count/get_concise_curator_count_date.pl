#!/usr/bin/perl -w

# get con_curator_hst count by pgid by date (not timestamp)

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pgidToGene;
my $result = $dbh->prepare( "SELECT * FROM con_wbgene ORDER BY con_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgidToGene{$row[0]} = $row[1]; }

my %pgidCount;
$result = $dbh->prepare( "SELECT DISTINCT ON (joinkey, date) joinkey, CAST(con_timestamp as date) AS Date FROM con_curator_hst WHERE con_timestamp > '2007-09-01' ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pgidCount{$row[0]}{$row[1]}++; }

foreach my $pgid (sort {$a<=>$b} keys %pgidCount) {
  my $dateCount = scalar keys %{ $pgidCount{$pgid} };
  my $gene = '';
  if ($pgidToGene{$pgid}) { $gene = $pgidToGene{$pgid}; }
  print "$pgid\t$dateCount\t$gene\n";
} # foreach my $pgid (sort keys %pgidCount)

__END__
