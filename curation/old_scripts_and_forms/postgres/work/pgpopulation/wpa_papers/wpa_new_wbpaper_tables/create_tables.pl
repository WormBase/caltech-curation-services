#!/usr/bin/perl -w

# Create wpa_ tables (except for wpa_gene and wpa_gene_index )  2005 06 27
#
# Get abstracts using /home/acedb/citace/longtext.pl as acedb.  2005 07 08
#
# Now 16 types in wpa_type_index.  2005 07 13

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "create_tables.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# my $result = $conn->exec( "SELECT two_groups FROM two_groups WHERE joinkey = 'two2';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { print "$row[0]\n";}
# }

my $result;

$result = $conn->exec( "DROP TABLE wpa; ");
$result = $conn->exec( "DROP TABLE wpa_identifier; ");
$result = $conn->exec( "DROP TABLE wpa_title; ");
$result = $conn->exec( "DROP TABLE wpa_publisher; ");
$result = $conn->exec( "DROP TABLE wpa_journal; ");
$result = $conn->exec( "DROP TABLE wpa_volume; ");
$result = $conn->exec( "DROP TABLE wpa_pages; ");
$result = $conn->exec( "DROP TABLE wpa_year; ");
$result = $conn->exec( "DROP TABLE wpa_fulltext_url; ");
$result = $conn->exec( "DROP TABLE wpa_abstract; ");
$result = $conn->exec( "DROP TABLE wpa_affiliation; ");
$result = $conn->exec( "DROP TABLE wpa_type; ");
$result = $conn->exec( "DROP TABLE wpa_author; ");
$result = $conn->exec( "DROP TABLE wpa_hardcopy; ");
$result = $conn->exec( "DROP TABLE wpa_comments; ");
$result = $conn->exec( "DROP TABLE wpa_editor; ");
$result = $conn->exec( "DROP TABLE wpa_nematode_paper; ");
$result = $conn->exec( "DROP TABLE wpa_contained_in; ");
$result = $conn->exec( "DROP TABLE wpa_contains; ");
$result = $conn->exec( "DROP TABLE wpa_keyword; ");
$result = $conn->exec( "DROP TABLE wpa_erratum; ");
$result = $conn->exec( "DROP TABLE wpa_in_book; ");
$result = $conn->exec( "DROP TABLE wpa_author_possible; ");
$result = $conn->exec( "DROP TABLE wpa_author_sent; ");
$result = $conn->exec( "DROP TABLE wpa_author_verified; ");
$result = $conn->exec( "DROP TABLE wpa_gene; ");

$result = $conn->exec( "DROP TABLE wpa_type_index; ");
$result = $conn->exec( "DROP SEQUENCE wpa_type_index_type_id_seq; ");
$result = $conn->exec( "DROP TABLE wpa_author_index; ");
$result = $conn->exec( "DROP SEQUENCE wpa_author_index_author_id_seq; ");
$result = $conn->exec( "DROP TABLE wpa_electronic_type_index; ");
$result = $conn->exec( "DROP SEQUENCE wpa_electronic_type_index_type_id_seq; ");
$result = $conn->exec( "DROP TABLE wpa_electronic_path_type; ");
$result = $conn->exec( "DROP TABLE wpa_electronic_path_md5; ");

# still need wpa_gene and wpa_gene_index
# also see file ``tables''
my @pgtables = qw( wpa wpa_identifier wpa_title wpa_publisher wpa_journal wpa_volume wpa_pages wpa_year wpa_fulltext_url wpa_abstract wpa_affiliation wpa_type wpa_author wpa_hardcopy wpa_comments wpa_editor wpa_nematode_paper wpa_contained_in wpa_contains wpa_erratum wpa_in_book wpa_keyword );

foreach my $table (@pgtables) {
  my $result = $conn->exec( "CREATE TABLE $table ( joinkey text, $table text,
wpa_order int, wpa_valid text, wpa_curator text,
wpa_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text) ); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE $table FROM PUBLIC;" );
  $result = $conn->exec( "GRANT ALL ON TABLE $table TO acedb;" );
  $result = $conn->exec( "GRANT ALL ON TABLE $table TO apache;" );
  $result = $conn->exec( "GRANT ALL ON TABLE $table TO azurebrd;" );
  $result = $conn->exec( "GRANT ALL ON TABLE $table TO cecilia;" );
  $result = $conn->exec( "CREATE INDEX ${table}_idx ON $table USING btree (joinkey);" );
  print OUT "Created $table\n";
} # foreach my $table (@pgtables)

$result = $conn->exec( "CREATE TABLE wpa_type_index (
    type_id int,
    wpa_type_index text,
    wpa_comment text,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
); ");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_type_index FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_type_index TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_type_index TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_type_index TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_type_index TO cecilia;" );
$result = $conn->exec( "CREATE SEQUENCE wpa_type_index_type_id_seq; ");
$result = $conn->exec( "GRANT ALL ON wpa_type_index_type_id_seq TO acedb;" );
$result = $conn->exec( "GRANT ALL ON wpa_type_index_type_id_seq TO apache;" );
$result = $conn->exec( "GRANT ALL ON wpa_type_index_type_id_seq TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON wpa_type_index_type_id_seq TO cecilia;" );
$result = $conn->exec( "CREATE UNIQUE INDEX wpa_type_index_idx ON wpa_type_index (type_id); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('1', 'ARTICLE', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('2', 'REVIEW', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('3', 'MEETING_ABSTRACT', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('4', 'GAZETTE_ABSTRACT', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('5', 'BOOK_CHAPTER', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('6', 'NEWS', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('7', 'EMAIL', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('8', 'COMMUNICATION', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('9', 'NOTE', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('10', 'COMMENT', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('11', 'LETTER', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('12', 'MONOGRAM', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('13', 'EDITORIAL', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('14', 'CORRECTION', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('15', 'ERRATUM', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
$result = $conn->exec( "INSERT INTO wpa_type_index VALUES ('16', 'ADDENDUM', NULL, 'valid', 'two1841', CURRENT_TIMESTAMP); ");
print OUT "Created wpa_type_index AND wpa_type_index_type_id_seq\n"; 


$result = $conn->exec( "CREATE TABLE wpa_author_index (
    author_id int,
    wpa_author_index text,
    wpa_affiliation text,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null 
);  ");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_author_index FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_index TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_index TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_index TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_index TO cecilia;" );
$result = $conn->exec( "CREATE SEQUENCE wpa_author_index_author_id_seq;");
$result = $conn->exec( "GRANT ALL ON wpa_author_index_author_id_seq TO acedb;" );
$result = $conn->exec( "GRANT ALL ON wpa_author_index_author_id_seq TO apache;" );
$result = $conn->exec( "GRANT ALL ON wpa_author_index_author_id_seq TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON wpa_author_index_author_id_seq TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_author_index_idx ON wpa_author_index (author_id);");
print OUT "Created wpa_author_index AND wpa_author_index_author_id_seq\n";
# INDEX not UNIQUE because a given author_id could have a bad name, so make that
# name invalid (add entry with same index number -- invalid), then add another
# author with the same index with the proper name.  result -> 3 entries with
# same author_id



$result = $conn->exec( "CREATE TABLE wpa_electronic_type_index (
    electronic_type_id int,
    wpa_electronic_type_index text,
    wpa_text_convertible boolean default 'false',
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_electronic_type_index FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_type_index TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_type_index TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_type_index TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_type_index TO cecilia;" );
$result = $conn->exec( "CREATE SEQUENCE wpa_electronic_type_index_type_id_seq;");
$result = $conn->exec( "GRANT ALL ON wpa_electronic_type_index_type_id_seq TO acedb;" );
$result = $conn->exec( "GRANT ALL ON wpa_electronic_type_index_type_id_seq TO apache;" );
$result = $conn->exec( "GRANT ALL ON wpa_electronic_type_index_type_id_seq TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON wpa_electronic_type_index_type_id_seq TO cecilia;" );
$result = $conn->exec( "CREATE UNIQUE INDEX wpa_electronic_type_index_idx ON wpa_electronic_type_index (electronic_type_id);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('1', 'WEB_PDF', true, 'valid', 'two1841', CURRENT_TIMESTAMP);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('2', 'LIBRARY_PDF', false, 'valid', 'two1841', CURRENT_TIMESTAMP);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('3', 'TIF_PDF', false, 'valid', 'two1841', CURRENT_TIMESTAMP);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('4', 'HTML_PDF', true, 'valid', 'two1841', CURRENT_TIMESTAMP);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('5', 'OCR_PDF', true, 'valid', 'two1841', CURRENT_TIMESTAMP);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('6', 'AUTHOR_CONTRIBUTED_PDF', true, 'valid', 'two1841', CURRENT_TIMESTAMP);");
$result = $conn->exec( "INSERT INTO wpa_electronic_type_index VALUES ('7', 'TEMP_PDF', true, 'valid', 'two1841', CURRENT_TIMESTAMP);");
print OUT "Created wpa_electonic_type_index AND wpa_electonic_type_index_electronic_type_id_seq\n";


$result = $conn->exec( "CREATE TABLE wpa_electronic_path_type (
    joinkey text,
    wpa_electronic_path_type text,
    wpa_type int,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_electronic_path_type FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_type TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_type TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_type TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_type TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_electronic_path_type_idx ON wpa_electronic_path_type (joinkey);");
print OUT "Created wpa_electronic_path_type\n";

$result = $conn->exec( "CREATE TABLE wpa_electronic_path_md5 (
    joinkey text,
    wpa_electronic_path_md5 text,
    wpa_md5 text,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_electronic_path_md5 FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_md5 TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_md5 TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_md5 TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_electronic_path_md5 TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_electronic_path_md5_idx ON wpa_electronic_path_md5 (joinkey);");
print OUT "Created wpa_electronic_path_md5\n";

# wpa_join is necessary below to link authors that have the same_id between
# possible, sent, and verified.  

$result = $conn->exec( "CREATE TABLE wpa_author_possible (
    author_id text,
    wpa_author_possible text,
    wpa_join int,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_author_possible FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_possible TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_possible TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_possible TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_possible TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_author_possible_idx ON wpa_author_possible (author_id);");
print OUT "Created wpa_author_possible\n";

$result = $conn->exec( "CREATE TABLE wpa_author_sent (
    author_id text,
    wpa_author_sent text,
    wpa_join int,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_author_sent FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_sent TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_sent TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_sent TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_sent TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_author_sent_idx ON wpa_author_sent (author_id);");
print OUT "Created wpa_author_sent\n";

$result = $conn->exec( "CREATE TABLE wpa_author_verified (
    author_id text,
    wpa_author_verified text,
    wpa_join int,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_author_verified FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_verified TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_verified TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_verified TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_author_verified TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_author_verified_idx ON wpa_author_verified (author_id);");
print OUT "Created wpa_author_verified\n";



$result = $conn->exec( "CREATE TABLE wpa_gene (
    joinkey text,
    wpa_gene text,
    wpa_evidence text,
    wpa_valid text,
    wpa_curator text,
    wpa_timestamp timestamp not null
);");
$result = $conn->exec( "REVOKE ALL ON TABLE wpa_gene FROM PUBLIC;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_gene TO acedb;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_gene TO apache;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_gene TO azurebrd;" );
$result = $conn->exec( "GRANT ALL ON TABLE wpa_gene TO cecilia;" );
$result = $conn->exec( "CREATE INDEX wpa_gene_idx ON wpa_gene (joinkey);");
print OUT "Created wpa_gene\n";



close (OUT) or die "Cannot close $outfile : $!";


__END__

to delete tables before running this to create them :
DROP TABLE wpa;
DROP TABLE wpa_identifier;
DROP TABLE wpa_title;
DROP TABLE wpa_publisher;
DROP TABLE wpa_journal;
DROP TABLE wpa_volume;
DROP TABLE wpa_pages;
DROP TABLE wpa_year;
DROP TABLE wpa_fulltext_url;
DROP TABLE wpa_abstract;
DROP TABLE wpa_affiliation;
DROP TABLE wpa_type;
DROP TABLE wpa_author;
DROP TABLE wpa_hardcopy;
DROP TABLE wpa_comments;
DROP TABLE wpa_editor;
DROP TABLE wpa_nematode_paper;
DROP TABLE wpa_contained_in;
DROP TABLE wpa_contains;
DROP TABLE wpa_keyword;
DROP TABLE wpa_erratum;
DROP TABLE wpa_in_book;
DROP TABLE wpa_author_possible;
DROP TABLE wpa_author_sent;
DROP TABLE wpa_author_verified;


DROP TABLE wpa_type_index;
DROP SEQUENCE wpa_type_index_type_id_seq;
DROP TABLE wpa_author_index;
DROP SEQUENCE wpa_author_index_author_id_seq;
DROP TABLE wpa_electronic_type_index;
DROP SEQUENCE wpa_electronic_type_index_type_id_seq;
DROP TABLE wpa_electronic_path_type;
DROP TABLE wpa_electronic_path_md5;


?Paper  Original_timestamp Datetype // temporary tag in transition period [krb 040223]
	Name    CGC_name ?Paper_name XREF CGC_name_for
		PMID     ?Paper_name XREF PMID_for
		Medline_name ?Paper_name XREF Medline_name_for
		Meeting_abstract ?Paper_name XREF Meeting_abstract_name
		WBG_abstract    ?Paper_name XREF WBG_abstract_name
		Old_WBPaper ?Paper_name XREF Old_WBPaper_name
		Other_name ?Paper_name XREF Other_name_for // e.g. agriola etc ...
	Nematode_paper ?Species // for flagging worm specific papers, ?Species part is optional
	Erratum #Paper
	Reference       Title UNIQUE ?Text
                        Journal UNIQUE ?Journal XREF Paper
                        Publisher UNIQUE Text
                        Editor ?Text            //used for books put in as whole objects
                        Page  UNIQUE  Text UNIQUE Text
                        Volume UNIQUE Text Text
                        Year UNIQUE Int
                        In_book #Paper
                        Contained_in ?Paper XREF Contains       // old form
        Author ?Author XREF Paper #Affiliation        // replaced by:
//        Author_to_person ?Author UNIQUE ?Person XREF Paper
        Person ?Person XREF Paper
        Affiliation Text        // Authors' affiliation if available
        Brief_citation UNIQUE Text
        Abstract ?LongText
        Type UNIQUE Text        //meaning review, article, chapter,
                                //monograph, news, book,
                                //meeting_abstract
        Contains ?Paper XREF Contained_in
        Refers_to Gene ?Gene XREF Reference #Evidence
		  Locus ?Locus XREF Reference #Evidence
                  Allele ?Variation XREF Reference #Evidence
                  Rearrangement ?Rearrangement XREF Reference #Evidence
                  Sequence ?Sequence XREF Reference #Evidence
		  CDS ?CDS XREF Reference #Evidence
		  Transcript ?Transcript XREF Reference #Evidence
		  Pseudogene ?Pseudogene XREF Reference #Evidence // new [030801 krb]
                  Strain ?Strain XREF Reference #Evidence
                  Clone ?Clone XREF Reference #Evidence
                  Protein ?Protein XREF Reference #Evidence
                  Expr_pattern ?Expr_pattern XREF Reference #Evidence
                  Expr_profile ?Expr_profile XREF Reference #Evidence
                  Cell ?Cell XREF Reference #Evidence
                  Cell_group ?Cell_group XREF Reference #Evidence
                  Life_stage ?Life_stage XREF Reference #Evidence
                  RNAi ?RNAi XREF Reference #Evidence
                  Transgene ?Transgene XREF Reference #Evidence
                  GO_term ?GO_term XREF Reference ?GO_code #Evidence
                  Operon ?Operon XREF Reference #Evidence
                  Cluster ?Cluster XREF Reference #Evidence
		  Feature ?Feature XREF Defined_by_paper                 // added [030424 dl]
		  Gene_regulation ?Gene_regulation XREF Reference // added [030804 krb]
		  Microarray_experiment ?Microarray_experiment XREF Reference //added for Microarray_experiment model
		  Anatomy_term ?Anatomy_term XREF Reference #Evidence
		  Antibody ?Antibody XREF Reference #Evidence // added [031120 krb]
		  SAGE_experiment ?SAGE_experiment XREF Reference
		  Y2H ?Y2H XREF Reference
		  Interaction ?Interaction XREF Paper
        Keyword ?Keyword

#Evidence Paper_evidence ?Paper                                       // Data from a Paper
          Published_as Gene UNIQUE ?Gene_name #Evidence               //  .. track other names for the same data
          Person_evidence ?Person                                     // Data from a Person
          Author_evidence ?Author UNIQUE Text                         // Data from an Author
          Accession_evidence ?Database ?Accession_number              // Data from a database (NDB/UNIPROT etc)
          Protein_id_evidence ?Text                                   // Reference a protein_ID
          GO_term_evidence ?GO_term                                   // Reference a GO_term
          Expr_pattern_evidence ?Expr_pattern                         // Reference a Expression pattern  
          Microarray_results_evidence ?Microarray_results             // Reference a Microarray result
          RNAi_evidence ?RNAi                                         // Reference a RNAi knockdown
          Gene_regulation_evidence ?Gene_regulation                   // Reference a Gene_regulation interaction
          CGC_data_submission                                         // bless the data as comning from CGC
	  Curator_confirmed ?Person                                   // bless the data manually 
	  Inferred_automatically Text                                 // bless the data via a script

