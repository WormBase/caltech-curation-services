#!/usr/bin/perl -w

# print out all afp_ field names from author first pass (if there's data), and then the cur_ tables from curators if there's data for the same papers.  2009 02 08

use strict;
use diagnostics;
use Pg;

my %hash;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


&hashName();
my @cats = qw( gif int gef pfs seq cell sil rgn oth );
my @gif = qw( genesymbol mappingdata genefunction newmutant rnai lsrnai );
my @int = qw( geneinteractions geneproduct );
my @gef = qw( expression sequencefeatures generegulation overexpression mosaic site microarray );
my @pfs = qw( invitro covalent structureinformation );
my @seq = qw( structurecorrectionsanger sequencechange massspec );
my @cell = qw( ablationdata cellfunction );
my @sil = qw( phylogenetic othersilico );
my @rgn = qw( chemicals transgene antibody newsnp rgngene );
my @oth = qw( nematode humandiseases supplemental );
$hash{cat}{gif} = [ @gif ];
$hash{cat}{int} = [ @int ];
$hash{cat}{gef} = [ @gef ];
$hash{cat}{pfs} = [ @pfs ];
$hash{cat}{seq} = [ @seq ];
$hash{cat}{cell} = [ @cell ];
$hash{cat}{sil} = [ @sil ];
$hash{cat}{rgn} = [ @rgn ];
$hash{cat}{oth} = [ @oth ];
my @comment = qw( comment );
$hash{cat}{comment} = [ @comment ];

my %joinkeys;
my $result = $conn->exec( "SELECT joinkey FROM afp_passwd;" );
while (my @row = $result->fetchrow) {
  $joinkeys{$row[0]}++;
} # while (my @row = $result->fetchrow)

print "START author first pass\n";
foreach my $joinkey (sort keys %joinkeys) {
  my @data;
  foreach my $cat (@cats) {
    foreach my $table (@{ $hash{cat}{$cat} }) { 
      my ($data) = &getPgData($table, $joinkey);
      if ($data) { push @data, "$table, $hash{name}{$table}"; }
    }
  } # foreach my $cat (@cats)
  if ($data[0]) {
    my $data = join"\t", @data;
    print "$joinkey, $data\n"; } 
} # foreach my $joinkey (sort keys %joinkeys)


my @PGparameters = qw(pubID pdffilename curator reference fullauthorname
                      genesymbol mappingdata genefunction generegulation
                      expression marker microarray rnai lsrnai transgene overexpression 
		      structureinformation functionalcomplementation 
		      invitro mosaic site antibody covalent 
		      extractedallelenew newmutant nonntwo    
                      sequencechange geneinteractions geneproduct                  
                      structurecorrectionsanger structurecorrectionstlouis    
                      sequencefeatures massspec cellname cellfunction 
                      ablationdata newsnp stlouissnp supplemental 
                      chemicals humandiseases comment);        # vals for %theHash

my %theHash;
  $theHash{curator}{html_field_name} = 'Curator &nbsp; &nbsp;(REQUIRED)';
  $theHash{pubID}{html_field_name} = 'General Public ID Number &nbsp; &nbsp;(REQUIRED)';
  $theHash{pdffilename}{html_field_name} = 'PDF file name';
  $theHash{reference}{html_field_name} = 'Reference';
  $theHash{fullauthorname}{html_field_name} = 'Full Author Names (if known)';
  $theHash{genesymbol}{html_field_name} = 'Gene Symbol (main/other/sequence)';
  $theHash{mappingdata}{html_field_name} = 'Mapping Data';
  $theHash{genefunction}{html_field_name} = 'Gene Function';
  $theHash{generegulation}{html_field_name} = 'Gene Regulation on Expression Level';
  $theHash{expression}{html_field_name} = 'Expression Data';
  $theHash{marker}{html_field_name} = 'Marker';
  $theHash{microarray}{html_field_name} = 'Microarray';
  $theHash{rnai}{html_field_name} = 'RNAi';
  $theHash{lsrnai}{html_field_name} = 'Large-Scale RNAi';
  $theHash{transgene}{html_field_name} = 'Transgene';
  $theHash{overexpression}{html_field_name} = 'Overexpression';
  $theHash{structureinformation}{html_field_name} = 'Structure Information';
  $theHash{functionalcomplementation}{html_field_name} = 'Functional Complementation';
  $theHash{invitro}{html_field_name} = 'in vitro Protein Analysis';
  $theHash{mosaic}{html_field_name} = 'Mosaic Analysis';
  $theHash{site}{html_field_name} = 'Site of Action';
  $theHash{antibody}{html_field_name} = 'Extract Antibody';
  $theHash{covalent}{html_field_name} = 'Covalent Modification';
  $theHash{extractedallelenew}{html_field_name} = 'Extract Allele';
  $theHash{newmutant}{html_field_name} = 'Mutant Phenotype';
  $theHash{nonntwo}{html_field_name} = 'Non-N2_phenotype';
  $theHash{sequencechange}{html_field_name} = 'Sequence Change';
  $theHash{geneinteractions}{html_field_name} = 'Gene Interactions';
  $theHash{geneproduct}{html_field_name} = 'Gene Product Interaction';
  $theHash{structurecorrectionsanger}{html_field_name} = 'Sanger Gene Structure Correction';
  $theHash{structurecorrectionstlouis}{html_field_name} = 'St. Louis Gene Structure Correction';
  $theHash{sequencefeatures}{html_field_name} = 'Sequence Features';
  $theHash{massspec}{html_field_name} = 'Mass Spec';
  $theHash{cellname}{html_field_name} = 'Cell Name';
  $theHash{cellfunction}{html_field_name} = 'Cell Function';
  $theHash{ablationdata}{html_field_name} = 'Ablation Data';
  $theHash{newsnp}{html_field_name} = 'Extract New SNP';
  $theHash{stlouissnp}{html_field_name} = 'Extract SNP Verified by St. Louis';
  $theHash{supplemental}{html_field_name} = 'Supplemental Material';
  $theHash{chemicals}{html_field_name} = 'Chemicals';
  $theHash{humandiseases}{html_field_name} = 'Human Diseases';
  $theHash{comment}{html_field_name} = 'Comment';

print "\n\nSTART curator first pass\n";
foreach my $joinkey (sort keys %joinkeys) {
  my @data;
  foreach my $type (@PGparameters) {
    my $result = $conn->exec( "SELECT * FROM cur_$type WHERE joinkey = '$joinkey';" );
    while (my @row = $result->fetchrow) {
      my $val = '';
      if ($row[1]) { $val = $row[1]; }	
      $theHash{$type}{html_value} = $val;             		# put value in %theHash
    } # while (my @row = $result->fetchrow)
    if ( $theHash{$type}{html_value} ) { push @data, "$type, $theHash{$type}{html_field_name}"; }
  } # foreach my $type (@PGparameters)
  if ($data[0]) {
    my $data = join"\t ", @data;
    print "$joinkey, $data\n"; } 
}

sub getPgData {
  my ($table, $joinkey) = @_;
  my $result = $conn->exec( "SELECT * FROM afp_$table WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow();
  if ($row[1]) { return $row[1]; }
  return;
} # sub getPgData

sub hashName {
  $hash{name}{gif} = 'Gene Identity and Function';
  $hash{name}{genesymbol} = 'Novel Gene Symbol or Gene-CDS link (e.g. xyz-1 gene was cloned and it turned out to be the same as abc-1 gene)';
  $hash{name}{mappingdata} = 'Genetic Mapping Data (e.g. 3-factor mapping, deficiency mapping)';
  $hash{name}{genefunction} = 'Gene Function (novel function for a gene (not reported in Wormbase under Concise Description on the Gene page)';
  $hash{name}{newmutant} = 'Mutant Phenotype (we reported the presence or absence of mutant phenotypes)';
  $hash{name}{rnai} = 'RNAi (small scale, less than 100 individual experiments)';
  $hash{name}{lsrnai} = 'RNAi (large scale >100 individual experiments)';

  $hash{name}{int} = 'Interactions';
  $hash{name}{geneinteractions} = 'Genetic interactions (e.g. daf-16(mu86) suppresses daf-2(e1370), daf-16(RNAi) suppresses daf-2(RNAi))';
  $hash{name}{geneproduct} = 'Gene Product Interaction (protein-protein, RNA-protein, DNA-protein interactions, etc.)';

  $hash{name}{gef} = 'Gene Expression and Function';
  $hash{name}{expression} = 'Expression Pattern Data (such as GFP reporter assay or immunostaining. exclude data for the reporters used exclusively as markers)';
  $hash{name}{sequencefeatures} = 'Cis-Gene Regulation (transcription factor binding sites, PWM, DNA/RNA elements required for gene expression etc.)';
  $hash{name}{generegulation} = 'Gene Regulation on Expression Level (e.g. geneA-gfp reporter is mis-expressed in geneB mutant background)';
  $hash{name}{overexpression} = 'Overexpression  (over-expression of a gene that results in a phenotypic change, genetic intractions, etc.)';
  $hash{name}{mosaic} = 'Mosaic Analysis (e.g. extra-chromosomal transgene loss in a particular cell lineage abolishes mutant rescue)';
  $hash{name}{site} = 'Site of Action (e.g. tissue/cell specific expression rescues mutant phenotype; RNAi in rrf-1 background determines that the gene acts in the germ line)';
  $hash{name}{microarray} = 'Microarray';

  $hash{name}{pfs} = 'Protein Function and Structure';
  $hash{name}{invitro} = 'Protein Analysis In Vitro (e.g. kinase assay)';
  $hash{name}{covalent} = 'Covalent Modification (e.g. phosphorylation site is studies via mutagenesis and in vitro assay)';
  $hash{name}{structureinformation} = 'Structure Information (e.g. NMR structure, functional domain info for a protein (e.g. removal of the first 50aa causes mislocalization of the protein))';
  
  $hash{name}{seq} = 'Sequence Data';
  $hash{name}{structurecorrectionsanger} = 'Gene Structure Correction (Gene Structure is different from the one in Wormbase: e.g. different splice-site, SL1 instead of SL2, etc.)';
  $hash{name}{sequencechange} = 'Sequence Change (we sequenced mutations in this paper)';
  $hash{name}{massspec} = 'Mass Spectrometry';
  
  $hash{name}{cell} = 'Cell Data';
  $hash{name}{ablationdata} = 'Ablation Data (cells were ablated using a laser or by other means (e.g. by expressing a cell-toxic protein))';
  $hash{name}{cellfunction} = 'Cell Function (the paper describes new function for a cell)';

  $hash{name}{sil} = 'In Silico Data';
  $hash{name}{phylogenetic} = 'Phylogenetic Analysis';
  $hash{name}{othersilico} = 'Other Silico Data (e.g. computational modeling of signaling pathways, genetic and physical interactions)';

  $hash{name}{rgn} = 'Reagents';
  $hash{name}{chemicals} = 'Chemicals (typically a small-molecule chemical was used: butanol, prozac, etc.)';
  $hash{name}{transgene} = 'Transgene (integrated or extra-chromosomal)';
  $hash{name}{antibody} = 'C.elegans Antibodies (Abs were created in the paper, or Abs used were created before elsewhere)';
  $hash{name}{newsnp} = 'New SNPs (SNPs that are not in Wormbase)';
#   $hash{name}{rgngene} = 'List Gene names for gene or gene products studied in the paper (exclude common markers and reporters)';
  $hash{name}{rgngene} = 'Please list genes studied in the paper (in the box on the next page)';
  $hash{name2}{rgngene} = 'Please list genes studied in the paper.  Exclude common markers and reporters';

  $hash{name}{oth} = 'Other';
  $hash{name}{nematode} = 'Nematode species (there is info about non-C.elegans nematodes)';
  $hash{name}{humandiseases} = 'Human Diseases (relevant to human diseases, e.g. the gene studied is a ortholog of a human disease gene)';
  $hash{name}{supplemental} = 'Check if the paper is accompanied by the supplemental materials';

  $hash{name}{comment} = 'Comment';
} # sub hashName


