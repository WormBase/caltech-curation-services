#!/usr/bin/perl -w

# count how many non-spams are submitted for allele form since time $date.  
# 2007 10 12

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @tables = qw( ale_allele ale_alteration_text ale_alteration_type ale_assoc_strain ale_cold_sensitive ale_cold_temp ale_comment ale_curated ale_deletion ale_downstream ale_forward ale_gain_of_function ale_gene ale_genomic ale_genotype ale_haploinsufficient ale_heat_sensitive ale_hot_temp ale_indel_seq ale_ip ale_lab ale_loss_of_function ale_mutagen ale_mutation_info ale_nature_of_allele ale_paper_evidence ale_partial_penetrance ale_penetrance ale_person_evidence ale_phenotypic_description ale_point_mutation_gene ale_reverse ale_seq ale_sequence ale_sequence_insertion ale_species ale_species_other ale_strain ale_submitter_email ale_temperature_sensitive ale_transposon_insertion ale_types_of_alterations ale_types_of_mutations ale_upstream);

my %hash;
my $date = '2006-10-12';

foreach my $table (@tables) {
  my $result = $conn->exec( "SELECT * FROM $table WHERE ale_timestamp > '$date';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $hash{good}{$row[0]}++; }
    if ($row[1] =~ m/a href/i) { $hash{bad}{$row[0]}++; }
    if ($row[2] =~ m/a href/i) { $hash{bad}{$row[0]}++; }
  } # while (@row = $result->fetchrow)
}

my $count;
foreach my $joinkey (sort keys %{ $hash{good} }) { 
  next if ($hash{bad}{$joinkey});
  $count++;
} # foreach my $joinkey (sort keys %{ $hash{good} }) 

print "There are $count alleles that are not spam since $date\n";

__END__

