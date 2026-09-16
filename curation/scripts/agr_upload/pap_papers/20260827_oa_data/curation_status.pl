#!/usr/bin/env perl

# Export OA curation data as ABC curation_status rows : one row per reference per topic,
# carrying the ATP topic term and the ATP curation status term, for ABC to ingest.
#
# The datatype to topic mapping is from the curator 2026 09 16.  The names the curator
# gave are wormOA.pm oa_label values, so each resolves to an OA datatype code through
# &populateWormDatatypeList in
# curation/website/priv/cgi-bin/oa/wormOA.pm  (mounted at /usr/lib/priv/cgi-bin/oa) :
#
#   antibody                 abp   ATP:0000096  antibody
#   construct                cns   ATP:0000013  transgenic construct
#   disease                  dis   ATP:0000152  disease model
#   exprpat                  exp   ATP:0000041  expression in wild type
#   genereg                  grg   ATP:0000070  regulatory interaction
#   interaction - physical   int   ATP:0000069  physical interaction
#   interaction - genetic    int   ATP:0000068  genetic interaction
#   phenotype - variation    app   ATP:0000083  variation phenotype
#   phenotype - overexpr     app   ATP:0000084  overexpression phenotype
#   rnai                     rna   ATP:0000082  RNAi phenotype
#   transgene                trp   ATP:0000110  transgenic allele
#
# The curator's list had rnai twice with the same ATP term ;  it is one topic here.
#
# Two datatypes produce two topics each, so those topics carry an entry filter :
#   int   physical is int_type  Physical ProteinProtein ProteinDNA ProteinRNA ,  genetic
#         is any other int_type except Predicted .  That is the split &populateOaData in
#         curation_status.cgi uses for geneprod and geneint .  int_type currently holds
#         no Predicted rows, so the exclusion is there for when they come back.
#   app   overexpression phenotype is app_transgene filled, variation phenotype is
#         app_variation filled .  Exactly one entry has both filled ( joinkey 62856,
#         WBPaper00066568, WBTransgene00033839 and WBVar02146626 ) and it is deliberately
#         counted on both sides, from the curator 2026 09 16 .
#         1807 app entries that have a reference have neither field filled ( 799 have only
#         a strain, 336 only a rearrangement ), covering 408 references of which 181 have
#         no other app entry at all.  $appNeitherToVariation sends those to variation
#         phenotype, which is how &populateOaData treats app as a whole for newmutant,
#         and they are all listed in the .app_neither.tsv report so the choice can be
#         checked with the curator.  Set it to 0 to drop them instead.
#
# Curation status terms :
#   ATP:0000239  curated               the default for an entry with no flag against it
#   ATP:0000237  curation in progress
#
# Flag handling, from the curator 2026 09 16.  Each topic lists the flag tables that act
# on it and what they do ;  'skip' drops the entry entirely, 'in_progress' downgrades it
# to ATP:0000237 .  An entry hitting both gets skipped, since skip is the stronger action.
#   exp   exp_nodump          skip
#   int   int_nodump          skip          ( both the physical and the genetic topic )
#         int_needsreview     in_progress
#   grg   grg_nodump          in_progress
#   app   app_nodump          in_progress   ( both the variation and the overexpr topic )
#         app_needsreview     in_progress
#   rna   rna_needsreview     in_progress
# Flags deliberately given no rule, listed in %ignoredFlags so they are documented rather
# than forgotten :
#   rna_nodump            1254 entries, ignored on the curator's instruction 2026 09 16,
#                         so a nodumped RNAi entry still transfers as curated
#   trp_objpap_falsepos    267 entries.  The curator's rule was 'transgene if nodump
#                         transfer as curated', but there is no trp_nodump table in
#                         postgres at all ;  trp's only flag is this object-paper 'Fail'
#                         toggle.  Since the rule's outcome is the default anyway, the
#                         rule is a no op and every trp entry transfers as curated.
# Any other flag table found in postgres for these datatypes, with no rule and not in
# %ignoredFlags, is reported in .unruled_flags.tsv and left with no effect, so a flag
# added to the OA later shows up instead of silently changing nothing.
#
# Curator and curator timestamp come from '<datatype>_curator_hst', keeping the row with
# the highest <datatype>_timestamp per joinkey, falling back to the most recent non blank
# history value and then to the live '<datatype>_curator' table, the same way oa_data.pl
# does it.  They are here for ABC to use as created_by and date_created.
#
# A reference collapses the entries of one topic into one row.  Curated wins : the row is
# ATP:0000239 when any contributing entry is curated, and ATP:0000237 only when every
# contributing entry is flagged in progress.  The references where that mattered are
# counted as references_mixed in the topic summary.
#
# Output is tab delimited, written to $outdir :
#   curation_status.<date>.tsv            reference  topic_atp  topic_label
#                                         curation_status_atp  curation_status_label
#                                         curator  curator_timestamp  entries
#                                         entries_curated  entries_in_progress
#                                         one row per reference per topic, the ingest file
#   curation_status.<date>.entries.tsv    the same before collapsing, one row per OA entry,
#                                         with its joinkey so it can be looked up in the OA
#   curation_status.<date>.skipped.tsv    entries dropped by a 'skip' flag, with the flag
#   curation_status.<date>.app_neither.tsv   app entries with neither app_transgene nor
#                                         app_variation, and where they were sent
#   curation_status.<date>.unruled_flags.tsv  flag tables with no rule in this script
#   curation_status.<date>.topics.tsv     per topic, the tables and rules used, and counts
#
# CC wrote this script
#
# 2026 09 16


use strict;
use diagnostics;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $outdir = '/usr/caltech_curation_files/pub/kimberly/20260827_oa_data';	# for ABC to ingest, from the curator 2026 09 16
unless (-d $outdir) { mkdir $outdir or die "Cannot create $outdir : $!"; }

my $date = &getSimpleSecDate();

my $outfile      = "$outdir/curation_status.$date.tsv";
my $entryfile    = "$outdir/curation_status.$date.entries.tsv";
my $skipfile     = "$outdir/curation_status.$date.skipped.tsv";
my $neitherfile  = "$outdir/curation_status.$date.app_neither.tsv";
my $unruledfile  = "$outdir/curation_status.$date.unruled_flags.tsv";
my $topicfile    = "$outdir/curation_status.$date.topics.tsv";

my $CURATED     = 'ATP:0000239';
my $IN_PROGRESS = 'ATP:0000237';
my %statusLabel;
$statusLabel{$CURATED}     = 'curated';
$statusLabel{$IN_PROGRESS} = 'curation in progress';

my $appNeitherToVariation = 1;		# app entries with neither app_transgene nor app_variation go to variation phenotype

my %physicalIntTypes;			# int_type values that make an interaction physical
foreach my $type (qw( Physical ProteinProtein ProteinDNA ProteinRNA )) { $physicalIntTypes{$type}++; }

    # the topics to export, in output order.  aux lists the extra <datatype>_<field> tables
    # a filter needs loaded ;  filter returns true when an entry belongs to the topic.
my @topics = (
  { key => 'antibody',                 datatype => 'abp', atp => 'ATP:0000096', label => 'antibody' },
  { key => 'construct',                datatype => 'cns', atp => 'ATP:0000013', label => 'transgenic construct' },
  { key => 'disease',                  datatype => 'dis', atp => 'ATP:0000152', label => 'disease model',
    reference_field => 'paperexpmod' },			# the field labeled Reference ;  dis_paperdisrel is the other WBPaper field, to clarify with the curator
  { key => 'exprpat',                  datatype => 'exp', atp => 'ATP:0000041', label => 'expression in wild type',
    flags => [ { table => 'exp_nodump', action => 'skip' } ] },
  { key => 'genereg',                  datatype => 'grg', atp => 'ATP:0000070', label => 'regulatory interaction',
    flags => [ { table => 'grg_nodump', action => 'in_progress' } ] },
  { key => 'interaction_physical',     datatype => 'int', atp => 'ATP:0000069', label => 'physical interaction',
    aux => [ 'type' ],
    filter => sub { my ($aux) = @_; my $t = $aux->{'type'}; return 0 unless (defined $t && $t ne ''); return ($physicalIntTypes{$t}) ? 1 : 0; },
    flags => [ { table => 'int_nodump', action => 'skip' }, { table => 'int_needsreview', action => 'in_progress' } ] },
  { key => 'interaction_genetic',      datatype => 'int', atp => 'ATP:0000068', label => 'genetic interaction',
    aux => [ 'type' ],
    filter => sub { my ($aux) = @_; my $t = $aux->{'type'}; return 0 unless (defined $t && $t ne ''); return 0 if ($physicalIntTypes{$t}); return 0 if ($t eq 'Predicted'); return 1; },
    flags => [ { table => 'int_nodump', action => 'skip' }, { table => 'int_needsreview', action => 'in_progress' } ] },
  { key => 'phenotype_variation',      datatype => 'app', atp => 'ATP:0000083', label => 'variation phenotype',
    aux => [ 'variation', 'transgene' ],
    filter => sub { my ($aux) = @_;
                    my $var = (defined $aux->{'variation'}) ? $aux->{'variation'} : '';
                    my $trp = (defined $aux->{'transgene'}) ? $aux->{'transgene'} : '';
                    return 1 if ($var ne '');
                    return 1 if ($appNeitherToVariation && $trp eq '');	# neither field filled, the catch all
                    return 0; },
    flags => [ { table => 'app_nodump', action => 'in_progress' }, { table => 'app_needsreview', action => 'in_progress' } ] },
  { key => 'phenotype_overexpression', datatype => 'app', atp => 'ATP:0000084', label => 'overexpression phenotype',
    aux => [ 'transgene' ],
    filter => sub { my ($aux) = @_; my $t = $aux->{'transgene'}; return (defined $t && $t ne '') ? 1 : 0; },
    flags => [ { table => 'app_nodump', action => 'in_progress' }, { table => 'app_needsreview', action => 'in_progress' } ] },
  { key => 'rnai',                     datatype => 'rna', atp => 'ATP:0000082', label => 'RNAi phenotype',
    flags => [ { table => 'rna_needsreview', action => 'in_progress' } ] },
  { key => 'transgene',                datatype => 'trp', atp => 'ATP:0000110', label => 'transgenic allele' },
);

    # flag tables with no rule on purpose, so the unruled report does not list them again
my %ignoredFlags;
$ignoredFlags{'rna_nodump'}          = 'ignored on the curator instruction 2026 09 16, a nodumped RNAi entry still transfers as curated';
$ignoredFlags{'trp_objpap_falsepos'} = 'the curator rule for transgene was nodump to curated, there is no trp_nodump table and curated is the default, so the rule is a no op';

    # the suffixes that make a postgres table a flag table, for the unruled flag report
my @flagSuffixes = qw( nodump needsreview falsepositive curationstatusomit objpap_falsepos );

my %pgTables;				# every table in the database, to check before querying
$result = $dbh->prepare( "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $pgTables{$row[0]}++; }

my %reference;				# $reference{datatype}{joinkey} = the reference field value
my %aux;				# $aux{datatype}{joinkey}{field} = value , for the topic filters
my %flagged;				# $flagged{flagTable}{joinkey} = 1
my %curator;				# $curator{datatype}{joinkey}{value,timestamp,source}
my %counts;
my %appNeither;				# app entries with neither app_transgene nor app_variation

&loadDatatypes();

open (OUT,     ">$outfile")     or die "Cannot create $outfile : $!";
open (ENTRY,   ">$entryfile")   or die "Cannot create $entryfile : $!";
open (SKIP,    ">$skipfile")    or die "Cannot create $skipfile : $!";
print OUT   join("\t", qw( reference topic_atp topic_label curation_status_atp curation_status_label curator curator_timestamp entries entries_curated entries_in_progress )) . "\n";
print ENTRY join("\t", qw( topic datatype joinkey reference topic_atp curation_status_atp curation_status_label flags curator curator_timestamp curator_source )) . "\n";
print SKIP  join("\t", qw( topic datatype joinkey reference flag_table )) . "\n";

my %byReference;			# $byReference{topicKey}{reference}{...}

foreach my $topic (@topics) {
  my $topicKey  = $topic->{'key'};
  my $datatype  = $topic->{'datatype'};
  my $topicAtp  = $topic->{'atp'};
  my @flagRules = ($topic->{'flags'}) ? @{ $topic->{'flags'} } : ();

  foreach my $joinkey (sort { $a <=> $b } keys %{ $reference{$datatype} }) {
    my $referenceValue = $reference{$datatype}{$joinkey};
    next unless (defined $referenceValue);
    my (@papers) = $referenceValue =~ m/WBPaper(\d+)/g;		# a reference field can hold more than one paper
    next unless (scalar @papers > 0);

    if ($topic->{'filter'}) {					# does this entry belong to this topic
      my $auxRef = ($aux{$datatype}{$joinkey}) ? $aux{$datatype}{$joinkey} : {};
      next unless ( $topic->{'filter'}->($auxRef) ); }
    $counts{$topicKey}{'entries_considered'}++;

    my $status = $CURATED;					# the default, no flag against the entry
    my @hitFlags;
    my $skipFlag = '';
    foreach my $rule (@flagRules) {
      next unless ($flagged{ $rule->{'table'} }{$joinkey});
      push @hitFlags, $rule->{'table'};
      if ($rule->{'action'} eq 'skip') { $skipFlag = $rule->{'table'}; }	# skip is the stronger action, so it wins
        elsif ($rule->{'action'} eq 'in_progress') { $status = $IN_PROGRESS unless ($skipFlag); } }

    if ($skipFlag) {
      $counts{$topicKey}{'entries_skipped'}++;
      foreach my $paper (@papers) { print SKIP join("\t", $topicKey, $datatype, $joinkey, "WBPaper$paper", $skipFlag) . "\n"; }
      next; }

    my $curatorValue     = ($curator{$datatype}{$joinkey}{'value'})     ? $curator{$datatype}{$joinkey}{'value'}     : '';
    my $curatorTimestamp = ($curator{$datatype}{$joinkey}{'timestamp'}) ? $curator{$datatype}{$joinkey}{'timestamp'} : '';
    my $curatorSource    = ($curator{$datatype}{$joinkey}{'source'})    ? $curator{$datatype}{$joinkey}{'source'}    : '';
    if ($status eq $CURATED) { $counts{$topicKey}{'entries_curated'}++; }
      else { $counts{$topicKey}{'entries_in_progress'}++; }
    unless ($curatorValue) { $counts{$topicKey}{'entries_without_curator'}++; }

    foreach my $paper (@papers) {
      my $reference = "WB:WBPaper$paper";
      print ENTRY join("\t", $topicKey, $datatype, $joinkey, $reference, $topicAtp, $status, $statusLabel{$status}, join("|", @hitFlags), $curatorValue, $curatorTimestamp, $curatorSource) . "\n";
      $byReference{$topicKey}{$reference}{'entries'}++;
      if ($status eq $CURATED) { $byReference{$topicKey}{$reference}{'curated'}++; }
        else { $byReference{$topicKey}{$reference}{'in_progress'}++; }
      my $best = $byReference{$topicKey}{$reference}{'timestamp'};	# keep the most recent curator of the reference
      if (!defined $best || $curatorTimestamp gt $best) {
        $byReference{$topicKey}{$reference}{'timestamp'} = $curatorTimestamp;
        $byReference{$topicKey}{$reference}{'curator'}   = $curatorValue; } }
  } # foreach my $joinkey
} # foreach my $topic

foreach my $topic (@topics) {			# print the ingest file in topic order
  my $topicKey = $topic->{'key'};
  foreach my $reference (sort keys %{ $byReference{$topicKey} }) {
    my $entries    = $byReference{$topicKey}{$reference}{'entries'};
    my $curated    = ($byReference{$topicKey}{$reference}{'curated'})     ? $byReference{$topicKey}{$reference}{'curated'}     : 0;
    my $inProgress = ($byReference{$topicKey}{$reference}{'in_progress'}) ? $byReference{$topicKey}{$reference}{'in_progress'} : 0;
    my $status = ($curated > 0) ? $CURATED : $IN_PROGRESS;		# curated wins over curation in progress
    $counts{$topicKey}{'references'}++;
    if ($curated > 0 && $inProgress > 0) { $counts{$topicKey}{'references_mixed'}++; }
    if ($status eq $CURATED) { $counts{$topicKey}{'references_curated'}++; }
      else { $counts{$topicKey}{'references_in_progress'}++; }
    my $curatorValue     = ($byReference{$topicKey}{$reference}{'curator'})   ? $byReference{$topicKey}{$reference}{'curator'}   : '';
    my $curatorTimestamp = ($byReference{$topicKey}{$reference}{'timestamp'}) ? $byReference{$topicKey}{$reference}{'timestamp'} : '';
    print OUT join("\t", $reference, $topic->{'atp'}, $topic->{'label'}, $status, $statusLabel{$status}, $curatorValue, $curatorTimestamp, $entries, $curated, $inProgress) . "\n"; } }

close (OUT)   or die "Cannot close $outfile : $!";
close (ENTRY) or die "Cannot close $entryfile : $!";
close (SKIP)  or die "Cannot close $skipfile : $!";

&printAppNeither();
&printUnruledFlags();
&printTopics();
&printSummary();


sub loadDatatypes {			# the reference, filter, flag and curator tables of every datatype in @topics
  my %needReference;  my %needAux;  my %needFlag;
  foreach my $topic (@topics) {
    my $datatype = $topic->{'datatype'};
    my $field = ($topic->{'reference_field'}) ? $topic->{'reference_field'} : 'paper';
    $needReference{$datatype} = $datatype . '_' . $field;
    if ($topic->{'aux'}) { foreach my $auxField (@{ $topic->{'aux'} }) { $needAux{$datatype}{$auxField}++; } }
    if ($topic->{'flags'}) { foreach my $rule (@{ $topic->{'flags'} }) { $needFlag{ $rule->{'table'} }++; } } }

  foreach my $datatype (sort keys %needReference) {
    my $table = $needReference{$datatype};
    unless ($pgTables{$table}) { die "reference table $table for datatype $datatype is not in postgres\n"; }
    $result = $dbh->prepare( "SELECT joinkey, $table FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless (defined $row[1]);
      next if ($row[1] eq '');
      $reference{$datatype}{$row[0]} = $row[1]; } }

  foreach my $datatype (sort keys %needAux) {
    foreach my $auxField (sort keys %{ $needAux{$datatype} }) {
      my $table = $datatype . '_' . $auxField;
      unless ($pgTables{$table}) { die "filter table $table for datatype $datatype is not in postgres\n"; }
      $result = $dbh->prepare( "SELECT joinkey, $table FROM $table" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while (my @row = $result->fetchrow) {
        next unless (defined $row[1]);
        next if ($row[1] eq '');
        $aux{$datatype}{$row[0]}{$auxField} = $row[1]; } } }

  foreach my $table (sort keys %needFlag) {			# a toggle table only holds rows for entries it is set on
    unless ($pgTables{$table}) { die "flag table $table is not in postgres\n"; }
    $result = $dbh->prepare( "SELECT joinkey, $table FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless (defined $row[1]);
      next if ($row[1] eq '');
      $flagged{$table}{$row[0]}++; } }

  foreach my $datatype (sort keys %needReference) {
    my $curTable    = $datatype . '_curator';
    my $curHstTable = $datatype . '_curator_hst';
    unless ($pgTables{$curTable})    { die "curator table $curTable is not in postgres\n"; }
    unless ($pgTables{$curHstTable}) { die "curator history table $curHstTable is not in postgres\n"; }
    &populateCurator($datatype, $curHstTable, $curTable, \%{ $curator{$datatype} }); }

  foreach my $joinkey (keys %{ $reference{'app'} }) {		# the app entries with no object to split on
    my $trp = ($aux{'app'}{$joinkey}{'transgene'}) ? $aux{'app'}{$joinkey}{'transgene'} : '';
    my $var = ($aux{'app'}{$joinkey}{'variation'}) ? $aux{'app'}{$joinkey}{'variation'} : '';
    next if ($trp ne '' || $var ne '');
    $appNeither{$joinkey}++; }
} # sub loadDatatypes

sub populateCurator {			# most recent curator timestamp from the history table, per joinkey, as oa_data.pl does it
  my ($datatype, $curHstTable, $curTable, $curatorRef) = @_;
  my $timestampColumn = $datatype . '_timestamp';
  my %latestNonBlank;			# most recent non-blank history value, for when the latest row is blank
  $result = $dbh->prepare( "SELECT joinkey, $curHstTable, $timestampColumn FROM $curHstTable ORDER BY $timestampColumn" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {			# ordered ascending, so the last row seen for a joinkey is its most recent
    my ($joinkey, $value, $timestamp) = ($row[0], $row[1], $row[2]);
    unless (defined $value)     { $value = ''; }
    unless (defined $timestamp) { $timestamp = ''; }
    $$curatorRef{$joinkey}{'value'}     = $value;
    $$curatorRef{$joinkey}{'timestamp'} = $timestamp;
    $$curatorRef{$joinkey}{'source'}    = 'hst';
    if ($value ne '') { $latestNonBlank{$joinkey} = $value; } }

  my %live;				# the live curator table, for joinkeys with no history
  $result = $dbh->prepare( "SELECT joinkey, $curTable, $timestampColumn FROM $curTable" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    next unless (defined $row[1]);
    next if ($row[1] eq '');
    $live{$row[0]}{'value'}     = $row[1];
    $live{$row[0]}{'timestamp'} = (defined $row[2]) ? $row[2] : ''; }

  foreach my $joinkey (keys %{ $curatorRef }) {			# fill in a blanked latest history value
    next unless (defined $$curatorRef{$joinkey}{'value'});
    next unless ($$curatorRef{$joinkey}{'value'} eq '');
    if (defined $latestNonBlank{$joinkey}) {
      $$curatorRef{$joinkey}{'value'}  = $latestNonBlank{$joinkey};
      $$curatorRef{$joinkey}{'source'} = 'hst_blank_latest'; }
    elsif (defined $live{$joinkey}) {
      $$curatorRef{$joinkey}{'value'}  = $live{$joinkey}{'value'};
      $$curatorRef{$joinkey}{'source'} = 'hst_blank_latest_live'; } }

  foreach my $joinkey (keys %live) {				# joinkeys the history table has no row for
    next if (defined $$curatorRef{$joinkey});
    $$curatorRef{$joinkey}{'value'}     = $live{$joinkey}{'value'};
    $$curatorRef{$joinkey}{'timestamp'} = $live{$joinkey}{'timestamp'};
    $$curatorRef{$joinkey}{'source'}    = 'live'; }
} # sub populateCurator

sub printAppNeither {			# app entries with neither app_transgene nor app_variation, and where they went
  open (NEITHER, ">$neitherfile") or die "Cannot create $neitherfile : $!";
  print NEITHER join("\t", qw( joinkey reference app_strain app_rearrangement sent_to )) . "\n";
  my %appStrain;  my %appRearrangement;
  foreach my $field ('strain', 'rearrangement') {
    my $table = 'app_' . $field;
    next unless ($pgTables{$table});
    $result = $dbh->prepare( "SELECT joinkey, $table FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless (defined $row[1]);
      next if ($row[1] eq '');
      if ($field eq 'strain') { $appStrain{$row[0]} = $row[1]; }
        else { $appRearrangement{$row[0]} = $row[1]; } } }
  my $sentTo = ($appNeitherToVariation) ? 'phenotype_variation' : 'dropped';
  foreach my $joinkey (sort { $a <=> $b } keys %appNeither) {
    my $strain = ($appStrain{$joinkey})         ? $appStrain{$joinkey}         : '';
    my $rearr  = ($appRearrangement{$joinkey})  ? $appRearrangement{$joinkey}  : '';
    print NEITHER join("\t", $joinkey, $reference{'app'}{$joinkey}, $strain, $rearr, $sentTo) . "\n"; }
  close (NEITHER) or die "Cannot close $neitherfile : $!";
} # sub printAppNeither

sub printUnruledFlags {			# flag tables of these datatypes that no rule in this script acts on
  my %ruled;
  foreach my $topic (@topics) {
    next unless ($topic->{'flags'});
    foreach my $rule (@{ $topic->{'flags'} }) { $ruled{ $rule->{'table'} } = $rule->{'action'}; } }
  my %datatypesUsed;
  foreach my $topic (@topics) { $datatypesUsed{ $topic->{'datatype'} }++; }
  open (UNRULED, ">$unruledfile") or die "Cannot create $unruledfile : $!";
  print UNRULED join("\t", qw( datatype flag_table entries_flagged state note )) . "\n";
  my $unruledCount = 0;
  foreach my $datatype (sort keys %datatypesUsed) {
    foreach my $suffix (@flagSuffixes) {
      my $table = $datatype . '_' . $suffix;
      next unless ($pgTables{$table});
      my $flaggedCount = 0;
      $result = $dbh->prepare( "SELECT count(DISTINCT joinkey) FROM $table WHERE $table != ''" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while (my @row = $result->fetchrow) { $flaggedCount = $row[0]; }
      if ($ruled{$table}) { next; }			# a rule acts on it, so it is not unruled
      if ($ignoredFlags{$table}) {
        print UNRULED join("\t", $datatype, $table, $flaggedCount, 'ignored_on_purpose', $ignoredFlags{$table}) . "\n";
        next; }
      $unruledCount++;
      print UNRULED join("\t", $datatype, $table, $flaggedCount, 'no_rule', 'found in postgres with no rule in this script, so it has no effect') . "\n";
      print "flag table $table has no rule in this script and is not in %ignoredFlags , $flaggedCount entries flagged, so it has no effect\n"; }
  }
  close (UNRULED) or die "Cannot close $unruledfile : $!";
  unless ($unruledCount) { print "every flag table of the datatypes used has a rule or is ignored on purpose\n"; }
} # sub printUnruledFlags

sub printTopics {			# per topic, the tables and rules used, and the counts
  open (TOPIC, ">$topicfile") or die "Cannot create $topicfile : $!";
  print TOPIC join("\t", qw( topic datatype topic_atp topic_label reference_table filter flag_rules entries_considered entries_skipped entries_curated entries_in_progress entries_without_curator references references_curated references_in_progress references_mixed )) . "\n";
  foreach my $topic (@topics) {
    my $topicKey = $topic->{'key'};
    my $field = ($topic->{'reference_field'}) ? $topic->{'reference_field'} : 'paper';
    my @rules;
    if ($topic->{'flags'}) { foreach my $rule (@{ $topic->{'flags'} }) { push @rules, $rule->{'table'} . ':' . $rule->{'action'}; } }
    my $filter = ($topic->{'filter'}) ? join(",", @{ $topic->{'aux'} }) : '';
    my @row = ( $topicKey, $topic->{'datatype'}, $topic->{'atp'}, $topic->{'label'},
                $topic->{'datatype'} . '_' . $field, $filter, join("|", @rules) );
    foreach my $key (qw( entries_considered entries_skipped entries_curated entries_in_progress entries_without_curator references references_curated references_in_progress references_mixed )) {
      my $value = ($counts{$topicKey}{$key}) ? $counts{$topicKey}{$key} : 0;
      push @row, $value; }
    print TOPIC join("\t", @row) . "\n"; }
  close (TOPIC) or die "Cannot close $topicfile : $!";
} # sub printTopics

sub printSummary {
  my $totalReferences = 0;  my $totalEntries = 0;  my $totalSkipped = 0;  my $totalInProgress = 0;  my $totalMixed = 0;
  foreach my $topic (@topics) {
    my $topicKey = $topic->{'key'};
    foreach my $pair ( [\$totalReferences, 'references'], [\$totalEntries, 'entries_considered'], [\$totalSkipped, 'entries_skipped'],
                       [\$totalInProgress, 'references_in_progress'], [\$totalMixed, 'references_mixed'] ) {
      my ($ref, $key) = @{ $pair };
      $$ref += ($counts{$topicKey}{$key}) ? $counts{$topicKey}{$key} : 0; } }
  print "topics exported : " . scalar(@topics) . "\n";
  print "OA entries considered : $totalEntries\n";
  print "OA entries dropped by a skip flag : $totalSkipped -> $skipfile\n";
  print "curation_status rows, one per reference per topic : $totalReferences -> $outfile\n";
  print "  of those, curation in progress : $totalInProgress\n";
  print "  of those, references where curated won over curation in progress : $totalMixed\n";
  my $neitherCount = scalar keys %appNeither;
  my $sentTo = ($appNeitherToVariation) ? 'sent to phenotype_variation' : 'dropped';
  print "app entries with neither app_transgene nor app_variation : $neitherCount , $sentTo -> $neitherfile\n";
  print "per topic counts -> $topicfile\n";
  print "flag tables with no rule -> $unruledfile\n";
  print "one row per OA entry -> $entryfile\n";
} # sub printSummary

sub getSimpleSecDate {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
  $year += 1900; $mon++;
  foreach ($mon, $mday, $hour, $min, $sec) { if ($_ < 10) { $_ = "0$_"; } }
  return "$year$mon$mday" . '_' . "$hour$min$sec";
} # sub getSimpleSecDate
