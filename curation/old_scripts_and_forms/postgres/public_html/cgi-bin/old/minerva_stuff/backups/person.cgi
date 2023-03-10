#!/usr/bin/perl -w
# 
# current version 2002 01 11 11:38 gets entries updated since $start_date.
# user chooses one to ``Compare !'' and the script checks their last name and 
# email addresses against wbg_tables in postgres, and if matching returns a 
# priority (goodness) value depending on likelyhood of match.  once all wbg 
# keys have a value, these are sorted (highest -> lowest) and displayed with 
# the proper color background.  user checks those that match, and results of
# matchness is written into the match-related wbg and ace tables for those keys.  
#
# 2002 01 16 : choose whether to search wbgs or aces, and what the recency date
# is.  ``Compare !'' compares the chosen entry vs those in the other type, and
# its own type (excluding itself).  ``Group !'' makes grouped be YES; makes all
# entries be ``compared_by'' to the main, makes the main be ``compared_vs'' to
# all others; likewise does a ``groupedwith'' or ``rejectedvs'' or
# ``rejectedby'' accordingly.  
#
# 2002 01 17 : gets 2 date inputs for date range, default end date current date,
# default start date ~6 months ago.  choice of full listings, or new (meaning
# those not yet grouped), defaults to full to list all.  if new, defaults to
# display, but checks to see if there's an entry.  if there is, sets flag to not 
# display; if there isn't, it won't go into the loop, which is why it has to 
# default to push.
# &getWbgByAceLast() updated to check the ace last names with the wbg
# middlenames as well as the wbg last names in case it's in the wrong place.
# &compareWbg() updated to have 3 more subroutines to get the middlenames to
# check against ace and wbg last names in case the source has a mistake
# &getWbgMiddleByWbgKey($main_wbg_key); &getAceByWbgMiddle(%wbg_middles);
# &getWbgByWbgMiddle($main_wbg_key, %wbg_middles);
#
# Changed getAceLastByAceKey to get ace_name, and put in %ace_lasts hash not
# only the found last name, but also to first sub out any underscores (_) with 
# spaces (these have been introduced to deal with people with two last names as 
# a last name) and then add the last word of the last name (like Silva from
# de_Silva) as well as the full thing (like de Silva for de_Silva)  2002-01-24
#
# Added allowing apostrophes (') to the regexp change from yesterday  2002-01-25
#
# Fixed the &group() subroutine to write the proper stuff to the PG database, 
# groupfile, and HTML display (what a headache to fix the PG tables from the
# errors)  2002 02 11


use strict;
use CGI;
use Fcntl;
# use HTML::Template;
# use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);

my $frontpage = 1;			# show the front page on first load
# my $displayList = 0;			# non-zero to show list of recent ace entries
my $start_date = '2001-06-01';		# date to compare against to check recency
my $end_date = &GetDate();		# last date to check, default to now

my %ace_wbg_keys;		# wbg keys that match an ace value, value of hash is higher the 
				# more likely it is to be a match
my %ace_ace_keys;		# ace keys that match an ace value (excluding itself), 
				# value of hash is higher the more likely it is to be a match
my %wbg_ace_keys;		# ace keys that match a wbg value, value of hash is higher the 
				# more likely it is to be a match
my %wbg_wbg_keys;		# wbg keys that match a wbg value (excluding itself), 
				# value of hash is higher the more likely it is to be a match

my @HTMLparameters;
my @HTMLparamvalues;
my @PGparameters;
my @PGparamvalues;
my %variables;

&PrintHeader();

# &pgRunOne();
# &pgGetWbgKey();

&process();		# check button action and do as appropriate
&display();		# check display flags and show appropriate page


&PrintFooter();

sub display {
  if ($frontpage) {
    &formAceOrWbgDate();	# make the frontpage
  } # if ($frontpage) 

#   if ($displayList) {	# currently commented out because Pick chooses which to display (ace or wbg)
#     &pgShowRecentAce();
# #   &pgGetRecentAce();
#   } # if ($displayList)
} # sub display

sub process {
  my $action;
  unless ($action = $query->param('action') ) { 
    $action = 'none';
  }

  if ($action eq 'Pick !') {
    $frontpage = 0;
#     $displayList = 1;
    &getPick();				# make list by picked paramters
  } # if ($action eq 'Pick !')

  elsif ($action eq 'Compare !') {
    $frontpage = 0;
#     $displayList = 0;
    &compare();				# get stuff to select among to make groups
  } # if ($action eq 'Compare !')

  elsif ($action eq 'Group !') {
    $frontpage = 0;
#     $displayList = 0;
    &group();				# make groupings depending on clicked and data
  } # elsif ($action eq 'Group !')

  elsif ($action eq 'none') { 1; }

  else { print "NOT A VALID ACTION : $action, contact the author.<BR>\n"; }
} # sub process

#### pick ####

sub getPick {
  my $oop;
  my ($ace_list, $wbg_list);
  my $full_or_new = 'full';
  if ( $query->param('full_or_new') ) {	# if full_or_new, overwrite default one
    $oop = $query->param('full_or_new');
    $full_or_new = &Untaint($oop);
  } # if ( $query->param('full_or_new') )
  if ( $query->param('start_date') ) {	# if start_date, overwrite default one
    $oop = $query->param('start_date');
    $start_date = &Untaint($oop);
  } # if ( $query->param('start_date') )
  if ( $query->param('end_date') ) {	# if end_date, overwrite default one
    $oop = $query->param('end_date');
    $end_date = &Untaint($oop);
  } # if ( $query->param('end_date') )
  if ( $query->param('ace_list') ) { 	# if ace chosen, do all for ace
    $oop = $query->param('ace_list');
    $ace_list = &Untaint($oop);
    &pgShowRecentAce($full_or_new);	# currently stored in depreciated DISPLAY section
  } # if ( $query->param('ace_list') )
  if ( $query->param('wbg_list') ) { 	# if wbg chosen, do all for wbg
    $oop = $query->param('wbg_list');
    $wbg_list = &Untaint($oop);
    &pgShowRecentWbg($full_or_new);	# currently stored in depreciated DISPLAY section
  } # if ( $query->param('wbg_list') )
} # sub getPick

#### pick ####


#### compare ####

sub compare {				# make comparisons to present to make groups
  my $oop;
  if ( $query->param('ace_key') ) { 
    $oop = $query->param('ace_key');
    my $main_ace_key = &Untaint($oop);
    &compareAce($main_ace_key);		# find possible groupings to ace key and display them
  } # if ( $query->param('ace_key') )
  if ( $query->param('wbg_key') ) { 
    $oop = $query->param('wbg_key');
    my $main_wbg_key = &Untaint($oop);
    &compareWbg($main_wbg_key);		# find possible groupings to wbg key and display them
  } # if ( $query->param('wbg_key') )
} # sub compare

  # WBG #
sub compareWbg {			# main wbg comparison subroutine
  my $main_wbg_key = shift;
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person.cgi\">\n";			# compare form, encompass wbg, aces, and wbgs
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Group !\"><BR><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_key\" VALUE=\"$main_wbg_key\">\n";
					# pass the main wbg_key for the cgi to read

    # display the data from the wbg key
  &displayWbgDataFromKey($main_wbg_key, '0', '1');	# comment out to display for each entry
					# pass main value, 0 to make white, 1 to default check the box
  
  my %wbg_emails = &getWbgEmailByWbgKey($main_wbg_key);	# get the email addresses of the entry
  &getAceByWbgEmail(%wbg_emails);			# get the ace keys for the email address
  &getWbgByWbgEmail($main_wbg_key, %wbg_emails);	# get the wbg keys for the email address
  
  my %wbg_lasts = &getWbgLastByWbgKey($main_wbg_key);	# get the last name of the entry
  &getAceByWbgLast(%wbg_lasts);				# get the ace keys for the last name
  &getWbgByWbgLast($main_wbg_key, %wbg_lasts);		# get the wbg keys for the last name

  my %wbg_middles = &getWbgMiddleByWbgKey($main_wbg_key);	# get the middle name of the entry
  &getAceByWbgMiddle(%wbg_middles);			# get the ace keys for the middle name
							# check ace author by wbg middle name
  &getWbgByWbgMiddle($main_wbg_key, %wbg_middles);	# get the wbg keys for the middle name
							# check wbg last names by wbg middle name 
							# in case source file is wrong

  foreach my $wbg_key (sort by_wbg_wbg_keys_value keys %wbg_wbg_keys) {
					# for the wbgs sort by value (high to low) and display them
    &displayWbgDataFromKey($wbg_key, $wbg_wbg_keys{$wbg_key});;
    &displayWbgDataFromKey($main_wbg_key, '0');	# comment out to display only once
  } # foreach (keys %wbg_wbg_keys)

  foreach my $ace_key (sort by_wbg_ace_keys_value keys %wbg_ace_keys) {
					# for the aces sort by value (high to low) and display them
    &displayAceDataFromKey($ace_key, $wbg_ace_keys{$ace_key});;
    &displayWbgDataFromKey($main_wbg_key, '0');	# comment out to display only once
  } # foreach (keys %wbg_ace_keys)

  my $wbg_ace_keys = join("\t", keys %wbg_ace_keys);
  print "EMAIL KEYS : $wbg_ace_keys<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_ace_keys\" VALUE=\"$wbg_ace_keys\">\n";
					# pass the secondary wbg_ace_keys in tabbed form
  my $wbg_wbg_keys = join("\t", keys %wbg_wbg_keys);
  print "EMAIL KEYS : $wbg_wbg_keys<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_wbg_keys\" VALUE=\"$wbg_wbg_keys\">\n";
					# pass the secondary wbg_wbg_keys in tabbed form

  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Group !\"><BR><BR>\n";
  print "</FORM>\n";		# close compare form, encompass wbg, aces, and wbgs
} # sub compareWbg

  # sorters
sub by_wbg_ace_keys_value {		# sort from highest to lowest by value
  $wbg_ace_keys{$b} <=> $wbg_ace_keys{$a}
} # sub by_wbg_ace_keys_value

sub by_wbg_wbg_keys_value {		# sort from highest to lowest by value
  $wbg_wbg_keys{$b} <=> $wbg_wbg_keys{$a}
} # sub by_wbg_wbg_keys_value
  # sorters

  # wbg by email
sub getWbgEmailByWbgKey {
  my $wbg_key = shift;
  my $result = '';
  $result = $conn->exec( "SELECT * FROM wbg_email WHERE joinkey = '$wbg_key';" );
  my @row; my %wbg_emails;
  while (@row = $result->fetchrow) {
    my $email = lc($row[1]);
    if ($email) { $wbg_emails{$email}++; } 
  } # while (@row = $result->fetchrow)
  return %wbg_emails;
} # sub getWbgEmailByWbgKey

sub getAceByWbgEmail {
  my %wbg_emails = @_;
  foreach my $wbg_email (sort keys %wbg_emails) { 
    my ($username, $domain) = $wbg_email =~ m/(.*)@(.*\..*)/;
# print "ACE EMAIL : $username $domain<BR>\n";
    my $result = $conn->exec( "SELECT * FROM ace_email WHERE ace_email ~ '$username' AND ace_email ~ '$domain';" );
    my $goodness_level = '5';			# user and domain match
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
        unless ($wbg_ace_keys{$row[0]}) {				# if value is new
          $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_ace_keys{$row[0]})			# if not new
          unless ($wbg_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

    $result = $conn->exec( "SELECT * FROM ace_email WHERE ace_email ~ '$username';" );
    $goodness_level = '3';			# only user matches
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_ace_keys{$row[0]}) {				# if value is new
          $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_ace_keys{$row[0]})			# if not new
          unless ($wbg_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

  } # foreach my %wbg_email (sort keys %wbg_emails)
} # sub getAceByWbgEmail

sub getWbgByWbgEmail {
  my ($wbg_key, %wbg_emails) = @_;
  foreach my $wbg_email (sort keys %wbg_emails) {
    my ($username, $domain) = $wbg_email =~ m/(.*)@(.*\..*)/;

    my $result = $conn->exec( "SELECT * FROM wbg_email WHERE wbg_email ~ '$username' AND wbg_email ~ '$domain' AND joinkey <> '$wbg_key';" );
    my $goodness_level = '5';			# user and domain match
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
        unless ($wbg_wbg_keys{$row[0]}) {				# if value is new
          $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_wbg_keys{$row[0]})			# if not new
          unless ($wbg_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

    $result = $conn->exec( "SELECT * FROM wbg_email WHERE wbg_email ~ '$username' AND joinkey <> '$wbg_key';" );
    $goodness_level = '3';			# only user matches
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_wbg_keys{$row[0]}) {				# if value is new
          $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_wbg_keys{$row[0]})			# if not new
          unless ($wbg_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

  } # foreach my $wbg_email (sort keys %wbg_emails)
} # sub getWbgByWbgEmail
  # wbg by email

  # wbg by middlename
sub getWbgMiddleByWbgKey {
  my $wbg_key = shift;
  my $result = '';
  $result = $conn->exec( "SELECT * FROM wbg_middlename WHERE joinkey = '$wbg_key';" );
  my @row;
  my %wbg_middles;
  while (@row = $result->fetchrow) {
    if ($row[1]) {			# if the table has a middlename entry
      my ($middlename) = $row[1]; #  =~ m/[^a-zA-Z]([a-zA-Z]*)$/;
      if ($middlename) { 
        $wbg_middles{$middlename}++;		# put in hash to filter doubles
      } else { # if ($middlename)		# if no middlename, get from author
        print "<font color=blue>ERROR : No middle name matched for $wbg_key</font><BR>\n";
      } # else # if ($middlename)
    } # if ($row[1])
  } # while (@row = $result->fetchrow)
  return %wbg_middles;
} # sub getWbgMiddleByWbgKey

sub getAceByWbgMiddle {
  my %wbg_middles = @_;				# get the middle names
  foreach my $wbg_middle (sort keys %wbg_middles) {
    my $result = $conn->exec( "SELECT * FROM ace_author WHERE ace_author ~ '$wbg_middle';" );
    my $goodness_level = '1';			# only middle name matches
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_ace_keys{$row[0]}) {			# if value is new
          $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_ace_keys{$row[0]})		# if not new
          unless ($wbg_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_middle (@wbg_middles)
} # sub getAceByWbgMiddle 

sub getWbgByWbgMiddle {		# check wbg last names by wbg middle name in case source file is wrong
  my ($wbg_key, %wbg_middles) = @_;		# get the main key and the middle names
  foreach my $wbg_middle (sort keys %wbg_middles) {
    my $result = $conn->exec( "SELECT * FROM wbg_last WHERE wbg_last ~ '$wbg_middle' AND joinkey <> '$wbg_key';" );
    my $goodness_level = '1';			# only middle name matches
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_wbg_keys{$row[0]}) {			# if value is new
          $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_wbg_keys{$row[0]})		# if not new
          unless ($wbg_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_middle (@wbg_middles)
} # sub getWbgByWbgMiddle 
  # wbg by middlename

  # wbg by lastname
sub getWbgLastByWbgKey {
  my $wbg_key = shift;
  my $result = '';
  $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE joinkey = '$wbg_key';" );
  my @row;
  my %wbg_lasts;
  while (@row = $result->fetchrow) {
    my ($lastname) = $row[1]; #  =~ m/[^a-zA-Z]([a-zA-Z]*)$/;
    if ($lastname) { 
      $wbg_lasts{$lastname}++;		# put in hash to filter doubles
    } else { # if ($lastname)		# if no lastname, get from author
      print "<font color=blue>ERROR : No last name matched for $wbg_key</font><BR>\n";
    } # else # if ($lastname)
  } # while (@row = $result->fetchrow)
  return %wbg_lasts;
} # sub getWbgLastByWbgKey

sub getAceByWbgLast {
  my %wbg_lasts = @_;				# get the last names
  foreach my $wbg_last (sort keys %wbg_lasts) {
    my $result = $conn->exec( "SELECT * FROM ace_author WHERE ace_author ~ '$wbg_last';" );
    my $goodness_level = '2';			# only last name matches
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_ace_keys{$row[0]}) {			# if value is new
          $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_ace_keys{$row[0]})		# if not new
          unless ($wbg_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_last (@wbg_lasts)
} # sub getAceByWbgLast 

sub getWbgByWbgLast {
  my ($wbg_key, %wbg_lasts) = @_;		# get the main key and the last names
  foreach my $wbg_last (sort keys %wbg_lasts) {
    my $result = $conn->exec( "SELECT * FROM wbg_last WHERE wbg_last ~ '$wbg_last' AND joinkey <> '$wbg_key';" );
    my $goodness_level = '2';			# only last name matches
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_wbg_keys{$row[0]}) {			# if value is new
          $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_wbg_keys{$row[0]})		# if not new
          unless ($wbg_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_last (@wbg_lasts)
} # sub getWbgByWbgLast 
  # wbg by lastname
  # WBG #

  # ACE #
sub compareAce {
  my $main_ace_key = shift;
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person.cgi\">\n";			# compare form, encompass ace, wbgs, and aces
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Group !\"><BR><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_key\" VALUE=\"$main_ace_key\">\n";
					# pass the main ace_key

    # display the data from the ace key
  &displayAceDataFromKey($main_ace_key, '0', '1');	# comment out to display for each entry
					# pass main value, 0 to make white, 1 to default check the box

  my %ace_emails = &getAceEmailByAceKey($main_ace_key);	# get the emails from the main key
  &getWbgByAceEmail(%ace_emails);			# get the wbg keys form the emails
  &getAceByAceEmail($main_ace_key, %ace_emails);	# get the ace keys form the emails

  my %ace_lasts = &getAceLastByAceKey($main_ace_key);	# get the last names from the main key
  &getWbgByAceLast(%ace_lasts);				# get the wbg keys form the last names
  &getAceByAceLast($main_ace_key, %ace_lasts);		# get the ace keys form the last names

  foreach my $wbg_key (sort by_ace_wbg_keys_value keys %ace_wbg_keys) {
					# for the wbgs sort by value (high to low) and display them
    &displayWbgDataFromKey($wbg_key, $ace_wbg_keys{$wbg_key});;
    &displayAceDataFromKey($main_ace_key, '0');	# comment out to display only once
  } # foreach (keys %ace_wbg_keys)

  foreach my $ace_key (sort by_ace_ace_keys_value keys %ace_ace_keys) {
					# for the aces sort by value (high to low) and display them
    &displayAceDataFromKey($ace_key, $ace_ace_keys{$ace_key});;
    &displayAceDataFromKey($main_ace_key, '0');	# comment out to display only once
  } # foreach (keys %ace_ace_keys)

  my $ace_wbg_keys = join("\t", keys %ace_wbg_keys);
  print "EMAIL KEYS : $ace_wbg_keys<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_wbg_keys\" VALUE=\"$ace_wbg_keys\">\n";
					# pass the secondary ace_wbg_keys in tabbed form
  my $ace_ace_keys = join("\t", keys %ace_ace_keys);
  print "EMAIL KEYS : $ace_ace_keys<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_ace_keys\" VALUE=\"$ace_ace_keys\">\n";
					# pass the secondary ace_ace_keys in tabbed form

  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Group !\"><BR><BR>\n";
  print "</FORM>\n";		# close compare form, encompass ace, wbgs, and aces
} # sub compareAce

  # sorters
sub by_ace_ace_keys_value {		# sort from highest to lowest by value
  $ace_ace_keys{$b} <=> $ace_ace_keys{$a}
} # sub by_ace_ace_keys_value

sub by_ace_wbg_keys_value {		# sort from highest to lowest by value
  $ace_wbg_keys{$b} <=> $ace_wbg_keys{$a}
} # sub by_ace_wbg_keys_value
  # sorters

  # get ace by email
sub getAceEmailByAceKey {
  my $ace_key = shift;
  my $result = '';
  $result = $conn->exec( "SELECT * FROM ace_email WHERE joinkey = '$ace_key';" );
  my @row;
  my %ace_emails;
  while (@row = $result->fetchrow) {
    my $email = lc($row[1]);
    if ($email) {
      $ace_emails{$email}++;
    } 
  } # while (@row = $result->fetchrow)
  return %ace_emails;
} # sub getAceEmailByAceKey

sub getWbgByAceEmail {
  my %ace_emails = @_;
  foreach my $ace_email (sort keys %ace_emails) { 
    my ($username, $domain) = $ace_email =~ m/(.*)@(.*\..*)/;
# print "ACE EMAIL : $username $domain<BR>\n";
    my $result = $conn->exec( "SELECT * FROM wbg_email WHERE wbg_email ~ '$username' AND wbg_email ~ '$domain';" );
    my $goodness_level = '5';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
        unless ($ace_wbg_keys{$row[0]}) {				# if value is new
          $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_wbg_keys{$row[0]})			# if not new
          unless ($ace_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

    $result = $conn->exec( "SELECT * FROM wbg_email WHERE wbg_email ~ '$username';" );
    $goodness_level = '3';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_wbg_keys{$row[0]}) {				# if value is new
          $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_wbg_keys{$row[0]})			# if not new
          unless ($ace_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

  } # foreach my %ace_email (sort keys %ace_emails)
} # sub getWbgByAceEmail

sub getAceByAceEmail {
  my ($ace_key, %ace_emails) = @_;
  foreach my $ace_email (sort keys %ace_emails) {
    my ($username, $domain) = $ace_email =~ m/(.*)@(.*\..*)/;

    my $result = $conn->exec( "SELECT * FROM ace_email WHERE ace_email ~ '$username' AND ace_email ~ '$domain' AND joinkey <> '$ace_key';" );
    my $goodness_level = '5';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
        unless ($ace_ace_keys{$row[0]}) {				# if value is new
          $ace_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_ace_keys{$row[0]})			# if not new
          unless ($ace_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

    $result = $conn->exec( "SELECT * FROM ace_email WHERE ace_email ~ '$username' AND joinkey <> '$ace_key';" );
    $goodness_level = '3';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_ace_keys{$row[0]}) {				# if value is new
          $ace_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_ace_keys{$row[0]})			# if not new
          unless ($ace_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

  } # foreach my $ace_email (sort keys %ace_emails)
} # sub getAceByAceEmail
  # get ace by email

  # get ace by last
sub getAceLastByAceKey {
  my $ace_key = shift;
  my $result = '';
  $result = $conn->exec( "SELECT * FROM ace_name WHERE joinkey = '$ace_key';" );
  my @row;
  my %ace_lasts;
  while (@row = $result->fetchrow) {
    my $lastname = '';
    if ( $row[1] =~ m/[^a-zA-Z_\']([a-zA-Z_\']*)$/ ) {
      ($lastname) = $row[1] =~ m/[^a-zA-Z_\']([a-zA-Z_\']*)$/;	# get the full lastname from row data
    }
    if ($lastname) { 				# if exists
      $lastname =~ s/_/ /g;
      $ace_lasts{$lastname}++;			# put in hash to filter doubles
      if ($lastname =~ m/[^a-zA-Z\']([a-zA-Z\']*)$/) {
						# get the last word of the lastname from the row data
        ($lastname) = $row[1] =~ m/[^a-zA-Z\']([a-zA-Z\']*)$/;	
        $ace_lasts{$lastname}++;		# put in hash to filter doubles
      } # if ($lastname =~ m/[^a-zA-Z\']([a-zA-Z\']*)$/) 
    } else { # if ($lastname)			# if no lastname, get from author
      $result = $conn->exec( "SELECT * FROM ace_author WHERE joinkey = '$ace_key';" );
      while (@row = $result->fetchrow) {
        my ($lastname) = $row[1] =~ m/([a-zA-Z\']*)[^a-zA-Z\'].*$/;	
						# get the lastname from the row data
        if ($lastname) {			# if found now
          $ace_lasts{$lastname}++;		# put in hash to filter doubles
        } else {				# not found, print error
          print "<font color=blue>ERROR : No last name matched for $ace_key</font><BR>\n";
        } # if ($lastname)
      } # while (@row = $result->fetchrow)
    } # else # if ($lastname)
  } # while (@row = $result->fetchrow)
  return %ace_lasts;
} # sub getAceLastByAceKey

sub getWbgByAceLast {				# also check wbg middlenames in case it's wrong
  my %ace_lasts = @_;
  foreach my $ace_last (sort keys %ace_lasts) {
      # check proper last names
    my $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE wbg_lastname ~ '$ace_last';" );
    my $goodness_level = '2';					# only last name found
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_wbg_keys{$row[0]}) {			# if value is new
          $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_wbg_keys{$row[0]})		# if not new
          unless ($ace_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

      # check middlenames that may be wrong
    $result = $conn->exec( "SELECT * FROM wbg_middlename WHERE wbg_middlename ~ '$ace_last';" );
    $goodness_level = '1';					# only middle name found as last name
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_wbg_keys{$row[0]}) {			# if value is new
          $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_wbg_keys{$row[0]})		# if not new
          unless ($ace_wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $ace_last (@ace_lasts)
} # sub getWbgByAceLast 

sub getAceByAceLast {
  my ($ace_key, %ace_lasts) = @_;
  foreach my $ace_last (sort keys %ace_lasts) {
    my $result = $conn->exec( "SELECT * FROM ace_author WHERE ace_author ~ '$ace_last' AND joinkey <> '$ace_key';" );
    my $goodness_level = '2';				# only last name found
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_ace_keys{$row[0]}) {			# if value is new
          $ace_ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_ace_keys{$row[0]})		# if not new
          unless ($ace_ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $ace_last (@ace_lasts)
} # sub getAceByAceLast 
  # get ace by last
  # ACE #

#### compare ####


#### display ####

sub numerically { $a <=> $b }			# sort numerically

sub formAceOrWbgDate {			# make the frontpage
  print "<TABLE border=1 cellspacing=2>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person.cgi\">\n";
  print "<TR><TD>Ace</TD><TD><INPUT NAME=\"ace_list\" TYPE=\"checkbox\" VALUE=\"yes\"></TD></TR>\n";
  print "<TR><TD>Wbg</TD><TD><INPUT NAME=\"wbg_list\" TYPE=\"checkbox\" VALUE=\"yes\"></TD></TR>\n";
  print "<TR><TD>Start Date</TD><TD><INPUT NAME=\"start_date\" VALUE=\"$start_date\" SIZE=40></TD></TR>\n";
  print "<TR><TD>End Date</TD><TD><INPUT NAME=\"end_date\" VALUE=\"$end_date\" SIZE=40></TD></TR>\n";
  print "<TR><TD><INPUT NAME=\"full_or_new\" TYPE=\"radio\" CHECKED VALUE=\"full\">full</TD>\n";
  print "<TD><INPUT NAME=\"full_or_new\" TYPE=\"radio\" VALUE=\"new\">new</TD></TR>\n";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pick !\"></TD>";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub formAceOrWbgDate

  # WBG
sub pgShowRecentWbg {		# make a listing and display wbg keys changed since start_date
  my $full_or_new = shift;
  my @recent_wbg = &getRecentWbgKeys($full_or_new);
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>Compare</TD></TR>\n";
  foreach (@recent_wbg) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person.cgi\">\n";
    my $wbg_key = 'wbg' . $_;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_key\" VALUE=\"$wbg_key\">\n";
    print "<TR>";
    print "<TD>$wbg_key</TD>";
    &pgShowHtmlWbgDataFromKey($wbg_key);
    print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Compare !\"></TD>";
    print "</TR>\n";
    print "</FORM>\n";
  } # foreach (@recent_wbg)
  print "</TABLE>\n";
} # sub pgShowRecentWbg

sub getRecentWbgKeys {		# get wbg keys given date
  my $full_or_new = shift;
  my %recent_wbg;
  foreach (@wbg_tables) {
    my $result = $conn->exec( "SELECT * FROM $_ WHERE wbg_timestamp > '$start_date' AND wbg_timestamp < '$end_date';" );
    while (my @row = $result->fetchrow) {
      my $push_flag = 1;	# push values by default
      my $wbg_key = $row[0];
      if ($full_or_new eq 'full') { 
        $push_flag = 1;	# if getting all values, push (not needed)
      } elsif ($full_or_new eq 'new') { 
        my $result = $conn->exec( "SELECT * FROM wbg_grouped WHERE joinkey = '$wbg_key';" );
		# this returns a value, but if no entry won't return something 
		# that will loop in the following while loop
        while (my @row = $result->fetchrow) {
          if ($row[1] eq 'YES') { $push_flag = 0; }	# if already grouped under new, don't push
          else { $push_flag = 1; }			# if not already grouped under new, push
        } # while (my @row = $result->fetchrow)
      } else { print "<font color=blue>ERROR : Not a valid choice for full or new</font><BR>\n"; }
      if ($push_flag) {	# if meant to push, push it
        $wbg_key =~ s/^wbg//;
        push @{ $recent_wbg{$wbg_key} }, $row[1];
      } # if ($push_flag)
    } # while (@row = $result->fetchrow)
  } # foreach (@wbg_tables)
  print scalar(keys %recent_wbg) . " wbg entries updated between $start_date and $end_date.<BR>\n";
  return sort numerically keys %recent_wbg;	# put in array to show a select number
} # sub getRecentWbgKeys

sub pgShowHtmlWbgDataFromKey {	# show in table form the data from a wbg key
  my $wbg_key = shift;
  my @wbg_html_table = qw(wbg_lastname wbg_firstname);
  foreach my $wbg_table (@wbg_html_table) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    print "<TD>";
    while (my @row = $result->fetchrow) {
      if($row[1]) { print "$row[1]<BR>"; }
    } # while (@row = $result->fetchrow)
    print "</TD>";
  } # foreach (@wbg_html_table)
  my $result = $conn->exec( "SELECT * FROM wbg_grouped WHERE joinkey = '$wbg_key';" );
  print "<TD>";
  my @row = $result->fetchrow;
  if($row[1]) { print "$row[1]<BR>"; }
  print "</TD>";

  $result = $conn->exec( "SELECT * FROM wbg_groupedwith WHERE joinkey = '$wbg_key';" );
  print "<TD>";
  while (my @row = $result->fetchrow) {
    if ($row[1]) { print "$row[1]<BR>" }
  }
  print "</TD>";
} # sub pgShowHtmlWbgDataFromKey
  # WBG 

  # ACE
sub pgShowRecentAce {		# make a listing and display ace keys changed since start_date
  my $full_or_new = shift;
  my @recent_ace = &getRecentAceKeys($full_or_new);
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>Compare</TD></TR>\n";
  foreach (@recent_ace) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person.cgi\">\n";
    my $ace_key = 'ace' . $_;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_key\" VALUE=\"$ace_key\">\n";
    print "<TR>";
    print "<TD>$ace_key</TD>";
    &pgShowHtmlAceDataFromKey($ace_key);
    print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Compare !\"></TD>";
    print "</TR>\n";
    print "</FORM>\n";
  } # foreach (@recent_ace)
  print "</TABLE>\n";
} # sub pgShowRecentAce

sub getRecentAceKeys {		# get ace keys given date
  my $full_or_new = shift;
  my %recent_ace;
  foreach (@ace_tables) {
    unless ($_ eq 'ace_author') {		# don't check ace_author for time
      my $result = $conn->exec( "SELECT * FROM $_ WHERE ace_timestamp > '$start_date' AND ace_timestamp < '$end_date';" );
      my @row;
      while (@row = $result->fetchrow) {
        my $push_flag = 1;	# push values by default
        my $ace_key = $row[0];
        if ($full_or_new eq 'full') { 
          $push_flag = 1;	# if getting all values, push (not needed)
        } elsif ($full_or_new eq 'new') { 
          my $result = $conn->exec( "SELECT * FROM ace_grouped WHERE joinkey = '$ace_key';" );
				# this returns a value, but if no entry won't return something 
				# that will loop in the following while loop
          while (my @row = $result->fetchrow) {
            if ($row[1] eq 'YES') { $push_flag = 0; }	# if already grouped under new, don't push
            else { $push_flag = 1; }			# if not already grouped under new, push
          } # while (my @row = $result->fetchrow)
        } else { print "<font color=blue>ERROR : Not a valid choice for full or new</font><BR>\n"; }
        if ($push_flag) {	# if meant to push, push it
          $ace_key =~ s/^ace//;
          push @{ $recent_ace{$ace_key} }, $row[1];
        } # if ($push_flag)
      } # while (@row = $result->fetchrow)
    } # unless ($_ eq 'ace_author)
  } # foreach (@ace_tables)
  print scalar(keys %recent_ace) . " ace entries updated between $start_date and $end_date.<BR>\n";
  return sort numerically keys %recent_ace;	# put in array to show a select number
} # sub getRecentAceKeys

sub pgShowHtmlAceDataFromKey {	# show in table form the data from an ace key
  my $ace_key = shift;
  my @ace_html_table = qw(ace_author ace_name);
  foreach my $ace_table (@ace_html_table) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    print "<TD>";
    while (my @row = $result->fetchrow) {
      if($row[1]) { print "$row[1]<BR>"; }
    } # while (@row = $result->fetchrow)
    print "</TD>";
  } # foreach (@ace_html_table)
  my $result = $conn->exec( "SELECT * FROM ace_grouped WHERE joinkey = '$ace_key';" );
  print "<TD>";
  my @row = $result->fetchrow;
  if($row[1]) { print "$row[1]<BR>"; }
  print "</TD>";

  $result = $conn->exec( "SELECT * FROM ace_groupedwith WHERE joinkey = '$ace_key';" );
  print "<TD>";
  while (my @row = $result->fetchrow) {
    if ($row[1]) { print "$row[1]<BR>" }
  }
  print "</TD>";
} # sub pgShowHtmlAceDataFromKey
  # ACE

#### display ####


####  display from key ####

sub displayAceDataFromKey {		# show all ace data from a given key in multiline table
#   print "DISPLAY ACE DATA<BR>\n";
  my ($ace_key, $color, $checked) = @_;
  if ($color eq '5') { $color = 'purple'; }
  elsif ($color eq '4') { $color = 'blue'; }
  elsif ($color eq '3') { $color = 'green'; }
  elsif ($color eq '2') { $color = 'yellow'; }
  elsif ($color eq '1') { $color = 'orange'; }
  else { $color = 'white'; }
#   print "<TABLE>\n";
  print "<TABLE bgcolor=\"$color\" border=1 cellspacing=2>\n";
  if ($checked) { 			# if it's the main one, ie, checked have the checkbox checked
    print "<INPUT NAME=\"$ace_key\" TYPE=\"checkbox\" CHECKED VALUE=\"yes\">$ace_key\n";
  } else { 				# if it's not the main one, don't default check it
    print "<INPUT NAME=\"$ace_key\" TYPE=\"checkbox\" VALUE=\"yes\">$ace_key\n";
  } # if ($checked)
  foreach my $ace_table (@ace_tables) {	# show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$ace_table</TD>";
        foreach (@row) { print "<TD>$_</TD>"; }
#         foreach (@row) { if($row[1]) { print "<TD>$ace_table : $_</TD>"; } }
        print "</TR>";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print "</TABLE><BR><BR>\n";
#   print "DISPLAY ACE DATA<BR>\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {		# show all wbg data from a given key in multiline table
  my ($wbg_key, $color, $checked) = @_;
    # set background table colors
#   if ($color eq '5') { $color = '#ffff00'; }
#   elsif ($color eq '4') { $color = '#dddd00'; }
#   elsif ($color eq '3') { $color = '#bbbb00'; }
#   elsif ($color eq '2') { $color = '#999900'; }
#   else { $color = '#555500'; }
  if ($color eq '5') { $color = 'purple'; }
  elsif ($color eq '4') { $color = 'blue'; }
  elsif ($color eq '3') { $color = 'green'; }
  elsif ($color eq '2') { $color = 'yellow'; }
  elsif ($color eq '1') { $color = 'orange'; }
  else { $color = 'white'; }
#   print "<TABLE>\n";
  print "<TABLE bgcolor=\"$color\" border=1 cellspacing=2>\n";
  if ($checked) {
    print "<INPUT NAME=\"$wbg_key\" TYPE=\"checkbox\" CHECKED VALUE=\"yes\">$wbg_key\n";
  } else { 
    print "<INPUT NAME=\"$wbg_key\" TYPE=\"checkbox\" VALUE=\"yes\">$wbg_key\n";
  } # else # if ($checked)
  foreach my $wbg_table (@wbg_tables) {	# go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) { 
        print "<TR><TD>$wbg_table</TD>"; 
#       foreach (@row) { if($row[1]) { print "<TD>$wbg_table : $_</TD>"; } }
        foreach (@row) { print "<TD>$_</TD>"; }
        print "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $wbg_table (@wbg_tables)
  print "</TABLE><BR><BR>\n";
} # sub displayWbgDataFromKey

####  display from key ####


#### group ####
  # REMOVE COMMENTING of INSERT INTO statements for database to do stuff
  # change OUTFILE

sub group {		# make groupings, print to outfile, postgres tables, and html tables
  my $outfile = "/home/postgres/work/authorperson/groupfile";
#   my $outfile = "/home/postgres/work/authorperson/tempgroupfile";
  open(OUT, ">>$outfile") or die "Cannot open $outfile : $!";
  my $oop;
  my @ace_wbg_keys; my @ace_ace_keys;		# searching main ace, matching wbg and ace keys
  my @wbg_ace_keys; my @wbg_wbg_keys;		# searching main wbg, matching ace and wbg keys
  my $main_key;					# main key to check everything against
  print "<TABLE border=1 cellspacing=2>\n";

    # group wbg stuff (by main being wbg)  
  if ( $query->param('wbg_key') ) { 		# get the main wbg key
    $oop = $query->param('wbg_key');
    my $wbg_key = &Untaint($oop);		# wbg key, same as main for the wbg vs wbg case
    $main_key = &Untaint($oop);		# get the main key 
    print OUT "MAIN $main_key wbg_grouped YES<BR>\n"; 
    my $result = $conn->exec( "INSERT INTO wbg_grouped VALUES ('$main_key', 'YES');" );
    print "<TR><TD>$main_key</TD><TD>wbg_grouped</TD><TD>YES</TD><TR>\n"; 
  } # if ( $query->param('wbg_key') )

  if ( $query->param('wbg_ace_keys') ) { 	# get the ace keys matching main wbg key
    $oop = $query->param('wbg_ace_keys');
    my $wbg_ace_keys = &Untaint($oop);
    @wbg_ace_keys = split(/\t/, $wbg_ace_keys);
  } # if ( $query->param('wbg_ace_keys') )
  foreach my $ace_key (@wbg_ace_keys) {		# for each of those keys, mark as appropriate
    my $checked = &getWbgKeyParam($ace_key);		# get clicked status

    print OUT "MAIN $main_key wbg_comparedvs SECONDARY $ace_key\n"; 
    print "<TR><TD>$main_key</TD><TD>wbg_comparedvs</TD><TD>$ace_key</TD><TR>\n";
    my $result = $conn->exec( "INSERT INTO wbg_comparedvs VALUES ('$main_key', '$ace_key');" );

    print OUT "SECONDARY $ace_key ace_comparedby MAIN $main_key\n";
    print "<TR><TD>$ace_key</TD><TD>ace_comparedby</TD><TD>$main_key</TD><TR>\n";
    $result = $conn->exec( "INSERT INTO ace_comparedby VALUES ('$ace_key', '$main_key');" );

    if ($checked eq 'yes') { 
      print OUT "MAIN $main_key wbg_groupedwith SECONDARY $ace_key\n"; 
      print "<TR><TD>$main_key</TD><TD>wbg_groupedwith</TD><TD>$ace_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_groupedwith VALUES ('$main_key', '$ace_key');" );

      print OUT "SECONDARY $ace_key ace_groupedwith MAIN $main_key\n";
      print "<TR><TD>$ace_key</TD><TD>ace_groupedwith</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_groupedwith VALUES ('$ace_key', '$main_key');" );
    } else { # if ($checked eq 'yes')
      print OUT "MAIN $main_key wbg_rejectedvs SECOND $ace_key\n"; 
      print "<TR><TD>$main_key</TD><TD>wbg_rejectedvs</TD><TD>$ace_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_rejectedvs VALUES ('$main_key', '$ace_key');" );

      print OUT "SECONDARY $ace_key ace_rejectedby MAIN $main_key\n";
      print "<TR><TD>$ace_key</TD><TD>ace_rejectedby</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_rejectedby VALUES ('$ace_key', '$main_key');" );
    } # else # if ($checked eq 'yes')
  } # foreach my $ace_key (@wbg_ace_keys)

  if ( $query->param('wbg_wbg_keys') ) {	# get the wbg keys matching main wbg key
    $oop = $query->param('wbg_wbg_keys');
    my $wbg_wbg_keys = &Untaint($oop);
    @wbg_wbg_keys = split(/\t/, $wbg_wbg_keys);
  } # if ( $query->param('wbg_wbg_keys') )
  foreach my $wbg_key (@wbg_wbg_keys) {		# for each of those keys, mark as appropriate
    my $checked = &getAceKeyParam($wbg_key);

    print OUT "MAIN $main_key wbg_comparedvs SECONDARY $wbg_key\n"; 
    print "<TR><TD>$main_key</TD><TD>wbg_comparedvs</TD><TD>$wbg_key</TD><TR>\n";
    my $result = $conn->exec( "INSERT INTO wbg_comparedvs VALUES ('$main_key', '$wbg_key');" );

    print OUT "SECONDARY $wbg_key wbg_comparedby MAIN $main_key\n";
    print "<TR><TD>$wbg_key</TD><TD>wbg_comparedby</TD><TD>$main_key</TD><TR>\n";
    $result = $conn->exec( "INSERT INTO wbg_comparedby VALUES ('$wbg_key', '$main_key');" );

    if ($checked eq 'yes') { 
      print OUT "MAIN $main_key wbg_groupedwith SECONDARY $wbg_key\n"; 
      print "<TR><TD>$main_key</TD><TD>wbg_groupedwith</TD><TD>$wbg_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_groupedwith VALUES ('$main_key', '$wbg_key');" );

      print OUT "SECONDARY $wbg_key wbg_groupedwith MAIN $main_key\n";
      print "<TR><TD>$wbg_key</TD><TD>wbg_groupedwith</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_groupedwith VALUES ('$wbg_key', '$main_key');" );
    } else { # if ($checked eq 'yes')
      print OUT "MAIN $main_key wbg_rejectedvs SECOND $wbg_key\n"; 
      print "<TR><TD>$main_key</TD><TD>wbg_rejectedvs</TD><TD>$wbg_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_rejectedvs VALUES ('$main_key', '$wbg_key');" );

      print OUT "SECONDARY $wbg_key wbg_rejectedby MAIN $main_key\n";
      print "<TR><TD>$wbg_key</TD><TD>wbg_rejectedby</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_rejectedby VALUES ('$wbg_key', '$main_key');" );
    } # else # if ($checked eq 'yes')
  } # foreach my $wbg_key (@wbg_wbg_keys)
    # group wbg stuff (by main being wbg)  

    # group ace stuff (by main being ace)  
  if ( $query->param('ace_key') ) { 		# get the main ace key
    $oop = $query->param('ace_key');
    my $ace_key = &Untaint($oop);		# ace key, same as main for the ace vs wbg case
    $main_key = &Untaint($oop);			# get the main key 
    print OUT "MAIN $main_key ace_grouped YES<BR>\n"; 
    my $result = $conn->exec( "INSERT INTO ace_grouped VALUES ('$main_key', 'YES');" );
    print "<TR><TD>$main_key</TD><TD>ace_grouped</TD><TD>YES</TD><TR>\n"; 
  } # if ( $query->param('ace_key') )

  if ( $query->param('ace_wbg_keys') ) { 	# get the wbg keys matching main ace key
    $oop = $query->param('ace_wbg_keys');
    my $ace_wbg_keys = &Untaint($oop);
    @ace_wbg_keys = split(/\t/, $ace_wbg_keys);
  } # if ( $query->param('ace_wbg_keys') )
  foreach my $wbg_key (@ace_wbg_keys) {		# for each of those keys, mark as appropriate
    my $checked = &getWbgKeyParam($wbg_key);	# get clicked status

    print OUT "MAIN $main_key ace_comparedvs SECONDARY $wbg_key\n"; 
    print "<TR><TD>$main_key</TD><TD>ace_comparedvs</TD><TD>$wbg_key</TD><TR>\n";
    my $result = $conn->exec( "INSERT INTO ace_comparedvs VALUES ('$main_key', '$wbg_key');" );

    print OUT "SECONDARY $wbg_key wbg_comparedby MAIN $main_key\n";
    print "<TR><TD>$wbg_key</TD><TD>wbg_comparedby</TD><TD>$main_key</TD><TR>\n";
    $result = $conn->exec( "INSERT INTO wbg_comparedby VALUES ('$wbg_key', '$main_key');" );

    if ($checked eq 'yes') { 
      print OUT "MAIN $main_key ace_groupedwith SECONDARY $wbg_key\n"; 
      print "<TR><TD>$main_key</TD><TD>ace_groupedwith</TD><TD>$wbg_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_groupedwith VALUES ('$main_key', '$wbg_key');" );

      print OUT "SECONDARY $wbg_key wbg_groupedwith MAIN $main_key\n";
      print "<TR><TD>$wbg_key</TD><TD>wbg_groupedwith</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_groupedwith VALUES ('$wbg_key', '$main_key');" );
    } else { # if ($checked eq 'yes')
      print OUT "MAIN $main_key ace_rejectedvs SECOND $wbg_key\n"; 
      print "<TR><TD>$main_key</TD><TD>ace_rejectedvs</TD><TD>$wbg_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_rejectedvs VALUES ('$main_key', '$wbg_key');" );

      print OUT "SECONDARY $wbg_key wbg_rejectedby MAIN $main_key\n";
      print "<TR><TD>$wbg_key</TD><TD>wbg_rejectedby</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO wbg_rejectedby VALUES ('$wbg_key', '$main_key');" );
    } # else # if ($checked eq 'yes')
  } # foreach my $wbg_key (@ace_wbg_keys)

  if ( $query->param('ace_ace_keys') ) {	# get the ace keys matching main ace key
    $oop = $query->param('ace_ace_keys');
    my $ace_ace_keys = &Untaint($oop);
    @ace_ace_keys = split(/\t/, $ace_ace_keys);
  } # if ( $query->param('ace_ace_keys') )
  foreach my $ace_key (@ace_ace_keys) {		# for each of those keys, mark as appropriate
    my $checked = &getAceKeyParam($ace_key);

    print OUT "MAIN $main_key ace_comparedvs SECONDARY $ace_key\n"; 
    print "<TR><TD>$main_key</TD><TD>ace_comparedvs</TD><TD>$ace_key</TD><TR>\n";
    my $result = $conn->exec( "INSERT INTO ace_comparedvs VALUES ('$main_key', '$ace_key');" );

    print OUT "SECONDARY $ace_key ace_comparedby MAIN $main_key\n";
    print "<TR><TD>$ace_key</TD><TD>ace_comparedby</TD><TD>$main_key</TD><TR>\n";
    $result = $conn->exec( "INSERT INTO ace_comparedby VALUES ('$ace_key', '$main_key');" );

    if ($checked eq 'yes') { 
      print OUT "MAIN $main_key ace_groupedwith SECONDARY $ace_key\n"; 
      print "<TR><TD>$main_key</TD><TD>ace_groupedwith</TD><TD>$ace_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_groupedwith VALUES ('$main_key', '$ace_key');" );

      print OUT "SECONDARY $ace_key ace_groupedwith MAIN $main_key\n";
      print "<TR><TD>$ace_key</TD><TD>ace_groupedwith</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_groupedwith VALUES ('$ace_key', '$main_key');" );
    } else { # if ($checked eq 'yes')
      print OUT "MAIN $main_key ace_rejectedvs SECOND $ace_key\n"; 
      print "<TR><TD>$main_key</TD><TD>ace_rejectedvs</TD><TD>$ace_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_rejectedvs VALUES ('$main_key', '$ace_key');" );

      print OUT "SECONDARY $ace_key ace_rejectedby MAIN $main_key\n";
      print "<TR><TD>$ace_key</TD><TD>ace_rejectedby</TD><TD>$main_key</TD><TR>\n";
      $result = $conn->exec( "INSERT INTO ace_rejectedby VALUES ('$ace_key', '$main_key');" );
    } # else # if ($checked eq 'yes')
  } # foreach my $ace_key (@ace_ace_keys)
    # group ace stuff (by main being ace)  

  print "</TABLE>\n";
  print OUT "\n"; 		# divider
  close (OUT) or die "Cannot close $outfile : $!";
} # sub group

sub getWbgKeyParam {			# for a given wbg_key, get whether it was clicked
  my $wbg_key = shift;  
  my $oop;
  my $wbg_key_data = 'no';		# default, assume not checked unless found clicked later
  if ( $query->param("$wbg_key") ) {
    $oop = $query->param("$wbg_key");
    $wbg_key_data = &Untaint($oop);	# get the clickness value if clicked
  } # if ( $query->param('$wbg_key') )
  return $wbg_key_data;			# pass back status
} # sub getWbgKeyParam

sub getAceKeyParam {			# for a given ace_key, get whether it was clicked
  my $ace_key = shift;  
  my $oop;
  my $ace_key_data = 'no';		# default, assume not checked unless found clicked later
  if ( $query->param("$ace_key") ) {
    $oop = $query->param("$ace_key");
    $ace_key_data = &Untaint($oop);	# get the clickness value if clicked
  } # if ( $query->param('$ace_key') )
  return $ace_key_data;			# pass back status
} # sub getAceKeyParam


#### group ####


#####  pgGetRecentAce ####

sub pgGetRecentAce {				# get a given number of recent entries
    # find the recent stuff, put in hash
  my @recent_ace = &getRecentAceKeys();

    # go through a few and get values out
  for my $i ( 0 .. 2 ) {			# pick how many ace to go through
    my $ace_key = 'ace' . $recent_ace[$i];
    &displayAceDataFromKey($ace_key);

      # find the lastnames from the ace names or authors from the found keys
    my %ace_lasts = &getAceLastByAceKey($ace_key);

      # take the found ace lastnames and get the wbg matches
    &getWbgByAceLast(%ace_lasts);
  } # for my $i ( 0 .. 2 )
} # sub pgGetRecentAce

#####  pgGetRecentAce ####




sub pgGetWbgKey {
  my $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE wbg_timestamp > '$start_date';" );
  my @row;
  my @keys;
  print "<TABLE>\n";
  while (@row = $result->fetchrow) {
    print "<TR>\n";
    my $wbgkey = $row[0];
    my $wbglast = $row[1];
    print "<TD>$wbgkey</TD><TD>$wbglast</TD>\n";
    &pgGetAceMatch($wbgkey, $wbglast);
    print "</TR>\n";
  } # while (@row = $result->fetchrow)
  print "</TABLE>\n";
} # sub pgGetWbgKey

sub pgGetAceMatch {
  my ($wbgkey, $wbglast) = @_;
  my $result = $conn->exec( "SELECT * FROM ace_name WHERE ace_name ~ '$wbglast';" );
  my @row;
#   print "<TABLE>\n";
  while (@row = $result->fetchrow) {
#     print "<TR><TD>$wbgkey</TD><TD>$wbglast</TD>";
    foreach (@row) { 
      print "<TD>$_</TD>\n";
    } # foreach (@row)
#     print "<\TR>\n";
  } # while (@row = $result->fetchrow)
#   print "</TABLE>\n";
} # sub pgGetAceMatch 


sub pgRunOne {
  my $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE wbg_timestamp > '$start_date';" );
  my @row;
  print "<TABLE>\n";
  while (@row = $result->fetchrow) { 
    print "<TR>";
    foreach (@row) { 
      print "<TD>ROW : $_</TD>\n";
    } # foreach (@row)
    print "</TR>\n";
  } # while (@row = $result->fetchrow)
  print "</TABLE>\n";
} # sub pgRunOne


#### OLD STUFF ####


sub GetDate {                           # begin GetDate
  my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
                                        # set array of days
  my @months = qw(January February March April May June 
          July August September October November December);
                                        # set array of months
  my $time = time;                   	# set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                  	# get right month
  my $shortdate = "$mday/$sam/$year";   # get final date
  my $ampm = "AM";                   	# fiddle with am or pm
  if ($hour eq 12) { $ampm = "PM"; }    # PM if noon
  if ($hour eq 0) { $hour = "12"; }     # AM if midnight
  if ($hour > 12) {               	# get hour right from 24
    $hour = ($hour - 12);
    $ampm = "PM";           		# reset PM if after noon
  }
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  $year = 1900+$year;             	# get right year in 4 digit form
  my $todaydate = "$days[$wday], $mday $months[$mon] $year";
                                        # set current date
  my $date = $todaydate . " $hour\:$min $ampm";
                                        # set final date
  return $date;
} # sub GetDate                         # end GetDate

sub Untaint {
  my $tainted = shift;
  my $untainted;
  if ($tainted eq "") {
    $untainted = "";
  } else { # if ($tainted eq "")
    $tainted =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*(){}[\]+=!~|' \t\n\r\f]//g;
    if ($tainted =~ m/^([\w\-.,;:?\/\\@#\$\%&\^*(){}[\]+=!~|' \t\n\r\f]+)$/) {
      $untainted = $1;
    } else {
      die "Bad data in $tainted";
    }
  } # else # if ($tainted eq "")
  return $untainted;
} # sub Untaint 

sub PrintHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">
  
<HEAD>
EndOfText
  print "<TITLE>Person Form</TITLE>";
					# get user's name 
  print <<"EndOfText";
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
<CENTER><A HREF="http://minerva.caltech.edu/~postgres/cgi-bin/sitemap.cgi">Site Map</A></CENTER>
<CENTER><A HREF="http://minerva.caltech.edu/~postgres/cgi-bin/person_doc.txt">Documentation</A></CENTER>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

