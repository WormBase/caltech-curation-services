#!/usr/bin/perl -w

# populate int_ tables for phenote interaction.  2008 03 20
#
# make andrei the curator if there isn't one.  for Jolene.  2008 06 24
#
# new dataset from Andrei.  2008 07 30
#
# output all ace entry with errors.  2008 08 04
# 
# TODO append errors to an Andrei file and don't put them in postgres
#
# (the above TODO seemed done when I started modifying this script (J - 2010 10 04)
# change to DBI.pg  use new batch off of WS220 parsed for entries that are small
# scale and not in int_ tables already.  for Xiaodong, Wen, also Karen, Gary.
# 2010 10 04
#
# copied to sandbox, unclear it's doing the correct thing for transgene / variation names.
# 2010 11 10
#
# ran on sandbox, read in WS220 to postgres.  2010 11 11
#
# modified for OA-style data instead of phenote-style data.  Tries to filter multiple entries
# for Gary and Chris, but don't have test data to test it.  2010 12 05
#
# trasngeneonegene and transgenetwogene were not getting read in.  Now when a
# geneone / genetwo matches a transgene, it adds to an array  @transgeneonegene
# or @transgenetwogene to write to postgres.  2010 12 08
#
# output pgcommands to .pg file that's the same as the inputfile with a different
# extension (.pg)  2010 12 09



use strict;
use diagnostics;
# use Pg;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

unless ($ARGV[0] || $ARGV[1]) { print "ERROR call with ./parse_ace_interaction_oa.pl <filename> WBPerson<your_number>\n"; exit; }

my $infile = shift @ARGV;
unless (-e $infile) { print "ERROR not an existing file $infile\n"; exit; }
my $source_curator = shift @ARGV;
unless ($source_curator =~ m/^WBPerson\d+$/) { print "ERROR not a valid WBPerson format for curator $source_curator\n"; exit; }

my $filename = $infile;
if ($filename =~ m/^(.*)\./) { $filename = $1; }
my $pgfile = $filename . '.pg';
open (PG, ">$pgfile") or die "Cannot create $pgfile : $!";


my @allpgcommands;

my @delete_from = qw( int_name_hst int_nondirectional_hst int_type_hst int_geneone_hst int_variationone_hst int_transgeneone_hst int_transgeneonegene_hst int_genetwo_hst int_variationtwo_hst int_transgenetwo_hst int_transgenetwogene_hst int_curator_hst int_paper_hst int_person_hst int_rnai_hst int_phenotype_hst int_remark_hst int_name int_nondirectional int_type int_geneone int_variationone int_transgeneone int_transgeneonegene int_genetwo int_variationtwo int_transgenetwo int_transgenetwogene int_curator int_paper int_person int_rnai int_phenotype int_remark );

# don't want to delete from OA-style script for now 2010 12 05
# foreach my $table (@delete_from) {
#   push @allpgcommands, "DELETE FROM ${table} WHERE CAST (joinkey AS INTEGER) > '8926';";
# }
# foreach my $pgcommand (@allpgcommands) {
#   print "$pgcommand\n";
# # UNCOMMENT THIS TO DELETE FROM POSTGRES
# #   my $result = $dbh->do( $pgcommand );
# } # foreach my $pgcommand (@allpgcommands)
@allpgcommands = ();

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $infile = 'interaction_acedb_dump_20080222.ace';
# my $infile = 'WS194Interaction.ace';
# my $infile = 'WS220Interaction_SmallScale.ace';
# my $infile = 'WS220Interaction_To_Read.ace';

# my $errfile = '/home/acedb/andrei/reading_interactions/interaction_with_reading_errors';
my $errfile = 'parse_ace_interaction_oa.err';

my $date = &getSimpleSecDate();

$/ = "";

my @noeff = qw( Genetic No_interaction Predicted_interaction Physical_interaction Synthetic Mutual_enhancement Mutual_suppression );
my @yeseff = qw( Regulatory Suppression Enhancement Epistasis );
# my %intType;
# foreach my $int (@noeff) { $intType{$int}{'noeff'}++; }
# foreach my $int (@yeseff) { $intType{$int}{'yeseff'}++; }


my %already_in;
my $id = 0;
my $result = $dbh->prepare( "SELECT * FROM int_name ORDER BY joinkey::INTEGER ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while ( my @row = $result->fetchrow() ) {
  if ($row[0]) { $already_in{$row[1]}++; } }
$result = $dbh->prepare( "SELECT * FROM int_curator ORDER BY joinkey::INTEGER DESC;" );	# some entries while reading in textpresso data and having old phenote data, don't have a name / object ID, so get the most recent postgres ID from the int_curator field.  2010 11 11
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
if ($row[0]) { $id = $row[0]; }

my %varIDs;
$result = $dbh->prepare( " SELECT * FROM obo_name_variation ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while ( my @row = $result->fetchrow() ) {
  if ($row[0]) { $varIDs{$row[0]}++; } }

my %transgeneNames;
$result = $dbh->prepare( " SELECT * FROM trp_name ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while ( my @row = $result->fetchrow() ) {
  if ($row[1]) { $transgeneNames{$row[1]}++; } }

my %geneIDs;
$result = $dbh->prepare( " SELECT * FROM gin_wbgene ; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while ( my @row = $result->fetchrow() ) {
  if ($row[1]) { $geneIDs{$row[1]}++; } }


my $allBad = '';

my $entry_count = 0;

my %hash; 
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (ERR, ">$errfile") or die "Cannot write to $errfile : $!";
while (my $entry = <IN>) {
  my (@lines) = split/\n/, $entry;
  my $topLine = shift @lines;
  foreach my $line (@lines) { $hash{$topLine}{$line}++; }
} # while (my $entry = <IN>)

my @entries;
foreach my $topLine (sort keys %hash) {
  my $entry = "$topLine\n";
  foreach my $line (sort keys %{ $hash{$topLine} }) { $entry .= "$line\n"; }
  push @entries, $entry;
} # foreach my $topLine (sort keys %hash)

%hash = ();
foreach my $entry (@entries) {
  my @pgcommands;
  my $veryBad = '';
  my ($name) = $entry =~ m/Interaction : \"WBInteraction(\d+)\"/;
  next unless ($name);
  my $int_name = "WBInteraction$name"; next if ($already_in{$int_name}); 
#   next if ($entry =~ m/Predicted_interaction\t/);	# X and Gary don't want to skip these entries
  next unless ($name);
#   next unless ($name eq '0007727');
  $entry_count++; 
  my %filter;
  $entry =~ s/\\//g;

# last if ($entry_count > 555);

  my @geneone; my @genetwo; # my @geneextra;
  my $directional = '';
  my $nondirectional = '';
  if ($entry =~ m/Non_directional/) { $nondirectional++; }
  if ($entry =~ m/Effector\s+\"(WBGene\d+)\"/) { (@geneone) = $entry =~ m/Effector\s+\"(WBGene\d+)\"/g; $directional .= "Effector "; }
  if ($entry =~ m/Effected\s+\"(WBGene\d+)\"/) { (@genetwo) = $entry =~ m/Effected\s+\"(WBGene\d+)\"/g; $directional .= " Effected"; }
  if ($directional && $nondirectional) { $veryBad .= "has both $directional and Non_directional\n"; }
  if ( !$directional && !$nondirectional) { $veryBad .= "has both neither Effector nor Effected nor Non_directional\n"; }
  if ($nondirectional) { $nondirectional = 'Non_directional'; } else { $nondirectional = ''; }
  unless ($geneone[0]) {
#     my (@genes) = $entry =~ m/Interactor\s+\"(WBGene\d+)\"/g; my %filter;	# don't user Interactor for genes, use Non_directional  2010 10 07
    my (@genes) = $entry =~ m/Non_directional\s+\"(WBGene\d+)\"/g; my %filter;
    foreach my $gene (@genes) { $filter{$gene}++; } @genes = ();
    foreach my $gene (sort keys %filter) { push @genes, $gene; }
#     if (scalar(@genes) > 2) { $veryBad .= "$name has multiple Interactor Genes that are not geneone / genetwo labeled : @genes\n"; }
    if (scalar(@genes) < 2) { $veryBad .= "$name has only 1 Interactor Genes that are not geneone / genetwo labeled : @genes\n"; }
      else {
        my $blah = shift @genes; 
        if ($geneIDs{$blah}) { push @geneone, $blah; }
          else { $veryBad .= "$blah not a valid WBGene from gin_wbgene\n"; }
# don't push into geneextra, put 2->n genes into genetwo for Gary and Xiaodong  2010 10 07
#         $blah = shift @genes; push @genetwo, $blah; 
#         while (@genes) { $blah = shift @genes; push @geneextra, $blah; }
        foreach my $blah (@genes) {
          if ($geneIDs{$blah}) { push @genetwo, $blah; }
            else { $veryBad .= "$blah not a valid WBGene from gin_wbgene\n"; } } } }
# Probably don't need these next two warnings  2010 10 04
#   if (scalar(@geneone) > 1) { $veryBad .= "$name has more than 1 Gene One : @geneone\n"; }
#   if (scalar(@genetwo) > 1) { $veryBad .= "$name has more than 1 Gene Two : @genetwo\n"; }
  my $geneone = join'","', @geneone; if ($geneone) { $geneone = '"' . $geneone . '"'; }
  my $genetwo = join'","', @genetwo; if ($genetwo) { $genetwo = '"' . $genetwo . '"'; }

  my %intType; my $intType = '';
  foreach my $intType (@noeff) { if ($entry =~ m/\n$intType\s+/) { $intType{$intType}++; } }
  foreach my $intType (@yeseff) { if ($entry =~ m/\n$intType\s+/) { $intType{$intType}++; } }
  my (@intTypes) = keys %intType; 
  if (scalar(@intTypes) > 1) { $veryBad .= "$name has multiple Interaction Types : @intTypes\n"; }
  elsif ($intTypes[0]) { $intType = shift @intTypes; }
  else { $veryBad .= "$name has no matching interaction type\n"; }

  my (@intPhenotypes) = $entry =~ m/Interaction_phenotype\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $ip (@intPhenotypes) { 
    if ($ip =~ m/\"/) { $veryBad .= "interaction phenotype $ip has a doublequote\n"; } 
    if ($ip =~ m/WBPhenotype\d/) { $ip =~ s/WBPhenotype(\d+)/WBPhenotype:$1/g; }
    unless ($ip =~ m/WBPhenotype:\d\d\d\d\d\d\d$/) { $veryBad .= "$ip does not have exactly 7 digits\n"; }
    ($ip) = &filterPg($ip) ;
    $filter{$ip}++; } @intPhenotypes = (); foreach my $ip (keys %filter) { push @intPhenotypes, $ip; }
#   my $intPhenotype = join"|",  @intPhenotypes; unless ($intPhenotype) { $intPhenotype = ''; }
  my $intPhenotype = join'","', @intPhenotypes;  if ($intPhenotype) { $intPhenotype = '"' . $intPhenotype . '"'; } else { $intPhenotype = ''; }

  my (@intRNAis) = $entry =~ m/Interaction_RNAi\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $ir (@intRNAis) { $filter{$ir}++; } @intRNAis = (); foreach my $ir (keys %filter) { push @intRNAis, $ir; }
  if (scalar(@intRNAis) > 1) { $veryBad .= "$name has multiple Interaction RNAi : @intRNAis\n"; }
  my $intRNAi = shift @intRNAis; unless ($intRNAi) { $intRNAi = ''; }
#   my $intRNAi = join", ", @intRNAis; unless ($intRNAi) { $intRNAi = ''; }	# Gary says there should only ever by one RNAi in a paragraph

  my (@remarks) = $entry =~ m/\nRemark\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $ip (@remarks) { $filter{$ip}++; } @remarks = (); foreach my $ip (keys %filter) { push @remarks, $ip; }
  my $remark = join"  ",  @remarks; unless ($remark) { $remark = ''; }

  my (@papers) = $entry =~ m/Paper\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $pap (@papers) { $filter{$pap}++; } @papers = (); foreach my $pap (keys %filter) { push @papers, $pap; }
  if (scalar(@papers) > 1) { $veryBad .= "$name has multiple Papers : @papers\n"; }
  my $paper = shift @papers; unless ($paper) { $paper = ''; }

  my @transgeneone; my @transgeneonegene;
  foreach my $gene (@geneone) {
    my (@trans) = $entry =~ m/\"$gene\"\s+Transgene\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $tran (@trans) { $filter{$tran}++; } @trans = (); foreach my $tran (keys %filter) { push @trans, $tran; }
    if (scalar(@trans) > 1) { $veryBad .= "$name has multiple Transgene for geneone $gene : @trans\n"; }
    my $tran = shift @trans; if ($tran) {
      if ($transgeneNames{$tran}) { push @transgeneone, $tran; push @transgeneonegene, $gene; }
        else { $veryBad .= "$tran (tranone) not in list of valid transgeneNames in trp_name\n"; } } }
  my $transgeneone = join", ", @transgeneone;  unless ($transgeneone) { $transgeneone = ''; }
  my $transgeneonegene = join'","', @transgeneonegene;  if ($transgeneonegene) { $transgeneonegene = '"' . $transgeneonegene . '"'; } else { $transgeneonegene = ''; }
  my @variationone;
  foreach my $gene (@geneone) {
    my (@vars) = $entry =~ m/\"$gene\"\s+Variation\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $var (@vars) { $filter{$var}++; } @vars = (); foreach my $var (keys %filter) { push @vars, $var; }
    if (scalar(@vars) > 1) { $veryBad .= "$name has multiple Variations for geneone $gene : @vars\n"; }
    my $var = shift @vars; if ($var) { 
      if ($varIDs{$var}) { push @variationone, $var; } 
        else { $veryBad .= "$var (varone) not in list of valid WBVarIDs in obo_name_variation\n"; } } }
  my $variationone = join'","',  @variationone;  if ($variationone) { $variationone = '"' . $variationone . '"'; } else { $variationone = ''; }
  my @transgenetwo; my @transgenetwogene;
  foreach my $gene (@genetwo) {
    my (@trans) = $entry =~ m/\"$gene\"\s+Transgene\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $tran (@trans) { $filter{$tran}++; } @trans = (); foreach my $tran (keys %filter) { push @trans, $tran; }
    if (scalar(@trans) > 1) { $veryBad .= "$name has multiple Transgene for genetwo $gene : @trans\n"; }
    my $tran = shift @trans; if ($tran) {
      if ($transgeneNames{$tran}) { push @transgenetwo, $tran; push @transgenetwogene, $gene; }
        else { $veryBad .= "$tran (trantwo) not in list of valid transgeneNames in trp_name\n"; } } }
  my $transgenetwo = join", ",  @transgenetwo;  unless ($transgenetwo) { $transgenetwo = ''; }
  my $transgenetwogene = join'","', @transgenetwogene;  if ($transgenetwogene) { $transgenetwogene = '"' . $transgenetwogene . '"'; } else { $transgenetwogene = ''; }
  my @variationtwo;
  foreach my $gene (@genetwo) {
    my (@vars) = $entry =~ m/\"$gene\"\s+Variation\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $var (@vars) { $filter{$var}++; } @vars = (); foreach my $var (keys %filter) { push @vars, $var; }
    if (scalar(@vars) > 1) { $veryBad .= "$name has multiple Variations for genetwo $gene : @vars\n"; }
    my $var = shift @vars; if ($var) { 
      if ($varIDs{$var}) { push @variationtwo, $var; } 
        else { $veryBad .= "$var (vartwo) not in list of valid WBVarIDs in obo_name_variation\n"; } } }
  my $variationtwo = join'","',  @variationtwo;  if ($variationtwo) { $variationtwo = '"' . $variationtwo . '"'; } else { $variationtwo = ''; }

  unless ($name) { $veryBad .= "$entry does not have an object name\n"; }
  next unless ($name); 
  $id++;
  if ($name) { 
#     print "Name : $name\n"; 
    if ($name =~ m/\"/) { $veryBad .= "name $name has a doublequote\n"; } ($name) = &filterPg($name);
    my $command = "INSERT INTO int_name_hst VALUES ('$id', 'WBInteraction$name');";
    push @pgcommands, $command; 
    $command = "INSERT INTO int_name VALUES ('$id', 'WBInteraction$name');";
    push @pgcommands, $command; }
  if ($geneone) { 
#     print "Gene One : $geneone\n"; 
#     if ($geneone =~ m/\"/) { $veryBad .= "geneone $geneone has a doublequote\n"; }
    ($geneone) = &filterPg($geneone);
    my $command = "INSERT INTO int_geneone_hst VALUES ('$id', '$geneone');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_geneone VALUES ('$id', '$geneone');";
    push @pgcommands, $command; }
  if ($variationone) { 
#     print "Gene One Variation : $variationone\n"; 
#     if ($variationone =~ m/\"/) { $veryBad .= "geneone variation $variationone has a doublequote\n"; } 	# ontology now
    ($variationone) = &filterPg($variationone);
    my $command = "INSERT INTO int_variationone_hst VALUES ('$id', '$variationone');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_variationone VALUES ('$id', '$variationone');";
    push @pgcommands, $command; }
  if ($transgeneone) { 
#     print "Gene One Transgene : $transgeneone\n"; 
#     if ($transgeneone =~ m/\"/) { $veryBad .= "geneone transgene $transgeneone has a doublequote\n"; }	# ontology now
    ($transgeneone) = &filterPg($transgeneone);
    my $command = "INSERT INTO int_transgeneone_hst VALUES ('$id', '$transgeneone');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_transgeneone VALUES ('$id', '$transgeneone');";
    push @pgcommands, $command; }
  if ($transgeneonegene) {
#     print "Gene One Transgene Gene : $transgeneonegene\n";
    ($transgeneonegene) = &filterPg($transgeneonegene);
    my $command = "INSERT INTO int_transgeneonegene_hst VALUES ('$id', '$transgeneonegene');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_transgeneonegene VALUES ('$id', '$transgeneonegene');";
    push @pgcommands, $command; }
  if ($genetwo) { 
#     print "Gene Two : $genetwo\n"; 
#     if ($genetwo =~ m/\"/) { $veryBad .= "genetwo $genetwo has a doublequote\n"; } 
    ($genetwo) = &filterPg($genetwo);
    my $command = "INSERT INTO int_genetwo_hst VALUES ('$id', '$genetwo');";
    push @pgcommands, $command; 
    $command = "INSERT INTO int_genetwo VALUES ('$id', '$genetwo');";
    push @pgcommands, $command; }
  if ($variationtwo) { 
#     print "Gene Two Variation : $variationtwo\n"; 
#     if ($variationtwo =~ m/\"/) { $veryBad .= "genetwo variation $variationtwo has a doublequote\n"; }	# ontology now
    ($variationtwo) = &filterPg($variationtwo);
    my $command = "INSERT INTO int_variationtwo_hst VALUES ('$id', '$variationtwo');";
    push @pgcommands, $command; 
    $command = "INSERT INTO int_variationtwo VALUES ('$id', '$variationtwo');";
    push @pgcommands, $command; }
  if ($transgenetwo) {
#     print "Gene Two Transgene : $transgenetwo\n"; 
#     if ($transgenetwo =~ m/\"/) { $veryBad .= "genetwo transgene $transgenetwo has a doublequote\n"; }	# ontology now
    ($transgenetwo) = &filterPg($transgenetwo);
    my $command = "INSERT INTO int_transgenetwo_hst VALUES ('$id', '$transgenetwo');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_transgenetwo VALUES ('$id', '$transgenetwo');";
    push @pgcommands, $command; }
  if ($transgenetwogene) {
#     print "Gene Two Transgene Gene : $transgenetwogene\n";
    ($transgenetwogene) = &filterPg($transgenetwogene);
    my $command = "INSERT INTO int_transgenetwogene_hst VALUES ('$id', '$transgenetwogene');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_transgenetwogene VALUES ('$id', '$transgenetwogene');";
    push @pgcommands, $command; }
  if ($intType) { 
#     print "intType : $intType\n"; 
    if ($intType =~ m/\"/) { $veryBad .= "interaction type $intType has a doublequote\n"; } ($intType) = &filterPg($intType) ;
    my $command = "INSERT INTO int_type_hst VALUES ('$id', '$intType');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_type VALUES ('$id', '$intType');";
    push @pgcommands, $command; }
  if ($intPhenotype) { 
#     print "intPhenotype : $intPhenotype\n"; 
    my $command = "INSERT INTO int_phenotype_hst VALUES ('$id', '$intPhenotype');";
    push @pgcommands, $command; 
    $command = "INSERT INTO int_phenotype VALUES ('$id', '$intPhenotype');";
    push @pgcommands, $command; }
  if ($intRNAi) { 
#     print "intRNAi : $intRNAi\n"; 
    if ($intRNAi =~ m/\"/) { $veryBad .= "interaction RNAi $intRNAi has a doublequote\n"; } ($intRNAi) = &filterPg($intRNAi) ;
    my $command = "INSERT INTO int_rnai_hst VALUES ('$id', '$intRNAi');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_rnai VALUES ('$id', '$intRNAi');";
    push @pgcommands, $command; }
  if ($paper) { 
#     print "paper : $paper\n"; 
    if ($paper =~ m/\"/) { $veryBad .= "paper $paper has a doublequote\n"; } ($paper) = &filterPg($paper) ;
    my $command = "INSERT INTO int_paper_hst VALUES ('$id', '$paper');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_paper VALUES ('$id', '$paper');";
    push @pgcommands, $command; }
  if ($remark) { 
#     print "remark : $remark\n"; 
    if ($remark =~ m/\"/) { $veryBad .= "remark $remark has a doublequote\n"; } ($remark) = &filterPg($remark) ;
    my $command = "INSERT INTO int_remark_hst VALUES ('$id', '$remark');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_remark VALUES ('$id', '$remark');";
    push @pgcommands, $command; }
  # always enter nondirectionality  2010 10 06
#     print "nondirectional : $nondirectional\n"; 
  my $command = "INSERT INTO int_nondirectional_hst VALUES ('$id', '$nondirectional');";
  push @pgcommands, $command;
  $command = "INSERT INTO int_nondirectional VALUES ('$id', '$nondirectional');";
  push @pgcommands, $command;

  # TODO make command line read ./script <filename> <WBPerson####> and use that as curator.  2010 11 11
  $command = "INSERT INTO int_curator_hst VALUES ('$id', '$source_curator');";
  push @pgcommands, $command;
  $command = "INSERT INTO int_curator VALUES ('$id', '$source_curator');";
  push @pgcommands, $command;
#   print "\n";

  if ($veryBad) { print ERR "// $date WBInteraction$veryBad\n$entry\n\n"; $allBad .= $veryBad; }	# print errors to err file
    else { foreach my $command (@pgcommands) { push @allpgcommands, $command; } }	# push good commands to full list if no errors
} # foreach my $entry (@entries)
close (IN) or die "Cannot close $infile : $!";
close (ERR) or die "Cannot close $errfile : $!";

# commented out checks because always populate data, according to Andrei  2008 08 04
# if ($allBad) { print "ERROR $allBad\n"; }
#   else {
    foreach my $command (@allpgcommands) {
      print PG "$command\n"; 
# UNCOMMENT TO READ IN TO POSTGRES  2010 11 11	# uncommented 2010 12 08, gary + X will read to acedb, dump, then use this script.
      $result = $dbh->do( $command );		
    } 
# }

close (PG) or die "Cannot close $pgfile : $!";

sub filterPg {
  my $stuff = shift;
  if ($stuff =~ m/\'/) { $stuff =~ s/\'/''/g; }
  return $stuff;
} # sub filterPg

# foreach my $name (sort keys %hash) {
#   
#   if ($hash{$name} > 1) { print "$name has $hash{$name} entries\n"; }
#   unless ($name) { print "BAD $hash{$name} BAD\n"; }
#   my $int = $name;
#   $int++; $int--;
#   my $command = "INSERT INTO int_index VALUES ('$name', '$int', 'acedb');";
#   print "$command\n";
#   my $result = $conn->exec( "$command" );
#   print "N $name I $int N\n";
# } # foreach my $name (sort keys %hash)


__END__

wbinteractionID		automatic
interactor 1 -- effector	WBGene or locus name	variation 1 / transgene 1 / remark 1
interactor 2 -- effected	WBGene or locus name	variation 2 / transgene 2 / remark 2
(effector & effected are multiple)
(other_evidence is multiple)
pull down -> genetic, enhancement, &c.
inter. phenot
inter. rnai	# multiple
Confidence_level	# float 
P_value			# float 
# db_info	# not anymore
paper		# to Paper tag, not hash
remark		# multiple


Interaction Type :
Genetic
Regulatory
No_interaction
Predicted_interaction
Physical_interaction
Suppression
Enhancement
Synthetic
Epistasis
Mutual_enhancement
Mutual_suppression

No effector/effected:
Genetic
No_interaction
Predicted_interaction
Physical_interaction
Synthetic
Mutual_enhancement
Mutual_suppression

Effector/Effected:
Regulatory
Suppression
Enhancement
Epistatis


DELETE FROM int_curator ;
DELETE FROM int_paper ;
DELETE FROM int_remark ;
DELETE FROM int_variationtwo ;
DELETE FROM int_type ;
DELETE FROM int_genetwo ;
DELETE FROM int_name ;
DELETE FROM int_person ;
DELETE FROM int_rnai ;
DELETE FROM int_transgeneone ;
DELETE FROM int_geneone ;
DELETE FROM int_otherevi ;
DELETE FROM int_phenotype ;
DELETE FROM int_transgenetwo  ;
DELETE FROM int_variationone ;
DELETE FROM int_treatment ;
DELETE FROM int_transgeneextra ;
DELETE FROM int_geneextra ;
DELETE FROM int_variationextra ;

DELETE FROM int_curator_hst;
DELETE FROM int_paper_hst;
DELETE FROM int_remark_hst;
DELETE FROM int_variationtwo_hst;
DELETE FROM int_type_hst;
DELETE FROM int_genetwo_hst;
DELETE FROM int_name_hst;
DELETE FROM int_person_hst;
DELETE FROM int_rnai_hst;
DELETE FROM int_transgeneone_hst;
DELETE FROM int_geneone_hst;
DELETE FROM int_otherevi_hst;
DELETE FROM int_phenotype_hst;
DELETE FROM int_transgenetwo_hst;
DELETE FROM int_variationone_hst;
DELETE FROM int_treatment_hst ;
DELETE FROM int_transgeneextra_hst ;
DELETE FROM int_geneextra_hst ;
DELETE FROM int_variationextra_hst ;

