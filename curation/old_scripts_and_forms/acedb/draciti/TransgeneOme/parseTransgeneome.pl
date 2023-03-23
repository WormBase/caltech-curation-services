#!/usr/bin/perl

# parse transgeneOme json data for Daniela  2016 03 24
#
# added full json data url.  2016 08 31
#
# try to merge duplicates, concatenate ids.  add construct.  add reference.  add expr_ to pictures.  2016 09 02
#
# merge on strain+constr key, not full entry.  2016 09 06

use strict;
use JSON;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;



my $json = JSON->new->allow_nonref;

my $jsonUrl = 'https://transgeneome.mpi-cbg.de/transgeneomics/api/imagingData.json';
my $filedata = get $jsonUrl;

my $date = &getSimpleDate();
my $outfile = 'transgeneome_' . $date;
my $errfile = 'err_transgeneome_' . $date;

open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
open (ERR, ">$errfile") or die "Cannot open $errfile : $!";

# my $infile = 'imagingData.json.WBGene00023497';
# $/ = undef;
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# my $filedata = <IN>;
# close (IN) or die "Cannot close $infile : $!";

my $perl_scalar = $json->decode( $filedata );

my @entries = @{ $perl_scalar };

my %transgeneIdFromName;
$result = $dbh->prepare( "SELECT trp_name.trp_name, trp_publicname.trp_publicname FROM trp_name, trp_publicname WHERE trp_name.joinkey = trp_publicname.joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $transgeneIdFromName{$row[1]} = $row[0]; } }

my %strainMapping;
$result = $dbh->prepare( "SELECT * FROM obo_name_strain;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $strainMapping{$row[1]} = $row[0]; } }

# temporary strain mappings to get to upload that aren't in postgres yet.  2019 09 26
$strainMapping{"TRG_1393"} = "WBStrain00047013";
$strainMapping{"TRG_1506"} = "WBStrain00047014";
$strainMapping{"TRG_1507"} = "WBStrain00047015";
$strainMapping{"TRG_1512"} = "WBStrain00047016";
$strainMapping{"TRG_1513"} = "WBStrain00047017";
$strainMapping{"TRG_1514"} = "WBStrain00047018";
$strainMapping{"TRG_1515"} = "WBStrain00047019";
$strainMapping{"TRG_1516"} = "WBStrain00047020";
$strainMapping{"TRG_1517"} = "WBStrain00047021";
$strainMapping{"TRG_1518"} = "WBStrain00047022";
$strainMapping{"TRG_1519"} = "WBStrain00047023";
$strainMapping{"OS7926"}   = "WBStrain00047024";
$strainMapping{"OS7161"}   = "WBStrain00047025";
$strainMapping{"TRG_1420"} = "WBStrain00047026";
$strainMapping{"TRG_1215"} = "WBStrain00047027";
$strainMapping{"TRG_1206"} = "WBStrain00047028";
$strainMapping{"TRG1537"}  = "WBStrain00047029";
$strainMapping{"TRG_1261"} = "WBStrain00047030";
$strainMapping{"TRG_1195"} = "WBStrain00047031";
$strainMapping{"TRG_1403"} = "WBStrain00047032";
$strainMapping{"TRG_1179"} = "WBStrain00047033";
$strainMapping{"TRG1538"}  = "WBStrain00047034";
$strainMapping{"TRG_1184"} = "WBStrain00047035";
$strainMapping{"OP392"}    = "WBStrain00047036";
$strainMapping{"OP393"}    = "WBStrain00047037";
$strainMapping{"OP391"}    = "WBStrain00047038";
$strainMapping{"TRG_1269"} = "WBStrain00047039";
$strainMapping{"TRG_1399"} = "WBStrain00047040";
$strainMapping{"TRG_1400"} = "WBStrain00047041";
$strainMapping{"TRG1541"}  = "WBStrain00047042";
$strainMapping{"TRG_1185"} = "WBStrain00047043";
$strainMapping{"NFB672"}   = "WBStrain00047044";
$strainMapping{"SWG 107"}  = "WBStrain00047045";
$strainMapping{"NFB691"}   = "WBStrain00047046";
$strainMapping{"TRG_1187"} = "WBStrain00047047";


my %names;
my %expr_output;
my %exprData;
my %picData;
my %picIdToRemark;
my %picIdToExprId;

foreach my $entry( @entries) {
  my $id     = $$entry{id} || '';
  my $ls     = $$entry{lifeStageTerm}{termId}       || '';
  my $strain = $$entry{strain}{name}                || '';
  my $allele = $$entry{strain}{allele}              || '';
  my $constr = $$entry{strain}{well}{externalDbId}  || '';
  my $straincreatorFirstname = $$entry{strain}{creator}{firstName} || '';
  my $straincreatorLastname  = $$entry{strain}{creator}{lastName}  || '';
  my $straincreator          = qq($straincreatorFirstname $straincreatorLastname);
  my $personimagerFirstname  = $$entry{creator}{firstName} || '';
  my $personimagerLastname   = $$entry{creator}{lastName}  || '';
  my $personimager           = qq($personimagerFirstname $personimagerLastname);
  my $wbgene = '';
  my (@tags) = @{ $$entry{strain}{well}{selectedFeature}{tags} };
  foreach my $tag (@tags) {
    if ($$tag{field} eq 'identifier') { $wbgene = $$tag{value}; } }
  my %anats; my %goids; my %entryNames;
  my (@annots) = @{ $$entry{annotations} };
  if (scalar @annots > 0) {
    foreach my $annot (@annots) {
      my (@anatomyTerms) = @{ $$annot{anatomyTerms} };
      foreach my $anatomyTerm (@anatomyTerms) {
        my $anat = $$anatomyTerm{termId};
        $anats{$anat}++;
      } # foreach my $anatomyTerm (@anatomyTerms)
      my (@subCLTs) = @{ $$annot{subcellularLocalizationTerms} };
      foreach my $subCLT (@subCLTs) {
        my $goid = $$subCLT{termId};
        $goids{$goid}++;
      } # foreach my $subCLT (@subCLTs)
      my $firstn = $$annot{person}{firstName}  || '';
      my $lastn  = $$annot{person}{lastName}   || '';
      my $name   = qq($firstn $lastn);
      my @name   = (); if ($firstn) { push @name, $firstn; } if ($lastn) { push @name, $lastn; } my $name = join " ", @name;
      $names{$name}++;
      $entryNames{$name}++;
    } # foreach my $annot (@annots)
  }
  my $anats = join", ", sort keys %anats;
  my $goids = join", ", sort keys %goids;
  my $names = join", ", sort keys %entryNames;
  my %images;
  my (@imagingDCs) = @{ $$entry{imagingDataChannels} };
  if (scalar @imagingDCs > 0) {
    foreach my $imagingDC (@imagingDCs) {
      my ($imageID)     = $$imagingDC{id};
      my ($imageFile)   = $$imagingDC{filename};
      $images{$imageID} = $imageFile;
    }
  }
  my $images = join", ", sort values %images;
#   if ($names =~ m/,/) { print ERR qq(MULTIPLE NAMES $id : $names\n); }
#   print ERR qq(ID $id LS $ls ST $strain AL $allele GE $wbgene AN $anats GO $goids NM $names IMG $images\n);
# TODO  each image gets own picture id.  each wbgene gets own expr_pattern id, so track which was assigned for repeating wbgenes later. 
#   if ($wbgene eq 'WBGene00023497') {

  my $line = qq(Gene\t"$wbgene"\n);
  $exprData{$constr}{$strain}{data}{$line}++;
  $line = qq(DB_INFO\t"TransgeneOme" "gene" "$wbgene"\n);
  $exprData{$constr}{$strain}{data}{$line}++;
  $line = qq(Reflects_endogenous_expression_of\t"$wbgene"\n);
  $exprData{$constr}{$strain}{data}{$line}++;
  if ($allele) {
    if ($transgeneIdFromName{$allele}) { 
        my $line = qq(Transgene\t"$transgeneIdFromName{$allele}"\n); 
        $exprData{$constr}{$strain}{data}{$line}++; }
# Daniela doesn't want these anymore.  She wants them again 2019 09 26.  Not again 2019 11 15
      else {
#         $exprData{$constr}{$strain}{data}{$line}++; 
        print ERR qq(\/\/ Transgene\t"$allele"\t\/\/ BAD TRANSGENE\n); 
      } 
  }
  my @remarkSections;
  if ($straincreator) { push @remarkSections, qq(Strain generated by $straincreator); }
  if ($personimager)  { push @remarkSections, qq(image captured by $personimager);    }
  if ($names)         { push @remarkSections, qq(annotated by $names);                }
  if (scalar @remarkSections > 0) {
    my $line = join", ", @remarkSections;
    $line = qq(Remark\t"$line"\n);
    $picIdToRemark{$id} = $line;
# remark only in picture objects
#     $exprData{$constr}{$strain}{data}{$line}++; 
  }
  foreach my $anat (sort keys %anats) {
    if ($ls) { my $line = qq(Anatomy_term\t"$anat" Life_stage "$ls"\n); $exprData{$constr}{$strain}{data}{$line}++; }
      else {   my $line = qq(Anatomy_term\t"$anat"\n);       $exprData{$constr}{$strain}{data}{$line}++; } }
  foreach my $goid (sort keys %goids) {
    my $line = qq(GO_term\t"$goid"\n); $exprData{$constr}{$strain}{data}{$line}++; }
  $exprData{$constr}{$strain}{ids}{$id}++;

  foreach my $imageID (sort keys %images) {
    my $picFile = $images{$imageID};
    my ($picId) = $picFile =~ m/imagingdata-(\d+)/;
    $picData{$picId}{ids}{$id}++;
#     print OUT qq(Picture : "someID"\n);
#     print OUT qq(Expr_pattern\t"nnnn" \/\/ $id\n);
#     my ($picId) = $picFile =~ m/imagingdata-(\d+)/;
#     if ($picId) { print OUT qq(Name\t"trg_gallery_${picId}.jpg"\n); }
    foreach my $anat (sort keys %anats) {
      my $line = qq(Anatomy\t"$anat"\n); $picData{$picId}{data}{$line}++; }
    if ($ls) { my $line = qq(Life_stage\t"$ls"\n); $picData{$picId}{data}{$line}++; }
    foreach my $goid (sort keys %goids) {
      my $line = qq(Cellular_component\t"$goid"\n); $picData{$picId}{data}{$line}++; }
#     print OUT qq(\n);
  } # foreach my $imageID (sort keys %images)
#   } # if ($wbgene eq 'WBGene00023497')
} # foreach my $entry( @{ %jsonHash })

my $exprCounter = 1200000;
foreach my $constr (sort keys %exprData) {
  foreach my $strain (sort keys %{ $exprData{$constr} }) {
    my $ids = join", ", sort {$a<=>$b} keys %{ $exprData{$constr}{$strain}{ids} };
    $exprCounter++;
    foreach my $id (sort keys %{ $exprData{$constr}{$strain}{ids} }) { $picIdToExprId{$id} = qq(Expr$exprCounter); }
    print OUT qq(Expr_pattern : Expr$exprCounter \/\/ $ids\n);
    print OUT qq(Pattern\t"Data from the TransgeneOme project"\n);
    print OUT qq(Reporter_gene\n);
    if ($constr) { print OUT qq(Construct\t"$constr"\n); }
    if ($strain) { 
      if ($strainMapping{$strain}) {
          print OUT qq(Strain\t"$strainMapping{$strain}"\n);    }
        else { 
          print ERR qq(\/\/ BAD Strain\t"$strain"\n);    } 	# Daniela doesn't want these anymore 2019 11 15
    }
    print OUT qq(Reference\t"WBPaper00041419"\n);
    foreach my $line (sort keys %{ $exprData{$constr}{$strain}{data} }) { print OUT qq($line); }
    print OUT "\n";
  } # foreach my $strain (sort keys %{ $exprData{$constr} })
} # foreach my $constr (sort keys %exprData)

my $picCounter = 2000000;
foreach my $picId (sort keys %picData) {
  my $ids = join", ", sort {$a<=>$b} keys %{ $picData{$picId}{ids} };
  $picCounter++;
  print OUT qq(Picture : WBPicture000$picCounter\n);
  print OUT qq(Contact\t"WBPerson3853"\n);
  print OUT qq(Person_name\t"Mihail Sarov"\n);
  print OUT qq(Name\t"trg_gallery_${picId}.jpg"\n); 
  print OUT qq($picIdToRemark{$ids}); 
  print OUT qq(Expr_pattern\t"$picIdToExprId{$ids}" \/\/ $ids\n);
  foreach my $line (sort keys %{ $picData{$picId}{data} }) { print OUT qq($line); }
  print OUT "\n";
} # foreach my $picId (sort keys %picData)


close (ERR) or die "Cannot close $errfile : $!";
close (OUT) or die "Cannot close $outfile : $!";



# old way hashing full entries
#   foreach my $entry (sort keys %expr_output) {
#     my $ids = join" + ", sort keys %{ $expr_output{$entry} };
#     print qq(Expr_pattern : "nnnn" \/\/ $ids\nReference\t"WBPaper00041419"\n$entry);
#   } # foreach my $entry (sort keys %expr_output)
    

# foreach my $name (sort {$names{$a}<=>$names{$b}} keys %names) { print qq(NAME $name\t$names{$name}\n); }

# Expr_pattern : "nnnn" // 45639867
# WBGene  "WBGene00001061"
# Strain  "OP365"
# Transgene       "WBTransgene00017369"
# 
# Expr_pattern : "nnnn" // 45639871
# WBGene  "WBGene00001061"
# Strain  "OP365"
# Transgene       "WBTransgene00017369"



__END__

