package get_dis_disease_ace_annotation;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getDiseaseAnnotation );
our $VERSION	= 1.00;

# new dumper of disease data in a different format for Ranjana.  2017 04 14
#
# added interactvariation interacttransgene interactgene rnaiexperiment  2017 06 13
#
# added qualifer and modqualifier  2017 08 23
#
# added corresponding text tables for wbgene + strain + transgene + variation  2017 11 17
#
# added dis_modelremark for Ranjana.  2018 03 06
#
# doid ontology has obsolete terms, put those in deadObjects for validation.  2018 08 29
#
# added a bunch of error messages if some fields don't have data for a pgid.  2018 09 07
#
# dump object IDs as WBDOannot<paddedPGID>.  2019 06 28
#
# added more tags, if genotype has data, skip some tables from dumping.  2020 05 18
#
# organize  doterm_associations  by doterm instead of by pgid.  2020 05 19
#
# changed inferredgene to assertedgene. 
# added assertedvariation.
# don't dump wbgene if there's variation data  2022 08 15
#
# no longer need checking that wbgene|variation require an inferredgene
# before needed wbgene|variation|strain|transgene, now can also be genotype.  2023 03 06
#
# for dot_entry only, treat dis_assertedgene as if it were a dis_wbgene.  2023 03 27
#
# add dis_assertedhumangene dumping for Ranjana.  2023 07 05
#
# add .ace output for modgenotype Modifier_genotype for Ranjana and Stavros.  2024 11 06




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
# my @tables = qw( wbgene curator humandoid paperexpmod dbexpmod lastupdateexpmod species diseaserelevance paperdisrel dbdisrel genedisrel lastupdatedisrel );
my @tables = qw( humandoid species strain straintext variation variationtext transgene transgenetext genotype wbgene wbgenetext interactvariation interacttransgene interactgene rnaiexperiment modelremark assertedgene assertedvariation assertedhumangene associationtype goinference eco qualifier inducingchemical inducingagent modtransgene modvariation modstrain modhumangene modgene modgenotype modmolecule modother moleculetype modqualifier geneticsex phenotypedisease phenotypeameliorated phenotypeexacerbated commentdisphen paperexpmod diseasemodeldesc genedisrel dbexpmod curator lastupdateexpmod );


my %tableToTag;
$tableToTag{"humandoid"}              = "Disease_term";
$tableToTag{"species"}                = "Disease_of_species";
$tableToTag{"strain"}                 = "Strain";
$tableToTag{"variation"}              = "Variation";
$tableToTag{"transgene"}              = "Transgene";
$tableToTag{"genotype"}               = "Genotype";
$tableToTag{"wbgene"}                 = "Disease_relevant_gene";
$tableToTag{"interactvariation"}      = "Interacting_variation";
$tableToTag{"interacttransgene"}      = "Interacting_transgene";
$tableToTag{"interactgene"}           = "Interacting_gene";
$tableToTag{"rnaiexperiment"}         = "RNAi_experiment";
$tableToTag{"modelremark"}            = "Modeled_by_remark";
$tableToTag{"assertedgene"}           = "Asserted_gene";
$tableToTag{"assertedvariation"}      = "Asserted_variation";
$tableToTag{"assertedhumangene"}      = "Asserted_human_gene";
$tableToTag{"associationtype"}        = "Association_type";
$tableToTag{"goinference"}            = "GO_code";
$tableToTag{"eco"}                    = "ECO_term";
$tableToTag{"qualifier"}              = "SELF";
$tableToTag{"inducingchemical"}       = "Inducing_chemical";
$tableToTag{"inducingagent"}          = "Inducing_agent";
$tableToTag{"modgenotype"}            = "Modifier_genotype";
$tableToTag{"modtransgene"}           = "Modifier_transgene";
$tableToTag{"modvariation"}           = "Modifier_variation";
$tableToTag{"modstrain"}              = "Modifier_strain";
$tableToTag{"modhumangene"}           = "Modifier_gene";
$tableToTag{"modgene"}                = "Modifier_gene";
$tableToTag{"modmolecule"}            = "Modifier_molecule";
$tableToTag{"modother"}               = "Other_modifier";
$tableToTag{"moleculetype"}           = "Modifier_association_type";
$tableToTag{"modqualifier"}           = "SELF";
$tableToTag{"geneticsex"}             = "Genetic_sex";
$tableToTag{"phenotypedisease"}       = "Disease_phenotype";
$tableToTag{"phenotypeameliorated"}   = "Ameliorated_phenotype";
$tableToTag{"phenotypeexacerbated"}   = "Exacerbated_phenotype";
$tableToTag{"commentdisphen"}         = "Phenotype_comment";
$tableToTag{"paperexpmod"}            = "Paper_evidence";
$tableToTag{"diseasemodeldesc"}       = "Disease_model_description";
$tableToTag{"genedisrel"}             = 'Database "OMIM" "gene"';
$tableToTag{"dbexpmod"}               = 'Database "OMIM" "disease"';
$tableToTag{"curator"}                = "Curator_confirmed";
$tableToTag{"lastupdateexpmod"}       = "Date_last_updated";

my %tableHasText;
$tableHasText{"wbgene"}               = "wbgenetext";
$tableHasText{"strain"}               = "straintext";
$tableHasText{"variation"}            = "variationtext";
$tableHasText{"transgene"}            = "transgenetext";

my %extraTableToTag;
$extraTableToTag{"wbgene"}                 = "Gene_by_biology";
$extraTableToTag{"assertedgene"}           = "Gene_by_biology";
$extraTableToTag{"strain"}                 = "Disease_model_strain";
$extraTableToTag{"variation"}              = "Disease_model_variation";
$extraTableToTag{"transgene"}              = "Disease_model_transgene";
$extraTableToTag{"genotype"}               = "Disease_model_genotype";
$extraTableToTag{"modtransgene"}           = "Disease_modifier_transgene";
$extraTableToTag{"modvariation"}           = "Disease_modifier_variation";
$extraTableToTag{"modstrain"}              = "Disease_modifier_strain";
$extraTableToTag{"modgene"}                = "Disease_modifier_gene";
$extraTableToTag{"modgenotype"}            = "Disease_modifier_genotype";
$extraTableToTag{"inducingchemical"}       = "Chemical_inducer";
$extraTableToTag{"inducingagent"}          = "Other_inducer";
$extraTableToTag{"modmolecule"}            = "Molecule_modifier";


my %skipTableHasGenotype;
$skipTableHasGenotype{wbgene}++;
$skipTableHasGenotype{variation}++;
$skipTableHasGenotype{strain}++;
$skipTableHasGenotype{transgene}++;
$skipTableHasGenotype{interactgene}++;
$skipTableHasGenotype{interactvariation}++;
$skipTableHasGenotype{interacttransgene}++;


my $all_entry = '';
my $all_dot_entry = '';			# doterm_associations
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;

my %deadObjects;
# my %validObjects;


my %dataType;
$dataType{humandoid}   = 'multi';
$dataType{paperexpmod} = 'multi';
$dataType{paperdisrel} = 'multi';
$dataType{dbexpmod}    = 'comma';
$dataType{dbdisrel}    = 'comma';




1;

sub populateDeadAndValidObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{invalid}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {                 # Ranjana doesn't care about hierarchy, just show her an error message
    if ($row[1]) { $deadObjects{gene}{"WBGene$row[0]"} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM obo_data_humando WHERE obo_data_humando ~ 'is_obsolete: true';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{humando}{"$row[0]"}++; }
} # sub populateDeadAndValidObjects

sub getDiseaseAnnotation {
  my ($flag) = shift;
  my $counter = 0;

  &populateDeadAndValidObjects();

  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM dis_$table;" );		
    $result->execute();	
    while (my @row = $result->fetchrow) { 
      my $data = $row[1];
      $data =~ s/\n/ /g;
      if ($table eq 'lastupdateexpmod') { 
        if ($data =~ m/^(\d{4}\-\d{2}\-\d{2})/) { $data = $1; } }
      $theHash{$table}{$row[0]} = $data; 
      $theHash{'any'}{$row[0]}++; 
    }
  } # foreach my $table (@tables)

  my %dotEntry;
  my @needsData = qw( associationtype curator humandoid species goinference eco paperexpmod lastupdateexpmod );
  foreach my $pgid (sort {$a<=>$b} keys %{ $theHash{'any'} }) {
#     next unless ( ($theHash{'strain'}{$pgid})		# removed this restriction 2017 08 23
#                || ($theHash{'variation'}{$pgid})
#                || ($theHash{'transgene'}{$pgid}) );
    unless ($theHash{humandoid}{$pgid})	{	# skip from even checking other types if no doid, to avoid error messages 2019 11 05
      $err_text .= "pgid $pgid has no humandoid\n"; next; }
    foreach my $typeNeedsData (@needsData) {
      unless ($theHash{$typeNeedsData}{$pgid}) { $err_text .= "pgid $pgid has no $typeNeedsData\n"; } }
    unless ( ($theHash{wbgene}{$pgid}) || ($theHash{variation}{$pgid}) ||
             ($theHash{strain}{$pgid}) || ($theHash{transgene}{$pgid}) ||
             ($theHash{genotype}{$pgid}) ) {
		 $err_text .= "pgid $pgid has no wbgene nor variation nor strain nor transgene\n"; }
# Ranjana doesn't want this check.  2018 11 06
#     if ( ( ($theHash{variation}{$pgid}) || ($theHash{transgene}{$pgid}) ) &&
#          !($theHash{wbgene}{$pgid}) ) { 
# 		 $err_text .= "pgid $pgid has variation or transgene but no wbgene\n"; }
# Ranjana and Chris G don't want this check.  2023 03 06
#     if ( ( ($theHash{wbgene}{$pgid}) || ($theHash{variation}{$pgid}) ) &&
#          !($theHash{inferredgene}{$pgid}) ) { 
# 		 $err_text .= "pgid $pgid has wbgene or variation but no inferredgene\n"; }
    if ( ( ($theHash{modtransgene}{$pgid}) || ($theHash{modvariation}{$pgid}) || ($theHash{modstrain}{$pgid}) || 
           ($theHash{modgene}{$pgid}) || ($theHash{modmolecule}{$pgid}) || ($theHash{modother}{$pgid}) ) &&
         !($theHash{moleculetype}{$pgid}) ) { 
		 $err_text .= "pgid $pgid has modtransgene or modvariation or modstrain or modgene or modmolecule or modother but no moleculetype\n"; }
    next unless ($theHash{'associationtype'}{$pgid});	# replaced below restriction 2017 08 23	# removed 2018 09 12 # put back 2018 09 17

#     $counter++;
#     my ($objectId) = &pad8Zeros($counter);
    my ($objectId) = &pad8Zeros($pgid);
    my $entry .= "\nDisease_model_annotation : \"WBDOannot$objectId\"\n";
    foreach my $table (@tables) {
      next unless ($tableToTag{$table});
      next if ($theHash{genotype}{$pgid} && $skipTableHasGenotype{$table});
      if ($table eq 'wbgene') {				# don't dump wbgene if there's variation data  2022 08 15
        next if ($theHash{variation}{$pgid}) }

      my @data;
      my $data = $theHash{$table}{$pgid};
      next unless $data;
      if ($data =~ m/^\"/) { $data =~ s/^\"//; }
      if ($data =~ m/\"$/) { $data =~ s/\"$//; }
      if ($data =~ m/\",\"/) { 
          @data = split/\",\"/, $data; }
        else { push @data, $data; }
      foreach my $data (@data) {
        if ($data) {
          if ($tableHasText{$table}) { 			# some tables have text associated, dump them with text
            if ($theHash{$tableHasText{$table}}{$pgid}) { $data .= qq(" "$theHash{$tableHasText{$table}}{$pgid}); } }
          if ($tableToTag{$table} eq 'SELF') { 
              $entry .= qq($data\n); }
            else {
              $entry .= qq($tableToTag{$table}\t"$data"\n); }
        } # if ($data)
      } # foreach my $data (@data)
    } # foreach my $table (@tables)

    
    my @extraTables = qw( wbgene assertedgene strain variation transgene genotype modtransgene modvariation modstrain modgene modgenotype inducingchemical inducingagent modmolecule );
    my $dot_entry = '';
    if ($theHash{"humandoid"}{$pgid}) {
      if ($theHash{"humandoid"}{$pgid} =~ m/\"/) { $theHash{"humandoid"}{$pgid} =~ s/\"//g; }
      if ($deadObjects{humando}{$theHash{'humandoid'}{$pgid}}) { $err_text .= "pgid $pgid has invalid DOID $theHash{'humandoid'}{$pgid}\n"; }
      foreach my $table (@extraTables) {
        next if ($theHash{genotype}{$pgid} && $skipTableHasGenotype{$table});
        my @data;
        my $data = $theHash{$table}{$pgid};
        next unless $data;
        if ($data =~ m/^\"/) { $data =~ s/^\"//; }
        if ($data =~ m/\"$/) { $data =~ s/\"$//; }
        if ($data =~ m/\",\"/) { 
            @data = split/\",\"/, $data; }
          else { push @data, $data; }
        foreach my $data (@data) {
          if ($data) {
            $dot_entry .= qq($extraTableToTag{$table}\t"$data"\n);
          } # if ($data)
        } # foreach my $data (@data)
      } # foreach my $table (@extraTables)
      if ($dot_entry) { 
        my $doterm = $theHash{'humandoid'}{$pgid};
        $dotEntry{$doterm} .= $dot_entry;
#         $dot_entry = qq(\nDO_term : "$theHash{'humandoid'}{$pgid}"\n$dot_entry); 
      }
    } # if ($theHash{"humandoid"}{$pgid})

    $all_entry .= $entry;

#     $all_dot_entry .= $dot_entry;

  } # foreach my $pgid (sort {$a<=>$b} keys %{ $theHash{'any'} })

  foreach my $doterm (sort keys %dotEntry) {
    $all_dot_entry .= qq(\nDO_term : $doterm\n$dotEntry{$doterm});
  } # foreach my $doterm (sort keys %dotEntry)



#   if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM dis_wbgene; " ); }		# get all entries for all wbgenes
#     else { $result = $dbh->prepare( "SELECT * FROM dis_wbgene WHERE dis_wbgene = '$flag';" ); }	# get all entries for all wbgenes with object name $flag
#   $result->execute();	
#   while (my @row = $result->fetchrow) {
#     if ($deadObjects{gene}{$row[1]}) { $err_text .= "pgid $row[0] has $row[1] which is $deadObjects{gene}{$row[1]}\n"; }	# add dead wbgenes to error out
#       else { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; } }		# add non-dead genes to hashes
#   my $ids = ''; my $qualifier = '';
#   if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
#   foreach my $table (@tables) {
#     $result = $dbh->prepare( "SELECT * FROM dis_$table $qualifier;" );		# get data for table with qualifier (or not if not)
#     $result->execute();	
#     while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
#   } # foreach my $table (@tables)
# 
#   foreach my $objName (sort keys %{ $nameToIDs{object} }) {
#     my $entry = ''; my $has_data;
#     $entry .= "\nGene : \"$objName\"\n";
# 
#     foreach my $pgid (sort {$a<=>$b} keys %{ $nameToIDs{object}{$objName} }) {
#       my $species = ''; if ($theHash{species}{$pgid}) { $species = $theHash{species}{$pgid}; }
#       my %omim = (); my %omimGene;
#       if ($theHash{humandoid}{$pgid}) {
#         my (@doids) = $theHash{humandoid}{$pgid} =~ m/(DOID:\d+)/g;
#         my @papers; my @all_papers;
#         if ($theHash{paperexpmod}{$pgid}) { (@all_papers) = $theHash{paperexpmod}{$pgid} =~ m/(WBPaper\d+)/g; }
#         foreach my $paper (@all_papers) { 			# get all papers and send error message for invalid papers, and add valid to list of papers
#           if ($deadObjects{paper}{invalid}{$paper}) { $err_text .= "pgid $pgid has invalid paper $paper\n"; }
#             else { push @papers, $paper; } }
#         if ($theHash{dbexpmod}{$pgid}) { my (@om) = $theHash{dbexpmod}{$pgid} =~ m/(\d+)/g; foreach (@om) { $omim{$_}++; } }	# Ranjana doesn't want to enter OMIM: each time, so match any group of digits to be an omim value 2013 05 15
#         foreach my $doid (@doids) {
#           unless ($validObjects{humando}{$doid}) { $err_text .= "pgid $pgid has invalid DOID $doid\n"; }
#           foreach my $omim (sort keys %omim) { $entry .= qq(Experimental_model\t"$doid"\t"$species"\tAccession_evidence\t"OMIM"\t"$omim"\n); }	# added to dump for each doid for Ranjana 2014 09 15
#           if (scalar @papers > 0) { foreach my $paper (@papers) { $entry .= qq(Experimental_model\t"$doid"\t"$species"\tPaper_evidence\t"$paper"\n); } }
#             else { $entry .= qq(Experimental_model\t"$doid"\t"$species"\n); }
#           if ($theHash{curator}{$pgid}) { $entry .= qq(Experimental_model\t"$doid"\t"$species"\tCurator_confirmed\t"$theHash{curator}{$pgid}"\n); }
#           if ($theHash{lastupdateexpmod}{$pgid}) { if ($theHash{lastupdateexpmod}{$pgid} =~ m/(\d{4}.\d{2}.\d{2})/) { 
#             # if there's a date last updated for exp mod, match the year month day and add to Date_last_updated
#             $entry .= qq(Experimental_model\t"$doid"\t"$species"\tDate_last_updated\t"$1"\n); } } }
#       }
#       if ($theHash{diseaserelevance}{$pgid}) {
#         my $disrel = $theHash{diseaserelevance}{$pgid}; if ($disrel =~ m/\'/) { $disrel =~ s/\'/''/g; } if ($disrel =~ m/\n/) { $disrel =~ s/\n/ /g; }
#         my @papers; my @all_papers;
#         if ($theHash{paperdisrel}{$pgid}) { (@all_papers) = $theHash{paperdisrel}{$pgid} =~ m/(WBPaper\d+)/g; }
#         foreach my $paper (@all_papers) { 			# get all papers and send error message for invalid papers, and add valid to list of papers
#           if ($deadObjects{paper}{invalid}{$paper}) { $err_text .= "pgid $pgid has invalid paper $paper\n"; }
#             else { push @papers, $paper; } }
#         if (scalar @papers > 0) { foreach my $paper (@papers) { $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tPaper_evidence\t"$paper"\n); } }
#           else { $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\n); }
#         if ($theHash{curator}{$pgid}) { $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tCurator_confirmed\t"$theHash{curator}{$pgid}"\n); }
#         if ($theHash{lastupdatedisrel}{$pgid}) { if ($theHash{lastupdatedisrel}{$pgid} =~ m/(\d{4}.\d{2}.\d{2})/) { 
#           # if there's a date last updated for dis rel, match the year month day and add to Date_last_updated
#           $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tDate_last_updated\t"$1"\n); } }
#         if ($theHash{dbdisrel}{$pgid}) { 
#           my (@om) = $theHash{dbdisrel}{$pgid} =~ m/(\d+)/g;
#             foreach my $omim (@om) { 
#               $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tAccession_evidence\t"OMIM"\t"$omim"\n);	# ranjana wants to dump omim accession evidence 2014 09 22
#               $omim{$omim}++; } }	# Ranjana doesn't want to enter OMIM: each time, so match any group of digits to be an omim value 2013 05 15   
#         if ($theHash{genedisrel}{$pgid}) { 
#           my (@om) = $theHash{genedisrel}{$pgid} =~ m/(\d+)/g;
#             foreach my $omim (@om) {
#               $entry .= qq(Disease_relevance\t"$disrel"\t"$species"\tAccession_evidence\t"OMIM"\t"$omim"\n);	# ranjana wants to dump omim accession evidence 2014 09 22
#               $omimGene{$omim}++; } }	# Ranjana doesn't want to enter OMIM: each time, so match any group of digits to be an omim value 2013 05 15
#       }
#       foreach my $omim (sort keys %omim) { $entry .= qq(Database\t"OMIM"\t"disease"\t"$omim"\n); }		
#       foreach my $omimGene (sort keys %omimGene) { $entry .= qq(Database\t"OMIM"\t"gene"\t"$omimGene"\n); }	
#       if ($entry) { $has_data++; }
#     } # foreach my $pgid (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$objName} })
#     if ($has_data) { $all_entry .= $entry; }
#   } # foreach my $objName (sort keys %{ $nameToIDs{$type} })

  return( $all_entry, $all_dot_entry, $err_text );
} # sub getDiseaseAnnotation

sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros


__END__

sub getData {
  my ($cur_entry, $table, $joinkey, $tag, $objName, $goodGenes_ref) = @_;
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
    if ($data =~ m/^\"/) { $data =~ s/^\"//; }
    if ($data =~ m/\"$/) { $data =~ s/\"$//; }
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my @data;
    if ($data =~ m/\",\"/) { @data = split/\",\"/, $data; }
      elsif ($pipeSplit{$table}) { @data = split/ \| /, $data; }
      else { push @data, $data; }
    foreach my $value (@data) {
      if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; }
    } # foreach my $value (@data)
  }
  return $cur_entry;
} # sub getData

