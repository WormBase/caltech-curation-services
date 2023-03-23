#!/usr/bin/perl

# parse yanai data to .ace for Daniela, based on her instructions below.  2014 12 03

use strict;

my $expnum = '1050000';
my $picnum = '1030253';

my $orthoyes = << "EndOfText";
Description	"A) Embryonic gene expression profile"
Description	"B) Comparative gene expression profiles for the orthologous group"
Description	"red=C. remanei"
Description	"green=C. briggsae"
Description	"blue=C. brenneri"
Description	"yellow=C. elegans"
Description	"pink=C. japonica"
Description	"For additional information: yanailab.technion.ac.il"
EndOfText

my $orthono = << "EndOfText";
Description	"A) Embryonic gene expression profile"
Description	"For additional information: yanailab.technion.ac.il"
EndOfText

my $microarray = << "EndOfText";
Microarray	"WBPaper00041190:C.remanei_rep1_stage1"
Microarray	"WBPaper00041190:C.remanei_rep1_stage2"
Microarray	"WBPaper00041190:C.remanei_rep1_stage3"
Microarray	"WBPaper00041190:C.remanei_rep1_stage4"
Microarray	"WBPaper00041190:C.remanei_rep1_stage5"
Microarray	"WBPaper00041190:C.remanei_rep1_stage6"
Microarray	"WBPaper00041190:C.remanei_rep1_stage7"
Microarray	"WBPaper00041190:C.remanei_rep1_stage8"
Microarray	"WBPaper00041190:C.remanei_rep1_stage9"
Microarray	"WBPaper00041190:C.remanei_rep1_stage10"
Microarray	"WBPaper00041190:C.remanei_rep2_stage1"
Microarray	"WBPaper00041190:C.remanei_rep2_stage2"
Microarray	"WBPaper00041190:C.remanei_rep2_stage3"
Microarray	"WBPaper00041190:C.remanei_rep2_stage4"
Microarray	"WBPaper00041190:C.remanei_rep2_stage5"
Microarray	"WBPaper00041190:C.remanei_rep2_stage6"
Microarray	"WBPaper00041190:C.remanei_rep2_stage7"
Microarray	"WBPaper00041190:C.remanei_rep2_stage8"
Microarray	"WBPaper00041190:C.remanei_rep2_stage9"
Microarray	"WBPaper00041190:C.remanei_rep2_stage10"
Microarray	"WBPaper00041190:C.remanei_rep3_stage1"
Microarray	"WBPaper00041190:C.remanei_rep3_stage2"
Microarray	"WBPaper00041190:C.remanei_rep3_stage3"
Microarray	"WBPaper00041190:C.remanei_rep3_stage4"
Microarray	"WBPaper00041190:C.remanei_rep3_stage5"
Microarray	"WBPaper00041190:C.remanei_rep3_stage6"
Microarray	"WBPaper00041190:C.remanei_rep3_stage7"
Microarray	"WBPaper00041190:C.remanei_rep3_stage8"
Microarray	"WBPaper00041190:C.remanei_rep3_stage9"
Microarray	"WBPaper00041190:C.remanei_rep3_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage10"
Microarray	"WBPaper00041190:C.elegans_rep1_stage1"
Microarray	"WBPaper00041190:C.elegans_rep1_stage2"
Microarray	"WBPaper00041190:C.elegans_rep1_stage3"
Microarray	"WBPaper00041190:C.elegans_rep1_stage4"
Microarray	"WBPaper00041190:C.elegans_rep1_stage5"
Microarray	"WBPaper00041190:C.elegans_rep1_stage6"
Microarray	"WBPaper00041190:C.elegans_rep1_stage7"
Microarray	"WBPaper00041190:C.elegans_rep1_stage8"
Microarray	"WBPaper00041190:C.elegans_rep1_stage9"
Microarray	"WBPaper00041190:C.elegans_rep1_stage10"
Microarray	"WBPaper00041190:C.elegans_rep2_stage1"
Microarray	"WBPaper00041190:C.elegans_rep2_stage2"
Microarray	"WBPaper00041190:C.elegans_rep2_stage3"
Microarray	"WBPaper00041190:C.elegans_rep2_stage4"
Microarray	"WBPaper00041190:C.elegans_rep2_stage5"
Microarray	"WBPaper00041190:C.elegans_rep2_stage6"
Microarray	"WBPaper00041190:C.elegans_rep2_stage7"
Microarray	"WBPaper00041190:C.elegans_rep2_stage8"
Microarray	"WBPaper00041190:C.elegans_rep2_stage9"
Microarray	"WBPaper00041190:C.elegans_rep2_stage10"
Microarray	"WBPaper00041190:C.elegans_rep3_stage1"
Microarray	"WBPaper00041190:C.elegans_rep3_stage2"
Microarray	"WBPaper00041190:C.elegans_rep3_stage3"
Microarray	"WBPaper00041190:C.elegans_rep3_stage4"
Microarray	"WBPaper00041190:C.elegans_rep3_stage5"
Microarray	"WBPaper00041190:C.elegans_rep3_stage6"
Microarray	"WBPaper00041190:C.elegans_rep3_stage7"
Microarray	"WBPaper00041190:C.elegans_rep3_stage8"
Microarray	"WBPaper00041190:C.elegans_rep3_stage9"
Microarray	"WBPaper00041190:C.elegans_rep3_stage10"
Microarray	"WBPaper00041190:C.japonica_rep1_stage1"
Microarray	"WBPaper00041190:C.japonica_rep1_stage2"
Microarray	"WBPaper00041190:C.japonica_rep1_stage3"
Microarray	"WBPaper00041190:C.japonica_rep1_stage4"
Microarray	"WBPaper00041190:C.japonica_rep1_stage5"
Microarray	"WBPaper00041190:C.japonica_rep1_stage6"
Microarray	"WBPaper00041190:C.japonica_rep1_stage7"
Microarray	"WBPaper00041190:C.japonica_rep1_stage8"
Microarray	"WBPaper00041190:C.japonica_rep1_stage9"
Microarray	"WBPaper00041190:C.japonica_rep1_stage10"
Microarray	"WBPaper00041190:C.japonica_rep2_stage1"
Microarray	"WBPaper00041190:C.japonica_rep2_stage2"
Microarray	"WBPaper00041190:C.japonica_rep2_stage3"
Microarray	"WBPaper00041190:C.japonica_rep2_stage4"
Microarray	"WBPaper00041190:C.japonica_rep2_stage5"
Microarray	"WBPaper00041190:C.japonica_rep2_stage6"
Microarray	"WBPaper00041190:C.japonica_rep2_stage7"
Microarray	"WBPaper00041190:C.japonica_rep2_stage8"
Microarray	"WBPaper00041190:C.japonica_rep2_stage9"
Microarray	"WBPaper00041190:C.japonica_rep2_stage10"
Microarray	"WBPaper00041190:C.japonica_rep3_stage1"
Microarray	"WBPaper00041190:C.japonica_rep3_stage2"
Microarray	"WBPaper00041190:C.japonica_rep3_stage3"
Microarray	"WBPaper00041190:C.japonica_rep3_stage4"
Microarray	"WBPaper00041190:C.japonica_rep3_stage5"
Microarray	"WBPaper00041190:C.japonica_rep3_stage6"
Microarray	"WBPaper00041190:C.japonica_rep3_stage7"
Microarray	"WBPaper00041190:C.japonica_rep3_stage8"
Microarray	"WBPaper00041190:C.japonica_rep3_stage9"
Microarray	"WBPaper00041190:C.japonica_rep3_stage10"
EndOfText

my %probeToMicro;
my $microfile = 'Microarray_results.ace';
$/ = "";
open (IN, "<$microfile") or die "Cannot open $microfile : $!";
while (my $entry = <IN>) {
  my ($name) = $entry =~ m/Microarray_results : \"(.*?)\"/;
  my ($micro) = $entry =~ m/Microarray\t \"(.*?)\"/;
  if ($name =~ m/^${micro}_(.*?)$/) { $probeToMicro{$1} = $name; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $microfile : $!";
$/ = "\n";

my @species = qw( briggsae japonica remanei );
foreach my $species (@species) {
  my $infile = 'EvoDevomics_data_' . $species . '_Wormbase.txt';
  my $picfile = 'pictures_' . $species . '.ace';
  my $exprfile = 'expr_' . $species . '.ace';
  open (EXP, ">$exprfile") or die "Cannot open $exprfile : $!";
  open (PIC, ">$picfile")  or die "Cannot open $picfile : $!";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($gene, $name, $probe, $seq, $ortholog) = split/\t/, $line;
    next unless ($gene =~ m/WBGene\d+/);
    my $expr = 'Expr' . $expnum; $expnum++;
    my $pic  = 'WBPicture000' . $picnum; $picnum++;

    my $pattern = 'Developmental gene expression time-course.  Raw data can be downloaded from ftp:\/\/caltech.wormbase.org\/pub\/wormbase\/datasets-published\/levin2012';
    my $paper = 'WBPaper00041190';
    my $microarray_results = "no match for $probe";
    if ($probeToMicro{$probe}) { $microarray_results = $probeToMicro{$probe} . ', ' . $gene; }
    my $remark = $name . ', ' . $seq . ', ' . $gene;
    print EXP qq(Expr_pattern : "$expr"\n);
    print EXP qq(Pattern\t"$pattern"\n);
    print EXP qq(Reference\t"$paper"\n);
    print EXP qq(Remark\t"$remark"\n);
    print EXP qq(Species\t"Caenorhabditis $species"\n);
    print EXP qq(Microarray_results\t"$microarray_results"\n);
    print EXP qq($microarray);
    print EXP qq(\n);

    print PIC qq(Picture : "$pic"\n);
    print PIC qq(Name\t"Wormbase_${gene}.jpg"\n);
    print PIC qq(Remark\t"Levin M et al. (2012) Dev Cell \"Developmental milestones punctuate gene expression in the caenorhabditis ....\""\n);
    print PIC qq(Expr_pattern\t"$expr"\n);
    print PIC qq(Template\t"$expr"\n);
    print PIC qq(Template\t"WormBase thanks <Person_name> for providing the pictures."\n);
    print PIC qq(Contact\t"WBPerson4037"\n);
    print PIC qq(Person_name\t"Itai Yanai"\n);
    print PIC qq(Species\t"Caenorhabditis $species"\n);
    if ($ortholog eq 'yes') { print PIC qq($orthoyes); }
      elsif ($ortholog eq 'no') { print PIC qq($orthono); }
    print PIC qq(\n);
  } # while (my $line = <IN>)
  close (IN)  or die "Cannot close $infile : $!";
  close (EXP) or die "Cannot close $exprfile : $!";
  close (PIC) or die "Cannot close $picfile : $!";
} # foreach my $species (@species)


__END__

-rw-r--r-- 1 acedb acedb 2407978 Dec  3 12:59 EvoDevomics_data_briggsae_Wormbase.txt
-rw-r--r-- 1 acedb acedb 2564175 Dec  3 12:59 EvoDevomics_data_japonica_Wormbase.txt
-rw-r--r-- 1 acedb acedb 3031026 Dec  3 12:59 EvoDevomics_data_remanei_Wormbase.txt
-rw-r--r-- 1 acedb acedb   19274 Dec  3 12:59 Instructions_other species.txt
lrwxrwxrwx 1 acedb acedb      90 Dec  3 13:13 Microarray_results.ace -> /home2/acedb/draciti/Expr_pattern/Yanai_Instructions_other_species2/Microarray_results.ace



Expr from Expr1050000
Pictures from WBPicture0001030253 on

for Expression Pattern
Generate three .ace file

we have 3 species: briggsae, remanei and japonica
briggsae from EvoDevomics_data_briggsae_Wormbase.txt
Japonica from EvoDevomics_data_japonica_Wormbase.txt
remanei from EvoDevomics_data_remanei_Wormbase.txt


Expr_pattern : from Expr1050000 on
Pattern	"Developmental gene expression time-course.  Raw data can be downloaded from ftp:\/\/caltech.wormbase.org\/pub\/wormbase\/datasets-published\/levin2012" -> same for all
Reference	"WBPaper00041190" -> Same for all
Microarray_results	match column C of each .txt file with the Microarray_results.ace and put the Microarray_resultsID here  

example for the first gene in the EvoDevomics_data_briggsae_Wormbase.txt. WBGene00036350 has in column C CBG16402_1093-1152_0.849_1_B you have to look for that string in the Microarray_results.ace and get the corresponding Microarray_results. In this case "GPL14143_CBG16402_1093-1152_0.849_1_B" see below for .ace example

Remark "<ColumnB>, <ColumnD>, <ColumnA>"
Species "Caenorhabditis briggsae, Caenorhabditis japonica or Caenorhabditis remanei, according to the file"
Microarray	"WBPaper00041190:C.remanei_rep1_stage1"
Microarray	"WBPaper00041190:C.remanei_rep1_stage2"
Microarray	"WBPaper00041190:C.remanei_rep1_stage3"
Microarray	"WBPaper00041190:C.remanei_rep1_stage4"
Microarray	"WBPaper00041190:C.remanei_rep1_stage5"
Microarray	"WBPaper00041190:C.remanei_rep1_stage6"
Microarray	"WBPaper00041190:C.remanei_rep1_stage7"
Microarray	"WBPaper00041190:C.remanei_rep1_stage8"
Microarray	"WBPaper00041190:C.remanei_rep1_stage9"
Microarray	"WBPaper00041190:C.remanei_rep1_stage10"
Microarray	"WBPaper00041190:C.remanei_rep2_stage1"
Microarray	"WBPaper00041190:C.remanei_rep2_stage2"
Microarray	"WBPaper00041190:C.remanei_rep2_stage3"
Microarray	"WBPaper00041190:C.remanei_rep2_stage4"
Microarray	"WBPaper00041190:C.remanei_rep2_stage5"
Microarray	"WBPaper00041190:C.remanei_rep2_stage6"
Microarray	"WBPaper00041190:C.remanei_rep2_stage7"
Microarray	"WBPaper00041190:C.remanei_rep2_stage8"
Microarray	"WBPaper00041190:C.remanei_rep2_stage9"
Microarray	"WBPaper00041190:C.remanei_rep2_stage10"
Microarray	"WBPaper00041190:C.remanei_rep3_stage1"
Microarray	"WBPaper00041190:C.remanei_rep3_stage2"
Microarray	"WBPaper00041190:C.remanei_rep3_stage3"
Microarray	"WBPaper00041190:C.remanei_rep3_stage4"
Microarray	"WBPaper00041190:C.remanei_rep3_stage5"
Microarray	"WBPaper00041190:C.remanei_rep3_stage6"
Microarray	"WBPaper00041190:C.remanei_rep3_stage7"
Microarray	"WBPaper00041190:C.remanei_rep3_stage8"
Microarray	"WBPaper00041190:C.remanei_rep3_stage9"
Microarray	"WBPaper00041190:C.remanei_rep3_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage10"
Microarray	"WBPaper00041190:C.elegans_rep1_stage1"
Microarray	"WBPaper00041190:C.elegans_rep1_stage2"
Microarray	"WBPaper00041190:C.elegans_rep1_stage3"
Microarray	"WBPaper00041190:C.elegans_rep1_stage4"
Microarray	"WBPaper00041190:C.elegans_rep1_stage5"
Microarray	"WBPaper00041190:C.elegans_rep1_stage6"
Microarray	"WBPaper00041190:C.elegans_rep1_stage7"
Microarray	"WBPaper00041190:C.elegans_rep1_stage8"
Microarray	"WBPaper00041190:C.elegans_rep1_stage9"
Microarray	"WBPaper00041190:C.elegans_rep1_stage10"
Microarray	"WBPaper00041190:C.elegans_rep2_stage1"
Microarray	"WBPaper00041190:C.elegans_rep2_stage2"
Microarray	"WBPaper00041190:C.elegans_rep2_stage3"
Microarray	"WBPaper00041190:C.elegans_rep2_stage4"
Microarray	"WBPaper00041190:C.elegans_rep2_stage5"
Microarray	"WBPaper00041190:C.elegans_rep2_stage6"
Microarray	"WBPaper00041190:C.elegans_rep2_stage7"
Microarray	"WBPaper00041190:C.elegans_rep2_stage8"
Microarray	"WBPaper00041190:C.elegans_rep2_stage9"
Microarray	"WBPaper00041190:C.elegans_rep2_stage10"
Microarray	"WBPaper00041190:C.elegans_rep3_stage1"
Microarray	"WBPaper00041190:C.elegans_rep3_stage2"
Microarray	"WBPaper00041190:C.elegans_rep3_stage3"
Microarray	"WBPaper00041190:C.elegans_rep3_stage4"
Microarray	"WBPaper00041190:C.elegans_rep3_stage5"
Microarray	"WBPaper00041190:C.elegans_rep3_stage6"
Microarray	"WBPaper00041190:C.elegans_rep3_stage7"
Microarray	"WBPaper00041190:C.elegans_rep3_stage8"
Microarray	"WBPaper00041190:C.elegans_rep3_stage9"
Microarray	"WBPaper00041190:C.elegans_rep3_stage10"
Microarray	"WBPaper00041190:C.japonica_rep1_stage1"
Microarray	"WBPaper00041190:C.japonica_rep1_stage2"
Microarray	"WBPaper00041190:C.japonica_rep1_stage3"
Microarray	"WBPaper00041190:C.japonica_rep1_stage4"
Microarray	"WBPaper00041190:C.japonica_rep1_stage5"
Microarray	"WBPaper00041190:C.japonica_rep1_stage6"
Microarray	"WBPaper00041190:C.japonica_rep1_stage7"
Microarray	"WBPaper00041190:C.japonica_rep1_stage8"
Microarray	"WBPaper00041190:C.japonica_rep1_stage9"
Microarray	"WBPaper00041190:C.japonica_rep1_stage10"
Microarray	"WBPaper00041190:C.japonica_rep2_stage1"
Microarray	"WBPaper00041190:C.japonica_rep2_stage2"
Microarray	"WBPaper00041190:C.japonica_rep2_stage3"
Microarray	"WBPaper00041190:C.japonica_rep2_stage4"
Microarray	"WBPaper00041190:C.japonica_rep2_stage5"
Microarray	"WBPaper00041190:C.japonica_rep2_stage6"
Microarray	"WBPaper00041190:C.japonica_rep2_stage7"
Microarray	"WBPaper00041190:C.japonica_rep2_stage8"
Microarray	"WBPaper00041190:C.japonica_rep2_stage9"
Microarray	"WBPaper00041190:C.japonica_rep2_stage10"
Microarray	"WBPaper00041190:C.japonica_rep3_stage1"
Microarray	"WBPaper00041190:C.japonica_rep3_stage2"
Microarray	"WBPaper00041190:C.japonica_rep3_stage3"
Microarray	"WBPaper00041190:C.japonica_rep3_stage4"
Microarray	"WBPaper00041190:C.japonica_rep3_stage5"
Microarray	"WBPaper00041190:C.japonica_rep3_stage6"
Microarray	"WBPaper00041190:C.japonica_rep3_stage7"
Microarray	"WBPaper00041190:C.japonica_rep3_stage8"
Microarray	"WBPaper00041190:C.japonica_rep3_stage9"
Microarray	"WBPaper00041190:C.japonica_rep3_stage10"

The Microarray lines are the same for all objects

the ace file should look like this

Expr_pattern : "Expr1050000"
Pattern	"Developmental gene expression time-course.  Raw data can be downloaded from ftp:\/\/caltech.wormbase.org\/pub\/wormbase\/datasets-published\/levin2012"
Reference	"WBPaper00041190"
Microarray_results	"GPL14143_CBG16402_1093-1152_0.849_1_B, WBGene00036350"
Remark	"CBG16402, CTTTCCGATCCCTACTGGTGCCAAGAATATGTGCAAATCTATTTAAGTTCCCGTCAACAA"
Species "Caenorhabditis briggsae"
Microarray	"WBPaper00041190:C.remanei_rep1_stage1"
Microarray	"WBPaper00041190:C.remanei_rep1_stage2"
Microarray	"WBPaper00041190:C.remanei_rep1_stage3"
Microarray	"WBPaper00041190:C.remanei_rep1_stage4"
Microarray	"WBPaper00041190:C.remanei_rep1_stage5"
Microarray	"WBPaper00041190:C.remanei_rep1_stage6"
Microarray	"WBPaper00041190:C.remanei_rep1_stage7"
Microarray	"WBPaper00041190:C.remanei_rep1_stage8"
Microarray	"WBPaper00041190:C.remanei_rep1_stage9"
Microarray	"WBPaper00041190:C.remanei_rep1_stage10"
Microarray	"WBPaper00041190:C.remanei_rep2_stage1"
Microarray	"WBPaper00041190:C.remanei_rep2_stage2"
Microarray	"WBPaper00041190:C.remanei_rep2_stage3"
Microarray	"WBPaper00041190:C.remanei_rep2_stage4"
Microarray	"WBPaper00041190:C.remanei_rep2_stage5"
Microarray	"WBPaper00041190:C.remanei_rep2_stage6"
Microarray	"WBPaper00041190:C.remanei_rep2_stage7"
Microarray	"WBPaper00041190:C.remanei_rep2_stage8"
Microarray	"WBPaper00041190:C.remanei_rep2_stage9"
Microarray	"WBPaper00041190:C.remanei_rep2_stage10"
Microarray	"WBPaper00041190:C.remanei_rep3_stage1"
Microarray	"WBPaper00041190:C.remanei_rep3_stage2"
Microarray	"WBPaper00041190:C.remanei_rep3_stage3"
Microarray	"WBPaper00041190:C.remanei_rep3_stage4"
Microarray	"WBPaper00041190:C.remanei_rep3_stage5"
Microarray	"WBPaper00041190:C.remanei_rep3_stage6"
Microarray	"WBPaper00041190:C.remanei_rep3_stage7"
Microarray	"WBPaper00041190:C.remanei_rep3_stage8"
Microarray	"WBPaper00041190:C.remanei_rep3_stage9"
Microarray	"WBPaper00041190:C.remanei_rep3_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep1_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep2_stage10"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage1"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage2"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage3"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage4"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage5"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage6"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage7"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage8"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage9"
Microarray	"WBPaper00041190:C.briggsae_rep3_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep1_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep2_stage10"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage1"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage2"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage3"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage4"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage5"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage6"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage7"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage8"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage9"
Microarray	"WBPaper00041190:C.brenneri_rep3_stage10"
Microarray	"WBPaper00041190:C.elegans_rep1_stage1"
Microarray	"WBPaper00041190:C.elegans_rep1_stage2"
Microarray	"WBPaper00041190:C.elegans_rep1_stage3"
Microarray	"WBPaper00041190:C.elegans_rep1_stage4"
Microarray	"WBPaper00041190:C.elegans_rep1_stage5"
Microarray	"WBPaper00041190:C.elegans_rep1_stage6"
Microarray	"WBPaper00041190:C.elegans_rep1_stage7"
Microarray	"WBPaper00041190:C.elegans_rep1_stage8"
Microarray	"WBPaper00041190:C.elegans_rep1_stage9"
Microarray	"WBPaper00041190:C.elegans_rep1_stage10"
Microarray	"WBPaper00041190:C.elegans_rep2_stage1"
Microarray	"WBPaper00041190:C.elegans_rep2_stage2"
Microarray	"WBPaper00041190:C.elegans_rep2_stage3"
Microarray	"WBPaper00041190:C.elegans_rep2_stage4"
Microarray	"WBPaper00041190:C.elegans_rep2_stage5"
Microarray	"WBPaper00041190:C.elegans_rep2_stage6"
Microarray	"WBPaper00041190:C.elegans_rep2_stage7"
Microarray	"WBPaper00041190:C.elegans_rep2_stage8"
Microarray	"WBPaper00041190:C.elegans_rep2_stage9"
Microarray	"WBPaper00041190:C.elegans_rep2_stage10"
Microarray	"WBPaper00041190:C.elegans_rep3_stage1"
Microarray	"WBPaper00041190:C.elegans_rep3_stage2"
Microarray	"WBPaper00041190:C.elegans_rep3_stage3"
Microarray	"WBPaper00041190:C.elegans_rep3_stage4"
Microarray	"WBPaper00041190:C.elegans_rep3_stage5"
Microarray	"WBPaper00041190:C.elegans_rep3_stage6"
Microarray	"WBPaper00041190:C.elegans_rep3_stage7"
Microarray	"WBPaper00041190:C.elegans_rep3_stage8"
Microarray	"WBPaper00041190:C.elegans_rep3_stage9"
Microarray	"WBPaper00041190:C.elegans_rep3_stage10"
Microarray	"WBPaper00041190:C.japonica_rep1_stage1"
Microarray	"WBPaper00041190:C.japonica_rep1_stage2"
Microarray	"WBPaper00041190:C.japonica_rep1_stage3"
Microarray	"WBPaper00041190:C.japonica_rep1_stage4"
Microarray	"WBPaper00041190:C.japonica_rep1_stage5"
Microarray	"WBPaper00041190:C.japonica_rep1_stage6"
Microarray	"WBPaper00041190:C.japonica_rep1_stage7"
Microarray	"WBPaper00041190:C.japonica_rep1_stage8"
Microarray	"WBPaper00041190:C.japonica_rep1_stage9"
Microarray	"WBPaper00041190:C.japonica_rep1_stage10"
Microarray	"WBPaper00041190:C.japonica_rep2_stage1"
Microarray	"WBPaper00041190:C.japonica_rep2_stage2"
Microarray	"WBPaper00041190:C.japonica_rep2_stage3"
Microarray	"WBPaper00041190:C.japonica_rep2_stage4"
Microarray	"WBPaper00041190:C.japonica_rep2_stage5"
Microarray	"WBPaper00041190:C.japonica_rep2_stage6"
Microarray	"WBPaper00041190:C.japonica_rep2_stage7"
Microarray	"WBPaper00041190:C.japonica_rep2_stage8"
Microarray	"WBPaper00041190:C.japonica_rep2_stage9"
Microarray	"WBPaper00041190:C.japonica_rep2_stage10"
Microarray	"WBPaper00041190:C.japonica_rep3_stage1"
Microarray	"WBPaper00041190:C.japonica_rep3_stage2"
Microarray	"WBPaper00041190:C.japonica_rep3_stage3"
Microarray	"WBPaper00041190:C.japonica_rep3_stage4"
Microarray	"WBPaper00041190:C.japonica_rep3_stage5"
Microarray	"WBPaper00041190:C.japonica_rep3_stage6"
Microarray	"WBPaper00041190:C.japonica_rep3_stage7"
Microarray	"WBPaper00041190:C.japonica_rep3_stage8"
Microarray	"WBPaper00041190:C.japonica_rep3_stage9"
Microarray	"WBPaper00041190:C.japonica_rep3_stage10"




Picture- generate three .ace file

we have 3 species: briggsae, remanei and japonica


Picture : from WBPicture0001030253 on
Description: if orthologs are present- "yes" in the columnE:

Description	"A) Embryonic gene expression profile"
Description	"B) Comparative gene expression profiles for the orthologous group"
Description	"red=C. remanei"
Description	"green=C. briggsae"
Description	"blue=C. brenneri"
Description	"yellow=C. elegans"
Description	"pink=C. japonica"
Description	"For additional information: yanailab.technion.ac.il"


if orthologs are not present- "no" in aformentioned column

Description	"A) Embryonic gene expression profile"
Description	"For additional information: yanailab.technion.ac.il"

Name	Wormbase_<columnA>.jpg e.g.: Wormbase_WBGene00000307.jpg
Remark	"Levin M et al. (2012) Dev Cell \"Developmental milestones punctuate gene expression in the caenorhabditis ....\""
Expr_pattern	"get the corresponding expression pattern objects" <ColumnA> from remark in the expression.ace
Template	"WormBase thanks <Person_name> for providing the pictures."
Contact	"WBPerson4037"
Person_name	"Itai Yanai"
Species "briggsae, japonica or remanei, according to the file"


Example:

Picture : "WBPicture0001030253"
Description	"A) Embryonic gene expression profile"
Description	"B) Comparative gene expression profiles for the orthologous group"
Description	"red=C. remanei"
Description	"green=C. briggsae"
Description	"blue=C. brenneri"
Description	"yellow=C. elegans"
Description	"pink=C. japonica"
Description	"For additional information: yanailab.technion.ac.il"
Name	"WBGene00000089.jpg"
Remark	"Levin M et al. (2012) Dev Cell \"Developmental milestones punctuate gene expression in the caenorhabditis ....\""
Expr_pattern	"Expr1050000"
Template	"WormBase thanks <Person_name> for providing the pictures."
Contact	"WBPerson4037"
Person_name	"Itai Yanai"
Species "Caenorhabditis briggsae"



Daniela TODO
Deposit the excel spreadsheets on
ftp://caltech.wormbase.org/pub/wormbase/datasets-published/levin2012/

expand the readme file

for Brenneri we don't have pictures
