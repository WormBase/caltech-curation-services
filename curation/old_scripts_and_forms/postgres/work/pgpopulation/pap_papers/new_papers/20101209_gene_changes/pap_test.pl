#!/usr/bin/perl

# test Kimberly's new 5 parameters to tokenize abstracts to match WBGenes.  2010 12 09
#
# added comparison to pap_gene to see what are new pap-gene entries to create (Kimberly doesn't 
# care about new pap-gene-inferred_evidence)  2011 01 21
#
# removed splitting on periods, it was making hsp-16.2::gfp match hsp-16 sets before we split on ::
# added stripping of . at the end of the word for sentence periods
# added splitting on ::   2011 05 03

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %cdsToGene;
&getLoci();

# my @papers = qw( 00035164 00035449 00035474 00035490 00035559 00037741 00037686 00037794 );

my @papers;
for my $i (36200 .. 36300) { 
  my $pap = "000" . $i;
  push @papers, $pap; 
}

my %pap_gene;
my $result = $dbh->prepare( "SELECT joinkey, pap_gene FROM pap_gene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap_gene{$row[0]}{$row[1]}++; }

my $joinkeys = join"','", @papers;
$result = $dbh->prepare( "SELECT * FROM pap_abstract WHERE joinkey IN ('$joinkeys') ORDER BY joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0] && $row[1]) { &matchAbstract($row[0], $row[1]); }
}


sub matchAbstract {
  my ($paper, $data) = @_;
  my @w1 = split/\s+/, $data; my %filtered_loci;
  foreach my $w1 (@w1) { 
    if ($cdsToGene{locus}{$w1}) {
      foreach my $wbgene (@{ $cdsToGene{locus}{$w1} }) { $filtered_loci{$wbgene}{$w1}++; } }
    else {
      my @w2 = split/[\(\)]/, $w1;
      foreach my $w2 (@w2) { 
        if ($cdsToGene{locus}{$w2}) {
          foreach my $wbgene (@{ $cdsToGene{locus}{$w2} }) { $filtered_loci{$wbgene}{$w2}++; } }
        else {
          my @w3 = split/\//, $w2;
          foreach my $w3 (@w3) { 
            if ($cdsToGene{locus}{$w3}) {
              foreach my $wbgene (@{ $cdsToGene{locus}{$w3} }) { $filtered_loci{$wbgene}{$w3}++; } }
             else {
               my @w4 = split/::/, $w3;
               foreach my $w4 (@w4) { 
                 if ($cdsToGene{locus}{$w4}) {
                   foreach my $wbgene (@{ $cdsToGene{locus}{$w4} }) { $filtered_loci{$wbgene}{$w4}++; } }
                 else {
                   my $w5 = $w4;
                   $w5 =~ s/[,;]//g;
                   if ($cdsToGene{locus}{$w5}) {
                     foreach my $wbgene (@{ $cdsToGene{locus}{$w5} }) { $filtered_loci{$wbgene}{$w5}++; } }
                     else {
                       my $w6 = $w5;
                       $w6 =~ s/\.$//g;
                       if ($cdsToGene{locus}{$w6}) {
                         foreach my $wbgene (@{ $cdsToGene{locus}{$w6} }) { $filtered_loci{$wbgene}{$w6}++; } } }
 } } } } } } } }

#               else {
#                 my @w5 = split/\./, $w4;
#                 foreach my $w5 (@w5) { 
#                   if ($cdsToGene{locus}{$w5}) {
#                     foreach my $wbgene (@{ $cdsToGene{locus}{$w5} }) { $filtered_loci{$wbgene}{$w5}++; } } } }
        
#     if ($word =~ m/,/) { $word =~ s/,//g; }
#     if ($word =~ m/\(/) { $word =~ s/\(//g; }
#     if ($word =~ m/\)/) { $word =~ s/\)//g; }
#     if ($word =~ m/;/) { $word =~ s/;//g; }
#     if ($cdsToGene{locus}{$word}) {
#       foreach my $wbgene (@{ $cdsToGene{locus}{$word} }) { $filtered_loci{$wbgene}{$word}++; } }
#     my $pgtable = 'pap_gene';
#     my ($order) = &getHighestOrderByTableJoinkey($pgtable, $joinkey);
    foreach my $wbgene (sort keys %filtered_loci) {
      foreach my $word (sort keys %{ $filtered_loci{$wbgene} }) { 
#         $order++;
        my $evidence = "'Inferred_automatically\t\"Abstract read $word\"'";
        print "WBPaper$paper : WBGene$wbgene matched $word\n";
        unless ($pap_gene{$paper}{$wbgene}) { print "NEW WBPaper$paper : WBGene$wbgene matched $word\n"; }
    } }
#         &appendMultiPg($order, $pgtable, $joinkey, $curator_id, $timestamp, $wbgene, $evidence); 
} # sub matchAbstract

sub getLoci {			# genes to all other possible names
#   my @pgtables = qw( gin_locus gin_molname gin_protein gin_seqname gin_sequence gin_synonyms );
  my @pgtables = qw( gin_locus gin_seqname gin_synonyms );		# just these 3, Kimberly, 2010 04 11
  foreach my $table (@pgtables) {					# updated to get values from postgres 2006 12 19
    my $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
#       my $wbgene = 'WBGene' . $row[0];
      my $wbgene = $row[0];
      push @{ $cdsToGene{locus}{$row[1]} }, $wbgene; 
      if ($table eq 'gin_locus') { my ($upLocus) = uc($row[1]); push @{ $cdsToGene{locus}{$upLocus} }, $wbgene; }	# match fully upcased locus names  2009 10 19
  } }

  push @{ $cdsToGene{locus}{'GPR-1/2'} }, "00001688";
  push @{ $cdsToGene{locus}{'GPR-1/2'} }, "00001689";
 
  if ($cdsToGene{locus}{run}) { delete $cdsToGene{locus}{run}; }	# Andrei's exclusion list 2006 07 15
  if ($cdsToGene{locus}{SC}) { delete $cdsToGene{locus}{SC}; }
  if ($cdsToGene{locus}{GATA}) { delete $cdsToGene{locus}{GATA}; }
  if ($cdsToGene{locus}{eT1}) { delete $cdsToGene{locus}{eT1}; }
  if ($cdsToGene{locus}{RhoA}) { delete $cdsToGene{locus}{RhoA}; }
  if ($cdsToGene{locus}{TBP}) { delete $cdsToGene{locus}{TBP}; }
  if ($cdsToGene{locus}{syn}) { delete $cdsToGene{locus}{syn}; }
  if ($cdsToGene{locus}{TRAP240}) { delete $cdsToGene{locus}{TRAP240}; }
  if ($cdsToGene{locus}{'AP-1'}) { delete $cdsToGene{locus}{'AP-1'}; }
} # sub getLoci


