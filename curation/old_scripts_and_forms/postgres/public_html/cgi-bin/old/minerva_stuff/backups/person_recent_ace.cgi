#!/usr/bin/perl -w
# 
# current version 2002 01 11 11:38 gets entries updated since $recent_date.
# user chooses one to ``Compare !'' and the script checks their last name and 
# email addresses against wbg_tables in postgres, and if matching returns a 
# priority (goodness) value depending on likelyhood of match.  once all wbg 
# keys have a value, these are sorted (highest -> lowest) and displayed with 
# the proper color background.  user checks those that match, and results of
# matchness is written into the match-related wbg and ace tables for those keys.  
#
# to do : check against ace tables as well as wbg tables.

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

my $displayList = 1;			# non-zero to show list of recent ace entries
my $recent_date = '2001-06-01';		# date to compare against to check recency

my %wbg_keys;			# wbg keys that match an ace value, value of hash is higher the 
				# more likely it is to be a match
my %ace_keys;			# ace keys that match an ace value (excluding itself), 
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
  if ($displayList) {
    &pgShowRecentAce();
#   &pgGetRecentAce();
  } # unless ($displayList)
} # sub display

sub process {
  my $action;
  unless ($action = $query->param('action') ) { 
    $action = 'none';
  }

  if ($action eq 'Compare !') {
    $displayList = 0;
    &compare();				# get stuff to select among to make groups
  } # if ($action eq 'Compare !')

  elsif ($action eq 'Group !') {
    $displayList = 0;
    &group();
  } # elsif ($action eq 'Group !')

  elsif ($action eq 'none') { 1; }

  else { print "NOT A VALID ACTION : $action, contact the author.<BR>\n"; }
} # sub process


#### compare ####

sub compare {				# make comparisons to present to make groups
  my $oop;
  if ( $query->param('ace_key') ) { 
    $oop = $query->param('ace_key');
    my $main_ace_key = &Untaint($oop);
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person_recent_ace.cgi\">\n";			# compare form, encompass ace and wbgs
    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Group !\"><BR><BR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_key\" VALUE=\"$main_ace_key\">\n";
					# pass the main ace_key

      # display the data from the ace key
    &displayAceDataFromKey($main_ace_key, '0');	# comment out to display for each entry

    my %ace_emails = &getAceEmailByAceKey($main_ace_key);
    &getWbgByAceEmail(%ace_emails);
    &getAceByAceEmail($main_ace_key, %ace_emails);

    my %ace_lasts = &getAceLastByAceKey($main_ace_key);
    &getWbgByAceLast(%ace_lasts);
    &getAceByAceLast($main_ace_key, %ace_lasts);

    foreach my $wbg_key (sort by_wbg_keys_value keys %wbg_keys) {
      &displayWbgDataFromKey($wbg_key, $wbg_keys{$wbg_key});;
      &displayAceDataFromKey($main_ace_key, '0');	# comment out to display only once
    } # foreach (keys %wbg_keys)

    foreach my $ace_key (sort by_ace_keys_value keys %ace_keys) {
      &displayAceDataFromKey($ace_key, $ace_keys{$ace_key});;
      &displayAceDataFromKey($main_ace_key, '0');	# comment out to display only once
    } # foreach (keys %main_ace_keys)

    my $wbg_keys = join("\t", keys %wbg_keys);
    print "EMAIL KEYS : $wbg_keys<BR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"wbg_keys\" VALUE=\"$wbg_keys\">\n";
					# pass the secondary wbg_keys in tabbed form
    my $ace_keys = join("\t", keys %ace_keys);
    print "EMAIL KEYS : $ace_keys<BR>\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"ace_keys\" VALUE=\"$ace_keys\">\n";
					# pass the secondary ace_keys in tabbed form


    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Group !\"><BR><BR>\n";
    print "</FORM>\n";		# close compare form, encompass ace and wbgs
  } # if ( $query->param('ace_key') )
} # sub compare

sub by_ace_keys_value {		# sort from highest to lowest by value
  $ace_keys{$b} <=> $ace_keys{$a}
} # sub by_ace_keys_value

sub by_wbg_keys_value {		# sort from highest to lowest by value
  $wbg_keys{$b} <=> $wbg_keys{$a}
} # sub by_wbg_keys_value

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
        unless ($wbg_keys{$row[0]}) {				# if value is new
          $wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_keys{$row[0]})			# if not new
          unless ($wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

    $result = $conn->exec( "SELECT * FROM wbg_email WHERE wbg_email ~ '$username';" );
    $goodness_level = '3';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_keys{$row[0]}) {				# if value is new
          $wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_keys{$row[0]})			# if not new
          unless ($wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_keys{$row[0]})
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
        unless ($ace_keys{$row[0]}) {				# if value is new
          $ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_keys{$row[0]})			# if not new
          unless ($ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

    $result = $conn->exec( "SELECT * FROM ace_email WHERE ace_email ~ '$username' AND joinkey <> '$ace_key';" );
    $goodness_level = '3';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_keys{$row[0]}) {				# if value is new
          $ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_keys{$row[0]})			# if not new
          unless ($ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)

  } # foreach my $ace_email (sort keys %ace_emails)
} # sub getAceByAceEmail

sub getAceLastByAceKey {
#   print "GET ACE LAST BY ACE KEY<BR>\n";
  my $ace_key = shift;
  my $result = '';
  $result = $conn->exec( "SELECT * FROM ace_name WHERE joinkey = '$ace_key';" );
  my @row;
  my %ace_lasts;
  while (@row = $result->fetchrow) {
    my ($lastname) = $row[1] =~ m/[^a-zA-Z]([a-zA-Z]*)$/;
    if ($lastname) { 
      $ace_lasts{$lastname}++;		# put in hash to filter doubles
    } else { # if ($lastname)			# if no lastname, get from author
      $result = $conn->exec( "SELECT * FROM ace_author WHERE joinkey = '$ace_key';" );
      while (@row = $result->fetchrow) {
        my ($lastname) = $row[1] =~ m/([a-zA-Z]*)[^a-zA-Z].*$/;
        if ($lastname) {			# if found now
          $ace_lasts{$lastname}++;		# put in hash to filter doubles
        } else {				# not found, print error
          print "<font color=blue>ERROR : No last name matched for $ace_key</font><BR>\n";
        } # if ($lastname)
      } # while (@row = $result->fetchrow)
    } # else # if ($lastname)
  } # while (@row = $result->fetchrow)
#   print "GET ACE LAST BY ACE KEY<BR>\n";
  return %ace_lasts;
} # sub getAceLastByAceKey

sub getWbgByAceLast {
#   print "GET WBG BY ACE LAST<BR>\n";
  my %ace_lasts = @_;
#   my @wbg_keys;			# all wbg_keys (for all ace last names)
  foreach my $ace_last (sort keys %ace_lasts) {
    my $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE wbg_lastname ~ '$ace_last';" );
    my $goodness_level = '2';
    my @row;
    my @wbg_key;		# set of wbg_keys for each ace last name
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($wbg_keys{$row[0]}) {				# if value is new
          $wbg_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($wbg_keys{$row[0]})			# if not new
          unless ($wbg_keys{$row[0]} > $goodness_level) {	# unless higher value
            $wbg_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($wbg_keys{$row[0]} > $goodness_level)
        } # else # unless ($wbg_keys{$row[0]})
      } # if ($row[1])
#       if ($row[1]) { push @wbg_key, $row[0]; push @wbg_keys, $row[0]; }
    } # while (@row = $result->fetchrow)

      # show the data from the matched wbgs
#     foreach my $wbg_key (@wbg_key) {
#       &displayWbgDataFromKey($wbg_key, 'okay');
#     } # foreach (@wbg_key)
  } # foreach my $ace_last (@ace_lasts)
#   return @wbg_keys;
#   print "GET WBG BY ACE LAST<BR>\n";
} # sub getWbgByAceLast 

sub getAceByAceLast {
  my ($ace_key, %ace_lasts) = @_;
  foreach my $ace_last (sort keys %ace_lasts) {
    my $result = $conn->exec( "SELECT * FROM ace_author WHERE ace_author ~ '$ace_last' AND joinkey <> '$ace_key';" );
    my $goodness_level = '2';
    my @row;
    my @ace_key;		# set of ace_keys for each ace last name
    while (@row = $result->fetchrow) {
      if ($row[1]) { 						# if query has value
        unless ($ace_keys{$row[0]}) {				# if value is new
          $ace_keys{$row[0]} = $goodness_level; 		# give it a priority
        } else { # unless ($ace_keys{$row[0]})			# if not new
          unless ($ace_keys{$row[0]} > $goodness_level) {	# unless higher value
            $ace_keys{$row[0]} = $goodness_level; 		# give it the current priority
          } # unless ($ace_keys{$row[0]} > $goodness_level)
        } # else # unless ($ace_keys{$row[0]})
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $ace_last (@ace_lasts)
} # sub getAceByAceLast 

#### compare ####


#### display ####

sub pgShowRecentAce {
  my @recent_ace = &getRecentAceKeys();
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>name</TD><TD>grouped</TD><TD>grouped with</TD><TD>Compare</TD></TR>\n";
  foreach (@recent_ace) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/person_recent_ace.cgi\">\n";
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

sub getRecentAceKeys {
  my %recent_ace;
  foreach (@ace_tables) {
    unless ($_ eq 'ace_author') {		# don't check ace_author for time
      my $result = $conn->exec( "SELECT * FROM $_ WHERE ace_timestamp > '$recent_date';" );
      my @row;
      while (@row = $result->fetchrow) {
        my $ace_key = $row[0];
        $ace_key =~ s/^ace//;
        push @{ $recent_ace{$ace_key} }, $row[1];
      } # while (@row = $result->fetchrow)
    } # unless ($_ eq 'ace_author)
  } # foreach (@ace_tables)
  print scalar(keys %recent_ace) . " ace entries updated since $recent_date.<BR>\n";
  return sort numerically keys %recent_ace;	# put in array to show a select number
} # sub getRecentAceKeys

sub numerically { $a <=> $b }			# sort numerically

sub pgShowHtmlAceDataFromKey {
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

#### display ####


####  display from key ####

sub displayAceDataFromKey {
#   print "DISPLAY ACE DATA<BR>\n";
  my ($ace_key, $color) = @_;
  if ($color eq '5') { $color = 'purple'; }
  elsif ($color eq '4') { $color = 'blue'; }
  elsif ($color eq '3') { $color = 'green'; }
  elsif ($color eq '2') { $color = 'yellow'; }
  elsif ($color eq '1') { $color = 'orange'; }
  else { $color = 'white'; }
#   print "<TABLE>\n";
  print "<TABLE bgcolor=\"$color\" border=1 cellspacing=2>\n";
  print "<INPUT NAME=\"$ace_key\" TYPE=\"checkbox\" VALUE=\"yes\">$ace_key\n";
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

sub displayWbgDataFromKey {
  my ($wbg_key, $color) = @_;
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
  else { $color = 'orange'; }
#   print "<TABLE>\n";
  print "<TABLE bgcolor=\"$color\" border=1 cellspacing=2>\n";
  print "<INPUT NAME=\"$wbg_key\" TYPE=\"checkbox\" VALUE=\"yes\">$wbg_key\n";
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

sub group {
  my $outfile = "/home/postgres/work/authorperson/groupfile";
  open(OUT, ">>$outfile") or die "Cannot open $outfile : $!";
  my $oop;
  my @wbg_keys; my @ace_keys;
  my $main_key;					# main key to check everything against
  print "<TABLE border=1 cellspacing=2>\n";
  if ( $query->param('ace_key') ) { 
    $oop = $query->param('ace_key');
    my $ace_key = &Untaint($oop);		# ace key, same as main for the ace vs wbg case
    $main_key = &Untaint($oop);		# get the main key 
#     print "ACE KEY : $ace_key<BR>\n";
#     print "MAIN $main_key ace_grouped YES<BR>\n"; 
    my $result = $conn->exec( "INSERT INTO ace_grouped VALUES ('$main_key', 'YES');" );
    print "<TR><TD>$main_key</TD><TD>ace_grouped</TD><TD>YES</TD><TR>\n"; 
  } # if ( $query->param('ace_key') )

  if ( $query->param('wbg_keys') ) { 
    $oop = $query->param('wbg_keys');
    my $wbg_keys = &Untaint($oop);
#     print "WBG KEYS : $wbg_keys<BR>\n";
    @wbg_keys = split(/\t/, $wbg_keys);
  } # if ( $query->param('wbg_keys') )
  foreach my $wbg_key (@wbg_keys) {
    my $checked = &getWbgKeyParam($wbg_key);		# get clicked status
#     print "WBG KEY : $wbg_key : $checked<BR>\n";	# print keys and clicked status

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
  } # foreach my $wbg_key (@wbg_keys)

  if ( $query->param('ace_keys') ) {
    $oop = $query->param('ace_keys');
    my $ace_keys = &Untaint($oop);
    @ace_keys = split(/\t/, $ace_keys);
  } # if ( $query->param('ace_keys') )
  foreach my $ace_key (@ace_keys) {
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
  } # foreach my $ace_key (@ace_keys)
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
  my $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE wbg_timestamp > '$recent_date';" );
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
  my $result = $conn->exec( "SELECT * FROM wbg_lastname WHERE wbg_timestamp > '$recent_date';" );
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

sub PGQueryRowify {		# Add lines to reference info
  my $result = shift;
  my @row;
  while (@row = $result->fetchrow) {
    $variables{reference} .= "$row[1]";
  } # while (@row = $result->fetchrow) 
} # sub PGQueryRowify 



sub FindIfPgEntry {	# look at postgresql by pubID (joinkey) to see if entry exists
	# use the pubID and the curator table to see if there's an entry already
  my $result = $conn->exec( "SELECT * FROM curator WHERE joinkey = '$variables{pubID}';" );
  my @row; my $found;
  while (@row = $result->fetchrow) { $found = $row[1]; }
  return $found;
} # sub FindIfPgEntry 

sub PgCommand {
	# 'Pg !'  Process the Query and show the results
  my $oop;
  if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
  else { $oop = "nodatahere"; }
  my $pgcommand = &Untaint($oop);
  if ($pgcommand eq "nodatahere") { 
    print "You must enter a valid PG command<BR>\n"; 
  } else { # if ($pgcommand eq "nodatahere") 
    my $result = $conn->exec( "$pgcommand" ); 
    if ( $pgcommand !~ m/select/i ) {
      print "PostgreSQL has processed it.<BR>\n";
      &ShowPgQuery();
    } else {
      print "<CENTER><TABLE border=1 cellspacing=5>\n";
      &PrintTableLabels();
      my @row;
      while (@row = $result->fetchrow) {	# loop through all rows returned
        print "<TR>";
        foreach $_ (@row) {
          print "<TD>${_}&nbsp;</TD>\n";	# print the value returned
        }
        print "</TR>\n";
      } # while (@row = $result->fetchrow) 
      &PrintTableLabels();
      print "</TABLE>\n";
    }
  } # else # if ($pgcommand eq "nodatahere") 
} # sub PgCommand 



sub QueryDataPG {		# get pg related values from html into @PGparamvalues
  my $oop; 
  for (0 .. scalar(@PGparameters)-1 ) {
    if ( $query->param("$PGparameters[$_]") ) { 
      $oop = $query->param("$PGparameters[$_]"); 
      $PGparamvalues[$_] = &Untaint($oop);
    } else { # if ( $query->param("$PGparameters[$_]") ) 
      $PGparamvalues[$_] = "";
    } # else # if ( $query->param("$PGparameters[$_]") ) 
  } # for (0 .. scalar(@PGparameters)-1 ) 
  return @PGparamvalues;
} # sub QueryDataPG 


sub QueryDataHTML {		# get html related values from html into @HTMLparamvalues
  my $oop; # my @HTMLparamvalues;
  for (0 .. scalar(@HTMLparameters)-1 ) {
    if ( $query->param("$HTMLparameters[$_]") ) { $oop = $query->param("$HTMLparameters[$_]"); }
    else { $oop = "nodatahere"; }	# set default for saving / loading
    $HTMLparamvalues[$_] = &Untaint($oop);
  } # for (0 .. scalar(@HTMLparameters)-1 ) 
  return @HTMLparamvalues;
} # sub QueryDataHTML 



sub DealPg {				# Add values to Postgres
  my @valuesforpostgres = @PGparamvalues;	# copy values
  foreach $_ (@valuesforpostgres) {
    if ($_ eq "nodatahere") { $_ = ''; }	# empty out those with no data
    if ($_ =~ m/'/) { $_ =~ s/'/''/g; }
  } # foreach $_ (@valuesforpostgres) 

  $variables{pubID} = $PGparamvalues[0];
  my $found = &FindIfPgEntry();
  if ($found) { &UpdatePg(@valuesforpostgres); } else { &AddToPg(@valuesforpostgres); }
  &AddToTest3(@valuesforpostgres);
} # sub DealPg 

sub AddToPg { 				# insert all separate data
  my @valuesforpostgres = @_;
  for (0 .. scalar(@PGparameters)-1) { 	# for each parameter from the CGI
    unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') ) {	 	 # exclude pubID and pdffilename and reference because 
					# they have no matching pgsql tables
      if ($valuesforpostgres[$_] eq "") { 	# no entry, enter NULL
					# insert entries
        my $result = $conn->exec( "INSERT INTO $PGparameters[$_] VALUES ('$valuesforpostgres[0]', NULL);" );
      } else {				# a real entry, enter the value
        my $result = $conn->exec( "INSERT INTO $PGparameters[$_] VALUES ('$valuesforpostgres[0]', '$valuesforpostgres[$_]');" );
      } # else # if ($valuesforpostgres[$_] eq "") 
    } # unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') )
  } # for (0 .. scalar(@PGparameters)-1) 
} # sub AddToPg 

sub UpdatePg { 				# update all separate data
  my @valuesforpostgres = @_;
  for (0 .. scalar(@PGparameters)-1) { 	# for each parameter from the CGI
    if ($PGparameters[$_] eq 'Curator') {
      my $result = $conn->exec( "INSERT INTO $PGparameters[$_] VALUES ('$valuesforpostgres[0]', '$valuesforpostgres[$_]');" );
    } # if ($PGparameters[$_] eq 'Curator') 
    unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') || ($PGparameters[$_] eq 'Curator') ) {	 
					# exclude pubID and pdffilename and reference because 
					# they have no matching pgsql tables
      if ($valuesforpostgres[$_] eq "") { 	# no entry, enter NULL
					# update entries
        my $result = $conn->exec( "UPDATE $PGparameters[$_] SET $PGparameters[$_] = NULL WHERE joinkey = '$valuesforpostgres[0]';" );
      	} else {			# a real entry, enter the value
        my $result = $conn->exec( "UPDATE $PGparameters[$_] SET $PGparameters[$_] = '$valuesforpostgres[$_]' WHERE joinkey = '$valuesforpostgres[0]';" );
      } # else # if ($valuesforpostgres[$_] eq "") 
    } # unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') )
  } # for (0 .. scalar(@PGparameters)-1) 
} # sub UpdatePg 


sub ShowPgQuery {
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://minerva.caltech.edu/~postgres/cgi-bin/person_recent_ace.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
} # sub ShowPgQuery 


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
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

