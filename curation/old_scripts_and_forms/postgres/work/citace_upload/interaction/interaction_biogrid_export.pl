#!/usr/bin/perl -w

# dump data for Biogrid.  2015 02 23
#
# To generate ncbi_geneinfo
# cd /home2/postgres/work/citace_upload/interaction/
# wget "ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_info.gz"
# zcat gene_info.gz | awk '{if ($1==6239) print $0}' | grep CELE > ncbi_geneinfo
# 2015 02 25
#
# Updated for int_gimodule one/two/three for Chris.  2017 12 05


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my %wbgeneToEntrez;
# my $entrezGeneMapFile = '/home/postgres/work/citace_upload/interaction/Celegans_Entrez_Gene_IDs_from_BioMart.txt';
# open (IN, "<$entrezGeneMapFile") or die "Cannot open $entrezGeneMapFile : $!";
# while (my $line = <IN>) { chomp $line;  my ($wbg, $entrez, $locus) = split/\t/, $line; $wbgeneToEntrez{$wbg} = $entrez; } 
# close (IN) or die "Cannot close $entrezGeneMapFile : $!";

my %seqnameToEntrez;
my %locusToEntrez;
my $entrezGeneMapFile = '/home2/postgres/work/citace_upload/interaction/ncbi_geneinfo';
# my $entrezGeneMapFile = '/home2/postgres/work/citace_upload/interaction/Caenorhabditis_elegans.gene_info';
open (IN, "<$entrezGeneMapFile") or die "Cannot open $entrezGeneMapFile : $!";
while (my $line = <IN>) { 
  chomp $line;
  my ($mod, $entrez, $locus, $cele) = split/\t/, $line; 
  $locusToEntrez{$locus} = $entrez;
  my ($seq) = $cele =~ m/CELE_(.*)$/;
  $seqnameToEntrez{$seq} = $entrez; } 
close (IN) or die "Cannot close $entrezGeneMapFile : $!";

my $outfile = 'biogrid.tab';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my @header;
push @header, "PostgreSQL ID";
push @header, "WormBase Interaction ID";
push @header, "#BioGRID Interaction ID";
push @header, "Entrez Gene Interactor A";
push @header, "Entrez Gene Interactor B";
push @header, "BioGRID ID Interactor A";
push @header, "BioGRID ID Interactor B";
push @header, "Systematic Name Interactor A";
push @header, "Systematic Name Interactor B";
push @header, "Official Symbol Interactor A";
push @header, "Official Symbol Interactor B";
push @header, "Synonyms Interactor A";
push @header, "Synonyms Interactor B";
push @header, "Experimental System";
push @header, "Experimental System Type";
push @header, "Author";
push @header, "Pubmed ID";
push @header, "Organism Interactor A";
push @header, "Organism Interactor B";
push @header, "Throughput";
push @header, "Score";
push @header, "Modification";
push @header, "Phenotypes";
push @header, "Qualifications";
push @header, "Tags";
push @header, "Source Database";
my $header = join"\t", @header;
print OUT qq($header\n);

my $errfile = 'biogrid.err';
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my %papToPmid;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $row[1] =~ s/pmid//;
  $papToPmid{"WBPaper$row[0]"} = $row[1]; }

my %phenToName;
$result = $dbh->prepare( "SELECT * FROM obo_name_phenotype " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $phenToName{$row[0]} = $row[1]; }

my %ginSeqname;
$result = $dbh->prepare( "SELECT * FROM gin_seqname " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ginSeqname{"WBGene$row[0]"} = $row[1]; }

my %ginLocus;
$result = $dbh->prepare( "SELECT * FROM gin_locus " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $ginLocus{"WBGene$row[0]"} = $row[1]; }

my %deadObjects; &populateDeadObjects();
my %mapToGene;
$result = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE obo_data_variation ~ 'WBGene';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my ($name) = $row[1] =~ m/name: \"(.*?)\"/;
  my (@genes) = $row[1] =~ m/(WBGene\d+)/g;
  my $varId = $row[0];
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{allele}{$varId}{$gene}++; $mapToGene{allele}{$name}{$gene}++; } }


my %papExclude;
$papExclude{"WBPaper00006425"}++;
$papExclude{"WBPaper00003570"}++;
$papExclude{"WBPaper00003574"}++;
$papExclude{"WBPaper00003656"}++;
$papExclude{"WBPaper00005042"}++;
$papExclude{"WBPaper00005193"}++;
$papExclude{"WBPaper00005278"}++;
$papExclude{"WBPaper00028371"}++;
$papExclude{"WBPaper00032400"}++;
$papExclude{"WBPaper00037111"}++;
$papExclude{"WBPaper00040136"}++;
$papExclude{"WBPaper00042215"}++;
$papExclude{"WBPaper00042236"}++;
$papExclude{"WBPaper00006212"}++;
$papExclude{"WBPaper00025079"}++;
$papExclude{"WBPaper00025199"}++;
$papExclude{"WBPaper00026603"}++;
$papExclude{"WBPaper00029007"}++;
$papExclude{"WBPaper00027756"}++;
$papExclude{"WBPaper00029258"}++;
$papExclude{"WBPaper00030897"}++;
$papExclude{"WBPaper00031036"}++;
$papExclude{"WBPaper00031110"}++;

my %typeExclude;
$typeExclude{"Physical"}++;
$typeExclude{"ProteinProtein"}++;
$typeExclude{"ProteinDNA"}++;
$typeExclude{"ProteinRNA"}++;
$typeExclude{"Predicted"}++;
$typeExclude{"No_interaction"}++;

my $papExcludePapers     = join"','", sort keys %papExclude;
my $papExcludeQuery      = qq(SELECT joinkey FROM int_paper WHERE int_paper IN ('$papExcludePapers'));

my $nodumpQuery          = qq(SELECT joinkey FROM int_nodump WHERE int_nodump = 'NO DUMP');

my $typeExclude          = join"' OR int_type = '", sort keys %typeExclude;
# my $typeQuery            = qq(SELECT joinkey FROM int_type WHERE int_type = 'Physical' OR int_type = 'Predicted' OR int_type = 'No_interaction');
my $typeQuery            = qq(SELECT joinkey FROM int_type WHERE int_type = '$typeExclude');

my $falsepositiveQuery   = qq(SELECT joinkey FROM int_falsepositive WHERE int_falsepositive = '');

my %joinkeys;
my $command = qq(SELECT joinkey FROM int_name WHERE joinkey NOT IN ( $papExcludeQuery ) AND joinkey NOT IN ( $nodumpQuery ) AND joinkey NOT IN ( $typeQuery ) AND joinkey NOT IN ( $falsepositiveQuery ) ;);
# print qq($command\n);
$result = $dbh->prepare( $command );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $joinkeys{$row[0]}++; }
my $joinkeys = join"','", sort keys %joinkeys;
# print "J $joinkeys J\n";

my %hash;
my @tables = qw( name paper type summary remark genenondir geneone genetwo variationnondir variationone variationtwo phenotype throughput detectionmethod gimoduleone gimoduletwo gimodulethree );
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM int_${table} WHERE joinkey IN ('$joinkeys')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1] =~ m/\t/) { $row[1] =~ s/\t/ /g; }
    if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
    $hash{$row[0]}{$table} = $row[1];
  } # while (my @row = $result->fetchrow)
} # foreach my $table (@tables)

foreach my $pgid (sort {$a<=>$b} keys %joinkeys) {
  my $lineError   = ''; my $lineWarning   = '';
  my $bioIntId    = '-';
  my $entrezGeneA = '';
  my $entrezGeneB = '';
  my $biogridIntA = '-';
  my $biogridIntB = '-';
# gin_seqname 
  my %genenondir; my %geneone; my %genetwo;
  my %varnondir;  my %varone;  my %vartwo;
  if ($hash{$pgid}{genenondir})       { my (@genes) = $hash{$pgid}{genenondir}      =~ m/(WBGene\d+)/g; foreach (@genes) { $genenondir{$_}++; } }
  if ($hash{$pgid}{geneone})          { my (@genes) = $hash{$pgid}{geneone}         =~ m/(WBGene\d+)/g; foreach (@genes) { $geneone{$_}++;    } }
  if ($hash{$pgid}{genetwo})          { my (@genes) = $hash{$pgid}{genetwo}         =~ m/(WBGene\d+)/g; foreach (@genes) { $genetwo{$_}++;    } }
  if ($hash{$pgid}{variationnondir})  { my (@vars)  = $hash{$pgid}{variationnondir} =~ m/(WBVar\d+)/g;  foreach (@vars)  { $varnondir{$_}++;  } }
  if ($hash{$pgid}{variationone})     { my (@vars)  = $hash{$pgid}{variationone}    =~ m/(WBVar\d+)/g;  foreach (@vars)  { $varone{$_}++;     } }
  if ($hash{$pgid}{variationtwo})     { my (@vars)  = $hash{$pgid}{variationtwo}    =~ m/(WBVar\d+)/g;  foreach (@vars)  { $vartwo{$_}++;     } }
  foreach my $var (sort keys %varnondir) {
    if ($mapToGene{allele}{$var}) { 
        if (scalar keys %{ $mapToGene{allele}{$var} } > 1) { $lineWarning .= qq(Warning PGID $pgid $var maps to multiple genes\n); }	
        foreach my $gene (sort keys %{ $mapToGene{allele}{$var} }) { $genenondir{$gene}++; } }
      else { $lineError .= qq(suppressing PGID $pgid Variation $var does not map to a gene\n); } }
  foreach my $var (sort keys %varone) {
    if ($mapToGene{allele}{$var}) { 
        if (scalar keys %{ $mapToGene{allele}{$var} } > 1) { $lineWarning .= qq(Warning PGID $pgid $var maps to multiple genes\n); }	
        foreach my $gene (sort keys %{ $mapToGene{allele}{$var} }) { $geneone{$gene}++; } }
      else { $lineError .= qq(suppressing PGID $pgid Variation $var does not map to a gene\n); } }
  foreach my $var (sort keys %vartwo) {
    if ($mapToGene{allele}{$var}) { 
        if (scalar keys %{ $mapToGene{allele}{$var} } > 1) { $lineWarning .= qq(Warning PGID $pgid $var maps to multiple genes\n); }	
        foreach my $gene (sort keys %{ $mapToGene{allele}{$var} }) { $genetwo{$gene}++; } }
      else { $lineError .= qq(suppressing PGID $pgid Variation $var does not map to a gene\n); } }

    # check that the genes (after variations mapped to genes) have a locus and entrez gene, or seqname and entrez gene
  foreach my $wbgene (sort keys %genenondir) { 
    my $entrezExists = 0; my $seqname = 'No Seqname'; my $locus = 'No Locus';
    if ($ginLocus{$wbgene}) {
      $locus = $ginLocus{$wbgene};
      if ( $locusToEntrez{$locus} ) { $entrezExists++; } }
    if ($ginSeqname{$wbgene}) { 
      $seqname = $ginSeqname{$wbgene}; 
      if ( $seqnameToEntrez{$seqname} ) { $entrezExists++; } }
    unless ( $entrezExists ) { $lineError .= qq(suppressing PGID $pgid WBGene Nondir $wbgene Locus $locus Seqname $seqname does not map to an entrez gene\n); } }
  foreach my $wbgene (sort keys %geneone) { 
    my $entrezExists = 0; my $seqname = 'No Seqname'; my $locus = 'No Locus';
    if ($ginLocus{$wbgene}) {
      $locus = $ginLocus{$wbgene};
      if ( $locusToEntrez{$locus} ) { $entrezExists++; } }
    if ($ginSeqname{$wbgene}) { 
      $seqname = $ginSeqname{$wbgene}; 
      if ( $seqnameToEntrez{$seqname} ) { $entrezExists++; } }
    unless ( $entrezExists ) { $lineError .= qq(suppressing PGID $pgid WBGene One $wbgene Locus $locus Seqname $seqname does not map to an entrez gene\n); } }
  foreach my $wbgene (sort keys %genetwo) { 
    my $entrezExists = 0; my $seqname = 'No Seqname'; my $locus = 'No Locus';
    if ($ginLocus{$wbgene}) {
      $locus = $ginLocus{$wbgene};
      if ( $locusToEntrez{$locus} ) { $entrezExists++; } }
    if ($ginSeqname{$wbgene}) { 
      $seqname = $ginSeqname{$wbgene}; 
      if ( $seqnameToEntrez{$seqname} ) { $entrezExists++; } }
    unless ( $entrezExists ) { $lineError .= qq(suppressing PGID $pgid WBGene Two $wbgene Locus $locus Seqname $seqname does not map to an entrez gene\n); } }

  my $wbInteractionId = '-';
    if ($hash{$pgid}{name}) { $wbInteractionId = $hash{$pgid}{name}; }
  my $systematicNameA = '-';		# sequence name
  my $systematicNameB = '-';		# sequence name
# gin_locus, if not use seqname
  my $officialNameA = '-';		# locus name
  my $officialNameB = '-';		# locus name
  my $synonymA      = '-';
  my $synonymB      = '-';
#   my $experSysName  = '-';
  my @experSysName = ();
  if ($hash{$pgid}{gimoduleone}) { push @experSysName, $hash{$pgid}{gimoduleone}; }
  if ($hash{$pgid}{gimoduletwo}) { push @experSysName, $hash{$pgid}{gimoduletwo}; }
  if ($hash{$pgid}{gimodulethree}) { push @experSysName, $hash{$pgid}{gimodulethree}; }
  if ($hash{$pgid}{type}) { push @experSysName, $hash{$pgid}{type}; }
  my $experSysName  = join" ", @experSysName;
  my $experSysType  = 'genetic';
#   unless ($hash{$pgid}{type}) { $hash{$pgid}{type} = ''; }
#   if ($hash{$pgid}{type} eq 'Physical') {	
#       $experSysName = $hash{$pgid}{detectionmethod}; 
#       $experSysType = 'physical'; }
#     else {					# for the genetic methods that haven't been skipped
#       $experSysName = $hash{$pgid}{type}; }
  my $author        = '-';
  my $pmid          = '-';			# if no pmid for paper (or lack paper), print blank '-' and error message
    if ($hash{$pgid}{paper}) {
        my $pap = $hash{$pgid}{paper};
        if ($papToPmid{$pap}) { $pmid = $papToPmid{$pap}; }
          else { $lineError .= qq(suppressing PGID $pgid paper $pap does not map to a pmid\n); } }
      else { $lineError .= qq(suppressing PGID $pgid does not have a paper\n); }
  my $orgIdA = '6239';
  my $orgIdB = '6239';
  my $throughput = 'Low Throughput';
  if ($hash{$pgid}{throughput}) { $throughput = 'High Throughput'; }
  my $quantScore   = '-';
  my $modification = '-';
  my $phenotype    = '-';	# convert phenotypes to names and join with |
  if ($hash{$pgid}{phenotype}) {	
    my (@phens) = $hash{$pgid}{phenotype} =~ m/(WBPhenotype:\d+)/g; my @phenNames = ();
    foreach my $phen (@phens) { push @phenNames, $phenToName{$phen}; }
    if (scalar @phenNames > 0) { $phenotype = join"|", @phenNames; } }
  my @quals = ();  
    if ($hash{$pgid}{summary}) { push @quals, $hash{$pgid}{summary}; }
    if ($hash{$pgid}{remark})  { push @quals, $hash{$pgid}{remark};  }
  my $tags = '-';
  my $sourceDatabase = 'WormBase';
  if ($lineError)   { print ERR $lineError;   }			# line errors prevent dumping any data for the pgid
    else {
      my $amountNondirGenes = scalar keys %genenondir;
      if ($amountNondirGenes > 1) {
        if ($amountNondirGenes > 2) { unshift @quals, qq(This interaction involves $amountNondirGenes mutants); }
        my $qualifications = '-';	# int_summary + | + int_remark 
        if (scalar @quals > 0) {     $qualifications = join"|", @quals;  }
        my @genenondir = sort keys %genenondir;
        while (scalar @genenondir > 0) {
          my $geneone = shift @genenondir;
          foreach my $genetwo (@genenondir) {
            if ($ginSeqname{$geneone}) { $systematicNameA = $ginSeqname{$geneone}; }
              else { $lineWarning .= qq(Warning PGID $pgid Nondir $geneone does not map to gin_seqname\n); }
            if ($ginSeqname{$genetwo}) { $systematicNameB = $ginSeqname{$genetwo}; }
              else { $lineWarning .= qq(Warning PGID $pgid Nondir $genetwo does not map to gin_seqname\n); }
            if ($ginLocus{$geneone}) { $officialNameA = $ginLocus{$geneone}; }
              else { $lineWarning .= qq(Warning PGID $pgid Nondir $geneone does not map to gin_locus\n); }
            if ($ginLocus{$genetwo}) { $officialNameB = $ginLocus{$genetwo}; }
              else { $lineWarning .= qq(Warning PGID $pgid Nondir $genetwo does not map to gin_locus\n); }
            if ( $locusToEntrez{$officialNameA} ) {          $entrezGeneA = $locusToEntrez{$officialNameA};     }
              elsif ( $seqnameToEntrez{$systematicNameA} ) { $entrezGeneA = $seqnameToEntrez{$systematicNameA}; }
            if ( $locusToEntrez{$officialNameB} ) {          $entrezGeneB = $locusToEntrez{$officialNameB};     }
              elsif ( $seqnameToEntrez{$systematicNameB} ) { $entrezGeneB = $seqnameToEntrez{$systematicNameB}; }
#             if ( $wbgeneToEntrez{$geneone} ) { $entrezGeneA = $wbgeneToEntrez{$geneone}; }
#             if ( $wbgeneToEntrez{$genetwo} ) { $entrezGeneB = $wbgeneToEntrez{$genetwo}; }
            print OUT qq(PGID $pgid\t$wbInteractionId\t$bioIntId\t$entrezGeneA\t$entrezGeneB\t$biogridIntA\t$biogridIntB\t$systematicNameA\t$systematicNameB\t$officialNameA\t$officialNameB\t$synonymA\t$synonymB\t$experSysName\t$experSysType\t$author\t$pmid\t$orgIdA\t$orgIdB\t$throughput\t$quantScore\t$modification\t$phenotype\t$qualifications\t$tags\t$sourceDatabase\n);
          } # foreach my $genetwo (@genenondir)
        } # while (scalar @genenondir > 0)
      } # if (scalar keys %genenondir > 1)
      my $amountDirGeneOne = scalar keys %geneone;
      my $amountDirGeneTwo = scalar keys %genetwo;
      my $amountDirGenes   = $amountDirGeneOne + $amountDirGeneTwo;
      if ($amountDirGenes > 1) {
        if ($amountDirGenes > 2) { unshift @quals, qq(This interaction involves $amountDirGenes mutants); }
        my $qualifications = '-';	# int_summary + | + int_remark 
        if (scalar @quals > 0) {     $qualifications = join"|", @quals;  }
        foreach my $geneone (sort keys %geneone) {
          foreach my $genetwo (sort keys %genetwo) {
            if ($ginSeqname{$geneone}) { $systematicNameA = $ginSeqname{$geneone}; }
              else { $lineWarning .= qq(Warning PGID $pgid geneone $geneone does not map to gin_seqname\n); }
            if ($ginSeqname{$genetwo}) { $systematicNameB = $ginSeqname{$genetwo}; }
              else { $lineWarning .= qq(Warning PGID $pgid genetwo $genetwo does not map to gin_seqname\n); }
            if ($ginLocus{$geneone}) { $officialNameA = $ginLocus{$geneone}; }
              else { $lineWarning .= qq(Warning PGID $pgid geneone $geneone does not map to gin_locus\n); }
            if ($ginLocus{$genetwo}) { $officialNameB = $ginLocus{$genetwo}; }
              else { $lineWarning .= qq(Warning PGID $pgid genetwo $genetwo does not map to gin_locus\n); }
            if ( $locusToEntrez{$officialNameA} ) {          $entrezGeneA = $locusToEntrez{$officialNameA};     }
              elsif ( $seqnameToEntrez{$systematicNameA} ) { $entrezGeneA = $seqnameToEntrez{$systematicNameA}; }
            if ( $locusToEntrez{$officialNameB} ) {          $entrezGeneB = $locusToEntrez{$officialNameB};     }
              elsif ( $seqnameToEntrez{$systematicNameB} ) { $entrezGeneB = $seqnameToEntrez{$systematicNameB}; }
#             if ( $wbgeneToEntrez{$geneone} ) { $entrezGeneA = $wbgeneToEntrez{$geneone}; }
#             if ( $wbgeneToEntrez{$genetwo} ) { $entrezGeneB = $wbgeneToEntrez{$genetwo}; }
            print OUT qq(PGID $pgid\t$wbInteractionId\t$bioIntId\t$entrezGeneA\t$entrezGeneB\t$biogridIntA\t$biogridIntB\t$systematicNameA\t$systematicNameB\t$officialNameA\t$officialNameB\t$synonymA\t$synonymB\t$experSysName\t$experSysType\t$author\t$pmid\t$orgIdA\t$orgIdB\t$throughput\t$quantScore\t$modification\t$phenotype\t$qualifications\t$tags\t$sourceDatabase\n);
          } # foreach my $genetwo (sort keys %genetwo)
        } # foreach my $geneone (sort keys %geneone)
      } # if (scalar keys %geneone > 0)
    }
  if ($lineWarning) { print ERR $lineWarning; }			# always print line warnings
} # foreach my $pgid (sort {$a<=>$b} keys %joinkeys)



close (OUT) or die "Cannot close $outfile : $!";
close (ERR) or die "Cannot close $errfile : $!";

sub populateDeadObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {                 # Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
    if ($row[1] =~ m/split_into (WBGene\d+)/) {       $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) { $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {              $deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {                    $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
  my $doAgain = 1;                                    # if a mapped gene maps to another gene, loop through all again
  while ($doAgain > 0) {
    $doAgain = 0;                                     # stop if no genes map to other genes
    foreach my $gene (sort keys %{ $deadObjects{gene}{mapto} }) {
      next unless ( $deadObjects{gene}{mapTo}{$gene} );
      my $mappedGene = $deadObjects{gene}{mapTo}{$gene};
      if ($deadObjects{gene}{mapTo}{$mappedGene}) {
        $deadObjects{gene}{mapTo}{$gene} = $deadObjects{gene}{mapTo}{$mappedGene};          # set mapping of original gene to 2nd degree mapped gene
        $doAgain++; } } }                             # loop again in case a mapped gene maps to yet another gene
} # sub populateDeadObjects


__END__

exclude int_type
Physical
Predicted
No_interaction



$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

