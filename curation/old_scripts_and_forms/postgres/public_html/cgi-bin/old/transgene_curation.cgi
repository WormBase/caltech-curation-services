#!/usr/bin/perl 

# THIS WAS NEVER USED.  Variables need to be cleaned up and postgres tables
# created.  2007 01 23

# Form to curate Transgene information.

# an transgene form to make .ace files and email curator
# This version gets headers and footers off of www.wormbase.org with LWP / Jex,
# untaints and gets HTML values with CGI / Jex, sends mail with Mail::Mailer /
# Jex   2002 05 14

my $acefile = "/home/azurebrd/public_html/cgi-bin/data/transgene.ace";

my $firstflag = 1;		# flag if first time around (show form for no data)

use LWP::Simple;
use Mail::Mailer;

my ($header, $footer) = &cshlNew('Transgene Curation');

use Jex;			# untaint, getHtmlVar, cshlNew
use strict;
use CGI;
use Pg;

my $query = new CGI;

my %theHash;
my @vars = qw(transgene summary Driven_by_Locus GFP LacZ Other_reporter Worm_gene author email clone Injected_into_CGC_strain injected_into integrated_by location strain map phenotype rescue Reference remark);


print "Content-type: text/html\n\n";
print "$header\n";		# make beginning of HTML page

my %section;
&initSections();

&process();
&displayForm();
print "</TABLE>\n$footer"; 		# make end of HTML page


sub process {
  &getHtmlValues();
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  if ($action =~ m/expand/) { 
    if ($action =~ m/composition/) { $section{composition} = 'yes'; }
    if ($action =~ m/isolation/) { $section{isolation} = 'yes'; }
    if ($action =~ m/related/) { $section{related} = 'yes'; }
    if ($action =~ m/datasource/) { $section{datasource} = 'yes'; } }
  elsif ($action =~ m/compress/) { 
    if ($action =~ m/composition/) { $section{composition} = 'no'; }
    if ($action =~ m/isolation/) { $section{isolation} = 'no'; }
    if ($action =~ m/related/) { $section{related} = 'no'; }
    if ($action =~ m/datasource/) { $section{datasource} = 'no'; } }
}

sub displayForm {
  &printFormTop();
  &printComposition();
  &printIsolation();
  &printRelated();
  &printDatasource();
  &printRemark();
  print "</FORM>\n";
} # sub displayForm

sub printRelated {
  print "<TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>\n";
  print "<INPUT TYPE=hidden NAME=related_flag VALUE=\"$section{related}\">\n"; 
  if ($section{related} eq 'no') {
    print "<INPUT TYPE=hidden NAME=map VALUE=\"$theHash{map}\">\n"; 
    print "<INPUT TYPE=hidden NAME=phenotype VALUE=\"$theHash{phenotype}\">\n"; 
    print "<INPUT TYPE=hidden NAME=rescue VALUE=\"$theHash{rescue}\">\n"; 
    print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"expand related\"></TD></TR>\n";
    return;
  }
  print "<TR><TD ALIGN=left><b>Related Information : </b></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"compress related\"></TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Map :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=map VALUE=\"$theHash{map}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : Chromosome IV, tightly linked to...</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Phenotype :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=phenotype VALUE=\"$theHash{phenotype}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : Unc, Egl, Let. animals paralyzed ...</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Rescue :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=rescue VALUE=\"$theHash{rescue}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : goa-1(n363)</TD></TR>\n";
} # sub printRelated

sub printDatasource {
  print "<TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>\n";
  print "<INPUT TYPE=hidden NAME=datasource_flag VALUE=\"$section{datasource}\">\n"; 
  if ($section{datasource} eq 'no') {
    print "<INPUT TYPE=hidden NAME=Reference VALUE=\"$theHash{Reference}\">\n"; 
    print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"expand datasource\"></TD></TR>\n";
    return;
  }
  print "<TR> <TD ALIGN=left><b>Data Source : </b></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"compress datasource\"></TD>\n";
  print "<TD> (where curators can confirm the data)</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Reference Info :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=Reference VALUE=\"$theHash{reference}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : Science 274, 113-115 ...</TD></TR>\n";
} # sub printDatasource

sub printRemark {
  print "<TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>\n";
  print "<TR><TD ALIGN=left><b>Remark :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=remark VALUE=\"$theHash{remark}\" SIZE=30></TABLE></TD>\n";
  print "<TD>Write comments here</TD></TR>\n";
} # sub printRemark

sub printIsolation {
  print "<TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>\n";
  print "<INPUT TYPE=hidden NAME=isolation_flag VALUE=\"$section{isolation}\">\n"; 
  if ($section{isolation} eq 'no') {
    print "<INPUT TYPE=hidden NAME=Author VALUE=\"$theHash{Author}\">\n"; 
    print "<INPUT TYPE=hidden NAME=Clone VALUE=\"$theHash{Clone}\">\n"; 
    print "<INPUT TYPE=hidden NAME=Injected_into_CGC_strain VALUE=\"$theHash{Injected_into_CGC_strain}\">\n"; 
    print "<INPUT TYPE=hidden NAME=injected_into VALUE=\"$theHash{injected_into}\">\n"; 
    print "<INPUT TYPE=hidden NAME=integrated_by VALUE=\"$theHash{integrated_by}\">\n"; 
    print "<INPUT TYPE=hidden NAME=location VALUE=\"$theHash{location}\">\n"; 
    print "<INPUT TYPE=hidden NAME=strain VALUE=\"$theHash{strain}\">\n"; 
    print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"expand isolation\"></TD></TR>\n";
    return;
  }
  print "<TR><TD ALIGN=left><b>Isolation : </b></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"compress isolation\"></TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Author : </b></TD>\n";
  print "<TD><TABLE><INPUT NAME=author VALUE=\"$theHash{author}\" SIZE=30></TABLE></TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Clone :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=clone VALUE=\"$theHash{clone}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : ZK863</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Injected into CGC Strain :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=Injected_into_CGC_strain VALUE=\"$theHash{Injected_into_CGC_strain}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : PS99</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Injected Into :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=injected_into VALUE=\"$theHash{injected_into}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : goa-1(n363); dpy-20(e1282)...</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Integrated By :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=integrated_by VALUE=\"$theHash{integrated_by}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : X_ray</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Location :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=location VALUE=\"$theHash{location}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : PS</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Strain :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=strain VALUE=\"$theHash{strain}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : PS3351</TD></TR>\n";
} # sub printIsolation


sub printComposition {
  print "<TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR> <TR></TR>\n";
  print "<INPUT TYPE=hidden NAME=composition_flag VALUE=\"$section{composition}\">\n"; 
  if ($section{composition} eq 'no') {
    print "<INPUT TYPE=hidden NAME=summary VALUE=\"$theHash{summary}\">\n"; 
    print "<INPUT TYPE=hidden NAME=Driven_by_GeneID VALUE=\"$theHash{Driven_by_GeneID}\">\n"; 
    print "<INPUT TYPE=hidden NAME=GFP VALUE=\"$theHash{GFP}\">\n"; 
    print "<INPUT TYPE=hidden NAME=LacZ VALUE=\"$theHash{LacZ}\">\n"; 
    print "<INPUT TYPE=hidden NAME=Other_reporter VALUE=\"$theHash{Other_reporter}\">\n"; 
    print "<INPUT TYPE=hidden NAME=Worm_gene VALUE=\"$theHash{Worm_gene}\">\n"; 
    print "<TR><TD><INPUT TYPE=submit NAME=action VALUE=\"expand composition\"></TD></TR>\n";
    return;
  }
  print "<TR><TD ALIGN=left><b>Transgene Composition : </b></TD>\n";
  print "<TD><INPUT TYPE=submit NAME=action VALUE=\"compress composition\"></TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Summary :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=summary VALUE=\"$theHash{summary}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g : [hsp16-2::goa-1(Q205L)\; dpy-20(+)]. ...</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Driven by GeneID :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=Driven_by_GeneID VALUE=\"$theHash{Driven_by_GeneID}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : HSP16B</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Drives GFP :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=GFP VALUE=\"$theHash{GFP}\" SIZE=30></TABLE></TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Drives lacZ :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=LacZ VALUE=\"$theHash{LacZ}\" SIZE=30></TABLE></TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Drives Other Reporter : </b></TD>\n";
  print "<TD><TABLE><INPUT NAME=Other_reporter VALUE=\"$theHash{Other_reporter}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : HA tag ...</TD></TR>\n";

  print "<TR><TD ALIGN=right><b>Drives Worm Gene :</b></TD>\n";
  print "<TD><TABLE><INPUT NAME=Worm_gene VALUE=\"$theHash{Worm_gene}\" SIZE=30></TABLE></TD>\n";
  print "<TD>e.g. : goa-1, with Q205L mutation ...</TD></TR>\n";
} # sub printComposition

sub getHtmlValues {
  foreach $_ (@vars) { 
    my ($var, $val) = &getHtmlVar($query, $_);
    if ($val) { $theHash{$var} = $val; } }
  &getSections();
} # sub getHtmlValues

sub getSections {
  my ($var, $val) = &getHtmlVar($query, 'composition_flag');
  if ($val eq 'no') { $section{composition} = 'no'; }
  if ($val eq 'yes') { $section{composition} = 'yes'; }
  ($var, $val) = &getHtmlVar($query, 'isolation_flag');
  if ($val eq 'no') { $section{isolation} = 'no'; }
  if ($val eq 'yes') { $section{isolation} = 'yes'; }
  ($var, $val) = &getHtmlVar($query, 'related_flag');
  if ($val eq 'no') { $section{related} = 'no'; }
  if ($val eq 'yes') { $section{related} = 'yes'; }
  ($var, $val) = &getHtmlVar($query, 'datasource_flag');
  if ($val eq 'no') { $section{datasource} = 'no'; }
  if ($val eq 'yes') { $section{datasource} = 'yes'; }
} # sub getSections


sub printFormTop {
    print <<"EndOfText";
<P><BR><P>
<FORM METHOD="POST" ACTION="transgene_curation.cgi">
<TABLE>

<TR>
<TD ALIGN="left"><b>Transgene : </b></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Transgene :</b></TD>
<TD><TABLE><INPUT NAME="transgene" VALUE="$theHash{transgene}" SIZE=30></TABLE></TD>
<TD>e.g. : syIs17</TD>
</TR>
EndOfText
} # sub printFormTop

sub initSections {
  $section{composition} = 'yes';
  $section{isolation} = 'yes';
  $section{related} = 'yes';
  $section{datasource} = 'yes';
} # sub initSections

__END__

my $user = 'transgene_form';		# who sends mail
my $email = "wchen\@its.caltech.edu";	# to whom send mail
my $subject = 'transgene data';	# subject of mail
my $body = '';					# body of mail


&process();			# see if anything clicked
&display();			# show form as appropriate
print "$footer"; 		# make end of HTML page

sub process {			# see if anything clicked
  my $action;			# what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'Go !') { 
    $firstflag = "";		# reset flag to not display first page (form)
    open (OUT, ">>$acefile") or die "Cannot create $acefile : $!";
    my @vars = qw(transgene summary Driven_by_GeneID Driven_by_Sequence GFP LacZ Other_reporter Worm_gene Worm_sequence author email clone Injected_into_CGC_strain injected_into integrated_by location strain map phenotype rescue CGC_number Other_ID Reference remark);
    foreach $_ (@vars) { 
      my ($var, $val) = &getHtmlVar($query, $_);
      if ($val =~ m/\S/) { 	# if value entered
        if ($_ eq 'email') {	
          $email .= ', ' . $val; }
        if ($_ eq 'transgene') {	# print main tag if transgene
          print OUT "@{[ucfirst($var)]} : [$val] \n";
          print "@{[ucfirst($var)]} : [$val]<BR>\n";
          $body .= "@{[ucfirst($var)]} : [$val]\n";
        } # if ($_ eq 'transgene')
        print OUT "@{[ucfirst($var)]} \"$val\" \n";
        print "@{[ucfirst($var)]} \"$val\" <BR>\n";
        $body .= "@{[ucfirst($var)]} \"$val\"\n";
      } # if ($val) 
    } # foreach $_ (@vars) 
    print OUT "\n";		# divider for outfile
    close (OUT) || die "cannot close $acefile : $!";
    &mailer($user, $email, $subject, $body);	# email wen the data
    print "<P><P><P><H1>Thank you, your info will be updated shortly.</H1>\n";
    print "If you wish to modify your submitted information, please go back and resubmit.<BR><P> See all <A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/transgene.ace\">new submissions</A>.<P>\n";
  } # if ($action eq 'Go !') 
} # sub process


sub display {			# show form as appropriate
  if ($firstflag) { # if first or bad, show form 
    print <<"EndOfText";
<A NAME="form"><H1>Transgene curation form :</H1></A>

<!--Use this form for reporting new Transgene data.<BR><BR>
We only accept integrated transgenic lines.<BR><BR>
If you don't know or don't have something, leave the field
blank.<BR><BR>-->
<!--If you have any problems or questions, please email me.<BR><BR>-->

<!--<HR>-->

<FORM METHOD="POST" ACTION="transgene.cgi">
<TABLE>

<TR>
<TD ALIGN="left"><b>Transgene : </b></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Transgene :</b></TD>
<TD><TABLE><INPUT NAME="transgene" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : syIs17</TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR> 
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="left"><b>Transgene Composition : </b></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Summary :</b></TD>
<TD><TABLE><INPUT NAME="summary" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g : [hsp16-2::goa-1(Q205L)\; dpy-20(+)]. ...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Driven by Locus :</b></TD>
<TD><TABLE><INPUT NAME="Driven_by_Locus" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : HSP16B</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Driven By Sequence :</b></TD>
<TD><TABLE><INPUT NAME="Driven_by_Sequence" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : ZK863.1</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Drives GFP :</b></TD>
<TD><TABLE><INPUT NAME="GFP" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Drives lacZ :</b></TD>
<TD><TABLE><INPUT NAME="LacZ" VALUE="" SIZE=30></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Drives Other Reporter : </b></TD>
<TD><TABLE><INPUT NAME="Other_reporter" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : HA tag ...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Drives Worm Gene :</b></TD>
<TD><TABLE><INPUT NAME="Worm_gene" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : goa-1, with Q205L mutation ...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Drives Worm Sequence :</b></TD>
<TD><TABLE><INPUT NAME="Worm_sequence" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : ZK863.1 ...</TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR> 
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="left"><b>Isolation : </b></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Author : </b></TD>
<TD><TABLE><INPUT NAME="author" VALUE="" SIZE=30></TABLE></TD>
</TR>

<!--<TR>
<TD ALIGN="right"><b>Email : </b></TD>
<TD><TABLE><INPUT NAME="email" VALUE="" SIZE=30></TABLE></TD>
<TD>If you don't get a verification email, email us at webmaster\@wormbase.org</TD>
</TR>-->

<TR>
<TD ALIGN="right"><b>Clone :</b></TD>
<TD><TABLE><INPUT NAME="clone" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : ZK863</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Injected into CGC Strain :</b></TD>
<TD><TABLE><INPUT NAME="Injected_into_CGC_strain" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : PS99</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Injected Into :</b></TD>
<TD><TABLE><INPUT NAME="injected_into" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : goa-1(n363); dpy-20(e1282)...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Integrated By :</b></TD>
<TD><TABLE><INPUT NAME="integrated_by" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : X_ray</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Location :</b></TD>
<TD><TABLE><INPUT NAME="location" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : PS</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Strain :</b></TD>
<TD><TABLE><INPUT NAME="strain" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : PS3351</TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR>
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="left"><b>Related Information : </b></TD>
</TR>

<TR>
<TD ALIGN="right"><b>Map :</b></TD>
<TD><TABLE><INPUT NAME="map" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : Chromosome IV, tightly linked to...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Phenotype :</b></TD>
<TD><TABLE><INPUT NAME="phenotype" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : Unc, Egl, Let. animals paralyzed ...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Rescue :</b></TD>
<TD><TABLE><INPUT NAME="rescue" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : goa-1(n363)</TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR> 
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="left"><b>Data Source : </b></TD>
<TD></TD>
<TD> (where curators can confirm the data)</TD>
</TR>

<TR>
<TD ALIGN="right"><b>CGC Number :</b></TD>
<TD><TABLE><INPUT NAME="CGC_number" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : 4501</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Other ID :</b></TD>
<TD><TABLE><INPUT NAME="Other_ID" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : PMID11134024, or medline ...</TD>
</TR>

<TR>
<TD ALIGN="right"><b>Reference Info :</b></TD>
<TD><TABLE><INPUT NAME="Reference" VALUE="" SIZE=30></TABLE></TD>
<TD>e.g. : Science 274, 113-115 ...</TD>
</TR>

<TR></TR> <TR></TR> <TR></TR> <TR></TR> 
<TR></TR> <TR></TR> <TR></TR> <TR></TR>

<TR>
<TD ALIGN="right"><b>Remark :</b></TD>
<TD><TABLE><INPUT NAME="remark" VALUE="" SIZE=30></TABLE></TD>
<TD>Write comments here</TD>
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
<!--If you have any problems, questions, or comments, please email <A HREF=\"mailto:wchen\@its.caltech.edu\">wchen\@its.caltech.edu</A>-->
EndOfText

  } # if (firstflag) show form 
} # sub display
