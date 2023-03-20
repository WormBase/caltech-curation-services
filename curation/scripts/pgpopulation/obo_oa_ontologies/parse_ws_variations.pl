#!/usr/bin/env perl

# Take WSVariations.ace from Wen dump, process to generate mapping of Variations to Genes.
# Use output in nightly_geneace.pl to add Gene connections to Variations from nightly geneace.
# For Kimberly.  2022 01 27
#
# Updated to check if Wen's source file changed in the last 24 hours, and only generates a 
# new file if that's the case.  Called by nightly_geneace.pl always.  For Kimberly.  2021 02 07

use strict;
use Dotenv -load => '/usr/lib/.env';

my $infile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/dump_from_ws/files/WSVariation.ace';
# my $infile = '/home2/acedb/cron/dump_from_ws/files/WSVariation.ace';

if (-M $infile < 1) {		# infile modified in the last 24 hours

  my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/obo_oa_ontologies/geneace/WSVar_Genes.ace';
  # my $outfile = '/home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/WSVar_Genes.ace';
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  
  my $count = 0;
  
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) {
  #   $count++; last if ($count > 5);
    my ($objName) = $entry =~ m/ : \"(.*?)\"/;
    my (@genes) = $entry =~ m/"(WBGene\d+)"/g;
    my $genes = join", ", @genes;
    if ($genes) {
      print OUT qq($objName\t$genes\n);
    }
  
  }
  close (IN) or die "Cannot close $infile : $!";
  
  close (OUT) or die "Cannot close $outfile : $!";
}
