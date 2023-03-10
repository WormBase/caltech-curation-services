#!/usr/bin/perl -w

# populate reilly set for Daniela.  2021 09 15

# populated tazendra  2021 09 21

# need to update ontologies on mangolassi, copy this there, and see how it looks.

# can start with the Strains_list file, populate gene, strain, variation (for those that have it), transgene (for those that have it)
# then read Single_Neuron_names and populate anatomy (gene ties thee 2 files)
# then read 'All_info_by_gene' and populate the 'Reporter gene' and 'Genome editing' fields
# 
# Expression OA tables:
# ExprID: sequential
# Reference: WBPaper00060123
# Gene: Column B of sheet 'Single Neuron names'
# Anatomy: Column C onward of sheet 'Single Neuron names'
# Qualifier: Certain
# Qualifier LS: WBls:0000038
# Type: - 'Reporter gene' for genes that Have 'Fosmid' or 'Extrachromosomal fosmid' in column F in sheet 'All info by gene'
#  - 'Reporter gene' and 'Genome editing' for genes that have CRISPR in column F in sheet 'All info by gene'
# Transgene: Column D of file 'Strain list'
# Variation: Column E of file 'Strain list'
# Strain: Column B of file 'Strain list'
# Curator: WBPerson12028


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %anatomy;
$result = $dbh->prepare( "SELECT * FROM obo_name_anatomy " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0] =~ m/WBbt/) { $anatomy{$row[1]} = $row[0]; } }

my %strain;
$result = $dbh->prepare( "SELECT * FROM obo_name_strain " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0] =~ m/WBStrain/) { $strain{$row[1]} = $row[0]; } }

my %variation;
$result = $dbh->prepare( "SELECT * FROM obo_name_variation " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0] =~ m/WBVar/) { $variation{$row[1]} = $row[0]; } }

my %transgene;
$result = $dbh->prepare( "SELECT trp_name, trp_publicname FROM trp_name, trp_publicname WHERE trp_name.joinkey = trp_publicname.joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0] =~ m/WBTransgene/) { $transgene{$row[1]} = $row[0]; } }

my %wbgene;
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0] =~ m/^00/) { $wbgene{$row[1]} = "WBGene$row[0]"; } }

my $neuron_list = 'Single_Neuron_names.txt';
my %anat_not_found;
my %wbgeneToAnat;
open (IN, $neuron_list) or die "Cannot open $neuron_list : $!";
my $header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($class, $gene, @list) = split/\t/, $line;
  my %anat;
  next if ($list[0] eq 'No adult Neurons');
  foreach my $anat (@list) {
    if ($anat) {
      if ($anat eq 'AWCon') { $anat = 'AWC-ON'; }
      if ($anat eq 'AWCoff') { $anat = 'AWC-OFF'; }
      my $anat_tack = $anat . ' neuron';
      if ($anatomy{$anat}) { $anat{$anatomy{$anat}}++; }
        if ($anatomy{$anat}) { $anat{$anatomy{$anat}}++; }
          elsif ($anatomy{$anat_tack}) { $anat{$anatomy{$anat_tack}}++; }
          else { $anat_not_found{$anat}++; } }
  }
  my $anats = join'","', sort keys %anat;
  my $wbgene = '';
  $gene =~ s/\s+//g;
  if ($wbgene{$gene}) { $wbgene = $wbgene{$gene}; }
    else { print qq(Single_Neuron_names GENE $gene not found\n); }
  $wbgeneToAnat{$wbgene} = qq("$anats");
}
close (IN) or die "Cannot close $neuron_list : $!";
foreach my $anat (sort keys %anat_not_found) {
  print qq(ANATOMY $anat not found\n); }

my $info_list = 'All_info_by_gene.txt';
my %wbgeneToType;
open (IN, $info_list) or die "Cannot open $info_list : $!";
$header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($class, $gene, $domain, $genecons, $strain, $reagent, $expression, $previous) = split/\t/, $line;
  $gene =~ s/\s+//g;
  next unless $gene;
  next unless $reagent;
  my $wbgene = '';
  if ($wbgene{$gene}) { $wbgene = $wbgene{$gene}; }
    else { print qq(All_info_by_gene GENE $gene not found in $line\n); }
  if ( ($reagent eq 'Fosmid') ||
       ($reagent eq 'Extrachromosomal fosmid') ||
       ($reagent eq 'Extrachromosomal Fosmid') ||
       ($reagent eq 'Extrachromsomal Fosmid') ||
       ($reagent eq 'Fosmid and CRISPR') ) {
         $wbgeneToType{$wbgene} = '"Reporter_gene"'; }
    elsif ($reagent eq 'CRISPR') {
         $wbgeneToType{$wbgene} = '"Reporter_gene","Genome_editing"'; }
    else { print qq(REAGENT $reagent not found in $line\n); }
# Type: - 'Reporter gene' for genes that Have 'Fosmid' or 'Extrachromosomal fosmid' in column F in sheet 'All info by gene'
#  - 'Reporter gene' and 'Genome editing' for genes that have CRISPR in column F in sheet 'All info by gene'
}
close (IN) or die "Cannot close $info_list : $!";

sub getHighestExprId {          # look at all exp_name, get the highest number and return
  my $highest = 0;
  my $result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE exp_name ~ '^Expr'" ); $result->execute();
  while (my @row = $result->fetchrow()) { if ($row[0]) { $row[0] =~ s/Expr//; if ($row[0] > $highest) { $highest = $row[0]; } } }
  return $highest; }

sub getHighestPgid {                                    # get the highest joinkey from the primary tables
  my $datatype = 'exp';
  my @tables = qw( name curator );
  my $pgUnionQuery = "SELECT MAX(joinkey::integer) FROM ${datatype}_" . join" UNION SELECT MAX(joinkey::integer) FROM ${datatype}_", @tables;
  my $result = $dbh->prepare( "SELECT max(max) FROM ( $pgUnionQuery ) AS max; " );
  $result->execute(); my @row = $result->fetchrow(); my $highest = $row[0];
  return $highest;
} # sub getHighestPgid

my ($newPgid) = &getHighestPgid();                  # current highest pgid (joinkey)
my ($newExprId) = &getHighestExprId(); 

print qq(PGID $newPgid\n);
print qq(EXPR $newExprId\n);

my @pgcommands;
my $strain_list = 'Strain_list.txt';
open (IN, $strain_list) or die "Cannot open $strain_list : $!";
$header = <IN>;
# my $count = 0;
while (my $line = <IN>) {
  chomp $line;
  my ($gene, $strain, $allele, $transgene, $variation) = split/\t/, $line;
  $gene =~ s/\s+//g;
  next unless $gene;
#   $count++;
#   print qq($count\t$line\n);
#   if ($count == 1) {
#     my (@split) = split/\t/, $line;
#     foreach my $term (@split) {
#       print qq(TERM $term ET\n);
#     } # foreach my $term (@split)
#   }
#   last if ($count > 1);
  my ($wbgene, $wbstrain, $wbtransgene, $wbvar) = ('', '', '', '');
  if ($wbgene{$gene}) { $wbgene = $wbgene{$gene}; }
    else { print qq(GENE $gene not found\n); }
  if ($transgene) {
# print qq($count START TRIN $transgene END \n);
    if ($transgene{$transgene}) { $wbtransgene = $transgene{$transgene}; }
      elsif ($variation{$transgene}) { $wbvar = $variation{$transgene}; }
      else { print qq(TRANSGENE ${transgene} not found\n); } }
  if ($strain) {
    $strain =~ s/\s+//g;
    if ($strain{$strain}) { $wbstrain = $strain{$strain}; }
      else { print qq(STRAIN $strain not found\n); } }
  if ($variation) {
    if ($variation{$variation}) { $wbvar = $variation{$variation}; }
      else { print qq(VARIATION $variation not found\n); } }
# print qq($wbtransgene\n);
  my $curator = 'WBPerson12028';
  my $endogenous = 'Endogenous';
  my $qualifier = 'Certain';
  my $qualifier_ls = 'WBls:0000038';
  my $reference = '"WBPaper00060123"';
  my $anat = '';
  if ($wbgeneToAnat{$wbgene}) { $anat = $wbgeneToAnat{$wbgene}; }
  my $type = '';
  if ($wbgeneToType{$wbgene}) { $type = $wbgeneToType{$wbgene}; }

  $newPgid++;
  $newExprId++;
  &insertToPostgresTableAndHistory('exp_name', $newPgid, "Expr$newExprId");
  &insertToPostgresTableAndHistory('exp_paper', $newPgid, $reference);
  &insertToPostgresTableAndHistory('exp_gene', $newPgid, qq("$wbgene"));
  &insertToPostgresTableAndHistory('exp_qualifier', $newPgid, $qualifier);
  &insertToPostgresTableAndHistory('exp_qualifierls', $newPgid, qq("$qualifier_ls"));
  &insertToPostgresTableAndHistory('exp_curator', $newPgid, $curator);
  &insertToPostgresTableAndHistory('exp_endogenous', $newPgid, $endogenous);
  if ($anat) { &insertToPostgresTableAndHistory('exp_anatomy', $newPgid, $anat); }
  if ($type) { &insertToPostgresTableAndHistory('exp_exprtype', $newPgid, $type); }
  if ($wbtransgene) { &insertToPostgresTableAndHistory('exp_transgene', $newPgid, qq("$wbtransgene")); }
  if ($wbstrain) { &insertToPostgresTableAndHistory('exp_strain', $newPgid, qq("$wbstrain")); }
  if ($wbvar) { &insertToPostgresTableAndHistory('exp_variation', $newPgid, qq("$wbvar")); }

#   print qq(Gene\t$wbgene\n);
#   print qq(Strain\t$wbstrain\n);
#   print qq(Transgene\t$wbtransgene\n);
#   print qq(Variation\t$wbvar\n);
#   print qq(Anatomy\t$anat\n);
#   print qq(Type\t$type\n);
#   print qq(Qualifier\t$qualifier\n);
#   print qq(Qualifier LS\t$qualifier_ls\n);
#   print qq(Endogenous\t$endogenous\n);
#   print qq(Curator\t$curator\n);
#   print qq(Reference\t$reference\n);
#   print qq(\n);
}
close (IN) or die "Cannot close $strain_list : $!";

sub insertToPostgresTableAndHistory {           # to create new rows, it is easier to have this sub in multiple <mod>OA.pm files than change the database in the helperOA.pm
  my ($table, $joinkey, $newValue) = @_;
  my $returnValue = '';
  print qq( INSERT INTO $table VALUES ('$joinkey', '$newValue')\n);
# UNCOMMENT TO POPULATE
#   my $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
#   $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
#   $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
#   $result->execute() or $returnValue .= "ERROR, failed to insert to ${table}_hst &insertToPostgresTableAndHistory\n";
} # sub insertToPostgresTableAndHistory

# Reference: WBPaper00060123
# Gene: Column B of sheet 'Single Neuron names'
# Anatomy: Column C onward of sheet 'Single Neuron names'
# Qualifier: Certain
# Qualifier LS: WBls:0000038
# Type: - 'Reporter gene' for genes that Have 'Fosmid' or 'Extrachromosomal fosmid' in column F in sheet 'All info by gene'
#  - 'Reporter gene' and 'Genome editing' for genes that have CRISPR in column F in sheet 'All info by gene'
# Transgene: Column D of file 'Strain list'
# Variation: Column E of file 'Strain list'
# Strain: Column B of file 'Strain list'
# Curator: WBPerson12028

__END__

# DELETE stuff that was entered by date
  DELETE FROM exp_name WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_paper WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_gene WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_qualifier WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_qualifierls WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_curator WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_endogenous WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_anatomy WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_exprtype WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_transgene WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_strain WHERE exp_timestamp > '2021-09-21 10:00';
  DELETE FROM exp_variation WHERE exp_timestamp > '2021-09-21 10:00';

