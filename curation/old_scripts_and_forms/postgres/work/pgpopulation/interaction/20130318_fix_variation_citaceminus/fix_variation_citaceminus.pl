#!/usr/bin/perl -w

# some interaction variations in citaceMinus are not in the OA, try to put the in.
# we find that the .ace genes and postgres genes do not map properly, so put this in hold.  2013 03 18
#
# chris finds that we can ignore the .ace mapping of gene to non/one/two, but we can use the 
# ace file for var -> gene, then use postgres interaction+gene to non/one/two and place the
# variations there.
# get int_name to pgid.  get pgid to gene list.  get pgid to variation list.
# get new int-var pairs from txt file.  get .ace file to parse each interaction object
# to get each variation to wbgene.  use that wbgene to get non/one/two from postgres.
# check if variation already in that slot in postgres (notify) or add to list and flag
# to change.  for all that should change, delete from data table and insert full list
# to data table and history table.  2013 03 19
#
# live run on tazendra. 2013 03 19


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
  if ($row[0]) { $intToPgid{$row[1]} = $row[0]; } }     # chris says interaction OA only has one pgid per int object
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

my @varTables = qw( variationnondir variationone variationtwo );
foreach my $table (@varTables) {
  $result = $dbh->prepare( "SELECT * FROM int_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      $intPg{$table}{$row[0]} = $row[1];
      $row[1] =~ s/^\"//; $row[1] =~ s/\"$//;
      my @vars = split/","/, $row[1];
      foreach my $var (@vars) {
        $int{$table}{$row[0]}{$var}++; } } }
} # foreach my $table (@varTables)


my %intToVar; my %intToVarDone;
my $infile = 'Int_Var_pairs_in_CM_not_WS236.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($int, $var) = split/\t/, $line;
  $intToVar{$int}{$var}++;
} # while (my $line = <IN>) 
close (IN) or die "Cannot close $infile : $!";

foreach my $int (sort keys %intToVar) { 
  my @vars = sort keys %{ $intToVar{$int} };
  if (scalar @vars > 1) { print "MULTI $int\t@vars\n"; }
} # foreach my $int (sort keys %intToVar) 

my @pgcommands;

$infile = 'CM224Interaction.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my ($int) = $header =~ m/"WBInteraction(\d+)"/;
  $int = 'WBInteraction00' . $int;
  next unless ($intToVar{$int});
  $intToVarDone{$int}++;
  unless ($intToPgid{$int}) { print "INT $int has no pgid\n"; next; }
  my $pgid = $intToPgid{$int};
  my %changed;
  foreach my $var (sort keys %{ $intToVar{$int} }) {
    my %genes;
    foreach my $line (@lines) { if ($line =~ m/$var/) { my ($gene) = $line =~ m/"(WBGene\d+)"/; $genes{$gene}++; } }
    foreach my $gene (sort keys %genes) {
      my ($nondir, $tor, $ted) = ('', '', '');
      if ( $genePg{"genenondir"}{$pgid}{$gene} ) { $nondir++; }	# get non/one/two from postgres based on the gene from the .ace file
      if ( $genePg{"geneone"}{$pgid}{$gene} ) { $tor++; }
      if ( $genePg{"genetwo"}{$pgid}{$gene} ) { $ted++; }
#       foreach my $line (@lines) {				# for old method of getting non/one/two from .ace file
#         if ($line =~ m/Non_directional\s+"$gene"/) { $nondir++; }
#         if ($line =~ m/Effector\s+"$gene"/) { $tor++; }
#         if ($line =~ m/Effected\s+"$gene"/) { $ted++; }
#       }
      my @geneType = (); 
      if ($nondir) { push @geneType, "variationnondir"; }
      if ($tor) { push @geneType, "variationone"; }
      if ($ted) { push @geneType, "variationtwo"; }
      my $geneType = join", ", @geneType;
      if (scalar(@geneType) > 1) { 
        print "ERR multiple gene types : "; 
        print "$int\t$var\t$gene\t$geneType\n";
        next; }
      unless ($geneType) { 
        print "ERR no gene mapping : "; 
        print "$int\t$var\t$gene\t$geneType\n";
        next; }

      print "$int\t$var\t$gene\t$geneType\n";
      if ($int{$geneType}{$pgid}{$var}) { print "ALREADY IN $int\t$var\t$gene\t$geneType\n"; }
        else { 
          $changed{$geneType}{$pgid}++; 
          $int{$geneType}{$pgid}{$var}++; }

#       my $table = $geneType; $table =~ s/variation/gene/; 	# old method we checked whether or not the gene existed in the corresponding table, new method requires it so the check is not needed.
#       my (@genes) = sort keys %{ $genePg{$table}{$pgid} };
#       my $table_genes = 'blank'; if (scalar(@genes) > 0) { $table_genes = join ", ", @genes; }
#       if ($genePg{$table}{$pgid}{$gene}) { 
#           print "mapped gene $gene OK IN TABLE $table HAS $table_genes\n"; }
#         else { 
#           print "mapped gene $gene NOT IN TABLE $table HAS $table_genes\n"; }

    } # foreach my $gene (sort keys %genes)
  } # foreach my $var (sort keys %{ $intToVar{$int} })
  foreach my $geneType (sort keys %changed) {
    foreach my $pgid (sort keys %{ $changed{$geneType} }) {
      my $newvars = join'","', sort keys %{ $int{$geneType}{$pgid} }; $newvars = '"' . $newvars . '"';
      my $oldvars = 'blank';
      if ($intPg{$geneType}{$pgid}) { $oldvars = $intPg{$geneType}{$pgid}; }
      print "$geneType\t$pgid\t$int\tOLD $oldvars\tNEW $newvars\n";
      push @pgcommands, qq(DELETE FROM int_$geneType WHERE joinkey = '$pgid');
      push @pgcommands, qq(INSERT INTO int_$geneType VALUES ( '$pgid', '$newvars' ));
      push @pgcommands, qq(INSERT INTO int_${geneType}_hst VALUES ( '$pgid', '$newvars' ));
    } # foreach my $pgid (sort keys %{ $changed{$geneType} })
  } # foreach my $geneType (sort keys %changed)
} # while (my $line = <IN>) 
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $int (sort keys %intToVar) {
  next if ($intToVarDone{$int});
  foreach my $var (sort keys %{ $intToVar{$int} }) {
    print "NOT PROCESSED $int\t$var\n";
  }
} # foreach my $int (sort keys %intToVar)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)



__END__


WBInteraction000006001	WBVar00248949
WBInteraction000006002	WBVar00248949
WBInteraction000008486	WBVar00089466
WBInteraction000008486	WBVar00089738

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
