#!/usr/bin/perl

# check all entries here are unique  https://fmsdev.alliancegenome.org/api/datasubtype/all

use strict;

my %name;
my %id;

my $infile = 'dataSubType';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/"name" : "(.*?)"/) { $name{$1}++; }
  if ($line =~ m/"id" : (\d+)/) { $id{$1}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $name (sort keys %name) {
  my $count = $name{$name};
  if ($count > 1) { print qq(TOO MANY name $name $count\n); }
    else { print qq(name $name $count\n); }
}

# foreach my $id (sort keys %id) {
#   my $count = $id{$id};
#   if ($count > 1) { print qq(TOO MANY id $id $count\n); }
#     else { print qq(ID $id $count\n); }
# }

__END__

[
   {
      "name" : "RGD",
      "description" : "Rat Genome Database",
      "id" : 42
   },
   {
      "id" : 43,
      "name" : "HUMAN",
      "description" : "Human"
   },
   {
      "name" : "FB",
      "description" : "Fly Base",
      "id" : 44
   },
   {
      "id" : 45,
      "description" : "Mouse Genome Database",
      "name" : "MGI"
   },
   {
      "description" : "Zebrafish Information Network",
      "name" : "ZFIN",
      "id" : 46
   },
   {
      "id" : 47,
      "description" : "Worm Base",
      "name" : "WB"
   },
   {
      "name" : "SGD",
      "description" : "Saccharomyces Genome Database",
      "id" : 48
   },
   {
      "description" : "Gene Ontology File",
      "name" : "GO",
      "id" : 561
   },
   {
      "id" : 571,
      "description" : "ZFA Ontology File",
      "name" : "ZFA"
   },
   {
      "id" : 572,
      "description" : "SO Ontology File",
      "name" : "SO"
   },
   {
      "id" : 573,
      "description" : "MMO Ontology File",
      "name" : "MMO"
   },
   {
      "name" : "ZFS",
      "description" : "ZFS Ontology File",
      "id" : 574
   },
   {
      "description" : "MI Ontology File",
      "name" : "MI",
      "id" : 575
   },
   {
      "description" : "UBERON Ontology File",
      "name" : "UBERON",
      "id" : 576
   },
   {
      "name" : "ECO",
      "description" : "ECO Ontology File",
      "id" : 577
   },
   {
      "description" : "WBBT Ontology File",
      "name" : "WBBT",
      "id" : 578
   },
   {
      "description" : "FBBT Ontology File",
      "name" : "FBBT",
      "id" : 579
   },
   {
      "id" : 580,
      "name" : "MA",
      "description" : "MA Ontology File"
   },
   {
      "description" : "CL Ontology File",
      "name" : "CL",
      "id" : 581
   },
   {
      "name" : "DOID",
      "description" : "DOID Ontology File",
      "id" : 582
   },
   {
      "id" : 583,
      "description" : "MMUSDV Ontology File",
      "name" : "MMUSDV"
   },
   {
      "description" : "EMAPA Ontology File",
      "name" : "EMAPA",
      "id" : 584
   },
   {
      "id" : 585,
      "name" : "BSPO",
      "description" : "BSPO Ontology File"
   },
   {
      "name" : "FBCV",
      "description" : "FBCV Ontology File",
      "id" : 586
   },
   {
      "id" : 587,
      "description" : "WBLS Ontology File",
      "name" : "WBLS"
   },
   {
      "name" : "ECOMAP",
      "description" : "Evidence Code Translation File",
      "id" : 589
   },
   {
      "name" : "Assembly",
      "description" : "Assembly",
      "id" : 625
   },
   {
      "id" : 626,
      "name" : "MOLECULAR",
      "description" : "Molecular Interactions"
   },
   {
      "id" : 647,
      "description" : "FlyBase-Assembly-R6.27",
      "name" : "FlyBaseAssemblyR6.27"
   },
   {
      "description" : "MGI-Assembly-GRCm38",
      "name" : "MGIAssemblyGRCm38",
      "id" : 648
   },
   {
      "name" : "ZFinAssemblyGRCz11",
      "description" : "ZFin-Assembly-GRCz11",
      "id" : 649
   },
   {
      "name" : "RGDAssemblyRnor60",
      "description" : "RGD-Assembly-Rnor6.0",
      "id" : 650
   },
   {
      "id" : 651,
      "name" : "WormBaseAssemblyWBcel235",
      "description" : "WormBase-Assembly-WBcel235"
   },
   {
      "description" : "MGI-Assembly-GRCm38",
      "name" : "GRCm38",
      "id" : 658
   },
   {
      "id" : 659,
      "description" : "RGD Assembly Rnor_6.0",
      "name" : "Rnor60"
   },
   {
      "name" : "GRCz11",
      "description" : "ZFin Assembly GRCz11",
      "id" : 660
   },
   {
      "id" : 661,
      "name" : "WBcel235",
      "description" : "WB Assembly WBcel235"
   },
   {
      "id" : 662,
      "description" : "FB Assembly R6.27",
      "name" : "R627"
   },
   {
      "name" : "AGM",
      "description" : "AffectedGenomicModel supertype for genotype,strain,fish",
      "id" : 795
   },
   {
      "id" : 1091,
      "name" : "R6",
      "description" : "FB assembly"
   },
   {
      "name" : "This can be used when there is no sub grouping",
      "description" : "ALL",
      "id" : 1101
   },
   {
      "name" : "ALL",
      "description" : "This can be used when there is no sub grouping",
      "id" : 1105
   },
   {
      "id" : 1121,
      "description" : "Biological General Repository for Interaction Datasets",
      "name" : "BIOGRID"
   },
   {
      "name" : "IMEX",
      "description" : "The International Molecular Exchange Consortium",
      "id" : 1122
   },
   {
      "id" : 1123,
      "description" : "Combined Mod Files",
      "name" : "COMBINED"
   },
   {
      "description" : "BioGrid physical interactions by organism",
      "name" : "BIOGRID-ORGANISM",
      "id" : 1207
   },
   {
      "name" : "0.0.6",
      "description" : "Version 0.0.6",
      "id" : 1460
   },
   {
      "name" : "1.0.0",
      "description" : "Version 1.0.0",
      "id" : 1461
   },
   {
      "description" : "Version 1.0.1",
      "name" : "1.0.1",
      "id" : 1462
   },
   {
      "name" : "1.0.2",
      "description" : "Version 1.0.2",
      "id" : 1463
   },
   {
      "name" : "1.0.3",
      "description" : "Version 1.0.3",
      "id" : 1464
   },
   {
      "name" : "1.0.4",
      "description" : "Version 1.0.4",
      "id" : 1465
   },
   {
      "id" : 1466,
      "description" : "Version 1.0.5",
      "name" : "1.0.5"
   },
   {
      "description" : "Version 1.0.5",
      "name" : "1.3.0",
      "id" : 1467
   },
   {
      "description" : "Version 1.0.5",
      "name" : "1.4.0",
      "id" : 1468
   },
   {
      "description" : "Version 1.0.5",
      "name" : "1.6.0",
      "id" : 1469
   },
   {
      "id" : 1470,
      "description" : "Version 1.0.5",
      "name" : "1.7.0"
   },
   {
      "id" : 1471,
      "name" : "1.8.0",
      "description" : "Version 1.0.5"
   },
   {
      "name" : "2.0.0",
      "description" : "Version 1.0.5",
      "id" : 1472
   },
   {
      "name" : "2.1.0",
      "description" : "Version 1.0.5",
      "id" : 1473
   },
   {
      "id" : 1474,
      "name" : "2.2.0",
      "description" : "Version 1.0.5"
   },
   {
      "id" : 1475,
      "name" : "2.3.0",
      "description" : "Version 1.0.5"
   },
   {
      "name" : "3.0.0",
      "description" : "Version 3.0.0",
      "id" : 1504
   },
   {
      "id" : 5037,
      "name" : "GO",
      "description" : "Gene Ontology File"
   },
   {
      "id" : 7979,
      "name" : "FYPO",
      "description" : "Fission Yeast Phenotype Ontology File"
   },
   {
      "name" : "WBPhenotype",
      "description" : "WormBase Phenotype Ontology File",
      "id" : 7981
   },
   {
      "id" : 7983,
      "name" : "DPO",
      "description" : "Drosophila Phenotype Ontology File"
   },
   {
      "id" : 7985,
      "description" : "Phenotype and Trait Ontology File",
      "name" : "PATO"
   },
   {
      "id" : 7987,
      "description" : "Mammalian Phenotype Ontology File",
      "name" : "MP"
   },
   {
      "description" : "Human Phenotype Ontology File",
      "name" : "HP",
      "id" : 7989
   },
   {
      "id" : 7991,
      "name" : "APO",
      "description" : "Ascomycete Phenotype Ontology File"
   },
   {
      "id" : 9834,
      "description" : "BIOGRID PSI File",
      "name" : "BIOGRID-PSI"
   },
   {
      "id" : 9836,
      "description" : "BIOGRID TAB File",
      "name" : "BIOGRID-TAB"
   },
   {
      "id" : 30338,
      "description" : "Ontology for Biomedical Investigations",
      "name" : "OBI"
   }
]
