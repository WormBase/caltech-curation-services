#!/usr/bin/perl

# Enter Australian Worm Meeting data.  Some Authors were munged and had to hand
# edit the input file.  2007 05 26

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw ( processWormbook );

use strict;

my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);

$journal = 'First Australian C. elegans Meeting';
$year = '2007';
$type = 'Meeting Abstract';

my $starttime = time;

my $infile = 'test_australian.txt';
undef $/;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";

my (@abs) = split/\n\d\d\n/, $allfile;

# Transformation of Parastrongyloides trichosuri, a parasitic nematode
# 
# Grant, W.N.1, Shuttleworth, G.2, Newton-Howes, J.2 and Grant, K.I.1
# 1Genetics Department, La Trobe University, Bundoora, Australia
# 2The Hopkirk Research Institute, AgResearch Ltd., Palmerston North, New Zealand


my $counter = 0;
$abs[0] =~ s/^\d+//; 
foreach my $abs (@abs) {
  $counter++;
  my $identifier = 'austwm07abs' . $counter;
#   print "ABS $abs ABS\n";
  if ($abs =~ m/^\s*(.*?)\n\n(.+?)\n\n(.+)$/sm) {
#   if ($abs =~ m/^\s*?(\w.+?)\n\s+(\w.+?)\n\s+([.\n\f]*)$/m)
    $title = $1; my $auths = $2; my $abst = $3;
#     print "TITLE $title\n";
    my (@alines) = split/\n/, $auths;
    $auths = shift @alines;
    if ($auths =~ m/\d+,\d+/) { $auths =~ s/\d+,\d+//g; }
    if ($auths =~ m/\d+/) { $auths =~ s/\d+//g; }
    if ($auths =~ m/\sand\s/) { $auths =~ s/\sand\s/, /g; }
    if ($auths =~ m/\s\&\s/) { $auths =~ s/\s\&\s/, /g; }
    my (@auths) = split/,/, $auths;
    $authors = '';
    foreach my $auth (@auths) { 
      $auth = &filterSpaces($auth);
      if ($auth =~ m/\d+/) { $auth =~ s/\d+//g; }
      if ($auth) { 
#         print "AUTH $auth\n"; 
        $authors .= $auth . '//';
      }
    }
    $authors =~ s/\/\/$//;
    if ($authors =~ m/\t/) { $authors =~ s/\t//g; }
#     print "AUTHS $authors\n";

#     $abs =~ s/$title//g;
#     $abs =~ s/$auths//g;
    $title = &filterSpaces($title);
    $authors = &filterSpaces($authors);
    $abst = &filterSpaces($abst);
#     print "ABS $abst\n\n";

    my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abst\t$genes\t$type\t$editor\t$fulltext_url";
    print "$line\n";
    &processWormbook( 'two480', 'wormbook', $line );	# 480 is Tuco
  } else { print "NO MATCH $abs\n"; }
}

my $endtime = time;
my $difftime = $endtime - $starttime;
print "Diff time is $difftime seconds\n";

sub filterSpaces {
  my $entry = shift;
  if ($entry =~ m/\n+/m) { $entry =~ s/\n+/. /mg; }
  if ($entry =~ m/\t+/m) { $entry =~ s/\t+/. /mg; }
  if ($entry =~ m/\s+\.\s+/m) { $entry =~ s/\s+\.\s+/ /mg; }
  if ($entry =~ m/^\n+/m) { $entry =~ s/^\n+//mg; }
  if ($entry =~ m/\n+$/m) { $entry =~ s/\n+$//mg; }
  if ($entry =~ m/^\r+/m) { $entry =~ s/^\r+//mg; }
  if ($entry =~ m/\r+$/m) { $entry =~ s/\r+$//mg; }
  if ($entry =~ m/^\f+/m) { $entry =~ s/^\f+//mg; }
  if ($entry =~ m/\f+$/m) { $entry =~ s/\f+$//mg; }
  if ($entry =~ m/^\.\s+/) { $entry =~ s/^\.\s+//g; }
  if ($entry =~ m/^\s+/) { $entry =~ s/^\s+//g; }
  if ($entry =~ m/\s+$/) { $entry =~ s/\s+$//g; }
  return $entry;
} # sub filterSpaces


__END__

DELETE FROM wpa WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_journal WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_volume WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_abstract WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2007-05-26 11:12:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2007-05-26 11:12:00';


01
Are REEP family members involved in membrane trafficking of olfactory receptors in Caenorhabditis elegans?

Guangmei Zhang, Chunyan Liao, Irene Horne, Stephen Trowell
Food Futures Flagship, CSIRO Division of Entomology, Black Mountain ACT 2601, Australia

Receptor expression enhancing proteins (REEPs), as their name suggests, enhance the expression of chemosensory G-protein coupled receptors.  First detected in yeast, they have also been identified and isolated from many other organisms including plants, insects and mammals.  In mouse, at least six REEP genes have been identified by BLAST searching of the genome. mREEP1 is strongly expressed in olfactory neurons.  Coexpression of mREEP1 and murine olfactory receptors (ORs) in HEK293 cells promoted cell surface expression of ORs and enhanced their responses to odorants.  We BLASTed mREEP amino acid sequences against the C. elegans genome and recovered five putative REEP homologues (designated CeREEP1-5). CeREEP1 has approximately 37% amino acid identity with mREEP1 and, like mREEP1, contains two predicted transmembrane domains, within which the levels of sequence conservation are much higher.  CeREEP2-5 each have three predicted transmembrane domains.  Although expression of CeREEP3 has not yet been detected, RT-PCR demonstrated that the other putative REEP genes are strongly expressed in C. elegans. A transgenic strain of nematode expressing a fusion between the CeREEP1 promoter and green fluorescent protein demonstrated that CeREEP1 gene is strongly expressed in a subset of amphid chemosensory neurons. These results suggest that CeREEP1 may have a similar function to mREEP1 being involved in membrane transport and targeting of ORs in C. elegans.



02
Functional expression of a Drosophila odorant receptor in C. elegans

Chunyan Liao, Mira Dumancic, Guangmei Zhang, Coralie Moore, Briony Cowper, Irene Horne, Stephen Trowell
Food Futures Flagship, CSIRO Division of Entomology, Black Mountain ACT 2601, Australia

Functional expression of odorant receptors (ORs) in a heterologous system is invaluable for exploring the molecular mechanisms of odorant perception and the odorant receptivity of ORs.  In Caenorhabditis elegans and vertebrates, odorants are sensed by large and diverse families of G protein-coupled receptors (GPCRs).  The status of insect ORs is controversial.   In C. elegans two pairs of ciliated olfactory neurons, AWA and AWC, sense many volatile attractants.  Using a small number of AWA- and AWC- targetted promoters and biolistic transformation, we expressed Drosophila OR43a in the AWA or AWC neurons of the nematode.  Known ligands of dOR43a include benzaldehyde, benzyl alcohol and related odorants, which are normally attractive to the nematode.   The chemotactic responses of transgenic nematodes expressing dOR43a were tested with these odorants as well as some unrelated compounds.  All transgenic strains expressing dOR43a show markedly reduced attraction to all five of the dOR43a ligands that were tested, regardless of whether the transgene was expressed in AWA or AWC.  The transgenic strains retained wild-type responses to odorants that are not ligands for dOR43a, including diacetyl, pyrazine and 2,3-pentanedione.  Preliminary immunolocalisation experiments indicate that the transgene OR43a was expressed in the cilia and dendrites of amphid neurons.  This is the first demonstration, to our knowledge, that heterologous expression of a chemosensory receptor leads to a readily observable behavioural change at the whole organism level.  We propose a limited number of testable hypotheses concerning the mechanism of integration of dOR43a into the C. elegans chemosensory system.



03
A worm's view of the bacterial world

FL Khaw, TS Sloan-Gardner, U Mathesius, CA Behm
The School of Biochemistry & Molecular Biology, Faculty of Science, The Australian National University, Canberra, A.C.T., Australia, 0200

C. elegans is a soil-dwelling nematode that encounters many microorganisms throughout its natural life.  Bacteria in the soil environment may provide food for C. elegans or may be pathogenic.  Some of these bacteria exhibit a form of density-dependant intercellular communication known as quorum sensing (QS), which involves secreted autoinducer molecules.  N-acyl homoserine lactones (AHLs) are quorum sensing signals that are produced primarily by Gram negative bacteria, including soil-dwelling species, such as Pseudomonas aeruginosa.  In this study, we have investigated C. elegans' behavioural responses to AHL autoinducers. We have used chemosensory mutants of C. elegans to explore which neuron(s) are involved in AHL detection.  Their behaviour was measured using two-choice chemotaxis assays to determine a choice index and thus the attractiveness of an AHL odorant.  We found that C. elegans detected a short-chain AHL as a volatile molecule and appeared to engage both its pairs of volatile attractant sensing neurons in the detection.  This study gives us information about C. elegans' interaction with soil bacterial signals and aid the exploration of its potential capacity to distinguish between pathogenic and non-pathogenic bacteria in its environment.

04
Quorum sensing detection in C. elegans

Yoo-Mi Kim, Fay Khaw, Timothy Sloan-Gardner, Ulrike Mathesius, Carolyn Behm
The School of Biochemistry & Molecular Biology, The Australian National University, Canberra

 'Quorum sensing' (QS) is a process in bacteria to regulate their behaviour by changing their gene expression in a cell-population density dependent manner, by exchanging QS signal molecules (QSSs) to signal between cells. These QS regulated genes are crucial to virulence, biofilm formation, and nutrient acquisition. Many Gram-negative bacteria such as Pseudomonas aeruginosa produce N-acyl homoserine lactone (AHL) QSSs. 

Caenorhabditis elegans is a free-living soil nematode that feeds on bacteria in soil. C. elegans displays a sophisticated chemosensory system to detect a wide range of chemicals present in soil, despite the fact that they only have 302 neurons, which makes this organism a good model to study quorum sensing detection in eukaryotes. P. aeruginosa produces two different AHL compounds and we have found that C. elegans are able to detect and respond differentially to these AHL compounds.

 It has been reported that eukaryotes are not only able to detect QSSs from bacteria, but they are able to produce QSS mimic compounds in order to interfere with QS-regulated gene expression in bacteria. Lumichrome is a break-down compound of riboflavin that is produced in plant roots as well as by some bacteria, and a recent study found that it acts as a QSS mimic compound in some bacteria. 

 The behavioural responses of C. elegans towards AHLs and lumichrome will be analysed using chemotaxis assays. Proteome analysis will be applied to detect a range of physiological responses of C. elegans to AHLs and lumichrome.

05

Investigating the expression profiles of the olfactory neurons of C. elegans

Nicholas M. Johnson, Timothy S. Sloan-Gardner, Ulrike Mathesius and Carolyn A. Behm
The School of Biochemistry & Molecular Biology, The Australian National University

C. elegans can respond to a wide array of volatile odours using three pairs of bilaterally symmetrical sensory neurons. The AWA and AWC neurons detect attractive odours and the AWB neurons detect repellent ones. The compositions of the signal transduction pathways that are active within these cells are beginning to be resolved, principally with the use of classical genetics. However, the global gene expression profile of these cells remains unknown. Microarray analysis is the standard technology for measuring global gene expression, but in order to use this approach, mRNA must be isolated from single pairs of olfactory neurons.
Recently, cell-specific microarray analysis for C. elegans has been achieved through the development of the mRNA-tagging technique (Roy et al Nature 418, 2002; Kunitomo et al Genome Biology 6, 2005; Von Stetina et al Genes and Development 21, 2007). This approach involves using a recombinant C. elegans polyA binding protein (FLAG::PAB-1) to isolate the mRNA population from a tissue of interest. FLAG::PAB-1 is expressed with the use of a tissue-specific promoter and is tagged with a FLAG epitope to enable purification of the recombinant protein. Following purification, mRNA bound by FLAG::PAB-1 is eluted and analysed with microarrays.
We are using the mRNA tagging approach to investigate the gene expression profiles of AWA, AWB and AWC neurons. Our progress will be reported.




06
MITR-1 is a novel nematode-specific protein required for mitochondrial respiration in C. elegans

Nicholas M. Johnson, Ranga S. Kumarasinghe, Timothy S. Sloan-Gardner, Julie-Anne Fritz, Suzannah Hetherington and Carolyn A. Behm
School of Biochemistry and Molecular Biology, The Australian National University, Canberra ACT 0200, Australia

Mutations affecting components of C. elegans mitochondria have varied effects on the worm, from increased oxidative stress susceptibility to developmental defects. Perhaps the most interesting mutants are those that cause increased life span such as in the case of the clk-1 gene, which is required for the biosynthesis of coenzyme Q (CoQ), an essential co-factor in mitochondrial respiration.
      Here we introduce mitr-1, a novel, nematode-specific gene, which plays an essential role in mitochondrial respiration and energy production and has many of the hall-marks of other clk genes, included an increased life span following gene knockout. mitr-1(RNAi) worms are small, slow growing, have small brood sizes and display a slowdown in some rhythmic processes such as defecation and egg-laying, which manifests as a highly penetrant lethal egg-laying defect (Egl). Those worms that do not die from Egl have significantly extended life spans in a manner independent of the insulin-like/DAF-2 signalling pathway. MITR-1::GFP is localised to mitochondria throughout the worm and is expressed at all development stages. Biochemical analysis reveals that MITR-1 is required for mitochondrial respiration: mitr-1(RNAi) worms have low oxygen consumption rates and low free-ATP levels. Removal of MITR-1 also results in expression of hsp-6::GFP, which is a reporter of mitochondrial stress and protein instability.
      In an attempt to better understand how MITR-1 contributes to mitochondrial respiration, we performed yeast two-hybrid screening to identify protein interactors of MITR-1. A putative physical interaction between MITR-1 and components of the E1 subunit of the pyruvate dehydrogenase complex (PDC) was identified. This implicates MITR-1 at the site of a critical metabolic reaction: the production of acetyl CoA from pyruvate. We are using GST-pull down experiments to test this interaction.


07
Using C. elegans to Solve the Phosphine Resistance Puzzle

Nick Valmas
School of Integrative Biology, University of Queensland

Phosphine is an important fumigant in the stored products industry, and especially to the Australian grain industry as it is their most potent defence against pest insects. However several species of grain insects are developing high-level phosphine resistance, which threatens existing fumigations procedures and could result in the loss of phosphine as a protective measure. I have used C. elegans as a model organism for the study of phosphine resistance and have used three strategies of investigation: synergist discovery to overcome resistance; finding a possible replacement chemical; and the genetic mapping of a phosphine resistant mutant, pre-7.

08
The role of Complex II in the metabolism of C. elegans

Jujiao Kuang
School of Integrative Biology, University of Queensland

Mitochondria are the essential organelles of oxidative respiration in eukaryote cells, and their central role is cellular energy production via oxidative phosphorylation through mitochondrial electron transport chain (ETC). Complex II of ETC, also known as succinate dehydrogenase, plays important role in both aerobic and anaerobic respiration. I have investigated the function of all four distinct subunits of complex II, in longevity and oxidative stress, using nematode Caenorhabditis elegans. RNA-mediated interference (RNAi) was employed to inactivate all six genes encoding complex II subunits. And phosphine gas was used as an oxidative stressor in this study. No lifespan extension was observed in nematodes with impaired complex II activity. But silence of two genes encoding subunit SDHA, the largest subunit in the enzyme complex, has triggered increased sensitivity to phosphine, which might indicate an increase in production of Reactive Oxygen Species (ROS). Future study is required to complete this systematic study, including the metabolic measurement (development rate, body size, reproduction, and oxygen consumption rate), mitochondrial membrane potential, body fat storage, NADH activity and expression of genes encoding antioxidant defence enzymes and different metabolic pathways. 


09

Mitochondrial dysfunction induces starvation pathways and oxidative stress protection extending lifespan

Steven Zuryn
School of Integrative Biology, University of Queensland

Lifespan in C. elegans is extended by a reduction in mitochondrial electron transport chain (ETC) activity in a manner distinct from either insulin/IGF-1 signalling or dietary restriction; the two other longevity pathways in C. elegans. To understand this effect, we have systematically silenced twenty-two ETC genes - identifying ten new longevity genes - whilst measuring physiological and metabolic changes. In these worms, a set of genes are up-regulated which function to promote fat-to-glucose conversion, in response to crippled energy production. This metabolic strategy, which also appears to be utilised in long-lived dauer larvae, insulin/IGF-1 mutants, and nematodes deprived of food, now appears to be a unifying feature of all three longevity mechanisms. We propose glucose is used to fuel somatic maintenance in neurons as oxidative stress defence genes are up-regulated. 

10
Population structure and genome assembly in Haemonchus contortus: Can C. elegans data help?

Peter Hunt, Jody McNally and Wes Barris
CSIRO BrisbaneB and ArmidaleA

Genetic diversity in populations of parasitic nematodes can allow selection to take place when pressure is placed upon these populations by environmental forces, including those imposed by man. A crucial example is selection for drug resistance in parasites of livestock, through the sometimes indiscriminate use of anthelmintics. Multiple drug resistance has already led to the failure of some sheep enterprises in both Australia and South Africa.
There has been a long history of using C. elegans to assist discovery of genes for drug resistance in parasitic nematodes such as H. contortus, in partnership with studies on the parasitic species themselves. Phylogenetic analysis implies that the clades to which H. contortus and C. elegans belong are relatively close in comparison to the relationship between C. elegans and other important nematode parasites. However, a disconnect between laboratory studies using C. elegans and studies of "wild" parasite populations is caused by the very high degree of genetic diversity in some parasites, expecially those in the Trichostrongylidae clade (examples are: H. contortus, Teladorsagia circumcincta, Ostertagia ostertagi). This diversity is so high that it has impaired assembly of the H. contortus shot-gun sequenced genome. BAC and Fosmid sequencing projects are underway to try and improve our ability to assemble genome information, but a genetic linkage map would also be highly useful as a framework for assembly.
At CSIRO we have begun a project to study genetic and phenotypic diversity of H. contortus in Australia. We are considering virulence and drug resistance as key phenotypes of interest; my talk will concentrate on the use of simple sequence repeat markers (SSR or microsatellite markers) for our investigation of population structure in H. contortus within Australia.
I will describe some of our bioinformatics work which aims to map published microsatellite markers to H. contortus genome sequence and also discover potential new markers. As part of marker design work, an attempt to map genes and nearby SSR markers to putative C. elegans homologs was made and I present the results. I will also present some data from an attempt to map markers by PCR from unfertilised oocytes. Finally I will describe some results from our population work which show both some of the dangers and possibilities for inference of population structure and marker linkage using wild populations and microsatellite markers.

11
VHA-19, a protein predicted to associate with the vacuolar ATPase, is critical for reproduction and development in C. elegans

Alison Knight, Nick Johnson, Suzannah Hetherington, Julie-Anne Fritz and Carolyn Behm.
School of Biochemistry and Molecular Biology, Australian National University, Canberra, Australia.

The vacuolar ATPase enzyme (v-ATPase) is found in many organisms and is involved in many key processes including sperm maturation, bone regeneration and tumour metastasis in mammals and cell fusion in yeast. v-ATPases pump protons across membranes and therefore contribute to the overall pH of cellular compartments. vha-19 is a C. elegans gene that has been predicted to associate with v-ATPase but this association has yet to be proved directly, and the exact function of vha-19 is so far unknown. 

We have found that RNA interference mediated (RNAi) knockdown of vha-19 from the first larval stage has a severe effect on development in C. elegans. Silencing vha-19 by RNAi from the fourth C. elegans larval stage produced adults that were grossly normal in appearance, but these worms produced very few viable embryos, and those progeny that did hatch all arrested in development by the third larval stage. A transgenic C. elegans strain containing the presumed vha-19 promoter fused to a GFP reporter protein showed that vha-19 is probably expressed in similar tissues to other C. elegans v-ATPase genes. Also, C. elegans in which vha-19 had been knocked down by RNAi stained less intensely with the fluorescent dye acridine orange than controls. This suggests knockdown of vha-19 may affect pH in cell compartments, consistent with the predicted association between VHA-19 and v-ATPase. This is the first reported study of vha-19 in C. elegans. 

12
MLT-12, a protein involved in nematode molting and development

Julie-Anne Fritz and Carolyn Behm
The School of Biochemistry & Molecular Biology, The Australian National University

Nematodes develop through five post-embryonic stages separated by a molt, which permits rapid growth. The process of molting is thought to have evolved to provide nematodes and other Ecdysozoans with greater flexibility to adapt to changing environmental conditions. MLT-12 is a nematode-specific protein that is involved in molting. We have shown that a reduction in mlt-12 mRNA by RNAi leads to worms that are unable to degrade the old cuticle during the molting process, and become trapped in it. A GFP reporter fusion reveals that mlt-12 is predominately expressed within the epithelia where it is secreted to the cuticle. Here its absence is believed to alter the otherwise highly ordered assembly of the cuticle leading to the inability of proteases or other enzymes to degrade cuticular components at the molt. In addition, mlt-12 is expressed in neurons and the vulval muscles. Based on this differential tissue expression, MLT-12 is believed to carry out other, as yet, unknown functions during development. Our investigations of these functions, and the role of MLT-12 during the molting process, will be presented.

13
Functional characterization of noah-1 and noah-2 in the nematode Caenorhabditis elegans.

A. Biswas, L.Wise, J-A Fritz, N. Johnson, C. Behm
The School of Biochemistry & Molecular Biology, The Australian National University

C.elegans, a small free-living soil nematode, serves as a good genetic model for many parasitic nematode species as it shows significant genetic similarity to these parasites. Parasitic nematodes cause considerable morbidity in humans and huge economic losses in both the livestock industry and the agriculture industry and anthelmintic resistance to existing drugs has been increasing. Therefore it has become absolutely necessary to find novel drug targets. One characteristic of a good drug target is specificity, a target that must be either absent in the host or have sufficiently different pharmacology. noah-1 and noah-2 encode nematode specific proteins that are predicted to be components of the cuticle. We have shown that RNA interference of either noah-1 or noah-2 results in defects in moulting, mobility, egg laying, pharyngeal pumping, development and feeding. Such adverse phenotypic effects when their expression is knocked down in C.elegans suggest that these genes are essential. Consequently, knowing their function can contribute to research into potential drug targets for the control of parasitic nematodes. In addition, the spatial expression pattern of noah-2 suggests that this gene is exclusively expressed in the hypodermis and the cuticle. Moreover, it was found that the mRNA expression levels of noah-1 and noah-2 peak before each larval moult, but were down regulated between moulting events. The project currently focuses on three main objectives. The first objective is to further characterize the spatial expression pattern of noah-2 in addition to noah-1 using translational GFP reporter constructs. This will contribute to more detailed information about their cellular localization. The second objective is to characterize the temporal expression pattern of noah-1 and noah-2 using Real-Time PCR. This will quantify the amount of mRNA expressed at a particular time in development. And, the last objective is to determine the range of proteins that are able to interact with NOAH-1 and NOAH-2 using the yeast-two hybrid method. 
Once more information about the function of these genes and their protein products is obtained, it is possible that we may uncover pathways or potential protein interactions that NOAH-1 and NOAH-2 participate in. If these pathways are crucial for viability of the worms and are specific or selective in nature (e.g. enzymes), they may contribute to identifying new drug targets for parasitic nematodes.     

14

The Insulin/IGF signalling transduction pathway in Parastrongyloides trichosuri, does it play a role in parasitism and ageing?

Susan Stasiuk1 and Warwick Grant2.
1Hopkirk Research Institute, AgResearch, Palmerston North New Zealand
2Genetics Department, La Trobe University, Melbourne Australia

Parastrongyloides trichosuri is an intestinal parasite of the Australian brush-tailed possum (Trichosuris vulpecula). In the early L1 stage, P. trichosuri make a developmental choice to become either a short lived, free-living nematode or a long lived parasite. We show that this developmental choice appears to be triggered by environmental signals such as temperature, food availability and population density , all known to be factors which influence entry of C. elegans into the dauer pathway. (daumone).  We also report that free-living P. trichosuri excrete a factor which is  the primary mediator of the switch from free-living to parasitic development and that this factor most likely also influences the lifespan of the free-living form of this species.  We hypothesise that this factor is analogous to C. elegans dauermone.

In C. elegans, daumone is believed to influence the signalling state of the Insulin/IGF signalling pathway, the end result of which is to initiate either normal adult development or diapause entry. Furthermore, mutation of some genes of the Insulin/IGF signal transduction pathway confer a 3-5 fold extension in C. elegans lifespan. The key genes involved in the Insulin/IGF pathway are the putative IGF-receptor, daf-2; the phosphatidylinositol 3-OH kinase, age-1 and the forkhead transcription factor, daf-16. We have cloned the putative orthologues of these components of the Insulin/IGF signalling pathway from P .trichosuri and aim to test the role that these Insulin/IGF signalling pathway gene orthologues may play in P. trichosuri ageing and development.

Since the unusual life history of P. trichosuri includes a completely free-living life cycle, we are able to maintain this species indefinitely in the laboratory as a free-living nematode. It is therefore amenable to manipulation using both classical genetic and molecular genetic techniques (see Grant et al., this meeting). Under the correct environmental conditions, it can then be switched into the parasitic life cycle. P. trichosuri therefore presents us with the opportunity to study an organism where aging and developmental plasticity are the result of a natural developmental choice and differential gene expression, rather then the result of knockdown or mutation of genes.  This may allow for the opportunity to discover novel longevity genes that are silent in the model systems currently used. 

15
Caenorhabditis elegans as a model in which to investigate the functions of a transcriptional co-repressor

Hannah Nicholas, Chu Kong Liew, Tina Wu, Joel Mackay and Merlin Crossley
School of Molecular and Microbial Biosciences, University of Sydney

Transcriptional co-repressors of the C-terminal binding protein (CtBP) family interact with other proteins that contain amino acid motifs of the form PXDLS. These motifs occur in many transcription factors, and serve to recruit CtBP and its associated repression complex to DNA-regulatory elements. 
In mammals there are two CtBP genes, with overlapping functions. Disruption of both genes leads to early lethality. We have identified a single CtBP-related gene in C. elegans. This worm CtBP (CTBP-1) binds PXDLS-containing transcription factors and can repress transcription, indicating that the nematode protein is functionally orthologous to other CtBPs. C. elegans therefore provides a tractable model system for investigating CtBP function. 
We have begun investigating CTBP-1. This protein contains an additional domain not found in other characterised members of the CtBP family, which homology searches have identified as a THAP domain. We have shown that the domain can bind to double-stranded DNA. We have also determined the structure of this domain and shown that it contains a positively charged face that may correspond to the DNA-contact surface. The C. elegans CtBP protein is the first CtBP protein with an intrinsic DNA-binding function and may serve as a DNA-binding transcriptional repressor in vivo.
In order to examine the in vivo roles of CTBP-1, we have obtained a ctbp-1 deletion allele from the C. elegans knockout consortium. Worms carrying this allele display a mild uncoordinated phenotype. Progress towards a molecular and cellular explanation of this phenotype will be presented. 

16
 An analysis of CtBP function in C. elegans

Saul Bert and Hannah R. Nicholas
School of Molecular and Microbial Biosciences, University of Sydney

The C-terminal Binding Protein (CtBP) is a well characterised transcriptional co-repressor with homologues found in many diverse organisms. In vertebrates, CtBP has been implicated in a variety of important processes such as apoptosis, with CtBP null organisms exhibiting embryonic lethality. To gain a more complete understanding of this co-repressor's function, we are investigating CtBP's function in Caenorhabditis elegans, wherein a CtBP reduction of function strain (ok498) is viable.
in situ hybridisation studies have suggested broad expression of CtBP throughout C. elegans development. We intend to corroborate this finding through the creation of polyclonal CtBP antibodies which will be used to define the expression pattern of CtBP in worms, allowing us to infer potential functions for this protein.
We are particularly interested in a possible role for CtBP in the regulation of apoptosis, and have commenced an investigation using Differential Interference Contrast (DIC) microscopy, together with SYTO(r) 12 staining, to observe variations in germ line apoptosis in live worms. We intend to compare levels of both physiological and gamma radiation induced germ line apoptosis, between wild type (N2) and the ok498 mutant strain of C. elegans. 
 In parallel to this study, we will undertake a non-complementation screen, with the final aim of generating novel CtBP mutants allowing for further functional analysis.
 

17
Identification and Characterisation of Mechanistic Partners of ctbp-1 in Caenorhabditis elegans

Daniel D. Scott, Poh S. Khoo and Hannah R. Nicholas
School of Molecular and Microbial Biosciences, University of Sydney

The CtBP family of transcriptional corepressors has been widely investigated in murine and Drosophila model systems, in which it plays essential roles in development, cellular proliferation and apoptosis; however the Caenorhabditis elegans family member ctbp-1 remains relatively uncharacterised.  Yeast-2-hybrid screens in our laboratory have identified a number of putative binding partners of ctbp-1 including transcription factors pag-3, zag-1 and egl-13, and the SUMOylation enzyme ubc-9.  Other research has also suggested the histone deacetylase sir-2 and the C. elegans Rb homologue lin-35 as cofactors of ctbp-1.  We aim to confirm and investigate these proposed partners by screening for genetic interactions between ctbp-1 and each candidate. These shall be identified in pseudo-double mutants constructed by knockdown of ctbp-1 expression by RNA interference within a genetic background containing a mutant candidate. Further, we shall conduct an unbiased mutagenesis screen for genetic interactions with a view to identifying hitherto unknown mechanistic partners of ctbp-1.  These data shall significantly expand our knowledge of how ctbp-1 functions in nematodes and may provide insights into the activities of the CtBP family as a whole.

18

Transformation of Parastrongyloides trichosuri, a parasitic nematode

Grant W.N.1, Shuttleworth G.2, Newton-Howes J.2 and Grant K.I.1
1Genetics Department, La Trobe University, Bundoora, Australia
2The Hopkirk Research Institute, AgResearch Ltd., Palmerston North, New Zealand

The investigation of parasitic nematode biology has been hampered by the lack of tools for genetic analysis and manipulation. Nematodes of the genus Parastrongyloides have an unusual life history composed of a conventional parasitic life cycle as gastrointestinal parasites and a completely free-living life cycle. The switch between life cycles is determined by environmental conditions (see Grant & Stasiuk, this meeting), so that under appropriate conditions these worms can be maintained indefinitely as free-living nematodes. We have taken advantage of this free-living life cycle to produce transgenic Parastrongyloides trichosuri, a parasite of the Australian brush tail possum.

The free living female adult of P. trichosuri is similar to adult C. elegans hermaphrodites: the reproductive anatomy is a central vulva with bilaterally symmetrical gonad arms extending posterior and anterior. The gonad arms a reflexed, with a gonadal syncytium at the distal end of each arm. Transgenic worms were generated by microinjection of DNA into the gonadal syncytium and recovery of transgenic progeny in the F1. Inheritance of the transgene is consistent with the formation of extrachromosomal arrays, as in C. elegans, so that a proportion of progeny from a transgenic mother carry the transgene. Transmission of the transgene occurs in the parasitic as well as the free living life cycle. The transgene expression is low, perhaps a result of silencing, but using a constitutive promoter derived from the P. trichosuri orthologue of the hsp-1 gene we have also shown expression in both the parasitic and the free-living life cycles. This technology may permit manipulation of the host-parasite relationship and/or the delivery of bioactive proteins to the host by a transgenic worm: we present evidence that a protein encoded by a transgene and expressed during the parasitic life cycle can elicit a biological response from the host infected with the transgenic worms. 

