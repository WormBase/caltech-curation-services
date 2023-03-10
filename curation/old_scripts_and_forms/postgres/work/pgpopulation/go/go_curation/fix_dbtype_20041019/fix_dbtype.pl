#!/usr/bin/perl 

# script to fix db_type (they didn't get moved, some didn't get created
# while the table didn't exit) based on go_evidence.  2004 10 19

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");      # connect to postgres database
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( 
got_bio_goinference
got_bio_dbtype
got_bio_goinference_two
got_bio_dbtype_two
got_cell_goinference
got_cell_dbtype
got_cell_goinference_two
got_mol_goinference
got_mol_dbtype
got_mol_goinference_two
got_mol_dbtype_two
);

my %transHash = (
  'IDA' => 'protein',
  'IEA' => 'protein',
  'IPI' => 'protein',
  'ISS' => 'protein',
  'IGI' => 'gene',
  'IMP' => 'gene',
  'NAS' => 'gene',
  'ND'  => 'gene',
  'IC'  => 'gene',
  'TAS' => 'gene',
  'IEP' => 'transcript'
);

my %hash;

my @thing = qw(bio_ cell_ mol_);
my @otherthing = qw(goinference goinference_two dbtype dbtype_two);
foreach my $thing (@thing) {
  foreach my $otherthing (@otherthing) {
    my $result = $conn->exec( "SELECT * FROM got_${thing}${otherthing} ORDER BY got_timestamp;" );
    while (my @row=$result->fetchrow) {
      my $joinkey = $row[0];
      my $order = $row[1];
      my $value = $row[2];
      $hash{$thing}{$joinkey}{$order}{$otherthing} = $value; }
} }

foreach my $thing (@thing) {
  foreach my $joinkey (sort keys %{ $hash{$thing} }) {
    next unless ($joinkey =~ m/\D/);
    foreach my $order (sort keys %{ $hash{$thing}{$joinkey} }) {
      if ($hash{$thing}{$joinkey}{$order}{goinference}) {
        if ($transHash{ $hash{$thing}{$joinkey}{$order}{goinference} } ) {
          unless ($hash{$thing}{$joinkey}{$order}{dbtype}) { $hash{$thing}{$joinkey}{$order}{dbtype} = ''; }
          if ($transHash{ $hash{$thing}{$joinkey}{$order}{goinference} } ne $hash{$thing}{$joinkey}{$order}{dbtype} ) {
            print "INF $hash{$thing}{$joinkey}{$order}{goinference} DB $hash{$thing}{$joinkey}{$order}{dbtype} END\n";
            print "INSERT INTO got_${thing}dbtype VALUES (\'$joinkey\', \'$order\', \'$transHash{ $hash{$thing}{$joinkey}{$order}{goinference} }\'); \n";
# UNCOMMENT TO MAKE CHANGES
#             my $result2 = $conn->exec( "INSERT INTO got_${thing}dbtype VALUES (\'$joinkey\', \'$order\', \'$transHash{ $hash{$thing}{$joinkey}{$order}{goinference} }\'); " );
          }
        } # else { print "ERR no transHash $thing $joinkey $order $hash{$thing}{$joinkey}{$order}{goinference}\n"; }
      } # else {  print "ERR no val $thing  $joinkey  $order\n"; }
      if ($hash{$thing}{$joinkey}{$order}{goinference_two}) {
        if ($transHash{ $hash{$thing}{$joinkey}{$order}{goinference_two} } ) {
          unless ($hash{$thing}{$joinkey}{$order}{dbtype_two}) { $hash{$thing}{$joinkey}{$order}{dbtype_two} = ''; }
          if ($transHash{ $hash{$thing}{$joinkey}{$order}{goinference_two} } ne $hash{$thing}{$joinkey}{$order}{dbtype_two} ) {
            print "INF $hash{$thing}{$joinkey}{$order}{goinference_two} DB $hash{$thing}{$joinkey}{$order}{dbtype_two} END\n";
            print "INSERT INTO got_${thing}dbtype_two VALUES (\'$joinkey\', \'$order\', \'$transHash{ $hash{$thing}{$joinkey}{$order}{goinference_two} }\'); \n";
# UNCOMMENT TO MAKE CHANGES
#             my $result2 = $conn->exec( "INSERT INTO got_${thing}dbtype_two VALUES (\'$joinkey\', \'$order\', \'$transHash{ $hash{$thing}{$joinkey}{$order}{goinference_two} }\');" );
          }
        } # else { print "ERR no transHash $thing $joinkey $order $hash{$thing}{$joinkey}{$order}{goinference_two}\n"; }
      } # else {  print "ERR no val $thing  $joinkey  $order\n"; }
    } # foreach my $order (sort keys %{ $hash{$thing}{$joinkey} })
  } # foreach my $joinkey (sort keys %{ $hash{$thing} })
}


__END__

foreach my $joinkey (sort keys %joinkeys) {
  foreach my $table (@tables) {
#     my $result = $conn->exec( "UPDATE $table SET got_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\';" );
#     $result = $conn->exec( "UPDATE $table SET joinkey = \'$joinkeys{$joinkey}\' WHERE joinkey = \'$joinkey\';" );
    print "UPDATE $table SET got_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\';\n";
    print "UPDATE $table SET joinkey = \'$joinkeys{$joinkey}\' WHERE joinkey = \'$joinkey\';\n";
  }
}
  

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
  
