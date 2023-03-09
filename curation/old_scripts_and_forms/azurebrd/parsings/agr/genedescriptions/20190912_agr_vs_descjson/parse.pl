#!/usr/bin/perl


use strict;
use Text::CSV_XS qw( csv );
use JSON;

my %geneHasDescription;
my %geneToBiotype;


my @mods = qw(FB HUMAN MGI RGD SGD WB ZFIN);
# my @mods = qw(WB );

foreach my $mod (@mods) {
  my $infile = $mod . '.desc.json';
  $/ = undef;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $json = <IN>;
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";
  
  my $perlHashref = decode_json ($json);
  # print qq($perl\n);
  my %perl = %$perlHashref;
  # print qq($perl{"general_stats"}{"total_number_of_genes"}\n); 
  
  foreach my $entryHref (@{ $perl{"data"} }) {
    my %entry = %$entryHref;
    my $geneid = $entry{"gene_id"};
    my $description = 0;
    if ($entry{"description"}) { $description++; }
    $geneHasDescription{$geneid} = $description;
  #   print qq($entry{"gene_id"}\n);
  #   print qq($entry{"description"}\n);
  }  
}

my $summaryFile = 'output/summaryFile';
open (SUM, ">$summaryFile") or die "Cannot create $summaryFile : $!"; 
print SUM qq(mod\tbiotype\tcount_yes\tcount_no\n);

my %geneToName;
my %modToType;
my $aoa = csv (in => "export.csv");    # as array of array
foreach my $line (@$aoa) {
  my $gene = @$line[0];
#   next if ($gene eq 'g.primaryKey');
  my ($mod) = $gene =~ m/^(.*?):/;
  my $biotype = @$line[2];
  next if ($biotype eq 's.name');
  $geneToBiotype{$gene} = $biotype;
  my $hasDescription = 'no';
  if ( $geneHasDescription{$gene} ) { $hasDescription = 'yes'; }
  $geneToName{$gene} = @$line[1];
  $modToType{$mod}{$biotype}{$hasDescription}{$gene}++;
#   print qq($gene\t$biotype\n);
}

foreach my $mod (sort keys %modToType) {
#   next unless ($mod eq 'WB');
  foreach my $biotype (sort keys %{ $modToType{$mod} }) {
    my $count_yes = 0; my $count_no = 0;
    foreach my $hasDescription (sort keys %{ $modToType{$mod}{$biotype} }) {
      if ($hasDescription eq 'yes') { $count_yes = scalar keys %{ $modToType{$mod}{$biotype}{$hasDescription} }; }
      if ($hasDescription eq 'no')  { $count_no  = scalar keys %{ $modToType{$mod}{$biotype}{$hasDescription} }; }
#       my $terms = join"\n", sort keys %{ $modToType{$mod}{$biotype}{$hasDescription} };
      my $outfile = 'output/' . $mod . '_' . $biotype . '_' . $hasDescription;
      open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
      foreach my $gene (sort keys %{ $modToType{$mod}{$biotype}{$hasDescription} }) {
        print OUT qq($gene\t$geneToName{$gene}\n);
      } # foreach my $gene (sort keys %{ $modToType{$mod}{$biotype}{$hasDescription} })
#       print OUT qq($terms);
      close (OUT) or die "Cannot close $outfile : $!";
    } # foreach my $hasDescription (sort keys %{ $modToType{$mod}{$biotype} })
    print SUM qq($mod\t$biotype\t$count_yes\t$count_no\n);
  } # foreach my $biotype (sort keys %{ $modToType{$mod} })
}

close (SUM) or die "Cannot close $summaryFile : $!"; 

#    "data": [
#         {
#             "gene_id": "WB:WBGene00000001",
#             "gene_name": "aap-1",
#             "description": "Exhibits protein kinase binding activity. Involved in dauer larval development; determination of adult lifespan; and insulin receptor signaling pathway. Localizes to the phosphatidylinositol 3-kinase complex. Human ortholog(s) of this gene implicated in several diseases, including astroblastoma; carcinoma (multiple); endometrial cancer (multiple); primary immunodeficiency disease (multiple); and type 2 diabetes mellitus. Is expressed in intestine and neurons. Orthologous to several human genes including PIK3R3 (phosphoinositide-3-kinase regulatory subunit 3).",
# 

#     "general_stats": {
#         "total_number_of_genes": 48021,

