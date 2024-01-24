#!/usr/bin/env perl

# generate reference to test merging UI for reference_relations

use strict;
use diagnostics;
use DBI;
use JSON;
use Encode qw( from_to is_utf8 );
use Storable qw(dclone);
use Dotenv -load => '/usr/lib/.env';

my $mod = 'WB';
# my $baseUrl = 'https://stage-literature-rest.alliancegenome.org/';
my $baseUrl = 'https://dev4002-literature-rest.alliancegenome.org/';
my $okta_token = &generateOktaToken();
# my $okta_token = 'use_above_when_live';

my $ref1 = &createReference('ref1');
my $ref2 = &createReference('ref2');
my $ref3 = &createReference('ref3');
my $ref4 = &createReference('ref4');
my $ref5 = &createReference('ref5');
my $ref6 = &createReference('ref6');

my $rel1 = &createRelation($ref1, $ref4, 'CommentOn');
my $rel2 = &createRelation($ref1, $ref5, 'CommentOn');
my $rel3 = &createRelation($ref1, $ref3, 'ChapterIn');
my $rel4 = &createRelation($ref2, $ref6, 'ErratumFor');
my $rel5 = &createRelation($ref2, $ref4, 'ReprintOf');
my $rel6 = &createRelation($ref2, $ref3, 'UpdateOf');


sub createRelation {
  my ($from, $to, $type) = @_;
  my %relation_hash = (
    reference_curie_from => $from,
    reference_curie_to => $to,
    reference_relation_type => $type
  );
  my $relation_json = encode_json \%relation_hash;
  my $url = $baseUrl . 'reference_relation/';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$relation_json'`;
  $api_json =~ s/"//g;
  print qq($api_json\n);
  return $api_json;
}

sub createReference {
#   my ($source_type, $source_method, $source_json) = @_;
  my ($title) = @_;
  my %reference_hash = ( title => $title, category => 'research_article' );
  my $reference_json = encode_json \%reference_hash;
  my $url = $baseUrl . 'reference/';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$reference_json'`;
  $api_json =~ s/"//g;
  print qq($api_json\n);
  return $api_json;
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

use constant FALSE => \0;
use constant TRUE => \1;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;





# my $source_json = '{
#   "source_type": "professional_biocurator",
#   "source_method": "wormbase_curation_status",
#   "validation_type": "curator",
#   "evidence": "eco_string",
#   "mod_abbreviation": "WB",
#   "description": "cur_curdata",
#   "created_by": "default_user",
#   "updated_by": "default_user"
# }';
my %source_default = (
  "source_type"      => "script",
  "source_method"    => "paper_editor",
  "evidence"         => "ECO:0008021",
  "mod_abbreviation" => $mod,
  "created_by"       => "00u2ao5gp6tZJ9xXU5d7",
  "updated_by"       => "00u2ao5gp6tZJ9xXU5d7"
);
# 00u2ao5gp6tZJ9xXU5d7 is vanauken@wormbase.org

my $source_type = 'script';
my $source_method = 'paper_editor';
my $source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
#   $source_json{validation_type} = 'curator';
  $source_json{description}     = 'WormBase script that identifies gene and protein names in PubMed abstracts upon manual inclusion into WormBase using the paper editor.';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00046571
}

$source_type = 'script';
$source_method = 'meeting_abstract_processing';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
#   $source_json{validation_type} = 'curation_tools';
  $source_json{description}     = 'WormBase script that identifies gene and protein names in meeting abstracts upon bulk inclusion into WormBase.';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00063872
}

$source_type = 'script';
$source_method = 'gene_paper_association_script';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
#   $source_json{validation_type} = 'curator';
  $source_json{description}     = 'WormBase scripts that identified gene and protein names in abstracts or updated gene identifiers.';
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00004952, WBPaper00005199
}

$source_type = 'professional_biocurator';
$source_method = 'CGC';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'Manual creation of gene-paper associations that likely came into WormBase via the CGC reference import, but no direct evidence for that is available.';
  $source_json{evidence}        = "ECO:0000302";
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00004952, WBPaper00005199, WBPaper00027280
}

$source_type = 'professional_biocurator';
$source_method = 'WormBook';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'Creation of gene-paper associations made during the initial publication of WormBook chapters.';
  $source_json{evidence}        = "ECO:0000302";
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00004952, WBPaper00005199, WBPaper00027280
}

$source_type = 'professional_biocurator';
$source_method = 'paper_editor';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'Manual creation of gene-paper associations in the WormBase paper editor.';
  $source_json{evidence}        = "ECO:0000302";
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00057043, WBPaper00064676
}

$source_type = 'professional_biocurator';
$source_method = 'curator_first_pass';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'curator';
  $source_json{description}     = 'Manual creation of gene-paper associations in the WormBase curator first pass form.';
  $source_json{evidence}        = "ECO:0000302";
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00057043, WBPaper00064676
}

$source_type = 'author';
$source_method = 'author_first_pass';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'author';
  $source_json{description}     = 'Manual creation of gene-paper associations in the WormBase author first pass form.';
  $source_json{evidence}        = "ECO:0000302";
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
  # e.g. WBPaper00057043, WBPaper00064676
}

$source_type = 'author';
$source_method = 'ACKnowledge_form';
$source_id = &getSourceId($source_type, $source_method);
unless ($source_id) { 
  my %source_json = %{ dclone (\%source_default) };
  $source_json{source_type}     = $source_type;
  $source_json{source_method}   = $source_method;
  $source_json{validation_type} = 'author';
  $source_json{description}     = 'Author validation and/or data entry from ACKnowledge form.';
  $source_json{evidence}        = "ECO:0000302";
  my $source_json = encode_json \%source_json;
  &createSource($source_type, $source_method, $source_json);
}



# had 2 types of string matching data for antibody, but only using one, don't need second type
# $source_type = 'TBD';
# $source_method = 'script_antibody_data_2';
# $source_id = &getSourceId($source_type, $source_method);
# unless ($source_id) { 
#   my %source_json = %{ dclone (\%source_default) };
#   $source_json{source_type}     = $source_type;
#   $source_json{source_method}   = $source_method;
#   $source_json{description}     = 'valerio daniela script';	# script name here
#   my $source_json = encode_json \%source_json;
#   &createSource($source_type, $source_method, $source_json);
# }

# for each nnc/svm, we're creating a new source for each datatype

$result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  print qq($row[0]\n);
  $source_type = 'neural_network';
  $source_method = 'nnc_' . $row[0];
  $source_id = &getSourceId($source_type, $source_method);
  unless ($source_id) { 
    my %source_json = %{ dclone (\%source_default) };
    $source_json{source_type}     = $source_type;
    $source_json{source_method}   = $source_method;
    $source_json{description}     = "TBD nnc $row[0]";
    $source_json{evidence}        = "ECO:0008025";
    my $source_json = encode_json \%source_json;
    &createSource($source_type, $source_method, $source_json);
  }
} # while (my @row = $result->fetchrow)

$result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_svmdata" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  print qq($row[0]\n);
  $source_type = 'support_vector_machine';
  $source_method = 'svm_' . $row[0];
  $source_id = &getSourceId($source_type, $source_method);
  unless ($source_id) { 
    my %source_json = %{ dclone (\%source_default) };
    $source_json{source_type}     = $source_type;
    $source_json{source_method}   = $source_method;
    $source_json{description}     = "TBD svm $row[0]";
    $source_json{evidence}        = "ECO:0008019";
    my $source_json = encode_json \%source_json;
    &createSource($source_type, $source_method, $source_json);
  }
} # while (my @row = $result->fetchrow)



sub createSource {
  my ($source_type, $source_method, $source_json) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source';
  my $api_json = `curl -X 'POST' $url -H 'accept: application/json' -H 'Authorization: Bearer $okta_token' -H 'Content-Type: application/json' --data '$source_json'`;
#   print qq(create $source_json\n);
#   print qq($api_json\n);
}

sub getSourceId {
  my ($source_type, $source_method) = @_;
  my $url = $baseUrl . 'topic_entity_tag/source/' . $source_type . '/' . $source_method . '/' . $mod;
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


my %datatypes;
my %datatypesAfpCfp;
&populateDatatypeStuff();

sub populateDatatypeStuff {
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $datatypesAfpCfp{$row[0]} = $row[0]; }
  $datatypesAfpCfp{'chemicals'}     = 'chemicals';              # added for Karen 2013 10 02
  $datatypesAfpCfp{'blastomere'}    = 'cellfunc';
  $datatypesAfpCfp{'exprmosaic'}    = 'siteaction';
  $datatypesAfpCfp{'geneticmosaic'} = 'mosaic';
  $datatypesAfpCfp{'laserablation'} = 'ablationdata';
  $datatypesAfpCfp{'humandisease'}  = 'humdis';                 # added mapping to correct table 2018 05 17
  $datatypesAfpCfp{'rnaseq'}        = 'rnaseq';                 # for new afp form 2018 10 31
  $datatypesAfpCfp{'chemphen'}      = 'chemphen';               # for new afp form 2018 10 31
  $datatypesAfpCfp{'envpheno'}      = 'envpheno';               # for new afp form 2018 10 31
  $datatypesAfpCfp{'timeaction'}    = 'timeaction';             # for new afp form 2018 11 13
  $datatypesAfpCfp{'siteaction'}    = 'siteaction';             # for new afp form 2018 11 13
  #   delete $datatypesAfpCfp{'catalyticact'};    # has svm but no afp / cfp      # afp got added, so cfp table also created.  2018 11 07
  delete $datatypesAfpCfp{'expression_cluster'};        # has svm but no afp / cfp      # should have been removed 2017 07 08, fixed 2017 08 04
  delete $datatypesAfpCfp{'genesymbol'};                # has svm but no afp / cfp      # added 2021 01 25
  delete $datatypesAfpCfp{'transporter'};               # has svm but no afp / cfp      # added 2021 01 25
  
  $datatypes{'antibody'}           = 'ATP:0000131';
  $datatypes{'blastomere'}         = 'ATP:0000143';
  $datatypes{'catalyticact'}       = 'ATP:0000061';
  $datatypes{'chemphen'}           = 'ATP:0000080';
  $datatypes{'envphen'}            = 'ATP:0000080';
  # $datatypes{'expression_cluster'} = 'no atp, skip';
  $datatypes{'expmosaic'}          = 'ATP:0000034';
  $datatypes{'geneint'}            = 'ATP:0000068';
  $datatypes{'geneprod'}           = 'ATP:0000069';
  $datatypes{'genereg'}            = 'ATP:0000024';
  $datatypes{'genesymbol'}         = 'ATP:0000048';
  $datatypes{'geneticablation'}    = 'ATP:0000032';
  $datatypes{'geneticmosaic'}      = 'ATP:0000034';
  $datatypes{'humandisease'}       = 'ATP:0000111';
  $datatypes{'laserablation'}      = 'ATP:0000032';
  $datatypes{'newmutant'}          = 'ATP:0000083';
  $datatypes{'optogenet'}          = 'ATP:0000145';
  $datatypes{'otherexpr'}          = 'ATP:0000041';
  $datatypes{'overexpr'}           = 'ATP:0000084';
  # $datatypes{'picture'}            = 'no atp, skip';
  $datatypes{'rnai'}               = 'ATP:0000082';
  $datatypes{'rnaseq'}             = 'ATP:0000146';
  # $datatypes{'seqchange'}          = 'no atp, skip';
  $datatypes{'siteaction'}         = 'ATP:0000033';
  # $datatypes{'strain'}             = 'ATP:0000027     not in WB';
  $datatypes{'structcorr'}         = 'ATP:0000054';
  # $datatypes{'timeaction'}         = 'no atp, skip';
  $datatypes{'transporter'}        = 'ATP:0000062';
} # sub populateDatatypeStuff

