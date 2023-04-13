#!/usr/bin/perl

# generate gpi file according to wiki instructions from Kimberly
# http://wiki.wormbase.org/index.php/Specifications_for_WB_gpi_file
# 2013 04 05
#
# made changes for Kimberly.  2013 04 08

use strict;
use diagnostics;

my $version = 'ws234';
my $outfile = $version . '_gpi';
my $tblfile = $version . '_tablemaker_info.txt';
my $xreffile = 'c_elegans.WS234.xrefs.txt';

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT qq(!gpi-version: 1.1\n);
print OUT qq(!namespace: WB\n);

my %tbl; my %xref; my %any;
open (IN, "<$tblfile") or die "Cannot open $tblfile: $!";
while (my $line = <IN>) {
  chomp $line;
  my @line = split/\t/, $line;
  foreach (@line) { $_ =~ s/^\"//; $_ =~ s/\"$//; }
  my ($one, $two, $thr, $fou, $fiv, $six) = ($line[0], $line[1], $line[2], $line[3], $line[4], $line[5]);
  $any{$one}++;
  $tbl{$one}{c2} = $two;
  $tbl{$one}{c3} = $thr;
  $tbl{$one}{c4}{$fou}++;
  $tbl{$one}{c6} = $six;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $tblfile : $!";

open (IN, "<$xreffile") or die "Cannot open $xreffile: $!";
while (my $line = <IN>) {
  chomp $line;
  my @line = split/\t/, $line;
  my $gene = $line[1];
  $any{$gene}++;
  for (my $i = 0; $i <= $#line; $i++) {
    if ($line[$i] eq '.') { $line[$i] = ''; }
    my $plus = $i+1; my $key = 'c' . $plus; $xref{$gene}{$key}{$line[$i]}++;
  } # for (my $i = 0; $i <= $#line; $i++)
} # while (my $line = <IN>)
close (IN) or die "Cannot close $xreffile : $!";

foreach my $gene (sort keys %any) {
  my $col1 = $gene;
  my $col2 = '';
  my $isc2 = 0;
  next if ($tbl{$gene}{c6});		# skip genes with Corresponding_pseudogene
  my %col4;
  if ($tbl{$gene}{c2}) {
      if ($tbl{$gene}{c3}) { $col4{ $tbl{$gene}{c3} }++; }
      $col2 = $tbl{$gene}{c2}; } 
    else { $col2 = $tbl{$gene}{c3}; }
  if ($tbl{$gene}{c4}) { foreach my $value (keys %{$tbl{$gene}{c4} }) { $col4{$value}++; } }
  foreach my $value (sort keys %{ $xref{$gene}{c4} }) {
    if ($value =~ m/^(.*?\..*?)\..*/) { $col4{$1}++; }
      else { $col4{$value}++; } }
  foreach my $value (sort keys %{ $xref{$gene}{c5} }) { $col4{"WP:$value"}++; }
  if ($col4{$col2}) { delete $col4{$col2}; }		# if col4 contains col2, remove col2 value, don't need it in both places.  col4 gets populated from two files.
  if ($col4{''}) { delete $col4{''}; }			# delete any blanks that may have gotten in
  my $col4 = join"|", sort keys %col4;
  my $col7 = 'WB:'. $gene;
  my $col8 = ''; my %col8;
  foreach my $value (sort keys %{ $xref{$gene}{c7} }) { $col8{"CCD:$value"}++; }
  foreach my $value (sort keys %{ $xref{$gene}{c8} }) { $col8{"UniProtKB:$value"}++; }
  $col8 = join"|", sort keys %col8;

  my $col5 = 'gene';
  my $col6 = 'taxon:6239';
  print OUT "$col1\t$col2\t\t$col4\t$col5\t$col6\t$col7\t$col8\t\n";
} # foreach my $gene (sort keys %any)


close (OUT) or die "Cannot close $outfile : $!";
