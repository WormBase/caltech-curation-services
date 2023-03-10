#!/usr/bin/perl -w

# Curate paper-locus and paper-sequence connections.


# Pick your name, choose ``Curate !''
# Enter the public ID number (e.g. cgc3)
# If you are entering data with Person_evidence attribute to someone
# else, enter their WBPerson number.
# If you'd like to see if someone's curated it, or what the Reference
# data is, click ``Query !''
# Enter data in the ``Paper Locus'' box
# Click ``Preview !''
# The relevant information is shown, the Locus connections are in green.
# If this is the first time the paper is curated, click the
# ``New Entry !'' button.
# If data has been entered  for this paper and this Person, the 
# ``Update !'' button will show, so it will overwrite old data 
# (so it's better to query before entering data to make sure your 
# data is not overwritten) 
# 
# Data is stored separetly for each Person evidence + paper ID.
# So multiple people can curate a paper with different info
# (and multiple papers can be cureated by the same person).
#
#
# Very simple form.  Choose curator, query if already entered, use only
# one PG table.  2003 07 29
#
# kim_paperlocus table in pg has joinkey (which is no longer indexed
# to make it unique because multiple entries are possible to key uniquely
# off of joinkey + kim_person [person evidence], but doesn't prevent
# someone from messing it up by entering data directly into psql), 
# data, kim_timestamp, kim_person, and kim_curator (confirmer).
# query is done off of joinkey and kim_person.  updating data checks
# both fields, inserting data could create another entry, but not
# if it has same joinkey and same kim_person.  2003 07 30
#
# Added Keith, Chao-Kung, Tamberlyn, Aniko, Darin, and John Spieth.  
# 2003 09 11
#
# Added to &dealPg(); so as not to enter brackets in joinkey.
#  if ($variables{pubID} =~ m/[\[\]]/) { $variables{pubID} =~ s/[\[\]]//g; }
# 2003 09 12
#
# Added kim_papersequence to postgres to be just like kim_paperlocus
# Populated with data copied from kim_paperlocus (minus the kim_paperlocus
# column).  Changed &findIfPgEntry(); to display in red what is in postgres
# so curators know what will be/has been overwritten.  2003 09 23
#
# Added warning and WormBase link for Paper and Sequence so no new objects
# are created by this form (non-CGC papers or Sequences).  2003 10 22
#
# Changed Sequence to CDS for Kimberly.  2004 03 12
#
# Added WBPerson1841 Eimear Kenny to list.  2004 04 06
#
# Added WBPerson1846 Daniel Lawson to list.  2005 01 11
#
# Changed Locus to Gene for Daniel and Kimberly.  2005 02 07
#
# Add a ``go back'' button after &dealPg(); in &commitData();  2005 06 10




use strict;
use CGI;
use Pg;
use LWP::Simple;
use Jex; 	# getHtmlVar, mailer

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
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi\">";
  print "<TABLE>\n";
#   print "<TR><TD ALIGN=\"right\">Entries / Page :</TD>";
#   print "<TD><INPUT NAME=\"entries_page\" SIZE=15 VALUE=\"$MaxEntries\"></TD></TR>";
#   print "<TR><TD ALIGN=\"right\">Select Paper Type : </TD><TD><SELECT NAME=\"paper_type\" SIZE=4>\n";
#   print "<OPTION>CGC</OPTION>\n";
#   print "<OPTION>PMID</OPTION>\n";
#   print "<OPTION>MED</OPTION>\n";
#   print "<OPTION>AGP</OPTION>\n";
#   print "</SELECT></TD>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=19>\n";
  print "<OPTION VALUE='WBPerson22'>Igor Antoshechkin</OPTION>\n";
  print "<OPTION VALUE='WBPerson48'>Carol Bastiani</OPTION>\n";
  print "<OPTION VALUE='WBPerson1849'>Tamberlyn Bieri</OPTION>\n";
  print "<OPTION VALUE='WBPerson1848'>Darin Blasiar</OPTION>\n";
  print "<OPTION VALUE='WBPerson1971'>Keith Bradnam</OPTION>\n";
  print "<OPTION VALUE='WBPerson1845'>Chao-Kung Chen</OPTION>\n";
  print "<OPTION VALUE='WBPerson101'>Wen Chen</OPTION>\n";
  print "<OPTION VALUE='WBPerson1841'>Eimear Kenny</OPTION>\n";
  print "<OPTION VALUE='WBPerson324'>Ranjana Kishore</OPTION>\n";
  print "<OPTION VALUE='WBPerson1846'>Daniel Lawson</OPTION>\n";
  print "<OPTION VALUE='WBPerson363'>Raymond Lee</OPTION>\n";
  print "<OPTION VALUE='WBPerson480'>Andrei Petcherski</OPTION>\n";
  print "<OPTION VALUE='WBPerson1850'>Aniko Sabo</OPTION>\n";
  print "<OPTION VALUE='WBPerson567'>Erich Schwarz</OPTION>\n";
  print "<OPTION VALUE='WBPerson615'>John Spieth</OPTION>\n";
  print "<OPTION VALUE='WBPerson625'>Paul Sternberg</OPTION>\n"; 
  print "<OPTION VALUE='WBPerson2970'>Mary Ann Tuli</OPTION>\n"; 
  print "<OPTION VALUE='WBPerson1843'>Kimberly Van Auken</OPTION>\n";
  print "<OPTION VALUE='WBPerson1823'>Juancarlos Testing</OPTION>\n";
  print "</SELECT></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curate !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub ChooseCurator


sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none'; 
  }
#   &populateHashes();		# fill hashes with xreference data

    # if new postgres command or curator chosen
  if ($action eq 'Curate !') {
    $curator = &getCurator();
    $variables{confirmed} = $curator;
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
    (my $oop, $variables{confirmed}) = &getHtmlVar($query, 'confirmed');
    &queryPG();
    if ($variables{pubID}) { &PopulateReference(); }
    &displayHtmlCuration();
  } # elsif ($action eq 'Query !')

#   elsif ($action eq 'Load !') {
#     $curator = &getCurator();
#     &loadState();
#   } # elsif ($action eq 'Load')

  elsif ( ($action eq 'Preview !') || ($action eq 'Save !') ) {
    $curator = &getCurator();
    if ($action eq 'Preview !') { &preview(); }
#     elsif ($action eq 'Save !') { &saveState(); } 
  } # elsif ( ($action eq 'Preview !') && ($action eq 'Save !') )

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
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi\">\n";
  &displayVars();
  &dealPg();
#   &mailGeneFunction();
  print "<TABLE>\n";				# add ``go back'' button  2005 06 10
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
  print "<TD>Curate another entry :</TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curate !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub commitData {

sub dealPg {
  my $found = &findIfPgEntry('curator'); 
  if ($variables{pubID} =~ m/[\[\]]/) { $variables{pubID} =~ s/[\[\]]//g; }
  if ($found) {					# do UPDATEs (Update !)
    my $result = $conn->exec( "UPDATE kim_paperlocus SET kim_paperlocus = '$variables{paperlocus}' WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
    $result = $conn->exec( "UPDATE kim_paperlocus SET kim_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
#     $result = $conn->exec( "UPDATE kim_paperlocus SET kim_person = '$curator' WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
    $result = $conn->exec( "UPDATE kim_paperlocus SET kim_curator = '$variables{confirmed}' WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
    $result = $conn->exec( "UPDATE kim_papersequence SET kim_curator = '$variables{confirmed}' WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
    $result = $conn->exec( "UPDATE kim_papersequence SET kim_papersequence = '$variables{papersequence}' WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
    $result = $conn->exec( "UPDATE kim_papersequence SET kim_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
#     $result = $conn->exec( "UPDATE cur_comment SET cur_comment = '$variables{comment}' WHERE joinkey = '$variables{pubID}';" );
  } else {					# do INSERTs (New Entry !)
#     my $result = $conn->exec( "INSERT INTO cur_curator VALUES ('$variables{pubID}', '$curator', CURRENT_TIMESTAMP);" );
    my $result = $conn->exec( "INSERT INTO kim_paperlocus VALUES ('$variables{pubID}', '$variables{paperlocus}', CURRENT_TIMESTAMP, '$curator', '$variables{confirmed}');" );
    $result = $conn->exec( "INSERT INTO kim_papersequence VALUES ('$variables{pubID}', '$variables{papersequence}', CURRENT_TIMESTAMP, '$curator', '$variables{confirmed}');" );
#     $result = $conn->exec( "INSERT INTO cur_comment VALUES ('$variables{pubID}', '$variables{comment}', CURRENT_TIMESTAMP);" );
  } # else # if ($found) 
} # sub dealPg

sub preview {
  &getHtml();
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi\">\n";
  &displayVars();
  &showButtonChoice();
  print "</FORM>\n";
} # sub preview

sub getHtml {
  my $oop;
  ($oop, $variables{pubID}) = &getHtmlVar($query, 'pubID');
#   ($oop, $variables{pdffilename}) = &getHtmlVar($query, 'pdffilename');
  ($oop, $variables{confirmed}) = &getHtmlVar($query, 'confirmed');
  ($oop, $variables{reference}) = &getHtmlVar($query, 'reference');
  ($oop, $variables{paperlocus}) = &getHtmlVar($query, 'paperlocus');
  ($oop, $variables{papersequence}) = &getHtmlVar($query, 'papersequence');
#   ($oop, $variables{genefunction1}) = &getHtmlVar($query, 'genefunction1');
#   ($oop, $variables{genefunction2}) = &getHtmlVar($query, 'genefunction2');
#   ($oop, $variables{genefunction}) = &getHtmlVar($query, 'genefunction');
#   ($oop, $variables{comment}) = &getHtmlVar($query, 'comment');
#   if ($variables{genefunction}) { $variables{genefunction} = $variables{genefunction}; }
#   elsif ($variables{genefunction2}) { $variables{genefunction} = $variables{genefunction2}; }
#   elsif ($variables{genefunctions1}) { $variables{genefunction} = 'yes'; }
#   else { $variables{genefunction} = ''; }
#   delete $variables{genefunction2}; delete $variables{genefunction1};
} # sub getHtml

sub displayVars {
  print "<FONT COLOR = green>Person Evidence : $curator</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
  print "<FONT COLOR = green>Curator Confirmed : $variables{confirmed}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"confirmed\" VALUE=\"$variables{confirmed}\">\n";
  print "PubID : $variables{pubID}<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"pubID\" VALUE=\"$variables{pubID}\">\n";
#   print "pdffilename : $variables{pdffilename}<BR>\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdffilename\" VALUE=\"$variables{pdffilename}\">\n";
  print "Reference : $variables{reference}<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"reference\" VALUE=\"$variables{reference}\">\n";
  print "<FONT COLOR = green>Paper Locus : $variables{paperlocus}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"paperlocus\" VALUE=\"$variables{paperlocus}\">\n";
  print "<FONT COLOR = green>Paper CDS : $variables{papersequence}</FONT><BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"papersequence\" VALUE=\"$variables{papersequence}\">\n";
#   print "<FONT COLOR = green>Comment : $variables{comment}</FONT><BR>\n";
#   print "<INPUT TYPE=\"HIDDEN\" NAME=\"comment\" VALUE=\"$variables{comment}\">\n";
} # sub displayVars

sub showButtonChoice {
  if ($curator eq 'error') { return; }
  my $found = &findIfPgEntry(); 
#   my $found = &findIfPgEntry('curator'); 
  if ($found) {
    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update !\">\n";
#     print "<BR><FONT color=red>You will overwrite this data : $found</FONT><BR>\n";
  } else { # if ($found)
    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Entry !\">\n";
  } # else # if ($found)
} # sub showButtonChoice

sub findIfPgEntry {     # look at postgresql by pubID (joinkey) to see if entry exists
        # use the pubID and the curator table to see if there's an entry already
#   my $cur_table = shift;                # figure out which table to check for data from
  my $cur_table = 'kim_paperlocus';
  my $result = $conn->exec( "SELECT * FROM kim_paperlocus WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
  my @row; my $found;
  while (@row = $result->fetchrow) { $found = $row[1]; if ($found eq '') { $found = ' '; } }
    # if there's null or blank data, change it to a space so it will update, not insert
  if ($found) { print "<FONT color=red>Previously entered Locus data : $found<BR></FONT>\n"; }
  $result = $conn->exec( "SELECT * FROM kim_papersequence WHERE joinkey = '$variables{pubID}' AND kim_person = '$curator';" );
  @row = (); my $found2;
  while (@row = $result->fetchrow) { $found2 = $row[1]; if ($found2 eq '') { $found2 = ' '; } }
  if ($found2) { print "<FONT color=red>Previously entered overwrite Sequence data : $found2</FONT><BR>\n"; }
  return $found;
} # sub FindIfPgEntry


sub queryPG {
  my $oop;
  ($oop, $variables{pubID}) = &getHtmlVar($query, 'pubID');
#   ($oop, $variables{pdffilename}) = &getHtmlVar($query, 'pdffilename');
  ($oop, $variables{reference}) = &getHtmlVar($query, 'reference');
  my $result = $conn->exec ( "SELECT * FROM kim_paperlocus WHERE joinkey = \'$variables{pubID}\' AND kim_person = '$curator';" );
  my @row = $result->fetchrow;
  $variables{paperlocus} = $row[1];
#   $result = $conn->exec ( "SELECT * FROM cur_comment WHERE joinkey = \'$variables{pubID}\';" );
#   @row = $result->fetchrow;
#   $variables{comment} = $row[1];
} # sub queryPG

sub resetForDisplay {
  my $oop;
  ($oop, $variables{pubID}) = &getHtmlVar($query, 'pubID');
#   ($oop, $variables{pdffilename}) = &getHtmlVar($query, 'pdffilename');
  ($oop, $variables{reference}) = &getHtmlVar($query, 'reference');
  $variables{paperlocus} = '';
#   $variables{genefunction1} = '';
#   $variables{genefunction2} = '';
#   $variables{genefunction} = '';
#   $variables{comment} = '';
  $curator = &getCurator();
} # sub resetForDisplay


sub displayHtmlCuration {
  unless ($variables{pubID}) { $variables{pubID} = ''; }
  unless ($variables{pdffilename}) { $variables{pdffilename} = ''; }
  unless ($variables{confirmed}) { $variables{confirmed} = ''; }
  unless ($variables{reference}) { $variables{reference} = ''; }
  unless ($variables{paperlocus}) { $variables{paperlocus} = ''; }
  unless ($variables{papersequence}) { $variables{papersequence} = ''; }
  unless ($variables{comment}) { $variables{comment} = ''; }
  print <<"EndOfText";
<A NAME="form"><H1>Add your entries : </H1></A><BR>

<FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi">

<TABLE>
<TR>
<TD ALIGN="right"><STRONG>General Public ID number :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="pubID" VALUE="$variables{pubID}" SIZE=40></TD>
               <TD><INPUT TYPE="submit" NAME="action" VALUE="Query !"></TD>
	       <TD><FONT SIZE=-1>(e.g. 'cgc3' or 'WBPaper0000001')<BR><FONT COLOR="red">ALWAYS QUERY FIRST</FONT><BR>Make sure that if you enter a non-CGC paper,<BR>
		   that you have checked it exists in 
		   <A HREF="http://www.wormbase.org/db/misc/paper?name=;class=Paper">WormBase</A>,<BR>
		   or you will create a blank Paper Object</FONT></TD></TR></TABLE></TD>
</TR>

<!--<TR>
<TD ALIGN="right"><STRONG>PDF file name :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="pdffilename" VALUE="$variables{pdffilename}" SIZE=40></TD></TR></TABLE></TD>
</TR>-->

<TR>
<TD ALIGN="right"><STRONG>Person Evidence :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="curator_name" VALUE="$curator" SIZE=40></TD>
               <TD><FONT SIZE=-1>This must be a valid WBPerson####</TD>
           </TR></TABLE></TD>
</TR>

<TR>
<TD ALIGN="right"><STRONG>Curator Confirmed :</STRONG></TD>
<TD><TABLE><TR><TD><INPUT NAME="confirmed" VALUE="$variables{confirmed}" SIZE=40></TD>
               <TD><FONT SIZE=-1>This is always your WBPerson####</TD>
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
<TR>
  <TD ALIGN="right"><STRONG>Paper Gene :</TD>
  <TD>
    <TABLE>
      <TR>
        <TD><TEXTAREA NAME="paperlocus" ROWS=40 COLS=40>$variables{paperlocus}</TEXTAREA></TD>
        <TD><FONT SIZE=-1>Please enter each gene in its own line. e.g. :<BR>abc-1<BR>pie-1<BR>WBGene0000001<BR>etc.<BR><BR>The form will convert to WBGene entries.</TD>
        <!--<TD> <FONT SIZE=-1>Mail emsch\@its.caltech.edu, <BR>ranjana\@eysturoy.caltech.edu</FONT></TD>-->
      </TR>
    </TABLE>
  </TD>
</TR>
<TR>
  <TD ALIGN="right"><STRONG>Paper CDS :</TD>
  <TD>
    <TABLE>
      <TR>
        <TD><TEXTAREA NAME="papersequence" ROWS=10 COLS=40>$variables{papersequence}</TEXTAREA></TD>
        <TD><FONT SIZE=-1>Please enter each sequence in its own line. e.g. :<BR>2L52<BR>BM355725<BR>etc.<BR>
	     Please make sure that if you enter a Sequence, <BR> that you have checked it exists in
	     <A HREF="http://www.wormbase.org/db/seq/sequence?name=;class=Sequence">WormBase</A>,<BR>
	     or you will create a blank Sequence Object.
        </TD>
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
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi\">";
} # sub PrintFormOpen 

sub ShowPgQuery {		# textarea box to make pgsql queries
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi">
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
<TITLE>Paper Locus Curation</TITLE>
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
<CENTER>Documentation <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus_doc.txt"
TARGET=NEW>here</A><BR>Submit data before 1pm on the Wednesday before uploads<BR>(subject to change
depending on who builds citace)</CENTER><P>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 


### OLD STUFF ###
#
# sub showSearch {		# look for a specific number
#   print <<"EndOfText";
#   <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/paper_gene.cgi">
#   <TABLE><TR>
#   <TD>Search for a specific number :</TD>
#   <TD><INPUT NAME="search_type" TYPE="radio" VALUE="sub" CHECKED>Wild Card<BR>
#   <INPUT NAME="search_type" TYPE="radio" VALUE="exact">Exact</TD>
#   <TD><INPUT NAME="paper_type" TYPE="radio" VALUE="CGC" CHECKED>CGC<BR>
#   <INPUT NAME="paper_type" TYPE="radio" VALUE="PMID">PMID<BR>
#   <INPUT NAME="paper_type" TYPE="radio" VALUE="MED">MED<BR>
#   <INPUT NAME="paper_type" TYPE="radio" VALUE="AGP">AGP</TD>
#   <TD><INPUT NAME="paper_number" SIZE=40></TD>
#   <INPUT TYPE="HIDDEN" NAME="curator_name" VALUE="$curator">
#   <TD><INPUT TYPE="submit" NAME="action" VALUE="Search !"></TD>
#   </TR></TABLE>
#   </FORM>
# EndOfText
# } # sub showSearch

# sub getAthenaPdfs {			# populate array of athena pdfs
#     # use LWP::Simple to get the list of PDFs from Athena
#   my $page = get "http://athena.caltech.edu/~daniel/tif_pdf/";
#   @pdfathena = $page =~ m/HREF="(.*?tif\.pdf)"/g;	# get list of athena pdfs
# } # sub getAthenaPdfs


# sub ProcessTable {
# 	# Take in pgcommand from hidden field or from Pg ! button
# 	# Take in page number from Page ! button or 1 as default
# 	# Process sql query 
# 	# Output number of results as well as sql query
# 	# output page selector as well as selected page results
#     my $page = shift; my $pgcommand = shift;
#     my $result = $conn->exec( "$pgcommand" ); 
#     my @row;
#     @RowOfRow = ();
#     while (@row = $result->fetchrow) {	# loop through all rows returned
#       push @RowOfRow, [@row];
#     } # while (@row = $result->fetchrow) 
# 
#       # identity display
#     if ($curator) { print "You claim to be $curator<P>\n"; }
# 
#       # show amount of results and compute page things
#     print "There are " . ($#RowOfRow+1) . " results to \"$pgcommand\".<BR>\n";
#     my $remainder = $#RowOfRow % $MaxEntries;
#     my $HighNumber = $#RowOfRow - $remainder;
#     my $dividednumber = $HighNumber / $MaxEntries;
# 
#     &showSearch();
# 
#       # process with this form, select new page, pass hidden values.
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus.cgi\">";
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
#                                 # pass curator_name value in hidden field
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"entries_page\" VALUE=\"$MaxEntries\">\n";
#                                 # pass entries_page value in hidden field
#     print "<TABLE>\n";
#     print "<TD>Select your page of " . ($dividednumber + 1) . " : </TD><TD><SELECT NAME=\"page\" SIZE=5> \n"; 
#     for my $k ( 1 .. ($dividednumber + 1) ) {
#       print "<OPTION>$k</OPTION>\n";
#     } # for my $k ( 0 .. $dividednumber ) 
#     print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Page !\"></TD><BR><BR>\n";
#     $pgcommand =~ s/>/&gt;/g;	# turn to code for html not to complain
#     $pgcommand =~ s/</&lt;/g;	# turn to code for html not to complain
#     print "<INPUT TYPE=\"HIDDEN\" NAME=\"pgcommand\" VALUE=\"$pgcommand\">\n";
# 				# pass pgcommand value in hidden field
#     $pgcommand =~ s/&gt;/>/g;	# turn back for pg not to complain
#     $pgcommand =~ s/&lt;/</g;	# turn back for pg not to complain
#     print "</TABLE>\n";
#     print "</FORM>\n";
#     print "<CENTER>\n";
#     print "PAGE : $page<BR>\n";
# 
#       # show reference table
#     print "<TABLE border=1 cellspacing=5>\n";
#     if ($pgcommand =~ $test_pgcommand) { print "<TR><TD ALIGN=CENTER>joinkey</TD><TD ALIGN=CENTER>hardcopy</TD><TD ALIGN=CENTER>pdf</TD><TD ALIGN=CENTER>html</TD><TD ALIGN=CENTER>tif</TD><TD ALIGN=CENTER>lib_pdf</TD><TD ALIGN=CENTER>checked_out</TD><TD ALIGN=CENTER>alternate</TD><TD ALIGN=CENTER>alt out</TD><TD ALIGN=CENTER>last curated</TD><TD ALIGN=CENTER>curate</TD></TR>\n"; }
# 				# show headers if default
#     for my $i ( (($page-1)*$MaxEntries) .. (($page*$MaxEntries)-1) ) {
# 				# for the amount of entries chosen in the chosen page
#       my $row = $RowOfRow[$i];
#       if ($row->[0]) {		# if there's an entry
#         print "<TR>";
#         &PrintFormOpen();	# print selector for curation_name.cgi form
#         my $cgc = my $key = $row->[0];	# get cgc for pdf, key for cgc/pmid
# 
#         print "<INPUT TYPE=\"HIDDEN\" NAME=\"cgc_number\" VALUE=\"$cgc\">\n";
# 				# pass cgc (joinkey) as hidden to html
#         if ($cgc =~ m/^cgc/) { $cgc =~ s/cgc//;	}	# get cgc number
#         if ($cgc =~ m/^pmid/) { $cgc =~ s/pmid//; }	# get pmid number
#         for my $j ( 0 .. $#{$row} ) {
#           unless ( ($row->[$j]) || ($j == 2) ) { 	
# 				# if nothing there, print a space
# 				# unless it's a pdf, in which case need to check
# 				# if pdf exists
#             print "<TD>&nbsp;</TD>\n"; 
#           } else { 		# if something there
#             unless ( ($pgcommand =~ $test_pgcommand) && ($j == 2) ) { 
# 				# unless it's a pdf
#               print "<TD ALIGN=CENTER>$row->[$j]</TD>\n"; 
#             } else {		# if it's a pdf, print a link
#               my $pdfexists = 0;
#               print "<TD>";	# open table down dealing with pdfs
#               foreach my $pdffile (@pdffiles) {		# deal with local /home3/allpdfs/ pdfs
# 				# find the pdf that matches the joinkey 
#                 $pdffile =~ m/^\/home3\/allpdfs\/((\d+).*)$/;      
# 				# get the pdf filename
#                 if ($2 eq $cgc) {	
# 				# exact number matches only
# 				# if the pdf matches the cgc 
#                   print "<A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A><BR>\n";	# print the link
#                   print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$1\">\n";
#                   $pdfexists = 1;	# pass pdf value in hidden field
#                 } # if ($pdffile =~ m/^$cgc\w+/) 
#                 if ($otherHash{$cgc}) {
#                   if ($2 eq $otherHash{$cgc}) {	
# 				# exact number matches only
# 				# if the pdf matches the xref pmid
#                     print "<A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A><BR>\n";	# print the link
#                     print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$1\">\n";
#                     $pdfexists = 1;	# pass pdf value in hidden field
#                   } # if ($2 eq $otherHash{$cgc}) 
#                 } # if ($pdffile =~ m/^$cgc\w+/) 
# 
#               } # foreach my $pdffile (@pdffiles) 
#               unless ($pdfexists) {		# if not found, look under athena
#                 foreach my $pdfath (@pdfathena) {		# deal with athena pdfs
#                   $pdfath =~ m/(\d+).*/;
#                   if ($1 eq $cgc) { 
#                     print "<A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/$pdfath\">$pdfath</A><BR>\n";	# print the link
#                     print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$pdfath\">\n";
#                     $pdfexists = 1;
#                   } # if ($1 eq $cgc) 
#                 } # foreach my $pdfath (@pdfathena)
#               } # unless ($pdfexists)
#               unless ($pdfexists) { print "&nbsp;\n"; } 
#               print "</TD>\n";	# close table down dealing with pdfs
#             } # else # unless ( ($pgcommand =~ $test_pgcommand) && ($j == 2) ) 
#           } # else # unless ($row->[$j]) 
#         } # for my $j ( 0 .. $#{$row} ) 
# 
#           # check ref_xref for cgc if pmid, or pmid if cgc
#         print "<TD ALIGN=CENTER>";
#         if ($key =~ m/^cgc/) { if ($cgcHash{$key}) { print "$cgcHash{$key}"; } }
#         elsif ($key =~ m/^pmid/) { if ($pmHash{$key}) { print "$pmHash{$key}"; } }
#         else { print "<FONT COLOR=blue>ERROR : paper type unknown</FONT>"; }
#         print "</TD><TD ALIGN=CENTER>";
#         if ($key =~ m/^cgc/) { if ($cgcHash{$key}) { if ($checkedoutHash{$cgcHash{$key}}) { print "$checkedoutHash{$cgcHash{$key}}"; } else { 1; } } }
#         if ($key =~ m/^pmid/) { if ($pmHash{$key}) { if ($checkedoutHash{$pmHash{$key}}) { print "$checkedoutHash{$pmHash{$key}}"; } else { 1; } } }
#         print "</TD><TD ALIGN=CENTER>";
#           # check if curated and print if so
#         if ($curatedbyHash{$key}) { print "$curatedbyHash{$key}"; } 
#         else { 
#           if ($key =~ m/^cgc/) { if ($cgcHash{$key}) { if ($curatedbyHash{$cgcHash{$key}}) { print "$curatedbyHash{$cgcHash{$key}}"; } else { 1; } } }
#           if ($key =~ m/^pmid/) { if ($pmHash{$key}) { if ($curatedbyHash{$pmHash{$key}}) { print "$curatedbyHash{$pmHash{$key}}"; } else { 1; } } }
#         } # if ($curatedbyHash{$key}) 
#         print "</TD>";
# 
#         print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curate !\"></TD>\n";
# 				# show button to ``Curate !''
#         print "</FORM>\n";	# close each form
#         print "</TR>\n";	# new table row
#       } # if ($row->[0]) 	# if there's an entry
#     } # for my $i ( 0 .. $#RowOfRow ) 
#     if ($pgcommand =~ $test_pgcommand) { print "<TR><TD ALIGN=CENTER>joinkey</TD><TD ALIGN=CENTER>hardcopy</TD><TD ALIGN=CENTER>pdf</TD><TD ALIGN=CENTER>html</TD><TD ALIGN=CENTER>tif</TD><TD ALIGN=CENTER>lib_pdf</TD><TD ALIGN=CENTER>checked_out</TD><TD ALIGN=CENTER>alternate</TD><TD ALIGN=CENTER>alt out</TD><TD ALIGN=CENTER>last curated</TD><TD ALIGN=CENTER>curate</TD></TR>\n"; }
# 				# show headers if default
#     print "</TABLE>\n";		# close table
#     print "PAGE : $page<BR>\n";	# show page number again
#     print "</CENTER>\n";
# } # sub ProcessTable 
#
# sub mailGeneFunction {
#   my $user = 'paper_locusonly';
# #   my $email = 'azurebrd@tazendra.caltech.edu, bounce@tazendra.caltech.edu';
#   my $email = 'ranjana@eysturoy.caltech.edu, emsch@its.caltech.edu';
#   my $subject = 'gene function only curation';
#   my $body = '';
#   $body .= "Curator : $curator\n";
#   $body .= "PubID : $variables{pubID}\n";
#   $body .= "pdffilename : $variables{pdffilename}\n";
#   $body .= "Reference : $variables{reference}\n\n";
#   $body .= "Gene Function : $variables{paper_locus}\n";
#   $body .= "Comment : $variables{comment}\n";
#   &mailer($user, $email, $subject, $body);
# } # sub mailGeneFunction


# sub populateHashes {
#     # check xreferences
#   my $result = $conn->exec( "SELECT * FROM ref_xref;" ); 
#   my @row;
#   while (@row = $result->fetchrow) {	# loop through all rows returned
#     $cgcHash{$row[0]} = $row[1];
#     $pmHash{$row[1]} = $row[0];
#     $row[0] =~ s/cgc//;
#     $row[1] =~ s/pmid//;
#     $otherHash{$row[0]} = $row[1];
#     $otherHash{$row[1]} = $row[0];
#   } # while (my @row = $result->fetchrow) 
#   $result = $conn->exec ( "SELECT * FROM ref_checked_out;" );
#   while (@row = $result->fetchrow) {
#     $checkedoutHash{$row[0]} = $row[1];
#   } # while (@row = $result->fetchrow)
#     # check if curated
#   $result = $conn->exec ( "SELECT * FROM cur_curator;" );
#   while (@row = $result->fetchrow) {
#     $curatedbyHash{$row[0]} = $row[1];
#   } # while (@row = $result->fetchrow)
# } # sub populateHashes

# sub loadState {
# #   &getHtml();
# #   &displayVars();
#   &loadFromFile();
#   &displayHtmlCuration();
# } # sub loadState
# 
# sub saveState {
#   &getHtml();
#   &displayVars();
#   &saveToFile();
# } # sub saveState

# sub Untaint {
#   my $tainted = shift;
#   my $untainted;
#   $tainted =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*(){}[\]+=!~|' \t\n\r\f]//g;
#   if ($tainted =~ m/^([\w\-.,;:?\/\\@#\$\%&\^*(){}[\]+=!~|' \t\n\r\f]+)$/) {
#     $untainted = $1;
#   } else {
#     die "Bad data in $tainted";
#   }
#   return $untainted;
# } # sub Untaint 

# sub CuratePopulate {
#   my $oop;
#   if ( $query->param('pdf_name') ) { 		# from allpdfs.cgi or checkout.cgi
#     $oop = $query->param('pdf_name');
#     $variables{pdffilename} = &untaint($oop);	# assign pdffilename
#     $variables{pdffilename} =~ m/^(\d+)_/;	# get cgc number
#     $variables{pubID} = "cgc" . $1;		# make number, i.e. pgsql joinkey
#     if ( $query->param('cgc_number') ) {	# check for number regardless in case it's a pmid
#       $oop = $query->param('cgc_number');
#       $variables{pubID} = &untaint($oop);
#     } # if ( $query->param('cgc_number') )
#     &PopulateReference();
#     my $result = $conn->exec( "UPDATE ref_checked_out SET ref_checked_out = \'$curator\' WHERE joinkey = \'$variables{pubID}\';" );
#     $result = $conn->exec( "UPDATE ref_checked_out SET ref_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$variables{pubID}\';" );
#   } elsif ( $query->param('cgc_number') ) { # if ( $query->param('pdf_name') )
#                                 		# from checkout.cgi
#     $oop = $query->param('cgc_number');
#     $variables{pubID} = &untaint($oop);		# assign pubID
#     &PopulateReference();
#     my $result = $conn->exec( "UPDATE ref_checked_out SET ref_checked_out = \'$variables{curator}\' WHERE joinkey = \'$variables{pubID}\';" );
#   } else { $oop = "nodatahere"; }		# if there's no pdf name, nothing.
# } # sub CuratePopulate

# sub saveToFile {
#   foreach my $val (sort keys %variables) {
#     $variables{$val} =~ s/\t/TABREPLACEMENT/g;
#   } # foreach my $val (sort keys %variables)
#   my $vals_to_save = $variables{pubID} . "\t" . $variables{pdffilename} . "\t" .
# $variables{reference} . "\t" . $variables{genefunction} . "\t" . $variables{comment};
#   open (SAVE, ">$save_file") or die "cannot create $save_file : $!";
#     # Saving, not as file, but as list
#   print SAVE "$vals_to_save\n";
#   close SAVE or die "Cannot close $save_file : $!";
# } # sub saveToFile
# 
# sub loadFromFile {
#   undef $/;
#   open (SAVE, "<$save_file") or die "cannot open $save_file : $!";
#   my $vals_to_save = <SAVE>;
#   close SAVE or die "Cannot close $save_file : $!";
#   $/ = "\n";
#   my @vals_to_save = split/\t/, $vals_to_save;
#   foreach (@vals_to_save) { $_ =~ s/TABREPLACEMENT/\t/g; }
#   $variables{pubID} = $vals_to_save[0];
#   $variables{pdffilename} = $vals_to_save[1];
#   $variables{reference} = $vals_to_save[2];
#   $variables{genefunction2} = $vals_to_save[3];
#   $variables{comment} = $vals_to_save[4];
# } # sub loadFromFile

# Sample query (find most recent cgcs with pdfs)
# SELECT pdf.joinkey, pdf.pdf FROM pdf, cgc WHERE cgc.joinkey = pdf.joinkey AND
# pdf.pdf = '1' ORDER BY cgc.cgc DESC;

# This CGI http://tazendra.caltech.edu/~postgres/cgi-bin/paper_locus.cgi
# 
# A link to this page is displayed.
# 
# Choose your name, and how many entries you'd like on each html page.
# Click the ``Paper !'' button.
# 
# A link to this page is displayed.
# Your identity is displayed.
# The amount of entries as well as the default postgres command that 
# properly displays the table are shown.
# There is a number of pages display, and a page number selector with
# ``Page !'' button.
# The page you are on is displayed.
# 
# A table contains : 
# The ID, which is also the postgreSQL joinkey.
# Whether there is a hardcopy or not (if you don't like the ones, tell
# me what you'd like instead)
# A link to the pdf if it's available.
# Whether there's an html copy.
# Whether there's a tif copy.
# Whether there's a pdf copy which came from the library and is thus
# now convertible (lib).
# To whom the File is checked out. 
# A ``Curate !'' button, which refers to the curation_user.cgi and
# populates the General (Reference) Info based on the first row of the
# html table (joinkey), as well as Checking out the paper to the curator
# identity, which can be seen if the paper_locus.cgi is refreshed.
# 
# For additional queries, a textarea box allows direct SELECT querying
# of the postgreSQL database, but headers are not shown, and the
# ``Curate !'' button keys off of the first table, so you would need a
# query to show the joinkey first, so the button knows how to process
# the text.  (That is, something that begins with ``SELECT
# name_of_table.joinkey, ...'' You generally don't need this, but if you
# want to use SQL commands this is better than nothing for now)
#
# &Process()  At first, no $action, so nothing.
# &Display()  At first !$curator, &ChooseCurator choose identity and entries / page
# ``Paper !''  &Process()  get curator_name and pgcommand.  untaint with subs
# for &lt; &gt; < >.  At first no command, so makes $pgcommand =  $default_command, 
# which is the only thing that will prompt table headers as well as PDF links.
# &ProcessTable() execute $pgcommand query, set FORM to this cgi, pass hidden
# curator_name and entries_page; show page selector, do the &lt; &gt; < > thing
# for hidden pgcommand.  For default query, show table headers as well as link
# to PDF.  Show ``Curate !'' link, which only works if first table row is the
# joinkey. If not first time, &ShowPgQuery()
# &ShowPgQuery()  Show textarea for command.  Pass hidden curator name.  ``Pg !''
# ``Pg !''  &Process() as ``Paper !'' but with different $pgcommand, i.e. no
# table headers nor link to PDF.
# ``Page !''   &Process() as ``Paper !'' but with a different page.
#
# $pdfexists added for tables looking okay for pdf entry -- 2001 11 28
#
# force check of existance of pdfs, not only if in postgresql database 2001 12 14
#
# pdf exact number matches only, not partial number matches.  updated to select
# from the new tables (ref_ instead of the old ref_ less tables)  2002 01 29
#
# Fixed display on last page that would show 20 entries regardless of how many
# entries there actually were (showing blank entries)  2002 02 02
#
# &ChooseCurator(); added paper type selection.  &ProcessTable(); checks for =~
# $test_pgcommand instead of eq $default_pgcommand for html table lables.  added 
# $cgc_pgcommand, $pmid_pgcommand, $med_pgcommand, $agp_pgcommand, $test_pgcommand
# ($cgc_pgcommand is redundant $default_pgcommand).  &Process(); updated to get 
# the paper_type from the HTML and make the appropriate $pgcommand change.  
# 2002 02 12
#
# Updated to show the cur_curated table to show if something has been curated
# 2002 04 17
#
# Updated &ProcessTable(); to check the populated xref hashes %cgcHash and %pmHash
# for possible alternate curated papers.  2002 05 03
#
# Created &getAthenaPdfs() and @pdfathena to be a list of tif.pdf files from the symlinked
# files on athena by daniel.  Altered &ProcessTable(); to deal with the additional athena
# pdfs.  2002 05 15
#
# Created &showSearch(); to show a table to choose a specific paper number, paper type,
# and search type (exact or sub).  Added it to &ProcessTable();.  Altered &Process(); 
# for the ``Search !'' option, which reads in the values, and subs into the $pgcommand
# the additional AND condition for the paper kind / number.  2002 05 15
#
# Added %otherHash to store just numbers for cgc-pmid xref for checking if a pdf
# exists for display  2002 06 18
#
# Changed lib field to new lib_pdf field.  Fixed pdfs to show in same html table 
# cell.  2002 07 16
#
# Added ``Save !'' and ``Load !'' features  2002 08 05
