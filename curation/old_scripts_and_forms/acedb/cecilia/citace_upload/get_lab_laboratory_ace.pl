#!/usr/bin/perl -w

# Dump Laboratory data.  2017 11 02


use strict;
use diagnostics;
# use Pg;
use DBI;
use Jex;
use LWP;

# my $dbh = DBI->connect ( "dbi:Pg:dbname=devdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
my @data_tables   = qw( name status mail phone email fax url alleledesignation remark );
my @normal_tables = qw( mail phone email fax url alleledesignation remark );

my $qualifier_general = ''; my $qualifier_paper_hash = '';  my $specific_two_num = 'all'; 
if ($specific_two_num ne 'all') { 
  $qualifier_paper_hash = " AND pap_author_possible.pap_author_possible = '$specific_two_num'";
  $qualifier_general    = " AND joinkey = '$specific_two_num'"; }

my %data;
foreach my $table (@data_tables) {
  $result = $dbh->prepare( "SELECT * FROM lab_$table WHERE lab_$table != 'NULL' $qualifier_general" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    $row[0] =~ s/lab//;
    my $data = $row[2];
#     my ($date_type) = $row[4] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
#     if ( ($table eq 'old_inst_date') || ($table eq 'old_email_date') ) {
#       if ($row[2] =~ m/^\s+/) { $row[2] =~ s/^\s+//; } if ($row[2] =~ m/\s+$/) { $row[2] =~ s/\s+$//; }
#       ($data) = $row[2] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/; }
#     $data{$table}{$row[0]}{$row[1]}{time} = $date_type;
    $data{$table}{$row[0]}{$row[1]}{data} = $data; } }

my %tableToTag;
$tableToTag{mail}              = "Mail";                      
$tableToTag{phone}             = "Phone";                     
$tableToTag{email}             = "E_mail";                    
$tableToTag{fax}               = "Fax";                       
$tableToTag{url}               = "URL";                       
# $tableToTag{straindesignation} = "Strain_designation";        
$tableToTag{alleledesignation} = "Allele_designation";
$tableToTag{remark}            = "Remark";                    


foreach my $twonum (sort {$a<=>$b} keys %{ $data{status} }) {
  next if ($data{status}{$twonum}{1}{data} ne 'Valid');

  print qq(\nLaboratory : "$data{name}{$twonum}{1}{data}"\n); 
  print qq(Strain_designation\t"$data{name}{$twonum}{1}{data}"\n); 

  foreach my $table (@normal_tables) {
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
#       if ($time) {
#         my $datenum = $time; $datenum =~ s/\-//g;
#         if ($datenum > $highest_date_num) { $highest_date = $time; $highest_date_num = $datenum; } }
      print "$tableToTag{$table}\t\"$data\"\n";
    } # foreach my $order (sort {$a<=>$b} keys %{ $data{$table}{$twonum} })
  } # foreach my $table (@normal_tables)
} # foreach my $twonum (sort {$a<=>$b} keys %{ $data{status} })



__END__

my $start = time;

my $error_file = 'errors_in_pap_person.ace';
open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 

my @normal_tables = qw(firstname middlename lastname standardname aka_firstname aka_middlename aka_lastname email old_email old_email_date street city state post country institution old_institution old_inst_date mainphone labphone officephone otherphone fax pis lab oldlab left_field unable_to_contact privacy webpage usefulwebpage wormbase_comment hide status mergedinto acqmerge orcid comment );

my %order_type;
my @single_order = qw( firstname middlename lastname standardname city state post country left_field unable_to_contact hide status mergedinto );
my @multi_order = qw( street institution old_institution old_inst_date mainphone labphone officephone otherphone fax email old_email old_email_date pis lab oldlab privacy aka_firstname aka_middlename aka_lastname webpage usefulwebpage wormbase_comment acqmerge orcid comment );
foreach (@single_order) { $order_type{single}{$_}++; }
foreach (@multi_order) { $order_type{multi}{$_}++; }

my $qualifier_general = ''; my $qualifier_paper_hash = '';  my $specific_two_num = 'all'; 
# $specific_two_num = 'two1';
# $specific_two_num = 'two6792';
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
    if ( ($table eq 'old_inst_date') || ($table eq 'old_email_date') ) {
      if ($row[2] =~ m/^\s+/) { $row[2] =~ s/^\s+//; } if ($row[2] =~ m/\s+$/) { $row[2] =~ s/\s+$//; }
      ($data) = $row[2] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/; }
    $data{$table}{$row[0]}{$row[1]}{time} = $date_type;
    $data{$table}{$row[0]}{$row[1]}{data} = $data; } }

my %tableToTag;
$tableToTag{'status'}            = 'Status';
$tableToTag{'mergedinto'}        = 'Merged_into';
$tableToTag{'acqmerge'}          = 'Acquires_merge';
$tableToTag{'left_field'}        = "Left_the_field"; 
$tableToTag{'unable_to_contact'} = "Last_attempt_to_contact\t date_type";	# needs date_type
$tableToTag{'orcid'}             = "Database\t\"ORCID\"\t\"Accession_number\"";
$tableToTag{'wormbase_comment'}  = "Comment"; 
$tableToTag{'comment'}           = "Comment";
$tableToTag{'old_institution'}   = "Old_address\t date_type Institution"; 	# needs date_type
$tableToTag{'oldlab'}            = "Old_laboratory"; 
$tableToTag{'old_email'}         = "Old_address\t date_type Email"; 		# needs date_type
$tableToTag{'lab'}               = "Laboratory"; 
$tableToTag{'pis'}               = "Principal_investigator"; 				# added 2016 02 09
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
  print "\nPerson : \"WBPerson$twonum\"\n"; 
  print "$tableToTag{status}\t\"$data{status}{$twonum}{1}{data}\"\n"; 
  if ($data{status}{$twonum}{1}{data} eq 'Invalid') { 
    if ($data{mergedinto}{$twonum}{1}{data}) { 
        my $data = $data{mergedinto}{$twonum}{1}{data}; $data =~ s/two/WBPerson/; 
        print "$tableToTag{mergedinto}\t\"$data\"\n"; } 
#       else { print ERR "Invalid two$twonum not merged into anything two_mergedinto\n"; } 	# cecilia doesn't want this warning
  }
  next if ($data{status}{$twonum}{1}{data} ne 'Valid');
#   next if ($data{hide}{$twonum}{1}{data});					# skip those to hide
  if ($data{hide}{$twonum}{1}{data}) {	# skip those to hide, print the object, status, standardname, and a comment for Cecilia and Raymond.  2013 03 06
    print qq(Comment\t"This person requested not to be contacted."\n);
    print qq($tableToTag{standardname}\t\"$data{standardname}{$twonum}{1}{data}\"\n); 
    next;
  }
  my $highest_date = ''; my $highest_date_num = 0;
  my ($city, $state, $post) = ('', '', '');
  my %akas;
  foreach my $table (@normal_tables) {
    next if ( ($table eq 'status') || ($table eq 'mergedinto') || 				# tags already printed
              ($table eq 'aka_middlename') || ($table eq 'aka_lastname') || 			# aka tags printed as part of another
              ($table eq 'old_email_date') || ($table eq 'old_inst_date') || 			# date tags printed as part of another
              ($table eq 'usefulwebpage') || ($table eq 'hide') || 				# tags not for printing
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
        elsif ($table eq 'pis') { print "$tableToTag{$table}\n"; }
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
