package get_rnai_ace;
require Exporter;

# molecule WBMolIDs now in mop_name instead of mop_molecule.  2012 10 22

# added constraint nodump if no phenotype.
# check all tables for pgids and see if any don't have an rna_name value.  2012 11 01
#
# dump molecules as separate .ace entries for Chris.  2014 06 02
#
# added entity-quality tables to dumper.  
# moved lifestage from regular tag to subtag under phenotype.
# &getData() now has to deal with a @data2 for pato terms following main subtag data.
# for Chris  2015 09 22
#
# added paper to community curator output.  2020 01 27



our @ISA	= qw(Exporter);
our @EXPORT	= qw( getRnai );
our $VERSION	= 1.00;


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
my @tables = qw( curator paper name laboratory date pcrproduct dnatext sequence strain genotype treatment temperature deliverymethod species remark nodump phenotype penfromto penetrance heatsens coldsens quantfromto quantdesc phenremark molecule phenotypenot person historyname movie database exprprofile anatomy lifestage molaffected goprocess gofunction gocomponent anatomyquality lifestagequality molaffectedquality goprocessquality gofunctionquality gocomponentquality communitycurator);

my @maintables = qw( paper laboratory date pcrproduct dnatext sequence strain genotype treatment temperature deliverymethod species remark nodump phenotype person historyname movie database exprprofile );
my @pentables = qw( penfromto penetrance heatsens coldsens quantfromto quantdesc phenremark molecule anatomy lifestage molaffected goprocess gofunction gocomponent );

my $all_entry = '';
my $err_text = '';

my %nameToIDs;							# type -> name -> ids -> count
my %ids;							# pgids relevant to the name(s) of the RNAi objects to get

my %paperCommunity;


my %tableToTag;        &populateTableToTag();			# convert postgres table to .ace tag
my %dataType;          &populateDataType();			# convert postgres table type of data for .ace dumping
my %patoSubtag;        &populatePatoSubtag();			# these fields have a pato quality
# my %ontologyIdToName;  &populateOntIdToName();		# some ids should dump as names	# currently nothing mapping between ids and names 2012 10 22

1;

sub getRnai {
  my ($flag) = shift;

  my %all_pgids;
  my %name_pgids;

  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM rna_$table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      if ($row[0]) {
        if ($table eq 'name') { $name_pgids{$row[0]}++; }
          else { $all_pgids{$row[0]}++; } } } }

  foreach my $pgid (sort {$a<=>$b} keys %all_pgids) { unless ($name_pgids{$pgid}) { $err_text .= "$pgid has no rna_name\n"; } } 


  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM rna_name; " ); }		# get all entries for type
    else { $result = $dbh->prepare( "SELECT * FROM rna_name WHERE rna_name = '$flag';" ); }	# get all entries for type of object name
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{object}{$row[0]} = $row[1]; $nameToIDs{object}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM rna_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $name (sort keys %{ $nameToIDs{object} }) {
    my %filter; my $has_data;
    my $molecule_ace = '';		# if there are molecules, create molecule .ace for Chris 2014 06 02
    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{object}{$name} }) {
      next if ($theHash{nodump}{$joinkey});
      my $curator = 'no curator';
      if ($theHash{curator}{$joinkey}) { $curator = $theHash{curator}{$joinkey}; }
        else {  $err_text .= "$joinkey\tflagonly\t$curator\thas no curator\n"; }
      my ($checkFlag) = &checkConstraints($joinkey, $curator);
      next if ($checkFlag eq 'nodump');
      foreach my $table (@maintables) {
        next unless ($tableToTag{$table});
        my $tag = $tableToTag{$table};
        if ( $table eq 'phenotype') {
            if ( $theHash{'phenotypenot'}{$joinkey} ) { $tag = $tableToTag{'phenotypenot'}; }	# if NOT flag on, replace phenotype tag
#             unless ($theHash{$table}{$joinkey}) { print "NO PHENOTYPE $table $joinkey\n"; }
            my $phenotypes = $theHash{$table}{$joinkey};
            if ($phenotypes =~ m/^\"/) { $phenotypes =~ s/^\"//; } if ($phenotypes =~ m/\"$/) { $phenotypes =~ s/\"$//; }
            my @phenotypes = split/\",\"/, $phenotypes;	# get the phenotypes
            foreach my $phenotype (@phenotypes) {
              my $phen_tag = "$tag\t\"$phenotype\"";	# phenotype + tag for subtags and if there is no data in subtags
              my $has_sub_data = 0;			# if the subtables have data, add those ; if they don't have data add the phenotype
              foreach my $subtable (@pentables) {	# for each phenotype subtag
                if ($subtable eq 'molecule') {		# if there are molecules, create molecule .ace for Chris 2014 06 02
                  next unless $theHash{$subtable}{$joinkey};
                  my $paper_evi = ''; if ( $theHash{'paper'}{$joinkey} ) { $paper_evi = qq( Paper_evidence "$theHash{'paper'}{$joinkey}"); }
                  my (@molecules) = $theHash{$subtable}{$joinkey} =~ m/"(WBMol:\d+)"/g;
                  foreach my $molecule (@molecules) { $molecule_ace .= qq(Molecule : "$molecule"\nRNAi\t"$name" "$phenotype"$paper_evi\n\n); }
                } # if ($subtable eq 'molecule')
                my $subtag = "$phen_tag $tableToTag{$subtable}";		# add subtag to the tag
                my $table_lines = &getData($subtable, $joinkey, $subtag); if ($table_lines) { 
                  $filter{$table_lines}++; $has_data++; $has_sub_data++; } }	# if table has data add to filter, flag the object and phenotype to have data 
              unless ($has_sub_data) { $filter{$phen_tag}++; } } }		# without subtag data just get phenotype
          else { my $table_lines = &getData($table, $joinkey, $tag); if ($table_lines) { 
            $filter{$table_lines}++; $has_data++; } }	# if table has data add to filter, flag the object to have data
      } # foreach my $table (@maintables)
      if ($theHash{paper}{$joinkey}) { if ($theHash{communitycurator}{$joinkey}) { $paperCommunity{$theHash{paper}{$joinkey}}{$theHash{communitycurator}{$joinkey}}++; } }
      if ($has_data) {
        $all_entry .= "RNAi : \"$name\"\nMethod\t\"RNAi\"\n";
        my $entry = join"\n", sort keys %filter;
        $all_entry .= "$entry\n\n"; }
      if ($molecule_ace) { 
        $all_entry .= "$molecule_ace"; }
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{$type}{$name} })
  } # foreach my $name (sort keys %{ $nameToIDs{$type} })

  foreach my $paper (sort keys %paperCommunity) {
    foreach my $curator (sort keys %{ $paperCommunity{$paper} }) {
      $all_entry .= qq(Paper : "$paper"\nCommunity_curation\tPhenotype_curation_by\t"$curator"\n\n); } }

  return( $all_entry, $err_text );
} # sub getRnai

sub getData {
  my ($table, $joinkey, $tag) = @_;
  my $table_lines = ''; my @lines;
  my @data2;						# entity-quality fields have a pato term as second value in the subtag, populate data here to output in crossproduct  2015 09 22
  if ($patoSubtag{$table}) { 
    my $otherTable = $table . $patoSubtag{$table};	# table with sub sub data matches table name but has additional text in name
    if ($theHash{$otherTable}{$joinkey}) {
        if ($theHash{$otherTable}{$joinkey} =~ m/^\"/) { $theHash{$otherTable}{$joinkey} =~ s/^\"//; } if ($theHash{$otherTable}{$joinkey} =~ m/\"$/) { $theHash{$otherTable}{$joinkey} =~ s/\"$//; }
        (@data2) = split/\",\"/, $theHash{$otherTable}{$joinkey}; }
      else { push @data2, "PATO:0000460"; } }
  if ($theHash{$table}{$joinkey}) {
    my $data = $theHash{$table}{$joinkey};
    my @data;
#     if ($data =~ m/^\"/)  { $data =~ s/^\"//;   }	# chris wants leading  doublequotes dumped  2016 07 28
#     if ($data =~ m/\"$/)  { $data =~ s/\"$//;   }	# chris wants trailing doublequotes dumped  2016 07 28
    if ($data =~ m//)   { $data =~ s///g;   }
    if ($data =~ m/\n/)   { $data =~ s/\n/  /g; }
    if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
    my $dataType = $dataType{$table};
    if ( ($dataType eq 'multiontology') || ($dataType eq 'multidropdown') ) { 
        if ($data =~ m/^\"/)  { $data =~ s/^\"//;   }	# leading  doublequotes need to be removed from multivalue fields  2016 07 28
        if ($data =~ m/\"$/)  { $data =~ s/\"$//;   }	# trailing doublequotes need to be removed from multivalue fields  2016 07 28
        @data = split/\",\"/, $data; }
      elsif ( ($dataType eq 'text') || ($dataType eq 'text_text') || ($dataType eq 'text_text_text') || ($dataType eq 'bigtext') ) { @data = split/ \| /, $data; }
      else { push @data, $data; }
    foreach my $value (@data) {
      next unless ($value);							# skip blank entries
      if ($value =~ m/\"/) { $value =~ s/\"/\\\"/g; }
#       if ($table eq 'lifestage') { if ($ontologyIdToName{$table}{$value}) { $value = $ontologyIdToName{$table}{$value}; } }	# convert lifestage ids to lifestage names.  2011 05 13 # stop converting to names  2012 05 11
#       if ($table eq 'molecule') { if ($ontologyIdToName{$table}{$value}) { $value = $ontologyIdToName{$table}{$value}; } }	# convert molecule pgids to molecule names.	# molecules now stored as wbmolids instead of pgids.  2012 10 22
      if ( ($dataType eq 'text_text') || ($dataType eq 'text_text_text') ) { $value =~ s/ /\" \"/g; }	# these dividers need doublequotes in .ace
      unless ($dataType eq 'noquote') { $value = '"' . $value . '"'; }		# doublequotes for .ace dump unless noquote
      if ($dataType eq 'valuetag') { push @lines, "$tag"; }
        elsif (scalar @data2 > 0) {				# if there is sub sub data append extra lines with it to regular data
          foreach my $data2 (@data2) {
            push @lines, "$tag\t$value\t\"$data2\""; } }
        else { push @lines, "$tag\t$value"; }
    } # foreach my $value (@data)
  } # if ($theHash{$table}{$joinkey})
  $table_lines = join"\n", @lines;
  return $table_lines;
} # sub getData

sub checkConstraints {
  my ($joinkey, $curator) = @_;
  my $error_data = '';

  unless ( ( $theHash{paper}{$joinkey} ) || ( $theHash{person}{$joinkey} ) ) {
    $error_data .= "$joinkey\tnodump\t$curator\tThere is no reference, neither paper nor person\n"; }
  unless ( ( $theHash{pcrproduct}{$joinkey} ) || ( $theHash{dnatext}{$joinkey} ) || ( $theHash{sequence}{$joinkey} ) ) {
    $error_data .= "$joinkey\tnodump\t$curator\tThere is no sequence, neither pcrproduct nor dnatext nor sequence\n"; }
  unless ( $theHash{name}{$joinkey} ) { $error_data .= "$joinkey\tnodump\t$curator\tThere is no RNAi ID\n"; }
  unless ( $theHash{phenotype}{$joinkey} ) { $error_data .= "$joinkey\tnodump\t$curator\tThere is no phenotype\n"; }

  unless ( $theHash{species}{$joinkey} ) { $err_text .= "$joinkey\tflagonly\t$curator\tThere is no species\n"; }
  unless ( $theHash{deliverymethod}{$joinkey} ) { $err_text .= "$joinkey\tflagonly\t$curator\tThere is no deliverymethod\n"; }

  if ($error_data) { $err_text .= $error_data; return "nodump"; }       # these errors go to log and prevent dumping of that pgid
    else { return "ok"; }
} # sub checkConstraints

# currently nothing mapping between id and name 2012 10 22
# sub populateOntIdToName {
#   $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage;" ); $result->execute();	
#   while (my @row = $result->fetchrow) { $ontologyIdToName{'lifestage'}{$row[0]} = $row[1]; }
#   $result = $dbh->prepare( "SELECT * FROM mop_molecule;" ); $result->execute();	
#   while (my @row = $result->fetchrow) { $ontologyIdToName{'molecule'}{$row[0]} = $row[1]; }
# } # sub populateOntIdToName

sub populatePatoSubtag {
  $patoSubtag{anatomy}        = 'quality';
  $patoSubtag{lifestage}      = 'quality';
  $patoSubtag{molaffected}    = 'quality';
  $patoSubtag{goprocess}      = 'quality';
  $patoSubtag{gofunction}     = 'quality';
  $patoSubtag{gocomponent}    = 'quality';
} # sub populatePatoSubTag

sub populateTableToTag {
  $tableToTag{paper}          = 'Reference';
  $tableToTag{laboratory}     = 'Laboratory';
  $tableToTag{date}           = 'Date';
  $tableToTag{pcrproduct}     = 'PCR_product';
  $tableToTag{dnatext}        = 'DNA_text';
  $tableToTag{sequence}       = 'Sequence';
  $tableToTag{strain}         = 'Strain';
  $tableToTag{genotype}       = 'Genotype';
  $tableToTag{treatment}      = 'Treatment';
  $tableToTag{lifestage}      = 'Life_stage';
  $tableToTag{temperature}    = 'Temperature';
  $tableToTag{deliverymethod} = 'Delivered_by';
  $tableToTag{species}        = 'Species';
  $tableToTag{remark}         = 'Remark';
  $tableToTag{phenotype}      = 'Phenotype';
  $tableToTag{penfromto}      = 'Range';
  $tableToTag{penetrance}     = 'Penetrance';
  $tableToTag{heatsens}       = 'Heat_sensitive';
  $tableToTag{coldsens}       = 'Cold_sensitive';
  $tableToTag{quantfromto}    = 'Quantity';
  $tableToTag{quantdesc}      = 'Quantity_description';
  $tableToTag{phenremark}     = 'Remark';
  $tableToTag{molecule}       = 'Molecule';
  $tableToTag{phenotypenot}   = 'Phenotype_not_observed';
  $tableToTag{person}         = "Evidence\tPerson_evidence";
  $tableToTag{historyname}    = 'History_name';
  $tableToTag{movie}          = 'Movie';
  $tableToTag{database}       = 'Database';
  $tableToTag{exprprofile}    = 'Expr_profile';
  $tableToTag{anatomy}        = 'Anatomy_term';
  $tableToTag{lifestage}      = 'Life_stage';
  $tableToTag{molaffected}    = 'Molecule_affected';
  $tableToTag{goprocess}      = 'GO_term';
  $tableToTag{gofunction}     = 'GO_term';
  $tableToTag{gocomponent}    = 'GO_term';
} # sub populateTableToTag

sub populateDataType {
  $dataType{paper}              = 'ontology';
  $dataType{laboratory}         = 'multiontology';
  $dataType{date}               = 'noquote';
  $dataType{pcrproduct}         = 'multiontology';
  $dataType{dnatext}            = 'text_text';
  $dataType{sequence}           = 'text';			# change later if we switch to ontology of 2 million objects
  $dataType{strain}             = 'ontology';
  $dataType{genotype}           = 'bigtext';
  $dataType{treatment}          = 'bigtext';
  $dataType{lifestage}          = 'ontology';
  $dataType{temperature}        = 'noquote';
  $dataType{deliverymethod}     = 'multidropdown';
  $dataType{species}            = 'dropdown';
  $dataType{remark}             = 'bigtext';
  $dataType{phenotype}          = 'multiontology';
  $dataType{penfromto}          = 'noquote';
  $dataType{penetrance}         = 'dropdown';
  $dataType{heatsens}           = 'valuetag';
  $dataType{coldsens}           = 'valuetag';
  $dataType{quantfromto}        = 'noquote';
  $dataType{quantdesc}          = 'bigtext';
  $dataType{phenremark}         = 'bigtext';
  $dataType{molecule}           = 'multiontology';
  $dataType{phenotypenot}       = 'toggletag';
  $dataType{person}             = 'multiontology';
  $dataType{historyname}        = 'text';
  $dataType{movie}              = 'bigtext';
  $dataType{database}           = 'text_text_text';
  $dataType{exprprofile}        = 'text';
  $dataType{anatomy}            = 'multiontology';
  $dataType{lifestage}          = 'multiontology';
  $dataType{molaffected}        = 'multiontology';
  $dataType{goprocess}          = 'multiontology';
  $dataType{gofunction}         = 'multiontology';
  $dataType{gocomponent}        = 'multiontology';
} # sub populateDataType
