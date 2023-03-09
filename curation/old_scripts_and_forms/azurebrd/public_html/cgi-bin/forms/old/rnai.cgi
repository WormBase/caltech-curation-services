#!/usr/bin/perl 

# Form to submit RNAi information.

# an rnai form to make .ace files and email curator
# This version gets headers and footers off of www.wormbase.org with LWP / Jex,
# untaints and gets HTML values with CGI / Jex, sends mail with Mail::Mailer /
# Jex   2002 05 14

my $acefile = "/home/azurebrd/public_html/cgi-bin/data/rnai.ace";

my $firstflag = 1;		# flag if first time around (show form for no data)

use LWP::Simple;
use Mail::Mailer;

my ($header, $footer) = &cshlNew();

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Fcntl;

my $query = new CGI;
my $user = 'rnai_form';		# who sends mail
my $email = "raymond\@its.caltech.edu";	# to whom send mail
my $subject = 'rnai data';	# subject of mail
my $body = '';					# body of mail

print "Content-type: text/html\n\n";
print "$header\n";		# make beginning of HTML page

&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Go !') { 
    $firstflag = "";		# reset flag to not display first page (form)
    open (OUT, ">>$acefile") or die "Cannot create $acefile : $!";
    my @vars = qw(sequence method laboratory email author date strain delivered_by predicted_gene locus reference phenotype remark);
    foreach $_ (@vars) { 
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($val =~ m/\S/) { 	# if value entered
        if ($_ eq 'email') {	# append email to email
          $email .= ', ' . $val; }
        if ($_ eq 'sequence') {	# print main tag if sequence
          print OUT "RNAi : [$val] \n";
          print "RNAi : [$val]<BR>\n";
          $body .= "RNAi : [$val]\n";
        } # if ($_ eq 'sequence')
        print OUT "@{[ucfirst($var)]} \"$val\" \n";
        print "@{[ucfirst($var)]} \"$val\" <BR>\n";
        $body .= "@{[ucfirst($var)]} \"$val\"\n";
      } # if ($val) 
    } # foreach $_ (@vars) 
    print OUT "\n";		# divider for outfile
    close (OUT) || die "cannot close $acefile : $!";
    &mailer($user, $email, $subject, $body);	# email wen the data
    print "<P><P><P><H1>Thank you, your info will be updated shortly.</H1>\n";
    print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> See all <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/rnai.ace\">new submissions</A>.<P>\n";
  } # if ($action eq 'Go !') 
} # sub process


sub display {			# show form as appropriate
  if ($firstflag) { # if first or bad, show form 
    print <<"EndOfText";


<A NAME="form"><H1>NEW RNAi SUBMISSION :</H1></A>

Use this form for reporting new RNAi data.<BR><BR>
<!--To see an example of this type of data click here : <A HREF=\"http://tazendra.caltech.edu/~azurebrd/rnaiexample.txt\">Example</A>.<BR><BR>-->
If you don't know or don't have something, leave the field
blank.<BR><BR>
<!--If you have any problems or questions, please email me.<BR><BR>-->

<HR>

<FORM METHOD="POST" ACTION="rnai.cgi">
<TABLE>


<TR>
<TD ALIGN="right"><b>Sequence :</b></TD>
<TD><TABLE><INPUT NAME="sequence" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Method :</b></TD>
<TD><TABLE><INPUT NAME="method" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR> 
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="right"><b>Experiment : Laboratory :</b></TD>
<TD><TABLE><INPUT NAME="laboratory" VALUE="" SIZE=10></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Author :</b></TD>
<TD><TABLE><INPUT NAME="author" VALUE="" SIZE=10></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Email :</b></TD>
<TD><TABLE><INPUT NAME="email" VALUE="" SIZE=10></TABLE></TD>
<TD>If you don't get a verification email,<BR>email us at webmaster\@wormbase.org</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Date :</b></TD>
<TD><TABLE><INPUT NAME="date" VALUE="" SIZE=10></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Strain : </b></TD>
<TD><TABLE><INPUT NAME="strain" VALUE="" SIZE=15></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Delivered By :</b></TD>
<TD><TABLE><INPUT NAME="delivered_by" VALUE="" SIZE=20></TABLE></TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR>
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="right"><b>Inhibits : Predicted_gene :</b></TD>
<TD><TABLE><INPUT NAME="predicted_gene" VALUE="" SIZE=20></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Locus : </b></TD>
<TD><TABLE><INPUT NAME="locus" VALUE="" SIZE=20></TABLE></TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR> 
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="right"><b>Reference :</b></TD>
<TD><TABLE><INPUT NAME="reference" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Phenotype :</b></TD>
<TD><TABLE><INPUT NAME="phenotype" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Remark :</b></TD>
<TD><TABLE><INPUT NAME="remark" VALUE="" SIZE=30></TABLE></TD>
</TR>

<!--
<TR>
<TD ALIGN="right"><b>Comment :</b></TD>
<TD><TABLE><INPUT NAME="comment" VALUE="" SIZE=30></TABLE></TD>
</TR>-->

<TR><TD COLSPAN=2> </TD></TR>
<TR>
<TD> </TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Go !">
    <INPUT TYPE="reset"></TD>
</TR>
</TABLE>

</FORM>
If you have any problems, questions, or comments, please email <A HREF=\"mailto:raymond\@its.caltech.edu\">raymond\@its.caltech.edu</A>
EndOfText

  } # if (firstflag) show form 
} # sub display
