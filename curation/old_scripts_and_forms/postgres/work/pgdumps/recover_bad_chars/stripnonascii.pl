#!/usr/bin/perl

my %tab_hash;
  $tab_hash{wbg_firstname}++;
  $tab_hash{wbg_lastname}++;
  $tab_hash{wbg_street}++;
  $tab_hash{wbg_city}++;
  $tab_hash{wbg_state}++;
  $tab_hash{ace_address}++;
  $tab_hash{ref_abstract}++;
  $tab_hash{ref_med}++;
  $tab_hash{cur_mappingdata}++;
  $tab_hash{cur_genefunction}++;
  $tab_hash{cur_associationequiv}++;
  $tab_hash{cur_expression}++;
  $tab_hash{cur_transgene}++;
  $tab_hash{cur_antibody}++;
  $tab_hash{cur_extractedallelenew}++;
  $tab_hash{cur_sequencechange}++;
  $tab_hash{cur_structurecorrection}++;
  $tab_hash{cur_ablationdata}++;
  $tab_hash{two_comment}++;
  $tab_hash{pap_inbook}++;
  $tab_hash{pap_pmid}++;
  $tab_hash{cur_structureinformation}++;
  $tab_hash{ale_transposon_insertion}++;
  $tab_hash{tpd_calc_lower}++;
  $tab_hash{tpd_calc_upper}++;
  $tab_hash{tpd_comment}++;
  $tab_hash{two_contactdata}++;
  $tab_hash{cur_microarray}++;
  $tab_hash{phe_evi_similarity_evidence}++;
  $tab_hash{phe_evi_cgc_data_submission}++;
  $tab_hash{phe_evi_author_evidence}++;
  $tab_hash{phe_evi_protein_id_evidence}++;
  $tab_hash{phe_evi_go_inference_type}++;
  $tab_hash{phe_assay}++;
  $tab_hash{phe_anatomy}++;
  $tab_hash{phe_specialisation_of}++;
  $tab_hash{phe_generalisation_of}++;
  $tab_hash{phe_part_of}++;
  $tab_hash{phe_equivalent_to}++;
  $tab_hash{phe_similar_to}++;
  $tab_hash{phe_rnai}++;
  $tab_hash{phe_locus}++;
  $tab_hash{phe_strain}++;
  $tab_hash{pha_consistof}++;
  $tab_hash{pha_partof}++;
  $tab_hash{pha_equivto}++;
  $tab_hash{pha_similarto}++;
  $tab_hash{pha_evi_author_evidence}++;
  $tab_hash{pha_evi_similarity_evidence}++;
  $tab_hash{pha_evi_pmid_evidence}++;
  $tab_hash{pha_evi_accession_evidence}++;
  $tab_hash{pha_evi_cgc_data_submission}++;
  $tab_hash{con_genotype}++;
  $tab_hash{con_other}++;
  $tab_hash{con_remark}++;
  $tab_hash{eim_timestamps}++;
  $tab_hash{dfd_genotype}++;
  $tab_hash{dfd_dfdp_clone}++;
  $tab_hash{dfd_dfdp_rearrangement}++;
  $tab_hash{dfd_comment}++;
  $tab_hash{rea_phenotype}++;
  $tab_hash{rea_comment}++;
  $tab_hash{rea_locus_in}++;
  $tab_hash{rea_locus_out}++;
  $tab_hash{rea_clone_out}++;
  $tab_hash{rea_rearr_in}++;
  $tab_hash{rea_rearr_out}++;
  $tab_hash{rea_lab}++;
  $tab_hash{ale_types_of_alterations}++;
  $tab_hash{car_ort3}++;
  $tab_hash{car_ort3_curator}++;
  $tab_hash{car_ort3_ref1}++;
  $tab_hash{car_ort4}++;
  $tab_hash{car_ort4_curator}++;
  $tab_hash{car_ort4_ref1}++;
  $tab_hash{car_phy2}++;
  $tab_hash{car_phy2_curator}++;
  $tab_hash{car_phy2_ref1}++;
  $tab_hash{car_phy3}++;
  $tab_hash{car_phy3_curator}++;
  $tab_hash{car_phy3_ref1}++;
  $tab_hash{car_phy4}++;
  $tab_hash{car_phy4_curator}++;
  $tab_hash{car_phy4_ref1}++;
  $tab_hash{car_phy5}++;
  $tab_hash{car_phy5_curator}++;
  $tab_hash{car_phy5_ref1}++;
  $tab_hash{car_exp3}++;
  $tab_hash{car_exp3_curator}++;
  $tab_hash{car_exp3_ref1}++;
  $tab_hash{car_exp4}++;
  $tab_hash{car_exp4_curator}++;
  $tab_hash{car_exp4_ref1}++;
  $tab_hash{car_exp5}++;
  $tab_hash{car_exp5_curator}++;
  $tab_hash{car_exp5_ref1}++;
  $tab_hash{car_oth2}++;
  $tab_hash{car_oth2_curator}++;
  $tab_hash{car_oth2_ref1}++;
  $tab_hash{car_oth3}++;
  $tab_hash{car_oth3_curator}++;
  $tab_hash{car_oth3_ref1}++;
  $tab_hash{car_oth4}++;
  $tab_hash{car_oth4_curator}++;
  $tab_hash{car_oth4_ref1}++;
  $tab_hash{ref_type}++;
  $tab_hash{car_oth_ref_person}++;
  $tab_hash{got_cell_qualifier_two}++;
  $tab_hash{got_mol_qualifier_two}++;
  $tab_hash{ref_other}++;
  $tab_hash{ref_xref_cgc}++;
  $tab_hash{ref_xref_wb_oldwb}++;
  $tab_hash{wpa_nematode_paper}++;
  $tab_hash{wpa_electronic_path_md5}++;
  $tab_hash{ant_cell_similarity}++;
  $tab_hash{ant_mol_similarity}++;
  $tab_hash{alp_rnai_brief}++;
  $tab_hash{alp_phenotype}++;
  $tab_hash{alp_go_sug}++;
  $tab_hash{alp_suggested}++;
  $tab_hash{alp_sug_ref}++;
  $tab_hash{alp_sug_def}++;
  $tab_hash{alp_delivered}++;
  $tab_hash{alp_pat_effect}++;
  $tab_hash{alp_haplo}++;
  $tab_hash{ggi_gene_gene_interaction}++;
  $tab_hash{ale_haploinsufficient}++;
  $tab_hash{got_mol_protein_two}++;
  $tab_hash{got_mol_protein}++;
  $tab_hash{got_cell_protein_two}++;
  $tab_hash{got_cell_protein}++;

# my $infile = 'abstracts';
my $infile = '../testdb.dump.200703020838';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  if ($para =~ m/^COPY ([\w\_]+)/) {
    if ($tab_hash{$1}) { 
      $para =~ s/[^\s\w\d\~\!\@\#\$\%\^\&\*\(\)\-\_\+\=\{\}\[\]\|\;\:\'\"\,\<\.\>\\\/\?]//g;
      print $para;
  } }
}
close (IN) or die "Cannot close $infile : $!";
