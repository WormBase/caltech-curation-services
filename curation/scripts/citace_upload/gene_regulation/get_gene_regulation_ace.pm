package get_gene_regulation_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getGeneRegulation );
our $VERSION	= 1.00;

# dump gene regulation data.  for Xiaodong.  2010 09 13
#
# added more tables  2010 09 20, 2010 09 21
#
# wasn't accounting for othermethod_text existing.  now dumping other_method line insitu, &c.  2010 11 01
#
# fixed subcellloc not being in one set of restrictions and othermethod not being in the second set of restrictions.  looks okay now.  2010 11 04
#
# convert molecule pgids to molecule ids.  2011 03 24
#
# convert lifestage IDs to names. 2011 05 13
#
# split tables in %pipeSplit on <space>|<space> to show in different lines.  2012 03 28
#
# changed for new interaction model.  automatically get mapping of antibody / transgene / variation / exprpattern to WBGenes and dump one line for each ;  or if not found dump as Unaffiliated into .ace and error file.  2012 05 22
#
# molecule WBMolIDs now in mop_name instead of mop_molecule.  2012 10 22
#
# added  Historical_gene  tag for merged genes.  Dead genes only have Historical_gene tag.  For convenience to avoid code to suppress whole object, split genes only have Historical_gene tag and an error message.  2013 05 21
#
# changed gin_dead to not have just "Dead" or "split_into / merged_into", now it has Dead / Suppressed / merged_into / split_into independent of
# each other (all merged / split must be dead though), so Chris has made a precedece for how to treat them (split > merged > suppressed > dead),
# and the dumper makes the Historical_gene comments appropriately.  2013 10 21
#
# Added  grg_cisregulatorfeature  to dump as  Feature_interactor <Feature> Cis_regulator  for Chris.  2013 11 21
#
# Added  grg_cisregulated  to dump as  Interactor_overlapping_gene <Gene> Cis_regulated  for Chris.  2014 04 01
#
# Added  grg_construct  to dump as  Construct <Construct>  for Xiaodong and Karen.  2014 07 08
#
# gene / driven_by_gene / threeutr have moved from transgene trp_ to construct cns_ so removed that checking from transgene and added it to construct.  2014 07 09
# need to dump Transgene as tag with no values as Detection_method for Xiaodong.  
# later in the day Chris said to dump Transgene objects as "Unaffiliated_transgene" instead.  2014 07 10
#
# model change, when variations map to a gene dump as separate tags to gene and variation, instead of single .ace line for both.  2015 03 03
# 
# Historical_gene Remark moved out of #Evidence into just Text.  2015 03 12
#
# Chris wants original gene + interactor info back in .ace file for suppressed and dead genes.  2015 03 16
#
# Chris no longer wants Interactor_overlapping_gene based on the allele, since it's redundant from being dumped from the gene  2015 03 17
#
# replaced grg_allele with grg_transregulatorallele , also added grg_cisregulatorallele .
# Chris no longer needs checking of Variation to gene mappings, always dump all Variations with the cis/trans suffix.  2015 03 19
#
# Bring back transgene mapping to good genes, now from transgene to construct to genes.
# int_otherregulator and int_otherregulated now dump as 'Other_interactor' instead of 'Other_regulator' / 'Other_regulated'.  2015 03 30
#
# chris wants leading  doublequotes dumped  2016 08 13 
#
# dump some text for scl toggles even if no text.  For Chris.  2017 12 13
#
# get rid of othermethod.




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
# my @tables = qw( curator paper name summary antibody antibodyremark reportergene transgene insitu insitu_text northern northern_text western western_text rtpcr rtpcr_text othermethod othermethod_text transregulatorallele rnai type regulationlevel transregulator moleculeregulator transregulatorseq otherregulator transregulated transregulatedseq otherregulated exprpattern nodump result anat_term lifestage subcellloc subcellloc_text remark );
# my @tables = qw( intid curator paper name summary antibody antibodyremark reportergene transgene construct insitu insitu_text northern northern_text western western_text rtpcr rtpcr_text othermethod_text transregulatorallele cisregulatorallele rearrangement rnai type regulationlevel transregulator moleculeregulator transregulatorseq cisregulatorfeature otherregulator transregulated cisregulated transregulatedseq otherregulated exprpattern nodump result pos_anatomy pos_lifestage pos_scl pos_scltext neg_anatomy neg_lifestage neg_scl neg_scltext not_anatomy not_lifestage not_scl not_scltext remark );
my @tables = qw( intid curator paper name summary antibody antibodyremark reportergene transgene construct insitu insitu_text northern northern_text western western_text rtpcr rtpcr_text othermethod_text transregulatorallele cisregulatorallele rearrangement rnai type regulationlevel transregulator moleculeregulator cisregulatorfeature otherregulator transregulated cisregulated otherregulated exprpattern nodump result anatomy lifestage scl scltext remark );

my @maintables = qw( paper summary antibody antibodyremark reportergene transgene construct insitu insitu_text northern northern_text western western_text rtpcr rtpcr_text othermethod_text type regulationlevel transregulatorallele cisregulatorallele rearrangement rnai transregulator moleculeregulator cisregulatorfeature otherregulator transregulated cisregulated otherregulated exprpattern result anatomy lifestage scl scltext remark );


my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;
my %mapToGene;


my %tableToTag;
$tableToTag{summary} = 'Interaction_summary';
$tableToTag{antibody} = 'PLACEHOLDER';					# Antibody
$tableToTag{antibodyremark} = 'Antibody_remark';
$tableToTag{reportergene} = 'Reporter_gene';
# $tableToTag{transgene} = 'PLACEHOLDER';					# Transgene 
$tableToTag{transgene} = 'Unaffiliated_transgene';					# Transgene 
$tableToTag{construct} = 'PLACEHOLDER';					# Construct
$tableToTag{insitu} = 'In_situ';
$tableToTag{northern} = 'Northern';
$tableToTag{western} = 'Western';
$tableToTag{rtpcr} = 'RT_PCR';
# $tableToTag{othermethod} = 'Other_method';
$tableToTag{insitu_text} = 'In_situ';
$tableToTag{northern_text} = 'Northern';
$tableToTag{western_text} = 'Western';
$tableToTag{rtpcr_text} = 'RT_PCR';
$tableToTag{othermethod_text} = 'Other_method';
$tableToTag{transregulatorallele} = 'PLACEHOLDER';					# Variation
$tableToTag{cisregulatorallele} = 'PLACEHOLDER';					# Variation
$tableToTag{rearrangement} = 'Rearrangement';
$tableToTag{exprpattern} = 'PLACEHOLDER';				# Expr
$tableToTag{rnai} = 'Interaction_RNAi';
$tableToTag{transregulator} = 'Interactor_overlapping_gene';		# Trans_regulator
# $tableToTag{transregulatorseq} = 'Sequence_interactor';			# Trans_regulator
$tableToTag{cisregulatorfeature} = 'Feature_interactor';		# Cis_regulator
$tableToTag{moleculeregulator} = 'Molecule_interactor';			# Trans_regulator	(was called Molecule_regulator until 2014 04 28)
# $tableToTag{otherregulator} = 'Other_regulator';			# Trans_regulator
$tableToTag{otherregulator} = 'Other_interactor';			# Trans_regulator
$tableToTag{transregulated} = 'Interactor_overlapping_gene';		# Trans_regulated
$tableToTag{cisregulated} = 'Interactor_overlapping_gene';		# Cis_regulated
# $tableToTag{transregulatedseq} = 'Sequence_interactor';			# Trans_regulated
# $tableToTag{otherregulated} = 'Other_regulated';			# Trans_regulated
$tableToTag{otherregulated} = 'Other_interactor';			# Trans_regulated
# $tableToTag{anat_term} = 'Anatomy_term';
# $tableToTag{lifestage} = 'Life_stage';
# $tableToTag{subcellloc} = 'Subcellular_localization';
# $tableToTag{subcellloc_text} = 'Subcellular_localization';
$tableToTag{type} = 'Regulatory';					# self
$tableToTag{regulationlevel} = 'Regulation_level';			# self
# $tableToTag{result} = 'Regulation_result';				# self
$tableToTag{anatomy} = 'Anatomy_term';
$tableToTag{lifestage} = 'Life_stage';
$tableToTag{scl} = 'Subcellular_localization';
$tableToTag{scltext} = 'Subcellular_localization';
# $tableToTag{pos_anatomy} = 'Positive_regulate Anatomy_term';
# $tableToTag{pos_lifestage} = 'Positive_regulate Life_stage';
# $tableToTag{pos_scl} = 'Positive_regulate Subcellular_localization';
# $tableToTag{pos_scltext} = 'Positive_regulate Subcellular_localization';
# $tableToTag{neg_anatomy} = 'Negative_regulate Anatomy_term';
# $tableToTag{neg_lifestage} = 'Negative_regulate Life_stage';
# $tableToTag{neg_scl} = 'Negative_regulate Subcellular_localization';
# $tableToTag{neg_scltext} = 'Negative_regulate Subcellular_localization';
# $tableToTag{not_anatomy} = 'Does_not_regulate Anatomy_term';
# $tableToTag{not_lifestage} = 'Does_not_regulate Life_stage';
# $tableToTag{not_scl} = 'Does_not_regulate Subcellular_localization';
# $tableToTag{not_scltext} = 'Does_not_regulate Subcellular_localization';
$tableToTag{remark} = 'Remark';
$tableToTag{paper} = 'Paper';

my %pipeSplit;
$pipeSplit{"reportergene"}++;
$pipeSplit{"scltext"}++;
# $pipeSplit{"pos_scltext"}++;
# $pipeSplit{"neg_scltext"}++;
# $pipeSplit{"not_scltext"}++;
$pipeSplit{"otherregulator"}++;
$pipeSplit{"otherregulated"}++;

my %dataType;
$dataType{"rnai"}                           = 'multiontology';
$dataType{"antibody"}                       = 'multiontology';
$dataType{"transgene"}                      = 'multiontology';
$dataType{"construct"}                      = 'multiontology';
$dataType{"transregulatorallele"}           = 'multiontology';
$dataType{"cisregulatorallele"}             = 'multiontology';
$dataType{"rearrangement"}                  = 'multiontology';
$dataType{"exprpattern"}                    = 'multiontology';
$dataType{"type"}                           = 'multidropdown';
$dataType{"regulationlevel"}                = 'multidropdown';
$dataType{"transregulator"}                 = 'multiontology';
$dataType{"moleculeregulator"}              = 'multiontology';
# $dataType{"transregulatorseq"}              = 'multiontology';
$dataType{"cisregulatorfeature"}            = 'multiontology';
$dataType{"transregulated"}                 = 'multiontology';
$dataType{"cisregulated"}                   = 'multiontology';
# $dataType{"transregulatedseq"}              = 'multiontology';
$dataType{"anatomy"}                        = 'multiontology';
$dataType{"lifestage"}                      = 'multiontology';
# $dataType{"pos_anatomy"}                    = 'multiontology';
# $dataType{"pos_lifestage"}                  = 'multiontology';
# $dataType{"neg_anatomy"}                    = 'multiontology';
# $dataType{"neg_lifestage"}                  = 'multiontology';
# $dataType{"not_anatomy"}                    = 'multiontology';
# $dataType{"not_lifestage"}                  = 'multiontology';


my %deadObjects;	 # reading the following
#  $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1];
#  $deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1];
#  $deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1;
#  $deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1;

my %ontologyIdToName;

# my %moleculePgidToMolecule;				# pgid of molecule -> molecule id	not necessary, molecules stored by wbmolid now instead of pgid  2012 10 22
# sub populateMoleculePgidToMolecule {
#   $result = $dbh->prepare( "SELECT * FROM mop_molecule;" );
#   $result->execute();	
#   while (my @row = $result->fetchrow) { $moleculePgidToMolecule{$row[0]} = $row[1]; } }


1;

sub getGeneRegulation {
  my ($flag) = shift;

#   &populateOntIdToName();				# dumps as IDs now
#   &populateMoleculePgidToMolecule();			# not necessary, molecules stored by wbmolid now instead of pgid  2012 10 22
  &populateObjToGene();
  &populateDeadObjects(); 

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM grg_intid; " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM grg_intid WHERE grg_intid = '$flag';" ); }	# get all entries for type of object intid
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM grg_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $objName (sort keys %{ $nameToIDs{object} }) {
    my $entry = ''; my $has_data;
#     $entry .= "\nGene_regulation : \"$objName\"\n";				# interaction objects now, don't use name.  2012 05 22
    $entry .= "\nInteraction : \"$objName\"\n";
    $entry .= "Regulatory\n";

    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$objName} }) {
      next if ($theHash{nodump}{$joinkey});
      my $goodGenes_ref = &getGoodGenes($joinkey);
      my $cur_entry = '';
      foreach my $table (@maintables) {
        next unless ($tableToTag{$table});
        my $tag = $tableToTag{$table};
        $cur_entry = &getData($cur_entry, $table, $joinkey, $tag, $objName, $goodGenes_ref);
      }
      if ($cur_entry) { $entry .= "$cur_entry"; $has_data++; }                  # if .ace object has a phenotype, append to whole list
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$objName} })
    if ($has_data) { $all_entry .= $entry; }
  } # foreach my $objName (sort keys %{ $nameToIDs{$type} })
  return( $all_entry, $err_text );
} # sub getGeneRegulation

sub getData {
  my ($cur_entry, $table, $joinkey, $tag, $objName, $goodGenes_ref) = @_;
  my %goodGenes = %$goodGenes_ref;
  if ( ($table eq 'northern') || ($table eq 'western') || ($table eq 'insitu') || ($table eq 'rtpcr') ) {
    my $subtable = $table . '_text';
    if ($theHash{$subtable}{$joinkey}) { return $cur_entry; } }		# these will be dumped by subtable dump
#   if ( ($table eq 'pos_scl') || ($table eq 'neg_scl') || ($table eq 'not_scl') )
  if ($table eq 'scl') {
    my $subtable = $table . 'text';
    if ($theHash{$subtable}{$joinkey}) { return $cur_entry; } }		# these will be dumped by subtable dump
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
#     if ($data =~ m/^\"/) { $data =~ s/^\"//; }		# chris wants leading  doublequotes dumped  2016 08 13 
#     if ($data =~ m/\"$/) { $data =~ s/\"$//; }
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my @data;
    my $dataType = $dataType{$table} || '';
    if ( ($dataType eq 'multiontology') || ($dataType eq 'multidropdown') ) {
        if ($data =~ m/^\"/) { $data =~ s/^\"//; }	# chris wants leading  doublequotes dumped  2016 08 13
        if ($data =~ m/\"$/) { $data =~ s/\"$//; }	# chris wants leading  doublequotes dumped  2016 08 13
        @data = split/\",\"/, $data; }
      elsif ($pipeSplit{$table}) { @data = split/ \| /, $data; }
      else { push @data, $data; }
#     if ( ($table eq 'othermethod') || ($table eq 'pos_scl') || ($table eq 'neg_scl') || ($table eq 'not_scl') || ($table eq 'northern') || ($table eq 'western') || ($table eq 'insitu') || ($table eq 'rtpcr') ) { @data = (''); }	# just a toggle, no value
#     if ( ($table eq 'pos_scl') || ($table eq 'neg_scl') || ($table eq 'not_scl') ) { @data = ('Subcellular localization'); }		# chris wants specific text for these 2017 12 13
    if ( $table eq 'scl') { @data = ('Subcellular localization'); }		# chris wants specific text for these 2017 12 13
    foreach my $value (@data) {
      if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; }

#       if ($table eq 'moleculeregulator') { if ($moleculePgidToMolecule{$value}) { $value = $moleculePgidToMolecule{$value}; } }	# convert molecule pgids to molecule ids.  2011 03 24	# molecules now stored as wbmolIDs instead of pgids  2012 10 22
#       if ($table eq 'lifestage') { if ($ontologyIdToName{$table}{$value}) { $value = $ontologyIdToName{$table}{$value}; } }	# convert lifestage ids to lifestage names.  2011 05 13	# dump as IDs 2012 05 21

      if ($value) {
          my $geneFound = 0;
          if ($table eq 'antibody') {
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Antibody "$value"\n); } } }
              if ($geneFound) { $cur_entry .= qq(Antibody\n); }
                else {
                  $err_text .= qq($objName\tUnaffiliated_antibody\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_antibody\t"$value"\n); } }
            elsif ($table eq 'construct') {
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Construct "$value"\n); } } }
              if ($geneFound) { $cur_entry .= qq(Construct\n); }
                else {
                  $err_text .= qq($objName\tUnaffiliated_construct\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_construct\t"$value"\n); } }
            elsif ($table eq 'transgene') {                                     # brought back by way of transgene -> construct -> gene  2015 03 30
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Transgene "$value"\n); } } }
              if ($geneFound) { $cur_entry .= qq(Transgene\n); }
                else {
                  $err_text .= qq($objName\tUnaffiliated_transgene\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_transgene\t"$value"\n); } }
#             elsif ($table eq 'transgene') { $cur_entry .= qq(Transgene\n); }	# just a tag, no value, for Xiaodong 2014 07 10 removed later same day for Chris and changed to Unaffiliated_transgene
#             elsif ($table eq 'transgene') {
#               if ($mapToGene{$table}{$value}) {
#                   foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
#                     if ($goodGenes{$gene}) {
#                       $geneFound++;
#                       $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Transgene "$value"\n); } } }
#               if ($geneFound) { $cur_entry .= qq(Transgene\n); }
#                 else {
#                   $err_text .= qq($objName\tUnaffiliated_transgene\t"$value"\n);
#                   $cur_entry .= qq(Unaffiliated_transgene\t"$value"\n); } }
            elsif ($table eq 'exprpattern') {
              if ($mapToGene{$table}{$value}) {
                  foreach my $gene (sort keys %{ $mapToGene{$table}{$value} }) {
                    if ($goodGenes{$gene}) {
                      $geneFound++;
                      $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Expr_pattern "$value"\n); } } }
              if ($geneFound) { 1; }
                else {
                  $err_text .= qq($objName\tUnaffiliated_expr_pattern\t"$value"\n);
                  $cur_entry .= qq(Unaffiliated_expr_pattern\t"$value"\n); } }
            elsif ( ($table eq 'transregulatorallele') || ($table eq 'cisregulatorallele') ) {
#               if ($mapToGene{allele}{$value}) {					# Chris no longer needs gene mappings, always dump the .ace tag 2015 03 19
#                   foreach my $gene (sort keys %{ $mapToGene{allele}{$value} }) {
#                     if ($goodGenes{$gene}) {
#                       $geneFound++;
# #                       $cur_entry .= qq(Interactor_overlapping_gene\t"$gene" Variation "$value"\n);	# old model replaced 2015 03 03
# #                       $cur_entry .= qq(Interactor_overlapping_gene\t"$gene"\n);	# Chris no longer wants it since it's being dumped from the gene  2015 03 17
#                       $cur_entry .= qq(Variation_interactor "$value" $suffix\n); } } }
#               if ($geneFound) { 1; }
#                 else {
# #                   $cur_entry .= qq(Unaffiliated_variation\t"$value"\n);		# Chris no longer wants this  2015 03 19
#                   $err_text .= qq($objName\tUnaffiliated_variation\t"$value"\n); } 
              my $suffix = 'Trans_regulator'; if ($table eq 'cisregulatorallele') { $suffix = 'Cis_regulator'; }
              $cur_entry .= qq(Variation_interactor "$value" $suffix\n); }
            elsif ($table eq 'paper') {
              if ($deadObjects{paper}{$value}) {
                  $err_text .= qq($objName\tInvalid Paper\t"$value"\t$deadObjects{paper}{$value}\n); }
                else {
                  $cur_entry .= "$tag\t\"$value\"\n"; } }
            elsif ( ($table eq 'northern') || ($table eq 'western') || ($table eq 'insitu') || ($table eq 'rtpcr') ) { 
                  $cur_entry .= "$tag\n"; }
            elsif ( ($table eq 'cisregulated') || ($table eq 'transregulated') || ($table eq 'transregulator') ) {
              my $main_line = qq($tag\t"$value");
#               if ($deadObjects{gene}{$value}) {
#                   $err_text .= qq($objName\tInvalid Gene\t"$value"\t$deadObjects{gene}{$value}\n); }
#                 else {
#                   $cur_entry .= "$tag\t\"$value\""; 
#                   if ( ($table eq 'transregulator') ) { $cur_entry .= " Trans_regulator"; }
#                   if ( ($table eq 'transregulated') ) { $cur_entry .= " Trans_regulated"; }
#                   $cur_entry .= "\n"; }
              if ($deadObjects{gene}{"mapto"}{$value}) {       # if gene maps to another gene, add the mapped version
#                   $cur_entry .= qq(Historical_gene  "$value"  Remark  "Note: This object originally referred to $value.  $value is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$value}. $deadObjects{gene}{"mapto"}{$value} has replaced $value accordingly."\n);
                  $cur_entry .= qq(Historical_gene  "$value"  "Note: This object originally referred to $value.  $value is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$value}. $deadObjects{gene}{"mapto"}{$value} has replaced $value accordingly."\n);
                  my $mappedGene = $deadObjects{gene}{"mapto"}{$value};        # convert to new gene
                  $main_line = qq($tag\t"$mappedGene");
#                   if ( ($table eq 'transregulator') ) { $cur_entry .= qq($tag\t"$mappedGene" Trans_regulator\n); }
#                   if ( ($table eq 'transregulated') ) { $cur_entry .= qq($tag\t"$mappedGene" Trans_regulated\n); }
#                   if ( ($table eq 'cisregulated')   ) { $cur_entry .= qq($tag\t"$mappedGene" Cis_regulated\n); }
                  $cur_entry .= qq($tag\t"$mappedGene" Inferred_automatically\n); }
                elsif ($deadObjects{gene}{"dead"}{$value}) {
#                   $cur_entry .= qq(Historical_gene\t"$value" Remark  "Note: This object originally referred to a gene ($value) that is now considered dead. Please interpret with discretion."\n);
                  $cur_entry .= qq(Historical_gene\t"$value" "Note: This object originally referred to a gene ($value) that is now considered dead. Please interpret with discretion."\n); }
                elsif ($deadObjects{gene}{"suppressed"}{$value}) {
#                   $cur_entry .= qq(Historical_gene\t"$value" Remark  "Note: This object originally referred to a gene ($value) that has been suppressed. Please interpret with discretion."\n);
                  $cur_entry .= qq(Historical_gene\t"$value" "Note: This object originally referred to a gene ($value) that has been suppressed. Please interpret with discretion."\n); }
                elsif ($deadObjects{gene}{"split"}{$value}) {  # anything with a split gene is an error
#                   $cur_entry .= qq(Historical_gene\t"$value" Remark  "Note: This object originally referred to a gene ($value) that is now considered dead. Please interpret with discretion."\n);
                  $cur_entry .= qq(Historical_gene\t"$value" "Note: This object originally referred to a gene ($value) that is now considered split. Please interpret with discretion."\n);
                  $err_text .= "$joinkey\tnodump\tThis pgid contains a gene that has been split $value in $table.\n"; }
              if ( ($table eq 'transregulator') ) { $main_line .= " Trans_regulator"; }
              if ( ($table eq 'transregulated') ) { $main_line .= " Trans_regulated"; }
              if ( ($table eq 'cisregulated')   ) { $main_line .= " Cis_regulated";   }
              $cur_entry .= "$main_line\n"; }
            elsif ( ($table eq 'anatomy') || ($table eq 'lifestage') || ($table eq 'scl') || ($table eq 'scltext') ) {
              if ( $theHash{'result'}{$joinkey} ) {
                  $cur_entry .= "$theHash{'result'}{$joinkey}\t$tag\t\"$value\"\n"; }
                else { 
                  $err_text .= qq($objName\t$table has no corresponding Regulation_result in pgid $joinkey\n); } }
            else {									# regular values
              $cur_entry .= "$tag\t\"$value\""; 
#               if ( ($table eq 'transregulatorseq') || ($table eq 'moleculeregulator') || ($table eq 'otherregulator') ) { $cur_entry .= " Trans_regulator"; }
#               if ( ($table eq 'transregulatedseq') || ($table eq 'otherregulated') ) { $cur_entry .= " Trans_regulated"; }
              if ( ($table eq 'moleculeregulator') || ($table eq 'otherregulator') ) { $cur_entry .= " Trans_regulator"; }
              if ( $table eq 'otherregulated' ) { $cur_entry .= " Trans_regulated"; }
              if ( ($table eq 'cisregulatorfeature') ) { $cur_entry .= " Cis_regulator"; }
              $cur_entry .= "\n"; }
        }
#         else { $cur_entry .= "$tag\n"; }			# no value, just print tag.  why were we ever doing this, it seems wrong.  2012 05 22
    } # foreach my $value (@data)
  }
  return $cur_entry;
} # sub getData

sub getGoodGenes {
  my $joinkey = shift;
  my %goodGenes;
  if ($theHash{'transregulator'}{$joinkey}) {
    my $transregulator = $theHash{'transregulator'}{$joinkey};
    if ($transregulator =~ m/^\"/) { $transregulator =~ s/^\"//; }
    if ($transregulator =~ m/\"$/) { $transregulator =~ s/\"$//; }
    my @transregulator = split/\",\"/, $transregulator;
#     foreach (@transregulator) { $goodGenes{$_}++; }
    foreach my $gene (@transregulator) { 
      if ($deadObjects{gene}{"mapto"}{"$gene"}) {             # if gene maps to another gene, add the mapped version
        $gene = $deadObjects{gene}{"mapto"}{"$gene"}; }
      $goodGenes{$gene}++; } }
  if ($theHash{'transregulated'}{$joinkey}) {
    my $transregulated = $theHash{'transregulated'}{$joinkey};
    if ($transregulated =~ m/^\"/) { $transregulated =~ s/^\"//; }
    if ($transregulated =~ m/\"$/) { $transregulated =~ s/\"$//; }
    my @transregulated = split/\",\"/, $transregulated;
#     foreach (@transregulated) { $goodGenes{$_}++; }
    foreach my $gene (@transregulated) { 
      if ($deadObjects{gene}{"mapto"}{"$gene"}) {             # if gene maps to another gene, add the mapped version
        $gene = $deadObjects{gene}{"mapto"}{"$gene"}; }
      $goodGenes{$gene}++; } }
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
#   foreach my $gene (@genes) { $mapToGene{antibody}{$antibody}{$gene}++; }
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
#   foreach my $gene (@genes) { $mapToGene{exprpattern}{$exprpattern}{$gene}++; }
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
# #   foreach my $gene (@genes) { $mapToGene{transgene}{$transgene}{$gene}++; }
#   foreach my $gene (@genes) {
#     if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
# #   foreach my $gene (@genes) { $mapToGene{transgene}{$transgene}{$gene}++; }
#   foreach my $gene (@genes) {
#     if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
# #   foreach my $gene (@genes) { $mapToGene{transgene}{$transgene}{$gene}++; }
#   foreach my $gene (@genes) {
#     if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
#   foreach my $gene (@genes) { $mapToGene{construct}{$construct}{$gene}++; }
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
#   foreach my $gene (@genes) { $mapToGene{construct}{$construct}{$gene}++; }
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
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
#   foreach my $gene (@genes) { $mapToGene{construct}{$construct}{$gene}++; }
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{construct}{$construct}{$gene}++; } }

$result = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE obo_data_variation ~ 'WBGene';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my ($name) = $row[1] =~ m/name: \"(.*?)\"/;
  my (@genes) = $row[1] =~ m/(WBGene\d+)/g;
  my $varId = $row[0];
#   foreach my $gene (@genes) { $mapToGene{allele}{$varId}{$gene}++; $mapToGene{allele}{$name}{$gene}++; }
  foreach my $gene (@genes) {
    if ($deadObjects{gene}{"mapto"}{$gene}) {   # if gene maps to another gene, add the mapped version
      $gene = $deadObjects{gene}{"mapto"}{$gene}; }
    $mapToGene{allele}{$varId}{$gene}++; $mapToGene{allele}{$name}{$gene}++; } }

  # transgenes map to genes via constructs.  2015 03 30
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
  while (my @row = $result->fetchrow) { $deadObjects{paper}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {			# Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
    if ($row[1] =~ m/split_into (WBGene\d+)/) {		$deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) {	$deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {		$deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {			$deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
#   while (my @row = $result->fetchrow) {		# previously gin_dead only had "Dead" or "merged_into / split_into", now it can have all 3 plus Suppressed, so redoing it based on priorities set by Chris
#   while (my @row = $result->fetchrow) {
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


# Deprecated, lifestages now dump as IDs
# sub populateOntIdToName {
#   $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage;" ); $result->execute();	
#   while (my @row = $result->fetchrow) { $ontologyIdToName{'lifestage'}{$row[0]} = $row[1]; }
# } # sub populateOntIdToName
