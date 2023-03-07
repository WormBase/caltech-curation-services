package get_process_curation_ace;
require Exporter;

# module to dump pro_ process curation objects.  2012 07 19
#
# molecule WBMolIDs now in mop_name instead of mop_molecule.  2012 10 22
#
# suppress dead genes and put them in error file, instead of complicated Historical_gene (complicated because of evidence hash), for Chris and Karen.  2013 09 05
#
# removed goid for Karen  2013 09 20
#
# changed gin_dead to not have just "Dead" or "split_into / merged_into", now it has Dead / Suppressed / merged_into / split_into independent of
# each other (all merged / split must be dead though).  For this dumper, all that seems to matter is whether there's a value in gin_dead.  Chris 
# will check with Karen.  2013 10 21
#
# changed  &getData  to have a type 'single' to dump out single ontology or single value type fields.  
# now also dumping paper as a Reference to .ace file.
# added  pro_topicpaperstatus  and extra check not to dump out entries which have a value or 'irrelevant' or 'unchecked'.
# for Karen and Chris.  2013 11 07
#
# added  construct  for Karen, unclear if it's the right .ace tag or needs evidence.  2014 07 08


our @ISA	= qw(Exporter);
our @EXPORT	= qw(getProcessCuration );
our $VERSION	= 1.00;



use strict;
use diagnostics;
use DBI;

use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my %theHash;
# my @tables = qw( paper process goid wbgene phenotype molecule anatomy lifestage taxon exprcluster picture movie pathwaydb );	# removed goid for Karen 2013 09 20
my @tables = qw( paper process wbgene phenotype molecule anatomy lifestage taxon exprcluster construct picture movie pathwaydb );


my %tableToTag;
# $tableToTag{"process"}   = 'WBProcess';
# $tableToTag{"goid"}        = 'GO_term';
$tableToTag{"wbgene"}      = 'Gene';
$tableToTag{"phenotype"}   = 'Phenotype';
$tableToTag{"molecule"}    = 'Molecule';
$tableToTag{"anatomy"}     = 'Anatomy_term';
$tableToTag{"lifestage"}   = 'Life_stage';
$tableToTag{"taxon"}       = 'NCBITaxonomyID';
$tableToTag{"exprcluster"} = 'Expression_cluster';
$tableToTag{"construct"}   = 'Marker_construct';
$tableToTag{"picture"}     = 'Picture';
$tableToTag{"movie"}       = 'Movie';
$tableToTag{"pathwaydb"}   = 'Database';
$tableToTag{"paper"}       = 'Reference';

my %tableType;
# $tableType{"goid"}        = 'multi';
$tableType{"wbgene"}      = 'multi';
$tableType{"phenotype"}   = 'multi';
$tableType{"molecule"}    = 'multi';
$tableType{"anatomy"}     = 'multi';
$tableType{"lifestage"}   = 'multi';
$tableType{"taxon"}       = 'multi';
$tableType{"exprcluster"} = 'multi';
$tableType{"construct"}   = 'multi';
$tableType{"picture"}     = 'multi';
$tableType{"movie"}       = 'text';
$tableType{"pathwaydb"}   = 'noquote';
$tableType{"paper"}       = 'single';

my %addEvi;
# $addEvi{"goid"}        = 'paper';
$addEvi{"wbgene"}      = 'paper';
$addEvi{"phenotype"}   = 'paper';
$addEvi{"molecule"}    = 'paper';
$addEvi{"anatomy"}     = 'paper';
$addEvi{"lifestage"}   = 'paper';
$addEvi{"taxon"}       = '';
$addEvi{"exprcluster"} = 'paper';
$addEvi{"construct"}   = '';
$addEvi{"picture"}     = 'paper';
$addEvi{"movie"}       = 'paper';
$addEvi{"pathwaydb"}   = '';

my $all_entry = '';
# my $allmolecule_entry = '';
my $err_text = '';

my %deadObjects; 				# dead objects

my %existing_evidence;				# existing wbpersons and wbpapers
&populateExistingEvidence();

my %dropdown;
&populateDropdown();

my %nameToIDs;							# type -> name -> ids -> count
my %ids;


sub getProcessCuration {
  my ($flag) = shift;

  &populateDeadObjects();

#   if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM pro_process;" ); }				# get all entries 
#     else {  $result = $dbh->prepare( "SELECT * FROM pro_process WHERE pro_process ~ '$flag';" ); }		# get all entries that match the name
  if ( $flag eq 'all' ) { $result = $dbh->prepare( "SELECT * FROM pro_process WHERE joinkey NOT IN (SELECT joinkey FROM pro_falsepositive) AND joinkey NOT IN (SELECT joinkey FROM pro_curator WHERE pro_curator = 'WBPerson11187') AND joinkey NOT IN (SELECT joinkey FROM pro_topicpaperstatus WHERE pro_topicpaperstatus = 'irrelevant' OR pro_topicpaperstatus = 'unchecked');" ); }				# get all entries 
    else {  $result = $dbh->prepare( "SELECT * FROM pro_process WHERE pro_process ~ '$flag' AND joinkey NOT IN (SELECT joinkey FROM pro_falsepositive) AND joinkey NOT IN (SELECT joinkey FROM pro_curator WHERE pro_curator = 'WBPerson11187') AND joinkey NOT IN (SELECT joinkey FROM pro_topicpaperstatus WHERE pro_topicpaperstatus = 'irrelevant' OR pro_topicpaperstatus = 'unchecked');" ); }		# get all entries that match the name
  $result->execute();	
  while (my @row = $result->fetchrow) { $theHash{'process'}{$row[0]} = $row[1]; $nameToIDs{'process'}{$row[1]}{$row[0]}++; $ids{$row[0]}++; }
  my $ids = ''; my $qualifier = '';
  if ($flag ne 'all') { $ids = join"','", sort keys %ids; $qualifier = "WHERE joinkey IN ('$ids')"; }
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM pro_$table $qualifier;" );		# get data for table with qualifier (or not if not)
    $result->execute();	
    while (my @row = $result->fetchrow) { $theHash{$table}{$row[0]} = $row[1]; }
  } # foreach my $table (@tables)

  foreach my $name (sort keys %{ $nameToIDs{'process'} }) {
    my $entry = '';
    $entry .= "WBProcess : \"$name\"\n";				# added pgid for debugging  2010 08 25

    foreach my $joinkey (sort {$a<=>$b} keys %{ $nameToIDs{'process'}{$name} }) {
      my $cur_entry = '';
      my $evidence = ''; ($evidence) = &getEvidence($joinkey);	# get the evidence multi-line for the joinkey and box

      foreach my $table (@tables) {
        next unless $tableToTag{$table};
        my $tag = $tableToTag{$table};
        my $dataRef = &getData($table, $joinkey);
        my @data = @$dataRef;
        foreach my $data (@data) {
          if ($data) { 
            if ($addEvi{$table}) { $cur_entry .= &addEvi($evidence, "$tag\t$data"); }
              else { $cur_entry .= "$tag\t$data\n"; } } }
      }
      if ($cur_entry) { $entry .= $cur_entry; }		# create the ace entry
    }

    if ($entry) { $all_entry .= "$entry\n"; }                  # if .ace object requires a tag, add check here
  } # foreach my $name (sort keys %{ $nameToIDs{'process'} })

  return( $all_entry, $err_text );
} # sub getProcessCuration


sub getData {
  my ($table, $joinkey) = @_;
  my $data = '';
  my @return_vals; 
  if ($theHash{$table}{$joinkey}) {
    $data = $theHash{$table}{$joinkey};
      if ($tableType{$table} eq 'multi' ) {
        if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
        if ($data =~ m/\",\"/) {
          my @data = split/\",\"/, $data; 
          foreach my $data (@data) {
            ($data) = &stripForAce($data);
            if ( ($table eq 'wbgene') && ( $deadObjects{gene}{"suppressed"}{$data} || $deadObjects{gene}{"mapto"}{$data} || $deadObjects{gene}{"dead"}{$data} || $deadObjects{gene}{"split"}{$data} ) ) { $err_text .= qq($data is not currently live and is not being dumped\n); next ; }	# skip dead genes and add to error message
            if ( $dropdown{$table}{$data} ) { 
#                 if ($table eq 'lifestage') { $data = $dropdown{$table}{$data}; }	# lifestage stored as IDs now, no need to change 2013 06 12
                push @return_vals, '"' . $data . '"'; }
              else { $err_text .= '//// ' . "$data in ID $joinkey and table $table not a valid term in obo\n"; } } }
          else { push @return_vals, '"' . $data . '"'; } }
      elsif ($tableType{$table} eq 'pipe' ) {
        my @data = split/\|/, $data; 
        foreach my $data (@data) { 
          ($data) = &stripForAce($data);
          push @return_vals, '"' . $data . '"'; } }
      elsif ($tableType{$table} eq 'noquote' ) {
        push @return_vals, $data; }
      elsif ($tableType{$table} eq 'single' ) {
        push @return_vals, '"' . $data . '"'; }
      else  { 
        ($data) = &stripForAce($data);
        push @return_vals, '"' . $data . '"'; }
  }
  return \@return_vals;
} # sub getData

sub stripForAce {
  my ($data) = @_;
  if ($data =~ m//) { $data =~ s///g; }
  if ($data =~ m/\n/) { $data =~ s/\n/  /g; }
  if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
  if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
  return $data;
} # sub stripForAce


sub addEvi {				# append evidence hash to a line, making it a multi-line line
  my ($evidence, $line) = @_; my $tag_data;
  chomp $line;
  my $line_ts = 0;
  if ($line =~ m/\-O \"[\d]{4}/) { 		# if the line has acedb timestamps
    $tag_data .= "$line\n";			# always print it without evidence (as well as with matching evidence later)
    $line_ts++; }				# flag it to have timestamp
  if ($evidence) {
      my @evidences = split/\n/, $evidence;			# break multi-line evidence into evidence array
      foreach my $evi (@evidences) { 
#         $tag_data .= "$line\t$evi\n"; 
        if ($evi =~ m/Curator_confirmed/) { 	# if curator evidence, check that their acedb timestamp state matches
            my $evi_ts = 0; 
            if ($evi =~ m/\-O\s+\"[\d]{4}/) { $evi_ts++; }			# flag if evidence has timestamp
            if ($evi_ts && $line_ts) { $tag_data .= "$line\t$evi\n"; }		# append lines without timestamp if evidence is without timestamp 
            if (!$evi_ts && !$line_ts) { $tag_data .= "$line\t$evi\n"; }	# append lines with timestamp if evidence is with timestamp 
          }
          else { $tag_data .= "$line\t$evi\n"; }				# always append person and paper evidence
      }
      return $tag_data; }
    else { return "$line\n"; }
} # sub addEvi


sub getEvidence {
  my ($joinkey) = @_; my $evidence;
  if ($theHash{curator}{$joinkey}) { 
    $evidence .= "Curator_confirmed\t\"$theHash{curator}{$joinkey}\"\n"; }
  if ($theHash{person}{$joinkey}) { 
    my @people = split/,/, $theHash{person}{$joinkey};				# break up into people if more than one person
    foreach my $person (@people) { 
      my ($check_evi) = $person =~ m/WBPerson(\d+)/; 
      unless ($check_evi) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
      unless ($existing_evidence{person}{$check_evi}) { $evidence .= "//// ERROR Person $person NOT a valid person\n"; next ; }
      $person =~ s/^\s+//g; $evidence .= "Person_evidence\t$person\n"; } }	# already has doublequotes in DB because of phenote 2008 01 30

  if ($theHash{paper}{$joinkey}) {
    if ($theHash{paper}{$joinkey} =~ m/WBPaper\d+/) { 
        my ($check_evi) = $theHash{paper}{$joinkey} =~ m/WBPaper(\d+)/;
        if ($existing_evidence{paper}{$check_evi}) {
            $evidence .= "Paper_evidence\t\"WBPaper$check_evi\"\n"; } 	# 2006 08 23 get the WBPaper, not the data with comments
          else { $evidence .= "//// ERROR Paper $theHash{paper}{$joinkey} NOT a valid paper\n"; } }
      else { $err_text .= '//// ' . "$joinkey has bad paper data $theHash{paper}{$joinkey}\n"; return "ERROR"; } }
  if ($evidence) { return $evidence; }
} # sub getEvidence

sub populateExistingEvidence {		# get hash of valid wbpersons and wbpapers
  my $result = $dbh->prepare( "SELECT * FROM two ORDER BY two" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    $existing_evidence{person}{$row[1]}++; }
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute();			# papers now in pap tables, not wpa  2010 08 25
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $existing_evidence{paper}{$row[0]}++; } }
} # sub populateExistingEvidence




sub populateDropdown {
  $result = $dbh->prepare( "SELECT * FROM obo_name_lifestage" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{lifestage}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
  $result->execute();			# get from obo_ table instead of obsolete .obo file
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{anatomy}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM mop_name" );
  $result->execute();			# papers now in pap tables, not wpa  2010 08 25
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{molecule}{$row[1]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_phenotype" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{phenotype}{$row[0]} = $row[1]; } }

#   $result = $dbh->prepare( "SELECT * FROM obo_name_goid" );
#   $result->execute();
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $dropdown{goid}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_taxon" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{taxon}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM obo_name_exprcluster" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{exprcluster}{$row[0]} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{wbgene}{"WBGene$row[0]"} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM pic_name" );
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $dropdown{wbgene}{$row[1]} = $row[1]; } }

} # sub populateDropdown

sub populateDeadObjects {
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
#   while (my @row = $result->fetchrow) { $deadObjects{gene}{"WBGene$row[0]"} = $row[1]; }
  while (my @row = $result->fetchrow) {			# Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21	This datatype doesn't dump historical_gene, so maybe Karen doesn't care.
    if ($row[1] =~ m/split_into (WBGene\d+)/) {		$deadObjects{gene}{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) {	$deadObjects{gene}{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {		$deadObjects{gene}{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {			$deadObjects{gene}{"dead"}{"WBGene$row[0]"} = $row[1]; } }
#   while (my @row = $result->fetchrow) {               # previously gin_dead only had "Dead" or "merged_into / split_into", now it can have all 3 plus Suppressed, so redoing it based on priorities set by Chris
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



sub filterAce {
  my $identifier = shift;
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/:/) { $identifier =~ s/:/\\:/g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/,/) { $identifier =~ s/,/\\,/g; }
  if ($identifier =~ m/-/) { $identifier =~ s/-/\\-/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  return $identifier;
} # sub filterAce


1;


__END__

