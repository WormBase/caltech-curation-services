#!/usr/bin/env perl

# parse seq feat data from nightly geneace
#
# http://wiki.wormbase.org/index.php/Sequence_Feature#OA_interface
# /home/postgres/work/pgpopulation/obo_oa_ontologies/geneace/nightly_geneace.pl
#
# repopulate sqf_ tables for values that have changed.
# email Daniela + Xiaodong about new objects, or previous objects that have changed papers.
# compare sanger FTP file with previous version.  If different compare each .ace entry, and
# for each different one delete pgid from postgres and enter new values.  2014 09 25
#
# live on tazendra.  2014 10 01
#
# exprpattern and intid tables removed because the data shouldn't be in geneace anymore, so
# moved from %tagToField to %tagToIgnore   2014 12 16
#
# email daniela any objects that are in the OA but not in the hinxton file.  2015 12 15
#
# replace ftp location, was probably failing for a while  2021 10 22
# 
# added inside cronjob 
# 0 20 * * * /home/postgres/work/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl
#
# dockerized, will require transfer of
# /home/postgres/work/pgpopulation/sqf_sequencefeature/populate_from_geneace/prev_features.ace.gz
# to /usr/caltech_curation_files/daniela/sqf_sequencefeature/prev_features.ace.gz
# when going live.  Do not back up that directory.  2023 03 20

# added inside cronjob 
# 0 20 * * * /usr/lib/scripts/pgpopulation/obo_oa_ontologies/update_obo_oa_ontologies.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use Jex;	# mailer
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my $highestPgid = 0;
my %pgData;
$result = $dbh->prepare( "SELECT * FROM sqf_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[0] > $highestPgid) { $highestPgid = $row[0]; }
    $pgData{pgidToName}{$row[0]} = $row[1];
    $pgData{nameToPgid}{$row[1]} = $row[0]; } }
$result = $dbh->prepare( "SELECT * FROM sqf_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $pgData{pgidToPaper}{$row[0]} = $row[1]; } }



# my $ftpUrl = 'ftp://ftp.sanger.ac.uk/pub/consortia/wormbase/STAFF/mh6/nightly_geneace/features.ace.gz';	# invalid on 2021 10 22, probably before
my $ftpUrl = 'ftp://ftp.ebi.ac.uk/pub/databases/wormbase/STAFF/nightly_geneace/features.ace.gz';
my $ftpdata = get $ftpUrl; 
next unless $ftpdata; 
if ($ftpdata =~ m/^\n/) { $ftpdata =~ s/^\n//; }
 
my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/daniela/sqf_sequencefeature/";
# my $directory = '/home/postgres/work/pgpopulation/sqf_sequencefeature/populate_from_geneace/';
$/ = undef;

# my $lastdata = '';
# my $lastFile = $directory . 'last.ace';
my $lastFile = $directory . 'prev_features.ace.gz';
open (IN, "<$lastFile") or warn "cannot open, no previous file : $!"; 
my $lastdata = <IN>;
close (IN) or warn "cannot close, no previous file : $!"; 

# my $newFile = $directory . 'new.ace';
# my $newFile = $directory . 'prev_features.ace.gz';
# open (IN, "<$newFile") or warn "cannot open, no new file : $!"; 
# my $ftpdata = <IN>;
# close (IN) or warn "cannot close, no new file : $!"; 

if ($lastdata eq $ftpdata) { 
#     print "data the same\n"; 
    exit 1; }
# UNCOMMENT TO REPLACE PREVIOUS FILE
  else { open (OUT, ">$lastFile") or die "Cannot create $lastFile : $!"; print OUT $ftpdata; close (OUT) or die "Cannot close $lastFile : $!"; }

my $logfile = $directory . 'logfile.pg';
open (OUT, ">$logfile") or die "Cannot open $logfile : $!";


my %goodMethods;
$goodMethods{"binding_site"}++;
$goodMethods{"binding_site_region"}++;
$goodMethods{"DNAseI_hypersensitive_site"}++;
$goodMethods{"enhancer"}++;
$goodMethods{"histone_binding_site_region"}++;
$goodMethods{"promoter"}++;
$goodMethods{"regulatory_region"}++;
$goodMethods{"TF_binding_site"}++;
$goodMethods{"TF_binding_site_region"}++;
$goodMethods{"history_feature"}++;

my %ignoreMethods;
$ignoreMethods{"TSS_region"}++;
# $ignoreMethods{"history_feature"}++;



my %tagToField;
$tagToField{"Public_name"}                          = 'publicname';
$tagToField{"Other_name"}                           = 'othername';
$tagToField{"Description"}                          = 'description';
$tagToField{"Species"}                              = 'species';
$tagToField{"Deprecated"}                           = 'deprecated';
$tagToField{"Defined_by_paper"}                     = 'paper';
$tagToField{"Defined_by_person"}                    = 'person';
$tagToField{"Defined_by_analysis"}                  = 'analysis';
$tagToField{"Method"}                               = 'method';
$tagToField{"SO_term"}                              = 'soterm';
$tagToField{"DNA_text"}                             = 'dnatext';
$tagToField{"Flanking_sequences"}                   = 'flanka';
$tagToField{"Mapping_target"}                       = 'target';
$tagToField{"Sequence"}                             = 'sequence';
$tagToField{"Associated_with_gene"}                 = 'wbgene';
# $tagToField{"Associated_with_expression_pattern"}   = 'exprpattern';
# $tagToField{"Associated_with_Interaction"}          = 'intid';
$tagToField{"Associated_with_CDS"}                  = 'cds';
$tagToField{"Associated_with_operon"}               = 'operon';
$tagToField{"Construct"}                            = 'construct';
$tagToField{"Bound_by_product_of"}                  = 'boundbyproduct';
$tagToField{"Transcription_factor"}                 = 'trascriptionfactor ';
$tagToField{"Confidential_remark"}                  = 'confidential';
$tagToField{"Remark"}                               = 'remark';
$tagToField{"Score"}                                = 'score';
$tagToField{"Merged_into"}                          = 'mergedinto';

my %tagToIgnore;
$tagToIgnore{"Acquires_merge"}++;			# read Merged_into instead
$tagToIgnore{"Associated_with_expression_pattern"}++;	# supposedely removed from geneace
$tagToIgnore{"Associated_with_Interaction"}++;		# supposedely removed from geneace

my %isMulti;
$isMulti{"paper"}++;
$isMulti{"person"}++;
$isMulti{"wbgene"}++;
# $isMulti{"exprpattern"}++;
# $isMulti{"intid"}++;
$isMulti{"cds"}++;
$isMulti{"construct"}++;
$isMulti{"boundbyproduct"}++;


my %lastData;
my (@lastEntries) = split/\n\n/, $lastdata;
foreach my $entry (@lastEntries) {
  if ($entry =~ m/\\\n"/) { $entry =~ s/\\\n"/"/g; }
  my ($wbsfid) = $entry =~ m/Feature : "(WBsf\d+)"/;
  $lastData{$wbsfid} = $entry;
} # foreach my $entry (@lastEntries)

my $oaNotHinxton = '';
foreach my $wbsfid (sort keys %{ $pgData{nameToPgid} }) {
  unless ($lastData{$wbsfid}) {
    $oaNotHinxton .= qq($wbsfid in postgres, not in hinxton dump\n); } }
if ($oaNotHinxton) {   
  my $body = "In OA but not Hinxton file :\n$oaNotHinxton\n";
  my $user = 'parse_seqfeat.pl';
  my $email = 'draciti@caltech.edu';
  my $subject = 'entries in seq feature OA not in Hinxton';
  &mailer($user, $email, $subject, $body); 
} # if ($body)

my (@entries) = split/\n\n/, $ftpdata;

my @pgidsToDelete;					# pgids of WBsfIDs that have changed, so need the postgres data removed before repopulating
my %newObjects;						# key WBsfID, value .ace entry for object that is new
my @changedPapers;					# papers that have changed for a WBsfID object
my $errorEmail;

my %pgcommands;
my $pgid = 0;
foreach my $entry (@entries) {
#   last if ($pgid > 7);
#   print "ENTRY $entry\n\n";
  if ($entry =~ m/\\\n"/) { $entry =~ s/\\\n"/"/g; }
  my $method = '';
  if ($entry =~ m/Method\s+"(.*?)"/) { $method = $1; }
  next unless ($goodMethods{$method});
  my (@lines) = split/\n/, $entry;
  my $header = shift @lines;
  my ($wbsfid) = $header =~ m/"(WBsf\d+)"/;
  next unless $wbsfid;
  my $oldEntry = '';
  if ($lastData{$wbsfid}) { $oldEntry = $lastData{$wbsfid}; }
  next if ($oldEntry eq $entry);
#   print "process $wbsfid\n"; 
  if ( $pgData{nameToPgid}{$wbsfid} ) {					# data existed in postgres before
      $pgid = $pgData{nameToPgid}{$wbsfid}; 				# reuse pgid for inserts
      push @pgidsToDelete, $pgid; }					# set pgid to delete data from tables first
    else { 
      $newObjects{$wbsfid} = $entry;					# new objects to email Daniela + Xiaodong
      $highestPgid++; $pgid = $highestPgid; }				# new entry, use a new pgid
  my %data;
  $data{"name"}{$wbsfid}++;
  $data{"curator"}{"WBPerson4025"}++;
  foreach my $line (@lines) {
    my ($tag, $rest) = ('', ''); 
    if ($line =~ m/^(\S+)\t (.*)$/) { 
        ($tag, $rest) = $line =~ m/^(\S+)\t (.*)$/; }
      else { 
        ($tag) = $line =~ m/^(\S+)\t$/; }
    next if ($tagToIgnore{$tag});
    unless ($tagToField{$tag}) { $errorEmail .= "$wbsfid invalid tag $tag : $line\n"; next; }
    if ($rest =~ m/\'/) { $rest =~ s/\'/''/g; }
    if ($rest =~ m/^\"/) { $rest =~ s/^\"//; }
    if ($rest =~ m/\"$/) { $rest =~ s/\"$//; }
    if ($rest =~ m/\\/) { $rest =~ s/\\//g; }
    if ($tag eq 'Flanking_sequences') { 
        my ($flanka, $flankb) = $rest =~ m/^(.*)" "(.*)$/;
        $data{"flanka"}{$flanka}++;
        $data{"flankb"}{$flankb}++; }
      elsif ($tag eq 'Defined_by_paper') { 
        my ($object) = $rest =~ m/(WBPaper\d+)/; $data{$tagToField{$tag}}{$object}++; }
      elsif ($tag eq 'Defined_by_person') { 
        my ($object) = $rest =~ m/(WBPerson\d+)/; $data{$tagToField{$tag}}{$object}++; }
      elsif ($tag eq 'SO_term') { 
        my ($object) = $rest =~ m/(SO:\d+)/; $data{$tagToField{$tag}}{$object}++; }
      elsif ($tag eq 'Merged_into') { 
        my ($object) = $rest =~ m/(WBsf\d+)/; $data{$tagToField{$tag}}{$object}++; }
      elsif ( ($tag eq 'Associated_with_gene') || ($tag eq 'Bound_by_product_of') ) {
        if ($rest =~ m/(WBGene\d+)/) { $data{$tagToField{$tag}}{$1}++; } }
      elsif ($tag eq 'Associated_with_expression_pattern ') { 
        my ($object) = $rest =~ m/(Expr\d+)/; $data{$tagToField{$tag}}{$object}++; }
      elsif ($tag eq 'Associated_with_Interaction') { 
        my ($object) = $rest =~ m/(WBInteraction\d+)/; $data{$tagToField{$tag}}{$object}++; }
      elsif ($tag eq 'Associated_with_construct') { 
        my ($object) = $rest =~ m/(WBCnstr\d+)/; $data{$tagToField{$tag}}{$object}++; }
      else { $data{$tagToField{$tag}}{$rest}++; }
  } # foreach my $line (@lines)
  foreach my $field (sort keys %data) {
    my $data = '';
    if ($isMulti{$field}) { $data = join'","', sort keys %{ $data{$field} }; $data = '"' . $data . '"'; }
      else { $data = join' | ', sort keys %{ $data{$field} }; }
    push @{ $pgcommands{$field} }, qq(('$pgid', E'$data'));
    if ($field eq 'paper') { 
      unless ($newObjects{$wbsfid}) {				# no email about paper if it's a new WBsfID object 
        my $oldPaper = '';
        if ( $pgData{pgidToPaper}{$pgid} ) { $oldPaper = $pgData{pgidToPaper}{$pgid}; }	# if there was old paper data, get it from postgres
        if ( $oldPaper ne $data) { 							# new paper data different from previous postgres data
          push @changedPapers, qq($wbsfid had $oldPaper now has $data); } } }		# add to send email 
  } # foreach my $field (sort keys %data)
} # foreach my $entry (@entries)

my $pgidsToDelete = join"','", @pgidsToDelete;
$tagToField{"flankb"} = 'flankb'; $tagToField{"name"} = 'name'; $tagToField{"curator"} = 'curator';	# tables that have data but not acedb tags
foreach my $tag (sort keys %tagToField) {
  my $pgtable = $tagToField{$tag};
  my $deletePgCommand = qq(DELETE FROM sqf_${pgtable} WHERE joinkey IN ('$pgidsToDelete'));
  print OUT "$deletePgCommand\n";
# UNCOMMENT TO POPULATE
  $dbh->do($deletePgCommand);
}


foreach my $field (sort keys %pgcommands) {
  my $pgcommand = join", ", @{ $pgcommands{$field} };
  $pgcommand = qq(INSERT INTO sqf_$field VALUES $pgcommand);
  print OUT "$pgcommand\n";
# UNCOMMENT TO POPULATE
  $dbh->do($pgcommand);
} # foreach my $field (sort keys %pgcommands)

close (OUT) or die "Cannot close $logfile : $!";


my $body = '';
my $user = 'parse_seqfeat.pl';
# my $email = 'azurebrd@tazendra.caltech.edu, draciti@caltech.edu';
my $email = 'draciti@caltech.edu, xdwang@its.caltech.edu';

my $newObjectIds = join", ", sort keys %newObjects;
if ($newObjectIds) {   
  my $amountObjectIds = scalar keys %newObjects;
  $body = "New Objects : $newObjectIds\n";
  my $subject = 'new WBsfID objects created';
  if ($amountObjectIds < 100) {
      foreach my $newObject (sort keys %newObjects) { $body .= qq(\n\n$newObjects{$newObject}\n\n); } }
    else { $body .= qq(\n\nToo many .ace objects $amountObjectIds, check features.ace.gz\n\n); }
  &mailer($user, $email, $subject, $body); 
} # if ($body)

my $amountChangedPapers = scalar @changedPapers;
if ($amountChangedPapers > 0) {
  $body = join"\n", @changedPapers;
  if ($amountChangedPapers > 100) { $body = qq(Too many objects have changed papers $amountChangedPapers, check features.ace.gz); }
  my $subject = 'papers in existing WBsfID objects have changed';
  &mailer($user, $email, $subject, $body); 
} # if (scalar @changedPapers > 0)

if ($errorEmail) {
  $body = $errorEmail;
  my $subject = 'errors in parsing features.ace.gz';
  &mailer($user, $email, $subject, $body); 
} # if (scalar @changedPapers > 0)
