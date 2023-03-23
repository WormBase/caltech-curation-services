#!/usr/bin/perl -w

# map neurons to genes. for Daniela, for Oliver Hobert.  2014 10 17

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my %anatomy;
my $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy WHERE joinkey NOT IN (SELECT joinkey FROM obo_data_anatomy WHERE obo_data_anatomy ~ 'obsolete')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $anatomy{$row[1]} = $row[0]; } }

my %locus;
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $locus{$row[0]} = $row[1]; } }


my $outfile = 'List_with_genes.txt';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

my $infile = 'List.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($a, $neuron, $b, $c, $d) = split/\t/, $line;
  my $wbbt = '';
  my $wbgenes = '';
  my $loci = ''; my @loci = ();
  if ($anatomy{$neuron}) { $wbbt = $anatomy{$neuron}; }
  if ($wbbt) {
        my %allGenes;
        $result = $dbh->prepare( "SELECT * FROM exp_gene WHERE joinkey IN (SELECT joinkey FROM exp_endogenous) AND joinkey IN (SELECT joinkey FROM exp_anatomy WHERE exp_anatomy ~ '$wbbt') AND ( joinkey IN (SELECT joinkey FROM exp_qualifier WHERE exp_qualifier = 'Certain' OR exp_qualifier = 'Partial') OR joinkey NOT IN (SELECT joinkey FROM exp_qualifier) ) AND joinkey IN (SELECT joinkey FROM exp_name WHERE exp_timestamp > '2014-11-01');" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        while (my @row = $result->fetchrow) { 
          if ($row[1] =~ m/WBGene(\d+)/) {
            my (@genes) = $row[1] =~ m/WBGene(\d+)/g; 
            foreach (@genes) { $allGenes{$_}++; } } }
        my @wbgenes; 
        foreach my $geneNum (sort keys %allGenes) {
          push @wbgenes, "WBGene$geneNum";
          if ($locus{$geneNum}) { push @loci, $locus{$geneNum}; }
            else { push @loci, "WBGene$geneNum"; } }
        $wbgenes = join", ", @wbgenes;
        $loci = join", ", @loci;
      }
    else { $wbbt = 'no wbbt found'; }
  my @line = ("$a", "$neuron", "$b", "$c", "$d", "$wbbt", "$loci", "$wbgenes");
  foreach (@loci) { push @line, $_; }
  my $out = join"\t", @line;
  print OUT "$out\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

close (OUT) or die "Cannot close $outfile : $!";

__END__

ADA	ADAL	Glu	AB.plapaaaapp	Ring interneuron	
	ADAR	Glu	AB.prapaaaapp	Ring interneuron			
ADE	ADEL	DA	AB.plapaaaapa	"Anterior deirid, sensory neuron"			
	ADER	DA	AB.prapaaaapa	"Anterior deirid, sensory neuron"			
