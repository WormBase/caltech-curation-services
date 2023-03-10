#!/usr/bin/perl 

# script to rename joinkeys in got_tables.  some loci were entered under a different name
# (synonym) and should be updated to the main 3-letter name.  below are all the relevant
# got tables, and a hash of the wrong joinkey and the new joinkey.  2004 10 06

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");      # connect to postgres database
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( 
got_curator
got_locus
got_sequence
got_synonym
got_protein
got_wbgene
got_bio_goterm
got_bio_goid
got_bio_paper_evidence
got_bio_person_evidence
got_bio_goinference
got_bio_dbtype
got_bio_with
got_bio_qualifier
got_bio_goinference_two
got_bio_dbtype_two
got_bio_with_two
got_bio_qualifier_two
got_bio_similarity
got_bio_comment
got_cell_goterm
got_cell_goid 
got_cell_paper_evidence
got_cell_person_evidence
got_cell_goinference
got_cell_dbtype
got_cell_with 
got_cell_qualifier
got_cell_goinference_two
got_cell_dbtype_two
got_cell_with_two
got_cell_qualifier_two
got_cell_similarity
got_cell_comment
got_mol_goterm
got_mol_goid
got_mol_paper_evidence
got_mol_person_evidence
got_mol_goinference
got_mol_dbtype
got_mol_with
got_mol_qualifier
got_mol_goinference_two
got_mol_dbtype_two
got_mol_with_two
got_mol_qualifier_two
got_mol_similarity
got_mol_comment
);

my %joinkeys = (
  'Bip' => 'obr-3'
#   'adm-1' => 'unc-71'
#   'cdc25.1' => 'cdc-25.1', 
#   'T14G8.1' => 'chd-3', 
#   'coh-2' => 'scc-1', 
#   'cup-10' => 'mtm-9', 
#   'cup-6' => 'mtm-6', 
#   'eca-39' => 'bcat-1', 
#   'lad-1' => 'sax-7', 
#   'lpb-8' => 'lbp-8', 
#   'mab-18' => 'vab-3', 
#   'son-1' => 'hmg-1.2'
);

foreach my $joinkey (sort keys %joinkeys) {
  foreach my $table (@tables) {
#     my $result = $conn->exec( "UPDATE $table SET got_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\';" );
#     $result = $conn->exec( "UPDATE $table SET joinkey = \'$joinkeys{$joinkey}\' WHERE joinkey = \'$joinkey\';" );
    print "UPDATE $table SET got_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\';\n";
    print "UPDATE $table SET joinkey = \'$joinkeys{$joinkey}\' WHERE joinkey = \'$joinkey\';\n";
  }
}
  
__END__


# # my %hash;
# # foreach my $table (@tables2) {
# #   my $result = $conn->exec( "SELECT * FROM $table;" );
# #   while ( my @row = $result->fetchrow ) {
# #     my $stuff = join"\", \"", @row;
# #     $stuff = "INSERT INTO $table VALUE ( \"$stuff\" );";
# # #     print "STUFF $stuff\n";
# #     $hash{$stuff}++;
# #   }
# # } # foreach my $table (@tables2)
# # 
# # foreach my $entries (sort keys %hash) {
# #   if ($hash{$entries} > 1) { print "DELETE $entries CREATE $entries\n"; }
# # } # foreach my $entries (sort keys %hash)
# 
# my @tables = qw( got_locus got_sequence got_protein got_curator got_synonym two_contactdata two_wormbase_comment cur_geneinteractions two_standardname two_pis phe_curator phe_checked_out phe_reference phe_definition cur_microarray phe_evi_similarity_evidence phe_evi_cgc_data_submission phe_evi_paper_evidence phe_evi_person_evidence phe_evi_author_evidence phe_evi_pmid_evidence phe_evi_accession_evidence phe_evi_protein_id_evidence phe_evi_go_inference_type phe_asp_type phe_asp_attribute phe_asp_value phe_asp_qualifier phe_synonym phe_description phe_evidence phe_assay_type phe_assay phe_assay_condition phe_remark phe_other phe_go_term phe_anatomy phe_life_stage phe_specialisation_of phe_generalisation_of phe_consist_of phe_part_of phe_equivalent_to phe_similar_to phe_rnai phe_locus phe_allele phe_strain phe_comment pha_curator pha_checked_out pha_description pha_assayphe pha_specialof pha_generalof pha_consistof pha_partof pha_equivto pha_similarto pha_comment pha_reference pha_evi_paper_evidence pha_evi_person_evidence pha_evi_author_evidence pha_evi_similarity_evidence pha_evi_pmid_evidence pha_evi_accession_evidence pha_evi_protein_id_evidence pha_evi_cgc_data_submission pha_evi_go_inference_type con_curator con_checked_out con_lifestage con_strain con_preparation con_temperature con_genotype con_other con_contains con_containedin con_precedes con_follows con_reference con_remark con_comment two_hide eim_timestamps kim_paperlocus ref_genes ref_cgcgenedeletion kim_papersequence ref_xrefmed two_lineage ggn_justification ggn_geneclass_desc ggn_geneclass_phen ggn_lab ggn_comment ggn_submitter_email ggn_corresponding ggn_conf_seq ggn_locus_desc ggn_locus_phen ggn_gene_name ggn_conf_gene ggn_geneclass_name ggn_conf_class ggn_provider ggn_ip ggn_locus_allele ggn_locus_chrom ggn_locus_product ggn_locus_comp ref_xrefpmidforced ref_origtime ale_mutagen got_wbgene got_bio_goterm got_bio_goid got_bio_paper_evidence got_bio_person_evidence got_bio_goinference got_bio_with got_protein got_bio_goterm1 );
# 
# foreach my $table (@tables) {
# #   my $result = $conn->exec( "DELETE FROM $table;" );
# 
# #   my ($prefix) = $table =~ m/^(\w{4})/;
# #   my $result = $conn->exec( "SELECT * FROM $table WHERE ${prefix}timestamp ~ \'2004-10-05\';" );
# #   while ( my @row = $result->fetchrow ) {
# #     my $stuff = join"\", \"", @row;
# #     $stuff = "INSERT INTO $table VALUE ( \"$stuff\" );";
# #     print "STUFF $stuff\n";
# #   }
# }
  
