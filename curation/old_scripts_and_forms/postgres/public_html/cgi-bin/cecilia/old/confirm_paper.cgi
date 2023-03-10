#!/usr/bin/perl -wT
#
# Take grouped Authors and Persons and check to confirm or to email them. (Obsolete)
#
# This was never used due to it being incredibly tedious  (Raymond wanted it to avoid
# emailing authors, now is clear that Raymond and Paul are not going to do this themselves)
# Replaced by version on ~azurebrd/public_html/cgi-bin/forms/ where authors verify
# their own data   2003 01 31
 
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

  if ($action eq 'Curator !') {		# display twos in sets of 50
    &pickRange();
  } # if ($action eq 'Curator !')

  if ($action eq 'Page !') {		# display a range with 50 twos
    &pickPage();
  } # if ($action eq 'Page !')

  if ($action eq 'Pick !') {		# display matching papers in groups of 10
    &papPick();
  } # if ($action eq 'Pick !')

  if ($action eq 'Select !') {		# check authors that match person (two)
    &papSelect();
  } # if ($action eq 'Select !')

  elsif ($action eq 'Edit !') {		# write changes to database
    &papEdit();
  }
} # sub display

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

    if ($query->param("email_or_verify$i")) { $oop = $query->param("email_or_verify$i"); } 
      else { $oop = 'nodatahere'; }
    my $email_or_verify = untaint($oop);

    $pap_author =~ s/\"/\\\"/g;			# escape double quotes for postgres and html display
    $pap_author =~ s/\'/''/g;			# escape single quotes for postgres and html display
#     print "<BR>JOIN $joinkey : AUTH $pap_author<BR>\n";

    if ($email_or_verify eq 'email') { 		# for email, change the email field
      print "<FONT COLOR='blue'>UPDATE pap_email SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
      my $result = $conn->exec( "UPDATE pap_email SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
      print "<FONT COLOR='blue'>UPDATE pap_email SET pap_email = \'$curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR><BR>\n";
      $result = $conn->exec( "UPDATE pap_email SET pap_email = \'$curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
    } elsif ($email_or_verify eq 'verify') { 	# for verify, change the verify field
      print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR>\n";
      my $result = $conn->exec( "UPDATE pap_verified SET pap_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
      print "<FONT COLOR='blue'>UPDATE pap_verified SET pap_verified = \'$curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\';</FONT><BR><BR>\n";
      $result = $conn->exec( "UPDATE pap_verified SET pap_verified = \'$curator\' WHERE joinkey = \'$joinkey\' AND pap_author = \'$pap_author\'" );
    } else { 1; } # print "<FONT COLOR=red>WARNING, not a valid option $email_or_verify</FONT>.<BR>";

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
  if ($query->param('val_groups')) { $oop = $query->param('val_groups'); } 
    else { $oop = 'nodatahere'; }
  my $val_groups = untaint($oop); 
  print "two : $two : val_groups : $val_groups<BR><BR>\n";
  if ($query->param('val_paper')) { $oop = $query->param('val_paper'); } 
    else { $oop = 'nodatahere'; }
  my $val_paper = untaint($oop); 
  if ($query->param('paper_range')) { $oop = $query->param('paper_range'); } 
    else { $oop = 'nodatahere'; }
  my $paper_range = untaint($oop); 
  print "two : $two<BR>paper_range : $paper_range<BR>val_paper : $val_paper<BR><BR>\n";

  &displayOneDataFromKey($two);

  &displayEditor($two, $paper_range, $curator);

} # sub papSelect

sub displayEditor {
  my ($two_key, $paper_range, $curator) = @_;
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper.cgi\">\n";
  print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  my @papers = split /\t/, $paper_range;
  my $count = 0;
  foreach my $paper_key (@papers) { $count = &displayPaperDataFromKey($paper_key, $count, $two_key); }
    # display tables with paper data and checkboxes (for each author) for each of the papers
  print "TOTAL authors : $count<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"count\" VALUE=\"$count\">\n";
  print "<INPUT TYPE=submit NAME=action VALUE=\"Edit !\"><BR><BR>\n";
  print "</FORM>\n";
} # sub displayEditor

## papSelect block ##

## papPick block ##

sub papPick {				# display matching papers in groups of 10
  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";

  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  if ($query->param('val_groups')) { $oop = $query->param('val_groups'); } 
    else { $oop = 'nodatahere'; }
  my $val_groups = untaint($oop); 
  print "two : $two : val_groups : $val_groups<BR><BR>\n";
  if ($query->param('val_paper')) { $oop = $query->param('val_paper'); } 
    else { $oop = 'nodatahere'; }
  my $val_paper = untaint($oop); 
  print "two : $two : val_paper : $val_paper<BR><BR>\n";

  &displayOneDataFromKey($two);

  my @keys = split /\t/, $val_groups;
  print "<TABLE border=1 cellspacing=5>\n";
  foreach my $key (@keys) {
    if ($key =~ m/^wbg/) { &displayWbgDataFromKey($key); }
    if ($key =~ m/^ace/) { &displayAceDataFromKey($key); }
  } # foreach my $key (@keys)
  print "</TABLE>\n";

  &displaySelector($two, $val_groups, $val_paper, $curator);
} # sub papPick

sub displaySelector {
  my ($two_key, $val_groups, $val_paper, $curator) = @_;
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
  foreach my $lastname (sort keys %lastnames) { 
    print "two$two_key finds : $lastname<BR><BR>\n"; 
    &findPapList($lastname, $two_key, $val_groups, $val_paper, $curator);
  }
} # sub displaySelector

sub findPapList {
  my ($lastname, $two_key, $val_groups, $val_paper, $curator) = @_;
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
  my @val_papers = split /\t/, $val_paper;
  print "<TABLE border=1 cellspacing=2>\n";
  for (my $i = 0; $i < scalar(@papers); $i+=10) { 
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper.cgi\">\n";
    print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two\" VALUE=\"$two_key\">\n";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_groups\" VALUE=\"$val_groups\">";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"val_paper\" VALUE=\"$val_paper\">";
    my @papers_in_group;
    print "<TR><TD>papers : " . (1 + $i) . " to " . (10 + $i) . "</TD><TD>";
    for (my $j = $i; ( ($j < $i+10) && ($j < scalar(@papers)) ); $j++) { 
#       if ($val_paper =~ m/$papers[$j]/) { print "<FONT COLOR = $red>"; }	
      foreach my $val_pap (@val_papers) { if ($val_pap eq $papers[$j]) { print "<FONT COLOR = $red>"; } }
	# show in different color if grouped
      print "paper " . ($j + 1) . " : $papers[$j]<BR>\n";
      push @papers_in_group, $papers[$j];
      foreach my $val_pap (@val_papers) { if ($val_pap eq $papers[$j]) { print "</FONT>"; } }
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
} # sub findPapList

## papPick block ##

sub pickPage {
  my $date = &getDate();
  print "Date : $date<P>\n";

  my ($oop2, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";

  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR><TD>Two</TD><TD>Grouped</TD><TD>Paper</TD></TR>\n";

  my $oop;
  if ($query->param('two_num')) { $oop = $query->param('two_num'); } 
    else { $oop = 'nodatahere'; }
  my $two_num = untaint($oop);
  my $highest_val = $two_num + 50;

    # populate hash of key twos and values ace/wbg
  my %twos;				# HoA  key = two#, values = ace#, wbg#
  my $result = $conn->exec( "SELECT * FROM two_groups;" );
  while (my @row = $result->fetchrow) {
    push @{ $twos{$row[0]}{group} } , $row[1];
  } # while (my @row = $result->fetchrow)

  $result = $conn->exec( "SELECT * FROM two_paper;" );
  while (my @row = $result->fetchrow) {
    push @{ $twos{$row[0]}{paper} } , $row[1];
  } # while (my @row = $result->fetchrow)

    # for each two, display it and its values
  for (my $i = $two_num; $i <= $highest_val; $i++) { 
    my $two = 'two' . $i;
    foreach $_ (@{ $twos{$two}{group} }) { }			# don't know why i need this
    foreach $_ (@{ $twos{$two}{paper} }) { }			# don't know why i need this
    my $val_groups = join "<BR>", @{ $twos{$two}{group} } ;	# display with breaks
    my $val_groupst = join "\t", @{ $twos{$two}{group} } ;	# pass value with tabs
#     my $val_paper = join "<BR>", @{ $twos{$two}{paper} } ;	# display with breaks
    my $val_paper = join ", ", @{ $twos{$two}{paper} } ;	# display with commas
    my $val_papert = join "\t", @{ $twos{$two}{paper} } ;	# pass value with tabs
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper.cgi\">\n";
    print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">\n";
    print "<TR><TD>$two</TD><TD>$val_groups</TD><TD>$val_paper</TD>";
    print "<INPUT TYPE=hidden NAME=two VALUE=\"$i\">";
    print "<INPUT TYPE=hidden NAME=val_groups VALUE=\"$val_groupst\">";
    print "<INPUT TYPE=hidden NAME=val_paper VALUE=\"$val_papert\">";
    print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Pick !\"></TD></TR>\n";
    print "</FORM>\n";
  } # for ($i = 1; $i < $highest_val; $i++)

  print "</TABLE>\n";
} # sub pickPage

sub numerically { $a <=> $b }

sub pickRange {
  my $date = &getDate();
  print "Date : $date<P>\n";
  my ($oop, $curator) = &getHtmlVar($query, 'curator_name');
  print "Curator : $curator<P>\n";

  my @papers; my %papers;
#   my $result = $conn->exec( "SELECT * FROM pap_author WHERE pap_person IS NOT NULL AND pap_email IS NULL AND pap_verified IS NULL ORDER BY joinkey;" );
#   my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_possible IS NOT NULL AND pap_email IS NULL AND pap_verified IS NULL ORDER BY joinkey;" );
  my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_possible IS NOT NULL ORDER BY joinkey;" );
    # show all, not just those that are new
  while (my @row = $result->fetchrow) {
    push @papers, $row[2];
  } # while (my @row = $result->fetchrow)
    # filter junk to sort numerically
  foreach $_ (@papers) { $_ =~ s/^\s+//g; $_ =~ s/\s+$//g; $_ =~ s/two//g; $papers{$_}++; }
  @papers = ();						# clear to put back into array
  my $last;						# dynamic update of last number of paper
  foreach $_ (sort numerically keys %papers) { push @papers, 'two' . $_; $last = $_; }	# put into array
#   foreach my $paper (@papers) {
#     print "PAPER $paper<BR>\n";							# print out for test
#   } # foreach my $paper (@papers)
  my $first = $papers[0]; $first =~ s/two//g;		# first paper of list of papers

  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper.cgi\">\n";
  print "<INPUT TYPE=HIDDEN NAME=curator_name VALUE=\"$curator\">";
  my $counter = 1;
#   for (my $i = 1; $i<2000; $i = $i+50) 
  for (my $i = $first; $i < $last; $i = $i+50) {
    if ($counter > 500) { $counter = 1; print "</TR><TR>\n"; }
    $counter += 50;                     # up the counter, must always be less than 500 for display
    my $j = $i + 49;                    # j is just i + 49 for display
    print "<TD>Two $i - $j</TD><TD><INPUT NAME=\"two_num\" TYPE=\"radio\" VALUE=\"$i\"></TD>\n";
  } # for (my $i = 1; $i<2000; $i = $i+50)
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Page !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub pickRange

sub firstPage {
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/confirm_paper.cgi\">";
  print "<TABLE>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=9>\n";
  print "<OPTION>Carol Bastiani</OPTION>\n";
  print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Ranjana Kishore</OPTION>\n";
  print "<OPTION>Raymond Lee</OPTION>\n";
  print "<OPTION>Cecilia Nakamura</OPTION>\n";
  print "<OPTION>Andrei Petcherski</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
#   print "<OPTION>Andrei Testing</OPTION>\n";
  print "<OPTION>Juancarlos Testing</OPTION>\n";
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub firstPage



### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  foreach my $two_table (@two_tables) {
    my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
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
    my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key';" );
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

sub displayAceDataFromKey {             # show all ace data from a given key in multiline table
  my ($ace_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $ace_table (@ace_tables) { # show the data
    my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$ace_table</TD>";
        foreach (@row) { print "<TD>$_</TD>"; }
        print "</TR>\n";
      } # if ($row[1])
    } # while (@row = $result->fetchrow)
  } # foreach (@ace_tables)
  print "</TABLE><BR><BR>\n";
} # sub displayAceDataFromKey

sub displayWbgDataFromKey {             # show all wbg data from a given key in multiline table
  my ($wbg_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $wbg_table (@wbg_tables) { # go through each table for the key
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

sub displayPaperDataFromKey {             # show all paper info from key, and checkbox for each author
  my ($paper_key, $count, $two_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $paper_table (@paper_tables) { # go through each table for the key
    my $result = $conn->exec( "SELECT * FROM $paper_table WHERE joinkey = '$paper_key';" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$paper_table</TD>";
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
      print "<TR><TD>pap_author</TD>";
      print "<TD>$row[0]</TD>"; 
      print "<TD>$row[1]</TD>"; 
      my $pap_value = $row[0] . '_JOIN_' . $row[1]; 
      $count++;				# add to checkbox counter
					# count which checkbox it is to give it a name
#       print "<TD>$count<INPUT NAME=\"check$count\" TYPE=\"checkbox\" ";
#       if ($row[2]) { print " CHECKED "; }
#       print "VALUE=\"YES\"></TD>";
      print "<TD ALIGN='center'>";
      if ($row[2]) { print "$row[2]"; } else { print "&nbsp;"; }
      print "</TD>";
      $pap_value =~ s/\"/REPQ/g;	# sub out doublequotes for replacement text
					# to pass the value
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"val$count\" VALUE=\"$pap_value\">\n";
      if ($row[2] eq "two$two_key") { 			# if Cecilia checked it and two number matches, 
							# give option of radio button
        if ( ($row[3] eq '') && ($row[4] eq '') ) {	# if both blank, show radio
          print "<TD ALIGN='center'><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"email\" CHECKED></TD>\n";
          print "<TD ALIGN='center'><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"verify\"></TD>\n";
        } else { 
          print "<TD ALIGN='center'><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"email\">";
          if ($row[3]) { print "$row[3]"; }
          print "</TD>\n";
          print "<TD ALIGN='center'><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"verify\">";
          if ($row[4]) { print "$row[4]"; }
          print "</TD>\n";
        }
      } else { print "<TD>&nbsp;</TD><TD>&nbsp;</TD>\n"; }
#       if ($row[2]) { 			# if Cecilia checked it, give option of radio button
#         print "<TD><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"email\" CHECKED></TD>\n";
#         print "<TD><INPUT NAME=\"email_or_verify$count\" TYPE=\"radio\" VALUE=\"verify\"></TD>\n";
#       } else { print "<TD>&nbsp;</TD><TD>&nbsp;</TD>\n"; }
      if ($row[5]) { print "<TD>$row[5]</TD></TR>\n"; } else { print "<TD>&nbsp;</TD></TR>\n"; }
#       print "</TR>\n";
    } # if ($row[1])
  } # while (my @row = $result->fetchrow)
  
  print "<TR><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>&nbsp;</TD><TD>Possible</TD><TD>E-mail</TD><TD>Verify</TD><TD>&nbsp;</TD></TR>";
  print "</TABLE><BR><BR>\n";
  return $count;
} # sub displayPaperDataFromKey

### display from key ###

