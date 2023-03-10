#!/usr/bin/perl -w

# Populate obo_ hgnc tables from Wen and Chris's SimpleMine HGNC files.  2020 12 03

# Don't forget to delete table data before repopulating
# Try writing the data to a file like :
# HGNC:100        id: HGNC:100\nAGR Gene ID: HGNC:100\nAGR Gene Name: ASIC1\nDescription: Exhibits acid-sensing ion channel activity. Involved in cellular response to pH; sensory perception of sour taste; and sodium ion transmembrane transport. Localizes to Golgi apparatus and integral component of plasma membrane.\nENSEMBL ID: ENSG00000110881\nNCBI ID: 41\nPANTHER ID: PTHR11690\nSpecies: Homo sapiens\nSynonym: ACCN2\nSynonym: ACCN2 variant 3\nSynonym: ASIC\nSynonym: ASIC1A\nSynonym: BNaC2\nSynonym: Cation channel, amiloride-sensitive, neuronal, 2\nSynonym: acid sensing (proton gated) ion channel 1\nSynonym: acid sensing ion channel 1\nSynonym: acid-sensing (proton-gated) ion channel 1\nSynonym: acid-sensing ion channel 1\nSynonym: acid-sensing ion channel 1a protein\nSynonym: amiloride-sensitive cation channel 2, neuronal\nSynonym: brain sodium channel 2\nSynonym: hBNaC2\nUniProtKB ID: F8VSK4\nWorm Ortholog: WB:WBGene00001465:flr-1\nWorm Ortholog: WB:WBGene00016064:acd-1\nWorm Ortholog: WB:WBGene00016066:acd-2\nWorm Ortholog: WB:WBGene00017879:acd-4
# and the copying the file into the table instead.


# disease, construct, phenotype, genotype


use strict;
use diagnostics;
use DBI;
use LWP::Simple;
use LWP;
use Crypt::SSLeay;				# for LWP to get https


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/obo_oa_ontologies/';
chdir ($directory) or die "Cannot chdir to $directory : $!";


# my @synFields = ('Gene ID', 'Gene Symbol', 'Gene Name', 'ENSEMBL ID', 'UniProtKB ID', 'PANTHER ID', 'Synonym');
my @synFields = ('Gene ID', 'Gene Symbol', 'ENSEMBL ID', 'UniProtKB ID', 'PANTHER ID', 'Synonym');
# my @allFields = ('Gene ID', 'Gene Symbol', 'Gene Name', 'NCBI ID', 'ENSEMBL ID', 'UniProtKB ID', 'PANTHER ID', 'Synonym', 'Description', 'Species', 'Worm Ortholog');
my @allFields = ('Gene ID', 'Gene Symbol', 'Gene Name', 'Description', 'Worm Ortholog', 'Synonym', 'NCBI ID', 'ENSEMBL ID', 'UniProtKB ID', 'PANTHER ID', 'Species');
my %synFields;
my %allFields;
foreach (@synFields) { $synFields{$_}++; }
foreach (@allFields) { $allFields{$_}++; }

my $genefile = '/home/acedb/wen/agrSimpleMine/sourceFile/HUMAN/GeneName.csv';
my $datafile = '/home/acedb/wen/agrSimpleMine/sourceFile/HUMAN/SimpleMineSourceData.csv';
my @files = ($genefile, $datafile);

my %data;
my %name;
my %syns;

foreach my $infile (@files) {
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $header = <IN>;
  chomp $header;
  my @headers = split/\t/, $header;
  while (my $line = <IN>) {
    chomp $line;
    my @line = split/\t/, $line;
    my $hgnc = $line[0];
    for my $i (0 .. $#line) {
      my $field = $headers[$i];
      if ($allFields{$field}) {
        if ($field eq 'Gene Name') { $name{$hgnc} = $line[$i]; }
        my $data = $line[$i];
        my @data = split/ \| /, $data;
        foreach my $entry (@data) {
          $data{$hgnc}{$field}{$entry}++;
          if ($synFields{$field}) {
            $syns{$hgnc}{$entry}++;
          } # if ($synFields{$field})
        } # foreach my $entry (@data)
      } # if ($allFields{$field})
    }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@files)

my @pgcommands;
my @pgcommands_name;
my @pgcommands_data;
my @pgcommands_syn;

foreach my $hgnc (sort keys %data) {
  my $termInfo = "id: $hgnc";
#   foreach my $field (sort keys %{ $data{$hgnc} })
  foreach my $field (@allFields) {
    foreach my $value (sort keys %{ $data{$hgnc}{$field} }) {
      $termInfo .= qq(\n$field: $value);
    } # foreach my $value (sort keys %{ $data{$hgnc}{$field} })
  } # foreach my $field (@allFields)
#   print qq($hgnc\t$termInfo\n);
  $termInfo =~ s/\'/''/g;
  my $name = $hgnc;
  if ($name{$hgnc}) { $name = $name{$hgnc}; }
  $name =~ s/\'/''/g;
#   push @pgcommands, qq(INSERT INTO obo_name_hgnc VALUES ('$hgnc', '$name'));
#   push @pgcommands, qq(INSERT INTO obo_data_hgnc VALUES ('$hgnc', '$termInfo'));
  push @pgcommands_name, qq(('$hgnc', '$name'));
  push @pgcommands_data, qq(('$hgnc', '$termInfo'));
}

foreach my $hgnc (sort keys %syns) {
  my $termInfo = "id: $hgnc";
  foreach my $value (sort keys %{ $syns{$hgnc} }) {
    $value =~ s/\'/''/g;
#     push @pgcommands, qq(INSERT INTO obo_syn_hgnc VALUES ('$hgnc', '$value'));
    push @pgcommands_syn, qq(('$hgnc', '$value'));
  } # foreach my $value (sort keys %{ $syns{$hgnc} })
#   print qq($hgnc\t$termInfo\n);
}


push @pgcommands, qq( DELETE FROM obo_name_hgnc; );
push @pgcommands, qq( DELETE FROM obo_data_hgnc; );
push @pgcommands, qq( DELETE FROM obo_syn_hgnc; );
my $name_commands = join",\n", @pgcommands_name;
my $data_commands = join",\n", @pgcommands_data;
my $syn_commands  = join",\n", @pgcommands_syn;
push @pgcommands, qq(INSERT INTO obo_name_hgnc VALUES $name_commands;);
push @pgcommands, qq(INSERT INTO obo_syn_hgnc VALUES $syn_commands;);
push @pgcommands, qq(INSERT INTO obo_data_hgnc VALUES $data_commands;);

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
  $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

