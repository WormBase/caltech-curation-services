#!/usr/bin/perl -w

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
# as well as an extra hidden field  new_$counter (value new) which flags as new data (for 
# inserting) and an edit_time_$counter field for the timestamp for that field.  
# Update &oneEdit(); to # check for the new_$counter field and if there, make INSERTs 
# appropriately (for the 5 field pg tables in general, and for the 3 field pg tables in case 
# of comment and groups)  2002 07 15
#
# Fixed error in INSERT to different types of fields (2 vs 4 column tables)  2002 07 17
#
# Edited to have two sets of tables, some for tables with 5 rows of data (4 + joinkey) and 
# another with for tables with 3 rows of data (2 + joinkey)	2002 09 18
#
# Changed two_wormbase_comments to have two timestamps like most fields.  2003 03 19
#
# Added two_standardname to list of @two_tables although it can only have one value.  2003 03 24
# 
# Added two_pis to list of @two_tables 2003 03 24
#
# Added two_hide to flag people that shouldn't show on WormBase.  
# This was essentially done by the table "two" which accounts for existing persons,
# but a script was written to key off last names to create missing two entries,
# overwriting the fact that one was missing, completely getting rid of the point.
# 2003 05 13
#
# Added Lineage stuff at bottom of form in own table in @two_complex.
# Created &makeExtraComplexFields to add extra complex fields to end of form.
# Added postgres commands.  If new, INSERT.  If not new, UPDATE by doing DELETE (and then INSERT)
# If not new and want to be delete, Cecilia will type ``NULL'' in first field, and it will 
# DELETE (and then next to skip INSERT).  2003 11 04
#
# Added tables two_status (only possible values should be ``Valid'' and
# ``Invalid'') two_mergedinto two_acqmerge  2006 11 02
#
# Added type-your-own-number on front page.  2006 11 08
#
# Before editing check if a joinkey has an entry for two and two_status before
# allowing editing.  2006 11 29
#
# Show Invalid in red at the top.  2007 03 13
#
# two_old_institution added.  2008 07 16
#
# update oneEdit data that has 4 things by joinkey and order instead of
# joinkey, order, and what the data said (sometimes the data doesn't match
# somehow, and it shouldn't be necessary to have that extra parameters, since a
# given joinkey and order should narrow it down).  2008 08 28
#
# Converted from Pg.pm to DBI.pm  2009 04 17
#
# Added #Role  Assistant_professor  2009 12 03
#
# Changed year to 2011.  2011 01 03
 
use strict;
use CGI;
use Fcntl;
# use Pg;
use DBI;
use Jex;

my $query = new CGI;

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "");
if ( !defined $dbh ) { die "Cannot connect to database!\n"; }


my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

my @ace_tables = qw(ace_author ace_name ace_lab ace_oldlab ace_address ace_email ace_phone ace_fax);
my @wbg_tables = qw(wbg_title wbg_firstname wbg_middlename wbg_lastname wbg_suffix wbg_street wbg_city wbg_state wbg_post wbg_country wbg_mainphone wbg_labphone wbg_officephone wbg_fax wbg_email);
# my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_comment two_groups);
my @two_tables = qw(two_firstname two_middlename two_lastname two_standardname two_street two_city two_state two_post two_country two_institution two_old_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_pis two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage two_wormbase_comment two_hide two_status two_mergedinto two_acqmerge );
my @two_simpler = qw(two_comment two_groups);
my %two_simpler; foreach my $table (@two_simpler) { $two_simpler{$table}++; }
my @two_complex = qw(two_lineage);

my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my $frontpage = 1;			# show the front page on first load

&printHeader('Two-Editor');
&display();
&printFooter();

sub display {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Page !') {
    &pickPage();
  } # if ($action eq 'Page !')

  if ($action eq 'Pick !') { &onePick(); }
  elsif ($action eq 'Edit !') { &oneEdit(); }
  elsif ($action eq 'Create !') { &createTwo(); }
} # sub display

sub createTwo {				# enter data into tables two and two_status  2006 11 29
  my $oop;				# initialize $oop
  if ($query->param('two')) { $oop = $query->param('two'); } 
    else { $oop = 'nodatahere'; }
  my $two = untaint($oop);
  print "TWO $two T<BR>\n";
  my $joinkey = 'two' . $two;
  my $command = "INSERT INTO two VALUES ( '$joinkey', '$two', CURRENT_TIMESTAMP );" ;
  print "$command<BR>\n";
#   my $result = $conn->exec( $command );
  my $result = $dbh->prepare( $command );
  $result->execute;
  $command = "INSERT INTO two_status VALUES ( '$joinkey', '1', 'Valid', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP );" ;
  print "$command<BR>\n";
#   $result = $conn->exec( $command );
  $result = $dbh->prepare( $command );
  $result->execute;
  &onePick();				# after creating, immediately show the Edit window
} # sub createTwo

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

    # Contact Info section separate from Lineage
  if ($counter & $two_number) { 	# check we've got a number and data
    for (my $i=0; $i<$counter; $i++) {
      if ($query->param("che_$i")) { 	# check each for changed data
        print "counter : $i : "; 
        if ($query->param("table_$i")) { $oop = $query->param("table_$i"); }
          else { $oop = 'nodatahere'; }
        my $table = untaint($oop);
        if ($query->param("num_$i")) { $oop = $query->param("num_$i"); }
          else { $oop = 'nodatahere'; }
        my $num = untaint($oop);
        if ($query->param("old_num_$i")) { $oop = $query->param("old_num_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_num = untaint($oop);
        if ($query->param("val_$i")) { $oop = $query->param("val_$i"); }
          else { $oop = 'nodatahere'; }
        my $val = untaint($oop);
        if ($query->param("old_val_$i")) { $oop = $query->param("old_val_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_val = untaint($oop);
        if ($query->param("time_$i")) { $oop = $query->param("time_$i"); }
          else { $oop = 'nodatahere'; }
        my $time = untaint($oop);
        if ($time =~ m/^\s*[nN][oO][wW]\s*$/) { $time = "CURRENT_TIMESTAMP"; } else { $time = "\'$time\'"; }
        if ($query->param("old_time_$i")) { $oop = $query->param("old_time_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_time = untaint($oop); if ($old_time eq 'nodatahere') { $old_time = 'now'; }
        if ($old_time =~ m/^\s*[nN][oO][wW]\s*$/) { $old_time = "CURRENT_TIMESTAMP"; } else { $old_time = "\'$old_time\'"; }
        if ($query->param("new_$i")) { $oop = $query->param("new_$i"); }
          else { $oop = 'nodatahere'; }
        my $new_flag = untaint($oop);

        if ($new_flag ne 'nodatahere') { 	# new entry, not update
#           if ($time eq 'nodatahere') { # }	# two field stuff 	# i think this was always wrong, not sure how timestamps work here  2008 09 02
          if ($two_simpler{$table}) {
            print "<FONT COLOR='orange'>\n";
            print "TWO INSERT INTO $table VALUES \( \'$two_number\', \'$val\' \)<BR>\n";
            print "</FONT>\n";
            $val =~ s/\'/\\\'/g; $val =~ s/\"/\\\"/g; $val =~ s/^\s+//g; $val =~ s/\s+$//g;
#             my $result = $conn->exec( "INSERT INTO $table VALUES \( \'$two_number\', \'$val\' \)" );
            my $result = $dbh->prepare( "INSERT INTO $table VALUES \( \'$two_number\', \'$val\' \)" );
            $result->execute;

          } else {				# four field stuff (with two_groups and extra time)
            print "<FONT COLOR='$red'>\n";
            print "FOUR INSERT INTO $table VALUES \( \'$two_number\', \'$num\', \'$val\', $time \)<BR>\n";
            print "</FONT>\n";
            $val =~ s/\'/\\\'/g; $val =~ s/\"/\\\"/g; $val =~ s/^\s+//g; $val =~ s/\s+$//g;
#             my $result = $conn->exec( "INSERT INTO $table VALUES \( \'$two_number\', \'$num\', \'$val\', $time \)" );
            my $result = $dbh->prepare( "INSERT INTO $table VALUES \( \'$two_number\', \'$num\', \'$val\', $time \)" );
            $result->execute;
          } # else # if ($time eq 'nodatahere') 

        } # if ($new_flag ne 'nodatahere')  	# new entry, not update

        elsif ($two_simpler{$table}) {
#         elsif ($num eq 'nodatahere') { # }		# update 2s	# using the two %two_simpler is more proper if a $num is missing by mistake  2008 09 02
#           print "$table : $val : $old_time<BR>\n";
#           print "2 : TAB $table : VAL $val : TIME $time : O_T $old_time : O_V $old_val<BR>\n";
          print "<FONT COLOR='green'>\n";
          print "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'<BR>\n";
          print "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'<BR>\n";
          print "</FONT>\n";
          $val =~ s/\'/\\\'/g;
          $val =~ s/\"/\\\"/g;
          $val =~ s/^\s+//g; $val =~ s/\s+$//g;
          $old_val =~ s/\'/\\\'/g;
          $old_val =~ s/\"/\\\"/g;
          $old_val =~ s/^\s+//g; $old_val =~ s/\s+$//g;
#           my $result = $conn->exec( "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'" );
          my $result = $dbh->prepare( "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'" );
          $result->execute;
#           $result = $conn->exec( "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'" );
          $result = $dbh->prepare( "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\'" );
          $result->execute;

        } else {				# update 4s
#           print "4 : TAB $table : VAL $val : TIME $time : O_T $old_time : O_V $old_val<BR>\n";
          print "<FONT COLOR='$blue'>\n";
#           print "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND $table = \'$old_val\' AND two_order = \'$num\'<BR>\n";
#           print "UPDATE $table SET old_timestamp = \'$time\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\' AND two_order = \'$num\'<BR>\n";
#           print "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\' AND two_order = \'$num\'<BR>\n";
          print "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND two_order = \'$num\'<BR>\n";
          print "UPDATE $table SET old_timestamp = $time WHERE joinkey = \'$two_number\' AND two_order = \'$num\'<BR>\n";
          print "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND two_order = \'$num\'<BR>\n";
          print "</FONT>\n";
#           $time =~ s/\'/\\\'/g; $time =~ s/\"/\\\"/g;
          $val =~ s/\'/\\\'/g; $val =~ s/\"/\\\"/g; $val =~ s/^\s+//g; $val =~ s/\s+$//g;
          $old_val =~ s/\'/\\\'/g; $old_val =~ s/\"/\\\"/g; $old_val =~ s/^\s+//g; $old_val =~ s/\s+$//g;
#           my $result = $conn->exec( "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND $table = \'$old_val\' AND two_order = \'$num\'" );
#           $result = $conn->exec( "UPDATE $table SET old_timestamp = \'$time\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\' AND two_order = \'$num\'" );
#           $result = $conn->exec( "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND $table = \'$old_val\' AND two_order = \'$num\'" );
#           my $result = $conn->exec( "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND two_order = \'$num\'" );
          my $result = $dbh->prepare( "UPDATE $table SET two_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$two_number\' AND two_order = \'$num\'" );
          $result->execute;
#           $result = $conn->exec( "UPDATE $table SET old_timestamp = $time WHERE joinkey = \'$two_number\' AND two_order = \'$num\'" );
          $result = $dbh->prepare( "UPDATE $table SET old_timestamp = $time WHERE joinkey = \'$two_number\' AND two_order = \'$num\'" );
          $result->execute;
#           $result = $conn->exec( "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND two_order = \'$num\'" );
          $result = $dbh->prepare( "UPDATE $table SET $table = \'$val\' WHERE joinkey = \'$two_number\' AND two_order = \'$num\'" );
          $result->execute;
        } 

      } # if ($query->param("che_$i"))
    } # for (my $i=0; $i<$counter; $i++)
  } # if ($counter & $two_number)
    # End of Contact info section

    # Lineage stuff done separetly from Contact Info
  if ($query->param('counter2')) { $oop = $query->param('counter2'); } 
    else { $oop = 'nodatahere'; }
  my $counter2 = untaint($oop);
  print "counter2 : $counter2<BR>\n";
  if (($counter2 ne "") && ($two_number ne "")) { 	# check we've got a number and data
    for (my $i=0; $i<$counter2; $i++) {
      if ($query->param("che2_$i")) { 	# check each for changed data
        print "<BR>counter2 : $i : <BR>"; 
        if ($query->param("table2_$i")) { $oop = $query->param("table2_$i"); }
          else { $oop = 'nodatahere'; }
        my $table = untaint($oop);
        if ($query->param("sentname_$i")) { $oop = $query->param("sentname_$i"); }
          else { $oop = 'nodatahere'; }
        my $sentname= untaint($oop);
        if ($query->param("old_sentname_$i")) { $oop = $query->param("old_sentname_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_sentname= untaint($oop);
        if ($query->param("othername_$i")) { $oop = $query->param("othername_$i"); }
          else { $oop = 'nodatahere'; }
        my $othername= untaint($oop);
        if ($query->param("old_othername_$i")) { $oop = $query->param("old_othername_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_othername= untaint($oop);
        if ($query->param("othernum_$i")) { $oop = $query->param("othernum_$i"); }
          else { $oop = 'nodatahere'; }
        my $othernum= untaint($oop);
        if ($query->param("old_othernum_$i")) { $oop = $query->param("old_othernum_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_othernum= untaint($oop);
        if ($query->param("role_$i")) { $oop = $query->param("role_$i"); }
          else { $oop = 'nodatahere'; }
        my $role= untaint($oop);
        if ($query->param("old_role_$i")) { $oop = $query->param("old_role_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_role= untaint($oop);
        if ($query->param("year1_$i")) { $oop = $query->param("year1_$i"); }
          else { $oop = 'nodatahere'; }
        my $year1= untaint($oop);
        if ($query->param("old_year1_$i")) { $oop = $query->param("old_year1_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_year1= untaint($oop);
        if ($query->param("year2_$i")) { $oop = $query->param("year2_$i"); }
          else { $oop = 'nodatahere'; }
        my $year2= untaint($oop);
        if ($query->param("old_year2_$i")) { $oop = $query->param("year2_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_year2= untaint($oop);
        if ($query->param("sender_$i")) { $oop = $query->param("sender_$i"); }
          else { $oop = 'nodatahere'; }
        my $sender= untaint($oop);
        if ($query->param("old_sender_$i")) { $oop = $query->param("old_sender_$i"); }
          else { $oop = 'nodatahere'; }
        my $old_sender= untaint($oop);

        if ($query->param("new2_$i")) { $oop = $query->param("new_$i"); }
          else { $oop = 'nodatahere'; }
        my $new_flag = untaint($oop);
        my $reverse_old_role = $old_role;		# get reverse
        if ($reverse_old_role eq 'Collaborated') { } 
          elsif ($reverse_old_role =~ m/^with/ ) { $reverse_old_role =~ s/with//g; } 
          else { $reverse_old_role = "with$reverse_old_role"; }
        my $reverse_role = $role;			# get reverse
        if ($reverse_role eq 'Collaborated') { } 
          elsif ($reverse_role =~ m/^with/ ) { $reverse_role =~ s/with//g; } 
          else { $reverse_role = "with$reverse_role"; }
        if ($new_flag ne 'nodatahere') { 	# new entry, not update
          print "INSERT STUFF<BR>\n";
        } else { 
          print "UPDATE STUFF<BR>\n";
          my $command1 = "DELETE FROM two_lineage WHERE joinkey = '$two_number' AND two_othername = '$old_othername' AND two_number = '$old_othernum' and two_role = '$old_role';";
          if ($command1 =~ m/= \'nodatahere\'/) { $command1 =~ s/= \'nodatahere\'/IS NULL/g; }	# fix blank
          print "$command1<BR>\n"; 
#           my $result = $conn->exec( $command1 );	# delete forward
          my $result = $dbh->prepare( $command1 );	# delete forward
          $result->execute;
	  my $command2 = "DELETE FROM two_lineage WHERE two_number = '$two_number' AND two_sentname = '$old_othername' AND joinkey = '$old_othernum' and two_role = '$reverse_old_role';";
          if ($command2 =~ m/= \'nodatahere\'/) { $command2 =~ s/= \'nodatahere\'/IS NULL/g; }	# fix blank
          print "$command2<BR>\n"; 	# delete forward
#           $result = $conn->exec( $command2 );		# delete reverse
          $result = $dbh->prepare( $command2 );		# delete reverse
          $result->execute;
        }
        if ($sentname eq 'NULL') { next; }		# if Cecilia wants to delete, will make $sentname be NULL (skip inserts)
	my $command1 = "INSERT INTO $table VALUES ('$two_number', '$sentname', '$othername', '$othernum', '$role', '$year1', '$year2', '$sender', CURRENT_TIMESTAMP); "; 
        if ($command1 =~ m/\'nodatahere\'/) { $command1 =~ s/\'nodatahere\'/NULL/g; }		# fix blank
        print "$command1<BR>\n"; 
#         my $result = $conn->exec( $command1 );		# insert forward
        my $result = $dbh->prepare( $command1 );		# insert forward
        $result->execute;
	my $command2 = "INSERT INTO $table VALUES ('$othernum', '$othername', '$sentname', '$two_number', '$reverse_role', '$year1', '$year2', 'REV - $sender', CURRENT_TIMESTAMP); "; 
        if ($command2 =~ m/REV - nodatahere/) { $command2 =~ s/\'REV - nodatahere\'/NULL/g; }	# fix blank
        if ($command2 =~ m/REV - REV -/) { $command2 =~ s/REV - REV -//g; }			# get rid of double Reverse
        if ($command2 =~ m/\'nodatahere\'/) { $command2 =~ s/\'nodatahere\'/NULL/g; }		# fix blank
        print "$command2<BR>\n"; 
#         $result = $conn->exec( $command2 );		# insert reverse
        $result = $dbh->prepare( $command2 );		# insert reverse
        $result->execute;
# 	  print "<BR>\n";
#         print "TABLE $table<BR>\n";
#         print "NAME $othername OLD $old_othername<BR>\n";
#         print "NUM $othernum OLD $old_othernum<BR>\n";
#         print "ROLE $role OLD $old_role<BR>\n";
#         print "YEAR1 $year1 OLD $old_year1<BR>\n";
#         print "YEAR2 $year2 OLD $old_year2<BR>\n";
#         print "SENDER $sender OLD $old_sender<BR>\n";
	# NEED TO THINK OF HOW TO DEAL WITH PG HERE
      } # if ($query->param("che2_$i"))
    } # for (my $i=0; $i<$counter2; $i++)
  } # if ($counter2 & $two_number)
    # End of Lineage section

  print "<P>Done<BR>\n";
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
  my ($flag) = &checkTwoExists($two);
  return if ($flag ne 'good');
  &displayOneDataFromKey($two);
  my @keys = split /\t/, $vals;
  print "<TABLE border=1 cellspacing=5>\n";
  foreach my $key (@keys) {
    if ($key =~ m/^wbg/) { &displayWbgDataFromKey($key); }
    if ($key =~ m/^ace/) { &displayAceDataFromKey($key); }
  } # foreach my $key (@keys)
  print "</TABLE>\n";
} # sub onePick

sub checkTwoExists {
  my $two = shift;
#   my $result = $conn->exec( "SELECT two FROM two WHERE two = '$two';" );
  my $result = $dbh->prepare( "SELECT two FROM two WHERE two = '$two';" );
  $result->execute;
  my @row = $result->fetchrow;
  if ($row[0]) { return 'good'; }
    else { print "This is a new two.  <A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/twoeditor.cgi?two=$two&action=Create+%21\">Create ?</A><BR>\n"; }
} # sub checkTwoExists


sub firstPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";

# <A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_display.cgi?number=$joinkey&action=Number+%21\" TARGET=new>
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/twoeditor.cgi\">\n";
  print "<P><BR><CENTER>Select a two number : <INPUT NAME=\"two\"><INPUT TYPE=submit NAME=action VALUE=\"Pick !\"></CENTER><P><BR>\n";
  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR>\n";
  my $counter = 1;
  for (my $i = 1; $i<10000; $i = $i+50) {
    if ($counter > 500) { $counter = 1; print "</TR><TR>\n"; }
    $counter += 50;                     # up the counter, must always be less than 500 for display
    my $j = $i + 49;                    # j is just i + 49 for display
    print "<TD>Two $i - $j</TD><TD><INPUT NAME=\"two_num\" TYPE=\"radio\" VALUE=\"$i\"></TD>\n";
    if ($counter > 500) { $counter = 1; print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Page !\"></TD></TR>\n"; }
  } # for (my $i = 1; $i<2000; $i = $i+50)
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Page !\"></TD></TR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub firstPage

sub pickPage {
  my $date = &getDate();
  print "Value : $date<BR>\n";

  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR><TD>Two</TD><TD>Grouped</TD></TR>\n";

  my $oop;
  if ($query->param('two_num')) { $oop = $query->param('two_num'); } 
    else { $oop = 'nodatahere'; }
  my $two_num = untaint($oop);
  my $highest_val = $two_num + 50;

    # populate hash of key twos and values ace/wbg
  my %twos;				# HoA  key = two#, values = ace#, wbg#
#   my $result = $conn->exec( "SELECT * FROM two_groups;" );
  my $result = $dbh->prepare( "SELECT * FROM two_groups;" );
  $result->execute;
  while (my @row = $result->fetchrow) {
    push @{ $twos{$row[0]} } , $row[1];
  } # while (my @row = $result->fetchrow)

    # get the highest value in the two table
#   $result = $conn->exec( "SELECT last_value FROM two_sequence;" );
#   my @row = $result->fetchrow;
#   my $highest_val = $row[0];

    # for each two, display it and its values
  for (my $i = $two_num; $i <= $highest_val; $i++) { 
    my $two = 'two' . $i;
    foreach $_ (@{ $twos{$two} }) { }
    my $vals = join "<BR>", @{ $twos{$two} } ;	# display with breaks
    my $valt = join "\t", @{ $twos{$two} } ;	# pass value with tabs
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/twoeditor.cgi\">\n";
    print "<TR><TD>$two</TD><TD>$vals</TD>";
    print "<INPUT TYPE=hidden NAME=two VALUE=\"$i\">";
    print "<INPUT TYPE=hidden NAME=vals VALUE=\"$valt\">";
    print "<TD><INPUT TYPE=submit NAME=action VALUE=\"Pick !\"></TD></TR>\n";
    print "</FORM>\n";
  } # for ($i = 1; $i < $highest_val; $i++)

  print "</TABLE>\n";
} # sub pickPage


### display from key ###

sub displayOneDataFromKey {
  my ($two_key) = 'two' . $_[0];
#   my $result = $conn->exec( "SELECT * FROM two_status WHERE joinkey = '$two_key' ORDER BY two_order;" );
  my $result = $dbh->prepare( "SELECT * FROM two_status WHERE joinkey = '$two_key' ORDER BY two_order;" );
  $result->execute;
  my @row = $result->fetchrow; if ($row[2]) { if ($row[2] eq 'Invalid') { print "<FONT SIZE=+2 COLOR=red>INVALID</FONT><P>\n"; } }
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/twoeditor.cgi\">\n";
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"Edit !\"></TD></TR>\n";
  my $counter = 0;
  foreach my $two_table (@two_tables) {
#     my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $two_table WHERE joinkey = '$two_key';" );
    $result->execute;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
        print "  <TD><INPUT NAME=\"che_$counter\" TYPE=\"checkbox\" VALUE=\"yes\" ></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"table_$counter\" VALUE=\"$two_table\">\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD><INPUT SIZE=5 NAME=\"num_$counter\" VALUE=\"$row[1]\"></TD>\n";
        print "  <TD><INPUT SIZE=40 NAME=\"val_$counter\" VALUE=\"$row[2]\"></TD>\n";
        print "  <TD><INPUT SIZE=40 NAME=\"time_$counter\" VALUE=\"$row[3]\"></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_num_$counter\" VALUE=\"$row[1]\">\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_val_$counter\" VALUE=\"$row[2]\">\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_time_$counter\" VALUE=\"$row[3]\">\n";
        $counter++;
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
    if ($two_table eq 'two_street') { $counter = &makeExtraFields($two_table, $counter, 3, $two_key); }
    else { $counter = &makeExtraFields($two_table, $counter, 2, $two_key); }
  } # foreach my $two_table (@two_tables)

  foreach my $two_simpler (@two_simpler) {
#     my $result = $conn->exec( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key' ORDER BY two_timestamp DESC;" );
    my $result = $dbh->prepare( "SELECT * FROM $two_simpler WHERE joinkey = '$two_key' ORDER BY two_timestamp DESC;" );
    $result->execute;
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"two_number\" VALUE=\"$two_key\">\n";
    while (my @row = $result->fetchrow) {
      if ($row[1]) { if ($row[1] ne 'nodatahere') { 	# don't show blanked lines  2008 07 15
        print "<TR bgcolor='$blue'>\n  <TD>$two_simpler</TD>\n";
        print "  <TD><INPUT NAME=\"che_$counter\" TYPE=\"checkbox\" VALUE=\"yes\" ></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"table_$counter\" VALUE=\"$two_simpler\">\n";
        print "  <TD>$row[0]</TD>\n"; 
        print "  <TD>&nbsp;</TD>\n"; 
        print "  <TD><INPUT SIZE=40 NAME=\"val_$counter\" VALUE=\"$row[1]\"></TD>\n";
        print "  <TD><INPUT SIZE=40 NAME=\"time_$counter\" VALUE=\"$row[2]\"></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_val_$counter\" VALUE=\"$row[1]\">\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_time_$counter\" VALUE=\"$row[2]\">\n";
        $counter++;
        print "</TR>\n";
      } } # if ($row[1])
    } # while (my @row = $result->fetchrow)
    $counter = &makeExtraFields($two_simpler, $counter, 2, $two_key);
  } # foreach my $two_simpler (@two_simpler)
  print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"Edit !\"></TD></TR>\n";
  print "</TABLE><BR><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"counter\" VALUE=\"$counter\">\n";

  my $counter2 = 0;
  print "<TABLE border=1 cellspacing=2>\n";
  print "<TR><TD align=center>table</TD><TD align=center>check</TD><TD align=center>Sent Name</TD>
	     <TD align=center>Other Name</TD><TD align=center>Person TWO</TD><TD align=center>Role</TD>
	     <TD align=center>Start Year</TD> <TD align=center>End Year</TD><TD align=center>Sender</TD></TR>\n";
  foreach my $two_complex (@two_complex) {
#     my $result = $conn->exec( "SELECT * FROM $two_complex WHERE joinkey = '$two_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $two_complex WHERE joinkey = '$two_key';" );
    $result->execute;
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        print "<TR bgcolor='$blue'>\n  <TD>$two_complex</TD>\n";
        print "  <TD><INPUT NAME=\"che2_$counter2\" TYPE=\"checkbox\" VALUE=\"yes\" ></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"table2_$counter2\" VALUE=\"$two_complex\">\n";
        print "  <TD><INPUT SIZE=20 NAME=\"sentname_$counter2\" VALUE=\"$row[1]\"></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_sentname_$counter2\" VALUE=\"$row[1]\">\n";
        print "  <TD><INPUT SIZE=20 NAME=\"othername_$counter2\" VALUE=\"$row[2]\"></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_othername_$counter2\" VALUE=\"$row[2]\">\n";
        print "  <TD><INPUT SIZE=20 NAME=\"othernum_$counter2\" VALUE=\"$row[3]\"></TD>\n";
        print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_othernum_$counter2\" VALUE=\"$row[3]\">\n";

#         print "  <TD><INPUT SIZE=20 NAME=\"role_$counter2\" VALUE=\"$row[4]\"></TD>\n";
        print "  <TD><SELECT NAME=\"role_$counter2\" SIZE=1>\n";
        if ($row[4]) { &printSelectedOption($row[4]); }
        print "    <OPTION VALUE=withPhd>Trained as a PhD with</OPTION>\n";
        print "    <OPTION VALUE=withPostdoc>Trained as a Postdoc with</OPTION>\n";
        print "    <OPTION VALUE=withMasters>Trained as a Masters with</OPTION>\n";
        print "    <OPTION VALUE=withUndergrad>Trained as an Undergrad with</OPTION>\n";
        print "    <OPTION VALUE=withHighschool>Trained as a High School student with</OPTION>\n";
        print "    <OPTION VALUE=withSabbatical>Trained for a Sabbatical with</OPTION>\n";
        print "    <OPTION VALUE=withLab_visitor>Trained as a Lab Visitor with</OPTION>\n";
        print "    <OPTION VALUE=withResearch_staff>Trained as a Research Staff with</OPTION>\n";
        print "    <OPTION VALUE=withAssistant_professor>Trained as an Assistant Professor with</OPTION>\n";
        print "    <OPTION VALUE=withUnknown>Trained as an Unknown with</OPTION>\n";
        print "    <OPTION VALUE=Phd>Trained PhD</OPTION>\n";
        print "    <OPTION VALUE=Postdoc>Trained Postdoc</OPTION>\n";
        print "    <OPTION VALUE=Masters>Trained Masters</OPTION>\n";
        print "    <OPTION VALUE=Undergrad>Trained Undergrad</OPTION>\n";
        print "    <OPTION VALUE=Highschool>Trained High School student</OPTION>\n";
        print "    <OPTION VALUE=Sabbatical>Trained for a Sabbatical</OPTION>\n";
        print "    <OPTION VALUE=Lab_visitor>Trained Lab Visitor</OPTION>\n";
        print "    <OPTION VALUE=Research_staff>Trained Research Staff</OPTION>\n";
        print "    <OPTION VALUE=Assistant_professor>Trained Assistant Professor</OPTION>\n";
        print "    <OPTION VALUE=Unknown>Trained Unknown</OPTION>\n";
        print "    <OPTION VALUE=Collaborated>Collaborated with</OPTION>\n";
        print "  </SELECT></TD>\n";
        if ($row[4]) { print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_role_$counter2\" VALUE=\"$row[4]\">\n"; }
          else { print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_role_$counter2\" VALUE=\"\">\n"; }

        print "    <TD><SELECT NAME=\"year1_$counter2\" SIZE=1>\n";
        if ($row[5]) { print "      <OPTION>$row[5]</OPTION>\n"; }
        print "      <OPTION></OPTION>\n";
        my $year = 2011;
        while ($year > 1900) { print "      <OPTION>$year</OPTION>\n"; $year--; }
        print "    </SELECT></TD>\n";
        if ($row[5]) {  print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_year1_$counter2\" VALUE=\"$row[5]\">\n"; }
          else { print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_year1_$counter2\" VALUE=\"\">\n"; }

        print "    <TD><SELECT NAME=\"year2_$counter2\" SIZE=1>\n";
        if ($row[6]) { print "      <OPTION>$row[6]</OPTION>\n"; }
        print "      <OPTION></OPTION>\n";
        $year = 2011;
        while ($year > 1900) { print "      <OPTION>$year</OPTION>\n"; $year--; }
        print "    </SELECT></TD>\n";
        if ($row[6]) {  print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_year2_$counter2\" VALUE=\"$row[6]\">\n"; }
          else { print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_year2_$counter2\" VALUE=\"\">\n"; }

        if ($row[7]) {
          print "  <TD><INPUT SIZE=20 NAME=\"sender_$counter2\" VALUE=\"$row[7]\"></TD>\n"; 
          print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_sender_$counter2\" VALUE=\"$row[7]\">\n"; }
        else { 
          print "  <TD><INPUT SIZE=20 NAME=\"sender_$counter2\" VALUE=\"\"></TD>\n"; 
          print "  <INPUT TYPE=\"HIDDEN\" NAME=\"old_sender_$counter2\" VALUE=\"\">\n"; }

        $counter2++;
        print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
    $counter2 = &makeExtraComplexFields($two_complex, $counter2, 3, $two_key);
  } # foreach my $two_simpler (@two_simpler)
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"counter2\" VALUE=\"$counter2\">\n";
  print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"Edit !\"></TD></TR>\n";

  print "</TABLE><BR><BR>\n";
  print "</FORM>\n";
} # sub displayOneDataFromKey

sub makeExtraComplexFields {
  my ($two_table, $counter2, $amount, $two_key) = @_;
  for (0 .. $amount) {
    print "<TR bgcolor='$red'>\n";
    print "  <TD>$two_table</TD>\n";
    print "  <TD><INPUT NAME=\"che2_$counter2\" TYPE=\"checkbox\" VALUE=\"yes\" ></TD>\n";
    print "  <INPUT TYPE=\"HIDDEN\" NAME=\"table2_$counter2\" VALUE=\"$two_table\">\n";
    print "  <TD><INPUT SIZE=20 NAME=\"sentname_$counter2\" VALUE=\"\"></TD>\n";
    print "  <TD><INPUT SIZE=20 NAME=\"othername_$counter2\" VALUE=\"\"></TD>\n";
    print "  <TD><INPUT SIZE=20 NAME=\"othernum_$counter2\" VALUE=\"\"></TD>\n";

    print "  <TD><SELECT NAME=\"role_$counter2\" SIZE=1>\n";
    print "    <OPTION VALUE=withPhd>Trained as a PhD with</OPTION>\n";
    print "    <OPTION VALUE=withPostdoc>Trained as a Postdoc with</OPTION>\n";
    print "    <OPTION VALUE=withMasters>Trained as a Masters with</OPTION>\n";
    print "    <OPTION VALUE=withUndergrad>Trained as an Undergrad with</OPTION>\n";
    print "    <OPTION VALUE=withHighschool>Trained as a High School student with</OPTION>\n";
    print "    <OPTION VALUE=withSabbatical>Trained for a Sabbatical with</OPTION>\n";
    print "    <OPTION VALUE=withLab_visitor>Trained as a Lab Visitor with</OPTION>\n";
    print "    <OPTION VALUE=withResearch_staff>Trained as an Research Staff with</OPTION>\n";
    print "    <OPTION VALUE=withAssistant_professor>Trained as an Assistant Professor with</OPTION>\n";
    print "    <OPTION VALUE=withUnknown>Trained as an Unknown with</OPTION>\n";
    print "    <OPTION VALUE=Phd>Trained PhD</OPTION>\n";
    print "    <OPTION VALUE=Postdoc>Trained Postdoc</OPTION>\n";
    print "    <OPTION VALUE=Masters>Trained Masters</OPTION>\n";
    print "    <OPTION VALUE=Undergrad>Trained Undergrad</OPTION>\n";
    print "    <OPTION VALUE=Highschool>Trained High School student</OPTION>\n";
    print "    <OPTION VALUE=Sabbatical>Trained for a Sabbatical</OPTION>\n";
    print "    <OPTION VALUE=Lab_visitor>Trained Lab Visitor</OPTION>\n";
    print "    <OPTION VALUE=Research_staff>Trained Research Staff</OPTION>\n";
    print "    <OPTION VALUE=Assistant_professor>Trained Assistant Professor</OPTION>\n";
    print "    <OPTION VALUE=Unknown>Trained Unknown</OPTION>\n";
    print "    <OPTION VALUE=Collaborated>Collaborated with</OPTION>\n";
    print "  </SELECT></TD>\n";

    print "    <TD><SELECT NAME=\"year1_$counter2\" SIZE=1>\n";
    print "      <OPTION></OPTION>\n";
    my $year = 2011;
    while ($year > 1900) { print "      <OPTION>$year</OPTION>\n"; $year--; }
    print "    </SELECT></TD>\n";

    print "    <TD><SELECT NAME=\"year2_$counter2\" SIZE=1>\n";
    print "      <OPTION></OPTION>\n";
    $year = 2011;
    while ($year > 1900) { print "      <OPTION>$year</OPTION>\n"; $year--; }
    print "    </SELECT></TD>\n";

    print "  <TD><INPUT SIZE=20 NAME=\"sender_$counter2\" VALUE=\"\"></TD>\n";

    print "  <INPUT TYPE=\"HIDDEN\" NAME=\"new2_$counter2\" VALUE=\"new\">\n";
    $counter2++;
    print "</TR>\n";
  } # for (0 .. $amount)
  return $counter2;
} # sub makeExtraComplexFields


sub makeExtraFields {
  my ($two_table, $counter, $amount, $two_key) = @_;
  for (0 .. $amount) {
    print "<TR bgcolor='$red'>\n";
    print "  <TD>$two_table</TD>\n";
    print "  <TD><INPUT NAME=\"che_$counter\" TYPE=\"checkbox\" VALUE=\"yes\" ></TD>\n";
    print "  <INPUT TYPE=\"HIDDEN\" NAME=\"table_$counter\" VALUE=\"$two_table\">\n";
    print "  <TD>$two_key</TD>\n"; 
    if (($two_table eq 'two_comment') || ($two_table eq 'two_groups')) {
      print "  <TD>&nbsp;</TD>\n"; }
    else { print "  <TD><INPUT SIZE=5 NAME=\"num_$counter\" VALUE=\"\"></TD>\n"; }
    print "  <TD><INPUT SIZE=40 NAME=\"val_$counter\" VALUE=\"\"></TD>\n"; 
    if (($two_table eq 'two_comment') || ($two_table eq 'two_groups')) {
      print "  <TD>&nbsp;</TD>\n"; }
    else { print "  <TD><INPUT SIZE=40 NAME=\"time_$counter\" VALUE=\"\"></TD>\n"; }
    print "  <INPUT TYPE=\"HIDDEN\" NAME=\"new_$counter\" VALUE=\"new\">\n";
    $counter++;
    print "</TR>\n";
  } # for (0 .. $amount)
  return $counter;
} # sub makeExtraFields

sub displayAceDataFromKey {             # show all ace data from a given key in multiline table
  my ($ace_key) = @_;
  print "<TABLE border=1 cellspacing=2>\n";
  foreach my $ace_table (@ace_tables) { # show the data
#     my $result = $conn->exec( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $ace_table WHERE joinkey = '$ace_key';" );
    $result->execute;
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
#     my $result = $conn->exec( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    my $result = $dbh->prepare( "SELECT * FROM $wbg_table WHERE joinkey = '$wbg_key';" );
    $result->execute;
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

### display from key ###

sub printSelectedOption {
  my $role = shift;
  if ($role eq 'withPhd') { print "      <OPTION VALUE=withPhD SELECTED>Trained as a PhD with</OPTION>\n"; }
  elsif ($role eq 'withPostdoc') { print "      <OPTION VALUE=withPostdoc>Trained as a Postdoc with</OPTION>\n"; }
  elsif ($role eq 'withMasters') { print "      <OPTION VALUE=withMasters>Trained as a Masters with</OPTION>\n"; }
  elsif ($role eq 'withUndergrad') { print "      <OPTION VALUE=withUndergrad>Trained as an Undergrad with</OPTION>\n"; }
  elsif ($role eq 'withHighschool') { print "      <OPTION VALUE=withHighschool>Trained as a High School student with</OPTION>\n"; }
  elsif ($role eq 'withSabbatical') { print "      <OPTION VALUE=withSabbatical>Trained for a Sabbatical with</OPTION>\n"; }
  elsif ($role eq 'withLab_visitor') { print "      <OPTION VALUE=withLab_visitor>Trained as a Lab Visitor with</OPTION>\n"; }
  elsif ($role eq 'withResearch_staff') { print "      <OPTION VALUE=withResearch_staff>Trained as a Research Staff with</OPTION>\n"; }
  elsif ($role eq 'withAssistant_professor') { print "      <OPTION VALUE=withAssistant_professor>Trained as an Assistant Professor with</OPTION>\n"; }
  elsif ($role eq 'withUnknown') { print "      <OPTION VALUE=withUnknown>Trained as an Unknown with</OPTION>\n"; }
  elsif ($role eq 'Phd') { print "      <OPTION VALUE=Phd>Trained PhD</OPTION>\n"; }
  elsif ($role eq 'Postdoc') { print "      <OPTION VALUE=Postdoc>Trained Postdoc</OPTION>\n"; }
  elsif ($role eq 'Masters') { print "      <OPTION VALUE=Masters>Trained Masters</OPTION>\n"; }
  elsif ($role eq 'Undergrad') { print "      <OPTION VALUE=Undergrad>Trained Undergrad</OPTION>\n"; }
  elsif ($role eq 'Highschool') { print "      <OPTION VALUE=Highschool>Trained High School student</OPTION>\n"; }
  elsif ($role eq 'Sabbatical') { print "      <OPTION VALUE=Sabbatical>Trained for a Sabbatical</OPTION>\n"; }
  elsif ($role eq 'Lab_visitor') { print "      <OPTION VALUE=Lab_visitor>Trained Lab Visitor</OPTION>\n"; }
  elsif ($role eq 'Research_staff') { print "      <OPTION VALUE=Research_staff>Trained Research Staff</OPTION>\n"; }
  elsif ($role eq 'Assistant_professor') { print "      <OPTION VALUE=Assistant_professor>Trained Assistant Professor</OPTION>\n"; }
  elsif ($role eq 'Unknown') { print "      <OPTION VALUE=Unknown>Trained Unknown</OPTION>\n"; }
  elsif ($role eq 'Collaborated') { print "      <OPTION VALUE=Collaborated>Collaborated with</OPTION>\n"; }
  else { 1; }
} # sub printSelectedOption


#           unless ($year1 eq $old_year1) { 
# 	    print "update two_lineage set two_date1 = '$year1' where joinkey = '$two_number' and two_othername = '$old_othername' and two_number = '$old_othernum' and two_role = '$old_role'; <br>\n";
# 	    print "update two_lineage set two_date1 = '$year1' where two_number = '$two_number' and two_sentname = '$old_othername' and joinkey = '$old_othernum' and two_role = '$reverse_old_role'; <br>\n";
# 	  }
#           unless ($year2 eq $old_year2) { 
# 	    print "update two_lineage set two_date2 = '$year2' where joinkey = '$two_number' and two_othername = '$old_othername' and two_number = '$old_othernum' and two_role = '$old_role'; <br>\n";
# 	    print "update two_lineage set two_date2 = '$year2' where two_number = '$two_number' and two_sentname = '$old_othername' and joinkey = '$old_othernum' and two_role = '$reverse_old_role'; <br>\n";
# 	  }
#           unless ($sender eq $old_sender) { 
# 	    print "update two_lineage set two_sender = '$sender' where joinkey = '$two_number' and two_othername = '$old_othername' and two_number = '$old_othernum' and two_role = '$old_role'; <br>\n";
# 	    print "update two_lineage set two_sender = '$sender' where two_number = '$two_number' and two_sentname = '$old_othername' and joinkey = '$old_othernum' and two_role = '$reverse_old_role'; <br>\n";
# 	  }
#           unless ($othername eq $old_othername) { 
# 	    print "update two_lineage set two_othername = '$othername' where joinkey = '$two_number' and two_othername = '$old_othername' and two_number = '$old_othernum' and two_role = '$old_role'; <br>\n";
# 	    print "UPDATE two_lineage SET two_sentname = '$othername' WHERE two_number = '$two_number' AND two_sentname = '$old_othername' AND joinkey = '$old_othernum' and two_role = '$reverse_old_role'; <BR>\n";
#           }
#           unless ($othernum eq $old_othernum) {
# 	    print "UPDATE two_lineage SET two_othername = '$othername' WHERE joinkey = '$two_number' AND two_othername = '$old_othername' AND two_number = '$old_othernum' and two_role = '$old_role'; <BR>\n";
# 	    print "UPDATE two_lineage SET two_sentname = '$othername' WHERE two_number = '$two_number' AND two_sentname = '$old_othername' AND joinkey = '$old_othernum' and two_role = '$reverse_old_role'; <BR>\n";
#           }
#           unless ($role eq $old_role) { 
# 	  }
