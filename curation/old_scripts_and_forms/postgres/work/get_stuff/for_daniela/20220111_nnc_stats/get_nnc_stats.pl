#!/usr/bin/perl -w

# query like the curation statistics page, but restrict to 4 datatypes and pap_year
# for Daniela and Kimberly  2022 01 11


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Tie::IxHash;                                # allow hashes ordered by item added
use Math::SigFigs;                              # significant figures $new = FormatSigFigs($n, $d);

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $datatypeSource = 'caltech';

my %chosenDatatypes;            # selected datatypes to display
my %chosenPapers;               # selected papers to display
my %curatablePapers;            # paper joinkeys that are curatable.  $curatablePapers{joinkey} = valid
my %oaData;                     # curator PG data from OA or other pg tables            $oaData{datatype}{joinkey} = 'positive';
my %curData;                    # curator PG data from cur_curdata table                $curData{datatype}{joinkey}{curator/donposneg/selcomment/txtcomment/timestamp} = value
my %objsCurated;                # datatype-object curated                               $objsCurated{$datatype}{$objName}++;
my %conflict;                   # datatype-paper has curator conflict                   $conflict{$datatype}{$joinkey}++;
my %validated;                  # datatype-paper validated                              $validated{$datatype}{$joinkey} = $value;
my %valCur;                     # datatype-paper validated as curated                   $valCur{$datatype}{$joinkey} = $value;
my %valPos;                     # datatype-paper validated as positive                  $valPos{$datatype}{$joinkey} = $value;
my %valNeg;                     # datatype-paper validated as negative                  $valNeg{$datatype}{$joinkey} = $value;
my %nncData;                    # nnc results by datatype-joinkey                       $nncData{$datatype}{$joinkey} = $nncdata;
my %curStats; tie %curStats, "Tie::IxHash";     # hash of curation statistics           $curStats{'cfp'}{'pos'}{$datatype}{papers}{$joinkey}++; $curStats{'cfp'}{'pos'}{$datatype}{'countPap'} = count; $curStats{'cfp'}{'pos'}{$datatype}{'ratio'}    = ratio;

$chosenPapers{all}++;

# "nnc hig val tp"

my @datatypes = qw( catalyticact 	geneprod 	otherexpr 	rnai );
# my @datatypes = qw( geneprod );
# my @datatypes = qw( catalyticact );

my %toPrint;
for my $i (reverse (1900 .. 2022)) {
  %curatablePapers = ();
  %validated = ();
  %valCur = ();
  %valPos = ();
  %valNeg = ();
  &populateCuratablePapers($i);
  &populateCuratedPapers();
  &populateNncData(); 
  &getCurationStatisticsNnc($i);
}
foreach my $datatype (sort keys %toPrint) {
  print qq($datatype\n);
  foreach my $year (sort keys %{ $toPrint{$datatype} }) {
    print qq($year\n$toPrint{$datatype}{$year}\n);
  } # foreach my $year (sort keys %{ $toPrint{$datatype} })
  print qq(\n);
}

sub getCurationStatisticsNnc {
  my $year = shift;
  my %nncNeg; my %nncNegNV; my %nncNegVal; my %nncNegTN; my %nncNegFN; my %nncNegFnCur; my %nncNegFnNC; my %nncNegNC;
        # positive : flagged, not validated, validated, false positive, true positive, TP curated, TP not curated, not curated minus validated negative OR not validated + TP not curated
  my %nncPos; my %nncPosNV; my %nncPosVal; my %nncPosFP; my %nncPosTP; my %nncPosTpCur; my %nncPosTpNC; my %nncPosNC;
  my %nncHig; my %nncHigNV; my %nncHigVal; my %nncHigTP; my %nncHigFP; my %nncHigTpCur; my %nncHigTpNC; my %nncHigNC;
  my %nncMed; my %nncMedNV; my %nncMedVal; my %nncMedTP; my %nncMedFP; my %nncMedTpCur; my %nncMedTpNC; my %nncMedNC;
  my %nncLow; my %nncLowNV; my %nncLowVal; my %nncLowTP; my %nncLowFP; my %nncLowTpCur; my %nncLowTpNC; my %nncLowNC;

  foreach my $datatype (@datatypes) {
    foreach my $joinkey (keys %{ $nncData{$datatype} }) {
      my $nncVal = $nncData{$datatype}{$joinkey};
      if ($nncVal eq 'NEG') {
        $nncNeg{$datatype}{$joinkey}++;
        if ($valNeg{$datatype}{$joinkey}) {      $nncNegTN{$datatype}{$joinkey}++; $nncNegVal{$datatype}{$joinkey}++; }
          elsif ($valPos{$datatype}{$joinkey}) { $nncNegFN{$datatype}{$joinkey}++; $nncNegVal{$datatype}{$joinkey}++;
            if ($valCur{$datatype}{$joinkey}) {  $nncNegFnCur{$datatype}{$joinkey}++; }
              else                            {  $nncNegFnNC{$datatype}{$joinkey}++; $nncNegNC{$datatype}{$joinkey}++; } }
          else {                                 $nncNegNV{$datatype}{$joinkey}++; $nncNegNC{$datatype}{$joinkey}++; } }
      elsif ($nncVal eq 'LOW') {
        $nncPos{$datatype}{$joinkey}++; $nncLow{$datatype}{$joinkey}++;
        if ($valNeg{$datatype}{$joinkey}) {      $nncPosVal{$datatype}{$joinkey}++; $nncPosFP{$datatype}{$joinkey}++;
                                                 $nncLowVal{$datatype}{$joinkey}++; $nncLowFP{$datatype}{$joinkey}++; }
          elsif ($valPos{$datatype}{$joinkey}) { $nncPosVal{$datatype}{$joinkey}++; $nncPosTP{$datatype}{$joinkey}++;
                                                 $nncLowVal{$datatype}{$joinkey}++; $nncLowTP{$datatype}{$joinkey}++;
            if ($valCur{$datatype}{$joinkey}) {  $nncPosTpCur{$datatype}{$joinkey}++; $nncLowTpCur{$datatype}{$joinkey}++; }
              else                            {   $nncPosTpNC{$datatype}{$joinkey}++; $nncPosNC{$datatype}{$joinkey}++;
                                                  $nncLowTpNC{$datatype}{$joinkey}++; $nncLowNC{$datatype}{$joinkey}++; } }
          else {                                  $nncPosNV{$datatype}{$joinkey}++; $nncLowNV{$datatype}{$joinkey}++;
                                                  $nncPosNC{$datatype}{$joinkey}++; $nncLowNC{$datatype}{$joinkey}++; } }
      elsif ($nncVal eq 'MEDIUM') {
        $nncPos{$datatype}{$joinkey}++; $nncMed{$datatype}{$joinkey}++;
        if ($valNeg{$datatype}{$joinkey}) {      $nncPosVal{$datatype}{$joinkey}++; $nncPosFP{$datatype}{$joinkey}++;
                                                 $nncMedVal{$datatype}{$joinkey}++; $nncMedFP{$datatype}{$joinkey}++; }
          elsif ($valPos{$datatype}{$joinkey}) { $nncPosVal{$datatype}{$joinkey}++; $nncPosTP{$datatype}{$joinkey}++;
                                                 $nncMedVal{$datatype}{$joinkey}++; $nncMedTP{$datatype}{$joinkey}++;
            if ($valCur{$datatype}{$joinkey}) {  $nncPosTpCur{$datatype}{$joinkey}++; $nncMedTpCur{$datatype}{$joinkey}++; }
              else                            {   $nncPosTpNC{$datatype}{$joinkey}++; $nncPosNC{$datatype}{$joinkey}++;
                                                  $nncMedTpNC{$datatype}{$joinkey}++; $nncMedNC{$datatype}{$joinkey}++; } }
          else {                                  $nncPosNV{$datatype}{$joinkey}++; $nncMedNV{$datatype}{$joinkey}++;
                                                  $nncPosNC{$datatype}{$joinkey}++; $nncMedNC{$datatype}{$joinkey}++; } }
      elsif ($nncVal eq 'HIGH') {
        $nncPos{$datatype}{$joinkey}++; $nncHig{$datatype}{$joinkey}++;
        if ($valNeg{$datatype}{$joinkey}) {      $nncPosVal{$datatype}{$joinkey}++; $nncPosFP{$datatype}{$joinkey}++;
                                                 $nncHigVal{$datatype}{$joinkey}++; $nncHigFP{$datatype}{$joinkey}++; }
          elsif ($valPos{$datatype}{$joinkey}) { $nncPosVal{$datatype}{$joinkey}++; $nncPosTP{$datatype}{$joinkey}++;
                                                 $nncHigVal{$datatype}{$joinkey}++; $nncHigTP{$datatype}{$joinkey}++;
            if ($valCur{$datatype}{$joinkey}) {  $nncPosTpCur{$datatype}{$joinkey}++; $nncHigTpCur{$datatype}{$joinkey}++; }
              else                            {   $nncPosTpNC{$datatype}{$joinkey}++; $nncPosNC{$datatype}{$joinkey}++;
                                                  $nncHigTpNC{$datatype}{$joinkey}++; $nncHigNC{$datatype}{$joinkey}++; } }
          else {                                  $nncPosNV{$datatype}{$joinkey}++; $nncHigNV{$datatype}{$joinkey}++;
                                                  $nncPosNC{$datatype}{$joinkey}++; $nncHigNC{$datatype}{$joinkey}++; } }
  } }

#   my $blah = join", ", sort keys %{ $valPos{'geneprod'} };
#   print qq(BLAH $blah\n);

  my $countCuratablePapers = scalar keys %curatablePapers;

  tie %{ $curStats{'nnc'} }, "Tie::IxHash";
  tie %{ $curStats{'nnc'}{'pos'} }, "Tie::IxHash";
  tie %{ $curStats{'nnc'}{'hig'} }, "Tie::IxHash";
  tie %{ $curStats{'nnc'}{'med'} }, "Tie::IxHash";
  tie %{ $curStats{'nnc'}{'low'} }, "Tie::IxHash";
  tie %{ $curStats{'nnc'}{'neg'} }, "Tie::IxHash";

#   print qq(Year $year\n);
  foreach my $datatype (@datatypes) {
#     print qq($datatype\n);
    my $countNncHigVal  = scalar keys %{ $nncHigVal{$datatype} };
    my $countNncHigTP  = scalar keys %{ $nncHigTP{$datatype} };
    my $ratio = 0;
    if ($countNncHigVal > 0) { $ratio = $countNncHigTP / $countNncHigVal * 100; $ratio = FormatSigFigs($ratio, 2); }
    foreach my $joinkey (keys %{ $nncHigTP{$datatype} }) { $curStats{'nnc'}{'hig'}{'val'}{'tp'}{$datatype}{papers}{$joinkey}++; }
    $curStats{'nnc'}{'hig'}{'val'}{'tp'}{$datatype}{'countPap'} = scalar keys %{ $nncHigTP{$datatype} };
    $curStats{'nnc'}{'hig'}{'val'}{'tp'}{$datatype}{'ratio'}    = $ratio;
    $toPrint{$datatype}{$year} .= qq('NN positive high validated true positive' $curStats{'nnc'}{'hig'}{'val'}{'tp'}{$datatype}{'countPap'} $ratio%\n);
    my $paps = join", WBPaper", sort keys %{ $nncHigTP{$datatype} };
    $toPrint{$datatype}{$year} .= qq(WBPaper$paps\n);

    my $countNncMedVal  = scalar keys %{ $nncMedVal{$datatype} };
    my $countNncMedTP  = scalar keys %{ $nncMedTP{$datatype} };
    $ratio = 0;
    if ($countNncMedVal > 0) { $ratio = $countNncMedTP / $countNncMedVal * 100; $ratio = FormatSigFigs($ratio, 2); }
    foreach my $joinkey (keys %{ $nncMedTP{$datatype} }) { $curStats{'nnc'}{'med'}{'val'}{'tp'}{$datatype}{papers}{$joinkey}++; }
    $curStats{'nnc'}{'med'}{'val'}{'tp'}{$datatype}{'countPap'} = scalar keys %{ $nncMedTP{$datatype} };
    $curStats{'nnc'}{'med'}{'val'}{'tp'}{$datatype}{'ratio'}    = $ratio;
    $toPrint{$datatype}{$year} .= qq('NN positive medium validated true positive' $curStats{'nnc'}{'med'}{'val'}{'tp'}{$datatype}{'countPap'} $ratio%\n);
    $paps = join", WBPaper", sort keys %{ $nncMedTP{$datatype} };
    $toPrint{$datatype}{$year} .= qq(WBPaper$paps\n);

    my $countNncLowVal  = scalar keys %{ $nncLowVal{$datatype} };
    my $countNncLowTP  = scalar keys %{ $nncLowTP{$datatype} };
    $ratio = 0;
    if ($countNncLowVal > 0) { $ratio = $countNncLowTP / $countNncLowVal * 100; $ratio = FormatSigFigs($ratio, 2); }
    foreach my $joinkey (keys %{ $nncLowTP{$datatype} }) { $curStats{'nnc'}{'low'}{'val'}{'tp'}{$datatype}{papers}{$joinkey}++; }
    $curStats{'nnc'}{'low'}{'val'}{'tp'}{$datatype}{'countPap'} = scalar keys %{ $nncLowTP{$datatype} };
    $curStats{'nnc'}{'low'}{'val'}{'tp'}{$datatype}{'ratio'}    = $ratio;
    $toPrint{$datatype}{$year} .= qq('NN positive low validated true positive' $curStats{'nnc'}{'low'}{'val'}{'tp'}{$datatype}{'countPap'} $ratio%\n);
    $paps = join", WBPaper", sort keys %{ $nncLowTP{$datatype} };
    $toPrint{$datatype}{$year} .= qq(WBPaper$paps\n);

#     print qq(\n);
  }
#   print qq(\n);

# "nnc hig val tp"
} # sub getCurationStatisticsNnc

sub populateCuratablePapers {
  my $year = shift;
  my %papersByTaxon;
  my @caltechTaxonIDs = qw( 6239 860376 135651 6238 6239 281687 1611254 31234 497829 1561998 1195656 54126 );
  my $caltechTaxonIDs = join"','", @caltechTaxonIDs;
  my $query = "SELECT * FROM pap_species WHERE pap_species IN ('$caltechTaxonIDs') AND joinkey IN (SELECT joinkey FROM pap_year WHERE pap_year = '$year')";
#   if ($datatypeSource eq 'parasite') {
#     $query = "SELECT * FROM pap_species WHERE pap_species NOT IN ('$caltechTaxonIDs')"; }
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $papersByTaxon{$row[0]} = $row[1]; }
  $query = "SELECT * FROM pap_status WHERE pap_status = 'valid' AND joinkey IN (SELECT joinkey FROM pap_primary_data WHERE pap_primary_data = 'primary') AND joinkey NOT IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode') AND joinkey NOT IN (SELECT joinkey FROM pap_type WHERE pap_type = '15')";
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($papersByTaxon{$row[0]});          # skip papers that are not in list of caltech taxon IDs
    $curatablePapers{$row[0]} = $row[1]; }
#   my $blah = join", ", sort keys %curatablePapers;
#   print qq(curatablePapers $blah\n);
} # sub populateCuratablePapers

sub populateCuratedPapers {
  my ($showTimes, $start, $end, $diff) = (0, '', '', '');
  if ($showTimes) { $start = time; }
  &populateCurCurData();
  if ($showTimes) { $end = time; $diff = $end - $start; $start = time; print "IN populateCuratedPapers  populateCurCurData $diff<br>"; }
  &populateOaData();                                            # $oaData{datatype}{joinkey} = 'positive';
  if ($showTimes) { $end = time; $diff = $end - $start; $start = time; print "IN populateCuratedPapers  populateOaData $diff<br>"; }
  my %allCuratorValues;                 # $allCuratorValues{datatype}{joinkey} = 0 | 1+
  foreach my $datatype (sort keys %oaData) {
    foreach my $joinkey (sort keys %{ $oaData{$datatype} }) {
      $allCuratorValues{$joinkey}{$datatype}{curated}++; } }            # validated positive and curated
  foreach my $datatype (sort keys %curData) {
    foreach my $joinkey (sort keys %{ $curData{$datatype} }) {
      $allCuratorValues{$joinkey}{$datatype}{ $curData{$datatype}{$joinkey}{donposneg} }++; } }
  foreach my $joinkey (sort keys %allCuratorValues) {
    next unless ($curatablePapers{$joinkey});
    foreach my $datatype (sort keys %{ $allCuratorValues{$joinkey} }) {
      my @values = keys %{ $allCuratorValues{$joinkey}{$datatype} };
      $validated{$datatype}{$joinkey}++;
      if (scalar @values < 2) {                 # only one value, categorize it
          my $value = $values[0];
          if ($value eq 'curated') {       $valPos{$datatype}{$joinkey} = $value; $valCur{$datatype}{$joinkey} = $value; }
            elsif ($value eq 'positive') { $valPos{$datatype}{$joinkey} = $value; }
            elsif ($value eq 'negative') { $valNeg{$datatype}{$joinkey} = $value; } }
        elsif (scalar @values == 2) {           # only two values, either ok or conflict
            if ( ($allCuratorValues{$joinkey}{$datatype}{'curated'}) && ($allCuratorValues{$joinkey}{$datatype}{'positive'}) ) {        # positive + curated not a conflict, for Chris 2013 06 12
                $valPos{$datatype}{$joinkey} = 'positive'; $valCur{$datatype}{$joinkey} = 'curated'; }
              else { $conflict{$datatype}{$joinkey}++; } }
        else { $conflict{$datatype}{$joinkey}++; }
  } }
  if ($showTimes) { $end = time; $diff = $end - $start; $start = time; print "IN populateCuratedPapers  categorizing hash $diff<br>"; }
#   my $blah = join", ", sort keys %{ $valPos{'geneprod'} };
#   print qq(BLAH $blah\n);
} # sub populateCuratedPapers

sub populateNncData {
  # for statistics page
#     $result = $dbh->prepare( "SELECT * FROM cur_nncdata ORDER BY cur_datatype, cur_date" );   # always doing for all datatypes vs looping for chosen takes 4.66vs 2.74 secs
  foreach my $datatype (@datatypes) {
    $result = $dbh->prepare( "SELECT * FROM cur_nncdata WHERE cur_datatype = '$datatype' ORDER BY cur_date" );
      # table stores multiple dates for same paper-datatype in case we want to see multiple results later.  if it didn't and we didn't order it would take 2.05 vs 2.74 secs, so not worth changing the way we're storing data
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      my $joinkey = $row[0]; my $nncdata = $row[3];
# print qq(BEFORE $joinkey\n);
      next unless ($curatablePapers{$row[0]});
# print qq(AFTER $joinkey\n);
      $nncData{$datatype}{$joinkey} = $nncdata; } }
#   my $blah = join", ", sort keys %{ $nncData{'geneprod'} };
#   print qq(BLAH $blah\n);
} # sub populateNncData

sub populateCurCurData {
  $result = $dbh->prepare( "SELECT * FROM cur_curdata WHERE cur_site = '$datatypeSource' ORDER BY cur_timestamp" );     # in case multiple values get in for a paper-datatype (shouldn't happen), keep the latest
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($chosenPapers{$row[0]} || $chosenPapers{all});
#     next unless ($chosenDatatypes{$row[1]});
    next if ( ($row[4] eq 'notvalidated') || ($row[4] eq '') );                                         # skip entries marked as notvalidated
    $curData{$row[1]}{$row[0]}{site}       = $row[2];
    $curData{$row[1]}{$row[0]}{curator}    = $row[3];
    $curData{$row[1]}{$row[0]}{donposneg}  = $row[4];
    $curData{$row[1]}{$row[0]}{selcomment} = $row[5];
    $curData{$row[1]}{$row[0]}{txtcomment} = $row[6];
    $curData{$row[1]}{$row[0]}{timestamp}  = $row[7]; }
#   my $blah = join", ", sort keys %curData;
#   print qq(BLAH $blah\n);
} # sub populateCurCurData


sub populateOaData {
  return unless ($datatypeSource eq 'caltech');

  # no catalyticact OA data

  $result = $dbh->prepare( "SELECT * FROM int_name WHERE joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical' OR int_type = 'ProteinProtein' OR int_type = 'ProteinDNA' OR int_type = 'ProteinRNA') AND joinkey NOT IN (SELECT joinkey FROM int_nodump)" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $objsCurated{'geneprod'}{$row[1]}++; }
  $result = $dbh->prepare( "SELECT * FROM int_paper WHERE joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical' OR int_type = 'ProteinProtein' OR int_type = 'ProteinDNA' OR int_type = 'ProteinRNA') AND joinkey NOT IN (SELECT joinkey FROM int_nodump)" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
    foreach my $paper (@papers) {
      $oaData{'geneprod'}{$paper} = 'curated'; } }

  $result = $dbh->prepare( "SELECT * FROM exp_name WHERE joinkey NOT IN (SELECT joinkey FROM exp_nodump)" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $objsCurated{'otherexpr'}{$row[1]}++; }
  $result = $dbh->prepare( "SELECT * FROM exp_paper WHERE joinkey NOT IN (SELECT joinkey FROM exp_nodump)" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
    foreach my $paper (@papers) {
      $oaData{'otherexpr'}{$paper} = 'curated'; } }

  $result = $dbh->prepare( "SELECT * FROM rna_name WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump)" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $objsCurated{'rnai'}{$row[1]}++; }
  $result = $dbh->prepare( "SELECT * FROM rna_paper WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey NOT IN (SELECT joinkey FROM rna_curator WHERE rna_curator = 'WBPerson29819')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
    foreach my $paper (@papers) {
      $oaData{'rnai'}{$paper} = 'curated'; } }
} # sub populateOaData



__END__

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

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

