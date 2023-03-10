#!/usr/bin/perl -w

# Curate paper-locus exclusion connections only.

# Pick your name, choose ``Curate !''
# Enter the public ID number (e.g. 'cgc3' or 'WBPaper00000001')
# Enter the Locus you'd like to exclude from the paper (e.g. pie-1)
# Enter the Remark of why you are excluding it (e.g. author typo)
# Click ``Preview !''
# The relevant information is shown, the Locus connections are in green.
# Click the ``New Entry !'' button.
# 
# If you'd like to see Loci curated for a given Paper, 
# enter data in the public ID number box and click ``Query !''
# 
# Data is stored separetly for each Person evidence + paper ID + Locus.
# 
# To delete or edit information, contact Juancarlos for direct psql access
# to postgresql database.
# 
# The data is stored on tazendra in postgresql it the testdb database
# in the ref_cgcgenedeletion table.  
#
#
# Very simple form.  Choose curator, use only # one PG table.  2003 09 09
#
# ref_cgcgenedeletion table in pg has joinkey ref_paper and ref_cgcgenedeletion
# (which are not indexed).  each row has its own paper-locus-curator-remark,
# multiples are possible.  deletion and updating are not allowed through form
# because Eimear thinks it unlikely to be necessary.  2003 09 09
#
# Added Keith, Chao-Kung, Tamberlyn, Aniko, Darin, and John Spieth.  2003 09 11
#
# Display deleted stuff, sorted by paper ID.  2004 02 18
#
# Added Eimear.  
# Added "Add More !" button to keep adding exclusions.  2004 02 19



use strict;
use CGI;
use Pg;
use LWP::Simple;
use Jex; 	# getHtmlVar

my $query = new CGI;


my $curator = "";		# initialize curator
my %variables;			# hash that stores all gene function form related data


  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&PrintHeader();			# print the HTML header
&Process();			# Do pretty much everything
&Display(); 			# Select whether to show selectors for curator name
				# entries / page, and &ShowPgQuery();
&PrintFooter();			# print the HTML footer

sub Display {
  if ( !($curator) ) { &ChooseCurator(); }
				# if no curator (first loaded), show selectors
  else { &ShowPgQuery(); }	# if not, offer option to do Pg query instead
} # sub Display

sub ChooseCurator {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion.cgi\">";
  print "<TABLE>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=16>\n";
  print "<OPTION VALUE='WBPerson22'>Igor Antoshechkin</OPTION>\n";
  print "<OPTION VALUE='WBPerson48'>Carol Bastiani</OPTION>\n";
  print "<OPTION VALUE='WBPerson1849'>Tamberlyn Bieri</OPTION>\n";
  print "<OPTION VALUE='WBPerson1848'>Darin Blasiar</OPTION>\n";
  print "<OPTION VALUE='WBPerson1971'>Keith Bradnam</OPTION>\n";
  print "<OPTION VALUE='WBPerson1841'>Eimear Kenny</OPTION>\n";
  print "<OPTION VALUE='WBPerson1845'>Chao-Kung Chen</OPTION>\n";
  print "<OPTION VALUE='WBPerson101'>Wen Chen</OPTION>\n";
  print "<OPTION VALUE='WBPerson324'>Ranjana Kishore</OPTION>\n";
  print "<OPTION VALUE='WBPerson363'>Raymond Lee</OPTION>\n";
  print "<OPTION VALUE='WBPerson480'>Andrei Petcherski</OPTION>\n";
  print "<OPTION VALUE='WBPerson1850'>Aniko Sabo</OPTION>\n";
  print "<OPTION VALUE='WBPerson567'>Erich Schwarz</OPTION>\n";
  print "<OPTION VALUE='WBPerson615'>John Spieth</OPTION>\n";
  print "<OPTION VALUE='WBPerson625'>Paul Sternberg</OPTION>\n";
  print "<OPTION VALUE='WBPerson1843'>Kimberly Van Auken</OPTION>\n";
  print "<OPTION VALUE='WBPerson1823'>Juancarlos Testing</OPTION>\n";
  print "</SELECT></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curate !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
  &displayExcluded();
} # sub ChooseCurator

sub displayExcluded {
  my $result = $conn->exec( "SELECT * FROM ref_cgcgenedeletion ORDER BY ref_paper;" );
  print "<TABLE border=2>\n";
  while (my @row = $result->fetchrow) {
    print "<TR><TD>$row[0]</TD><TD>$row[1]</TD><TD>$row[2]</TD><TD>$row[4]</TD><TD>$row[3]</TD></TR>\n";
  } # while (my @row = $result->fetchrow)
  print "</TABLE>\n";
} # sub displayExcluded

sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none'; 
  }
#   &populateHashes();		# fill hashes with xreference data

    # if new postgres command or curator chosen
  if ( ($action eq 'Curate !') || ($action eq 'Add More !') ) {
    $curator = &getCurator();
#     $variables{confirmed} = $curator;
#     &CuratePopulate();
    &displayHtmlCuration();
  } # if ($action eq 'Curate !')

  elsif ($action eq 'Reset !') {
    $curator = &getCurator();
    &resetForDisplay();         # Clear all Variables for HTML
    &displayHtmlCuration();
  } # elsif ($action eq 'Reset !')

  elsif ($action eq 'Query !') {
    $curator = &getCurator();
    &queryPG();
    if ($variables{pubID}) { &PopulateReference(); }
    &displayHtmlCuration();
  } # elsif ($action eq 'Query !')

  elsif ($action eq 'Preview !') {
    $curator = &getCurator();
    if ($action eq 'Preview !') { &preview(); }
#     elsif ($action eq 'Save !') { &saveState(); } 
  } # elsif ($action eq 'Preview !')

  elsif ( ($action eq 'Update !') || ($action eq 'New Entry !') ) {
    $curator = &getCurator();
    &commitData();
  } # elsif ($action eq 'Preview !')
} # sub Process


sub getCurator {
  my ($oop, $curator) = &getHtmlVar($query, 'curator_name');
  unless ($curator =~ m/^WBPerson\d+$/) { print "<FONT COLOR=red>\"$curator\" is not a valid WBPerson number.</FONT>"; $curator = 'error'; }
  return $curator;
} # sub getCurator

sub commitData {
  &getHtml();
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion.cgi\">\n";
  &displayVars();
  &dealPg();
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Add More !\">\n";
  print "</FORM>\n";
} # sub commitData {

sub dealPg { 		# insert all stuff into its own row (allowing multiples due to possible different remarks
#     my $result = $conn->exec( "insert into cur_curator values ('$variables{pubid}', '$curator', current_timestamp);" );
  my $result = $conn->exec( "INSERT INTO ref_cgcgenedeletion VALUES ('$variables{pubID}', '$variables{paperlocus}', '$curator', '$variables{remark}');" );
} # sub dealPg

sub preview {
  &getHtml();
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion.cgi\">\n";
  &displayVars();
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Entry !\">\n";
  print "</FORM>\n";
} # sub preview

sub getHtml {
  my $oop;
  ($oop, $variables{pubID}) = &getHtmlVar($query, 'pubID');
  ($oop, $variables{remark}) = &getHtmlVar($query, 'remark');
  ($oop, $variables{reference}) = &getHtmlVar($query, 'reference');
  ($oop, $variables{paperlocus}) = &getHtmlVar($query, 'paperlocus');
} # sub getHtml

sub displayVars {
  print "<FONT COLOR = green>Curator ID : $curator</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
  print "<FONT COLOR = green>PubID : $variables{pubID}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"pubID\" VALUE=\"$variables{pubID}\">\n";
  print "<FONT COLOR = green>Paper Gene Exclusion : $variables{paperlocus}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"paperlocus\" VALUE=\"$variables{paperlocus}\">\n";
  print "<FONT COLOR = green>Remark : $variables{remark}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"remark\" VALUE=\"$variables{remark}\">\n";
  print "Reference : $variables{reference}<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"reference\" VALUE=\"$variables{reference}\">\n";
#   print "<FONT COLOR = green>Comment : $variables{comment}</FONT><BR>\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"comment\" VALUE=\"$variables{comment}\">\n";
} # sub displayVars


sub queryPG {
  my $oop; my $thing;
  ($oop, $variables{pubID}) = &getHtmlVar($query, 'pubID');
  my $result = $conn->exec ( "SELECT * FROM ref_cgcgenedeletion WHERE ref_paper = \'$variables{pubID}\';" );
  while (my @row = $result->fetchrow) { 
    $thing .= "<TR><TD>$row[0]</TD><TD>$row[1]</TD><TD>$row[2]</TD><TD>$row[3]</TD><TD>$row[4]</TD><TD>$row[5]</TD></TR>";
  } # while (my @row = $result->fetchrow)
  if ($thing) { print "<TABLE border=1><TR><TD>Paper</TD><TD>Excluded</TD><TD>Person</TD><TD>Remark</TD><TD>Timestamp</TD></TR>$thing</TABLE>\n"; }
  else { print "There are no Loci excluded for this Paper : $variables{pubID}<BR>\n"; }
} # sub queryPG

sub resetForDisplay {
  my $oop;
  ($oop, $variables{pubID}) = &getHtmlVar($query, 'pubID');
  ($oop, $variables{reference}) = &getHtmlVar($query, 'reference');
  $variables{paperlocus} = '';
  $curator = &getCurator();
} # sub resetForDisplay


sub displayHtmlCuration {
  print <<"EndOfText";
<A NAME="form"><H1>Add your entries : </H1></A><BR>

<FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion.cgi">

<TABLE>
<TR>
<TD ALIGN="right"><STRONG>General Public ID number :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="pubID" VALUE="$variables{pubID}" SIZE=40></TD>
               <TD><INPUT TYPE="submit" NAME="action" VALUE="Query !"></TD>
	       <TD><FONT SIZE=-1>(e.g. 'cgc3' or 'WBPaper00000001')</FONT></TD></TR></TABLE></TD>
</TR>

<TR>
  <TD ALIGN="right"><STRONG>Paper Gene Exclusion :</TD>
  <TD>
    <TABLE>
      <TR>
        <TD><INPUT NAME="paperlocus" SIZE=40>$variables{paperlocus}</TEXTAREA></TD>
        <TD><FONT SIZE=-1>Please enter one gene (e.g. 'abc-1' or 'WBGene00000001') for each entry</TD>
      </TR>
    </TABLE>
  </TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>Remark :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="remark" VALUE="$variables{remark}" SIZE=40></TD></TR></TABLE></TD>
</TR>

<!--<TR>
<TD ALIGN="right"><STRONG>PDF file name :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="pdffilename" VALUE="$variables{pdffilename}" SIZE=40></TD></TR></TABLE></TD>
</TR>-->

<TR>
<TD ALIGN="right"><STRONG>Curator ID :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="curator_name" VALUE="$curator" SIZE=40></TD>
               <TD><FONT SIZE=-1>This must be a valid WBPerson####</TD>
           </TR></TABLE></TD>
</TR>


<TR>
  <TD ALIGN="right"><STRONG>Reference :</STRONG></TD>
  <TD>
    <TABLE>
      <TR>
        <TD><TEXTAREA NAME="reference" ROWS=5 COLS=40>$variables{reference}</TEXTAREA></TD>
        <TD><FONT SIZE=-1>(Title, Journal, 
             Year, Volume, Pages, Authors)</FONT></TD>
      </TR>
    </TABLE>
  </TD>
</TR>

<!--<TR>
  <TD ALIGN="right"><STRONG>Comments :</STRONG></TD>
  <TD><TABLE><TR>
    <TD><TEXTAREA NAME="comment" ROWS=2 COLS=40>$variables{comment}</TEXTAREA></TD>
  </TR></TABLE></TD>
</TR>-->

<TR><TD COLSPAN=2> </TD></TR>
<TR>
<TD> </TD>
<TD><INPUT TYPE="submit" NAME="action" VALUE="Preview !">
    <!--<INPUT TYPE="submit" NAME="action" VALUE="Save !">
    <INPUT TYPE="submit" NAME="action" VALUE="Load !">-->
    <INPUT TYPE="submit" NAME="action" VALUE="Reset !"></TD>
</TR>
</TABLE>

</FORM>
EndOfText
} # sub displayHtmlCuration

# subroutines below are copy-pasted from checkout.cgi or curation_azurebrd.cgi (pre 2002 08 01)

sub PopulateReference {         # Get the reference info from the $variables{pubID}, i.e.
                                # the joinkey.  UPDATE the checked_out table on pgsql
  my @refparams = qw(author title journal volume pages year abstract);
                                # name of reference parameters used in pgsql
  foreach $_ (@refparams) {     # for each pgsql reference data parameter
    my $result = $conn->exec( "SELECT * FROM ref_$_ WHERE joinkey = '$variables{pubID}\';" );
    $variables{reference} .= "\n$_ == ";
                                # add parameter name to reference info
    &PGQueryRowify($result);    # add reference info from pgsql to reference
                                # info variable for html
  } # foreach $_ (@refparams)
} # sub PopulateReference

sub PGQueryRowify {             # Add lines to reference info
  my $result = shift;
  my @row;
  while (@row = $result->fetchrow) {
    $variables{reference} .= "$row[1]";
  } # while (@row = $result->fetchrow) 
} # sub PGQueryRowify 



sub PrintFormOpen {		# open form link to appropriate curation_name.cgi 
				# depending on the curator
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion.cgi\">";
} # sub PrintFormOpen 

sub ShowPgQuery {		# textarea box to make pgsql queries
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="HIDDEN" NAME="curator_name" VALUE="$curator">
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
} # sub ShowPgQuery


sub PrintHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">
  
<HEAD>
<TITLE>Paper Gene Exclusion Curation</TITLE>
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
<CENTER>Documentation <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_exclusion_doc.txt"
TARGET=NEW>here</A></CENTER><P>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

