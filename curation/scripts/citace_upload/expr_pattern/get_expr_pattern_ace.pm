package get_expr_pattern_ace;
require Exporter;


our @ISA	= qw(Exporter);
our @EXPORT	= qw( getExprPattern );
our $VERSION	= 1.00;

# dump gene regulation data.  for Xiaodong.  2010 09 13
#
# convert lifestage IDs to names. 2011 05 13
#
# modified for expression pattern data.  for Daniela.  2011 05 27
#
# added Historical_gene stuff.  2013 05 30
#
# changed gin_dead to not have just "Dead" or "split_into / merged_into", now it has Dead / Suppressed / merged_into / split_into independent of
# each other (all merged / split must be dead though), so Chris has made a precedece for how to treat them (split > merged > suppressed > dead),
# and the dumper makes the Historical_gene comments appropriately.  2013 10 21
#
# if endogenous toggle, also dump gene to endogenous .ace tag.  for Daniela.  2014 03 19
#
# added transgene and variation fields, but Daniela hasn't said how they should dump, so may be wrong.  2014 07 08
#
# added exp_seqfeature to dump as Associated_feature for Daniela.  2014 09 25
#
# added dumping of species for Daniela.  2014 12 03
#
# qualifierls and anatomy always dump as cross product of their terms to each other as Anatomy Life_stage and Life_stage Anatomy.  
# some micropub data will have qualifierls without anatomy, so if there's a qualifierls without anatomy, dump as Life_stage.  2015 02 04
#
# Historical_gene Remark moved out of #Evidence into just Text.  2015 03 12
#
# Added possibility of qualifier being 'NOT' which requires changing the dumping .ace tag, but also needs to allow for an anatomy term
# and lifestages, which should be in the same .ace line.  2015 07 01
#
# Getting obsolete anatomy terms into %deadObjects to prevent dumping them and showing them in err.out.<date>
# for Daniela and Raymond.  2015 10 05
#
# Moved gin_protein data to gin_proteindesc, using gin_protein for new Protein field dumping multi ontology objects from gin_protein
# for Daniela.  2017 10 23
#
# Split qualifier + qualifiertext into separate lines putting the qualifiertext in remark.  2017 11 08
#
# Dump exp_species based on values from pap_species_index  2021 02 21
#
# Added exp_person dump.  2021 03 31
#
# Changed for utf8 changes in postgres.  2021 05 16



use strict;
use diagnostics;
use LWP;
use LWP::Simple;
use DBI;
use Dotenv -load => '/usr/lib/.env';

use lib qw(  /usr/lib/scripts/perl_modules/ );                      # for general ace dumping functions
# use lib qw( /home/postgres/work/citace_upload/ );           	# for general ace dumping functions
use ace_dumper;

use lib qw( /usr/lib/priv/cgi-bin/oa/ );
# use lib qw( /home/postgres/public_html/cgi-bin/oa/ );           # to get tables/fields and which ones to split as multivalue
use wormOA;

my $datatype = 'exp';
my ($fieldsRef, $datatypesRef) = &initModFields($datatype, 'two1823');
my %fields = %$fieldsRef;
my %datatypes = %$datatypesRef;
# my %data;

my $simpleRemapHashRef = &populateSimpleRemap();

my $deadObjectsHashRef = &populateDeadObjects();
my %deadObjects = %$deadObjectsHashRef;


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %theHash;

# my @tables = qw( name paper person gene endogenous anatomy qualifier qualifiertext qualifierls goid subcellloc lifestage exprtype antibodytext reportergene insitu rtpcr northern western antibody pattern remark transgene construct curator nodump protein proteindesc clone strain seqfeature sequence movieurl laboratory variation species );
# 
# my @maintables = qw( paper gene person anatomy goid subcellloc lifestage qualifierls exprtype antibodytext reportergene insitu rtpcr northern western antibody pattern remark transgene construct protein proteindesc clone strain seqfeature sequence movieurl laboratory variation species );


my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;

my %pipeSplit;
$pipeSplit{subcellloc}++;
$pipeSplit{antibodytext}++;
$pipeSplit{reportergene}++;
$pipeSplit{insitu}++;
$pipeSplit{rtpcr}++;
$pipeSplit{northern}++;
$pipeSplit{western}++;
$pipeSplit{pattern}++;
$pipeSplit{remark}++;

my %justTag;
$justTag{exprtype}++;

my %tableToTag;
$tableToTag{paper}         = 'Reference';
$tableToTag{gene}          = 'Gene';
$tableToTag{person}        = 'Person';
# $tableToTag{endogenous}    = 'Reflects_endogenous_expression_of';
$tableToTag{anatomy}       = 'Anatomy_term';
$tableToTag{goid}          = 'GO_term';
$tableToTag{subcellloc}    = 'Subcellular_localization';
$tableToTag{lifestage}     = 'Life_stage';
$tableToTag{qualifierls}   = 'Life_stage';
# $tableToTag{exprtype}      = 'Special';
$tableToTag{antibodytext}  = 'Antibody';
$tableToTag{reportergene}  = 'Reporter_gene';
$tableToTag{insitu}        = 'In_situ';
$tableToTag{rtpcr}         = 'RT_PCR';
$tableToTag{northern}      = 'Northern';
$tableToTag{western}       = 'Western';
$tableToTag{antibody}      = 'Antibody_info';
$tableToTag{pattern}       = 'Pattern';
$tableToTag{remark}        = 'Remark';
$tableToTag{transgene}     = 'Transgene';
$tableToTag{construct}     = 'Construct';
$tableToTag{protein}       = 'Protein';
$tableToTag{proteindesc}   = 'Protein_description';
$tableToTag{clone}         = 'Clone';
$tableToTag{strain}        = 'Strain';
$tableToTag{sequence}      = 'Sequence';
$tableToTag{seqfeature}    = 'Associated_feature';
$tableToTag{movieurl}      = 'MovieURL';
$tableToTag{laboratory}    = 'Laboratory';
$tableToTag{variation}     = 'Variation';
$tableToTag{species}       = 'Species';

my %tableToOntology;
# $tableToOntology{'anat_term'} = 'anatomy';	# put stuff here if the postgres table doesn't match the deadObjects ontology name



my %ontologyIdToName;

1;

sub getExprPattern {
  my ($flag) = shift;

  &populateOntIdToName();
  &populateDeadObjects();

  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM exp_name ; " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM exp_name WHERE exp_name = '$flag' ;" ); }	# get all entries for type of object name
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }

#   foreach my $table (@tables) {
#     $result = $dbh->prepare( "SELECT * FROM exp_$table $qualifier;" );		# get data for table with qualifier (or not if not)
#     $result->execute();	
#     while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
#   } # foreach my $table (@tables)


  # generic way to query postgres for all OA fields for the datatype, and store in arrays of html encoded entities
  foreach my $table (sort keys %{ $fields{$datatype} }) {
    next if ($table eq 'id');             # skip pgid column
  #   print qq(F $table F\n);
  #   $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL AND joinkey IN ('1', '2', '3');" );
#     $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table WHERE ${datatype}_$table IS NOT NULL;" );
    $result = $dbh->prepare( "SELECT * FROM ${datatype}_$table $qualifier;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless $row[1];
      if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/ /g; }
      if ( ($fields{$datatype}{$table}{type} eq 'multiontology') || ($fields{$datatype}{$table}{type} eq 'multidropdown') ) {
        my ($data) = $row[1] =~ m/^\"(.*)\"$/;
        my (@data) = split/\",\"/, $data;
        foreach my $entry (@data) {
          $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
          if ($entry) {
            push @{ $theHash{$table}{$row[0]} }, $entry; } }
      }
      elsif ($pipeSplit{$table}) {
        my (@data) = split/\|/, $row[1];
        foreach my $entry (@data) {
          $entry = &utf8ToHtml($simpleRemapHashRef, $entry);
          if ($entry) {
            push @{ $theHash{$table}{$row[0]} }, $entry; } }
      }
      else {
        my $entry = &utf8ToHtml($simpleRemapHashRef, $row[1]);
        if ($entry) {
          push @{ $theHash{$table}{$row[0]} }, $entry; }
      }
    } # while (my @row = $result->fetchrow)
  } # foreach my $table (sort keys %{ $fields{$datatype} })

  foreach my $name (sort keys %{ $nameToIDs{object} }) {
    my $entry = ''; 
# my $has_data;
#     $entry .= "\nExpr_pattern : \"$name\"\n";

    my %cur_entry;
    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$name} }) {
# print qq(J $joinkey J\n);
      next if ($theHash{nodump}{$joinkey});

      unless ($theHash{'paper'}{$joinkey}[0] || $theHash{'person'}{$joinkey}[0]) {
        $err_text .= "$joinkey $name has neither person nor paper\n"; }

      my $qualifierNot = 0;
      if ($theHash{'qualifier'}{$joinkey}[0]) {
        if ($theHash{'qualifier'}{$joinkey}[0] eq 'NOT') { $qualifierNot++; } }

      foreach my $field (sort keys %justTag) {
        foreach my $data (@{ $theHash{$field}{$joinkey} }) {
          $cur_entry{qq($data\n)}++; } }

      foreach my $field (sort keys %tableToTag) {
        foreach my $data (@{ $theHash{$field}{$joinkey} }) {
          $data =~ s/\n/ /g; $data =~ s/ +/ /g;     # daniela wants no linebreaks dumped, and multiple spaces converted to a single space 2011 02 09
          ($data) = &filterAce($data);
          if ($data) { 
            my $ontology = $field;
            if ($tableToOntology{$field}) { $ontology = $tableToOntology{$field}; }
            my $isGood = 0;
            if ($deadObjects{$ontology}{$data}) {
              if ($field eq 'gene') {
                  if ($deadObjects{gene}{$data}{"split"}) {  # anything with a split gene is an error
                      $cur_entry{qq(Historical_gene\t"$data" "Note: This object originally referred to a gene ($data) that is now considered dead. Please interpret with discretion."\n)}++;
                      $err_text .= "$joinkey\tnodump\tThis pgid contains a gene that has been split $data in $field.\n"; }
                    elsif ($deadObjects{gene}{$data}{"mapto"}) {       # if gene maps to another gene, add the mapped version
                      my $mappedGene = $deadObjects{gene}{$data}{"mapto"};        # convert to new gene
                      $cur_entry{qq(Historical_gene  "$data"  "Note: This object originally referred to $data.  $data is now considered dead and has been merged into $mappedGene. $mappedGene has replaced $data accordingly."\n)}++;
                      if ($theHash{endogenous}{$joinkey}[0]) {			# if endogenous toggle, also dump gene to endogenous .ace tag for Daniela 2014 03 19
                        $cur_entry{qq(Reflects_endogenous_expression_of\t"$mappedGene"\n)}++; }
                      $cur_entry{qq($tableToTag{$field}\t"$mappedGene" Inferred_automatically\n)}++; }
                    elsif ($deadObjects{gene}{$data}{"suppressed"}) {
                      $cur_entry{qq(Historical_gene\t"$data" "Note: This object originally referred to a gene ($data) that has been suppressed. Please interpret with discretion."\n)}++; }
                    elsif ($deadObjects{gene}{$data}{"dead"}) {
                      $cur_entry{qq(Historical_gene\t"$data" "Note: This object originally referred to a gene ($data) that is now considered dead. Please interpret with discretion."\n)}++; } }
                else {
                    $err_text .= "$name has dead $field $data $deadObjects{$ontology}{$data}\n"; } }
              elsif ($field eq 'gene') {
                $isGood = 1;
                if ($theHash{endogenous}{$joinkey}[0]) {		# if endogenous toggle, also dump gene to endogenous .ace tag for Daniela 2014 03 19
                  $cur_entry{qq(Reflects_endogenous_expression_of\t"$data"\n)}++; } }
              elsif ($field eq 'goid') {
                if ($qualifierNot) { $cur_entry{qq(Not_in_GO_term\t"$data"\n)}++; }
                  else { $isGood = 1; } }
              elsif ($field eq 'qualifierls') {
                if (scalar @{ $theHash{'anatomy'}{$joinkey} } < 1) {	# if there is no anatomy data, dump each qualifierls (if there was anatomy it would have dumped above under the anatomy section)
                  if ($qualifierNot) { $cur_entry{qq(Not_in_Life_stage\t"$data"\n)}++; }
                    else { $isGood = 1; } } }
              elsif ($field eq 'anatomy') {
                my $l2_exists = 0; my $l3_exists = 0; my $l4_exists = 0;
                if ($qualifierNot) {
                    foreach my $qualifierls (@{ $theHash{'qualifierls'}{$joinkey} }) {
                      $cur_entry{qq(Not_in_Anatomy_term\t"$data" Life_stage "$qualifierls"\n)}++; }
                    $cur_entry{qq(Not_in_Anatomy_term\t"$data"\n)}++; }
                  else {
                    foreach my $qualifierls (@{ $theHash{'qualifierls'}{$joinkey} }) {
                      $l4_exists++;
                      $cur_entry{qq($tableToTag{$field}\t"$data" Life_stage "$qualifierls"\n)}++;
                      $cur_entry{qq(Life_stage\t"$qualifierls" Anatomy_term "$data"\n)}++; }
                    foreach my $qualifier (@{ $theHash{'qualifier'}{$joinkey} }) {
                      $cur_entry{qq($tableToTag{$field}\t"$data" $qualifier\n)}++; $l2_exists++; }
                    foreach my $qualifiertext (@{ $theHash{'qualifiertext'}{$joinkey} }) {
                      $cur_entry{qq($tableToTag{$field}\t"$data" Remark "$qualifiertext"\n)}++; $l3_exists++; }
                    unless ( ($l2_exists) || ($l3_exists) || ($l4_exists) ) { $isGood = 1; } } }
              else { $isGood = 1; }
            if ($isGood) {
              if ($ontologyIdToName{$field}{$data}) { $data = $ontologyIdToName{$field}{$data}; }	# convert ontology ids to species names.
              $cur_entry{qq($tableToTag{$field}\t"$data"\n)}++; } } } }

#           my %entries = &getData($table, $joinkey);
#           foreach my $entry (sort keys %entries) { $cur_entry{"$tag\t\"$entry\"\n"}++; }

#       foreach my $table (@maintables) {
#         next unless ($tableToTag{$table});
#         my %qualifiers = &getData('qualifier', $joinkey); my $qualifierNot = 0;
#         if ($qualifiers{'NOT'}) { $qualifierNot++; }
#         my $tag = $tableToTag{$table};
#         if ($table eq 'anatomy') {
#           my %e1 = &getData($table, $joinkey);
#           my %e2 = &getData('qualifier', $joinkey);
#           my %e3 = &getData('qualifiertext', $joinkey);
#           my %e4 = &getData('qualifierls', $joinkey);
#           my $l2_exists = 0; my $l3_exists = 0; my $l4_exists = 0;
#           foreach my $e1 (sort keys %e1) {
#             if ($deadObjects{anatomy}{$e1}) { $err_text .= "$name has obsolete anatomy $e1\n"; }
#               elsif ($qualifierNot) { 
#                 foreach my $e4 (sort keys %e4) { $cur_entry{"Not_in_Anatomy_term\t\"$e1\" Life_stage \"$e4\"\n"}++; }
#                 $cur_entry{"Not_in_Anatomy_term\t\"$e1\"\n"}++; }
#               else {
#                 foreach my $e4 (sort keys %e4) {				# dump anatomy to qualifierls in both directions for every crossproduct, if there is an anatomy.  2015 02 03
#                    $l4_exists++;
#                    $cur_entry{"$tag\t\"$e1\" Life_stage \"$e4\"\n"}++; 
#                    $cur_entry{"Life_stage\t\"$e4\" Anatomy_term \"$e1\"\n"}++; }
# # old way dumping qualifier + qualifiertext inline.  replace 2017 10 08
# #                 foreach my $e2 (sort keys %e2) {
# #                   foreach my $e3 (sort keys %e3) {
# #                     $cur_entry{"$tag\t\"$e1\" $e2 \"$e3\"\n"}++; $l3_exists++; }
# #                   unless ($l3_exists) {
# #                     $cur_entry{"$tag\t\"$e1\" $e2\n"}++; $l2_exists++; } }
#                 foreach my $e2 (sort keys %e2) {
#                   $cur_entry{"$tag\t\"$e1\" $e2\n"}++; $l2_exists++; }
#                 foreach my $e3 (sort keys %e3) {
#                   $cur_entry{"$tag\t\"$e1\" Remark \"$e3\"\n"}++; $l3_exists++; }
#                 unless ( ($l2_exists) || ($l3_exists) || ($l4_exists) ) {
#                   $cur_entry{"$tag\t\"$e1\"\n"}++; } } } }
#         elsif ($table eq 'qualifierls') {				# micropub data could have qualifierls without anatomy
#           my %e1 = &getData($table, $joinkey);
#           my %e2 = &getData('anatomy', $joinkey);
#           if (scalar keys %e2 < 1) { 					# if there is no anatomy data, dump each qualifierls (if there was anatomy it would have dumped above under the anatomy section)
#             foreach my $e1 (sort keys %e1) {
#               if ($qualifierNot) { $cur_entry{"Not_in_Life_stage\t\"$e1\"\n"}++; }
#                 else { $cur_entry{"$tag\t\"$e1\"\n"}++; } } } }
#         elsif ($table eq 'goid') {					# goid data could have qualifier NOT
#           my %entries = &getData($table, $joinkey);
#           foreach my $entry (sort keys %entries) { 
#             if ($qualifierNot) { $cur_entry{"Not_in_GO_term\t\"$entry\"\n"}++; }
#               else { $cur_entry{"$tag\t\"$entry\"\n"}++; } } }
#         elsif ($table eq 'exprtype') {
#           my %entries = &getData($table, $joinkey);
#           foreach my $entry (sort keys %entries) { $cur_entry{"$entry\n"}++; } }
#         elsif ($table eq 'gene') {
#           my %entries = &getData($table, $joinkey);
#           foreach my $entry (sort keys %entries) {
# #             if ($deadObjects{gene}{$entry}) { $err_text .= "$name has dead gene $entry $deadObjects{gene}{$entry}\n"; }
#             if ($deadObjects{gene}{"split"}{$entry}) {  # anything with a split gene is an error
# #                 $cur_entry{qq(Historical_gene\t"$entry" Remark  "Note: This object originally referred to a gene ($entry) that is now considered dead. Please interpret with discretion."\n)}++;
#                 $cur_entry{qq(Historical_gene\t"$entry" "Note: This object originally referred to a gene ($entry) that is now considered dead. Please interpret with discretion."\n)}++;
#                 $err_text .= "$joinkey\tnodump\tThis pgid contains a gene that has been split $entry in $table.\n"; }
#               elsif ($deadObjects{gene}{"mapto"}{$entry}) {       # if gene maps to another gene, add the mapped version
# #                 $cur_entry{qq(Historical_gene  "$entry"  Remark  "Note: This object originally referred to $entry.  $entry is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$entry}. $deadObjects{gene}{"mapto"}{$entry} has replaced $entry accordingly."\n)}++;
#                 $cur_entry{qq(Historical_gene  "$entry"  "Note: This object originally referred to $entry.  $entry is now considered dead and has been merged into $deadObjects{gene}{"mapto"}{$entry}. $deadObjects{gene}{"mapto"}{$entry} has replaced $entry accordingly."\n)}++;
#                 my $mappedGene = $deadObjects{gene}{"mapto"}{$entry};        # convert to new gene
#                 if ($theHash{endogenous}{$joinkey}) {			# if endogenous toggle, also dump gene to endogenous .ace tag for Daniela 2014 03 19
#                   $cur_entry{qq(Reflects_endogenous_expression_of\t"$mappedGene"\n)}++; }
#                 $cur_entry{qq($tag\t"$mappedGene" Inferred_automatically\n)}++; }
#               elsif ($deadObjects{gene}{"suppressed"}{$entry}) {
# #                 $cur_entry{qq(Historical_gene\t"$entry" Remark  "Note: This object originally referred to a gene ($entry) that has been suppressed. Please interpret with discretion."\n)}++;
#                 $cur_entry{qq(Historical_gene\t"$entry" "Note: This object originally referred to a gene ($entry) that has been suppressed. Please interpret with discretion."\n)}++; }
#               elsif ($deadObjects{gene}{"dead"}{$entry}) {
# #                 $cur_entry{qq(Historical_gene\t"$entry" Remark  "Note: This object originally referred to a gene ($entry) that is now considered dead. Please interpret with discretion."\n)}++;
#                 $cur_entry{qq(Historical_gene\t"$entry" "Note: This object originally referred to a gene ($entry) that is now considered dead. Please interpret with discretion."\n)}++; }
#               else { 
#                 if ($theHash{endogenous}{$joinkey}) { 			# if endogenous toggle, also dump gene to endogenous .ace tag for Daniela 2014 03 19
#                   $cur_entry{qq(Reflects_endogenous_expression_of\t"$entry"\n)}++; }
#                 $cur_entry{"$tag\t\"$entry\"\n"}++; } } }
#         elsif ($table eq 'paper') {
#           my %entries = &getData($table, $joinkey);
#           foreach my $entry (sort keys %entries) {
#             if ($deadObjects{paper}{$entry}) { $err_text .= "$name has dead paper $entry $deadObjects{paper}{$entry}\n"; }
#               else { $cur_entry{"$tag\t\"$entry\"\n"}++; } } }
#         else {
#           my %entries = &getData($table, $joinkey);
#           foreach my $entry (sort keys %entries) { $cur_entry{"$tag\t\"$entry\"\n"}++; } }
#       }
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$name} })
#     foreach my $line (sort keys %cur_entry) { $entry .= $line; $has_data++; }
#     if ($has_data) { $all_entry .= $entry; }
    foreach my $line (sort keys %cur_entry) { $entry .= $line; }
    if ($entry) {
       $all_entry .= qq(\nExpr_pattern : "$name"\n);
       $all_entry .= $entry; }
  } # foreach my $name (sort keys %{ $nameToIDs{$type} })
  return( $all_entry, $err_text );
} # sub getExprPattern

sub getData {				# get hash of values in this table
  my ($table, $joinkey) = @_;
  my %entries;
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
    unless ($table eq 'remark') {			# remark could have doublequotes at the beginning or the end, everything else shouldn't
      if ($data =~ m/^\"/) { $data =~ s/^\"//; }
      if ($data =~ m/\"$/) { $data =~ s/\"$//; } }
    if ($data =~ m/\//) { $data =~ s/\//\\\//g; }
    if ($data =~ m//) { $data =~ s///g; }
    if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my @data;
    if ($data =~ m/\",\"/) { @data = split/\",\"/, $data; }
      elsif ($pipeSplit{$table}) { @data = split/\|/, $data; }
      else { push @data, $data; }
    foreach my $value (@data) {
      if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; }
      if ($value =~ m/^\s+/) { $value =~ s/^\s+//g; }
      if ($value =~ m/\s+$/) { $value =~ s/\s+$//g; }
      if ($table eq 'species') { if ($ontologyIdToName{$table}{$value}) { $value = $ontologyIdToName{$table}{$value}; } }	# convert species ids to species names.
#       if ($table eq 'lifestage') { if ($ontologyIdToName{$table}{$value}) { $value = $ontologyIdToName{$table}{$value}; } }	# convert lifestage ids to lifestage names.  2011 05 13 # no longer convert to names 2012 05 10
      if ($value) { $entries{$value}++; }
    }
  }
  return %entries;
} # sub getData

sub populateOntIdToName {
#   $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage;" ); $result->execute();	 # no longer convert to names 2012 05 10
#   while (my @row = $result->fetchrow) { $ontologyIdToName{'lifestage'}{$row[0]} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM pap_species_index;" ); $result->execute();	
  while (my @row = $result->fetchrow) { $ontologyIdToName{'species'}{$row[0]} = $row[1]; }
} # sub populateOntIdToName

# sub populateDeadObjects {
#   $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();	
#   while (my @row = $result->fetchrow) { $deadObjects{paper}{"WBPaper$row[0]"} = $row[1]; }
#   $result = $dbh->prepare( "SELECT * FROM obo_data_anatomy WHERE obo_data_anatomy ~ 'is_obsolete: true';" ); $result->execute();	
#   while (my @row = $result->fetchrow) { $deadObjects{anatomy}{"$row[0]"} = $row[0]; }
# 
#   my %temp;
#   $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();	
#   while (my @row = $result->fetchrow) {                 # Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
#     if ($row[1] =~ m/split_into (WBGene\d+)/) {       $temp{"split"}{"WBGene$row[0]"} = $1; }
#       elsif ($row[1] =~ m/merged_into (WBGene\d+)/) { $temp{"mapto"}{"WBGene$row[0]"} = $1; }
#       elsif ($row[1] =~ m/Suppressed/) {              $temp{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
#       elsif ($row[1] =~ m/Dead/) {                    $temp{"dead"}{"WBGene$row[0]"} = $row[1]; } }
#   my $doAgain = 1;                                    # if a mapped gene maps to another gene, loop through all again
#   while ($doAgain > 0) {
#     $doAgain = 0;                                     # stop if no genes map to other genes
#     foreach my $gene (sort keys %{ $temp{mapto} }) {
#       next unless ( $temp{mapTo}{$gene} );
#       my $mappedGene = $temp{mapTo}{$gene};
#       if ($temp{mapTo}{$mappedGene}) {
#         $temp{mapTo}{$gene} = $temp{mapTo}{$mappedGene};          # set mapping of original gene to 2nd degree mapped gene
#         $doAgain++; } } }                             # loop again in case a mapped gene maps to yet another gene
#   foreach my $type (sort keys %temp) {
#     foreach my $gene (sort keys %{ $temp{$type} }) {
#       my $value = $temp{$type}{$gene};
#       $deadObjects{gene}{$gene}{$type} = $value; } }
# } # sub populateDeadObjects



__END__

  $fields{exp}{name}{label}                          = 'Expr Pattern';
  $fields{exp}{paper}{label}                         = 'Reference';
  $fields{exp}{gene}{label}                          = 'Gene';
  $fields{exp}{anatomy}{label}                       = 'Anatomy';
  $fields{exp}{qualifier}{label}                     = 'Qualifier';
  $fields{exp}{qualifiertext}{label}                 = 'Qualifier Text';
  $fields{exp}{goid}{label}                          = 'GO Term';
  $fields{exp}{subcellloc}{label}                    = 'Subcellular Localization';
  $fields{exp}{lifestage}{label}                     = 'Life Stage';
  $fields{exp}{exprtype}{label}                      = 'Type';
  $fields{exp}{antibodytext}{label}                  = 'Antibody_Text';
  $fields{exp}{reportergene}{label}                  = 'Reporter Gene';
  $fields{exp}{insitu}{label}                        = 'In Situ';
  $fields{exp}{rtpcr}{label}                         = 'RT PCR';
  $fields{exp}{northern}{label}                      = 'Northern';
  $fields{exp}{western}{label}                       = 'Western';
  $fields{exp}{pictureflag}{label}                   = 'Picture_Flag';
  $fields{exp}{antibody}{label}                      = 'Antibody_Info';
  $fields{exp}{antibodyflag}{label}                  = 'Antibody_Flag';
  $fields{exp}{pattern}{label}                       = 'Pattern';
  $fields{exp}{remark}{label}                        = 'Remark';
  $fields{exp}{transgene}{label}                     = 'Transgene';
  $fields{exp}{transgeneflag}{label}                 = 'Transgene_Flag';
  $fields{exp}{curator}{label}                       = 'Curator';
  $fields{exp}{nodump}{label}                        = 'NO DUMP';
  $fields{exp}{protein}{label}                       = 'Protein Description';
  $fields{exp}{clone}{label}                         = 'Clone';
  $fields{exp}{strain}{label}                        = 'Strain';
  $fields{exp}{sequence}{label}                      = 'Sequence';
  $fields{exp}{movieurl}{label}                      = 'Movie URL';
  $fields{exp}{laboratory}{label}                    = 'Laboratory';


  $fields{exp}{qualifiertext}{type}                  = 'bigtext';
  $fields{exp}{subcellloc}{type}                     = 'bigtext';
  $fields{exp}{antibodytext}{type}                   = 'bigtext';
  $fields{exp}{reportergene}{type}                   = 'bigtext';
  $fields{exp}{insitu}{type}                         = 'bigtext';
  $fields{exp}{rtpcr}{type}                          = 'bigtext';
  $fields{exp}{northern}{type}                       = 'bigtext';
  $fields{exp}{western}{type}                        = 'bigtext';
  $fields{exp}{pattern}{type}                        = 'bigtext';
  $fields{exp}{remark}{type}                         = 'bigtext';

