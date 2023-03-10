#!/usr/bin/perl -w
#
# Force grouping of aces and wbgs.
# 
# Select type (ace or wbg) on radio buttons, type number.  Select other's type and number.
# Click ``Preview !'' which shows the data for them.  If correct, click ``Force !''.  
# Checks for each if ace or wbg and enters into ace_groupedwith or wbg_groupedwith table
# in postgreSQL as approriate for both.			2002 05 02

use strict;
use CGI;
use Fcntl;
use Pg;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);

my $frontpage = 1;			# show the front page on first load

&PrintHeader();

&process();		# check button action and do as appropriate
&display();		# check display flags and show appropriate page


&PrintFooter();

sub display {
  if ($frontpage) {
    &formPickForce();	# make the frontpage
  } # if ($frontpage) 
} # sub display

sub process {
  my $action;
  unless ($action = $query->param('action') ) { 
    $action = 'none';
  }

  if ($action eq 'Preview !') {
    $frontpage = 0;
    &getPreview();				# make list by picked paramters
  } # if ($action eq 'Preview !')

  elsif ($action eq 'Force !') {
    $frontpage = 0;
    &force_group();				# make groupings depending on clicked and data
  } # elsif ($action eq 'Force !')

  elsif ($action eq 'none') { 1; }

  else { print "NOT A VALID ACTION : $action, contact the author.<BR>\n"; }
} # sub process

#### pick ####

sub getPreview {
  my $oop;				# fake variable to untaint
    # get the types and numbers
  my ($type_one, $type_two) = ('ace', 'wbg');
  my ($num_one, $num_two) = ('', '');
  if ( $query->param('type_one') ) {
    $oop = $query->param('type_one');
    $type_one = &Untaint($oop);
  } # if ( $query->param('type_one') )
  if ( $query->param('type_two') ) {	
    $oop = $query->param('type_two');
    $type_two = &Untaint($oop);
  } # if ( $query->param('type_two') )
  if ( $query->param('num_one') ) {
    $oop = $query->param('num_one');
    $num_one = &Untaint($oop);
  } # if ( $query->param('num_one') )
  if ( $query->param('num_two') ) { 	
    $oop = $query->param('num_two');
    $num_two = &Untaint($oop);
  } # if ( $query->param('num_two') )
#   print "n1 : $num_one<BR>\n";
#   print "n2 : $num_two<BR>\n";
#   print "t1 : $type_one<BR>\n";
#   print "t2 : $type_two<BR>\n";

    # check all data there
  unless ( ($num_one) && ($type_one) && ($num_two) && ($type_two) ) {
    print "Not Sufficient Data<BR>\n";
  } else {				# make key, display with bgcolor white (0),
					# and (useless) box checked (1)
    my $one_key = $type_one . $num_one;
    if ($type_one eq 'ace') { &displayAceDataFromKey($one_key, '0', '1'); }
    elsif ($type_one eq 'wbg') { &displayWbgDataFromKey($one_key, '0', '1'); }
    else { print "Not a valid type : $one_key<BR>\n"; }
    my $two_key = $type_two . $num_two;
    if ($type_two eq 'ace') { &displayAceDataFromKey($two_key, '0', '1'); }
    elsif ($type_two eq 'wbg') { &displayWbgDataFromKey($two_key, '0', '1'); }
    else { print "Not a valid type : $two_key<BR>\n"; }
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/force_group.cgi\">\n";
      # pass values to form to group later
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"one_key\" VALUE=\"$one_key\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_key\" VALUE=\"$two_key\">\n";
    print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Force !\"></TD>";
    print "</FORM>\n";
  } # else # unless ( ($num_one) && ($type_one) && ($num_two) && ($type_two) )
} # sub getPreview

#### pick ####


#### display ####

sub numerically { $a <=> $b }		# sort numerically

sub formPickForce {			# make the frontpage, pick numbers and type
  print "<TABLE border=1 cellspacing=2>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/force_group.cgi\">\n";
  print "<TR><TD>Ace</TD><TD>Wbg</TD><TD>Numbers :</TD></TR>\n";

  print "<TR><TD><INPUT NAME=\"type_one\" TYPE=\"radio\" CHECKED VALUE=\"ace\">Ace</TD>\n";
  print "<TD><INPUT NAME=\"type_one\" TYPE=\"radio\" VALUE=\"wbg\">Wbg</TD>\n";
  print "<TD><INPUT NAME=\"num_one\" SIZE=40></TD></TR>\n";

  print "<TR><TD><INPUT NAME=\"type_two\" TYPE=\"radio\" VALUE=\"ace\">Ace</TD>\n";
  print "<TD><INPUT NAME=\"type_two\" TYPE=\"radio\" CHECKED VALUE=\"wbg\">Wbg</TD>\n";
  print "<TD><INPUT NAME=\"num_two\" SIZE=40></TD></TR>";

  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Preview !\"></TD>";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub formPickForce

#### display ####


####  display from key ####

sub displayAceDataFromKey {		# show all ace data from a given key in multiline table
  my ($ace_key, $color, $checked) = @_;
  if ($color eq '5') { $color = '#aa4bf2'; }	# light purple
  elsif ($color eq '4') { $color = 'blue'; }
  elsif ($color eq '3') { $color = 'green'; }
  elsif ($color eq '2') { $color = 'yellow'; }
  elsif ($color eq '1') { $color = 'orange'; }
  else { $color = 'white'; }
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
        print "</TR>";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print "</TABLE><BR><BR>\n";
#   print "DISPLAY ACE DATA<BR>\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {		# show all wbg data from a given key in multiline table
  my ($wbg_key, $color, $checked) = @_;
  if ($color eq '5') { $color = '#aa4bf2'; }	# light purple
  elsif ($color eq '4') { $color = 'blue'; }
  elsif ($color eq '3') { $color = 'green'; }
  elsif ($color eq '2') { $color = 'yellow'; }
  elsif ($color eq '1') { $color = 'orange'; }
  else { $color = 'white'; }
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

sub force_group {
  my ($one_key, $two_key);
  if ( $query->param('one_key') ) {
    my $oop = $query->param('one_key');
    $one_key = &Untaint($oop);
  } # if ( $query->param('one_key') )
  if ( $query->param('two_key') ) {
    my $oop = $query->param('two_key');
    $two_key = &Untaint($oop);
  } # if ( $query->param('two_key') )
  print "one : $one_key<BR>\n";
  if ($one_key =~ m/^ace/) { 
    print "\$result = \$conn->exec( \"INSERT INTO ace_groupedwith VALUES ('$one_key', '$two_key');\" );<BR>\n";
  } elsif ($one_key =~ m/^wbg/) {
    print "\$result = \$conn->exec( \"INSERT INTO wbg_groupedwith VALUES ('$one_key', '$two_key');\" );<BR>\n";
  } else { print "Not a valid type : $one_key<BR>\n"; }
    my $result = $conn->exec( "INSERT INTO ace_groupedwith VALUES ('$one_key', '$two_key');" );
    $result = $conn->exec( "INSERT INTO wbg_groupedwith VALUES ('$one_key', '$two_key');" );
  print "two : $two_key<BR>\n";
  if ($two_key =~ m/^ace/) { 
    print "\$result = \$conn->exec( \"INSERT INTO ace_groupedwith VALUES ('$two_key', '$one_key');\" );<BR>\n";
  } elsif ($two_key =~ m/^wbg/) {
    print "\$result = \$conn->exec( \"INSERT INTO wbg_groupedwith VALUES ('$two_key', '$one_key');\" );<BR>\n";
  } else { print "Not a valid type : $two_key<BR>\n"; }
} # sub force_group

#### group ####


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
<CENTER><A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/sitemap.cgi">Site Map</A></CENTER>
<CENTER><A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/force_group_doc.txt">Documentation</A></CENTER>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

