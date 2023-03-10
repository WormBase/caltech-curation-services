#!/usr/bin/perl -w

# populate ian hope expr data.  2012 01 10
# populated live 2012 01 13

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my %datatypes;
@{ $datatypes{exp}{highestPgidTables} }            = qw( name curator );
@{ $datatypes{pic}{highestPgidTables} }            = qw( name curator );

my $exp_paper = '"WBPaper00040230"';
my $exp_curator = 'WBPerson12028';
my $exp_exprtype = '"Reporter_gene"';
my $pic_paper = 'WBPaper00040230';
my $pic_curator = 'WBPerson12028';
my $pic_contact = '"WBPerson266"'; 
my $pic_person = '"WBPerson266"'; 
my $pic_remark = 'Feng H et al. (2012) Methods Mol Biol "Expression Pattern Analysis of Regulatory Transcription Factors in ...."';

my ($newPgidExp) = &getHighestPgid('exp');			# current highest pgid (joinkey)
my ($newPgidPic) = &getHighestPgid('pic');			# current highest pgid (joinkey)
my ($newExprId) = &getHighestExprId(); 

my $infile = 'ExperimentDetailsIanHope.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $junk1 = <IN>; my $junk2 = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($exp_gene, $junk, $exp_clone, $exp_strain, $exp_reportergene, $exp_pattern, $im1, $im2, $im3, $im4, $im5, $im6) = split/\t/, $line;
  $newPgidExp++;
  $newExprId++;
  &insertToPostgresTableAndHistory('exp_name', $newPgidExp, "Expr$newExprId");
  &insertToPostgresTableAndHistory('exp_paper', $newPgidExp, $exp_paper);
  &insertToPostgresTableAndHistory('exp_curator', $newPgidExp, $exp_curator);
  &insertToPostgresTableAndHistory('exp_exprtype', $newPgidExp, $exp_exprtype);
  if ($exp_gene) {
    my $wbgene = &getWBGene($exp_gene); 
    if ($wbgene) {
        if ($wbgene =~ m/,/) { print "ERROR $exp_gene maps to $wbgene\n"; }
          else { &insertToPostgresTableAndHistory('exp_gene', $newPgidExp, $wbgene); } }
      else { print "ERR NO GENE FOR $exp_gene\n"; } }
  if ($exp_clone) {
    my $clone = &getGenericOntology('clone', $exp_clone); 
    if ($clone) {
        if ($clone =~ m/,/) { print "ERROR $exp_clone maps to $clone\n"; }
          else { &insertToPostgresTableAndHistory('exp_clone', $newPgidExp, $clone); } }
      else {
#         print "ERR NO CLONE FOR $exp_clone\n"; 
        $exp_clone = '"'. $exp_clone . '"';
        &insertToPostgresTableAndHistory('exp_clone', $newPgidExp, $exp_clone); } }
  if ($exp_strain) {
    my $strain = &getGenericOntology('strain', $exp_strain); 
    if ($strain) {
        if ($strain =~ m/,/) { print "ERROR $exp_strain maps to $strain\n"; }
          else { &insertToPostgresTableAndHistory('exp_strain', $newPgidExp, $strain); } }
      else { 
#         print "ERR NO STRAIN FOR $exp_strain\n"; 
        $exp_strain = '"'. $exp_strain . '"';
        &insertToPostgresTableAndHistory('exp_strain', $newPgidExp, $exp_strain); } }
  if ($exp_reportergene) { 
    $exp_reportergene =~ s/^"//; $exp_reportergene =~ s/"$//;
    if ($exp_reportergene =~ m/\'/) { $exp_reportergene =~ s/\'/''/g; }
    &insertToPostgresTableAndHistory('exp_reportergene', $newPgidExp, $exp_reportergene); }
  if ($exp_pattern) { 
    $exp_pattern =~ s/^"//; $exp_pattern =~ s/"$//;
    if ($exp_pattern =~ m/\'/) { $exp_pattern =~ s/\'/''/g; }
    &insertToPostgresTableAndHistory('exp_pattern', $newPgidExp, $exp_pattern); }
  if ($im1) { &createImage($im1, "Expr$newExprId"); }
  if ($im2) { &createImage($im2, "Expr$newExprId"); }
  if ($im3) { &createImage($im3, "Expr$newExprId"); }
  if ($im4) { &createImage($im4, "Expr$newExprId"); }
  if ($im5) { &createImage($im5, "Expr$newExprId"); }
  if ($im6) { &createImage($im6, "Expr$newExprId"); }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

sub createImage {
  my ($pic_source, $pic_expr) = @_;
  $newPgidPic++;
  my $picId = &pad10Zeros($newPgidPic);
  $pic_expr = '"' . $pic_expr . '"';
  &insertToPostgresTableAndHistory('pic_name', $newPgidPic, "WBPicture$picId");
  &insertToPostgresTableAndHistory('pic_source', $newPgidPic, $pic_source);
  &insertToPostgresTableAndHistory('pic_exprpattern', $newPgidPic, $pic_expr);
#   &insertToPostgresTableAndHistory('pic_paper', $newPgidPic, $pic_paper);
  &insertToPostgresTableAndHistory('pic_remark', $newPgidPic, $pic_remark);
  &insertToPostgresTableAndHistory('pic_curator', $newPgidPic, $pic_curator);
  &insertToPostgresTableAndHistory('pic_contact', $newPgidPic, $pic_contact);
  &insertToPostgresTableAndHistory('pic_person', $newPgidPic, $pic_person);
} # sub createImage

sub insertToPostgresTableAndHistory {           # to create new rows, it is easier to have this sub in multiple <mod>OA.pm files than change the database in the helperOA.pm
  my ($table, $joinkey, $newValue) = @_;
  my $returnValue = '';
  $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
  print "INSERT INTO $table VALUES ('$joinkey', '$newValue')\n" ;
# UNCOMMENT TO POPULATE
#   $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
  $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
  print "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')\n" ;
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


DELETE FROM exp_name WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_paper WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_curator WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_gene WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_clone WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_strain WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_reportergene  WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_pattern WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_exprtype WHERE exp_timestamp > '2012-01-13 00:01';

DELETE FROM pic_name WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_source WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_exprpattern WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_paper  WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_contact WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_person WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_curator WHERE pic_timestamp > '2012-01-13 00:01';

DELETE FROM exp_name_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_paper_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_curator_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_gene_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_clone_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_strain_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_reportergene _hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_pattern_hst WHERE exp_timestamp > '2012-01-13 00:01';
DELETE FROM exp_exprtype_hst WHERE exp_timestamp > '2012-01-13 00:01';

DELETE FROM pic_name_hst WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_source_hst WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_exprpattern_hst WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_paper _hst WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_contact_hst WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_person_hst WHERE pic_timestamp > '2012-01-13 00:01';
DELETE FROM pic_curator_hst WHERE pic_timestamp > '2012-01-13 00:01';
