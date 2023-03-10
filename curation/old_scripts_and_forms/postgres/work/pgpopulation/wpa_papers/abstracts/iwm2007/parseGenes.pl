#!/usr/bin/perl

# enter genes for abstracts that didn't go in with the main script for some
# reason.  2007 06 12

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&getLoci();
my %cdsToGene;

my $result = $conn->exec( "SELECT * FROM wpa_abstract WHERE wpa_timestamp ~ '2007-06-07 15:0';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my ($joinkey, $abstract, $order, $valid, $curator, $timestamp) = @row;
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#     print "J $joinkey AB $abstract\n";
      &parseGenes($curator, $joinkey, $abstract);
  } # if ($row[0])
} # while (@row = $result->fetchrow)

sub parseGenes {
  my ($curator, $joinkey, $abstract) = @_;
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my %filtered_loci;
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) {
    $word =~ s/,//g;
    if ($cdsToGene{locus}{$word}) { $filtered_loci{$word}++; } }
#   foreach my $word (@words) { if ($cdsToGene{locus}{$word}) { foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) { $filtered_loci{$wbgene}++; } } } # this seems wrong 2006 10 10
  foreach my $word (sort keys %filtered_loci) { 
#     print "Add $word to $joinkey\n";
    &addPg($curator, $joinkey, 'wpa_gene', $word); 
  }
} # sub parseGenes

sub addPg {
  my ($two_number, $joinkey, $pgtable, $word) = @_;
  my %filtered_gene;
  my $evidence = "'Inferred_automatically	\"Abstract read $word\"'";
  foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) {    # each possible wbgene that matches that word
    $filtered_gene{$wbgene}++ }
  foreach my $wbgene (sort keys %filtered_gene) {
    my $pm_value = $wbgene . "($word)";                      # wbgene(word)
    if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; }
    my $pg_command = "INSERT INTO $pgtable VALUES ('$joinkey', '$pm_value', $evidence, 'valid', '$two_number', CURRENT_TIMESTAMP);";
    my $result = $conn->exec( $pg_command );
    print "$pg_command\n";
  }
}

sub getLoci {                   # genes to all other possible names
  my @pgtables = qw( gin_locus gin_molname gin_protein gin_seqname gin_sequence gin_synonyms );
  foreach my $table (@pgtables) {                                       # updated to get values from postgres 2006 12 19
    my $result = $conn->exec( "SELECT * FROM $table;" );
    while (my @row = $result->fetchrow) {
      my $wbgene = 'WBGene' . $row[0];
      push @{ $cdsToGene{locus}{$row[1]} }, $wbgene; } }

  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }        # Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{SC}) { delete $cdsToGene{locus}{SC}; }
  if ($cdsToGene{locus}{GATA}) { delete $cdsToGene{locus}{GATA}; }
  if ($cdsToGene{locus}{eT1}) { delete $cdsToGene{locus}{eT1}; }
  if ($cdsToGene{locus}{RhoA}) { delete $cdsToGene{locus}{RhoA}; }
  if ($cdsToGene{locus}{TBP}) { delete $cdsToGene{locus}{TBP}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{TRAP240}) { delete $cdsToGene{locus}{TRAP240}; }
  if ($cdsToGene{locus}{'AP-1'}) { delete $cdsToGene{locus}{'AP-1'}; }
} # sub getLoci



__END__

