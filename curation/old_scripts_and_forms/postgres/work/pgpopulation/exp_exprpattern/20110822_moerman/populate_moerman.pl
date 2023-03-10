#!/usr/bin/perl -w

# populate moerman large scale set.
# get pgid from postgres, but exp_name from daniela.  2011 08 22


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %anat;
my $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $anat{$row[1]} = $row[0]; }
$result = $dbh->prepare( "SELECT * FROM obo_syn_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $anat{$row[1]} = $row[0]; }

my %gene;
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gene{$row[1]} = "WBGene$row[0]"; }
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gene{$row[1]} = "WBGene$row[0]"; }
$result = $dbh->prepare( "SELECT * FROM gin_protein" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gene{$row[1]} = "WBGene$row[0]"; }
$gene{"tag-313"} = 'WBGene00022045';
$gene{"tag-246"} = 'WBGene00044072';

my $exprid = '9356';				# set by daniela
my $joinkey = '';
$result = $dbh->prepare( "SELECT * FROM exp_name ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow(); $joinkey = $row[0];

my $infile = 'largescale_moerman.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my (@stuff) = split/\t/, $line;
  foreach (@stuff) { ($_) = &stripJunk($_); }
  my ($gene, $remark, $pattern, $subcell, $operon) = @stuff;
  if ($remark) { if ($remark =~ m/\'/) { $remark =~ s/\'/''/g; } }
  if ($pattern) { if ($pattern =~ m/\'/) { $pattern =~ s/\'/''/g; } }
  if ($operon) { $operon = 'Operon: ' . $operon; if ($operon =~ m/\'/) { $operon =~ s/\'/''/g; } }
  my $exp_paper = '"WBPaper00038444"';
  my $exp_curator = 'WBPerson12028';
  my $exp_nodump = 'NO DUMP';
  my $exp_exprtype = '"Reporter_gene"';
  my $exp_reportergene = 'The Gateway destination vector (pDM#834) was constructed as follows: an 1,878 bp promoter region upstream of T05G5.1 was amplified from wild type (N2) genomic DNA using primers T05G5.1-Fo-Hind, TACTTAAGCTTTTCCTATCTCCG-3 and T05G5.1-Re-XmaI, TCCCCCGGGGCCTGAAGATAAGTGTGAA, and then inserted between the HindIII and XmaI sites of the GFP-encoding vector pPD95.75 (Fire LabVector Kit available at http://www.addgene.org/pgvec1?f=3Dc&cmd=3Dshowcol&colid=3D 1) to generate pDM#823. A second PCR fragment containing the attR sites and the ccdB gene from the pDEST24 destination vector (nucleotides 70=961777; Invitrogen) was amplified and cloned into p#DM823 between the MscI and KpnI cloning sites to generate pDM#834.This plasmid was transformed into the E. coli strain DB3.1 (Invitrogen), which is tolerant for the ccdB selectable marker gene. Entry clones were obtained from the ORFeome project (Open Biosystems) and cloned into the destination vector pDM#834 using the gateway strategy with LR clonase (Invitrogen) to make the pT05G5.1 ::ORF::GFP expression clones.';
  my $exp_subcellloc = '';
  my $exp_gene = '';
  my $exp_pattern = '';
  my $exp_anatomy = '';
  my $exp_remark = '';
  if ($subcell) { $exp_subcellloc = $subcell; }
  if ($gene) {
    if ($gene{$gene}) { $exp_gene = '"' . $gene{$gene} . '"'; }
      else { print "$gene has no match\n"; }
  } # if ($gene)
  if ($remark && $operon) { $exp_remark = $remark . ' | ' . $operon; }
    elsif ($operon) { $exp_remark = $operon; }
    elsif ($remark) { $exp_remark = $remark; }
  if ($pattern) {
    $exp_pattern = $pattern;
    my %bad; my %good;
    my (@pattern) = split/[,:;\|\.]/, $pattern;
    foreach my $pattern (@pattern) { 
      ($pattern) = &stripJunk($pattern);
      next unless $pattern;
      if ($anat{$pattern}) { $good{$anat{$pattern}}++; } else { $bad{$pattern}++; }
    }
    my $bad = join"\t", sort keys %bad ;
    my $good = join"\t", sort keys %good ;
    $exp_anatomy = join'","', sort keys %good ; $exp_anatomy = '"' . $exp_anatomy . '"';
#     print "$pattern GOOD $good BAD $bad\n"; 
  } # if ($pattern)
  next unless $exp_gene;
  $joinkey++;
  $exprid++;
  &addToPg($joinkey, "Expr$exprid", 'exp_name');
  if ($exp_paper) { &addToPg($joinkey, $exp_paper, 'exp_paper'); }
  if ($exp_curator) { &addToPg($joinkey, $exp_curator, 'exp_curator'); }
  if ($exp_nodump) { &addToPg($joinkey, $exp_nodump, 'exp_nodump'); }
  if ($exp_exprtype) { &addToPg($joinkey, $exp_exprtype, 'exp_exprtype'); }
  if ($exp_reportergene) { &addToPg($joinkey, $exp_reportergene, 'exp_reportergene'); }
  if ($exp_subcellloc) { &addToPg($joinkey, $exp_subcellloc, 'exp_subcellloc'); }
  if ($exp_gene) { &addToPg($joinkey, $exp_gene, 'exp_gene'); }
  if ($exp_pattern) { &addToPg($joinkey, $exp_pattern, 'exp_pattern'); }
  if ($exp_anatomy) { &addToPg($joinkey, $exp_anatomy, 'exp_anatomy'); }
  if ($exp_remark) { &addToPg($joinkey, $exp_remark, 'exp_remark'); }
#   print "\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot open $infile : $!";

sub addToPg {
  my ($joinkey, $data, $table) = @_;
  my @pgcommands;
  push @pgcommands, "INSERT INTO $table VALUES ('$joinkey', '$data')";
  push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$joinkey', '$data')";
  foreach my $pgcommand (@pgcommands) {
    print "$pgcommand\n";
#     $dbh->do( $pgcommand );		# uncomment to populate
  } # foreach my $pgcommand (@pgcommands)
} # sub addToPg

sub stripJunk {
  my ($stuff) = @_;
  if ($stuff =~ m/^\"/) { $stuff =~ s/^\"//; } 
  if ($stuff =~ m/\"$/) { $stuff =~ s/\"$//; } 
  if ($stuff =~ m/^\s+/) { $stuff =~ s/^\s+// } 
  if ($stuff =~ m/\s+$/) { $stuff =~ s/\s+$//; } 
  return $stuff;
}

__END__

DELETE FROM exp_name_hst WHERE exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_paper_hst WHERE exp_timestamp > '2011-08-23 15:00'; 
DELETE FROM exp_curator_hst WHERE exp_timestamp > '2011-08-23 15:00';RE 
DELETE FROM exp_nodump_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_exprtype_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_reportergene_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_subcellloc_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_gene_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_pattern_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_anatomy_hst WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_remark_hst WHERE  exp_timestamp > '2011-08-23 15:00';

DELETE FROM exp_name WHERE exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_paper WHERE exp_timestamp > '2011-08-23 15:00'; 
DELETE FROM exp_curator WHERE exp_timestamp > '2011-08-23 15:00';RE 
DELETE FROM exp_nodump WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_exprtype WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_reportergene WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_subcellloc WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_gene WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_pattern WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_anatomy WHERE  exp_timestamp > '2011-08-23 15:00';
DELETE FROM exp_remark WHERE  exp_timestamp > '2011-08-23 15:00';


Gene	Remark	 Pattern	 Subcellular Localization	Operon
B0303.2	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies	Larval Expression: pharynx; intestine; body wall muscle; | Adult Expression: pharynx; Reproductive System; uterine muscle; vulval muscle; body wall muscle;		
C04F12.8	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies			
tmd-2	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies			
mlc-3	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies	Larval Expression: pharynx; anal depressor muscle; body wall muscle; | Adult Expression: pharynx; anal depressor muscle; vulval muscle; body wall muscle;		
F15G9.1	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies	"Post-embryonic expression.  All cells in larvae through L4, with higher levels in muscle and hypodermis.  Little signal in adults."		
cpn-3	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies	"Strong vul, bwm, anal, mu int, sphincter, head neurons."		
R31.2	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies			CEOP5541
tni-3	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies	"The tni-2 and tni-3 genes were also expressed in the same cells of body wall, vulval and anal muscles, but while tni-2 was uniformly expressed in body wall muscles, the tni-3 gene was strongly expressed in the head, vulval and anal muscles. Expression of tni-2::gfp was observed in the vulval and anal muscles in addition to those muscles detected with tni-2::lacZ. This was the result of the inclusion of a longer 5' upstream region of tni-2 that includes the NdE-box enhancer for vulval expression."		
tpi-1	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies			CEOP2588
ZC395.10	Sub-cellular localization within the body wall muscle: Myofilaments +/- Dense bodies	Larval Expression: pharynx; body wall muscle; Nervous System; ventral nerve cord; head neurons; tail neurons; | Adult Expression: pharynx; Reproductive System; vulval muscle; body wall muscle; Nervous System; ventral nerve cord; head neurons; tail neurons;		CEOP3276
eva-1	"Sub-cellular localization within the body wall muscle: Dense bodies, M-lines, Cell-cell attachment sites"	"EVA-1::GFP expression was observed along the VNC, body wall muscles, Also expressed in pharyngeal muscles and hypodermis."	Exclusively localized on or near the cell surface membrane.	
tag-163	"Sub-cellular localization within the body wall muscle: Dense bodies, M-lines, Cell-cell attachment sites"	Larval Expression: anal depressor muscle; body wall muscle; | Adult Expression: stomato-intestinal muscle; anal depressor muscle; Reproductive System; vulval muscle; body wall muscle;		
tag-303	"Sub-cellular localization within the body wall muscle: Dense bodies, Cell-cell attachment sites"			
F42H10.3	"Sub-cellular localization within the body wall muscle: Dense bodies, Cell-cell attachment sites"			
gei-15	"Sub-cellular localization within the body wall muscle: Dense bodies, Cell-cell attachment sites"			
Y71H2AM.15	"Sub-cellular localization within the body wall muscle: Dense bodies, Cell-cell attachment sites"			
cutc-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cell-cell attachment sites"			CEOP3520
har-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Larval Expression: pharynx; anal depressor muscle; body wall muscle; Nervous System; head neurons; tail neurons; | Adult Expression: pharynx; anal depressor muscle; body wall muscle; Nervous System; head neurons; tail neurons;		CEOP3152
C17G1.7	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
C40H1.6	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	"4 neural nuclei stain L1-adult. One just posterior to the proximal bulb of the pharynx, one just anterior to it (these 2 very strong signal) and a symmetrical pair slightly more anterior again (not nearly as strong as others).-maybe members of head sensilla? | Two strongly staining nuclei in the main body of neuropil, and a faintly staining pair symmetrically positioned anterior to the metacorpus of the pharynx (though not inside that organ) show expression from early larval stages onwards. This symmetrical pattern, plus the small size of the stained nuclei, suggests the identity of these two cells to be socket or sheath cells of the IL group of sensilla."		
C47B2.2	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP1680
C55A6.10	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP5288
D1007.4	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP1184
D2063.1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
D2063.3	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP5052
F22B5.10	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP2348
F22F7.7	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
F25H2.4	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
F25H2.12	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP1624
F26A3.4	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Expressed in neuronal and metabolic tissues.		
pkn-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Larval Expression: pharynx; intestine; Nervous System; ventral nerve cord; head neurons; | Adult Expression: pharynx; intestine; Nervous System; ventral nerve cord; head neurons;		
mom-4	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
gyg-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Larval Expression: pharynx; body wall muscle; | Adult Expression: pharynx; Reproductive System; vulval muscle; body wall muscle;		
ltd-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	"The LTD-1::GFP signal is present throughout the development of C. elegans. This signal was detected as early as the 2-fold embryo. The ltd-1 reporter is also expressed throughout the seam cell division process. Its expression is observed in the seam cells of the early embryo and in the larval stages once these cells have commenced division. The LTD-1::GFP signal is also observed in rectal epithelial cells (tentatively, U and Y cells) and in the terminal bulb (marginal cells) and isthmus of the pharynx from hatching to adulthood."	"The LTD-1::GFP construct is expressed in the apical regions of the dorsal and ventral hypodermis in very tightly organized circumferential filament bundles. This cytoskeletal expression pattern mirrors the intracellular distribution of actin and tubulin in C. elegans. In late embryos, the GFP signal is localized to the apical junction between hyp 5, hyp 6 and hyp 7 and between the seam cells and the P blast cells in the ventral midline. This signal highlights the cell fusion processes that take place during post-embryonic development. The ltd-1 reporter is also expressed throughout the seam cell division process. It clearly outlines the cytokinesis between posterior mother cells and anterior daughter cells and illustrates the subsequent fusion of the anterior daughter cells to the hypodermal syncitium. The GFP signal is also observed in longitudinal filaments within the cytoplasm linking both extremities of the elongating seam cells and in the alae formed by their fusion."	
smg-8	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
T01G9.2	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP1456
mlp-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Larval Expression: intestine; rectal gland cells; body wall muscle; Nervous System; head neurons; tail neurons; | Adult Expression: intestine; rectal gland cells; Reproductive System; vulval muscle; spermatheca; body wall muscle; hypodermis; Nervous System; head neurons; neurons along body; tail neurons;		
rsbp-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	"GFP::RSBP-1 was expressed throughout the C. elegans nervous system and in many muscles. Expression of GFP::RSBP-1 was observed in neuronal cell bodies in the head, in the bundle of neuronal processes that form the nerve ring and in the neurons and muscles of the pharynx; in neuronal cell bodies and the anal depressor muscle in the tail; in the cell bodies and processes of the ventral nerve cord and in body wall muscles, which are required for locomotion; in the hermaphrodite specific neuron (HSN) and the vulval and uterine muscles that are required for egg laying; as well as in lateral neurons, the dorsal nerve cord, commissural nerve processes and additional muscles and support cells in the head."		
hsp-12.1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
W03C9.2	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
W05G11.6	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
hgo-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Larval Expression: pharynx; intestine; hypodermis; | Adult Expression: intestine; hypodermis;		CEOP1524
arx-5	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"		"Enrichment of ARX-5 was found near plasma membranes. This pattern was seen at gastrulation and earlier, and it was eliminated using RNAi targeting arx-5. At the time of Ea/p cell internalization, ARX-5 was also present at sites where MS granddaughter cells contact Ea at the apical surfaces of the cells. Diffuse cytoplasmic and P-granule staining was also seen, but RNAi targeting arx-5 eliminated only the cortical signal, suggesting that the cytoplasmic and P-granule staining were primarily non-specific background. Thus, Arp2/3 is enriched at the cell cortex at gastrulation and earlier."	
Y39A1C.1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	Larval Expression: anal depressor muscle; body wall muscle; Nervous System; head neurons; | Adult Expression: anal depressor muscle; Reproductive System; vulval muscle; body wall muscle; Nervous System; head neurons;		CEOP3704
Y43F8B.2	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
Y45G5AM.6	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
Y48G10A.3	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			
ZK637.2	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"			CEOP3552
ZK643.1	"Sub-cellular localization within the body wall muscle: Dense bodies, Cytoplasm, +/- Nucleus"	"Expression is seen in 4 neural cells of the anterior ganglion, 8 more in the lateral/ventral ganglia, and 4-6 nuclei of the tail ganglia. Staining is also seen on sub-cellular particles in the vm1 muscles of the vulva. The neural pattern develops from L1 onwards; the vulval staining occurs L4 onwards."	Expressed in nuclei.	
B0412.3	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			CEOP3036
C29F5.1	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	"The reporter construct was observed in body wall, vulval, and anal but not pharyngeal muscle in all stages."		
ptp-1	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			
ccch-1	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	Larval Expression: pharynx; body wall muscle; | Adult Expression: pharynx; Reproductive System; vulval muscle; body wall muscle;		
F44A2.5	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	Diffuse expression is seen in the anterior pharynx (procorpus and metacorpus) from the 3-fold embryo stage until adulthood. Occasionally more general staining throughout the pharynx is seen.		
F57C2.5	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			
K01A2.3	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	Intestine		
K07F5.15	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			CEOP4340
K08C7.6	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			
R151.10	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			CEOP3424
T03G6.3	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	Larval Expression: body wall muscle; | Adult Expression: body wall muscle;		
ndx-1	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	strong pan neuronal; spermatheca; faint vulval mu; rare and faint bwm in adult; neuronal starts at bean with strong at 3-fold.		
W01A11.2	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	Larval Expression: Nervous System; head neurons; amphids; tail neurons; phasmids; | Adult Expression: Nervous System; head neurons; amphids; tail neurons; phasmids;		CEOP5118
Y37D8A.10	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			
oig-2	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	"Expressed in ventral nerve cord from L2 to adult, anterior neurons (not individually identified in this study) from L2 to adult, posterior neurons from L2 to adult, pharynx from L2 to adult, mid body cell bodies from L2 to adult, specific pair of head neurons from L2 to adult, posterior cells (not individually identified in this study) from L2 to adult in some animals, main body hypodermis in some L2/L3 animals."		CEOP2670
Y54E5A.5	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			CEOP1748
Y57G7A.10	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like	Larval Expression: intestine; rectal gland cells; | Adult Expression: intestine; rectal gland cells;		CEOP2044
Y106G6A.1	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			CEOP1568
ZK54.1	Sub-cellular localization within the body wall muscle: Sarcoplasmic reticulum (SR)-like			
C04G6.4	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"			CEOP2160
bre-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	Larval Expression: body wall muscle; Nervous System; head neurons; | Adult Expression: body wall muscle; Nervous System; head neurons; unidentified cells;		
ttll-12	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	Larval Expression: intestine; rectal gland cells; | Adult Expression: intestine; rectal gland cells;		CEOP2424
cnb-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	"The expression pattern of the predicted calcineurin B was similar to the pattern of tax-6::gfp in pAK43. See Expr1824: pAK43 drove TAX-6 expression in many sensory neurons, as well as interneurons including AIY and AIZ, and most, if not all, muscle cells."	"Scattered and distinct cytoplasmic signals of CNB-1 was observed surrounding the cellularized spermatids. | Wildtype male sperm was examined and immunostained with antiCNB-1 antibody. As expected, robust staining was observed in the wild-type sperm and the staining was distinctly cytoplasmic."	
pfd-2	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"			CEOP2124
K08E3.5	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	Larval Expression: intestine; body wall muscle; hypodermis; | Adult Expression: intestine; body wall muscle;		
M02D8.1	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"			
R102.5	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"			CEOP4392
aldo-1	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	Larval Expression: stomato-intestinal muscle; anal depressor muscle; Reproductive System; developing vulva; body wall muscle; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; lateral nerve cords; head neurons; neurons along body; tail neurons; | Adult Expression: stomato-intestinal muscle; anal depressor muscle; Reproductive System; vulval muscle; spermatheca uterine valve; body wall muscle; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; lateral nerve cords; head neurons; neurons along body; tail neurons;		
T12D8.8	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	Larval Expression: intestine; hypodermis; unidentified cells in head; unidentified cells in tail ; | Adult Expression: intestine; unidentified cells in head;		
set-18	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	"Strong pharyngeal, vulval, bwm, anal dep, mu int; 3-fold earliest embryonic."		
W03F9.1	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"			CEOP5004
Y57G11C.3	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"			CEOP4667
pyk-2	"Sub-cellular localization within the body wall muscle: Dense bodies, Thick filaments and/or M-line, SR/ER"	Larval Expression: intestine; | Adult Expression: intestine;		
C05D9.3	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
C05G5.1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"Expression is seen in the ventral cord, nerve ring and nerves in the head and tail. Expression appears to be restricted to the adult and L4 stage nematodes. Some irregular gut expression is also seen."		
C24A3.2	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
otub-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"Pan-neuronal: enriched in embryo (1.9); expressed in larva. | A-class motor neuron: enriched in embryo (2.9); not expressed in larva. | Neuronal expression include: Weak in head and tail neurons, ventral cord. Also expressed in other cells: Pharynx, sheath cells, distal tip cell."		CEOP5440
glb-10	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"Neuronal expression: cholinergic & GABAergic motor neurons, head, tail & body. | Non-neuronal expression: pharynx, intestine, vulval muscle."	"Synaptic expression, co-localized with SNB-1::RFP."	
nlg-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"nlg-1 is expressed in a subset of neurons in C. elegans adults, including ~20 cells in the ventral nerve cord and ~20 cells in the head (Fig. 3). The nlg-1-expressing cells in the ventral nerve cord were identified as the cholinergic VA and DA motor neurons. Authors also identified the two AIY and two URB interneurons and the four URA motor neurons in the head, and the two PVD mechanosensory and two HSN motor neurons in the body, as nlg-1-expressing cells. Finally, faint Pnlg-1::YFP expression was also observed in body wall muscles."	"Bright punctate staining was observed in dendritic (postsynaptic) regions. Clear punctate staining was also observed in presynaptic regions of each neuronal type. For example, in the DA9 motor neuron, bright NLG-1::YFP puncta were present in the ventral postsynaptic domain, and dimmer puncta were present in the dorsal presynaptic region. Puncta were excluded from the synapse-poor region between the cell body and dorsal presynaptic region and from the anterior asynaptic region of the dorsal process. To further study the punctate staining in the presynaptic region, NLG-1::YFP localization was examined in animals expressing the tagged synaptic vesicle protein mCherry::RAB-3 in DA9. In the dorsal axon, NLG-1::YFP puncta partially colocalized with puncta containing mCherry::RAB-3, suggesting that NLG-1::YFP localization is perisynaptic."	
rab-8	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
F14B6.2	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
twk-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	hypoderm		
ehbp-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
F29B9.8	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
lec-2	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
K04G2.9	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
crml-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"Animals bearing the transcriptional and translational reporters had similar GFP expression patterns. L1 animals carrying the translation reporter expressed GFP in many neurons, including CANs, DD-type motoneurons and ALMs. Expression in the nervous system began early in comma-stage embryos and peaked in intensity around the 3-fold stage of embryogenesis. Although neuronal expression was much fainter at later larval stages, it persisted in some head and tail neurons through adulthood. Non-neuronal cells that also expressed CRML-1::GFP included the migrating distal tip cells, the pharynx, some vulval epithelial cells, rectal epithelial cells and the excretory canal"		CEOP1368
M02B1.3	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
R07E5.7	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	Larval Expression: pharynx; intestine; anal depressor muscle; rectal epithelium; Reproductive System; distal tip cell; body wall muscle; hypodermis; excretory cell; unidentified cells; | Adult Expression: pharynx; anal depressor muscle; rectal epithelium; Reproductive System; distal tip cell; vulval muscle; spermatheca; body wall muscle; hypodermis; excretory cell; unidentified cells;		CEOP3188
R10E4.9	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			CEOP3168
T10C6.6	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			CEOP5452
lgc-34	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	Larval Expression: stomato-intestinal muscle; body wall muscle; unidentified cells in head; | Adult Expression: Reproductive System; vulval muscle; body wall muscle; unidentified cells in head;		
W06A7.2	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
Y9C2UA.1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
Y15E3A.4	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
Y48C3A.16	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"Expression is seen in all larval stages and adults, predominantly in intestinal cells. However, expression in other cells in the head and tail (presumably neurons), and expression in the pharynx and hypodermis is also seen, particularly in young larvae. This gene is the orthologue of human PIN4 (peptidyl-prolyl cis/trans isomerase (NIMA-interacting), 4 parvulin)."		CEOP2606
Y55F3C.3	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
Y57A10A.16	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			CEOP2688
yop-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	Larval Expression: pharynx; rectal gland cells; anal depressor muscle; body wall muscle; excretory cell; Nervous System; nerve ring; ventral nerve cord; head neurons; neurons along body; tail neurons; unidentified cells in head; unidentified cells in tail ; | Adult Expression: pharynx; rectal gland cells; anal depressor muscle; Reproductive System; uterine muscle; vulval muscle; spermatheca; body wall muscle; excretory cell; Nervous System; nerve ring; ventral nerve cord; head neurons; neurons along body; tail neurons;		CEOP1056
clc-3	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
tag-256	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	Larval Expression: rectal epithelium; Reproductive System; distal tip cell; developing vulva; hypodermis; excretory cell; Nervous System; nerve ring; head neurons; neurons along body; tail neurons; | Adult Expression: Reproductive System; vulva other; excretory cell; Nervous System; nerve ring; head neurons; tail neurons;		CEOP3552
lec-3	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms			
shk-1	Sub-cellular localization within the body wall muscle: Muscle cell membrane +/- Muscle arms	"The SHK-1::GFP fusion protein was expressed in a variety of interneurons and sensory neurons, as well as body wall muscle."		
K01G5.8	Sub-cellular localization within the body wall muscle: Nucleolus			CEOP3700
W04C9.4	Sub-cellular localization within the body wall muscle: Nucleolus			CEOP1008
W09C5.1	Sub-cellular localization within the body wall muscle: Nucleolus	Larval Expression: pharynx; intestine; Reproductive System; developing vulva; body wall muscle; hypodermis; seam cells; excretory cell; Nervous System; nerve ring; ventral nerve cord; head neurons; | Adult Expression: pharynx; Reproductive System; spermatheca; gonad sheath cells; body wall muscle; excretory cell; Nervous System; nerve ring; ventral nerve cord; head neurons;		CEOP1712
Y39B6A.33	Sub-cellular localization within the body wall muscle: Nucleolus			CEOP5480
Y40B1B.7	Sub-cellular localization within the body wall muscle: Nucleolus	Larval Expression: pharynx; anal depressor muscle; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons; | Adult Expression: pharynx; anal depressor muscle; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons;		
Y52B11A.9	Sub-cellular localization within the body wall muscle: Nucleolus	Expression is observed in all tissue except the germ line from the 100 cell embryo onward.		
Y54G11A.11	Sub-cellular localization within the body wall muscle: Nucleolus			
ZK265.6	Sub-cellular localization within the body wall muscle: Nucleolus			
B0024.10	Sub-cellular localization within the body wall muscle: Nucleus only	"Expression is predominantly in adult stages, but similar staining is seen in all larval stages. Expression is seen in intestinal nuclei, the pharynx (muscle and epithelial cells), and other cells in the head and tail (probably hypodermis). | Expression is seen in the muscle and epithelial cells of the pharynx. | Expression is seen in the intestinal nuclei. | Expression is seen in cells in the head and tail (probably hypodermis)."		CEOP5252
flh-2	Sub-cellular localization within the body wall muscle: Nucleus only	Expression was detected in embryos and reduced significantly after hatching.		
D2030.3	Sub-cellular localization within the body wall muscle: Nucleus only			CEOP1404
F13B12.1	Sub-cellular localization within the body wall muscle: Nucleus only	Larval Expression: pharynx; intestine; body wall muscle; hypodermis; excretory cell; Nervous System; neurons along body; unidentified cells in tail ; | Adult Expression: pharynx; intestine; vulval muscle; body wall muscle; hypodermis; excretory cell; Nervous System; neurons along body; unidentified cells in tail ;		
F25B3.6	Sub-cellular localization within the body wall muscle: Nucleus only	Larval Expression: pharynx; pharyngeal-intestinal valve; intestine; anal depressor muscle; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons; neurons along body; tail neurons; | Adult Expression: pharynx; intestine; anal depressor muscle; Reproductive System; vulval muscle; body wall muscle;		
psf-1	Sub-cellular localization within the body wall muscle: Nucleus only	Adult Expression: Reproductive System; vulval muscle; spermatheca; body wall muscle;		
tdp-1	Sub-cellular localization within the body wall muscle: Nucleus only			
tag-304	Sub-cellular localization within the body wall muscle: Nucleus only	Larval Expression: pharynx; body wall muscle; seam cells; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; head neurons; tail neurons; | Adult Expression: pharynx; Reproductive System; vulval muscle; body wall muscle; seam cells; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; head neurons; tail neurons;		
rnf-113	Sub-cellular localization within the body wall muscle: Nucleus only	"From late embryo to adult, expression is seen in the ventral nerve cord, and several other neurons in the head and tail."		CEOP3701
nhr-49	Sub-cellular localization within the body wall muscle: Nucleus only			CEOP1566
pqn-53	Sub-cellular localization within the body wall muscle: Nucleus only			CEOP5320
etr-1	Sub-cellular localization within the body wall muscle: Nucleus only	"Transgenic animals expressed this reporter specifically in muscle. Strong expression was observed in muscle cells in embryos. Adult expression was seen in striated body-wall muscle along the length of the animal, especially in the head. Strong expression was also seen in the vulval muscles. Additional expression was observed in intestinal muscle, anal sphincter muscle and the sex-specific muscles of the male tail. No expression was observed in pharyngeal muscle."		
T10C6.5	Sub-cellular localization within the body wall muscle: Nucleus only	Larval Expression: pharynx; body wall muscle; excretory cell; Nervous System; ventral nerve cord; head neurons; | Adult Expression: pharynx; stomato-intestinal muscle; Reproductive System; vulval muscle; gonad sheath cells; body wall muscle; Nervous System; head neurons;		CEOP5452
T11G6.8	Sub-cellular localization within the body wall muscle: Nucleus only			CEOP4396
zfp-3	Sub-cellular localization within the body wall muscle: Nucleus only			CEOPX016
tag-246	Sub-cellular localization within the body wall muscle: Nucleus only	Larval Expression: pharynx; intestine; Reproductive System; developing vulva; body wall muscle; hypodermis; excretory cell; Nervous System; nerve ring; ventral nerve cord; head neurons; neurons along body; tail neurons; | Adult Expression: pharynx; intestine; Reproductive System; vulval muscle; vulva other; spermatheca; body wall muscle; hypodermis; excretory cell; Nervous System; nerve ring; ventral nerve cord; head neurons; neurons along body; tail neurons;		CEOP3657
ZK1236.7	Sub-cellular localization within the body wall muscle: Nucleus only			CEOP3524
dnc-2	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other	Larval Expression: unidentified cells in body ;unidentified cells in tail ; | Adult Expression: pharynx; unidentified cells in body ;unidentified cells in tail ;	"When examined at the four-cell stage during P2 and EMS spindle rotation, DNC-1::GFP, DNC-2::GFP and ARP-1::GFP were all enriched at the cell border between P2 and EMS prior to and during EMS and P2 spindle rotation. The accumulation first appeared at 8.88+/-0.63 minutes after the first appearance of the cleavage furrow in P1 (n=5, measured with DNC-2::GFP embryos) and remained there for 6.8+/-0.7 minutes (n=5). Dynactin-labeled EMS and P2 centrosomes rotated and moved such that one centrosome from each spindle became closely apposed to the accumulation site.Authors also observed instances of dynactin-labeled putative microtubule (MT) plus-ends emanating from one centrosome and terminating at this accumulation site. The accumulation was then observed to disappear about 4.77+/-0.78 minutes (n=5) before EMS cleaved. | This dynamic dynactin accumulation was confirmed by immunofluorescence staining with anti-DNC-1 antibody."	
lgg-1	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other	Larval Expression: pharynx; intestine; body wall muscle; seam cells; Nervous System; nerve ring; ventral nerve cord; neurons along body; tail neurons; | Adult Expression: pharynx; intestine; body wall muscle; seam cells; Nervous System; nerve ring; ventral nerve cord; neurons along body; tail neurons;	"In non-dauser stages, GFP::LGG-1 had diffuse cytoplasmic GFP expression. During dauer formation, a marked change was observed in the subcellular localization pattern of GFP::LGG-1 in hypodermal seam cells."	CEOP2240
uba-1	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other	"Expressed in anterior neurons (not individually identified in this study) from L2 to adult, pharynx from L2 to adult, mid body cell bodies at L4, head hypodermal cells/muscle at adult stage."		CEOP4344
C53B4.3	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
dpf-4	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other	Expression is seen in a few unidentified cells in early and late stage embryos.		CEOP3340
F08B12.4	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
F22D6.2	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other	Larval Expression: pharynx; intestine; body wall muscle; seam cells; Nervous System; nerve ring; ventral nerve cord; head neurons; tail neurons; | Adult Expression: pharynx; intestine; Reproductive System; vulval muscle; body wall muscle; seam cells; Nervous System; nerve ring; ventral nerve cord; head neurons; tail neurons;		CEOP1364
F25H8.2	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
dph-3	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
T01C3.2	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
kin-10	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other		"In pkd-2 expressing cells, KIN-10::GFP was enriched in cilia and also found in cell bodies (including nuclei), dendrites, and axons."	CEOP1456
T20D3.8	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			CEOP4328
ttr-6	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
dnj-24	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
Y43F4B.5	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			CEOP3776
Y73B6BL.21	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
gur-3	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			
tag-143	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			CEOP5248
ZK856.11	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			CEOP5248
ZK1098.1	Sub-cellular localization within the body wall muscle: Nucleus and Cytoplasm/Other			CEOP3596
B0035.15	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP4428
tag-321	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP4252
pqn-24	Sub-cellular localization within the body wall muscle: Mitochondria	"faint to moderate head bwm, no other GFP seen, no embryonic"		
mce-1	Sub-cellular localization within the body wall muscle: Mitochondria	D2030.5 shows expression in the intestine as well as other tissues.	"The subcellular distribution clearly shows that it is not distributed evenly in the tissues, but has a distinct dotted appearance, consistent with mitochondrial localization (Fig. 8B,E). The GFP-signal obtained was highly similar to the staining of MitoTracker Red, which specifically labels mitochondria."	
alh-8	Sub-cellular localization within the body wall muscle: Mitochondria			
tag-299	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: body wall muscle; Nervous System; tail neurons; | Adult Expression: body wall muscle; Nervous System; tail neurons;		CEOPX130
mdh-1	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: pharynx; intestine; body wall muscle; | Adult Expression: pharynx; intestine; body wall muscle;		
F21C10.10	Sub-cellular localization within the body wall muscle: Mitochondria			
F45G2.4	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP3788
F53F10.1	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: body wall muscle; | Adult Expression: body wall muscle;		
F54C8.7	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: pharynx; | Adult Expression: pharynx;		CEOP3584
F57B10.14	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP1332
bcat-1	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: pharynx; intestine; Reproductive System; developing spermatheca; gonad sheath cells; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons; tail neurons; | Adult Expression: pharynx; intestine; Reproductive System; spermatheca; gonad sheath cells; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons; tail neurons;		
gta-1	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: body wall muscle; Nervous System; head neurons; | Adult Expression: body wall muscle; Nervous System; head neurons; unidentified cells;		CEOP4360
R07H5.3	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP4424
R119.3	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP1004
T05G5.5	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP3616
T09A5.5	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP2312
T10B11.6	Sub-cellular localization within the body wall muscle: Mitochondria	Larval Expression: intestine; stomato-intestinal muscle; anal depressor muscle; rectal epithelium; Reproductive System; distal tip cell; gonad sheath cells; body wall muscle; head mesodermal cell; coelomocytes; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; lateral nerve cords; head neurons; neurons along body; tail neurons; | Adult Expression: intestine; stomato-intestinal muscle; anal depressor muscle; rectal epithelium; Reproductive System; distal tip cell; uterine muscle; vulval muscle; spermatheca; gonad sheath cells; body wall muscle; head mesodermal cell; coelomocytes; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; lateral nerve cords; head neurons; neurons along body; tail neurons;		CEOP1360
T15B12.1	Sub-cellular localization within the body wall muscle: Mitochondria			
Y43E12A.2	Sub-cellular localization within the body wall muscle: Mitochondria			
Y53G8AR.8	Sub-cellular localization within the body wall muscle: Mitochondria			
tag-313	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP4028
Y67H2A.5	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP4538
mtx-2	Sub-cellular localization within the body wall muscle: Mitochondria			CEOP3448
srp-1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: arcade cells; body wall muscle; | Adult Expression: body wall muscle;		
C35E7.8	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			
C47D12.2	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	No expression		
D2024.5	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			CEOP4216
F01G4.5	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			CEOP4416
F02E9.1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			
cup-2	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	"Fusion of GFP to the CUP-2 promoter resulted in ubiquitous expression of GFP in all tissues, including coelomocytes."		
tct-1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	"Transcription of the control gene Ce-tbb-1 was consistent among the different life stages of C. elegans. No Ce-tct-1 transcripts could be detected in the L1, L2 and L3 stages. Transcription of Ce-tct-1 appeared to be initiated in the L4 stage (240 bp band) whilst the highest level of transcription was found in the adult hermaphrodite."		CEOP1624
cey-1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	"At 1 through 30-cell stage, maintained in germ line, lost from somatic cells.  At 30-cell stage, staining was in 2 then 4 posterior cells.  Staining was ubiquitous at 100 through 550-cell stage.  Staining was seen in muscle and other tissues at bean through pretzel stages."		
F36F2.1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: pharynx; | Adult Expression: pharynx;		
F48E3.8	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			
glb-18	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	"Several globin genes (C06E4.7, C09H10.8, C36E8.2, C52A11.2, F52A8.4, R01E6.6, R13A1.8, R90.5, and W01C9.5) are similarly upregulated in L3 and dauers relative to young adults, although some reach significance in dauers only. Many genes exhibited more than 2- fold upregulation but didn't reach statistical significance because strong upregulation was only seen in 2 biological replicates, A significant downregulation in L3 stage relative to young adults was observed for C26C6.7, T22C1.2 and ZK637.13. A similar trend was seen in dauers. C26C6.7 was the only globin which exressed at a significantly higher level in dauers relative to L3. Quantitative real-time RT-PCR experiments were done to compare the relative bundance of all 33 globins in wild type adults. Results demonstrate T22C1.2 and ZK637.13 are expressed at substantially higher levels. The difference with the other globins ranges within 1-3 orders of magnitude."		
calu-1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: pharynx; body wall muscle; hypodermis; | Adult Expression: pharynx; body wall muscle; hypodermis;		
M05D6.5	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			CEOP2352
M176.4	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: arcade cells; intestine; | Adult Expression: intestine;		CEOP2426
R04F11.5	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: pharynx; pharyngeal-intestinal valve; anal depressor muscle; Reproductive System; developing gonad; developing vulva; developing spermatheca; body wall muscle; Nervous System; head neurons; | Adult Expression: pharynx; pharyngeal-intestinal valve; anal depressor muscle; Reproductive System; spermatheca; body wall muscle; Nervous System; head neurons;		CEOP5344
T10B10.4	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			
T22C1.6	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: pharynx; anal depressor muscle; body wall muscle; unidentified cells in head; unidentified cells in tail ; | Adult Expression: pharynx; anal depressor muscle; Reproductive System; vulval muscle; body wall muscle; unidentified cells in head; unidentified cells in tail ;		CEOP1436
W04A8.4	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			
tag-210	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: intestine; anal depressor muscle; hypodermis; | Adult Expression: intestine; anal depressor muscle; hypodermis;		CEOP1692
Y105E8A.3	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other			
prmt-1	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: pharynx; intestine; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons; tail neurons; | Adult Expression: pharynx; intestine; Reproductive System; vulval muscle; body wall muscle; hypodermis; Nervous System; nerve ring; ventral nerve cord; head neurons; tail neurons;		CEOP5508
cth-2	Sub-cellular localization within the body wall muscle: Endoplasmic reticulum (ER) +/- Other	Larval Expression: anal depressor muscle; body wall muscle; hypodermis; | Adult Expression: anal depressor muscle; Reproductive System; vulval muscle; body wall muscle; hypodermis;		
B0001.6	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			
ikb-1	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			
pfd-1	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	Larval Expression: pharynx; intestine; body wall muscle; | Adult Expression: pharynx; intestine; body wall muscle; excretory cell;		CEOP4420
C49H3.6	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	Larval Expression: pharynx; intestine; stomato-intestinal muscle; anal depressor muscle; body wall muscle; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; head neurons; neurons along body; tail neurons; unidentified cells; | Adult Expression: pharynx; stomato-intestinal muscle; anal depressor muscle; Reproductive System; vulval muscle; body wall muscle; Nervous System; ventral nerve cord; dorsal nerve cord; head neurons; neurons along body; tail neurons; unidentified cells;		
F02A9.4	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	"Expression is evident in both the metacorpus and terminal bulb of the adult pharynx. B-gal staining seems to be sub-cellularly localised in the pseudocircular m4 muscle cells in the metacorpus; staining in the terminal bulb is restricted to the posterior of the bulb, and so may mark the location of the m7 muscles."		
F37H8.5	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	Larval Expression: intestine; | Adult Expression: intestine; Reproductive System; vulval muscle; Nervous System; nerve ring; ventral nerve cord; dorsal nerve cord; lateral nerve cords; head neurons; neurons along body; tail neurons;		
ptl-1	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	Larval Expression: pharynx; intestine; Nervous System; head neurons; unidentified cells in body ;unidentified cells in tail ; | Adult Expression: pharynx; Reproductive System; vulval muscle; Nervous System; head neurons; tail neurons; unidentified cells in body ;unidentified cells in tail ;		
F46F11.1	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			
F47F2.1	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			
K07H8.1	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			CEOP4280
M01E5.4	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			CEOP1688
M18.3	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			CEOP4492
R151.4	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			
T06A10.3	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			CEOP4668
T20D3.6	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other			CEOP4328
vps-2	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	Larval Expression: pharynx; anal depressor muscle; body wall muscle; unidentified cells in body ;unidentified cells in tail ; | Adult Expression: pharynx; anal depressor muscle; Reproductive System; vulval muscle; body wall muscle; unidentified cells in body ;unidentified cells in tail ;		
Y54E10BR.4	Sub-cellular localization within the body wall muscle: Cytoplasm +/- Other	Expressed in neuronal and metabolic tissues.		CEOP1080
D2092.4	Sub-cellular localization within the body wall muscle: Unique and Undetermined			
F42C5.9	Sub-cellular localization within the body wall muscle: Unique and Undetermined			
gsnl-1	Sub-cellular localization within the body wall muscle: Unique and Undetermined	"Neuronal expression: none. | Non-neuronal expression: body wall muscle, hypodermis."	"Synaptic expression, co-localized with SNB-1::RFP."	
R11G1.6	Sub-cellular localization within the body wall muscle: Unique and Undetermined			
