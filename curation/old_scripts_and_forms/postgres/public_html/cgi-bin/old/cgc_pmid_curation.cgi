#!/usr/bin/perl -w

# Insert CGC - PMID connection.

# Type in CGC and PMID numbers, get a connection in postgres table 
# ref_xrefpmidforced   2003 10 02



use strict;
use CGI;
use Pg;
use LWP::Simple;
use Jex; 	# getHtmlVar, mailer

my $query = new CGI;


my %variables;			# hash that stores all gene function form related data

my %missing_cgc;		# hash of cgc's without pmids


  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&PrintHeader();			# print the HTML header
&Process();			# Do pretty much everything
&PrintFooter();			# print the HTML footer


sub getMissing {
  my %xref;
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) { $xref{$row[0]}++; }
  $result = $conn->exec( "SELECT * FROM ref_cgc;" );
  while (my @row = $result->fetchrow) { 
    unless ($xref{$row[0]}) { $missing_cgc{$row[0]}++; }
  } # while (my @row = $result->fetchrow)
} # sub getMissing


sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none'; 
    &displayHtmlCuration();
  }

  if ($action eq 'Start Over !') {
    &displayHtmlCuration();
  } # if ($action eq 'Start Over !')

    # if new postgres command or curator chosen
  if ($action eq 'Preview !') {
    if ($action eq 'Preview !') { &preview(); }
  } # if ($action eq 'Preview !')

  elsif ( ($action eq 'Update !') || ($action eq 'New Entry !') ) {
    &commitData();
  } # elsif ($action eq 'Preview !')
} # sub Process


sub commitData {
  &getHtml();
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cgc_pmid_curation.cgi\">\n";
  &displayVars();
  &dealPg();
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Start Over !\">\n";
  print "</FORM>\n";
} # sub commitData {

sub dealPg {
    # insert into ref_xrefpmidforced table for posterity and ref_xref for now until the next wrapper
    # script reconnects all cgcs and pmids.
  my $result = $conn->exec( "INSERT INTO ref_xrefpmidforced VALUES ('cgc$variables{cgc}', 'pmid$variables{pmid}', CURRENT_TIMESTAMP);" );
  $result = $conn->exec( "INSERT INTO ref_xref VALUES ('cgc$variables{cgc}', 'pmid$variables{pmid}', CURRENT_TIMESTAMP);" );
} # sub dealPg

sub preview {
  &getHtml();
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cgc_pmid_curation.cgi\">\n";
  &displayVars();
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update !\">\n";
  print "</FORM>\n";
} # sub preview

sub getHtml {
  my $oop;
  ($oop, $variables{cgc}) = &getHtmlVar($query, 'cgc');
  ($oop, $variables{pmid}) = &getHtmlVar($query, 'pmid');
} # sub getHtml

sub displayVars {
  print "<FONT COLOR = green>CGC Number : $variables{cgc}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"cgc\" VALUE=\"$variables{cgc}\">\n";
  print "<FONT COLOR = green>PMID Number : $variables{pmid}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"pmid\" VALUE=\"$variables{pmid}\">\n";
  $variables{cgc} =~ s/\D//g;
  $variables{pmid} =~ s/\D//g;
  print "Your connection is : cgc$variables{cgc} to pmid$variables{pmid}.<BR>\n";
} # sub displayVars



sub displayHtmlCuration {
  &getMissing();
  print <<"EndOfText";
<A NAME="form"><H1>Add your entries : </H1></A><BR>

<FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/cgc_pmid_curation.cgi">

<TABLE>
<TR>
<TD ALIGN="right"><STRONG>CGC number :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="cgc" VALUE="$variables{cgc}" SIZE=40></TD>
	       <TD><FONT SIZE=-1>(e.g. 'cgc3')</FONT></TD></TR></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>PMID number :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="pmid" VALUE="$variables{pmid}" SIZE=40></TD>
               <TD><FONT SIZE=-1>(e.g. 'pmid1234567')</TD>
           </TR></TABLE></TD>
</TR>

<TR><TD COLSPAN=2> </TD></TR>
<TR>
<TD> </TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Preview !"></TD>
</TR>
</TABLE>

</FORM>
EndOfText
  foreach my $key (sort keys %missing_cgc) {
    print "$key<BR>\n";
  } # foreach my $key (sort keys %missing_cgc)
} # sub displayHtmlCuration




sub PrintFormOpen {		# open form link to appropriate curation_name.cgi 
				# depending on the curator
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cgc_pmid_curation.cgi\">";
} # sub PrintFormOpen 


sub PrintHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">
  
<HEAD>
<TITLE>CGC PMID Curation</TITLE>
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<!--<HR>
<CENTER>Documentation <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/cgc_pmid_curation.txt"
TARGET=NEW>here</A><BR>Submit data before 1pm on the Wednesday before uploads<BR>(subject to change
depending on who builds citace)</CENTER><P>-->
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

