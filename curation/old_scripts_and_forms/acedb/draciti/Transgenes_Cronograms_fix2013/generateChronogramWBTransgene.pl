#!/usr/bin/perl -w

# map transgene names to IDs, for 2012 file take names and convert to IDs, for file tofix -D existing transgenes.  2013 07 09

use strict;

my %map;
my %add;
my %del;
my %any;

$/ = "";
my $infile = 'Transgenes.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  my ($name, $id) = ('', '');
  if ($obj =~ m/Transgene : "(WBTransgene\d+)"/) { $id = $1; }
  if ($obj =~ m/Public_name\s+"(.*?)"/) { $name = $1; }
  $map{$name} = $id;
} # while (my $obj = <IN>)
close (IN) or die "Cannot close $infile : $!";

$infile = 'Chronograms2012.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  my ($id) = $obj =~ m/Expr_pattern : "(.*?)"/;
  next unless $id;
  my (@trans) = $obj =~ m/Transgene\s+"(.*?)"/g;
  $any{$id}++;
  foreach my $tran (@trans) {
    if ($map{$tran}) { $add{$id}{$map{$tran}}++; }
      else { print "$id : No transgene mapping for $tran\n"; }
  } # foreach my $tran (@trans)
} # while (my $obj = <IN>)
close (IN) or die "Cannot close $infile : $!";

$infile = 'Chronogramstofix.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $obj = <IN>) {
  my ($id) = $obj =~ m/Expr_pattern : "(.*?)"/;
  next unless $id;
  $any{$id}++;
  my (@trans) = $obj =~ m/Transgene\s+"(.*?)"/g;
  foreach my $tran (@trans) { $del{$id}{$tran}++; }
} # while (my $obj = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $id (sort keys %any) {
  print qq(Expr_pattern : "$id"\n);
  foreach my $tran (sort keys %{ $del{$id} }) { print qq(-D Transgene "$tran"\n); } 
  foreach my $tran (sort keys %{ $add{$id} }) { print qq(Transgene "$tran"\n); } 
  print qq(\n);
} # foreach my $id (sort keys %any)



__END__

Transgenes.ace
Chronograms2012.ace
Chronogramstofix.ace

// data dumped from keyset display


Transgene : "WBTransgene00000001"
Public_name	 "adEx1256"
Summary	 "[C48A7.1:gfp]"
Driven_by_gene	 "WBGene00001187"
Reporter_product	 "GFP"
Reporter_type	 "Transcriptional fusion"
Strain	 "DA1256"
Reference	 "WBPaper00029359"
// data dumped from keyset display

SOURCE
Expr_pattern : "Chronogram1"
Gene	 "WBGene00007534"
Homol_homol	 "C12D8:Expr"
Reporter_gene	 "[C12D8.1:gfp] transcriptional fusion."
Localizome	
Picture	 "1_BC11926.png"
Remark	 "Original chronogram file: chronogram.1.xml"
Strain	 "BC11926"
Reference	 "WBPaper00029359"
Transgene	 "sIs10429"
Curated_by	 "Caltech"

To FIX
Expr_pattern : "Chronogram1"
Gene	 "WBGene00007534"
Reporter_gene	 "[C12D8.1:gfp] transcriptional fusion."
Localizome	
Picture	 "WBPicture0000000002"
Remark	 "Original chronogram file: chronogram.1.xml"
Strain	 "BC11926"
Reference	 "WBPaper00029359"
Transgene	 "WBTransgene00004281"
Curated_by	 "Caltech"

