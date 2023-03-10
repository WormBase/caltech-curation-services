#!/usr/bin/perl -w

# Group Person data with Paper with help form Author
#
# Group together Person (two tables in pg) with Paper (pap tables in pg) via author, and with help
# of Author (ace and wbg tables in pg)
#
# Added ``Mail !'' button, which emails the Person to verify the Papers associated with him/her
# on the confirm_paper.cgi form.  2003 01 31
#
# Added displayPossibleMatches($two) which return a list of tab delimited papers that may be 
# matches, matching by lastname first, or lastname first middle.  Sets as blue in findPapList
# display unless they are red.  2003 02 18
#
# Table pap_author seems to no longer be used, but is still being updated here (but not in
# confirm_paper.cgi under ~azurebrd/cgi-bin/forms/), I suppose redundantly.  If not used at all
# it should later be deleted from here and from postgres (don't think it's used anywhere else)
# 2003 04 11
#
# Changed &papMail(); to just send email to most recent email (old_timestamp) 2003 06 05
#
# Need to account searching for ' for Ch'ng.  2004 01 13
#
# Change date to Feb 19, 2004 instead of ``to the beginning of 2002''.  Use standardname instead 
# of fullname for sending emails.  2004 04 17
#
# Added papers up to July 6th, changed email to say July 6 instead of June 2
# 2004 07 07
#
# Look at ref_xref and ref_xrefmed to filter pmids and medlines that have a cgc.
# Changed email to cc Daniel and to mention pdfs or word docs.  2004 07 15
#
# Changed for wpa_ live on 2005 09 15
#
# Filter commas from aname to find exact matches.
# Filter out invalid papers.  2005 10 18
#
# Changed &findPapList(); to filter out extra spaces in $aname for exact
# matches.  (See author_id 50870 and 50422).  2005 10 20 
#
# Updated email to reflect color sorting in confirm_paper.cgi form, and 
# with a note that this is not a repeat of an older email, but instead an
# email based on new sets of connection that need verification.  2005 11 08
#
# Changed &findPapList(); to check if another person has verified YES, then NO,
# and overwrite the previous verification of YES, since only the latest YES/NO
# is the valid one for a given author-person-join connection.  And viceversa.
# Changed the priority of color choosing so it first checks if it's been connected
# to this person and not verified, then checking if it's connected to someone else
# and verified NO.  Previously it was the other way.  2005 11 10
#
# Fixed some @paper_tables that didn't exist (e.g. wpa_in_book vs. wpa_inbook)
# 2005 11 23
#
# Changed &findPapList(); to see if an author is invalid in wpa_author_index ;
# if so, remove the paper from the filtering hash.  2005 12 01
#
# Changed &papMail(); to tell people to verify even if they're not first author.
# 2005 12 08
# 
# Changed &papMail(); to check if someone that has been emailed said ``NO
# EMAIL''.  If so set that invalid and set valid ``SENT''.  2006 01 13
#
# Got rid of val_paper in pages other than papPick since it wasn't being used
# anymore.  Added a Pick by two number in front page.  Changed papPick page to
# have options of fastly looking at two_paper (which is incomplete), or slowly
# looking at wpa_author_possible, wpa_author_verified, wpa_author to see what
# has and hasn't been verified.  2006 11 17
#
# Added two_institution to @two_tables.  2007 04 27
#
# Added purple color if verified by Raymond.  Filter out invalid AIDs like was
# filtering out invalid papers.  2007 07 16
#
# &papMail(); has more code to find the unverified papers, and send links to all
# of them for direct yes / no.  2008 07 15
#
# Look at Cecilia's file to look what the latest WS-corresponding paper dump has
# as valid papers, and send links to wormbase if those exist, otherwise check if
# it has a pmid a link to pubmed, otherwise link to wbpaper_display.cgi  
# 2008 07 22
#
# Changed email for Cecilia and Andrei.  2008 09 30
#
# Converted from Pg.pm to DBI.pm (DBD::Pg)  2009 04 17

 
use strict;
use CGI;
# use Fcntl;
# use Pg;
use DBI;
use Jex;

my $query = new CGI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "");
if ( !defined $dbh ) { die "Cannot connect to database!\n"; }

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
# my @paper_tables = qw(pap_paper pap_title pap_journal pap_page pap_volume pap_year pap_inbook pap_contained pap_pmid pap_affiliation pap_type pap_contains);
# my @paper_tables = qw(wpa_paper wpa_title wpa_identifier wpa_journal wpa_page wpa_volume wpa_year wpa_inbook wpa_contained wpa_pmid wpa_affiliation wpa_type wpa_contains);
my @paper_tables = qw(wpa_title wpa_identifier wpa_journal wpa_pages wpa_volume wpa_year wpa_in_book wpa_contained_in wpa_affiliation wpa_type wpa_contains);
my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_pis two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);
my @two_simpler = qw(two_comment two_groups);

my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $pink = '#ff00cc';			# redefine pink to a mom-friendly color
my $red = '#ff0000';			# redefine red to a mom-friendly color
my $green = '#00ff00';			# redefine green to a mom-friendly color
my $purple = '#880088';			# redefine green to a mom-friendly color
my $yellow = '#aaaa00';			# redefine yellow to a mom-friendly color

my %aid_paper;				# authorid{id}{name} -> name   authorid{id}{paper} -> wbpaper

my %ws_papers;				# papers in current WS

my $frontpage = 1;			# show the front page on first load

&printHeader('Pepito');
&display();
&printFooter();

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Page !') { &pickPage(); }		# display a range with 50 twos
  elsif ($action eq 'Pick !') { &papPick(); }		# display matching papers in groups of 10
  elsif ($action eq 'Select !') { &papSelect(); }	# check authors that match person (two)
  elsif ($action eq 'Mail !') { &papMail(); } 
  elsif ($action eq 'Edit !') { &papEdit(); }		# write changes to database
  else { 1; }
} # sub display

sub populateWSPapers {
  my $loc_file = '/home/cecilia/work/wb-release';
  open (IN, "$loc_file") or die "Cannot open $loc_file : $!";
  my $src_file = <IN>;
  close (IN) or die "Cannot close $loc_file : $!";
  open (IN, "$src_file") or die "Cannot open $src_file : $!";
  while (my $line = <IN>) { if ($line =~ m/Paper : \"WBPaper(\d+)\"/) { $ws_papers{ws}{$1}++; } }
  close (IN) or die "Cannot close $src_file : $!";
#   my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
  my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid' ORDER BY wpa_timestamp;" );
  if ( !defined $result ) { die "Cannot prepare statement: $DBI::errstr\n"; }
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $ws_papers{pmid}{$row[0]} = $row[1]; }
      else { delete $ws_papers{pmid}{$row[0]}; } }
}

sub papMail {
  my ($oop, $two) = &getHtmlVar($query, 'two');
  print "TWO : $two<BR>\n";

  my $value = 'SENT'; my $send_email = 0;
  my @emails;
#   my $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = 'two$two' ORDER BY old_timestamp DESC;" );
  my $result = $dbh->prepare( "SELECT * FROM two_email WHERE joinkey = 'two$two' ORDER BY old_timestamp DESC;" );
  if ( !defined $result ) { die "Cannot prepare statement: $DBI::errstr\n"; }
  $result->execute;
  my @row = $result->fetchrow;
  if ($row[2]) { push @emails, $row[2]; }
  if ($emails[0]) { $send_email++; }
    else { $value = 'NO EMAIL'; print "<P><FONT COLOR='red'><B>NO EMAIL</B></FONT><P>\n"; }

  my %join_hash;		# the aids and joins of the twos that match
#   $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible = 'two$two' ORDER BY wpa_timestamp; ");
  $result = $dbh->prepare( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible = 'two$two' ORDER BY wpa_timestamp; ");
  $result->execute;
  while (my @row = $result->fetchrow) { 
    if ($row[3] eq "valid") { $join_hash{$row[0]}{$row[2]}++; }			# aid, wpa_join
      else { delete $join_hash{$row[0]}{$row[2]}; } }				# delete invalid
  my %ver_hash;			# all aids and joins that are verified	(faster than checking each possible ?)
#   $result = $conn->exec( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp; ");
  $result = $dbh->prepare( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp; ");
  $result->execute;
  while (my @row = $result->fetchrow) { 
    if ($row[3] eq "valid") { if ($row[1]) { if ($row[1] =~ m/YES/) { $ver_hash{$row[0]}{$row[2]}++; } } }			# aid, wpa_join
      else { delete $ver_hash{$row[0]}{$row[2]}; } }				# delete invalid
  my $unverified_stuff = ''; my @unv_aids;					# unverified author ids
  
  &populateWSPapers();	
  my %inserted_hash;		# the aids and joins from those that already have sent data
  foreach my $aid (sort {$a<=>$b} keys %join_hash) {	# look at all matching ones to get the wpa_author_sent value if there is one
    foreach my $wpa_join (sort keys %{ $join_hash{$aid} }) {
#       my $result = $conn->exec( "SELECT * FROM wpa_author_sent WHERE author_id = '$aid' AND wpa_join = '$wpa_join' AND wpa_author_sent IS NOT NULL ORDER BY wpa_timestamp; ");
      my $result = $dbh->prepare( "SELECT * FROM wpa_author_sent WHERE author_id = '$aid' AND wpa_join = '$wpa_join' AND wpa_author_sent IS NOT NULL ORDER BY wpa_timestamp; ");
      $result->execute;
      while (my @row = $result->fetchrow) {
        if ($row[3] eq "valid") { $inserted_hash{$row[0]}{$row[2]} = $row[1]; }		# aid, wpa_join
          else { delete $inserted_hash{$row[0]}{$row[2]}; } }    			# delete invalid
      unless ($ver_hash{$aid}{$wpa_join}) { 						# process the aid
        my %author_hash;
#         $result = $conn->exec( " SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp; " );
        $result = $dbh->prepare( " SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp; " );
        $result->execute;
        while (my @row = $result->fetchrow) { 
          if ($row[3] eq "valid") { $author_hash{$row[1]} = $row[0]; }			# aid = joinkey
            else { delete $author_hash{$row[1]}; } }				 	# delete invalid
        my $joinkey = $author_hash{$aid};
        my $info = &getPaperInfo($joinkey);
        if ($info) { $unverified_stuff .= "$info\n";
          $unverified_stuff .= "Click <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?action=Connect&two_number=$two&aid=$aid&wpa_join=$wpa_join&yes_no=YES\">here</A> if the paper is yours, or click <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?action=Connect&two_number=$two&aid=$aid&wpa_join=$wpa_join&yes_no=NO\">here</A> if the paper is NOT yours.<BR><BR>\n"; }
  } } }

# print "UNV $unverified_stuff UNV<BR>\n";
  
  foreach my $aid (sort keys %join_hash) {		# look at all possible twos again
    foreach my $wpa_join (sort keys %{ $join_hash{$aid} }) {
      if ($inserted_hash{$aid}{$wpa_join}) { 	# if already inserted
        if ($inserted_hash{$aid}{$wpa_join} eq 'NO EMAIL') {	# if it set NO EMAIL set that invalid and mark as SENT  2006 01 13
          my $pg_command = "INSERT INTO wpa_author_sent VALUES ('$aid', 'NO EMAIL', '$wpa_join', 'invalid', 'two1', CURRENT_TIMESTAMP);";
#           my $result = $conn->exec( $pg_command );	# invalidate NO EMAIL
          my $result = $dbh->prepare( $pg_command );	# invalidate NO EMAIL
          $result->execute;
          $pg_command = "INSERT INTO wpa_author_sent VALUES ('$aid', 'SENT', '$wpa_join', 'valid', 'two1', CURRENT_TIMESTAMP);";
#           $result = $conn->exec( $pg_command );	# set to sent
          $result = $dbh->prepare( $pg_command );	
          $result->execute; }	# set to sent
      } else {						# if not already inserted, insert it
        my $pg_command = "INSERT INTO wpa_author_sent VALUES ('$aid', '$value', '$wpa_join', 'valid', 'two1', CURRENT_TIMESTAMP);";
#         my $result = $conn->exec( $pg_command );
        my $result = $dbh->prepare( $pg_command );
        $result->execute;
        print "$pg_command<BR>\n"; } } }

  if ($send_email) {
    my $email = join', ', @emails;
    $email .= ', cecilia@tazendra.caltech.edu, qwang@its.caltech.edu';
#     my $email = 'azurebrd@minerva.caltech.edu';
#     my $email = 'closertothewake@gmail.com';
    my $email_to_be_sent = join', ', @emails;
# my $email = 'cecnak@gmail.com';
# my $email_to_be_sent = 'cecnak@gmail.com';

    print "SEND EMAIL TO $email<P>\n";

#     $result = $conn->exec( "SELECT two_standardname FROM two_standardname WHERE joinkey = 'two$two';" );
    $result = $dbh->prepare( "SELECT two_standardname FROM two_standardname WHERE joinkey = 'two$two';" );
    $result->execute;
    my @row = $result->fetchrow;
    my $standardname = $row[0];

    my $user = 'cecilia@tazendra.caltech.edu';
    my $subject = 'WormBase Paper Verification';
    my $body = "Dear $standardname,<BR><BR>

$email_to_be_sent<BR><BR>


We at WormBase are trying to create a clean connection between People and the
Papers they have published.<BR><BR>

This isn't a straightforward task because many times people will publish under
different names for various reasons.  We have tried to connect all your 
C. elegans or other nematode research papers with you and would like your help 
to verify that the papers we have found are actually those published by you. 
Even though our paper collection is primarily focused on C. elegans (and 
other nematodes), it includes some non-nematode papers.<BR><BR>

$unverified_stuff<BR><BR>

If there are any C. elegans papers that you have published that are not on the 
list, please let us know. Also, if you have any corrections or updates about 
your contact information, please let me know.<BR><BR>

This is an ongoing process, so if you have received this email before, you are 
receiving it now because new papers have been attached to you.<BR><BR>

Thank you,<BR>
Cecilia Nakamura<BR>
Assistant Curator<BR>
California Institute of Technology<BR>
Division of Biology 156-29<BR>
Pasadena, CA 91125<BR>
USA<BR>
tel: 626.395.2688   fax: 626.395.8611<BR>
cecilia\@tazendra.caltech.edu\n";

    my $command = 'sendmail';
    my $mailer = Mail::Mailer->new($command) ;
    print "Mail to $email\n";
    $mailer->open({ From    => $user,
                    To      => $email,
                    Subject => $subject,
                  "Content-type" => 'text/html',
                  })
        or die "Can't open: $!\n";
    print $mailer $body;
    $mailer->close();


#     &mailer($user, $email, $subject, $body);	# email CGI to user
# old email :
# Please go to the following WWW form and check off the ones selected as Yours 
# or Not Yours (including those where you are not first author).  
# 
# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?two_num=$two&action=Pick+%21
  } # if ($send_email)
} # sub papMail

# FIX DATA : SELECT * FROM wpa_author_sent WHERE wpa_timestamp > '2005-08-29';
# FIX DATA : SELECT * FROM wpa_author_possible WHERE wpa_timestamp > '2005-08-29';

sub getPaperInfo {
  my %type_index;                         # for paper table data
#   my $result = $conn->exec( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp; ");
  my $result = $dbh->prepare( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp; ");
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $type_index{$row[0]} = $row[1]; }         # type_id, wpa_type_index
      else { delete $type_index{$row[0]}; } }                           # delete invalid

  my $joinkey = shift;
#   $result = $conn->exec( "SELECT * FROM wpa WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  $result = $dbh->prepare( "SELECT * FROM wpa WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  $result->execute;
  my %valid_hash = ();                                             # filter things through a hash to get rid of invalid data.
  while (my @row = $result->fetchrow) { if ($row[0]) { if ($row[3] eq 'valid') { $valid_hash{$row[0]}++; } else { delete $valid_hash{$row[0]}; } } }
  my @valid = keys %valid_hash; unless ($valid[0]) { print "Not a valid paper $joinkey<BR>\n"; return; }

#   $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  $result = $dbh->prepare( "SELECT * FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  $result->execute;
  %valid_hash = ();                                             # filter things through a hash to get rid of invalid data.
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      my $link = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/wbpaper_display.cgi?number=$joinkey&action=Number+%21";
      if ($ws_papers{ws}{$joinkey}) { $link = "http://wormbase.org/db/misc/paper?name=WBPaper$joinkey;class=Paper"; }
      elsif ($ws_papers{pmid}{$joinkey}) { my $pmid = $ws_papers{pmid}{$joinkey}; $pmid =~ s/pmid//g; $link = "http://www.ncbi.nlm.nih.gov/pubmed/$pmid?ordinalpos=1&itool=EntrezSystem2.P"; }
      $row[1] = "<A HREF=\"$link\" TARGET=new>$row[1]</A><BR>\n";
#       $row[1] = "<A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/wbpaper_display.cgi?number=$joinkey&action=Number+%21\" TARGET=new>$row[1]</A><BR>\n";
      if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; } else { delete $valid_hash{$row[1]}; } } }
  my $data = join ", ", sort keys %valid_hash;
  my $paper_info .= "$data\n";
  my @line;
  foreach my $paper_table (@paper_tables) { # go through each table for the key
    my %valid_hash;                                             # filter things through a hash to get rid of invalid data.
#     my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
    my $result = $dbh->prepare( "SELECT * FROM $paper_table WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        if ($paper_table eq 'wpa_type') { $row[1] = $type_index{$row[1]}; }
        if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; } else { delete $valid_hash{$row[1]}; } } }
    foreach my $data (sort keys %valid_hash) { push @line, $data; }
  } # foreach my $paper_table (@paper_tables)
  $data = join "; ", @line;
  $paper_info .= "$data<BR>\n";
  unless ($paper_info) { $paper_info = 'No paper info'; }
  if ($paper_info) { return $paper_info; }
} # sub getPaperInfo



sub papEdit {
  my $oop;
  if ($query->param('two_number')) { $oop = $query->param('two_number'); } 
    else { $oop = 'nodatahere'; }
  my $two_number = untaint($oop);
  print "TWO : $two_number<BR>\n";
  if ($query->param('count')) { $oop = $query->param('count'); } 
    else { $oop = 'nodatahere'; }
  my $count = untaint($oop);
  print "COUNT : $count<BR>\n";
  my %hidden_hash;				# hash

  for (my $i = 1; $i <= $count; $i++) {
    if ($query->param("aid$i")) { $oop = $query->param("aid$i"); } 
      else { $oop = 'nodatahere'; }
    my $aid = untaint($oop);
    if ($query->param("join$i")) { $oop = $query->param("join$i"); } 
      else { $oop = 'nodatahere'; }
    my $wpa_join = untaint($oop);
    if ($query->param("paper$i")) { $oop = $query->param("paper$i"); } 
      else { $oop = 'nodatahere'; }
    my $paper_key = untaint($oop);
    if ($query->param("check$i")) { $oop = $query->param("check$i"); } 
      else { $oop = 'nodatahere'; }
    my $check = untaint($oop);
    if ($check eq 'YES') { $check = 1; } 	# if it's checked, set to 1
      else { $check = 0; }			# if it's not checked, set to 0
print "AId $aid : TWO $two_number : JOIN $wpa_join : PAPER $paper_key :<BR>\n";

    my %theHash;				# hash structure to sort data and get rid of invalid data
    my $data = 0;				# default no data in postgres
#     my $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' AND wpa_author_possible = 'two$two_number' ORDER BY wpa_timestamp;" );
    my $result = $dbh->prepare( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' AND wpa_author_possible = 'two$two_number' ORDER BY wpa_timestamp;" );
    $result->execute;
    while (my @row = $result->fetchrow) { 	# get valid possible person connections
      if ($row[3] eq 'valid') { $theHash{$aid}{$row[2]}{possible} = $row[1]; }
        else { delete $theHash{$aid}{$row[2]}{possible}; } }
    if ($theHash{$aid}{$wpa_join}{possible}) { $data = $theHash{$aid}{$wpa_join}{possible}; }

    if ($check) { print "CHECK $check CHECK<BR>\n"; }
    if ($data) { print "DATA $data DATA<BR>\n"; }

    if ($check) {	# should be yes
      if ($data) { 	# stay the same
          print "CHECKED and DATA stay the same<BR>\n"; }
        else { 		# add valid
          if ($wpa_join eq 'nodatahere') { $wpa_join = &getWpaJoin($paper_key); }				# get the highest existing wpa_join + 1 (new)
          my $pgcommand = "INSERT INTO wpa_author_possible VALUES ('$aid', 'two$two_number', '$wpa_join', 'valid', 'two1', CURRENT_TIMESTAMP);";
#           my $result = $conn->exec( "$pgcommand" );	# add to wpa_author_possible that this is a possible two_number
          my $result = $dbh->prepare( "$pgcommand" );	# add to wpa_author_possible that this is a possible two_number
          $result->execute;
          print "<FONT COLOR='blue'>$pgcommand</FONT><BR>\n";
#           $result = $conn->exec ( "INSERT INTO two_paper VALUES \(\'two$two_number\', \'$paper_key\'\)" );	# add to list of cecilia-connected person-paper
          $result = $dbh->prepare ( "INSERT INTO two_paper VALUES \(\'two$two_number\', \'$paper_key\'\)" );	# add to list of cecilia-connected person-paper
          $result->execute;
          print "<FONT COLOR='blue'>INSERT INTO two_paper VALUES \(\'two$two_number\', \'$paper_key\'\)</FONT><BR>\n";
          print "CHECKED no DATA add data<BR>\n"; }
    } else {		# should be no
      if ($data) { 	# add invalid
          if ($wpa_join eq 'nodatahere') { $wpa_join = &getWpaJoin($paper_key); }
          my $pgcommand = "INSERT INTO wpa_author_possible VALUES ('$aid', 'two$two_number', '$wpa_join', 'invalid', 'two1', CURRENT_TIMESTAMP);";
#           my $result = $conn->exec( "$pgcommand" );
          my $result = $dbh->prepare( "$pgcommand" );
          $result->execute;
          print "<FONT COLOR='blue'>$pgcommand</FONT><BR>\n";
#           $result = $conn->exec ( "INSERT INTO two_paper VALUES \(\'two$two_number\', \'$paper_key\'\)" );
          $result = $dbh->prepare ( "INSERT INTO two_paper VALUES \(\'two$two_number\', \'$paper_key\'\)" );
          $result->execute;
          print "<FONT COLOR='blue'>INSERT INTO two_paper VALUES \(\'two$two_number\', \'$paper_key\'\)</FONT><BR>\n";
          print "NO CHECK has DATA add invalid<BR>\n"; }
        else { 		# stay the same
          print "NO CHECK has no DATA stay the same<BR>\n"; }
    }
    print "<BR>\n";
    
# #     my $result = $conn->exec( "SELECT pap_person FROM pap_author WHERE pap_author ~ '$pap_author' AND joinkey = '$joinkey' ;" );
# #     print "<FONT COLOR='green'>SELECT pap_person FROM pap_author WHERE pap_author ~ '$pap_author' AND joinkey = '$joinkey';</FONT><BR>\n";
#       # limit results to those that refer to this two_number, otherwise we'll get matches for
#       # proper hits that refer to other people.
#     my $result = $conn->exec( "SELECT pap_possible FROM pap_view WHERE pap_author ~ '$pap_author' AND joinkey = '$joinkey' AND pap_possible = 'two$two_number' ;" );
#     print "<FONT COLOR='green'>SELECT pap_possible FROM pap_view WHERE pap_author ~ '$pap_author' AND joinkey = '$joinkey' AND pap_possible = 'two$two_number' ;</FONT><BR>\n";
#     my @row = $result->fetchrow;
#     if ($row[0]) { $data = 1; } 		# if there's data in postgres, set to 1
#       else { $data = 0; }			# if there's no data in postgres, set to 0 (redundant)

# FOR VERIFIED DATA, probably not needed (THINK ABOUT THIS)
#     $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
#     while (my @row = $result->fetchrow) { 	# get valid verified person connections
#       if ($row[3] eq 'valid') { $theHash{$aid}{$row[2]}{verified} = $row[1]; }
#         else { delete $theHash{$aid}{$row[2]}{verified}; } }
#     foreach my $wpa_join (sort keys %{ $theHash{$aid} }) {	# get rid of possibles verified as NO
#       if ($theHash{$aid}{$wpa_join}{verified}) { 
#         if ($theHash{$aid}{$wpa_join}{verified} =~ m/NO  /) { delete $theHash{$aid}{$wpa_join}{possible}; } } }
#     foreach my $wpa_join (sort keys %{ $theHash{$aid} }) {	# check if there are any possible persons (not verfied as NO) for that author_id
#       if ($theHash{$aid}{$wpa_join}{possible}) { $data++; } }

    
#     if ($data != $check) { 			# if they are different, update
#       print "<FONT COLOR='blue'>UPDATE pap_author SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#       my $result = $conn->exec( "UPDATE pap_author SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
#       print "<FONT COLOR='blue'>UPDATE pap_possible SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#       $result = $conn->exec( "UPDATE pap_possible SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
# 
#       if ($check) {				# if checked
#         print "<FONT COLOR='blue'>UPDATE pap_author SET pap_person = \'two$two_number\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#         my $result = $conn->exec( "UPDATE pap_author SET pap_person = \'two$two_number\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
#         print "<FONT COLOR='blue'>UPDATE pap_possible SET pap_possible = \'two$two_number\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#         $result = $conn->exec( "UPDATE pap_possible SET pap_possible = \'two$two_number\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
# 
#         print "<FONT COLOR='blue'>INSERT INTO two_paper VALUES \(\'two$two_number\', \'$joinkey\'\)</FONT><BR>\n";
#         $result = $conn->exec ( "INSERT INTO two_paper VALUES \(\'two$two_number\', \'$joinkey\'\)" );
#       } else {					# if unchecked
#         print "<FONT COLOR='red'>UPDATE pap_author SET pap_person = NULL WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#         my $result = $conn->exec( "UPDATE pap_author SET pap_person = NULL WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
#         print "<FONT COLOR='red'>UPDATE pap_possible SET pap_possible = NULL WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
#         $result = $conn->exec( "UPDATE pap_possible SET pap_possible = NULL WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
# 
#         print "<FONT COLOR='red'>DELETE FROM two_paper WHERE joinkey = \'two$two_number\' AND two_paper = \'$joinkey\';</FONT><BR>\n";
#         $result = $conn->exec ( "DELETE FROM two_paper WHERE joinkey = \'two$two_number\' AND two_paper = \'$joinkey\'" );
#       }
# 
#     } # if ($data != $check)			# if they are different, update

  } # for (my $i = 1; $i <= $count; $i++)
} # sub papEdit

sub getWpaJoin {	# if an entry doesn't already have a wpa_join, look at that paper and find the highest existing wpa_join and return that value + 1 to use as the new wpa_join
  my $paper_key = shift; my $wpa_join = 0;	# default to zero in case there aren't any wpa_join values for that paper
#   my $result = $conn->exec( "
  my $result = $dbh->prepare( "
  SELECT wpa_author_possible.wpa_join
    FROM wpa_author_possible, wpa_author
   WHERE wpa_author.wpa_author = wpa_author_possible.author_id
     AND wpa_author_possible.author_id IN (
         SELECT wpa_author FROM wpa_author WHERE joinkey = '$paper_key'
         )
   ORDER BY wpa_author_possible.wpa_join DESC;
  " );		# highest wpa_join
  $result->execute;
  my @row = $result->fetchrow;
  if ($row[0]) { $wpa_join = $row[0]; }
  $wpa_join++;		# add one to use a new value
  return $wpa_join;
} # sub getWpaJoin


## papSelect block ##

sub papSelect {
  my $start = time;
#   &populateAIdHash();		# this adds 3-4 seconds
#   my $end2 = time;
#   my $diff2 = $end2 - $start;
#   print "AIdHash Time $diff2 seconds<BR>\n";
  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
#   if ($query->param('val_paper')) { $oop = $query->param('val_paper'); } 
#     else { $oop = 'nodatahere'; }
#   my $val_paper = untaint($oop); 
  if ($query->param('paper_range')) { $oop = $query->param('paper_range'); } 
    else { $oop = 'nodatahere'; }
  my $paper_range = untaint($oop); 
#   print "two : $two<BR>paper_range : $paper_range<BR>val_paper : $val_paper<BR><BR>\n";

  &displayOneDataFromKey($two);
  &displayEditor($two, $paper_range);
  my $end = time;
  my $diff = $end - $start;
  print "Load Time $diff seconds<BR>\n";
} # sub papSelect

sub displayEditor {
  my ($two_key, $paper_range) = @_;
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  my @papers = split /\t/, $paper_range;
  my %filter; foreach my $pap (@papers) { $filter{$pap}++; } @papers = sort keys %filter; 
  my $count = 0;	 		# count of authors in page
  my $mark_count = 0;			# count of checked authors in page
  foreach my $paper_key (@papers) { ($count, $mark_count) = &displayPaperDataFromKey($paper_key, $count, $two_key, $mark_count); }
    # display tables with paper data and checkboxes (for each author) for each of the papers
  print "TOTAL authors : $count<BR>\n";
  print "TOTAL CHECKED authors : $mark_count<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"count\" VALUE=\"$count\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  print "</FORM>\n";
} # sub displayEditor

## papSelect block ##

## papPick block ##

sub papPick {
  my $start = time;
#   &populateAIdHash();		# this adds 3-4 seconds
  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
#   if ($query->param('val_paper')) { $oop = $query->param('val_paper'); } 
#     else { $oop = 'nodatahere'; }
#   my $val_paper = untaint($oop); 
#   print "two : $two : val_paper connected_by_cecilia : $val_paper<BR><BR>\n";

  &displayOneDataFromKey($two);
#   my $pos_papers = &displayPossibleMatches($two);

#   &displaySelector($two, $val_paper, $pos_papers);
#   &displaySelector($two, $val_paper);
  &displaySelector($two);
  my $end = time;
  my $diff = $end - $start;
  print "DIFF $diff DIFF<BR>\n";
} # sub papPick

sub getLastNames {
  my $two_key = shift;
  my @lastnames;			# all lastnames from two tables
  my %lastnames;			# hash to filter multiple lastnames
  my @two_tables_last = qw( two_lastname two_aka_lastname two_apu_lastname );
  foreach my $two_table_last (@two_tables_last) { 
#     my $result = $conn->exec( "SELECT $two_table_last FROM $two_table_last WHERE joinkey = 'two$two_key';" );
    my $result = $dbh->prepare( "SELECT $two_table_last FROM $two_table_last WHERE joinkey = 'two$two_key';" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      push @lastnames, $row[0]; } }
  foreach $_ (@lastnames) { $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $lastnames{$_}++; }
  my $lastnames = join"\t", keys %lastnames;
  return $lastnames;
} # sub getLastNames

sub displaySelector {
#   my ($two_key, $val_paper, $pos_papers) = @_;
#   my ($two_key, $val_paper) = @_;
  my ($two_key) = @_;
  my $lastnames = &getLastNames($two_key);
  my @lastnames = split/\t/, $lastnames;
  foreach my $lastname (@lastnames) { 
    print "two$two_key finds : $lastname<BR><BR>\n"; 
#     &findPapList($lastname, $two_key, $val_paper, $pos_papers);
#     &findPapList($lastname, $two_key, $val_paper);
    &findPapList($lastname, $two_key);
  }
  &displayEmailButton($two_key);
} # sub displaySelector

sub displayEmailButton {
  my $two_key = shift;
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>Click here to E-Mail to Verify</TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Mail !\"></TD></TR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub displayEmailButton

# NOT USING THIS, two625 would take 41secs, although two1 would take 2secs ;  vs always 6 secs
sub getPaperFromAId {
  my $aid = shift;
#   my $result = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
  my $result = $dbh->prepare( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
  $result->execute;
  my @row = $result->fetchrow;
  if ($row[3] eq 'valid') { return $row[0]; }
    else { return 0; }
} # sub getPaperFromAId

sub findPapList {
# somewhat simliar to SELECT * FROM pap_view :
#  SELECT wpa_author_possible.author_id, wpa_author_possible.wpa_author_possible, wpa_author_sent.wpa_author_sent, wpa_author_verified.wpa_author_verified
#    FROM wpa_author_possible, wpa_author_sent, wpa_author_verified
#   WHERE wpa_author_possible.author_id = wpa_author_sent.author_id 
#     AND wpa_author_possible.author_id = wpa_author_verified.author_id 
#     AND wpa_author_possible.wpa_join = wpa_author_sent.wpa_join 
#     AND wpa_author_possible.wpa_join = wpa_author_verified.wpa_join;
    # this is accurate, but requires indexing aid_paper, which takes 3 seconds
#   my @author_ids;
#   my %partial_author_papers;		# hash to filter papers
#   my $result = $conn->exec( "SELECT * FROM wpa_author_index WHERE wpa_author_index ~ '$lastname_search' ORDER BY author_id;" );
#   while (my @row = $result->fetchrow) { push @author_ids, $row[0]; } 
#   foreach my $partial_author (@author_ids) { $partial_author_papers{$aid_paper{$partial_author}{paper}}++; }
# #   foreach my $partial_author (@author_ids) { my $paper = &getPaperFromAId($partial_author); $partial_author_papers{$paper}++; }
#   foreach $_ (sort keys %partial_author_papers) { push @papers, $_; }	# put back in array
#   print "There are " . scalar(@papers) . " matching authors for $lastname :<BR>\n";
#   my $exact_author = &findExactAuthor($two_key);			# this adds 2-3 seconds
    # this is fast for people with few papers, but very slow for people with lots of papers, e.g. 625 takes 41 seconds
#   foreach my $exact_author (@exact_author) { $exact_author_papers{$aid_paper{$exact_author}{paper}}++; }
#   foreach my $exact_author (@exact_author) { my $paper = &getPaperFromAId($exact_author); $exact_author_papers{$paper}++; }
  
    # this seems to work, but fails for Chan (1823)  query too long ?
    # get author_ids and sort in %verified_paper{$aid} depending on which two it's connected to and whether or not it's verified, verified yes, or verified no
    # this could also get bad data if something is invalid
#    my $result = $conn->exec( "
#    SELECT wpa_author_possible.author_id, wpa_author_possible.wpa_author_possible, wpa_author_verified.wpa_author_verified
#      FROM wpa_author_possible, wpa_author_verified
#     WHERE wpa_author_verified.author_id = wpa_author_possible.author_id
#       AND wpa_author_verified.wpa_join = wpa_author_possible.wpa_join
#       AND wpa_author_possible.wpa_author_possible IS NOT NULL
#       AND wpa_author_possible.author_id IN (
#           SELECT author_id FROM wpa_author_index WHERE wpa_author_index ~ 'Chan'
#           );
#    " );		# paper joinkey, author id, possible two#, author verified
#    while (my @row = $result->fetchrow) {
#      if ($row[1]) {				# if verified
#        if ($row[1] eq "two$two_key") {		# verified two
#          if ($row[2] =~ m/^YES/) { 		# verified two yes	# green
#            $verified_paper{$row[0]}{ver_yes}++; }
#          else {					# verified two no	# red
#            $verified_paper{$row[0]}{ver_no}++; } }
#        else {					# verified other
#          if ($row[2] =~ m/^YES/) { 		# verified other yes	# stop
#            $verified_paper{$row[0]}{oth_yes}++; }
#          else {					# verified other no	# continue
#            $verified_paper{$row[0]}{oth_no}++; } } }
#      else {					# not verified
#        if ($row[1] eq "two$two_key") {		# connected two		# pink
#          $verified_paper{$row[0]}{con_two}++; }
#        else {					# connected other	# yellow
#          $verified_paper{$row[0]}{con_oth}++; } } }

#   my ($lastname, $two_key, $val_paper) = @_;
  my ($lastname, $two_key) = @_;
  my $lastname_search = $lastname; $lastname_search =~ s/'/''/g;	# need to account for ' for Ch'ng  2004 01 13
  my @paperordered_aids; my @ver_paperordered_aids;		# list of papers, list of verified papers (show separately), get the aids and sort by papers
  my @aids; my @ver_aids;		# list of aids, list of verified aids (show separately)
  my %exact_author_papers;		# papers with exact author matches
  my %join_hash;			# hash to join possible authors+joins with verified+joins
  my %verified_paper;			# key : aid ;  second key : verified or not, yes or no, by two or not 
  my %sort_papers;			# hash to sort three paper types
  my %sort_aids;			# hash to sort three paper types
  my %aid_to_paper;			# convert aid to paper

    # get author_ids and sort in %verified_paper{$aid} depending on which two it's connected to ;  to get those which have been connected but have no verified data yet 
#   my $result = $conn->exec( "
  my $result = $dbh->prepare( "
  SELECT wpa_author_possible.author_id, wpa_author_possible.wpa_join, wpa_author_possible.wpa_author_possible, wpa_author_possible.wpa_valid
    FROM wpa_author_possible
   WHERE wpa_author_possible.wpa_author_possible IS NOT NULL
     AND wpa_author_possible.author_id IN (
         SELECT author_id FROM wpa_author_index WHERE wpa_author_index ~ '$lastname_search'
         )
   ORDER BY wpa_timestamp;
  " );		# author id, wpa_join, possible two#, valid
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") {
        if ($row[2] eq "two$two_key") { $join_hash{$row[0]}{$row[1]}{con_two}++; }
          else { $join_hash{$row[0]}{$row[1]}{con_oth}++; } }	 			# connected other
      else { delete $join_hash{$row[0]}{$row[1]}; } }

    # get author_ids and sort in %verified_paper{$aid} depending on which two it's connected to ;  to get those which have been connected but have no verified data yet 
    # this could also get bad data if something is invalid
#   $result = $conn->exec( "
  $result = $dbh->prepare( "
  SELECT wpa_author_verified.author_id, wpa_author_verified.wpa_join, wpa_author_verified.wpa_author_verified, wpa_author_verified.wpa_valid
    FROM wpa_author_verified
   WHERE wpa_author_verified.wpa_author_verified IS NOT NULL
     AND wpa_author_verified.author_id IN (
         SELECT author_id FROM wpa_author_index WHERE wpa_author_index ~ '$lastname_search'
         )
   ORDER BY wpa_timestamp;
  " );		# author id, wpa_join, verified, valid
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") {
        if ($row[2] =~ m/^YES +Raymond Lee/) { 
            $join_hash{$row[0]}{$row[1]}{ver_ray}++;			# connected verification yes by Raymond
            if ($join_hash{$row[0]}{$row[1]}{ver_yes}) { delete $join_hash{$row[0]}{$row[1]}{ver_yes}; }	# overwrites verification yes
            if ($join_hash{$row[0]}{$row[1]}{ver_no}) { delete $join_hash{$row[0]}{$row[1]}{ver_no}; } }	# overwrites verification no
          elsif ($row[2] =~ m/^YES/) { 
            $join_hash{$row[0]}{$row[1]}{ver_yes}++;			# connected verification yes
            if ($join_hash{$row[0]}{$row[1]}{ver_ray}) { delete $join_hash{$row[0]}{$row[1]}{ver_ray}; }	# overwrites verification raymond
            if ($join_hash{$row[0]}{$row[1]}{ver_no}) { delete $join_hash{$row[0]}{$row[1]}{ver_no}; } }	# overwrites verification no
          else { 
            $join_hash{$row[0]}{$row[1]}{ver_no}++;			# connected verification no
            if ($join_hash{$row[0]}{$row[1]}{ver_ray}) { delete $join_hash{$row[0]}{$row[1]}{ver_ray}; }	# overwrites verification raymond
            if ($join_hash{$row[0]}{$row[1]}{ver_yes}) { delete $join_hash{$row[0]}{$row[1]}{ver_yes}; } } }	# overwrites verification yes
      else { delete $join_hash{$row[0]}{$row[1]}; } }

 
  foreach my $aid (sort keys %join_hash) {						# check the verification status by ``joining''
#     my $is_valid = 0;
#     $result = $conn->exec( "SELECT wpa_valid FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp" );
#     while (my @row = $result->fetchrow) { if ($row[0] eq 'valid') { $is_valid++; } else { $is_valid = 0; } }
# print "ISV $aid $is_valid END<BR>\n";
#     next unless $is_valid;
# print "NEXTISV $aid $is_valid END<BR>\n";
    foreach my $join (sort keys %{ $join_hash{$aid} }) {
      if ( ($join_hash{$aid}{$join}{ver_yes}) && ($join_hash{$aid}{$join}{con_two}) ) { $verified_paper{$aid}{ver_yes}++; }	# green
      elsif ( ($join_hash{$aid}{$join}{ver_ray}) && ($join_hash{$aid}{$join}{con_two}) ) { $verified_paper{$aid}{ver_ray}++; }	# purple
      elsif ( ($join_hash{$aid}{$join}{ver_no}) && ($join_hash{$aid}{$join}{con_two}) ) { $verified_paper{$aid}{ver_no}++; }	# red
      elsif ($join_hash{$aid}{$join}{con_two}) { $verified_paper{$aid}{con_two}++; }						# pink
      elsif ( ($join_hash{$aid}{$join}{ver_yes}) && ($join_hash{$aid}{$join}{con_oth}) ) { $verified_paper{$aid}{oth_yes}++; }	# don't show
      elsif ( ($join_hash{$aid}{$join}{ver_no}) && ($join_hash{$aid}{$join}{con_oth}) ) { $verified_paper{$aid}{oth_no}++; }	# continue
      elsif ($join_hash{$aid}{$join}{con_oth}) { $verified_paper{$aid}{con_oth}++; }						# yellow
      else { 1; }
    } # foreach my $join (sort keys %{ $join_hash{$aid} })
  } # foreach my $aid (sort keys %join_hash)

  my $exact_author = &findExactAuthors($two_key);			# this is not as accurate since it captures invalid data
  my @exact_author = split /\t/, $exact_author;				# exact author match
  foreach my $exact_author (@exact_author) { $exact_author_papers{$exact_author}++; }

  my %invalid_aids;
#   $result = $conn->exec( " SELECT * FROM wpa_author ORDER BY wpa_timestamp; " );
  $result = $dbh->prepare( " SELECT * FROM wpa_author ORDER BY wpa_timestamp; " );
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[3] ne 'valid') { $invalid_aids{$row[1]}++; }
      else { if ($invalid_aids{$row[1]}) { delete $invalid_aids{$row[1]}; } } }

  my %invalid_papers;
#   $result = $conn->exec( " SELECT * FROM wpa ORDER BY wpa_timestamp; " );
  $result = $dbh->prepare( " SELECT * FROM wpa ORDER BY wpa_timestamp; " );
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[3] ne 'valid') { $invalid_papers{$row[0]}++; }
      else { if ($invalid_papers{$row[0]}) { delete $invalid_papers{$row[0]}; } } }

    # get all author_id matching lastname, put in %sort_aids{sort}{$aid} depending on %verified_paper{$aid} and %exact_author_name or partial
    # this is much faster than indexing wpa_author_index and wpa_author, but it could get bad data if something is invalid (gets both valid and invalid data)
#   $result = $conn->exec( "
  $result = $dbh->prepare( "
  SELECT wpa_author.joinkey, wpa_author_index.author_id, wpa_author_index.wpa_author_index, wpa_author_index.wpa_valid , wpa_author_index.wpa_timestamp
    FROM wpa_author_index, wpa_author
   WHERE wpa_author_index ~ '$lastname_search'
     AND wpa_author_index.author_id = wpa_author.wpa_author
   ORDER BY wpa_author_index.wpa_timestamp ;
  " );		# paper joinkey, author id, author name
  $result->execute;
  while (my @row = $result->fetchrow) {
    my $paper = $row[0]; my $aid = $row[1]; my $aname = $row[2]; my $valid = $row[3];
    next if ($invalid_papers{$paper});					# skip invalid papers
    next if ($invalid_aids{$aid});					# skip invalid aids
    $aid_to_paper{$aid} = $paper;					# assign the paper to the aid
    if ($valid ne 'valid') {						# if an author is invalid, check if paper in hash, and if so, remove it  2005 12 01
      if ($sort_aids{verified_yes}{$aid}) { delete $sort_aids{verified_yes}{$aid}; }
      if ($sort_aids{verified_no}{$aid}) { delete $sort_aids{verified_no}{$aid}; }
      if ($sort_aids{connected}{$aid}) { delete $sort_aids{connected}{$aid}; }
      if ($sort_aids{connected_other}{$aid}) { delete $sort_aids{connected_other}{$aid}; }
      if ($sort_aids{exact}{$aid}) { delete $sort_aids{exact}{$aid}; }
      if ($sort_aids{partial}{$aid}) { delete $sort_aids{partial}{$aid}; }
      next; }								# don't keep going since it's an invalid author
    if ($aname =~ m/,/) { $aname =~ s/,//g; }				# filter out commas for exact matches
    if ($aname =~ m/\s+/) { $aname =~ s/\s+/ /g; }			# filter out extra spaces for exact matches
    my $keep_going = 0;
    if ($verified_paper{$aid}) {
        if ($verified_paper{$aid}{ver_yes}) { $sort_aids{verified_yes}{$aid}++; }
        elsif ($verified_paper{$aid}{ver_ray}) { $sort_aids{verified_ray}{$aid}++; }
        elsif ($verified_paper{$aid}{ver_no}) { $sort_aids{verified_no}{$aid}++; }
        elsif ($verified_paper{$aid}{oth_yes}) { 1; }					# verified yes by other, don't show
        elsif ($verified_paper{$aid}{con_two}) { $sort_aids{connected}{$aid}++; }
        elsif ($verified_paper{$aid}{oth_no}) { $keep_going++; }			# not verified yes yet
        elsif ($verified_paper{$aid}{con_oth}) { $sort_aids{connected_other}{$aid}++; } }
      else { $keep_going++; }
    if ($keep_going) {
      if ($exact_author_papers{$aname}) { $sort_aids{exact}{$aid}++; }
      else { $sort_aids{partial}{$aid}++; } } 
  } # while (my @row = $result->fetchrow) 

  foreach my $aid (sort keys %{ $sort_aids{verified_yes} }) { push @ver_aids, $aid; }
  foreach my $aid (sort keys %{ $sort_aids{verified_ray} }) { push @ver_aids, $aid; }
  foreach my $aid (sort keys %{ $sort_aids{verified_no} }) { push @ver_aids, $aid; }
  foreach my $aid (sort keys %{ $sort_aids{exact} }) { 		# unless it's verified as yes or no, put in list of aid
    unless( ($sort_aids{verified_yes}{$aid}) || ($sort_aids{verified_ray}{$aid}) || ($sort_aids{verified_no}{$aid}) ) { push @aids, $aid; } }
  foreach my $aid (sort keys %{ $sort_aids{partial} }) { unless( ($sort_aids{verified_yes}{$aid}) || ($sort_aids{verified_ray}{$aid}) || ($sort_aids{verified_no}{$aid}) ) { push @aids, $aid; } }
  foreach my $aid (sort keys %{ $sort_aids{connected} }) { unless( ($sort_aids{verified_yes}{$aid}) || ($sort_aids{verified_ray}{$aid}) || ($sort_aids{verified_no}{$aid}) ) { push @aids, $aid; } }
  foreach my $aid (sort keys %{ $sort_aids{connected_other} }) { unless( ($sort_aids{verified_yes}{$aid}) || ($sort_aids{verified_ray}{$aid}) || ($sort_aids{verified_no}{$aid}) ) { push @aids, $aid; } }

  my %temp_sort = ();
  foreach my $aid (@ver_aids) { $temp_sort{$aid_to_paper{$aid}} = $aid; }
  foreach my $pap (sort {$a<=>$b} keys %temp_sort) { push @ver_paperordered_aids, $temp_sort{$pap}; }
  %temp_sort = ();
  foreach my $aid (@aids) { $temp_sort{$aid_to_paper{$aid}}{$aid}++; }
  foreach my $pap (sort {$a<=>$b} keys %temp_sort) {
    foreach my $aid (sort {$a<=>$b} keys %{ $temp_sort{$pap} }) { 
      push @paperordered_aids, $aid; } }

  print "Color chart : <FONT COLOR=$green>Verified YES</FONT> <FONT COLOR=$purple>Verified YES by Raymond</FONT> <FONT COLOR=$red>Verified NO</FONT> <FONT COLOR=$pink>Connected not verified</FONT> <FONT COLOR=$yellow>Connected to Other not verified</FONT> <FONT COLOR=$blue>Exact Match</FONT> <FONT COLOR=black>Last name Match</FONT> .<BR>\n";
  print "<TABLE border=1 cellspacing=2>\n";
  for (my $i = 0; $i < scalar(@paperordered_aids); $i+=10) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_paper\" VALUE=\"$val_paper\">";
    my @papers_in_group;
    print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
    for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@paperordered_aids)) ); $j++) { 

      if ($sort_aids{verified_yes}{$paperordered_aids[$j]}) { print "<FONT COLOR = $green>"; }
      elsif ($sort_aids{verified_ray}{$paperordered_aids[$j]}) { print "<FONT COLOR = $purple>"; }
      elsif ($sort_aids{verified_no}{$paperordered_aids[$j]}) { print "<FONT COLOR = $red>"; }
      elsif ($sort_aids{connected}{$paperordered_aids[$j]}) { print "<FONT COLOR = $pink>"; }
      elsif ($sort_aids{connected_other}{$paperordered_aids[$j]}) { print "<FONT COLOR = $yellow>"; }
      elsif ($sort_aids{exact}{$paperordered_aids[$j]}) { print "<FONT COLOR = $blue>"; }
      else { print "<FONT COLOR = black>"; }		# show in different color if grouped
      print "paper " . ($j + 1) . " : $aid_to_paper{$paperordered_aids[$j]}<BR>\n";
      push @papers_in_group, $aid_to_paper{$paperordered_aids[$j]};
      print "</FONT>"; 
    } # for (my $j = $i; $j < $i+10; $j++)
    print "</TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
    my $papers_in_group = join "\t", @papers_in_group;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$papers_in_group\">";
    print "</TR>\n";
    print "</FORM>\n";
  } # for (my $i = 0; $i < scalar(@paperordered_aids); $i+=10)
  print "</TABLE><BR><P><BR>\n";
  print "<TABLE border=1 cellspacing=2>\n";
  for (my $i = 0; $i < scalar(@ver_paperordered_aids); $i+=10) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_paper\" VALUE=\"$val_paper\">";
    my @papers_in_group;
    print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
    for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@ver_paperordered_aids)) ); $j++) { 
      if ($sort_aids{verified_yes}{$ver_paperordered_aids[$j]}) { print "<FONT COLOR = $green>"; }
      elsif ($sort_aids{verified_ray}{$ver_paperordered_aids[$j]}) { print "<FONT COLOR = $purple>"; }
      elsif ($sort_aids{verified_no}{$ver_paperordered_aids[$j]}) { print "<FONT COLOR = $red>"; }
      elsif ($sort_aids{connected}{$ver_paperordered_aids[$j]}) { print "<FONT COLOR = $pink>"; }
      elsif ($sort_aids{connected_other}{$paperordered_aids[$j]}) { print "<FONT COLOR = $yellow>"; }
      elsif ($sort_aids{exact}{$ver_paperordered_aids[$j]}) { print "<FONT COLOR = $blue>"; }
      else { print "<FONT COLOR = black>"; }		# show in different color if grouped
      print "paper " . ($j + 1) . " : $aid_to_paper{$ver_paperordered_aids[$j]}<BR>\n";
      push @papers_in_group, $aid_to_paper{$ver_paperordered_aids[$j]};
      print "</FONT>"; 
    } # for (my $j = $i; $j < $i+10; $j++)
    print "</TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
    my $papers_in_group = join "\t", @papers_in_group;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$papers_in_group\">";
    print "</TR>\n";
    print "</FORM>\n";
  } # for (my $i = 0; $i < scalar(@ver_papers); $i+=10)
  print "</TABLE><BR><P><BR>\n";
} # sub findPapList

sub findExactAuthors {
  my $two_key = shift; my @authors;
#   my $result = $conn->exec( "
  my $result = $dbh->prepare( "
    SELECT two_aka_lastname.two_aka_lastname, two_aka_firstname.two_aka_firstname, two_aka_middlename.two_aka_middlename
      FROM two_aka_lastname, two_aka_middlename, two_aka_firstname
     WHERE two_aka_lastname.joinkey = two_aka_middlename.joinkey
       AND two_aka_lastname.two_order = two_aka_middlename.two_order
       AND two_aka_lastname.joinkey = two_aka_firstname.joinkey
       AND two_aka_lastname.two_order = two_aka_firstname.two_order
       AND two_aka_lastname.joinkey = 'two$two_key';
    ");
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[2]) { if ($row[2] ne 'NULL') { push @authors, "$row[1] $row[2] $row[0]";		# first, middle, last
                                            push @authors, "$row[0] $row[1] $row[2]"; } }	# last, first, middle
    if ($row[0]) { push @authors, "$row[1] $row[0]"; 	# first, last
                   push @authors, "$row[0] $row[1]"; }	# last, first
  }
#   $result = $conn->exec( "
  $result = $dbh->prepare( "
    SELECT two_aka_lastname.two_aka_lastname, two_aka_firstname.two_aka_firstname
      FROM two_aka_lastname, two_aka_firstname
     WHERE two_aka_lastname.joinkey = two_aka_firstname.joinkey
       AND two_aka_lastname.two_order = two_aka_firstname.two_order
       AND two_aka_lastname.joinkey = 'two$two_key';
    ");
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[0]) { push @authors, "$row[1] $row[0]";    	# first, last
                   push @authors, "$row[0] $row[1]"; } }	# last, first
#   $result = $conn->exec( "
  $result = $dbh->prepare( "
    SELECT two_lastname.two_lastname, two_firstname.two_firstname, two_middlename.two_middlename
      FROM two_lastname, two_middlename, two_firstname
     WHERE two_lastname.joinkey = two_middlename.joinkey
       AND two_lastname.two_order = two_middlename.two_order
       AND two_lastname.joinkey = two_firstname.joinkey
       AND two_lastname.two_order = two_firstname.two_order
       AND two_lastname.joinkey = 'two$two_key';
    ");
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[2]) { if ($row[2] ne 'NULL') { push @authors, "$row[1] $row[2] $row[0]";		# first, middle, last
                                            push @authors, "$row[0] $row[1] $row[2]"; }	}	# last, first, middle
    if ($row[0]) { push @authors, "$row[1] $row[0]";	# first, last
                   push @authors, "$row[0] $row[1]"; }	# last, first
  }
#   $result = $conn->exec( "
  $result = $dbh->prepare( "
    SELECT two_lastname.two_lastname, two_firstname.two_firstname
      FROM two_lastname, two_firstname
     WHERE two_lastname.joinkey = two_firstname.joinkey
       AND two_lastname.two_order = two_firstname.two_order
       AND two_lastname.joinkey = 'two$two_key';
    ");
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[0]) { push @authors, "$row[1] $row[0]";	# first, last
                   push @authors, "$row[0] $row[1]"; }	# last, first
  }
  my $authors = join"\t", @authors;
  return $authors;
} # sub findExactAuthors

## papPick block ##

sub pickPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";

  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR><TD>Two</TD><TD>Papers</TD></TR>\n";

  my $oop;
  if ($query->param('two_num')) { $oop = $query->param('two_num'); } 
    else { $oop = 'nodatahere'; }
  my $two_num = untaint($oop);
  my $highest_val = $two_num + 50;

  my $fast_slow = 'fast';
  if ($query->param('fast_slow')) { $fast_slow = $query->param('fast_slow'); } 

  my %twos;				# HoA  key = two#, values = papers

#   my $result = $conn->exec( "SELECT * FROM two_paper;" );
  my $result = $dbh->prepare( "SELECT * FROM two_paper;" );
  $result->execute;
  while (my @row = $result->fetchrow) { push @{ $twos{$row[0]}{paper} }, $row[1]; }

  for (my $i = $two_num; $i <= $highest_val; $i++) {		# for each two, display it and its values
    my $two = 'two' . $i;
    my $val_paper = '';

    if ($fast_slow eq 'slow') {
      my %connect; my %aids;
#       my $result2 = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible = '$two' ORDER BY wpa_timestamp;" );
      my $result2 = $dbh->prepare( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible = '$two' ORDER BY wpa_timestamp;" );
      $result2->execute;
      while (my @row2 = $result2->fetchrow()) {
        if ($row2[3] eq 'valid') { $connect{$row2[0]}{$row2[2]}++; }
          else { delete $connect{$row2[0]}{$row2[2]}; } }
      foreach my $aid (sort keys %connect) {
        foreach my $join (sort keys %{ $connect{$aid} }) {
#           my $result2 = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' AND wpa_join = '$join' ORDER BY wpa_timestamp DESC;" );
          my $result2 = $dbh->prepare( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' AND wpa_join = '$join' ORDER BY wpa_timestamp DESC;" );
          $result2->execute;
          my @row2 = $result2->fetchrow();
          if ($row2[1]) { 
              if ($row2[1] =~ m/NO/) { $aids{no}{$aid}++; }
              elsif ($row2[1] =~ m/YES/) { $aids{yes}{$aid}++; } }
            else { $aids{unverified}{$aid}++; } } }
      my %paps;
      foreach my $aid (sort keys %{ $aids{unverified} }) { 
#         my $result2 = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
        my $result2 = $dbh->prepare( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
        $result2->execute;
        while (my @row2 = $result2->fetchrow()) {
          if ($row2[3] eq 'valid') { $paps{$row2[0]}++; }
            else { delete $connect{$row2[0]}; } } }
      my @paps = keys %paps; my $unver = join", ", @paps;
      %paps = ();
      foreach my $aid (sort keys %{ $aids{yes} }) { 
#         my $result2 = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
        my $result2 = $dbh->prepare( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
        $result2->execute;
        while (my @row2 = $result2->fetchrow()) {
          if ($row2[3] eq 'valid') { $paps{$row2[0]}++; }
            else { delete $connect{$row2[0]}; } } }
      @paps = keys %paps; my $yes = join", ", @paps;
      %paps = ();
      foreach my $aid (sort keys %{ $aids{no} }) { 
#         my $result2 = $conn->exec( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
        my $result2 = $dbh->prepare( "SELECT * FROM wpa_author WHERE wpa_author = '$aid' ORDER BY wpa_timestamp DESC;" );
        $result2->execute;
        while (my @row2 = $result2->fetchrow()) {
          if ($row2[3] eq 'valid') { $paps{$row2[0]}++; }
            else { delete $connect{$row2[0]}; } } }
      @paps = keys %paps; my $no = join", ", @paps;
      my @val_paper = ();
      if ($unver) { $unver = "<FONT COLOR=$pink>$unver</FONT>"; push @val_paper, $unver; }
      if ($no) { $no = "<FONT COLOR=$red>$no</FONT>"; push @val_paper, $no; }
      if ($yes) { $yes = "<FONT COLOR=$green>$yes</FONT>"; push @val_paper, $yes; }
      $val_paper = join", ", @val_paper; }
        
    if ($fast_slow eq 'fast') {
#       foreach $_ (@{ $twos{$two}{paper} }) { }			# don't know why i need this
      my @temp; my %temp;						# filter repeats
      foreach $_ (@{ $twos{$two}{paper} }) { $temp{$_}++; }
      foreach $_ (sort keys %temp) { push @temp, $_; }
#     my $val_papert = join "\t", @temp ;				# pass value with tabs
      $val_paper = join ", ", @temp ; }					# display with commas

    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
    print "<TR><TD>$two</TD><TD>$val_paper</TD>";
    print "<INPUT TYPE=hidden NAME=two VALUE=\"$i\">";
#     print "<INPUT TYPE=hidden NAME=val_paper VALUE=\"$val_papert\">";
    print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Pick !\"></TD></TR>\n";
    print "</FORM>\n";
  } # for ($i = 1; $i < $highest_val; $i++)
  print "</TABLE>\n";
} # sub pickPage

sub firstPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
  print "<CENTER>Enter a two number : <INPUT NAME=two SIZE=8><INPUT TYPE=submit NAME=action VALUE=\"Pick !\"></CENTER><P>\n";

  print "<CENTER>Fast <INPUT NAME=\"fast_slow\" TYPE=\"radio\" VALUE=\"fast\"> Slow <INPUT NAME=\"fast_slow\" TYPE=\"radio\" VALUE=\"slow\"></CENTER><P>\n";
  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR>\n";
  my $counter = 1;
  for (my $i = 1; $i<50000; $i = $i+50) {
    $counter += 50;                     # up the counter, must always be less than 500 for display
    my $j = $i + 49;                    # j is just i + 49 for display
    print "<TD>Two $i - $j</TD><TD><INPUT NAME=\"two_num\" TYPE=\"radio\" VALUE=\"$i\"></TD>\n";
    if ($counter > 500) { $counter = 1; print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Page !\"></TD></TR>\n"; }
  } # for (my $i = 1; $i<50000; $i = $i+50)
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub firstPage


### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  foreach my $two_table (@two_tables) {
#     my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    my $result = $dbh->prepare( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>$row[1]</TD>\n";
        print "  <TD>$row[2]</TD>\n";
        print "  <TD>$row[3]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_table (@two_tables)

  foreach my $two_simpler (@two_simpler) {
#     my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key';" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_simpler</TD>\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>&nbsp;</TD>\n"; 
        print "  <TD>$row[1]</TD>\n";
        print "  <TD>$row[2]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_simpler (@two_simpler)

  print "</TABLE><BR><BR>\n";
} # sub displayOneDataFromKey


sub displayPaperDataFromKey {             # show all paper info from key, and checkbox for each author
  my ($paper_key, $count, $two_key, $mark_count) = @_;
  my $lastnames = &getLastNames($two_key);
  my @lastnames = split/\t/, $lastnames;
  $two_key = 'two' . $two_key;
  print "<TD>TWO KEY $two_key</TD>";
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $paper_table (@paper_tables) { # go through each table for the key
#     my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$paper_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $paper_table WHERE joinkey = '$paper_key';" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$paper_table</TD>";
        print "<TD>$row[0]</TD>"; 
        print "<TD>$row[1]</TD>"; 
        print "<TD>&nbsp;</TD>"; 
        print "<TD>&nbsp;</TD>"; 
        print "<TD>&nbsp;</TD>"; 
        print "<TD>$row[5]</TD></TR>\n"; 
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $paper_table (@paper_tables)
  my %aid = ();
#   my $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$paper_key' ORDER BY wpa_order, wpa_timestamp;" );
  my $result = $dbh->prepare( "SELECT * FROM wpa_author WHERE joinkey = '$paper_key' ORDER BY wpa_order, wpa_timestamp;" );
  $result->execute;
  while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $aid{$row[2]}{$row[1]}++; } else { delete $aid{$row[2]}{$row[1]}; } }
  foreach my $order (sort keys %aid) {
  foreach my $aid (keys %{ $aid{$order} }) {
    if ($aid =~ m/\s/) { $aid =~ s/\s+//g; }	# shouldn't be necessary, but someone copy-pasted wrong
#     $result = $conn->exec( "SELECT * FROM wpa_author_index WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result = $dbh->prepare( "SELECT * FROM wpa_author_index WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[3] eq 'valid') { $aid_paper{$row[0]}{name} = $row[1]; }
        else  { delete $aid_paper{$row[0]}{name}; }
    } # while (my @row = $result->fetchrow)
    my %theHash = ();
#     $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result = $dbh->prepare( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result->execute;
    while (my @row = $result->fetchrow) { 
      if ($row[2]) {
        if ($row[3] eq 'valid') { $theHash{$aid}{$row[2]}{possible} = $row[1]; }
          else { delete $theHash{$aid}{$row[2]}{possible}; } } }
#     $result = $conn->exec( "SELECT * FROM wpa_author_sent WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result = $dbh->prepare( "SELECT * FROM wpa_author_sent WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result->execute;
    while (my @row = $result->fetchrow) { 
      if ($row[2]) { 
        if ($row[3] eq 'valid') { $theHash{$aid}{$row[2]}{sent} = $row[1]; }
          else { delete $theHash{$aid}{$row[2]}{sent}; } } }
#     $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result = $dbh->prepare( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
    $result->execute;
    while (my @row = $result->fetchrow) { 
      if ($row[2]) { 
        if ($row[3] eq 'valid') { $theHash{$aid}{$row[2]}{verified} = $row[1]; }
          else { delete $theHash{$aid}{$row[2]}{verified}; } } }

    if ($theHash{$aid}) {
      foreach my $wpa_join (sort keys %{ $theHash{$aid} }) {
        my $checkbox_flag = 0;
        foreach my $lastname (@lastnames) { 			# for all possible two's lastnames, show checkbox if matches this author
          if ($aid_paper{$aid}{name} =~ m/$lastname/) { $checkbox_flag++; } }
        if ($theHash{$aid}{$wpa_join}{possible}) { 		# no checkbox if refers to another two_person
          if ($theHash{$aid}{$wpa_join}{possible} ne $two_key) { $checkbox_flag = 0; } }
        print "<TR><TD>wpa_author</TD>";
        print "<TD>$paper_key $wpa_join</TD>"; 
        print "<TD>$aid($aid_paper{$aid}{name})</TD>"; 
        if ($checkbox_flag) {
            $count++; 
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"join$count\" VALUE=\"$wpa_join\">\n";
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper$count\" VALUE=\"$paper_key\">\n";
            print "<TD>$count<INPUT NAME=\"check$count\" TYPE=\"checkbox\" ";
            if ($theHash{$aid}{$wpa_join}{possible}) { 
                if ($theHash{$aid}{$wpa_join}{possible} eq $two_key) { print " CHECKED "; $mark_count++; }
                print "VALUE=\"YES\">$theHash{$aid}{$wpa_join}{possible}</TD>"; } 
              else { print "VALUE=\"YES\"></TD>"; } }
          else {
            if ($theHash{$aid}{$wpa_join}{possible}) { print "<TD>$theHash{$aid}{$wpa_join}{possible}</TD>"; }
              else { print "<TD>&nbsp;</TD>"; } }
        if ($theHash{$aid}{$wpa_join}{sent}) { print "<TD>$theHash{$aid}{$wpa_join}{sent}</TD>"; } else { print "<TD>&nbsp;</TD>"; }
        if ($theHash{$aid}{$wpa_join}{verified}) { print "<TD>$theHash{$aid}{$wpa_join}{verified}</TD>"; } else { print "<TD>&nbsp;</TD>"; }
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"aid$count\" VALUE=\"$aid\">\n";
      }
      print "</TR>\n"; }
    else {
      my $checkbox_flag = 0;
      foreach my $lastname (@lastnames) { if ($aid_paper{$aid}{name} =~ m/$lastname/) { $checkbox_flag++; } }
      print "<TR><TD>wpa_author</TD>";
      print "<TD>$paper_key</TD>"; 
      print "<TD>$aid($aid_paper{$aid}{name})</TD>"; 
      if ($checkbox_flag) {
          $count++;
          print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper$count\" VALUE=\"$paper_key\">\n";
          print "<TD>$count<INPUT NAME=\"check$count\" TYPE=\"checkbox\" VALUE=\"YES\"></TD>"; }
        else { print "<TD>&nbsp;</TD>"; }
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"aid$count\" VALUE=\"$aid\">\n";
      print "<TD>&nbsp;</TD><TD>&nbsp;</TD></TR>\n"; }
  } # foreach my $aid (keys %{ $aid{$order} })
  } # foreach my $order (sort keys %aid)
  print "</TABLE><BR><BR>\n";
  return ($count, $mark_count);
} # sub displayPaperDataFromKey

### display from key ###



__END__ 

### depreciated ###
sub displayPossibleMatches {	# return a list of tab delimited papers that may be matches
				# match by lastname first, or lastname first middle
  my ($two_key) = @_;
#   print "TWO $two_key<BR>\n";
  my $result;
  my @firstname; my @lastname; my @middlename;
  $result = $conn->exec( "SELECT two_lastname FROM two_lastname WHERE joinkey = 'two$two_key';" );
  my @row = $result->fetchrow; $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; push @lastname, $row[0];
  $result = $conn->exec( "SELECT two_firstname FROM two_firstname WHERE joinkey = 'two$two_key';" );
  @row = $result->fetchrow; $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; push @firstname, $row[0];
  $result = $conn->exec( "SELECT two_middlename FROM two_middlename WHERE joinkey = 'two$two_key';" );
  @row = $result->fetchrow; if ($row[0]) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; push @middlename, $row[0]; }
  $result = $conn->exec( "SELECT two_aka_lastname FROM two_aka_lastname WHERE joinkey = 'two$two_key';" );
  while (@row = $result->fetchrow) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; push @lastname, $row[0]; }
  $result = $conn->exec( "SELECT two_aka_firstname FROM two_aka_firstname WHERE joinkey = 'two$two_key';" );
  while (@row = $result->fetchrow) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; push @firstname, $row[0]; }
  $result = $conn->exec( "SELECT two_aka_middlename FROM two_aka_middlename WHERE joinkey = 'two$two_key';" );
  while (@row = $result->fetchrow) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; push @middlename, $row[0]; }
  my %temp;
  for (my $i = 0; $i < scalar(@lastname); $i++) { 
    my $name = '';
    $name = $lastname[$i] . ' ' . $firstname[$i];
    my $result2 = $conn->exec( "SELECT * FROM pap_view WHERE pap_author ~ '^$name';" );
    while (my @row2 = $result2->fetchrow) { $temp{$row2[0]}++; }
    if ($middlename[$i]) {
      $name = $lastname[$i] . ' ' . $firstname[$i] . ' ' . $middlename[$i]; }
    $result2 = $conn->exec( "SELECT * FROM pap_view WHERE pap_author ~ '^$name';" );
    while (my @row2 = $result2->fetchrow) { $temp{$row2[0]}++ }
  }
  my $pos_papers = join"\t", sort keys %temp;
  print "Possible Papers : " . scalar(keys %temp) . " : $pos_papers<P>\n";
  return $pos_papers;
} # sub displayPossibleMatches

sub OLDfindExactAuthor {		# this gets more matches by making all possible combinations but takes 3 more seconds
  my $two_key = shift;
  my %firstname; my %lastname; my %middlename;		# valid first, last, and middle names
  my %temp;						# exact author matches
  my $result = $conn->exec( "SELECT two_lastname FROM two_lastname WHERE joinkey = 'two$two_key';" );
  my @row = $result->fetchrow; $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $lastname{$row[0]}++;
  $result = $conn->exec( "SELECT two_firstname FROM two_firstname WHERE joinkey = 'two$two_key';" );
  @row = $result->fetchrow; $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $firstname{$row[0]}++;
  $result = $conn->exec( "SELECT two_middlename FROM two_middlename WHERE joinkey = 'two$two_key';" );
  @row = $result->fetchrow; if ($row[0]) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $middlename{$row[0]}++; }
  $result = $conn->exec( "SELECT two_aka_lastname FROM two_aka_lastname WHERE joinkey = 'two$two_key';" );
  while (@row = $result->fetchrow) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $lastname{$row[0]}++; }
  $result = $conn->exec( "SELECT two_aka_firstname FROM two_aka_firstname WHERE joinkey = 'two$two_key';" );
  while (@row = $result->fetchrow) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $firstname{$row[0]}++; }
  $result = $conn->exec( "SELECT two_aka_middlename FROM two_aka_middlename WHERE joinkey = 'two$two_key';" );
  while (@row = $result->fetchrow) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $middlename{$row[0]}++; }
  foreach my $lastname (keys %lastname) {
    foreach my $firstname (keys %firstname) {
      if (keys %middlename) { foreach my $middlename (keys %middlename) { 
        my $name = $lastname . ' ' . $firstname . ' ' . $middlename; 
        my $result2 = $conn->exec( "SELECT * FROM wpa_author_index WHERE wpa_author_index ~ '^$name';" );
        while (my @row2 = $result2->fetchrow) { $temp{$row2[0]}++ }
      } } # foreach my $middlename (keys %middlename) # if ($middlename[0]) 
      my $name = $lastname . ' ' . $firstname;
      my $result2 = $conn->exec( "SELECT * FROM wpa_author_index WHERE wpa_author_index ~ '^$name';" );
      while (my @row2 = $result2->fetchrow) { $temp{$row2[0]}++; }
    } # foreach my $firstname (keys %firstname)
  } # foreach my $lastname (keys %lastname)
  my $pos_papers = join"\t", sort keys %temp;
  return $pos_papers;
} # sub OLDfindExactAuthor

sub OLDfindPapList {
  my ($lastname, $two_key, $val_groups, $val_paper, $pos_papers) = @_;
#   my $papercount = 0;			# count of papers
  my @papers;				# list of papers
  my %filter_papers;			# hash to filter papers
  my %cgcHash; my %pmHash;		# read xrefs to filter duplicates (main cgcs) 2004 07 15
  my $result = $conn->exec( "SELECT * FROM ref_xrefmed;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];        # hash of cgcs, values meds
    $pmHash{$row[1]} = $row[0]; }       # hash of meds, values cgcs 
  $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];        # hash of cgcs, values pmids
    $pmHash{$row[1]} = $row[0]; }       # hash of pmids, values cgcs
# ASK CECILIA if want to filter papers with lastname that already has a person
#   my $result = $conn->exec( "SELECT * FROM pap_author WHERE pap_author ~ '$lastname' AND pap_person IS NULL ORDER BY joinkey;" );
  my $lastname_search = $lastname; $lastname_search =~ s/'/''/g;	# need to account for ' for Ch'ng  2004 01 13
  $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_author ~ '$lastname_search' ORDER BY joinkey;" );
  while (my @row = $result->fetchrow) {
#     $papercount++;
    push @papers, $row[0];
  } # while (my @row = $result->fetchrow)
  foreach $_ (@papers) { next if ($pmHash{$_}); $filter_papers{$_}++; };	# put papers in filter hash
  @papers = ();						# clear array
  foreach $_ (sort keys %filter_papers) { push @papers, $_; }	# put back in array
  print "There are " . scalar(@papers) . " matching papers for $lastname :<BR>\n";
  my @val_papers = split /\t/, $val_paper;
  my @pos_papers = split /\t/, $pos_papers;
  print "<TABLE border=1 cellspacing=2>\n";
  for (my $i = 0; $i < scalar(@papers); $i+=10) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/paper.cgi\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_groups\" VALUE=\"$val_groups\">";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_paper\" VALUE=\"$val_paper\">";
    my @papers_in_group;
    print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
    for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@papers)) ); $j++) { 
#       if ($val_paper =~ m/$papers[$j]/) { print "<FONT COLOR = $pink>"; }	
      foreach my $pos_pap (@pos_papers) { if ($pos_pap eq $papers[$j]) { print "<FONT COLOR = $blue>"; } }
      foreach my $val_pap (@val_papers) { if ($val_pap eq $papers[$j]) { print "<FONT COLOR = $pink>"; } }
	# show in different color if grouped
      print "paper " . ($j + 1) . " : $papers[$j]<BR>\n";
      push @papers_in_group, $papers[$j];
      foreach my $val_pap (@val_papers) { if ($val_pap eq $papers[$j]) { print "</FONT>"; } }
      foreach my $pos_pap (@pos_papers) { if ($pos_pap eq $papers[$j]) { print "</FONT>"; } }
#       if ($val_paper =~ m/$papers[$j]/) { print "</FONT>CLOSE CLOSE"; }
	# show in different color if grouped
    } # for (my $j = $i; $j < $i+10; $j++)
    print "</TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
    my $papers_in_group = join "\t", @papers_in_group;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$papers_in_group\">";
    print "</TR>\n";
    print "</FORM>\n";
  } # for (my $i = 0; $i < scalar(@papers); $i+=10)
  print "</TABLE><BR><P><BR>\n";
} # sub OLDfindPapList

sub OLDpapMail {
  my ($oop, $two) = &getHtmlVar($query, 'two');
  print "TWO : $two<BR>\n";

  my $value = 'SENT';
  my @emails;
  my $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = 'two$two' ORDER BY old_timestamp DESC;" );
  my @row = $result->fetchrow;
  if ($row[2]) { push @emails, $row[2]; }
# comment out all emails, change to just send to most recent email
#   my $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = 'two$two';" );
#   while (my @row = $result->fetchrow) {
#     if ($row[2]) { push @emails, $row[2]; }
#   } # while (my @row = $result->fetchrow)
  if ($emails[0]) { 
    my $email = join', ', @emails;
    $email .= ', cecilia@tazendra.caltech.edu, qwang@its.caltech.edu';
#     my $email = 'azurebrd@minerva.caltech.edu';
    print "SEND EMAIL TO $email<P>\n";

#     $result = $conn->exec( "SELECT * FROM two_fullname WHERE joinkey = 'two$two' ORDER BY two_lastname, two_firstname, two_middlename;" );
#     my @row = $result->fetchrow;
#     my $lastname = ''; my $firstname = ''; my $middlename = '';
#     if ($row[1]) { $lastname = $row[1]; }
#     if ($row[2]) { $firstname = $row[2]; }
#     if ($row[3]) { $middlename = $row[3]; }
#     my $fullname = $firstname . " " . $middlename . " " . $lastname;
#     $fullname =~ s/\s+/ /g;
     # Changed to standardname because Cecilia forgot how to edit middlenames.  2004 04 16
    $result = $conn->exec( "SELECT two_standardname FROM two_standardname WHERE joinkey = 'two$two';" );
    my @row = $result->fetchrow;
    my $fullname = $row[0];

    my $user = 'cecilia@tazendra.caltech.edu';
    my $subject = 'WormBase Paper Verification';
    my $body = "Dear $fullname,

We at WormBase are trying to create a clean connection between People and the 
Papers they have published.  

This isn't a straightforward task because many times people will publish under 
different names for various reasons.  We have tried to connect all your 
C. elegans papers up to July 6, 2004 with you and would like your help to 
verify that the papers we have found are actually those published by you.  

Please go to the following WWW form and check off the ones selected as Yours 
or Not Yours.  

http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?two_num=$two&action=Pick+%21

If there are any C. elegans papers that you have published that are not on the 
list, please let us know (excluding those that appeared in pubmed in the last 2
months). Also, if you have any corrections or updates about your contact 
information, please let me know.

Thank you,
Cecilia Nakamura
Assistant Curator
California Institute of Technology
Division of Biology 156-29
Pasadena, CA 91125
USA
tel: 626.395.5878   fax: 626.395.8611
cecilia\@tazendra.caltech.edu\n";
    &mailer($user, $email, $subject, $body);	# email CGI to user
  } else {
    $value = 'NO EMAIL';
    print "<P><FONT COLOR='red'><B>NO EMAIL</B></FONT><P>\n";
  }

  my $count = 0;
  $result = $conn->exec( "SELECT * FROM pap_possible WHERE pap_possible = 'two$two' ORDER BY joinkey;" );
    # show all, not just those that are new
  print "<TABLE border=0 cellspacing=2>\n";
  while (my @row = $result->fetchrow) {
    $count++;
    my $joinkey = $row[0];
    my $pap_author = $row[1];
    $pap_author =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
    $pap_author =~ s/\'/''/g;			# escape single quotes for postgres and html display
    print "<TR><TD>$count</TD><TD><FONT COLOR='blue'>UPDATE pap_email SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT></TD></TR>\n";
    my $result = $conn->exec( "UPDATE pap_email SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'; " );
    print "<TR><TD>&nbsp;</TD><TD><FONT COLOR='blue'>UPDATE pap_email SET pap_email = '$value' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT></TD></TR>\n";
    $result = $conn->exec( "UPDATE pap_email SET pap_email = '$value' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'; " );
  } # while (my @row = $result->fetchrow)
  print "</TABLE>\n";
} # sub OLDpapMail


### pg hashes ###

sub populateAIdHash {
  my $result = $conn->exec( "SELECT * FROM wpa_author_index ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $aid_paper{$row[0]}{name} = $row[1]; }
      else  { delete $aid_paper{$row[0]}{name}; }
  } # while (my @row = $result->fetchrow)
  $result = $conn->exec( "SELECT * FROM wpa_author ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $aid_paper{$row[1]}{paper} = $row[0]; }
      else  { delete $aid_paper{$row[1]}{paper}; }
  } # while (my @row = $result->fetchrow)
} # sub populateAIdHash

### pg hashes ###

