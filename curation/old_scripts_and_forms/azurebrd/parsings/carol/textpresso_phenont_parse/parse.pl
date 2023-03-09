#!/usr/bin/perl

# Parse PhenOnt.obo according to instructions in
# rule_phenotype_ontology_textpresso from Carol  2007 02 27

use strict;

my %hash;
my $infile = 'PhenOnt.obo';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  if ($_ =~ m/name: (\w+)/) { $hash{$1}++; }
  elsif ($_ =~ m/synonym: \"(\w+)\"/) { $hash{$1}++; }
  else { 1; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $term (sort keys %hash) {
  if ($term =~ m/_sexually_dimorphic/) { $term =~ s/_sexually_dimorphic//g; $term = 'sexually_dimorphic_' .  $term; }
  if ($term =~ m/_reduced/) { $term =~ s/_reduced//g; $term = 'reduced_' .  $term; }
  if ($term =~ m/_increased/) { $term =~ s/_increased//g; $term = 'increased_' .  $term; }
  if ($term =~ m/_decreased/) { $term =~ s/_decreased//g; $term = 'decreased_' .  $term; }
  if ($term =~ m/_variable/) { $term =~ s/_variable//g; $term = 'variable_' .  $term; }
  if ($term =~ m/_asynchronous/) { $term =~ s/_asynchronous//g; $term = 'asynchronous_' . $term; }
  if ($term =~ m/_detached/) { $term =~ s/_detached//g; $term = 'detached_' .  $term; }
  if ($term =~ m/_defective/) { $term =~ s/_defective//g; $term = 'defective_' .  $term; }
  if ($term =~ m/_ectopic/) { $term =~ s/_ectopic//g; $term = 'ectopic_' .  $term; }
  if ($term =~ m/_extra_cells/) { $term =~ s/_extra_cells//g; $term = 'extra_cells_' . $term; }
  if ($term =~ m/_hermaphrodite/) { $term =~ s/_hermaphrodite//g; $term = 'hermaphrodite_' . $term; }

  if ($term =~ m/_rounded/) { 
    if ($term =~ m/_round/) { $term =~ s/_round//g; $term = 'round_' . $term; }
    else { $term =~ s/_rounded//g; $term = 'rounded_' .  $term; } }
  if ($term =~ m/_high/) { 
    if ($term =~ m/_high_/) { $term =~ s/_high_//g; $term = 'high_' . $term; }
    if ($term =~ m/_high$/) { $term =~ s/_high$//g; $term = 'high_' . $term; }
    if ($term =~ m/^high_/) { $term =~ s/^high_//g; $term = 'high_' . $term; } }
  if ($term =~ m/_swollen/) { 
    if ($term =~ m/_swollen_/) { $term =~ s/_swollen_//g; $term = 'swollen_' .  $term; }
    if ($term =~ m/_swollen$/) { $term =~ s/_swollen$//g; $term = 'swollen_' .  $term; }
    if ($term =~ m/^swollen_/) { $term =~ s/^swollen_//g; $term = 'swollen_' .  $term; } }
  if ($term =~ m/_dark/) { 
    if ($term =~ m/_dark_/) { $term =~ s/_dark_//g; $term = 'dark_' . $term; }
    if ($term =~ m/_dark$/) { $term =~ s/_dark$//g; $term = 'dark_' . $term; }
    if ($term =~ m/^dark_/) { $term =~ s/^dark_//g; $term = 'dark_' . $term; } }
  if ($term =~ m/_absent/) {
    if ($term =~ m/_absent_/) { $term =~ s/_absent_//g; $term = 'no_' . $term; }
    if ($term =~ m/_absent$/) { $term =~ s/_absent$//g; $term = 'no_' . $term; }
    if ($term =~ m/^absent_/) { $term =~ s/^absent_//g; $term = 'no_' . $term; } }
  if ($term =~ m/_irregular/) {
    if ($term =~ m/_irregular_/) { $term =~ s/_irregular_//g; $term = 'irregular_' .  $term; }
    if ($term =~ m/_irregular$/) { $term =~ s/_irregular$//g; $term = 'irregular_' .  $term; }
    if ($term =~ m/^irregular_/) { $term =~ s/^irregular_//g; $term = 'irregular_' .  $term; } }
  if ($term =~ m/_small/) {
    if ($term =~ m/_small_/) { $term =~ s/_small_//g; $term = 'small_' . $term; }
    if ($term =~ m/_small$/) { $term =~ s/_small$//g; $term = 'small_' . $term; }
    if ($term =~ m/^small_/) { $term =~ s/^small_//g; $term = 'small_' . $term; } }
  if ($term =~ m/_severe/) {
    if ($term =~ m/_severe_/) { $term =~ s/_severe_//g; $term = 'severe_' . $term; }
    if ($term =~ m/_severe$/) { $term =~ s/_severe$//g; $term = 'severe_' . $term; }
    if ($term =~ m/^severe_/) { $term =~ s/^severe_//g; $term = 'severe_' .  $term; } }
  if ($term =~ m/_rare/) { 
    if ($term =~ m/_rare_/) { $term =~ s/_rare_//g; $term = 'rare_' . $term; }
    if ($term =~ m/_rare$/) { $term =~ s/_rare$//g; $term = 'rare_' . $term; }
    if ($term =~ m/^rare_/) { $term =~ s/^rare_//g; $term = 'rare_' . $term; } }
  if ($term =~ m/_short/) {
    if ($term =~ m/_short_/) { $term =~ s/_short_//g; $term = 'short_' . $term; }
    if ($term =~ m/_short$/) { $term =~ s/_short$//g; $term = 'short_' . $term; }
    if ($term =~ m/^short_/) { $term =~ s/^short_//g; $term = 'short_' . $term; } }
  if ($term =~ m/_slow/) {
    if ($term =~ m/_slow_/) { $term =~ s/_slow_//g; $term = 'slow_' . $term; }
    if ($term =~ m/_slow$/) { $term =~ s/_slow$//g; $term = 'slow_' . $term; }
    if ($term =~ m/^slow_/) { $term =~ s/^slow_//g; $term = 'slow_' . $term; } }
  if ($term =~ m/_long/) { 
    if ($term =~ m/_long_/) { $term =~ s/_long_//g; $term = 'long_' . $term; }
    if ($term =~ m/_long$/) { $term =~ s/_long$//g; $term = 'long_' . $term; }
    if ($term =~ m/^long_/) { $term =~ s/^long_//g; $term = 'long_' . $term; } }
  if ($term =~ m/_swollen/) { $term =~ s/_swollen//g; $term = 'swollen_' .  $term; }
  if ($term =~ m/_twisted/) { $term =~ s/_twisted//g; $term = 'twisted_' .  $term; }
  if ($term =~ m/_withered/) { $term =~ s/_withered//g; $term = 'withered_' .  $term; }
  if ($term =~ m/_shallow/) { $term =~ s/_shallow//g; $term = 'shallow_' .  $term; }
  if ($term =~ m/_excess/) { $term =~ s/_excess//g; $term = 'excess_' . $term; } 
  if ($term =~ m/_nonmotile/) { $term =~ s/_nonmotile//g; $term = 'nonmotile_' .  $term; }
  if ($term =~ m/_etarded/) { $term =~ s/_etarded//g; $term = 'etarded_' .  $term; }
  if ($term =~ m/_hypersensitive/) { $term =~ s/_hypersensitive//g; $term = 'hypersensitive_' . $term; }
  if ($term =~ m/_resistant/) { $term =~ s/_resistant//g; $term = 'resistant_' .  $term; }
  if ($term =~ m/_mistimed/) { $term =~ s/_mistimed//g; $term = 'mistimed_' .  $term; }
  if ($term =~ m/_displaced/) { $term =~ s/_displaced//g; $term = 'displaced_' .  $term; }
  if ($term =~ m/_delayed/) { $term =~ s/_delayed//g; $term = 'delayed_' .  $term; }
  if ($term =~ m/_slippery/) { $term =~ s/_slippery//g; $term = 'slippery_' .  $term; }
  if ($term =~ m/_elongated/) { $term =~ s/_elongated//g; $term = 'elongated_' .  $term; }
  if ($term =~ m/_precocious/) { $term =~ s/_precocious//g; $term = 'precocious_' . $term; }
  if ($term =~ m/_misplaced/) { $term =~ s/_misplaced//g; $term = 'misplaced_' .  $term; }
  if ($term =~ m/_incomplete/) { $term =~ s/_incomplete//g; $term = 'incomplete_' . $term; }
  if ($term =~ m/_prolonged/) { $term =~ s/_prolonged//g; $term = 'prolonged_' .  $term; }
  if ($term =~ m/_infrequent/) { $term =~ s/_infrequent//g; $term = 'infrequent_' . $term; }
  if ($term =~ m/_insensitive/) { $term =~ s/_insensitive//g; $term = 'insensitive_' . $term; }
  if ($term =~ m/_disorganized/) { $term =~ s/_disorganized//g; $term = 'disorganized_' . $term; }
  if ($term =~ m/_malformed/) { $term =~ s/_malformed//g; $term = 'malformed_' .  $term; }
  if ($term =~ m/_undetectable/) { $term =~ s/_undetectable//g; $term = 'undetectable_' . $term; }
  if ($term =~ m/_defective/) { $term =~ s/_defective//g; $term = 'defective_' .  $term; }
  if ($term =~ m/_bulbous/) { $term =~ s/_bulbous//g; $term = 'bulbous_' . $term; }

  if ($term =~ m/_hypersensitive/) { $term =~ s/_hypersensitive//g; $term = 'hypersensitive_to_' . $term; }
  if ($term =~ m/_alteration/) { $term =~ s/_alteration//g; $term = 'alteration_in_' . $term; }
  if ($term =~ m/_failure/) { $term =~ s/_failure//g; $term = 'failure_in_' .  $term; }

  if ($term =~ m/_early_emb$/) { $term =~ s/_early_emb$//g; $term = $term . '_during_early_embryogenesis'; }
  if ($term =~ m/_emb$/) { $term =~ s/_emb$//g; $term = $term .  '_during_embryogenesis'; }
  if ($term =~ m/emb_/) { 
    if ($term =~ m/late_emb_/) { $term =~ s/late_emb_//g; $term = $term .  '_during_late_embryogenesis'; }
    else { $term =~ s/emb_//g; $term = $term .  '_during_embryogenesis'; } }
  if ($term =~ m/two_fold_/) { $term =~ s/two_fold_//g; $term = $term .  '_during_the_two-fold_stage_of_embryogenesis'; }
  if ($term =~ m/_four_emb/) { $term =~ s/_four_emb//g; $term = $term .  '_during_the_one,_two_and_four_cell-stage_of_embryogenesis'; }
  if ($term =~ m/postembryonic_/) { $term =~ s/postembryonic_//g; $term = $term .  '_during_postembryonic_development'; }

  if ($term =~ m/_abnormal/) { $term =~ s/_abnormal//g; $term = 'abnormal_' .  $term; }
  if ($term =~ m/_organism/) { $term =~ s/_organism//g; $term = 'worms_' .  $term; }
  if ($term =~ m/organism_/) { $term =~ s/organism_//g; $term = 'worms_' .  $term; }

#   $term =~ s/early_during_emb/during_early_emb/g;
  $term =~ s/_/ /g;
  print "$term\n";
} # foreach my $term (sort keys %hash)


__END__

[Term]
id: WBPhenotype0000000
name: chromosome_instability
is_a: WBPhenotype0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype0000004
name: constitutive_egg_laying
def: "Eggs are laid in M9, normally an inhibitor of egg laying." [WB:cab]
comment: Liquid M9.
synonym: "Egl_c" BROAD three_letter_name []
is_a: WBPhenotype0000005 ! hyperactive_egg_laying

[Term]
id: WBPhenotype0000026
name: lipid_depleted
synonym: "fat_depleted" RELATED []
synonym: "Lpd" RELATED []
is_a: WBPhenotype0001183 ! fat_content_reduced


where abnormal exists, move to front of term
where early_emb exists, move to end of term and expand to "during early embryogenesis"
where reduced exists, move to front of term
where increased exists, move to front of term
where decreased exists, move to front of term
where variable exists, move to front of term
where emb exists, move to end of term and expand to "during embryogenesis"
where alteration exists, move to front of term and expand to "alteration in"
where late_emb exists, move to end of term and expand to "during late embryogenesis"
where two_fold exists, move to end of term and expand to "during the two-fold stage of embryogenesis"
where slow exists, move to front of term
where one and/or two and/or four precede emb, expand at the end of term to during the one, two and four cell-stage of embryogenesis
where asynchronous exists, move to front of term
where failure exists, move to front of term and expand to "failure in"
where small exists, move to front of term
where detached exists, move to front of term
where defective exists, move to front of term
where severe exists, move to front of term
where postembryonic exists, move to end of term and expand to "during postembryonic development"
where ectopic exists, move to front of term
where absent exists, delete and move no to front of term
where irregular exists, move to front of term
where round exists, move to front of term
where rare exists, move to front of term
where short exists, move to front of term
where extra cells exists, move to front of term
where hermaphrodite exists, move to front of term
where slow exists, move to front of term
where hypersensitive exists, move to front of term
where resistant exists, move to front of term
where long exists, move to front of term
where swollen exists, move to front of term
where twisted exists, move to front of term
where withered, exists move to front of term
where rounded exists, move to front of term
where high exists, move to front of term
where mistimed exists, move to front of term
where swollen exists, move to front of term
where dark exists, move to front of term
where displaced exists, move to front of term
where delayed exists, move to front of term
where slippery exists, move to front of term
where elongated exists, move to front of term
where precocious exists, move to front of term
where misplaced exists, move to front of term
where incomplete exists, move to front of term
where prolonged exists, move to front of term
where shallow exists, move to front of term
where infrequent exists, move to front of term
where excess exists, move to front of term
where nonmotile exists, move to front of term
where insensitive exists, move to front of term
were retarded exists, move to front of term
where disorganized exists, move to front of term
where malformed exists, move to front of term
where undetectable exists, move to front of term
where organism exists, move to very beginning of term and expand to "worm is"
where defective exists, move to front of term
where hypersensitive exists, move to front of term and expand to hypersensitive to

where sexually dimorphic exists, move to front of term, *priority 2



//For Textpresso's use, if there are an "and" or an "or" or an "in" or a "next to" or a "the" or an "is" or an "of" or a "during" or an "a" in the text of a paper, or "with respect to" but all the other terms match, then match to phenotype (epidermis_cuticle_detached)

//Ontology does not use plural in terms
