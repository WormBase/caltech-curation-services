#!/usr/bin/env perl

# generate topic entity classifiers for Kimberly for ABC  https://agr-jira.atlassian.net/browse/SCRUM-2664  2023 06 09
#
# create sources at ABC if they don't already exist.
# does not handle cur_svmdata nor cur_nncdata until confirmation.  2023 08 15
#
# handle second strdata for antibody from Valerio/Daniela pipeline, use for strdata after 2021-06-09
# handles nnc and svm, although Kimberly has not confirmed.  2023 08 16
#
# dockerized, filled in TDB for source_type for str, svm, nnc.  wrote to Valerio and Kimberly about the confirmation questions.  2023 10 04
#
# modified for gene sources instead of general entity sources.  2024 01 08
#
# updated to new source data from https://docs.google.com/document/d/1xNnGLb1KO1ONrvTontgC1LTjpUc0JlfxrXWCvR_XIGA/edit  2024 04 18
#
# new source added by Kimberly on 2024 07 23 for afp_transgene extraction.  2024 07 23
#
# aggregate topic, gene, transgenic_allele into a single script for sources.  species are already on abc prod.  2024 07 26

# ./create_sources.pl


use strict;
use diagnostics;
use DBI;
use JSON;
use Encode qw( from_to is_utf8 );
use Storable qw(dclone);
use Dotenv -load => '/usr/lib/.env';

use constant FALSE => \0;
use constant TRUE => \1;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $mod = 'WB';
my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
# my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
my $okta_token = &generateOktaToken();
# my $okta_token = 'use_above_when_live';


# old source format
# my %source_default = (
#   "source_type"      => "script",
#   "source_method"    => "paper_editor",
#   "evidence"         => "ECO:0008021",
#   "mod_abbreviation" => $mod,
#   "created_by"       => "00u2ao5gp6tZJ9xXU5d7",
#   "updated_by"       => "00u2ao5gp6tZJ9xXU5d7"
# );
# 00u2ao5gp6tZJ9xXU5d7 is vanauken@wormbase.org

# sources for gene aren't ready, so using a single test source for all entries.  2024 03 14
my %source_default = (
  "source_evidence_assertion"                   => "ECO:0008021",
  "source_method"                               => "ACKnowledge_pipeline",
  "validation_type"                             => "",
  "description"                                 => "Association of entities with references by the ACKnowledge pipeline that recognizes entity mentions and subsequently filters according to empirically determined methods, e.g. threshold values for species or tf/idf for genes, to associate those entities most likely to be experimentally studied.",
  "data_provider"                               => $mod,
  "secondary_data_provider_abbreviation"        => $mod,
  "created_by"                                  => "00u2ao5gp6tZJ9xXU5d7",
  "updated_by"                                  => "00u2ao5gp6tZJ9xXU5d7"
);



# START TOPIC sources

my $source_evidence_assertion = 'ATP:0000035';
my $source_method = 'ACKnowledge_form';
my $data_provider = $mod;
my $secondary_data_provider = $mod;
my $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= "author";
  $source_json{description}			= "Manual association of entities and topics with references by authors using the ACKnowledge form.";
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000035';
$source_method = 'author_first_pass';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}  			= $source_method;
  $source_json{validation_type}			= 'author';
  $source_json{description}    			= 'Manual association of entities and topics with references by authors using the author first pass form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'author_first_pass';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual association of topics with references by professional biocurators via data type curation using the author first pass form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'ontology_annotator';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual association of topics with references by professional biocurators via data type curation using the ontology annotator form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'curation_status_form';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual validation of topic associations with references by professional biocurators using the curation status form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'curator_first_pass';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{validation_type}			= 'professional_biocurator';
  $source_json{description}     		= 'Manual association of topics with references by professional biocurators using the curator first pass form.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'string_matching_antibody';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  delete $source_json{validation_type};
  $source_json{source_evidence_assertion}	= $source_evidence_assertion;
  $source_json{source_method}   		= $source_method;
  $source_json{description}     		= 'String matching algorithm that identifies relevant words and/or phrases in C. elegans references to identify references describing production and/or use of antibodies.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

# for each nnc/svm, we're creating a new source for each datatype
$result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  print qq($row[0]\n);
  $source_evidence_assertion = 'ECO:0008025';
  $source_method = 'nnc_' . $row[0];
  $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) { 
    my %source_json = %{ dclone (\%source_default) };
    delete $source_json{validation_type};
    $source_json{source_evidence_assertion}	= $source_evidence_assertion;
    $source_json{source_method}   		= $source_method;
    $source_json{description}     		= 'Neural network document classifier trained on manually validated C. elegans references to identify references describing production and/or use of antibodies.';	# TODO  Kimberly will need to generate individual descriptions for each datatype ?
    my $source_json = encode_json \%source_json;
    &createSource($source_json);
  }
} # while (my @row = $result->fetchrow)

# That happens automatically from the API ?  Or you mean populate from another value ?

$result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_svmdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  print qq($row[0]\n);
  $source_evidence_assertion = 'ECO:0008019';
  $source_method = 'svm_' . $row[0];
  $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
  unless ($source_id) { 
    my %source_json = %{ dclone (\%source_default) };
    delete $source_json{validation_type};
    $source_json{source_evidence_assertion}	= $source_evidence_assertion;
    $source_json{source_method}   		= $source_method;
    $source_json{description}     		= 'Support vector machine document classifier trained on manually validated C. elegans references to identify references that describe production and/or use of antibodies.';	# TODO  Kimberly will need to generate individual descriptions for each datatype ?
    my $source_json = encode_json \%source_json;
    &createSource($source_json);
  }
} # while (my @row = $result->fetchrow)

# END TOPIC sources



# START GENE sources

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'ACKnowledge_pipeline';
$data_provider = $mod;
$secondary_data_provider = $mod;
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  delete $source_json{validation_type};
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

# created for topic
# $source_evidence_assertion = 'ATP:0000035';
# $source_method = 'ACKnowledge_form';
# $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
# unless ($source_id) {
#   my %source_json = %{ dclone (\%source_default) };
#   $source_json{source_evidence_assertion}       = $source_evidence_assertion;
#   $source_json{source_method}                   = $source_method;
#   $source_json{validation_type}                 = 'author';
#   $source_json{description}                     = 'Manual association of entities and topics with references by authors using the ACKnowledge form.';
#   my $source_json = encode_json \%source_json;
#   &createSource($source_json);
# }

# created for topic, but with different description
# $source_evidence_assertion = 'ATP:0000035';
# $source_method = 'author_first_pass';
# $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
# unless ($source_id) {
#   my %source_json = %{ dclone (\%source_default) };
#   $source_json{source_evidence_assertion}       = $source_evidence_assertion;
#   $source_json{source_method}                   = $source_method;
#   $source_json{validation_type}                 = 'author';
#   $source_json{description}                     = 'Manual association of genes with references by authors in the author first pass form or otherwise communicated by authors to a WormBase curator.';
#   my $source_json = encode_json \%source_json;
#   &createSource($source_json);
# }

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'genes_curator';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  $source_json{validation_type}                 = 'professional_biocurator';
  $source_json{description}                     = 'Manual association of genes with references by a curator by a method other than using the Caltech paper editor.  This includes gene-reference associations made by the CGC for which we have curator evidence, gene-reference associations to WormBook chapters, and gene-reference associations made directly into AceDB prior to paper curation in the Caltech postgres database.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'script_gene_meeting_abstract';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'Scripts that associated genes with meeting abstracts based on mention of a gene in the abstract.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ATP:0000036';
$source_method = 'paper_editor_genes_curator';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  $source_json{validation_type}                 = 'professional_biocurator';
  $source_json{description}                     = 'Manual association of genes with references in the WormBase paper editor.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'paper_editor_genes_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'Association of genes mentioned in abstracts with references based on string matching of gene and protein names, and synonyms, upon approval of a reference in the WormBase paper editor.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

# This source has been replaced by the multiple 8021 sources below
# $source_evidence_assertion = 'ECO:0008021';
# $source_method = 'script_gene';
# $source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
# unless ($source_id) {
#   my %source_json = %{ dclone (\%source_default) };
#   $source_json{source_evidence_assertion}       = $source_evidence_assertion;
#   $source_json{source_method}                   = $source_method;
#   delete $source_json{validation_type};
#   $source_json{description}                     = 'One of several scripts that associated genes with references based on mention of a gene in a reference abstract or full text.';
#   my $source_json = encode_json \%source_json;
#   &createSource($source_json);
# }

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'update2_gene_cds_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run in 2006 that associated genes with references based on mention of a gene in a reference.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'fix_dead_genes_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run in 2010 that updated WBGene identifiers for genes previously associated with a reference but for which the identifier was no longer valid, likely due to a gene merge.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'update_oldwbgenes_papers_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run in 2008 that updated WBGene identifiers for genes previously associated with a reference but for which the identifier was no longer valid, likely due to a gene merge.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'geneChecker_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run by Eimear Kenny to associate genes with references.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'abstract2aceCGC_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run by Eimear Kenny to associate genes with references.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'abstract2acePMID_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run by Eimear Kenny to associate genes with references.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'automatic_update_merge_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A script run by Eimear Kenny to fix gene-reference associations after gene merges.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'parsing_supplementary_tables_ortholist';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A one-time pipeline that parsed sequence names in the supplementary tables of two Ortholist papers to match those names to WBGene identifiers.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

$source_evidence_assertion = 'ECO:0008021';
$source_method = 'update_of_dead_and_merged_genes_Mary_Ann';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'A one-time pipeline that updated dead genes associated with references.  The updated identifiers list was sourced from Mary Ann Tuli.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}


# this source might be too broad with a description that is too specific.
$source_evidence_assertion = 'ECO:0006151';
$source_method = 'unknown';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'Association of genes with references by an unknown method.  Some of these associations likely came into WormBase when we took over curation of the C. elegans literature from the CGC; others may have been added via bulk upload without corresponding evidence.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}

# END GENE sources


# for transgenic alleles from old afp that are getting script mapped to WBTransgene
$source_evidence_assertion = 'ECO:0008021';
$source_method = 'free_text_to_entity_id_script';
$source_id = &getSourceId($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider);
unless ($source_id) {
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_evidence_assertion}       = $source_evidence_assertion;
  $source_json{source_method}                   = $source_method;
  delete $source_json{validation_type};
  $source_json{description}                     = 'Mapping of free text entries in WormBase reference entity flagging tables, e.g. afp_transgene, to valid WormBase entity ids.';
  my $source_json = encode_json \%source_json;
  &createSource($source_json);
}



sub createSource {
  my ($source_json) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$source_json'`;
#   print qq(create $source_json\n);
#   print qq($api_json\n);
}

sub getSourceId {
  my ($source_evidence_assertion, $source_method, $data_provider, $secondary_data_provider) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_evidence_assertion . '/' . $source_method . '/' . $data_provider . '/' . $secondary_data_provider;
#   my ($source_type, $source_method) = @_;
#   my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
  # print qq($url\n);
  my $api_json = `curl -X 'GET' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json'`;
  my $hash_ref = decode_json $api_json;
  if ($$hash_ref{'topic_entity_tag_source_id'}) {
    my $source_id = $$hash_ref{'topic_entity_tag_source_id'};
    # print qq($source_id\n);
    return $source_id; }
  else { return ''; }
}

sub generateOktaToken {
#   my $okta_token = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}" \      | jq '.access_token' | tr -d '"'`;
  my $okta_result = `curl -s --request POST --url https://$ENV{OKTA_DOMAIN}/v1/token \    --header 'accept: application/json' \    --header 'cache-control: no-cache' \    --header 'content-type: application/x-www-form-urlencoded' \    --data "grant_type=client_credentials&scope=admin&client_id=$ENV{OKTA_CLIENT_ID}&client_secret=$ENV{OKTA_CLIENT_SECRET}"`;
  my $hash_ref = decode_json $okta_result;
  my $okta_token = $$hash_ref{'access_token'};
#   print $okta_token;
  return $okta_token;
}


__END__

