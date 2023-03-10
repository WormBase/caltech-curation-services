#!/usr/bin/perl -w

# DO NOT USE THIS unless you look at the data, this will wipe out all entries
# with Juancarlos Testing or NULL for curator, which may delete someone else's
# data with the same joinkey.  2005 12 29


use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( alp_cold_degree alp_genotype alp_mat_effect alp_person alp_strain alp_treatment alp_cold_sens alp_go_sug alp_nature alp_phenotype alp_sug_def alp_type alp_curator alp_haplo alp_not alp_preparation alp_suggested alp_wbgene alp_delivered alp_heat_degree alp_paper alp_quantity alp_sug_ref alp_finalname alp_heat_sens alp_pat_effect alp_quantity_remark alp_temperature alp_finished alp_intx_desc alp_penetrance alp_remark alp_tempname alp_func alp_lifestage alp_percent alp_rnai_brief alp_term );

# my %joinkeys;
# my $result = $conn->exec( "SELECT joinkey FROM alp_curator WHERE alp_curator = 'Juancarlos Testing' OR alp_curator IS NULL;" );
# while (my @row = $result->fetchrow) { if ($row[0]) { $joinkeys{$row[0]}++; } }
# 
my @joinkeys = (' tran1', ' tran2', ' tran3', ' tran4', ' tran5', 'temprnai00000001');

foreach my $joinkey (@joinkeys) {
  foreach my $table (@tables) {
    print "DELETE FROM $table WHERE joinkey = '$joinkey';\n";
    my $result = $conn->exec( "DELETE FROM $table WHERE joinkey = '$joinkey';" ); } }
