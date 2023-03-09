#!/usr/bin/perl
# This program takes the .old file from Allen's crawl, strips off extra junk,
# reformats stuff into useful stuff, writes to a temp file.  Reads tempfile to
# reformat with RNAi first (didn't feel like using a hash), outputs to
# .old.stripped file.

$infile = "hyman.old";
$tempfile = "hyman.old.temp";
$outfile = "hyman.old.stripped";

open (IN, "$infile") or die "Cannot open $infile : $!";
open (OUT, ">$tempfile") or die "Cannot create $tempfile : $!";

while (<IN>) {
  chomp;
  if ($_ =~ m/^Author/) {			# zap author
  } elsif ($_ =~ m/^Date/) {			# zap date
  } elsif ($_ =~ m/^Laboratory/) {		# zap lab
  } elsif ($_ =~ m/^Phenotype Class/) {		# zap phen class
  } elsif ($_ =~ m/^Progeny Phenotype Class/) {	# zap pro phen class
  } elsif ($_ =~ m/^Position/) {		# zap position
  } elsif ($_ =~ m/^Phenotype/) {		# zap phenotypes
  } elsif ($_ =~ m/^RNAi/) {			# format and print RNAi
    $_ =~ s/RNAi: /RNAi TH:/;
    print OUT "$_\n";				
  } elsif ($_ =~ m/^Predicted Gene/) {		# format and print Pred_gene
    $_ =~ s/Predicted Gene:/Predicted_gene/;
    $_ =~ s/TH://;
    print OUT "$_\n";
  } elsif ($_ =~ m/^Primers/) { 		# Primers in remark
    print OUT "Remark \t \"$_\"\n";
  } elsif ($_ =~ m/^PCR_product/) { 		# pcr_product in remark
    print OUT "Remark \t \"$_\"\n";
  } elsif ($_ =~ m/^Progeny Phenotype Description: (.*?)$/m) {		# same
    print OUT "Remark \t \"$1\"\n";
  } elsif ($_ =~ m/^Progeny Phenotype Comment.*?: (.*?)$/m) {		# same
    print OUT "Remark \t \"$1\"\n";
  } elsif ($_ =~ m/^$/) { 			# counter, comment out if wanted
    $i++; print OUT "$_\n";
  } else { 					# missed cases, print
    print OUT "$_\n";
  }
}
print $i . "\n";

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $tempfile : $!";

open (IN, "$tempfile") or die "Cannot open $tempfile : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";

$/ = "";				# get blocks
while (<IN>) {
  chomp;				# munch
  if ($_ =~ m/^(RNAi.*?)$/m) {		# get the RNAi entry
    print OUT "$1\n";			# print it first
    $_ =~ s/^RNAi.*?$//m;		# take it out
    $_ =~ s/\n\n/\n/;			# take out the newline
    print OUT "$_\n";			# print entry (minus RNAi entry)
    print OUT "\n";			# newline
  }
}

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
