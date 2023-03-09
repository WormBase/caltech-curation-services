#!/usr/bin/perl
# This program takes input from hyman.old.stripped (which is the result of
# running hyman.old through hymanstripper.pl), Gonczy_Table4.txt,
# Gonczy_Table3.txt, and Gonczy_Table3a.txt (originally a single Gonczy file
# that had different info needed from different parts).  Relevant info from
# .old.stripped already parsed.  Parses info from tables, keying hashes from
# predicted_genes.  Getting Phenotypes, DIC-info, and other Remark info.
# Outputs it all out to hyman.old.parsed.  (Missing a&b predicted_genes from
# table4 F43C1.2; proper phenotype from table3 AD phenotypes).

$infile = "hyman.old.stripped";
$outfile = "hyman.old.parsed";
$table3 = "Gonczy_Table3.txt";
$table4 = "Gonczy_Table4.txt";
$table3a = "Gonczy_Table3a.txt";

open (T3, $table3) or die "Cannot open $table3 : $!";
while (<T3>) {
  chomp;
  if ($_ =~ m/^.*?\t([A-Z]{1,2}\d{2,}.*?\.\d+)/) {
    ($t3type, $t3predgene, $junk, $ta3phen, $comment) = split("\t", $_);
    $comment =~ s/\beos\b/egg-osmotic-sensitive/;
    $ta3{$t3predgene} = $comment;
    if ($ta3phen eq "EL") { $ta3p{$t3predgene} = "Emb"; }
    if ($ta3phen eq "WT") { $ta3p{$t3predgene} = "WT"; }
    if ($ta3phen eq "ND") { $ta3p{$t3predgene} = ""; }
    if ($ta3phen eq "LA") { $ta3p{$t3predgene} = "Lva"; }
    if ($ta3phen eq "AD") { $ta3p{$t3predgene} = ""; }
    if ($t3type eq "A1") { $ta3t{$t3predgene} = "Male and female pronuclei do not become visible; embryos seem arrested during meiotic division."; }
    if ($t3type eq "A2") { $ta3t{$t3predgene} = "Multiple female pronuclei; Irregular cytoplasm; aberrant pseudocleavage stage; spindle unstable during anaphase; karyomeres in AB/P1; AB/P1 nuclei off-center; often semi-sterile."; }
    if ($t3type eq "A3") { $ta3t{$t3predgene} = "Delay before entering interphase; vigorous cytoplasmic and cortical movements; aberrant number and/or position of pronuclei; aberrant spindle position."; }
    if ($t3type eq "A4") { $ta3t{$t3predgene} = "Little/no cortical ruffing or pseudocleavage furrow."; }
    if ($t3type eq "B1") { $ta3t{$t3predgene} = "Pronuclei and nuclei in daughter blastomeres are not/poorly visible; spindle is not/poorly visible; often failure in cytokinesis."; }
    if ($t3type eq "B2") { $ta3t{$t3predgene} = "Nuclei in daughter blastomeres are not/poorly visible (but pronuclei appear normal)."; }
    if ($t3type eq "C1") { $ta3t{$t3predgene} = "Lack of male pronuclear migration; female pronuclear migration variable; sometimes multiple female pronuclei; no/small spindle."; }
    if ($t3type eq "C2") { $ta3t{$t3predgene} = "Spindle is either very small or no bipolar spindle is observed; karyomeres are generated." }
    if ($t3type eq "C3") { $ta3t{$t3predgene} = "Daughter nuclei stay close to the central cortex; usually karyomeres in daughter blastomeres." }
    if ($t3type eq "C4") { $ta3t{$t3predgene} = "More than one nucleus (karyomeres) in daughter blastomeres AB and/or P1." }
    if ($t3type eq "C5") { $ta3t{$t3predgene} = "No posterior spindle displacement during anaphase; symmetric first division." }
    if ($t3type eq "C6") { $ta3t{$t3predgene} = "Cleavage furrow not visible or regresses." }
    if ($t3type eq "C7") { $ta3t{$t3predgene} = "No rotation of centrosome/nuclear complex in P1." }
    if ($t3type eq "D1") { $ta3t{$t3predgene} = "Slow overall pace of development (over 30 min between pronuclear migration and AB division -compared to 18-22 min in wt)." }
    if ($t3type eq "D2") { $ta3t{$t3predgene} = "Slow between pseudocleavage stage and pronuclear envelope breakdown; P1 division delayed with respect to that of AB." }
    if ($t3type eq "E1") { $ta3t{$t3predgene} = "Embryos loose structural integrity upon dissection; limited phenotypic analysis done in utero." }
    if ($t3type eq "E2") { $ta3t{$t3predgene} = "Density of yolk granules throughout embryo is markedly reduced." }
    if ($t3type eq "E3") { $ta3t{$t3predgene} = "Uneven or irregular distribution of yolk granules." }
  }
}
close (T3) or die "Cannot close $table3 : $!";

open (T3A, $table3a) or die "Cannot open $table3a : $!";
while (<T3A>) {
  chomp;
  if ($_ =~ m/^.*?\t([A-Z]{1,2}\d{2,}.*?\.\d+)/) {
    ($t3type, $t3predgene, $comment, $ta3phen) = split("\t", $_);
    $comment =~ s/\beos\b/egg-osmotic-sensitive/;
    $ta3{$t3predgene} = $comment;
    if ($ta3phen eq "EL") { $ta3p{$t3predgene} = "Emb"; }
    if ($ta3phen eq "WT") { $ta3p{$t3predgene} = "WT"; }
  }
}
close (T3A) or die "Cannot close $table3a : $!";

open (T4, $table4) or die "Cannot open $table4 : $!";
while (<T4>) {
  chomp;
  if ($_ =~ m/^.*?\t([A-Z]{1,2}\d{2,}.*?\.\d+)/) {
    ($t4type, $t4predgene, $junk, $comment) = split("\t", $_);
    $ta4{$t4predgene} = $comment;
    if ($t4type eq "A") { $ta4p{$t4predgene} = "Emb"; }
    if ($t4type eq "B") { $ta4p{$t4predgene} = "Lva"; }
    if ($t4type eq "C") { $ta4p{$t4predgene} = "Lva"; }
    if ($t4type eq "D") { $ta4p{$t4predgene} = ""; }
    if ($t4type eq "E") { $ta4p{$t4predgene} = "Ste"; }
  }
}
close (T4) or die "Cannot close $table4 : $!";


open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

$/ = "";

while (<IN>) {
  chomp;
  if ($_ =~ m/^Predicted_gene (.*?\..*?)\b$/m) {
    $HoA{$1} = $_;
  }
}

foreach $_ (sort keys %HoA) {
  $allen{$_}++;
}
foreach $_ (sort keys %ta3p) {
  $allen{$_}++;
}
foreach $_ (sort keys %ta4p) {
  $allen{$_}++;
}

foreach $_ (sort keys %allen) {
  if ($allen{$_} != 2) { print "$_, $allen{$_}\n"; $miscount++ }
}
print "$miscount\n";

foreach $_ (sort keys %allen) {
  $i++;
  # print OUT "$_ : \n";
  print OUT "$HoA{$_}\n";
  if ($ta3p{$_}) { print OUT "Phenotype \t $ta3p{$_}\n"; }
  if ($ta4p{$_}) { print OUT "Phenotype \t $ta4p{$_}\n"; }
  if ($ta3{$_}) { print OUT "Remark \t \"DIC phenotype -- $ta3t{$_}\"\n"; }
  if ($ta3t{$_}) { print OUT "Remark \t \"$ta3{$_}\"\n"; }
  if ($ta4{$_}) { print OUT "Remark \t \"$ta4{$_}\"\n"; }
  print OUT "Date 2000-11-16\nLaboratory TH\n";
  print OUT "Author \"Gonczy P\"\nAuthor \"Echeverri C\"\n";
  print OUT "Author \"Oegema K\"\nAuthor \"Coulson AR\"\n";
  print OUT "Author \"Jones SJ\"\nAuthor \"Copley RR\"\n";
  print OUT "Author \"Duperon J\"\nAuthor \"Oegema J\"\n";
  print OUT "Author \"Brehm M\"\nAuthor \"Cassin E\"\n";
  print OUT "Author \"Hannak E\"\nAuthor \"Kirkham M\"\nAuthor \"Pichler SC\"\nAuthor \"Flohrs K\"\nAuthor \"Goessen A\"\nAuthor \"Leidel S\"\nAuthor \"Alleaume AM\"\nAuthor \"Martin C\"\nAuthor \"Ozlu N\"\nAuthor \"Bork P\"\nAuthor \"Hyman AA\"\nReference\t[cgc4403]\n";
  print OUT "\n";
}
print OUT "$i\n";
