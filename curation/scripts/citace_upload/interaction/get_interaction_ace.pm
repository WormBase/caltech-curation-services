package get_interaction_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getInteraction );
our $VERSION	= 1.00;

# dump interaction data.  for Chris.  2012 06 07

# added  &checkNamePgids();  to get all pgids from all table, subtract curator Arun, and check if any don't have an rna_name value.  2012 11 01
#
# added  Historical_gene  tag for merged genes.  Dead genes only have Historcial_gene tag.  Split genes do not dump the whole object.  2013 05 21
#
# changed gin_dead to not have just "Dead" or "split_into / merged_into", now it has Dead / Suppressed / merged_into / split_into independent of
# each other (all merged / split must be dead though), so Chris has made a precedece for how to treat them (split > merged > suppressed > dead),
# and the dumper makes the Historical_gene comments appropriately.  2013 10 21
#
# added  int_featurebait  and  int_featuretarget  to dump into  Feature_interactor .  For Chris.  2013 11 21
#
# added  int_nodump  table to prevent dumping (oddly, code already accounted for it, but table never existed that I can recall)  For Chris  2014 05 12
#
# gene / driven_by_gene / threeutr have moved from transgene trp_ to construct cns_ so removed that checking from transgene and added it to construct.  changed transgene objects to dump as Unaffiliated_transgene.  For Chris and Karen.  2014 07 10
#
# removed tables : deviation  neutralityfxn  intravariationone  intravariationtwo .  
# No longer dump Unaffiliated_variation to .ace file.
# No longer dump Interactor_overlapping_gene for Variation, instead dump  Variation_interactor.  2015 02 19
#
# Historical_gene Remark moved out of #Evidence into just Text.
# Chris wants original gene + interactor info back in .ace file for suppressed and dead genes.  2015 03 12
#
# Split genes now dump data instead of suppressing the object.  2015 03 16
#
# Dump moleculenondir moleculeone moleculetwo  
# Bring back transgene mapping to good genes, now from transgene to construct to genes.  2015 03 26
#
# Removed int_otheronetype + int_othertwotype as one of the two datatypes (chemical) got moved to the new molecule table.  Added int_othernondir .  2015 03 30
#
# chris wants leading  doublequotes dumped  2016 08 13
#
# no longer dumping from int_type, generate type based on gimoduleone/two/three  2017 04 14
# NEED TO FIGURE OUT WHY THERE's NO OUTPUT WITHOUT type IN @table.  2017 04 14



use strict;
use diagnostics;
use LWP;
use LWP::Simple;
use DBI;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %theHash;


# my @tables = qw( nodump name process database paper type summary remark detectionmethod library laboratory company pcrbait pcrtarget pcrnondir sequencebait sequencetarget sequencenondir featurebait featuretarget cdsbait cdstarget cdsnondir proteinbait proteintarget proteinnondir genebait genetarget antibody antibodyremark genenondir geneone genetwo rearrnondir rearrone rearrtwo otheronetype otherone othertwotype othertwo deviation neutralityfxn rnai lsrnai phenotype exprpattern variationnondir variationone variationtwo intravariationone intravariationtwo transgene construct person confidence pvalue loglikelihood throughput falsepositive curator );
# my @tables = qw( nodump name process database paper type summary remark detectionmethod library laboratory company pcrbait pcrtarget pcrnondir sequencebait sequencetarget sequencenondir featurebait featuretarget cdsbait cdstarget cdsnondir proteinbait proteintarget proteinnondir genebait genetarget antibody antibodyremark genenondir geneone genetwo rearrnondir rearrone rearrtwo othernondir otherone othertwo rnai lsrnai phenotype exprpattern variationnondir variationone variationtwo moleculenondir moleculeone moleculetwo transgene construct person confidence pvalue loglikelihood throughput falsepositive curator );

my @tables = qw( nodump name process database paper type gimoduleone gimoduletwo gimodulethree summary remark detectionmethod library laboratory company pcrbait pcrtarget pcrnondir sequencebait sequencetarget sequencenondir featurebait featuretarget cdsbait cdstarget cdsnondir proteinbait proteintarget proteinnondir genebait genetarget antibody antibodyremark genenondir geneone genetwo rearrnondir rearrone rearrtwo othernondir otherone othertwo rnai lsrnai phenotype exprpattern variationnondir variationone variationtwo moleculenondir moleculeone moleculetwo transgene construct person confidence pvalue loglikelihood throughput falsepositive curator );


my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;
my %mapToGene;


my %fieldType;
$fieldType{"database"}                      = 'noquote';
$fieldType{"library"}                       = 'noquote';
$fieldType{"throughput"}                    = 'special';
$fieldType{"antibody"}                      = 'special';
# $fieldType{"otheronetype"}                  = 'special';
# $fieldType{"othertwotype"}                  = 'special';
$fieldType{"exprpattern"}                   = 'special';
$fieldType{"variationnondir"}               = 'special';
$fieldType{"variationone"}                  = 'special';
$fieldType{"variationtwo"}                  = 'special';
# $fieldType{"intravariationone"}             = 'special';
# $fieldType{"intravariationtwo"}             = 'special';
$fieldType{"transgene"}                     = 'special';
$fieldType{"construct"}                     = 'special';
$fieldType{"person"}                        = 'special';

my %dataType;
$dataType{"process"}                        = 'multiontology';
$dataType{"person"}                         = 'multiontology';
$dataType{"phenotype"}                      = 'multiontology';
$dataType{"detectionmethod"}                = 'multidropdown';
$dataType{"pcrbait"}                        = 'multiontology';
$dataType{"pcrtarget"}                      = 'multiontology';
$dataType{"pcrnondir"}                      = 'multiontology';
$dataType{"featurebait"}                    = 'multiontology';
$dataType{"featuretarget"}                  = 'multiontology';
$dataType{"genetarget"}                     = 'multiontology';
$dataType{"antibody"}                       = 'multiontology';
$dataType{"genenondir"}                     = 'multiontology';
$dataType{"geneone"}                        = 'multiontology';
$dataType{"genetwo"}                        = 'multiontology';
$dataType{"variationnondir"}                = 'multiontology';
$dataType{"variationone"}                   = 'multiontology';
$dataType{"variationtwo"}                   = 'multiontology';
$dataType{"moleculenondir"}                 = 'multiontology';
$dataType{"moleculeone"}                    = 'multiontology';
$dataType{"moleculetwo"}                    = 'multiontology';
$dataType{"rearrnondir"}                    = 'multiontology';
$dataType{"rearrone"}                       = 'multiontology';
$dataType{"rearrtwo"}                       = 'multiontology';
$dataType{"rnai"}                           = 'multiontology';
$dataType{"exprpattern"}                    = 'multiontology';
$dataType{"transgene"}                      = 'multiontology';
$dataType{"construct"}                      = 'multiontology';


my %tableToTag;
# $tableToTag{"name"}                          = 'Interaction : ';	# object header, not a tag
$tableToTag{"process"}                       = 'WBProcess';
$tableToTag{"database"}                      = 'Database';
$tableToTag{"paper"}                         = 'Paper';
# $tableToTag{"type"}                          = 'self';
$tableToTag{"gimoduleone"}                   = 'self';
$tableToTag{"gimoduletwo"}                   = 'self';
$tableToTag{"gimodulethree"}                 = 'self';
$tableToTag{"summary"}                       = 'Interaction_summary';
$tableToTag{"remark"}                        = 'Remark';
$tableToTag{"detectionmethod"}               = 'self';
$tableToTag{"library"}                       = 'Library_screened';
$tableToTag{"laboratory"}                    = 'From_laboratory';
$tableToTag{"company"}                       = 'From_company';
$tableToTag{"pcrbait"}                       = 'PCR_interactor';
$tableToTag{"pcrtarget"}                     = 'PCR_interactor';
$tableToTag{"pcrnondir"}                     = 'PCR_interactor';
$tableToTag{"sequencebait"}                  = 'Sequence_interactor';
$tableToTag{"sequencetarget"}                = 'Sequence_interactor';
$tableToTag{"sequencenondir"}                = 'Sequence_interactor';
$tableToTag{"featurebait"}                   = 'Feature_interactor';
$tableToTag{"featuretarget"}                 = 'Feature_interactor';
$tableToTag{"cdsbait"}                       = 'Interactor_overlapping_CDS';
$tableToTag{"cdstarget"}                     = 'Interactor_overlapping_CDS';
$tableToTag{"cdsnondir"}                     = 'Interactor_overlapping_CDS';
$tableToTag{"proteinbait"}                   = 'Interactor_overlapping_protein';
$tableToTag{"proteintarget"}                 = 'Interactor_overlapping_protein';
$tableToTag{"proteinnondir"}                 = 'Interactor_overlapping_protein';
$tableToTag{"genebait"}                      = 'Interactor_overlapping_gene';
$tableToTag{"genetarget"}                    = 'Interactor_overlapping_gene';
$tableToTag{"antibody"}                      = 'special';
$tableToTag{"antibodyremark"}                = 'Antibody_remark';
$tableToTag{"genenondir"}                    = 'Interactor_overlapping_gene';
$tableToTag{"geneone"}                       = 'Interactor_overlapping_gene';
$tableToTag{"genetwo"}                       = 'Interactor_overlapping_gene';
$tableToTag{"rearrnondir"}                   = 'Rearrangement';
$tableToTag{"rearrone"}                      = 'Rearrangement';
$tableToTag{"rearrtwo"}                      = 'Rearrangement';
$tableToTag{"otherone"}                      = 'Other_interactor';
$tableToTag{"othertwo"}                      = 'Other_interactor';
$tableToTag{"othernondir"}                   = 'Other_interactor';
# $tableToTag{"otheronetype"}                  = 'special';
# $tableToTag{"otherone"}                      = 'by_other';
# $tableToTag{"othertwotype"}                  = 'special';
# $tableToTag{"othertwo"}                      = 'by_other';
# $tableToTag{"deviation"}                     = 'Deviation_from_expectation';
# $tableToTag{"neutralityfxn"}                 = 'self';
$tableToTag{"rnai"}                          = 'Interaction_RNAi';
$tableToTag{"lsrnai"}                        = 'Interaction_RNAi';
$tableToTag{"phenotype"}                     = 'Interaction_phenotype';
$tableToTag{"exprpattern"}                   = 'special';
$tableToTag{"variationnondir"}               = 'special';
$tableToTag{"variationone"}                  = 'special';
$tableToTag{"variationtwo"}                  = 'special';
$tableToTag{"moleculenondir"}                = 'Molecule_interactor';
$tableToTag{"moleculeone"}                   = 'Molecule_interactor';
$tableToTag{"moleculetwo"}                   = 'Molecule_interactor';
# $tableToTag{"intravariationone"}             = 'special';
# $tableToTag{"intravariationtwo"}             = 'special';
$tableToTag{"transgene"}                     = 'Unaffiliated_transgene';
$tableToTag{"construct"}                     = 'special';
$tableToTag{"person"}                        = 'special';
$tableToTag{"confidence"}                    = 'Description';
$tableToTag{"pvalue"}                        = 'P_value';
$tableToTag{"loglikelihood"}                 = 'Log_likelihood_score';
$tableToTag{"throughput"}                    = 'special';





my %deadObjects;	# reading the following 
#  $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1]; 
#  $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; 
#  $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; 
#  $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; 

my %badMultiline;
my %ontologyIdToName;

# not used by this dumper, but if we add molecule objects we'll need this.
# my %moleculePgidToMolecule;				# pgid of molecule -> molecule id
# sub populateMoleculePgidToMolecule {
#   $result = $dbh->prepare( "SELECT * FROM mop_molecule;" );
#   $result->execute();	
#   while (my @row = $result->fetchrow) { $moleculePgidToMolecule{$row[0]} = $row[1]; } }

sub checkNamePgids {
  my %hash; my %name;

  foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM int_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      if ($table eq 'name') { $name{$row[0]}++; }
        else { $hash{$row[0]}++; } } } }

  $result = $dbh->prepare( "SELECT * FROM int_curator WHERE int_curator = 'WBPerson4793'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { delete $hash{$row[0]}; } }

  foreach my $pgid (sort {$a<=>$b} keys %hash) { unless ($name{$pgid}) { $err_text .= "$pgid has no int_name\n"; } }
} # sub checkNamePgids

sub populateBadMultiline {
  $result = $dbh->prepare( "SELECT int_name, COUNT(*) AS count FROM int_name  GROUP BY int_name HAVING COUNT(*) > 1;" );	# interactions with same int_name in multiple pgids
  $result->execute();	
  while (my @row = $result->fetchrow) { $badMultiline{$row[0]} = $row[1]; }
} # sub populateBadMultiline

1;

sub getInteraction {
  my ($flag) = shift;

  &populateObjToGene();
#   &populateMoleculePgidToMolecule(); 	# not used by this dumper, but if we add molecule objects we'll need this.
  &populateDeadObjects(); 
  &populateBadMultiline();
  &checkNamePgids();				# comment this out when developing, adds a bit of time.

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM int_name; " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM int_name WHERE int_name = '$flag';" ); }	# get all entries for type of object intid
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM int_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $objName (sort keys %{ $nameToIDs{object} }) {
    my $entry = ''; my $has_data;
    $entry .= "\nInteraction : \"$objName\"\n";

    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$objName} }) {
      next if ($theHash{nodump}{$joinkey});
      my $suppress_this_object = 0; 
      my $curator = 'no curator';
      if ($theHash{curator}{$joinkey}) { $curator = $theHash{curator}{$joinkey}; }
        else {  $err_text .= "$joinkey\tflagonly\t$curator\thas no curator\n"; } 

      my ($checkFlag) = &checkConstraints($joinkey, $curator);

      next if ($checkFlag eq 'nodump');
      my $goodGenes_ref = &getGoodGenes($joinkey);
      my $cur_entry = ''; my $has_suppressing_error = '';
      foreach my $table (@tables) {
        if ($table eq 'type') { 
          my ($inttype) = &getIntType($joinkey);
#           $cur_entry .= qq(Interaction_type\t$inttype\n); 
          $cur_entry .= qq($inttype\n); 
        }
        next unless ($tableToTag{$table});
        my $tag = $tableToTag{$table};
        my $fieldType = 'normal'; if ($fieldType{$table}) { $fieldType = $fieldType{$table}; }
        ($cur_entry, $has_suppressing_error) = &getData($cur_entry, $table, $joinkey, $tag, $fieldType, $objName, $curator, $goodGenes_ref);
        if ($has_suppressing_error) { $suppress_this_object++; }	# if any data has an error, suppress this object
      }
      next if ($suppress_this_object);			# don't add to entry if it should be suppressed
      if ($theHash{throughput}{$joinkey}) { $cur_entry .= "$theHash{throughput}{$joinkey}\n"; }
        else { $cur_entry .= "Low_throughput\n"; }
      if ($cur_entry) { $entry .= "$cur_entry"; $has_data++; }                  # if .ace object has a phenotype, append to whole list
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$objName} })
    if ($has_data) { $all_entry .= $entry; }
  } # foreach my $objName (sort keys %{ $nameToIDs{object} })
  return( $all_entry, $err_text );
} # sub getInteraction

sub getIntType {
  my ($joinkey) = @_;
  my $type = '';
  my ($pgtype, $g1, $g2, $g3) = ('', '', '', '');
  if ($theHash{'type'}{$joinkey})          { $pgtype = $theHash{'type'}{$joinkey};   }
  if ($theHash{'gimoduleone'}{$joinkey})   { $g1     = $theHash{'gimoduleone'}{$joinkey};   }
  if ($theHash{'gimoduletwo'}{$joinkey})   { $g2     = $theHash{'gimoduletwo'}{$joinkey};   }
  if ($theHash{'gimodulethree'}{$joinkey}) { $g3     = $theHash{'gimodulethree'}{$joinkey}; }
  if ( ($pgtype eq 'ProteinDNA') ||
       ($pgtype eq 'ProteinRNA') ||
       ($pgtype eq 'ProteinProtein') ||
       ($pgtype eq 'Physical') ) { $type = $pgtype; }
    elsif ($g3 eq 'Neutral') {                                               $type = 'No_interaction'; }
    elsif ( ($g1 eq 'A_phenotypic') && ($g3 eq 'Diverging') ) {              $type = 'Synthetic'; }
    elsif ( ($g1 eq 'Mono_phenotypic')  && ($g2 eq 'All_suppressing') ) {    $type = 'Complete_unilateral_suppression'; }
    elsif ( ($g1 eq 'Mono_phenotypic')  && ($g2 eq 'Enhancing') ) {          $type = 'Unilateral_enhancement'; }
    elsif ( ($g1 eq 'Mono_phenotypic')  && ($g2 eq 'Sub_suppressing') ) {    $type = 'Partial_unilateral_suppression'; }
    elsif ( ($g1 eq 'Mono_phenotypic')  && ($g2 eq 'Suppressing') ) {        $type = 'Unilateral_suppression'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'All_suppressing') ) {    $type = 'Complete_mutual_suppression'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Co_suppressing') ) {     $type = 'Mutual_suppression'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Enhancing') ) {          $type = 'Mutual_enhancement'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Inter_suppressing') ) {  $type = 'Suppression_enhancement'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Masking') ) {            $type = 'Maximal_epistasis'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Semi_suppressing') ) {   $type = 'Minimal_epistasis'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Super_suppressing') ) {  $type = 'Mutual_oversuppression'; }
    elsif ( ($g1 eq 'Cis_phenotypic')   && ($g2 eq 'Suppressing') ) {        $type = 'Mutual_suppression'; }
    elsif ( ($g1 eq 'Iso_phenotypic')   && ($g2 eq 'Masking') ) {            $type = 'Asynthetic'; }
    elsif ( ($g1 eq 'Trans_phenotypic') && ($g2 eq 'All_suppressing') ) {    $type = 'Complete_mutual_suppression'; }
    elsif ( ($g1 eq 'Trans_phenotypic') && ($g2 eq 'Enhancing') ) {          $type = 'Oversuppression_enhancement'; }
    elsif ( ($g1 eq 'Trans_phenotypic') && ($g2 eq 'Masking') ) {            $type = 'Opposing_epistasis'; }
    elsif ( ($g1 eq 'Trans_phenotypic') && ($g2 eq 'Suppressing') ) {        $type = 'Mutual_suppression'; }
    elsif ($g2 eq 'Enhancing') {                                             $type = 'Enhancement'; }
    elsif ($g2 eq 'Suppressing') {                                           $type = 'Suppression'; }
    elsif ($g2 eq 'Sub_suppressing') {                                       $type = 'Partial_suppression'; }
    elsif ($g2 eq 'All_suppressing') {                                       $type = 'Complete_suppression'; }
    elsif ($g2 eq 'Super_suppressing') {                                     $type = 'Oversuppression'; }
    elsif ($g2 eq 'Masking') {                                               $type = 'Epistasis'; }
    elsif ( ($g1 eq '') || ($g2 eq '') || ($g3 eq '') ) {                    $type = 'Genetic_interaction'; }
    else {                                                                   $type = qq(ERROR $g1 $g2 $g3); }
  return $type;
}

sub getData {
  my ($cur_entry, $table, $joinkey, $tag, $fieldType, $objName, $curator, $goodGenes_ref) = @_;
  if ($tag eq 'by_other') { return $cur_entry }					# dumped by other tag
  my $has_suppressing_error = 0;					# if there's an error to return, will suppress pgid entry
  my %goodGenes = %$goodGenes_ref;
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my @data;
    my $dataType = $dataType{$table} || '';
    if ( ($dataType eq 'multiontology') || ($dataType eq 'multidropdown') ) {
      if ($data =~ m/^\"/) { $data =~ s/^\"//; }				# chris wants leading  doublequotes dumped  2016 08 13
      if ($data =~ m/\"$/) { $data =~ s/\"$//; } }
    if ($data =~ m/\",\"/) { 
        if ($data =~ m/^\"/)  { $data =~ s/^\"//;   }   # leading  doublequotes need to be removed from multivalue fields  2016 08 13
        if ($data =~ m/\"$/)  { $data =~ s/\"$//;   }   # trailing doublequotes need to be removed from multivalue fields  2016 08 13
        @data = split/\",\"/, $data; }
      elsif ($data =~ m/ \| /) { @data = split/ \| /, $data; }
      else { push @data, $data; }
    foreach my $value (@data) {
      unless ($fieldType eq 'noquote') {
        if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; } }

#       if ($table eq 'moleculeregulator') { if ($moleculePgidToMolecule{$value}) { $value = $moleculePgidToMolecule{$value}; } }	# convert molecule pgids to molecule ids if we ever need this 

      if ($value) {
        my $geneFound = 0;
        if ($tag eq 'self') { $cur_entry .= qq($value\n); }
          elsif ($fieldType eq 'noquote') { $cur_entry .= "$tag\t$value\n"; }
          elsif ($fieldType eq 'special') {
            if ($table eq 'throughput') { 1; }					# dump one thing if exists, Low_throughput if no value, happens outside this function
            elsif ($table eq 'antibody') {
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Antibody "$value"\n); } } }
              if ($geneFound) { $cur_entry .= qq(Antibody\n); }
                else {
                  $err_text .= qq($joinkey\tlineonly\t$curator\t$objName\tUnaffiliated_antibody\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_antibody\t"$value"\n); } }
            elsif ($table eq 'construct') {
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Construct "$value"\n); } } }
              if ($geneFound) { $cur_entry .= qq(Construct\n); }
                else {
                  $err_text .= qq($joinkey\tlineonly\t$curator\t$objName\tUnaffiliated_construct\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_construct\t"$value"\n); } }
            elsif ($table eq 'transgene') {					# brought back by way of transgene -> construct -> gene  2015 03 27
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Transgene "$value"\n); } } }
              if ($geneFound) { $cur_entry .= qq(Transgene\n); }
                else {
                  $err_text .= qq($joinkey\tlineonly\t$curator\t$objName\tUnaffiliated_transgene\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_transgene\t"$value"\n); } }
            elsif ($table eq 'exprpattern') {
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Expr_pattern "$value"\n); } } }
              if ($geneFound) { 1; }
                else {
                  $err_text .= qq($joinkey\tlineonly\t$curator\t$objName\tUnaffiliated_expr_pattern\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_expr_pattern\t"$value"\n); } }
#             elsif ( ($table eq 'variationnondir') || ($table eq 'variationone') || ($table eq 'variationtwo') || ($table eq 'intravariationone') || ($table eq 'intravariationtwo') )
            elsif ( ($table eq 'variationnondir') || ($table eq 'variationone') || ($table eq 'variationtwo') ) {
              if ($table eq 'variationone') {         $cur_entry .= qq(Variation_interactor "$value" Effector\n); }
                elsif ($table eq 'variationtwo') {    $cur_entry .= qq(Variation_interactor "$value" Affected\n); }
                elsif ($table eq 'variationnondir') { $cur_entry .= qq(Variation_interactor "$value" Non_directional\n); }
              if ($mapToGene{allele}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{allele}{$value} }) {
#                     if ($goodGenes{$gene}) {
                     $geneFound++;
                     if ($table eq 'variationone') {
#                          $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Variation "$value"\n); 
                         $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Effector\n); }
                       elsif ($table eq 'variationtwo') {
#                          $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Variation "$value"\n); 
                         $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Affected\n); }
                       elsif ($table eq 'variationnondir') {
#                          $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Variation "$value"\n); 
                         $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Non_directional\n); }
#                        elsif ($table eq 'intravariationone') {
#                          $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Intragenic_effector_variation "$value"\n); }
#                        elsif ($table eq 'intravariationtwo') {
#                          $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Intragenic_affected_variation "$value"\n); }
# }
                     } }
              if ($geneFound) { 1; }
                else {
#                   $cur_entry .= qq(Unaffiliated_variation\t"$value"\n); 
                  $err_text .= qq($joinkey\tlineonly\t$curator\t$objName\tUnaffiliated_variation\t"$value"\n); } }
#             elsif ($table eq 'otheronetype') {
#               my $type = $value; my $text = ''; if ($theHash{'otherone'}{$joinkey}) { $text = $theHash{'otherone'}{$joinkey}; }
#               $cur_entry .= qq(Remark\t"Effector $type: $text"\n); }
#             elsif ($table eq 'othertwotype') {
#               my $type = $value; my $text = ''; if ($theHash{'othertwo'}{$joinkey}) { $text = $theHash{'othertwo'}{$joinkey}; }
#               $cur_entry .= qq(Remark\t"Affected $type: $text"\n); }
            elsif ($table eq 'person') {
              my $remark = 'See Person Evidence'; if ($theHash{'remark'}{$joinkey}) { $remark = $theHash{'remark'}{$joinkey}; }
              if ($remark =~ m/\"/) { $remark =~ s/\"/\\\"/g; }
              $cur_entry .= qq(Remark\t"$remark"\tPerson_evidence\t"$value"\n); }
          } # elsif ($fieldType eq 'special') 
          else {									# regular values
            my $main_line = qq($tag\t"$value");	my $skip_main_line = 0;		# if fully dead gene skip printing the main line later
            if ( ($table eq 'genebait') || ($table eq 'genetarget') || ($table eq 'genenondir') || 
                 ($table eq 'geneone') || ($table eq 'genetwo') ) {
               if ($deadObjects{gene}{"mapto"}{$value}) {	# if gene maps to another gene, add the mapped version
#                    $cur_entry .= qq(Historical_gene  "$value"  Remark  "Note: This object originally referred to $value.  $value is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$value}. $deadObjects{gene}{"mapto"}{$value} has replaced $value accordingly."\n);
                   $cur_entry .= qq(Historical_gene  "$value"  "Note: This object originally referred to $value.  $value is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$value}. $deadObjects{gene}{"mapto"}{$value} has replaced $value accordingly."\n);
                   my $mappedGene = $deadObjects{gene}{"mapto"}{$value}; 	# convert to new gene
                   $cur_entry .= qq($tag\t"$mappedGene" Inferred_automatically\n);
                   $main_line = qq($tag\t"$mappedGene"); }
                 elsif ($deadObjects{gene}{"suppressed"}{$value}) {
#                    $skip_main_line++;						# 2015 03 12 Chris wants original gene + interactor info back in .ace file
#                    $cur_entry .= qq(Historical_gene\t"$value" Remark  "Note: This object originally referred to a gene ($value) that has been suppressed. Please interpret with discretion."\n);
                   $cur_entry .= qq(Historical_gene\t"$value" "Note: This object originally referred to a gene ($value) that has been suppressed. Please interpret with discretion."\n); }
                 elsif ($deadObjects{gene}{"dead"}{$value}) {
#                    $cur_entry .= qq($tag\t"$value" Remark  "Note: This object refers to a gene ($value) that is now considered dead. Please interpret with discretion."\n);
#                    $skip_main_line++;						# 2015 03 12 Chris wants original gene + interactor info back in .ace file
#                    $cur_entry .= qq(Historical_gene\t"$value" Remark  "Note: This object originally referred to a gene ($value) that is now considered dead. Please interpret with discretion."\n);
                   $cur_entry .= qq(Historical_gene\t"$value" "Note: This object originally referred to a gene ($value) that is now considered dead. Please interpret with discretion."\n); }
                 elsif ($deadObjects{gene}{"split"}{$value}) {	# anything with a split gene is an error
#                    $has_suppressing_error++;					# 2015 03 16 Chris no longer wants to suppress these entries
                   $cur_entry .= qq(Historical_gene\t"$value" "Note: This object originally referred to a gene ($value) that is now considered split. Please interpret with discretion."\n);
                   $err_text .= "$joinkey\tnodump\t$curator\tThis pgid contains a gene that has been split $value in $table.\n"; } }
            next if ($skip_main_line);			# refers to a dead gene, don't dump the main line
            if ($table =~ m/bait$/ ) {        $main_line .= " Bait"; }
              elsif ($table =~ m/target$/ ) { $main_line .= " Target"; }
              elsif ($table =~ m/nondir$/ ) { $main_line .= " Non_directional"; }
              elsif ($table =~ m/one$/ ) {    $main_line .= " Effector"; }
              elsif ($table =~ m/two$/ ) {    $main_line .= " Affected"; }
            $cur_entry .= "$main_line\n"; 
          }
      } # if ($value)
    } # foreach my $value (@data)
  } # if ($theHash{$table}{$joinkey})
  return ($cur_entry, $has_suppressing_error);
} # sub getData

sub getGoodGenes {
  my $joinkey = shift;
  my %goodGenes;
  my @gene_fields = qw( geneone genetwo genenondir genebait genetarget );
  foreach my $gene_field (@gene_fields) {
    if ($theHash{$gene_field}{$joinkey}) {
      my $genes = $theHash{$gene_field}{$joinkey};
      if ($genes =~ m/^\"/) { $genes =~ s/^\"//; }
      if ($genes =~ m/\"$/) { $genes =~ s/\"$//; }
      my @genes = split/\",\"/, $genes;
      foreach my $gene (@genes) { 
        if ($deadObjects{gene}{"mapto"}{"$gene"}) { 		# if gene maps to another gene, add the mapped version
          $gene = $deadObjects{gene}{"mapto"}{"$gene"}; }
        $goodGenes{$gene}++; } } }
#   my @var_fields = qw( variationnondir variationone variationtwo intravariationone intravariationtwo );
  my @var_fields = qw( variationnondir variationone variationtwo );
  foreach my $var_field (@var_fields) {
    if ($theHash{$var_field}{$joinkey}) {
      my $vars = $theHash{$var_field}{$joinkey};
      if ($vars =~ m/^\"/) { $vars =~ s/^\"//; }
      if ($vars =~ m/\"$/) { $vars =~ s/\"$//; }
      my @vars = split/\",\"/, $vars;
      foreach my $var (@vars) { 								# for each variation
        if ($mapToGene{allele}{$var}) {								# if it maps to a gene
            foreach my $gene (sort keys %{ $mapToGene{allele}{$var} }) { 
              if ($deadObjects{gene}{"mapto"}{"$gene"}) { 	# if gene maps to another gene, add the mapped version
                $gene = $deadObjects{gene}{"mapto"}{"$gene"}; }
              $goodGenes{$gene}++;	# add each gene to the goodGenes list
  } } } } }
  return \%goodGenes;
} # sub getGoodGenes


sub populateObjToGene {
  my $result = $dbh->prepare( " SELECT abp_name.joinkey, abp_name.abp_name, abp_gene.abp_gene FROM abp_name, abp_gene WHERE abp_name.joinkey = abp_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $antibody = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { 
    if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{antibody}{$antibody}{$gene}++; } }

$result = $dbh->prepare( " SELECT exp_name.joinkey, exp_name.exp_name, exp_gene.exp_gene FROM exp_name, exp_gene WHERE exp_name.joinkey = exp_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $exprpattern = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { 
    if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{exprpattern}{$exprpattern}{$gene}++; } }

# $result = $dbh->prepare( " SELECT trp_name.joinkey, trp_name.trp_name, trp_driven_by_gene.trp_driven_by_gene FROM trp_name, trp_driven_by_gene WHERE trp_name.joinkey = trp_driven_by_gene.joinkey; ");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) {
#   my $pgid = $row[0];
#   my $transgene = $row[1];
#   my $genes = $row[2];
#   $genes =~s /^\"//; $genes =~s /\"$//;
#   my (@genes) = split/\",\"/, $genes;
#   foreach my $gene (@genes) { 
#     if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
#       $gene = $deadObjects{gene}{"mapto"}{$gene}; }
#     $mapToGene{transgene}{$transgene}{$gene}++; } }
# $result = $dbh->prepare( " SELECT trp_name.joinkey, trp_name.trp_name, trp_gene.trp_gene FROM trp_name, trp_gene WHERE trp_name.joinkey = trp_gene.joinkey; ");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) {
#   my $pgid = $row[0];
#   my $transgene = $row[1];
#   my $genes = $row[2];
#   $genes =~s /^\"//; $genes =~s /\"$//;
#   my (@genes) = split/\",\"/, $genes;
#   foreach my $gene (@genes) { 
#     if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
#       $gene = $deadObjects{gene}{"mapto"}{$gene}; }
#     $mapToGene{transgene}{$transgene}{$gene}++; } }
# $result = $dbh->prepare( " SELECT trp_name.joinkey, trp_name.trp_name, trp_threeutr.trp_threeutr FROM trp_name, trp_threeutr WHERE trp_name.joinkey = trp_threeutr.joinkey; ");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) {
#   my $pgid = $row[0];
#   my $transgene = $row[1];
#   my $genes = $row[2];
#   $genes =~s /^\"//; $genes =~s /\"$//;
#   my (@genes) = split/\",\"/, $genes;
#   foreach my $gene (@genes) { 
#     if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
#       $gene = $deadObjects{gene}{"mapto"}{$gene}; }
#     $mapToGene{transgene}{$transgene}{$gene}++; } }

$result = $dbh->prepare( " SELECT cns_name.joinkey, cns_name.cns_name, cns_drivenbygene.cns_drivenbygene FROM cns_name, cns_drivenbygene WHERE cns_name.joinkey = cns_drivenbygene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $construct = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { 
    if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{construct}{$construct}{$gene}++; } }
$result = $dbh->prepare( " SELECT cns_name.joinkey, cns_name.cns_name, cns_gene.cns_gene FROM cns_name, cns_gene WHERE cns_name.joinkey = cns_gene.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $construct = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { 
    if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{construct}{$construct}{$gene}++; } }
$result = $dbh->prepare( " SELECT cns_name.joinkey, cns_name.cns_name, cns_threeutr.cns_threeutr FROM cns_name, cns_threeutr WHERE cns_name.joinkey = cns_threeutr.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $construct = $row[1];
  my $genes = $row[2];
  $genes =~s /^\"//; $genes =~s /\"$//;
  my (@genes) = split/\",\"/, $genes;
  foreach my $gene (@genes) { 
    if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{construct}{$construct}{$gene}++; } }

$result = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE obo_data_variation ~ 'WBGene';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my ($name) = $row[1] =~ m/name: \"(.*?)\"/;
  my (@genes) = $row[1] =~ m/(WBGene\d+)/g;
  my $varId = $row[0];
  foreach my $gene (@genes) { 
    if ($deadObjects{gene}{"mapto"}{$gene}) { 	# if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{allele}{$varId}{$gene}++; $mapToGene{allele}{$name}{$gene}++; } }


  # transgenes map to genes via constructs.  2015 03 27
$result = $dbh->prepare( " SELECT trp_name.joinkey, trp_name.trp_name, trp_construct.trp_construct FROM trp_name, trp_construct WHERE trp_name.joinkey = trp_construct.joinkey; ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $transgene = $row[1];
  my $constructs = $row[2];
  $constructs =~s /^\"//; $constructs =~s /\"$//;
  my (@constructs) = split/\",\"/, $constructs;
  foreach my $construct (@constructs) { 
    foreach my $gene (sort keys %{ $mapToGene{construct}{$construct} }) {
      $mapToGene{transgene}{$transgene}{$gene}++; } } }
} # sub populateObjToGene

sub populateDeadObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
#   while (my @row = $result->fetchrow) { $deadObjects{gene}{"WBGene$row[0]"} = $row[1]; }
  while (my @row = $result->fetchrow) {			# Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
    if ($row[1] =~ m/split_into (WBGene\d+)/) {       $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) { $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {              $deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {                    $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
#   while (my @row = $result->fetchrow) {		# previously gin_dead only had "Dead" or "merged_into / split_into", now it can have all 3 plus Suppressed, so redoing it based on priorities set by Chris
#     if ($row[1] =~ m/Dead/) { $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; }
#       else {
#         if ($row[1] =~ m/merged_into (WBGene\d+)/) { $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
#         if ($row[1] =~ m/split_into (WBGene\d+)/) { $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; } } }
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


sub checkConstraints {
  my ($joinkey, $curator) = @_;
  my @bait     = qw( pcrbait sequencebait cdsbait proteinbait genebait featurebait );
  my @target   = qw( pcrtarget sequencetarget cdstarget proteintarget genetarget featuretarget );
#   my @effector = qw( geneone rearrone otheronetype otherone variationone intravariationone );
#   my @effected = qw( genetwo rearrtwo othertwotype othertwo variationtwo intravariationtwo );
#   my @effector = qw( geneone rearrone otheronetype otherone variationone moleculeone );
#   my @effected = qw( genetwo rearrtwo othertwotype othertwo variationtwo moleculetwo );
  my @effector = qw( geneone rearrone otherone variationone moleculeone );
  my @effected = qw( genetwo rearrtwo othertwo variationtwo moleculetwo );
  my @nondir   = qw( pcrnondir sequencenondir cdsnondir proteinnondir genenondir rearrnondir othernondir variationnondir moleculenondir );

  my $checkOne = 0; my $error_data = '';
  my $hasNondir = 0; my $hasBait = 0; my $hasTarget = 0; my $hasOne = 0; my $hasTwo = 0;

  foreach my $bait   (@bait)   { if ( $theHash{$bait}{$joinkey}   ) { $hasBait++; } }
  foreach my $target (@target) { if ( $theHash{$target}{$joinkey} ) { $hasTarget++; } }
  if ( ($hasBait > 0) && ($hasTarget > 0) ) { $checkOne++; }
  foreach my $effector (@effector) { if ( $theHash{$effector}{$joinkey} ) { $hasOne++; } }
  foreach my $effected (@effected) { if ( $theHash{$effected}{$joinkey} ) { $hasTwo++; } }
  if ( ($hasOne > 0) && ($hasTwo > 0) ) { $checkOne++; }
  my %nondir;
  foreach my $nondir (@nondir) { 
    if ( $theHash{$nondir}{$joinkey} ) { 
      my $data = $theHash{$nondir}{$joinkey};
      if ($data =~ m/^\"/) { $data =~ s/^\"//; }
      if ($data =~ m/\"$/) { $data =~ s/\"$//; }
      my @data = split/\",\"/, $data; 
      foreach (@data) { $nondir{$_}++; $hasNondir++; } } }
  if (scalar(keys %nondir) > 1) { $checkOne++; }
  unless ($checkOne) { $error_data .= "$joinkey\tnodump\t$curator\tThere are not two interactors\n"; }

  unless ( ( $theHash{paper}{$joinkey} ) || ( $theHash{person}{$joinkey} ) ) { 
    $error_data .= "$joinkey\tnodump\t$curator\tThere is no reference, neither paper nor person\n"; }

  if ($hasNondir) {
    if ($hasBait)        { $error_data .= "$joinkey\tnodump\t$curator\thas nondiretional + bait\n"; }
    if ($hasTarget)      { $error_data .= "$joinkey\tnodump\t$curator\thas nondiretional + target\n"; }
    if ($hasOne)         { $error_data .= "$joinkey\tnodump\t$curator\thas nondiretional + effector\n"; }
    if ($hasTwo)         { $error_data .= "$joinkey\tnodump\t$curator\thas nondiretional + effected\n"; } }
  if ($hasOne) {
    unless ($hasTwo)     { $error_data .= "$joinkey\tnodump\t$curator\thas effector but no effected\n"; }
    if ($hasBait)        { $error_data .= "$joinkey\tnodump\t$curator\thas effector + bait\n"; }
    if ($hasTarget)      { $error_data .= "$joinkey\tnodump\t$curator\thas effector + target\n"; } }
  if ($hasTwo) {
    if ($hasBait)        { $error_data .= "$joinkey\tnodump\t$curator\thas effected + bait\n"; }
    if ($hasTarget)      { $error_data .= "$joinkey\tnodump\t$curator\thas effected + target\n"; } }
  if ($hasBait) {
    unless ($hasTarget)  { $error_data .= "$joinkey\tnodump\t$curator\thas bait but no target\n"; } }

  if ( $theHash{name}{$joinkey} ) { 
      if ($badMultiline{$theHash{name}{$joinkey}}) { $error_data .= "$joinkey\tnodump\t$curator\t$theHash{name}{$joinkey} exists across multiple lines\n"; } }
    else { $error_data .= "$joinkey\tnodump\t$curator\tThere is no Interaction ID\n"; }


   # no longer dumping based on int_type, this won't do anything
#   if ( $theHash{type}{$joinkey} ) {
#       # these directionality type to data errors go to error output but do not prevent the pgid from going to the .ace file
# #       my @dirtypes = qw( Enhancement Unilateral_enhancement Suppression Unilateral_suppression Epistasis Maximal_epistasis Minimal_epistasis Suppression_epistasis Agonistic_epistasis Antagonistic_epistasis Oversuppression Unilateral_oversuppression Complex_oversuppression Phenotype_bias Biased_suppression Biased_enhancement Complex_phenotype_bias );	# removed several types and added new ones  2013 09 03, only changed code in 2013 10 11
#       my @nondirtypes = qw( Predicted Synthetic Asynthetic Mutual_enhancement Mutual_suppression Complete_mutual_suppression Partial_mutual_suppression Mutual_oversuppression Suppression_enhancement Oversuppression_enhancement No_interaction );
#       my @dirtypes = qw( Enhancement Unilateral_enhancement Suppression Complete_suppression Partial_suppression Unilateral_suppression Complete_unilateral_suppression Partial_unilateral_suppression Epistasis Positive_epistasis Maximal_epistasis Minimal_epistasis Neutral_epistasis Qualitative_epistasis Opposing_epistasis Quantitative_epistasis Oversuppression Unilateral_oversuppression Phenotype_bias );
#       my @ignoredirection = qw( Physical Genetic_interaction Negative_genetic Positive_genetic Neutral_genetic );
#       my %dirTypes;
#       foreach my $nondir (@nondirtypes) { $dirTypes{nondir}{$nondir}++; }
#       foreach my $dir (@dirtypes)       { $dirTypes{dir}{$dir}++; }
# 
#       my $dirTypes = $theHash{type}{$joinkey};
#       if ($dirTypes =~ m/^\"/) { $dirTypes =~ s/^\"//; }
#       if ($dirTypes =~ m/\"$/) { $dirTypes =~ s/\"$//; }
#       my @dirTypes = split/\",\"/, $dirTypes; 
#       my $isNondir = 0; my $isDir = 0;
#       foreach my $dirType (@dirTypes) {
#         if ($dirTypes{nondir}{$dirType}) { $isNondir++; }
#         if ($dirTypes{dir}{$dirType}) { $isDir++; } }
#       if ($isNondir && $isDir) { $err_text .= "$joinkey\tflagonly\t$curator\thas both nondirectional and directional type $dirTypes\n"; } 
#       if ($isNondir) {
#         if ($hasBait)           { $err_text .= "$joinkey\tflagonly\t$curator\thas nondiretional type $dirTypes + bait data\n"; }
#         if ($hasTarget)         { $err_text .= "$joinkey\tflagonly\t$curator\thas nondiretional type $dirTypes + target data\n"; }
#         if ($hasOne)            { $err_text .= "$joinkey\tflagonly\t$curator\thas nondiretional type $dirTypes + effector data\n"; }
#         if ($hasTwo)            { $err_text .= "$joinkey\tflagonly\t$curator\thas nondiretional type $dirTypes + effected data\n"; } }
#       if ($isDir && $hasNondir) { $err_text .= "$joinkey\tflagonly\t$curator\thas diretional type $dirTypes + nondirectional data\n"; } }
#     else { $error_data .= "$joinkey\tnodump\t$curator\tThere is no Interaction Type\n"; }

  if ($error_data) { $err_text .= $error_data; return "nodump"; }	# these errors go to log and prevent dumping of that pgid
    else { return "ok"; }
} # sub checkConstraints

__END__

Checks to make when dumping interactions

1) There are at least two interactors (Otherwise NO DUMP):

  a) There is at least one "Bait" entry and one "Target" entry
OR
  b) There is at least one "Effector" and one "Affected" entry
OR
  c) There is at least two "Non-directional" entries
OR
  d) There is at least one "Intragenic Effector Variation" and at least one "Intragenic Affected Variation" entry


2) There is a reference (Otherwise NO DUMP):

  a) There is a WBPaper ID
OR
  b) There is a Person reference


3) Interactor types are compatible (Otherwise NO DUMP):

  a) If there is a "Non-directional" entry, there are no "Effector", "Affected", "Bait", or "Target" entries
AND
  b) If there is an "Effector" entry, there is at least one "Affected" entry AND there are no "Non-directional", "Bait", or "Target" entries
AND
  c) If there is an "Affected" entry, there is at least one "Effector" entry AND there are no "Non-directional", "Bait", or "Target" entries
AND
  d) If there is a "Bait" entry, there is at least one "Target" entry AND there are no "Non-directional", "Effector", or "Affected" entries
AND
  d) If there is a "Target" entry, there is at least one "Bait" entry AND there are no "Non-directional", "Effector", or "Affected" entries


4) There is an Interaction ID (Otherwise NO DUMP)


5) There is an Interaction Type (Otherwise NO DUMP):



Optional check, for curators (Dump, but print to error output):

6) Check that inherently Non-directional Interaction types are, in fact, Non-directional and inherently Directional Interaction types are, in fact, directional

  a) Non-directional types: Synthetic, Asynthetic, Mutual Suppression, Mutual Enhancement, Mutual oversuppression, Mutual oversuppression/enhancement, No interaction

  b) Directional types: everything else

The above is wrong, this is the correct list :

my @nondirtypes = qw( Predicted Synthetic Asynthetic Mutual_enhancement Mutual_suppression Mutual_oversuppression Suppression_enhancement Oversuppression_enhancement No_interaction );

my @dirtypes = qw( Enhancement Unilateral_enhancement Suppression Unilateral_suppression Epistasis Maximal_epistasis Minimal_epistasis Suppression_epistasis Agonistic_epistasis Antagonistic_epistasis Oversuppression Unilateral_oversuppression Complex_oversuppression Phenotype_bias Biased_suppression Biased_enhancement Complex_phenotype_bias );

my @ignoredirection = qw( Physical Genetic_interaction Negative_genetic );
