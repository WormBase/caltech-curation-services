#!/usr/bin/perl

# use the wpa_match.pm stuff to get all the valid papers, their abstracts, split into words,
# and look for case-insensitive matches to  gin_locus gin_molname gin_protein gin_seqname 
# gin_sequence gin_synonyms   for Kimberly.  2009 11 03


use strict;
use diagnostics;
use DBI;



my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my %keys_wpa; 

my %cdsToGene;

my $result;

&getLoci();

my %wpa_gene;
$result = $dbh->prepare( "SELECT * FROM wpa_gene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my ($wbg) = $row[1] =~ m/(WBGene\d+)/;
  if ($wbg) { $wpa_gene{$row[0]}{$wbg}++; }
}


my %wpas;
$result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wpas{$row[0]}++; }
    else { delete $wpas{$row[0]}; }
} # while (my @row = $result->fetchrow)

my %abstracts;
$result = $dbh->prepare( "SELECT * FROM wpa_abstract WHERE wpa_abstract IS NOT NULL AND wpa_abstract != '' ORDER BY wpa_timestamp ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  unless ($row[0]) { print "NO zero @row END ROW\n"; }
  unless ($row[1]) { print "NO one @row END ROW\n"; }
  if ($row[3] eq 'valid') { $abstracts{$row[0]}{$row[1]}++; }
    else { delete $abstracts{$row[0]}{$row[1]}; }
} # while (my @row = $result->fetchrow)

foreach my $joinkey (sort keys %wpas) {
  foreach my $abstract (sort keys %{ $abstracts{$joinkey} }) {
    &parseGenes('two1843', $joinkey, $abstract);
  } # foreach my $abstract (sort keys %{ $abstracts{$joinkey} })
} # foreach my $joinkey (sort keys %wpas)

sub getLoci {			# genes to all other possible names
  my @pgtables = qw( gin_locus gin_molname gin_protein gin_seqname gin_sequence gin_synonyms );
  foreach my $table (@pgtables) {					# updated to get values from postgres 2006 12 19
    my $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my $wbgene = 'WBGene' . $row[0];
      my $lcvalue = lc($row[1]);
      push @{ $cdsToGene{locus}{$lcvalue} }, $wbgene; 
  } }

  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }	# Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{sc}) { delete $cdsToGene{locus}{sc}; }
  if ($cdsToGene{locus}{gata}) { delete $cdsToGene{locus}{gata}; }
  if ($cdsToGene{locus}{et1}) { delete $cdsToGene{locus}{et1}; }
  if ($cdsToGene{locus}{rhoa}) { delete $cdsToGene{locus}{rhoa}; }
  if ($cdsToGene{locus}{tbp}) { delete $cdsToGene{locus}{tbp}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{trap240}) { delete $cdsToGene{locus}{traP240}; }
  if ($cdsToGene{locus}{'ap-1'}) { delete $cdsToGene{locus}{'ap-1'}; }
} # sub getLoci

sub parseGenes {
  my ($two_number, $joinkey, $abstract) = @_;
  if ($abstract =~ m/,/) { $abstract =~ s/,//g; }
  if ($abstract =~ m/\(/) { $abstract =~ s/\(//g; }
  if ($abstract =~ m/\)/) { $abstract =~ s/\)//g; }
  if ($abstract =~ m/;/) { $abstract =~ s/;//g; }
  my %filtered_loci;
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) {
    my $lcw = lc($word);
    if ($cdsToGene{locus}{$lcw}) { $filtered_loci{$word}++; } }
#   foreach my $word (@words) { if ($cdsToGene{locus}{$word}) { foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) { $filtered_loci{$wbgene}++; } } }	# this seems wrong 2006 10 10
  my %genes;
  foreach my $word (sort keys %filtered_loci) { 
    my $lcw = lc($word);
    my $wbgene = $cdsToGene{locus}{$lcw}[0];
    unless ($wpa_gene{$joinkey}{$wbgene}) {
      print "ADD $word WBGENE $wbgene WBPaper $joinkey\n";
    }
#     &addPg($two_number, $joinkey, 'wpa_gene', $lcw); 
  }
} # sub parseGenes

