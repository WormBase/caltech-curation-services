#!/usr/bin/perl -w

# Send emails to authors that have been connected to people.  

# Different format for emails in recent 6 months.  Filtering out valid 
# author_ids from wpa_author and wpa takes a _really_ long time (10 minutes).
# 2006 07 12
#
# Look for invalid aids (valid aids from invalid wpas) instead of valid aids
# from all valid wpas (huge amount).  now takes about 30 seconds.  2006 07 13
#
# Converting to a CGI script that either emails all, or emails a list.  2006 07 18


use strict;
use diagnostics;
use Pg;
use Mail::Mailer;
use CGI;
use Jex;	# getSimpleSecDate

my $query = new CGI;

my $testing_flag = 0;		# set this to 1 to keep from emailing and entering data in postgres

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %results;
my %emails;				# emails by two# keys
my %type_index;				# for paper table data
my %current_aids; my %current_wpa;	# aid and wpa with wpa created within 6 months (aids key is aid, value is paper's joinkey)
my %invalid_aids; my %invalid_wpa;	# some wbpapers are not valid and need to be filtered out

&printHeader();

my $frontpage = '1';
&process();		# check button action and do as appropriate
&display();		# check display flags and show appropriate page

&printFooter();

sub display {
  if ($frontpage) { &frontPageDisplay(); } }

sub frontPageDisplay {			# make the frontpage
  print "<TABLE border=1 cellspacing=2>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/email_for_verification.cgi\">\n";
  print "<TR><TD>Enter two #s (e.g. 625 1234 1 1823)</TD><TD><INPUT NAME=\"two_numbers\" SIZE=40></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Some twos !\"></TD></TR>\n";
  print "<TR><TD>All two #s</TD><TD>&nbsp;</TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"All twos !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub formAceOrWbgDate

sub process {
  my $action;
  unless ($action = $query->param('action') ) { $action = 'none'; }

  if ($action eq 'Some twos !') {
    $frontpage = 0;
    &populateData('sometwos');				# make list by picked paramters
  } # if ($action eq 'Some twos !')
  elsif ($action eq 'All twos !') {
    $frontpage = 0;
    &populateData('alltwos');				# make list by picked paramters
  } # if ($action eq 'All twos !')
  else { print "NOT A VALID ACTION : $action, contact the author.<BR>\n"; }
} # sub process
  

sub populateData {
  my $how_many = shift;

  my $starttime = time;
  my $date = &getSimpleSecDate();
  print "Results in ``send_emails.outfile.$date''<BR>\n";
  my $outfile = "/home/postgres/public_html/cgi-bin/cecilia/data/send_emails.outfile." . $date;
  open(OUT, ">$outfile") or die "Cannot create $outfile : $!";
  
  my $result = $conn->exec( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp; ");
  while (my @row = $result->fetchrow) {
    if ($row[3] eq "valid") { $type_index{$row[0]} = $row[1]; }         # type_id, wpa_type_index
      else { delete $type_index{$row[0]}; } }                           # delete invalid
  
  
  $result = $conn->exec( "SELECT * FROM two_email ORDER BY two_order;" );		# only send email to highest order
  while (my @row = $result->fetchrow) { if ($row[2]) { $row[0] =~ s/two//g; $emails{$row[0]} = $row[2]; } }
  
  my $six_months_date = &getPgDateMinusSixMonths();
  $result = $conn->exec( "SELECT * FROM wpa WHERE wpa_timestamp > '$six_months_date' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $current_wpa{$row[0]}++; } else { delete $current_wpa{$row[0]}; } }
  $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[3] eq 'invalid') { $invalid_wpa{$row[0]}++; } else { delete $invalid_wpa{$row[0]}; } }
  my $current_wpas = join"', '",  keys %current_wpa ; 
  $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey IN ('$current_wpas') ORDER BY wpa_timestamp; " );
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      if ($row[3] eq 'invalid') { $invalid_aids{$row[1]} = $row[0]; } else { delete $invalid_aids{$row[1]}; }
      if ($row[3] eq 'valid') { $current_aids{$row[1]} = $row[0]; } else { delete $current_aids{$row[1]}; } } }
    # This should work, but adding the joinkey IN ('$valid_wpas') section makes it not return anything because of max_expr_depth set to default of 10000
  # my $invalid_wpas = join"', '", keys %invalid_wpa;
  # $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey IN ('$invalid_wpas') ORDER BY wpa_timestamp; " );
  my @invalid_wpas = keys %invalid_wpa;
  while (@invalid_wpas) {
    my @group; 
    for (0 .. 8999) { my $wpa = shift @invalid_wpas; if ($wpa) { push @group, $wpa; } }
    my $invalid_wpas = join"', '", @group;
      # This group of queries takes about 30 seconds, vs. 10 minutes when looking for all valid aids
    $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey IN ('$invalid_wpas') ORDER BY wpa_timestamp; " );
  #   print "SELECT * FROM wpa_author WHERE joinkey IN ('$invalid_wpas') ORDER BY wpa_timestamp; \n" ;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        if ($row[3] eq 'valid') { $invalid_aids{$row[1]} = $row[0]; } else { delete $invalid_aids{$row[1]}; } } } }
  # foreach my $wpa (sort keys %current_wpa) { print "WPA $wpa\n"; }
  # foreach my $aid (sort keys %current_aids) { print "AID $aid\n"; }
  
  my %author_index;		# key author_id, value author_name
  my @special = qw( € ‚ ƒ „ … † ‡ ˆ ‰ Š ‹ Œ Ž ‘ ’ “ ” • — ˜ ™ š › œ ž Ÿ ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ­ ® ¯ ° ± ² ³ ´ µ ¶ · ¹ º » ¼ ½ ¾ ¿ À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö × Ø Ù Ú Û Ü Ý Þ ß à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö ÷ ø ù ú û ü ý þ );
  
  $result = $conn->exec( "SELECT * FROM wpa_author_index ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $author_index{$row[0]} = $row[1]; }
      else { delete $author_index{$row[0]}; } }
  
  my %author_possible;		# keys author_id, wpa_join, value possible two#
  my %author_verified;		# keys author_id, wpa_join, value YES / NO / NULL (no answer)
  my %author_sent;		# keys author_id, wpa_join, value SENT / NO EMAIL / NULL (not sent)
  
  $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    next unless $row[1];
    if ($row[3] eq 'valid') { $author_possible{$row[0]}{$row[2]} = $row[1]; }
      else { delete $author_possible{$row[0]}{$row[2]}; } }
  
  $result = $conn->exec( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    next unless $row[1];
    if ($row[3] eq 'valid') { $author_verified{$row[0]}{$row[2]} = $row[1]; }
      else { delete $author_verified{$row[0]}{$row[2]}; } }
  
  $result = $conn->exec( "SELECT * FROM wpa_author_sent ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    next unless $row[1];
    if ($row[3] eq 'valid') { $author_sent{$row[0]}{$row[2]} = $row[1]; }
      else { delete $author_sent{$row[0]}{$row[2]}; } }
  
  foreach my $aid (sort keys %author_verified) {		# Delete from list those who already verified
    foreach my $wpa_join (sort keys %{ $author_verified{$aid} }) {
      if ($author_verified{$aid}{$wpa_join} =~ m/NO/) { delete $author_possible{$aid}{$wpa_join}; }
      elsif ($author_verified{$aid}{$wpa_join} =~ m/YES/) { delete $author_possible{$aid}{$wpa_join}; } } }
  
  foreach my $aid (sort keys %author_possible) {					# for each possible
    next if $invalid_aids{$aid};							# skip aids that aren't valid
  #   next unless $current_aids{$aid};						# skip aids that aren't current (paper in recent 6 months)
    foreach my $wpa_join (sort keys %{ $author_possible{$aid} }) {		# and its join
      unless ($author_sent{$aid}{$wpa_join}) { $author_sent{$aid}{$wpa_join} = 'BLANK'; }		# set NULL to BLANK in author_sent
      unless ($author_index{$aid}) { $author_index{$aid} = 'ERROR NO INDEX'; }
      if ($author_possible{$aid}{$wpa_join}) {					# this is always true, unless the possible two# is blank
        my ($num) = $author_possible{$aid}{$wpa_join} =~ m/(\d+)/;		# grab the number
        unless ($num) { $num = 0; }						# put info into array of results for that two#
        if ($author_possible{$aid}{$wpa_join}) { if ($author_possible{$aid}{$wpa_join} =~ m/two/) { $author_possible{$aid}{$wpa_join} =~ s/two//g; } }
        push @{ $results{$num} }, "$aid\t$wpa_join\t$author_possible{$aid}{$wpa_join}\t$author_sent{$aid}{$wpa_join}\t$author_index{$aid}"; } 
  } } # foreach my $aid (sort keys %author_possible)
  
  
  
  
  if ($how_many eq 'sometwos') {
    my ($var, $two_numbers) = &getHtmlVar($query, 'two_numbers');
    print "TWO $two_numbers TWO<BR>\n";
    my @cecilia_list = split/\s+/, $two_numbers;
    foreach my $two (@cecilia_list) { print "SENDING TO $two<BR>\n"; &sendConnection($two); } }
  elsif ($how_many eq 'alltwos') {
    print OUT "There are " . scalar(keys %results) . " people in the list.\n";
    print OUT "Author ID\ttwo#\tSent\tAuthor Name\n";
    foreach my $two (sort {$a <=> $b} keys %results) { &sendConnection($two); } }
  else { print "ERROR need to pick some twos or all twos<BR>\n"; die; }

  my $endtime = time;
  my $difftime = $endtime - $starttime;
  print "This took $difftime seconds<BR>\n";

  close (OUT) or die "Cannot close $outfile : $!";
} # sub populateData
  
sub sendConnection {
  my $two = shift;
  my $result = $conn->exec( "SELECT two_standardname FROM two_standardname WHERE joinkey = 'two$two' ORDER BY two_timestamp DESC;" );
  my @row = $result->fetchrow;
  my $standard_name = $row[0];
  my $has_current_papers = '';
  my $has_old_papers = '';
  foreach my $line ( @{ $results{$two} } ) {
    my ($aid, $wpa_join, $two, $sent, $aname) = split/\t/, $line;
    print OUT "$line\n";
    if ($emails{$two}) { 			# there is an email
      if ($sent eq 'BLANK') { 			# insert SENT
        my $command = "INSERT INTO wpa_author_sent VALUES ('$aid', 'SENT', '$wpa_join', 'valid', 'two1', CURRENT_TIMESTAMP);";
        unless ($testing_flag) { my $result = $conn->exec( $command ); }
        print OUT "$command\n"; }
      elsif ($sent eq 'NO EMAIL') {		# set invalid, insert SENT
        my $command = "INSERT INTO wpa_author_sent VALUES ('$aid', 'NO EMAIL', '$wpa_join', 'invalid', 'two1', CURRENT_TIMESTAMP);";
        unless ($testing_flag) { my $result = $conn->exec( $command ); }
        print OUT "$command\n";
        $command = "INSERT INTO wpa_author_sent VALUES ('$aid', 'SENT', '$wpa_join', 'valid', 'two1', CURRENT_TIMESTAMP);";
        unless ($testing_flag) { my $result = $conn->exec( $command ); }
        print OUT "$command\n"; }
      elsif ($sent eq 'SENT') { 1; }		# nothing
      else { print OUT "ERR not a valid sent option $sent\n"; }
    } else {					# there is no email
      if ($sent eq 'BLANK') { 			# insert NO EMAIL
        my $command = "INSERT INTO wpa_author_sent VALUES ('$aid', 'NO EMAIL', '$wpa_join', 'valid', 'two1', CURRENT_TIMESTAMP);";
        unless ($testing_flag) { my $result = $conn->exec( $command ); }
        print OUT "NO EMAIL $command\n"; }
      elsif ($sent eq 'NO EMAIL') { 1; }	# nothing
      elsif ($sent eq 'SENT') { 1; }		# nothing, Cecilia doesn't want to overwrite old ``SENT'' with current ``NO EMAIL'' 2006 07 14
      else { print OUT "ERR not a valid sent option $sent\n"; }
    }
    if ($current_aids{$aid}) {
      my $info = &getPaperInfo($aid);
      unless ($info eq 'No info') {
        $has_current_papers .= $info;
        $has_current_papers .= "Click <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?action=Connect&two_number=$two&aid=$aid&wpa_join=$wpa_join&yes_no=YES\">here</A> if the paper is yours, or click <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?action=Connect&two_number=$two&aid=$aid&wpa_join=$wpa_join&yes_no=NO\">here</A> if the paper is NOT yours.<BR><BR>\n"; } }
    else { print OUT "OLD AID $aid\n"; $has_old_papers++; }
#     my %join_hash;                # the aids and joins of the twos that match
#     $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE wpa_author_possible = 'two$two' ORDER BY wpa_timestamp; ");
#     while (my @row = $result->fetchrow) {
#       if ($row[3] eq "valid") { $join_hash{$row[0]}{$row[2]}++; }		# aid, wpa_join
#         else { delete $join_hash{$row[0]}{$row[2]}; } }			# delete invalid
  } # foreach my $line ( @{ $results{$two} } )

  if ( ($emails{$two}) && ( $has_current_papers || $has_old_papers ) ) {	# if there's an email and content, email them
#     my $body = "Dear $standard_name ($emails{$two}) :<BR>\n";
    my $body = "Dear $standard_name :<BR><BR>WormBase wants to confirm your authorship on the following C. elegans paper(s).<BR>\n";
    if ($has_current_papers) {
      $body .= "These links refer to current C. elegans papers, please click the links if they're yours or not as appropriate :<BR><BR>\n$has_current_papers\n"; }
    if ($has_old_papers) {
      $body .= "<BR><BR>\nThese are older C. elegans papers, click <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/confirm_paper.cgi?two_num=$two&action=Pick+%21\">here</A> to verify if they're yours or not as appropriate.<BR>\n"; }
    $body .= "<BR>Thank you for your help!<BR>\n";
    print OUT $body;

#     my $email = 'cecilia@tazendra.caltech.edu';
#     my $email = 'cecilianakamura@excite.com';
#     my $email = 'pws@its.caltech.edu';
#     my $email = 'closertothewake@gmail.com, azurebrd@its.caltech.edu';
#     my $email = $emails{$two};			# UNCOMMENT THIS TO SEND TO USERS
    my $email = $emails{$two} . ', cecilia@tazendra.caltech.edu'; 	# UNCOMMENT THIS TO SEND TO USERS and Cecilia
    my $user = 'cecilia@tazendra.caltech.edu';
    my $subject = 'WormBase : Connect your recently published C. elegans papers';

    unless ($testing_flag) {
      my $command = 'sendmail';
      my $mailer = Mail::Mailer->new($command) ;
      $mailer->open({ From    => $user,
                      To      => $email,
                      Subject => $subject,
            	  "Content-type" => 'text/html',
                    })
          or die "Can't open: $!\n";
      print $mailer $body;
      $mailer->close();
    } # unless ($testing_flag)
  } # if ($emails{$two})

} # sub sendConnection


sub getPaperInfo {
  my $aid = shift;
  if ($current_aids{$aid}) {
    my @paper_tables = qw(wpa_journal wpa_pages wpa_volume wpa_year wpa_type wpa_contains );
    my $paper_info = '';
    my $joinkey = $current_aids{$aid};
    my $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
    my %valid_hash = ();                                             # filter things through a hash to get rid of invalid data.
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        $row[1] = "<A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_display.cgi?number=$joinkey&action=Number+%21\" TARGET=new>$row[1]</A><BR>\n";
#         $row[1] = "<A HREF=http://www.wormbase.org/db/misc/paper?name=WBPaper$joinkey;class=Paper TARGET=new>$row[1]</A><BR>\n";	# link to WormBase
        if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; } else { delete $valid_hash{$row[1]}; } } }
    my $data = join ", ", sort keys %valid_hash;
    $paper_info .= "$data\n";
    my @line;
    foreach my $paper_table (@paper_tables) { # go through each table for the key
      my %valid_hash;                                             # filter things through a hash to get rid of invalid data.
      my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
      while (my @row = $result->fetchrow) {
        if ($row[1]) {
          if ($paper_table eq 'wpa_type') { $row[1] = $type_index{$row[1]}; }
          if ($row[3] eq 'valid') { $valid_hash{$row[1]}++; } else { delete $valid_hash{$row[1]}; } } }
      foreach my $data (sort keys %valid_hash) { push @line, $data; }
    } # foreach my $paper_table (@paper_tables)
    $data = join "; ", @line;
    $paper_info .= "$data<BR>\n";
    if ($paper_info) { return $paper_info; } }
  else { return "No info"; }
} # sub getPaperInfo

sub getPgDateMinusSixMonths {
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($mon < 7) { $year--; $mon += 12; }	# if month is less than 7 subtract from year and add 12 months
  $mon -= 6;					# go back 6 months
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($mon < 10) { $mon = "0$mon"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  my $todaydate = "${year}-${mon}-${mday}";
                                        # set current date
  my $date = $todaydate . " $hour\:$min\:$sec";
                                        # set final date
  return $date;
} # sub getPgDateMinusSixMonths





