#!/usr/bin/perl

# Editing to work wiht wpa_ tables in testdb instead of demo4.  2005 06 27
#
# Adapted to populate wpa_electronic_path_type based on daniel's Reference
# directory in /home/acedb/daniel/Reference/   2005 06 29
#
# Adapted for Cecilia's pap_ data, as well as Daniel's ref_hardcopy and 
# general pdfs by location on tazendra.  2005 07 19

use strict;
use diagnostics;
use Pg;
use LWP::UserAgent;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn ->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hardcopy;

my ($date) = &getSimpleSecDate();
my $start_time = time;
# my $estimate_time = time + 336;         # estimate 336 seconds
# my $estimate_time = time + 853;         # estimate 853 seconds
my $estimate_time = time + 683;         # estimate 683 seconds
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
if ($min < 10) { $min = "0$min"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";


my $outfile = 'populate_electronic_path_type.out';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $errfile = 'populate_electronic_path_type.err';
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";
my $warn_file = 'populate_electronic_path_type.warnings';	# for log of things skipped or ignored rightfully
open (WAR, ">$warn_file") or die "Cannot create $warn_file : $!";




my %convertToWBPaper;
my %backwards;
&readConversions;


my %no_wbpaper;

my %wpa;	# hash of stuff to insert into postgres
my $result = $conn->exec( "SELECT * FROM wpa;" );	# valid papers, originally all valid
while (my @row = $result->fetchrow) { $wpa{valid}{$row[0]}++; }

  # clear up old data
$result = $conn->exec( "DELETE FROM wpa_hardcopy; ");
$result = $conn->exec( "DELETE FROM wpa_electronic_path_type; ");
$result = $conn->exec( "DELETE FROM wpa_author_sent; ");
$result = $conn->exec( "DELETE FROM wpa_author_verified; ");
$result = $conn->exec( "DELETE FROM wpa_author_possible; ");


  # manual mappings of what papers used to have as authors in the freezes, and
  # what they have as authors in the current dump (probably changed by Eimear)
my %author_mappings;
&initManual();			# initialize %author_mappings hash


my %authors;	# hash from wpa_author_index, which contains the author names and author ids
                # maps $authors{auth_id}{$auth_id} = $auth_name;
                # maps $authors{paper}{$joinkey}{$auth_name} = $auth_id;  for backwards
$result = $conn->exec( "SELECT author_id, wpa_author_index FROM wpa_author_index;" );
while (my @row = $result->fetchrow) { 
  my $auth_id = $row[0];
  my $auth_name = $row[1];
  if ($auth_name =~ m/\".*/) { $auth_name =~ s/\".*$//g; }				# take out comments
  if ($auth_name =~ m/\s+$/) { $auth_name =~ s/\s+$//; }				# take out end spaces
  if ($auth_name =~ m/\s*\-COMMENT.*$/) { $auth_name =~ s/\s*\-COMMENT.*$//; }		# take out wpa_ comments
# if ($auth_name =~ m/Ali MY/) { print "37787 $auth_id -=${auth_name}=-\n"; }
  $authors{auth_id}{$auth_id} = $auth_name; } 

$result = $conn->exec( "SELECT joinkey, wpa_author FROM wpa_author;" );
while (my @row = $result->fetchrow) { 
  my $joinkey = $row[0];
    # don't care that the joinkey is an In_book (.2) since wpa_ tables will only match to author_id, not the paper itself.  
    # this makes the hashing easier to match a $wbpaper to this joinkey later on.  do care about .1 becuase Erratum 4301 is really 4137.1
  if ($joinkey =~ m/\.2.*$/) { $joinkey =~ s/\.2.*$//; }	
  my $auth_id = $row[1];
  if ($authors{auth_id}{$row[1]}) {				# if the author id exists (it should)
    my $auth_name = $authors{auth_id}{$row[1]};			# get the name
if ($joinkey eq '00001577') { print STDERR "$joinkey $auth_name $auth_id 1577\n"; }
if ($joinkey =~ m/00002064/) { print STDERR "$joinkey NAME $auth_name AUTH ID $auth_id 2064\n"; }
    $authors{paper}{$joinkey}{$auth_name} = $auth_id; } }	# store the name

my %pap_values;
  # from pap_ tables 
  # store original papers (e.g. 1577) for error file : $pap_values{$wbpaper}{papers}{$row[0]}++;	
  # for each pap_author store the possible/sent/verified value/timestamp values
  # by pushing into an array because could have multiple authors if some verified as NO :
  # push @{ $pap_values{$wbpaper}{author}{$author}{possible}{value} }, $pos_value;  (etc.)

# $result = $conn->exec( "SELECT * FROM pap_possible; ");
# while (my @row = $result->fetchrow) {
#   if ($convertToWBPaper{$row[0]}) {
#     my $wbpaper = $convertToWBPaper{$row[0]}; 
#     $wbpaper =~ s/WBPaper//g;
#     $pap_values{$wbpaper}{papers}{$row[0]}++;
#     my $author = $row[1];
#     if ($author =~ m/\".*/) { $author =~ s/\".*$//g; }
#     if ($author =~ m/\s+$/) { $author =~ s/\s+$//; }
#     if ($author =~ m/\s*\-COMMENT.*$/) { $author =~ s/\s*\-COMMENT.*$//; }
#     my $value = 'NULL';				# init pap_possible value
#     
#     if ($row[2]) { $value = "'$row[2]'"; }	# assign if exists
#     if ($pap_values{$wbpaper}{author}{$author}{possible}{value}) {
#       if ($pap_values{$wbpaper}{author}{$author}{possible}{value} ne 'NULL') {
#         print WAR "SKIPPING $wbpaper $author Has possible value $pap_values{$wbpaper}{author}{$author}{possible}{value}\n"; }
#       else {
#         $pap_values{$wbpaper}{author}{$author}{possible}{value} = $value;
#         $pap_values{$wbpaper}{author}{$author}{possible}{timestamp} = $row[3]; } }
#     else {
#       $pap_values{$wbpaper}{author}{$author}{possible}{value} = $value;
#       $pap_values{$wbpaper}{author}{$author}{possible}{timestamp} = $row[3]; }
#   } else { print WAR "NO pap_possible CONVERSION $row[0] :\n"; }
# } # while (my @row = $result->fetchrow)
# 
# $result = $conn->exec( "SELECT * FROM pap_email; ");
# while (my @row = $result->fetchrow) {
#   if ($convertToWBPaper{$row[0]}) {
#     my $wbpaper = $convertToWBPaper{$row[0]}; 
#     $wbpaper =~ s/WBPaper//g;
#     $pap_values{$wbpaper}{papers}{$row[0]}++;
#     my $author = $row[1];
#     if ($author =~ m/\".*/) { $author =~ s/\".*$//g; }
#     if ($author =~ m/\s+$/) { $author =~ s/\s+$//; }
#     if ($author =~ m/\s*\-COMMENT.*$/) { $author =~ s/\s*\-COMMENT.*$//; }
#     my $value = 'NULL';
#     if ($row[2]) { $value = "'$row[2]'"; }
#     if ($pap_values{$wbpaper}{author}{$author}{sent}{value}) {
#       if ($pap_values{$wbpaper}{author}{$author}{sent}{value} ne 'NULL') {
#         print WAR "SKIPPING $wbpaper $author Has sent value $pap_values{$wbpaper}{author}{$author}{sent}{value}\n"; }
#       else {
#         $pap_values{$wbpaper}{author}{$author}{sent}{value} = $value;
#         $pap_values{$wbpaper}{author}{$author}{sent}{timestamp} = $row[3]; } }
#     else {
#       $pap_values{$wbpaper}{author}{$author}{sent}{value} = $value;
#       $pap_values{$wbpaper}{author}{$author}{sent}{timestamp} = $row[3]; }
#   }
#   else { print WAR "NO pap_email CONVERSION $row[0] :\n"; }
# } # while (my @row = $result->fetchrow)
# 
# $result = $conn->exec( "SELECT * FROM pap_verified; ");
# while (my @row = $result->fetchrow) {
#   if ($convertToWBPaper{$row[0]}) {
#     my $wbpaper = $convertToWBPaper{$row[0]}; 
#     $wbpaper =~ s/WBPaper//g;
#     $pap_values{$wbpaper}{papers}{$row[0]}++;
#     my $author = $row[1];
#     if ($author =~ m/\".*/) { $author =~ s/\".*$//g; }
#     if ($author =~ m/\s+$/) { $author =~ s/\s+$//; }
#     if ($author =~ m/\s*\-COMMENT.*$/) { $author =~ s/\s*\-COMMENT.*$//; }
# # if ($author =~ m/Ali MY/) { print "37787 -=${author}=-\n"; }
#     my $value = 'NULL';
#     if ($row[2]) { 
#       if ($row[2] =~ m/\'/) { $row[2] =~ s/\'/''/g; } 
#       $value = "'$row[2]'"; }
#     if ($pap_values{$wbpaper}{author}{$author}{verified}{value}) {
#       if ($pap_values{$wbpaper}{author}{$author}{verified}{value} ne 'NULL') {
#         print WAR "SKIPPING $wbpaper $author Has verified value $pap_values{$wbpaper}{author}{$author}{verified}{value}\n"; }
#       else {
#         $pap_values{$wbpaper}{author}{$author}{verified}{value} = $value;
#         $pap_values{$wbpaper}{author}{$author}{verified}{timestamp} = $row[3]; } }
#     else {
#       $pap_values{$wbpaper}{author}{$author}{verified}{value} = $value;
#       $pap_values{$wbpaper}{author}{$author}{verified}{timestamp} = $row[3]; }
#   }
#   else { print WAR "NO pap_verified CONVERSION $row[0] :\n"; }
# } # while (my @row = $result->fetchrow)

# $result = $conn->exec( "SELECT * FROM pap_view; ");
$result = $conn->exec( "
 SELECT pap_possible.joinkey, pap_possible.pap_author, pap_possible.pap_possible, pap_email.pap_email, pap_verified.pap_verified,
        pap_possible.pap_timestamp, pap_email.pap_timestamp, pap_verified.pap_timestamp
 FROM pap_possible, pap_email, pap_verified
 WHERE pap_possible.joinkey = pap_email.joinkey 
   AND pap_possible.joinkey = pap_verified.joinkey 
   AND pap_possible.pap_author = pap_email.pap_author 
   AND pap_possible.pap_author = pap_verified.pap_author; ");
# Have to query across multiselect to make sure Author names with difference
# after " match each other, e.g. SELECT * FROM pap_view WHERE joinkey = 'wcwm2000ab41';
#  wcwm2000ab41 | Johnson CD" Affiliation_address "Institute for Behavioral Genetics, University of Colorado, Boulder, CO 80309        | two1122      | SENT | NO  Carl D. Johnson
#  wcwm2000ab41 | Johnson CD"Carolyn J. Johnson" | two1120      |           | YES  Carolyn J. Johnson
# Can't use pap_view because it loses timestamps

while (my @row = $result->fetchrow) {
  if ( ($convertToWBPaper{$row[0]}) || ($row[0] eq 'cgc4301') ) { 
    my $wbpaper = '';			# 4301 is the only erratum which now becomes 4137.1, this is a manual fix
    if ($convertToWBPaper{$row[0]}) {
      $wbpaper = $convertToWBPaper{$row[0]}; 	# get the wbpaper
      $wbpaper =~ s/WBPaper//g; }		# get only the number
    elsif ($row[0] eq 'cgc4301') { $wbpaper = '00004137.1'; }		# manually assign the erratum number to cgc4301
    else { print WAR "NO pap_verified CONVERSTION $row[0] :\n"; next; }
if ($wbpaper =~ m/00002064/) { print STDERR "GOT FROM pap_view 2064\n"; }
    $pap_values{$wbpaper}{papers}{$row[0]}++;	# store original papers e.g.  cgc1577 for error file
    my $author = $row[1];
    if ($author =~ m/\".*/) { $author =~ s/\".*$//g; }		# take out comments or Affiliation or whatever
    if ($author =~ m/\s+$/) { $author =~ s/\s+$//; }		# take out trailing spaces
    if ($author =~ m/\s*\-COMMENT.*$/) { $author =~ s/\s*\-COMMENT.*$//; }	# take out stored comments (possibly not necessary)
# if ($author =~ m/Ali MY/) { print "37787 -=${author}=-\n"; }
    my $pos_value = 'NULL'; my $sent_value = 'NULL'; my $ver_value = 'NULL';	# init values
    my $pos_timestamp = 'NULL'; my $sent_timestamp = 'NULL'; my $ver_timestamp = 'NULL';
    if ($row[2]) { if ($row[2] =~ m/\'/) { $row[2] =~ s/\'/''/g; } $pos_value = "'$row[2]'"; }
    if ($row[3]) { if ($row[3] =~ m/\'/) { $row[3] =~ s/\'/''/g; } $sent_value = "'$row[3]'"; }
    if ($row[4]) { if ($row[4] =~ m/\'/) { $row[4] =~ s/\'/''/g; } $ver_value = "'$row[4]'"; }
    if ($row[5]) { $pos_timestamp = "'$row[5]'"; }		# filter for quotes if there's values
    if ($row[6]) { $sent_timestamp = "'$row[6]'"; }		# NULL would have no quotes around it
    if ($row[7]) { $ver_timestamp = "'$row[7]'"; }
if ($wbpaper =~ m/00004137/) { print "BOOM $pos_value . $sent_value .  $ver_value . $pos_timestamp . $sent_timestamp . $ver_timestamp\n"; }
    push @{ $pap_values{$wbpaper}{author}{$author}{possible}{value} }, $pos_value;
    push @{ $pap_values{$wbpaper}{author}{$author}{sent}{value} }, $sent_value;
    push @{ $pap_values{$wbpaper}{author}{$author}{verified}{value} }, $ver_value;
    push @{ $pap_values{$wbpaper}{author}{$author}{possible}{timestamp} }, $pos_timestamp;
    push @{ $pap_values{$wbpaper}{author}{$author}{sent}{timestamp} }, $sent_timestamp;
    push @{ $pap_values{$wbpaper}{author}{$author}{verified}{timestamp} }, $ver_timestamp;
  }
  else { print WAR "NO pap_verified CONVERSION $row[0] :\n"; }
} # while (my @row = $result->fetchrow)

foreach my $wbpaper (sort keys %pap_values) {
my $whatever = 0;
# if ($wbpaper eq '00023328') { $whatever++; }
# if ($wbpaper eq '00023690') { $whatever++; }
# if ($wbpaper =~ m/00002064/) { $whatever++; }
if ($wbpaper =~ m/00004137/) { $whatever++; }
if ($wbpaper =~ m/00004301/) { $whatever++; }

  if ($authors{paper}{$wbpaper}) {	# if have wpa authors for that pap table converted wbpaper
if ($whatever > 0) { print STDERR "$wbpaper YES authors{paper} 2064\n"; }
    foreach my $pap_author (sort keys %{ $pap_values{$wbpaper}{author} } ) {	# for each pap author
if ($whatever > 0) { print STDERR "$wbpaper $pap_author 2064\n"; }
      if ($pap_author =~ m/\".*/) { $pap_author =~ s/\".*$//g; }		# clear comments
      if ($pap_author =~ m/\s+$/) { $pap_author =~ s/\s+$//; }			# clear trailing spaces
# if ($whatever > 0) { print "WPA $wbpaper PAPAUTH $pap_author END\n"; }
      if ($pap_author =~ m/\s*\-COMMENT.*$/) { $pap_author =~ s/\s*\-COMMENT.*$//; }	# clear comments
# if ($whatever > 0) { print "WPA $wbpaper PAPAUTH $pap_author END\n"; }
      my $good = 0;			# flag that have author_id
      my $author_id = '';		# no answer yet, if guessConnection it assigns, otherwise get from $authors{paper}{$wbpaper}{$pap_author}
      my $real_pap_author = $pap_author;	# keep copy
      my $error_message = '';		# error_message if don't find an author_id


# if ($author_id eq '43642') { print "FOREACH GUESSING 43642 JOIN $wbpaper \n"; }
# if ($pap_author =~ m/BRUNET/) { print "FOREACH BRUNET : $pap_author JOIN $wbpaper \n"; }


      if ($authors{paper}{$wbpaper}{$pap_author}) { $good++; 	# there's a wpa match straight up
# if ($wbpaper eq '00015620') { print "IF WPA $wbpaper PAPAUTH $pap_author END\n"; }
if ($whatever > 0) { print "$wbpaper DIRECT MATCH $pap_author PAP AUTHOR\n"; }
}		# if the author name is in that paper in wpa_ tables
      else {								# author name not in the wpa_ tables, have to guess

if ($whatever > 0) { print "$wbpaper TRY TO GUESS $pap_author PAP AUTHOR\n"; }

#         my $pos_value = $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value};
        my $pos_value = '';
          # get first non-null possible two value (from pap_possible)
        foreach my $looping_value (@{ $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} }) {
          if ($looping_value ne 'NULL') { $pos_value = $looping_value; last; } }
        my $flag = 0;		# flag that authors has a cecilia-matched possible two number
        if ($pos_value) { 			# if there's a value
if ($whatever > 0) { print "$wbpaper WHATEVER $pap_author PAP AUTHOR $pos_value POS VALUE\n"; }
          if ($pos_value ne 'NULL') { 		# if value is not null
            $flag++; 
} }
else { 1;
if ($whatever > 0) { print "$wbpaper WHATEVER $real_pap_author REAL PAP AUTHOR $pap_author PAP AUTHOR NO POS VALUE\n"; }
}
if ($whatever > 0) { print "$wbpaper WHATEVER $pap_author PAP AUTHOR $flag FLAG\n"; }
        if ($flag > 0) {
          ($author_id, $error_message) = &guessConnection($pap_author, $wbpaper, $pos_value); 
if ($whatever > 0) { print "$wbpaper WHATEVER $pap_author PAP AUTHOR $author_id ID $flag FLAG\n"; }
          if ($author_id > 0) { $good++; } }
        else {
          print WAR "NO Author Match, no data lost : Author $pap_author in paper -=${wbpaper}=-\n\n"; }
      }

      if ($good == 0) {				# still no match, try manual mappings
        if ( $author_mappings{$pap_author} ) {				# if there's a manual mapping of the author
# if ($whatever > 0) { print "$wbpaper ELSIF $pap_author PAP AUTHOR\n"; }

# if ($pap_author =~ m/BRUNET/) { print "ELSIF BRUNET : $pap_author JOIN $wbpaper \n"; }
# if ($pap_author =~ m/Brunet J-F/) { print "ELSIF Brunet J-F : $pap_author JOIN $wbpaper\n"; }

        foreach my $manual_mapping ( sort keys %{ $author_mappings{$pap_author} } ) {

# if ($pap_author =~ m/BRUNET/) { print "MANUAL $manual_mapping : BRUNET : $pap_author JOIN $wbpaper \n"; }
# if ($pap_author =~ m/Brunet J-F/) { print "MANUAL $manual_mapping : Brunet J-F : $pap_author JOIN $wbpaper\n"; } # HERE 

          if ($authors{paper}{$wbpaper}{$manual_mapping}) {		# and the manual mapping is in the wpa_ tables
            $good++; $pap_author = $manual_mapping; 			# replace the pap_author with the manual mapping value
# if ($pap_author =~ m/BRUNET/) { $whatever++; print "MATCHES $manual_mapping BRUNET : $pap_author JOIN $wbpaper \n"; } # HERE
# if ($pap_author =~ m/Brunet J-F/) { print "MATCHES $manual_mapping : Brunet J-F : $pap_author JOIN $wbpaper\n"; }
} } } }		# switch pap_author to match now


if ($whatever > 0) { print "$wbpaper WHATEVER $pap_author PAP AUTHOR\n"; }
      if ($good <= 0) {		# failed to find a match for that pap author
if ($whatever > 0) { print STDERR "$wbpaper good less equal zero  2064\n"; }
        if ($error_message) { print ERR "$error_message\n"; } }
      else { # if ($good <= 0)	# found an author id for that pap author
if ($whatever > 0) { print "$wbpaper GOOD $good GOOD\n"; }
        if ($author_id) {	# if author id from guessing subroutine
if ($whatever > 0) { print "$wbpaper AID $author_id AID\n"; }
            # if author id returned zero from guessing, but manual mapping worked, get from %authors since pap_author has changed to match
          unless ($author_id > 0) {	
if ($whatever > 0) { print "$wbpaper AID NOT GREATER ZERO $author_id AID\n"; }
# print "GRABBING author id\n";
            $author_id = $authors{paper}{$wbpaper}{$pap_author}; 
if ($pap_author =~ m/BRUNET/i) { print "NOT GRABBING $author_id BRUNET : $pap_author JOIN $wbpaper \n"; }
if ($pap_author =~ m/Brunet J-F/) { print "GRABBING $author_id Brunet J-F : $pap_author JOIN $wbpaper\n"; }
if ($pap_author =~ m/BRUNET/) { print "GRABBING $author_id BRUNET : $pap_author JOIN $wbpaper \n"; }
} 
if ($whatever > 0) { print "$wbpaper AID GREATER ZERO $author_id AID\n"; }
}	# grab the author id
        else {
            $author_id = $authors{paper}{$wbpaper}{$pap_author}; 
if ($whatever > 0) { print "$wbpaper ELSE GRABBING $author_id AID $pap_author PAP_AUTHOR\n"; }
} 	# grab the author id
# print "AID $author_id\n";

          # loop through all pap values (could be multiples for each pap author)
        while (@{ $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} }) {
if ($whatever > 0) { print STDERR "$wbpaper WHILE values \n"; }
          my $pos_value = shift( @{ $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} } );
          my $sent_value = shift( @{ $pap_values{$wbpaper}{author}{$real_pap_author}{sent}{value} } );
          my $ver_value = shift( @{ $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value} } );
          my $pos_timestamp = shift( @{ $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{timestamp} } );
          my $sent_timestamp = shift( @{ $pap_values{$wbpaper}{author}{$real_pap_author}{sent}{timestamp} } );
          my $ver_timestamp = shift( @{ $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{timestamp} } );
if ($whatever > 0) { print "BOOM2 $author_id AUTHID $pos_value . $sent_value .  $ver_value . $pos_timestamp . $sent_timestamp . $ver_timestamp\n"; }
          if ($pos_value) {	# if there's a value add to hash for inserting into postgres
            push @{ $wpa{possible}{$wbpaper}{$author_id}{value} }, $pos_value;
            push @{ $wpa{sent}{$wbpaper}{$author_id}{value} }, $sent_value;
            push @{ $wpa{verified}{$wbpaper}{$author_id}{value} }, $ver_value;
            push @{ $wpa{possible}{$wbpaper}{$author_id}{timestamp} }, $pos_timestamp;
            push @{ $wpa{sent}{$wbpaper}{$author_id}{timestamp} }, $sent_timestamp;
            push @{ $wpa{verified}{$wbpaper}{$author_id}{timestamp} }, $ver_timestamp; }
if ($whatever > 0) { print STDERR "$wbpaper PUSHED values 2064\n"; }
if ($whatever > 0) { 
foreach my $temp_pos_value ( @{ $wpa{possible}{$wbpaper}{$author_id}{value} } ) { print "TEMP POS $temp_pos_value WBP $wbpaper\n"; } }
        } # while (@{ $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} })

#         if ($pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value}) { 
# if ($author_id eq '61360') { print "61360 POS $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} JOIN $wbpaper \n"; }
# if ($author_id eq '43642') { print "43642 POS $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} JOIN $wbpaper \n"; }
# if ($author_id eq '16678') { print "16678 POS $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} JOIN $wbpaper \n"; }
# if ($author_id eq '15954') { print "15954 POS $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} JOIN $wbpaper \n"; }
#           $wpa{possible}{$wbpaper}{$author_id}{value} = $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{value} ; }
#         if ($pap_values{$wbpaper}{author}{$real_pap_author}{possible}{timestamp}) { 
#           $wpa{possible}{$wbpaper}{$author_id}{timestamp} = $pap_values{$wbpaper}{author}{$real_pap_author}{possible}{timestamp} ; }
#         if ($pap_values{$wbpaper}{author}{$real_pap_author}{sent}{value}) { 
#           $wpa{sent}{$wbpaper}{$author_id}{value} = $pap_values{$wbpaper}{author}{$real_pap_author}{sent}{value} ; }
#         if ($pap_values{$wbpaper}{author}{$real_pap_author}{sent}{timestamp}) { 
#           $wpa{sent}{$wbpaper}{$author_id}{timestamp} = $pap_values{$wbpaper}{author}{$real_pap_author}{sent}{timestamp} ; }
#         if ($pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value}) { 
# if ($author_id eq '61360') { print "61360 VER $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value} JOIN $wbpaper \n"; }
# if ($author_id eq '43642') { print "43642 VER $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value} JOIN $wbpaper \n"; }
# if ($author_id eq '16678') { print "16678 VER $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value} JOIN $wbpaper \n"; }
# if ($author_id eq '15954') { print "15954 VER $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value} JOIN $wbpaper \n"; }
#           $wpa{verified}{$wbpaper}{$author_id}{value} = $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{value} ; }
#         if ($pap_values{$wbpaper}{author}{$real_pap_author}{verified}{timestamp}) { 
#           $wpa{verified}{$wbpaper}{$author_id}{timestamp} = $pap_values{$wbpaper}{author}{$real_pap_author}{verified}{timestamp} ; }
      } # else # if ($good <= 0)
    } # foreach my $pap_author (sort keys %{ $pap_values{$wbpaper}{author} } )
  } # if ($authors{paper}{$wbpaper})
  else { 					# no paper match either, paper missing
    my $original_papers = join", ", sort keys %{ $pap_values{$wbpaper}{papers} };
    print ERR "NO Paper Match value FOR wbpaper $wbpaper ORIGINALS $original_papers\n"; }
} # foreach my $wbpaper (sort keys %pap_values)

print "ERROR SERIES 1 over\n";

sub guessConnection {
  my ($pap_author, $wbpaper, $pos_value) = @_;

# if ($wbpaper eq '00023328') { print "$wbpaper GUESSING $pap_author PAP_AUTHOR\n"; }

  my $message = '';		# the message for warning or error 
  $message .= "NO Author Match, has paper match, this data $pos_value is lost : Author -=${pap_author}=- in paper -=${wbpaper}=-\n";
if ($pap_author =~ m/BRUNET/) { print "guessConnection BRUNET : $pap_author POS $pos_value JOIN $wbpaper \n"; }
  foreach my $wpa_author_name (sort keys %{ $authors{paper}{$wbpaper} }) {
    $message .= "WPA Author : $wpa_author_name\n"; } 	# add the wpa authors for that wbpaper
  my (@words) = split/\W/, $pap_author;			# break pap author into words
  my $main_word = ''; my $length = 0; my $matches = 0; my %matches; my $auth_id = '';
  foreach my $word (@words) { 
    my (@count) = split//, $word;			# break into characters
    my $count = scalar( @count );			# count them
    if ($count > $length) { $length = $count; $main_word = $word; } }	# get largest word
  foreach my $wpa_author_name (sort keys %{ $authors{paper}{$wbpaper} }) {
    if ($wpa_author_name =~ m/$main_word/) { 		# if a wpa author name matches the largest word
      $matches{$wpa_author_name}++; $matches++; } }	# store in hash
  foreach my $wpa_author_name ( sort keys %matches ) {
    $auth_id = $authors{paper}{$wbpaper}{$wpa_author_name};	# grab the author id for that wpa match
# if ($auth_id eq '43642') { print "FOREACH GUESSING 43642 POS $pos_value JOIN $wbpaper \n"; }
# if ($wbpaper eq '00023328') { print "$wbpaper FOREACH GUESSING $auth_id AUTH_ID $pos_value POS_VALUE\n"; }
    $message .= "$main_word GUESS $auth_id IS $wpa_author_name\n"; }
#   if ($matches > 1) { $message .= "TOO MANY MATCHES $matches\n"; print ERR "$message\n"; return 0; }
  if ($matches > 1) { $message .= "TOO MANY MATCHES $matches\n"; return (0, $message); }
#   elsif ($matches < 1) { $message .= "FAILED TO FIND MATCHES\n"; print ERR "$message\n"; return 0; }
  elsif ($matches < 1) { $message .= "FAILED TO FIND MATCHES\n"; return (0, $message); }
  else { 
    print WAR "$message\n"; 
    if ($auth_id) {
# if ($auth_id eq '43642') { print "GUESSING 43642 POS $pos_value JOIN $wbpaper \n"; }
# if ($wbpaper eq '00023328') { print "$wbpaper GUESSING $auth_id AUTH_ID\n"; }
      return $auth_id; } }
} # sub guessConnection






  # get valid authors.  for first population all authors are valid, so just get all
$result = $conn->exec( "SELECT * FROM wpa_author;" );
while (my @row = $result->fetchrow) { 
    # don't care that the joinkey is an In_book (.2) since wpa_ tables will only match to author_id, not the paper itself.  
    # this makes the hashing easier to match a $wbpaper to this joinkey later on.  do care about .1 becuase Erratum 4301 is really 4137.1
  if ($row[0] =~ m/\.2.*$/) { $row[0] =~ s/\.2.*$//; }	
  $wpa{vauthor}{$row[0]}{$row[1]}++; }	# paper joinkey , author_id

foreach my $joinkey (sort keys %{ $wpa{vauthor} }) {			# for each paper's joinkey check values and insert them
  my $author_count = 0;
if ($joinkey eq '00000905') { print "BOOM3 $joinkey JOINKEY\n"; }
if ($joinkey =~ m/00002064/) { print STDERR "BOOM3 $joinkey JOINKEY\n"; }
if ($joinkey =~ m/00004137/) { print STDERR "BOOM3 $joinkey JOINKEY\n"; }
  foreach my $author_id (sort keys %{ $wpa{vauthor}{$joinkey} }) {	# for each author id
#       $author_count++;    # wpa_join for joinining possible, sent, verified.  
if ($joinkey eq '00000905') { print "BOOM4 $author_id AUTHOR_ID $joinkey JOINKEY\n"; }
if ($joinkey =~ m/00002064/) { print "BOOM4 $author_id AUTHOR_ID $joinkey JOINKEY\n"; }
if ($joinkey =~ m/00004137/) { print "BOOM4 $author_id AUTHOR_ID $joinkey JOINKEY\n"; }
if ($joinkey eq '00000905') { 
foreach my $temp_pos_value ( @{ $wpa{possible}{$joinkey}{$author_id}{value} } ) { print "AGAINPOS $temp_pos_value WBP $joinkey\n"; } }

      if ( $wpa{possible}{$joinkey}{$author_id}{value} ) {		# if values were stored for postgres
if ($joinkey eq '00000905') { print "BOOM5 THERE IS wpa{possible} VALUE $author_id AUTHOR_ID $joinkey JOINKEY\n"; }
if ($joinkey =~ m/00002064/) { print "BOOM5 THERE IS wpa{possible} VALUE $author_id AUTHOR_ID $joinkey JOINKEY\n"; }
if ($joinkey =~ m/00004137/) { print "BOOM5 THERE IS wpa{possible} VALUE $author_id AUTHOR_ID $joinkey JOINKEY\n"; }
        while ( scalar( @{ $wpa{possible}{$joinkey}{$author_id}{value} } ) > 0 ) {	# loop through values
          my $pos_value = shift( @{ $wpa{possible}{$joinkey}{$author_id}{value} } );	# get values
          my $sent_value = shift( @{ $wpa{sent}{$joinkey}{$author_id}{value} } );
          my $ver_value = shift( @{ $wpa{verified}{$joinkey}{$author_id}{value} } );
          my $pos_timestamp = shift( @{ $wpa{possible}{$joinkey}{$author_id}{timestamp} } );
          my $sent_timestamp = shift( @{ $wpa{sent}{$joinkey}{$author_id}{timestamp} } );
          my $ver_timestamp = shift( @{ $wpa{verified}{$joinkey}{$author_id}{timestamp} } );
if ($joinkey eq '00000905') { print "BOOM6 $pos_value . $sent_value .  $ver_value . $pos_timestamp . $sent_timestamp . $ver_timestamp\n"; }
if ($joinkey =~ m/00002064/) { print "BOOM6 $pos_value . $sent_value .  $ver_value . $pos_timestamp . $sent_timestamp . $ver_timestamp\n"; }
if ($joinkey =~ m/00004137/) { print "BOOM6 $pos_value . $sent_value .  $ver_value . $pos_timestamp . $sent_timestamp . $ver_timestamp\n"; }
          unless ($pos_value) { $pos_value = 'NULL'; } 			# set to null if empty
          unless ($sent_value) { $sent_value = 'NULL'; } 
          unless ($ver_value) { $ver_value = 'NULL'; } 
          unless ($pos_timestamp) { $pos_timestamp = 'CURRENT_TIMESTAMP'; } 
          unless ($sent_timestamp) { $sent_timestamp = 'CURRENT_TIMESTAMP'; } 
          unless ($ver_timestamp) { $ver_timestamp = 'CURRENT_TIMESTAMP'; } 
          $author_count++;							# wpa_join for joinining possible, sent, verified
                            # have to do it here to match each of multiples with same author name e.g. 
                            # testdb=# SELECT * FROM wpa_author_verified WHERE author_id = '9897';
                            # 9897      | NO  Wen Joanna Chen |        1 | valid     | two1        | 2004-08-09 18:43:29.093247
                            # 9897      | YES  Wei Chen       |        1 | valid     | two1        | 2005-02-18 12:05:10.155197
          my $result2 = $conn->exec( "INSERT INTO wpa_author_possible VALUES ('$author_id', $pos_value, '$author_count', 'valid', 'two1', $pos_timestamp); ");
          print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_author_possible VALUES ('$author_id', $pos_value, '$author_count', 'valid', 'two1', $pos_timestamp); \"); \n";
          $result2 = $conn->exec( "INSERT INTO wpa_author_sent VALUES ('$author_id', $sent_value, '$author_count', 'valid', 'two1', $sent_timestamp); ");
          print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_author_sent VALUES ('$author_id', $sent_value, '$author_count', 'valid', 'two1', $sent_timestamp); \"); \n";
          $result2 = $conn->exec( "INSERT INTO wpa_author_verified VALUES ('$author_id', $ver_value, '$author_count', 'valid', 'two1', $ver_timestamp); ");
          print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_author_verified VALUES ('$author_id', $ver_value, '$author_count', 'valid', 'two1', $ver_timestamp); \"); \n";
        } # while (@{ $pap_values{$joinkey}{author}{$real_pap_author}{possible}{value} })
      } # if ( $wpa{possible}{$joinkey}{$author_id}{value} )

#       my $value = 'NULL';
#       my $timestamp = 'CURRENT_TIMESTAMP';
#       if ($wpa{possible}{$joinkey}{$author_id}{value}) { $value = $wpa{possible}{$joinkey}{$author_id}{value}; }
#       if ($wpa{possible}{$joinkey}{$author_id}{timestamp}) { $timestamp = "'$wpa{possible}{$joinkey}{$author_id}{timestamp}'"; }
# if ($author_id eq '43642') { print "43642 POS $value JOIN $joinkey \n"; }
# if ($author_id eq '16678') { print "16678 POS $value JOIN $joinkey \n"; }
# if ($author_id eq '15954') { print "15954 POS $value JOIN $joinkey \n"; }
# if ($author_id eq '38398') { print "38398 POS $value JOIN $joinkey \n"; }
#       my $result2 = $conn->exec( "INSERT INTO wpa_author_possible VALUES ('$author_id', $value, '$author_count', 'valid', 'two1', $timestamp); ");
#       print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_author_possible VALUES ('$author_id', $value, '$author_count', 'valid', 'two1', $timestamp); \"); \n";
# 
#       $value = 'NULL';
#       $timestamp = 'CURRENT_TIMESTAMP';
#       if ($wpa{sent}{$joinkey}{$author_id}{value}) { $value = $wpa{sent}{$joinkey}{$author_id}{value}; }
#       if ($wpa{sent}{$joinkey}{$author_id}{timestamp}) { $timestamp = "'$wpa{sent}{$joinkey}{$author_id}{timestamp}'"; }
#       $result2 = $conn->exec( "INSERT INTO wpa_author_sent VALUES ('$author_id', $value, '$author_count', 'valid', 'two1', $timestamp); ");
#       print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_author_sent VALUES ('$author_id', $value, '$author_count', 'valid', 'two1', $timestamp); \"); \n";
# 
#       $value = 'NULL';
#       $timestamp = 'CURRENT_TIMESTAMP';
#       if ($wpa{verified}{$joinkey}{$author_id}{value}) { $value = $wpa{verified}{$joinkey}{$author_id}{value}; }
#       if ($wpa{verified}{$joinkey}{$author_id}{timestamp}) { $timestamp = "'$wpa{verified}{$joinkey}{$author_id}{timestamp}'"; }
#       $result2 = $conn->exec( "INSERT INTO wpa_author_verified VALUES ('$author_id', $value, '$author_count', 'valid', 'two1', $timestamp); ");
#       print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_author_verified VALUES ('$author_id', $value, '$author_count', 'valid', 'two1', $timestamp); \"); \n";

  } # foreach my $author_id (sort keys %{ $wpa{vauthor}{$joinkey} })
} # foreach my $joinkey (sort keys %{ $wpa{vauthor} })


### end pap_ stuff, start hardcopy and electronic reference ###


$result = $conn->exec( "SELECT * FROM ref_hardcopy;" );
while (my @row = $result->fetchrow) { 
  if ($convertToWBPaper{$row[0]}) {
    my $wbpaper = $convertToWBPaper{$row[0]}; 
    $wbpaper =~ s/WBPaper//g;
    $wpa{hardcopy}{$wbpaper} = $row[2];
  }
  else { print ERR "NO ref_hardcopy CONVERSION $row[0] :\n"; }
} # while (my @row = $result->fetchrow)

foreach my $joinkey (sort keys %{ $wpa{valid} }) {
  my $value = 'NULL';
  my $timestamp = 'CURRENT_TIMESTAMP';
  if ($wpa{hardcopy}{$joinkey}) { $value = "'YES'"; $timestamp = "'$wpa{hardcopy}{$joinkey}'"; }
  my $result2 = $conn->exec( "INSERT INTO wpa_hardcopy VALUES ('$joinkey', $value, NULL, 'valid', 'two736', $timestamp); ");
  print OUT "my \$result2 = \$conn->exec( \"INSERT INTO wpa_hardcopy VALUES ('$joinkey', $value, $value, 'valid', 'two736', $timestamp); \"); \n";
} # foreach my $joinkey (sort keys %{ $wpa{valid} })



my @Reference; my @Reference2;
my @directory; my @file;

@Reference = </home/acedb/daniel/Reference/cgc/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
}
foreach my $file (@file) {
  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/pdf$/) { next; }		# skip non-pdfs
  my ($cgc) = $file_name =~ m/^(\d+).*/;
  $cgc = 'cgc' . $cgc;
  my $wbid = 0;
  if ($convertToWBPaper{$cgc}) {
    $wbid = $convertToWBPaper{$cgc};
    $wbid =~ s/WBPaper//g;
    my $type = '1';
    if ($file_name =~ m/lib\.pdf/) { $type = '2'; }
    elsif ($file_name =~ m/tif\.pdf/) { $type = '3'; }
    elsif ($file_name =~ m/html\.pdf/) { $type = '4'; }
    elsif ($file_name =~ m/ocr\.pdf/) { $type = '5'; }
    elsif ($file_name =~ m/temp\.pdf/) { $type = '7'; }
    else { $type = '1'; }
    if ($file =~ m/\'/) { $file =~ s/\'/''/g; }
    my $result = $conn->exec( "INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); ");
    print OUT "my \$result = \$conn->exec( \"INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); \"); \n";
#     if ($file_name =~ m/lib\.pdf/) { print OUT "LIB $wbid $file\n"; }
#     elsif ($file_name =~ m/tif\.pdf/) { print OUT "TIF $wbid $file\n"; }
#     elsif ($file_name =~ m/html\.pdf/) { print OUT "HTML $wbid $file\n"; }
#     elsif ($file_name =~ m/ocr\.pdf/) { print OUT "OCR $wbid $file\n"; }
#     elsif ($file_name =~ m/temp\.pdf/) { print OUT "TEMP $wbid $file\n"; }
#     else { print OUT "WEB $wbid $file\n"; }
  }
  else { print ERR "NO NUM $cgc FILE $file\n"; }
}

@directory = ();
@file = ();
@Reference = </home/acedb/daniel/Reference/pubmed/*>;
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; } } }

foreach my $file (@file) {

  my ($file_name) = $file =~ m/.*\/(.*?)$/;
  if ($file_name !~ m/pdf$/) { next; }		# skip non-pdfs
  my ($pmid) = $file_name =~ m/(\d+).*/;
  $pmid = 'pmid' . $pmid;
  my $wbid = 0;
  if ($convertToWBPaper{$pmid}) {
    $wbid = $convertToWBPaper{$pmid};
    $wbid =~ s/WBPaper//g;
    my $type = '1';
    if ($file_name =~ m/lib\.pdf/) { $type = '2'; }
    elsif ($file_name =~ m/tif\.pdf/) { $type = '3'; }
    elsif ($file_name =~ m/html\.pdf/) { $type = '4'; }
    elsif ($file_name =~ m/ocr\.pdf/) { $type = '5'; }
    elsif ($file_name =~ m/aut\.pdf/) { $type = '6'; }
    elsif ($file_name =~ m/temp\.pdf/) { $type = '7'; }
    else { $type = '1'; }
    if ($file =~ m/\'/) { $file =~ s/\'/''/g; }
    my $result = $conn->exec( "INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); ");
    print OUT "my \$result = \$conn->exec( \"INSERT INTO wpa_electronic_path_type VALUES ('$wbid', '$file', '$type', 'valid', 'two736', CURRENT_TIMESTAMP); \"); \n";
#     if ($file_name =~ m/lib\.pdf/) { print OUT "LIB $wbid $file\n"; }
#     elsif ($file_name =~ m/tif\.pdf/) { print OUT "TIF $wbid $file\n"; }
#     elsif ($file_name =~ m/html\.pdf/) { print OUT "HTML $wbid $file\n"; }
#     elsif ($file_name =~ m/ocr\.pdf/) { print OUT "OCR $wbid $file\n"; }
#     elsif ($file_name =~ m/temp\.pdf/) { print OUT "TEMP $wbid $file\n"; }
#     else { print OUT "WEB $wbid $file\n"; }
  }
  else { print ERR "NO NUM $pmid FILE $file\n"; }
}



close (WAR) or die "Cannot close $warn_file : $!";
close (ERR) or die "Cannot close $errfile : $!";
close (OUT) or die "Cannot close $outfile : $!";




($date) = &getSimpleSecDate();
print "END $date\n";
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time seconds\n";



sub readConversions {
  my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      my $other = $1; my $wbid = $2;
      unless ($backwards{$wbid}) { $backwards{$wbid} = $other; }
      $convertToWBPaper{$other} = $wbid; } }
} # sub readConversions


sub initManual {	# initialize %author_mappings hash
  $author_mappings{'de Castro E'}{'De Castro E'}++;
  $author_mappings{'de Castro E'}{'Edouard de Castro'}++;
  $author_mappings{'Labouesse ML'}{'Labouesse M'}++;
  $author_mappings{'Kim H'}{'Kim HY'}++;
  $author_mappings{'Han M'}{'Min Han'}++;
  $author_mappings{'Ma C'}{'Charles Ma'}++;
  $author_mappings{'Georges-Labouesse E'}{'Elisabeth Georges-Labouesse'}++;
  $author_mappings{'Labouesse M'}{'Michel Labouesse'}++;
  $author_mappings{'Thierry-Mieg D'}{'Danielle Thierry-Mieg'}++;
  $author_mappings{'Thierry-Mieg J'}{'Jean Thierry-Mieg'}++;
  $author_mappings{'Shi Y'}{'Yang Shi'}++;
  $author_mappings{'Schnabel H'}{'Heinke Schnabel'}++;
  $author_mappings{'Schnabel R'}{'Ralf Schnabel'}++;
  $author_mappings{'Honda S'}{'Shuji Honda'}++;
  $author_mappings{'Li XJ'}{'Xiumin Li'}++;
  $author_mappings{'Caldwell GA'}{'Guy A Caldwell'}++;
  $author_mappings{'Caldwell KA'}{'Kim A Caldwell'}++;
  $author_mappings{'Lee JH'}{'Junho Lee'}++;
  $author_mappings{'Royal DC'}{'D Royal'}++;
  $author_mappings{'Anders KR'}{'Kirk Anders'}++;
  $author_mappings{'de Castro SH'}{'Sarah Hegi de Castro'}++;
  $author_mappings{'Li WQ'}{'Weiqing Li'}++;
  $author_mappings{'Li C'}{'C Li'}++;
  $author_mappings{'Kim JS'}{'James Kim'}++;
  $author_mappings{'Siddiqui SS'}{'Shahid S Siddiqui'}++;
  $author_mappings{'Chan A'}{'Annette Chan'}++;
  $author_mappings{'Chan RC'}{'Raymond C Chan'}++;
  $author_mappings{'Asano A'}{'A Asano'}++;
  $author_mappings{'Maruyama IN'}{'I Maruyama'}++;
  $author_mappings{'Rand JB'}{'Jim Rand'}++;
  $author_mappings{'Aamodt EJ'}{'E Aamodt'}++;
  $author_mappings{'Aamodt SJ'}{'S Aamodt'}++;
  $author_mappings{'Siddiqui SS'}{'SS Siddiqui'}++;
  
  $author_mappings{'Swanson MA'}{'MacMorris MA'}++;
  $author_mappings{'Scott Ogg'}{'Ogg SC'}++;
  $author_mappings{'Kazunori Kondo'}{'Kondo K'}++;
  $author_mappings{'Shawn Ahmed'}{'Ahmed S'}++;
  $author_mappings{'Hartwieg EA'}{'Hartweig EA'}++;
  $author_mappings{'Yi-Chun Wu'}{'Wu Y-C'}++;
  $author_mappings{'Marsha M Smith'}{'Smith M'}++;
  $author_mappings{'Jin Liu'}{'Liu J'}++;
  $author_mappings{'Sambath Chung'}{'Chung S'}++;
  $author_mappings{'Aspoeck G'}{'Aspock G'}++;
  $author_mappings{'Jing Liu'}{'Liu J'}++;
  $author_mappings{'Wen Joanna Chen'}{'Chen W'}++;
  $author_mappings{'Mueller F'}{'Muller F'}++;
  $author_mappings{'Garry Wong Wong'}{'Wong G'}++;
  $author_mappings{'Shmookler Reis RJ'}{'Reis RJS'}++;
  $author_mappings{'Petcherski AG'}{'Petchers'}++;
  $author_mappings{'Junho Lee'}{'Lee JH'}++;
  $author_mappings{'Juan Carlos Rodrguez-Aguilera'}{'Juan Carlos Rodr&iacute;guez-Aguilera'}++;
  $author_mappings{'Plcido Navas'}{'Placido Navas'}++;
  $author_mappings{'F Mller'}{'Fritz Mueller'}++;
  $author_mappings{'Ingo Bssing'}{'Ingo Buessing'}++;
  $author_mappings{'Fitz Mller'}{'Fritz Mueller'}++;
  $author_mappings{'C Lopold Kurz'}{'C Leopold Kurz'}++;
  $author_mappings{'Chris Li'}{'Li C'}++;
  $author_mappings{'Maurice David Butler'}{'Butler M'}++;
  $author_mappings{'William B. Wood'}{'Woods W'}++;
  $author_mappings{'John Wang'}{'Wang JL'}++;
  $author_mappings{'Kerstin Howe'}{'Howe KL'}++;
  $author_mappings{'Marleen H. Roos'}{'Roos MH'}++;
  $author_mappings{'Steven J.M. Jones'}{'Jones S'}++;
  $author_mappings{'Yukimasa Shibata'}{'Shibata'}++;
  $author_mappings{'David Karow'}{'Da vid Karow'}++;
  $author_mappings{'Wei-Meng Woo'}{'Wei-meng Woo'}++;
  $author_mappings{'Ho SSH'}{'Stephen S H Ho'}++;
  $author_mappings{'Brunet J-F'}{'Jean-Francois BRUNET'}++;
  $author_mappings{'Torregrossa P'}{'Pascal TORREGROSSA'}++;
  $author_mappings{'Gonczy P'}{'Pierre Goenczy'}++;
  $author_mappings{'van Frden D'}{'Daniela van Fuerden'}++;
  $author_mappings{'McMahon LM'}{'Laura Mc MAHON'}++;
  $author_mappings{'Kuroyanagi H'}{'Hidehito KUROYANAGI'}++;
  $author_mappings{'Yu RYL'}{'Raymond Y L Yu'}++;
  $author_mappings{'Gobel V'}{'Verena Goebel'}++;
  $author_mappings{'Ko FCF'}{'Frankie C F Ko'}++;
  $author_mappings{'Sassa T'}{'Toshihiro sassa'}++;
  $author_mappings{'Bradley Keith Yoder'}{'John H'}++;	# WBPaper18428, two711
  $author_mappings{'Jarriault S'}{'Sophie JARRIAULT'}++;
  $author_mappings{'Annette Chan'}{'Ann Chan'}++;
  $author_mappings{'Bussing I'}{'Ingo Buessing'}++;
  $author_mappings{'Kuroyanagi H'}{'Hidehito KUROYANAGI'}++;
  $author_mappings{'Scott G Kennedy'}{'Scott G kennedy'}++;
  $author_mappings{'Christopher D. Link'}{'Link CD'}++;
  $author_mappings{'Alkema M'}{'m alkema'}++;
  $author_mappings{'Burglin TR'}{'TR Buerglin'}++;
  $author_mappings{'Wilson Berry L'}{'LW Berry'}++;
  $author_mappings{'Matsubara Lapidus D'}{'DM Lapidus'}++;
  $author_mappings{'Chisholm AD'}{'AD Chishom'}++;
  $author_mappings{'Ganetzky B'}{'B Ganetsky'}++;
  $author_mappings{'Volgyi A'}{'A Voelgyi'}++;
  $author_mappings{'Chisholm AD'}{'AD Chishlom'}++;

  $author_mappings{'Kim H'}{'Hongkyun Kim'}++;
  $author_mappings{'Schnabel H'}{'H Schnabel'}++;
  $author_mappings{'Schnabel R'}{'R Schnabel'}++;
  $author_mappings{'Anders KR'}{'K Anders'}++;
  $author_mappings{'Han M'}{'M Han'}++;
  $author_mappings{'Honda S'}{'S Honda'}++;
  $author_mappings{'Shi Y'}{'Y Shi'}++;
  $author_mappings{'Gonczy P'}{'P Goenczy'}++;
  $author_mappings{'Yukimasa Shibata'}{'Shibata Y'}++;
  $author_mappings{'David Karow'}{'Dav id Karow'}++;
  $author_mappings{'Asano A'}{'Akira ASANO'}++;
  $author_mappings{'Shmookler Reis RJ'}{'Robert J S Reis'}++;
  $author_mappings{'Wen Joanna Chen'}{'W Chen'}++;
  $author_mappings{'Wen Joanna Chen'}{'Wei Chen'}++;
  $author_mappings{'Jing Liu'}{'J Liu'}++;
  $author_mappings{'Hartwieg EA'}{'E Hartweig'}++;
  $author_mappings{'Garcia-Ailoveros J'}{'Garcia-Anoveros J'}++;
  $author_mappings{'Jing Liu'}{'Ji Liu'}++;
  $author_mappings{'Jing Liu'}{'Jun Liu'}++;
  $author_mappings{'Yi-Chun Wu'}{'Wu Y'}++;
  $author_mappings{'Bradley Keith Yoder'}{'John H Yoder'}++;  # WBPaper18428, two711
} # sub initManual
