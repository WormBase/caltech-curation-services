#!/usr/bin/perl 

$rnaidump = "/home/azurebrd/work/rnaifields/Supple_mat1.txt";
$outfile = "/home/azurebrd/work/rnaifields/rnaiout";

open (IN, "$rnaidump") or die "Cannot open $rnaidump : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

while (<IN>) {
  chomp;
  @line = split("\t");

  if ($line[4]) { # not wildtype 
    $key = $line[4]; 
  } else {
    $key = "WT";
  }

  $line = join("\t", @line);

  push @{ $HoA{$key} }, $line;
  # print "$key \t $line\n";
} # while (<IN>)

print "divider \n\n\n\n";

foreach $line (sort keys %HoA) {
  print "scalar number : " . scalar( @{ $HoA{$line} } ) . "\n";
  foreach $_ (@{ $HoA{$line} }) { 
    @line = split("\t");
    print OUT "RNAi \t \"SA:yk$line[1]\"\n";
    print OUT "Laboratory \t \"SA\"\n";
    print OUT "Laboratory \t \"YK\"\n";
    print OUT "Author \t \"Maeda I\"\n";
    print OUT "Author \t \"Kohara Y\"\n";
    print OUT "Author \t \"Yamamoto M\"\n";
    print OUT "Author \t \"Sugimoto A\"\n";
    print OUT "Date \t \"2001-02-06\"\n";
    if ($line[3]) { print OUT "Predicted_gene \t \"$line[3]\"\n"; }
    if ($line[4]) {$phenotype = $line[4];} else {$phenotype = "WT";}
    print OUT "Phenotype \t \"$phenotype\"\n";
    print OUT "Remark \t \"SA:yk$line[1]";
    if ($line[3]) {print OUT "\"\n\n"} else {print OUT ", $line[3]\"\n\n";}
 
    # print "$_ \n"; 
  }

  # print "line : $line \t value : @{ $HoA{$line} } \n";
}
  
  print OUT "RNAi \t \"SA:yk$line[1]\"\n";
  print OUT "Laboratory \t \"SA\"\n";
  print OUT "Laboratory \t \"YK\"\n";
  print OUT "Author \t \"Maeda I\"\n";
  print OUT "Author \t \"Kohara Y\"\n";
  print OUT "Author \t \"Yamamoto M\"\n";
  print OUT "Author \t \"Sugimoto A\"\n";
  print OUT "Date \t \"2001-02-06\"\n";
  if ($line[3]) { print OUT "Predicted_gene \t \"$line[3]\"\n"; }
  if ($line[4]) {$phenotype = $line[4];} else {$phenotype = "WT";}
  print OUT "Phenotype \t \"$phenotype\"\n";
  print OUT "Remark \t \"SA:yk$line[1]";
  if ($line[3]) {print OUT "\"\n\n"} else {print OUT ", $line[3]\"\n\n";}
  


# } # while (<IN>)

close (IN) or die "Cannot close $rnaidump : $!";
close (OUT) or die "Cannot close $outfile : $!";
