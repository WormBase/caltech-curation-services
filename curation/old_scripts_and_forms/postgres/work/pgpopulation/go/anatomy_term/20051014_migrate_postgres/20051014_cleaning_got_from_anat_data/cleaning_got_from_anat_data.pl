#!/usr/bin/perl -w

# Clean got_ tables from anatomy term data, since they've been migrated
# to the ant_ tables.  2005 10 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %anat;
my $result = $conn->exec( "SELECT * FROM ant_anatomy_term ;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    if ($row[0] =~ m/^0/) { $anat{$row[0]}++; } } }

my @PGparameters = qw(curator anatomy_term);
my @PGsubparameters = qw( goterm goid paper_evidence person_evidence goinference
                          goinference_two aoinference comment qualifier
			  qualifier_two similarity with with_two );

$anat{'abcd'}++;
$anat{'1'}++;
$anat{'asdf'}++;
$anat{'cgc3'}++;
$anat{'zk512.1'}++;
$anat{'1234567'}++;



# deleted got_bio_aoinference got_anatomy_term got_cell_aoinference got_mol_aoinference 
my @PGgottables = qw( got_bio_qualifier         got_cell_goinference_two  got_locus                     got_mol_qualifier
                      got_bio_qualifier_two     got_cell_goterm		  got_mol_qualifier_two
                      got_bio_comment           got_bio_similarity        got_cell_paper_evidence	got_mol_comment           got_mol_with
                      got_bio_dbtype            got_bio_with              got_cell_person_evidence	got_mol_dbtype            got_mol_with_two
                      got_bio_dbtype_two        got_bio_with_two          got_cell_qualifier		got_mol_dbtype_two        got_obsoleteterm
                      got_bio_goid              got_cell_qualifier_two	  got_mol_goid                  got_pro_paper_evidence
                      got_bio_goinference       got_cell_comment          got_cell_with			got_mol_goinference       got_protein
                      got_bio_goinference_two   got_cell_dbtype           got_cell_with_two		got_mol_goinference_two   got_provisional
                      got_bio_goterm            got_cell_dbtype_two       got_curator			got_mol_goterm            got_sequence
                      got_bio_paper_evidence    got_cell_goid             got_dbtype			got_mol_paper_evidence    got_synonym
                      got_bio_person_evidence   got_cell_goinference      got_goterm			got_mol_person_evidence   got_wbgene );

foreach my $pgtable (@PGgottables) {
  print "\n$pgtable\n";
  foreach my $joinkey (sort keys %anat) {
    print "JOINKEY $joinkey\n";
    my $result = $conn->exec( "SELECT * FROM $pgtable WHERE joinkey = '$joinkey' AND $pgtable != '' AND $pgtable IS NOT NULL;" );
    while (my @row = $result->fetchrow) { 
      if ($row[1]) { print "$pgtable\t$joinkey\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n"; }
    }
    $result = $conn->exec( "DELETE FROM $pgtable WHERE joinkey = '$joinkey';" );
  } # foreach my $joinkey (sort keys %anat)
} # foreach my $pgtable (@PGgottables)

