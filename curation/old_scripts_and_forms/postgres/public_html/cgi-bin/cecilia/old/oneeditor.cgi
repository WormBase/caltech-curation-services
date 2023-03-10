#!/usr/bin/perl -wT
#
# Edit oneified data.
#
# if first time, do &firstPage which shows all the one_tables and their corresponding one_groups
# data.  one then does ``Pick !'' to select what to edit, which queries for the various tables 
# and prints as hidden old_val the data that's there, and as input val the data to change, as 
# well as a counter for the fields.  one then does ``Edit !'' which checks through the counter
# to see what has been marked with a checkbox; for those changed, it does an update off of 
# table, joinkey, and old_val; replacing with the newly entered val.  2002 04 17
#
# Edited &displayOneDataFromKey(); to include a &makeExtraFields();, which makes 3 extra fields 
# for each table in @two_tables that have the same data as the normal tables (used for updating)
# as well as an extra hidden field  new_$counter (value new) which flags as new data (for inserting)
# and an edit_time_$counter field for the timestamp for that field.  Update &oneEdit(); to
# check for the new_$counter field and if there, make INSERTs appropriately (for the 5 field pg
# tables in general, and for the 3 field pg tables in case of comment and groups)  2002 07 15
#
# Fixed error in INSERT to different types of fields (2 vs 4 column tables)  2002 07 17
 
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
my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_comment two_groups);

my $frontpage = 1;			# show the front page on first load

&printHeader('One-Editor');
&display();
&printFooter();

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Pick !') {
    &onePick();
  } # if ($action eq 'Pick !')

  elsif ($action eq 'Edit !') {
    &oneEdit();
  }
} # sub display

sub oneEdit {
#   print "editing<BR>\n";
  my $oop;				# initialize $oop
  if ($query->param('two_number')) { $oop = $query->param('two_number'); } 
    else { $oop = 'nodatahere'; }
  my $two_number = untaint($oop);
  print "two_number : $two_number<BR>\n";
  if ($query->param('counter')) { $oop = $query->param('counter'); } 
    else { $oop = 'nodatahere'; }
  my $counter = untaint($oop);
  print "counter : $counter<BR>\n";
  if ($counter & $two_number) { 	# check we've got a number and data
    for (my $i=0; $i<$counter; $i++) {
      if ($query->param("che_$i")) { 	# check each for changed data
        print "$i : "; 
        if ($query->param("table_$i")) { $oop = $query->param("table_$i"); }
          else { $oop = 'nodatahere'; }
        my $table = untaint($oop);
        if ($query->param("val_$i")) { $oop = $query->param("val_$i"); }
          else { $oop = 'nodatahere'; }
        my $val = untaint($oop);
        if ($query->param("old_val_$i")) { $oop = $query->param("old_val_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_val = untaint($oop);
        if ($query->param("time_$i")) { $oop = $query->param("time_$i"); }
          else { $oop = 'nodatahere'; }
        my $time = untaint($oop);
        if ($query->param("old_time_$i")) { $oop = $query->param("old_time_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_time = untaint($oop);
        if ($query->param("new_$i")) { $oop = $query->param("new_$i"); }
          else { $oop = 'nodatahere'; }
        my $new_flag = untaint($oop);
        if ($query->param("edit_time_$i")) { $oop = $query->param("edit_time_$i"); }
          else { $oop = 'nodatahere'; }
        my $edit_time = untaint($oop);
        if ($new_flag ne 'nodatahere') { 	# new entry, not update
          if ($time eq 'nodatahere') {		# two field stuff (no two_groups or extra time)
            print "VAL INSERT INTO $table VALUES \( \'$two_number\', \'$val\', \'$edit_time\' \)<BR>\n";
            $val =~ s/\'/\\\'/g;
            my $result = $conn->exec( "INSERT INTO $table VALUES \( \'$two_number\', \'$val\', \'$edit_time\' \)" );
          } else { # if ($time eq 'nodatahere') # four field stuff (with two_groups and extra time)
            print "TIME INSERT INTO $table VALUES \( \'$two_number\', \'$val\', \'$time\', \'$edit_time\' \)<BR>\n";
            $time =~ s/\'/\\\'/g;
            my $result = $conn->exec( "INSERT INTO $table VALUES \( \'$two_number\', \'$val\', \'$time\', \'$edit_time\' \)" );
          } # else # if ($time eq 'nodatahere') # four field stuff (with two_groups and extra time)
        } # if ($new_flag ne 'nodatahere')  	# new entry, not update
        elsif ($table & $val) { 
#           print "$table : $val : $time<BR>\n";
#           print "2 : TAB $table : VAL $val : TIME $time : O_T $old_time : O_V $old_val<BR>\n";
          print "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'<BR>\n";
          $val =~ s/\'/\\\'/g;
          my $result = $conn->exec( "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'" );
        } # if ($table & $val)
        elsif ($table & $time) {
#           print "4 : TAB $table : VAL $val : TIME $time : O_T $old_time : O_V $old_val<BR>\n";
          print "UPDATE $table SET $table = \'$time\' WHERE joinkey = \'$two_number\' AND $table = \'$old_time\'<BR>\n";
          $time =~ s/\'/\\\'/g;
          my $result = $conn->exec( "UPDATE $table SET $table = \'$time\' WHERE joinkey = \'$two_number\' AND $table = \'$old_time\'" );
        } # if ($table & $time)
      } # if ($query->param("che_$i"))
    } # for (my $i=0; $i<$counter; $i++)
  } # if ($counter & $two_number)
#   print "Done<BR>\n";
} # sub oneEdit

sub onePick {
  my $oop;
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  if ($query->param('vals')) { $oop = $query->param('vals'); } 
    else { $oop = 'nodatahere'; }
  my $vals = untaint($oop); 
  print "two : $two : vals : $vals<BR><BR>\n";
  &displayOneDataFromKey($two);
  my @keys = split /\t/, $vals;
  print "<TABLE border=1 cellspacing=5>\n";
  foreach my $key (@keys) {
    if ($key =~ m/^wbg/) { &displayWbgDataFromKey($key); }
    if ($key =~ m/^ace/) { &displayAceDataFromKey($key); }
  } # foreach my $key (@keys)
  print "</TABLE>\n";
} # sub onePick


sub firstPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";

  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR><TD>Stuff</TD><TD>More</TD></TR>\n";

    # populate hash of key twos and values ace/wbg
  my %twos;				# HoA  key = two#, values = ace#, wbg#
  my $result = $conn->exec( "SELECT * FROM two_groups;" );
  while (my @row = $result->fetchrow) {
    push @{ $twos{$row[0]} } , $row[1];
  } # while (my @row = $result->fetchrow)

# foreach my $ent (%twos) {
#   foreach my $twof (@{ $twos{$ent} }) {
#      print "$ent : $twof<BR>\n";
#   }
# }

    # get the highest value in the two table
  $result = $conn->exec( "SELECT last_value FROM two_sequence;" );
  my @row = $result->fetchrow;
  my $highest_val = $row[0];

    # for each two, display it and its values
  for (my $i = 1; $i <= $highest_val; $i++) { 
    my $two = 'two' . $i;
    foreach $_ (@{ $twos{$two} }) { }
    my $vals = join "<BR>", @{ $twos{$two} } ;	# display with breaks
    my $valt = join "\t", @{ $twos{$two} } ;	# pass value with tabs
    print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/oneeditor.cgi\">\n";
    print "<TR><TD>$two</TD><TD>$vals</TD>";
    print "<INPUT TYPE=hidden NAME=two VALUE=\"$i\">";
    print "<INPUT TYPE=hidden NAME=vals VALUE=\"$valt\">";
    print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Pick !\"></TD></TR>\n";
    print "</FORM>\n";
  } # for ($i = 1; $i < $highest_val; $i++)

  print "</TABLE>\n";
} # sub firstPage


### display from key ###

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

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/cecilia/oneeditor.cgi\">\n";
  print "<TABLE border=1 cellspacing=2>\n";
  my $counter = 0;
  foreach my $two_table (@two_tables) {
    my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key';" );
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR><TD>$two_table</TD><TD><INPUT NAME=\"che_$counter\" TYPE=\"checkbox\" ";
        print "VALUE=\"yes\" ></TD>";
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"table_$counter\" VALUE=\"$two_table\">\n";
        print "<TD>$row[0]</TD>"; 
        if ($row[3]) { 			# if it has two dates
          print "<TD><INPUT SIZE=40 NAME=\"val_$counter\" VALUE=\"$row[1]\"></TD>";
          print "<TD><INPUT SIZE=40 NAME=\"time_$counter\" VALUE=\"$row[2]\"></TD>";
          print "<INPUT TYPE=\"HIDDEN\" NAME=\"old_val_$counter\" VALUE=\"$row[1]\">\n";
          print "<INPUT TYPE=\"HIDDEN\" NAME=\"old_time_$counter\" VALUE=\"$row[2]\">\n";
          print "<TD>$row[3]</TD>";
        } else {			# only has one date
          print "<TD><INPUT SIZE=40 NAME=\"val_$counter\" VALUE=\"$row[1]\"></TD>";
          print "<INPUT TYPE=\"HIDDEN\" NAME=\"old_val_$counter\" VALUE=\"$row[1]\">\n";
          print "<TD></TD>";
          print "<TD>$row[2]</TD>";
        }
        $counter++;
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
    $counter = &makeExtraFields($two_table, $counter, 2, $two_key);
  } # foreach my $two_table (@two_tables)
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"counter\" VALUE=\"$counter\">\n";
  print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"Edit !\"></TD></TR>\n";
  print "</TABLE><BR><BR>\n";
  print "</FORM>\n";
} # sub displayOneDataFromKey

sub makeExtraFields {
  my ($two_table, $counter, $amount, $two_key) = @_;
  for (0 .. $amount) {
    print "<TR><TD>$two_table</TD><TD><INPUT NAME=\"che_$counter\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\" ></TD>";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"table_$counter\" VALUE=\"$two_table\">\n";
    print "<TD>$two_key</TD>"; 
    print "<TD><INPUT SIZE=40 NAME=\"val_$counter\" VALUE=\"\"></TD>";
    if (($two_table eq 'two_comment') || ($two_table eq 'two_groups')) {
      print "<TD></TD>"; }
    else { print "<TD><INPUT SIZE=40 NAME=\"time_$counter\" VALUE=\"\"></TD>"; }
    print "<TD><INPUT SIZE=40 NAME=\"edit_time_$counter\" VALUE=\"\"></TD>";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"new_$counter\" VALUE=\"new\">\n";
    $counter++;
    print "</TR>\n";
  } # for (0 .. $amount)
  return $counter;
} # sub makeExtraFields

### display from key ###
