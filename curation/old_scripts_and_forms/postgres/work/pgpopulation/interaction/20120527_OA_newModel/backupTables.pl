#!/usr/bin/perl -w

# backup tables that will have data transferred or removed.  2012 05 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $dir = '/home/postgres/work/pgpopulation/interaction/20120527_OA_newModel/backup/';

# my @pgtables = qw( int_nondirectional int_transgeneone int_transgeneonegene int_transgenetwo int_transgenetwogene int_type int_rnai int_geneone int_genetwo int_nondirectional_hst int_transgeneone_hst int_transgeneonegene_hst int_transgenetwo_hst int_transgenetwogene_hst int_type_hst int_rnai_hst int_geneone_hst int_genetwo_hst  );

my @pgtables = qw( int_name int_nondirectional int_type int_geneone int_variationone int_transgeneone int_transgeneonegene int_otheronetype int_otherone int_genetwo int_variationtwo int_transgenetwo int_transgenetwogene int_othertwotype int_othertwo int_curator int_paper int_person int_rnai int_phenotype int_remark int_sentid int_falsepositive int_name_hst int_nondirectional_hst int_type_hst int_geneone_hst int_variationone_hst int_transgeneone_hst int_transgeneonegene_hst int_otheronetype_hst int_otherone_hst int_genetwo_hst int_variationtwo_hst int_transgenetwo_hst int_transgenetwogene_hst int_othertwotype_hst int_othertwo_hst int_curator_hst int_paper_hst int_person_hst int_rnai_hst int_phenotype_hst int_remark_hst int_sentid_hst int_falsepositive_hst );

foreach my $pgtable (@pgtables) {
  my $file = $dir . $pgtable . '.pg';
#   $result = $dbh->do( "COPY $pgtable TO '$file'" );  	# TO BACKUP
  # UNCOMMENT TO RECOVER
#   $result = $dbh->do( "DELETE FROM $pgtable" );     	# TO RECOVER
#   $result = $dbh->do( "COPY $pgtable FROM '$file'" );	# TO RECOVER
} # foreach my $pgtable (@pgtables)

