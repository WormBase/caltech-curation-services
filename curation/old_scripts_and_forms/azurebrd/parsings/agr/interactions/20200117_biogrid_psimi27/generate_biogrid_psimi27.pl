#!/usr/bin/perl

# generate psi-mi tab file format 2.7 for biogrid data for agr
# https://docs.google.com/document/d/16haMujZ2ZeN2jg13AvxageXouZBeVOWrqPRbJakt6dc/edit

# download from
# https://downloads.thebiogrid.org/BioGRID
# https://downloads.thebiogrid.org/Download/BioGRID/Latest-Release/BIOGRID-ALL-LATEST.tab2.zip
# https://downloads.thebiogrid.org/Download/BioGRID/Latest-Release/BIOGRID-ALL-LATEST.mitab.zip

use strict;
use diagnostics;

my $mitabFile = 'BIOGRID-ALL-3.5.180.mitab.txt';
my $tab20File = 'BIOGRID-ALL-3.5.180.tab2.txt';

my %approvedCol12 = (
  'psi-mi:"MI:0794"(synthetic genetic interaction defined by inequality)' => 1,
  'psi-mi:"MI:0796"(suppressive genetic interaction defined by inequality)' => 1,
  'psi-mi:"MI:0799"(additive genetic interaction defined by inequality)' => 1,
);

my %validTaxons = (
  'taxid:9606' => 1,
  'taxid:559292' => 1,
  'taxid:7227' => 1,
  'taxid:6239' => 1,
  'taxid:10090' => 1,
  'taxid:10116' => 1,
  'taxid:7955' => 1,
);

my %geneticInteractionTerms = (
  'Dosage Growth Defect'         => { '19' => '-', '20' => '-' },
  'Dosage Lethality'             => { '19' => '-', '20' => '-' },
  'Dosage Rescue'                => { '19' => 'suppressed', '20' => 'suppressor' },
  'Negative Genetic'             => { '19' => '-', '20' => '-' },
  'Phenotypic Enhancement'       => { '19' => 'enhanced', '20' => 'enhancer' },
  'Phenotypic Suppression'       => { '19' => 'suppressed', '20' => 'suppressor' },
  'Positive Genetic'             => { '19' => '-', '20' => '-' },
  'Synthetic Growth Defect'      => { '19' => '-', '20' => '-' },
  'Synthetic Haploinsufficiency' => { '19' => '-', '20' => '-' },
  'Synthetic Lethality'          => { '19' => '-', '20' => '-' },
  'Synthetic Rescue'             => { '19' => '-', '20' => '-' }
);



my %tab20;
open (IN, "<$tab20File") or die "Cannot open $tab20File : $!";
my $header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my (@line) = split/\t/, $line;
# if ($line[0] =~ m/76746/) { print qq(YUP line1 $line[0] line $line\n); }
  my $key = 'biogrid:' . $line[0];
  $tab20{$key} = $line;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $tab20File : $!";

open (IN, "<$mitabFile") or die "Cannot open $mitabFile : $!";
$header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my (@line) = split/\t/, $line;
  next unless $approvedCol12{$line[11]};
  next unless ($line[12] eq 'psi-mi:"MI:0463"(biogrid)');
  next unless $validTaxons{$line[9]};
  next unless $validTaxons{$line[10]};
  for my $i (14 .. 35) { $line[$i] = '-'; }
  $line[20] = 'psi-mi:"MI:0250"(gene)';
  $line[21] = 'psi-mi:"MI:0250"(gene)';
  $line[35] = 'false';

  my $biogrid = $line[13];
  my $tab20line = $tab20{$biogrid};
  my (@tab20line) = split/\t/, $tab20line;
  next unless ($tab20line[23] eq 'BIOGRID');
  $line[27] = $tab20line[20];
  my $physicalOrGenetic = $tab20line[12];
  $line[11] = $tab20line[11];
  if ($geneticInteractionTerms{$line[11]}) { 
      $line[18] = $geneticInteractionTerms{$line[11]}{'19'};
      $line[19] = $geneticInteractionTerms{$line[11]}{'20'}; }
   else { print qq(ERROR $line[11] tab2.0 col12 not a valid genetic Interaction Term\n); }

  my $line = join"\t", @line;
  print qq($line\n);
} # while (my $line = <IN>)
close (IN) or die "Cannot close $mitabFile : $!";
