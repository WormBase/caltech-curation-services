#!/usr/bin/perl

# Form to submit Go Consortium Registration information.
#
# Written for Cecilia and Kimberly, still needs some data updated and postgres
# storing of fields.  2005 01 05
#
# Changed registration field for Kimberly to radio buttons.  Changed street
# field to 80 characters.  2005 01 13
#
# Added prices for Kimberly.  2005 01 18 
#
# Added links for Cecilia.  2005 01 18
#
# Re added gom_tables.  2005 02 07



my $firstflag = 1;		# flag if first time around (show form for no data)

# use LWP::Simple;
# use Mail::Mailer;

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Fcntl;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $query = new CGI;
my $user = 'cecilia@tazendra.caltech.edu';	# who sends mail
my $email = 'cecilia@tazendra.caltech.edu, vanauken@its.caltech.edu';	# to whom send mail
# my $email = 'azurebrd@tazendra.caltech.edu';	# to whom send mail
my $subject = 'New Go Consortium Registration';	# subject of mail
my $body = '';			# body of mail

print "Content-type: text/html\n\n";
my $title = 'Go Consortium Registration Data Submission Form';
my ($header, $footer) = &cshlNew($title);
print "$header\n";		# make beginning of HTML page

&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Submit') { 
    $firstflag = "";				# reset flag to not display first page (form)

    my $mandatory_ok = 'ok';			# default mandatory is ok
    my $sender = '';
    my @mandatory = qw ( Reg_fee Diet Country PostalCode City Street Institution Department Email Last_Name First_Name );

    my %mandatoryName;				# hash of field names to print warnings
    $mandatoryName{Reg_fee} = "Registration Fee";
    $mandatoryName{Diet} = "Diet";
    $mandatoryName{Country} = "Country";
    $mandatoryName{PostalCode} = "Postal Code";
    $mandatoryName{State} = "State";
    $mandatoryName{City} = "City";
    $mandatoryName{Street} = "Institution";
    $mandatoryName{Department} = "Department";
    $mandatoryName{URL} = "URL";
    $mandatoryName{FAX} = "FAX";
    $mandatoryName{Phone} = "Phone";
    $mandatoryName{Email} = "Email";
    $mandatoryName{Last_name} = "Last Name";
    $mandatoryName{First_name} = "First Name";
 
    foreach $_ (reverse @mandatory) {			# check mandatory fields
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($_ eq 'Email') {		# check emails
        unless ($val =~ m/@.+\..+/) { 		# if email doesn't match, warn
          print "<FONT COLOR=red SIZE=+2>$val is not a valid email address.</FONT><BR>";
          $mandatory_ok = 'bad';		# mandatory not right, print to resubmit
        } else { $sender = $val; }
      } else { 					# check other mandatory fields
	unless ($val) { 			# if there's no value
          print "<FONT COLOR=red SIZE=+2>$mandatoryName{$_} is a mandatory field.</FONT><BR>";
          $mandatory_ok = 'bad';		# mandatory not right, print to resubmit
        }
      }
    } # foreach $_ (@mandatory)

    if ($mandatory_ok eq 'bad') { 
      print "Please click back and resubmit.<P>";
    } else { 					# if email is good, process
      my $result;				# general pg stuff
      my $joinkey;				# the joinkey for pg
      my $host = $query->remote_host();		# get ip address
      my $body .= "$sender from ip $host sends :\n\n";

      $result = $conn->exec( "SELECT nextval('gom_sequence');" );
      my @row = $result->fetchrow;
      $joinkey = 'gom' . $row[0];

      my @all_vars = qw ( Reg_fee Diet Country PostalCode State City Street Institution Department URL FAX Phone Email Last_Name First_Name );

#       my %aceName;
#       $aceName{locus_1} = 'NULL';			# can't just append, must add with allele_1
#       $aceName{allele_1} = 'NULL';			# add with above
#       $aceName{locus_2} = 'NULL';	      		# can't just append, must add with allele_2
#       $aceName{allele_2} = 'NULL';			# add with above                          ;
#       $aceName{genotype} = 'Genotype';
#       $aceName{results} = 'Results';
#       $aceName{temperature} = 'Temperature';
#       $aceName{mapper} = 'Mapper';
#       $aceName{submitter_email} = 'NULL';
#       $aceName{calc_opt} = 'NULL';			# must add with calc_num
#       $aceName{calc_num} = 'NULL';			# add with above
#       $aceName{calc_distance} = 'Calc_distance';
#       $aceName{calc_lower} = 'Calc_lower_conf';
#       $aceName{calc_upper} = 'Calc_upper_conf';
#       $aceName{lab} = 'Laboratory';
#       $aceName{comment} = 'NULL';
# 
#       my ($var, $mapper) = &getHtmlVar($query, 'mapper');	# using mapper as pg key
#       unless ($mapper =~ m/\S/) {				# if there's no mapper text
#         print "<FONT COLOR='red'>Warning, you have not picked a Mapper</FONT>.<P>\n";
#       } else {							# if tpd text, output
#         $result = $conn->exec( "INSERT INTO tpd_mapper (tpd_mapper) VALUES ('$mapper');" );
#         $result = $conn->exec( "SELECT currval('tpd_seq');" );
#         my @row = $result->fetchrow;
#         $joinkey = $row[0];
#         print "2_pt_data entry number $joinkey<BR><BR>\n";
#         $result = $conn->exec( "INSERT INTO tpd_submitter_email VALUES ('$joinkey', '$sender');" );
#         $result = $conn->exec( "INSERT INTO tpd_ip VALUES ('$joinkey', '$host');" );
#         $body .= "mapper\t$mapper\n";
  
        foreach $_ (reverse @all_vars) { 			# for all fields, check for data and output
          my ($var, $val) = &getHtmlVar($query, $_);
          $body .= "$_ : $val\n";
          my $table = 'gom_' . lc($var);
          $result = $conn->exec( "INSERT INTO $table VALUES ('$joinkey', '$val');" );
        } # foreach $_ (@vars) 
        $email .= ", $sender";
        $body = "Thank you for registering for the GO Meeting.  Please check your registration information to make sure that everything is correct.  We look forward to seeing you in April.\n\n" . $body;
        &mailer($user, $email, $subject, $body);	# email the data
        $body =~ s/\n/<BR>\n/mg;
        print "BODY : <BR>$body<BR><BR>\n";
        print "<P><P><P><H1>Thank you, your info will be updated shortly.</H1>\n";
#         print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> See all <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/two_point_data.ace\">new submissions</A>.<P>\n";
#       } # else # unless ($genotype =~ m/\S/)
    } # else # unless ($sender =~ m/@.+\..+/)
  } # if ($action eq 'Submit') 
} # sub process



sub display {			# show form as appropriate
  if ($firstflag) { # if first or bad, show form 
    print <<"EndOfText";
<html>
  <head>
    <title>2_point_data_submission_form</title>
  </head>

<body bgcolor=FFFFFF>
<title>REGISTRATION: GO Consortium Meeting - April 8 - 9th, 2005 -
Caltech, CA</title>

<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
				<tr valign="middle"><td>
<a href="http://www.geneontology.org/index.shtml"> <img align="left" width="54"
height="50" src="http://www.geneontology.org/images/GOthumbnail.gif" title="Gene
Ontology Consortium" alt="index.shtml"></a></td>

				<td class="h2bg" width="100%" align="center">

						<h2>REGISTRATION:
						GO Consortium Meeting April 8 - 9th, 2005 <br>
						Caltech,
						Pasadena, CA</h2>
						</td>
				</tr>
			</table>
<p><hr size="2" width="100%">
<table border=0 align=center cellpadding=5 cellspacing=10>
        <tr>

		  <td bgcolor="#FFEFD5"><font size=4><a
href="http://tazendra.caltech.edu/~cecilia/stuff/GO_registration_draft.html"><b>Consortium Meeting General Info</b></a></font>
          </td> 
<td bgcolor="#FFEFD5"><font size=4><a
href="http://www.geneontology.org/"><b>GO Home Page</b></a></font>
          </td>
         </tr>
      </table>

<HR size="2" width="80%">

<FORM METHOD="POST" ACTION="go_consortium_registration.cgi">

<b>PERSONAL INFORMATION</b><p>

<b>Many of the fields have maximum size limits, so you must fit
your information within the space provided.</b>
<p>

<TABLE border=0>
<TR>
<TD ALIGN=RIGHT><B>First Name:</B></TD>
<TD><INPUT NAME="First_Name" SIZE=15><I>e.g.,</I> Samantha <I>or</I>

J. Stephen <I>or</I> Marcus R. (required)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Last (Family) Name(s):</B></TD>
<TD><INPUT NAME="Last_Name" SIZE=25><I>e.g.,</I> Smith <I>or</I>
Van Buren (required)</TD>

</TR>

<TR>
<TD ALIGN=RIGHT><B>e-mail:</B></TD>
<TD><INPUT NAME="Email" SIZE=40 maxlength=40>(required)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Phone:</B></TD>
<TD><INPUT NAME="Phone" SIZE=22 maxlength=22>(include country code -
optional)</TD>
</TR>

<TR>

<TD ALIGN=RIGHT><B>FAX:</B></TD>
<TD><INPUT NAME="FAX" SIZE=22 maxlength=22>(include country code -
optional)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Web Homepage:</B></TD>
<TD><INPUT NAME="URL" SIZE=35>(optional)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Department:</B></TD>
<TD><INPUT name="Department" size=30 maxlength=30>(required)</TD>

</TR>

<TR>
<TD ALIGN=RIGHT><B>Institution:</B></TD>
<TD><INPUT name="Institution" size=30 maxlength=30>(required)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Street:</B></TD>
<TD><INPUT name="Street" size=80 maxlength=80>(required)</TD>
</TR>

<TR>

<TD ALIGN=RIGHT><B>City:</B></TD>
<TD><INPUT name="City" size=17 maxlength=17>(required)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>US State:</B></TD>
<TD><INPUT name="State" size=2 maxlength=2>(optional)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Postal Code:</B></TD>
<TD><INPUT name="PostalCode" size=10 maxlength=10>(required)</TD>

</TR>

<TR>
<TD ALIGN=RIGHT><B>Country:</B></TD>
<TD><INPUT name="Country" size=30 maxlength=30>(required)</TD>
</TR>

<TR>
<TD ALIGN=RIGHT><B>Dietary Requirements:</B></TD>
<td>
<DD>      <SELECT NAME="Diet">
<OPTION Selected Value="None">None
<OPTION Value="Vegetarian">Vegetarian
</SELECT>
</td>
</tr>
<tr>

<TR>
<TD ALIGN=RIGHT><B>Registration Fee:</B></TD>
<TD>
      <table>
          <TR><Input Type="radio" Name = "Reg_fee" Value="external">\$180.00 -- GO External Advisory Board Meeting ONLY, April 6th and 7th</TR><BR>
          <TR><Input Type="radio" Name = "Reg_fee" Value="consortium">\$135.00 -- GO Consortium Meeting ONLY, April 8th and 9th</TR><BR>
          <TR><Input Type="radio" Name = "Reg_fee" Value="both">\$315.00 -- BOTH  Meetings, April 6th - 9th</TR><BR>
      </table>
</TD>
<!--
<td>
<DD>      <SELECT NAME="Reg_fee">
<OPTION Selected Value="External">GO External Advisory Board Meeting \$</OPTION>
<OPTION Value="Consortium">GO Consortium Meeting \$</OPTION>
<OPTION Value="Both">Both \$</OPTION>
</SELECT>
</td>-->
</tr>
<tr>
<!--<td ALIGN=RIGHT><b>Registration Fee:</b></td><td>$130.00 (Please bring
cash or check to the meeting.)</td></tr>-->
<tr><td ALIGN=RIGHT><b>Registration Deadline:</b></td><td>March 13, 2005 (note that the deadline for special hotel rates is March 13, 2005).</td></tr>
<tr>
<td align=RIGHT><b>Accommodation and Travel:</b></td><td><a
href="http://tazendra.caltech.edu/~cecilia/stuff/GO_registration_draft.html">Click here</a></td></tr>
</TABLE>



    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    <TR></TR> <TR></TR> <TR></TR> <TR></TR>
    
    <TR><TD COLSPAN=2> </TD></TR>
    <TR>
      <TD> </TD>
      <TD><INPUT TYPE="submit" NAME="action" VALUE="Submit">
        <INPUT TYPE="reset"></TD>
    </TR>
  </TABLE>

</FORM>
<HR size="2" width="80%">
If you have any problems, questions, or comments, please contact <A HREF=\"mailto:cecilia\@tazendra.caltech.edu, vanauken\@its.caltech.edu\">cecilia\@tazendra.caltech.edu, vanauken\@its.caltech.edu</A>

<!-- Created: Tue Nov 19 12:51:54 GMT 2002 -->
<!-- hhmts start -->
<!--Last modified: Tue Nov 19 22:28:10 GMT Standard Time 2002-->
<!-- hhmts end -->
  </body>
</html>

EndOfText

  } # if (firstflag) show form 
} # sub display

