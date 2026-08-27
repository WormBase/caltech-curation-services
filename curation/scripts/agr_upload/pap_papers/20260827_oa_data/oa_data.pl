#!/usr/bin/env perl

# Export, for every OA datatype, each curated entry mapped to its main object and its
# primary reference, with the curator and the most recent curator timestamp from the
# history tables, and the postgres table of any NO DUMP or equivalent flag on the entry.
#
# The OA configuration is read at runtime from
# curation/website/priv/cgi-bin/oa/wormOA.pm  (mounted at /usr/lib/priv/cgi-bin/oa in the
# curation container) instead of being copied here, so the script follows the config when
# fields are added or renamed.  &populateWormDatatypeList gives the datatype list, and
# &initModFields gives each datatype's fields, in the order wormOA.pm declares them.
#
# Each OA field has its own postgres table '<datatype>_<field>' and history table
# '<datatype>_<field>_hst', both with columns  joinkey, <table_name>, <datatype>_timestamp
# (documented in the POD of  curation/website/priv/cgi-bin/oa/ontology_annotator.cgi ).
#
# Primary reference field, in this order :
#   - the field literally named 'paper'                    (every datatype but dis)
#   - else the first WBPaper field labeled 'Reference'     (dis -> paperexpmod)
#   - else the first WBPaper field in wormOA.pm order
#
# Main object field, from the datatype's 'highestPgidTables' in wormOA.pm, which is the
# array of fields that identify an entry, skipping 'curator' and skipping dropdown fields
# (con lists 'desctype', a Description Type dropdown, not an object).  That leaves one
# object field for every datatype but app, which lists four alternative objects
# (app_strain app_rearrangement app_transgene app_variation) ;  an app entry can have more
# than one filled, so object_id and object_field are pipe-joined in the same order.
# grg is overridden to use grg_intid : highestPgidTables gives grg_name, but that is a
# constructed label ('WBPaper00044190_pax-1') set on only 6136 of the 13443 grg entries,
# while grg_intid is a real WBInteraction ID set on 13442 of them.
# The choices are reported per datatype in the .datatypes file so they can be checked.
#
# Curator and curator timestamp come from '<datatype>_curator_hst', keeping the row with
# the highest <datatype>_timestamp for each joinkey.  When that latest row has a blank
# curator (the field was cleared) its timestamp is kept and the curator falls back to the
# most recent non-blank history value, then to the live '<datatype>_curator' table ;  the
# curator_source column of the by_reference file records which was used.  A datatype loaded
# in bulk has little history to read : sqf has 5 rows in sqf_curator_hst against 376k in
# sqf_curator , so nearly all of its timestamps come from the live table.  The .datatypes
# file counts the split per datatype and STDOUT names the datatypes it happens in.
#
# Any cell holding more than one value pipe-joins them, because a rearrangement name can
# have commas in it ( app WBPaper00053293 has the object 'eanIR158(V,CB4856,N2)' ) and a
# comma-joined cell would not be splittable.
#
# The nodump column holds the postgres table names of the flags set on the entry, pipe
# joined, blank when none are set.  Two kinds of flag go in it :
#   nodump   the 'nodump' toggle labeled 'NO DUMP', in 10 of the 20 datatypes
#   related  8 toggles that are not NO DUMP but keep entries out of dumps in the same
#            spirit : 'Needs Review', 'False Positive', 'Curation Status Omit', and the
#            transgene object-paper 'Fail'.  The table name says which kind a row is,
#            and .nodump_fields.tsv lists every flag field with its kind.
# Note that gop_falsepositive is set on 37793 of gop's 38144 entries, so it dominates the
# column for that datatype.
#
# Output is tab delimited, written to $outdir :
#   oa_data.<date>.tsv               datatype  object_id  object_field  reference  curator
#                                    curator_timestamp  nodump
#                                    one row per OA entry per reference, the full output
#   oa_data.<date>.by_reference.tsv  the same collapsed to one row per datatype-reference,
#                                    keeping the most recent curator timestamp, plus counts
#   oa_data.<date>.nodump.tsv        every entry with a nodump or related flag set, grouped
#                                    by datatype then flag table, including the entries
#                                    that have no reference and so are not in the tsv
#   oa_data.<date>.no_curator.tsv    the entries of the tsv whose curator came out blank,
#                                    with their joinkey so they can be looked up in the OA
#   oa_data.<date>.curator_no_reference.tsv
#                                    the reverse : entries that have a curator but no
#                                    reference, so they are in none of the files above.
#                                    Only entries that still exist are here, meaning ones
#                                    with a value in the live '<datatype>_curator' table ;
#                                    a deleted entry keeps its history rows forever, so
#                                    going by history would report deleted entries too.
#                                    The reason column says whether the reference table has
#                                    no row for the entry at all or has a row with no
#                                    WBPaper value in it
#   oa_data.<date>.nodump_fields.tsv datatypes with a NODUMP or equivalent field, and the
#                                    field name and postgres table of each
#   oa_data.<date>.datatypes.tsv     per datatype, the fields and tables used, and counts,
#                                    including how many timestamps came from the history
#                                    table and how many from the live curator table
#
# CC wrote this script
#
# 2026 08 27


use strict;
use diagnostics;
use DBI;
use Dotenv -load => '/usr/lib/.env';
use lib '/usr/lib/priv/cgi-bin/oa';
use lib '/usr/lib/priv/cgi-bin';
use wormOA;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $outdir = '/usr/caltech_curation_files/pub/kimberly/20260827_oa_data';	# for the curator 2026 08 27
unless (-d $outdir) { mkdir $outdir or die "Cannot create $outdir : $!"; }

my $date = &getSimpleSecDate();

my $outfile       = "$outdir/oa_data.$date.tsv";
my $reffile       = "$outdir/oa_data.$date.by_reference.tsv";
my $flagfile      = "$outdir/oa_data.$date.nodump.tsv";
my $nocuratorfile = "$outdir/oa_data.$date.no_curator.tsv";
my $norefile      = "$outdir/oa_data.$date.curator_no_reference.tsv";
my $nodumpfile    = "$outdir/oa_data.$date.nodump_fields.tsv";
my $dtfile        = "$outdir/oa_data.$date.datatypes.tsv";

    # main object field where the datatype's highestPgidTables is not the object that identifies the entry
my %objectFieldOverride;
$objectFieldOverride{'grg'} = 'intid';		# WBInteraction ID, covering 13442 entries where grg_name covers 6136

    # toggles that are not 'NO DUMP' but keep entries out of dumps in the same spirit
my %relatedFlagFields;
$relatedFlagFields{'app'}{'needsreview'}        = 'entry flagged for review, &populateOaData in curation_status.cgi excludes these from newmutant';
$relatedFlagFields{'int'}{'needsreview'}        = 'entry flagged for review';
$relatedFlagFields{'rna'}{'needsreview'}        = 'entry flagged for review';
$relatedFlagFields{'gop'}{'falsepositive'}      = 'entry marked a false positive';
$relatedFlagFields{'int'}{'falsepositive'}      = 'entry marked a false positive';
$relatedFlagFields{'pro'}{'falsepositive'}      = 'entry marked a false positive';
$relatedFlagFields{'pro'}{'curationstatusomit'} = 'entry omitted from curation status';
$relatedFlagFields{'trp'}{'objpap_falsepos'}    = 'object-paper association marked a failure';

my $datatypeListRef = &populateWormDatatypeList();		# the selectable OA datatypes, in wormOA.pm order
my @oaDatatypes = keys %{ $datatypeListRef };			# tied hash, so this keeps wormOA.pm order

my %conf;					# $conf{datatype}{label/reference_field/object_fields/flag_fields}
my %missingTables;				# tables wormOA.pm configures that postgres does not have
my %noReferenceDatatypes;			# datatypes with no WBPaper field at all
&populateConf();

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT join("\t", qw( datatype object_id object_field reference curator curator_timestamp nodump )) . "\n";

    # every entry with a flag set, including the ones with no reference, which are not in the tsv
open (FLAG, ">$flagfile") or die "Cannot create $flagfile : $!";
print FLAG join("\t", qw( datatype oa_label joinkey object_id object_field reference curator curator_timestamp nodump flag_kind )) . "\n";

    # entries with no curator, kept in the tsv with a blank curator and repeated here with their joinkey
open (NOCUR, ">$nocuratorfile") or die "Cannot create $nocuratorfile : $!";
print NOCUR join("\t", qw( datatype oa_label joinkey object_id object_field reference curator_timestamp nodump curator_table curator_history_table )) . "\n";

    # entries that have a curator but no reference, so they are in none of the other files
open (NOREF, ">$norefile") or die "Cannot create $norefile : $!";
print NOREF join("\t", qw( datatype oa_label joinkey object_id object_field curator curator_timestamp nodump reference_table reason )) . "\n";

my %byReference;				# $byReference{datatype}{reference}{timestamp/curator/curator_source/entries/nodump_entries/objects}
my %counts;					# $counts{datatype}{entries/references/rows/...}
my $total_rows = 0;
my $total_no_curator_rows = 0;
my $total_flag_rows = 0;
my $total_no_reference_rows = 0;

foreach my $datatype (@oaDatatypes) {
  next unless ($conf{$datatype}{reference_field});		# no WBPaper field, so nothing to map
  &processDatatype($datatype);
}
close (OUT)   or die "Cannot close $outfile : $!";
close (FLAG)  or die "Cannot close $flagfile : $!";
close (NOCUR) or die "Cannot close $nocuratorfile : $!";
close (NOREF) or die "Cannot close $norefile : $!";

&printByReference();
&printNodumpFields();
&printDatatypes();
&printSummary();


sub processDatatype {
  my ($datatype) = @_;
  my $refTable    = $datatype . '_' . $conf{$datatype}{reference_field};
  my $curTable    = $datatype . '_curator';
  my $curHstTable = $curTable . '_hst';

  my %curator;			# $curator{joinkey}{timestamp/value/source}
  &populateCurator($datatype, $curHstTable, $curTable, \%curator);

  my %object;			# $object{joinkey}{field} = value
  foreach my $field (@{ $conf{$datatype}{'object_fields'} }) {
    my $table = $datatype . '_' . $field;
    $result = $dbh->prepare( "SELECT joinkey, $table FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless (defined $row[1]);
      my $value = $row[1];
      $value =~ s/^"//;  $value =~ s/"$//;		# multiontology values are doublequoted
      next if ($value eq '');
      $object{$row[0]}{$field} = $value; } }

  my %flag;			# $flag{joinkey}{table} = kind
  foreach my $field (sort keys %{ $conf{$datatype}{'flag_fields'} }) {
    my $table = $datatype . '_' . $field;
    $result = $dbh->prepare( "SELECT joinkey, $table FROM $table" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      next unless (defined $row[1]);
      next if ($row[1] eq '');
      $flag{$row[0]}{$table} = $conf{$datatype}{'flag_fields'}{$field};
      $counts{$datatype}{'flagged'}{$table}++; } }

  my %refRowNoPaper;		# joinkeys with a reference table row that holds no WBPaper value
  my %reference;		# $reference{joinkey} = \@papers , also used by the flag file
  $result = $dbh->prepare( "SELECT joinkey, $refTable FROM $refTable ORDER BY joinkey" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $value) = ($row[0], $row[1]);
    $counts{$datatype}{'entries'}++;
    unless (defined $value) { $value = ''; }
    my (@papers) = $value =~ m/(WBPaper\d+)/g;
    unless (scalar @papers > 0) { $counts{$datatype}{'no_reference_value'}++; $refRowNoPaper{$joinkey}++; next; }
    my %seenPaper; my @papersOnce;			# a field can list the same paper twice
    foreach my $paper (@papers) { next if ($seenPaper{$paper}); $seenPaper{$paper}++; push @papersOnce, $paper; }
    @{ $reference{$joinkey} } = @papersOnce;

    my ($objectId, $objectField) = &objectOf($datatype, $joinkey, \%object);
    my $curatorValue     = (defined $curator{$joinkey}{'value'})     ? $curator{$joinkey}{'value'}     : '';
    my $curatorTimestamp = (defined $curator{$joinkey}{'timestamp'}) ? $curator{$joinkey}{'timestamp'} : '';
    my $curatorSource    = (defined $curator{$joinkey}{'source'})    ? $curator{$joinkey}{'source'}    : 'none';
    unless ($curatorValue)  { $counts{$datatype}{'no_curator'}++; }
    unless ($objectId)      { $counts{$datatype}{'no_object'}++; }
    my $nodumpValue = &nodumpOf($joinkey, \%flag);
    if ($nodumpValue) { $counts{$datatype}{'nodump_entries'}++; }
    $counts{$datatype}{'curator_source'}{$curatorSource}++;

    foreach my $paper (@papersOnce) {
      $total_rows++;
      $counts{$datatype}{'rows'}++;
      print OUT join("\t", $datatype, $objectId, $objectField, $paper, $curatorValue, $curatorTimestamp, $nodumpValue) . "\n";
      unless ($curatorValue) {
        $total_no_curator_rows++;
        print NOCUR join("\t", $datatype, $conf{$datatype}{'label'}, $joinkey, $objectId, $objectField, $paper, $curatorTimestamp,
                               $nodumpValue, $curTable, $curHstTable) . "\n"; }

      $byReference{$datatype}{$paper}{'entries'}++;
      if ($nodumpValue) { $byReference{$datatype}{$paper}{'nodump_entries'}++; }
      if ($objectId) { $byReference{$datatype}{$paper}{'objects'}{$objectId}++; }
      my $previous = $byReference{$datatype}{$paper}{'timestamp'};
      if ( (!defined $previous) || ($curatorTimestamp gt $previous) ) {	# postgres timestamps sort correctly as text
        $byReference{$datatype}{$paper}{'timestamp'}      = $curatorTimestamp;
        $byReference{$datatype}{$paper}{'curator'}        = $curatorValue;
        $byReference{$datatype}{$paper}{'curator_source'} = $curatorSource; } } }
  $counts{$datatype}{'references'} = scalar keys %{ $byReference{$datatype} };

    # the flag file, grouped by datatype then flag table, and including flagged entries with no reference
  foreach my $joinkey (sort { $a <=> $b } keys %flag) {
    my ($objectId, $objectField) = &objectOf($datatype, $joinkey, \%object);
    my $curatorValue     = (defined $curator{$joinkey}{'value'})     ? $curator{$joinkey}{'value'}     : '';
    my $curatorTimestamp = (defined $curator{$joinkey}{'timestamp'}) ? $curator{$joinkey}{'timestamp'} : '';
    my $nodumpValue = &nodumpOf($joinkey, \%flag);
    my @kinds;  my %seenKind;
    foreach my $table (sort keys %{ $flag{$joinkey} }) {
      next if ($seenKind{ $flag{$joinkey}{$table} }); $seenKind{ $flag{$joinkey}{$table} }++;
      push @kinds, $flag{$joinkey}{$table}; }
    my @papers = ($reference{$joinkey}) ? @{ $reference{$joinkey} } : ('');
    foreach my $paper (@papers) {
      $total_flag_rows++;
      unless ($paper) { $counts{$datatype}{'flagged_without_reference'}++; }
      print FLAG join("\t", $datatype, $conf{$datatype}{'label'}, $joinkey, $objectId, $objectField, $paper,
                            $curatorValue, $curatorTimestamp, $nodumpValue, join("|", @kinds)) . "\n"; } }

    # entries that still exist and have a curator, but that the reference table has no WBPaper for
  foreach my $joinkey (sort { $a <=> $b } keys %curator) {
    next unless ($curator{$joinkey}{'in_live'});		# a history-only joinkey is a deleted entry
    next unless ($curator{$joinkey}{'value'});
    next if ($reference{$joinkey});
    my ($objectId, $objectField) = &objectOf($datatype, $joinkey, \%object);
    my $reason = ($refRowNoPaper{$joinkey}) ? 'reference_table_row_without_wbpaper' : 'no_row_in_reference_table';
    $total_no_reference_rows++;
    $counts{$datatype}{'curator_no_reference'}++;
    print NOREF join("\t", $datatype, $conf{$datatype}{'label'}, $joinkey, $objectId, $objectField, $curator{$joinkey}{'value'},
                           $curator{$joinkey}{'timestamp'}, &nodumpOf($joinkey, \%flag), $refTable, $reason) . "\n"; }

  print "$datatype ($conf{$datatype}{label}) : $counts{$datatype}{'entries'} entries, $counts{$datatype}{'rows'} rows, $counts{$datatype}{'references'} references\n";
} # sub processDatatype

sub objectOf {				# main object id and the postgres table it came from, comma joined for app
  my ($datatype, $joinkey, $objectRef) = @_;
  my @ids;  my @fields;
  foreach my $field (@{ $conf{$datatype}{'object_fields'} }) {
    next unless (defined $$objectRef{$joinkey}{$field});
    push @ids, $$objectRef{$joinkey}{$field};
    push @fields, $datatype . '_' . $field; }
  return ( join("|", @ids), join("|", @fields) );
} # sub objectOf

sub nodumpOf {				# postgres table names of the flags set on an entry, comma joined
  my ($joinkey, $flagRef) = @_;
  return '' unless ($$flagRef{$joinkey});
  return join("|", sort keys %{ $$flagRef{$joinkey} });
} # sub nodumpOf

sub populateCurator {			# most recent curator timestamp from the history table, per joinkey
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

  foreach my $joinkey (keys %live) { $$curatorRef{$joinkey}{'in_live'} = 1; }	# the entry still exists, so it is not a deleted one
} # sub populateCurator

sub populateConf {			# the reference, object, curator, and flag fields of each datatype, from wormOA.pm
  my %pgTables;
  $result = $dbh->prepare( "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $pgTables{$row[0]}++; }

  foreach my $datatype (@oaDatatypes) {
    my ($fieldsRef, $datatypesRef) = &initModFields($datatype, '');
    unless ($fieldsRef) { die "wormOA.pm has no fields for OA datatype '$datatype'\n"; }
    $conf{$datatype}{'label'} = (defined $$datatypesRef{$datatype}{'label'}) ? $$datatypesRef{$datatype}{'label'} : $$datatypeListRef{$datatype};

    my @paperFields;  my $namedPaper = '';  my $labeledReference = '';  my $curatorField = '';
    foreach my $field (keys %{ $$fieldsRef{$datatype} }) {		# tied hash, so this keeps wormOA.pm order
      my $type          = (defined $$fieldsRef{$datatype}{$field}{'type'})          ? $$fieldsRef{$datatype}{$field}{'type'}          : '';
      my $label         = (defined $$fieldsRef{$datatype}{$field}{'label'})         ? $$fieldsRef{$datatype}{$field}{'label'}         : '';
      my $ontology_type = (defined $$fieldsRef{$datatype}{$field}{'ontology_type'}) ? $$fieldsRef{$datatype}{$field}{'ontology_type'} : '';
      if ($ontology_type eq 'WBPaper') {
        push @paperFields, $field;
        if ($field eq 'paper') { $namedPaper = $field; }
        if ( ($labeledReference eq '') && ($label eq 'Reference') ) { $labeledReference = $field; } }
      if ( ($type eq 'toggle') && ( ($field =~ m/^no.?dump$/i) || ($label =~ m/^no.?dump$/i) ) ) {
        $conf{$datatype}{'nodump_field'} = $field;
        $conf{$datatype}{'nodump_label'} = $label;
        $conf{$datatype}{'flag_fields'}{$field} = 'nodump'; }
      if ($field eq 'curator') { $curatorField = $field; }
    } # foreach my $field (keys %{ $$fieldsRef{$datatype} })
    $conf{$datatype}{'curator_field'} = $curatorField;
    unless ($curatorField) { die "wormOA.pm has no curator field for OA datatype '$datatype'\n"; }

    @{ $conf{$datatype}{'paper_fields'} } = @paperFields;
    if    ($namedPaper ne '')       { $conf{$datatype}{'reference_field'} = $namedPaper;         $conf{$datatype}{'reference_rule'} = 'field_named_paper'; }
    elsif ($labeledReference ne '') { $conf{$datatype}{'reference_field'} = $labeledReference;   $conf{$datatype}{'reference_rule'} = 'label_Reference'; }
    elsif (scalar @paperFields > 0) { $conf{$datatype}{'reference_field'} = $paperFields[0];     $conf{$datatype}{'reference_rule'} = 'first_WBPaper_field'; }
    else                            { $noReferenceDatatypes{$datatype}++; }

    my @objectFields;			# from highestPgidTables, skipping curator and dropdowns
    my @highest = ($$datatypesRef{$datatype}{'highestPgidTables'}) ? @{ $$datatypesRef{$datatype}{'highestPgidTables'} } : ();
    if ($objectFieldOverride{$datatype}) { @highest = ( $objectFieldOverride{$datatype} ); }
    foreach my $field (@highest) {
      next if ($field eq 'curator');
      my $type = (defined $$fieldsRef{$datatype}{$field}{'type'}) ? $$fieldsRef{$datatype}{$field}{'type'} : '';
      next if ($type eq 'dropdown');
      next if ($type eq 'multidropdown');
      push @objectFields, $field; }
    @{ $conf{$datatype}{'object_fields'} } = @objectFields;
    unless (scalar @objectFields > 0) { print "no main object field for OA datatype '$datatype' , its highestPgidTables are " . join(", ", @highest) . "\n"; }

    foreach my $field (sort keys %{ $relatedFlagFields{$datatype} }) { $conf{$datatype}{'flag_fields'}{$field} = 'related'; }

    my @needed = ( $datatype . '_curator', $datatype . '_curator_hst' );
    if ($conf{$datatype}{'reference_field'}) { push @needed, $datatype . '_' . $conf{$datatype}{'reference_field'}; }
    foreach my $field (@objectFields)                          { push @needed, $datatype . '_' . $field; }
    foreach my $field (keys %{ $conf{$datatype}{'flag_fields'} }) { push @needed, $datatype . '_' . $field; }
    foreach my $table (@needed) {
      unless ($pgTables{$table}) { $missingTables{$datatype}{$table}++; } }
    if ($missingTables{$datatype}) { delete $conf{$datatype}{'reference_field'}; }	# cannot query it, so skip the datatype
  } # foreach my $datatype (@oaDatatypes)
} # sub populateConf

sub printByReference {
  open (REF, ">$reffile") or die "Cannot create $reffile : $!";
  print REF join("\t", qw( datatype reference curator curator_timestamp nodump entries nodump_entries distinct_objects curator_source )) . "\n";
  foreach my $datatype (@oaDatatypes) {
    next unless ($byReference{$datatype});
    foreach my $paper (sort keys %{ $byReference{$datatype} }) {
      my $entries        = $byReference{$datatype}{$paper}{'entries'};
      my $nodump_entries = ($byReference{$datatype}{$paper}{'nodump_entries'}) ? $byReference{$datatype}{$paper}{'nodump_entries'} : 0;
      my $objects        = ($byReference{$datatype}{$paper}{'objects'}) ? scalar keys %{ $byReference{$datatype}{$paper}{'objects'} } : 0;
      my $nodump = '';				# flagged only when every entry of this datatype-reference is flagged, matching
      if ($nodump_entries == $entries) { $nodump = 'NODUMP'; }	# how a paper still counts as curated when any one entry is dumpable
      print REF join("\t", $datatype, $paper, $byReference{$datatype}{$paper}{'curator'}, $byReference{$datatype}{$paper}{'timestamp'},
                           $nodump, $entries, $nodump_entries, $objects, $byReference{$datatype}{$paper}{'curator_source'}) . "\n"; } }
  close (REF) or die "Cannot close $reffile : $!";
} # sub printByReference

sub printNodumpFields {
  open (ND, ">$nodumpfile") or die "Cannot create $nodumpfile : $!";
  print ND join("\t", qw( datatype oa_label kind field field_label postgres_table postgres_history_table entries_flagged note )) . "\n";
  foreach my $datatype (@oaDatatypes) {
    foreach my $field (sort keys %{ $conf{$datatype}{'flag_fields'} }) {
      my $kind  = $conf{$datatype}{'flag_fields'}{$field};
      my $table = $datatype . '_' . $field;
      my $label = ($kind eq 'nodump') ? $conf{$datatype}{'nodump_label'} : '';
      my $note  = ($kind eq 'nodump') ? 'the NO DUMP toggle' : $relatedFlagFields{$datatype}{$field};
      my $flagged = ($counts{$datatype}{'flagged'}{$table}) ? $counts{$datatype}{'flagged'}{$table} : 0;
      print ND join("\t", $datatype, $conf{$datatype}{'label'}, $kind, $field, $label, $table, $table . '_hst', $flagged, $note) . "\n"; } }
  close (ND) or die "Cannot close $nodumpfile : $!";
} # sub printNodumpFields

sub printDatatypes {
  open (DT, ">$dtfile") or die "Cannot create $dtfile : $!";
  print DT join("\t", qw( datatype oa_label object_fields reference_field reference_table reference_rule other_wbpaper_fields curator_table curator_history_table nodump_field flag_tables entries rows references entries_nodump entries_without_curator entries_without_object entries_without_reference_value entries_with_curator_and_no_reference entries_timestamp_from_history entries_timestamp_from_live_table )) . "\n";
  foreach my $datatype (@oaDatatypes) {
    my $referenceField = ($conf{$datatype}{'reference_field'}) ? $conf{$datatype}{'reference_field'} : '';
    my $referenceTable = ($referenceField) ? $datatype . '_' . $referenceField : '';
    my $referenceRule  = ($conf{$datatype}{'reference_rule'})  ? $conf{$datatype}{'reference_rule'}  : 'none';
    my @others;
    foreach my $field (@{ $conf{$datatype}{'paper_fields'} }) { next if ($field eq $referenceField); push @others, $field; }
    my @objectTables;
    foreach my $field (@{ $conf{$datatype}{'object_fields'} }) { push @objectTables, $datatype . '_' . $field; }
    my @flagTables;
    foreach my $field (sort keys %{ $conf{$datatype}{'flag_fields'} }) { push @flagTables, $datatype . '_' . $field; }
    my $nodumpField = ($conf{$datatype}{'nodump_field'}) ? $conf{$datatype}{'nodump_field'} : '';
    my @out = ( $datatype, $conf{$datatype}{'label'}, join("|", @objectTables), $referenceField, $referenceTable, $referenceRule, join("|", @others),
                $datatype . '_curator', $datatype . '_curator_hst', $nodumpField, join("|", @flagTables) );
    foreach my $key (qw( entries rows references nodump_entries no_curator no_object no_reference_value curator_no_reference )) {
      push @out, ($counts{$datatype}{$key}) ? $counts{$datatype}{$key} : 0; }
    my $fromHst = 0;  my $fromLive = 0;
    foreach my $source (keys %{ $counts{$datatype}{'curator_source'} }) {
      if ($source eq 'live') { $fromLive += $counts{$datatype}{'curator_source'}{$source}; }
        else                 { $fromHst  += $counts{$datatype}{'curator_source'}{$source}; } }
    push @out, $fromHst, $fromLive;
    print DT join("\t", @out) . "\n"; }
  close (DT) or die "Cannot close $dtfile : $!";
} # sub printDatatypes

sub printSummary {
  my $total_entries = 0;  my $total_references = 0;  my $total_nodump = 0;  my $total_no_curator = 0;  my $total_no_object = 0;
  foreach my $datatype (@oaDatatypes) {
    $total_entries    += ($counts{$datatype}{'entries'})        ? $counts{$datatype}{'entries'}        : 0;
    $total_references += ($counts{$datatype}{'references'})     ? $counts{$datatype}{'references'}     : 0;
    $total_nodump     += ($counts{$datatype}{'nodump_entries'}) ? $counts{$datatype}{'nodump_entries'} : 0;
    $total_no_curator += ($counts{$datatype}{'no_curator'})     ? $counts{$datatype}{'no_curator'}     : 0;
    $total_no_object  += ($counts{$datatype}{'no_object'})      ? $counts{$datatype}{'no_object'}      : 0; }
  print "\n";
  print "output directory : $outdir\n";
  print "OA datatypes in wormOA.pm &populateWormDatatypeList : " . scalar(@oaDatatypes) . "\n";
  print "OA entries with a reference field : $total_entries\n";
  print "datatype-reference rows : $total_rows -> $outfile\n";
  print "datatype-reference pairs : $total_references -> $reffile\n";
  print "entries with a nodump or related flag : $total_nodump , $total_flag_rows rows -> $flagfile\n";
  print "entries with no curator : $total_no_curator , $total_no_curator_rows rows -> $nocuratorfile\n";
  my $total_no_reference = 0;
  foreach my $datatype (@oaDatatypes) { $total_no_reference += ($counts{$datatype}{'curator_no_reference'}) ? $counts{$datatype}{'curator_no_reference'} : 0; }
  print "entries with a curator but no reference : $total_no_reference -> $norefile\n";
  print "entries with no main object id : $total_no_object\n";
  my @withNodump;
  foreach my $datatype (@oaDatatypes) { if ($conf{$datatype}{'nodump_field'}) { push @withNodump, "$datatype ($datatype" . "_$conf{$datatype}{'nodump_field'})"; } }
  print "datatypes with a NO DUMP field : " . scalar(@withNodump) . " -> $nodumpfile\n";
  print "  " . join(", ", @withNodump) . "\n";
  print "per datatype fields and tables -> $dtfile\n";
  foreach my $datatype (@oaDatatypes) {
    foreach my $table (sort keys %{ $counts{$datatype}{'flagged'} }) {
      print "flag table '$table' ($conf{$datatype}{'flag_fields'}{ substr($table, length($datatype) + 1) }) is set on $counts{$datatype}{'flagged'}{$table} entries\n"; } }
  foreach my $datatype (@oaDatatypes) {
    next unless ($counts{$datatype}{'flagged_without_reference'});
    print "OA datatype '$datatype' has $counts{$datatype}{'flagged_without_reference'} flagged entries with no reference, so they are only in $flagfile\n"; }
  foreach my $datatype (@oaDatatypes) {			# a datatype loaded in bulk has little or no curator history to read
    next unless ($counts{$datatype}{'entries'});
    my $fromLive = ($counts{$datatype}{'curator_source'}{'live'}) ? $counts{$datatype}{'curator_source'}{'live'} : 0;
    next unless ($fromLive);
    print "OA datatype '$datatype' has $fromLive of its $counts{$datatype}{'entries'} entries with no row in ${datatype}_curator_hst , so their curator and timestamp come from the live ${datatype}_curator table\n"; }
  foreach my $datatype (sort keys %noReferenceDatatypes) {
    print "OA datatype '$datatype' has no WBPaper field in wormOA.pm , so it has no reference to map to and is not in the output\n"; }
  foreach my $datatype (sort keys %missingTables) {
    foreach my $table (sort keys %{ $missingTables{$datatype} }) {
      print "OA datatype '$datatype' is configured for postgres table '$table' which does not exist, so the datatype is not in the output\n"; } }
} # sub printSummary

sub getSimpleSecDate {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
  $year += 1900; $mon++;
  foreach ($mon, $mday, $hour, $min, $sec) { if ($_ < 10) { $_ = "0$_"; } }
  return "$year$mon$mday" . '_' . "$hour$min$sec";
} # sub getSimpleSecDate
