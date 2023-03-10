#!/usr/bin/perl -w

# in parsing variations we find that many genes in the .ace file are not in the corresponding tor/ted/nondir tables in postgres.  find out which.
# 2013 03 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;



my @geneTables = qw( genenondir geneone genetwo );
my %genePg;
my %intToPgid;
my %intPg; my %int;
$result = $dbh->prepare( "SELECT * FROM int_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $intToPgid{$row[1]} = $row[0]; } }	# chris says interaction OA only has one pgid per int object
foreach my $table (@geneTables) {
  $result = $dbh->prepare( "SELECT * FROM int_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      $intPg{$table}{$row[0]} = $row[1];
      $row[1] =~ s/^\"//; $row[1] =~ s/\"$//;
      my @genes = split/","/, $row[1];
      foreach my $gene (@genes) {
        $genePg{$table}{$row[0]}{$gene}++; } } }
} # foreach my $table (@geneTables)

my $infile = 'CM224Interaction.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my ($int) = $header =~ m/"WBInteraction(\d+)"/;
  $int = 'WBInteraction00' . $int;
  my (@geneone) = $para =~ m/Effector\s+"(WBGene\d+)"/;
  @geneone = sort @geneone; my $aceone = join", ", sort @geneone;
  my (@genetwo) = $para =~ m/Effected\s+"(WBGene\d+)"/;
  @genetwo = sort @genetwo; my $acetwo = join", ", sort @genetwo;
  my (@genenondir) = $para =~ m/Non_directional\s+"(WBGene\d+)"/;
  @genenondir = sort @genenondir; my $acenondir = join", ", sort @genenondir;

  unless ($intToPgid{$int}) { print "INT $int has no pgid\n"; next; }
  my $pgid = $intToPgid{$int};
  my $pgone = join", ", sort keys %{ $genePg{geneone}{$pgid} };
  my $pgtwo = join", ", sort keys %{ $genePg{genetwo}{$pgid} };
  my $pgnondir = join", ", sort keys %{ $genePg{genenondir}{$pgid} };

  my $bad = 0;
  unless ($pgone eq $aceone) { print "$int\t$pgid\tint_geneone\tace $aceone\tpg $pgone\n"; $bad++; }
  unless ($pgtwo eq $acetwo) { print "$int\t$pgid\tint_genetwo\tace $acetwo\tpg $pgtwo\n"; $bad++; }
  unless ($pgnondir eq $acenondir) { print "$int\t$pgid\tint_genenondir\tace $acenondir\tpg $pgnondir\n"; $bad++; }

  unless ($bad) { print "$int\t$pgid\tOK\n"; }

} # while (my $line = <IN>) 
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

__END__


Interaction : "WBInteraction0006001"
Interactor	 "WBGene00000186" Variation "WBVar00248949"
Interactor	 "WBGene00007135"
Enhancement	 Interaction_RNAi "WBRNAi00064474"
Enhancement	 Effector "WBGene00007135"
Enhancement	 Effected "WBGene00000186"
Enhancement	 Interaction_phenotype "WBPhenotype:0000050"
Enhancement	 Interaction_phenotype "WBPhenotype:0000688"
Paper	 "WBPaper00027756"
Remark	 "37 mutant worm strains were screened with an RNAi library consisting of 1,860 bacterial feeding strains targeting 1,744 different worm genes. All of the RNAi clones that gave a stronger RNAi phenotype in at least one worm strain compared with wild-type worms were retested in all of the 37 query strains (in duplicate) in order to reduce the rate of false negatives. All interactions from this second round of screening were retested, and interactions observed in at least two of four repeats were considered as positives, giving a total of 377 interactions between query strains and library RNAi clones (equivalent to 349 interactions between 162 genes)"

Interaction : "WBInteraction0006002"
Interactor	 "WBGene00000186" Variation "WBVar00248949"
Interactor	 "WBGene00015203"
Enhancement	 Interaction_RNAi "WBRNAi00064475"
Enhancement	 Effector "WBGene00015203"
Enhancement	 Effected "WBGene00000186"
Enhancement	 Interaction_phenotype "WBPhenotype:0000688"
Paper	 "WBPaper00027756"
Remark	 "37 mutant worm strains were screened with an RNAi library consisting of 1,860 bacterial feeding strains targeting 1,744 different worm genes. All of the RNAi clones that gave a stronger RNAi phenotype in at least one worm strain compared with wild-type worms were retested in all of the 37 query strains (in duplicate) in order to reduce the rate of false negatives. All interactions from this second round of screening were retested, and interactions observed in at least two of four repeats were considered as positives, giving a total of 377 interactions between query strains and library RNAi clones (equivalent to 349 interactions between 162 genes)"

Interaction : "WBInteraction0008486"
Interactor	 "WBGene00002992" Variation "WBVar00089466"
Interactor	 "WBGene00003020"
Interactor	 "WBGene00023498" Variation "WBVar00089738"
Synthetic	 Interaction_RNAi "WBRNAi00075397"
Synthetic	 Effector "WBGene00003020"
Synthetic	 Effected "WBGene00002992"
Synthetic	 Effected "WBGene00023498"
Synthetic	 Interaction_phenotype "WBPhenotype:0000700"
Paper	 "WBPaper00029258"
