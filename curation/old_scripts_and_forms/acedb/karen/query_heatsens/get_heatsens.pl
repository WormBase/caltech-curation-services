#!/usr/bin/perl -w

# get app_ stuff for heat_sens and cold_sens for Karen.  2012 02 16

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;

my %varToGene;
my %ginLocus;

$result = $dbh->prepare( "SELECT * FROM gin_locus ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ginLocus{$row[0]} = $row[1]; } 

$result = $dbh->prepare( "SELECT * FROM obo_data_variation ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my (@genes) = $row[1] =~ m/WBGene(\d+)/g;
  my %genes; foreach (@genes) { $genes{$_}++; }
  @genes = keys %genes;
  $varToGene{$row[0]} = \@genes;
}

$result = $dbh->prepare( "SELECT * FROM app_heat_sens WHERE app_heat_sens = 'Heat Sensitive';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{hea} = $row[1]; } } 

$result = $dbh->prepare( "SELECT * FROM app_cold_sens WHERE app_cold_sens = 'Cold Sensitive';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{col} = $row[1]; } } 

$result = $dbh->prepare( "SELECT * FROM app_variation;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{var} = $row[1]; } } 

$result = $dbh->prepare( "SELECT * FROM app_term;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$row[0]}{phe} = $row[1]; } } 

my %lines;
foreach my $joinkey (sort keys %hash) {
  next unless ( ($hash{$joinkey}{hea}) || ($hash{$joinkey}{col}) );
  my ($pub, $gene, $var, $phe, $cold, $heat) = ('', '', '', '', '', '' ,'');
  if ($hash{$joinkey}{hea}) { $heat = 'Heat Sensitive'; }
  if ($hash{$joinkey}{col}) { $cold = 'Cold Sensitive'; }
  if ($hash{$joinkey}{var}) { $var = $hash{$joinkey}{var}; }
  if ($hash{$joinkey}{phe}) { $phe = $hash{$joinkey}{phe}; }
  if ($varToGene{$var}) {
      my $genesref = $varToGene{$var};
      my @genes = @$genesref;
      foreach my $gene (@genes) {
        if ($ginLocus{$gene}) { $pub = $ginLocus{$gene}; }
        $lines{"$pub\tWBGene$gene\t$var\t$phe\t$cold\t$heat\n"}++; } }
    else {
      $lines{"$pub\t$gene\t$var\t$phe\t$cold\t$heat\n"}++; }
} # foreach my $joinkey (sort keys %hash)

foreach my $line (sort keys %lines) {
  print $line;
}

__END__

