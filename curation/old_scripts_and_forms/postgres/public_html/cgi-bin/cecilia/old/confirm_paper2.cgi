#!/usr/bin/perl -wT
#
# Verify grouped Authors and Persons.  (Obsolete)
#
# Moved to ~azurebrd/cgi-bin/forms/   2003 01 31
 
use strict;
use CGI;
use Fcntl;
use Pg;
use Jex;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
my @paper_tables = qw(pap_paper pap_title pap_journal pap_page pap_volume pap_year pap_inbook pap_contained pap_pmid pap_affiliation pap_type pap_contains);
# my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_comment two_groups);
my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);
my @two_simpler = qw(two_comment two_groups);

my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $frontpage = 1;			# show the front page on first load

&printHeader('Confirm Author-Paper-Person Connections');
print "<CENTER><A HREF='confirm_paper_doc.txt'>Documentation</A></CENTER><P>\n";
&display();
&printFooter();

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Pick !') {		# display matching papers in groups of 10
    &papPick();
  } # if ($action eq 'Pick !')

  if ($action eq 'Select !') {		# check authors that match person (two)
    &papSelect();
  } # if ($action eq 'Select !')

  elsif ($action eq 'Edit !') {		# write changes to database
    &papEdit();
  }

  if ($action eq 'Comment !') {		# check authors that match person (two)
    &papComment();
  } # if ($action eq 'Comment !')
} # sub display

sub papComment {				# authors that want to leave comments
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  $curator =~ s/^\s+//g;
  $curator =~ s/\s+$//g;
  print "Curator : $curator<P>\n";

  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  print "WBPerson : $two<P>\n";

  if ($query->param('comment')) { $oop = $query->param('comment'); } 
    else { $oop = 'nodatahere'; }
  my $comment = untaint($oop);
  print "Comment : $comment<P>\n";
  $comment =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
  $comment =~ s/\'/''/g;			# escape single quotes for postgres and html display

  print "<FONT COLOR='blue'>INSERT INTO two_comment VALUES ('two$two', '$curator : $comment');</FONT><BR>\n";
  my $result = $conn->exec( "INSERT INTO two_comment VALUES ('two$two', '$curator : $comment');" );

  my $user = $curator;
  $user =~ s/\s+/_/g;				# get rid of spaces for email address
  my $email = 'cecilia@minerva.caltech.edu';
  my $subject = "$curator comment for paper connections";
  my $body = $comment;
  &mailer($user, $email, $subject, $body);	# email comments to cecilia
} # sub papComment

sub papEdit {
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";

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
    if ($query->param("val$i")) { $oop = $query->param("val$i"); } 
      else { $oop = 'nodatahere'; }
    my $val = untaint($oop);
    $val =~ s/REPQ/\"/g;			# get double quotes back in values from html values
    my ($joinkey, $pap_author) = $val =~ m/^(.*)_JOIN_(.*)$/;

    if ($query->param("yours_or_not$i")) { $oop = $query->param("yours_or_not$i"); } 
      else { $oop = 'nodatahere'; }
    my $yours_or_not = untaint($oop);

    $pap_author =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
    $pap_author =~ s/\'/''/g;			# escape single quotes for postgres and html display
#     print "<BR>JOIN $joinkey : AUTH $pap_author<BR>\n";

    if ($yours_or_not eq 'yours') { 		# for yours, change the verified field
      print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
      my $result = $conn->exec( "UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
      print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_verified = \'YES $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR><BR>\n";
      $result = $conn->exec( "UPDATE pap_verified SET pap_verified = \'YES $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
    } elsif ($yours_or_not eq 'not') { 		# for not yours, change the verified field
      print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
      my $result = $conn->exec( "UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
      print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_verified = \'NO $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR><BR>\n";
      $result = $conn->exec( "UPDATE pap_verified SET pap_verified = \'NO $curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
    } else { 1; } # print "<FONT COLOR=red>WARNING, not a valid option $yours_or_not</FONT>.<BR>";

  } # for (my $i = 1; $i <= $count; $i++)
} # sub papEdit


## papSelect block ##

sub papSelect {
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";

  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  if ($query->param('paper_range')) { $oop = $query->param('paper_range'); } 
    else { $oop = 'nodatahere'; }
  my $paper_range = untaint($oop); 

  &displayOneDataFromKey($two);

  &displayEditor($two, $paper_range, $curator);

} # sub papSelect

sub displayEditor {
  my ($two_key, $paper_range, $curator) = @_;
  print "<P><B>From each table of Papers below, please check the radio button corresponding to whether a paper is Yours or Not Yours.<BR>When finished choosing for all papers, click the ``Edit !'' button  :<BR>(If a checkbox says YES or NO with a name next to it, it is because someone with that name has already chosen YES or NO for it.  Reselecting the checkbox and clicking the ``Edit !'' button will override the previous value with your name.)</B><P>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper2.cgi\">\n";
  print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  my @papers = split /\t/, $paper_range;
  my $count = 0;
  foreach my $paper_key (@papers) { $count = &displayPaperDataFromKey($paper_key, $count, $two_key); }
    # display tables with paper data and checkboxes (for each author) for each of the papers
#   print "TOTAL authors : $count<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"count\" VALUE=\"$count\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  print "</FORM>\n";
} # sub displayEditor

## papSelect block ##

## papPick block ##

sub papPick {				# display matching papers in groups of 10
  my %names; my %two;
  my $result = $conn->exec( "SELECT * FROM two_standardname ORDER BY two_lastname, two_firstname, two_middlename;" );
my $thing = '';
  while (my @row = $result->fetchrow) {
    my $lastname = ''; my $firstname = ''; my $middlename = '';
    if ($row[1]) { $lastname = $row[1]; }
    if ($row[2]) { $firstname = $row[2]; }
    if ($row[3]) { $middlename = $row[3]; }
    my $standard_name = $lastname . ", " . $firstname . " " . $middlename;
    $standard_name =~ s/^\s+//g;
    $standard_name =~ s/\s+$//g;
    $names{$standard_name} = $row[0];
    $two{$row[0]} = $standard_name;
  } # while (my @row = $result->fetchrow)

  my $two = ''; my $curator = '';
  my ($oop, $curator) = &getHtmlVar($query, 'curator_name');
  my $two_name = $names{$curator};
  if ($two_name) { 			# if picked their name, get data
    $two_name =~ s/two//g;
    $two = $two_name;
    my ($last, $rest) = split/,/, $curator;
  } else { 				# if not, if picked their number, get data
    my $oop;
    if ($query->param('two_num')) { $oop = $query->param('two_num'); } 
      else { $oop = 'nodatahere'; }
    $two = untaint($oop);
    $two =~ s/two//g;
    my $two_temp = 'two' . $two;
    $curator = $two{$two_temp};
    my ($last, $rest) = split/,/, $curator;
  } # else # if ($two_name)

  print "WBPerson : $two<P>\n";		# display two number

  my ($last, $rest) = split/,/, $curator;
  $curator = $rest . " " . $last;
  print "Curator : $curator<P>\n";	# display standard name

  &displayOneDataFromKey($two);

  print "</TABLE>\n";

  &displaySelector($two, $curator);
} # sub papPick

sub displaySelector {
  my ($two_key, $curator) = @_;
  my @lastnames;			# all lastnames from two tables
  my %lastnames;			# hash to filter multiple lastnames
  my @two_tables_last = qw( two_lastname two_aka_lastname two_apu_lastname );
  foreach my $two_table_last (@two_tables_last) { 
    my $result = $conn->exec( "SELECT $two_table_last FROM $two_table_last WHERE joinkey = 'two$two_key';" );
    while (my @row = $result->fetchrow) {
      push @lastnames, $row[0];
    } # while (my @row = $result->fetchrow)
  }
  foreach $_ (@lastnames) { $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $lastnames{$_}++; }
  print "<P><B>From each batch of papers below, please click the corresponding ``Select !'' button, and follow the directions there.<BR>Afterwards, come back to this page if there is another batch of papers you have not selected :</B><P>\n";
  foreach my $lastname (sort keys %lastnames) { 
    print "two$two_key finds : $lastname<BR><BR>\n"; 
    &findPapList($lastname, $two_key, $curator);
  }
} # sub displaySelector

sub findPapList {
  my ($lastname, $two_key, $curator) = @_;
  my $papercount = 0;			# count of papers
  my @papers;				# list of papers
  my %filter_papers;			# hash to filter papers
    # updated to show by two_key that is marked, and where email and verified are null
#   my $result = $conn->exec( "SELECT * FROM pap_author WHERE pap_person = 'two$two_key' AND pap_email IS NULL AND pap_verified IS NULL ORDER BY joinkey;" );
#   my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_possible = 'two$two_key' AND pap_email IS NULL AND pap_verified IS NULL ORDER BY joinkey;" );
  my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_possible = 'two$two_key' ORDER BY joinkey;" );
    # show all, not just those that are new
  while (my @row = $result->fetchrow) {
    $papercount++;
    push @papers, $row[0];
  } # while (my @row = $result->fetchrow)
  foreach $_ (@papers) { $filter_papers{$_}++; };	# put papers in filter hash
  @papers = ();						# clear array
  foreach $_ (sort keys %filter_papers) { push @papers, $_; }	# put back in array
  print "There are " . scalar(@papers) . " matching papers for $lastname :<BR>\n";
  print "<TABLE border=1 cellspacing=2>\n";
  for (my $i = 0; $i < scalar(@papers); $i+=10) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper2.cgi\">\n";
    print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
    my @papers_in_group;
    print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
    for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@papers)) ); $j++) { 
      print "paper " . ($j + 1) . " : $papers[$j]<BR>\n";
      push @papers_in_group, $papers[$j];
    } # for (my $j = $i; $j < $i+10; $j++)
    print "</TD><TD><INPUT TYPE=submit NAME=action VALUE=\"Select !\"></TD>\n";
    my $papers_in_group = join "\t", @papers_in_group;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"paper_range\" VALUE=\"$papers_in_group\">";
    print "</TR>\n";
    print "</FORM>\n";
  } # for (my $i = 0; $i < scalar(@papers); $i+=10)
  print "</TABLE><BR><P><BR>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper2.cgi\">\n";
  print "<B>Please feel free to leave us any comments, especially if there are any other <I>C. elegans</I> papers you have published that are not in the list : </B><BR>\n";
  print "<TEXTAREA Name=\"comment\" Rows=5 Cols=40></TEXTAREA><BR>\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Comment !\"><BR>\n";
  print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
  print "</FORM>\n";
} # sub findPapList

## papPick block ##

sub firstPage {
  my @names;
  my $result = $conn->exec( "SELECT * FROM two_standardname ORDER BY two_lastname, two_firstname, two_middlename;" );
  while (my @row = $result->fetchrow) {
    my $lastname = ''; my $firstname = ''; my $middlename = '';
    if ($row[1]) { $lastname = $row[1]; }
    if ($row[2]) { $firstname = $row[2]; }
    if ($row[3]) { $middlename = $row[3]; }
    my $standard_name = $lastname . ", " . $firstname . " " . $middlename;
    push @names, $standard_name;
  } # while (my @row = $result->fetchrow)

  print "<TABLE>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper2.cgi\">";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\">\n";
  foreach my $name (@names) { print "<OPTION>$name</OPTION>\n"; }
  print "</SELECT></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pick !\"></TD></TR>\n";
  print "</FORM>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper2.cgi\">";
  print "<TR><TD>Or type your WBPerson number : </TD><TD><INPUT NAME=\"two_num\" SIZE=15></TD>\n";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pick !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub firstPage



### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  print "<TR bgcolor='$blue'><TD align='center'>table</TD><TD>WBPerson number</TD><TD>order</TD>
         <TD align='center'>Value</TD><TD align='center'>Timestamp</TD></TR>\n";
  foreach my $two_table (@two_tables) {
    my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        $two_table =~ s/two_//g;
        print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
        $row[0] =~ s/two//g;
        print "  <TD align='center'>$row[0]</TD>\n"; 
        print "  <TD align='center'>$row[1]</TD>\n";
        print "  <TD>$row[2]</TD>\n";
        print "  <TD>$row[3]</TD>\n";
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_table (@two_tables)

#   foreach my $two_simpler (@two_simpler) {
#     my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key';" );
#     while (my @row = $result->fetchrow) {
#       if ($row[1]) {
#         $two_simpler =~ s/two_//g;
#         print "<TR bgcolor='$blue'>\n  <TD>$two_simpler</TD>\n";
#         $row[0] =~ s/two//g;
#         print "  <TD align='center'>$row[0]</TD>\n"; 
#         print "  <TD>&nbsp;</TD>\n"; 
#         print "  <TD>$row[1]</TD>\n";
#         print "  <TD>$row[2]</TD>\n";
#         print "</TR>\n";
#       } # if ($row[1])
#     } # while (my @row = $result->fetchrow)
#   } # foreach my $two_simpler (@two_simpler)

  print "</TABLE><BR><BR>\n";
} # sub displayOneDataFromKey

sub displayPaperDataFromKey {             # show all paper info from key, and checkbox for each author
  my ($paper_key, $count, $two_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD align='center'>table</TD><TD align='center'>paper id</TD><TD align='center'>data</TD><TD>WBPerson</TD><TD align='center'>Yours</TD><TD align='center'>Not<BR>Yours</TD><TD align='center'>Timestamp</TD></TR>";
  foreach my $paper_table (@paper_tables) { # go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$paper_key';" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        my $table_name = $paper_table; $table_name =~ s/pap_//g;
        print "<TR><TD>&nbsp;$table_name&nbsp;</TD>";
        print "<TD>$row[0]</TD>"; 
        print "<TD>$row[1]</TD>"; 
        print "<TD>&nbsp;</TD>"; 
        print "<TD>&nbsp;</TD>"; 
        print "<TD>&nbsp;</TD>"; 
        print "<TD>$row[2]</TD></TR>\n"; 
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach my $paper_table (@paper_tables)
#   my $result = $conn->exec( "SELECT * FROM pap_author WHERE joinkey = '$paper_key';" );
  my $result = $conn->exec( "SELECT * FROM pap_view WHERE joinkey = '$paper_key';" );
    # use the view instead of separate tables
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      my $joinkey = ''; my $pap_author = ''; my $pap_person = ''; my $pap_email = ''; my $pap_verified = ''; my $pap_timestamp = '';
      if ($row[0]) { $joinkey = $row[0]; }
      if ($row[1]) { $pap_author = $row[1]; }
      if ($row[2]) { $pap_person = $row[2]; $pap_person =~ s/two//g; }
      if ($row[3]) { $pap_email = $row[3]; }
      if ($row[4]) { $pap_verified = $row[4]; }
      if ($row[5]) { $pap_timestamp = $row[5]; }
      print "<TR><TD>&nbsp;author&nbsp;</TD>";
      print "<TD>$joinkey</TD>"; 
      print "<TD>$pap_author</TD>"; 
      my $pap_value = $joinkey . '_JOIN_' . $pap_author; 
      $count++;				# add to checkbox counter
					# count which checkbox it is to give it a name
      print "<TD ALIGN='center'>";
      if ($pap_person) { print "$pap_person"; } else { print "&nbsp;"; }
      print "</TD>";
      $pap_value =~ s/\"/REPQ/g;	# sub out doublequotes for replacement text
					# to pass the value
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"val$count\" VALUE=\"$pap_value\">\n";
      if ($pap_person eq "$two_key") { 			# if Cecilia checked it and two number matches, 
							# give option of radio button
        if ( ($pap_email eq '') && ($pap_verified eq '') ) {	# if both blank, show radio
#           print "<TD ALIGN='center'><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"email\" CHECKED></TD>\n";
          print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\"></TD>\n";
          print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\"></TD>\n";
        } else { 
          print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"yours\">";
#           if ($pap_email) { print "$pap_email"; }
          if ($pap_verified =~ m/YES/) { print "$pap_verified"; }
          print "</TD>\n";
          print "<TD ALIGN='center'><INPUT NAME=\"yours_or_not$count\" TYPE=\"radio\" VALUE=\"not\">";
          if ($pap_verified =~ m/NO/) { print "$pap_verified"; }
          print "</TD>\n";
        }
      } else { print "<TD>&nbsp;</TD><TD>&nbsp;</TD>\n"; }
      if ($pap_timestamp) { print "<TD>$pap_timestamp</TD></TR>\n"; } else { print "<TD>&nbsp;</TD></TR>\n"; }
    } # if ($row[1])
  } # while (my @row = $result->fetchrow)
#   print "<TR><TD align='center'>table</TD><TD align='center'>paper id</TD><TD align='center'>data</TD><TD>WBPerson</TD><TD align='center'>Yours</TD><TD align='center'>Not<BR>Yours</TD><TD align='center'>Timestamp</TD></TR>";
  print "</TABLE><BR><BR>\n";
  return $count;
} # sub displayPaperDataFromKey

### display from key ###

