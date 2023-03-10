#!/usr/bin/perl -w

# Fix 4 new columns for go_curation.cgi by adding NULL data to those columns for got_locus
# that has been created, so that these new columns may be updated by the CGI.  2004 02 05

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @stufftofix = qw( dbtype
                     bio_goterm5 bio_goterm6 bio_goterm7 bio_goterm8
                     bio_goid5 bio_goid6 bio_goid7 bio_goid8
                     bio_paper_evidence5 bio_paper_evidence6 bio_paper_evidence7 bio_paper_evidence8
                     bio_person_evidence5 bio_person_evidence6 bio_person_evidence7 bio_person_evidence8
                     bio_goinference5 bio_goinference6 bio_goinference7 bio_goinference8
                     bio_with1 bio_with2 bio_with3 bio_with4
                     bio_with5 bio_with6 bio_with7 bio_with8
                     bio_qualifier1 bio_qualifier2 bio_qualifier3 bio_qualifier4
                     bio_qualifier5 bio_qualifier6 bio_qualifier7 bio_qualifier8
                     bio_goinference_two5 bio_goinference_two6 bio_goinference_two7 bio_goinference_two8
                     bio_with_two1 bio_with_two2 bio_with_two3 bio_with_two4
                     bio_with_two5 bio_with_two6 bio_with_two7 bio_with_two8
                     bio_qualifier_two1 bio_qualifier_two2 bio_qualifier_two3 bio_qualifier_two4
                     bio_qualifier_two5 bio_qualifier_two6 bio_qualifier_two7 bio_qualifier_two8
                     bio_similarity5 bio_similarity6 bio_similarity7 bio_similarity8
                     bio_comment5 bio_comment6 bio_comment7 bio_comment8
                     cell_goterm5 cell_goterm6 cell_goterm7 cell_goterm8
                     cell_goid5 cell_goid6 cell_goid7 cell_goid8
                     cell_paper_evidence5 cell_paper_evidence6 cell_paper_evidence7 cell_paper_evidence8
                     cell_person_evidence5 cell_person_evidence6 cell_person_evidence7 cell_person_evidence8
                     cell_goinference5 cell_goinference6 cell_goinference7 cell_goinference8
                     cell_with1 cell_with2 cell_with3 cell_with4
                     cell_with5 cell_with6 cell_with7 cell_with8
                     cell_qualifier1 cell_qualifier2 cell_qualifier3 cell_qualifier4
                     cell_qualifier5 cell_qualifier6 cell_qualifier7 cell_qualifier8
                     cell_goinference_two5 cell_goinference_two6 cell_goinference_two7 cell_goinference_two8
                     cell_with_two1 cell_with_two2 cell_with_two3 cell_with_two4
                     cell_with_two5 cell_with_two6 cell_with_two7 cell_with_two8
                     cell_qualifier_two1 cell_qualifier_two2 cell_qualifier_two3 cell_qualifier_two4
                     cell_qualifier_two5 cell_qualifier_two6 cell_qualifier_two7 cell_qualifier_two8
                     cell_similarity5 cell_similarity6 cell_similarity7 cell_similarity8
                     cell_comment5 cell_comment6 cell_comment7 cell_comment8
                     mol_goterm5 mol_goterm6 mol_goterm7 mol_goterm8
                     mol_goid5 mol_goid6 mol_goid7 mol_goid8
                     mol_paper_evidence5 mol_paper_evidence6 mol_paper_evidence7 mol_paper_evidence8
                     mol_person_evidence5 mol_person_evidence6 mol_person_evidence7 mol_person_evidence8
                     mol_goinference5 mol_goinference6 mol_goinference7 mol_goinference8
                     mol_with1 mol_with2 mol_with3 mol_with4
                     mol_with5 mol_with6 mol_with7 mol_with8
                     mol_qualifier1 mol_qualifier2 mol_qualifier3 mol_qualifier4
                     mol_qualifier5 mol_qualifier6 mol_qualifier7 mol_qualifier8
                     mol_goinference_two5 mol_goinference_two6 mol_goinference_two7 mol_goinference_two8
                     mol_with_two1 mol_with_two2 mol_with_two3 mol_with_two4
                     mol_with_two5 mol_with_two6 mol_with_two7 mol_with_two8
                     mol_qualifier_two1 mol_qualifier_two2 mol_qualifier_two3 mol_qualifier_two4
                     mol_qualifier_two5 mol_qualifier_two6 mol_qualifier_two7 mol_qualifier_two8
                     mol_similarity5 mol_similarity6 mol_similarity7 mol_similarity8 );

my $result = $conn->exec( "SELECT joinkey FROM got_locus;" );
while (my @row = $result->fetchrow) { 
  foreach my $table (@stufftofix) {
    my $result2 = $conn->exec( "INSERT INTO got_$table VALUES ('$row[0]', NULL);" );
  }
} # while (my @row = $result->fetchrow)

