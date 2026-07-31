#!/usr/bin/env perl

# Export cur_curdata entries whose cur_curdata value is 'curated' (displayed as
# "curated and positive" in curation_status.cgi) but whose paper-datatype has no
# OA curation data, so curation_status.cgi would show 'oa_blank' for the OA column.
#
# The oa_blank determination replicates &populateOaData from
# curation/website/priv/cgi-bin/curation_status.cgi  (a paper-datatype is oa_blank
# when populateOaData does not set $oaData{datatype}{paper}).
#
# All datatypes are included, not only the ones &populateOaData has an OA source
# for, because curation_status.cgi shows oa_blank for any row it does not have OA
# data for, including datatypes that have no OA source at all.  For the curator
# 2026 07 30.  The oa_source column flags which is which, 1 when the datatype has
# an OA source and this paper is missing from it, 0 when the datatype has no OA
# source so every paper of that datatype is oa_blank.
#
# Output is tab delimited :
#   cur_paper  cur_datatype  atp  cur_curator  cur_selcomment  cur_txtcomment
#   cur_timestamp  oa_source  in_curation_status
#
# Entries whose cur_datatype has no ATP mapping are kept out of the .tsv and go to
# the .skipped file with an atp_unmapped reason instead, for the curator 2026 07 31.
# The datatypes involved are reported to STDOUT and to the .unmapped_datatypes file.
#
# CC wrote this script
# https://agr-jira.atlassian.net/browse/SCRUM-6130
#
# 2026 07 29


use strict;
use diagnostics;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $datatypeSource = 'caltech';		# curation_status.cgi only computes OA data for caltech

my $date = &getSimpleSecDate();

my $outfile = 'curated_positive_oa_blank.' . $date . '.tsv';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $skipfile = 'curated_positive_oa_blank.' . $date . '.skipped';	# entries matching, but that curation_status.cgi would not display
open (SKIP, ">$skipfile") or die "Cannot create $skipfile : $!";

my $unmappedfile = 'curated_positive_oa_blank.' . $date . '.unmapped_datatypes';

my $nooafile = 'curated_positive_oa_blank.' . $date . '.datatypes_without_oa_source';

my %datatypes;				# all allowed datatypes, from &populateDatatypes
my %datatypesAfpCfp;
my %oaDatatypes;			# datatypes &populateOaData has an OA source for
my %oaData;				# $oaData{datatype}{paper} = 'curated'
my %curatablePapers;			# papers curation_status.cgi will display
my %datatypeToAtp;			# cur_datatype to ATP term
my %unmappedDatatypes;			# cur_datatype values queried without an ATP mapping
my %noOaSourceDatatypes;		# oa_blank entries whose datatype has no OA source at all
my %premadeComments;			# cur_selcomment number to text, from &populatePremadeComments
my %unmappedSelcomments;		# cur_selcomment values without a premade comment text
my %seenDatatypes;			# every cur_datatype seen in cur_curdata, for the unused mapping check

&populateDatatypeToAtp();
&populatePremadeComments();
&populateDatatypes();
&populateCuratablePapers();
&populateOaData();

my $total_curated  = 0;
my $oa_blank_count = 0;
my $skipped_count  = 0;
my $atp_unmapped_count = 0;

print OUT join("\t", qw( cur_paper cur_datatype atp cur_curator cur_selcomment cur_txtcomment cur_timestamp oa_source in_curation_status )) . "\n";
print SKIP join("\t", qw( skip_reason cur_paper cur_datatype atp cur_curator cur_selcomment cur_txtcomment cur_timestamp oa_source in_curation_status )) . "\n";

my %curatedRows;			# $curatedRows{paper}{datatype} = \@row , keep latest timestamp like &populateCurCurData
$result = $dbh->prepare( "SELECT cur_paper, cur_datatype, cur_site, cur_curator, cur_curdata, cur_selcomment, cur_txtcomment, cur_timestamp FROM cur_curdata WHERE cur_site = '$datatypeSource' AND cur_curdata = 'curated' ORDER BY cur_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  $total_curated++;
  $seenDatatypes{$row[1]}++;
  $curatedRows{$row[0]}{$row[1]} = [ @row ];
}

foreach my $paper (sort { $a <=> $b } keys %curatedRows) {
  foreach my $datatype (sort keys %{ $curatedRows{$paper} }) {
    my @row = @{ $curatedRows{$paper}{$datatype} };
    my ($cur_curator, $cur_selcomment, $cur_txtcomment, $cur_timestamp) = ($row[3], $row[5], $row[6], $row[7]);
    foreach ($cur_curator, $cur_selcomment, $cur_txtcomment, $cur_timestamp) { unless (defined $_) { $_ = ''; } }
    $cur_txtcomment =~ s/[\t\r\n]+/ /g;			# keep the output one line per entry
    my $atp = '';
    if ($datatypeToAtp{$datatype}) { $atp = $datatypeToAtp{$datatype}; }
      else { $unmappedDatatypes{$datatype}{'cur_curdata_curated'}++; }
    if ($cur_selcomment ne '') {			# show the premade comment text instead of its number, like curation_status.cgi does
      if (defined $premadeComments{$cur_selcomment}) { $cur_selcomment = $premadeComments{$cur_selcomment}; }
        else { $unmappedSelcomments{$cur_selcomment}++; } }
    my $oa_source = 0;  if ($oaDatatypes{$datatype}) { $oa_source = 1; }		# 0 means the datatype has no OA source, so every paper of it is oa_blank
    my $in_curation_status = 0;  if ($datatypes{$datatype}) { $in_curation_status = 1; }	# 0 means curation_status.cgi draws no row for this datatype
    my @outRow = ($paper, $datatype, $atp, $cur_curator, $cur_selcomment, $cur_txtcomment, $cur_timestamp, $oa_source, $in_curation_status);

    next if ($oaData{$datatype}{$paper});		# has OA data, so not oa_blank

    unless ($curatablePapers{$paper}) {			# curation_status.cgi only shows curatable papers
      $skipped_count++;
      print SKIP join("\t", "paper_not_curatable", @outRow) . "\n";
      next; }

    if ($atp eq '') {					# no ATP term for this datatype, so it only goes to the reports.  for the curator 2026 07 31
      $skipped_count++;
      $atp_unmapped_count++;
      print SKIP join("\t", "atp_unmapped", @outRow) . "\n";
      next; }

    unless ($oa_source) { $noOaSourceDatatypes{$datatype}++; }
    $oa_blank_count++;
    print OUT join("\t", @outRow) . "\n";
  } # foreach my $datatype (sort keys %{ $curatedRows{$paper} })
} # foreach my $paper (sort { $a <=> $b } keys %curatedRows)

close (OUT) or die "Cannot close $outfile : $!";
close (SKIP) or die "Cannot close $skipfile : $!";

foreach my $datatype (sort keys %datatypes) {			# datatypes curation_status.cgi draws rows for
  next if ($datatypeToAtp{$datatype});
  $unmappedDatatypes{$datatype}{'curation_status_datatypes'}++; }

my $no_oa_source_count = 0;
open (NOOA, ">$nooafile") or die "Cannot create $nooafile : $!";
print NOOA join("\t", qw( cur_datatype oa_blank_entries )) . "\n";
foreach my $datatype (sort keys %noOaSourceDatatypes) {
  $no_oa_source_count += $noOaSourceDatatypes{$datatype};
  print NOOA join("\t", $datatype, $noOaSourceDatatypes{$datatype}) . "\n"; }
close (NOOA) or die "Cannot close $nooafile : $!";

print "cur_curdata entries with cur_curdata 'curated' : $total_curated\n";
print "of those, oa_blank and displayed by curation_status.cgi : $oa_blank_count -> $outfile\n";
print "of those, oa_blank but kept out of the tsv : $skipped_count -> $skipfile\n";
print "  of those, kept out because their cur_datatype has no ATP mapping : $atp_unmapped_count\n";
print "of the oa_blank entries, from datatypes with no OA source at all (oa_source 0) : $no_oa_source_count -> $nooafile\n";
foreach my $datatype (sort keys %noOaSourceDatatypes) {
  print "cur_datatype '$datatype' has no OA source in populateOaData , so all $noOaSourceDatatypes{$datatype} of its curated entries are oa_blank\n"; }

open (UNMAPPED, ">$unmappedfile") or die "Cannot create $unmappedfile : $!";
print UNMAPPED join("\t", qw( cur_datatype source count )) . "\n";
my $unmapped_count = 0;
foreach my $datatype (sort keys %unmappedDatatypes) {
  foreach my $source (sort keys %{ $unmappedDatatypes{$datatype} }) {
    $unmapped_count++;
    print UNMAPPED join("\t", $datatype, $source, $unmappedDatatypes{$datatype}{$source}) . "\n";
    print "no ATP mapping for cur_datatype '$datatype' (from $source, $unmappedDatatypes{$datatype}{$source} entries)\n"; } }
close (UNMAPPED) or die "Cannot close $unmappedfile : $!";
unless ($unmapped_count) { print "all cur_datatype values queried have an ATP mapping\n"; }

foreach my $selcomment (sort keys %unmappedSelcomments) {	# left as the raw value in the output
  print "no premade comment text for cur_selcomment '$selcomment' ($unmappedSelcomments{$selcomment} entries)\n"; }

    # ATP mappings for datatypes that are not processed here, in case a mapping key is misspelled
my @unusedMappings;
foreach my $datatype (sort keys %datatypeToAtp) {
  next if ($datatypes{$datatype});		# a datatype curation_status.cgi draws rows for
  next if ($oaDatatypes{$datatype});		# a datatype with an OA source
  next if ($seenDatatypes{$datatype});		# a datatype that exists in cur_curdata
  push @unusedMappings, "$datatype ($datatypeToAtp{$datatype})"; }
if (scalar @unusedMappings > 0) { print "ATP mappings not matching any datatype in the database : " . join(", ", @unusedMappings) . "\n"; }


sub populatePremadeComments {		# from &populatePremadeComments in curation_status.cgi
  $premadeComments{"1"}  = "SVM Positive, Curation Negative";
  $premadeComments{"2"}  = "C. elegans as heterologous expression system";
  $premadeComments{"3"}  = "Curated for GO (by WB)";
  $premadeComments{"4"}  = "Curated for GO (by GOA)";
  $premadeComments{"5"}  = "Curated for GO (by IntAct)";
  $premadeComments{"6"}  = "Curated for BioGRID (by WB)";
  $premadeComments{"7"}  = "Curated for BioGRID (by BG)";
  $premadeComments{"8"}  = "Curated for GO (by WB), Curated for BioGRID (by WB)";
  $premadeComments{"9"}  = "Curated for GO (by WB), Curated for BioGRID (by BG)";
  $premadeComments{"10"} = "Curated for GO (by GOA), Curated for BioGRID (by WB)";
  $premadeComments{"11"} = "Curated for GO (by GOA), Curated for BioGRID (by BG)";
  $premadeComments{"12"} = "Curated for GO (by IntAct), Curated for BioGRID (by WB)";
  $premadeComments{"13"} = "Curated for GO (by IntAct), Curated for BioGRID (by BG)";
  $premadeComments{"14"} = "Curation Negative, no Strain name given in paper";
  $premadeComments{"15"} = "Toxicology";		# was "No disease models" until it was removed for Ranjana 2021 03 16, so older entries with 15 meant that
  $premadeComments{"16"} = "Host-pathogen/virulence";
  $premadeComments{"17"} = "Disease model";
  $premadeComments{"18"} = "Non-genetic disease model";
  $premadeComments{"19"} = "Genetic disease model";
} # sub populatePremadeComments

sub populateDatatypeToAtp {		# cur_datatype to ATP term, from Juancarlos 2026 07 29
  $datatypeToAtp{'antibody'}       = 'ATP:0000096';
  $datatypeToAtp{'catalyticact'}   = 'ATP:0000061';
  $datatypeToAtp{'chemicals'}      = 'ATP:0000278';
  $datatypeToAtp{'chemphen'}       = 'ATP:0000350';
  $datatypeToAtp{'seqfeature'}     = 'ATP:0000055';	# mapping list called this 'seqfeat', the database only has 'seqfeature'.  confirmed by Juancarlos 2026 07 29
  $datatypeToAtp{'disease'}        = 'ATP:0000011';
  $datatypeToAtp{'humdis'}         = 'ATP:0000152';
  $datatypeToAtp{'humandisease'}   = 'ATP:0000152';
  $datatypeToAtp{'domanal'}        = 'ATP:0000089';
  $datatypeToAtp{'envpheno'}       = 'ATP:0000351';
  $datatypeToAtp{'funccomp'}       = 'ATP:0000071';
  $datatypeToAtp{'otherexpr'}      = 'ATP:0000041';
  $datatypeToAtp{'structcorr'}     = 'ATP:0000054';
  $datatypeToAtp{'geneint'}        = 'ATP:0000068';
  $datatypeToAtp{'othergenefunc'}  = 'ATP:0000060';
  $datatypeToAtp{'genesymbol'}     = 'ATP:0000048';
  $datatypeToAtp{'overexpr'}       = 'ATP:0000084';
  $datatypeToAtp{'geneprod'}       = 'ATP:0000069';
  $datatypeToAtp{'genereg'}        = 'ATP:0000070';
  $datatypeToAtp{'rnai'}           = 'ATP:0000082';
  $datatypeToAtp{'siteaction'}     = 'ATP:0000033';
  $datatypeToAtp{'exprmosaic'}     = 'ATP:0000033';	# treated like siteaction, which is also how %datatypesAfpCfp in curation_status.cgi aliases it.  from the curator 2026 07 31
  $datatypeToAtp{'timeaction'}     = 'ATP:0000349';
  $datatypeToAtp{'transporter'}    = 'ATP:0000062';
  $datatypeToAtp{'seqchange'}      = 'ATP:0000056';
  $datatypeToAtp{'newmutant'}      = 'ATP:0000083';
} # sub populateDatatypeToAtp


sub populateDatatypes {			# from &populateDatatypes in curation_status.cgi
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_nncdata" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $datatypesAfpCfp{$row[0]} = $row[0]; }
  $datatypesAfpCfp{'chemicals'}     = 'chemicals';
  $datatypesAfpCfp{'blastomere'}    = 'cellfunc';
  $datatypesAfpCfp{'exprmosaic'}    = 'siteaction';
  $datatypesAfpCfp{'geneticmosaic'} = 'mosaic';
  $datatypesAfpCfp{'laserablation'} = 'ablationdata';
  $datatypesAfpCfp{'humandisease'}  = 'humdis';
  $datatypesAfpCfp{'rnaseq'}        = 'rnaseq';
  $datatypesAfpCfp{'chemphen'}      = 'chemphen';
  $datatypesAfpCfp{'envpheno'}      = 'envpheno';
  $datatypesAfpCfp{'timeaction'}    = 'timeaction';
  $datatypesAfpCfp{'siteaction'}    = 'siteaction';
  foreach my $datatype (keys %datatypesAfpCfp) { $datatypes{$datatype}++; }
  $datatypes{'geneticablation'}++;
  $datatypes{'picture'}++;
  $datatypes{'optogenetic'}++;
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_strdata" );	# from string search data
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $datatypes{$row[0]} = $row[0]; }
} # sub populateDatatypes

sub populateCuratablePapers {		# from &populateCuratablePapers in curation_status.cgi
  my %papersByTaxon;
  my @caltechTaxonIDs = qw( 6239 860376 135651 6238 6239 281687 1611254 31234 497829 1561998 1195656 54126 );
  my $caltechTaxonIDs = join"','", @caltechTaxonIDs;
  my $query = "SELECT * FROM pap_species WHERE pap_species IN ('$caltechTaxonIDs')";
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $papersByTaxon{$row[0]} = $row[1]; }
  $query = "SELECT * FROM pap_status WHERE pap_status = 'valid' AND joinkey IN (SELECT joinkey FROM pap_primary_data WHERE pap_primary_data = 'primary') AND joinkey NOT IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode') AND joinkey NOT IN (SELECT joinkey FROM pap_type WHERE pap_type = '15')";
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless ($papersByTaxon{$row[0]});		# skip papers that are not in list of caltech taxon IDs
    $curatablePapers{$row[0]} = $row[1]; }
} # sub populateCuratablePapers

sub populateOaData {			# from &populateOaData in curation_status.cgi, for all datatypes instead of only the chosen ones
    # chemicals : 7 sources for papers related to curated molecules, from Karen 2013 11 02
  &oaPapers('chemicals', "SELECT * FROM mop_paper");
  &oaPapers('chemicals', "SELECT * FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_molecule WHERE app_molecule IS NOT NULL AND app_molecule != '')");
  &oaPapers('chemicals', "SELECT * FROM grg_paper WHERE joinkey IN (SELECT joinkey FROM grg_moleculeregulator WHERE grg_moleculeregulator IS NOT NULL AND grg_moleculeregulator != '')");
  &oaPapers('chemicals', "SELECT * FROM pro_paper WHERE joinkey IN (SELECT joinkey FROM pro_molecule WHERE pro_molecule IS NOT NULL AND pro_molecule != '')");
  &oaPapers('chemicals', "SELECT * FROM rna_paper WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey IN (SELECT joinkey FROM rna_molecule WHERE rna_molecule IS NOT NULL AND rna_molecule != '')");
  &oaPapers('chemicals', "SELECT * FROM int_paper WHERE joinkey IN (SELECT joinkey FROM int_moleculeone WHERE int_moleculeone IS NOT NULL) OR joinkey IN (SELECT joinkey FROM int_moleculetwo WHERE int_moleculetwo IS NOT NULL) OR joinkey IN (SELECT joinkey FROM int_moleculenondir WHERE int_moleculenondir IS NOT NULL)");

  &oaPapers('newmutant', "SELECT * FROM app_paper WHERE joinkey NOT IN (SELECT joinkey FROM app_needsreview) AND joinkey NOT IN (SELECT joinkey FROM app_curator WHERE app_curator = 'WBPerson29819') AND joinkey NOT IN (SELECT joinkey FROM app_nodump)");

  &oaPapers('overexpr', "SELECT * FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_transgene WHERE app_transgene IS NOT NULL AND app_transgene != '') AND joinkey NOT IN (SELECT joinkey FROM app_nodump)");

  &oaPapers('antibody', "SELECT * FROM abp_paper");

  &oaPapers('otherexpr', "SELECT * FROM exp_paper WHERE joinkey NOT IN (SELECT joinkey FROM exp_nodump)");

  &oaPapers('humandisease', "SELECT * FROM dis_paperdisrel");
  &oaPapers('humandisease', "SELECT * FROM dis_paperexpmod");

  &oaPapers('seqfeature', "SELECT * FROM sqf_paper");

  &oaPapers('genereg', "SELECT * FROM grg_paper WHERE joinkey NOT IN (SELECT joinkey FROM grg_nodump)");

  &oaPapers('geneprod', "SELECT * FROM int_paper WHERE joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Physical' OR int_type = 'ProteinProtein' OR int_type = 'ProteinDNA' OR int_type = 'ProteinRNA') AND joinkey NOT IN (SELECT joinkey FROM int_nodump)");

  &oaPapers('rnai', "SELECT * FROM rna_paper WHERE joinkey NOT IN (SELECT joinkey FROM rna_nodump) AND joinkey NOT IN (SELECT joinkey FROM rna_curator WHERE rna_curator = 'WBPerson29819')");

    # these are not in the OA but they're in postgres, so are here
  &oaPapers('picture', "SELECT * FROM pic_paper WHERE joinkey NOT IN (SELECT joinkey FROM pic_nodump)");
  &oaPapers('blastomere',      "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Blastomere_isolation')");
  &oaPapers('exprmosaic',      "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Expression_mosaic')");
  &oaPapers('geneticablation', "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Genetic_ablation')");
  &oaPapers('geneticmosaic',   "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Genetic_mosaic')");
  &oaPapers('optogenetic',     "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Optogenetic')");
  &oaPapers('laserablation',   "SELECT * FROM wbb_reference WHERE joinkey IN (SELECT joinkey FROM wbb_assay WHERE wbb_assay = 'Laser_ablation')");

    # geneint corresponds to int_type not being physical nor predicted 2015 04 02
  $oaDatatypes{'geneint'}++;			# not going through &oaPapers, so flag it here
  my %int;
  $result = $dbh->prepare( "SELECT * FROM int_name" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $int{'name'}{$row[0]} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM int_paper" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $int{'paper'}{$row[0]} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM int_type" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $int{'type'}{$row[0]} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM int_nodump" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $int{'nodump'}{$row[0]} = $row[1]; }
  my %typeSkip;
  $typeSkip{"Physical"}++;
  $typeSkip{"ProteinProtein"}++;
  $typeSkip{"ProteinDNA"}++;
  $typeSkip{"ProteinRNA"}++;
  $typeSkip{"Predicted"}++;
  foreach my $joinkey (sort keys %{ $int{'name'} }) {
    next unless $int{'type'}{$joinkey};
    next if ($typeSkip{$int{'type'}{$joinkey}});
    next if ($int{'nodump'}{$joinkey});
    if ($int{'paper'}{$joinkey}) {
      my (@papers) = $int{'paper'}{$joinkey} =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{'geneint'}{$paper} = 'curated'; } } }
} # sub populateOaData

sub oaPapers {				# for a datatype and a query whose second column has WBPaper values, flag those papers as OA curated
  my ($datatype, $query) = @_;
  $oaDatatypes{$datatype}++;			# this datatype has an OA source, so oa_blank is meaningful for it
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless (defined $row[1]);
    my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
    foreach my $paper (@papers) {
      $oaData{$datatype}{$paper} = 'curated'; } }
} # sub oaPapers

sub getSimpleSecDate {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
  $year += 1900; $mon++;
  foreach ($mon, $mday, $hour, $min, $sec) { if ($_ < 10) { $_ = "0$_"; } }
  return "$year$mon$mday" . '_' . "$hour$min$sec";
} # sub getSimpleSecDate
