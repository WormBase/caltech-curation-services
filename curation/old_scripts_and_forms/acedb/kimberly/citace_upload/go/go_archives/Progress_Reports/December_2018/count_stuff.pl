#!/usr/bin/perl

# get counts, convert data, and sort for Kimberly, according to wiki at 
# http://wiki.wormbase.org/index.php/New_GO_Progress_Report_Script
# 2014 03 06
#
# DB_Object_ID was matching on first 6 characters instead of matching on
# exactly 6, 8, or 10 characters.  2017 12 12
#
# updated to get mapping of protein to genes like in 
# /home/acedb/kimberly/citace_upload/go/gpad2ace/2018_November/go_gpad_parser.pl                 
# 2018 12 03


use strict;
use diagnostics;
use LWP::Simple;


my %protToWBGene;
my %tempGpi;            # tempname to uniprot
my %nameToWbg;          # tempname to wbgene
my $gpifileUrl = 'ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/PRJNA13758/annotation/gene_product_info/c_elegans.canonical_bioproject.current_development.gene_product_info.gpi.gz';
my $gpifiledata = get $gpifileUrl;
my (@gpilines) = split/\n/, $gpifiledata;
foreach my $line (@gpilines) {
  next unless ($line =~ m/^WB/);
  my (@tabs) = split/\t/, $line;
  my $tempid   = $tabs[1];
  my $tempname = lc($tabs[2]);
  if ($tempid =~ m/WBGene\d+/) { $nameToWbg{$tempname} = $tempid; }
  next unless $tabs[8];
  my $uniprot  = $tabs[8];
  my (@uniprots) = split/\|/, $uniprot;
  foreach my $unip (@uniprots) { $tempGpi{$tempname}{$unip}++; } }
foreach my $tempname (sort keys %tempGpi) {
  unless ($nameToWbg{$tempname}) { print qq(ERROR $tempname in gpi file doesn't map to a WBGene from column 2\n); next; }
  my $wbgene = $nameToWbg{$tempname};
  foreach my $unip (sort keys %{ $tempGpi{$tempname} }) {
    $unip =~ s/UniProtKB://;
    $protToWBGene{$unip}{$wbgene}++; } }

# old way  2018 12 03
# my %protToWBGene;
# my $prot_file = 'gp2protein.wb';
# open (IN, "<$prot_file") or die "Cannot open $prot_file : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   my ($wb, $uni) = split/\t/, $line;
#   next unless $uni;
#   $wb =~ s/^WB://g;
#   my (@uni) = split/;/, $uni;
#   foreach (@uni) { 
#     $_ =~ s/^UniProtKB://g;
#     $protToWBGene{$_}{$wb}++; }
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $prot_file : $!";

my %all_lines; 
my %wbg;
my %sorted_lines;
my %three_to_six;
my %three_to_six_with_eleven;
my $assoc_file = 'gp_association.wb';
open (IN, "<$assoc_file") or die "Cannot open $assoc_file : $!";
while (my $line = <IN>) {
  next unless ($line =~ m/^UniProtKB/);
  chomp $line;
  my ($c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $c10, $c11, $c12) = split/\t/, $line;
#   next if ($c6 eq 'ECO:0000256');
  next if ($c12 eq 'go_evidence=IEA');
  if ($c2 =~ m/^(.{6})$/)       { $c2 = $1; }
    elsif ($c2 =~ m/^(.{8})$/)  { $c2 = $1; }
    elsif ($c2 =~ m/^(.{10})$/) { $c2 = $1; }
#   ($c2) = $c2 =~ m/^(.{6})/;					# strip out trailing stuff 2014 03 12	this only matched on first 6, should match exactly 6 8 or 10
  $c12 = '';									# ignore this ?  not sure this is correct  2014 03 12
  if ($protToWBGene{$c2}) { 
      foreach my $wbgene (sort keys %{ $protToWBGene{$c2} }) {
        my $line = "$c1\t$wbgene\t$c3\t$c4\t$c5\t$c6\t$c7\t$c8\t$c9\t$c10\t$c11\t$c12";
        $all_lines{$line}++;
        $sorted_lines{$c10}{$line}++;
        $wbg{$wbgene}++;
        $three_to_six{$c3}{$c6}{$c10}++;
        if ($c11) { $three_to_six_with_eleven{$c3}{$c6}{$c10}++; }
      } # foreach my $wbgene (sort keys %{ $protToWBGene{$c2} })
    } else { print "ERROR $c2 does not map to WBGene in $line\n"; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $assoc_file : $!";

my $unique_lines   = scalar keys %all_lines;
my $unique_wbgenes = scalar keys %wbg;
print "unique annotations : $unique_lines\n";
print "unique wbgenes : $unique_wbgenes\n";
print "\n";
foreach my $c3 (sort keys %three_to_six) {
  foreach my $c6 (sort keys %{ $three_to_six{$c3} }) {
    foreach my $c10 (sort keys %{ $three_to_six{$c3}{$c6} }) {
      my $count = $three_to_six{$c3}{$c6}{$c10};
      print "C3 $c3 with C6 $c6 C10 $c10 count $count\n";
    } # foreach my $c10 (sort keys %{ $three_to_six{$c3}{$c6} })
  } # foreach my $c6 (sort keys %{ $three_to_six{$c3} })
} # foreach my $c3 (sort keys %three_to_six)
foreach my $c3 (sort keys %three_to_six_with_eleven) {
  foreach my $c6 (sort keys %{ $three_to_six_with_eleven{$c3} }) {
    foreach my $c10 (sort keys %{ $three_to_six_with_eleven{$c3}{$c6} }) {
      my $count = $three_to_six_with_eleven{$c3}{$c6}{$c10};
      print "C3 $c3 with C6 $c6 C10 $c10 and C11 count $count\n";
    } # foreach my $c10 (sort keys %{ $three_to_six_with_eleven{$c3}{$c6} })
  } # foreach my $c6 (sort keys %{ $three_to_six_with_eleven{$c3} })
} # foreach my $c3 (sort keys %three_to_six)

print "\n";
foreach my $c10 (sort keys %sorted_lines) { 
  foreach my $line (sort keys %{ $sorted_lines{$c10} }) { 
    print "$line\n";
  } # foreach my $line (sort keys %{ $sorted_lines{$c10} }) 
} # foreach my $c10 (sort keys %sorted_lines)
