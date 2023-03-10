#!/usr/bin/perl -w

# To create full data set ./get_person_ace.pl > full_person.ace
# fixed Fax entries that had an extra \tOther_phone in them
# added &left_fieldPrint(); for those who have left the field
# added ``AND two IS NOT NULL'' to filter those that do not
# wish to be in wormbase.   2002 12 19
#
# Updated to have a delete_Person.ace file to append to beginning
# of file for next time, to delete entries before inserting new
# ones.  Fixed spaces at end or beginning of entries.  Fixed
# middlename problem that wasn't outputting some standard_names
# because they contained the word NULL.  2003 02 20
#
# Added two_wormbase_comment for comments that go to wormbase.
# 2003 02 28
#
# Changed Standard_name to be Full_name.  Created Standard_name
# as a new table (two_thestandardname) and populated it.  
# 2003 03 22
#
# Changed two_standardname (view) to be two_fullname (view),
# copied two_thestandardname to two_standardname, and deleted
# two_thestandardname.  2003 03 24
#
# Changed to no longer print apu's because they were sent by people
# and that may have typos or not exactly match an acedb author or
# not be an elegans paper's author.  2003 04 10
#
# Deleting -O tags because Wen & Raymond don't want forced timestamp
# override, so will create dumps, and compare to previous to create
# -D and insertion lines in another .ace file.  2003 04 30
#
# Added two_hide, so check for existence, if so, skip the entry so
# as not to display on wormbase.  Filter .'s and ,'s from names and
# aka_names.  2003 05 13
#
# Last_verified should not be affected by last attempt to contact
# since that is not verification (for Cecilia)  2004 02 03
#
# Added Institution for Keith, Todd, Cecilia.  2004 03 31
#
#######
#
# Took original Person dumpers from 
# /home/postgres/work/citace_upload/cecilia/compare_citace_vs_pg_dump/
# /home/postgres/work/citace_upload/cecilia/compare_citace_vs_pg_dump/person_paper_author_for_now
# /home/postgres/work/citace_upload/cecilia/compare_citace_vs_pg_dump/Lineage_temp
# and combined into this script to dump data that all 3 scripts would dump separetly.
#
# usage ./get_person_ace.pl > Juancarlos_date.ace
# then diff with the ./find_diff.pl old.ace new.ace > Cecilia_date.ace 
#
# Cleaned up lots of errors from bad timestamp data or missing data causing 
# concatenations errors.  Deleted all stuff relating to .ace -O timestamp.
# 2004 05 19
#
# Changed to have WBPaper instead of paper.  Only error from 
# ERROR No conversion for wm7710a on two521   which already exists as 
# wm77p10a, so everything seems ok.  2004 09 02
#
# It was dumping affiliation address data which is not in the model.  2004 12 29 
#
# Changed some tabs to spaces, added spaces after tabs, took out "s
# to make the dump match a citace dump for diff'ing.  2005 03 15
#
# Temporarily ignore list of stuff from Eimear because these WBPapers have 
# been merged with others and are no longer the correct WBPaper.  2005 05 26
#
# Rewrote &populatePaperHash(); to use the new wpa_author tables.  2005 07 16
#
# Was only dumping up to 4000, changed to look at two table and get highest
# there first.  2005 10 13
#
# Filter out invalid papers.  Might want to get the merged one instead ?  
# But maybe not because some may eventually not be merged and just be invalid.
# 2005 10 19
#
# Check that lineage doesn't refer to self.  2006 02 07
#
# Added two_status, two_acqmerge, two_mergedinto.  2006 11 06
#
# Changed %paperHash to include verified data to determine if it's been made by
# a script, either lineage ``YES Raymond Lee'' or labs ``YES  Raymond Lee'', and
# Not_paper ``NO  someone''.  To account for adding and taking off papers, must
# use timestamp and sort by timestamp to keep only the latest information.  If
# connected by script, add Inferred_automatically tag with explanation text, and
# add Curator_confirmed WBPerson363  (Raymond, since he looked over the script
# results).  2007 04 09
#
# Forgot to get the highest val, should have been <= instead of <  2008 02 29
#
# Put in place &filterAce(); to get rid of non-acedb format stuff.  Hopefully
# works, not tested.  2008 07 30
#
# filtering works, except for Supervised stuff, which is now not filtering.
# Catch errors if there's no firstname or no lastname.  2008 08 28
#
# Skip .number papers otherwise we're creating them here.  2008 10 09
#
# Now dumping old_institution under Old_address  2008 11 11
#
# Took out the backslash escaping from the functions since they called 
# &filterAce() anyway   2009 01 12
#
# Cecilia wants periods now in aka, standardname, full name, firstname, 
# lastname, middlename 2009 01 20
#
# Switched from Pg.pm to DBI.pm 
# only pring Full_name and Last_verified if there's data.  2009 04 24
#
# add end year to person lineage #Role, unless it's 'present'.  2009 10 27
#
# Switched to pap tables even though they're not live.  2010 06 22
#
# Switched to new two_ tables that have a curator instead of an old timestamp.
# 2011 06 14


use strict;
use diagnostics;
# use Pg;
use DBI;
use Jex;
use LWP;

# my $dbh = DBI->connect ( "dbi:Pg:dbname=devdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $start = time;

my $error_file = 'errors_in_pap_person.ace';
open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 

my @normal_tables = qw(firstname middlename lastname standardname aka_firstname aka_middlename aka_lastname email old_email old_email_date street city state post country institution old_institution old_inst_date mainphone labphone officephone otherphone fax pis lab oldlab left_field unable_to_contact privacy webpage usefulwebpage wormbase_comment hide status mergedinto acqmerge comment );

my %order_type;
my @single_order = qw( firstname middlename lastname standardname city state post country left_field unable_to_contact hide status mergedinto );
my @multi_order = qw( street institution old_institution old_inst_date mainphone labphone officephone otherphone fax email old_email old_email_date pis lab oldlab privacy aka_firstname aka_middlename aka_lastname webpage usefulwebpage wormbase_comment acqmerge comment );
foreach (@single_order) { $order_type{single}{$_}++; }
foreach (@multi_order) { $order_type{multi}{$_}++; }

my $qualifier_general = ''; my $qualifier_paper_hash = '';  my $specific_two_num = 'all'; 
# $specific_two_num = 'two1';
# $specific_two_num = 'two2449';
if ($specific_two_num ne 'all') { 
  $qualifier_paper_hash = " AND pap_author_possible.pap_author_possible = '$specific_two_num'";
  $qualifier_general = " AND joinkey = '$specific_two_num'"; }

my %paperHash;
&populatePaperHash();

my %lineageHash;
&populateLineageHash();

sub populateLineageHash {
  $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_number ~ 'two' AND joinkey IS NOT NULL AND joinkey != two_number $qualifier_general; " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $stuff = '';
    my $num = $row[3]; $num =~ s/two//g;
    my $role = $row[4]; my $known = 'known'; if ($row[4] =~ m/Unknown/) { $known = 'unknown'; }
    if ($row[5]) { $role .= " $row[5]"; }
    if ($row[6]) { unless ($row[6] eq 'present') { $role .= " $row[6]"; } }     # add end year unless it's present  2009 10 27
    if ($role =~ m/^Collaborated/) {                     $stuff = "Worked_with\t\"WBPerson$num\" $role\n"; }
      elsif ($role =~ m/^with/) {    $role =~ s/with//g; $stuff = "Supervised_by\t\"WBPerson$num\" $role\n"; }
      else {                                             $stuff = "Supervised\t\"WBPerson$num\" $role\n"; }
    $lineageHash{$row[0]}{$num}{$known}{$stuff}++;
  } # while (my @row = $result->fetchrow)
  foreach my $two (keys %lineageHash) {
    foreach my $othertwo (keys %{ $lineageHash{$two} }) {
      if ( ($lineageHash{$two}{$othertwo}{'known'}) && ($lineageHash{$two}{$othertwo}{'unknown'}) ) { 
        delete $lineageHash{$two}{$othertwo}{'unknown'}; } } }
} # sub populateLineageHash

my %data;
foreach my $table (@normal_tables) {
  $result = $dbh->prepare( "SELECT * FROM two_$table WHERE two_$table != 'NULL' $qualifier_general" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $row[0] =~ s/two//;
    my $data = $row[2];
    my ($date_type) = $row[4] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
    if ( ($table eq 'old_inst_date') || ($table eq 'old_email_date') ) { ($data) = $row[2] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/; }
    $data{$table}{$row[0]}{$row[1]}{time} = $date_type;
    $data{$table}{$row[0]}{$row[1]}{data} = $data; } }

my %tableToTag;
$tableToTag{'status'}            = 'Status';
$tableToTag{'mergedinto'}        = 'Merged_into';
$tableToTag{'acqmerge'}          = 'Acquires_merge';
$tableToTag{'left_field'}        = "Left_the_field"; 
$tableToTag{'unable_to_contact'} = "Last_attempt_to_contact\t date_type";	# needs date_type
$tableToTag{'wormbase_comment'}  = "Comment"; 
$tableToTag{'comment'}           = "Comment";
$tableToTag{'old_institution'}   = "Old_address\t date_type Institution"; 	# needs date_type
$tableToTag{'oldlab'}            = "Old_laboratory"; 
$tableToTag{'old_email'}         = "Old_address\t date_type Email"; 		# needs date_type
$tableToTag{'lab'}               = "Laboratory"; 
$tableToTag{'webpage'}           = "Address\tWeb_page"; 
$tableToTag{'fax'}               = "Address\tFax";
$tableToTag{'otherphone'}        = "Address\tOther_phone";
$tableToTag{'officephone'}       = "Address\tOffice_phone";
$tableToTag{'labphone'}          = "Address\tLab_phone";
$tableToTag{'mainphone'}         = "Address\tMain_phone";
$tableToTag{'email'}             = "Address\tEmail";
$tableToTag{'country'}           = "Address\tCountry";
$tableToTag{'institution'}       = "Address\tInstitution";
$tableToTag{'street'}            = "Address\tStreet_address";
$tableToTag{'firstname'}         = "First_name";
$tableToTag{'middlename'}        = "Middle_name";
$tableToTag{'lastname'}          = "Last_name";
$tableToTag{'standardname'}      = "Standard_name";
$tableToTag{'fullname'}          = "Full_name";					# not a real table


foreach my $twonum (sort {$a<=>$b} keys %{ $data{status} }) {
  next if ($data{hide}{$twonum}{1}{data});					# skip those to hide
  print "\nPerson : \"WBPerson$twonum\"\n"; 
  print "$tableToTag{status}\t\"$data{status}{$twonum}{1}{data}\"\n"; 
  if ($data{status}{$twonum}{1}{data} eq 'Invalid') { 
    if ($data{mergedinto}{$twonum}{1}{data}) { 
        my $data = $data{mergedinto}{$twonum}{1}{data}; $data =~ s/two/WBPerson/; 
        print "$tableToTag{mergedinto}\t\"$data\"\n"; } 
#       else { print ERR "Invalid two$twonum not merged into anything two_mergedinto\n"; } 	# cecilia doesn't want this warning
  }
  next if ($data{status}{$twonum}{1}{data} ne 'Valid');
  my $highest_date = ''; my $highest_date_num = 0;
  my ($city, $state, $post) = ('', '', '');
  my %akas;
  foreach my $table (@normal_tables) {
    next if ( ($table eq 'status') || ($table eq 'mergedinto') || 				# tags already printed
              ($table eq 'aka_middlename') || ($table eq 'aka_lastname') || 			# aka tags printed as part of another
              ($table eq 'old_email_date') || ($table eq 'old_inst_date') || 			# date tags printed as part of another
              ($table eq 'usefulwebpage') || ($table eq 'hide') || ($table eq 'pis') ||		# tags not for printing
              ($table eq 'privacy') || ($table eq 'comment')	
            );
    foreach my $order (sort {$a<=>$b} keys %{ $data{$table}{$twonum} }) {
      my ($data, $time) = ('', '');
      if ( $data{$table}{$twonum}{$order}{time} ) { $time = $data{$table}{$twonum}{$order}{time}; }
      if ( $data{$table}{$twonum}{$order}{data} ) { $data = $data{$table}{$twonum}{$order}{data}; }
      next unless $data;			# only print stuff if there's data
      if ($data =~ m/\//)   { $data =~ s/\//\\\//g; }
      if ($data =~ m/\"/)   { $data =~ s/\"/\\\"/g; }
      if ($data =~ m/\s+/)  { $data =~ s/\s+/ /g; }
      if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; }
      if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; }
      if ($time) {
        my $datenum = $time; $datenum =~ s/\-//g;
        if ($datenum > $highest_date_num) { $highest_date = $time; $highest_date_num = $datenum; } }
      if ($table eq 'firstname') {
        if ($data{middlename}{$twonum}{$order}{data}) { print "Full_name\t\"$data{firstname}{$twonum}{$order}{data} $data{middlename}{$twonum}{$order}{data} $data{lastname}{$twonum}{$order}{data}\"\n"; }
          else { print "Full_name\t\"$data{firstname}{$twonum}{$order}{data} $data{lastname}{$twonum}{$order}{data}\"\n"; } }
      if ($table eq 'acqmerge') { $data =~ s/two/WBPerson/; }			# change twos to WBPerson
      if ($table eq 'city') { $city = $data; }
        elsif ($table eq 'state') { $state = $data; }
        elsif ($table eq 'post') { $post = $data; }
        elsif ($table eq 'unable_to_contact') {
          my $date_type = $data{unable_to_contact}{$twonum}{$order}{time};
          my $tag = $tableToTag{$table}; $tag =~ s/date_type/$date_type/; 
          print "$tag\t\"$data\"\n"; }
        elsif ($table eq 'old_institution') {
          if ($data{old_inst_date}{$twonum}{$order}{data}) {
              my $date_type = $data{old_inst_date}{$twonum}{$order}{data};
              my $tag = $tableToTag{$table}; $tag =~ s/date_type/$date_type/; 
              print "$tag\t\"$data\"\n"; }
            else { print ERR "MISSING two_old_inst_date two$twonum Order $order\n"; } }
        elsif ($table eq 'old_email') {
          if ($data{old_email_date}{$twonum}{$order}{data}) {
              my $date_type = $data{old_email_date}{$twonum}{$order}{data};
              my $tag = $tableToTag{$table}; $tag =~ s/date_type/$date_type/; 
              print "$tag\t\"$data\"\n"; }
            else { print ERR "MISSING two_old_email_date two$twonum Order $order\n"; } }
        elsif ($table eq 'aka_firstname') {
          my $first  = $data{aka_firstname}{$twonum}{$order}{data};
          my $last   = '';
          if ($data{aka_lastname}{$twonum}{$order}{data}) { $last= $data{aka_lastname}{$twonum}{$order}{data}; }
            else { print ERR "MISSING two_aka_lastname two$twonum Order $order\n"; }
          if ( $data{aka_middlename}{$twonum}{$order}{data} ) {
              my $middle = $data{aka_middlename}{$twonum}{$order}{data};
              $akas{"$first $middle $last"}++; }
            else { $akas{"$first $last"}++; } }
        else { print "$tableToTag{$table}\t\"$data\"\n"; }
    } # foreach my $order (sort {$a<=>$b} keys %{ $data{$table}{$twonum} })
  } # foreach my $table (@normal_tables)
  if ( ($city) && ($state) && ($post) ) { print "Address\tStreet_address\t\"$city, $state $post\"\n"; }
    elsif ( ($city) && ($state) ) {       print "Address\tStreet_address\t\"$city, $state\"\n"; }
    elsif ( ($city) && ($post) ) {        print "Address\tStreet_address\t\"$city, $post\"\n"; }
    elsif ( ($state) && ($post) ) {       print "Address\tStreet_address\t\"$state $post\"\n"; }
    elsif ($city) {                       print "Address\tStreet_address\t\"$city\"\n"; }
    elsif ($state) {                      print "Address\tStreet_address\t\"$state\"\n"; }
    elsif ($post) {                       print "Address\tStreet_address\t\"$post\"\n"; }
    else { 1; }
  foreach my $aka (sort keys %akas) { 
    if ($aka =~ m/\,/) { $aka =~ s/\,//g; }
    print "Also_known_as\t\"$aka\"\n"; }
  foreach my $othertwo (keys %{ $lineageHash{"two$twonum"} }) {
    foreach my $known_or_not (keys %{ $lineageHash{"two$twonum"}{$othertwo} }) {
      foreach my $lineage_line (keys %{ $lineageHash{"two$twonum"}{$othertwo}{$known_or_not} }) {
        print $lineage_line; } } }
  &paperPrint("two$twonum");
  if ($highest_date) { print "Last_verified\t$highest_date\n"; }
} # foreach my $twonum (sort {$a<=>$b} keys %data)

my $end = time;
my $diff = $end - $start;
print STDERR "$diff seconds\n";

close (ERR) or die "Cannot close $error_file : $!";

sub populatePaperHash {
    # assume for now that Cecilia only has valid data.
  my %paper_valid; my %paper_index;
  my $result = $dbh->prepare( "SELECT * FROM pap_author ORDER BY pap_timestamp ;");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $paper_index{$row[1]} = "WBPaper$row[0]"; }

  my %author_valid; my %author_index;
  $result = $dbh->prepare( "SELECT * FROM pap_author_index ORDER BY pap_timestamp ;");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[1] =~ m/\s+-COMMENT.*/) { $row[1] =~ s/\s+-COMMENT.*//g; }
    $author_index{$row[0]} = $row[1]; }

  $result = $dbh->prepare( "
    SELECT pap_author_possible.author_id, pap_author_possible.pap_author_possible, pap_author_possible.pap_join, pap_author_verified.pap_author_verified, pap_author_verified.pap_timestamp
    FROM pap_author_possible, pap_author_verified
    WHERE pap_author_possible.author_id = pap_author_verified.author_id
      AND pap_author_possible.pap_join = pap_author_verified.pap_join
      AND (pap_author_verified.pap_author_verified ~ 'NO' OR pap_author_verified.pap_author_verified ~ 'YES')
      $qualifier_paper_hash
    ORDER BY pap_timestamp; ");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    my $person = $row[1]; my $author_id = $row[0]; my $verified = $row[3]; my $paper = ''; my $author_name = '';
    next unless ($person);
    if ($verified =~ m/NO/) {
      if ($paper_index{$author_id}) {
        $paper = $paper_index{$author_id};
        next if ($paper =~ m/\.[12]$/);         # skip .number papers otherwise we're creating them here        2008 10 09
        delete $paperHash{$person}{paper}{$paper}; delete $paperHash{$person}{paper_lab}{$paper}; delete $paperHash{$person}{paper_lineage}{$paper};
        $paperHash{$person}{not_paper}{$paper}++; } }
    else {
      if ($paper_index{$author_id}) {
        $paper = $paper_index{$author_id};
        next if ($paper =~ m/\.[12]$/);         # skip .number papers otherwise we're creating them here        2008 10 09
        delete $paperHash{$person}{not_paper}{$paper};
        if (($author_id ne 'two363') && ($verified =~ m/YES  Raymond Lee/)) { $paperHash{$person}{paper_lab}{$paper}++; }
        if (($author_id ne 'two363') && ($verified =~ m/YES Raymond Lee/)) { $paperHash{$person}{paper_lineage}{$paper}++; }
        $paperHash{$person}{paper}{$paper}++; }
      if ($author_index{$author_id}) {
        $author_name = $author_index{$author_id};
        $paperHash{$person}{author}{$author_name}++; } }
  } # while (my @row = $result->fetchrow)
} # sub populatePaperHash

sub paperPrint {
  my $joinkey = shift;
  foreach my $author (sort keys %{$paperHash{$joinkey}{author}}) {
    $author =~ s/\.//g; $author =~ s/,//g;
    if ($author =~ m/\" Affiliation_address/) { $author =~ s/\" Affiliation_address.*$//g; }
      # 2004 12 29 -- was dumping affiliation address data which is not in the model
    ($author) = &filterAce($author);
    print "Possibly_publishes_as\t \"$author\"\n";
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper}}) {
    $paper =~ s/\.$//g;                                 # take out dots at the end that are typos
    if ($paper =~ m/WBPaper/) {
      print "Paper\t \"$paper\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; }
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper_lineage}}) {
    $paper =~ s/\.$//g;
    if ($paper =~ m/WBPaper/) {
      print "Paper\t \"$paper\" Curator_confirmed \"WBPerson363\"\n";
      print "Paper\t \"$paper\" Inferred_automatically \"/home/postgres/work/pgpopulation/pap_papers/author_person/verify_automatically/verify_by_labs_or_lineage.pl\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; } }
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper_lab}}) {
    $paper =~ s/\.$//g;
    if ($paper =~ m/WBPaper/) {
      print "Paper\t \"$paper\" Curator_confirmed \"WBPerson363\"\n";
      print "Paper\t \"$paper\" Inferred_automatically \"/home/postgres/work/pgpopulation/pap_papers/author_person/verify_automatically/verify_by_labs_or_lineage.pl\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; } }
  foreach my $paper (sort keys %{$paperHash{$joinkey}{not_paper}}) {
    $paper =~ s/\.$//g;
    if ($paper =~ m/WBPaper/) { print "Not_paper\t \"$paper\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; } }
} # sub paperPrint

sub filterAce {
  my $identifier = shift;
  unless ($identifier) { return ""; }
  my $comment = '';
  if ($identifier =~ m/-COMMENT (.*)/) { $comment = $1; $identifier =~ s/-COMMENT .*//; }
  if ($identifier =~ m/HTTP:\/\//i) { $identifier =~ s/HTTP:\/\//PLACEHOLDERASDF/ig; }
  if ($identifier =~ m/HTTPS:\/\//i) { $identifier =~ s/HTTPS:\/\//PLACEHOLDERHTTPS/ig; }
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\\\/\\\//) { $identifier =~ s/\\\/\\\//" "/g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/PLACEHOLDERASDF/) { $identifier =~ s/PLACEHOLDERASDF/HTTP:\\\/\\\//g; }
  if ($identifier =~ m/PLACEHOLDERHTTPS/) { $identifier =~ s/PLACEHOLDERHTTPS/HTTPS:\\\/\\\//g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  if ($comment) {
    if ($identifier =~ m/[^"]$/) { $identifier .= "\" "; }
    $identifier .= "-C \"$comment"; }
  return $identifier;
} # sub filterAce



__END__

my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);



my $highest_two_val = '4000';
my $lowest_two_val = '0';

my @dates = ();
my $result;
$result = $dbh->prepare( "SELECT * FROM two ORDER BY two DESC;" );
$result->execute();
my @row = $result->fetchrow;
if ($row[1] > $highest_two_val) { $highest_two_val = $row[1]; }


my $error_file = 'errors_in_pap_person.ace';

open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 

my %paperHash;
&populatePaperHash;

my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper
&readConvertions();

for (my $i = $lowest_two_val; $i <= $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
  $result = $dbh->prepare( "SELECT * FROM two_hide WHERE joinkey = '$joinkey' AND two_hide IS NOT NULL;" );
  $result->execute();
  my @row = $result->fetchrow;
  next if ($row[2]);				# skip if meant to hide
    # added two IS NOT NULL because there are three people that do not want to be displayed
  $result = $dbh->prepare( "SELECT * FROM two WHERE joinkey = '$joinkey' AND two IS NOT NULL;" );
  $result->execute();
  next if ($result->rows == 0); 
  @row = $result->fetchrow() ;
  next unless ($row[1]);			# skip if two does not exist
  @dates = ();
  print "Person : \"WBPerson$i\"\n"; 
  my ($status) = &statusPrint($joinkey);
  unless ($status) { print "\n"; }
  if ($status eq 'Invalid') { print "\n"; }
  next unless ($status);			# error in getting status stop
  next if ($status eq 'Invalid');		# person is invalid don't show data

  &namePrint($joinkey);
  &akaPrint($joinkey);
  &labPrint($joinkey);
  &streetPrint($joinkey);
  &countryPrint($joinkey);
  &institutionPrint($joinkey);
  &emailPrint($joinkey);
  &mainphonePrint($joinkey);
  &labphonePrint($joinkey);
  &officephonePrint($joinkey);
  &otherphonePrint($joinkey);
  &faxPrint($joinkey);
  &webpagePrint($joinkey);
  &old_emailPrint($joinkey);
  &last_attemptPrint($joinkey);
  &left_fieldPrint($joinkey);
  &oldlabPrint($joinkey);
  &oldInstPrint($joinkey);
#   &apuPrint($joinkey);		# don't print apu's because sent by person not actual acedb authors
#   &commentPrint($joinkey);	# don't print comments
  &wormbasecommentPrint($joinkey);	# don't print comments
  &lineagePrint($joinkey);
  &paperPrint($joinkey);
  &last_verifiedPrint();
  print "\n";  				# divider between Persons
} # for (my $i = 0; $i < $highest_two_val; $i++)

close (ERR) or die "Cannot close $error_file : $!";

sub statusPrint {
  my $joinkey = shift; my $status = 'Valid';
  $result = $dbh->prepare ( "SELECT * FROM two_status WHERE joinkey = '$joinkey' ORDER BY two_timestamp DESC;" );
  $result->execute();
  my @row = $result->fetchrow;
  if ($row[2]) { $status = $row[2]; }
    else { print ERR "$joinkey has no status\n"; }
  unless (($status eq 'Valid') || ($status eq 'Invalid')) { print ERR "$joinkey $status is not a valid option\n"; return; }
  ($status) = &filterAce($status);
  print "Status\t\"$status\"\n"; 
  if ($status eq 'Invalid') {
      $result = $dbh->prepare ( "SELECT * FROM two_mergedinto WHERE joinkey = '$joinkey' ORDER BY two_timestamp DESC;" );
      $result->execute();
      while ( @row = $result->fetchrow ) { 
        $row[2] =~ s/two/WBPerson/;
        ($row[2]) = &filterAce($row[2]);
        print "Merged_into\t\"$row[2]\"\n\n"; } }
    else {
      $result = $dbh->prepare ( "SELECT * FROM two_acqmerge WHERE joinkey = '$joinkey' ORDER BY two_timestamp DESC;" );
      $result->execute();
      while ( @row = $result->fetchrow ) { 
        $row[2] =~ s/two/WBPerson/;
        ($row[2]) = &filterAce($row[2]);
        print "Acquires_merge\t\"$row[2]\"\n"; } }
  return ($status);
} # sub statusPrint

sub lineagePrint {
  my $joinkey = shift;
  my $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two'; " );
  $result->execute();
  my $stuff = '';
  while (my @row = $result->fetchrow) {
    if ($joinkey eq $row[3]) { print ERR "ERROR LINEAGE joinkeys is $joinkey matched with $row[3]\n"; next; }	# self-referential lineage, don't print 2006 02 07
    my $num = $row[3]; $num =~ s/two//g;
    my $role = $row[4];
    if ($row[5]) { $role .= " $row[5]"; }
    if ($row[6]) { unless ($row[6] eq 'present') { $role .= " $row[6]"; } }	# add end year unless it's present  2009 10 27
    if ($role =~ m/^Collaborated/) {
      $stuff .= "Worked_with\t \"WBPerson$num\" $role\n"; }
    elsif ($role =~ m/^with/) {
      $role =~ s/with//g;
      $stuff .= "Supervised_by\t \"WBPerson$num\" $role\n"; }
    else {
      $stuff .= "Supervised\t \"WBPerson$num\" $role\n"; }
  } # while (my @row = $result->fetchrow)

  if ($stuff) {
      # Ridiculously overcomplicated way to prevent Role Unknown to appear if already
      # have data under a different Role for that Tag and WBPerson  2004 01 13
    my @stuff = split/\n/, $stuff;
    my %filter;
    foreach my $line (@stuff) {
      my ($front, $role) = $line =~ m/^(.*?\t \"WB.*?) (.*?)$/;
      $filter{$front}{$role}++;
    } # foreach my $line (@stuff)
    foreach my $key (sort keys %filter) {
      my $not_unknown_flag = 0; my $unknown_flag = 0;
      foreach my $role (sort keys %{ $filter{$key} }) {
        if ($role !~ m/^Unknown/) { $not_unknown_flag++; }
        if ($role =~ m/^Unknown/) { $unknown_flag++; }
      } # foreach my $role (sort keys %{ $filter{$key} })
      if ( ($not_unknown_flag > 0) && ($unknown_flag > 0) ) {
        my $take_out = "$key\tUnknown";
        # print "TAKE OUT $take_out\n";
        $stuff =~ s/$take_out.*\n//g;
      } # if ( ($not_unknown_flag > 0) && ($unknown_flag > 0) )
    } # foreach my $key (sort keys %filter)
#     ($stuff) = &filterAce($stuff);
    print $stuff;
  } # if ($stuff)
} # sub lineagePrint



sub left_fieldPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_left_field WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $left_field = $row[2];
      my $left_field_time = $row[3];
      my ($date_type) = $left_field_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($left_field !~ m/NULL/) { 
        $left_field =~ s/\s+/ /g; $left_field =~ s/^\s+//g; $left_field =~ s/\s+$//g;
#         $left_field =~ s/\//\\\//g;
        ($left_field) = &filterAce($left_field);
        print "Left_the_field\t \"$left_field\"\n"; 
        push @dates, $left_field_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub left_fieldPrint

sub last_verifiedPrint {
  my $date = ''; my $time_temp = ''; my $highest = 0;
  foreach my $time (@dates) {
    $time_temp = $time;
    ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
    unless ($time_temp) { $time_temp = '1970-01-01'; }
    if ($time_temp =~ m/\D/) { $time_temp =~ s/\D//g; }
    if ($time_temp > $highest) {
      $highest = $time_temp;
      $date = $time;
    } # if ($time_temp > $highest)
  } # foreach my $time (@dates)
  my ($date_type) = $date =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
  if ($date_type) {
    print "Last_verified\t $date_type\n"; }
} # sub last_verifiedPrint

sub last_attemptPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_unable_to_contact WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $unable_to_contact = $row[2];
      my $unable_to_contact_time = $row[3];
      my ($date_type) = $unable_to_contact_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($unable_to_contact !~ m/NULL/) { 
        $unable_to_contact =~ s/\s+/ /g; $unable_to_contact =~ s/^\s+//g; $unable_to_contact =~ s/\s+$//g;
#         $unable_to_contact =~ s/\//\\\//g;
#         $unable_to_contact =~ s/\;/\\\;/g;
        ($unable_to_contact) = &filterAce($unable_to_contact);
        print "Last_attempt_to_contact\t $date_type \"$unable_to_contact\"\n";
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub last_attemptPrint

sub wormbasecommentPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_wormbase_comment WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $wormbase_comment = $row[2];
      my $wormbase_comment_time = $row[3];
      if ( ($wormbase_comment !~ m/NULL/) && ($wormbase_comment !~ m/nodatahere/) ) { 
        $wormbase_comment =~ s/\n/ /sg;
        if ($wormbase_comment !~ m/NULL/) { 
	  $wormbase_comment =~ s/\s+/ /g; $wormbase_comment =~ s/^\s+//g; $wormbase_comment =~ s/\s+$//g;
#           $wormbase_comment =~ s/\//\\\//g;
          ($wormbase_comment) = &filterAce($wormbase_comment);
          print "Comment\t \"$wormbase_comment\"\n"; 
          push @dates, $wormbase_comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
} # sub wormbasecommentPrint

sub commentPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_comment WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 
      my $comment = $row[1];
      my $comment_time = $row[2];
      if ( ($comment !~ m/NULL/) && ($comment !~ m/nodatahere/) ) { 
        $comment =~ s/\n/ /sg;
        if ($comment !~ m/NULL/) { 
	  $comment =~ s/\s+/ /g; $comment =~ s/^\s+//g; $comment =~ s/\s+$//g;
#           $comment =~ s/\//\\\//g;
          ($comment) = &filterAce($comment);
          print "Comment\t \"$comment\"\n";
          push @dates, $comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub oldInstPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_old_institution WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $old_institution = $row[2];
      my $old_institution_time = $row[3];
      my ($date_type) = $old_institution_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($old_institution !~ m/NULL/) { 
	$old_institution =~ s/\s+/ /g; $old_institution =~ s/^\s+//g; $old_institution =~ s/\s+$//g;
#         $old_institution =~ s/\//\\\//g;
        ($old_institution) = &filterAce($old_institution);
        print "Old_address\t $date_type Institution \"$old_institution\"\n"; 
        push @dates, $old_institution_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub oldInstPrint

sub oldlabPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_oldlab WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $oldlab = $row[2];
      my $oldlab_time = $row[3];
      if ($oldlab !~ m/NULL/) { 
	$oldlab =~ s/\s+/ /g; $oldlab =~ s/^\s+//g; $oldlab =~ s/\s+$//g;
#         $oldlab =~ s/\//\\\//g;
        ($oldlab) = &filterAce($oldlab);
        print "Old_laboratory\t \"$oldlab\"\n"; 
        push @dates, $oldlab_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub old_emailPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_old_email WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $old_email = $row[2];
      my $old_email_time = $row[3];
      my ($date_type) = $old_email_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($old_email !~ m/NULL/) { 
	$old_email =~ s/\s+/ /g; $old_email =~ s/^\s+//g; $old_email =~ s/\s+$//g;
#         $old_email =~ s/\//\\\//g;
#         $old_email =~ s/%/\\%/g;
        ($old_email) = &filterAce($old_email);
        print "Old_address\t $date_type Email \"$old_email\"\n"; 
        push @dates, $old_email_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub webpagePrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_webpage WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $webpage = $row[2];
      my $webpage_time = $row[3];
      if ($webpage !~ m/NULL/) { 
	$webpage =~ s/\s+/ /g; $webpage =~ s/^\s+//g; $webpage =~ s/\s+$//g;
#         $webpage =~ s/\//\\\//g;
#         $webpage =~ s/%/\\%/g;
        ($webpage) = &filterAce($webpage);
        print "Address\t Web_page \"$webpage\"\n"; 
        push @dates, $webpage_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub faxPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_fax WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $fax = $row[2];
      my $fax_time = $row[3];
      if ($fax !~ m/NULL/) { 
	$fax =~ s/\s+/ /g; $fax =~ s/^\s+//g; $fax =~ s/\s+$//g;
#         $fax =~ s/\//\\\//g;
        ($fax) = &filterAce($fax);
        print "Address\t Fax \"$fax\"\n"; 
        push @dates, $fax_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub otherphonePrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_otherphone WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $otherphone = $row[2];
      my $otherphone_time = $row[3];
      if ($otherphone !~ m/NULL/) { 
	$otherphone =~ s/\s+/ /g; $otherphone =~ s/^\s+//g; $otherphone =~ s/\s+$//g;
#         $otherphone =~ s/\//\\\//g;
        ($otherphone) = &filterAce($otherphone);
        print "Address\t Other_phone \"$otherphone\"\n"; 
        push @dates, $otherphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub officephonePrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_officephone WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $officephone = $row[2];
      my $officephone_time = $row[3];
      if ($officephone !~ m/NULL/) { 
	$officephone =~ s/\s+/ /g; $officephone =~ s/^\s+//g; $officephone =~ s/\s+$//g;
#         $officephone =~ s/\//\\\//g;
        ($officephone) = &filterAce($officephone);
        print "Address\t Office_phone \"$officephone\"\n"; 
        push @dates, $officephone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub labphonePrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_labphone WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $labphone = $row[2];
      my $labphone_time = $row[3];
      if ($labphone !~ m/NULL/) { 
	$labphone =~ s/\s+/ /g; $labphone =~ s/^\s+//g; $labphone =~ s/\s+$//g;
#         $labphone =~ s/\//\\\//g;
        ($labphone) = &filterAce($labphone);
        print "Address\t Lab_phone \"$labphone\"\n"; 
        push @dates, $labphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub mainphonePrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_mainphone WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $mainphone = $row[2];
      my $mainphone_time = $row[3];
      if ($mainphone !~ m/NULL/) { 
	$mainphone =~ s/\s+/ /g; $mainphone =~ s/^\s+//g; $mainphone =~ s/\s+$//g;
#         $mainphone =~ s/\//\\\//g;
        ($mainphone) = &filterAce($mainphone);
        print "Address\t Main_phone \"$mainphone\"\n"; 
        push @dates, $mainphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub emailPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_email WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $email = $row[2];
      my $email_time = $row[3];
      if ($email !~ m/NULL/) { 
	$email =~ s/\s+/ /g; $email =~ s/^\s+//g; $email =~ s/\s+$//g;
#         $email =~ s/\//\\\//g;
        $email =~ s/%/\\%/g;
        ($email) = &filterAce($email);
        print "Address\t Email \"$email\"\n"; 
        push @dates, $email_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub countryPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_country WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $country = $row[2];
      my $country_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $country =~ s/\s+/ /g; $country =~ s/^\s+//g; $country =~ s/\s+$//g;
#         $country =~ s/\//\\\//g;
        ($country) = &filterAce($country);
        print "Address\t Country \"$country\"\n"; 
        push @dates, $country_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub countryPrint

sub institutionPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_institution WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $institution = $row[2];
      my $institution_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $institution =~ s/\s+/ /g; $institution =~ s/^\s+//g; $institution =~ s/\s+$//g;
#         $institution =~ s/\//\\\//g;
        ($institution) = &filterAce($institution);
        if ($row[1] == 1) {			# put first thing in Address
          print "Address\t Institution \"$institution\"\n";  }
        else {					# put other things in Old_address
          my ($date_type) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
          print "Old_address\t $date_type Institution \"$institution\"\n";  }
        push @dates, $institution_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub countryPrint

sub streetPrint {
  my $joinkey = shift;
  my %street_hash; my @row;
  my @tables = qw( two_street two_city two_state two_post );
  foreach my $table (@tables) { 
    $result = $dbh->prepare ( "SELECT * FROM ${table} WHERE joinkey = '$joinkey' ORDER BY two_order;" );
    $result->execute();
    while ( @row = $result->fetchrow ) {	# foreach line of data
      if ($row[3]) { 				# if there's data (date)
        if ($table eq 'two_street') { 		# street data print straight out
          my $street = $row[2];
          my $street_time = $row[3];
          if ($row[2] !~ m/NULL/) { 		# if there's data
            $street =~ s/\s+/ /g; $street =~ s/^\s+//g; $street =~ s/\s+$//g;
#             $street =~ s/\//\\\//g;
            ($street) = &filterAce($street);
            print "Address\t Street_address \"$street\"\n";
            push @dates, $street_time;
          } # if ($row[2] !~ m/NULL/)
        } else { 				# city, state, and post preprocess
          if ($row[2] !~ m/NULL/) { 		# if there's data
            $row[2] =~ s/\s+/ /g;
#             $row[2] =~ s/\//\\\//g;
            $street_hash{$row[1]}{$table}{val} = $row[2];
            $street_hash{$row[1]}{$table}{time} = $row[3];
          }
        } 
      } # if ($row[3])
    } # while ( @row = $result->fetchrow )
  } # foreach my $table (@tables)

  foreach my $street_entry (sort keys %street_hash) {
    my $street_name; my $street_time = 0; my $street_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($street_hash{$street_entry}{$table}{time}) {
        $time_temp = $street_hash{$street_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $street_time_temp) { 
          $street_time_temp = $time_temp;
          $street_time = $street_hash{$street_entry}{$table}{time}; 
          push @dates, $street_time;
        }
      } # if ($street_hash{$street_entry}{$table}{time})
    } # foreach my $table (@tables)

    my $city; my $state; my $post; 
    if ($street_hash{$street_entry}{two_city}{val}) { $city = $street_hash{$street_entry}{two_city}{val}; }
    if ($street_hash{$street_entry}{two_state}{val}) { $state = $street_hash{$street_entry}{two_state}{val}; }
    if ($street_hash{$street_entry}{two_post}{val}) { $post = $street_hash{$street_entry}{two_post}{val}; }

    if ($city) { $city =~ s/\s+/ /g; $city =~ s/^\s+//g; $city =~ s/\s+$//g; }
    if ($state) { $state =~ s/\s+/ /g; $state =~ s/^\s+//g; $state =~ s/\s+$//g; }
    if ($post) { $post =~ s/\s+/ /g; $post =~ s/^\s+//g; $post =~ s/\s+$//g; }

    ($city) = &filterAce($city);
    ($state) = &filterAce($state);
    ($post) = &filterAce($post);
    if ( ($city) && ($state) && ($post) ) { print "Address\t Street_address \"$city, $state $post\"\n"; }
    elsif ( ($city) && ($state) ) { print "Address\t Street_address \"$city, $state\"\n"; }
    elsif ( ($city) && ($post) ) { print "Address\t Street_address \"$city, $post\"\n"; }
    elsif ( ($state) && ($post) ) { print "Address\t Street_address \"$state $post\"\n"; }
    elsif ($city) { print "Address\t Street_address \"$city\"\n"; }
    elsif ($state) { print "Address\t Street_address \"$state\"\n"; }
    elsif ($post) { print "Address\t Street_address \"$post\"\n"; }
    else { 1; }
  } # foreach my $street_entry (sort keys %street_hash)
} # sub streetPrint

sub labPrint {
  my $joinkey = shift;
  $result = $dbh->prepare ( "SELECT * FROM two_lab WHERE joinkey = '$joinkey';" );
  $result->execute();
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $lab = $row[2];
      my $lab_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $lab =~ s/\s+/ /g; $lab =~ s/^\s+//g; $lab =~ s/\s+$//g;
#         $lab =~ s/\//\\\//g;
        if ($lab !~ m/[A-Z][A-Z]/) { print ERR "ERROR $joinkey LAB $lab\n"; }
          else { 
            ($lab) = &filterAce($lab);
	    print "Laboratory\t \"$lab\"\n"; 
	  }
        push @dates, $lab_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub labPrint

sub apuPrint {
  my $joinkey = shift;
  my @row;
  my %apu_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $dbh->prepare ( "SELECT * FROM two_apu_${table}name WHERE joinkey = '$joinkey';" );
    $result->execute();
    while ( @row = $result->fetchrow ) { 
      if ($row[3]) { 
        $apu_hash{$row[1]}{$table}{val} = $row[2];
        $apu_hash{$row[1]}{$table}{time} = $row[3];
      }
    }
  } # foreach my $table (@tables)

  foreach my $apu_entry (sort keys %apu_hash) {
    my $apu_name; my $apu_time = 0; my $apu_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($apu_hash{$apu_entry}{$table}{time}) {
        $time_temp = $apu_hash{$apu_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $apu_time_temp) { 
          $apu_time_temp = $time_temp;
          $apu_time = $apu_hash{$apu_entry}{$table}{time}; 
        }
      } # if ($apu_hash{$apu_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($apu_hash{$apu_entry}{middle}{val}) { 
      $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{last}{val};
    } else {
      unless ($apu_hash{$apu_entry}{middle}{val} !~ m/NULL/) { 
        $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{last}{val};
      } else {
        $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{middle}{val} . " " . $apu_hash{$apu_entry}{last}{val};
      }
    }
    $apu_name =~ s/\s+/ /g; $apu_name =~ s/^\s+//g; $apu_name =~ s/\s+$//g;
#     $apu_name =~ s/\//\\\//g;
    if ($apu_name !~ m/NULL/) { 
# DON'T PUT IN BECAUSE PERSON SENDS STUFF AND IT MAY NOT BE ACEDB-FORMAT AUTHOR
#       print "Publishes_as\t \"$apu_name\"\n";	# confirmed 
#       print "Possibly_publishes_as\t \"$apu_name\"\n";	
#       print "Possibly_publishes_as\t \"$apu_name\"\n";
      push @dates, $apu_time;
    }
  } # foreach my $apu_entry (sort keys %apu_hash)
} # sub apuPrint

sub akaPrint {
  my $joinkey = shift;
  my @row;
  my %aka_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE joinkey = '$joinkey';" );
    $result->execute();
    while ( @row = $result->fetchrow ) { 
      if ($row[2]) { $aka_hash{$row[1]}{$table}{val} = $row[2]; } else { $aka_hash{$row[1]}{$table}{val} = ' '; }
      if ($row[3]) { $aka_hash{$row[1]}{$table}{time} = $row[3]; } else { $aka_hash{$row[1]}{$table}{time} = ' '; }
    }
  } # foreach my $table (@tables)

  foreach my $aka_entry (sort keys %aka_hash) {
    my $aka_name; my $aka_time = 0; my $aka_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($aka_hash{$aka_entry}{$table}{time}) {
        $time_temp = $aka_hash{$aka_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        unless ($time_temp) { $time_temp = '1970-01-01'; }
        if ($time_temp =~ m/\D/) { $time_temp =~ s/\D//g; }
        if ($time_temp > $aka_time_temp) { 
          $aka_time_temp = $time_temp;
          $aka_time = $aka_hash{$aka_entry}{$table}{time}; 
        }
      } # if ($aka_hash{$aka_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($aka_hash{$aka_entry}{middle}{val}) { 
      unless ($aka_hash{$aka_entry}{first}{val}) { $aka_hash{$aka_entry}{first}{val} = ' '; }
      unless ($aka_hash{$aka_entry}{last}{val}) { $aka_hash{$aka_entry}{last}{val} = ' '; }
      $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val};
      $aka_name =~ s/\s+/ /g; 
    } else {
      unless ($aka_hash{$aka_entry}{middle}{val}) { $aka_hash{$aka_entry}{middle}{val} = ''; }
      unless ($aka_hash{$aka_entry}{first}{val}) { $aka_hash{$aka_entry}{first}{val} = ' '; }
      unless ($aka_hash{$aka_entry}{last}{val}) { $aka_hash{$aka_entry}{last}{val} = ' '; }
      unless ($aka_hash{$aka_entry}{middle}{val} !~ m/NULL/) { 
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val}; 
        $aka_name =~ s/\s+/ /g; }
      else {
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{middle}{val} . " " . $aka_hash{$aka_entry}{last}{val}; $aka_name =~ s/\s+/ /g; }
    }
    $aka_name =~ s/\s+/ /g; $aka_name =~ s/^\s+//g; $aka_name =~ s/\s+$//g;
#     $aka_name =~ s/\//\\\//g;
    if ($aka_name !~ m/NULL/) { 
      $aka_name =~ s/\,//g;
#       $aka_name =~ s/\.//g; 		# Cecilia wants periods now  2009 01 20
      ($aka_name) = &filterAce($aka_name);
      print "Also_known_as\t \"$aka_name\"\n";
      push @dates, $aka_time;
    }
  } # foreach my $aka_entry (sort keys %aka_hash)
} # sub akaPrint


sub namePrint	{	# name block
  my $joinkey = shift;
  my $firstname; my $middlename; my $lastname; my $standardname; my $timestamp; my $full_name;
  $result = $dbh->prepare ( "SELECT * FROM two_firstname WHERE joinkey = '$joinkey';" );
  $result->execute();
  my @row = $result->fetchrow;
  if ($row[3]) { 
    $firstname = $row[2];
    $timestamp = $row[3];
    if ($firstname !~ m/NULL/) { 
      $firstname =~ s/\s+/ /g; $firstname =~ s/^\s+//g; $firstname =~ s/\s+$//g;
#       $firstname =~ s/\//\\\//g;
#       $firstname =~ s/\.//g; 		# Cecilia wants periods now  2009 01 20
      $firstname =~ s/\,//g;
      ($firstname) = &filterAce($firstname);
      print "First_name\t \"$firstname\"\n";
    } else { print ERR "ERROR no firstname for $joinkey : $firstname\n"; }
  }
  $result = $dbh->prepare ( "SELECT * FROM two_middlename WHERE joinkey = '$joinkey';" );
  $result->execute();
  @row = $result->fetchrow;
  if ($row[3]) { 
    $middlename = $row[2];
    $timestamp = $row[3];
    if ($middlename !~ m/NULL/) { 
      $middlename =~ s/\s+/ /g; $middlename =~ s/^\s+//g; $middlename =~ s/\s+$//g;
#       $middlename =~ s/\//\\\//g;
#       $middlename =~ s/\.//g; 	# Cecilia wants periods now  2009 01 20
      $middlename =~ s/\,//g;
      ($middlename) = &filterAce($middlename);
      print "Middle_name\t \"$middlename\"\n";
    } else { print ERR "ERROR no middlename for $joinkey : $middlename\n"; }
  }
  $result = $dbh->prepare ( "SELECT * FROM two_lastname WHERE joinkey = '$joinkey';" );
  $result->execute();
  @row = $result->fetchrow;
  if ($row[3]) { 
    $lastname = $row[2];
    $timestamp = $row[3];
    if ($lastname !~ m/NULL/) { 
      $lastname =~ s/\s+/ /g; $lastname =~ s/^\s+//g; $lastname =~ s/\s+$//g;
#       $lastname =~ s/\//\\\//g;
#       $lastname =~ s/\.//g; 		# Cecilia wants periods now  2009 01 20
      $lastname =~ s/\,//g;
      ($lastname) = &filterAce($lastname);
      print "Last_name\t \"$lastname\"\n";
    } else { print "ERROR no lastname for $joinkey : $lastname\n"; }
  }
  unless ($middlename) { $middlename = ''; }
  unless ($lastname) { print "// ERROR joinkey $joinkey has no lastname\n"; $lastname = ''; }
  unless ($firstname) { print "// ERROR joinkey $joinkey has no firstname\n"; $firstname = ''; }
  if ($middlename !~ m/NULL/) {
    $full_name = $firstname . " " . $middlename . " " . $lastname; }
  else {
    $full_name = $firstname . " " . $lastname; } 
  $standardname = $firstname . " " . $lastname;	# init as default first last
  $result = $dbh->prepare ( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey';" );
  $result->execute();
  @row = $result->fetchrow;
  if ($row[3]) {
    $standardname = $row[2];
    $timestamp = $row[3];
    if ($standardname !~ m/NULL/) { 
      $standardname =~ s/\s+/ /g; $standardname =~ s/^\s+//g; $standardname =~ s/\s+$//g;
#       $standardname =~ s/\//\\\//g;
    } else { print "ERROR no standardname for $joinkey : $standardname\n"; }
    ($standardname) = &filterAce($standardname);
    print "Standard_name\t \"$standardname\"\n";
  }
  unless ($full_name) { $full_name = ''; }
  if ($full_name !~ m/NULL/) {
    $full_name =~ s/\s+/ /g; $full_name =~ s/^\s+//g; $full_name =~ s/\s+$//g;
    ($full_name) = &filterAce($full_name);
    if ($full_name) {
      print "Full_name\t \"$full_name\"\n";
      push @dates, $timestamp; } }
  else { print ERR "ERROR no full_name for $joinkey : $full_name\n"; }
} # sub namePrint	


sub populatePaperHash {
    # assume for now that Cecilia only has valid data.
  my %paper_valid; my %paper_index;
  my $result = $dbh->prepare( "SELECT * FROM pap_author ORDER BY pap_timestamp ;");
  $result->execute();
  while (my @row = $result->fetchrow) { 
    $paper_index{$row[1]} = "WBPaper$row[0]"; }

  my %author_valid; my %author_index;
  $result = $dbh->prepare( "SELECT * FROM pap_author_index ORDER BY pap_timestamp ;");
  $result->execute();
  while (my @row = $result->fetchrow) { 
    if ($row[1] =~ m/\s+-COMMENT.*/) { $row[1] =~ s/\s+-COMMENT.*//g; }
    $author_index{$row[0]} = $row[1]; }

#   $result = $dbh->prepare( "
#     SELECT wpa_author_possible.author_id, wpa_author_possible.wpa_author_possible, wpa_author_possible.wpa_join, wpa_author_verified.wpa_author_verified, wpa_author_verified.wpa_timestamp 
#     FROM wpa_author_possible, wpa_author_verified 
#     WHERE wpa_author_possible.author_id = wpa_author_verified.author_id 
#       AND wpa_author_possible.wpa_join = wpa_author_verified.wpa_join 
#       AND (wpa_author_verified.wpa_author_verified ~ 'NO' OR wpa_author_verified.wpa_author_verified ~ 'YES')
#     ORDER BY wpa_timestamp; ");
  $result = $dbh->prepare( "
    SELECT pap_author_possible.author_id, pap_author_possible.pap_author_possible, pap_author_possible.pap_join, pap_author_verified.pap_author_verified, pap_author_verified.pap_timestamp 
    FROM pap_author_possible, pap_author_verified 
    WHERE pap_author_possible.author_id = pap_author_verified.author_id 
      AND pap_author_possible.pap_join = pap_author_verified.pap_join 
      AND (pap_author_verified.pap_author_verified ~ 'NO' OR pap_author_verified.pap_author_verified ~ 'YES')
    ORDER BY pap_timestamp; ");
  $result->execute();
  while (my @row = $result->fetchrow) {
    my $person = $row[1]; my $author_id = $row[0]; my $verified = $row[3]; my $paper = ''; my $author_name = '';
    next unless ($person);
    if ($verified =~ m/NO/) {
      if ($paper_index{$author_id}) { 
        $paper = $paper_index{$author_id}; 
        next if ($paper =~ m/\.[12]$/);		# skip .number papers otherwise we're creating them here	2008 10 09
        delete $paperHash{$person}{paper}{$paper}; delete $paperHash{$person}{paper_lab}{$paper}; delete $paperHash{$person}{paper_lineage}{$paper};
        $paperHash{$person}{not_paper}{$paper}++; } }
    else {
      if ($paper_index{$author_id}) {
        $paper = $paper_index{$author_id}; 
        next if ($paper =~ m/\.[12]$/);		# skip .number papers otherwise we're creating them here	2008 10 09
        delete $paperHash{$person}{not_paper}{$paper};
        if (($author_id ne 'two363') && ($verified =~ m/YES  Raymond Lee/)) { $paperHash{$person}{paper_lab}{$paper}++; }
        if (($author_id ne 'two363') && ($verified =~ m/YES Raymond Lee/)) { $paperHash{$person}{paper_lineage}{$paper}++; }
        $paperHash{$person}{paper}{$paper}++; }
      if ($author_index{$author_id}) {
        $author_name = $author_index{$author_id}; 
        $paperHash{$person}{author}{$author_name}++; } }
  } # while (my @row = $result->fetchrow)
} # sub populatePaperHash

sub paperPrint {
  my $joinkey = shift;
  foreach my $author (sort keys %{$paperHash{$joinkey}{author}}) {
    $author =~ s/\.//g; $author =~ s/,//g;
    if ($author =~ m/\" Affiliation_address/) { $author =~ s/\" Affiliation_address.*$//g; }
      # 2004 12 29 -- was dumping affiliation address data which is not in the model
    ($author) = &filterAce($author);
    print "Possibly_publishes_as\t \"$author\"\n";
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper}}) {
    $paper =~ s/\.$//g;					# take out dots at the end that are typos
    if ($paper =~ m/WBPaper/) { 
      print "Paper\t \"$paper\"\n"; }
    elsif ($convertToWBPaper{$paper}) {			# conver to WBPaper or print ERROR
      print "Paper\t \"$convertToWBPaper{$paper}\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; }
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper_lineage}}) {
    $paper =~ s/\.$//g;
    if ($paper =~ m/WBPaper/) {
      print "Paper\t \"$paper\" Curator_confirmed \"WBPerson363\"\n"; 
#       print "Paper\t \"$paper\" Inferred_automatically \"/home/cecilia/work/authors_not_verified/using_lineage/connect_by_lineage.pl\"\n";
      print "Paper\t \"$paper\" Inferred_automatically \"/home/postgres/work/pgpopulation/pap_papers/author_person/verify_automatically/verify_by_labs_or_lineage.pl\"\n"; }
    elsif ($convertToWBPaper{$paper}) {
      print "Paper\t \"$convertToWBPaper{$paper}\" Curator_confirmed \"WBPerson363\"\n"; 
#       print "Paper\t \"$convertToWBPaper{$paper}\" Inferred_automatically \"/home/cecilia/work/authors_not_verified/using_lineage/connect_by_lineage.pl\"\n";
      print "Paper\t \"$paper\" Inferred_automatically \"/home/postgres/work/pgpopulation/pap_papers/author_person/verify_automatically/verify_by_labs_or_lineage.pl\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; } }
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper_lab}}) {
    $paper =~ s/\.$//g;
    if ($paper =~ m/WBPaper/) {
      print "Paper\t \"$paper\" Curator_confirmed \"WBPerson363\"\n"; 
#       print "Paper\t \"$paper\" Inferred_automatically \"/home/cecilia/work/authors_not_verified/using_labs/connect_by_labs.pl\"\n";
      print "Paper\t \"$paper\" Inferred_automatically \"/home/postgres/work/pgpopulation/pap_papers/author_person/verify_automatically/verify_by_labs_or_lineage.pl\"\n"; }
    elsif ($convertToWBPaper{$paper}) {
      print "Paper\t \"$convertToWBPaper{$paper}\" Curator_confirmed \"WBPerson363\"\n"; 
#       print "Paper\t \"$convertToWBPaper{$paper}\" Inferred_automatically \"/home/cecilia/work/authors_not_verified/using_labs/connect_by_labs.pl\"\n";
      print "Paper\t \"$paper\" Inferred_automatically \"/home/postgres/work/pgpopulation/pap_papers/author_person/verify_automatically/verify_by_labs_or_lineage.pl\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; } }
  foreach my $paper (sort keys %{$paperHash{$joinkey}{not_paper}}) {
    $paper =~ s/\.$//g;
    if ($paper =~ m/WBPaper/) { print "Not_paper\t \"$paper\"\n"; }
    elsif ($convertToWBPaper{$paper}) { print "Not_paper\t \"$convertToWBPaper{$paper}\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; } }
} # sub paperPrint
  
sub readConvertions {
  my %ignoreHash;	# temporarily ignore list of stuff from Eimear because these WBPapers have been merged with others 
			# and are no longer the correct WBPaper 	2005 05 26
  my $eimearFileToIgnore = '/home/azurebrd/work/parsings/eimear/fixingEimearsPaper2WBPaperTable/Papers_with_only_Person_data.txt';
  open (IN, "<$eimearFileToIgnore") or die "Cannot open $eimearFileToIgnore : $!";
  while (<IN>) {
    my ($ignore) = $_ =~ m/^\"(.*?)\"\t/;
    $ignoreHash{$ignore}++;
  } # while (<IN>)

  my $u = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      unless ($ignoreHash{$2}) {		# temporarily ignore list of stuff from Eimear  2005 05 26
      $convertToWBPaper{$1} = $2; } }
      }
} # sub readConvertions

sub filterAce {
  my $identifier = shift;
  unless ($identifier) { return ""; }
  my $comment = '';
  if ($identifier =~ m/-COMMENT (.*)/) { $comment = $1; $identifier =~ s/-COMMENT .*//; }
  if ($identifier =~ m/HTTP:\/\//i) { $identifier =~ s/HTTP:\/\//PLACEHOLDERASDF/ig; }
  if ($identifier =~ m/HTTPS:\/\//i) { $identifier =~ s/HTTPS:\/\//PLACEHOLDERHTTPS/ig; }
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\\\/\\\//) { $identifier =~ s/\\\/\\\//" "/g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/PLACEHOLDERASDF/) { $identifier =~ s/PLACEHOLDERASDF/HTTP:\\\/\\\//g; }
  if ($identifier =~ m/PLACEHOLDERHTTPS/) { $identifier =~ s/PLACEHOLDERHTTPS/HTTPS:\\\/\\\//g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  if ($comment) {
    if ($identifier =~ m/[^"]$/) { $identifier .= "\" "; }
    $identifier .= "-C \"$comment"; }
  return $identifier;
} # sub filterAce



__END__

# Deprecated

sub oldpopulatePaperHash {
#   my $result = $dbh->prepare( "SELECT * FROM pap_view WHERE pap_verified ~ 'YES';");
  my $result = $dbh->prepare( "SELECT * FROM wpa_author_verified WHERE wpa_author_verified ~ 'YES';");
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      my ($joinkey, $author, $person);
      if ($row[0]) { if ($row[0] =~ m//) { $row[0] =~ s///g; } $joinkey = $row[0]; }
      if ($row[1]) { if ($row[1] =~ m//) { $row[1] =~ s///g; } $author = $row[1]; }
      if ($row[2]) { if ($row[2] =~ m//) { $row[2] =~ s///g; } $person = $row[2]; }
      unless ($person) { $person = ' '; }
      unless ($joinkey) { $joinkey = ' '; }
      $paperHash{$person}{paper}{$joinkey}++; 
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
  
  $result = $dbh->prepare( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible IS NOT NULL;");
  $result->execute();
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      $row[1] =~ s///g; my $author = $row[1];
      $row[2] =~ s///g; my $person = $row[2];
      if ($author =~ m/^[\-\w\s]+"/) { $author =~ m/^([\-\w\s]+)\"/; $author = $1; }
      $paperHash{$person}{author}{$author}++;
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
} # sub oldpopulatePaperHash
