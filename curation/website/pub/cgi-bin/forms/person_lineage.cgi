#!/usr/bin/env perl

# Form to submit person lineage information

# Commented out all PG stuff.  Based on 2_pt_data.cgi.
# Required to enter email and WBPerson to connect.  Add XREF type data
# to form some kind of DAG to connect to other people.  At the moment
# only email me and write to a flatfile.  Need to figure out if it
# will be people, and if so whether Cecilia will curate each.  2003 07 09
#
# Ack.  has forgotten to touch + chmod the $acefile.
# Changed box to take up to 5000 chars instead of 50.
# Change Trained With to Trained As (etc.)  
# Created forms@tazendra.caltech.edu to store emails.  2003 10 09
#
# Recreated form in format to connect each person individually
# with a drop down menu for #Role.  Added 2 year fields.  Have
# box to enter amount of connections desired.  Updating that 
# loads previously entered values if any names were typed for
# that field.  .ace output makes more sense so should require
# less parsing.  Parsing to names, and then in separate script
# parsing backwards for #Role seems like a better idea than
# both at once (because then double sent to Cecilia for checking)
# Created person_lineage2.ace in same location to store this data.
# 2003 10 21
#
# Added insertions to postgres to two_lineage.
# Moved this to person_lineage.cgi, using person_lineage.ace
# moved old form to old/person_lineage.cgi.oldform
# 2003 10 27
#
# Changed email address to be forms since person_lineage_data_form
# was bouncing when people replied to it.  Changed beginning year to 
# 1901 since Baillie has someone starting in 1975.   2003 10 28
#
# Added examples as suggested by Curtis Loer.  2003 10 30
#
# Cecilia wants a space in standard name, or a WBPerson.  2005 07 06
#
# Updated to query like the person.cgi and display all existing 
# lineage information (to checkoff if something is false).  Broke up
# &display(); into &displayTop(); and &displayBottom(); to sandwich
# in the existing lineage in between.  2005 10 06
#
# Changed the Display button section to sort existing connections
# by lastname (the count of the lines is out of whack now because 
# of it)  2005 10 07
#
# Added instructions stating that it's allowed to enter WBPerson####
# into the connections instead of name of user.  2006 03 06
#
# Changed Submitter to Your Email, Cecilia to Your Name, Trained as a (.*?) with
# to Trained as a (.*?) under.  2006 03 10
#
# A few changes for Cecilia in layout and emails, no functional change.  
# 2006 05 11
#
# Added a preview page for lineage data.  2006 06 08
#
# Add fullnames in parenthesis if stdname is different   2007 08 22
#
# Changed body of email to 4 weeks / 8 weeks from 6 weeks, since release cycle
# has changed  2008 02 05
#
# Made preview and submit buttons have font be red size be 22.  2008 11 20
#
# New high year current year off of &getSimpleDate();  2009 08 26
#
# Changes to letter.  2009 10 22
#
# Added "present" as option in person_lineage.  2009 10 27
#
# Added #Role "Assistant_professor".  2009 12 03
#
# Made instructions javascript collapsible.  2010 06 09
#
# Changed 8 weeks to 4 months.  2011 10 05
#
# Changed 4 months to release schedule.  2011 10 19
#
# Some changes to introduction, instructions, and email.  2013 11 20
#
# Previewing and getting bad data was displaying the form again but without the data populated.
# Now using  &populateHashFromForm();  to populate it.  Should probably just run that once always,
# and process data based on hash instead of separate queries, but it would be a fair amount to
# rewrite without the form working any better.  2019 11 21
#
# allow updating of existing entries, instead of making them false and re-entering them.  2020 03 24
#
# populate your email and your full name based on two_email most recent and two_standardname 
# when coming from action Display with wbperson id.  2020 06 10
#
# updated getPgHash() to skip invalid persons into aka_hash.  For Cecilia and Kimberly.  2022 01 06
#
# removing acefile in dockerized, Cecilia doesn't use it.  2023 03 01


# removing acefile in dockerized, Cecilia doesn't use it.  2023 03 01
# my $acefile = "/home/azurebrd/public_html/cgi-bin/data/person_lineage.ace";

# use LWP::Simple;
# use Mail::Mailer;

use Jex;			# untaint, getHtmlVar, cshlNew, mailer, getSimpleDate
use strict;
use CGI;
use Fcntl;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $baseUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms";


my $query = new CGI;
my $user = 'cecilia';	# who sends mail
my $email = 'cecnak@wormbase.org';	# to whom send mail
# my $email = 'cecilia@tazendra.caltech.edu';	# to whom send mail
# my $email = 'azurebrd@tazendra.caltech.edu';	# to whom send mail
# my $email = 'forms@tazendra.caltech.edu';	# to whom send mail
my $subject = 'person_lineage';	# subject of mail
my $body = '';			# body of mail
my $ace_body = '';		# body of ace file

my $num_fields = '15';		# default number of connections to make
my %hash;			# store data here
&initializeHash($num_fields);	# store values in hash

print "Content-type: text/html\n\n";
my $title = 'Person Lineage Data Submission Form';
my ($header, $footer) = &cshlNew($title);
print "$header\n";		# make beginning of HTML page

&process();			# see if anything clicked
print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; &displayTop(); &displayBottom(); }
#   print "ACTION : $action<BR>\n";

  if ( ($action eq 'Preview')|| ($action eq 'Submit') || ($action eq 'Update Form') || ($action eq 'Query') || ($action eq 'Display') ) {
    my $mandatory_ok = 'ok';			# default mandatory is ok
    my $sender = '';
    my @mandatory = qw ( email mapper );
    my %mandatoryName;				# hash of field names to print warnings
    $mandatoryName{email} = "Email";
    $mandatoryName{mapper} = "Full Name";

    if ( ($action eq 'Submit') || ($action eq 'Preview') ) {			# check mandatory fields only when submitting data
      foreach $_ (@mandatory) {			# check mandatory fields
        my ($var, $val) = &getHtmlVar($query, $_);
        if ($_ eq 'email') {			# check emails
          unless ($val =~ m/@.+\..+/) { 		# if email doesn't match, warn
            print "<FONT COLOR=red SIZE=+2>$val is not a valid email address.</FONT><BR>";
            $mandatory_ok = 'bad';		# mandatory not right, print to resubmit
          } else { $sender = $val; }
        } else { 					# check other mandatory fields
          if ($val) { 			# if there's no value
            if ($val =~ m/WBPerson/) { 1; }	# good
            else {				# for Cecilia, needs standard name with space 2005 07 06
              if ($val !~ m/\s/) {		# if no space, name is not right
                print "<FONT COLOR=red SIZE=+2>$mandatoryName{$_} requires a standard name (two words or more) or a WBPerson entry.</FONT><BR>";
                $mandatory_ok = 'bad'; } }	# mandatory not right, print to resubmit
          } else {
            print "<FONT COLOR=red SIZE=+2>$mandatoryName{$_} is a mandatory field.</FONT><BR>";
            $mandatory_ok = 'bad';		# mandatory not right, print to resubmit
          }
        }
      } # foreach $_ (@mandatory)
    } # if ( ($action eq 'Submit') || ($action eq 'Preview') )

    if ($mandatory_ok eq 'bad') { 		# if required fields missing, show error message
      &populateHashFromForm();
#       print "<FONT COLOR=red><B>Missing Required Field, please click back and resubmit.</B></FONT><P>";
      print "<FONT COLOR=red><B>Missing Required Field, please edit and resubmit.</B></FONT><P>";
      &displayTop(); &displayBottom();
    } else { 					# if email is good, process

      if ($action eq 'Submit') {
        my $result;				# general pg stuff
        my $joinkey;				# the joinkey for pg
        # removing acefile in dockerized, Cecilia doesn't use it.  2023 03 01
        # open (OUT, ">>$acefile") or die "Cannot create $acefile : $!";
        my $host = $query->remote_host();		# get ip address
        my $body .= "$sender from ip $host sends :\n\n";
  
        my ($var, $mapper) = &getHtmlVar($query, 'mapper');	# using mapper as pg key
        unless ($mapper =~ m/\S/) {				# if there's no mapper text
          print "<FONT COLOR='red'>Warning, you have not picked a Mapper</FONT>.<P>\n";
        } else {							# if tpd text, output
          $body .= "mapper\t$mapper\n";
          $ace_body .= "Person : $mapper\n";
	  $ace_body .= "Email\t$sender\n";
  
          my ($var, $val) = &getHtmlVar($query, 'comment');
          if ($val) { $body .= "Comment\t\"$val\"\n"; $ace_body .= "Comment\t\"$val\"\n"; }
          ($var, $val) = &getHtmlVar($query, 'max_fields');	# how many fields were (could have data)
          my $max_fields = $val;
          my $i = 0;
          while ($i < $max_fields) { 				# for each of the lines
            $i++;
            ($var, $val) = &getHtmlVar($query, "trained$i");
            if ($val) { 					# if user entered name, put data in hash
              $val =~ s/^\s+//g; $val =~ s/\s+$//g; $val =~ s/\s+/ /g;
              my $name = $val;					# assign name
              if ($name) { 
                if ($name =~ m/^Dr\. /i) { $name =~ s/^Dr\. //i; }
                if ($name =~ m/^Dr /i)   { $name =~ s/^Dr //i; }
                if ($name =~ m/^Doctor /i)   { $name =~ s/^Doctor //i; }
                if ($name =~ m/ phD$/i)   { $name =~ s/ phD$//i; }
                if ($name =~ m/ phD\.$/i)   { $name =~ s/ phD\.$//i; }
                if ($name =~ m/ ph\.D\.$/i)   { $name =~ s/ ph\.D\.$//i; } }
              ($var, $val) = &getHtmlVar($query, "role$i");	# get the chosen role
              my $role = $val; 					# assign role
              my $ace_role = $val;				# assign role for output file
	      my $year1 = 'NULL';
	      my $year2 = 'NULL';
              ($var, $val) = &getHtmlVar($query, "year1$i");	# get the chosen year1
              my $years = $val;					# assign year1
              if ($years) { 					# if year1, get year2
		$year1 = $val;					# assign year1
                ($var, $val) = &getHtmlVar($query, "year2$i");	# get the chosen year2
                if ($val) { $years .= "\t$val";	$year2 = $val; }	# if year2, append year2
                $ace_role .= "\t$years"; }			# append years to date
              if ($year2 eq 'present') { $year2 = "'present'"; }
              if ($role eq 'Collaborated') {
                $body .= "Worked_with\t\"$name\"\t$ace_role\n"; # add to outfile
#                 print "INSERT INTO two_lineage VALUES (NULL, '$mapper', '$name', NULL, '$role', $year1, $year2, '$sender', CURRENT_TIMESTAMP);<BR>\n";
#                 print "INSERT INTO two_lineage VALUES (NULL, '$name', '$mapper', NULL, '$role', $year1, $year2, 'REV - $sender', CURRENT_TIMESTAMP);<BR>\n";
                $result = $dbh->do( "INSERT INTO two_lineage VALUES (NULL, '$mapper', '$name', NULL, '$role', $year1, $year2, '$sender', CURRENT_TIMESTAMP);" );
                $result = $dbh->do( "INSERT INTO two_lineage VALUES (NULL, '$name', '$mapper', NULL, '$role', $year1, $year2, 'REV - $sender', CURRENT_TIMESTAMP);" );
                $ace_body .= "Worked_with\t\"$name\"\t$ace_role\n"; }
              elsif ($role =~ m/with/) {
                $role =~ s/with//g;
                $body .= "Supervised_by\t\"$name\"\t$ace_role\n";	# add to outfile
#                 print "INSERT INTO two_lineage VALUES (NULL, '$mapper', '$name', NULL, 'with$role', $year1, $year2, '$sender', CURRENT_TIMESTAMP);<BR>\n";
#                 print "INSERT INTO two_lineage VALUES (NULL, '$name', '$mapper', NULL, '$role', $year1, $year2, 'REV - $sender', CURRENT_TIMESTAMP);<BR>\n";
                $result = $dbh->do( "INSERT INTO two_lineage VALUES (NULL, '$mapper', '$name', NULL, 'with$role', $year1, $year2, '$sender', CURRENT_TIMESTAMP);" );
                $result = $dbh->do( "INSERT INTO two_lineage VALUES (NULL, '$name', '$mapper', NULL, '$role', $year1, $year2, 'REV - $sender', CURRENT_TIMESTAMP);" );
                if ($ace_role =~ m/with/) { $ace_role =~ s/with/during their /g; }
                $ace_body .= "Supervised_by\t\"$name\"\t$ace_role\n"; } 
              else {
                $body .= "Supervised\t\"$name\"\t$ace_role\n"; 	# add to outfile
#                 print "INSERT INTO two_lineage VALUES (NULL, '$mapper', '$name', NULL, '$role', $year1, $year2, '$sender', CURRENT_TIMESTAMP);<BR>\n";
#                 print "INSERT INTO two_lineage VALUES (NULL, '$name', '$mapper', NULL, 'with$role', $year1, $year2, 'REV - $sender', CURRENT_TIMESTAMP);<BR>\n";
                $result = $dbh->do( "INSERT INTO two_lineage VALUES (NULL, '$mapper', '$name', NULL, '$role', $year1, $year2, '$sender', CURRENT_TIMESTAMP);" );
                $result = $dbh->do( "INSERT INTO two_lineage VALUES (NULL, '$name', '$mapper', NULL, 'with$role', $year1, $year2, 'REV - $sender', CURRENT_TIMESTAMP);" );
                $ace_role = "for their " . $ace_role;
                $ace_body .= "Supervised\t\"$name\"\t$ace_role\n"; } 
            } # if ($val)
          } # while ($i < $max_fields)
          $body .= "\n\n";

          ($var, $val) = &getHtmlVar($query, 'false_count');	# how many possibly-false fields were (could have data)
          my $false_count = $val;
          my $j = 0;
          while ($j < $false_count) { 				# for each of the lines
            $j++;
            ($var, $val) = &getHtmlVar($query, "false$j");
            if ($val) { $body .= qq(Remove : <span style="color:brown">WBPerson$val</span>\n); }
            ($var, $val) = &getHtmlVar($query, "update$j");
            if ($val) {
              ($var, my $role) = &getHtmlVar($query, "updaterole$j");
              ($var, my $year1) = &getHtmlVar($query, "updateyear1$j");
              ($var, my $year2) = &getHtmlVar($query, "updateyear2$j");
              $body .= qq(Update : <span style="color:brown">WBPerson$val</span> into $role from $year1 to $year2<br>\n); }
          }

          my $full_body = "Thank you very much for updating your lineage of C. elegans biologist and other nematologist.\n\nUpdates will appear in the next release of WormBase in your WBPerson page. The full release schedule is available here:\n\nhttps://www.wormbase.org/about/release_schedule#0--10\n\nYou will be contacted if there are any conflicts, or if people from your lineage have not been assigned a WBPerson ID.\n\nPlease do not hesitate to contact me if you have any questions.\n\nHave a great day,\n\nCecilia\n";
          $full_body .= "\n\n" . $body . "\n" . $ace_body;
          # print OUT "$ace_body\n";			# print to outfile
          # close (OUT) or die "cannot close $acefile : $!";
          $email .= ", $sender";
          $full_body =~ s/<span style="color:brown">//g;
          $full_body =~ s/<\/span//g;
          $full_body =~ s/<br>//g;
          &mailer($user, $email, $subject, $full_body);	# email the data
          $body =~ s/\n/<BR>\n/mg;
          $ace_body =~ s/\n/<BR>\n/mg;
          print "BODY : <BR>$body<BR><BR>\n";
          print "ACE : <BR>$ace_body<BR><BR>\n";
#           print "<P><P><P><H1>Thank you, your info will be updated shortly.</H1>\n";
          print "<P><P><P>Thank you very much for updating your lineage of C. elegans biologist and other nematologist. Updates will appear in the next release of WormBase in your WBPerson page.<br/>\n";
          print qq(The full release schedule is available here: <a href="http://www.wormbase.org/about/release_schedule#0--10" target="new">http://www.wormbase.org/about/release_schedule#0--10</a><br/>\n);
          print "You will be contacted if there are any conflicts, or if people from your lineage have not been assigned a WBPerson ID.<br/>\n";
          print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> 
                 See all <A HREF=\"${baseUrl}/../data/person_lineage.ace\">new submissions</A>.<P>\n";
#           print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> 
#                  See all <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/person_lineage.ace\">new submissions</A>.<P>\n";
        } # else # unless ($genotype =~ m/\S/)
      } # if ($action eq 'Submit') 

      elsif ($action eq 'Preview') {		# wrote preview section to display existing data and show submit button
        print "<FORM METHOD=\"POST\" ACTION=\"person_lineage.cgi\">\n";
        print qq(<FONT SIZE=+2><B>You've entered the following information.  If this information is correct click "Submit", otherwise click <a href="javascript:history.back()">here</a> to go back and edit that information.<INPUT TYPE=submit NAME=action VALUE="Submit" style="color:Red; font-size:22px;"></B></FONT><P>\n);

        my ($var, $mapper) = &getHtmlVar($query, 'mapper');	# using mapper as pg key
        print "Mapper : $mapper<BR>\n";
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"mapper\" VALUE=\"$mapper\">\n";
        my ($var, $val) = &getHtmlVar($query, 'comment');
        if ($val) { print "Comment : $val<BR>\n"; }
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
        ($var, $val) = &getHtmlVar($query, 'email');		# mapper's email
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
        ($var, $val) = &getHtmlVar($query, 'max_fields');	# how many fields were (could have data)
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
        my $max_fields = $val;
        my $i = 0;
        while ($i < $max_fields) { 				# for each of the lines
          $i++;
          ($var, $val) = &getHtmlVar($query, "trained$i");
          if ($val) { 					# if user entered name, put data in hash
            $val =~ s/^\s+//g; $val =~ s/\s+$//g; $val =~ s/\s+/ /g;
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n"; 
            my $name = $val;					# assign name
            print "Name is $name. ";
            ($var, $val) = &getHtmlVar($query, "role$i");	# get the chosen role
            my $role = $val; 					# assign role
            if ($role) {
              print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n"; 
              print "Role is $role. "; }
            my $ace_role = $val;				# assign role for output file
	    my $year1 = 'NULL';
	    my $year2 = 'NULL';
            ($var, $val) = &getHtmlVar($query, "year1$i");	# get the chosen year1
            my $years = $val;					# assign year1
            if ($val) { 
              print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
              print "Starting $years. "; }
            if ($years) { 					# if year1, get year2
	      $year1 = $val;					# assign year1
              ($var, $val) = &getHtmlVar($query, "year2$i");	# get the chosen year2
              if ($val) { 
                print "Ending $val. ";
                print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n"; }
            }
            print "<BR>\n";
        } } 
        ($var, $val) = &getHtmlVar($query, 'false_count');	# how many possibly-false fields were (could have data)
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
        my $false_count = $val;
        my $j = 0;
        while ($j < $false_count) { 				# for each of the lines
          $j++;
          ($var, $val) = &getHtmlVar($query, "false$j");
          print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
          if ($val) { print qq(Remove : <span style="color:brown">WBPerson$val</span><BR>\n); }
          ($var, $val) = &getHtmlVar($query, "update$j");
          if ($val) {
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$val\">\n";
            ($var, my $role) = &getHtmlVar($query, "updaterole$j");
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$role\">\n";
            ($var, my $year1) = &getHtmlVar($query, "updateyear1$j");
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$year1\">\n";
            ($var, my $year2) = &getHtmlVar($query, "updateyear2$j");
            print "<INPUT TYPE=\"HIDDEN\" NAME=\"$var\" VALUE=\"$year2\">\n";
            print qq(Update : <span style="color:brown">WBPerson$val</span> into $role from $year1 to $year2<br>\n); }
        }
        print "</FORM>\n";
      } # if ($action eq 'Preview') 

      elsif ($action eq 'Update Form') {
        &populateHashFromForm();
        &displayTop(); &displayBottom();
      } # elsif ($action eq 'Update Form')

      elsif ($action eq 'Query') {			# query for the already-existing lineage
        (my $oop, my $name) = &getHtmlVar($query, 'name');
        if ($name !~ m/\w/) { 1; }					# no action if no name
        elsif ($name =~ /\d/) { &processPgNumber($name); }
        elsif ($name =~ m/[\*\?]/) { &processPgWild($name); }		# if it has a * or ?
        else {                    # if it doesn't do simple aka hash thing
          my %aka_hash = &getPgHash();
          &processAkaSearch($name, $name, %aka_hash); }
      } # if ($action eq 'Query')

      elsif ($action eq 'Display') {			# diplay the form as well as existing lineage
        (my $oop, my $number) = &getHtmlVar($query, 'number');
        print "Display $number data<BR>\n";
        my $joinkey = $number; $joinkey =~ s/WBPerson/two/g;
        my $result = $dbh->prepare( "SELECT two_standardname FROM two_standardname WHERE joinkey = '$joinkey'; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row = $result->fetchrow();
        if ($row[0]) { $hash{'mapper'} = $row[0]; }
        $result = $dbh->prepare( "SELECT two_email FROM two_email WHERE joinkey = '$joinkey' ORDER BY two_timestamp DESC;" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        @row = $result->fetchrow();
        if ($row[0]) { $hash{'email'} = $row[0]; }

        &displayTop(); 
        print "<TR><TD><BR/></TD></TR>\n";
        print "<TR><TD COLSPAN=6><FONT SIZE=+2><B>Existing Data</B></FONT>&nbsp;&nbsp;&nbsp;If any of these are not correct check the corresponding box.</FONT></TD></TR>\n";
        my %stdname; my %lastname; my %fullname;			# numbers to standardname and lastname (for display and sorting respectively)
        $result = $dbh->prepare( "SELECT joinkey, two_standardname FROM two_standardname; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        while (my @row = $result->fetchrow) {
          my $num = $row[0]; $num =~ s/two//g; $stdname{$num} = $row[1]; }		# map wbperson numbers to standardnames for display
        my $firstname = ''; my $middlename = ''; my $lastname = ''; my $num;
        $result = $dbh->prepare( "SELECT joinkey, two_firstname FROM two_firstname; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row = $result->fetchrow(); if ($row[1]) { $firstname = $row[1]; }
        $result = $dbh->prepare( "SELECT joinkey, two_middlename FROM two_middlename; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row = $result->fetchrow(); if ($row[1]) { $middlename = $row[1]; }
        $result = $dbh->prepare( "SELECT joinkey, two_lastname FROM two_lastname; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        my @row = $result->fetchrow(); if ($row[1]) { $lastname = $row[1]; $num = $row[0]; $num =~ s/two//; }
        my $fullname = "$firstname $lastname";
        if ($middlename) { $fullname = "$firstname $middlename $lastname"; }
        
#         $result = $dbh->prepare( "SELECT joinkey, two_firstname, two_lastname, two_middlename FROM two_fullname; " );
#         $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#         while (my @row = $result->fetchrow) {
#           my $num = $row[0]; $num =~ s/two//g; 
#           my $fullname = "$row[1] $row[2]";
#           if ($row[3]) { $fullname = "$row[1] $row[3] $row[2]"; }
#           $fullname{$num} = $fullname; }		# map wbperson numbers to fullnames for display
        $number =~ s/WBPerson//g;				# filter out 'two' to get the proper stdname
        print "<TR><TD><BR/></TD></TR>\n";
        print "<TR><TD COLSPAN=6><FONT SIZE=+2 COLOR='blue'>$stdname{$number}'s current Lineage :</FONT><BR/>&nbsp;</TD></TR>\n";
        $result = $dbh->prepare( "SELECT joinkey, two_lastname FROM two_lastname; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
        while (my @row = $result->fetchrow) {
          my $num = $row[0]; $num =~ s/two//g; $lastname{$num} = $row[1]; }		# map wbperson numbers to lastnames for sorting
        $result = $dbh->prepare( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two' ORDER BY two_number, two_date2 DESC, two_date1 DESC; " );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
          # order by two number to group them, then by dates to show those without dates first, so they'll be overwritten by entries with longer dates
        # SELECT joinkey, two_role FROM two_lineage WHERE two_role !~ 'Collaborated' AND two_role !~ 'Highschool' AND two_role !~ 'Lab_visitor' AND two_role !~ 'Masters' AND two_role !~ 'Phd' AND two_role !~ 'PhD' AND two_role !~ 'Postdoc' AND two_role !~ 'Research_staff' AND two_role !~ 'Sabbatical' AND two_role !~ 'Undergrad' AND two_role !~ 'Unknown' ORDER BY two_role;
        print "<TR><TD ALIGN=center>Remove</TD><TD ALIGN=center>Update</TD><TD>Role</TD><TD COLSPAN=2>Name of Person</TD><TD>Dates</TD></TR>\n";
        my %lineage; my %not_unknown;
        while (my @row = $result->fetchrow) {
          my $name = $row[2];
          my $num = $row[3]; $num =~ s/two//g;
          my $role = $row[4];
          my $date = '&nbsp;'; 
          if ($row[5]) { $date = $row[5]; }
          if ($row[6]) { $date .= ' to ' . $row[6]; }
#           $lineage{$num}{$role} = $date;
          $lineage{$num}{$role}{start} = $row[5];
          $lineage{$num}{$role}{end}   = $row[6];
          if ($role !~ m/Unknown/) { $not_unknown{$num}++; }	# If has a role that's not Unknown set in hash to check against later (so as not to print unknown if both unknown and something else)
        } # while (my @row = $result->fetchrow)
        my $count = 0;
        my %sort_hash;
        foreach my $num (sort keys %lineage) {
          foreach my $role (sort keys %{ $lineage{$num} }) {
            if ( ($role =~ m/Unknown/) && $not_unknown{$num} ) { next; }		# skip unknowns if they also have known data
            $count++;
            my $translated_role = $role;
            if ($translated_role eq 'Collaborated') { 1; }				# nothing for collaborators
              elsif ($translated_role =~ m/with/) { $translated_role =~ s/with/I trained as a /; $translated_role .= " under"; }
              else { $translated_role = 'During their ' . $translated_role; }
            my $name = $stdname{$num}; if ($fullname{$num}) { if ($stdname{$num} ne $fullname{$num}) { $name .= " ($fullname{$num})"; } }
            my $line = "<TR><TD ALIGN=center><INPUT TYPE=checkbox NAME=\"false$count\" VALUE=\"$num $stdname{$num} $translated_role $lineage{$num}{$role}{start} $lineage{$num}{$role}{end}\"></TD>"; 
            $line .= qq(<TD ALIGN=center><INPUT TYPE=checkbox NAME="update$count" VALUE="$num $stdname{$num} $translated_role $lineage{$num}{$role}{start} $lineage{$num}{$role}{end}" onClick="document.getElementById('updaterole' + $count).disabled = ''; document.getElementById('updateyear1' + $count).disabled = ''; document.getElementById('updateyear2' + $count).disabled = '';"></TD><TD>); 
            $line .= &getRoleSelect($count, 'updaterole', $role, 'disabled');
            $line .= "</TD><TD COLSPAN=2><A HREF=http://www.wormbase.org/db/misc/person?name=WBPerson$num;class=Person TARGET=new>$name</A></TD>";
            $line .= "<TD>Beginning in the year ";
            my $year1Select = &getYearSelect($count, 'updateyear1', $lineage{$num}{$role}{start}, 'disabled');
            $line .= qq($year1Select</TD>);
            $line .= "<TD>Through the year ";
            my $year2Select = &getYearSelect($count, 'updateyear2', $lineage{$num}{$role}{end}, 'disabled');
            $line .= qq($year2Select</TD></TR>\n);
#             $line .= qq(<TD>$lineage{$num}{$role}</TD></TR>\n);
            push @{ $sort_hash{$num} }, $line;
#             print "<TR><TD ALIGN=center><INPUT TYPE=checkbox NAME=\"false$count\" VALUE=\"$num $stdname{$num} $role $lineage{$num}{$role}\">$count</TD>
#                        <TD COLSPAN=2><A HREF=http://www.wormbase.org/db/misc/person?name=WBPerson$num;class=Person TARGET=new>$stdname{$num}</A></TD>
#                        <TD>$role</TD><TD>$lineage{$num}{$role}</TD></TR>\n";
        } } 
        foreach my $num (sort { $lastname{$a} cmp $lastname{$b} } keys %sort_hash) {
          foreach my $entry (@{ $sort_hash{$num} }) { print $entry; } }
        print "<INPUT TYPE=hidden NAME=false_count VALUE=$count>\n";			# total amount of lines from existing lineage
        &displayBottom();
      } # elsif ($action eq 'Display') {			# diplay the form as well as existing lineage

      else { print "<FONT COLOR=red><B>NOT A VALID FORM ACTION</B></FONT>\n"; }
    } # else # if ($mandatory_ok eq 'bad') 		# if required fields are ok
  } # if ( ($action eq 'Preview')|| ($action eq 'Submit') || ($action eq 'Update Form') || ($action eq 'Query') || ($action eq 'Display') ) {
} # sub process

sub populateHashFromForm {
        my ($var, $val) = &getHtmlVar($query, 'mapper');
        $hash{mapper} = $val;
        ($var, $val) = &getHtmlVar($query, 'email');
        $hash{email} = $val;
        ($var, $val) = &getHtmlVar($query, 'comment');
        $hash{comment} = $val;
        ($var, $val) = &getHtmlVar($query, 'num_fields');	# how many fields will be
        $num_fields = $val;
        ($var, $val) = &getHtmlVar($query, 'max_fields');	# how many fields were (could have data)
        my $max_fields = $val;
        my $i = 0;
        while ($i < $num_fields) { 			# for each of the lines
          $i++; 
          ($var, $val) = &getHtmlVar($query, "trained$i");
          if ($val) { 					# if user entered name, put data in hash
            $hash{$i}{name} = $val; 			# assign name
            ($var, $val) = &getHtmlVar($query, "role$i");	# get the chosen role
            $hash{$i}{role} = $val; 
            ($var, $val) = &getHtmlVar($query, "year1$i");	# get the chosen year1
            $hash{$i}{year1} = $val; 
            ($var, $val) = &getHtmlVar($query, "year2$i");	# get the chosen year2
            $hash{$i}{year2} = $val; }
        } # while ($i < $num_fields)
} # populateHashFromForm

sub displayTop {			# show form as appropriate
  print <<"EndOfText";
<html>
  <head>
    <title>Person Lineage Data Submission Form</title>
  </head>

  <body>

<FORM METHOD="POST" ACTION="person_lineage.cgi">

<A NAME="form"><H1>Person Lineage Data Submission Form :</H1></A>
WormBase would like to fully describe the professional associations
between C. elegans biologists that started with Sydney Brenner and 
other nematologists.  
Please describe both those people that trained you and the people that 
you have subsequently trained/collaborated with.<P><HR>

<a id="instructions_show" href='#' onclick="document.getElementById('instructions_show').style.display = 'none'; document.getElementById('instructions').style.display = ''; return false;">Instructions</a>
<div id="instructions" style="display:none">
<P>
<B>The first two fields are required.</B><P>
<B>For each Lineage connection, please type the full name of the person 
you wish to connect and select the type of connection to each other.</B>
If you know the WBPerson number of the person you wish to connect, you 
may use that instead of their name.
If you know the years you started / stopped working with someone please
enter it.<BR><BR>
e.g., to connect yourself to Mary Smith where she trained you for your Phd between 1990 and 1995, you could :<BR>
Type ``Mary Smith'' under Relationship 1 (or ``WBPerson1234'' if you know the
WBPerson number).<BR>
Select ``Trained as a Phd with''.<BR>
Select ``1990''.<BR>
Select ``1995''.<BR><BR>
e.g., to connect yourself to Bob Smith where you trained him for Undergrad between 1999 and now, you would :<BR>
Type ``Bob Smith'' under Relationship 2.<BR>
Select ``Trained Undergrad''.<BR>
Select ``1999''.<BR>
Select ``present''.<BR><br />
<a id="instructions_hide" href='#' onclick="document.getElementById('instructions_show').style.display = ''; document.getElementById('instructions').style.display = 'none'; return false;">Collapse instructions</a>
</div>

<HR><P>

If we can not find information on someone you have trained, we will 
contact you to create an entry for them.<BR>
Please type the number of connections, if you wish to make more than <Input Type="Text" Name="num_fields" Size="5"
Value=$num_fields> and click <INPUT TYPE="submit" NAME="action" VALUE="Update Form"><BR>
<INPUT TYPE=hidden NAME=max_fields VALUE=$num_fields><P><P>

<HR><P><BR>
EndOfText

  &displayQuery();

  print <<"EndOfText";

    <TABLE ALIGN="center" border=0> 
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD colspan="2"><FONT SIZE=+2><B>REQUIRED</B></FONT></TD></TR>
    <TR><TD ALIGN="right" colspan="2"><I><FONT COLOR='black'><B>Your Email</FONT></I> :</B></TD>
        <TD COLSPAN=2><Input Type="Text" Name="email" Size="30" Value="$hash{email}"></TD>
        <TD COLSPAN=3>(e.g. bob\@yahoo.com)<BR>If you don't get a verification email, email us at webmaster\@wormbase.org</TD><TD></TR>
    <!--<TR><TD ALIGN="right"><I><FONT COLOR='red'><B>Full Name of Person to Connect</FONT></I> :</B></TD>-->
    <TR><TD ALIGN="right" colspan="2"><I><FONT COLOR='black'><B>Your Full Name</FONT></I> :</B></TD>
        <TD COLSPAN=2><Input Type="Text" Name="mapper" Size="30" Value="$hash{mapper}"></TD>
        <!--<TD COLSPAN=3>(e.g. Your Name or WBPerson#)</TD><TD></TR>-->
        <TD COLSPAN=3>(e.g. ``Richard Feynman'' or ``WBPerson7777777''<BR>Please don't use titles, e.g. don't use ``Dr. Richard Feynman'')</TD><TD></TR>

EndOfText
} # sub displayTop 

sub displayBottom {			# show form as appropriate
  print <<"EndOfText";
    <TR><TD><BR/></TD></TR>
    <TR><TD colspan=4><FONT SIZE=+2><B>LINEAGE CONNECTIONS WITH</B></FONT> (Please don't use titles)</TD></TR>
EndOfText

    &showFields($num_fields);
 
    print <<"EndOfText";
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD colspan="2"><FONT SIZE=+2><B>COMMENT</B></FONT></TD></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR><TR><TD ALIGN="right" colspan="2"><B>Comment :</B></TD>
        <TD COLSPAN=3><TEXTAREA Name="comment" Rows=5 Cols=50>$hash{comment}</TEXTAREA></TD>
        <TD COLSPAN=3></TD></TR><TR></TR>

    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR><TD COLSPAN=2> </TD></TR>
    <TR>
      <TD colspan="2"> </TD>
      <!--<TD COLOR="red"><INPUT TYPE="submit" NAME="action" VALUE="Preview" style="background-color:Red; font-size:22px;">-->
      <TD COLOR="red"><INPUT TYPE="submit" NAME="action" VALUE="Preview" style="color:Red; font-size:22px;">
        <INPUT TYPE="reset"></TD>
    </TR>
  </TABLE>

</FORM>
If you have any problems, questions, or comments, please contact <A HREF=\"mailto:cecnak\@wormbase.org\">cecnak\@wormbase.org</A><P>
EndOfText
  print "</body></html>\n";
} # sub displayBottom 




sub showFields {
  my $num_fields = shift;
  my $i = 0;
  while ($i < $num_fields) { $i++; &showField($i); }
} # sub showFields

sub showField {
  my $field_num = shift;
  &printLine($field_num);
} # sub showField

sub getRoleSelect {
  my ($field_num, $name, $value, $disabled) = @_;
  my $to_return = '';
  $to_return .= "    <SELECT NAME=\"$name$field_num\" ID=\"$name$field_num\" SIZE=1 $disabled>\n";
  if ($value) { $to_return .= &getSelectedOption($value); }
  $to_return .= "      <OPTION VALUE=withPhd>I trained as a PhD under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withPostdoc>I trained as a Postdoc under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withMasters>I trained as a Masters under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withUndergrad>I trained as an Undergrad under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withHighschool>I trained as a High School student under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withSabbatical>I trained for a Sabbatical under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withLab_visitor>I trained as a Lab Visitor under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withResearch_staff>I trained as a Research Staff under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withAssistant_professor>I trained as an Assistant Professor under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=withUnknown>I trained as an Unknown under</OPTION>\n";
  $to_return .= "      <OPTION VALUE=bad>--------------</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Phd>I trained this person as a PhD</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Postdoc>I trained this person as a Postdoc</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Masters>I trained this person as a Masters</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Undergrad>I trained this person as an Undergrad</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Highschool>I trained this person as a High School student</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Sabbatical>I trained this person during a Sabbatical</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Lab_visitor>I trained this person as a Lab Visitor</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Research_staff>I trained this person as a Research Staff</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Assistant_professor>I trained this person as an Assistant Professor</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Unknown>I trained this person as an Unknown</OPTION>\n";
  $to_return .= "      <OPTION VALUE=Collaborated>I collaborated with</OPTION>\n";
#   foreach (@roles) { print "      <OPTION>$_</OPTION>\n"; }
  $to_return .= "    </SELECT>\n";
  return $to_return;
} # sub getRoleSelect

sub getYearSelect {
  my ($field_num, $name, $value, $disabled) = @_;
  my $to_return = '';
  $to_return .= "    <SELECT NAME=\"$name$field_num\" ID=\"$name$field_num\" SIZE=1 $disabled>\n";
  if ($value) { $to_return .= "      <OPTION>$value</OPTION>\n"; }
  $to_return .= "      <OPTION></OPTION>\n";
  my ($cur_date) = &getSimpleDate();
  my ($year) = $cur_date =~ m/^(\d{4})/;
  while ($year > 1900) { $to_return .= "      <OPTION>$year</OPTION>\n"; $year--; }
  $to_return .= "    </SELECT></TD>\n";
  return $to_return;
} # sub getYearSelect 

sub printLine {
  my $field_num = shift;
  print "<TR></TR> <TR></TR> <TR></TR> <TR></TR>"; 
  print "<TR><TD align=right colspan=\"2\"><B>Relationship $field_num : </B></TD>";
  my $roleSelect = &getRoleSelect($field_num, 'role', $hash{$field_num}{'role'}, '');
  print qq(<TD>$roleSelect</TD>);
  print "<TD COLSPAN=2><Input Type=\"Text\" Name=\"trained$field_num\" Size=\"30\" Maxlength=\"5000\" Value=\"$hash{$field_num}{name}\"></TD>\n";
  print "<TD>Beginning in the year\n";
  my $year1Select = &getYearSelect($field_num, 'year1', $hash{$field_num}{year1}, '');
  print qq($year1Select</TD>);
#   print "    <SELECT NAME=\"year1$field_num\" SIZE=1>\n";
#   if ($hash{$field_num}{year1}) { print "      <OPTION>$hash{$field_num}{year1}</OPTION>\n"; }
#   print "      <OPTION></OPTION>\n";
#   my ($cur_date) = &getSimpleDate();
#   my ($year) = $cur_date =~ m/^(\d{4})/;
#   while ($year > 1900) { print "      <OPTION>$year</OPTION>\n"; $year--; }
#   print "    </SELECT></TD>\n";
  print "<TD>Through the year\n";
  my $year2Select = &getYearSelect($field_num, 'year2', $hash{$field_num}{year2}, '');
  print qq($year2Select</TD>);
#   print "    <SELECT NAME=\"year2$field_num\" SIZE=1>\n";
#   if ($hash{$field_num}{year2}) { print "      <OPTION>$hash{$field_num}{year2}</OPTION>\n"; }
#   print "      <OPTION></OPTION>\n";
#   print "      <OPTION>present</OPTION>\n";
#   ($year) = $cur_date =~ m/^(\d{4})/;
#   while ($year > 1900) { print "      <OPTION>$year</OPTION>\n"; $year--; }
#   print "    </SELECT></TD>\n";
  print "</TR>\n";
} # sub printLine

sub getSelectedOption {
  my $value = shift;
  my $to_return = '';
  if ($value eq 'withPhd') { $to_return .= "      <OPTION VALUE=withPhd SELECTED>I trained as a PhD under</OPTION>\n"; }
  elsif ($value eq 'withPostdoc') { $to_return .= "      <OPTION VALUE=withPostdoc SELECTED>I trained as a Postdoc under</OPTION>\n"; }
  elsif ($value eq 'withMasters') { $to_return .= "      <OPTION VALUE=withMasters SELECTED>I trained as a Masters under</OPTION>\n"; }
  elsif ($value eq 'withUndergrad') { $to_return .= "      <OPTION VALUE=withUndergrad SELECTED>I trained as an Undergrad under</OPTION>\n"; }
  elsif ($value eq 'withHighschool') { $to_return .= "      <OPTION VALUE=withHighschool SELECTED>I trained as a High School student under</OPTION>\n"; }
  elsif ($value eq 'withSabbatical') { $to_return .= "      <OPTION VALUE=withSabbatical SELECTED>I trained for a Sabbatical under</OPTION>\n"; }
  elsif ($value eq 'withLab_visitor') { $to_return .= "      <OPTION VALUE=withLab_visitor SELECTED>I trained as a Lab Visitor under</OPTION>\n"; }
  elsif ($value eq 'withResearch_staff') { $to_return .= "      <OPTION VALUE=withResearch_staff SELECTED>I trained as a Research Staff under</OPTION>\n"; }
  elsif ($value eq 'withAssistant_professor') { $to_return .= "      <OPTION VALUE=withAssistant_professor SELECTED>I trained as an Assistant Professor under</OPTION>\n"; }
  elsif ($value eq 'withUnknown') { $to_return .= "      <OPTION VALUE=withUnknown SELECTED>I trained as an Unknown under</OPTION>\n"; }
  elsif ($value eq 'Phd') { $to_return .= "      <OPTION VALUE=Phd SELECTED>I trained this person as a PhD</OPTION>\n"; }
  elsif ($value eq 'Postdoc') { $to_return .= "      <OPTION VALUE=Postdoc SELECTED>I trained this person as a Postdoc</OPTION>\n"; }
  elsif ($value eq 'Masters') { $to_return .= "      <OPTION VALUE=Masters SELECTED>I trained this person as a Masters</OPTION>\n"; }
  elsif ($value eq 'Undergrad') { $to_return .= "      <OPTION VALUE=Undergrad SELECTED>I trained this person as an Undergrad</OPTION>\n"; }
  elsif ($value eq 'Highschool') { $to_return .= "      <OPTION VALUE=Highschool SELECTED>I trained this person as a High School student</OPTION>\n"; }
  elsif ($value eq 'Sabbatical') { $to_return .= "      <OPTION VALUE=Sabbatical SELECTED>I trained this person during a Sabbatical</OPTION>\n"; }
  elsif ($value eq 'Lab_visitor') { $to_return .= "      <OPTION VALUE=Lab_visitor SELECTED>I trained this person as a Lab Visitor</OPTION>\n"; }
  elsif ($value eq 'Research_staff') { $to_return .= "      <OPTION VALUE=Research_staff SELECTED>I trained this person as a Research Staff</OPTION>\n"; }
  elsif ($value eq 'Assistant_professor') { $to_return .= "      <OPTION VALUE=Assistant_professor SELECTED>I trained this person as an Assistant Professor</OPTION>\n"; }
  elsif ($value eq 'Unknown') { $to_return .= "      <OPTION VALUE=Unknown SELECTED>I trained this person as an Unknown</OPTION>\n"; }
  elsif ($value eq 'Collaborated') { $to_return .= "      <OPTION VALUE=Collaborated SELECTED>Collaborated with</OPTION>\n"; }
  else { 1; }
  return $to_return;
} # sub getSelectedOption

sub initializeHash {
  my $num_fields = shift;
  $hash{mapper} = '';
  $hash{email} = '';
  $hash{comment} = '';
  my $i = 0;
  while ($i < $num_fields) { 
    $i++; 
    $hash{$i}{name} = ''; $hash{$i}{role} = ''; 
    $hash{$i}{year1} = ''; $hash{$i}{year2} = ''; 
  }
} # sub initializeHash


### Query Section

sub displayQuery {                      # show form as appropriate
    print <<"EndOfText";
  <TABLE ALIGN="center"> 
    <TR><TD><B>Please enter your name :</B><BR><FONT SIZE=-2 COLOR=red>(to update your existing lineage information)</FONT></TD>
        <TD><Input Type="Text" Name="name" Size="20"></TD>
        <TD><INPUT TYPE="submit" NAME="action" VALUE="Query"></TD></TR>
    <TR><TD> </TD> </TR>
  </TABLE>
EndOfText
} # sub displayQuery

sub getPgHash {				# get akaHash from postgres instead of flatfile
  my $result;
  my %filter;
  my %aka_hash;

  my %invalid;
  $result = $dbh->prepare ( "SELECT * FROM two_status WHERE two_status = 'Invalid';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( my @row = $result->fetchrow ) { $invalid{$row[0]}++; }
  
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      next if $invalid{$row[0]};
      if ($row[3]) { 					# if there's a curator
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      next if $invalid{$row[0]};
      if ($row[3]) { 					# if there's a curator
        my $joinkey = $row[0];
        $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;	# take out spaces in front and back
        $row[2] =~ s/[\,\.]//g;				# take out commas and dots
        $row[2] =~ s/_/ /g;				# replace underscores for spaces
        $row[2] = lc($row[2]);				# for full values (lowercase it)
        $row[0] =~ s/two//g;				# take out the 'two' from the joinkey
        $filter{$row[0]}{$table}{$row[2]}++;
        my ($init) = $row[2] =~ m/^(\w)/;		# for initials
        $filter{$row[0]}{$table}{$init}++;
      }
    }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) { 
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
        $possible = "$first"; $aka_hash{$possible}{$person}++;
        $possible = "$last"; $aka_hash{$possible}{$person}++;
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
            $possible = "$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last $middle $first"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "$middle $first $last"; $aka_hash{$possible}{$person}++;
          } # foreach my $middle (sort keys %{ $filter{$person}{middle}} )
        }
      } # foreach my $first (sort keys %{ $filter{$person}{first}} )
    } # foreach my $last (sort keys %{ $filter{$person}{last}} )
  } # foreach my $person (sort keys %filter) 

  return %aka_hash;
} # sub getPgHash

sub processPgNumber {
  my $input_name = shift;
  if ($input_name =~ /(\d*)/) {   # and search just for number
    my $person = "WBPerson".$1;
    my $joinkey = "two".$1;
    my $result = $dbh->prepare ( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    my @row = $result->fetchrow;
    print "PERSON <FONT COLOR=red>$row[2]</FONT> has \n";
#     print "ID <A HREF=http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_lineage.cgi?action=Display&num_fields=$num_fields&number=$person>$person</A>.</BR>\n";
    print "ID <A HREF=${baseUrl}/person_lineage.cgi?action=Display&num_fields=$num_fields&number=$person>$person</A>.</BR>\n";
  } # if ($input_name =~ /(\d*)/)
} # sub processPgNumber

sub processAkaSearch {                  # get generated aka's and try to find exact match
  my ($name, $name, %aka_hash) = @_;
  my $search_name = lc($name);
  print "<TABLE>\n";
  unless ($aka_hash{$search_name}) {
    print "<TR><TD>NAME <FONT COLOR=red>$name</FONT> NOT FOUND</TD></TR>\n";
    my @names = split/\s+/, $search_name; $search_name = '';
    foreach my $name (@names) {
      if ($name =~ m/^[a-zA-Z]$/) { $search_name .= "$name "; }
      else { $search_name .= '*' . $name . '* '; } }
    &processPgWild($name);
  } else {
    my %standard_name;
    my $result = $dbh->prepare ( "SELECT * FROM two_standardname;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow ) {
      $standard_name{$row[0]} = $row[2];
    } # while (my @row = $result->fetchrow )

    print "<TR><TD colspan=2 align=center>NAME <FONT COLOR=red>$name</FONT> could be (click the WBPerson link that corresponds to you to edit your lineage) : </TD></TR>\n";
    my @stuff = sort {$a <=> $b} keys %{ $aka_hash{$search_name} };
    foreach $_ (@stuff) {               # add url link
      my $joinkey = 'two'.$_;
      my $person = 'WBPerson'.$_;
      print "<TR><TD>$standard_name{$joinkey}</TD><TD><A HREF=person_lineage.cgi?action=Display&num_fields=$num_fields&number=$person>$person</A></TD>\n";
    }
  }
  print "</TABLE>\n";
} # sub processAkaSearch

sub processPgWild {
  my $input_name = shift;
  print "<TABLE>\n";
  print "<TR><TD>INPUT</TD><TD>$input_name</TD></TR>\n";
  my @people_ids;
  $input_name =~ s/\*/.*/g;
  $input_name =~ s/\?/./g;
  my @input_parts = split/\s+/, $input_name;
  my %input_parts;
  my %matches;                          # keys = wbid, value = amount of matches
  my %filter;

  my %invalid;
  my $result = $dbh->prepare ( "SELECT * FROM two_status WHERE two_status = 'Invalid';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( my @row = $result->fetchrow ) { $invalid{$row[0]}++; }

  foreach my $input_part (@input_parts) {
    my @tables = qw (first middle last);
    foreach my $table (@tables) {
      my $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE lower(two_aka_${table}name) ~ lower('$input_part');" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; }
      $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE lower(two_${table}name) ~ lower('$input_part');" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$input_part}++; } } }
  foreach my $number (sort keys %filter) {
    next if $invalid{$number};
    foreach my $input_part (@input_parts) {
      if ($filter{$number}{$input_part}) {
        my $temp = $number; $temp =~ s/two/WBPerson/g; $matches{$temp}++;
        my $count = length($input_part);
        unless ($input_parts{$temp} > $count) { $input_parts{$temp} = $count; } } } }
  print "<TR><TD></TD><TD>There are " . scalar(keys %matches) . " match(es).</TD></TR>\n";
  print "<TR></TR>\n";
  print "</TABLE>\n";
  print "<TABLE border=2 cellspacing=5>\n";
  foreach my $person (sort {$matches{$b}<=>$matches{$a} || $input_parts{$b} <=> $input_parts{$a}} keys %matches) {
    # print "<TR><TD><A HREF=http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_lineage.cgi?action=Display&number=$person>$person</A></TD>\n";
    print "<TR><TD><A HREF=${baseUrl}/person_lineage.cgi?action=Display&number=$person>$person</A></TD>\n";
    print "<TD>has $matches{$person} match(es)</TD><TD>priority $input_parts{$person}</TD></TR>\n"; }
  print "</TABLE>\n";
  unless (%matches) { print "<FONT COLOR=red>Sorry, no person named '$input_name', please try again</FONT><P>\n" if $input_name; }
} # sub processPgWild


#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR><TD><FONT SIZE=+2><B>TRAINED AS A</B></FONT></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as a PhD with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_phd" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3>(e.g. Cecilia Nakamura, Keith Horatio Bradnam)</TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as a Postdoc with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_postdoc" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as a Masters with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_masters" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as an Undergrad with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_undergrad" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as a High School student with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_highschool" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained for a Sabbatical with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_sabbatical" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as a Lab Visitor with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_visitedlab" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as a Research Staff with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_staff" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained as Unknown with :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trainedwith_unknown" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#   
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR><TD><FONT SIZE=+2><B>TRAINED</B></FONT></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained PhD :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_phd" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Postdoc :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_postdoc" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Masters :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_masters" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Undergrad :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_undergrad" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained High School student :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_highschool" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Sabbatical :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_sabbatical" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Lab Visitor :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_visitedlab" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Research Staff :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_staff" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
#     <TR><TD ALIGN="right"><B>Trained Unknown :</B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="trained_unknown" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
# 
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR><TD><FONT SIZE=+2><B>COLLABORATED</B></FONT></TD></TR>
#     <TR></TR> <TR></TR> <TR></TR> <TR></TR>
#     <TR><TD ALIGN="right"><B>Collaborated with : </B></TD>
#         <TD COLSPAN=2><Input Type="Text" Name="collaborated" Size="50" Maxlength="5000"></TD>
#         <TD COLSPAN=3></TD></TR>
# 
# 
# <B>If a field has multiple data, please separate with commas, e.g.
# \"Cecilia Nakamura, Keith Horatio Bradnam\".</B><P>
# 
# 	  my @all_vars = qw ( mapper trainedwith_phd trainedwith_postdoc trainedwith_masters trainedwith_undergrad trainedwith_highschool trainedwith_sabbatical trainedwith_visitedlab trainedwith_staff trainedwith_unknown trained_phd trained_postdoc trained_masters trained_undergrad trained_highschool trained_sabbatical trained_visitedlab trained_staff trained_unknown collaborated comment );
  

