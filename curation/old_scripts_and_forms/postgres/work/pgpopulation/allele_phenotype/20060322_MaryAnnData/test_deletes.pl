#!/usr/bin/perl -w

# Quick PG query to get some data.  Template sample.  2004 04 19

use strict;
use diagnostics;
use Pg;

print "pie\n";

my @tables = qw( alp_cold_degree alp_func alp_intx_desc alp_pat_effect alp_quantity alp_suggested alp_type alp_cold_sens alp_genotype alp_lifestage alp_penetrance alp_quantity_remark alp_sug_ref alp_wbgene alp_curator alp_go_sug alp_mat_effect alp_percent alp_remark alp_temperature alp_delivered alp_haplo alp_nature alp_person alp_rnai_brief alp_tempname alp_finalname alp_heat_degree alp_not alp_phenotype alp_strain alp_term alp_finished alp_heat_sens alp_paper alp_preparation alp_sug_def alp_treatment);

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $outfile = "outfile";
# open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $table (@tables) { 
    # TEST
  my $result = $conn->exec( "SELECT * FROM $table WHERE alp_timestamp > '2006-05-12 19:36:00';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { print "$table\t@row\n";}
  }
    # DELETE
#   $result = $conn->exec( "DELETE FROM $table WHERE alp_timestamp > '2006-05-12 19:36:00';" );
}


# close (OUT) or die "Cannot close $outfile : $!";
