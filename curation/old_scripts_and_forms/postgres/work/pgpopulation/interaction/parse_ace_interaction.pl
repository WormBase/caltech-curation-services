#!/usr/bin/perl -w

# populate int_ tables for phenote interaction.  2008 03 20
#
# make andrei the curator if there isn't one.  for Jolene.  2008 06 24
#
# new dataset from Andrei.  2008 07 30
#
# output all ace entry with errors.  2008 08 04

# TODO append errors to an Andrei file and don't put them in postgres

use strict;
use diagnostics;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $infile = 'interaction_acedb_dump_20080222.ace';
my $infile = 'WS194Interaction.ace';
my $errfile = '/home/acedb/andrei/reading_interactions/interaction_with_reading_errors';

my $date = &getSimpleSecDate();

$/ = "";

my @noeff = qw( Genetic No_interaction Predicted_interaction Physical_interaction Synthetic Mutual_enhancement Mutual_suppression );
my @yeseff = qw( Regulatory Suppression Enhancement Epistatis );
# my %intType;
# foreach my $int (@noeff) { $intType{$int}{'noeff'}++; }
# foreach my $int (@yeseff) { $intType{$int}{'yeseff'}++; }


my %already_in;
my $id = 0;
my $result = $conn->exec( "SELECT * FROM int_name ORDER BY joinkey DESC;" );
my @row = $result->fetchrow();
if ($row[0]) { $id = $row[0]; $already_in{$row[1]}++; }

my $allBad = '';
my @allpgcommands;

my $entry_count = 0;

my %hash;
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (ERR, ">>$errfile") or die "Cannot append to $errfile : $!";
while (my $entry = <IN>) {
  my @pgcommands;
  my $veryBad = '';
  my ($name) = $entry =~ m/Interaction : \"WBInteraction(\d+)\"/;
  next unless ($name);
  my $int_name = "WBInteraction$name"; next if ($already_in{$int_name}); 
  next if ($entry =~ m/Predicted_interaction\t/);
  next unless ($name);
#   next unless ($name eq '0007727');
  $entry_count++; 
  my %filter;
  $entry =~ s/\\//g;

# last if ($entry_count > 555);

  my @geneone; my @genetwo; my @geneextra;
  if ($entry =~ m/Effector\s+\"(WBGene\d+)\"/) { (@geneone) = $entry =~ m/Effector\s+\"(WBGene\d+)\"/g; }
  if ($entry =~ m/Effected\s+\"(WBGene\d+)\"/) { (@genetwo) = $entry =~ m/Effected\s+\"(WBGene\d+)\"/g; }
  unless ($geneone[0]) {
    my (@genes) = $entry =~ m/Interactor\s+\"(WBGene\d+)\"/g; my %filter;
    foreach my $gene (@genes) { $filter{$gene}++; } @genes = ();
    foreach my $gene (sort keys %filter) { push @genes, $gene; }
#     if (scalar(@genes) > 2) { $veryBad .= "$name has multiple Interactor Genes that are not geneone / genetwo labeled : @genes\n"; }
    if (scalar(@genes) < 2) { $veryBad .= "$name has only 1 Interactor Genes that are not geneone / genetwo labeled : @genes\n"; }
      else { 
        my $blah = shift @genes; push @geneone, $blah; $blah = shift @genes; push @genetwo, $blah; 
        while (@genes) { $blah = shift @genes; push @geneextra, $blah; } } }
  if (scalar(@geneone) > 1) { $veryBad .= "$name has more than 1 Gene One : @geneone\n"; }
  if (scalar(@genetwo) > 1) { $veryBad .= "$name has more than 1 Gene Two : @genetwo\n"; }
#   my $geneone = join"|", @geneone;
#   my $genetwo = join"|", @genetwo;
  my $geneone = $geneone[0]; my $genetwo = $genetwo[0];

  my %intType;
  foreach my $intType (@noeff) { if ($entry =~ m/\n$intType\s+/) { $intType{$intType}++; } }
  foreach my $intType (@yeseff) { if ($entry =~ m/\n$intType\s+/) { $intType{$intType}++; } }
  my (@intTypes) = keys %intType; 
  if (scalar(@intTypes) > 1) { $veryBad .= "$name has multiple Interaction Types : @intTypes\n"; }
  my $intType = shift @intTypes;

  my (@intPhenotypes) = $entry =~ m/Interaction_phenotype\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $ip (@intPhenotypes) { $filter{$ip}++; } @intPhenotypes = (); foreach my $ip (keys %filter) { push @intPhenotypes, $ip; }
  my $intPhenotype = join"|",  @intPhenotypes; unless ($intPhenotype) { $intPhenotype = ''; }

  my (@intRNAis) = $entry =~ m/Interaction_RNAi\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $ir (@intRNAis) { $filter{$ir}++; } @intRNAis = (); foreach my $ir (keys %filter) { push @intRNAis, $ir; }
#   if (scalar(@intRNAis) > 1) { $veryBad .= "$name has multiple Interaction RNAi : @intRNAis\n"; }
#   my $intRNAi = shift @intRNAis; unless ($intRNAi) { $intRNAi = ''; }
  my $intRNAi = join", ", @intRNAis; unless ($intRNAi) { $intRNAi = ''; }

  my (@remarks) = $entry =~ m/\nRemark\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $ip (@remarks) { $filter{$ip}++; } @remarks = (); foreach my $ip (keys %filter) { push @remarks, $ip; }
  my $remark = join"|",  @remarks; unless ($remark) { $remark = ''; }

  my (@papers) = $entry =~ m/Paper\s+\"(.*?)\"\n/g; 
  %filter = (); foreach my $pap (@papers) { $filter{$pap}++; } @papers = (); foreach my $pap (keys %filter) { push @papers, $pap; }
  if (scalar(@papers) > 1) { $veryBad .= "$name has multiple Papers : @papers\n"; }
  my $paper = shift @papers; unless ($paper) { $paper = ''; }

  my @transgeneone;
  foreach my $gene (@geneone) {
    my (@trans) = $entry =~ m/\"$gene\"\s+Transgene\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $tran (@trans) { $filter{$tran}++; } @trans = (); foreach my $tran (keys %filter) { push @trans, $tran; }
    if (scalar(@trans) > 1) { $veryBad .= "$name has multiple Transgene for geneone $gene : @trans\n"; }
    my $tran = shift @trans; unless ($tran) { $tran = ""; } push @transgeneone, $tran; }
  my $transgeneone = join", ",  @transgeneone;  unless ($transgeneone) { $transgeneone = ''; }
  my @variationone;
  foreach my $gene (@geneone) {
    my (@vars) = $entry =~ m/\"$gene\"\s+Variation\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $var (@vars) { $filter{$var}++; } @vars = (); foreach my $var (keys %filter) { push @vars, $var; }
    if (scalar(@vars) > 1) { $veryBad .= "$name has multiple Variations for geneone $gene : @vars\n"; }
    my $var = shift @vars; unless ($var) { $var = ""; } push @variationone, $var; }
  my $variationone = join", ",  @variationone;  unless ($variationone) { $variationone = ''; }
#   my @tor_remark;
#   foreach my $gene (@geneone) {
#     my (@rems) = $entry =~ m/\"$gene\"\s+Remark\s+\"(.*?)\"\n/g; 
#     %filter = (); foreach my $rem (@rems) { $filter{$rem}++; } @rems = (); foreach my $rem (keys %filter) { push @rems, $rem; }
#     if (scalar(@rems) > 1) { $veryBad .= "$name has multiple Remark for geneone $gene : @rems\n"; }
#     my $rem = shift @rems; unless ($rem) { $rem = ""; } push @tor_remark, $rem; }
#   my $tor_remark = join"|",  @tor_remark;  unless ($tor_remark) { $tor_remark = ''; }
  my @transgenetwo;
  foreach my $gene (@genetwo) {
    my (@trans) = $entry =~ m/\"$gene\"\s+Transgene\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $tran (@trans) { $filter{$tran}++; } @trans = (); foreach my $tran (keys %filter) { push @trans, $tran; }
    if (scalar(@trans) > 1) { $veryBad .= "$name has multiple Transgene for genetwo $gene : @trans\n"; }
    my $tran = shift @trans; unless ($tran) { $tran = ""; } push @transgenetwo, $tran; }
  my $transgenetwo = join", ",  @transgenetwo;  unless ($transgenetwo) { $transgenetwo = ''; }
  my @variationtwo;
  foreach my $gene (@genetwo) {
    my (@vars) = $entry =~ m/\"$gene\"\s+Variation\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $var (@vars) { $filter{$var}++; } @vars = (); foreach my $var (keys %filter) { push @vars, $var; }
    if (scalar(@vars) > 1) { $veryBad .= "$name has multiple Variations for genetwo $gene : @vars\n"; }
    my $var = shift @vars; unless ($var) { $var = ""; } push @variationtwo, $var; }
  my $variationtwo = join", ",  @variationtwo;  unless ($variationtwo) { $variationtwo = ''; }
#   my @ted_remark;
#   foreach my $gene (@genetwo) {
#     my (@rems) = $entry =~ m/\"$gene\"\s+Remark\s+\"(.*?)\"\n/g; 
#     %filter = (); foreach my $rem (@rems) { $filter{$rem}++; } @rems = (); foreach my $rem (keys %filter) { push @rems, $rem; }
#     if (scalar(@rems) > 1) { $veryBad .= "$name has multiple Remark for genetwo $gene : @rems\n"; }
#     my $rem = shift @rems; unless ($rem) { $rem = ""; } push @ted_remark, $rem; }
#   my $ted_remark = join"|",  @ted_remark;  unless ($ted_remark) { $ted_remark = ''; }
  my @transgeneextra;
  foreach my $gene (@geneextra) {
    my (@trans) = $entry =~ m/\"$gene\"\s+Transgene\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $tran (@trans) { $filter{$tran}++; } @trans = (); foreach my $tran (keys %filter) { push @trans, $tran; }
    if (scalar(@trans) > 1) { $veryBad .= "$name has multiple Transgene for geneextra $gene : @trans\n"; }
    my $tran = shift @trans; unless ($tran) { $tran = ""; } push @transgeneextra, $tran; }
  my $transgeneextra = join", ",  @transgeneextra;  unless ($transgeneextra) { $transgeneextra = ''; }
  my @variationextra;
  foreach my $gene (@geneextra) {
    my (@vars) = $entry =~ m/\"$gene\"\s+Variation\s+\"(.*?)\"\n/g; 
    %filter = (); foreach my $var (@vars) { $filter{$var}++; } @vars = (); foreach my $var (keys %filter) { push @vars, $var; }
    if (scalar(@vars) > 1) { $veryBad .= "$name has multiple Variations for geneextra $gene : @vars\n"; }
    my $var = shift @vars; unless ($var) { $var = ""; } push @variationextra, $var; }
  my $variationextra = join", ",  @variationextra;  unless ($variationextra) { $variationextra = ''; }

  my (@evidence) = $entry =~ m/Evidence\s+(.*?)\n/g; %filter = ();
  foreach my $evidence (@evidence) {
    if ($evidence =~ m/Person_evidence\s\"(.*?)\"/) {
      if ($evidence =~ m/Person_evidence\s\"(WBPerson\d+)\"/) { $filter{person}{$1}++; }
        else { $veryBad .= "$evidence is Person_evidence without matching WBPerson#####\n"; } }
    elsif ($evidence =~ m/Curator_confirmed\s\"(.*?)\"/) {
      if ($evidence =~ m/Curator_confirmed\s\"(WBPerson\d+)\"/) { $filter{curator}{$1}++; }
        else { $veryBad .= "$evidence is Curator_confirmed without matching WBPerson#####\n"; } }
    else { $evidence =~ s/^Evidence\s+//; 
#       $evidence =~ s/\"/\\\\"/g; 
      $filter{other}{$evidence}++; } }
  my @person_evi; foreach my $person (keys %{ $filter{person} }) { push @person_evi, $person; } my $person_evi = join"|", @person_evi;
  my @curator_evi; foreach my $curator (keys %{ $filter{curator} }) { push @curator_evi, $curator; } my $curator_evi = join"|", @curator_evi;
  my @other_evi; foreach my $other (keys %{ $filter{other} }) { push @other_evi, $other; } my $other_evi = join"|", @other_evi;

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
  if ($geneextra[0]) { 
#     print "Gene Extra : $geneextra\n"; 
    my $geneextra = join"|", @geneextra;  unless ($geneextra) { $geneextra = ''; }
    if ($geneextra =~ m/\"/) { $veryBad .= "geneextra $geneextra has a doublequote\n"; } ($geneextra) = &filterPg($geneextra);
    my $command = "INSERT INTO int_geneextra_hst VALUES ('$id', '$geneextra');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_geneextra VALUES ('$id', '$geneextra');";
    push @pgcommands, $command; }
  if ($geneone) { 
#     print "Gene One : $geneone\n"; 
    if ($geneone =~ m/\"/) { $veryBad .= "geneone $geneone has a doublequote\n"; } ($geneone) = &filterPg($geneone);
    my $command = "INSERT INTO int_geneone_hst VALUES ('$id', '$geneone');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_geneone VALUES ('$id', '$geneone');";
    push @pgcommands, $command; }
#   if ($tor_remark) { 		# not a field anymore 2008 06 24
# #     print "Effector Remark : $tor_remark\n"; 
#     if ($tor_remark =~ m/\"/) { $veryBad .= "geneone remark $tor_remark has a doublequote\n"; } ($tor_remark) = &filterPg($tor_remark);
#     my $command = "INSERT INTO int_torremark_hst VALUES ('$id', '$tor_remark');";
#     push @pgcommands, $command; 
#     $command = "INSERT INTO int_torremark VALUES ('$id', '$tor_remark');";
#     push @pgcommands, $command; }
  if ($variationone) { 
#     print "Gene One Variation : $variationone\n"; 
    if ($variationone =~ m/\"/) { $veryBad .= "geneone variation $variationone has a doublequote\n"; } ($variationone) = &filterPg($variationone);
    my $command = "INSERT INTO int_torvariation_hst VALUES ('$id', '$variationone');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_torvariation VALUES ('$id', '$variationone');";
    push @pgcommands, $command; }
  if ($transgeneone) { 
#     print "Gene One Transgene : $transgeneone\n"; 
    if ($transgeneone =~ m/\"/) { $veryBad .= "geneone transgene $transgeneone has a doublequote\n"; } ($transgeneone) = &filterPg($transgeneone);
    my $command = "INSERT INTO int_tortransgene_hst VALUES ('$id', '$transgeneone');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_tortransgene VALUES ('$id', '$transgeneone');";
    push @pgcommands, $command; }
  if ($genetwo) { 
#     print "Gene Two : $genetwo\n"; 
    if ($genetwo =~ m/\"/) { $veryBad .= "genetwo $genetwo has a doublequote\n"; } ($genetwo) = &filterPg($genetwo);
    my $command = "INSERT INTO int_genetwo_hst VALUES ('$id', '$genetwo');";
    push @pgcommands, $command; 
    $command = "INSERT INTO int_genetwo VALUES ('$id', '$genetwo');";
    push @pgcommands, $command; }
#   if ($ted_remark) { 		# not a field anymore 2008 06 24
# #     print "Effected Remark : $ted_remark\n"; 
#     if ($ted_remark =~ m/\"/) { $veryBad .= "genetwo remark $ted_remark has a doublequote\n"; } ($ted_remark) = &filterPg($ted_remark);
#     my $command = "INSERT INTO int_tedremark_hst VALUES ('$id', '$ted_remark');";
#     push @pgcommands, $command;
#     $command = "INSERT INTO int_tedremark VALUES ('$id', '$ted_remark');";
#     push @pgcommands, $command; }
  if ($variationtwo) { 
#     print "Gene Two Variation : $variationtwo\n"; 
    if ($variationtwo =~ m/\"/) { $veryBad .= "genetwo variation $variationtwo has a doublequote\n"; } ($variationtwo) = &filterPg($variationtwo);
    my $command = "INSERT INTO int_tedvariation_hst VALUES ('$id', '$variationtwo');";
    push @pgcommands, $command; 
    $command = "INSERT INTO int_tedvariation VALUES ('$id', '$variationtwo');";
    push @pgcommands, $command; }
  if ($transgenetwo) { 
#     print "Gene Two Transgene : $transgenetwo\n"; 
    if ($transgenetwo =~ m/\"/) { $veryBad .= "genetwo transgene $transgenetwo has a doublequote\n"; } ($transgenetwo) = &filterPg($transgenetwo);
    my $command = "INSERT INTO int_tedtransgene_hst VALUES ('$id', '$transgenetwo');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_tedtransgene VALUES ('$id', '$transgenetwo');";
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
    if ($intPhenotype =~ m/\"/) { $veryBad .= "interaction phenotype $intPhenotype has a doublequote\n"; } ($intPhenotype) = &filterPg($intPhenotype) ;
    if ($intPhenotype =~ m/WBPhenotype\d+/) { $intPhenotype =~ s/WBPhenotype(\d+)/WBPhenotype:$1/g; }
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
  if ($person_evi) { 
#     print "person_evi : $person_evi\n"; 
    if ($person_evi =~ m/\"/) { $veryBad .= "person evidence $person_evi has a doublequote\n"; } ($person_evi) = &filterPg($person_evi) ;
    my $command = "INSERT INTO int_person_hst VALUES ('$id', '$person_evi');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_person VALUES ('$id', '$person_evi');";
    push @pgcommands, $command; }
  unless ($curator_evi) { $curator_evi = 'WBPerson480'; }	# assign no curator to Andrei
  if ($curator_evi) { 
#     print "curator_evi : $curator_evi\n"; 
    if ($curator_evi =~ m/\"/) { $veryBad .= "curator evidence $curator_evi has a doublequote\n"; } ($curator_evi) = &filterPg($curator_evi) ;
    my $command = "INSERT INTO int_curator_hst VALUES ('$id', '$curator_evi');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_curator VALUES ('$id', '$curator_evi');";
    push @pgcommands, $command; }
  if ($other_evi) { 
#     print "other_evi : $other_evi\n"; 
    ($other_evi) = &filterPg($other_evi);
    my $command = "INSERT INTO int_otherevi_hst VALUES ('$id', '$other_evi');";
    push @pgcommands, $command;
    $command = "INSERT INTO int_otherevi VALUES ('$id', '$other_evi');";
    push @pgcommands, $command; }
#   print "\n";

  if ($veryBad) { print ERR "// $date WBInteraction$veryBad\n$entry\n\n"; $allBad .= $veryBad; }	# print errors to err file
    else { foreach my $command (@pgcommands) { push @allpgcommands, $command; } }	# push good commands to full list if no errors
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (ERR) or die "Cannot close $errfile : $!";

# commented out checks because always populate data, according to Andrei  2008 08 04
# if ($allBad) { print "ERROR $allBad\n"; }
#   else {
    foreach my $command (@allpgcommands) {
      print "$command\n"; 
      $result = $conn->exec( $command );
    } 
# }


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

