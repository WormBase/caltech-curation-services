#!/usr/bin/env perl 

# get gene -> paper -> pmid -> datatypes  for uniprot for Kimberly.  2015 05 22
#
# Interactions changed to have 'ProteinProtein' instead of 'Physical'.  2022 01 12
#
# http://wiki.wormbase.org/index.php/UniProt_Paper_-_Gene_-_Data_Type



use strict;
use diagnostics;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my %pap;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { if ($row[0]) { $pap{"WBPaper$row[0]"} = $row[1]; } }


my $inDir = '/home2/acedb/cron/dump_from_ws/files/';
my $outfile = 'uniprot_paper_data';

open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

my %genes;
my @files = qw( GO_annotation Interaction RNAi Variation Expr_pattern Gene );
# my @files = qw( Variation );

$/ = "";
foreach my $file (@files) {
  my $start = time;
  my $infile = $inDir . 'WS' . $file . '.ace';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
    my @genes; my @paps; my $datatype = ''; my @paps2; my $datatype2 = '';
    if ($file eq 'GO_annotation') { 
      (@paps)  = $entry =~ m/Reference\s+"(WBPaper\d+)"/g;
      (@genes) = $entry =~ m/Gene\s+"(WBGene\d+)"/g;
      $datatype = 'GO'; }
    if ($file eq 'Interaction') { 
      next unless ($entry =~ m/ProteinProtein\t/); 
      (@paps)  = $entry =~ m/Paper\s+"(WBPaper\d+)"/g;
      (@genes) = $entry =~ m/Interactor_overlapping_gene\s+"(WBGene\d+)"/g;
      $datatype = 'PPI'; }
    if ($file eq 'RNAi') { 
      next unless ($entry =~ m/Phenotype\t/); 
      (@paps)  = $entry =~ m/Reference\s+"(WBPaper\d+)"/g;
      (@genes) = $entry =~ m/Gene\s+"(WBGene\d+)"/g;
      $datatype = 'Phenotype'; }
    if ($file eq 'Variation') { 		# needs clarification
#       next unless ($entry =~ m/Affects\t/); 
      (@genes) = $entry =~ m/Gene\s+"(WBGene\d+)"/g;
      my (@type_of_mutation) = qw( Substitution Insertion Deletion Inversion Tandem_duplication );
      my %temp; $datatype2 = 'Sequence';
      foreach my $mutation (@type_of_mutation) {
        my (@temp) = $entry =~ m/$mutation.*Paper_evidence\s+"(WBPaper\d+)"/g;
        foreach (@temp) { $temp{$_}++; }
      } # foreach my $mutation (@type_of_mutation)
      (@paps2) = sort keys %temp;
      (@paps)  = $entry =~ m/Reference\s+"(WBPaper\d+)"/g;
      $datatype = 'Phenotype'; }
    if ($file eq 'Expr_pattern') { 
      (@paps)  = $entry =~ m/Reference\s+"(WBPaper\d+)"/g;
      (@genes) = $entry =~ m/Gene\s+"(WBGene\d+)"/g;
      $datatype = 'Expression'; }
    if ($file eq 'Gene') { 
      ($genes[0])  = $entry =~ m/Gene : "(WBGene\d+)"/;
      my @subtags  = qw( Experimental_model Disease_relevance );
      my %filterPaps;
      foreach my $subtag (@subtags) {
        my (@temp) = $entry =~ m/$subtag\s+.*?Paper_evidence "(WBPaper\d+)"/g;
        foreach (@temp) { $filterPaps{$_}++; } }
      (@paps) = sort keys %filterPaps;
# Experimental_model       "DOID:10652" "Homo sapiens" Paper_evidence "WBPaper00033160"
# Disease_relevance
      $datatype = 'Disease'; }
    foreach my $gene (@genes) {
      foreach my $pap (@paps) {
        $genes{$gene}{$pap}{$datatype}++;
      } # foreach my $pap (@paps)
      foreach my $pap (@paps2) {
        $genes{$gene}{$pap}{$datatype2}++;
      } # foreach my $pap (@paps)
    } # foreach my $gene (@genes)
  } # while (my $entry = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  my $end = time;
  my $timeDiff = $end - $start;
  print qq($file took $timeDiff to process\n);
} # foreach my $file (@files)

foreach my $gene (sort keys %genes) {
  foreach my $pap (sort keys %{ $genes{$gene} }) {
    my $pmid  = 'nopmid';
    if ( $pap{$pap} ) { $pmid  = $pap{$pap}; }
    my $types = join";", sort keys %{ $genes{$gene}{$pap} };
    print OUT qq($gene\t$pap\t$pmid\t$types\n);
  } # foreach my $pap (sort keys %{ $genes{$gene} })
} # foreach my $gene (sort keys %genes)

close (OUT) or die "Cannot close $outfile : $!";

__END__

WSCDS.ace
WSExpression_cluster.ace
WSExpr_pattern.ace
WSFeature.ace
WSGene.ace
WSGO_annotation.ace
WSInteraction.ace
WSRNAi.ace
WSVariation.ace

