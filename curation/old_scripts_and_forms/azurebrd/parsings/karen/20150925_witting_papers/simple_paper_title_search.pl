#!/usr/bin/perl -w

# find matches for some papers.  doesn't work too well because titles are often in different formats. for Karen 2015 09 25

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $infile = 'wittings_papers.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($title, $author, $year) = split/\t/, $line;
  my ($lctitle) = lc($title);
  my @papids;
  $result = $dbh->prepare( "SELECT * FROM pap_title WHERE LOWER(pap_title) = '$lctitle'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { push @papids, "WBPaper$row[0]"; } 
  my $papids = join",", @papids;
  unless ($papids) {
    $result = $dbh->prepare( "SELECT * FROM pap_title WHERE LOWER(pap_title) ~ '$lctitle'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { push @papids, "WBPaper$row[0]"; } 
    $papids = join",", @papids; }
  print qq($papids\t$line\n);
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

__END__

Metabotyping of Caenorhabditis elegans reveals latent phenotypes	Blaise	2007
Top-Down Lipidomic Screens by Multivariate Analysis of High-Resolution Survey Mass Spectra	Schwudke	2007
A comparative metabolomics study of NHR-49 in Caenorhabditis elegans and PPAR-alpha in the mouse	Atherton	2008
LET-767 Is Required for the Production of Branched Chain and Long Chain Fatty Acids In Caenorhabditis elegans	Entchev	2008
Lipid extraction by methyl-tert-butyl ether for high-throughput lipidomics	Matyash	2008
A blend of small molecules regulates both mating and development in Caenorhabditis elegans	Srinivasan	2008
Metabolic Profiling Strategy of Caenorhabditis elegans by Whole-Organism Nuclear Magnetic Resonance	Blaise	2009
The Metabolomic Responses of Caenorhabditis elegans to Cadmium Are Largely Independent of Metallothionein Status, but Dominated by Changes in Cystathionine and Phytochelatins	Hughes	2009
Visualizing the spatial distribution of biomolecules in C. elegans by imaging mass spectrometry	Kimura	2009
A shortcut to identifying small molecule signals that regulate behavior and development in Caenorhabditis elegans	Pungaliya	2009
Long-lived mitochondrial (Mit) mutants of Caenorhabditis elegans utilize a novel metabolism	Butler	2010
A metabolic signaturer of long life in Caenorhabditis elegans	Fuchs	2010
Maradolipids: Diacyltrehalose Glycolipids Specific to Dauer Larva in Caenorhabditis elegans	Penkov	2010
Caenorhabditis elegans diet significantly affected metabolic profile, mitochondrial DNA levels, lifespan and brood size	Reinke	2010
Fluorodeoxyuridine affects the identification of metabolic responses to DAF-2 status in Caenorhabditis elegans	Davies	2011
Cross-Platform Comparison of Caenorhabditis elegans Tissue Extraction Strategies for Comprehensive Metabolome Coverage	Geier	2011
Potential New Method of Mixture Effected Testing Using Metabolomics and Caenorhabditis elegans	Jones	2011
N-Acylethanolamine signalling mediates the effect of diet on lifespan in Caenorhabditis elegans	Lucanic	2011
Metabotyping of Caenorhabditis elegans and their Culture Media Revealed Unique Metabolic Phenotypes Associated to Amino Acid Deficiency and Insulin-Like Signaling	Martin	2011
1H NMR-based metabolic profiling reveals inherent biological variation in yeast and nematode model systems	Szeto	2011
Metabotyping of the C. elegans sir-2.1 Mutant Using in Vivo Labeling and 13C-Heteronuclear Multidimenisional NMR Metabolomics	An	2012
Profiling the Anaerobic Response of C. elegans Using GC-MS	Butler	2012
A metabolomic strategy defines the regulation of lipid content and global metabolism by delta9 desaturases in Caenorhabditis elegans	Castro	2012
2D NMR-based Metabolomics Uncovers Interactions between Conserved Biochemical Pathways in the Model Organism Caenorhabditis elegans	Izrayelit	2012
Targeted Metabolomics Reveals a Male Pheromone and Sex-Specific Ascaroside Biosynthesis in Caenorhabditis elegans	Izrayelit	2012
Excessive folate synthesis limits lifespan in the C. elegans:E. coli aging model	Virk	2012
Comparative Metabolomics Reveals Biogenesis of Ascarosides, a Modular Library of Small-Molecule Signal in C. elegans	von Reuss	2012
A Core Metabolic Enzyme Mediates Resistance to Phosphine Gas	Schlipalius	2012
A metabolic signature for long life in the Caenorhabditis elegans Mit mutants	Butler	2013
A study of Caenorhabditis elegans DAF-2 mutants by metabolomics and differential correlation networks	Castro	2013
Absolute Quantification of a Steroid Hormone that Regulates Development in Caenorhabditis elegans	Li	2013
Functional Loss of Two Ceramide Synthases Elicits Autophagy-Depedent Lifespan Extension in C elegans	Mosbech	2013
Meta-analysis of global metabolomic data identifies metabolites associated with life-span extension	Patti	2013
Isotopic Ratio Outlier Analysis Global Metabolomics of Caenorhabditis elegans	Stupp	2013
Metabolic profiling in Caenorhabditis elegans provides an ubiased approach to investigations of dosage dependent lead toxicity	Sudama	2013
The metabolite alpha-ketoglutarate extends lifespan by inhibiting ATP syntase and TOR	Chin	2014
Comparative Metabolomics Reveals Endogenous Ligands of DAF-12, a Nuclear Hormone Receptor, Regulating C. elegans Development and Lifespan	Mahanti	2014
Systematic Screening for Novel Lipids by Shotgun Lipidomics	Papan	2014
Metabolomics Analysis Uncovers That Dietary Restriction Buffers Metabolic Changes Associated with Aging in Caenorhabditis elegans	Pontoizeau	2014
Chromatographic separation of free dafachronic acid epimers with a novel triazole click quinidine-based chiral stationary phase	Sardella	2014
D-Glucosamine supplementation extends life span of nematodes and of ageing mice	Weimer	2014
Fast separation and quantification of steroid hormones ∆4- and ∆7-dafachronic acid in Caenorhabditis elegans	Witting	2014
Optimizing a Ultrahigh pressure liquid chromatography-Time of Fligth-Mass spectrometry approach using a novel sub-2µm core shell particle for in depth lipidomic profiling of Caenorhabditis elegans	Witting	2014
µHigh Resolution-Magic-Angle Spinning NMR Spectroscopy for Metabolic Phenotyping of Caenorhabditis elegas	Wong	2014
Protection of C. elegans from Anoxia by HYL-2 Ceramide Synthase	Menuz	2009
Metabolomic changes in Caenorhabditis elegans lifespan mutants as evident from GC-EI-MS and GC-APCI-TOF-MS profiling	Jaeger	2014
Metabolic profiling of a transgenic Caenorhabditis elegans Alzheimer model	Assche	2014
DI-ICR-FT-MS-based high-throughput deep metabotyping: a case study of the Caenorhabditis elegans–Pseudomonas aeruginosa infection model	Witting	2014
Sphingolipid metabolism regulates development and lifespan in Caenorhabditis elegans	Cutler	2014
Comparison of proteomic and metabolomic profiles of mutants in the mitochondrial respiratory chain in Caenorhabditis elegans	Morgan	2014
In vivo metabolic flux profiling with stable isotopes discriminates sites and quantifies effects of mitochondrial dysfunction in C. elegans	Schrier Vergano	2014
Activation of a G protein-coupled receptor by ist endogenous ligand triggers teh innate immune response of Caenorhabditis elegans	Zugasti	2014
Lysosomal signaling molecules regulate longevity in Caenorhabditis elegans	Folick	2015
