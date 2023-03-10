#!/usr/bin/perl -w

# populate expression, movie, and picture objects for Murray set.  2012 10 25
#
# live run 2012 10 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my %gene;
my %anatomy;
my %alleleToTransgene;
my %strainToTransgene;
my %movieToAnatomy;				# $movieToAnatomy{$movie}{$anatomy}++;
my %movieToTransgene;				# $movieToTransgene{$movie}{$transgene}++;

&populateObjects();
sub populateObjects {
  $result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $gene{$row[1]} = 'WBGene' . $row[0]; }
  $result = $dbh->prepare( "SELECT * FROM gin_seqname" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $gene{$row[1]} = 'WBGene' . $row[0]; }
  $result = $dbh->prepare( "SELECT * FROM gin_locus" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $gene{$row[1]} = 'WBGene' . $row[0]; }

  $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    $anatomy{$row[1]} = $row[0]; 
    $anatomy{lc($row[1])} = $row[0]; }
  $result = $dbh->prepare( "SELECT * FROM obo_syn_anatomy" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    $anatomy{$row[1]} = $row[0]; 
    $anatomy{lc($row[1])} = $row[0]; }
  
  $result = $dbh->prepare( "SELECT trp_name.trp_name, trp_publicname.trp_publicname FROM trp_name, trp_publicname WHERE trp_name.joinkey = trp_publicname.joinkey" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $alleleToTransgene{$row[1]} = $row[0]; }
  $alleleToTransgene{'itIs38'} = 'WBTransgene00015852';
} # sub populateObjects

my ($mov_pgid) = &getHighestPgid('mov');
my ($exp_pgid) = &getHighestPgid('exp');
my ($pic_pgid) = &getHighestPgid('pic');

sub getHighestPgid {
  my ($type) = @_;
  my $highest = 0;
  my @tables = qw( name curator );
  foreach my $table (@tables) {
    my $pgtable = $type . '_' . $table;
    my $result = $dbh->prepare( "SELECT joinkey FROM $pgtable ORDER BY joinkey::INTEGER DESC" ); $result->execute();
    my @row = $result->fetchrow(); if ($row[0] > $highest) { $highest = $row[0]; }
  } # foreach my $table (@tables)
  return $highest;
} # sub getHighestPgid
my ($newExprId) = &getHighestExprId(); 
sub getHighestExprId {          # look at all exp_name, get the highest number and return
  my $highest = 0;
  my $result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE exp_name ~ '^Expr'" ); $result->execute();
  while (my @row = $result->fetchrow()) { if ($row[0]) { $row[0] =~ s/Expr//; if ($row[0] > $highest) { $highest = $row[0]; } } } 
  return $highest; }

sub pad10Zeros {                # take a number and pad to 10 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '000000000' . $number; }
  elsif ($number < 100) { $number = '00000000' . $number; }
  elsif ($number < 1000) { $number = '0000000' . $number; }
  elsif ($number < 10000) { $number = '000000' . $number; }
  elsif ($number < 100000) { $number = '00000' . $number; }
  elsif ($number < 1000000) { $number = '0000' . $number; }
  elsif ($number < 10000000) { $number = '000' . $number; }
  elsif ($number < 100000000) { $number = '00' . $number; }
  elsif ($number < 1000000000) { $number = '0' . $number; }
  return $number;
} # sub pad10Zeros





my $file1 = 'Supplemental_Dataset_1_-_Cells_for_each_gene-1.txt';
my $file2 = 'Supplemental_Table1_ListOfStrains_Revised.txt';
my $file3 = 'Supplemental_Table2_ListOfEmbryos_Revised_withComments.txt';

open (IN, "<$file2") or die "Cannot open $file2 : $!"; my $junk = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($strain, $locus, $rep_allele, $lin_allele, $expression ) = split/\t/, $line;
  my %alleles;
# RW10757 alr-1   stIs10757       stIs10116;itIs38
  my (@alleles) = split/;/, $rep_allele; foreach (@alleles) { $alleles{$_}++; }
     (@alleles) = split/;/, $lin_allele; foreach (@alleles) { $alleles{$_}++; }
  foreach my $allele (sort keys %alleles) {
    if ($alleleToTransgene{$allele}) { $strainToTransgene{$strain}{$alleleToTransgene{$allele}}++; }
      else { print qq(ERR $allele does not map to transgeneID $line\n); } }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $file2 : $!";

open (IN, "<$file1") or die "Cannot open $file1 : $!"; $junk = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($cell, $cellname, $locus, $movie, $strain) = split/\t/, $line;

  if ($strainToTransgene{$strain}) { 
    foreach my $transgene (keys %{ $strainToTransgene{$strain} } ) {
      $movieToTransgene{$movie}{$transgene}++; } }
  unless ($cellname eq 'death') {
    my (@cells) = split/\|/, $cellname;
    foreach my $cell (@cells) {
      $cell =~ s/^\s+//; $cell =~ s/\s+$//;
      my $anatomy = '';
      if ($anatomy{$cell}) { $anatomy = $anatomy{$cell}; }
        elsif ($anatomy{lc($cell)}) { $anatomy = $anatomy{lc($cell)}; }
        else { print qq(ERR $cell does not map to anatomyID $line\n); }
      $movieToAnatomy{$movie}{$anatomy}++; } }

# DO NOT GENERATE OBJECTS FROM THIS FILE.  use to get mapping from movie (time_series) to anatomy (cellname) and strains (and then transgenes)
#   # generate expr object
#   $movieInDataset{$time_series}++;
#   my $exp_pgid = 'GET';
#   my $exp_name = 'GET';
#   my $exp_paper = 'WBPaper00040986';
#   my $exp_gene = ''; my $exp_anatomy = '';
#   if ($gene{$locus}) { $exp_gene = $gene{$locus}; }
#     else { print qq(ERR $locus does not map to a WBGene : $line\n); }
#   unless ($cellname eq 'death') {
#     if ($anatomy{$cellname}) { $exp_anatomy = $anatomy{$cellname}; }
#       elsif ($anatomy{lc($cellname)}) { $exp_anatomy = $anatomy{lc($cellname)}; }
#       else { print qq(ERR $cellname does not map to anatomyID $line\n); } }
#   my $exp_qualifer = 'Certain';
#   my $exp_exprtype = '"Reporter_gene"';
#   my $exp_curator = 'WBPerson12028';
#   my $exp_pattern = 'EPIC dataset. http://epic.gs.washington.edu/. Large-scale cellular resolution compendium of gene expression dynamics throughout development. To generate a compact description of which cells express a particular reporter irrespective of time, the authors defined a metric "peak expression" for each of the 671 terminal ("leaf") cells born during embryogenesis. For each of these cells, the peak expression is the maximal reporter intensity observed in that cell or any of its ancestors; this has the effect of transposing earlier expression forward in time to the terminal set of cells. This metric allows straightforward comparisons of genes\' cellular and lineal expression overlap, even when the expression occurs with different timing and despite differences in the precise time point that curation ended in different movies, at the cost of ignoring the temporal dynamics of expression, a topic that requires separate treatment. For simplicity, the authors use the term "expressing cells" to mean the number of leaf cells (of 671) with peak expression greater than background (2000 intensity units) and at least 10% of the maximum expression in that embryo. Quantitative expression data for all cells are located here: ftp://caltech.wormbase.org/pub/wormbase/datasets-published/murray2012/ ' . 'FIX, do not understand';
#   my $exp_strain = '"' . $strain . '"';
} # while (my $line = <IN>)
close (IN) or die "Cannot close $file1 : $!";

open (IN, "<$file3") or die "Cannot open $file3 : $!"; $junk = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($sequence, $strain, $movie, $comment) = split/\t/, $line;

  $mov_pgid++;
  $exp_pgid++;
  $pic_pgid++;
# each line is one exprObj and also one movieObj and also one pictureObj

  $newExprId++; my $exp_name = 'Expr' . $newExprId;
  my $exp_paper = '"WBPaper00040986"';
  my $exp_gene = '';
  if ($sequence) { 
    if ($sequence eq 'cep-1.b') { $sequence = 'cep-1'; }
      elsif ($sequence eq 'egl-27.b') { $sequence = 'egl-27'; }
      elsif ($sequence eq 'egl-27.c') { $sequence = 'egl-27'; } }
  if ($gene{$sequence}) { $exp_gene = '"' . $gene{$sequence} . '"'; }
    else { print qq(ERR $sequence does not map to a WBGene : $line\n); }

  my $exp_exprtype = '"Reporter_gene"';
  my $exp_curator = 'WBPerson12028';
  my $exp_strain = '"' . $strain . '"';
  my $exp_pattern = qq(EPIC dataset. http://epic.gs.washington.edu/ Large-scale cellular resolution compendium of gene expression dynamics throughout development. This reporter was inferred to be expressing in this cell or one of its embryonic progenitor cells as described below. | To generate a compact description of which cells express a particular reporter irrespective of time, the authors defined a metric "peak expression" for each of the 671 terminal ("leaf") cells born during embryogenesis. For each of these cells, the peak expression is the maximal reporter intensity observed in that cell or any of its ancestors; this has the effect of transposing earlier expression forward in time to the terminal set of cells. This metric allows straightforward comparisons of genes' cellular and lineal expression overlap, even when the expression occurs with different timing and despite differences in the precise time point that curation ended in different movies, at the cost of ignoring the temporal dynamics of expression, a topic that requires separate treatment. For simplicity, the authors use the term "expressing cells" to mean the number of leaf cells (of 671) with peak expression greater than background (2000 intensity units) and at least 10% of the maximum expression in that embryo. Quantitative expression data for all cells are located here: ftp://caltech.wormbase.org/pub/wormbase/datasets-published/murray2012/);
  my $exp_qualifier = 'Certain';
  my (@anatomies) = sort keys %{ $movieToAnatomy{$movie} };
  my $exp_anatomy = join'","', @anatomies; if ($exp_anatomy) { $exp_anatomy = '"'. $exp_anatomy . '"'; }
  my (@transgenes) = sort keys %{ $movieToTransgene{$movie} };
  my %transgenes; foreach (@transgenes) { $transgenes{$_}++; }
  foreach my $transgene (keys %{ $strainToTransgene{$strain} } ) { $transgenes{$transgene}++; }
  my $exp_transgene = join'","', sort keys %transgenes; if ($exp_transgene) { $exp_transgene = '"'. $exp_transgene . '"'; }

  &addToPg($exp_pgid, 'exp_name', $exp_name);
  &addToPg($exp_pgid, 'exp_paper', $exp_paper);
  &addToPg($exp_pgid, 'exp_exprtype', $exp_exprtype);
  &addToPg($exp_pgid, 'exp_curator', $exp_curator);
  &addToPg($exp_pgid, 'exp_strain', $exp_strain);
  &addToPg($exp_pgid, 'exp_pattern', $exp_pattern);
  if ($exp_gene) {      &addToPg($exp_pgid, 'exp_gene',      $exp_gene);       }
    else { print "ERR no gene $line\n"; }
  if ($exp_anatomy) {
    &addToPg($exp_pgid, 'exp_anatomy',   $exp_anatomy);    
    &addToPg($exp_pgid, 'exp_qualifier', $exp_qualifier); }
#     else { print "ERR no anatomy $line\n"; }	# it's okay for there to be no anatomy  Daniela
  if ($exp_transgene) { &addToPg($exp_pgid, 'exp_transgene', $exp_transgene);  }
    else { print "ERR no transgene $line\n"; }

  my $movId = &pad10Zeros($mov_pgid);
  my $mov_name = 'WBMovie' . $movId;
  my $mov_source = $movie . '.mov';
  my $mov_exprpattern = '"' . $exp_name . '"';
  my $mov_curator = 'WBPerson12028';
  my $mov_remark = ''; if ($comment ne 'n/a') { 
    $comment =~ s/^\"//; $comment =~ s/\"$//;
    $mov_remark = $comment; }
  &addToPg($mov_pgid, 'mov_name', $mov_name);
  &addToPg($mov_pgid, 'mov_source', $mov_source);
  &addToPg($mov_pgid, 'mov_exprpattern', $mov_exprpattern);
  &addToPg($mov_pgid, 'mov_curator', $mov_curator);
  &addToPg($mov_pgid, 'mov_remark', $mov_remark);

  my $picId = &pad10Zeros($pic_pgid);
  my $pic_name = 'WBPicture' . $picId;
  my $pic_contact = '"WBPerson3733"';
  my $pic_person  = '"WBPerson3733"';
  my $pic_description = 'Quantitative expression data for all cells are located here: ftp://caltech.wormbase.org/pub/wormbase/datasets-published/murray2012/';
  my $pic_source = $movie . '.jpg';
  my $pic_exprpattern = '"' . $exp_name . '"';
  my $pic_remark = 'Murray JI et al. (2012) Genome Res "Multidimensional regulation of gene expression in the C. elegans ..."';
  my $pic_curator = 'WBPerson12028';
  &addToPg($pic_pgid, 'pic_name', $pic_name);
  &addToPg($pic_pgid, 'pic_contact', $pic_contact);
  &addToPg($pic_pgid, 'pic_person', $pic_person);
  &addToPg($pic_pgid, 'pic_description', $pic_description);
  &addToPg($pic_pgid, 'pic_source', $pic_source);
  &addToPg($pic_pgid, 'pic_exprpattern', $pic_exprpattern);
  &addToPg($pic_pgid, 'pic_curator', $pic_curator);
  &addToPg($pic_pgid, 'pic_remark', $pic_remark);
} # while (my $line = <IN>)
close (IN) or die "Cannot close $file3 : $!";

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub addToPg {
  my ($pgid, $table, $value) = @_;
  if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  push @pgcommands, "INSERT INTO $table VALUES ('$pgid', E'$value');";
  push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$pgid', E'$value');";
} # sub addToPg


__END__

  DELETE FROM exp_name        WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_paper       WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_exprtype    WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_curator     WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_strain      WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_pattern     WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_qualifier   WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_gene        WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_anatomy     WHERE exp_timestamp > '2012-10-29 20:51';
  DELETE FROM exp_transgene   WHERE exp_timestamp > '2012-10-29 20:51';

  DELETE FROM mov_name        WHERE mov_timestamp > '2012-10-29 20:51';
  DELETE FROM mov_source      WHERE mov_timestamp > '2012-10-29 20:51';
  DELETE FROM mov_exprpattern WHERE mov_timestamp > '2012-10-29 20:51';
  DELETE FROM mov_curator     WHERE mov_timestamp > '2012-10-29 20:51';
  DELETE FROM mov_remark      WHERE mov_timestamp > '2012-10-29 20:51';

  DELETE FROM pic_name        WHERE pic_timestamp > '2012-10-29 20:51';
  DELETE FROM pic_contact     WHERE pic_timestamp > '2012-10-29 20:51';
  DELETE FROM pic_description WHERE pic_timestamp > '2012-10-29 20:51';
  DELETE FROM pic_source      WHERE pic_timestamp > '2012-10-29 20:51';
  DELETE FROM pic_exprpattern WHERE pic_timestamp > '2012-10-29 20:51';
  DELETE FROM pic_curator     WHERE pic_timestamp > '2012-10-29 20:51';
  DELETE FROM pic_remark      WHERE pic_timestamp > '2012-10-29 20:51';


==> Supplemental_Dataset_1_-_Cells_for_each_gene-1.txt <==
Cell	Cell Name	gene	time series name	strain
MSapaaaav	GLRVL	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSapaaaad	GLRL	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSaaaaapp	m4DL	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSaaaaapaa	I3	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSaaaaapap	g1P	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSaaaaaar	GLRDR	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSaaaaaal	GLRDL	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSapaaap	mu_bod	alr-1	20081016_alr-1_10A2_3_L1	RW10757
MSapaapp	M	alr-1	20081016_alr-1_10A2_3_L1	RW10757

==> Supplemental_Table1_ListOfStrains_Revised.txt <==
strain	gene	reporter allele	lineaging allele(s)	Expression onset/pattern for strains with no edited movies
RW10614	ceh-39	stIs10685	zuIs178	ubiquitous
RW10618	ceh-39	stIs10687	zuIs178	ubiquitous
RW10738	ceh-39	stIs10686	zuIs178	ubiquitous
RW10229	ceh-49	stIs10184	zuIs178	ubiquitous
RW10252	ceh-49	stIs10215	zuIs178	ubiquitous
RW10857	hmg-5	stIs10779	zuIs178	ubiquitous
RW11057	kin-33	stIs10338	zuIs178	ubiquitous
RW10852	lin-13	stIs10630	zuIs178	ubiquitous
RW10908	lin-13	stIs10806	zuIs178	ubiquitous

==> Supplemental_Table2_ListOfEmbryos_Revised_withComments.txt <==
gene	strain	embryo movie name	Comments
B0310.2	RW10613	20080905_B0310_2_13_L1	"7-25 laser AB/C Hyp, MS pha?"
B0310.2	RW10704	20080911_B0310_2_2_L1	"AB subset, E brightest"
B0310.2	RW10803	20081111_B0310_2_8_L1	E and c-neuron biased
B0310.2	RW10803	20081111_B0310_2_8_L2	huckebein E/Cneuron/ABneuron-biased ubiq
B0336.3	RW10906	20090505_B0336_3_13_L1	gut/hyp from after 350 cells
B0336.3	RW10906	20090505_B0336_3_13_L2	gut hyp
B0336.3	RW11494	20111017_B03363_9_L1	n/a
B0336.3	RW11494	20111017_B03363_9_L2	n/a
C05D10.1	RW11077	20090812_C05D10_1b_3_L1	n/a


$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)
