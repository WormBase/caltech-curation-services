#!/usr/bin/perl
# This file formats dbScreen according to Raymond's specs more or less in
# (unupdated) dbScreen2ace_instr.txt

$infile = "dbScreen.txt";
$outfile = "dbOUT.txt";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<IN>) {
  chomp;
  ($gene, $two, $three, $four, $five, $rnai, $start, $end, $phencom, $ten, $eleven, $twelve, $thirteen, $fourteen, $dicdesc, $dicphencom, $prophencla, $prophendesc, $prophencom) = split /\t/, $_;
  $gene =~ s/\"//g;
  $fullgene = $gene;
  $gene =~ s/\..*//;
  $rnai =~ s/\"//g;
  $start =~ s/\"//g;
  $end =~ s/\"//g;

  print OUT "Sequence $gene\n";
  print OUT "RNAi TH:$rnai $start $end\n\n";
  print OUT "RNAi TH:$rnai\n";
  print OUT "Method RNAi\n";
  print OUT "Sequence $gene\n";
  print OUT "Predicted_gene $fullgene\n";

  $phencom =~ s/\"//g;
  if ($phencom eq "") {
  } elsif ($phencom =~ m/^NA$/i) {
  } elsif ($phencom =~ m/^None$/i) {
  } elsif ($phencom =~ m/sterile/i) { 
    print OUT "Phenotype \t Ste\n";
    print OUT "Remark \t \"Phenotype comment -- $phencom\"\n";
  } else {
    print OUT "Remark \t \"Phenotype comment -- $phencom\"\n";
  }

  $dicdesc =~ s/\"//g;
  if ($dicdesc =~ m/^NA$/i) {
    print OUT "Phenotype \t Ste\n";
  } elsif ($dicdesc =~ m/^no$/i) { # print "$fullgene\n"; for raymond
  } elsif ($dicdesc =~ m/^none$/i) {
    print OUT "Remark \t \"DIC phenotype -- wild type\"\n";
  } else {
    print OUT "Remark \t \"DIC phenotype -- $dicdesc\"\n";
  }

  $dicphencom =~ s/\"//g;
  if ($dicphencom =~ m/^no$/i) {
  } else { print OUT "Remark \t \"DIC phenotype comment -- $dicphencom\"\n";
  }
 
  $prophencla =~ s/\"//g;
  if ($prophencla =~ m/^no$/) { 
    print OUT "Phenotype \t WT\n";
  } else {
    if ($prophencla =~ m/early larval defect/i) { 
      print OUT "Phenotype \t Lva\n"; 
    }
    if ($prophencla =~ m/embryonic lethal/i) { 
      print OUT "Phenotype \t Emb\n"; 
    }
    if ($prophencla =~ m/adult phenotype-f1 sterility/i) { 
      print OUT "Phenotype \t Stp\n"; 
    }
    if ($prophencla =~ m/slow larval development/i) { 
      print OUT "Phenotype \t Gro\n"; 
    }
    # if ($prophencla =~ m/morphological defects/i) { 
    #   print OUT "Phenotype \t Bmd\n"; 
    # }
    if ($prophencla =~ m/morphological defects/i) { 
      if ($prophendesc =~ m/dumpy/i) { 
      } else { print OUT "Phenotype \t Bmd\n";
      }
    }
  } # if ($prophencla =~ m/^no$/)  else  

  $prophendesc =~ s/\"//g;
  if ($prophendesc =~ m/^no$/i) {
  } elsif ($prophendesc =~ m/dumpy/i) { 
    print OUT "Phenotype \t Dpy\n";
    print OUT "Remark \t \"$prophendesc\"\n";
  } elsif ($prophendesc =~ m/unc/i) {
    print OUT "Phenotype \t Unc\n";
    print OUT "Remark \t \"$prophendesc\"\n";
  } else { print OUT "Remark \t \"$prophendesc\"\n";
  }

  $prophencom =~ s/\"//g;
  if ($prophencom =~ m/^no$/) {
  } else { print OUT "Remark \t \"$prophencom\"\n";
  }

  print OUT "Date 2000-11-16\nLaboratory TH\n";
  print OUT "Author \"Gonczy P\"\nAuthor \"Echeverri C\"\n";
  print OUT "Author \"Oegema K\"\nAuthor \"Coulson AR\"\n";
  print OUT "Author \"Jones SJ\"\nAuthor \"Copley RR\"\n";
  print OUT "Author \"Duperon J\"\nAuthor \"Oegema J\"\n";
  print OUT "Author \"Brehm M\"\nAuthor \"Cassin E\"\n";
  print OUT "Author \"Hannak E\"\nAuthor \"Kirkham M\"\n";
  print OUT "Author \"Pichler SC\"\nAuthor \"Flohrs K\"\n";
  print OUT "Author \"Go essen A\"\nAuthor \"Leidel S\"\n";
  print OUT "Author \"Alleaume AM\"\nAuthor \"Martin C\"\n";
  print OUT "Author \"Ozlu N\"\nAuthor \"Bork P\"\n";
  print OUT "Author \"Hyman AA\"\n";
  print OUT "Reference\t[cgc4403]\n";
  print OUT "\n";
}
