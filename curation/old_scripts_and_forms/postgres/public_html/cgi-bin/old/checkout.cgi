#!/usr/bin/perl -w

# Checkout papers to curate.  Table with hard/electronic copy status.

# Sample query (find most recent cgcs with pdfs)
# SELECT pdf.joinkey, pdf.pdf FROM pdf, cgc WHERE cgc.joinkey = pdf.joinkey AND
# pdf.pdf = '1' ORDER BY cgc.cgc DESC;

# This CGI http://tazendra.caltech.edu/~postgres/cgi-bin/checkout.cgi
# 
# A link to this page is displayed.
# 
# Choose your name, and how many entries you'd like on each html page.
# Click the ``Curator !'' button.
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
# identity, which can be seen if the checkout.cgi is refreshed.
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
# ``Curator !''  &Process()  get curator_name and pgcommand.  untaint with subs
# for &lt; &gt; < >.  At first no command, so makes $pgcommand =  $default_command, 
# which is the only thing that will prompt table headers as well as PDF links.
# &ProcessTable() execute $pgcommand query, set FORM to this cgi, pass hidden
# curator_name and entries_page; show page selector, do the &lt; &gt; < > thing
# for hidden pgcommand.  For default query, show table headers as well as link
# to PDF.  Show ``Curate !'' link, which only works if first table row is the
# joinkey. If not first time, &ShowPgQuery()
# &ShowPgQuery()  Show textarea for command.  Pass hidden curator name.  ``Pg !''
# ``Pg !''  &Process() as ``Curator !'' but with different $pgcommand, i.e. no
# table headers nor link to PDF.
# ``Page !''   &Process() as ``Curator !'' but with a different page.
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
# Daniel wanted pfds in Athena to always be looked for, commented out the 
# unless ($pdfexists).  2002 12 17
#
# Put pdfs in /home/acedb/public_html/daniel/  2004 11 17
#
# Commented out &getAthenaPdfs(); since Athena died until Nestor is up.
# 2004 12 20


use strict;
use CGI;
use Fcntl;
# use HTML::Template;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use LWP::Simple;

my $query = new CGI;
our @RowOfRow;
my $MaxEntries = 20;

our %pmHash;
our %cgcHash;
our %otherHash;
our %checkedoutHash;
our %curatedbyHash;

our $pgcommand;			# global query
our $default_pgcommand = "SELECT ref_pdf.joinkey, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_lib_pdf.ref_lib_pdf, ref_checked_out.ref_checked_out FROM ref_cgc, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_lib_pdf, ref_checked_out WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_checked_out.joinkey = ref_cgc.joinkey ORDER BY ref_cgc DESC;";
				# default query
our $cgc_pgcommand = "SELECT ref_pdf.joinkey, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_lib_pdf.ref_lib_pdf, ref_checked_out.ref_checked_out FROM ref_cgc, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_lib_pdf, ref_checked_out WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_checked_out.joinkey = ref_cgc.joinkey ORDER BY ref_cgc DESC;";
				# cgc query
our $pmid_pgcommand = "SELECT ref_pdf.joinkey, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_lib_pdf.ref_lib_pdf, ref_checked_out.ref_checked_out FROM ref_pmid, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_lib_pdf, ref_checked_out WHERE ref_pmid.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_pmid.joinkey AND ref_html.joinkey = ref_pmid.joinkey AND ref_tif.joinkey = ref_pmid.joinkey AND ref_lib_pdf.joinkey = ref_pmid.joinkey AND ref_checked_out.joinkey = ref_pmid.joinkey ORDER BY ref_pmid DESC;";
				# pmid query
our $med_pgcommand = "SELECT ref_pdf.joinkey, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_lib_pdf.ref_lib_pdf, ref_checked_out.ref_checked_out FROM ref_med, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_lib_pdf, ref_checked_out WHERE ref_med.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_med.joinkey AND ref_html.joinkey = ref_med.joinkey AND ref_tif.joinkey = ref_med.joinkey AND ref_lib_pdf.joinkey = ref_med.joinkey AND ref_checked_out.joinkey = ref_med.joinkey ORDER BY ref_med DESC;";
				# med query
our $agp_pgcommand = "SELECT ref_pdf.joinkey, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_lib_pdf.ref_lib_pdf, ref_checked_out.ref_checked_out FROM ref_agp, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_lib_pdf, ref_checked_out WHERE ref_agp.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_agp.joinkey AND ref_html.joinkey = ref_agp.joinkey AND ref_tif.joinkey = ref_agp.joinkey AND ref_lib_pdf.joinkey = ref_agp.joinkey AND ref_checked_out.joinkey = ref_agp.joinkey ORDER BY ref_agp DESC;";
				# agp query
our $test_pgcommand = "SELECT ref_pdf.joinkey, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_lib_pdf.ref_lib_pdf, ref_checked_out.ref_checked_out";
				# test query
$pgcommand = $default_pgcommand;
our @pdffiles;			# make list of pdfs
# push @pdffiles, </home3/allpdfs/*.pdf>;		# get list of pdfs
push @pdffiles, </home/acedb/public_html/daniel/*.pdf>;		# get list of pdfs
our @pdfathena;			# make list of athena pdfs
# &getAthenaPdfs();		# get list of athena pdfs, populate @pdfathena

my $curator = "";		# initialize curator


  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

  # not in use with HTML::Template
# my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

&PrintHeader();			# print the HTML header
&Process();			# Do pretty much everything
&Display(); 			# Select whether to show selectors for curator name
				# entries / page, and &ShowPgQuery();
#    &PrintPgTable();
&PrintFooter();			# print the HTML footer

sub Display {
  if ( !($curator) ) { &ChooseCurator(); }
				# if no curator (first loaded), show selectors
  else { &ShowPgQuery(); }	# if not, offer option to do Pg query instead
} # sub Display

sub ChooseCurator {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/checkout.cgi\">";
  print "<TABLE>\n";
  print "<TR><TD ALIGN=\"right\">Entries / Page :</TD>";
  print "<TD><INPUT NAME=\"entries_page\" SIZE=15 VALUE=\"$MaxEntries\"></TD></TR>";
  print "<TR><TD ALIGN=\"right\">Select Paper Type : </TD><TD><SELECT NAME=\"paper_type\" SIZE=4>\n";
  print "<OPTION>CGC</OPTION>\n";
  print "<OPTION>PMID</OPTION>\n";
  print "<OPTION>MED</OPTION>\n";
  print "<OPTION>AGP</OPTION>\n";
  print "</SELECT></TD></TR><BR><BR>\n";
  print "<TR><TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=9>\n";
  print "<OPTION>Igor Antoshechkin</OPTION>\n";
  print "<OPTION>Carol Bastiani</OPTION>\n";
  print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Ranjana Kishore</OPTION>\n";
  print "<OPTION>Raymond Lee</OPTION>\n";
  print "<OPTION>Andrei Petcherski</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
  print "<OPTION>Kimberly Van Auken</OPTION>\n";
#   print "<OPTION>Andrei Testing</OPTION>\n";
  print "<OPTION>Juancarlos Testing</OPTION>\n";
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD></TR><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub ChooseCurator


sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none'; 
  }
  &populateHashes();		# fill hashes with xreference data

    # if new postgres command or curator chosen
  if ( ($action eq 'Pg !') || ($action eq 'Curator !') || ($action eq 'Search !') ) { 
    my $oop;
      # get $curator 
    if ( $query->param("curator_name") ) { $oop = $query->param("curator_name"); }
    else { $oop = "nodatahere"; }
    $curator = &Untaint($oop);
      # get $pgcommand
    my $pgcommand;
    if ($action eq 'Curator !') { $pgcommand = $default_pgcommand; }
    if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
    else { $oop = "nodatahere"; }
    $oop =~ s/>/&gt;/g;		# make into code to make through taint check
    $oop =~ s/</&lt;/g;		# make into code to make through taint check
    $pgcommand = &Untaint($oop);
    $pgcommand =~ s/&gt;/>/g;	# put back into pg readable
    $pgcommand =~ s/&lt;/</g;	# put back into pg readable
    if ( $query->param("paper_type") ) { $oop = $query->param("paper_type"); }
    else { $oop = "nodatahere"; }
    my $paper_type = &Untaint($oop);
    if ($paper_type eq 'CGC') { $pgcommand = $cgc_pgcommand; }
    elsif ($paper_type eq 'PMID') { $pgcommand = $pmid_pgcommand; }
    elsif ($paper_type eq 'MED') { $pgcommand = $med_pgcommand; }
    elsif ($paper_type eq 'AGP') { $pgcommand = $agp_pgcommand; }
    elsif ($paper_type eq 'nodatahere') { } 
    else { print "<FONT COLOR=blue>ERROR : invalid paper type in subroutine Process</FONT><BR>\n"; }
      # get $MaxEntries
    if ( $query->param("entries_page") ) { $oop = $query->param("entries_page"); }
    else { $oop = "20"; }
    $MaxEntries = &Untaint($oop);
      # get $page number
    if ( $query->param("page") ) { $oop = $query->param("page"); }
    else { $oop = "1"; }
    my $page = &Untaint($oop);
      # if page just loaded, and just signed on, use default with good tables
      # and PDF links.

    if ($action eq 'Search !') {
         # add into the pgcommand an additional AND to specify the joinkey
       if ($query->param("paper_number")) { $oop = $query->param("paper_number"); }
         else { $oop = 1; print "<FONT COLOR=blue>ERROR : no paper number chosen</FONT>"; }
       my $search_value = "'" . lc($paper_type) . &Untaint($oop) . "'";
       if ($query->param("search_type")) { $oop = $query->param("search_type"); }
         else { $oop = 'exact'; }
       my $search_type = &Untaint($oop);
       if ($search_type eq 'exact') { $search_value = 'AND ref_pdf.joinkey = ' . $search_value; }
       elsif ($search_type eq 'sub') { $search_value = 'AND ref_pdf.joinkey ~ ' . $search_value; }
       else { $oop = 1; print "<FONT COLOR=blue>ERROR : no search type chosen</FONT>"; }
       $pgcommand =~ s/ORDER/$search_value ORDER/g;
    } # if ($action eq 'Search !')

    if ($pgcommand eq "nodatahere") { 
      				# if invalid postgres command
      print "You must enter a valid PG command<BR>\n"; 
    } else { # if ($pgcommand eq "nodatahere") 
				# if valid command
      my $result = $conn->exec( "$pgcommand" ); 
				# make query, put in $result
      if ( $pgcommand !~ m/select/i ) {
				# if not a select, just show query box again
        print "PostgreSQL has processed it.<BR>\n";
        &ShowPgQuery();
      } else { # if ( $pgcommand !~ m/select/i ) 
				# if a select, process and display
#         &PrintTableLabels();
        &ProcessTable($page, $pgcommand);
      } # else # if ( $pgcommand !~ m/select/i ) 
    } # else # if ($pgcommand eq "nodatahere") 
  } # if ($action eq 'Pg !') 

    # this could be made part of above, if so chosen.
  if ($action eq 'Page !') {
    my $oop;
    if ( $query->param("curator_name") ) { $oop = $query->param("curator_name"); }
    else { $oop = "nodatahere"; }
    $curator = &Untaint($oop);
    if ( $query->param("entries_page") ) { $oop = $query->param("entries_page"); } else { $oop = "20"; }
    $MaxEntries = &Untaint($oop);
    if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
    else { $oop = "nodatahere"; }
    $oop =~ s/>/&gt;/g;		# make into code to make through taint check
    $oop =~ s/</&lt;/g;		# make into code to make through taint check
    my $pgcommand = &Untaint($oop);
    $pgcommand =~ s/&gt;/>/g;	# put back into pg readable
    $pgcommand =~ s/&lt;/</g;	# put back into pg readable
    if ( $query->param("page") ) { $oop = $query->param("page"); }
    else { $oop = "1"; }
    my $page = &Untaint($oop);
    &ProcessTable($page, $pgcommand);
  } # if ($action eq 'Page !') 
} # sub Process

sub ProcessTable {
	# Take in pgcommand from hidden field or from Pg ! button
	# Take in page number from Page ! button or 1 as default
	# Process sql query 
	# Output number of results as well as sql query
	# output page selector as well as selected page results
    my $page = shift; my $pgcommand = shift;
    my $result = $conn->exec( "$pgcommand" ); 
    my @row;
    @RowOfRow = ();
    while (@row = $result->fetchrow) {	# loop through all rows returned
      push @RowOfRow, [@row];
    } # while (@row = $result->fetchrow) 

      # identity display
    if ($curator) { print "You claim to be $curator<P>\n"; }

      # show amount of results and compute page things
    print "There are " . ($#RowOfRow+1) . " results to \"$pgcommand\".<BR>\n";
    my $remainder = $#RowOfRow % $MaxEntries;
    my $HighNumber = $#RowOfRow - $remainder;
    my $dividednumber = $HighNumber / $MaxEntries;

    &showSearch();

      # process with this form, select new page, pass hidden values.
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/checkout.cgi\">";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
                                # pass curator_name value in hidden field
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"entries_page\" VALUE=\"$MaxEntries\">\n";
                                # pass entries_page value in hidden field
    print "<TABLE>\n";
    print "<TD>Select your page of " . ($dividednumber + 1) . " : </TD><TD><SELECT NAME=\"page\" SIZE=5> \n"; 
    for my $k ( 1 .. ($dividednumber + 1) ) {
      print "<OPTION>$k</OPTION>\n";
    } # for my $k ( 0 .. $dividednumber ) 
    print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Page !\"></TD><BR><BR>\n";
    $pgcommand =~ s/>/&gt;/g;	# turn to code for html not to complain
    $pgcommand =~ s/</&lt;/g;	# turn to code for html not to complain
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"pgcommand\" VALUE=\"$pgcommand\">\n";
				# pass pgcommand value in hidden field
    $pgcommand =~ s/&gt;/>/g;	# turn back for pg not to complain
    $pgcommand =~ s/&lt;/</g;	# turn back for pg not to complain
    print "</TABLE>\n";
    print "</FORM>\n";
    print "<CENTER>\n";
    print "PAGE : $page<BR>\n";

      # show reference table
    print "<TABLE border=1 cellspacing=5>\n";
    if ($pgcommand =~ $test_pgcommand) { print "<TR><TD ALIGN=CENTER>joinkey</TD><TD ALIGN=CENTER>hardcopy</TD><TD ALIGN=CENTER>pdf</TD><TD ALIGN=CENTER>html</TD><TD ALIGN=CENTER>tif</TD><TD ALIGN=CENTER>lib_pdf</TD><TD ALIGN=CENTER>checked_out</TD><TD ALIGN=CENTER>alternate</TD><TD ALIGN=CENTER>alt out</TD><TD ALIGN=CENTER>last curated</TD><TD ALIGN=CENTER>curate</TD></TR>\n"; }
				# show headers if default
    for my $i ( (($page-1)*$MaxEntries) .. (($page*$MaxEntries)-1) ) {
				# for the amount of entries chosen in the chosen page
      my $row = $RowOfRow[$i];
      if ($row->[0]) {		# if there's an entry
        print "<TR>";
        &PrintFormOpen();	# print selector for curation_name.cgi form
        my $cgc = my $key = $row->[0];	# get cgc for pdf, key for cgc/pmid

        print "<INPUT TYPE=\"HIDDEN\" NAME=\"cgc_number\" VALUE=\"$cgc\">\n";
				# pass cgc (joinkey) as hidden to html
        if ($cgc =~ m/^cgc/) { $cgc =~ s/cgc//;	}	# get cgc number
        if ($cgc =~ m/^pmid/) { $cgc =~ s/pmid//; }	# get pmid number
        for my $j ( 0 .. $#{$row} ) {
          unless ( ($row->[$j]) || ($j == 2) ) { 	
				# if nothing there, print a space
				# unless it's a pdf, in which case need to check
				# if pdf exists
            print "<TD>&nbsp;</TD>\n"; 
          } else { 		# if something there
            unless ( ($pgcommand =~ $test_pgcommand) && ($j == 2) ) { 
				# unless it's a pdf
              print "<TD ALIGN=CENTER>$row->[$j]</TD>\n"; 
            } else {		# if it's a pdf, print a link
              my $pdfexists = 0;
              print "<TD>";	# open table down dealing with pdfs
              foreach my $pdffile (@pdffiles) {		# deal with local /home3/allpdfs/ pdfs
				# find the pdf that matches the joinkey 
#                 $pdffile =~ m/^\/home3\/allpdfs\/((\d+).*)$/;      
                $pdffile =~ m/^\/home\/acedb\/public_html\/daniel\/((\d+).*)$/;      
				# get the pdf filename
                if ($2) { if ($2 eq $cgc) {	
				# exact number matches only
				# if the pdf matches the cgc 
#                   print "<TD><A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A></TD>\n";	# print the link
#                   print "<A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A><BR>\n";	# print the link
                  print "<A HREF=\"http://tazendra.caltech.edu/~acedb/daniel/$1\">$1</A><BR>\n";	# print the link
                  print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$1\">\n";
                  $pdfexists = 1;	# pass pdf value in hidden field
                } }  # if ($pdffile =~ m/^$cgc\w+/) 
                if ($otherHash{$cgc}) {
                  if ($2) { if ($2 eq $otherHash{$cgc}) {	
				# exact number matches only
				# if the pdf matches the xref pmid
#                     print "<TD><A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A></TD>\n";	# print the link
#                     print "<A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A><BR>\n";	# print the link
                    print "<A HREF=\"http://tazendra.caltech.edu/~acedb/daniel/$1\">$1</A><BR>\n";	# print the link
                    print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$1\">\n";
                    $pdfexists = 1;	# pass pdf value in hidden field
                  } } # if ($2 eq $otherHash{$cgc}) 
                } # if ($pdffile =~ m/^$cgc\w+/) 

              } # foreach my $pdffile (@pdffiles) 
# commented out, always look at Athena
#               unless ($pdfexists) {		# if not found, look under athena
                foreach my $pdfath (@pdfathena) {		# deal with athena pdfs
                  $pdfath =~ m/(\d+).*/;
                  if ($1 eq $cgc) { 
#                     print "<TD><A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/$pdfath\">$pdfath</A></TD>\n";	# print the link
                    print "<A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/$pdfath\">$pdfath</A><BR>\n";	# print the link
                    print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$pdfath\">\n";
                    $pdfexists = 1;
                  } # if ($1 eq $cgc) 
                } # foreach my $pdfath (@pdfathena)
#               } # unless ($pdfexists)
#               unless ($pdfexists) { print "<TD>&nbsp;</TD>\n"; } 	# print a blank if nothing there
              unless ($pdfexists) { print "&nbsp;\n"; } 
              print "</TD>\n";	# close table down dealing with pdfs
            } # else # unless ( ($pgcommand =~ $test_pgcommand) && ($j == 2) ) 
          } # else # unless ($row->[$j]) 
        } # for my $j ( 0 .. $#{$row} ) 

          # check ref_xref for cgc if pmid, or pmid if cgc
        print "<TD ALIGN=CENTER>";
        if ($key =~ m/^cgc/) { if ($cgcHash{$key}) { print "$cgcHash{$key}"; } }
        elsif ($key =~ m/^pmid/) { if ($pmHash{$key}) { print "$pmHash{$key}"; } }
        else { print "<FONT COLOR=blue>ERROR : paper type unknown</FONT>"; }
        print "</TD><TD ALIGN=CENTER>";
        if ($key =~ m/^cgc/) { if ($cgcHash{$key}) { if ($checkedoutHash{$cgcHash{$key}}) { print "$checkedoutHash{$cgcHash{$key}}"; } else { 1; } } }
        if ($key =~ m/^pmid/) { if ($pmHash{$key}) { if ($checkedoutHash{$pmHash{$key}}) { print "$checkedoutHash{$pmHash{$key}}"; } else { 1; } } }
        print "</TD><TD ALIGN=CENTER>";
          # check if curated and print if so
        if ($curatedbyHash{$key}) { print "$curatedbyHash{$key}"; } 
        else { 
          if ($key =~ m/^cgc/) { if ($cgcHash{$key}) { if ($curatedbyHash{$cgcHash{$key}}) { print "$curatedbyHash{$cgcHash{$key}}"; } else { 1; } } }
          if ($key =~ m/^pmid/) { if ($pmHash{$key}) { if ($curatedbyHash{$pmHash{$key}}) { print "$curatedbyHash{$pmHash{$key}}"; } else { 1; } } }
        } # if ($curatedbyHash{$key}) 
        print "</TD>";

        print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curate !\"></TD>\n";
				# show button to ``Curate !''
        print "</FORM>\n";	# close each form
        print "</TR>\n";	# new table row
      } # if ($row->[0]) 	# if there's an entry
    } # for my $i ( 0 .. $#RowOfRow ) 
    if ($pgcommand =~ $test_pgcommand) { print "<TR><TD ALIGN=CENTER>joinkey</TD><TD ALIGN=CENTER>hardcopy</TD><TD ALIGN=CENTER>pdf</TD><TD ALIGN=CENTER>html</TD><TD ALIGN=CENTER>tif</TD><TD ALIGN=CENTER>lib_pdf</TD><TD ALIGN=CENTER>checked_out</TD><TD ALIGN=CENTER>alternate</TD><TD ALIGN=CENTER>alt out</TD><TD ALIGN=CENTER>last curated</TD><TD ALIGN=CENTER>curate</TD></TR>\n"; }
				# show headers if default
    print "</TABLE>\n";		# close table
    print "PAGE : $page<BR>\n";	# show page number again
    print "</CENTER>\n";
} # sub ProcessTable 

sub PrintFormOpen {		# open form link to appropriate curation_name.cgi 
				# depending on the curator
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation.cgi\">";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
#   if ($curator eq 'Wen Chen') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_wen.cgi\">";
#   } elsif ($curator eq 'Raymond Lee') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_raymond.cgi\">";
#   } elsif ($curator eq 'Andrei Petcherski') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_andrei.cgi\">";
#   } elsif ($curator eq 'Ranjana Kishore') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_ranjana.cgi\">";
#   } elsif ($curator eq 'Erich Schwarz') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_erich.cgi\">";
#   } elsif ($curator eq 'Paul Sternberg') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_paul.cgi\">";
# #   } elsif ($curator eq 'Andrei Testing') {
# #     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_andrei_play.cgi\">";
#   } elsif ($curator eq 'Juancarlos Testing') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_azurebrd.cgi\">";
#   } else {
#     print "You have not chosen a valid Curator, contact the admin.<P>\n";
#   }
} # sub PrintFormOpen 

sub showSearch {		# look for a specific number
  print <<"EndOfText";
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/checkout.cgi">
  <TABLE><TR>
  <TD>Search for a specific number :</TD>
  <TD><INPUT NAME="search_type" TYPE="radio" VALUE="sub" CHECKED>Wild Card<BR>
  <INPUT NAME="search_type" TYPE="radio" VALUE="exact">Exact</TD>
  <TD><INPUT NAME="paper_type" TYPE="radio" VALUE="CGC" CHECKED>CGC<BR>
  <INPUT NAME="paper_type" TYPE="radio" VALUE="PMID">PMID<BR>
  <INPUT NAME="paper_type" TYPE="radio" VALUE="MED">MED<BR>
  <INPUT NAME="paper_type" TYPE="radio" VALUE="AGP">AGP</TD>
  <TD><INPUT NAME="paper_number" SIZE=40></TD>
  <INPUT TYPE="HIDDEN" NAME="curator_name" VALUE="$curator">
  <TD><INPUT TYPE="submit" NAME="action" VALUE="Search !"></TD>
  </TR></TABLE>
  </FORM>
EndOfText
} # sub showSearch

sub ShowPgQuery {		# textarea box to make pgsql queries
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/checkout.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="HIDDEN" NAME="curator_name" VALUE="$curator">
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
} # sub ShowPgQuery

sub populateHashes {
    # check xreferences
  my $result = $conn->exec( "SELECT * FROM ref_xref;" ); 
  my @row;
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $cgcHash{$row[0]} = $row[1];
    $pmHash{$row[1]} = $row[0];
    $row[0] =~ s/cgc//;
    $row[1] =~ s/pmid//;
    $otherHash{$row[0]} = $row[1];
    $otherHash{$row[1]} = $row[0];
  } # while (my @row = $result->fetchrow) 
  $result = $conn->exec ( "SELECT * FROM ref_checked_out;" );
  while (@row = $result->fetchrow) {
    $checkedoutHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
    # check if curated
  $result = $conn->exec ( "SELECT * FROM cur_curator;" );
  while (@row = $result->fetchrow) {
    $curatedbyHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
} # sub populateHashes

sub getAthenaPdfs {			# populate array of athena pdfs
    # use LWP::Simple to get the list of PDFs from Athena
  my $page = get "http://athena.caltech.edu/~daniel/tif_pdf/";
#   @pdfathena = $page =~ m/HREF="(.*?tif\.pdf)"/g;	# get list of athena pdfs
  @pdfathena = $page =~ m/href="(.*?tif\.pdf)"/g;	# get list of athena pdfs # someone changed HREF to href 2004 01 14
} # sub getAthenaPdfs

sub Untaint {
  my $tainted = shift;
  my $untainted;
  $tainted =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*(){}[\]+=!~|' \t\n\r\f]//g;
  if ($tainted =~ m/^([\w\-.,;:?\/\\@#\$\%&\^*(){}[\]+=!~|' \t\n\r\f]+)$/) {
    $untainted = $1;
  } else {
    die "Bad data in $tainted";
  }
  return $untainted;
} # sub Untaint 


sub PrintHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">
  
<HEAD>
<TITLE>Reference Data Query</TITLE>
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
<CENTER>Documentation <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/checkout_doc.txt" TARGET=NEW>here</A></CENTER><P>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 


# DEPRECATED

sub PrintTableLabels {		# Just a bunch of table down entries
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>title</TD><TD>journal</TD><TD>volume</TD><TD>pages</TD><TD>year</TD><TD>abstract</TD><TD>hardcopy</TD><TD>pdf</TD><TD>html</TD><TD>tif</TD><TD>lib_pdf</TD></TR>\n";
} # sub PrintTableLabels 


sub PrintPgTable {
  my @ary;
#   Pg::doQuery($conn, "select * from testreference where lib = '1'", \@ary);
  Pg::doQuery($conn, "select * from testreference", \@ary);
  print "<CENTER><TABLE border=1 cellspacing=5>\n";
  &PrintTableLabels();
#   my $result = $conn->exec( "SELECT * FROM testreference where lib = '1';" ); 
  my $result = $conn->exec( "SELECT * FROM testreference;" ); 
        my @row;
        while (@row = $result->fetchrow) {	# loop through all rows returned
# if ( ($row[0] =~ m/^cgc100/) || ($row[0] =~ m/^cgc200/) || ($row[0] =~ m/^cgc12/) ) 
if ($row[3] =~ m/Nature/) {
          print "<TR>";
          foreach $_ (@row) {
            print "<TD>${_}&nbsp;</TD>\n";		# print the value returned
          }
          print "</TR>\n";
}
        } # while (@row = $result->fetchrow) 
#   for my $i ( 0 .. $#ary ) {
#     print "<TR>";
#     for my $j ( 0 .. $#{$ary[$i]} ) {
#       print "<TD>$ary[$i][$j]</TD>";
#     } # for my $j ( 0 .. $#{$ary[$i]} ) 
#     print "</TR>\n";
#   } # for my $i ( 0 .. $#ary ) 
  &PrintTableLabels();
  print "</TABLE></CENTER>\n";
} # sub PrintPgTable 
