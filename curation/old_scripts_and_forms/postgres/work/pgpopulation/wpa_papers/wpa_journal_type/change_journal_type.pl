#!/usr/bin/perl -w

# use a %forceReview list of Paul approved journals, and convert all types to review if they're not already.  2009 05 14

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %journals;
my $result = $dbh->prepare( 'SELECT * FROM wpa_journal ORDER BY wpa_timestamp' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $journals{$row[1]}{$row[0]}++; }
      else { delete $journals{$row[1]}{$row[0]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %type;
$result = $dbh->prepare( 'SELECT * FROM wpa_type ORDER BY wpa_timestamp' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $type{$row[0]}{$row[1]}++; }
      else { delete $type{$row[0]}{$row[1]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %forceReview;

# paul generated list by pattern
$forceReview{"Current Trends in Membranes"}++;
$forceReview{"Current Trends in Microbiology"}++;
$forceReview{"Trends in Biochemical Sciences"}++;
$forceReview{"Trends in Biotechnology"}++;
$forceReview{"Trends in Biotechnology Supp"}++;
$forceReview{"Trends in Cell Biology"}++;
$forceReview{"Trends in Ecology & Evolution"}++;
$forceReview{"Trends in Endocrinology and Metabolism"}++;
$forceReview{"Trends in Endocrinology & Metabolism"}++;
$forceReview{"Trends in Genetics"}++;
$forceReview{"Trends in Glycoscience and Glycotechnology"}++;
$forceReview{"Trends in Glycosylation"}++;
$forceReview{"Trends in Immunology"}++;
$forceReview{"Trends in Microbiology"}++;
$forceReview{"Trends in Neurosciences"}++;
$forceReview{"Trends in Parasitology"}++;
$forceReview{"Trends in Pharmacological Sciences"}++;
$forceReview{"Annual Review of Biophysics & Bioengineering"}++;
$forceReview{"Annual Review of Cell and Developmental Biology"}++;
$forceReview{"Annual Review of Cell Biology"}++;
$forceReview{"Annual Review of Cell & Developmental Biology"}++;
$forceReview{"Annual Review of Genetics"}++;
$forceReview{"Annual Review of Genomics & Human Genetics"}++;
$forceReview{"Annual Review of Microbiology"}++;
$forceReview{"Annual Review of Neuroscience"}++;
$forceReview{"Annual Review of Pharmacology and Toxicology"}++;
$forceReview{"Annual Review of Physiology"}++;
$forceReview{"Annual Review of Phytopathology"}++;
$forceReview{"Nature Reviews Genetics"}++;
$forceReview{"Nature Reviews Molecular Cell Biology"}++;
$forceReview{"Nature Reviews Neuroscience"}++;
$forceReview{"Nature Reviews Immunology"}++;

# paul approved list
$forceReview{"Adv Genet"}++;
$forceReview{"Annu Rev Genet"}++;
$forceReview{"Annu Rev Physiol"}++;
$forceReview{"Annual Review of Cell and Developmental Biology"}++;
$forceReview{"Annual Review of Genetics"}++;
$forceReview{"Annual Review of Neuroscience"}++;
$forceReview{"Annual Review of Physiology"}++;
$forceReview{"Annual Review of Phytopathology"}++;
$forceReview{"BioEssays"}++;
$forceReview{"Bioessays"}++;
$forceReview{"Brief Funct Genomic Proteomic"}++;
$forceReview{"Curr Opin Genet Dev"}++;
$forceReview{"Curr Opin Neurobiol"}++;
$forceReview{"Current Genomics"}++;
$forceReview{"Current Opinion in Chemical Biology"}++;
$forceReview{"Current Opinion in Genetics & Development"}++;
$forceReview{"Current Opinion in Genetics and Development"}++;
$forceReview{"Current Opinion in Neurobiology"}++;
$forceReview{"Current Opinion in Neurology"}++;
$forceReview{"Current Opinion in Structural Biology"}++;
$forceReview{"Current Topics in Developmental Biology"}++;
$forceReview{"Cytokine and Growth Factor Reviews"}++;
$forceReview{"Genetic Maps"}++;
$forceReview{"Int Rev Neurobiol"}++;
$forceReview{"Methods Cell Biol"}++;
$forceReview{"Mol Neurobiol"}++;
$forceReview{"Nature Reviews Genetics"}++;
$forceReview{"Nature Reviews Neuroscience"}++;
$forceReview{"Parasitology Today"}++;
$forceReview{"Pflugers Arch"}++;
$forceReview{"Sci Aging Knowledge Environ"}++;
$forceReview{"Sci aging knowledge environ"}++;
$forceReview{"Semin Cell Dev Biol"}++;
$forceReview{"Seminars in Cell & Developmental Biology"}++;
$forceReview{"Seminars in Developmental Biology"}++;
$forceReview{"Trends Endocrinol Metab"}++;
$forceReview{"Trends Neurosci"}++;
$forceReview{"Trends Parasitol"}++;
$forceReview{"Trends in Cell Biology"}++;
$forceReview{"Trends in Ecology & Evolution"}++;
$forceReview{"Trends in Genetics"}++;
$forceReview{"Trends in Neurosciences"}++;
# $forceReview{"WormBook"}++;


my $papsOver30000 = 0;
foreach my $journal (sort keys %journals) {
  next unless ($forceReview{$journal});
  foreach my $paper (sort keys %{ $journals{$journal} }) {
#     my (@types) = keys %{ $type{$paper} };
#     if (scalar @types > 1) { print "ERR $journal $paper has multiple types @types\n"; next; }
#       else { print "$journal P $paper T $types[0]\n"; }
    foreach my $type (keys %{ $type{$paper} }) {
      if ($type ne '2') {
        if ($paper > 30000) { $papsOver30000++; }
# UNCOMMENT TO execute changes (invalid old type, valid review type)
#         $result = $dbh->do( "INSERT INTO wpa_type VALUES ('$paper', '$type', NULL, 'invalid', 'two625')" );
#         $result = $dbh->do( "INSERT INTO wpa_type VALUES ('$paper', '2', NULL, 'valid', 'two625')" );
        print "$paper\t$type\n";
    } }
  } # foreach my $paper (sort keys %{ $journals{$journal} })
} # foreach my $journal (sort keys %journals)

print "$papsOver30000 papers over 00030000\n";

