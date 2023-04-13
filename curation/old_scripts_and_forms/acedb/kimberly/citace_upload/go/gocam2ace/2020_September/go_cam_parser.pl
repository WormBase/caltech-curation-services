#!/usr/bin/perl

# get ftp://ftp.ebi.ac.uk/pub/contrib/goa/gp_association.6239_wormbase.gz and convert to .ace format
# for Kimberly  2015 02 05
#
# check wbgenes are valid / not-dead  2015 04 23
#
# col12 splits different terms on ,   2015 07 24
#
# account for DOI: as well as PMID:  2015 09 23
#
# all PAINT_REF map to WBPaper00046480  2018 05 04
#
# convert qualifier annotation relations to RO terms, change tag appropriately if NOT.  2018 06 28
#
# get gpi file every time from wormbase ftp, generate wbgene mappings to uniprot from there.  2018 08 30
#
#
# modified for go_cam  2018 11 05
#
# added full set of gp2term relations for BP 2018 11 06 kmv
#
# map column 2 to a wbgene, then check whether it was or has become a wbgene before outputting it.  2019 10 16
# 
# added NAS and IC to ECO mapping list. 2020 06 01 kmva
#
# added RCA to ECO mapping list. 2020 06 28 kmva

use strict;
use diagnostics;
use LWP::Simple;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;


my %annotToRo;
&populateAnnotrelToRo();
my %chebiToMol;
&populateChebiToMol();
my %pmidToWBPaper;
&populatePmidToWBPaper();
my %doiToWBPaper;
&populateDoiToWBPaper();
my %ecoToGoCode;
&populateEcoToGoCode();

# my %gin;
# &populateGin();


my $newtabfile = 'gpad_extra_column';
open (TAB, ">$newtabfile") or die "Cannot create $newtabfile : $!";
my $errfile = 'gpad_extra_column.err';
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";
my $acefile = 'gocam_annotation.ace';
open (ACE, ">$acefile") or die "Cannot create $acefile : $!";

my %taxonToSpecies;
&populateTaxonToSpecies();


my %dbidToWb;		# uniprot to wbgene
my %tempGpi;		# tempname to uniprot
my %nameToWbg;		# tempname to wbgene
my $gpifileUrl = 'ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/PRJNA13758/annotation/gene_product_info/c_elegans.canonical_bioproject.current_development.gene_product_info.gpi.gz';
my $gpifiledata = get $gpifileUrl;
my (@gpilines) = split/\n/, $gpifiledata;
foreach my $line (@gpilines) {
  next unless ($line =~ m/^WB/);
  my (@tabs) = split/\t/, $line;
  my $tempid   = $tabs[1];
  my $tempname = lc($tabs[2]);
  if ($tempid =~ m/WBGene\d+/) { $nameToWbg{$tempname} = $tempid; }
  next unless $tabs[8];
  my $uniprot  = $tabs[8];
  my (@uniprots) = split/\|/, $uniprot;
  foreach my $unip (@uniprots) { $tempGpi{$tempname}{$unip}++; } }
foreach my $tempname (sort keys %tempGpi) { 
  unless ($nameToWbg{$tempname}) { print ERR qq($tempname in gpi file doesn't map to a WBGene from column 2\n); next; }
  my $wbgene = $nameToWbg{$tempname};
  foreach my $unip (sort keys %{ $tempGpi{$tempname} }) {
    $unip =~ s/UniProtKB://;
    $dbidToWb{$unip} = $wbgene; } }


my $annotCounter = 0;
my $annotFile = '/home/acedb/kimberly/citace_upload/go/gp_annotation.ace';
open (IN, "<$annotFile") or die "Cannot open $annotFile : $!";
while (my $line = <IN>) { if ($line =~ m/GO_annotation : "(\d+)"/) { $annotCounter = $1; } }
close (IN) or die "Cannot close $annotFile : $!";


# # my $sourcefile = 'http://build.berkeleybop.org/job/export-lego-to-gpad-sparql/lastSuccessfulBuild/artifact/legacy/wb.gpad';
# # my $sourcefile = 'ftp://ftp.ebi.ac.uk/pub/contrib/goa/gp_association.6239_wormbase.gz';
# my $sourcedata = get $sourcefile;

my $sourcefile = 'http://current.geneontology.org/products/annotations/noctua_wb.gpad.gz';
`wget $sourcefile`;
`gunzip noctua_wb.gpad.gz`;
$/ = undef;
my $infile = 'noctua_wb.gpad';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $sourcedata = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";
# `rm noctua_wb.gpad`;


my (@lines) = split/\n/, $sourcedata;
# my $count = 0;
my $count = $annotCounter;
my %filter;				# filter on wbgDbid + goid + dbref + evicode + withConverted + taxon + assignedBy + annotExtConverted  any entries with same values for all these considered the same
foreach my $line (@lines) {
  next unless ($line =~ m/^WB/);
  my (@tabs) = split/\t/, $line;
  my ($db, $dbid, $qualifier, $goid, $dbref, $evicode, $with, $taxon, $date, $assignedBy, $annotExts, $annotProp) = split/\t/, $line;
  next if ($assignedBy eq 'SynGO');
  next if ($with =~ m/EC:/);
  next if ($with =~ m/InterPro:/);
  next if ($with =~ m/PANTHER:/);
  next if ($with =~ m/UniPathway:/);
  next if ($with =~ m/UniProt-KW:/);
  next if ($with =~ m/UniProt-SubCell:/);
  next if ($with =~ m/UniRule:/);
  if ($assignedBy eq 'WB') { $assignedBy = 'WormBase'; }


  $count++;
  my $goanid = &pad8Zeros($count);
  print ACE qq(GO_annotation : "$goanid"\n);
  if ($dbidToWb{$dbid}) { $dbid = $dbidToWb{$dbid}; }
  if ($dbid =~ m/WBGene/) {
      print ACE qq(Gene\t"$dbid"\n); }
    else {
      print ERR qq($dbid doesn't map to WBGene from column 2, line $count\n); }
  print ACE qq(GO_term\t"$goid"\n);
  my (@annotRel) = split/\|/, $qualifier;
  my $annotTag = 'Annotation_relation';
  if ($qualifier =~ m/NOT/) { $annotTag = 'Annotation_relation_not'; }
  foreach my $annotRel (@annotRel) { 
    if ($annotToRo{$annotRel}) {
      print ACE qq($annotTag\t"$annotToRo{$annotRel}"\n); } }
  my (@dbrefs) = split/\|/, $dbref;
  foreach my $adbref (@dbrefs) {
    if ($adbref =~ m/GO_REF:(\d+)/) {                    print ACE qq(GO_reference\t"Gene Ontology Consortium"\t"GO_REF"\t"$1"\n); }
      elsif ($adbref =~ m/PMID:(\d+)/) {
        if ($pmidToWBPaper{$1}) {                        print ACE qq(Reference\t"$pmidToWBPaper{$1}"\n); }
          else {                                         print ERR qq(PMID $1 does not map to WBPaper\n); } }
      elsif ($adbref =~ m/DOI:(.+)/) {
        if ($doiToWBPaper{$1}) {                         print ACE qq(Reference\t"$doiToWBPaper{$1}"\n); }
          else {                                         print ERR qq(DOI $1 does not map to WBPaper\n); } }
      elsif ($adbref =~ m/PAINT_REF:\d+/) {              print ACE qq(Reference\t"WBPaper00046480"\n); }
      else {                                             print ERR qq(DBREF $adbref invalid\n); }
  } # foreach my $adbref (@dbrefs)
  if ($evicode) {                             			 print ACE qq(ECO_term\t"$evicode"\n); }
  if ($ecoToGoCode{$evicode}) {                          print ACE qq(GO_code\t"$ecoToGoCode{$evicode}"\n); }
      else {                                             print ERR qq(ECO $evicode invalid\n); }

  my (@withunis) = split/\|/, $with;
  my @withConverted;
  foreach my $withuni (@withunis) {
    if ($withuni =~ m/^UniProtKB:/) {							# convert UniProtKB: to wbgene
       $withuni =~ s/^UniProtKB://;
       my $withuniStripped = $withuni; 
       $withuniStripped =~ s/\-\d$//g;
       my $wbgWith = $withuni;
       if ($dbidToWb{$withuniStripped}) { $wbgWith = $dbidToWb{$withuniStripped}; push @withConverted, $wbgWith; }
         else { 
           push @withConverted, "UniProtKB:$withuni";			# add uniprotkb value if does not map to wormbase value (kimberly 2015 02 05)
           print ERR qq($withuni doesn't map to WBGene from column 8, line $count\n); } }
     else {
       push @withConverted, $withuni; }							# those that are not UniProtKB: just get added back
  } # foreach my $withuni (@withunis)
  foreach my $with (@withConverted) {
    if ($with =~ m/With:Not_supplied/) { 1; }			# do nothing
      elsif ($with =~ m/^UniProt:(\w+)/) {               print ACE qq(Database\t"UniProt"\t"UniProtAcc"\t"$1"\n); }
      elsif ($with =~ m/^UniProtKB:(\w+)/) {             print ACE qq(Database\t"UniProt"\t"UniProtAcc"\t"$1"\n); }
      elsif ($with =~ m/^InterPro:(IPR\d+)/) {           print ACE qq(Motif\t"INTERPRO:$1"\n); }
      elsif ($with =~ m/^HGNC:(\d+)/) {                  print ACE qq(Database\t"HGNC"\t"HGNCID"\t"$1"\n); }
      elsif ($with =~ m/^MGI:(MGI:\d+)/) {               print ACE qq(Database\t"MGI"\t"MGIID"\t"$1"\n); }
      elsif ($with =~ m/^HAMAP:(MF_\d+)/) {              print ACE qq(Database\t"HAMAP"\t"HAMAP_annotation_rule"\t"$1"\n); }
      elsif ($with =~ m/^EC:([\.\d]+)/) {                print ACE qq(Database\t"KEGG"\t"KEGG_id"\t"$1"\n); }
      elsif ($with =~ m/^UniPathway:(UPA\d+)/) {         print ACE qq(Database\t"UniPathway"\t"Pathway_id"\t"$1"\n); }
      elsif ($with =~ m/^UniProtKB-KW:(KW-\d+)/) {       print ACE qq(Database\t"UniProt"\t"UniProtKB-KW"\t"$1"\n); }
      elsif ($with =~ m/^UniProtKB-SubCell:(SL-\d+)/) {  print ACE qq(Database\t"UniProt"\t"UniProtKB-SubCell"\t"$1"\n); }
      elsif ($with =~ m/^UniRule:(\w+)/) {               print ACE qq(Database\t"UniProt"\t"UniRule"\t"$1"\n); }
      elsif ($with =~ m/^(GO:\d+)/) {                    print ACE qq(Inferred_from_GO_term\t"$1"\n); }
      elsif ($with =~ m/^WB:(WBVar\d+)/) {               print ACE qq(Variation\t"$1"\n); }
      elsif ($with =~ m/^WB:(WBRNAi\d+)/) {              print ACE qq(RNAi_result\t"$1"\n); }
      elsif ($with =~ m/^WB:(WBGene\d+)/) {              print ACE qq(Interacting_gene\t"$1"\n); }
      elsif ($with =~ m/^(WBGene\d+)/) {                 print ACE qq(Interacting_gene\t"$1"\n); }
      elsif ($with =~ m/^PomBase:([\.\w]+)/) {           print ACE qq(Database\t"PomBase"\t"PomBase_systematic_name"\t"$1"\n); }
      elsif ($with =~ m/^SGD:(S\d+)/) {                  print ACE qq(Database\t"SGD"\t"SGDID"\t"$1"\n); }
      elsif ($with =~ m/^PANTHER:(PTN\d+)/) {            print ACE qq(Database\t"Panther"\t"PanTree_node"\t"$1"\n); }
      elsif ($with =~ m/^Panther:(PTN\d+)/) {            print ACE qq(Database\t"Panther"\t"PanTree_node"\t"$1"\n); }
      elsif ($with =~ m/^TAIR:locus:(\d+)/) {            print ACE qq(Database\t"TAIR"\t"TAIR_locus_id"\t"$1"\n); }
      elsif ($with =~ m/^FB:(FBgn\d+)/) {                print ACE qq(Database\t"FLYBASE"\t"FLYBASEID"\t"$1"\n); }
      elsif ($with =~ m/^RGD:(\d+)/) {                   print ACE qq(Database\t"RGD"\t"RGDID"\t"$1"\n); }
      elsif ($with =~ m/^dictyBase:(DDB_G\d+)/) {        print ACE qq(Database\t"dictyBase"\t"dictyBaseID"\t"$1"\n); }
      elsif ($with =~ m/^CHEBI:(\d+)/) {                 print ACE qq(Database\t"ChEBI"\t"CHEBI_ID"\t"$1"\n); }
      else {                                             print ERR qq(WITH $with not acounted in .ace file\n); }
  } # foreach my $with (@withConverted)
  if ($taxon) {
    if ($taxonToSpecies{$taxon}) {                       print ACE qq($taxonToSpecies{$taxon}\n); }
      else {                                             print ERR qq(Taxon $taxon does not map to species\n); } }
  if ($date) { if ($date =~ m/(\d{4})(\d{2})(\d{2})/) {  print ACE qq(Date_last_updated\t"$1-$2-$3"\n); } }
  if ($assignedBy) {                                     print ACE qq(Contributed_by\t"$assignedBy"\n); }
  my (@annExtsComma) = split/\|/, $annotExts;
  foreach my $annExtComma (@annExtsComma) {
    my (@annExts) = split/,/, $annExtComma;
    foreach my $annExt (@annExts) {
      my $relation = '';
      if ($annExt =~ m/^(.*?)\((.*?)\)/) { $relation = $1; $annExt = $2; }
      if ($annExt =~ m/(WBls:\d+)/) {                       print ACE qq(Life_stage_relation\t"$relation"\t"$1"\n); }
        elsif ($annExt =~ m/WB:(WBGene\d+)/) {              print ACE qq(Gene_relation\t"$relation"\t"$1"\n); }
        elsif ($annExt =~ m/(WBGene\d+)/) {                 print ACE qq(Gene_relation\t"$relation"\t"$1"\n); }
        elsif ($annExt =~ m/CHEBI:(\d+)/) {
          if ($chebiToMol{$1}) {                           print ACE qq(Molecule_relation\t"$relation"\t"$chebiToMol{$1}"\n); }	
            else {                                         print ERR qq(CHEBI $1 does not map to WBMol\n); } }
        elsif ($annExt =~ m/(WBbt:\d+)/) {                  print ACE qq(Anatomy_relation\t"$relation"\t"$1"\n); }
        elsif ($annExt =~ m/(GO:\d+)/) {                    print ACE qq(GO_term_relation\t"$relation"\t"$1"\n); }
        elsif ($annExt =~ m/UniProtKB:/) {                  1; }
        elsif ($annExt =~ m/FB:/) {                         1; }
        else {                                             print ERR qq(Annotation Extension $annExt not acounted in .ace file\n); }
    } # foreach my $annExt (@annExts)
  } # foreach my $annExtComma (@annExtsComma)

  print ACE qq(\n);
} # foreach my $line (@lines)



close (TAB) or die "Cannot close $newtabfile : $!";
close (ERR) or die "Cannot close $errfile : $!";
close (ACE) or die "Cannot close $acefile : $!";

sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros


sub populateAnnotrelToRo {
  $annotToRo{'colocalizes_with'} = 'RO:0002325';
  $annotToRo{'contributes_to'}   = 'RO:0002326';
  $annotToRo{'enables'}          = 'RO:0002327';
  $annotToRo{'involved_in'}      = 'RO:0002331';
  $annotToRo{'part_of'}          = 'BFO:0000050';
  $annotToRo{'acts_upstream_of_or_within'}   = 'RO:0002264';
  $annotToRo{'acts_upstream_of'}   = 'RO_0002263';
  $annotToRo{'acts_upstream_of_or_within_negative_effect'}   = 'RO:0004033';
  $annotToRo{'acts_upstream_of_or_within_positive_effect'}   = 'RO:0004032';
  $annotToRo{'acts_upstream_of_negative_effect'}   = 'RO:0004035';
  $annotToRo{'acts_upstream_of_positive_effect'}   = 'RO:0004034';
} # sub populateAnnotrelToRo

sub populateChebiToMol {
  $result = $dbh->prepare( "SELECT mop_name.mop_name, mop_chebi.mop_chebi FROM mop_name, mop_chebi WHERE mop_name.joinkey = mop_chebi.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $chebiToMol{$row[1]} = $row[0]; } 
} # sub populateChebiToMol

sub populateDoiToWBPaper {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'doi';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[1] =~ s/doi//; $doiToWBPaper{$row[1]} = 'WBPaper' . $row[0]; }
} # sub populateDoiToWBPaper

sub populatePmidToWBPaper {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[1] =~ s/pmid//; $pmidToWBPaper{$row[1]} = 'WBPaper' . $row[0]; }
} # sub populatePmidToWBPaper

sub populateTaxonToSpecies {
  $taxonToSpecies{"taxon:1280"}   = qq(Interacting_species\t"Staphylococcus aureus");
  $taxonToSpecies{"taxon:1428"}   = qq(Interacting_species\t"Bacillus thuringiensis");
  $taxonToSpecies{"taxon:98403"}  = qq(Interacting_species\t"Drechmeria coniospora");
  $taxonToSpecies{"taxon:5207"}   = qq(Interacting_species\t"Cryptococcus neoformans");
  $taxonToSpecies{"taxon:216597"} = qq(Interacting_species\t "Salmonella enterica subs. enterica serovar Typhimurium" "SL1344");
  $taxonToSpecies{"taxon:226185"} = qq(Interacting_species\t"Enterococcus faecalis" "V583");
  $taxonToSpecies{"taxon:273526"} = qq(Interacting_species\t"Serratia marcescens" "Db11");
  $taxonToSpecies{"taxon:474186"} = qq(Interacting_species\t"Enterococcus faecalis" "OG1RF");
  $taxonToSpecies{"taxon:5476"}   = qq(Interacting_species\t"Candida albicans");
  $taxonToSpecies{"taxon:615"}    = qq(Interacting_species\t"Serratia marcescens");
  $taxonToSpecies{"taxon:637912"} = qq(Interacting_species\t"Escherichia coli" "OP50");
  $taxonToSpecies{"taxon:652611"} = qq(Interacting_species\t"Pseudomonas aeruginosa" "PA14");
  $taxonToSpecies{"taxon:686"}    = qq(Interacting_species\t"Vibrio cholerae"  "O1 biovar El Tor");
  $taxonToSpecies{"taxon:93061"}  = qq(Interacting_species\t"Staphylococcus aureus subsp. aureus" "NCTC 8325");
  $taxonToSpecies{"taxon:90371"}  = qq(Interacting_species\t"Salmonella enteric subs. enterica serovar Typhimurium");
  $taxonToSpecies{"taxon:28450"}  = qq(Interacting_species\t"Burkholderia pseudomallei");
  $taxonToSpecies{"taxon:46170"}  = qq)Interacting_species\t"Staphylococcus aureus subsp. aureus");
  $taxonToSpecies{"taxon:287"}    = qq)Interacting_species\t"Pseudomonas aeruginosa");
  $taxonToSpecies{"taxon:621"}    = qq)Interacting_species\t"Shigella boydii");
  $taxonToSpecies{"taxon:623"}    = qq)Interacting_species\t"Shigella flexneri");
  $taxonToSpecies{"taxon:29488"}  = qq)Interacting_species\t"Photorhabdus luminescens");
} # sub populateTaxonToSpecies

sub populateEcoToGoCode {
  $ecoToGoCode{"ECO:0000245"} = "RCA";
  $ecoToGoCode{"ECO:0000250"} = "ISS";
  $ecoToGoCode{"ECO:0000270"} = "IEP";
  $ecoToGoCode{"ECO:0000304"} = "TAS";
  $ecoToGoCode{"ECO:0000303"} = "NAS";
  $ecoToGoCode{"ECO:0000307"} = "ND";
  $ecoToGoCode{"ECO:0000305"} = "IC";
  $ecoToGoCode{"ECO:0000314"} = "IDA";
  $ecoToGoCode{"ECO:0000315"} = "IMP";
  $ecoToGoCode{"ECO:0000316"} = "IGI";
  $ecoToGoCode{"ECO:0000318"} = "IBA";
  $ecoToGoCode{"ECO:0000352"} = "IEA";
  $ecoToGoCode{"ECO:0000353"} = "IPI";
  $ecoToGoCode{"ECO:0000501"} = "IEA";
  $ecoToGoCode{"ECO:0001225"} = "IMP";
  $ecoToGoCode{"ECO:0001232"} = "IDA";
  $ecoToGoCode{"ECO:0005589"} = "IDA";
  $ecoToGoCode{"ECO:0005593"} = "IDA";
  $ecoToGoCode{"ECO:0005611"} = "IDA";
  $ecoToGoCode{"ECO:0006003"} = "IDA";
  $ecoToGoCode{"ECO:0006013"} = "IDA";
  $ecoToGoCode{"ECO:0006062"} = "IDA";
  $ecoToGoCode{"ECO:0006063"} = "IMP";
  $ecoToGoCode{"ECO:0006064"} = "IDA";
  $ecoToGoCode{"ECO:0007007"} = "HEP";
  $ecoToGoCode{"ECO:0007293"} = "IEA";
}

# sub populateGin {
#   $result = $dbh->prepare( "SELECT gin_wbgene FROM gin_wbgene;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) { $gin{exists}{$row[0]}++; } 
#   $result = $dbh->prepare( "SELECT * FROM gin_dead;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#   while (my @row = $result->fetchrow) { $gin{dead}{"WBGene$row[0]"} = $row[1]; } 
# } # sub populateGin

