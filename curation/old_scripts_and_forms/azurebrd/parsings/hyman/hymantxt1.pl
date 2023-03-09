#!/usr/bin/perl 

$infile = "hyman.txt";
$outfile = "hyman.2.txt";
$table3 = "Gonczy_Table3.txt";
$table4 = "Gonczy_Table4.txt";

open (T3, $table3) or die "Cannot open $table3 : $!";
while (<T3>) {
  chomp;
  if ($_ =~ m/^([A-Z]{1,2}\d{2,}.*?\.\d+)/) {
    ($a, $b, $c, $d) = split("\t", $_);
    $ta3{$a} = $d;
  }
}
close (T3) or die "Cannot close $table3 : $!";

open (T4, $table4) or die "Cannot open $table4 : $!";
while (<T4>) {
  chomp;
  if ($_ =~ m/^([A-Z]{1,2}\d{2,}.*?\.\d+)/) {
    ($a, $b, $c) = split("\t", $_);
    $ta4{$a} = $c;
  }
}
close (T4) or die "Cannot close $table4 : $!";

foreach $_ (sort keys %ta3) {
  # print "T3 : $_ \t $ta3{$_}\n";
}
foreach $_ (sort keys %ta4) {
  # print "T4 : $_ \t $ta4{$_}\n";
}

open (IN, $infile) or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

$/ = "";

while (<IN>) {
  chomp; 
  if ($_ =~ m/^Sequence/) {
    print OUT "$_\n";
    print OUT "\n";
  }
  if ($_ =~ m/^(RNAi|Predicted_gene)/) {
  $date = 0;
  chomp;
  if ($_ =~ m/^Predicted_gene ([A-Z]{1,2}\d{2,}.*?\.\d+)/m) {
    $in{$1} = $_;
  }
  @entry = split("\n", $_);
  foreach $_ (@entry) { 
    if ($_ =~ m/^Primers/) {  # put Primers into remark
      # ($a, $b) = split(":", $_);
      # $b =~ s/^ //;
      print OUT "Remark \t \"$_\"\n";
    } elsif ($_ =~ m/^PCR_product/) {  # put PCR_product into remark
      # ($a, $b) = split(":", $_);
      # $b =~ s/^ //;
      print OUT "Remark \t \"$_\"\n";
    } elsif ($_ =~ m/^Phenotype.*Remark "/) {    # dates on phenotypes out
      ($a, $b) = split /"/, $_;
      if ($b =~ m/[A-Za-z]/) { print OUT "$_\n"; }
    } elsif ($_ =~ m/^Date 2000-11-16/) {
      $date = 1; print OUT "$_\n";
    } elsif ($_ =~ m/^Phenotype Class: wild type$/) {
      # $_ =~ s/wild type/WT/;		# zap it
      # print OUT "$_\n";
    } elsif ($_ =~ m/^Phenotype Description:/) { 	# zap it
    } elsif ($_ =~ m/^Phenotype Class: NA/) {		# zap it
    } elsif ($_ =~ m/^Phenotype Class: Progress through meiotic divisions/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Male and female pronuclei do not become visible; embryos seem arrested during meiotic divisions.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Fidelity of meiotic divisions/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Multiple female pronuclei; irregular cytoplasm; aberrant pseudoclevage stage; splindle unstable during anaphase; karyomeres in AB/ P1; AB/P1 nuclei off-center; often semi-sterile.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Entry into interphase/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Delay before entering
interphase; vigorous cytoplasmic and cortical movements; aberrant number and/or
position of pronuclei; aberrant splindle position.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Nuclear appearance/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Nuclei in daughter blastomeres are not/poorly visible (but pronuclei appear normal).\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Pronuclear migration/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Lack of male pronuclear migration; female pronuclear migration viable; sometimes multiple female pronuclei; no/small spindle.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Spindle assembly/) {
      print OUT "Spindle is either very small or no bipolar spindle is observed; karyomeres are generated.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Cytokinesis/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Cleavage furrow not visible or regresses.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: P1 rotation/) {
      print OUT "Phenotype \t Emb \t Remark \t \"No rotation of centrosome/nuclear complex in P1.\"\n";
    } elsif ($_ =~ m/^Phenotype Class: Osmotic integrity and other processes/) {
      print OUT "Phenotype \t Emb \t Remark \t \"Embryos loose structural integrity upon dissection; limited phenotypic analysis done in utero.\"\n";

    } elsif ($_ =~ m/^Progeny Phenotype Class: Embryonic lethal/) {
      print OUT "Phenotype \t Emb \t Remark \t \"0-10 F1 larvae; dead eggs on plate.\"\n";
    } else { 
      print OUT "$_\n"; 
    }
  } # foreach $_ (@entry) 
  if ($date == 0) { print OUT "Date 2000-11-16\n" }
  print OUT "\n";

  } # if (($_ =~ m/^RNAi/) || ($_ =~ m/^Predicted_gene) ) 
}


  # $in{$1} = $/;
foreach $_ (sort keys %in) {
  print "$in{$_}\n";
  if ($ta3{$_}) { print "Phenotype \t Emb \t \"$ta3{$_}\"\n"; }
  if ($ta4{$_}) { print "Phenotype \t Emb \t \"$ta4{$_}\"\n"; }
  print "\n";
  # print "T3 : $_ \t $ta3{$_}\n";
}
foreach $_ (sort keys %ta4) {
  # print "T4 : $_ \t $ta4{$_}\n";
}
