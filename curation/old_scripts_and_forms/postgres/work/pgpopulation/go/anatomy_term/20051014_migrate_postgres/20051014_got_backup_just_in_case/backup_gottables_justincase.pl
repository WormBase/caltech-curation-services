#!/usr/bin/perl -w

# back up all the got tables in case something gets lost while creating
# anatomy term tables and separating the data.  2005 10 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %anat;
my $result = $conn->exec( "SELECT * FROM got_anatomy_term WHERE got_anatomy_term IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $anat{$row[0]}++; } }

my @PGparameters = qw(curator anatomy_term);
my @PGsubparameters = qw( goterm goid paper_evidence person_evidence goinference
                          goinference_two aoinference comment qualifier
			  qualifier_two similarity with with_two );

my @PGgottables = qw( got_anatomy_term          got_bio_qualifier         got_cell_goinference_two	got_locus                 got_mol_qualifier
                      got_bio_aoinference       got_bio_qualifier_two     got_cell_goterm		got_mol_aoinference       got_mol_qualifier_two
                      got_bio_comment           got_bio_similarity        got_cell_paper_evidence	got_mol_comment           got_mol_with
                      got_bio_dbtype            got_bio_with              got_cell_person_evidence	got_mol_dbtype            got_mol_with_two
                      got_bio_dbtype_two        got_bio_with_two          got_cell_qualifier		got_mol_dbtype_two        got_obsoleteterm
                      got_bio_goid              got_cell_aoinference      got_cell_qualifier_two	got_mol_goid              got_pro_paper_evidence
                      got_bio_goinference       got_cell_comment          got_cell_with			got_mol_goinference       got_protein
                      got_bio_goinference_two   got_cell_dbtype           got_cell_with_two		got_mol_goinference_two   got_provisional
                      got_bio_goterm            got_cell_dbtype_two       got_curator			got_mol_goterm            got_sequence
                      got_bio_paper_evidence    got_cell_goid             got_dbtype			got_mol_paper_evidence    got_synonym
                      got_bio_person_evidence   got_cell_goinference      got_goterm			got_mol_person_evidence   got_wbgene );

foreach my $pgtable (@PGgottables) { 
  my $result = $conn->exec( "COPY $pgtable TO '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051015_got_backup_just_in_case/$pgtable.pg'; " );
} 

