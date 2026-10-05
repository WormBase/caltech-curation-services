#!/usr/bin/env perl

# Export WormBase person data for a one time transfer to the ABC
# ( https://github.com/alliance-genome/agr_literature_service ) :  laboratories, persons with
# their lab memberships, person lineage, and the verified paper-author-person connections.
# Everything comes from one run, so all files are the same snapshot ;  person creation and
# author verification have to be frozen at WormBase when the final run is made.
#
# Load order at ABC, each file depends on the ones before it :
#   1  laboratory                 ABC laboratory, laboratory_cross_reference, laboratory_allele_designation
#   2  person                     ABC person, person_name, person_email, person_institution,
#                                 person_cross_reference, person_note, laboratory_person
#   3  person_lineage             ABC person_lineage  ( needs both persons )
#   4  person_lineage_submission  ABC person_lineage_submission  ( links to 3 )
#   5  paper_author_person        ABC author.person_id  ( needs persons and references )
#
# Every exported value carries the WormBase curator and timestamp it came from, so the importer
# can set date_created and created_by.  Curators are written as WBPerson ids ( two1 -> WBPerson1 ) ;
# the importer maps those to ABC users.  Timestamps are ISO 8601 with the offset.
#
# Laboratory, from the lab_ OA tables.  Only lab_status Valid labs are exported.
#   lab_name                -> strain_designation, and the WB:<code> cross reference.  WormBase lab
#                              codes are CGC strain designations ;  lab_straindesignation is set for
#                              31 labs and always equals lab_name.  ABC name is left for ABC.
#   lab_mail                -> institution          lab_email  -> email      lab_url -> webpage
#   lab_alleledesignation   -> allele_designations  ( laboratory_allele_designation )
#   lab_remark              -> additional_information   public, it is the .ace Remark
#   lab_comment             -> private_note             internal, it is not in the .ace dump
#   lab_phone lab_fax       not exported, no ABC field
#
# Person, from the two_ tables.  Only two_status Valid persons are exported.  An Invalid person
# merged into another ( two_mergedinto, following chains ) becomes an obsolete WB:WBPerson cross
# reference on the person it ended up in, and so do the two_acqmerge values.  Invalid persons that
# were not merged are not exported.
#   two_standardname                          -> display_name
#   two_firstname two_middlename two_lastname -> names, is_primary true
#   two_aka_firstname _middlename _lastname   -> names, is_primary false
#   two_email                                 -> emails
#   two_old_email + two_old_email_date        -> emails with date_made_old_email
#   two_institution                           -> institutions
#   two_old_institution + two_old_inst_date   -> institutions with date_made_old_institution
#   two_street ( lines joined with newlines ) two_city two_state two_post two_country -> address fields
#   two_webpage                               -> webpage
#   two_orcid                                 -> ORCID:<id> cross reference
#   two_wormbase_comment                      -> biography_research_interest ( public notes,
#                                                joined with newlines, ABC holds one string )
#   two_comment                               -> notes ( person_note, internal notes )
#   two_unsubscribe                           -> unsubscribe true
#   two_hide                                  -> privacy fully_hidden  ( the .ace dump hides these )
#   two_left_field                            -> active_status deceased or retired when the text
#                                                says so, the raw text is always kept under unmapped
#   two_lab two_oldlab two_pis two_oldpis     -> laboratories ( laboratory_person ) : two_lab is a
#                                                current member, two_oldlab sets alum, two_pis sets
#                                                is_pi, two_oldpis sets former_pi, each to the
#                                                timestamp of the WormBase row.  Numeric two_pis are
#                                                CGC numeric PI ids with no lab object, they go
#                                                under unmapped.cgc_numeric_pi
#   under unmapped, exported but with no ABC field :  left_field hide privacy unable_to_contact
#                                                usefulwebpage cgc_numeric_pi
#   not exported :  the phone and fax tables, two_contactdata two_curator_ip two_user_ip two_paper
#
# Person lineage, from two_lineage.  WormBase stores each relationship on both persons ( Phd on the
# supervisor, withPhd on the student, the mirror usually has a 'REV - ' sender ) and has no record
# of who resolved a row.  So :
#   every two_lineage row -> one person_lineage_submission, with two_sender as who_sent_this, the
#     names as sent, and status validated ( both sides are Valid WBPersons ), partially_resolved
#     ( one side, e.g. two_number NO when the other person is not a WBPerson ) or pending ( neither ).
#   every validated relationship -> one person_lineage row, the mirrored pair collapsed into one.
#     person_lineage has no sender field and WormBase has no resolving curator, so created_by is
#     left to the importer ;  the sender survives only on the submissions.
#   Direction is what ABC expects, the subject is the supervisor :  role X on a row means the row's
#   person ( joinkey ) is the supervisor, withX means the other person ( two_number ) is.
#   Collaborated is symmetric, subject is the lower WBPerson number.
#   two_date1 two_date2 are years ( or 'present' for an end ) and are written as the year.
#
# Paper-author-person, from pap_author pap_author_index pap_author_possible pap_author_verified,
# the latest row per author_id and pap_join.  Only YES verifications are exported, who and when
# from pap_author_verified.  The two Raymond Lee script inferences get a verification_method,
# the same text match the .ace dump uses :
#   'YES  Raymond Lee'  ( two spaces )  inferred lab raymond
#   'YES Raymond Lee'   ( one space )   inferred lineage raymond
# NO rows and possible matches with no verification are not exported, only counted.  A person
# merged away is replaced by the person it was merged into.  A person verified on two author
# positions of one paper is listed in .problems.tsv for a curator to resolve before the transfer,
# since ABC allows one author row per reference and person.
#
# Output goes to $outdir, /usr/caltech_curation_files/priv/agr_upload/person , served behind the
# basic auth login at https://caltech-curation.textpressolab.com/files/priv/agr_upload/person/ .
# Not pub, because these hold personal data ( emails, addresses, internal notes, hide requests ),
# do not commit them or copy them to pub.  The 'output' symlink next to this script points there.
# <date> is the run time, and each person_to_abc.latest.<suffix> symlink points at the newest run :
#   person_to_abc.<date>.ABC_IMPORT_INSTRUCTIONS.md      the importer instructions, copied from
#                                                        ABC_IMPORT_INSTRUCTIONS.md next to this script
#   person_to_abc.<date>.laboratory.jsonl                one lab per line
#   person_to_abc.<date>.person.jsonl                    one person per line
#   person_to_abc.<date>.person_lineage.tsv
#   person_to_abc.<date>.person_lineage_submission.tsv
#   person_to_abc.<date>.paper_author_person.tsv
#   person_to_abc.<date>.not_loaded.tsv                  every WormBase field ABC cannot hold, with counts
#   person_to_abc.<date>.problems.tsv                    row level issues, to resolve before transfer, under a
#                                                        commented summary of each kind :  severity, count and why
#   person_to_abc.<date>.character_fixes.tsv             every value whose mojibake was repaired ( see &fixMojibake ),
#                                                        before and after, under a summary of each kind of repair
#   person_to_abc.<date>.counts.tsv                      rows exported and skipped, for the importer to check against
#
# 2026 09 28


use strict;
use diagnostics;
use DBI;
use JSON::XS;
use File::Basename;
use Encode qw( decode FB_CROAK LEAVE_SRC );
use charnames ();
use File::Copy;
use File::Path qw( make_path );
use Cwd qw( abs_path );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $scriptdir = dirname(abs_path($0));
my $outdir    = '/usr/caltech_curation_files/priv/agr_upload/person';	# behind the basic auth login, not pub
make_path($outdir) unless (-d $outdir);
my $date   = &getSimpleSecDate();
my $prefix = "$outdir/person_to_abc.$date";
my @suffixes = qw( ABC_IMPORT_INSTRUCTIONS.md laboratory.jsonl person.jsonl person_lineage.tsv person_lineage_submission.tsv
                   paper_author_person.tsv not_loaded.tsv problems.tsv counts.tsv character_fixes.tsv );

copy("$scriptdir/ABC_IMPORT_INSTRUCTIONS.md", "$prefix.ABC_IMPORT_INSTRUCTIONS.md") or die "Cannot copy ABC_IMPORT_INSTRUCTIONS.md : $!";

my $json = JSON::XS->new->utf8->canonical;

my %notLoaded;		# $notLoaded{source}{field} = { rows, objects, exported, note }
my @notLoadedOrder;	# source and field pairs, in the order they were added
my %counts;

my @problems;		# [ file, key, problem, detail ] , written at the end under a summary
my %charFixes;		# $charFixes{from}{to} = count , the mojibake repairs made by &fixMojibake
my @charFixLines;	# [ where, before, after ] , one per value repaired

    # Mojibake is UTF-8 text that was read as Latin-1 or Windows-1252 somewhere before it reached
    # postgres, so one character became two to four ( an apostrophe U+2019, UTF-8 bytes e2 80 99, is
    # stored as 'â' U+0080 U+0099 ).  A run of such characters is turned back into bytes and decoded
    # as UTF-8, one character at a time ;  a piece is only replaced when its bytes are exactly one
    # valid UTF-8 character, so correct accented text ( 'é' alone is not valid UTF-8 ) is never
    # touched.  Repeated so text mangled twice is repaired too.  Every repair is logged in
    # .character_fixes.tsv .
my %cp1252Byte;		# Windows-1252 characters in 0x80-0x9F, to the byte they stand for
foreach my $byte (0x80 .. 0x9F) {
  my $char = eval { decode('cp1252', chr($byte), FB_CROAK) };
  $cp1252Byte{$char} = $byte if (defined $char); }
my $mojibakeClass = '[\x{80}-\x{FF}' . join('', map { quotemeta } keys %cp1252Byte) . ']';
my $mojibakeRun   = qr/(?:$mojibakeClass){2,}/;

    # why each kind of problem matters, matched against the problem text.  blocks import means the
    # ABC insert will fail until a curator fixes it in WormBase ;  info means the exporter already
    # handled it and it is listed so nothing changes silently.
my @problemWhy = (
  [ qr/^same person verified on more than one author position/, 'blocks import', 'ABC has a unique index on author (reference_id, person_id), so a person can be on a paper once' ],
  [ qr/^ORCID on more than one person/,                         'blocks import', 'ABC person_cross_reference curie must be unique among live cross references ;  usually two WBPersons that are one person and should be merged' ],
  [ qr/^more than one ORCID/,                                   'blocks import', 'ABC allows one live cross reference per person and prefix' ],
  [ qr/^no two_sender/,                                         'blocks import', 'ABC person_lineage_submission.who_sent_this is required' ],
  [ qr/^no last name/,                                          'blocks import', 'ABC person_name.last_name is required' ],
  [ qr/^no standard name/,                                      'fix or importer default', 'ABC person.display_name is required ;  the importer can build it from the primary name' ],
  [ qr/^lab code not ABC/,                                      'fix or importer default', 'ABC validates laboratory WB cross references as WB:<2 or 3 capital letters>' ],
  [ qr/^ORCID not in ABC format/,                               'info', 'ABC validates ORCID:<0000-0000-0000-000X> ;  the value is left out of the export' ],
  [ qr/^Invalid and not merged/,                                'info', 'only Valid persons are exported, and this one was not merged into a Valid person' ],
  [ qr/^not Valid, not exported/,                               'info', 'only Valid labs are exported' ],
  [ qr/^two_acqmerge/,                                          'info', 'merge history that does not match two_mergedinto or a Valid person, so no obsolete cross reference was made from it' ],
  [ qr/^aka name without a last name/,                          'info', 'ABC person_name.last_name is required, so this also known as name is left out' ],
  [ qr/lab code has no Valid WB lab/,                           'info', 'the membership is exported but its laboratory will not exist at ABC, so the importer skips it' ],
  [ qr/without two_.*_date, exported without a date/,           'info', 'an old email or institution with no date it became old ;  exported with date_made_old null, so ABC will read it as current' ],
  [ qr/^role has no ABC relationship/,                          'info', 'the two_role has no person_person_relationship term' ],
  [ qr/is not a person id, left unresolved/,                    'info', 'a typo in the person id, so that side of the submission stays unresolved' ],
  [ qr/^person is Invalid and not merged, left unresolved/,     'info', 'that side of the submission stays unresolved' ],
  [ qr/was merged, used the person it was merged into/,         'info', 'the merged person does not exist at ABC, the person it was merged into does' ],
  [ qr/^date is not a year/,                                    'info', 'lineage dates are expected to be four digit years' ],
  [ qr/^relationship with self/,                                'info', 'both sides are the same person, exported as a rejected submission' ],
  [ qr/differs between rows, used the non REV one/,             'info', 'the original submission and its REV mirror disagree ;  the original sender wins' ],
  [ qr/differs between rows, kept the first/,                   'info', 'repeat submissions disagree ;  the earliest is kept' ],
  [ qr/^author id on more than one paper/,                      'info', 'a WormBase author id should be on one paper ;  the connection is exported for each' ],
  [ qr/^verified author id is on no paper/,                     'info', 'the author was removed from its paper after it was verified, so there is nothing to connect' ],
  [ qr/^verified person is Invalid and not merged/,             'info', 'the person is not exported, so the connection cannot be' ],
  [ qr/^verified on a paper that is not valid/,                 'info', 'invalid papers are not transferred' ],
  [ qr/^no two_status/,                                         'info', 'persons with no status are not exported' ],
);


# persons

my @twoTables = qw( status mergedinto acqmerge standardname firstname middlename lastname aka_firstname aka_middlename aka_lastname
                    email old_email old_email_date institution old_institution old_inst_date street city state post country
                    webpage usefulwebpage orcid wormbase_comment comment unsubscribe hide privacy left_field unable_to_contact
                    lab oldlab pis oldpis );
my %two;		# $two{table}{joinkey}{order} = { value, curator, timestamp }
foreach my $table (@twoTables) { &loadTwoTable($table); }
&loadUnorderedTwoTable('unsubscribe');		# two_unsubscribe has no two_order or two_curator

my %twoCreated;		# $twoCreated{joinkey} = timestamp of the two table row, when the person was made
$result = $dbh->prepare( "SELECT joinkey, two_timestamp FROM two WHERE joinkey ~ '^two[0-9]+\$'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $twoCreated{$row[0]} = &isoTs($row[1]); }

my %personStatus;	# $personStatus{joinkey} = Valid or Invalid, from the lowest order
foreach my $joinkey (keys %{ $two{status} }) {
  my ($order) = sort { $a <=> $b } keys %{ $two{status}{$joinkey} };
  $personStatus{$joinkey} = $two{status}{$joinkey}{$order}{value}; }
foreach my $joinkey (keys %twoCreated) {
  next if ($personStatus{$joinkey});
  &problem('person', &wbPerson($joinkey), 'no two_status', 'in the two table but has no status, not exported'); }

my %labs;		# $labs{code} = lab joinkey, for Valid labs
my %lab;		# $lab{table}{joinkey}{order} = { value, curator, timestamp }
&loadLabs();
&exportLabs();

my %obsoleteXrefs;	# $obsoleteXrefs{joinkey}{merged joinkey} = { curator, timestamp }
&buildMerges();
&exportPersons();


# lineage

&exportLineage();


# paper-author-person

&exportPaperAuthorPerson();


&addNotLoaded('two_mainphone two_labphone two_officephone two_otherphone two_fax', 'phone numbers', &countRows(qw( two_mainphone two_labphone two_officephone two_otherphone two_fax )), '', 'no', 'no ABC field, the .ace dump dropped them in 2022');
&addNotLoaded('two_contactdata', 'contact attempt notes', &countRows('two_contactdata'), '', 'no', 'internal contact tracking, no ABC field');
&addNotLoaded('two_curator_ip two_user_ip', 'form ip addresses', &countRows(qw( two_curator_ip two_user_ip )), '', 'no', 'form bookkeeping');
&addNotLoaded('two_paper', 'legacy person paper list', &countRows('two_paper'), '', 'no', 'superseded by the pap_author tables, which go in paper_author_person');
&addNotLoaded('lab_phone lab_fax', 'lab phone numbers', &countRows(qw( lab_phone lab_fax )), '', 'no', 'no ABC laboratory field');

&writeNotLoaded();
&writeProblems();
&writeCharacterFixes();

open (COUNT, ">:utf8", "$prefix.counts.tsv") or die "Cannot create $prefix.counts.tsv : $!";	# for the importer to check its own counts against
foreach my $key (sort keys %counts) { print "$key\t$counts{$key}\n"; print COUNT "$key\t$counts{$key}\n"; }
close (COUNT) or die "Cannot close $prefix.counts.tsv : $!";
foreach my $suffix (@suffixes) {		# person_to_abc.latest.<suffix> -> this run, relative so it works over http too
  my $link = "$outdir/person_to_abc.latest.$suffix";
  unlink $link if (-l $link);
  symlink("person_to_abc.$date.$suffix", $link) or die "Cannot symlink $link : $!";
  chmod 0644, "$prefix.$suffix"; }
unless (-l "$scriptdir/output") { symlink($outdir, "$scriptdir/output") or print STDERR "Cannot symlink $scriptdir/output : $!\n"; }

print "output in $prefix.*\n";


sub loadTwoTable {
  my ($table) = @_;
  return if ($table eq 'unsubscribe');
  $result = $dbh->prepare( "SELECT joinkey, two_order, two_$table, two_curator, two_timestamp FROM two_$table WHERE joinkey ~ '^two[0-9]+\$' ORDER BY two_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {		# ordered by timestamp, so the latest row for an order wins
    my $value = &cleanValue($row[2], "two_$table $row[0]");
    next if ($value eq '');
    my $order = (defined $row[1] && $row[1] ne '') ? $row[1] : 1;
    $two{$table}{$row[0]}{$order} = { value => $value, curator => &wbPerson($row[3]), timestamp => &isoTs($row[4]) }; }
} # sub loadTwoTable

sub loadUnorderedTwoTable {
  my ($table) = @_;
  $result = $dbh->prepare( "SELECT joinkey, two_$table, two_timestamp FROM two_$table WHERE joinkey ~ '^two[0-9]+\$' ORDER BY two_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $value = &cleanValue($row[1], "two_$table $row[0]");
    next if ($value eq '');
    $two{$table}{$row[0]}{1} = { value => $value, curator => '', timestamp => &isoTs($row[2]) }; }
} # sub loadUnorderedTwoTable

sub loadLabs {
  foreach my $table (qw( name status straindesignation mail email url alleledesignation remark comment )) {
    $result = $dbh->prepare( "SELECT joinkey, lab_order, lab_$table, lab_curator, lab_timestamp FROM lab_$table ORDER BY lab_timestamp" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) {
      my $value = &cleanValue($row[2], "lab_$table $row[0]");
      next if ($value eq '');
      my $order = (defined $row[1] && $row[1] ne '') ? $row[1] : 1;
      $lab{$table}{$row[0]}{$order} = { value => $value, curator => &wbPerson($row[3]), timestamp => &isoTs($row[4]) }; } }
  foreach my $joinkey (keys %{ $lab{name} }) {
    my $status = ($lab{status}{$joinkey}{1}) ? $lab{status}{$joinkey}{1}{value} : '';
    next unless ($status eq 'Valid');
    my $code = $lab{name}{$joinkey}{1}{value};
    unless ($code =~ m/^[A-Z]{2,3}$/) {
      &problem('laboratory', $joinkey, 'lab code not ABC WB:<code> format', $code); }
    $labs{$code} = $joinkey; }
} # sub loadLabs

sub exportLabs {
  open (LAB, ">:raw", "$prefix.laboratory.jsonl") or die "Cannot create $prefix.laboratory.jsonl : $!";
  my $invalid = 0;
  foreach my $joinkey (sort { &numOf($a) <=> &numOf($b) } keys %{ $lab{name} }) {
    my $code = $lab{name}{$joinkey}{1}{value};
    unless ($labs{$code} && $labs{$code} eq $joinkey) {
      $invalid++;
      &problem('laboratory', $joinkey, 'not Valid, not exported', $code);
      next; }
    my %rec;
    $rec{wb_lab_id}            = $joinkey;
    $rec{strain_designation}   = $lab{name}{$joinkey}{1};
    $rec{status}               = { %{ $lab{status}{$joinkey}{1} }, value => 'active' };
    $rec{cross_references}     = [ { curie => "WB:$code", is_obsolete => JSON::XS::false, curator => $lab{name}{$joinkey}{1}{curator}, timestamp => $lab{name}{$joinkey}{1}{timestamp} } ];
    $rec{institution}          = &orderedValues(\%lab, 'mail', $joinkey);
    $rec{email}                = &orderedValues(\%lab, 'email', $joinkey);
    $rec{webpage}              = &orderedValues(\%lab, 'url', $joinkey);
    $rec{allele_designations}  = &orderedValues(\%lab, 'alleledesignation', $joinkey);
    $rec{additional_information} = &joinedValue(\%lab, 'remark', $joinkey, "\n");
    $rec{private_note}         = &joinedValue(\%lab, 'comment', $joinkey, "\n");
    foreach my $key (keys %rec) { delete $rec{$key} unless (defined $rec{$key}); }
    my ($created, $updated) = &dateRange(\%rec);
    $rec{date_created} = $created; $rec{date_updated} = $updated;
    print LAB $json->encode(\%rec) . "\n";
    $counts{'laboratory exported'}++; }
  close (LAB) or die "Cannot close $prefix.laboratory.jsonl : $!";
  &addNotLoaded('lab_status', 'Invalid labs', $invalid, $invalid, 'no', 'only Valid labs are exported, listed in problems');
} # sub exportLabs

sub buildMerges {
  foreach my $joinkey (keys %personStatus) {
    next if ($personStatus{$joinkey} eq 'Valid');
    my ($final, $problem) = &resolvePerson($joinkey);
    unless ($final) {
      &problem('person', &wbPerson($joinkey), 'Invalid and not merged, not exported', $problem);
      $counts{'person invalid not merged'}++;
      next; }
    my ($order) = sort { $a <=> $b } keys %{ $two{mergedinto}{$joinkey} };
    $obsoleteXrefs{$final}{$joinkey} = { curator => $two{mergedinto}{$joinkey}{$order}{curator}, timestamp => $two{mergedinto}{$joinkey}{$order}{timestamp} }; }
  foreach my $joinkey (keys %{ $two{acqmerge} }) {
    foreach my $order (keys %{ $two{acqmerge}{$joinkey} }) {
      my $merged = $two{acqmerge}{$joinkey}{$order}{value};
      $merged =~ s/^WBPerson/two/;
      unless ($merged =~ m/^two\d+$/) {
        &problem('person', &wbPerson($joinkey), 'two_acqmerge not a person id', $merged); next; }
      my ($final) = &resolvePerson($joinkey);
      unless ($final) {
        &problem('person', &wbPerson($joinkey), 'two_acqmerge on a person that is not exported', &wbPerson($merged)); next; }
      if ($personStatus{$merged} && $personStatus{$merged} eq 'Valid') {
        &problem('person', &wbPerson($joinkey), 'two_acqmerge names a Valid person, cross reference not made', &wbPerson($merged)); next; }
      my ($mergedFinal) = ($personStatus{$merged}) ? &resolvePerson($merged) : ('');
      if ($mergedFinal && $mergedFinal ne $final) {
        &problem('person', &wbPerson($joinkey), 'two_acqmerge disagrees with two_mergedinto, used two_mergedinto', &wbPerson($merged) . ' merged into ' . &wbPerson($mergedFinal)); next; }
      next if ($obsoleteXrefs{$final}{$merged});
      $obsoleteXrefs{$final}{$merged} = { curator => $two{acqmerge}{$joinkey}{$order}{curator}, timestamp => $two{acqmerge}{$joinkey}{$order}{timestamp} }; } }
} # sub buildMerges

sub resolvePerson {		# returns the Valid joinkey a person ends up as, following two_mergedinto, or '' and why not
  my ($joinkey) = @_;
  my %seen;
  while (1) {
    return ('', 'no two_status') unless ($personStatus{$joinkey});
    return ($joinkey, '') if ($personStatus{$joinkey} eq 'Valid');
    return ('', 'merge loop') if ($seen{$joinkey}++);
    my ($order) = sort { $a <=> $b } keys %{ $two{mergedinto}{$joinkey} };
    return ('', 'no two_mergedinto') unless (defined $order);
    my $next = $two{mergedinto}{$joinkey}{$order}{value};
    $next =~ s/^WBPerson/two/;
    return ('', "two_mergedinto not a person id $next") unless ($next =~ m/^two\d+$/);
    $joinkey = $next; }
} # sub resolvePerson

sub exportPersons {
  open (PER, ">:raw", "$prefix.person.jsonl") or die "Cannot create $prefix.person.jsonl : $!";
  my %unmappedCount;		# $unmappedCount{field}{rows,persons}
  my ($numericPi, $numericPiPersons) = (0, 0);
  my %leftFieldUnmapped;
  my %orcidPersons;		# $orcidPersons{ORCID curie} = [ WBPerson ids ], ABC needs each live curie on one person
  foreach my $joinkey (sort { &numOf($a) <=> &numOf($b) } keys %personStatus) {
    next unless ($personStatus{$joinkey} eq 'Valid');
    my $wbid = &wbPerson($joinkey);
    my %rec;
    $rec{wb_person_id} = $wbid;

    my @xrefs = ( { curie => "WB:$wbid", is_obsolete => JSON::XS::false, curator => '', timestamp => $twoCreated{$joinkey} || '' } );
    foreach my $merged (sort { &numOf($a) <=> &numOf($b) } keys %{ $obsoleteXrefs{$joinkey} }) {
      push @xrefs, { curie => 'WB:' . &wbPerson($merged), is_obsolete => JSON::XS::true, %{ $obsoleteXrefs{$joinkey}{$merged} } }; }
    foreach my $orcid (@{ &orderedValues(\%two, 'orcid', $joinkey) || [] }) {
      my $id = $orcid->{value}; $id =~ s/^.*orcid\.org\///i; $id =~ s/^ORCID://i;
      unless ($id =~ m/^\d{4}-\d{4}-\d{4}-(\d{3}X|\d{4})$/) {
        &problem('person', $wbid, 'ORCID not in ABC format, not exported', $orcid->{value}); next; }
      push @xrefs, { curie => "ORCID:$id", is_obsolete => JSON::XS::false, curator => $orcid->{curator}, timestamp => $orcid->{timestamp} };
      push @{ $orcidPersons{"ORCID:$id"} }, $wbid; }
    my @personOrcids = grep { $_->{curie} =~ m/^ORCID:/ } @xrefs;
    if (scalar(@personOrcids) > 1) {		# ABC allows one live cross reference per person and prefix
      &problem('person', $wbid, 'more than one ORCID, ABC allows one per person, a curator must resolve before transfer', join(' ', map { $_->{curie} } @personOrcids)); }
    $rec{cross_references} = \@xrefs;

    if ($two{standardname}{$joinkey}) {
      my ($order) = sort { $a <=> $b } keys %{ $two{standardname}{$joinkey} };
      $rec{display_name} = $two{standardname}{$joinkey}{$order}; }

    my @names;
    foreach my $order (sort { $a <=> $b } keys %{ $two{lastname}{$joinkey} }) {
      push @names, &nameRecord($joinkey, $order, '', (scalar(@names) == 0) ? 1 : 0); }
    foreach my $order (sort { $a <=> $b } &unionKeys($two{aka_firstname}{$joinkey}, $two{aka_lastname}{$joinkey})) {
      unless ($two{aka_lastname}{$joinkey}{$order}) {
        &problem('person', $wbid, 'aka name without a last name, not exported', "order $order " . ($two{aka_firstname}{$joinkey}{$order}{value} || '')); next; }
      push @names, &nameRecord($joinkey, $order, 'aka_', 0); }
    $rec{names} = \@names;
    unless ($two{lastname}{$joinkey}) {
      &problem('person', $wbid, 'no last name, ABC person_name needs one', ($rec{display_name}) ? $rec{display_name}{value} : ''); }
    unless ($rec{display_name}) {
      &problem('person', $wbid, 'no standard name, ABC display_name needs one', ''); }

    my @emails = map { { email_address => $_->{value}, date_made_old_email => undef, curator => $_->{curator}, timestamp => $_->{timestamp} } } @{ &orderedValues(\%two, 'email', $joinkey) || [] };
    push @emails, @{ &oldValues($joinkey, 'old_email', 'old_email_date', 'email_address', 'date_made_old_email') };
    $rec{emails} = \@emails if (@emails);
    my @institutions = map { { institution => $_->{value}, date_made_old_institution => undef, curator => $_->{curator}, timestamp => $_->{timestamp} } } @{ &orderedValues(\%two, 'institution', $joinkey) || [] };
    push @institutions, @{ &oldValues($joinkey, 'old_institution', 'old_inst_date', 'institution', 'date_made_old_institution') };
    $rec{institutions} = \@institutions if (@institutions);

    $rec{street_address} = &joinedValue(\%two, 'street', $joinkey, "\n");	# one line per WormBase street line
    $rec{city}           = &joinedValue(\%two, 'city', $joinkey, ', ');
    $rec{state}          = &joinedValue(\%two, 'state', $joinkey, ', ');
    $rec{postal_code}    = &joinedValue(\%two, 'post', $joinkey, ', ');
    $rec{country}        = &joinedValue(\%two, 'country', $joinkey, ', ');
    $rec{webpage}        = &orderedValues(\%two, 'webpage', $joinkey);
    $rec{biography_research_interest} = &joinedValue(\%two, 'wormbase_comment', $joinkey, "\n");
    my $notes = &orderedValues(\%two, 'comment', $joinkey);
    $rec{notes} = [ map { { note => $_->{value}, curator => $_->{curator}, timestamp => $_->{timestamp} } } @$notes ] if ($notes);
    if ($two{unsubscribe}{$joinkey}) { $rec{unsubscribe} = { %{ $two{unsubscribe}{$joinkey}{1} }, value => JSON::XS::true }; }
    if (my $hide = &orderedValues(\%two, 'hide', $joinkey)) { $rec{privacy} = { %{ $hide->[-1] }, value => 'fully_hidden' }; }
    if (my $left = &orderedValues(\%two, 'left_field', $joinkey)) {
      my $text = $left->[-1]{value};
      if    ($text =~ m/deceased/i) { $rec{active_status} = { %{ $left->[-1] }, value => 'deceased' }; }
      elsif ($text =~ m/retired/i)  { $rec{active_status} = { %{ $left->[-1] }, value => 'retired' }; }
      else  { $leftFieldUnmapped{rows}++; } }

    my %unmapped;
    foreach my $field (qw( left_field hide privacy unable_to_contact )) {
      if (my $values = &orderedValues(\%two, $field, $joinkey)) {
        $unmapped{$field} = $values;
        $unmappedCount{$field}{rows} += scalar(@$values); $unmappedCount{$field}{persons}++; } }
    foreach my $order (sort { $a <=> $b } keys %{ $two{usefulwebpage}{$joinkey} }) {
      my $web = ($two{webpage}{$joinkey}{$order}) ? $two{webpage}{$joinkey}{$order}{value} : '';
      push @{ $unmapped{usefulwebpage} }, { %{ $two{usefulwebpage}{$joinkey}{$order} }, value => $web };
      $unmappedCount{usefulwebpage}{rows}++; }
    $unmappedCount{usefulwebpage}{persons}++ if ($unmapped{usefulwebpage});

    my %labMember;		# $labMember{code} = laboratory_person record
    foreach my $pair ( [ 'lab', 'member' ], [ 'oldlab', 'alum' ], [ 'pis', 'is_pi' ], [ 'oldpis', 'former_pi' ] ) {
      my ($table, $field) = @$pair;
      foreach my $value (@{ &orderedValues(\%two, $table, $joinkey) || [] }) {
        my $code = $value->{value};
        if ($code =~ m/^\d+$/) {
          push @{ $unmapped{cgc_numeric_pi} }, { %$value, source => "two_$table" };
          $numericPi++; next; }
        unless ($labMember{$code}) {
          $labMember{$code} = { laboratory => "WB:$code", curator => $value->{curator}, timestamp => $value->{timestamp},
                                is_pi => undef, former_pi => undef, alum => undef };
          unless ($labs{$code}) {
            &problem('person', $wbid, "two_$table lab code has no Valid WB lab", $code); } }
        next if ($field eq 'member');
        $labMember{$code}{$field} = $value->{timestamp}; } }
    $numericPiPersons++ if ($unmapped{cgc_numeric_pi});
    $rec{laboratories} = [ map { $labMember{$_} } sort keys %labMember ] if (%labMember);
    $rec{unmapped} = \%unmapped if (%unmapped);

    foreach my $key (keys %rec) { delete $rec{$key} unless (defined $rec{$key}); }
    my (undef, $updated) = &dateRange(\%rec);
    $rec{date_created} = $twoCreated{$joinkey} || '';
    $rec{date_updated} = $updated;
    print PER $json->encode(\%rec) . "\n";
    $counts{'person exported'}++; }
  close (PER) or die "Cannot close $prefix.person.jsonl : $!";
  foreach my $curie (sort keys %orcidPersons) {
    next unless (scalar(@{ $orcidPersons{$curie} }) > 1);
    $counts{'person ORCID on more than one person'}++;
    &problem('person', $curie, 'ORCID on more than one person, ABC allows it on one, a curator must resolve before transfer', join(' ', @{ $orcidPersons{$curie} })); }

  &addNotLoaded('two_left_field', 'left the field text', $unmappedCount{left_field}{rows} || 0, $unmappedCount{left_field}{persons} || 0, 'unmapped', ($leftFieldUnmapped{rows} || 0) . ' are not deceased or retired and set no active_status ;  for the rest the text ( e.g. a year of death ) is lost');
  &addNotLoaded('two_hide', 'reason for hiding', $unmappedCount{hide}{rows} || 0, $unmappedCount{hide}{persons} || 0, 'unmapped', 'privacy is set to fully_hidden, the reason text has no ABC field');
  &addNotLoaded('two_privacy', 'privacy entries', $unmappedCount{privacy}{rows} || 0, $unmappedCount{privacy}{persons} || 0, 'unmapped', 'mostly email addresses, some requests not to be listed ;  no ABC field, the importer decides');
  &addNotLoaded('two_unable_to_contact', 'unable to contact', $unmappedCount{unable_to_contact}{rows} || 0, $unmappedCount{unable_to_contact}{persons} || 0, 'unmapped', 'no ABC field');
  &addNotLoaded('two_usefulwebpage', 'useful webpage flag', $unmappedCount{usefulwebpage}{rows} || 0, $unmappedCount{usefulwebpage}{persons} || 0, 'unmapped', 'the webpage itself is exported, ABC webpage has no flag');
  &addNotLoaded('two_pis two_oldpis', 'CGC numeric PI ids', $numericPi, $numericPiPersons, 'unmapped', 'numeric PI ids with no lab object, ABC laboratory_person needs a laboratory');
  &addNotLoaded('two_wormbase_comment', 'curator and timestamp of each comment', &countRows('two_wormbase_comment'), '', 'text yes', 'the comment text is all exported, joined with newlines into biography_research_interest ;  ABC holds one string, so only the latest curator and timestamp survive, not one per comment');
  &addNotLoaded('two_street', 'curator and timestamp of each street line', &countRows('two_street'), '', 'text yes', 'the street lines are all exported, joined with newlines into street_address ;  only the latest curator and timestamp survive, not one per line');
  &addNotLoaded('two_status', 'Invalid persons not merged', $counts{'person invalid not merged'} || 0, $counts{'person invalid not merged'} || 0, 'no', 'listed in problems');
} # sub exportPersons

sub nameRecord {
  my ($joinkey, $order, $aka, $isPrimary) = @_;
  my %name = ( is_primary => ($isPrimary) ? JSON::XS::true : JSON::XS::false );
  my @stamps;
  foreach my $pair ( [ 'firstname', 'first_name' ], [ 'middlename', 'middle_name' ], [ 'lastname', 'last_name' ] ) {
    my ($table, $field) = @$pair;
    my $entry = $two{"$aka$table"}{$joinkey}{$order};
    $name{$field} = ($entry) ? $entry->{value} : undef;
    push @stamps, $entry if ($entry); }
  my ($latest) = sort { $b->{timestamp} cmp $a->{timestamp} } @stamps;
  $name{curator}   = $latest->{curator};
  $name{timestamp} = $latest->{timestamp};
  return \%name;
} # sub nameRecord

sub oldValues {		# old emails or institutions, with the date they became old from the matching order
  my ($joinkey, $table, $dateTable, $field, $dateField) = @_;
  my @out;
  foreach my $order (sort { $a <=> $b } keys %{ $two{$table}{$joinkey} }) {
    my $entry = $two{$table}{$joinkey}{$order};
    my $old = ($two{$dateTable}{$joinkey}{$order}) ? &isoTs($two{$dateTable}{$joinkey}{$order}{value}) : undef;
    unless ($old) {
      &problem('person', &wbPerson($joinkey), "two_$table without two_$dateTable, exported without a date", "order $order $entry->{value}"); }
    push @out, { $field => $entry->{value}, $dateField => $old, curator => $entry->{curator}, timestamp => $entry->{timestamp} }; }
  return \@out;
} # sub oldValues

sub exportLineage {
  my %relationship = (
    'Phd'                 => 'PhD Supervisor of',
    'Postdoc'             => 'Postdoc Supervisor of',
    'Masters'             => "Master's Supervisor of",
    'Undergrad'           => 'Undergraduate Supervisor of',
    'Highschool'          => 'High School Supervisor of',
    'Sabbatical'          => 'Sabbatical Supervisor of',
    'Lab_visitor'         => 'Lab Visitor Supervisor of',
    'Research_staff'      => 'Research Staff Supervisor of',
    'Assistant_professor' => 'Assistant Professor Supervisor of',
    'Unknown'             => 'Unknown Role Supervisor of',
    'Collaborated'        => 'Collaborator of' );

  open (SUB, ">:utf8", "$prefix.person_lineage_submission.tsv") or die "Cannot create $prefix.person_lineage_submission.tsv : $!";
  print SUB join("\t", qw( submission_id person_subject_name person_object_name person_subject person_object relationship
                           who_sent_this start_date end_date status person_lineage_key date_created
                           wb_joinkey wb_number wb_role )) . "\n";

  my %canonical;		# $canonical{key} = { subject, object, relationship, start_date, end_date, date_created, date_updated, submissions }
  my $submissionId = 0;
  $result = $dbh->prepare( "SELECT joinkey, two_sentname, two_othername, two_number, two_role, two_date1, two_date2, two_sender, two_timestamp FROM two_lineage ORDER BY two_timestamp, joinkey, two_number" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $sentname, $othername, $number, $role, $date1, $date2, $sender, $timestamp) = map { &cleanValue($_, 'two_lineage ' . join(' ', map { (defined $_) ? $_ : '' } @row[0, 3, 4])) } @row;
    $submissionId++;
    my $isWith = ($role =~ s/^with//) ? 1 : 0;
    my $rel = $relationship{$role};
    unless ($rel) {
      &problem('person_lineage_submission', $submissionId, 'role has no ABC relationship, not exported', $row[4]); next; }
    my ($rowPerson)   = ($joinkey =~ m/^two\d+$/) ? &resolvePerson($joinkey) : ('');
    my ($otherPerson) = ($number  =~ m/^two\d+$/) ? &resolvePerson($number)  : ('');
    if ($number ne '' && $number ne 'NO' && $number !~ m/^two\d+$/) {
      &problem('person_lineage_submission', $submissionId, 'two_number is not a person id, left unresolved', "'$number' on " . ($joinkey || 'no joinkey')); }
    if ($joinkey ne '' && $joinkey ne 'NO' && $joinkey !~ m/^two\d+$/) {
      &problem('person_lineage_submission', $submissionId, 'joinkey is not a person id, left unresolved', "'$joinkey' with " . ($number || 'no two_number')); }
    foreach my $pair ( [ $joinkey, $rowPerson ], [ $number, $otherPerson ] ) {
      my ($raw, $resolved) = @$pair;
      next unless ($raw =~ m/^two\d+$/);
      if (!$resolved) {
        &problem('person_lineage_submission', $submissionId, 'person is Invalid and not merged, left unresolved', &wbPerson($raw)); }
      elsif ($resolved ne $raw) {
        &problem('person_lineage_submission', $submissionId, 'person was merged, used the person it was merged into', &wbPerson($raw) . ' -> ' . &wbPerson($resolved)); } }

    my ($subjectName, $objectName, $subject, $object) = ($isWith) ?
      ($othername, $sentname, $otherPerson, $rowPerson) : ($sentname, $othername, $rowPerson, $otherPerson);
    if ($rel eq 'Collaborator of' && $subject && $object && &numOf($object) < &numOf($subject)) {
      ($subjectName, $objectName, $subject, $object) = ($objectName, $subjectName, $object, $subject); }
    my $end = ($date2 eq 'present') ? '' : $date2;
    foreach my $year ($date1, $end) {
      if ($year ne '' && $year !~ m/^\d{4}$/) {
        &problem('person_lineage_submission', $submissionId, 'date is not a year', $year); } }
    if ($sender eq '') {
      &problem('person_lineage_submission', $submissionId, 'no two_sender, ABC who_sent_this is required', ($joinkey || 'no joinkey') . " $row[4] " . ($number || '')); }

    my ($status, $key) = ('pending', '');
    if ($subject && $object && $subject eq $object) {
      $status = 'rejected';
      &problem('person_lineage_submission', $submissionId, 'relationship with self, rejected', &wbPerson($subject)); }
    elsif ($subject && $object) {
      $status = 'validated';
      $key = join('|', &wbPerson($subject), &wbPerson($object), $rel);
      my $iso = &isoTs($timestamp);
      unless ($canonical{$key}) {
        $canonical{$key} = { subject => &wbPerson($subject), object => &wbPerson($object), relationship => $rel,
                             start_date => '', end_date => '', date_created => $iso, date_updated => $iso, submissions => 0, dateSource => '' }; }
      my $canon = $canonical{$key};
      $canon->{submissions}++;
      $canon->{date_updated} = $iso if ($iso gt $canon->{date_updated});
      my $isRev = ($sender =~ m/^REV\b/) ? 1 : 0;
      foreach my $pair ( [ 'start_date', $date1 ], [ 'end_date', $end ] ) {
        my ($field, $year) = @$pair;
        next if ($year eq '');
        if ($canon->{$field} eq '') { $canon->{$field} = $year; $canon->{"${field}_rev"} = $isRev; }
        elsif ($canon->{$field} ne $year) {
          if ($canon->{"${field}_rev"} && !$isRev) {	# the original submission wins over a REV mirror
            &problem('person_lineage', $key, "$field differs between rows, used the non REV one", "$canon->{$field} replaced by $year");
            $canon->{$field} = $year; $canon->{"${field}_rev"} = 0; }
          else {
            &problem('person_lineage', $key, "$field differs between rows, kept the first", "$canon->{$field} kept, $year not used"); } } } }
    elsif ($subject || $object) { $status = 'partially_resolved'; }
    $counts{"person_lineage_submission $status"}++;

    print SUB join("\t", map { &tsv($_) } $submissionId, $subjectName, $objectName, ($subject) ? &wbPerson($subject) : '', ($object) ? &wbPerson($object) : '',
                   $rel, $sender, $date1, $end, $status, $key, &isoTs($timestamp), $joinkey, $number, $row[4]) . "\n"; }
  close (SUB) or die "Cannot close $prefix.person_lineage_submission.tsv : $!";

  open (LIN, ">:utf8", "$prefix.person_lineage.tsv") or die "Cannot create $prefix.person_lineage.tsv : $!";
  print LIN join("\t", qw( person_lineage_key person_subject person_object relationship start_date end_date date_created date_updated submissions )) . "\n";
  foreach my $key (sort keys %canonical) {
    my $c = $canonical{$key};
    print LIN join("\t", map { &tsv($_) } $key, @$c{qw( subject object relationship start_date end_date date_created date_updated submissions )}) . "\n";
    $counts{'person_lineage exported'}++; }
  close (LIN) or die "Cannot close $prefix.person_lineage.tsv : $!";

  &addNotLoaded('two_lineage', 'lineage sender on the relationship', $counts{'person_lineage exported'} || 0, '', 'submission only',
                'person_lineage has no sender field and WormBase records no curator who resolved a row, so created_by is left to the importer ;  two_sender is kept on person_lineage_submission.who_sent_this');
  &addNotLoaded('two_lineage', 'two_date1 two_date2', '', '', 'yes', 'years only, ABC start_date end_date are dates ;  written as the year for the importer to convert');
} # sub exportLineage

sub exportPaperAuthorPerson {
  my %paperValid;
  $result = $dbh->prepare( "SELECT joinkey, pap_status FROM pap_status" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $paperValid{$row[0]} = ($row[1] eq 'valid') ? 1 : 0; }

  my %authorPapers;		# $authorPapers{author_id} = [ [ paper, order ] ]
  $result = $dbh->prepare( "SELECT joinkey, pap_author, pap_order FROM pap_author ORDER BY joinkey, pap_order" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { push @{ $authorPapers{$row[1]} }, [ $row[0], $row[2] ]; }
  foreach my $authorId (keys %authorPapers) {
    next unless (scalar(@{ $authorPapers{$authorId} }) > 1);
    &problem('paper_author_person', $authorId, 'author id on more than one paper, exported on each', join(' ', map { "WBPaper$_->[0]" } @{ $authorPapers{$authorId} })); }

  my %authorName;
  $result = $dbh->prepare( "SELECT author_id, pap_author_index FROM pap_author_index ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $name = &cleanValue($row[1], "pap_author_index $row[0]"); $name =~ s/\s+-COMMENT.*$//;
    $authorName{$row[0]} = $name; }

  my %possible;		# $possible{author_id}{join} = joinkey, the latest
  $result = $dbh->prepare( "SELECT author_id, pap_join, pap_author_possible FROM pap_author_possible ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $possible{$row[0]}{$row[1] || 0} = &cleanValue($row[2]); }

  my %verified;		# $verified{author_id}{join} = { text, curator, timestamp }, the latest
  $result = $dbh->prepare( "SELECT author_id, pap_join, pap_author_verified, pap_curator, pap_timestamp FROM pap_author_verified ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $verified{$row[0]}{$row[1] || 0} = { text => (defined $row[2]) ? $row[2] : '', curator => &wbPerson($row[3]), timestamp => &isoTs($row[4]) }; }

  open (PAP, ">:utf8", "$prefix.paper_author_person.tsv") or die "Cannot create $prefix.paper_author_person.tsv : $!";
  print PAP join("\t", qw( reference author_order author_name person verified verification_method curator timestamp wb_author_id wb_pap_join )) . "\n";
  my %paperPerson;		# $paperPerson{paper}{person} = [ author positions ], for the duplicate check
  my %possibleOnly;
  foreach my $authorId (sort { $a <=> $b } keys %possible) {
    foreach my $join (sort { $a <=> $b } keys %{ $possible{$authorId} }) {
      my $person = $possible{$authorId}{$join};
      next unless ($person =~ m/^two\d+$/);
      my $v = $verified{$authorId}{$join};
      unless ($v && $v->{text} =~ m/^(YES|NO)/) { $counts{'paper_author_person possible without verification'}++; $possibleOnly{$person}++; next; }
      if ($v->{text} =~ m/^NO/) { $counts{'paper_author_person NO not exported'}++; next; }
      unless ($authorPapers{$authorId}) {
        &problem('paper_author_person', $authorId, 'verified author id is on no paper, not exported', &wbPerson($person)); next; }
      my ($final) = &resolvePerson($person);
      unless ($final) {
        &problem('paper_author_person', $authorId, 'verified person is Invalid and not merged, not exported', &wbPerson($person)); next; }
      if ($final ne $person) {
        &problem('paper_author_person', $authorId, 'verified person was merged, used the person it was merged into', &wbPerson($person) . ' -> ' . &wbPerson($final)); }
      my $method = '';
      if    ($v->{text} =~ m/^YES  Raymond Lee\s*$/) { $method = 'inferred lab raymond'; }
      elsif ($v->{text} =~ m/^YES Raymond Lee\s*$/)  { $method = 'inferred lineage raymond'; }
      foreach my $paperOrder (@{ $authorPapers{$authorId} }) {
        my ($paper, $order) = @$paperOrder;
        unless ($paperValid{$paper}) {
          $counts{'paper_author_person on invalid paper not exported'}++;
          &problem('paper_author_person', "WBPaper$paper", 'verified on a paper that is not valid, not exported', &wbPerson($final) . " author $authorId"); next; }
        push @{ $paperPerson{$paper}{$final} }, $order;
        print PAP join("\t", map { &tsv($_) } "WB:WBPaper$paper", $order, $authorName{$authorId} || '', &wbPerson($final), $v->{text}, $method,
                       $v->{curator}, $v->{timestamp}, $authorId, $join) . "\n";
        $counts{'paper_author_person exported'}++;
        $counts{"paper_author_person exported $method"}++ if ($method); } } }
  close (PAP) or die "Cannot close $prefix.paper_author_person.tsv : $!";

  foreach my $paper (sort keys %paperPerson) {
    foreach my $person (sort keys %{ $paperPerson{$paper} }) {
      next unless (scalar(@{ $paperPerson{$paper}{$person} }) > 1);
      $counts{'paper_author_person same person on two author positions'}++;
      &problem('paper_author_person', "WBPaper$paper", 'same person verified on more than one author position, a curator must resolve before transfer',
                      &wbPerson($person) . ' author_order ' . join(' ', sort { $a <=> $b } @{ $paperPerson{$paper}{$person} })); } }

  &addNotLoaded('pap_author_possible', 'possible matches not verified', $counts{'paper_author_person possible without verification'} || 0, scalar(keys %possibleOnly), 'no', 'only verified YES connections are sent');
  &addNotLoaded('pap_author_verified', 'NO verifications', $counts{'paper_author_person NO not exported'} || 0, '', 'no', 'ABC author has no field for a person who is not this author');
  &addNotLoaded('pap_author_possible', 'who proposed a match and when', '', '', 'no', 'ABC author has one person_id ;  the verification curator and timestamp are sent, the proposal ones are not');
  &addNotLoaded('pap_author_verified', 'verification method', ($counts{'paper_author_person exported inferred lab raymond'} || 0) + ($counts{'paper_author_person exported inferred lineage raymond'} || 0), '', 'yes', 'in verification_method, ABC author has no field for it, the importer decides');
} # sub exportPaperAuthorPerson


sub orderedValues {		# the entries of a table for a joinkey, in order, or undef when there are none
  my ($data, $table, $joinkey) = @_;
  return undef unless ($data->{$table}{$joinkey});
  return [ map { $data->{$table}{$joinkey}{$_} } sort { $a <=> $b } keys %{ $data->{$table}{$joinkey} } ];
} # sub orderedValues

sub joinedValue {		# the entries of a table joined into one value, with the latest curator and timestamp
  my ($data, $table, $joinkey, $separator) = @_;
  my $values = &orderedValues($data, $table, $joinkey);
  return undef unless ($values);
  my ($latest) = sort { $b->{timestamp} cmp $a->{timestamp} } @$values;
  return { value => join($separator, map { $_->{value} } @$values), curator => $latest->{curator}, timestamp => $latest->{timestamp} };
} # sub joinedValue

sub dateRange {		# earliest and latest timestamp anywhere in a record
  my ($rec) = @_;
  my @stamps;
  my @queue = ($rec);
  while (my $item = shift @queue) {
    if (ref $item eq 'HASH') {
      foreach my $key (keys %$item) {
        if ($key eq 'timestamp' && defined $item->{$key} && $item->{$key} ne '') { push @stamps, $item->{$key}; }
        elsif (ref $item->{$key}) { push @queue, $item->{$key}; } } }
    elsif (ref $item eq 'ARRAY') { push @queue, @$item; } }
  @stamps = sort @stamps;
  return ($stamps[0] || '', $stamps[-1] || '');
} # sub dateRange

sub unionKeys {
  my %keys;
  foreach my $hash (@_) { next unless ($hash); $keys{$_}++ foreach (keys %$hash); }
  return keys %keys;
} # sub unionKeys

sub countRows {
  my $total = 0;
  foreach my $table (@_) {
    my $count = $dbh->prepare( "SELECT count(*) FROM $table" );
    $count->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    my ($n) = $count->fetchrow; $total += $n; }
  return $total;
} # sub countRows

sub addNotLoaded {
  my ($source, $field, $rows, $objects, $exported, $note) = @_;
  push @notLoadedOrder, [ $source, $field ];
  $notLoaded{$source}{$field} = { rows => $rows, objects => $objects, exported => $exported, note => $note };
} # sub addNotLoaded

sub writeNotLoaded {
  open (NOT, ">:utf8", "$prefix.not_loaded.tsv") or die "Cannot create $prefix.not_loaded.tsv : $!";
  print NOT join("\t", qw( wormbase_source data rows objects exported note )) . "\n";
  print NOT "#\texported : no = not in any file,  unmapped = in the person unmapped section,  yes = exported but changed,  text yes = the text is exported and only its per value curator and timestamp are lost,  submission only = on person_lineage_submission\n";
  foreach my $pair (@notLoadedOrder) {
    my ($source, $field) = @$pair;
    my $n = $notLoaded{$source}{$field};
    print NOT join("\t", map { &tsv($_) } $source, $field, $n->{rows}, $n->{objects}, $n->{exported}, $n->{note}) . "\n"; }
  close (NOT) or die "Cannot close $prefix.not_loaded.tsv : $!";
} # sub writeNotLoaded

sub cleanValue {		# trimmed, mojibake repaired, with the literal NULL that some tables hold treated as blank
  my ($value, $where) = @_;
  return '' unless (defined $value);
  $value =~ s/^\s+//; $value =~ s/\s+$//;
  return '' if ($value eq 'NULL');
  $value = &fixMojibake($value, $where) if ($where && $value =~ m/[^\x00-\x7F]/);
  return $value;
} # sub cleanValue

sub fixMojibake {
  my ($value, $where) = @_;
  my $original = $value;
  foreach (1 .. 4) {
    my $before = $value;
    $value =~ s/($mojibakeRun)/&decodeMojibakeRun($1)/ge;
    last if ($value eq $before); }
    # an 'â' whose two following bytes were lost before postgres, so it can not be decoded.  Only the
    # two shapes seen in the data are repaired :  a contraction ( donât -> don't ), and a lone one
    # between spaces, which was a dash.  An 'â' inside a word is left alone, it is real in names
    # like Câmara or Lâm .
  if (my $n = ($value =~ s/(?<=[A-Za-z]n)\x{E2}(?=t\b)/'/g)) { $charFixes{"\x{E2} in n\x{E2}t, bytes lost"}{"'"} += $n; }
  if (my $n = ($value =~ s/(?<= )\x{E2}(?= )/-/g))          { $charFixes{"\x{E2} alone between spaces, bytes lost"}{'-'} += $n; }
  if ($value ne $original) { push @charFixLines, [ $where, $original, $value ]; }
  return $value;
} # sub fixMojibake

sub decodeMojibakeRun {
  my ($run) = @_;
  my @chars = split //, $run;
  my $bytes = join('', map { chr( (defined $cp1252Byte{$_}) ? $cp1252Byte{$_} : ord($_) ) } @chars);
  my $out = ''; my $i = 0;
  while ($i < length($bytes)) {
    my $done = 0;
    foreach my $length (4, 3, 2) {
      next if ($i + $length > length($bytes));
      my $piece = substr($bytes, $i, $length);
      my $char = eval { decode('UTF-8', $piece, FB_CROAK | LEAVE_SRC) };
      next unless (defined $char && length($char) == 1 && ord($char) > 0x7F);
      $char = "'" if ($char eq "\x{2019}" || $char eq "\x{2018}");	# curly apostrophes become the plain one
      $char = '-' if ($char =~ m/^[\x{2010}-\x{2015}]$/);		# hyphens and dashes become the plain one
      $char = '"' if ($char eq "\x{201C}" || $char eq "\x{201D}");	# curly double quotes become the plain one
      $char = ' ' if ($char =~ m/^[\x{00A0}\x{2000}-\x{200A}\x{202F}]$/);	# no-break, thin and other spaces become a plain space
      $charFixes{ join('', @chars[$i .. $i + $length - 1]) }{$char}++;
      $out .= $char; $i += $length; $done = 1; last; }
    unless ($done) { $out .= $chars[$i]; $i++; } }
  return $out;
} # sub decodeMojibakeRun

sub showChars {		# a string with its invisible characters made visible, for the fix report
  my ($text) = @_;
  $text =~ s/([\x{00}-\x{1F}\x{7F}-\x{9F}\x{A0}\x{AD}\x{2000}-\x{200F}\x{2011}])/sprintf('<U+%04X>', ord($1))/ge;
  return $text;
} # sub showChars

sub writeCharacterFixes {
  open (FIX, ">:utf8", "$prefix.character_fixes.tsv") or die "Cannot create $prefix.character_fixes.tsv : $!";
  print FIX "# Mojibake repaired by the exporter :  UTF-8 text that had been read as Latin-1 or Windows-1252,\n";
  print FIX "# so one character was stored as two to four.  Invisible characters are shown as <U+XXXX>.\n";
  print FIX "# " . scalar(@charFixLines) . " values repaired.  Each kind of repair :\n";
  print FIX "#\tcount\tstored as\trepaired to\tcharacter\n";
  my @kinds;
  foreach my $from (keys %charFixes) { foreach my $to (keys %{ $charFixes{$from} }) { push @kinds, [ $charFixes{$from}{$to}, $from, $to ]; } }
  foreach my $kind (sort { $b->[0] <=> $a->[0] || $a->[1] cmp $b->[1] } @kinds) {
    my ($count, $from, $to) = @$kind;
    my $name = charnames::viacode(ord($to)) || sprintf('U+%04X', ord($to));	# ASCII ' and - have names too
    print FIX join("\t", '#', $count, &showChars($from), &showChars($to), sprintf('U+%04X %s', ord($to), $name)) . "\n"; }
  print FIX join("\t", qw( where before after )) . "\n";
  foreach my $line (@charFixLines) {
    print FIX join("\t", map { &tsv(&showChars($_)) } @$line) . "\n"; }
  close (FIX) or die "Cannot close $prefix.character_fixes.tsv : $!";
} # sub writeCharacterFixes

sub problem {
  my ($file, $key, $problem, $detail) = @_;
  push @problems, [ $file, $key, $problem, (defined $detail) ? $detail : '' ];
} # sub problem

sub writeProblems {
  open (PROB, ">:utf8", "$prefix.problems.tsv") or die "Cannot create $prefix.problems.tsv : $!";
  my %summary;		# $summary{file}{problem} = count
  foreach my $p (@problems) { $summary{ $p->[0] }{ $p->[2] }++; }
  my @rows;
  foreach my $file (keys %summary) {
    foreach my $problem (keys %{ $summary{$file} }) {
      my ($severity, $why) = ('info', 'no explanation in @problemWhy, add one');
      foreach my $rule (@problemWhy) { if ($problem =~ $rule->[0]) { ($severity, $why) = ($rule->[1], $rule->[2]); last; } }
      push @rows, [ $severity, $file, $problem, $summary{$file}{$problem}, $why ]; } }
  my %severityOrder = ( 'blocks import' => 0, 'fix or importer default' => 1, 'info' => 2 );
  print PROB "# Summary of the problems below.  blocks import :  the ABC insert fails until a curator fixes it in WormBase\n";
  print PROB "# and the export is re-run.  fix or importer default :  fix it, or the importer has to supply a value.\n";
  print PROB "# info :  already handled by the exporter, listed so nothing changes silently.\n";
  print PROB "#\t" . join("\t", qw( severity file problem count why )) . "\n";
  foreach my $row (sort { $severityOrder{$a->[0]} <=> $severityOrder{$b->[0]} || $a->[1] cmp $b->[1] || $b->[3] <=> $a->[3] } @rows) {
    print PROB "#\t" . join("\t", map { &tsv($_) } @$row) . "\n"; }
  print PROB join("\t", qw( file key problem detail )) . "\n";
  foreach my $p (@problems) { print PROB join("\t", map { &tsv($_) } @$p) . "\n"; }
  close (PROB) or die "Cannot close $prefix.problems.tsv : $!";
} # sub writeProblems

sub tsv {		# a value safe for a tab delimited line
  my ($value) = @_;
  return '' unless (defined $value);
  $value =~ s/[\t\r\n]+/ /g;
  return $value;
} # sub tsv

sub isoTs {		# postgres timestamp to ISO 8601, '2026-09-25 17:53:18.15-07' -> '2026-09-25T17:53:18.15-07:00'
  my ($ts) = @_;
  return '' unless (defined $ts && $ts ne '');
  $ts =~ s/^\s+//; $ts =~ s/\s+$//;
  $ts =~ s/^(\d{4}-\d\d-\d\d) (\d)/$1T$2/;
  $ts =~ s/([+-]\d\d)$/$1:00/;
  return $ts;
} # sub isoTs

sub wbPerson {
  my ($id) = @_;
  return '' unless (defined $id);
  $id =~ s/^two(\d+)$/WBPerson$1/;
  return $id;
} # sub wbPerson

sub numOf {
  my ($id) = @_;
  my ($n) = $id =~ m/(\d+)/;
  return $n || 0;
} # sub numOf

sub getSimpleSecDate {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
  $year += 1900; $mon++;
  foreach ($mon, $mday, $hour, $min, $sec) { if ($_ < 10) { $_ = "0$_"; } }
  return "$year$mon$mday" . '_' . "$hour$min$sec";
} # sub getSimpleSecDate
