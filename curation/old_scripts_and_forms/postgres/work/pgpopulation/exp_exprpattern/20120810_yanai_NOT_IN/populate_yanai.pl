#!/usr/bin/perl -w

# populate yanai expr + pic data.  2012 08 10
#
# ran on sample set.  2012 08 11
# 
# revisited again after a few changes after Daniela worked things out.  2012 09 19
#
# put pipes to split pic_description, get rid of pic_paper.  (also changed dumper to split description on pipes).  2012 09 20
#
# live run 2 hours 53 minutes.  2012 10 01
#
# made .ace dump for citaceMinus, changed pic/expr object IDs, and removed from postgres.  2012 10 03


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my %datatypes;
@{ $datatypes{exp}{highestPgidTables} }            = qw( name curator );
@{ $datatypes{pic}{highestPgidTables} }            = qw( name curator );

my $exp_paper = '"WBPaper00041190"';
my $exp_curator = 'WBPerson12028';
# my $exp_exprtype = '"Microarray"';		# no expr type at all 2012 09 19
my $exp_pattern = 'Developmental gene expression time-course.  Raw data can be downloaded from ftp://caltech.wormbase.org/pub/wormbase/datasets-published/levin2012';
my $pic_paper = 'WBPaper00041190';
my $pic_curator = 'WBPerson12028';
my $pic_contact = '"WBPerson4037"'; 
my $pic_person = '"WBPerson4037"';
my $pic_remark = 'Levin M et al. (2012) Dev Cell "Developmental milestones punctuate gene expression in the caenorhabditis ...."';
my $pic_description_YES = "A) Embryonic gene expression profile | B) Comparative gene expression profiles for the orthologous group | red=C. remanei | green=C. briggsae | blue=C. brenneri | yellow=C. elegans | pink=C. japonica | For additional information: yanailab.technion.ac.il";
my $pic_description_NO = "A) Embryonic gene expression profile | For additional information: yanailab.technion.ac.il";

# my $pic_source = '<colA>.jpg';
# my $exp_gene = '<colA>';
# my $exp_remark = '<colB>';
# my $exp_dnatext = '<colD>';		# create pg table


my ($newPgidExp) = &getHighestPgid('exp');			# current highest pgid (joinkey)
my ($newPgidPic) = &getHighestPgid('pic');			# current highest pgid (joinkey)
my ($newExprId)  = &getHighestExprId(); 

# original numbers in sandbox  2012 09 21
# $newPgidExp = '12344';
# $newPgidPic = '11163';
# $newExprId  = '10056';

my %validWBGenes;
$result = $dbh->prepare( "SELECT * FROM gin_wbgene;" );
$result->execute();
while (my @row = $result->fetchrow()) { $validWBGenes{$row[1]} = '"' . $row[1] . '"'; }

# my $infile = 'ExperimentDetailsIanHope.txt';
my $infile = 'EvoDevomics_data_elegans_Wormbase.txt';
# my $infile = 'EvoDevomics_data_elegans_Wormbase.sample.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk1 = <IN>; my $junk2 = <IN>;
while (my $line = <IN>) {
  next unless ($line =~ m/^WBGene/);
  chomp $line;
#   my ($exp_gene, $junk, $exp_clone, $exp_strain, $exp_reportergene, $exp_pattern, $im1, $im2, $im3, $im4, $im5, $im6) = split/\t/, $line;
  my ($exp_gene, $exp_remark, $junk, $exp_dnatext, $yesNo) = split/\t/, $line;
  my $pic_source = $exp_gene . '.jpg';
  my $pic_description = 'YES_NO';
  if ($yesNo eq 'no') { $pic_description = $pic_description_NO; }
    elsif ($yesNo eq 'yes') { $pic_description = $pic_description_YES; }
    else { print "ERR colE neither yes nor no for $line\n"; }
  $newPgidExp++;
  $newExprId++;
  &insertToPostgresTableAndHistory('exp_name',     $newPgidExp, "Expr$newExprId" );
  &insertToPostgresTableAndHistory('exp_paper',    $newPgidExp, $exp_paper       );
  &insertToPostgresTableAndHistory('exp_curator',  $newPgidExp, $exp_curator     );
  &insertToPostgresTableAndHistory('exp_remark',   $newPgidExp, 'Microarray'     );
#   &insertToPostgresTableAndHistory('exp_remark',   $newPgidExp, $exp_remark      );		# no remark from file  2012 09 19
#   &insertToPostgresTableAndHistory('exp_exprtype', $newPgidExp, $exp_exprtype    );		# no expr type 2012 09 19
#   &insertToPostgresTableAndHistory('exp_dnatext',  $newPgidExp, $exp_dnatext     );		# no dna text  2012 09 19
  if ($exp_gene) {
    if ($validWBGenes{$exp_gene}) {
        my $wbgene = $validWBGenes{$exp_gene};
        &insertToPostgresTableAndHistory('exp_gene', $newPgidExp, $wbgene); }
      else { print "ERR NO GENE FOR $exp_gene\n"; } }
#     my $wbgene = &getWBGene($exp_gene); 		# this took way too long with nearly 20000 objects
#     if ($wbgene) {
#         if ($wbgene =~ m/,/) { print "ERROR $exp_gene maps to $wbgene\n"; }
#           else { &insertToPostgresTableAndHistory('exp_gene', $newPgidExp, $wbgene); } }
      else { print "ERR NO GENE FOR $line\n"; }
  if ($exp_pattern) { 
    $exp_pattern =~ s/^"//; $exp_pattern =~ s/"$//;
    if ($exp_pattern =~ m/\'/) { $exp_pattern =~ s/\'/''/g; }
    &insertToPostgresTableAndHistory('exp_pattern', $newPgidExp, $exp_pattern); }

  &createImage($pic_source, "Expr$newExprId", $pic_description); 

} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

sub createImage {
  my ($pic_source, $pic_expr, $pic_description) = @_;
  $newPgidPic++;
  my $picId = &pad10Zeros($newPgidPic);
  $pic_expr = '"' . $pic_expr . '"';
  &insertToPostgresTableAndHistory('pic_name', $newPgidPic, "WBPicture$picId");
  &insertToPostgresTableAndHistory('pic_source', $newPgidPic, $pic_source);
  &insertToPostgresTableAndHistory('pic_exprpattern', $newPgidPic, $pic_expr);
#   &insertToPostgresTableAndHistory('pic_paper', $newPgidPic, $pic_paper);		# Daniela doesn't want the paper
  &insertToPostgresTableAndHistory('pic_description', $newPgidPic, $pic_description);
  &insertToPostgresTableAndHistory('pic_remark', $newPgidPic, $pic_remark);
  &insertToPostgresTableAndHistory('pic_curator', $newPgidPic, $pic_curator);
  &insertToPostgresTableAndHistory('pic_contact', $newPgidPic, $pic_contact);
  &insertToPostgresTableAndHistory('pic_person', $newPgidPic, $pic_person);
} # sub createImage

sub insertToPostgresTableAndHistory {           # to create new rows, it is easier to have this sub in multiple <mod>OA.pm files than change the database in the helperOA.pm
  my ($table, $joinkey, $newValue) = @_;
  my $returnValue = '';
  $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
  print "INSERT INTO $table VALUES ('$joinkey', '$newValue');\n" ;
# UNCOMMENT TO POPULATE
#   $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
  $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
  print "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue');\n" ;
# UNCOMMENT TO POPULATE
#   $result->execute() or $returnValue .= "ERROR, failed to insert to ${table}_hst &insertToPostgresTableAndHistory\n";
} # sub insertToPostgresTableAndHistory

sub getHighestExprId {          # look at all exp_name, get the highest number and return
  my $highest = 0;
  $result = $dbh->prepare( "SELECT exp_name FROM exp_name WHERE exp_name ~ '^Expr'" ); $result->execute();
  while (my @row = $result->fetchrow()) { if ($row[0]) { $row[0] =~ s/Expr//; if ($row[0] > $highest) { $highest = $row[0]; } } }
  return $highest; }

sub getHighestPgid {                                    # get the highest joinkey from the primary tables
#   ($var, my $datatype) = &getHtmlVar($query, 'datatype');
  my ($datatype) = @_;
  if ($datatypes{$datatype}{highestPgidTables}) {
      my $pgUnionQuery = "SELECT MAX(joinkey::integer) FROM ${datatype}_" . join" UNION SELECT MAX(joinkey::integer) FROM ${datatype}_", @{ $datatypes{$datatype}{highestPgidTables} };
      $result = $dbh->prepare( "SELECT max(max) FROM ( $pgUnionQuery ) AS max; " );
      $result->execute(); my @row = $result->fetchrow(); my $highest = $row[0];
      return $highest; }
    else { return "ERROR, no valid datatype for highestPgidTables"; }
} # sub getHighestPgid

sub getGenericOntology {
  my ($datatype, $word) = @_;
  my @matches; my $match = '';
  my @types = qw( name syn );
  foreach my $type (@types) {
    my $table = 'obo_' . $type . '_' . $datatype;
    $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) = '$word' ORDER BY $table;" );
    $result->execute();
    while (my @row = $result->fetchrow()) { push @matches, "$row[0]"; } }
  if (scalar @matches > 0) {
    $match = join'","', @matches; $match = '"' . $match . '"'; }
  return $match;
} # sub getGenericOntology

sub getWBGene {
  my ($words) = @_;
  my @tables = qw( gin_locus gin_synonyms gin_seqname gin_wbgene );
  my @matches; my $match = '';
  ($words) = lc($words);
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM $table WHERE LOWER($table) = '$words' ORDER BY $table;" );
    $result->execute();
    while (my @row = $result->fetchrow()) { push @matches, "WBGene$row[0]"; } }
  if (scalar @matches > 0) {
    $match = join'","', @matches; $match = '"' . $match . '"'; }
  return $match;
} # sub getWBGene

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


__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

exp_name -> from the last unused one
exp_paper -> WBPaper00040230
exp_curator -> WBPerson12028
exp_exprtype -> "Reporter_gene"
exp_gene -> exp_gene
exp_clone -> exp_clone
exp_strain -> exp_strain
exp_reportergene  -> exp_reportergene
exp_pattern -> exp_pattern

pic_name  -> from the last unused one
pic_source -> image 1 to 6, generate a WBPicture Object for each separate image, and attach to Expr for that file line.
pic_exprpattern -> once we know the Exp_pattern ID we will put that in
pic_paper  -> WBPaper00040230
pic_contact -> Ian Hope (WBPerson266 ) 
pic_person -> Ian Hope (WBPerson266 ) 
pic_curator -> Daniela Raciti ( WBPerson12028 ) 


DELETE FROM exp_name WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_paper WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_curator WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_gene WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_clone WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_strain WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_reportergene  WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_pattern WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_exprtype WHERE exp_timestamp > '2012-10-01 20:35';

DELETE FROM pic_name WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_source WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_exprpattern WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_paper  WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_contact WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_person WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_curator WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_description WHERE pic_timestamp > '2012-10-01 20:35';

DELETE FROM exp_name_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_paper_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_curator_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_gene_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_clone_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_strain_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_reportergene _hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_pattern_hst WHERE exp_timestamp > '2012-10-01 20:35';
DELETE FROM exp_exprtype_hst WHERE exp_timestamp > '2012-10-01 20:35';

DELETE FROM pic_name_hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_source_hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_exprpattern_hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_paper _hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_contact_hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_person_hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_curator_hst WHERE pic_timestamp > '2012-10-01 20:35';
DELETE FROM pic_description_hst WHERE pic_timestamp > '2012-10-01 20:35';

# not creating these anymore  2012 09 20
# after creating pg table :
# DELETE FROM exp_dnatext_hst WHERE exp_timestamp > '2012-10-01 20:35';
# DELETE FROM exp_dnatext WHERE exp_timestamp > '2012-10-01 20:35';
