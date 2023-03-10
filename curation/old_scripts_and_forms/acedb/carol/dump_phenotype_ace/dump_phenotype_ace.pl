#!/usr/bin/perl

# Checkout PhenOnt.obo and process for .ace output
# For Carol.  2006 01 11

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %all_evi;

my %paperid;
my %phenotypeTerms;
my $error_file = 'errorfile';
open (ERR, ">$error_file") or die "Cannot create $error_file : $!";
my $outfile = 'phenotype_from_obo.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

&populateXref();
&readCvs;

sub populateXref {
  my $result = $conn->exec( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      if ($row[3] eq 'valid') { $paperid{$row[1]} = $row[0]; }
        else { if ($paperid{$row[1]}) { delete $paperid{$row[1]}; } } } }
} # sub populateXref

sub readCvs {
  my $directory = '/home/acedb/carol/dump_phenotype_ace';
  chdir($directory) or die "Cannot go to $directory ($!)";
  `cvs -d /var/lib/cvsroot checkout PhenOnt`;
  my $file = $directory . '/PhenOnt/PhenOnt.obo';
  $/ = "";
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $para = <IN>) {  
    if ($para =~ m/id: WBPhenotype:(\d+).*?\bname: (\w+)/s) {
      my $name = $2; my $number = 'WBPhenotype' . $1;
      $phenotypeTerms{$number}{name} = $name;
      if ($para =~ m/\ndef: "(.*?)" \[(.*?)\]/) {
        my $description = $1; my $evi_long = $2;
        my $line = "Description\t\"$description\"";
        if ($evi_long) { $phenotypeTerms{$number}{desc} = &attachEvi($line, $evi_long); } 
          else { $phenotypeTerms{$number}{desc} = "$line\n"; }
        $phenotypeTerms{$number}{evi} = $evi_long;
      }
#       if ($para =~ m/\nrelated_synonym:.*\n/) {
#         my (@syn_lines) = $para =~ m/(related_synonym:.*)/g;
#         foreach my $syn_line (@syn_lines) { 
#           if ($syn_line =~ m/related_synonym: "(.*?)" \[(.*?)\]/) {
#             my $syn_long = $1; my $evi_long = $2;
#             my $line = '';
#             if ($syn_long =~ m/^([A-Z][a-z][a-z](\_.*)?)/) { 
#                 my $syn = $1;
#                 if ($evi_long) { $line = &attachEvi("Short_name\t\"$syn\"", $evi_long); }
#                   else { $line = "Short_name\t\"$syn\"\t$evi_long\n"; } }
#               else { 
#                 if ($evi_long) { $line = &attachEvi("Synonym\t\"$syn_long\"", $evi_long); }
#                   else { $line = "Synonym\t\"$syn_long\"\t$evi_long\n"; } }
#             $phenotypeTerms{$number}{syn} .= $line;
#       } } }
      if ($para =~ m/\nsynonym/) {
        my (@syn_lines) = $para =~ m/\n(synonym:.*)\n/g;
        foreach my $syn_line (@syn_lines) { 
          my ($syn, $evi_long) = $syn_line =~ m/synonym:\s+\"([^"]+)\".*?\[(.*?)\]/;
          my $line = '';
          if ($syn_line =~ m/three_letter_name/) {
              if ($evi_long) { $line = &attachEvi("Short_name\t\"$syn\"", $evi_long); }
                else { $line = "Short_name\t\"$syn\"\t$evi_long\n"; } }
            else { 
              if ($evi_long) { $line = &attachEvi("Synonym\t\"$syn\"", $evi_long); }
                else { $line = "Synonym\t\"$syn\"\t$evi_long\n"; } }
            $phenotypeTerms{$number}{syn} .= $line;
      } }
      if ($para =~ m/\nis_a:/) {
        my (@isa_lines) = $para =~ m/(is_a: WBPhenotype:\d{7})/g;
        foreach my $isa_line (@isa_lines) {
          if ($isa_line =~ m/is_a: WBPhenotype:(\d{7})/) {
            my $num = "WBPhenotype" . $1;
            $phenotypeTerms{$number}{specof} .= "Specialisation_of\t\"$num\"\n";
            $phenotypeTerms{$num}{genof} .= "Generalisation_of\t\"$number\"\n";
      } } }
  } }
  close (IN) or die "Cannot close $file : $!";
  $directory .= '/PhenOnt';
  `rm -rf $directory`; 
} # sub readCvs 

foreach my $num (sort keys %phenotypeTerms) {
  print OUT "\nPhenotype : \"$num\"\n";
  if ($phenotypeTerms{$num}{name}) { 
      if ($phenotypeTerms{$num}{evi}) { 
          my $line = &attachEvi("Primary_name\t\"$phenotypeTerms{$num}{name}\"", $phenotypeTerms{$num}{evi}); 
          if ($line) { print OUT "$line"; }
            else { print ERR "BAD EVIDENCE $phenotypeTerms{$num}{evi}\n"; } }
        else { print OUT "Primary_name\t\"$phenotypeTerms{$num}{name}\"\n"; } }
    else { print ERR "ERROR $num HAS NO NAME\n"; }
  if ($phenotypeTerms{$num}{desc}) { 
      print OUT "$phenotypeTerms{$num}{desc}"; }
  if ($phenotypeTerms{$num}{syn}) { 
      print OUT "$phenotypeTerms{$num}{syn}"; }
  if ($phenotypeTerms{$num}{specof}) { 
      print OUT "$phenotypeTerms{$num}{specof}"; }
  if ($phenotypeTerms{$num}{genof}) { 
      print OUT "$phenotypeTerms{$num}{genof}"; }
} # foreach my $num (sort keys %phenotypeTerms)

# foreach my $evi (sort keys %all_evi) { print ERR "$evi\n"; }

close (ERR) or die "Cannot close $error_file : $!";
close (OUT) or die "Cannot close $outfile : $!";

sub attachEvi {
  my ($line, $evi) = @_;
  my $lines;
  my @evi; my @tran_evi;
  if ($evi =~ m/, /) { @evi = split/, /, $evi; } else { push @evi, $evi; }
  foreach my $evi (@evi) { $all_evi{$evi}++; }
  foreach my $evi (@evi) { 
    if ($evi =~ m/WB:(WBPaper\d+)/) { push @tran_evi, "Paper_evidence\t\"$1\""; }
    elsif ($evi =~ m/WB:WBperson557/) { push @tran_evi, "Curator_confirmed\t\"WBPerson557\""; }
    elsif ($evi =~ m/WB:WBPerson557/) { push @tran_evi, "Curator_confirmed\t\"WBPerson557\""; }
    elsif ($evi =~ m/WB:(WBPerson\d+)/) { push @tran_evi, "Person_evidence\t\"$1\""; }
    elsif ($evi =~ m/WB:WBperson(\d+)/) { push @tran_evi, "Person_evidence\t\"WBPerson$1\""; }
    elsif ($evi =~ m/WB:cab/) { push @tran_evi, "Curator_confirmed\t\"WBPerson48\""; }
    elsif ($evi =~ m/WB:kmva/) { push @tran_evi, "Curator_confirmed\t\"WBPerson1843\""; }
    elsif ($evi =~ m/WB:rk/) { push @tran_evi, "Curator_confirmed\t\"WBPerson324\""; }
    elsif ($evi =~ m/WB:IA/) { push @tran_evi, "Curator_confirmed\t\"WBPerson22\""; }
    elsif ($evi =~ m/WB:ia/) { push @tran_evi, "Curator_confirmed\t\"WBPerson22\""; }
    elsif ($evi =~ m/WB:(cgc\d+)/) { 
      if ($paperid{$1}) { push @tran_evi, "Paper_evidence\t\"$paperid{$1}\""; } }
    elsif ($evi =~ m/cgc:(\d+)/) { my $cgc = 'cgc' . $1; 
      if ($paperid{$cgc}) { push @tran_evi, "Paper_evidence\t\"$paperid{$cgc}\""; } }
    elsif ($evi =~ m/pmid:(\d+)/) { my $pmid = 'pmid' . $1; 
      if ($paperid{$pmid}) { push @tran_evi, "Paper_evidence\t\"$paperid{$pmid}\""; } }
    elsif ($evi =~ m/XX:/) { 1; }		# ignore placeholder
    elsif ($evi =~ m/(GO:\d+)/) { my $goterm = $1; }		# FIX, do something with this go term
    else { print ERR "NOT a convertible evidence $evi\n"; }
  }
  foreach my $evi (@tran_evi) { $lines .= "$line\t$evi\n"; }
  return $lines;
} # sub attachEvi

__END__

format-version: 1.0
date: 11:01:2006 11:49
saved-by: carolbas
auto-generated-by: OBO-Edit 1.000-beta8
default-namespace: C_elegans_phenotype_ontology

[Term]
id: WBPhenotype:0000000
name: chromosome_instability
is_a: WBPhenotype:0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000001
name: body_posture_abnormal
def: "Characteristic sinusoidal body posture is altered." [WB:cab]
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000002
name: kinker
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000003
name: flattened_locomotion_path
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0000004
name: constitutive_egg_laying
related_synonym: "Egl_C" []
is_a: WBPhenotype:0000005 ! hyperactive_egg_laying

[Term]
id: WBPhenotype:0000005
name: hyperactive_egg_laying
is_a: WBPhenotype:0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype:0000006
name: egg_laying_defective
def: "Eggs are layed at a slower rate\, eggs are laid at a later stage\, or worms fail to respond to a typical external stimulator of egg laying." [WB:cab]
related_synonym: "Egl_D" []
is_a: WBPhenotype:0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype:0000007
name: bag_of_worms
def: "A worm carcass is formed with retained eggs that hatch inside." [WB:cab]
is_a: WBPhenotype:0000545 ! eggs_retained

[Term]
id: WBPhenotype:0000008
name: hypersensitive_to_anesthetic
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug
is_a: WBPhenotype:0000627 ! anesthetic_response_abnormal

[Term]
id: WBPhenotype:0000009
name: resistant_to_anesthetic
is_a: WBPhenotype:0000011 ! resistant_to_drug
is_a: WBPhenotype:0000627 ! anesthetic_response_abnormal

[Term]
id: WBPhenotype:0000010
name: hypersensitive_to_drug
is_a: WBPhenotype:0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype:0000011
name: resistant_to_drug
is_a: WBPhenotype:0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype:0000012
name: dauer_constitutive
def: "Any abnormality that results in the formation of dauer larvae under otherwise favorable environmental\, or growth\, conditions." [WB:kmva]
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000013
name: dauer_defective
def: "Any abnormality that results in failure to form dauer larvae under dauer-inducing conditions." [WB:kmva]
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000015
name: chemotaxis_defective
def: "Failure to move towards typically attractive chemicals." [WB:cab]
is_a: WBPhenotype:0000635 ! chemotaxis_abnormal

[Term]
id: WBPhenotype:0000016
name: aldicarb_hypersensitive
related_synonym: "Hic" []
is_a: WBPhenotype:0000500 ! acetylcholinesterase_inhibitor_hypersensitive

[Term]
id: WBPhenotype:0000017
name: aldicarb_resistant
related_synonym: "Ric" []
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000018
name: pharyngeal_pumping_increased
is_a: WBPhenotype:0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype:0000019
name: pharyngeal_pumping_decreased
is_a: WBPhenotype:0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype:0000020
name: pharyngeal_pumping_irregular
is_a: WBPhenotype:0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype:0000021
name: squat
related_synonym: "Sqt" []
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000022
name: long
related_synonym: "Lon" []
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000023
name: serotonin_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000024
name: serotonin_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000025
name: blistered
related_synonym: "Bli" []
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal
is_a: WBPhenotype:0000703 ! epithelial_morphology_abnormal

[Term]
id: WBPhenotype:0000026
name: lipid_depleted
related_synonym: "Lpd" []
related_synonym: "fat_depleted" []
is_a: WBPhenotype:0000725 ! lipid_metabolism_abnormal

[Term]
id: WBPhenotype:0000027
name: organism_metabolism_processing_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000028
name: RNA_processing_abnormal
is_a: WBPhenotype:0000027 ! organism_metabolism_processing_abnormal
is_a: WBPhenotype:0000113 ! RNA_expression_abnormal

[Term]
id: WBPhenotype:0000029
name: systemic_RNAi_abnormal
is_a: WBPhenotype:0000743 ! RNAi_response_abnormal

[Term]
id: WBPhenotype:0000030
name: growth_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000031
name: slow_growth
related_synonym: "Gro" []
is_a: WBPhenotype:0000030 ! growth_abnormal

[Term]
id: WBPhenotype:0000032
name: sick
related_synonym: "Sck" []
is_a: WBPhenotype:0000030 ! growth_abnormal

[Term]
id: WBPhenotype:0000033
name: developmental_timing_defects
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000034
name: embryonic_polarity_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000035
name: larval_body_morphology_abnormal
is_a: WBPhenotype:0000934 ! developmental_morphology_abnormal

[Term]
id: WBPhenotype:0000036
name: adult_body_morphology_abnormal
is_a: WBPhenotype:0000934 ! developmental_morphology_abnormal

[Term]
id: WBPhenotype:0000037
name: embryonic_body_morphology_abnormal
is_a: WBPhenotype:0000934 ! developmental_morphology_abnormal

[Term]
id: WBPhenotype:0000038
name: exploded_through_vulva
related_synonym: "Rup" []
related_synonym: "gonad_exploded_through_vulva" []
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000039
name: longevity_abnormal
is_a: WBPhenotype:0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype:0000040
name: one_cell_arrest
related_synonym: "Ocs" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000041
name: osmotic_integrity_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000042
name: slow_embryonic_development
related_synonym: "Sle" []
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000043
name: general_pace_of_development_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal
is_a: WBPhenotype:0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype:0000044
name: egg_size_abnormal_emb
def: "Egg is smaller or larger than normal." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000037 ! embryonic_body_morphology_abnormal
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000045
name: developmental_delay
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000046
name: pace_of_p_lineage_abnormal_emb
def: "More than five minutes between AB and P1 divisions." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000099 ! P_lineage_abnormal

[Term]
id: WBPhenotype:0000047
name: gastrulation_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000048
name: hatching_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000049
name: postembryonic_development_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000050
name: embryonic_lethal
related_synonym: "Emb" []
related_synonym: "embryonic_death" []
is_a: WBPhenotype:0000062 ! lethal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000051
name: embryonic_terminal_arrest_variable
related_synonym: "Etv" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000052
name: maternal_effect_lethal
related_synonym: "Mel" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000053
name: paralyzed_arrested_elongation_at_two_fold
def: "Mutant embryos do not move (wild-type embryos move soon after they reach the one-and-one-half-fold stage of elongation)\, and elongation in mutants arrests at the two-fold stage. Development in mutants continues (e.g. pharyngeal and cuticle formation is normal)\, but the myofilament lattice in body wall muscle cells is abnormal.  Embryos hatch as inviable larvae." [WB:cab, WB:cgc1894]
related_synonym: "Pat" []
related_synonym: "active_elongation_arrest" []
related_synonym: "two_fold_arrest" []
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000054
name: larval_lethal
related_synonym: "Let" []
related_synonym: "Lvl" []
related_synonym: "larval_death" []
is_a: WBPhenotype:0000062 ! lethal

[Term]
id: WBPhenotype:0000055
name: early_larval_arrest
def: "Larval arrest during the L1 or L2 stages of larval development." [WB:cab]
is_a: WBPhenotype:0000059 ! larval_arrest

[Term]
id: WBPhenotype:0000056
name: late_larval_arrest
def: "Larval arrest during the L3 or L4 stages of larval development." [WB:cab]
is_a: WBPhenotype:0000059 ! larval_arrest

[Term]
id: WBPhenotype:0000057
name: early_larval_lethal
is_a: WBPhenotype:0000054 ! larval_lethal

[Term]
id: WBPhenotype:0000058
name: late_larval_lethal
related_synonym: "Let" []
is_a: WBPhenotype:0000054 ! larval_lethal

[Term]
id: WBPhenotype:0000059
name: larval_arrest
related_synonym: "Lva" []
is_a: WBPhenotype:0000750 ! larval_development_abnormal
is_a: WBPhenotype:0001016 ! larval_growth_abnormal

[Term]
id: WBPhenotype:0000060
name: adult_early_lethal
is_a: WBPhenotype:0000062 ! lethal

[Term]
id: WBPhenotype:0000061
name: extended_life_span
is_a: WBPhenotype:0000039 ! longevity_abnormal

[Term]
id: WBPhenotype:0000062
name: lethal
is_a: WBPhenotype:0000039 ! longevity_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000063
name: terminal_arrest_variable
related_synonym: "Var" []
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000064
name: sex_specific_lethality
is_a: WBPhenotype:0000062 ! lethal
is_a: WBPhenotype:0000822 ! sex_determination_abnormal

[Term]
id: WBPhenotype:0000065
name: male_specific_lethality
is_a: WBPhenotype:0000064 ! sex_specific_lethality

[Term]
id: WBPhenotype:0000066
name: hermaphrodite_specific_lethality
is_a: WBPhenotype:0000064 ! sex_specific_lethality

[Term]
id: WBPhenotype:0000067
name: organism_stress_response_abnormal
is_a: WBPhenotype:0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype:0000068
name: oxidative_stress_response_abnormal
is_a: WBPhenotype:0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype:0000069
name: progeny_abnormal
is_a: WBPhenotype:0000518 ! Development_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000070
name: male_tail_abnormal
is_a: WBPhenotype:0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype:0000071
name: head_morphology_abnormal
is_a: WBPhenotype:0000582 ! organism_segment_morphology_abnormal

[Term]
id: WBPhenotype:0000072
name: body_morphology_abnormal
is_a: WBPhenotype:0000582 ! organism_segment_morphology_abnormal

[Term]
id: WBPhenotype:0000073
name: tail_morphology_abnormal
is_a: WBPhenotype:0000582 ! organism_segment_morphology_abnormal

[Term]
id: WBPhenotype:0000074
name: genetic_pathway_abnormal
is_a: WBPhenotype:0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype:0000075
name: cuticle_attachment_abnormal
is_a: WBPhenotype:0000201 ! cuticle_development_abnormal

[Term]
id: WBPhenotype:0000076
name: epithelial_attachment_abnormal
related_synonym: "hypodermal_attachment_abnormal" []
is_a: WBPhenotype:0000608 ! epithelial_system_physiology_abnormal

[Term]
id: WBPhenotype:0000077
name: cuticle_shedding_abnormal
is_a: WBPhenotype:0000638 ! molt_defect

[Term]
id: WBPhenotype:0000078
name: seam_cells_stacked
is_a: WBPhenotype:0000703 ! epithelial_morphology_abnormal

[Term]
id: WBPhenotype:0000079
name: branched_adult_alae
is_a: WBPhenotype:0000948 ! cuticle_morphology_abnormal

[Term]
id: WBPhenotype:0000080
name: no_anterior_pharynx
is_a: WBPhenotype:0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype:0000081
name: L1_arrest
alt_id: WBPhenotype:0000115
is_a: WBPhenotype:0000055 ! early_larval_arrest
is_a: WBPhenotype:0000751 ! L1_larval_development_abnormal

[Term]
id: WBPhenotype:0000082
name: L2_arrest
is_a: WBPhenotype:0000055 ! early_larval_arrest
is_a: WBPhenotype:0000752 ! L2_larval_development_abnormal
is_a: WBPhenotype:0001019 ! mid_larval_arrest

[Term]
id: WBPhenotype:0000083
name: L3_arrest
is_a: WBPhenotype:0000056 ! late_larval_arrest
is_a: WBPhenotype:0000753 ! L3_larval_development_abnormal
is_a: WBPhenotype:0001019 ! mid_larval_arrest

[Term]
id: WBPhenotype:0000084
name: L4_arrest
is_a: WBPhenotype:0000056 ! late_larval_arrest
is_a: WBPhenotype:0000754 ! L4_larval_development_abnormal

[Term]
id: WBPhenotype:0000085
name: swollen_intestine
is_a: WBPhenotype:0000710 ! intestinal_morphology_abnormal

[Term]
id: WBPhenotype:0000086
name: shrunken_intestine
is_a: WBPhenotype:0000710 ! intestinal_morphology_abnormal

[Term]
id: WBPhenotype:0000087
name: body_wall_cell_development_abnormal
is_a: WBPhenotype:0000861 ! body_wall_muscle_development_abnormal

[Term]
id: WBPhenotype:0000088
name: body_muscle_displaced
is_a: WBPhenotype:0000861 ! body_wall_muscle_development_abnormal

[Term]
id: WBPhenotype:0000089
name: alpha_amanitin_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000090
name: epidermis_cuticle_detached
related_synonym: "hypodermis_detached_from_cuticle" []
is_a: WBPhenotype:0000076 ! epithelial_attachment_abnormal

[Term]
id: WBPhenotype:0000091
name: epidermis_muscle_detached
related_synonym: "hypodermis_detached_from_muscle" []
is_a: WBPhenotype:0000076 ! epithelial_attachment_abnormal
is_a: WBPhenotype:0000474 ! muscle_attachment_abnormal

[Term]
id: WBPhenotype:0000092
name: intestinal_cell_proliferation_abnormal
is_a: WBPhenotype:0000705 ! intestinal_cell_development_abnormal

[Term]
id: WBPhenotype:0000093
name: lineage_abnormal
related_synonym: "Lin" []
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000094
name: anus_development_abnormal
is_a: WBPhenotype:0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype:0000095
name: M_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000096
name: cloacal_development_abnormal
is_a: WBPhenotype:0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype:0000097
name: AB_lineage_abnormal
is_a: WBPhenotype:0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000098
name: pharyngeal_intestinal_valve_development_abnormal
is_a: WBPhenotype:0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype:0000099
name: P_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000100
name: cell_UV_response_abnormal
is_a: WBPhenotype:0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype:0000101
name: UV_induced_apoptosis
is_a: WBPhenotype:0000100 ! cell_UV_response_abnormal

[Term]
id: WBPhenotype:0000102
name: slightly_lipid_depleted
related_synonym: "slightly_fat_depleted" []
is_a: WBPhenotype:0000026 ! lipid_depleted

[Term]
id: WBPhenotype:0000103
name: moderately_lipid_depleted
related_synonym: "moderately_fat_depleted" []
is_a: WBPhenotype:0000026 ! lipid_depleted

[Term]
id: WBPhenotype:0000104
name: severely_lipid_depleted
related_synonym: "severely_fat_depleted" []
is_a: WBPhenotype:0000026 ! lipid_depleted

[Term]
id: WBPhenotype:0000105
name: oocyte_maturation_abnormal
related_synonym: "Oma" []
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000106
name: inhibition_of_oocyte_maturation_abnormal
is_a: WBPhenotype:0000105 ! oocyte_maturation_abnormal

[Term]
id: WBPhenotype:0000107
name: inhibition_of_ovulation_abnormal
is_a: WBPhenotype:0000666 ! ovulation_abnormal

[Term]
id: WBPhenotype:0000108
name: severe_dumpy
is_a: WBPhenotype:0000583 ! dumpy

[Term]
id: WBPhenotype:0000109
name: moderate_dumpy
is_a: WBPhenotype:0000583 ! dumpy

[Term]
id: WBPhenotype:0000110
name: slightly_dumpy
is_a: WBPhenotype:0000583 ! dumpy

[Term]
id: WBPhenotype:0000111
name: pattern_of_gene_expression_abnormal
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000112
name: protein_expression_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000113
name: RNA_expression_abnormal
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000114
name: mRNA_expression_abnormal
is_a: WBPhenotype:0000113 ! RNA_expression_abnormal

[Term]
id: WBPhenotype:0000116
name: mid_larval_lethal
related_synonym: "Let" []
is_a: WBPhenotype:0000054 ! larval_lethal

[Term]
id: WBPhenotype:0000117
name: L1_lethal
is_a: WBPhenotype:0000057 ! early_larval_lethal

[Term]
id: WBPhenotype:0000118
name: L2_lethal
is_a: WBPhenotype:0000057 ! early_larval_lethal
is_a: WBPhenotype:0000116 ! mid_larval_lethal

[Term]
id: WBPhenotype:0000119
name: protein_expression_levels_high
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000120
name: protein_expression_levels_reduced
def: "Any change that results in lower than normal levels of protein expression." [WB:kmva]
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000121
name: translation_abnormal
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000122
name: post_translational_processing_abnormal
is_a: WBPhenotype:0000027 ! organism_metabolism_processing_abnormal
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000123
name: enzyme_expression_levels_reduced
is_a: WBPhenotype:0000120 ! protein_expression_levels_reduced

[Term]
id: WBPhenotype:0000124
name: enzyme_activity_low
is_a: WBPhenotype:0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype:0000125
name: enzyme_activity_high
is_a: WBPhenotype:0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype:0000126
name: pace_of_development_slow_embryo_emb
def: "More than 30 minutes from PN meeting to furrow initiation in AB." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000043 ! general_pace_of_development_abnormal
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000127
name: dauer_recovery_abnormal
def: "Characteristic exit fro mthe dauer stage is altered." [WB:cab]
is_a: WBPhenotype:0000049 ! postembryonic_development_abnormal
is_a: WBPhenotype:0001001 ! dauer_behavior_abnormal

[Term]
id: WBPhenotype:0000128
name: temperature_induced_dauer_formation_enhanced
def: "Daur larvae are more likely to form at high temperature\, even in the presence of food." [WB:cgc424]
related_synonym: "Hid" []
is_a: WBPhenotype:0000639 ! temperature_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000129
name: temperature_induced_dauer_formation_reduced
is_a: WBPhenotype:0000013 ! dauer_defective
is_a: WBPhenotype:0000639 ! temperature_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000130
name: pheromone_induced_dauer_formation_enhance
is_a: WBPhenotype:0000132 ! pheromone_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000131
name: pheromone_induced_dauer_formation_reduced
is_a: WBPhenotype:0000013 ! dauer_defective
is_a: WBPhenotype:0000132 ! pheromone_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000132
name: pheromone_induced_dauer_formation_abnormal
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000133
name: expression_of_lipogenic_enzymes_reduced
is_a: WBPhenotype:0000123 ! enzyme_expression_levels_reduced

[Term]
id: WBPhenotype:0000134
name: gene_expression_levels_reduced
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000135
name: gene_expression_levels_high
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000136
name: mRNA_levels_high
is_a: WBPhenotype:0000114 ! mRNA_expression_abnormal

[Term]
id: WBPhenotype:0000137
name: mRNA_levels_low
is_a: WBPhenotype:0000114 ! mRNA_expression_abnormal

[Term]
id: WBPhenotype:0000138
name: lipid_composition_abnormal
related_synonym: "fat_composition_abnormal" []
related_synonym: "fatty_acid_composition_abnormal" []
is_a: WBPhenotype:0000725 ! lipid_metabolism_abnormal

[Term]
id: WBPhenotype:0000139
name: stress_induced_lethality_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000140
name: stress_induced_arrest_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000141
name: stress_induced_lethality_enhanced
is_a: WBPhenotype:0000139 ! stress_induced_lethality_abnormal

[Term]
id: WBPhenotype:0000142
name: cell_stress_response_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000143
name: organism_UV_response_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000144
name: salmonella_induced_cell_death_enhanced
is_a: WBPhenotype:0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype:0000145
name: fertility_abnormal
is_a: WBPhenotype:0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype:0000146
name: organism_temperature_response_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000147
name: organism_starvation_response_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000148
name: starvation_induced_dauer_formation_abnormal
is_a: WBPhenotype:0000147 ! organism_starvation_response_abnormal
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000149
name: starvation_induced_dauer_formation_enhanced
is_a: WBPhenotype:0000148 ! starvation_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000150
name: starvation_induced_dauer_formation_reduced
is_a: WBPhenotype:0000013 ! dauer_defective
is_a: WBPhenotype:0000148 ! starvation_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000151
name: cleavage_furrows_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000152
name: no_cleavage_furrow_first_division
is_a: WBPhenotype:0000151 ! cleavage_furrows_abnormal

[Term]
id: WBPhenotype:0000153
name: body_wall_contraction_abnormal
relationship: part_of WBPhenotype:0000596 ! body_behavior_abnormal

[Term]
id: WBPhenotype:0000154
name: low_brood_size
is_a: WBPhenotype:0000145 ! fertility_abnormal

[Term]
id: WBPhenotype:0000155
name: body_wall_contraction_defect
is_obsolete: true

[Term]
id: WBPhenotype:0000156
name: body_wall_contraction_interval_abnormal
is_a: WBPhenotype:0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype:0000157
name: pos_body_wall_contraction_abnormal
alt_id: WBPhenotype:0000206
related_synonym: "pBoc" []
related_synonym: "posterior_body_contraction_abnormal" []
related_synonym: "posterior_body_wall_contraction_defective" []
is_a: WBPhenotype:0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype:0000158
name: pos_body_wall_shortened_interval
is_a: WBPhenotype:0000157 ! pos_body_wall_contraction_abnormal

[Term]
id: WBPhenotype:0000159
name: pos_body_wall_contraction_reduced
related_synonym: "pBoc" []
is_obsolete: true

[Term]
id: WBPhenotype:0000160
name: cleavage_furrow_not_discrete
is_a: WBPhenotype:0000151 ! cleavage_furrows_abnormal

[Term]
id: WBPhenotype:0000161
name: nuclear_rotation_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000162
name: pale_larva
related_synonym: "transluscent" []
is_a: WBPhenotype:0000890 ! larval_pigmentation_abnormal

[Term]
id: WBPhenotype:0000163
name: clear_larva
related_synonym: "Clr" []
related_synonym: "transparent" []
is_a: WBPhenotype:0000890 ! larval_pigmentation_abnormal

[Term]
id: WBPhenotype:0000164
name: thin
related_synonym: "slim" []
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000165
name: cell_fusion_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000166
name: seam_cell_fusion_abnormal
is_a: WBPhenotype:0000165 ! cell_fusion_abnormal

[Term]
id: WBPhenotype:0000167
name: precocious_seam_cell_fusion
is_a: WBPhenotype:0000166 ! seam_cell_fusion_abnormal

[Term]
id: WBPhenotype:0000168
name: alae_secretion_abnormal
is_a: WBPhenotype:0000258 ! cell_secretion_abnormal

[Term]
id: WBPhenotype:0000169
name: early_exit_cell_cycle
is_a: WBPhenotype:0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype:0000170
name: precocious_alae_secretion
is_a: WBPhenotype:0000168 ! alae_secretion_abnormal

[Term]
id: WBPhenotype:0000171
name: cell_proliferation_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000172
name: increased_cell_proliferation
is_a: WBPhenotype:0000171 ! cell_proliferation_abnormal

[Term]
id: WBPhenotype:0000173
name: decreased_cell_proliferation
is_a: WBPhenotype:0000171 ! cell_proliferation_abnormal

[Term]
id: WBPhenotype:0000174
name: basal_lamina_development_abnormal
is_a: WBPhenotype:0000619 ! epithelial_system_development_abnormal

[Term]
id: WBPhenotype:0000175
name: hypercontracted
is_a: WBPhenotype:0000001 ! body_posture_abnormal
is_a: WBPhenotype:0000644 ! paralyzed

[Term]
id: WBPhenotype:0000176
name: body_wall_hypercontracted
is_obsolete: true

[Term]
id: WBPhenotype:0000177
name: acetylcholinesterase_reduced
is_a: WBPhenotype:0000124 ! enzyme_activity_low

[Term]
id: WBPhenotype:0000178
name: cell_degeneration
is_a: WBPhenotype:0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype:0000179
name: neuron_degeneration
is_a: WBPhenotype:0000178 ! cell_degeneration

[Term]
id: WBPhenotype:0000180
name: axon_morphology_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000181
name: axon_trajectory_abnormal
is_a: WBPhenotype:0000180 ! axon_morphology_abnormal

[Term]
id: WBPhenotype:0000182
name: apoptosis_reduced
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000183
name: apoptosis_enhanced
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000184
name: apoptosis_fails_to_occur
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000185
name: apoptosis_protracted
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000186
name: oogenesis_abnormal
related_synonym: "oocyte_development_abnormal" []
is_a: WBPhenotype:0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype:0000187
name: egg_round
is_a: WBPhenotype:0000037 ! embryonic_body_morphology_abnormal

[Term]
id: WBPhenotype:0000188
name: gonad_arm_morphology_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000189
name: hypodermis_disorganized
is_a: WBPhenotype:0000703 ! epithelial_morphology_abnormal

[Term]
id: WBPhenotype:0000190
name: no_dauer_recovery
is_a: WBPhenotype:0000127 ! dauer_recovery_abnormal

[Term]
id: WBPhenotype:0000191
name: organism_crowding_response_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000192
name: constitutive_enzyme_activity
is_a: WBPhenotype:0000125 ! enzyme_activity_high

[Term]
id: WBPhenotype:0000193
name: dominant_negative_enzyme
is_a: WBPhenotype:0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype:0000194
name: first_polar_body_position_abnormal
is_a: WBPhenotype:0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype:0000195
name: distal_tip_cell_migration_abnormal
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000196
name: distal_tip_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000197
name: cell_induction_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000198
name: vulval_cell_induction_abnormal
is_a: WBPhenotype:0000197 ! cell_induction_abnormal
is_a: WBPhenotype:0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype:0000199
name: male_tail_sensory_ray_generation_abnormal
is_a: WBPhenotype:0001008 ! male_nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000200
name: pericellular_component_development_abnormal
is_a: WBPhenotype:0000518 ! Development_abnormal

[Term]
id: WBPhenotype:0000201
name: cuticle_development_abnormal
is_a: WBPhenotype:0000200 ! pericellular_component_development_abnormal

[Term]
id: WBPhenotype:0000202
name: alae_abnormal
is_a: WBPhenotype:0000201 ! cuticle_development_abnormal

[Term]
id: WBPhenotype:0000203
name: odorant_adaptation_abnormal
is_a: WBPhenotype:0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype:0000204
name: anterior_body_contraction_defect
related_synonym: "aBoc" []
is_a: WBPhenotype:0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype:0000205
name: expulsion_abnormal
related_synonym: "Exp" []
is_a: WBPhenotype:0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype:0000207
name: defecation_cycle_abnormal
is_a: WBPhenotype:0000650 ! defecation_abnormal

[Term]
id: WBPhenotype:0000208
name: long_defecation_cycle
is_a: WBPhenotype:0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype:0000209
name: short_defecation_cycle
is_a: WBPhenotype:0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype:0000210
name: defecation_contraction_abnormal
is_a: WBPhenotype:0000650 ! defecation_abnormal

[Term]
id: WBPhenotype:0000211
name: defecation_contraction_mistimed
is_a: WBPhenotype:0000210 ! defecation_contraction_abnormal

[Term]
id: WBPhenotype:0000212
name: body_constriction
is_a: WBPhenotype:0000072 ! body_morphology_abnormal

[Term]
id: WBPhenotype:0000213
name: zygotic_development_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000214
name: alpha_amanitin_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000215
name: no_germline
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000216
name: cell_fate_specification_abnormal
def: "Any abnormality in the processes that govern acquisition of particular cell fates." [WB:kmva]
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000217
name: prolonged_pharyngeal_contraction
is_a: WBPhenotype:0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype:0000218
name: vulval_cell_induction_increased
is_a: WBPhenotype:0000198 ! vulval_cell_induction_abnormal

[Term]
id: WBPhenotype:0000219
name: vulval_cell_induction_reduced
is_a: WBPhenotype:0000198 ! vulval_cell_induction_abnormal

[Term]
id: WBPhenotype:0000220
name: VPC_cell_fate_specification_abnormal
is_a: WBPhenotype:0000216 ! cell_fate_specification_abnormal

[Term]
id: WBPhenotype:0000221
name: neurotransmitter_metabolism_abnormal
is_a: WBPhenotype:0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype:0000222
name: serotonin_metabolism_abnormal
is_a: WBPhenotype:0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype:0000223
name: acetylcholine_metabolism_abnormal
is_a: WBPhenotype:0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype:0000224
name: serotonin_deficient
is_a: WBPhenotype:0000222 ! serotonin_metabolism_abnormal

[Term]
id: WBPhenotype:0000225
name: serotonin_synthesis_defective
is_a: WBPhenotype:0000222 ! serotonin_metabolism_abnormal

[Term]
id: WBPhenotype:0000226
name: serotonin_catabolism_defective
is_a: WBPhenotype:0000222 ! serotonin_metabolism_abnormal

[Term]
id: WBPhenotype:0000227
name: male_turning_abnormal
def: "The inability of a male to properly turn\, via a sharp ventral arch of the tail\, as he approaches either the hermaphrodite head or tail during mating." [WB:WBPaper00000392, WB:WBPaper00002109]
is_a: WBPhenotype:0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0000228
name: spontaneous_mutation_rate_increased
related_synonym: "Mut" []
related_synonym: "mutator" []
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000229
name: small
related_synonym: "Sma" []
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000230
name: tail_withered
is_a: WBPhenotype:0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype:0000232
name: CAN_cell_migration_abnormal
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000233
name: dopamine_metabolism_abnormal
is_a: WBPhenotype:0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype:0000234
name: dopamine_reduced
is_a: WBPhenotype:0000233 ! dopamine_metabolism_abnormal

[Term]
id: WBPhenotype:0000235
name: dopamine_synthesis_defective
is_a: WBPhenotype:0000233 ! dopamine_metabolism_abnormal

[Term]
id: WBPhenotype:0000236
name: dopamine_catabolism_defective
is_a: WBPhenotype:0000233 ! dopamine_metabolism_abnormal

[Term]
id: WBPhenotype:0000237
name: foraging_hyperactive
is_a: WBPhenotype:0000662 ! foraging_behavior_abnormal

[Term]
id: WBPhenotype:0000238
name: foraging_reduced
is_a: WBPhenotype:0000662 ! foraging_behavior_abnormal

[Term]
id: WBPhenotype:0000239
name: vulval_cell_lineage_abnormal
related_synonym: "VPC_lineage_abnormal" []
is_a: WBPhenotype:0000099 ! P_lineage_abnormal

[Term]
id: WBPhenotype:0000240
name: decreased_blast_cell_proliferation
is_a: WBPhenotype:0000173 ! decreased_cell_proliferation

[Term]
id: WBPhenotype:0000241
name: accumulated_cell_corpses
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000242
name: body_elongation_defect
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000243
name: engulfment_failure_by killer
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000244
name: apoptotic_arrest
related_synonym: "apoptosis_block" []
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Term]
id: WBPhenotype:0000245
name: SM_migration_abnormal
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000246
name: defecation_cycle_variable_length
is_a: WBPhenotype:0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype:0000247
name: sodium_chemotaxis_defective
def: "Failure to move towards sodium." [WB:cab, WB:cgc387]
related_synonym: "Na_chemotaxis_defective" []
is_a: WBPhenotype:0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype:0000248
name: sensory_neuroanatomy_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000249
name: osmotic_avoidance_defective
is_a: WBPhenotype:0000663 ! osmotic_avoidance_abnormal

[Term]
id: WBPhenotype:0000250
name: octopamine_metabolism_abnormal
is_a: WBPhenotype:0000221 ! neurotransmitter_metabolism_abnormal

[Term]
id: WBPhenotype:0000251
name: octopamine_deficient
is_a: WBPhenotype:0000250 ! octopamine_metabolism_abnormal

[Term]
id: WBPhenotype:0000252
name: caffeine_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000253
name: movement_erratic
related_synonym: "movement_irregular" []
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000254
name: chloride_chemotaxis_defective
def: "Failure to move towards chloride." [WB:cab, WB:cgc387]
related_synonym: "Cl_chemotaxis_defective" []
is_a: WBPhenotype:0001052 ! anion_chemotaxis_defective

[Term]
id: WBPhenotype:0000255
name: amphid_phasmid_morphology_abnormal
related_synonym: "Dyf" []
related_synonym: "dye_filling_defect" []
is_a: WBPhenotype:0000299 ! sensory_anatomy_abnormal

[Term]
id: WBPhenotype:0000256
name: amphid_morphology_abnormal
is_a: WBPhenotype:0000255 ! amphid_phasmid_morphology_abnormal

[Term]
id: WBPhenotype:0000257
name: phasmid_morphology_abnormal
is_a: WBPhenotype:0000255 ! amphid_phasmid_morphology_abnormal

[Term]
id: WBPhenotype:0000258
name: cell_secretion_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000259
name: sheath_cell_secretion_abnormal
is_a: WBPhenotype:0000258 ! cell_secretion_abnormal

[Term]
id: WBPhenotype:0000260
name: sheath_cell_secretion_failure
is_a: WBPhenotype:0000259 ! sheath_cell_secretion_abnormal

[Term]
id: WBPhenotype:0000261
name: amphid_sheath_secretion_failure
is_a: WBPhenotype:0000260 ! sheath_cell_secretion_failure

[Term]
id: WBPhenotype:0000262
name: axoneme_morphology_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000263
name: axoneme_shortened
is_a: WBPhenotype:0000262 ! axoneme_morphology_abnormal

[Term]
id: WBPhenotype:0000264
name: camp_chemotaxis_defective
def: "Characteristic movement towards cAMP is altered." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001053 ! cyclic_nucleotide_chemotaxis_defective

[Term]
id: WBPhenotype:0000265
name: volatile_odorant_chemotaxis_defective
def: "Failure to move towards typically attractive volatile organic molecules\, sensed by the AWA and AWC neurons." [WB:cab, WB:cgc1786]
is_a: WBPhenotype:0000015 ! chemotaxis_defective
is_a: WBPhenotype:0001048 ! volatile_chemosensory_response_abnormal

[Term]
id: WBPhenotype:0000266
name: cell_cleavage_abnormal
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0000267
name: cell_cleavage_delayed
is_a: WBPhenotype:0000266 ! cell_cleavage_abnormal

[Term]
id: WBPhenotype:0000268
name: P_cell_cleavage_delayed
is_a: WBPhenotype:0000267 ! cell_cleavage_delayed

[Term]
id: WBPhenotype:0000269
name: Unclassified

[Term]
id: WBPhenotype:0000270
name: pleiotropic_defects_severe_emb
def: "Often multiple pronuclei\, aberrant cytoplasmic texture\, drop in overall pace of development\, osmotic sensitivity." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000271
name: cell_cycle_slow
is_a: WBPhenotype:0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype:0000272
name: egg_laying_irregular
is_a: WBPhenotype:0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype:0000273
name: swimming_defect
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0000274
name: dead_eggs_laid
is_a: WBPhenotype:0000145 ! fertility_abnormal

[Term]
id: WBPhenotype:0000275
name: organism_hypersensitive_UV
is_a: WBPhenotype:0000143 ! organism_UV_response_abnormal

[Term]
id: WBPhenotype:0000276
name: organism_X_ray_response_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000277
name: rhythms_slow
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000278
name: body_region_pigmentation_abnormal
is_a: WBPhenotype:0000521 ! Pigmentation_abnormal

[Term]
id: WBPhenotype:0000279
name: spicule_insertion_defective
is_a: WBPhenotype:0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0000280
name: breaks_in_alae
is_a: WBPhenotype:0000948 ! cuticle_morphology_abnormal

[Term]
id: WBPhenotype:0000281
name: male_sex_muscle_abnormal
is_a: WBPhenotype:0000669 ! sex_muscle_abnormal

[Term]
id: WBPhenotype:0000282
name: hermaphrodite_sex_muscle_abnormal
is_a: WBPhenotype:0000669 ! sex_muscle_abnormal

[Term]
id: WBPhenotype:0000283
name: vulva_uterus_connection_defect
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000284
name: sperm_transfer_defective
is_a: WBPhenotype:0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0000285
name: ray_tips_swollen
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000286
name: embryo_disorganized
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000287
name: vulval_invagination_L4_abnormal
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000288
name: distal_germline_abnormal
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000289
name: uterus_morphology_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000290
name: no_sperm
is_a: WBPhenotype:0000395 ! no_differentiated_gametes

[Term]
id: WBPhenotype:0000291
name: no_oocytes
is_a: WBPhenotype:0000395 ! no_differentiated_gametes

[Term]
id: WBPhenotype:0000292
name: organ_system_pigmentation_abnormal
is_a: WBPhenotype:0000521 ! Pigmentation_abnormal

[Term]
id: WBPhenotype:0000293
name: alimentary_system_pigmentation_abnormal
is_a: WBPhenotype:0000292 ! organ_system_pigmentation_abnormal

[Term]
id: WBPhenotype:0000294
name: intestine_dark
is_a: WBPhenotype:0000293 ! alimentary_system_pigmentation_abnormal

[Term]
id: WBPhenotype:0000295
name: thermotolerance_increased
is_a: WBPhenotype:0000146 ! organism_temperature_response_abnormal

[Term]
id: WBPhenotype:0000296
name: spicules_crumpled
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000297
name: rays_fused
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000298
name: rays_displaced
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000299
name: sensory_anatomy_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000300
name: amphidial_sheath_cells_abnormal
is_a: WBPhenotype:0000299 ! sensory_anatomy_abnormal

[Term]
id: WBPhenotype:0000301
name: distal_tip_cell_reflex_failure
is_a: WBPhenotype:0000195 ! distal_tip_cell_migration_abnormal

[Term]
id: WBPhenotype:0000302
name: benzaldehyde_chemotaxis_defective
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0000303
name: diacetyl_chemotaxis_defective
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0000304
name: isoamyl_alcohol_chemotaxis_defective
def: "Failure to move towards typically attractive concentrations of isoamyl alcohol." [WB:cab, WB:cgc1786]
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0000305
name: pheromone_sensation_abnormal
is_a: WBPhenotype:0000132 ! pheromone_induced_dauer_formation_abnormal

[Term]
id: WBPhenotype:0000306
name: transgene_expression_abnormal
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000307
name: dauer_pheromone_sensation_defective
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000308
name: dauer_development_abnormal
def: "Any abnormality in the processes that govern development of the dauer larva\, a developmentally arrested\, alternative third larval stage that is specialized for survival under harsh\, or otherwise unfavorable\, environmental conditions." [WB:kmva]
is_a: WBPhenotype:0000049 ! postembryonic_development_abnormal

[Term]
id: WBPhenotype:0000309
name: SDS_sensitive_dauer
is_a: WBPhenotype:0000308 ! dauer_development_abnormal

[Term]
id: WBPhenotype:0000310
name: cilia_missing_sensory_neuron
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000311
name: semi_sterile
is_a: WBPhenotype:0000145 ! fertility_abnormal

[Term]
id: WBPhenotype:0000312
name: dauer_pheromone_production_defective
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000313
name: meiosis_progression_during_oogenesis
is_a: WBPhenotype:0000186 ! oogenesis_abnormal

[Term]
id: WBPhenotype:0000314
name: scrawny
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000315
name: mechanosensory_abnormal
def: "Alteration with respect to perception or response to mechanical stimuli." [WB:cab]
related_synonym: "Mec" []
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000316
name: touch_insensitive_tail
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0000317
name: head_withdrawal_defect
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0000318
name: cell_cycle_delayed
is_a: WBPhenotype:0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype:0000319
name: large
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000320
name: reduced_viability_after_freezing
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000321
name: nose_morphology_abnormal
is_a: WBPhenotype:0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype:0000322
name: round_nose
is_a: WBPhenotype:0000321 ! nose_morphology_abnormal

[Term]
id: WBPhenotype:0000323
name: head_swollen
is_a: WBPhenotype:0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype:0000324
name: short
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000325
name: arecoline_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000326
name: arecoline_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000327
name: corpus_contraction_defect
is_a: WBPhenotype:0000747 ! pharyngeal_contraction_defect

[Term]
id: WBPhenotype:0000328
name: terminal_bulb_contraction_abnormal
is_a: WBPhenotype:0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype:0000329
name: pumping_nonsynchronized
is_a: WBPhenotype:0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype:0000330
name: pharyngeal_relaxation_defect
is_a: WBPhenotype:0001004 ! pharyngeal_relaxation_abnormal

[Term]
id: WBPhenotype:0000331
name: inhibitors_of_na_k_atpase_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000332
name: inhibitors_of_na_k_atpase_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000333
name: pharyngeal_pumps_brief
is_a: WBPhenotype:0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype:0000334
name: isthmus_corpus_slippery
is_a: WBPhenotype:0000335 ! pharynx_slippery

[Term]
id: WBPhenotype:0000335
name: pharynx_slippery
is_a: WBPhenotype:0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype:0000336
name: terminal_bulb_relaxation_abnormal
is_a: WBPhenotype:0001004 ! pharyngeal_relaxation_abnormal

[Term]
id: WBPhenotype:0000337
name: grinder_relaxation_defective
is_a: WBPhenotype:0000330 ! pharyngeal_relaxation_defect

[Term]
id: WBPhenotype:0000338
name: tail_bulge
is_a: WBPhenotype:0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype:0000339
name: transient_bloating
is_a: WBPhenotype:0000545 ! eggs_retained

[Term]
id: WBPhenotype:0000340
name: imipramine_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000341
name: imipramine_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000342
name: bursa_morphology_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000343
name: cloaca_morphology_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000344
name: cloacal_structures_protrude
is_a: WBPhenotype:0000343 ! cloaca_morphology_abnormal

[Term]
id: WBPhenotype:0000345
name: vpc_cell_division_abnormal
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0000346
name: adult_pigmentation_abnormal
is_a: WBPhenotype:0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype:0000347
name: rectal_development_abnormal
is_a: WBPhenotype:0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype:0000348
name: muscle_activation_defective
related_synonym: "Mac_d" []
xref_analog: PMID:8582640
is_obsolete: true

[Term]
id: WBPhenotype:0000349
name: flaccid
related_synonym: "limp" []
is_a: WBPhenotype:0000001 ! body_posture_abnormal

[Term]
id: WBPhenotype:0000350
name: hermaphrodite_tail_spike
is_a: WBPhenotype:0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype:0000351
name: failure_to_hatch
is_a: WBPhenotype:0000048 ! hatching_abnormal

[Term]
id: WBPhenotype:0000352
name: backing_uncoordinated
is_a: WBPhenotype:0001005 ! backward_locomotion_abnormal

[Term]
id: WBPhenotype:0000353
name: backing_increased
is_a: WBPhenotype:0001005 ! backward_locomotion_abnormal

[Term]
id: WBPhenotype:0000354
name: cell_differentiation_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000355
name: HSN_differentiation_precocious
is_a: WBPhenotype:0000354 ! cell_differentiation_abnormal

[Term]
id: WBPhenotype:0000356
name: spermatogenesis_delayed
is_a: WBPhenotype:0000670 ! spermatogenesis_abnormal

[Term]
id: WBPhenotype:0000357
name: unfertilized_oocytes_laid
is_a: WBPhenotype:0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype:0000358
name: extra_cell_divisions
related_synonym: "supernumerary_cell_divisions" []
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0000359
name: no_pseudocleavage
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000360
name: cytoplasmic_streaming_defect
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000361
name: lima_bean_arrest
related_synonym: "arrest_during_epiboly" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000362
name: blastocoel_abnormal
is_a: WBPhenotype:0000047 ! gastrulation_abnormal

[Term]
id: WBPhenotype:0000363
name: cell_division_slow
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0000364
name: gut_granule_birefringence_misplaced
is_a: WBPhenotype:0000705 ! intestinal_cell_development_abnormal

[Term]
id: WBPhenotype:0000365
name: egg_osmotic_integrity_abnormal_emb
def: "Embryo fills egg shell\, and lyses upon dissection or during recording." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000041 ! osmotic_integrity_abnormal
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000366
name: three_fold_arrest
related_synonym: "active_elongation_arrest" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000367
name: comma_arrest
related_synonym: "end_of_epiboly_arrest" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000368
name: one_point_five_fold_arrest
related_synonym: "beginning_elongation_arrest" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000369
name: pretzel_arrest
related_synonym: "end_of_elongation_arrest" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0000370
name: egg_long
is_a: WBPhenotype:0000037 ! embryonic_body_morphology_abnormal

[Term]
id: WBPhenotype:0000371
name: cell_division_incomplete
is_a: WBPhenotype:0000417 ! cell_division_failure

[Term]
id: WBPhenotype:0000372
name: no_polar_body_formation
is_a: WBPhenotype:0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype:0000373
name: egg_shape_variable
is_a: WBPhenotype:0000037 ! embryonic_body_morphology_abnormal

[Term]
id: WBPhenotype:0000374
name: early_divisions_prolonged
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000375
name: later_divisions_prolonged
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000376
name: no_uterine_cavity
is_a: WBPhenotype:0000289 ! uterus_morphology_abnormal

[Term]
id: WBPhenotype:0000377
name: canal_lumen_morphology_abnormal
is_a: WBPhenotype:0000704 ! excretory_canal_morphology_abnormal

[Term]
id: WBPhenotype:0000378
name: pharyngeal_pumping_shallow
is_a: WBPhenotype:0001006 ! pharyngeal_pumping_rate_abnormal

[Term]
id: WBPhenotype:0000379
name: head_notched
is_a: WBPhenotype:0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype:0000380
name: expulsion_infrequent
is_a: WBPhenotype:0000996 ! expulsion_defective

[Term]
id: WBPhenotype:0000381
name: serotonin_reuptake_inhibitor_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000382
name: serotonin_reuptake_inhibitor_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000383
name: lipid_synthesis_defective
is_a: WBPhenotype:0000725 ! lipid_metabolism_abnormal

[Term]
id: WBPhenotype:0000384
name: axon_pathfinding_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000385
name: sperm_excess
is_a: WBPhenotype:0000670 ! spermatogenesis_abnormal

[Term]
id: WBPhenotype:0000386
name: sperm_behavior_abnormal
related_synonym: "spermatozoa_behavior_abnormal" []
is_obsolete: true

[Term]
id: WBPhenotype:0000387
name: sperm_nonmotile
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000388
name: sperm_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000389
name: hermaphrodite_sperm_fertilization_defective
is_a: WBPhenotype:0000694 ! hermaphrodite_sterility

[Term]
id: WBPhenotype:0000390
name: spermatid_activation_defective
is_a: WBPhenotype:0000670 ! spermatogenesis_abnormal

[Term]
id: WBPhenotype:0000391
name: defecation_missing_motor_steps
is_a: WBPhenotype:0000650 ! defecation_abnormal

[Term]
id: WBPhenotype:0000392
name: intestinal_fluorescence_increased
is_a: WBPhenotype:0000293 ! alimentary_system_pigmentation_abnormal

[Term]
id: WBPhenotype:0000393
name: cell_migration_failure
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000394
name: electrophoretic_variant_protein
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000395
name: no_differentiated_gametes
is_a: WBPhenotype:0000894 ! germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype:0000396
name: non_reflexed_gonad_arms
is_a: WBPhenotype:0000691 ! gonad_development_abnormal

[Term]
id: WBPhenotype:0000397
name: harsh_body_touch_insensitive
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0000398
name: light_body_touch_insensitive
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0000399
name: somatic_gonad_development_abnormal
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000400
name: somatic_gonad_primordium_development_defective
is_a: WBPhenotype:0000399 ! somatic_gonad_development_abnormal

[Term]
id: WBPhenotype:0000401
name: no_uterus
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000402
name: avoids_bacterial_lawn
is_a: WBPhenotype:0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype:0000403
name: sperm_transfer_initiation_defective
is_a: WBPhenotype:0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype:0000404
name: delayed_hatching
is_a: WBPhenotype:0000048 ! hatching_abnormal

[Term]
id: WBPhenotype:0000405
name: giant_oocytes
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000406
name: lumpy
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000407
name: ray_loss
is_a: WBPhenotype:0000199 ! male_tail_sensory_ray_generation_abnormal

[Term]
id: WBPhenotype:0000408
name: dauer_recovery_inhibited
is_a: WBPhenotype:0000127 ! dauer_recovery_abnormal

[Term]
id: WBPhenotype:0000409
name: variable_morphology
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000410
name: no_defecation_cycle
is_a: WBPhenotype:0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype:0000411
name: rod_like_morphology
is_a: WBPhenotype:0000035 ! larval_body_morphology_abnormal

[Term]
id: WBPhenotype:0000412
name: muscle_paralyzed
def: "Immobilized muscle that is not responsive to external stimulation." [WB:cab]
is_obsolete: true

[Term]
id: WBPhenotype:0000413
name: pharyngeal_muscle_paralyzed
def: "Immobilized pharyngeal muscle that is not responsive to external stimulation." [WB:cab]
is_a: WBPhenotype:0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype:0000414
name: cell_fate_transformation
is_a: WBPhenotype:0000216 ! cell_fate_specification_abnormal

[Term]
id: WBPhenotype:0000415
name: intestinal_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000416
name: yolk_synthesis_abnormal
related_synonym: "vitellogenin_synthesis_abnormal" []
is_a: WBPhenotype:0001093 ! intestinal_physiology_abnormal

[Term]
id: WBPhenotype:0000417
name: cell_division_failure
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0000418
name: intestinal_cell_division_failure
is_a: WBPhenotype:0000417 ! cell_division_failure

[Term]
id: WBPhenotype:0000419
name: L3_lethal
is_a: WBPhenotype:0000058 ! late_larval_lethal
is_a: WBPhenotype:0000116 ! mid_larval_lethal

[Term]
id: WBPhenotype:0000420
name: levamisole_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000421
name: levamisole_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000422
name: twitcher
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000423
name: head_muscle_contraction_abnormal
relationship: part_of WBPhenotype:0001002 ! head_muscle_behavior_abnormal

[Term]
id: WBPhenotype:0000424
name: antibody_staining_abnormal
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000425
name: antibody_staining_reduced
is_a: WBPhenotype:0000424 ! antibody_staining_abnormal

[Term]
id: WBPhenotype:0000426
name: antibody_staining_increased
is_a: WBPhenotype:0000424 ! antibody_staining_abnormal

[Term]
id: WBPhenotype:0000427
name: no_cuticle
is_a: WBPhenotype:0000201 ! cuticle_development_abnormal

[Term]
id: WBPhenotype:0000428
name: no_adult_cuticle
is_a: WBPhenotype:0000427 ! no_cuticle

[Term]
id: WBPhenotype:0000429
name: copulatory_structure_development_abnormal
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000430
name: male_copulatory_structure_development_abnormal
is_a: WBPhenotype:0000429 ! copulatory_structure_development_abnormal

[Term]
id: WBPhenotype:0000431
name: hermaphrodite_copulatory_structure_development_abnormal
is_a: WBPhenotype:0000429 ! copulatory_structure_development_abnormal

[Term]
id: WBPhenotype:0000432
name: no_male_copulatory_structures
is_a: WBPhenotype:0000430 ! male_copulatory_structure_development_abnormal

[Term]
id: WBPhenotype:0000433
name: DNA_synthesis_abnormal
is_a: WBPhenotype:0000732 ! DNA_metabolism_abnormal

[Term]
id: WBPhenotype:0000434
name: sexual_maturation_defective
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000435
name: protein_localization_abnormal
def: "Any change in the subcellular localization of a protein." [WB:kmva]
is_a: WBPhenotype:0000112 ! protein_expression_abnormal

[Term]
id: WBPhenotype:0000436
name: protein_subcellular_localization_abnormal
is_a: WBPhenotype:0000435 ! protein_localization_abnormal

[Term]
id: WBPhenotype:0000437
name: heterochronic_defect
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000438
name: retarded_heterochronic_alterations
is_a: WBPhenotype:0000437 ! heterochronic_defect

[Term]
id: WBPhenotype:0000439
name: precocious_heterochronic_alterations
is_a: WBPhenotype:0000437 ! heterochronic_defect

[Term]
id: WBPhenotype:0000440
name: long_excretory_canals
is_a: WBPhenotype:0000704 ! excretory_canal_morphology_abnormal

[Term]
id: WBPhenotype:0000441
name: tail_rounded
is_a: WBPhenotype:0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype:0000442
name: larval_development_retarded
is_a: WBPhenotype:0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype:0000443
name: spicule_morphology_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000444
name: bursa_elongated
is_a: WBPhenotype:0000342 ! bursa_morphology_abnormal

[Term]
id: WBPhenotype:0000445
name: yolk_synthesis_in_males
related_synonym: "vitellogenin_synthesis_in_males" []
is_a: WBPhenotype:0000416 ! yolk_synthesis_abnormal

[Term]
id: WBPhenotype:0000446
name: supernumerary_molt
is_a: WBPhenotype:0000638 ! molt_defect

[Term]
id: WBPhenotype:0000447
name: adult_development_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000448
name: adult_cuticle_development_abnormal
is_a: WBPhenotype:0000447 ! adult_development_abnormal

[Term]
id: WBPhenotype:0000449
name: second_adult_cuticle
is_a: WBPhenotype:0000448 ! adult_cuticle_development_abnormal

[Term]
id: WBPhenotype:0000450
name: swollen_male_tail
is_a: WBPhenotype:0000070 ! male_tail_abnormal

[Term]
id: WBPhenotype:0000451
name: head_protrusions
is_a: WBPhenotype:0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype:0000452
name: tail_protrusions
is_a: WBPhenotype:0000073 ! tail_morphology_abnormal

[Term]
id: WBPhenotype:0000453
name: body_protrusions
is_a: WBPhenotype:0000072 ! body_morphology_abnormal

[Term]
id: WBPhenotype:0000454
name: head_twisted
is_a: WBPhenotype:0000071 ! head_morphology_abnormal

[Term]
id: WBPhenotype:0000455
name: jerky_movement
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000456
name: touch_insensitive
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0000457
name: starvation_hypersensitive
is_a: WBPhenotype:0000147 ! organism_starvation_response_abnormal

[Term]
id: WBPhenotype:0000458
name: starvation_resistant
is_a: WBPhenotype:0000147 ! organism_starvation_response_abnormal

[Term]
id: WBPhenotype:0000459
name: pesticide_response_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000460
name: paraquat_response_abnormal
related_synonym: "methyl_viologen_response_abnormal" []
is_a: WBPhenotype:0000459 ! pesticide_response_abnormal

[Term]
id: WBPhenotype:0000461
name: paraquat_resistant
is_a: WBPhenotype:0000460 ! paraquat_response_abnormal

[Term]
id: WBPhenotype:0000462
name: paraquat_hypersensitive
is_a: WBPhenotype:0000460 ! paraquat_response_abnormal

[Term]
id: WBPhenotype:0000463
name: metabolic_pathway_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000464
name: oxygen_response_abnormal
is_a: WBPhenotype:0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype:0000465
name: high_oxygen_resistant
is_a: WBPhenotype:0000464 ! oxygen_response_abnormal

[Term]
id: WBPhenotype:0000466
name: high_oxygen_hypersensitive
is_a: WBPhenotype:0000464 ! oxygen_response_abnormal

[Term]
id: WBPhenotype:0000467
name: age_associated_fluorescence_increased
is_a: WBPhenotype:0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype:0000468
name: age_associated_fluorescence_decreased
is_a: WBPhenotype:0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype:0000469
name: Q_neuroblast_migration_abnormal
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000470
name: HSN_migration_abnormal
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000471
name: ALM_migration_abnormal
is_a: WBPhenotype:0000594 ! cell_migration_abnormal

[Term]
id: WBPhenotype:0000472
name: no_endoderm
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000473
name: progressive_paralysis
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0000474
name: muscle_attachment_abnormal
is_a: WBPhenotype:0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype:0000475
name: muscle_detached
is_a: WBPhenotype:0000474 ! muscle_attachment_abnormal

[Term]
id: WBPhenotype:0000476
name: progressive_muscle_detachment
is_a: WBPhenotype:0000474 ! muscle_attachment_abnormal

[Term]
id: WBPhenotype:0000477
name: nucleoli_refraction_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000478
name: isothermal_tracking_behavior_abnormal
def: "Deviation from a tendency for animals to track towards their cultivation temperature and  within their cultivation temperature." [WB:WBPaper00002214]
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000479
name: eggs_pale
is_a: WBPhenotype:0000970 ! embryonic_pigmentation_abnormal

[Term]
id: WBPhenotype:0000480
name: pyrazine_chemotaxis_defective
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0000481
name: chemoaversion_abnormal
def: "Avoidance of odorants is altered." [WB:cab]
related_synonym: "chemical_avoidance_abnormal" []
is_a: WBPhenotype:0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype:0000482
name: garlic_chemoaversion_abnormal
is_a: WBPhenotype:0000481 ! chemoaversion_abnormal

[Term]
id: WBPhenotype:0000483
name: no_gut_granules
is_a: WBPhenotype:0000708 ! intestinal_development_abnormal

[Term]
id: WBPhenotype:0000484
name: embryo_small
is_a: WBPhenotype:0000037 ! embryonic_body_morphology_abnormal

[Term]
id: WBPhenotype:0000485
name: dauer_death_increased
related_synonym: "reduced_dauer_survival" []
is_a: WBPhenotype:0000308 ! dauer_development_abnormal

[Term]
id: WBPhenotype:0000486
name: colchicine_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000487
name: colchicine_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000488
name: chloroquinone_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000489
name: chloroquinone_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000490
name: pharynx_disorganized
is_a: WBPhenotype:0000707 ! pharyngeal_development_abnormal

[Term]
id: WBPhenotype:0000491
name: isthmus_malformed
is_a: WBPhenotype:0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype:0000492
name: corpus_malformed
is_a: WBPhenotype:0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype:0000493
name: metacarpus_malformed
is_a: WBPhenotype:0000709 ! pharyngeal_morphology_abnormal

[Term]
id: WBPhenotype:0000494
name: male_spicule_protruding
is_obsolete: true

[Term]
id: WBPhenotype:0000495
name: rays_ectopic
is_a: WBPhenotype:0000199 ! male_tail_sensory_ray_generation_abnormal

[Term]
id: WBPhenotype:0000496
name: male_posterid_sensilla_missing
is_a: WBPhenotype:0001008 ! male_nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000497
name: organism_gamma_ray_response_abnormal
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000498
name: methyl_methanesulfonate_response_abnormal
related_synonym: "MMS_response_abnormal" []
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000499
name: ethyl_methanesulfonate_response_abnormal
related_synonym: "EMS_response_abnormal" []
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0000500
name: acetylcholinesterase_inhibitor_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000501
name: left_handed_roller
related_synonym: "Rol" []
is_a: WBPhenotype:0000645 ! roller

[Term]
id: WBPhenotype:0000502
name: right_handed_roller
related_synonym: "Rol" []
is_a: WBPhenotype:0000645 ! roller

[Term]
id: WBPhenotype:0000503
name: abnormal_endoreduplication
is_a: WBPhenotype:0000732 ! DNA_metabolism_abnormal

[Term]
id: WBPhenotype:0000504
name: nuclear_division_abnormal
related_synonym: "karyokinesis_abnormal" []
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000505
name: male_ray_morphology_abnormal
is_a: WBPhenotype:0000299 ! sensory_anatomy_abnormal

[Term]
id: WBPhenotype:0000506
name: swollen_bursa
is_a: WBPhenotype:0000342 ! bursa_morphology_abnormal

[Term]
id: WBPhenotype:0000507
name: acetylcholine_levels_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000508
name: nonsense_mRNA_accumulation
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000509
name: sperm_pseudopods_abnormal
is_a: WBPhenotype:0000388 ! sperm_morphology_abnormal

[Term]
id: WBPhenotype:0000510
name: vulval_invagination_abnormal_at_L4
is_a: WBPhenotype:0000695 ! vulva_morphogenesis_abnormal

[Term]
id: WBPhenotype:0000511
name: nuclear_positioning_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000512
name: VNC_nuclear_positioning_abnormal
is_a: WBPhenotype:0000511 ! nuclear_positioning_abnormal

[Term]
id: WBPhenotype:0000513
name: touch_response_abnormal
is_a: WBPhenotype:0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype:0000514
name: rubber_band
is_a: WBPhenotype:0000513 ! touch_response_abnormal

[Term]
id: WBPhenotype:0000515
name: ventral_nerve_cord_development_abnormal
is_a: WBPhenotype:0000945 ! neuropil_development_abnormal

[Term]
id: WBPhenotype:0000516
name: ventral_cord_disorganized
is_a: WBPhenotype:0000515 ! ventral_nerve_cord_development_abnormal

[Term]
id: WBPhenotype:0000517
name: Behavior_abnormal

[Term]
id: WBPhenotype:0000518
name: Development_abnormal

[Term]
id: WBPhenotype:0000519
name: Physiology_abnormal

[Term]
id: WBPhenotype:0000520
name: Morphology_abnormal

[Term]
id: WBPhenotype:0000521
name: Pigmentation_abnormal

[Term]
id: WBPhenotype:0000522
name: organism_region_behavior_abnormal
is_a: WBPhenotype:0000517 ! Behavior_abnormal

[Term]
id: WBPhenotype:0000523
name: cell_behavior_abnormal
def: "Activity characteristic of a cell is altered." [WB:cab]
is_obsolete: true

[Term]
id: WBPhenotype:0000524
name: organ_system_behavior_abnormal
def: "Activity characteristic of an organ system is altered." [WB:cab]
is_obsolete: true

[Term]
id: WBPhenotype:0000525
name: organism_behavior_abnormal
is_a: WBPhenotype:0000517 ! Behavior_abnormal

[Term]
id: WBPhenotype:0000526
name: cell_pigmentation_abnormal
is_a: WBPhenotype:0000521 ! Pigmentation_abnormal

[Term]
id: WBPhenotype:0000527
name: organism_pigmentation_abnormal
is_a: WBPhenotype:0000521 ! Pigmentation_abnormal

[Term]
id: WBPhenotype:0000528
name: body_region_development_abnormal
is_a: WBPhenotype:0000518 ! Development_abnormal

[Term]
id: WBPhenotype:0000529
name: cell_development_abnormal
is_a: WBPhenotype:0000518 ! Development_abnormal

[Term]
id: WBPhenotype:0000530
name: organ_system_development_abnormal
is_a: WBPhenotype:0000518 ! Development_abnormal

[Term]
id: WBPhenotype:0000531
name: organism_development_abnormal
is_a: WBPhenotype:0000518 ! Development_abnormal

[Term]
id: WBPhenotype:0000532
name: body_region_morphology_abnormal
is_a: WBPhenotype:0000520 ! Morphology_abnormal

[Term]
id: WBPhenotype:0000533
name: cell_morphology_abnormal
is_a: WBPhenotype:0000520 ! Morphology_abnormal

[Term]
id: WBPhenotype:0000534
name: organ_system_morphology_abnormal
is_a: WBPhenotype:0000520 ! Morphology_abnormal

[Term]
id: WBPhenotype:0000535
name: organism_morphology_abnormal
related_synonym: "Bmd" []
is_a: WBPhenotype:0000520 ! Morphology_abnormal

[Term]
id: WBPhenotype:0000536
name: cell_physiology_abnormal
is_a: WBPhenotype:0000519 ! Physiology_abnormal

[Term]
id: WBPhenotype:0000537
name: synaptic_input_abnormal
is_a: WBPhenotype:0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype:0000538
name: synaptic_output_abnormal
is_a: WBPhenotype:0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype:0000539
name: dorsal_nerve_cord_development_abnormal
is_a: WBPhenotype:0000945 ! neuropil_development_abnormal

[Term]
id: WBPhenotype:0000540
name: muscle_arm_development_abnormal
is_a: WBPhenotype:0000087 ! body_wall_cell_development_abnormal

[Term]
id: WBPhenotype:0000541
name: cord_commissures_fail_to_reach_target
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000542
name: fat
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000543
name: forward_kinker
is_a: WBPhenotype:0000002 ! kinker

[Term]
id: WBPhenotype:0000544
name: backward_kinker
is_a: WBPhenotype:0000002 ! kinker

[Term]
id: WBPhenotype:0000545
name: eggs_retained
def: "Eggs are retained in the uterus at a later stage than in wild-type worms." [WB:cab]
related_synonym: "late_eggs_laid" []
is_a: WBPhenotype:0000006 ! egg_laying_defective

[Term]
id: WBPhenotype:0000546
name: early_eggs_laid
is_a: WBPhenotype:0000005 ! hyperactive_egg_laying

[Term]
id: WBPhenotype:0000547
name: starved
related_synonym: "Eat" []
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000548
name: muscle_dystrophy
def: "Progressive degeneration of muscle." [WB:cab]
is_a: WBPhenotype:0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype:0000549
name: head_muscle_dystrophy
def: "Progressive degenration of the head muscle." [WB:cab]
is_a: WBPhenotype:0000548 ! muscle_dystrophy
relationship: part_of WBPhenotype:0001002 ! head_muscle_behavior_abnormal

[Term]
id: WBPhenotype:0000550
name: body_muscle_dystrophy
def: "Progressive muscle degeneration." [WB:cab]
is_a: WBPhenotype:0000548 ! muscle_dystrophy
relationship: part_of WBPhenotype:0000596 ! body_behavior_abnormal

[Term]
id: WBPhenotype:0000551
name: omega_locomotion
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0000552
name: GABA_levels_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000553
name: muscle_ultrastructure_disorganized
related_synonym: "muscle_birefringence_abnormal" []
is_a: WBPhenotype:0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype:0000554
name: hypoosmotic_shock_hypersensitive
is_a: WBPhenotype:0000041 ! osmotic_integrity_abnormal

[Term]
id: WBPhenotype:0000555
name: drug_adaptation_abnormal
is_a: WBPhenotype:0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype:0000556
name: dopamine_adaptation_abnormal
is_a: WBPhenotype:0000555 ! drug_adaptation_abnormal

[Term]
id: WBPhenotype:0000557
name: dopamine_adaptation_defective
is_a: WBPhenotype:0000556 ! dopamine_adaptation_abnormal

[Term]
id: WBPhenotype:0000558
name: calcium_channel_modulator_response_abnormal
is_a: WBPhenotype:0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype:0000559
name: calcium_channel_modulator_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug
is_a: WBPhenotype:0000558 ! calcium_channel_modulator_response_abnormal

[Term]
id: WBPhenotype:0000560
name: calcium_channel_modulator_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug
is_a: WBPhenotype:0000558 ! calcium_channel_modulator_response_abnormal

[Term]
id: WBPhenotype:0000561
name: head_levamisole_resistant
is_a: WBPhenotype:0000421 ! levamisole_resistant

[Term]
id: WBPhenotype:0000562
name: body_levamisole_resistant
is_a: WBPhenotype:0000421 ! levamisole_resistant

[Term]
id: WBPhenotype:0000563
name: shrinker
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000564
name: echo_defecation_cycle
is_a: WBPhenotype:0000207 ! defecation_cycle_abnormal

[Term]
id: WBPhenotype:0000565
name: coiler
related_synonym: "curler" []
is_a: WBPhenotype:0000001 ! body_posture_abnormal
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000566
name: ventral_coiler
related_synonym: "ventral_curler" []
is_a: WBPhenotype:0000565 ! coiler

[Term]
id: WBPhenotype:0000567
name: dorsal_coiler
related_synonym: "dorsal_curler" []
is_a: WBPhenotype:0000565 ! coiler

[Term]
id: WBPhenotype:0000568
name: axon_ultrastructure_abnormal
is_a: WBPhenotype:0000180 ! axon_morphology_abnormal

[Term]
id: WBPhenotype:0000569
name: axon_variscosities
is_a: WBPhenotype:0000568 ! axon_ultrastructure_abnormal

[Term]
id: WBPhenotype:0000570
name: axon_cisternae
is_a: WBPhenotype:0000568 ! axon_ultrastructure_abnormal

[Term]
id: WBPhenotype:0000571
name: abnormal_vesicles_axons
is_a: WBPhenotype:0000568 ! axon_ultrastructure_abnormal

[Term]
id: WBPhenotype:0000572
name: neuronal_outgrowth_abnormal
is_a: WBPhenotype:0000816 ! neuron_development_abnormal

[Term]
id: WBPhenotype:0000573
name: neuronal_branching_abnormal
is_a: WBPhenotype:0000572 ! neuronal_outgrowth_abnormal

[Term]
id: WBPhenotype:0000574
name: excretory_canal_short
is_a: WBPhenotype:0000704 ! excretory_canal_morphology_abnormal

[Term]
id: WBPhenotype:0000575
name: organ_system_physiology_abnormal
is_a: WBPhenotype:0000519 ! Physiology_abnormal

[Term]
id: WBPhenotype:0000576
name: organism_physiology_abnormal
is_a: WBPhenotype:0000519 ! Physiology_abnormal

[Term]
id: WBPhenotype:0000577
name: organism_homeostasis_metabolism_abnormal
is_a: WBPhenotype:0000576 ! organism_physiology_abnormal

[Term]
id: WBPhenotype:0000578
name: body_axis_development_abnormal
is_a: WBPhenotype:0000528 ! body_region_development_abnormal

[Term]
id: WBPhenotype:0000579
name: organism_segment_development_abnormal
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000580
name: organism_segment_behavior_abnormal
is_a: WBPhenotype:0000522 ! organism_region_behavior_abnormal

[Term]
id: WBPhenotype:0000581
name: body_axis_morphology_abnormal
is_a: WBPhenotype:0000532 ! body_region_morphology_abnormal

[Term]
id: WBPhenotype:0000582
name: organism_segment_morphology_abnormal
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000583
name: dumpy
related_synonym: "Dpy" []
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000584
name: synaptic_transmission_abnormal
is_a: WBPhenotype:0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype:0000585
name: cell_homeostasis_metabolism_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000586
name: alimentary_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000587
name: coelomic_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000588
name: epithelial_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000589
name: excretory_secretory_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000590
name: excretory_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000591
name: muscle_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000592
name: nervous_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000593
name: reproductive_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000594
name: cell_migration_abnormal
related_synonym: "Mig" []
related_synonym: "migration_of_cells_abnormal" []
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000595
name: head_behavior_abnormal
def: "Activity characteristic of the head is altered." [WB:cab]
is_a: WBPhenotype:0000580 ! organism_segment_behavior_abnormal

[Term]
id: WBPhenotype:0000596
name: body_behavior_abnormal
def: "Activity characteristic of the body is altered." [WB:cab]
is_a: WBPhenotype:0000580 ! organism_segment_behavior_abnormal

[Term]
id: WBPhenotype:0000597
name: tail_behavior_abnormal
is_a: WBPhenotype:0000580 ! organism_segment_behavior_abnormal

[Term]
id: WBPhenotype:0000598
name: alimentary_system_morphology_abnormal
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000599
name: coelomic_system_morphology_abnormal
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000600
name: epithelial_system_morphology_abnormal
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000601
name: excretory_secretory_system_morphology_abnormal
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000602
name: excretory_system_morphology_abnormal
is_a: WBPhenotype:0000601 ! excretory_secretory_system_morphology_abnormal

[Term]
id: WBPhenotype:0000603
name: muscle_system_morphology_abnormal
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000604
name: nervous_system_morphology_abnormal
related_synonym: "neuroanatomical_defect" []
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000605
name: reproductive_system_morphology_abnormal
is_a: WBPhenotype:0000534 ! organ_system_morphology_abnormal

[Term]
id: WBPhenotype:0000606
name: alimentary_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000607
name: coelomic_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000608
name: epithelial_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000609
name: excretory_secretory_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000610
name: excretory_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000611
name: muscle_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000612
name: nervous_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000613
name: reproductive_system_physiology_abnormal
is_a: WBPhenotype:0000575 ! organ_system_physiology_abnormal

[Term]
id: WBPhenotype:0000614
name: GLR_development_abnormal
is_a: WBPhenotype:0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype:0000615
name: cilia_morphology_abnormal
related_synonym: "defective_dye_filling_of_cilia" []
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000616
name: synapse_morphology_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000617
name: alimentary_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000618
name: coelomic_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000619
name: epithelial_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000620
name: excretory_secretory_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000621
name: excretory_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal
relationship: part_of WBPhenotype:0000620 ! excretory_secretory_system_development_abnormal

[Term]
id: WBPhenotype:0000622
name: muscle_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000623
name: nervous_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000624
name: reproductive_system_development_abnormal
is_a: WBPhenotype:0000530 ! organ_system_development_abnormal

[Term]
id: WBPhenotype:0000625
name: synapse_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000626
name: habituation_abnormal
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000627
name: anesthetic_response_abnormal
is_a: WBPhenotype:0000631 ! drug_response_abnormal

[Term]
id: WBPhenotype:0000628
name: embryonic_spindle_assembly_abnormal_emb
def: "Spindle bipolarity is not established." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0000629
name: ectopic_neurite_outgrowth
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000631
name: drug_response_abnormal
alt_id: WBPhenotype:0000630
def: "Characteristic response(s) to drug(s) is abnormal." [WB:cab]
related_synonym: "drug_response_abnormal" []
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000632
name: axon_fasciculation_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000633
name: axon_branching_abnormal
is_a: WBPhenotype:0000604 ! nervous_system_morphology_abnormal

[Term]
id: WBPhenotype:0000634
name: pharyngeal_pumping_abnormal
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000635
name: chemotaxis_abnormal
def: "Movement towards typical attractive odorants is alteered." [WB:cab, WB:cgc122, WB:cgc387]
is_a: WBPhenotype:0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype:0000636
name: neuronal_degeneration_abnormal
is_a: WBPhenotype:0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype:0000637
name: dauer_formation_abnormal
def: "Characteristic entry into the dauer stage is altered." [WB:cab]
related_synonym: "Daf" []
is_a: WBPhenotype:0000308 ! dauer_development_abnormal
is_a: WBPhenotype:0001001 ! dauer_behavior_abnormal

[Term]
id: WBPhenotype:0000638
name: molt_defect
related_synonym: "Mlt" []
related_synonym: "Mult" []
is_a: WBPhenotype:0000750 ! larval_development_abnormal
is_a: WBPhenotype:0001016 ! larval_growth_abnormal

[Term]
id: WBPhenotype:0000639
name: temperature_induced_dauer_formation_abnormal
is_a: WBPhenotype:0000146 ! organism_temperature_response_abnormal
is_a: WBPhenotype:0000637 ! dauer_formation_abnormal

[Term]
id: WBPhenotype:0000640
name: egg_laying_abnormal
def: "The stage of eggs laid\, egg laying cycle\, or egg laying in reponse to external stimuli is altered." [pmid:11813735, pmid:9697864, WB:cab]
related_synonym: "Egl" []
related_synonym: "oviposition_abnormal" []
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000641
name: activity_level_abnormal
def: "The level of activity normally characteristic of C. elegans is altered." [WB:cab]
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0000642
name: hyperactive
related_synonym: "Hya" []
is_a: WBPhenotype:0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype:0000643
name: locomotion_abnormal
related_synonym: "movement_defect" []
related_synonym: "unc" []
related_synonym: "uncoordinated" []
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000644
name: paralyzed
def: "Immobilized worm that is not responsive to external stimulation." [WB:cab]
related_synonym: "Prl" []
related_synonym: "Prz" []
is_a: WBPhenotype:0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype:0000645
name: roller
related_synonym: "Rol" []
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000646
name: sluggish
def: "Characterized by activity levels that are reduced compared wtih wild-type worms." [WB:cab]
related_synonym: "Slu" []
is_a: WBPhenotype:0000641 ! activity_level_abnormal

[Term]
id: WBPhenotype:0000647
name: copulation_abnormal
def: "Mating is altered." [WB:cab]
related_synonym: "Cod" []
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000648
name: male_mating_abnormal
def: "Characteritic male behavior during mating is altered." [WB:cab]
is_a: WBPhenotype:0000647 ! copulation_abnormal
is_a: WBPhenotype:0000821 ! sex_specific_behavior_abnormal

[Term]
id: WBPhenotype:0000649
name: vulva_location_abnormal
is_a: WBPhenotype:0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0000650
name: defecation_abnormal
def: "Activites characteristic of defecation behavior are altered." [WB:cab]
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000651
name: constipated
related_synonym: "Con" []
is_a: WBPhenotype:0000650 ! defecation_abnormal

[Term]
id: WBPhenotype:0000652
name: sensory_system_abnormal
is_a: WBPhenotype:0000653 ! mechanosensory_system_abnormal

[Term]
id: WBPhenotype:0000653
name: mechanosensory_system_abnormal
is_a: WBPhenotype:0000612 ! nervous_system_physiology_abnormal

[Term]
id: WBPhenotype:0000654
name: synaptic_vesicle_exocytosis_abnormal
is_a: WBPhenotype:0000584 ! synaptic_transmission_abnormal
is_a: WBPhenotype:0000728 ! exocytosis_abnormal

[Term]
id: WBPhenotype:0000655
name: GABA_synaptic_transmission_abnormal
is_a: WBPhenotype:0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype:0000656
name: acetylcholine_synaptic_transmission_abnormal
is_a: WBPhenotype:0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype:0000657
name: neuronal_synaptic_transmission_abnormal
is_a: WBPhenotype:0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype:0000658
name: neuromuscular_synaptic_transmission_abnormal
is_a: WBPhenotype:0000584 ! synaptic_transmission_abnormal

[Term]
id: WBPhenotype:0000659
name: feeding_behavior_abnormal
related_synonym: "Eat" []
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000660
name: social_feeding_enhanced
related_synonym: "social_behavior_enhanced" []
is_a: WBPhenotype:0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype:0000661
name: solitary_feeding_enhanced
related_synonym: "solitary_behavior_enhanced" []
is_a: WBPhenotype:0000659 ! feeding_behavior_abnormal

[Term]
id: WBPhenotype:0000662
name: foraging_behavior_abnormal
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000663
name: osmotic_avoidance_abnormal
def: "Characteristic tendency of worms to avoid solutions of high osmotic strength is altered." [WB:cab]
is_a: WBPhenotype:0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype:0000664
name: exaggerated_body_bends
related_synonym: "loopy" []
is_a: WBPhenotype:0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype:0000665
name: connection_of_gonad_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000666
name: ovulation_abnormal
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000667
name: gonad_displaced
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000668
name: endomitotic_oocytes
def: "Any abnormality that results in the presence\, in proximal gonad arms\, of oocytes with distended polyploid nuclei.  Such oocytes mature and exit diakinesis\, but are often not properly ovulated or fertilized." [WB:kmva]
related_synonym: "Emo" []
related_synonym: "arrest_in_meiosis_I" []
is_a: WBPhenotype:0000186 ! oogenesis_abnormal

[Term]
id: WBPhenotype:0000669
name: sex_muscle_abnormal
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal
is_a: WBPhenotype:0000860 ! nonstriated_muscle_development_abnormal

[Term]
id: WBPhenotype:0000670
name: spermatogenesis_abnormal
is_a: WBPhenotype:0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype:0000671
name: blast_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000672
name: epithelial_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000673
name: germ_cell_behavior_abnormal
alt_id: WBPhenotype:0000886
related_synonym: "germline_behavior_abnormal" []
is_obsolete: true

[Term]
id: WBPhenotype:0000674
name: gland_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000675
name: marginal_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000676
name: muscle_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000677
name: neuron_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000678
name: spermatid_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000679
name: spermatocyte_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000680
name: uterine_vulval_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000682
name: feminization_of_germline
related_synonym: "Fog" []
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000683
name: masculinization_of_germline
related_synonym: "Mog" []
is_a: WBPhenotype:0000688 ! sterile
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000684
name: fewer_germ_cells
related_synonym: "Fgc" []
is_a: WBPhenotype:0000688 ! sterile
is_a: WBPhenotype:0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype:0000685
name: coelomocyte_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000686
name: pseudocoelom_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000687
name: feminization_of_XX_and_XO_animals
related_synonym: "Fem" []
is_a: WBPhenotype:0000049 ! postembryonic_development_abnormal
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000688
name: sterile
related_synonym: "Ste" []
is_a: WBPhenotype:0000145 ! fertility_abnormal

[Term]
id: WBPhenotype:0000689
name: sterile_FO_fertility_problems
def: "Worm injected with inhibiting RNA produces no\, or few embryos." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000688 ! sterile

[Term]
id: WBPhenotype:0000690
name: gonad_migration_abnormal
related_synonym: "Gom" []
relationship: part_of WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000691
name: gonad_development_abnormal
related_synonym: "Gon" []
related_synonym: "gonadogenesis_abnormal" []
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000692
name: male_sterility
is_a: WBPhenotype:0000688 ! sterile

[Term]
id: WBPhenotype:0000693
name: male_sperm_fertilization_defect
is_a: WBPhenotype:0000692 ! male_sterility

[Term]
id: WBPhenotype:0000694
name: hermaphrodite_sterility
is_a: WBPhenotype:0000688 ! sterile

[Term]
id: WBPhenotype:0000695
name: vulva_morphogenesis_abnormal
is_a: WBPhenotype:0000605 ! reproductive_system_morphology_abnormal

[Term]
id: WBPhenotype:0000696
name: everted_vulva
related_synonym: "Evl" []
is_a: WBPhenotype:0000695 ! vulva_morphogenesis_abnormal

[Term]
id: WBPhenotype:0000697
name: protruding_vulva
related_synonym: "Pvl" []
related_synonym: "Pvu" []
is_a: WBPhenotype:0000695 ! vulva_morphogenesis_abnormal

[Term]
id: WBPhenotype:0000698
name: vulvaless
related_synonym: "Vul" []
is_a: WBPhenotype:0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype:0000699
name: vulva_development_abnormal
def: "Abnormal vulval development" [WB:IA]
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000700
name: multivulva
related_synonym: "Muv" []
is_a: WBPhenotype:0000699 ! vulva_development_abnormal

[Term]
id: WBPhenotype:0000701
name: epithelial_development_abnormal
related_synonym: "hypodermal_development_abnormal" []
is_a: WBPhenotype:0000619 ! epithelial_system_development_abnormal

[Term]
id: WBPhenotype:0000702
name: epithelial_cell_fusion_failure
xref_analog: PMID:15341747
is_a: WBPhenotype:0000701 ! epithelial_development_abnormal

[Term]
id: WBPhenotype:0000703
name: epithelial_morphology_abnormal
related_synonym: "hypodermal_morphology_abnormal" []
is_a: WBPhenotype:0000600 ! epithelial_system_morphology_abnormal

[Term]
id: WBPhenotype:0000704
name: excretory_canal_morphology_abnormal
is_a: WBPhenotype:0000916 ! excretory_cell_morphology_abnormal

[Term]
id: WBPhenotype:0000705
name: intestinal_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal
is_a: WBPhenotype:0000708 ! intestinal_development_abnormal

[Term]
id: WBPhenotype:0000706
name: gut_granule_biogenesis_reduced
related_synonym: "glo" []
related_synonym: "gut_granule_loss" []
xref_analog: PMID:15843430
is_a: WBPhenotype:0000705 ! intestinal_cell_development_abnormal

[Term]
id: WBPhenotype:0000707
name: pharyngeal_development_abnormal
is_a: WBPhenotype:0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype:0000708
name: intestinal_development_abnormal
related_synonym: "gut_development" []
is_a: WBPhenotype:0000617 ! alimentary_system_development_abnormal

[Term]
id: WBPhenotype:0000709
name: pharyngeal_morphology_abnormal
is_a: WBPhenotype:0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype:0000710
name: intestinal_morphology_abnormal
is_a: WBPhenotype:0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype:0000711
name: somatic_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000712
name: nonstriated_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000713
name: spermatocyte_division_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000714
name: disorganized_muscle
is_a: WBPhenotype:0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype:0000715
name: muscle_excess
def: "Any abnormality that results in a greater than wild-type number of embryonic muscle cells." [WB:kmva, WB:WBPaper00001584]
related_synonym: "Mex" [WB:WBPaper00001584]
is_a: WBPhenotype:0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype:0000716
name: muscle_cell_attachment_abnormal
is_a: WBPhenotype:0000990 ! muscle_cell_physiology_abnormal

[Term]
id: WBPhenotype:0000717
name: gene_expression_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000718
name: dosage_compensation_abnormal
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000719
name: reporter_gene_expression_abnormal
is_a: WBPhenotype:0000717 ! gene_expression_abnormal

[Term]
id: WBPhenotype:0000720
name: pattern_of_reporter_gene_expression_abnormal
is_a: WBPhenotype:0000719 ! reporter_gene_expression_abnormal

[Term]
id: WBPhenotype:0000721
name: level_of_reporter_gene_expression_abnormal
is_a: WBPhenotype:0000719 ! reporter_gene_expression_abnormal

[Term]
id: WBPhenotype:0000722
name: nucleoli_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000723
name: cellular_secretion_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000724
name: protein_secretion_abnormal
is_a: WBPhenotype:0000723 ! cellular_secretion_abnormal

[Term]
id: WBPhenotype:0000725
name: lipid_metabolism_abnormal
is_a: WBPhenotype:0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype:0000726
name: ligand_binding_abnormal
is_a: WBPhenotype:0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype:0000727
name: enzyme_activity_abnormal
is_a: WBPhenotype:0000027 ! organism_metabolism_processing_abnormal

[Term]
id: WBPhenotype:0000728
name: exocytosis_abnormal
is_a: WBPhenotype:0000723 ! cellular_secretion_abnormal

[Term]
id: WBPhenotype:0000729
name: cell_death_abnormal
related_synonym: "Ced" []
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000730
name: apoptosis_abnormal
related_synonym: "Ced" []
is_a: WBPhenotype:0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype:0000731
name: necrosis_abnormal
is_a: WBPhenotype:0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype:0000732
name: DNA_metabolism_abnormal
is_a: WBPhenotype:0000585 ! cell_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000733
name: catalysis_abnormal
is_a: WBPhenotype:0000727 ! enzyme_activity_abnormal

[Term]
id: WBPhenotype:0000734
name: hypodermal_cell_physiology_abnormal
is_a: WBPhenotype:0000608 ! epithelial_system_physiology_abnormal

[Term]
id: WBPhenotype:0000735
name: endoreduplication_of_hypodermal_nuclei_abnormal
is_a: WBPhenotype:0000734 ! hypodermal_cell_physiology_abnormal

[Term]
id: WBPhenotype:0000736
name: autophagic_cell_death_abnormal
related_synonym: "autophagy_abnormal" []
is_a: WBPhenotype:0000729 ! cell_death_abnormal

[Term]
id: WBPhenotype:0000737
name: cell_adhesion_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000738
name: organism_environmental_stimulus_response_abnormal
def: "Characteristic response to a change in the environment is altered." [WB:cab]
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000739
name: DNA_damage_response_abnormal
is_a: WBPhenotype:0000142 ! cell_stress_response_abnormal

[Term]
id: WBPhenotype:0000740
name: cell_cycle_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000741
name: DNA_damage_checkpoint_abnormal
is_a: WBPhenotype:0000740 ! cell_cycle_abnormal

[Term]
id: WBPhenotype:0000742
name: DNA_recombination_abnormal
is_a: WBPhenotype:0000732 ! DNA_metabolism_abnormal

[Term]
id: WBPhenotype:0000743
name: RNAi_response_abnormal
related_synonym: "Rde" []
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000744
name: transgene_induced_cosuppression_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000745
name: transposon_silencing_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0000746
name: cell_division_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000747
name: pharyngeal_contraction_defect
is_a: WBPhenotype:0000980 ! pharyngeal_contraction_abnormal

[Term]
id: WBPhenotype:0000748
name: asymmetric_cell_division_abnormal_emb
def: "Symmetric (PAR-like) divisions or excessive posterior displacement (zyg-8 like phenotypes)." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0000749
name: embryonic_development_abnormal
related_synonym: "developmental_defects_detected_in_embryos" []
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000750
name: larval_development_abnormal
is_a: WBPhenotype:0000049 ! postembryonic_development_abnormal

[Term]
id: WBPhenotype:0000751
name: L1_larval_development_abnormal
is_a: WBPhenotype:0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype:0000752
name: L2_larval_development_abnormal
is_a: WBPhenotype:0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype:0000753
name: L3_larval_development_abnormal
is_a: WBPhenotype:0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype:0000754
name: L4_larval_development_abnormal
is_a: WBPhenotype:0000750 ! larval_development_abnormal

[Term]
id: WBPhenotype:0000755
name: L1_L2_molt_abnormal
is_a: WBPhenotype:0000638 ! molt_defect

[Term]
id: WBPhenotype:0000756
name: L2_L3_molt_abnormal
is_a: WBPhenotype:0000638 ! molt_defect

[Term]
id: WBPhenotype:0000757
name: L3_L4_molt_abnormal
is_a: WBPhenotype:0000638 ! molt_defect

[Term]
id: WBPhenotype:0000758
name: L4_adult_molt_abnormal
is_a: WBPhenotype:0000638 ! molt_defect

[Term]
id: WBPhenotype:0000759
name: embryonic_spindle_abnormal_emb
related_synonym: "Spd" []
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype:0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype:0000760
name: embryonic_spindle_orientation_abnormal_emb
related_synonym: "Spn" []
is_a: WBPhenotype:0000761 ! embryonic_spindle_position_orientation_abnormal_emb

[Term]
id: WBPhenotype:0000761
name: embryonic_spindle_position_orientation_abnormal_emb
related_synonym: "Spi" []
related_synonym: "Spo" []
is_a: WBPhenotype:0000759 ! embryonic_spindle_abnormal_emb

[Term]
id: WBPhenotype:0000762
name: embryonic_spindle_position_abnormal_emb
related_synonym: "Abs" []
is_a: WBPhenotype:0000761 ! embryonic_spindle_position_orientation_abnormal_emb

[Term]
id: WBPhenotype:0000763
name: embryonic_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000764
name: embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal
is_a: WBPhenotype:0000763 ! embryonic_cell_physiology_abnormal
is_a: WBPhenotype:0010002 ! cell_organization_and_biogenesis_abnormal

[Term]
id: WBPhenotype:0000765
name: embryonic_spindle_elongation_integrity_abnormal_emb
def: "Bipolar spindle shows clear elongation defect." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0000766
name: centrosome_pair_and_associated_pronuclear_rotation_abnormal
related_synonym: "Rot" []
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0000767
name: integrity_of_membranous_organelles_abnormal_emb
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0000768
name: cytoplasmic_structures_abnormal_emb
def: "Areas devoid of yolk granules throughout the embryo." [WB:cab, WB:cgc7141]
related_synonym: "cellular_structures_disorganized" []
is_a: WBPhenotype:0001081 ! cytoplasmic_morphology_abnormal_emb

[Term]
id: WBPhenotype:0000769
name: cytoplasmic_appearance_abnormal_early_emb
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal
is_a: WBPhenotype:0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype:0000770
name: embryonic_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000771
name: embryonic_centrosome_attachment_abnormal_emb
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000770 ! embryonic_cell_morphology_abnormal

[Term]
id: WBPhenotype:0000772
name: sister_chromatid_segregation_abnormal_emb
def: "Daughter nuclei are deformed and stay close to central cortex\, cytokinesis defects." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000773 ! chromosome_segregation_abnormal

[Term]
id: WBPhenotype:0000773
name: chromosome_segregation_abnormal
def: "Any abnormality in the processes that regulate the apportionment of chromosomes to each of two daughter cells." [WB:kmva]
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000774
name: gametogenesis_abnormal
is_a: WBPhenotype:0000624 ! reproductive_system_development_abnormal

[Term]
id: WBPhenotype:0000775
name: meiosis_abnormal
related_synonym: "Mei" []
is_a: WBPhenotype:0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype:0000776
name: passage_through_meiosis_abnormal_emb
def: "Male and female PNs not visible; embryo often fills egg shell completely." [WB:cab, WB:cgc71441]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype:0000777
name: polar_body_extrusion_abnormal_emb
def: "Unextruded or resorbed polar body(ies) leading to an extra PNs in Po and/or extra karyomeres in AB/P1." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype:0000778
name: multiple_nuclei_in_early_embryo_emb
alt_id: WBPhenotype:0000779
related_synonym: "Mul" []
related_synonym: "karyomeres" []
is_a: WBPhenotype:0000746 ! cell_division_abnormal
is_a: WBPhenotype:0001035 ! nuclear_appearance_abnormal_emb

[Term]
id: WBPhenotype:0000780
name: shaker
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0000781
name: thin_filaments_abnormal
is_a: WBPhenotype:0000553 ! muscle_ultrastructure_disorganized

[Term]
id: WBPhenotype:0000782
name: thick_filaments_abnormal
is_a: WBPhenotype:0000553 ! muscle_ultrastructure_disorganized

[Term]
id: WBPhenotype:0000783
name: no_M_line
is_a: WBPhenotype:0000782 ! thick_filaments_abnormal

[Term]
id: WBPhenotype:0000784
name: nuclear_migration_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000785
name: body_part_pigmentation_abnormal
is_a: WBPhenotype:0000278 ! body_region_pigmentation_abnormal

[Term]
id: WBPhenotype:0000786
name: body_axis_pigmentation_abnormal
is_a: WBPhenotype:0000278 ! body_region_pigmentation_abnormal

[Term]
id: WBPhenotype:0000787
name: posterior_pale
is_a: WBPhenotype:0000984 ! posterior_pigmentation_abnormal

[Term]
id: WBPhenotype:0000788
name: anterior_pale
is_a: WBPhenotype:0000971 ! anterior_pigmentation_abnormal

[Term]
id: WBPhenotype:0000789
name: fluoxetine_hypersensitive
is_a: WBPhenotype:0000010 ! hypersensitive_to_drug

[Term]
id: WBPhenotype:0000790
name: fluoxetine_resistant
is_a: WBPhenotype:0000011 ! resistant_to_drug

[Term]
id: WBPhenotype:0000791
name: nose_resistant_to_fluoxetine
is_a: WBPhenotype:0000790 ! fluoxetine_resistant

[Term]
id: WBPhenotype:0000792
name: anterior_body_morphology_abnormal
is_a: WBPhenotype:0000581 ! body_axis_morphology_abnormal

[Term]
id: WBPhenotype:0000793
name: posterior_body_morphology_abnormal
is_a: WBPhenotype:0000581 ! body_axis_morphology_abnormal

[Term]
id: WBPhenotype:0000794
name: posterior_body_thin
is_a: WBPhenotype:0000793 ! posterior_body_morphology_abnormal

[Term]
id: WBPhenotype:0000795
name: body_axis_behavior_abnormal
is_a: WBPhenotype:0000522 ! organism_region_behavior_abnormal

[Term]
id: WBPhenotype:0000796
name: posterior_body_uncoordinated
def: "Posterior of the worm does not move in a sinusiodal motion fashion that is coordinated with the anterior body movement of the worm." [WB:cab]
is_a: WBPhenotype:0000797 ! posterior_body_behavior_abnormal

[Term]
id: WBPhenotype:0000797
name: posterior_body_behavior_abnormal
is_a: WBPhenotype:0000795 ! body_axis_behavior_abnormal

[Term]
id: WBPhenotype:0000798
name: anterior_body_behavior_abnormal
is_a: WBPhenotype:0000795 ! body_axis_behavior_abnormal

[Term]
id: WBPhenotype:0000799
name: anterior_development_abnormal
is_a: WBPhenotype:0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype:0000800
name: posterior_development_abnormal
is_a: WBPhenotype:0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype:0000801
name: ventral_development_abnormal
is_a: WBPhenotype:0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype:0000802
name: dorsal_development_abnormal
is_a: WBPhenotype:0000578 ! body_axis_development_abnormal

[Term]
id: WBPhenotype:0000803
name: head_development_abnormal
is_a: WBPhenotype:0000579 ! organism_segment_development_abnormal

[Term]
id: WBPhenotype:0000804
name: body_development_abnormal
is_a: WBPhenotype:0000579 ! organism_segment_development_abnormal

[Term]
id: WBPhenotype:0000805
name: tail_development_abnormal
is_a: WBPhenotype:0000579 ! organism_segment_development_abnormal

[Term]
id: WBPhenotype:0000806
name: cell_attachment_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000807
name: G_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000808
name: K_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000809
name: male_specific_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000810
name: blast_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000811
name: epithelial_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000812
name: germ_cell_development_abnormal
alt_id: WBPhenotype:0000681
related_synonym: "germline_development_abnormal" []
is_a: WBPhenotype:0000529 ! cell_development_abnormal
is_a: WBPhenotype:0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype:0000813
name: gland_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000814
name: marginal_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000815
name: muscle_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000816
name: neuron_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000817
name: uterine_vulval_cell_development_abnormal
is_a: WBPhenotype:0000529 ! cell_development_abnormal

[Term]
id: WBPhenotype:0000818
name: adult_behavior_abnormal
def: "Activity characteristic of an adult worm is altered." [WB:cab]
is_a: WBPhenotype:0000819 ! postembryonic_behavior_abnormal

[Term]
id: WBPhenotype:0000819
name: postembryonic_behavior_abnormal
def: "Behavior characteristic of postembryonic stage(s) is altered." [WB:cab]
is_a: WBPhenotype:0001000 ! developmental_behavior_abnormal

[Term]
id: WBPhenotype:0000820
name: embryonic_behavior_abnormal
def: "Activity characteristic of an embryo is altered." [WB:cab]
is_a: WBPhenotype:0001000 ! developmental_behavior_abnormal

[Term]
id: WBPhenotype:0000821
name: sex_specific_behavior_abnormal
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0000822
name: sex_determination_abnormal
def: "Any abnormality in the processes that govern the sexually dimorphic development of germline or somatic tissue." [WB:kmva]
related_synonym: "sex_specific_development_abnormal" []
is_a: WBPhenotype:0000531 ! organism_development_abnormal

[Term]
id: WBPhenotype:0000823
name: germ_cell_proliferation_abnormal
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000824
name: embryonic_cell_lineage_abnormal
is_a: WBPhenotype:0000093 ! lineage_abnormal

[Term]
id: WBPhenotype:0000825
name: postembryonic_cell_lineage_abnormal
is_a: WBPhenotype:0000093 ! lineage_abnormal

[Term]
id: WBPhenotype:0000826
name: H_Lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000827
name: V_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000828
name: T_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000829
name: Q_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000830
name: B_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000831
name: Y_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000832
name: C_lineage_abnormal
is_a: WBPhenotype:0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000833
name: U_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000834
name: E_lineage_abnormal
is_a: WBPhenotype:0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000835
name: F_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000836
name: gonadal_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000837
name: hermaphrodite_gonadal_lineage_abnormal
is_a: WBPhenotype:0000836 ! gonadal_lineage_abnormal

[Term]
id: WBPhenotype:0000838
name: male_gonadal_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal
is_a: WBPhenotype:0000836 ! gonadal_lineage_abnormal

[Term]
id: WBPhenotype:0000839
name: Z1_hermaphrodite_lineage_abnormal
is_a: WBPhenotype:0000837 ! hermaphrodite_gonadal_lineage_abnormal

[Term]
id: WBPhenotype:0000840
name: Z4_hermaphrodite_lineage_abnormal
is_a: WBPhenotype:0000837 ! hermaphrodite_gonadal_lineage_abnormal

[Term]
id: WBPhenotype:0000841
name: Z1_male_lineage_abnormal
is_a: WBPhenotype:0000838 ! male_gonadal_lineage_abnormal

[Term]
id: WBPhenotype:0000842
name: Z4_male_lineage_abnormal
is_a: WBPhenotype:0000838 ! male_gonadal_lineage_abnormal

[Term]
id: WBPhenotype:0000843
name: anus_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000844
name: cloacal_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000845
name: pharyngeal_intestinal_valve_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000846
name: pharyngeal_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000847
name: rectal_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000848
name: basal_lamina_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000849
name: epithelial_behavior_abnormal
related_synonym: "hypodermis_behavior_abnormal" []
is_obsolete: true

[Term]
id: WBPhenotype:0000850
name: excretory_gland_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000851
name: excretory_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000852
name: coelomocyte_development_abnormal
is_a: WBPhenotype:0000618 ! coelomic_system_development_abnormal

[Term]
id: WBPhenotype:0000853
name: excretory_socket_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000854
name: excretory_duct_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:00008545
name: stomato_intestinal_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:00008546
name: pharyngeal_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:00008547
name: anal_spincter_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:00008548
name: anal_depressor_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:00008549
name: vulval_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000855
name: pseudocoelom_development_abnormal
is_a: WBPhenotype:0000200 ! pericellular_component_development_abnormal

[Term]
id: WBPhenotype:00008550
name: uterine_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000856
name: excretory_gland_cell_development_abnormal
is_a: WBPhenotype:0000620 ! excretory_secretory_system_development_abnormal

[Term]
id: WBPhenotype:0000857
name: excretory_cell_development_abnormal
related_synonym: "excretory_canal_cell_development_abnormal" []
is_a: WBPhenotype:0000621 ! excretory_system_development_abnormal

[Term]
id: WBPhenotype:0000858
name: excretory_duct_cell_development_abnormal
is_a: WBPhenotype:0000621 ! excretory_system_development_abnormal

[Term]
id: WBPhenotype:0000859
name: excretory_socket_cell_development_abnormal
related_synonym: "excretory_pore_cell_development_abnormal" []
is_a: WBPhenotype:0000621 ! excretory_system_development_abnormal

[Term]
id: WBPhenotype:0000860
name: nonstriated_muscle_development_abnormal
is_a: WBPhenotype:0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype:0000861
name: body_wall_muscle_development_abnormal
related_synonym: "somatic_muscle_development_abnormal" []
related_synonym: "striated_muscle_development_abnormal" []
is_a: WBPhenotype:0000921 ! striated_muscle_development_abnormal

[Term]
id: WBPhenotype:0000862
name: neurite_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000863
name: axon_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000864
name: dendrite_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000865
name: pharyngeal_nervous_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000866
name: ventral_nerve_cord_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000867
name: dorsal_nerve_cord_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000868
name: ganglion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000869
name: neuropil_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000870
name: nerve_ring_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000871
name: anterior_ganglion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000872
name: dorsal_ganglion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000873
name: lateral_ganglia_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000874
name: ventral_ganglion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000875
name: retrovesicular_ganglion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000876
name: preanal_ganglion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000877
name: lumbar_ganglia_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000878
name: dorsorectal_ganglia_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000879
name: posterior_lateral_ganlion_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000880
name: axon_development_abnormal
is_a: WBPhenotype:0000944 ! neurite_development_abnormal

[Term]
id: WBPhenotype:0000881
name: pharyngeal_neuron_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000882
name: dendrite_development_abnormal
is_a: WBPhenotype:0000944 ! neurite_development_abnormal

[Term]
id: WBPhenotype:0000883
name: nerve_ring_development_abnormal
is_a: WBPhenotype:0000945 ! neuropil_development_abnormal

[Term]
id: WBPhenotype:0000884
name: distal_tip_cell_behavior_abnormal
related_synonym: "DTC_behavior_abnormal" []
is_obsolete: true

[Term]
id: WBPhenotype:0000885
name: accessory_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000887
name: somatic_gonad_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000888
name: reproductive_system_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000889
name: reproductive_system_neuron_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000890
name: larval_pigmentation_abnormal
is_a: WBPhenotype:0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype:0000891
name: clear_adult
related_synonym: "Clr" []
is_a: WBPhenotype:0000346 ! adult_pigmentation_abnormal

[Term]
id: WBPhenotype:0000892
name: hermaphrodite_germ_cell_proliferation_abnormal
is_a: WBPhenotype:0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype:0000893
name: male_germ_cell_proliferation_abnormal
is_a: WBPhenotype:0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype:0000894
name: germ_cell_differentiation_abnormal
is_a: WBPhenotype:0000774 ! gametogenesis_abnormal

[Term]
id: WBPhenotype:0000895
name: spermatocyte_germ_cell_differentiation_abnormal
is_a: WBPhenotype:0000894 ! germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype:0000896
name: oocyte_germ_cell_differentiation_abnormal
is_a: WBPhenotype:0000894 ! germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype:0000897
name: connective_tissue_abnormal
is_a: WBPhenotype:0000200 ! pericellular_component_development_abnormal

[Term]
id: WBPhenotype:0000898
name: blast_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000899
name: epithelial_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000900
name: germ_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000901
name: gland_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000902
name: intestinal_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000903
name: marginal_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000904
name: muscle_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000905
name: neuron_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000906
name: uterine_vulval_cell_morphology_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0000907
name: anus_morphology_abnormal
is_a: WBPhenotype:0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype:0000908
name: cloacal_morphology_abnormal
is_a: WBPhenotype:0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype:0000909
name: pharyngeal_intestinal_valve_morphology_abnormal
is_a: WBPhenotype:0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype:0000910
name: rectal_morphology_abnormal
is_a: WBPhenotype:0000598 ! alimentary_system_morphology_abnormal

[Term]
id: WBPhenotype:0000911
name: coelomocyte_morphology_abnormal
is_a: WBPhenotype:0000599 ! coelomic_system_morphology_abnormal

[Term]
id: WBPhenotype:0000912
name: pericellular_component_morphology_abnormal
is_a: WBPhenotype:0000520 ! Morphology_abnormal

[Term]
id: WBPhenotype:0000913
name: basal_lamina_morphology_abnormal
is_a: WBPhenotype:0000600 ! epithelial_system_morphology_abnormal

[Term]
id: WBPhenotype:0000914
name: excretory_gland_cell_morphology_abnormal
is_a: WBPhenotype:0000601 ! excretory_secretory_system_morphology_abnormal

[Term]
id: WBPhenotype:0000915
name: pale_adult
is_a: WBPhenotype:0000346 ! adult_pigmentation_abnormal

[Term]
id: WBPhenotype:0000916
name: excretory_cell_morphology_abnormal
related_synonym: "excretory_canal_cell_morphology_abnormal" []
is_a: WBPhenotype:0000602 ! excretory_system_morphology_abnormal

[Term]
id: WBPhenotype:0000917
name: excretory_duct_cell_morphology_abnormal
is_a: WBPhenotype:0000602 ! excretory_system_morphology_abnormal

[Term]
id: WBPhenotype:0000918
name: excretory_socket_cell_morphology_abnormal
is_a: WBPhenotype:0000602 ! excretory_system_morphology_abnormal

[Term]
id: WBPhenotype:0000919
name: spindle_body_wall_muscle_cell_development_abnormal
related_synonym: "filament_lattice_body_wall_muscle_cell_development_abnormal" []
is_a: WBPhenotype:0000087 ! body_wall_cell_development_abnormal

[Term]
id: WBPhenotype:0000920
name: body_body_wall_muscle_cell_development_abnormal
related_synonym: "muscle_belly_development_abnormal" []
is_a: WBPhenotype:0000087 ! body_wall_cell_development_abnormal

[Term]
id: WBPhenotype:0000921
name: striated_muscle_development_abnormal
is_a: WBPhenotype:0000622 ! muscle_system_development_abnormal

[Term]
id: WBPhenotype:0000922
name: male_logitudinal_muscle_development_abnormal
is_a: WBPhenotype:0000921 ! striated_muscle_development_abnormal

[Term]
id: WBPhenotype:0000923
name: nonstriated_muscle_morphology_abnormal
is_a: WBPhenotype:0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype:0000924
name: striated_muscle_morphology_abnormal
is_a: WBPhenotype:0000603 ! muscle_system_morphology_abnormal

[Term]
id: WBPhenotype:0000925
name: sex_muscle_morphology_abnormal
is_a: WBPhenotype:0000923 ! nonstriated_muscle_morphology_abnormal

[Term]
id: WBPhenotype:0000926
name: body_wall_muscle_morphology_abnormal
is_a: WBPhenotype:0000924 ! striated_muscle_morphology_abnormal

[Term]
id: WBPhenotype:0000927
name: male_longitudinal_muscle_morphology_abnormal
is_a: WBPhenotype:0000924 ! striated_muscle_morphology_abnormal

[Term]
id: WBPhenotype:0000928
name: gonadal_sheath_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000929
name: spermatheca_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000930
name: spermatheca_uterine_valve_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000931
name: uterus_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000932
name: egg_laying_system_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000933
name: MS_lineage_abnormal
is_a: WBPhenotype:0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000934
name: developmental_morphology_abnormal
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0000935
name: D_lineage_abnormal
is_a: WBPhenotype:0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000936
name: P4_lineage_abnormal
is_a: WBPhenotype:0000824 ! embryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000937
name: W_lineage_abnormal
is_a: WBPhenotype:0000825 ! postembryonic_cell_lineage_abnormal

[Term]
id: WBPhenotype:0000938
name: male_V_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000939
name: male_T_Lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000940
name: male_P_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000941
name: male_M_lineage_abnormal
is_a: WBPhenotype:0000809 ! male_specific_lineage_abnormal

[Term]
id: WBPhenotype:0000942
name: accessory_cell_development_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000943
name: ganglion_development_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000944
name: neurite_development_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000945
name: neuropil_development_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000946
name: pharyngeal_nervous_system_development_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0000947
name: connective_tissue_morphology_abnormal
is_a: WBPhenotype:0000912 ! pericellular_component_morphology_abnormal

[Term]
id: WBPhenotype:0000948
name: cuticle_morphology_abnormal
is_a: WBPhenotype:0000912 ! pericellular_component_morphology_abnormal

[Term]
id: WBPhenotype:0000949
name: pseudocoelom_morphology_abnormal
is_a: WBPhenotype:0000912 ! pericellular_component_morphology_abnormal

[Term]
id: WBPhenotype:0000950
name: neuronal_sheath_cell_development_abnormal
is_a: WBPhenotype:0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype:0000951
name: socket_cell_development_abnormal
is_a: WBPhenotype:0000942 ! accessory_cell_development_abnormal

[Term]
id: WBPhenotype:0000952
name: anterior_ganglion_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000953
name: dorsal_ganglion_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000954
name: dorsorectal_ganglia_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000955
name: lateral_ganglia_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000956
name: lumbar_ganglia_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000957
name: posterior_lateral_ganglion_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000958
name: preanal_ganglion_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000959
name: retrovesicular_ganglion_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000960
name: ventral_ganglion_development_abnormal
is_a: WBPhenotype:0000943 ! ganglion_development_abnormal

[Term]
id: WBPhenotype:0000961
name: vulval_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000962
name: HSN_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000963
name: VC_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000964
name: male_somatic_gonad_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000965
name: hermaphrodite_somatic_gonad_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000966
name: hermaphrodite_distal_tip_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000967
name: male_distal_tip_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000968
name: hermaphrodite_gonad_migration_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000969
name: male_gonad_migration_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000970
name: embryonic_pigmentation_abnormal
is_a: WBPhenotype:0001009 ! developmental_pigmentation_abnormal

[Term]
id: WBPhenotype:0000971
name: anterior_pigmentation_abnormal
is_a: WBPhenotype:0000786 ! body_axis_pigmentation_abnormal

[Term]
id: WBPhenotype:0000972
name: linker_cell_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000973
name: vas_deferens_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000974
name: seminal_vesicle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000975
name: copulatory_bursa_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000976
name: copulatory_spicule_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000977
name: hermaphrodite_sex_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000978
name: male_sex_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000979
name: proctodeum_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000980
name: pharyngeal_contraction_abnormal
is_a: WBPhenotype:0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype:0000981
name: spermatocyte_meiosis_abnormal
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000982
name: spermatid_maturation_abnormal
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0000983
name: anus_muscle_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000984
name: posterior_pigmentation_abnormal
is_a: WBPhenotype:0000786 ! body_axis_pigmentation_abnormal

[Term]
id: WBPhenotype:0000985
name: blast_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000986
name: epithelial_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000987
name: germ_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000988
name: gland_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000989
name: marginal_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000990
name: muscle_cell_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000991
name: neuron_physiology_abnormal
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0000992
name: oocyte_behavior_abnormal
is_obsolete: true

[Term]
id: WBPhenotype:0000993
name: anal_depressor_contraction_defect
def: "failure in the ability of the anal depressor muscle to contract fully." [WB:WBPaper00001256]
related_synonym: "Exp" []
is_a: WBPhenotype:0001092 ! larval_defecation_defect

[Term]
id: WBPhenotype:0000994
name: intestinal_contractions_abnormal
is_a: WBPhenotype:0000650 ! defecation_abnormal

[Term]
id: WBPhenotype:0000995
name: pos_body_wall_contraction_defect
related_synonym: "pBoc" []
is_obsolete: true

[Term]
id: WBPhenotype:0000996
name: expulsion_defective
is_a: WBPhenotype:0000205 ! expulsion_abnormal

[Term]
id: WBPhenotype:0000997
name: cryophilic
is_a: WBPhenotype:0000478 ! isothermal_tracking_behavior_abnormal

[Term]
id: WBPhenotype:0000998
name: thermophilic
is_a: WBPhenotype:0000478 ! isothermal_tracking_behavior_abnormal

[Term]
id: WBPhenotype:0000999
name: athermotactic
is_a: WBPhenotype:0000478 ! isothermal_tracking_behavior_abnormal

[Term]
id: WBPhenotype:0001000
name: developmental_behavior_abnormal
def: "Behavior characteristic during certain developmental stage(s) is altered." [WB:cab]
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0001001
name: dauer_behavior_abnormal
is_a: WBPhenotype:0000819 ! postembryonic_behavior_abnormal

[Term]
id: WBPhenotype:0001002
name: head_muscle_behavior_abnormal
is_a: WBPhenotype:0000595 ! head_behavior_abnormal

[Term]
id: WBPhenotype:0001003
name: L4_lethal
is_a: WBPhenotype:0000058 ! late_larval_lethal

[Term]
id: WBPhenotype:0001004
name: pharyngeal_relaxation_abnormal
is_a: WBPhenotype:0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype:0001005
name: backward_locomotion_abnormal
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0001006
name: pharyngeal_pumping_rate_abnormal
is_a: WBPhenotype:0000634 ! pharyngeal_pumping_abnormal

[Term]
id: WBPhenotype:0001007
name: other_abnormality_emb
related_synonym: "Oth" []
is_a: WBPhenotype:0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype:0001008
name: male_nervous_system_development_abnormal
is_a: WBPhenotype:0000623 ! nervous_system_development_abnormal

[Term]
id: WBPhenotype:0001009
name: developmental_pigmentation_abnormal
is_a: WBPhenotype:0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype:0001010
name: clear
related_synonym: "Clr" []
is_a: WBPhenotype:0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype:0001011
name: complex_phenotype_emb
def: "Complex combination of defects that does not match other class definitions." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0001012
name: pathogen_response_abnormal
is_a: WBPhenotype:0000577 ! organism_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0001013
name: pathogen_susceptibility_increased
related_synonym: "Esp" []
related_synonym: "enhanced_susceptibility_to_pathogens" []
is_a: WBPhenotype:0001012 ! pathogen_response_abnormal

[Term]
id: WBPhenotype:0001014
name: pathogen_resistence_increased
is_a: WBPhenotype:0001012 ! pathogen_response_abnormal

[Term]
id: WBPhenotype:0001015
name: developmental_growth_abnormal
is_a: WBPhenotype:0000030 ! growth_abnormal

[Term]
id: WBPhenotype:0001016
name: larval_growth_abnormal
is_a: WBPhenotype:0001015 ! developmental_growth_abnormal

[Term]
id: WBPhenotype:0001017
name: adult_growth_abnormal
is_a: WBPhenotype:0001015 ! developmental_growth_abnormal

[Term]
id: WBPhenotype:0001018
name: high_incidence_male_progeny
related_synonym: "Him" []
is_obsolete: true

[Term]
id: WBPhenotype:0001019
name: mid_larval_arrest
def: "Larval arrest during the L2 to L3 stages of larval development." [WB:cab]
is_a: WBPhenotype:0000059 ! larval_arrest

[Term]
id: WBPhenotype:0001020
name: late_embryonic_development_abnormal_emb
related_synonym: "Led" []
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0001021
name: male_development_abnormal
is_a: WBPhenotype:0000822 ! sex_determination_abnormal

[Term]
id: WBPhenotype:0001022
name: hermaphrodite_development_abnormal
is_a: WBPhenotype:0000822 ! sex_determination_abnormal

[Term]
id: WBPhenotype:0001023
name: sex_specific_morphology_abnormal
is_a: WBPhenotype:0000535 ! organism_morphology_abnormal

[Term]
id: WBPhenotype:0001024
name: male_morphology_abnormal
related_synonym: "Mab" []
is_a: WBPhenotype:0001023 ! sex_specific_morphology_abnormal

[Term]
id: WBPhenotype:0001025
name: hermaphrodite_morphology_abnormal
is_a: WBPhenotype:0001023 ! sex_specific_morphology_abnormal

[Term]
id: WBPhenotype:0001026
name: nuclear_morphology_alteration_early_embryo_emb
related_synonym: "Nmo" []
is_a: WBPhenotype:0001035 ! nuclear_appearance_abnormal_emb

[Term]
id: WBPhenotype:0001027
name: nuclear_position_alteration_early_embryo_emb
related_synonym: "Npo" []
is_a: WBPhenotype:0001035 ! nuclear_appearance_abnormal_emb

[Term]
id: WBPhenotype:0001028
name: nuclear_appearance_abnormal
is_a: WBPhenotype:0000533 ! cell_morphology_abnormal

[Term]
id: WBPhenotype:0001029
name: patchy_coloration
related_synonym: "Pch" []
is_a: WBPhenotype:0000527 ! organism_pigmentation_abnormal

[Term]
id: WBPhenotype:0001030
name: pronuclear_envelope_abnormal_emb
related_synonym: "Pna" []
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0001031
name: pronuclear_migration_abnormal_emb
def: "Lack of male pronuclear migration\, female pronuclear migration variable\, sometimes multiple female pronuclei\, no or small spindle." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0001032
name: larval_behavior_abnormal
is_a: WBPhenotype:0000819 ! postembryonic_behavior_abnormal

[Term]
id: WBPhenotype:0001033
name: proximal_germ_cell_proliferation_abnormal
related_synonym: "Pro" []
is_a: WBPhenotype:0000823 ! germ_cell_proliferation_abnormal

[Term]
id: WBPhenotype:0001034
name: pronuclear_and_nuclear_appearance_abnormal_emb
def: "Pronuclei and nuclei are small or missing altogether\, often accompanied by spindle defects." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0001035
name: nuclear_appearance_abnormal_emb
alt_id: WBPhenotype:0001042
def: "Pronuclei are normal but nuclei are completely mising or significantly smaller than normal; often accompanied by spindle and cytokinesis defects." [WB:cab, WB:cgc7141]
related_synonym: "nucleus_abnormal_emb" []
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal
is_a: WBPhenotype:0000770 ! embryonic_cell_morphology_abnormal

[Term]
id: WBPhenotype:0001036
name: sterile_F1
is_a: WBPhenotype:0001037 ! sterile_progeny

[Term]
id: WBPhenotype:0001037
name: sterile_progeny
related_synonym: "Stp" []
is_a: WBPhenotype:0000069 ! progeny_abnormal

[Term]
id: WBPhenotype:0001038
name: tumorous_germline
related_synonym: "Tum" []
is_a: WBPhenotype:0000812 ! germ_cell_development_abnormal

[Term]
id: WBPhenotype:0001039
name: embryonic_growth_abnormal
is_a: WBPhenotype:0001015 ! developmental_growth_abnormal

[Term]
id: WBPhenotype:0001040
name: chemosensory_response_abnormal
def: "Typical response to chemicals is altered." [WB:cab, WB:cgc3824]
is_a: WBPhenotype:0001049 ! chemosensory_behavior_abnormal

[Term]
id: WBPhenotype:0001041
name: meiosis_abnormal_emb
is_a: WBPhenotype:0001100 ! early_embryonic_lethal

[Term]
id: WBPhenotype:0001043
name: interphase_entry_abnormal_emb
def: "Embryos spend longer than normal when entering first interphase." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000740 ! cell_cycle_abnormal
is_a: WBPhenotype:0000775 ! meiosis_abnormal

[Term]
id: WBPhenotype:0001044
name: cortical_dynamics_abnormal_emb
def: "Little/no cortical ruffling or pseudocleavage furrow\, or excessive cortical activity at the two-cell stage." [WB:cab, WB:cgc7141]
related_synonym: "Cpa" []
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000764 ! embryonic_cell_organization_biogenesis_abnormal

[Term]
id: WBPhenotype:0001045
name: cytokinesis_abnormal_emb
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000746 ! cell_division_abnormal

[Term]
id: WBPhenotype:0001047
name: aqueous_chemotaxis_defective
def: "Failure to move towards typically attractive water-soluble chemicals." [WB:cab, WB:cgc3824]
is_a: WBPhenotype:0000015 ! chemotaxis_defective

[Term]
id: WBPhenotype:0001048
name: volatile_chemosensory_response_abnormal
is_a: WBPhenotype:0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype:0001049
name: chemosensory_behavior_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000525 ! organism_behavior_abnormal

[Term]
id: WBPhenotype:0001050
name: chemosensation_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0001049 ! chemosensory_behavior_abnormal

[Term]
id: WBPhenotype:0001051
name: cation_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure to move towards typically attractive cations." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001047 ! aqueous_chemotaxis_defective

[Term]
id: WBPhenotype:0001052
name: anion_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure to move towards typically attractive anions." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001047 ! aqueous_chemotaxis_defective

[Term]
id: WBPhenotype:0001053
name: cyclic_nucleotide_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Characteristic movement towards cyclic nucleotides is altered." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0000015 ! chemotaxis_defective

[Term]
id: WBPhenotype:0001054
name: cgmp_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Characteristic movement towards cGMP is altered." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001053 ! cyclic_nucleotide_chemotaxis_defective

[Term]
id: WBPhenotype:0001055
name: bromide_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure to move towards bromide." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001052 ! anion_chemotaxis_defective

[Term]
id: WBPhenotype:0001056
name: iodide_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure to move towards iodide." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001052 ! anion_chemotaxis_defective

[Term]
id: WBPhenotype:0001057
name: lithium_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure to move towards lithium." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype:0001058
name: potassium_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure of the animals to move towards potassium." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype:0001059
name: magnesium_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
def: "Failure to move towards magnesium." [WB:cab, WB:cgc387]
is_a: WBPhenotype:0001051 ! cation_chemotaxis_defective

[Term]
id: WBPhenotype:0001060
name: awc_volatile_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001061
name: awa_volatile_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001062
name: late_paralysis_arrested_elongation_two_fold
namespace: C_elegans_phenotype_ontology
def: "Movement and elongation stop nearly simultaneously soon after the twofold stage of elongation.  However\, mutant embryos twitch at the one-and-a-half-fold stage of elongation\, like wild type\, and move as well as wild type at the two- fold stage.  " [WB:cab, WB:cgc1894]
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0001063
name: egg_laying_phases_abnormal
namespace: C_elegans_phenotype_ontology
def: "Fluctuation between  inactive\, active\, and egg-laying states is atypical\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype:0000640 ! egg_laying_abnormal

[Term]
id: WBPhenotype:0001064
name: inactive_phase_long
namespace: C_elegans_phenotype_ontology
def: "Animals display uncharacteristically long periods during which they do not lay eggs\, as in HSN-ablated and serotonin-deficient animals\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype:0000006 ! egg_laying_defective
is_a: WBPhenotype:0001066 ! inactive_phase_abnormal

[Term]
id: WBPhenotype:0001065
name: fewer_egg_laying_events_during_active
namespace: C_elegans_phenotype_ontology
def: "Fewer egg-laying events occur within the active phase of egg laying\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype:0000006 ! egg_laying_defective
is_a: WBPhenotype:0001067 ! active_phase_abnormal

[Term]
id: WBPhenotype:0001066
name: inactive_phase_abnormal
namespace: C_elegans_phenotype_ontology
def: "The period during which the animal is less likely to lay eggs is not typical compared with wild type\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype:0001063 ! egg_laying_phases_abnormal

[Term]
id: WBPhenotype:0001067
name: active_phase_abnormal
namespace: C_elegans_phenotype_ontology
def: "The active phase of egg-laying\, the period during which aniamls are more likely to display multiple egg-laying events\, is atypical compared with wild-type animals\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype:0001063 ! egg_laying_phases_abnormal

[Term]
id: WBPhenotype:0001068
name: egg_laying_serotonin_insensitive
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000006 ! egg_laying_defective
is_a: WBPhenotype:0000024 ! serotonin_resistant

[Term]
id: WBPhenotype:0001069
name: increased_egg_laying_events_during_active
namespace: C_elegans_phenotype_ontology
def: "More eggs are laid during the active phase compared with wild type\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype:0001067 ! active_phase_abnormal

[Term]
id: WBPhenotype:0001070
name: inactive_phase_short
namespace: C_elegans_phenotype_ontology
def: "The period during which a worm usually does not lay eggs is short compared with wild type\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:9697864, WB:cab]
is_a: WBPhenotype:0001066 ! inactive_phase_abnormal

[Term]
id: WBPhenotype:0001071
name: active_phase_switch_defective
namespace: C_elegans_phenotype_ontology
def: "Activation of the active phase of egg laying is defective\, leading to an abnormally long inactive phase\, based on the analysis of the distribution of the log intervals of egg-laying events." [pmid:10757762, pmid:9697864, WB:cab]
is_a: WBPhenotype:0001064 ! inactive_phase_long

[Term]
id: WBPhenotype:0001072
name: response_to_food_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000738 ! organism_environmental_stimulus_response_abnormal

[Term]
id: WBPhenotype:0001073
name: egg_laying_response_to_food_abnormal
namespace: C_elegans_phenotype_ontology
def: "Well-fed animals do not lay more eggs compared with starved animals\, unlike wild type." [pmid:10757762, WB:cab]
is_a: WBPhenotype:0000640 ! egg_laying_abnormal
is_a: WBPhenotype:0001072 ! response_to_food_abnormal

[Term]
id: WBPhenotype:0001074
name: vulval_muscle_unresponsive_to_serotonin
namespace: C_elegans_phenotype_ontology
def: "The vulval muscle does not respond typically to serotonin\, based on imaging of calcium transients in response to serotonin." [pmid:14588249, WB:cab]
is_a: WBPhenotype:0001068 ! egg_laying_serotonin_insensitive
is_a: WBPhenotype:0001076 ! vulval_muscle_homeostasis_metabolism_abnormal

[Term]
id: WBPhenotype:0001075
name: vulval_muscle_physiology_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000613 ! reproductive_system_physiology_abnormal

[Term]
id: WBPhenotype:0001076
name: vulval_muscle_homeostasis_metabolism_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0001075 ! vulval_muscle_physiology_abnormal

[Term]
id: WBPhenotype:0001077
name: chromosome_segregation_abnormal_karyomeres_emb
namespace: C_elegans_phenotype_ontology
def: "Karyomeres in AB or P1 often accompanied by weak/thin wobbly spindle." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0000050 ! embryonic_lethal
is_a: WBPhenotype:0000773 ! chromosome_segregation_abnormal

[Term]
id: WBPhenotype:0001078
name: cytokinesis_abnormal_early_emb
namespace: C_elegans_phenotype_ontology
def: "Cytokinesis is abnormal in the first or second stages of cell division." [WB:cab, WB:cgc7141]
is_a: WBPhenotype:0001045 ! cytokinesis_abnormal_emb

[Term]
id: WBPhenotype:0001079
name: cytoplasmic_dynamics_abnormal_emb
namespace: C_elegans_phenotype_ontology
def: "Cytoplasmic movements are atypical." [WB:cab, WB:WBPerson1815]
is_a: WBPhenotype:0000769 ! cytoplasmic_appearance_abnormal_early_emb

[Term]
id: WBPhenotype:0001080
name: excessive_blebbing_emb
namespace: C_elegans_phenotype_ontology
def: "Excessive shaking and movements are seen in the cell membrane or cytoplasm of one-cell or two-cell embryos." [cgc:5599, WB:cab, WB:WBPerson1815]
is_a: WBPhenotype:0001079 ! cytoplasmic_dynamics_abnormal_emb

[Term]
id: WBPhenotype:0001081
name: cytoplasmic_morphology_abnormal_emb
namespace: C_elegans_phenotype_ontology
def: "Morphology of the cytoplasm differs from wild type." [WB:cab, WB:WBPerson1815]
is_a: WBPhenotype:0000769 ! cytoplasmic_appearance_abnormal_early_emb

[Term]
id: WBPhenotype:0001082
name: large_cytoplasmic_granules_emb
namespace: C_elegans_phenotype_ontology
def: "Abnormally large granules are observed in the cytoplasm of P0." [cgc:5599, WB:cab, WB:WBPerson1815]
is_a: WBPhenotype:0001081 ! cytoplasmic_morphology_abnormal_emb

[Term]
id: WBPhenotype:0001083
name: multiple_cytoplasmic_cavities_emb
namespace: C_elegans_phenotype_ontology
def: "Multiple vesicles\, vacuoles\, or cavities are seen during early embryoogenesis." [cgc:5599, WB:cab, WB:WBPerson1815]
is_a: WBPhenotype:0001081 ! cytoplasmic_morphology_abnormal_emb

[Term]
id: WBPhenotype:0001084
name: sodium_chloride_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000015 ! chemotaxis_defective

[Term]
id: WBPhenotype:0001085
name: butanone_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001086
name: trimethylthiazole_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001087
name: acetone_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001088
name: pentanol_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001089
name: hexanol_chemotaxis_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000265 ! volatile_odorant_chemotaxis_defective

[Term]
id: WBPhenotype:0001090
name: thermotolerance_decreased
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000146 ! organism_temperature_response_abnormal

[Term]
id: WBPhenotype:0001091
name: larval_defecation_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000650 ! defecation_abnormal

[Term]
id: WBPhenotype:0001092
name: larval_defecation_defect
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0001091 ! larval_defecation_abnormal

[Term]
id: WBPhenotype:0001093
name: intestinal_physiology_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000606 ! alimentary_system_physiology_abnormal

[Term]
id: WBPhenotype:0001094
name: NaCl_response_abnormal
namespace: C_elegans_phenotype_ontology
def: "Organismal response to NaCl differs from wild type." [WB:cab]
is_a: WBPhenotype:0000067 ! organism_stress_response_abnormal

[Term]
id: WBPhenotype:0001095
name: hypersensitive_high_NaCl
namespace: C_elegans_phenotype_ontology
def: "Generation time and number of progeny are reduced in response to growth on media containing high NaCl." [pmid:16027367, WB:cab]
is_a: WBPhenotype:0001094 ! NaCl_response_abnormal

[Term]
id: WBPhenotype:0001096
name: protrusion_at_vulval_region
namespace: C_elegans_phenotype_ontology
def: "Large protrusion at the normal position of the vulva\, as seen in lin-12 null animals." [cgc:646, WB:cab]
is_a: WBPhenotype:0000695 ! vulva_morphogenesis_abnormal

[Term]
id: WBPhenotype:0001097
name: premature_spermatocyte_germ_cell_differentiation
namespace: C_elegans_phenotype_ontology
def: "Premature differentiation of germ cells as sperm." [cgc:4207, WB:cab]
is_a: WBPhenotype:0000895 ! spermatocyte_germ_cell_differentiation_abnormal

[Term]
id: WBPhenotype:0001098
name: no_rectum
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000347 ! rectal_development_abnormal

[Term]
id: WBPhenotype:0001099
name: twisted_nose
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000321 ! nose_morphology_abnormal

[Term]
id: WBPhenotype:0001100
name: early_embryonic_lethal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000050 ! embryonic_lethal

[Term]
id: WBPhenotype:0001101
name: meiotic_spindle_abnormal_emb
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000759 ! embryonic_spindle_abnormal_emb

[Term]
id: WBPhenotype:0001102
name: mitotic_spindle_abnormal_emb
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000759 ! embryonic_spindle_abnormal_emb

[Term]
id: WBPhenotype:0001103
name: spindle_absent
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0001102 ! mitotic_spindle_abnormal_emb

[Term]
id: WBPhenotype:0001104
name: spindle_absent_P0
namespace: C_elegans_phenotype_ontology
def: "No mitotic spindle is seen in P0." [WB:cab, WB:WBPerson1815, XX:<new dbxref>]
is_a: WBPhenotype:0001103 ! spindle_absent

[Term]
id: WBPhenotype:0001105
name: embryonic_P0_spindle_position_abnormal_emb
namespace: C_elegans_phenotype_ontology
def: "Altered P0 spindle placement causes either a symmetric first division\, a division in which P1 is larger than AB\, or a division in which the asymmetry is exaggerated such that AB is much larger than normal." [WB:cab, WB:cgc5599, WB:WBPerson1815]
is_a: WBPhenotype:0000762 ! embryonic_spindle_position_abnormal_emb

[Term]
id: WBPhenotype:0001106
name: spindle_orientation_abnormal_AB_or_P1
namespace: C_elegans_phenotype_ontology
def: "The orientation of the spindle is aberrant in either the AB or the P1 cell." [WB:cab, WB:cgc5599, WB:WBPerson1815]
is_a: WBPhenotype:0000760 ! embryonic_spindle_orientation_abnormal_emb

[Term]
id: WBPhenotype:0001107
name: embryonic_spindle_rotation_abnormal_emb
namespace: C_elegans_phenotype_ontology
def: "Rotation of the embryonic spindle is aberrant." [WB:cab, WB:WBPerson1815]
is_a: WBPhenotype:0000759 ! embryonic_spindle_abnormal_emb

[Term]
id: WBPhenotype:0001108
name: embryonic_spindle_rotation_abnormal_P0_emb
namespace: C_elegans_phenotype_ontology
def: "P0 spindle fails to rotate and extends perpendicular to the long axis of the embryo." [WB:cab, WB:cgc5599, WB:WBPerson1815]
is_a: WBPhenotype:0001107 ! embryonic_spindle_rotation_abnormal_emb

[Term]
id: WBPhenotype:0001109
name: embryonic_spindle_rotation_delayed_P0_emb
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0001107 ! embryonic_spindle_rotation_abnormal_emb

[Term]
id: WBPhenotype:0004001
name: hermaphrodite_mating_abnormal
namespace: C_elegans_phenotype_ontology
def: "Characteritic hermaphrodite behavior during mating is altered." [WB:WBPerson557]
is_a: WBPhenotype:0000647 ! copulation_abnormal
is_a: WBPhenotype:0000821 ! sex_specific_behavior_abnormal

[Term]
id: WBPhenotype:0004002
name: attraction_signal_defective
namespace: C_elegans_phenotype_ontology
def: "Hermaphrodites defective for the production of the sensory signal to attract males" [WB:WBPaper00005109]
is_a: WBPhenotype:0004015 ! pre_male_contact_abnormal

[Term]
id: WBPhenotype:0004003
name: mate_finding_abnormal
namespace: C_elegans_phenotype_ontology
def: "Impaired ability of the male to respond to the hermaphrodite produced mate-finding cue." [WB:WBPaper00005109]
is_a: WBPhenotype:0004005 ! pre_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0004004
name: response_to_contact_defective
namespace: C_elegans_phenotype_ontology
def: "The inability of a male to respond properly to a potential mate after contact.  Proper response includes apposing the ventral side of his tail to the hermaphrodite's body and swimming backward." [WB:WBPaper00000392, WB:WBPaper00002109]
is_a: WBPhenotype:0004006 ! post_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0004005
name: pre_hermaphrodite_contact_abnormal
namespace: C_elegans_phenotype_ontology
def: "Characteristic male mating prior to hermaphrodite contact is altered" [WB:WBPerson557]
is_a: WBPhenotype:0000648 ! male_mating_abnormal

[Term]
id: WBPhenotype:0004006
name: post_hermaphrodite_contact_abnormal
namespace: C_elegans_phenotype_ontology
def: "characteristic of male mating after hermaphrodite contact is altered" [WB:WBPerson557]
is_a: WBPhenotype:0000648 ! male_mating_abnormal

[Term]
id: WBPhenotype:0004007
name: periodic_spicule_prodding_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000279 ! spicule_insertion_defective

[Term]
id: WBPhenotype:0004008
name: sustained_spicule_protraction_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000279 ! spicule_insertion_defective

[Term]
id: WBPhenotype:0004009
name: approximate_vulval_location_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000649 ! vulva_location_abnormal

[Term]
id: WBPhenotype:0004010
name: precise_vulval_location_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000649 ! vulva_location_abnormal

[Term]
id: WBPhenotype:0004011
name: sperm_transfer_cessation_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype:0004012
name: sperm_transfer_continuation_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype:0004013
name: sperm_release_defective
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000284 ! sperm_transfer_defective

[Term]
id: WBPhenotype:0004014
name: post_male_contact_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004001 ! hermaphrodite_mating_abnormal

[Term]
id: WBPhenotype:0004015
name: pre_male_contact_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004001 ! hermaphrodite_mating_abnormal

[Term]
id: WBPhenotype:0004016
name: dauer_nictation_behavior_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0001001 ! dauer_behavior_abnormal

[Term]
id: WBPhenotype:0004017
name: locomotor_coordination_abnormal
namespace: C_elegans_phenotype_ontology
def: "an altered ability to maintain characteristic and effective movement." [WB:WBperson557]
is_a: WBPhenotype:0000643 ! locomotion_abnormal

[Term]
id: WBPhenotype:0004018
name: sinusoidal_movement_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004017 ! locomotor_coordination_abnormal

[Term]
id: WBPhenotype:0004021
name: exaggerated_body_bends
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000664 ! exaggerated_body_bends

[Term]
id: WBPhenotype:0004022
name: amplitude_of_movement_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype:0004023
name: frequency_of_body_bends_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype:0004024
name: wavelenght_of_movement_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype:0004025
name: velocity_of_movement_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004018 ! sinusoidal_movement_abnormal

[Term]
id: WBPhenotype:0004026
name: nose_touch_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0004027
name: plate_tap_reflex_abnormal
namespace: C_elegans_phenotype_ontology
def: "abnormal response to substrate vibration" [WB:WBPerson557]
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0004028
name: slowing_response_on_food_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0004029
name: sex_specific_mechanosensory_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000315 ! mechanosensory_abnormal

[Term]
id: WBPhenotype:0004030
name: male_response_to_hermaphrodite_abnormal
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0004029 ! sex_specific_mechanosensory_abnormal

[Term]
id: WBPhenotype:0004031
name: mate_searching_abnormal
namespace: C_elegans_phenotype_ontology
def: "An altered ability to search for a mate as defined by failure of the \"leaving assay\"" [WB:WBPaper00024428]
is_a: WBPhenotype:0004005 ! pre_hermaphrodite_contact_abnormal

[Term]
id: WBPhenotype:0006001
name: squashed_vulva
namespace: C_elegans_phenotype_ontology
is_a: WBPhenotype:0000510 ! vulval_invagination_abnormal_at_L4

[Term]
id: WBPhenotype:0008001
name: embryonic_cell_fate_specification_abnormal
namespace: C_elegans_phenotype_ontology
def: "Any abnormality in the processes that govern acquisition of particular cell fates in the embryo\, from the time of zygote formation until hatching." [WB:kmva]
is_a: WBPhenotype:0000216 ! cell_fate_specification_abnormal
is_a: WBPhenotype:0000749 ! embryonic_development_abnormal

[Term]
id: WBPhenotype:0008002
name: embryonic_somatic_cell_fate_specification_abnormal
namespace: C_elegans_phenotype_ontology
def: "Any abnormality in the processes that govern acquisition of somatic cell fates in the embryo\, from the time of zygote formation until hatching." [WB:kmva]
is_a: WBPhenotype:0008001 ! embryonic_cell_fate_specification_abnormal

[Term]
id: WBPhenotype:0008003
name: odorant_imprinting_abnormal
namespace: C_elegans_phenotype_ontology
def: "Any abnormality that results in alterations to the process of odorant imprinting\, a learned olfactory response whereby exposure of animals to odorants during specific developmental times or physiological states results in a lasting memory that determines the animal's behavior upon encountering the same odorant at a later time." [WB:WBPaper00026662, WB:WBPerson1843]
exact_synonym: "olfactory_imprinting_abnormal" []
is_a: WBPhenotype:0001040 ! chemosensory_response_abnormal

[Term]
id: WBPhenotype:0010001
name: cell_growth_abnormal
namespace: C_elegans_phenotype_ontology
def: "The process(es) by which a cell irreversibly increases in size over time by accretion and biosynthetic production of matter similar to that already present\, is altered." [GO:0016049, WB:rk]
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0010002
name: cell_organization_and_biogenesis_abnormal
namespace: C_elegans_phenotype_ontology
def: "The process(es) involved in the assembly and arrangement of cell structures is altered." [GO:0016043, WB:rk]
is_a: WBPhenotype:0000536 ! cell_physiology_abnormal

[Term]
id: WBPhenotype:0010003
name: cell_corspe_appearance_delayed
namespace: C_elegans_phenotype_ontology
def: "The appearance of cell corpses and their clearance is delayed " [WB:rk]
is_a: WBPhenotype:0000185 ! apoptosis_protracted

[Term]
id: WBPhenotype:0010004
name: cell_corpse_degradation_abnormal
namespace: C_elegans_phenotype_ontology
def: "The normal process(es) that constitute cell corpse degradation within the engulfing cell  is altered." [WB:rk]
xref_analog: WB:rk
is_a: WBPhenotype:0000730 ! apoptosis_abnormal

[Typedef]
id: part_of
name: part_of
is_transitive: true

