#!/usr/bin/perl -w

# Send emails to authors that have been connected to people.  Different format
# for emails in recent 6 months.  Filtering out valid author_ids from wpa_author
# and wpa takes a _really_ long time (10 minutes).
# 2006 07 12
#
# Look for invalid aids (valid aids from invalid wpas) instead of valid aids
# from all valid wpas (huge amount).  now takes about 30 seconds.  2006 07 13
#
# Look at Cecilia's file to look what the latest WS-corresponding paper dump has
# as valid papers, and send links to wormbase if those exist, otherwise check if
# it has a pmid a link to pubmed, otherwise link to wbpaper_display.cgi
# 2008 07 22
#
# Changed email for Andrei and Cecilia.  2008 09 30
#
# Added  (vs just Content-type => 'text/html', )
# 'MIME-Version' => '1.0',
# "Content-type" => 'text/html; charset=ISO-8859-1',
# for some russian dudes Cecilia sent, about RFC 1521 not being met.
# Didn't know where to add Content-Transfer-Encoding since it's a single part message.  
# 2010 02 25
#
# Update for new pap_ tables, but don't yet have correct form to update those value.  
# 2010 06 07
#
# Cleaned up, send emails with links to all unverified papers, update postgres only for 
# pap_author_sent that have changed.  2010 06 09
#
# Live run to 5 people  2010 06 29
# 
# Changed to new paper_display.cgi  Many emails were sent to wrong link.  2010 09 17
#
# Nathalie Pujol was getting it as spam, sent her a new message just to her and got to
# test that the paper link was to the new paper display.  2010 09 21
#
# Changed email text for Kimberly and Cecilia.  2011 07 07
#
# Changed body of email for Cecilia.  2011 07 17
#
# Changed link to person.cgi to new person.cgi link.  2012 06 07
#
# Some changes to body of email.  2013 11 20


use strict;
use diagnostics;
use DBI;
use Mail::Mailer;
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %ws_papers;                          # papers in current WS
&populateWSPapers();
my %paperInfo;
my %type_index;				# for paper table data
$result = $dbh->prepare( "SELECT * FROM pap_type_index;" ); $result->execute;
while (my @row = $result->fetchrow) { $type_index{$row[0]} = $row[1]; }         # type_id, pap_type_index

my %authors;

my $date = &getSimpleSecDate();

my $outfile = "send_emails.outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %pap_author;			# aid => paperID
my %pap_functional;		# paperID
my %aid_done;			# aid, two#
my %aid_person_ver_no;		# aid, two#
my %aid_possible;		# aid, pap_join => two#	originally all under possible, after verified deletions, only those needing response
my %aid_sent;			# aid, pap_join => SENT / NO EMAIL / <blank>
my %aid_verified;		# aid, pap_join => verification
my %aid_name;			# aid => author name

my %histogram;			# stat of how many authors have n-matches with names/akas

my $temp_counter = 0;




# TODO this table is going to get deleted, remove after that
# $result = $dbh->prepare( "SELECT * FROM pap_ignore; " ); $result->execute;
# while (my @row = $result->fetchrow) { $pap_functional{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'functional_annotation'; " ); $result->execute;
while (my @row = $result->fetchrow) { $pap_functional{$row[0]}++; }

$result = $dbh->prepare( "SELECT * FROM pap_author; " ); $result->execute;
while (my @row = $result->fetchrow) { $pap_author{$row[1]} = $row[0]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_index;" ); $result->execute;
while (my @row = $result->fetchrow) { $aid_name{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_possible;" ); $result->execute;
while (my @row = $result->fetchrow) { $aid_possible{$row[0]}{$row[2]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'YES';" ); $result->execute;
while (my @row = $result->fetchrow) { 
  $aid_verified{$row[0]}{$row[2]} = $row[1]; 
  unless ($aid_possible{$row[0]}{$row[2]}) { print "NO possible for verified $row[0] $row[2] E\n"; }
  if ($aid_possible{$row[0]}{$row[2]}) {
    $aid_done{$row[0]}{$aid_possible{$row[0]}{$row[2]}}++; }		# store who said yes
  delete $aid_name{$row[0]};			# verified YES no need to find him
  delete $aid_possible{$row[0]}{$row[2]};	# verified YES don't need to track this person
}

$result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE pap_author_verified ~ 'NO';" ); $result->execute;
while (my @row = $result->fetchrow) { 
  $aid_verified{$row[0]}{$row[2]} = $row[1]; 
  unless ($aid_possible{$row[0]}{$row[2]}) { print "NO possible for verified $row[0] $row[2] E\n"; }
  $aid_person_ver_no{$row[0]}{$aid_possible{$row[0]}{$row[2]}}++;	# store who said no
  delete $aid_possible{$row[0]}{$row[2]};	# verified NO don't need to track this person
}

$result = $dbh->prepare( "SELECT * FROM pap_author_sent;" ); $result->execute;
while (my @row = $result->fetchrow) { 
  $aid_sent{$row[0]}{$row[2]} = $row[1]; 
#   if ($row[1] eq 'SENT') { delete $aid_possible{$row[0]}{$row[2]}; }	# even if sent, send again
}


my %person_paper_aid_join;
my %papers_info;
my %person_info;

foreach my $aid (sort keys %aid_possible) {	# aids with possible neither sent nor verified
#   unless ($pap_author{$aid}) { print "AID $aid not in paper\n"; }
  next unless ($pap_author{$aid});		# skip if not in a paper
  my $joinkey = $pap_author{$aid};
  next if ($pap_functional{$joinkey});		# skip if functional annotation
  foreach my $join (sort keys %{ $aid_possible{$aid} }) {
    my $possible = ''; my $sent = ''; my $verified = '';
    if ($aid_possible{$aid}{$join}) { $possible = $aid_possible{$aid}{$join}; }
    if ($aid_sent{$aid}{$join}) { $sent = $aid_sent{$aid}{$join}; }
    if ($aid_verified{$aid}{$join}) { $verified = $aid_verified{$aid}{$join}; }
    print OUT "J $joinkey A $aid J $join P $possible S $sent V $verified E\n";
    $papers_info{$joinkey}{need}++;
    $person_paper_aid_join{$possible}{$joinkey}{"$aid\t$join"}++;
  } # foreach my $join (sort keys %{ $aid_possible{$aid} })
} # foreach my $aid (sort keys %aid_possible)


my $possible_count = 0;
&populatePaperInfo();
&populatePersonInfo();

foreach my $possible (sort keys %person_paper_aid_join) {
# COMMENT  to send to everyone
#   next unless ( ($possible eq 'two2') || ($possible eq 'two625') || ($possible eq 'two11711') || 
#                 ($possible eq 'two11524') || ($possible eq 'two4749') );
#   next unless ( ($possible eq 'two625') || ($possible eq 'two11590') );
#   next unless ( ($possible eq 'two499') );		# test for Nathalie Pujol  2010 09 21
#   next unless ( ($possible eq 'two1') );		# test for Cecilia  2012 06 20
#   next unless ( ($possible eq 'two9963') );		# test for Cecilia  2012 08 01
#   next if ($possible_count > 2);
  $possible_count++;

  my $email = 'no_email';
  if ($person_info{$possible}{email}) { $email = $person_info{$possible}{email}; }
  my $stdname = 'Author';
  if ($person_info{$possible}{stdname}) { $stdname = $person_info{$possible}{stdname}; }
  print OUT "Considering possible connections to $possible MAILING TO $email\n";
#   my $body = "Dear $stdname :<br /><br />WormBase would like to confirm your authorship on the following papers that are likely related to C. elegans or other nematode research. Even though our paper collection is primarily focused on C. elegans (and other nematodes), it includes some non-nematode papers.<br /><br />\n";	# change 2011 07 07 to below
  my $body = "Dear $stdname :<br /><br />WormBase would like to confirm your authorship on the following papers that are likely related to C. elegans or other nematode research. Please note that our paper collection is primarily focused on C. elegans and other nematodes and, at this time, we are not able to include non-nematode papers.<br /><br />\n";
#   $body .= "These links refer to C. elegans papers, please click the links if they're yours or not as appropriate :<BR><BR>\n";
  $body .= "Please click the links if they're yours or not as appropriate :<BR><BR>\n";		# changed 2011 11 17 for Cecilia
  my $paper_counter_for_cecilia = 0;
  foreach my $joinkey (sort keys %{ $person_paper_aid_join{$possible} }) {
# remove this line if all paper data has been copied from wpa to pap
#     unless ($papers_info{$joinkey}{info}) { $papers_info{$joinkey}{info} = 'NOT YET COPIED FROM wpa_ TABLES'; }
    $paper_counter_for_cecilia++ ;
    my $info = $papers_info{$joinkey}{info};
    $body .= "$paper_counter_for_cecilia $info\n";
    foreach my $aidjoin (sort keys %{ $person_paper_aid_join{$possible}{$joinkey} }) {
      my ($aid, $join) = split/\t/, $aidjoin;
      $body .= "Click <a href=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=VerifyPaper&two_number=$possible&aid=$aid&pap_join=$join&yes_no=YES\">here</a> if the paper is yours, or click <a href=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/generic.cgi?action=VerifyPaper&two_number=$possible&aid=$aid&pap_join=$join&yes_no=NO\">here</a> if the paper is NOT yours.<br /><br />\n";
      &updateSent($aid, $join, $email);
    }
  }
  my ($two) = $possible =~ m/two(\d+)/;
  my $wbperson_url = 'http://wormbase.org/db/misc/person?name=WBPerson' . $two . ';class=Person';
  $body .= "<br />Please reply to this email if your browser can not see the links or if you get an erroneous reply to your submission.<br />\n";
  $body .= "<br />Please check your Person page in <a href=\"$wbperson_url\">WormBase</a> to verify that your information is up to date.<br />\n";
  $body .= "<br />To update contact information please fill <a href=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=Query&number=two$two\">this form</a>.<br />\n";
  $body .= "<br />To add or update your information about lineage of C. elegans biologist and other nematologist please fill <a href=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_lineage.cgi?action=Display&number=WBPerson$two\">this form</a>.<br />\n";
  $body .= "<br />This is an ongoing process, so if you have received this email before, you are receiving it now because new papers have been attached to you.<br />\n<br />\nThank you for your help!<br />Cecilia Nakamura<br />\n<br />\nWormBase Assistant Curator<br />\nCalifornia Institute of Technology<br />\nDivision of Biology 156-29<br />\nPasadena, CA 91125 USA<br />\ncecilia\@tazendra.caltech.edu<br />\n";

  next if ($email eq 'no_email');
  my $user = 'cecilia@tazendra.caltech.edu';
  my $gmail = 'cecnak@gmail.com';				# always send to gmail 2008 01 24
  my $subject = 'WormBase : Connect your recently published C. elegans or other nematode papers';
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;

# TODO remove this so it always goes to who it should go to
#   $email = 'closertothewake@gmail.com';
#   $email = 'cecnak@gmail.com';
#   $email = 'cecnak@gmail.com, closertothewake@gmail.com';

  print OUT "Mail to $email\n";
  $mailer->open({ From    => $user,
                  To      => $email,
                  Bcc     => $gmail,
                  Subject => $subject,
                  'MIME-Version' => '1.0',
        	  "Content-type" => 'text/html; charset=ISO-8859-1',
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
}


close (OUT) or die "Cannot close $outfile : $!";


sub updateSent {
  my ($aid, $join, $email) = @_;
  if ($email eq 'no_email') {
      if ($aid_sent{$aid}{$join}) { if ($aid_sent{$aid}{$join} eq 'NO EMAIL') { return; } }	# already have that in postgres, no need to update
      $email = 'NO EMAIL'; } 
    else { 
      if ($aid_sent{$aid}{$join}) { if ($aid_sent{$aid}{$join} eq 'SENT') { return; } }		# already have that in postgres, no need to update
      $email = 'SENT'; }

  my @commands = ();
  my $command = "DELETE FROM pap_author_sent WHERE author_id = '$aid' AND pap_join = '$join'";
  push @commands, $command;
  $command = "INSERT INTO pap_author_sent VALUES ('$aid', '$email', '$join', 'two1', CURRENT_TIMESTAMP)";
  push @commands, $command;
  $command = "INSERT INTO h_pap_author_sent VALUES ('$aid', '$email', '$join', 'two1', CURRENT_TIMESTAMP)";
  push @commands, $command;
  foreach my $command (@commands) {
    print OUT "$command\n";
# TODO uncomment to update pap_author_sent tables
    $result = $dbh->do( $command );
  } # foreach my $command (@commands)
}


sub populatePersonInfo {
  my $keys = join "', '", keys %person_paper_aid_join;
  my $pgquery = "SELECT * FROM two_standardname WHERE joinkey IN ( '$keys' );";
  $result = $dbh->prepare( $pgquery ); $result->execute;
  while (my @row = $result->fetchrow) { if ($row[1]) { $person_info{$row[0]}{stdname} = $row[2]; } }

  $result = $dbh->prepare( "SELECT * FROM two_email WHERE joinkey IN ( '$keys' ) ORDER BY joinkey, two_order DESC;" ); $result->execute;	# only send email to highest order.  changed to lowest order for Cecilia 2013 10 17
  while (my @row = $result->fetchrow) { if ($row[2]) { $person_info{$row[0]}{email} = $row[2]; } }
 
  my %two_invalid;			# take out invalid twos  2007 07 16  not tested
  $result = $dbh->prepare( "SELECT * FROM two_status ORDER BY two_timestamp;" ); $result->execute;
  while (my @row = $result->fetchrow) { 
    if ($row[2] eq 'Valid') { $row[0] =~ s/two//g; delete $two_invalid{$row[0]}; } 
    elsif ($row[2] eq 'Invalid') { $row[0] =~ s/two//g; $two_invalid{$row[0]}++; } }
  foreach my $two (sort keys %two_invalid) { delete $person_info{$two}; }
}

sub populatePaperInfo {
  my $keys = join"', '", keys %papers_info;
  my @tables = qw( title journal pages volume year type );
  foreach my $table (@tables) {
    my $pgquery = "SELECT * FROM pap_$table WHERE joinkey IN ( '$keys' );";
    $result = $dbh->prepare( $pgquery ); $result->execute;
    while (my @row = $result->fetchrow)  {
      if ($row[1]) { 
        if ($table eq 'title') {
#           my $link = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/wbpaper_display.cgi?number=$row[0]&action=Number+%21";
          my $link = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/paper_display.cgi?data_number=$row[0]&action=Search+%21&history=off";
          if ($ws_papers{ws}{$row[0]}) { $link = "http://wormbase.org/db/misc/paper?name=WBPaper$row[0];class=Paper"; }
          elsif ($ws_papers{pmid}{$row[0]}) { my $pmid = $ws_papers{pmid}{$row[0]}; $pmid =~ s/pmid//g; $link = "http://www.ncbi.nlm.nih.gov/pubmed/$pmid?ordinalpos=1&itool=EntrezSystem2.P"; }
          $row[1] = "<a href=\"$link\" target=new>$row[1]</a><br />\n"; }
        elsif ($table eq 'type') { $row[1] = $type_index{$row[1]}; }
        $papers_info{$row[0]}{$table} = $row[1]; } } }
  foreach my $joinkey (keys %papers_info) {
    my @info;
    foreach my $table (@tables) {
      if ($papers_info{$joinkey}{$table}) { push @info, $papers_info{$joinkey}{$table}; } }
    if (scalar @info> 0) { $papers_info{$joinkey}{info} = join "; ", @info; $papers_info{$joinkey}{info} =~ s/(\n); /\n/; } }
} # sub populatePaperInfo


sub populateWSPapers {
  my $loc_file = '/home/cecilia/work/wb-release';
  open (IN, "$loc_file") or die "Cannot open $loc_file : $!";
  my $src_file = <IN>;
  close (IN) or die "Cannot close $loc_file : $!";
  open (IN, "$src_file") or die "Cannot open $src_file : $!";
  while (my $line = <IN>) { if ($line =~ m/Paper : \"WBPaper(\d+)\"/) { $ws_papers{ws}{$1}++; } }
  close (IN) or die "Cannot close $src_file : $!";
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' ;" ); $result->execute;
  while (my @row = $result->fetchrow) { $ws_papers{pmid}{$row[0]} = $row[1]; }
}



