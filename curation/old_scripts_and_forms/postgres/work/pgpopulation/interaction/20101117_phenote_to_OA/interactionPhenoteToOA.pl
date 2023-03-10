#!/usr/bin/perl -w

# check int_ data from phenote-like tables to convert to OA-style tables.  Check that if fits ontologies and then convert from | or ", " separation to '", "' style separation.  2010 11 16
#
# added manual exceptions and mapping that Xiaodong came up with.  2010 11 18
#
# moved mangolassi data from phenote format to OA format, and edited OA to work with it.  2010 11 29
#
# tazendra live run 2011 01 06


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;

my %papers;
my %persons;
my %genes;
my %transgenes;
my %variations;
my %phenotypes;

my %geneToGene;
my %paperToPaper;
&popGeneToGene();
&popPaperToPaper();

&populateWBGene();
sub populateWBGene {
  $result = $dbh->prepare( "SELECT * FROM gin_wbgene WHERE gin_wbgene IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[1]) { $genes{$row[1]}++; } }
  $genes{"WBGene00003004"}++;
  $genes{"WBGene00004799"}++;
  $genes{"WBGene00020676"}++;
} # sub populateWBGene
&populateTransgene();
sub populateTransgene {
  $result = $dbh->prepare( "SELECT * FROM trp_name WHERE trp_name IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[1]) { $transgenes{$row[1]}++; } }
} # sub populateTransgene
&populateVariation();
sub populateVariation {
  $result = $dbh->prepare( "SELECT * FROM obo_name_app_variation WHERE obo_name_app_variation IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $variations{id}{$row[0]}++; $variations{nameToID}{$row[1]} = $row[0]; } }
} # sub populateVariation
&populatePhenotype();
sub populatePhenotype {
  $result = $dbh->prepare( "SELECT * FROM obo_name_app_term WHERE obo_name_app_term IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $phenotypes{$row[0]}++; } }
} # sub populatePhenotype
&populatePerson();
sub populatePerson {
  $result = $dbh->prepare( "SELECT * FROM two_standardname WHERE two_standardname IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $row[0] =~ s/two/WBPerson/; $persons{$row[0]}++; } }
} # sub populatePerson
&populatePapers();
sub populatePapers {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $papers{"WBPaper$row[0]"}++; } }
} # sub populatePapers



my @types = qw( Genetic Regulatory No_interaction Predicted_interaction Physical_interaction Suppression Enhancement Synthetic Epistasis Mutual_enhancement Mutual_suppression );
my $types = join"' AND int_type != '", @types;

my $errfile = 'errors_interactionPhenoteToOA';
open(ERR, ">$errfile") or die "Cannot create $errfile : $!";

$result = $dbh->prepare( "SELECT * FROM int_name WHERE int_name !~ '^WBInteraction[0-9][0-9][0-9][0-9][0-9][0-9][0-9]\$'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { print ERR "bad int_name @row\n"; } }

$result = $dbh->prepare( "SELECT * FROM int_nondirectional WHERE int_nondirectional != 'Non_directional' AND int_nondirectional != '';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { print ERR "bad int_nondirectional @row\n"; } }

$result = $dbh->prepare( "SELECT * FROM int_type WHERE int_type != '$types';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { print ERR "bad int_type @row\n"; } }

$result = $dbh->prepare( "SELECT * FROM int_rnai WHERE int_rnai !~ '^WBRNAi[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\$'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { print ERR "bad int_rnai @row\n"; } }

$result = $dbh->prepare( "SELECT * FROM int_phenotype WHERE int_phenotype IS NOT NULL;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) {
  my @terms = split/\|/, $row[1];
  my @good_terms;
  foreach my $term (@terms) { 
    if ($phenotypes{$term}) { push @good_terms, $term; }				# it's good phenotype
      else { print ERR "bad $term int_phenotype @row\n"; } } 
  my $newValue = join'","', @good_terms; $newValue = '"' . $newValue . '"';
  my $command = "UPDATE int_phenotype SET int_phenotype = '$newValue' WHERE joinkey = '$row[0]' AND int_phenotype = '$row[1]'";
  push @pgcommands, $command;
} }

my @transgene_tables = qw( int_transgeneone int_transgenetwo );
foreach my $table (@transgene_tables) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my @terms = split/\|/, $row[1];
    my @good_terms;
    foreach my $term (@terms) { 
      if ($transgenes{$term}) { push @good_terms, $term; }				# it's good transgene
        else { print ERR "bad $term $table @row\n"; } } 
# transgenes are now just ontology, not multiontology
#     my $newValue = join'","', @good_terms; $newValue = '"' . $newValue . '"';
#     my $command = "UPDATE $table SET $table = '$newValue' WHERE joinkey = '$row[0]' AND $table = '$row[1]'";
#     push @pgcommands, $command;
} } }

my @gene_tables = qw( int_geneone int_transgeneonegene int_genetwo int_transgenetwogene );
foreach my $table (@gene_tables) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my @terms = split/\|/, $row[1];
    my @good_terms;
    foreach my $term (@terms) {
      if ($genes{$term}) { push @good_terms, $term; }				# it's good gene
        elsif ($geneToGene{$term}) { push @good_terms, $geneToGene{$term}; }	# has good mapping
        else { print ERR "bad $term $table @row\n"; } } 
    my $newValue = join'","', @good_terms; $newValue = '"' . $newValue . '"';
    my $command = "UPDATE $table SET $table = '$newValue' WHERE joinkey = '$row[0]' AND $table = '$row[1]'";
    push @pgcommands, $command;
} } }

my @variation_tables = qw( int_variationone int_variationtwo );
foreach my $table (@variation_tables) {
  $result = $dbh->prepare( "SELECT * FROM $table WHERE $table IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my @terms = split/, /, $row[1];
    my @newTerms;
    foreach my $term (@terms) {
      my $var = $term;
      if ($variations{id}{$term}) { push @newTerms, $term; }	# this is okay
        elsif ($variations{nameToID}{$term}) { $var = $variations{nameToID}{$term}; push @newTerms, $var; }	# convert name to ID
        else { print ERR "bad $term $table @row\n"; } }
    my $newValue = join'","', @newTerms;
    $newValue = '"'. $newValue . '"';
    my $command = "UPDATE $table SET $table = '$newValue' WHERE joinkey = '$row[0]' AND $table = '$row[1]'";
    push @pgcommands, $command;
} } }


$result = $dbh->prepare( "SELECT * FROM int_paper WHERE int_paper IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { 
  my $paper = '';
  if ($papers{$row[1]}) { $paper = $row[1]; }
    elsif ($paperToPaper{$row[1]}) {
      $paper = $paperToPaper{$row[1]}; 
      my $command = "UPDATE int_paper SET int_paper = '$paper' WHERE joinkey = '$row[0]' AND int_paper = '$row[1]'";
      push @pgcommands, $command; }
    else { print ERR "bad int_paper @row\n"; } 
} }

$result = $dbh->prepare( "SELECT * FROM int_person WHERE int_person IS NOT NULL" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { 
  if ($persons{$row[1]}) { 
      my $newValue = '"' . $row[1] . '"';
      my $command = "UPDATE int_person SET int_person = '$newValue' WHERE joinkey = '$row[0]' AND int_person = '$row[1]'";
      push @pgcommands, $command; }
    else { print ERR "bad int_person @row\n"; } 
} }
# multiontology, but all values have just one papers

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT to update values
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)


close(ERR) or die "Cannot close $errfile : $!";

sub popGeneToGene {
  $geneToGene{"WBGene00000398"} = "WBGene00001475";
  $geneToGene{"WBGene00001219"} = "WBGene00003025";
  $geneToGene{"WBGene00018832"} = "WBGene00003929";
  $geneToGene{"WBGene00001254"} = "WBGene00015981";
  $geneToGene{"WBGene00007037"} = "WBGene00002148";
  $geneToGene{"WBGene00007040"} = "WBGene00000445";
  $geneToGene{"WBGene00004289"} = "WBGene00018285";
  $geneToGene{"WBGene00004763"} = "WBGene00001258";
  $geneToGene{"WBGene00015314"} = "WBGene00002717";
  $geneToGene{"WBGene00003871"} = "WBGene00005744";
  $geneToGene{"WBGene00009376"} = "WBGene00009375";
  $geneToGene{"WBGene00020734"} = "WBGene00044623";
  $geneToGene{"WBGene00003819"} = "WBGene00002889";
  $geneToGene{"WBGene00016498"} = "WBGene00003242";
} # sub popGeneToGene

sub popPaperToPaper {
  $paperToPaper{"WBPaper00005944"} = "WBPaper00005822";
  $paperToPaper{"WBPaper00006145"} = "WBPaper00005909";
  $paperToPaper{"WBPaper00006518"} = "WBPaper00013396";
  $paperToPaper{"WBPaper00013354"} = "WBPaper00006377";
  $paperToPaper{"WBPaper00013357"} = "WBPaper00006391";
  $paperToPaper{"WBPaper00013358"} = "WBPaper00006388";
  $paperToPaper{"WBPaper00013392"} = "WBPaper00024188";
  $paperToPaper{"WBPaper00013397"} = "WBPaper00006519";
  $paperToPaper{"WBPaper00013417"} = "WBPaper00024228";
  $paperToPaper{"WBPaper00013428"} = "WBPaper00024234";
  $paperToPaper{"WBPaper00013429"} = "WBPaper00024194";
  $paperToPaper{"WBPaper00013436"} = "WBPaper00024207";
  $paperToPaper{"WBPaper00013437"} = "WBPaper00024206";
  $paperToPaper{"WBPaper00013438"} = "WBPaper00024218";
  $paperToPaper{"WBPaper00013446"} = "WBPaper00024213";
  $paperToPaper{"WBPaper00013459"} = "WBPaper00024262";
  $paperToPaper{"WBPaper00013464"} = "WBPaper00024423";
  $paperToPaper{"WBPaper00013501"} = "WBPaper00024307";
  $paperToPaper{"WBPaper00013512"} = "WBPaper00024212";
  $paperToPaper{"WBPaper00013518"} = "WBPaper00024430";
  $paperToPaper{"WBPaper00013525"} = "WBPaper00024211";
  $paperToPaper{"WBPaper00023885"} = "WBPaper00024303";
  $paperToPaper{"WBPaper00005694"} = "WBPaper00013312";
  $paperToPaper{"WBPaper00006287"} = "WBPaper00006247";
  $paperToPaper{"WBPaper00013431"} = "WBPaper00024210";
  $paperToPaper{"WBPaper00024499"} = "WBPaper00024985";
  $paperToPaper{"WBPaper00024384"} = "WBPaper00024898";
  $paperToPaper{"WBPaper00024371"} = "WBPaper00024474";
  $paperToPaper{"WBPaper00023910"} = "WBPaper00024301";
  $paperToPaper{"WBPaper00024936"} = "WBPaper00024670";
  $paperToPaper{"WBPaper00013519"} = "WBPaper00024321";
  $paperToPaper{"WBPaper00000962"} = "WBPaper00000880";
  $paperToPaper{"WBPaper00024282"} = "WBPaper00024451";
  $paperToPaper{"WBPaper00023886"} = "WBPaper00024450";
  $paperToPaper{"WBPaper00024938"} = "WBPaper00024542";
  $paperToPaper{"WBPaper00025027"} = "WBPaper00025132";
  $paperToPaper{"WBPaper00025042"} = "WBPaper00025164";
  $paperToPaper{"WBPaper00024702"} = "WBPaper00025147";
  $paperToPaper{"WBPaper00024499"} = "WBPaper00024985";
  $paperToPaper{"WBPaper00024500"} = "WBPaper00024986";
  $paperToPaper{"WBPaper00024928"} = "WBPaper00025140";
  $paperToPaper{"WBPaper00024410"} = "WBPaper00024876";
  $paperToPaper{"WBPaper00024935"} = "WBPaper00025001";
  $paperToPaper{"WBPaper00024332"} = "WBPaper00013507";
  $paperToPaper{"WBPaper00024963"} = "WBPaper00025151";
  $paperToPaper{"WBPaper00025060"} = "WBPaper00025138";
  $paperToPaper{"WBPaper00024565"} = "WBPaper00024891";
  $paperToPaper{"WBPaper00024701"} = "WBPaper00025148";
  $paperToPaper{"WBPaper00024969"} = "WBPaper00025114";
  $paperToPaper{"WBPaper00024948"} = "WBPaper00024886";
  $paperToPaper{"WBPaper00025015"} = "WBPaper00025135";
  $paperToPaper{"WBPaper00013460"} = "WBPaper00024263";
  $paperToPaper{"WBPaper00024384"} = "WBPaper00024898";
  $paperToPaper{"WBPaper00024362"} = "WBPaper00024532";
  $paperToPaper{"WBPaper00013460"} = "WBPaper00024263";
  $paperToPaper{"WBPaper00024677"} = "WBPaper00025000";
  $paperToPaper{"WBPaper00025043"} = "WBPaper00026596";
} # sub popPaperToPaper


__END__


#   $fields{int}{name}{type}          = 'text';			# match WBInteraction\d{7}
#   $fields{int}{nondirectional}{type}          = 'toggle';	# Non_directional or <blank>
#   $fields{int}{type}{type}          = 'dropdown';		# @types
#   $fields{int}{geneone}{type}          = 'multiontology';	# genes
  $fields{int}{variationone}{type}          = 'multiontology';	# obo_name_app_variation (from row[1] to row[0])
  $fields{int}{transgeneone}{type}          = 'ontology';	# trp_name
#   $fields{int}{transgeneonegene}{type}          = 'multiontology';	# genes
#   $fields{int}{genetwo}{type}          = 'multiontology';	# genes
  $fields{int}{variationtwo}{type}          = 'multiontology';	# obo_name_app_variation (from row[1] to row[0])
  $fields{int}{transgenetwo}{type}          = 'ontology';	# trp_name
#   $fields{int}{transgenetwogene}{type}          = 'multiontology';	# genes
#   $fields{int}{curator}{type}       = 'dropdown';		# already checked
#   $fields{int}{paper}{type}         = 'ontology';		# paper
#   $fields{int}{person}{type}         = 'multiontology';		# person
#   $fields{int}{rnai}{type}          = 'text';			# WBRNAi\d{8}
#   $fields{int}{phenotype}{type}          = 'multiontology';	# ``term''  obo_name_app_term
#   $fields{int}{remark}{type}          = 'bigtext';

  $fields{int}{id}{type}            = 'text';
  $fields{int}{name}{type}          = 'text';
  $fields{int}{nondirectional}{type}          = 'toggle';
  $fields{int}{type}{type}          = 'text';
  $fields{int}{type}{label}         = 'Interaction Type';
  $fields{int}{type}{tab}           = 'tab1';
  $fields{int}{geneone}{type}          = 'text';
  $fields{int}{variationone}{type}          = 'text';
  $fields{int}{transgeneone}{type}          = 'text';
  $fields{int}{transgeneonegene}{type}          = 'text';
  $fields{int}{genetwo}{type}          = 'text';
  $fields{int}{variationtwo}{type}          = 'text';
  $fields{int}{transgenetwo}{type}          = 'text';
  $fields{int}{transgenetwogene}{type}          = 'text';
  $fields{int}{curator}{type}       = 'dropdown';
  $fields{int}{paper}{type}         = 'text';
  $fields{int}{person}{type}         = 'text';
  $fields{int}{rnai}{type}          = 'text';
  $fields{int}{phenotype}{type}          = 'text';
  $fields{int}{phenotype}{label}         = 'Phenotype';
  $fields{int}{phenotype}{tab}           = 'tab2';
  $fields{int}{remark}{type}          = 'bigtext';
