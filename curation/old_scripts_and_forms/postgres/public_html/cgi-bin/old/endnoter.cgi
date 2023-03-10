#!/usr/bin/perl -w
#
# Edit hardcopy/electonic copy status.
#
# Start with a default postgreSQL query showing joinkeys, journal, hardcopy,
# pdf, html, tif, lib, and date last changed (by cgc table).  Choose to sort by
# any of those tables, and showing 20 entries in each page, which page to look
# at.  Choose one to Edit !
# Shows cgc number, time of last editing, name of tables, data from each table,
# and checkbox to say whether to change the data or not.  Shows status of papers
# and whether we have hardcopy/pdf/html/tif/lib.  Click Change ! to preview.
# Shows cgc number.  In red shows what hasn't changed or clicked to send out.
# In green it shows what has changed or been chosen to send / update.  In blue
# it shows warnings if no data.  Click Confirm ! to email Theresa and update
# PostgreSQL tables.
# Same display, but now emails Theresa and updates postgreSQL tables.  2002 02 01
#
# Added display to show ``Search !'',  and select fields to search by.  Added
# Counts to count hardcopies, pdfs, libs, htmls, tifs, each w/o hardcopy,
# hardcopy alone.  2002 02 08
#
# Changed val_ref_abstract textarea to print nothing if there's no data, as opposed 
# to &nbsp; which was causing errors in IE, and wasn't leaving a NULL value in the
# pg database (which was wrong)  2002 02 18
#
# &countExclude changed to write HC only to a tab-delimited file for daniel.  
# 2002 02 25
#
# changed email to email theresa and daniel  2002 03 13
#
# added a if ($action) { } wrapper in the &ProcessTable() subroutine to keep 
# a bunch of idiotic ``uninitialized value in string eq at..'' lines  2002 04 12
#
# Updated to show the new ref_comment table instead of date of last change.  
# created and populated ref_comment table (with NULLs).  added ref_comment to the
# @pg_ref_info_tables for ease of coding (messy) because it takes input like other
# tables there.  added a check so as not to $sendmail++ if it's the ref_comment
# table, and to update under &confirmData(); if comment field has changed
# 2002 05 03
#
# Updated to allow non-existing data to show to be edited.  Changed &confirmData();
# to check whether an entry already exists (in which case, update) or doesn't
# (in which case, insert)  2002 05 06
# 
# Updated to check for row[0] to decide whether to INSERT or UPDATE becuse row[1]
# would often be NULL, so would make no check at all.  [at if (row[1]) ]. 
# Updated Jex.pm to have a getPgDate to have a pg format date.  printing out
# changes made to a changes.log file with pgDate for timestamp.  2002 05 08
#
# Updated to account for doublequotes.  Turn into &quot; for html.  Turn into
# TAG_QUOTE and back before Untainting.  2002 06 17
#
# Added ref_tif_pdf and ref_lib_pdf to postgres, and so made appropriately similar
# additions to the cgi, and edited the pg SELECTs to include those new fields.
# 2002 07 12
#
# Deleted ref_tif  2002 07 16
#
# Added $nopdf_pgcommand, and ``No Pdf !'' button to sort by entries without PDF
# (as opposed to sorting by pdf and looking backwards, I guess to get a count)
# Added table dividers to buttons so they don't scroll right.  2002 11 10

use strict;
use Jex;
use CGI;
use Fcntl;
use Pg;
use Mail::Mailer;

my $query = new CGI;
my $firstflag = 1;		# set flag for first time to do stuff
our @RowOfRow;
my $MaxEntries = 20;
our $pgcommand;			# global query

our $test_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, "; # ref_cgc.ref_timestamp FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_lib WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_lib.joinkey = ref_cgc.joinkey";
  # used to check for similarity in =~ check to display html table headers

  # old way with dates
# our $default_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_cgc.ref_timestamp FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey ORDER BY ref_cgc.ref_timestamp DESC;";

  # new way with comments
our $default_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_cgc.ref_timestamp DESC;";

our $pmid_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_pmid, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_pmid.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_pmid.joinkey AND ref_html.joinkey = ref_pmid.joinkey AND ref_tif.joinkey = ref_pmid.joinkey AND ref_tif_pdf.joinkey = ref_pmid.joinkey AND ref_lib_pdf.joinkey = ref_pmid.joinkey AND ref_comment.joinkey = ref_pmid.joinkey ORDER BY ref_pmid.ref_timestamp DESC;";

our $med_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_med, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_med.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_med.joinkey AND ref_html.joinkey = ref_med.joinkey AND ref_tif.joinkey = ref_med.joinkey AND ref_tif_pdf.joinkey = ref_med.joinkey AND ref_lib_pdf.joinkey = ref_med.joinkey AND ref_comment.joinkey = ref_med.joinkey ORDER BY ref_med.ref_timestamp DESC;";

our $agp_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_agp, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_agp.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_agp.joinkey AND ref_html.joinkey = ref_agp.joinkey AND ref_tif.joinkey = ref_agp.joinkey AND ref_tif_pdf.joinkey = ref_agp.joinkey AND ref_lib_pdf.joinkey = ref_agp.joinkey AND ref_comment.joinkey = ref_agp.joinkey ORDER BY ref_agp.ref_timestamp DESC;";

  # by which ever sorting method
our $date_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_cgc.ref_timestamp DESC;";

our $cgc_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_cgc DESC;";

our $journal_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_journal;";

our $hardcopy_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_hardcopy;";

our $pdf_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_pdf;";

our $nopdf_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey AND ref_pdf.ref_pdf IS NULL ORDER BY ref_pdf.joinkey;";

our $html_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_html;";

our $tif_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_tif;";

our $tif_pdf_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_tif_pdf;";

our $lib_pdf_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_lib_pdf;";

# our $lib_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_cgc, ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_cgc.joinkey = ref_pdf.joinkey AND ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_cgc.joinkey AND ref_html.joinkey = ref_cgc.joinkey AND ref_tif.joinkey = ref_cgc.joinkey AND ref_tif_pdf.joinkey = ref_cgc.joinkey AND ref_lib_pdf.joinkey = ref_cgc.joinkey AND ref_comment.joinkey = ref_cgc.joinkey ORDER BY ref_lib DESC;";

  # pg command for getting display of records with no kind of record (no hardcopy, no pdf, no html,
  # no lib, no tif)
our $none_pgcommand = "SELECT ref_pdf.joinkey, ref_journal.ref_journal, ref_hardcopy.ref_hardcopy, ref_pdf.ref_pdf, ref_html.ref_html, ref_tif.ref_tif, ref_tif_pdf.ref_tif_pdf, ref_lib_pdf.ref_lib_pdf, ref_comment.ref_comment FROM ref_journal, ref_pdf, ref_hardcopy, ref_html, ref_tif, ref_tif_pdf, ref_lib_pdf, ref_comment WHERE ref_journal.joinkey = ref_pdf.joinkey AND ref_hardcopy.joinkey = ref_pdf.joinkey AND ref_html.joinkey = ref_pdf.joinkey AND ref_tif.joinkey = ref_pdf.joinkey AND ref_tif_pdf.joinkey = ref_pdf.joinkey AND ref_lib_pdf.joinkey = ref_pdf.joinkey AND ref_pdf.ref_pdf IS NULL AND ref_html.ref_html IS NULL AND ref_tif.ref_tif IS NULL AND ref_tif_pdf IS NULL AND ref_lib_pdf IS NULL AND ref_hardcopy.ref_hardcopy IS NULL AND ref_comment.joinkey = ref_pdf.joinkey ORDER BY ref_pdf DESC;";


# our $default_pgcommand = "SELECT pdf.joinkey, journal.journal, hardcopy.hardcopy, pdf.pdf, html.html, tif.tif, lib.lib FROM cgc, journal, pdf, hardcopy, html, tif, lib WHERE cgc.joinkey = pdf.joinkey AND journal.joinkey = pdf.joinkey AND hardcopy.joinkey = cgc.joinkey AND html.joinkey = cgc.joinkey AND tif.joinkey = cgc.joinkey AND lib.joinkey = cgc.joinkey AND cgc.joinkey ~ '12' ORDER BY cgc DESC;";
# our $default_pgcommand = "SELECT pdf.joinkey, hardcopy.hardcopy, pdf.pdf, html.html, tif.tif, lib.lib FROM cgc, pdf, hardcopy, html, tif, lib WHERE cgc.joinkey = pdf.joinkey AND hardcopy.joinkey = cgc.joinkey AND html.joinkey = cgc.joinkey AND tif.joinkey = cgc.joinkey AND lib.joinkey = cgc.joinkey AND cgc.joinkey ~ '123' ORDER BY cgc DESC;";
# our $default_pgcommand = "SELECT pdf.joinkey, hardcopy.hardcopy, pdf.pdf, html.html, tif.tif, lib.lib, checked_out.checked_out FROM cgc, pdf, hardcopy, html, tif, lib, checked_out WHERE cgc.joinkey = pdf.joinkey AND hardcopy.joinkey = cgc.joinkey AND html.joinkey = cgc.joinkey AND tif.joinkey = cgc.joinkey AND lib.joinkey = cgc.joinkey AND checked_out.joinkey = cgc.joinkey ORDER BY cgc DESC;";
				# default query
$pgcommand = $default_pgcommand;
our @pdffiles;			# make list of pdfs
push @pdffiles, </home3/allpdfs/*.pdf>;	# get list of pdfs

my $color_key = "COLOR KEY : <FONT COLOR=blue> blue are warnings</FONT>, <FONT COLOR=red>red doesn't change</FONT>, <FONT COLOR=green>green changes</FONT>, black is normal text.<BR><BR>\n"; 						# text for color_key

  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&PrintHeader();			# print the HTML header
&Process();			# Do pretty much everything
&Display(); 			# Select whether to show selectors for curator name
				# entries / page, and &ShowPgQuery();
&PrintFooter();			# print the HTML footer

sub Display {
  if ($firstflag) { 		# first time through, process didn't do anything
    $pgcommand = $default_pgcommand; 	# set pg command
    my $page = 1;		# set page number
    &ProcessTable($page, $pgcommand);	# call up work horse
  } # if ($firstflag) 		# first time through
  &ShowPgQuery();		# show query
} # sub Display


sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none'; 
  }

  if ($action eq 'Query !') {
    &searchPg();		# show search
  } # if ($action eq 'Query !')

  if ($action eq 'Search !') {
    &showPgSearch();		# show search
  } # if ($action eq 'Search !')

  if ($action eq 'Confirm !') {
    &confirmData();
  }

  if ($action eq 'Change !') {
    &changeData();
  }

  if ($action eq 'Edit !') {
    &editData();
  }

    # if new postgres command or curator chosen
  if ($action eq 'Pg !') {
    $firstflag = 0;
    my $oop;

      # get $pgcommand
    my $pgcommand;
    if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
				# if there's a comand, read it
    else { $oop = "nodatahere"; }
    $oop =~ s/>/&gt;/g;		# make into code to make through taint check
    $oop =~ s/</&lt;/g;		# make into code to make through taint check
    $pgcommand = &Untaint($oop);
    $pgcommand =~ s/&gt;/>/g;	# put back into pg readable
    $pgcommand =~ s/&lt;/</g;	# put back into pg readable
    if ($pgcommand eq 'nodatahere') { $pgcommand = $default_pgcommand; }
				# if no command, use default

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

    if ($pgcommand =~ m/(DROP|DELETE)/i) { 
      				# if invalid postgres command
      print "Dropping and Deleting not allowed through web form, use psql<BR>\n";
    } else { # if ($pgcommand =~ m/(DROP|DELETE)/i)
				# if valid command
      my $result = $conn->exec( "$pgcommand" ); 
				# make query, put in $result
      if ( $pgcommand !~ m/select/i ) {
				# if not a select, just show query box again
        print "PostgreSQL has processed it.<BR>\n";
        &ShowPgQuery();
      } else { # if ( $pgcommand !~ m/select/i ) 
				# if a select, process and display
        &ProcessTable($page, $pgcommand);
      } # else # if ( $pgcommand !~ m/select/i ) 
    } # else # if ($pgcommand eq "nodatahere") 
  } # if ($action eq 'Pg !') 

    # this could be made part of above, if so chosen.
  if ( ($action eq 'Page !') || ($action eq 'Date !') || ($action eq 'Number !') ||
       ($action eq 'Journal !') || ($action eq 'Hardcopy !') || 
       ($action eq 'Pdf !') || ($action eq 'No Pdf !') || ($action eq 'Html !') || 
       ($action eq 'Tif !') || ($action eq 'Tif_Pdf !') || ($action eq 'Lib_Pdf !') || 
#        ($action eq 'Lib !') || 
       ($action eq 'No Record !') ||
       ($action eq 'Cgc !') || ($action eq 'Pmid !') || ($action eq 'Med !') || 
       ($action eq 'Agp !') ) {
#   if ($action eq 'Page !') 
    $firstflag = 0;
    my $oop;

      # get number of pages
    if ( $query->param("entries_page") ) { $oop = $query->param("entries_page"); } else { $oop = "20"; }
    $MaxEntries = &Untaint($oop);

      # get the command from the hidden field
    if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
    else { $oop = "nodatahere"; }
    $oop =~ s/>/&gt;/g;		# make into code to make through taint check
    $oop =~ s/</&lt;/g;		# make into code to make through taint check
    $pgcommand = &Untaint($oop);
    $pgcommand =~ s/&gt;/>/g;	# put back into pg readable
    $pgcommand =~ s/&lt;/</g;	# put back into pg readable

      # get the page number
    if ( $query->param("page") ) { $oop = $query->param("page"); }
    else { $oop = "1"; }
    my $page = &Untaint($oop);

      # call the work horse
    &ProcessTable($page, $pgcommand, $action);
  } # if ( ($action eq 'Page !') || ($action eq 'Date !') || ($action eq 'Number !') ||
    #      ($action eq 'Journal !') || ($action eq 'Hardcopy !') || ($action eq 'Pdf !') ||
    #      ($action eq 'Html !') || ($action eq 'Tif !') ) # || ($action eq 'Lib !') )

  if ( ($action eq 'Count HC !') || ($action eq 'Count PDF !') || # ($action eq 'Count Lib !') || 
       ($action eq 'Count Html !') || ($action eq 'Count Tif !') || 
       ($action eq 'Count Tif_Pdf !') || ($action eq 'Count Lib_Pdf !') || 
       ($action eq 'PDF no HC !') || # ($action eq 'Lib no HC !') || 
       ($action eq 'Tif no HC !') || ($action eq 'Tif_Pdf no HC !') ||
       ($action eq 'Lib_Pdf no HC !') || ($action eq 'HC Only !') || 
       ($action eq 'Html no HC !') ) {
    $firstflag = 0;
    if ($action eq 'Count HC !') { &countTable('ref_hardcopy'); }
    if ($action eq 'Count PDF !') { &countTable('ref_pdf'); }
#     if ($action eq 'Count Lib !') { &countTable('ref_lib'); }
    if ($action eq 'Count Html !') { &countTable('ref_html'); }
    if ($action eq 'Count Tif !') { &countTable('ref_tif'); }
    if ($action eq 'Count Tif_Pdf !') { &countTable('ref_tif_pdf'); }
    if ($action eq 'Count Lib_Pdf !') { &countTable('ref_lib_pdf'); }
    if ($action eq 'PDF no HC !') { &countExclude('ref_pdf'); }
    if ($action eq 'Tif no HC !') { &countExclude('ref_tif'); }
    if ($action eq 'Tif_Pdf no HC !') { &countExclude('ref_tif_pdf'); }
    if ($action eq 'Lib_Pdf no HC !') { &countExclude('ref_lib_pdf'); }
#     if ($action eq 'Lib no HC !') { &countExclude('ref_lib'); }
    if ($action eq 'Html no HC !') { &countExclude('ref_html'); }
    if ($action eq 'HC Only !') { &countExclude('ref_all'); }
  } # if ( ($action eq 'Count HC !') || ($action eq 'Count PDF !') || # ($action eq 'Count Lib !') || 
    #      ($action eq 'Count Html !') || ($action eq 'Count Tif !') || ($action eq 'PDF no HC !') || 
    #      ($action eq 'Lib no HC !') || # ($action eq 'Tif no HC !') || ($action eq 'HC Only !') )


} # sub Process

sub countTable {
  my $table = shift;
  my $result = $conn->exec( "SELECT COUNT(*) FROM $table WHERE $table IS NOT NULL;" );
  my @row = $result->fetchrow;
  print "There are $row[0] entries in ${table}.<BR><P>\n";
} # sub countTable

sub countExclude {
  my $table = shift;
  my (%hardcopy, %pdf, %tif, %tif_pdf, %lib_pdf, %html);
  my $count = 0;

  my $result = $conn->exec( "SELECT joinkey FROM ref_hardcopy WHERE ref_hardcopy IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    unless ($row[0]) { 
      print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
    } else { $hardcopy{$row[0]}++; } 
  } # while (my @row = $result->fetchrow)

  if ( ($table eq 'ref_all') || ($table eq 'ref_pdf') ) {
    my $result = $conn->exec( "SELECT joinkey FROM ref_pdf WHERE ref_pdf IS NOT NULL;" );
    while (my @row = $result->fetchrow) {
      unless ($row[0]) { 
        print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
      } else { $pdf{$row[0]}++; } 
    } # while (my @row = $result->fetchrow)
  } # if ( ($table eq 'ref_all') || ($table eq 'ref_pdf') )

  if ( ($table eq 'ref_all') || ($table eq 'ref_tif') ) {
    my $result = $conn->exec( "SELECT joinkey FROM ref_tif WHERE ref_tif IS NOT NULL;" );
    while (my @row = $result->fetchrow) {
      unless ($row[0]) { 
        print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
      } else { $tif{$row[0]}++; } 
    } # while (my @row = $result->fetchrow)
  } # if ( ($table eq 'ref_all') || ($table eq 'ref_tif') )

  if ( ($table eq 'ref_all') || ($table eq 'ref_tif_pdf') ) {
    my $result = $conn->exec( "SELECT joinkey FROM ref_tif_pdf WHERE ref_tif_pdf IS NOT NULL;" );
    while (my @row = $result->fetchrow) {
      unless ($row[0]) { 
        print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
      } else { $tif_pdf{$row[0]}++; } 
    } # while (my @row = $result->fetchrow)
  } # if ( ($table eq 'ref_all') || ($table eq 'ref_tif_pdf') )

  if ( ($table eq 'ref_all') || ($table eq 'ref_lib_pdf') ) {
    my $result = $conn->exec( "SELECT joinkey FROM ref_lib_pdf WHERE ref_lib_pdf IS NOT NULL;" );
    while (my @row = $result->fetchrow) {
      unless ($row[0]) { 
        print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
      } else { $lib_pdf{$row[0]}++; } 
    } # while (my @row = $result->fetchrow)
  } # if ( ($table eq 'ref_all') || ($table eq 'ref_lib_pdf') )

#   if ( ($table eq 'ref_all') || ($table eq 'ref_lib') ) {
#     my $result = $conn->exec( "SELECT joinkey FROM ref_lib WHERE ref_lib IS NOT NULL;" );
#     while (my @row = $result->fetchrow) {
#       unless ($row[0]) { 
#         print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
#       } else { $lib{$row[0]}++; } 
#     } # while (my @row = $result->fetchrow)
#   } # if ( ($table eq 'ref_all') || ($table eq 'ref_lib') )

  if ( ($table eq 'ref_all') || ($table eq 'ref_html') ) {
    my $result = $conn->exec( "SELECT joinkey FROM ref_html WHERE ref_html IS NOT NULL;" );
    while (my @row = $result->fetchrow) {
      unless ($row[0]) { 
        print "<FONT COLOR=blue>ERROR : Bad query in subroutine countExclude</FONT><BR>\n";
      } else { $html{$row[0]}++; } 
    } # while (my @row = $result->fetchrow)
  } # if ( ($table eq 'ref_all') || ($table eq 'ref_html') )

  if ($table eq 'ref_pdf') { 
    foreach $_ (sort keys %pdf) { 
      unless ($hardcopy{$_}) { $count++; }
    } # foreach $_ (sort keys %pdf) 
    print "There are $count Pdfs with no hardcopy.<BR><P>\n";
  } # if ($table eq 'ref_pdf') 

  if ($table eq 'ref_tif') { 
    foreach $_ (sort keys %tif) { 
      unless ($hardcopy{$_}) { $count++; }
    } # foreach $_ (sort keys %tif) 
    print "There are $count Tifs with no hardcopy.<BR><P>\n";
  } # if ($table eq 'ref_tif') 

  if ($table eq 'ref_tif_pdf') { 
    foreach $_ (sort keys %tif_pdf) { 
      unless ($hardcopy{$_}) { $count++; }
    } # foreach $_ (sort keys %tif_pdf) 
    print "There are $count Tif_Pdfs with no hardcopy.<BR><P>\n";
  } # if ($table eq 'ref_tif_pdf') 

  if ($table eq 'ref_lib_pdf') { 
    foreach $_ (sort keys %lib_pdf) { 
      unless ($hardcopy{$_}) { $count++; }
    } # foreach $_ (sort keys %lib_pdf) 
    print "There are $count Lib_Pdfs with no hardcopy.<BR><P>\n";
  } # if ($table eq 'ref_lib_pdf') 

#   if ($table eq 'ref_lib') { 
#     foreach $_ (sort keys %lib) { 
#       unless ($hardcopy{$_}) { $count++; }
#     } # foreach $_ (sort keys %lib) 
#     print "There are $count Libs with no hardcopy.<BR><P>\n";
#   } # if ($table eq 'ref_lib') 

  if ($table eq 'ref_html') { 
    foreach $_ (sort keys %html) { 
      unless ($hardcopy{$_}) { $count++; }
    } # foreach $_ (sort keys %html) 
    print "There are $count Htmls with no hardcopy.<BR><P>\n";
  } # if ($table eq 'ref_html') 

  if ($table eq 'ref_all') { 
    my $outfile = "/home/postgres/public_html/cgi-bin/daniel/hc_only_tabbed.txt";
							# write output of hardcopy only to a txt file
    my %sorted_hc_only;					# make a hash to sort stuff more easily
    foreach $_ (sort keys %hardcopy) { 
      unless ( ($pdf{$_}) || ($tif{$_}) || ($tif_pdf{$_}) || ($lib_pdf{$_}) || ($html{$_}) ) { 
        my $full = $_;					# keep the full thing
        $_ =~ s/\D//g; 					# sort by just the numbers
        $sorted_hc_only{$_} = $full; 			# put in a hash
      } # unless ( ($pdf{$_}) || ($tif{$_}) || ($html{$_}) ) 
    } # foreach $_ (sort keys %hardcopy) 
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";	# open to write out
    foreach $_ (sort numerically keys %sorted_hc_only) { print OUT "$sorted_hc_only{$_}\t"; $count++; }
									# write to a file, add count
    close (OUT) or die "Cannot close $outfile : $!";			# close the write out
    print "There are $count Hardcopies alone.  Download <A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/daniel/hc_only_tabbed.txt\">here</A><BR><P>\n";		     # show link to output file and count
  } # if ($table eq 'ref_html') 
} # sub countExclude

sub showPgSearch {
  $firstflag = 0;
  my @pg_ref_info_tables = qw(ref_cgc ref_author ref_title ref_journal ref_pages ref_volume ref_year ref_abstract);
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi\">";
  print "<TABLE border = 1 cellspacing = 2>\n";
  foreach my $pg_info_table (@pg_ref_info_tables) {
    print "<TR><TD>$pg_info_table</TD><TD><INPUT NAME=\"che_$pg_info_table\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"></TD><TD><INPUT NAME=\"val_$pg_info_table\" VALUE=\"\" SIZE=70></TD></TR>\n";
#         print "<TR><TD>$pg_table</TD><TD><INPUT NAME=\"che_$pg_table\" TYPE=\"checkbox\" ";
#         print "VALUE=\"yes\"></TD><TD><INPUT NAME=\"val_$pg_table\" VALUE=\"";
#         if ($row[1]) { print $row[1]; } else { print "&nbsp;"; }	# print data or space
#         print "\" SIZE=70></TD></TR>\n";
  } # foreach my $pg_info_table (@pg_ref_info_tables)
  print "</TABLE>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Query !\">\n";
  print "</FORM>\n";
} # sub showPgSearch

sub searchPg {
  $firstflag = 0;
  my @pg_ref_info_tables = qw(ref_cgc ref_author ref_title ref_journal ref_pages ref_volume ref_year ref_abstract);
  my @pg_ref_edit_tables = qw(ref_author ref_title ref_journal ref_pages ref_volume ref_year ref_hardcopy ref_pdf ref_html ref_tif ref_tif_pdf ref_lib_pdf ); 
  my %pgToSearch;
  foreach my $pg_info_table (@pg_ref_info_tables) {
    my $oop;
    if ($query->param("che_$pg_info_table") ) {		# if want to search
      unless ($query->param("val_$pg_info_table") ) {	# if has value to search
        print "<FONT COLOR=blue>ERROR : No data to search $pg_info_table</FONT><BR>\n";
      } else {
        $oop = $query->param("val_$pg_info_table");
        my $val_pg_info = &Untaint($oop);
#         print "$pg_info_table : $val_pg_info<BR>\n";
        $pgToSearch{$pg_info_table} = $val_pg_info;
      } # if ($query->param("val_$pg_info_table") )
    } # if ($query->param("val_$pg_info_table") )
  } # foreach my $pg_info_table (@pg_ref_info_tables)
  my %joinkeys = ();
  foreach my $pg_info_table (sort keys %pgToSearch) {
    print "SEARCH : $pg_info_table : $pgToSearch{$pg_info_table}<BR>\n";
    my @joinkeys = &getJoinkeys($pg_info_table, $pgToSearch{$pg_info_table});
    foreach $_ (@joinkeys) { $joinkeys{$_}++; }		# add joinkey to hash
  } # foreach my $pg_info_table (sort keys %pgToSearch)
  print "<TABLE border = 1 cellspacing = 2>\n";
#   print "<TR><TD>joinkey</TD><TD>matches</TD><TD>Journal</TD><TD>Hardcopy</TD><TD>pdf</TD><TD>Html</TD><TD>Tif</TD><TD>Lib</TD><TD>Date Changed</TD><TD>Edit</TD></TR>\n";
  print "<TR><TD>joinkey</TD><TD>matches</TD><TD>Authors</TD><TD>Title</TD><TD>Journal</TD><TD>pages</TD><TD>Volume</TD><TD>year</TD><TD>Hardcopy</TD><TD>pdf</TD><TD>Html</TD><TD>Tif</TD><TD>Tif_Pdf</TD><TD>Lib_Pdf</TD><TD>Edit</TD></TR>\n";
  foreach my $joinkey (sort {$joinkeys{$b} <=> $joinkeys{$a}} keys %joinkeys) {
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi\">";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_number\" VALUE=\"$joinkey\">\n";
    print "<TR><TD>$joinkey</TD><TD>$joinkeys{$joinkey}</TD>";
    foreach my $ref_edit_table (@pg_ref_edit_tables) {
      &printEditCell($joinkey, $ref_edit_table);
    } # foreach my $ref_edit_table (@pg_ref_edit_tables)
#     &printTimeCell($joinkey);			# to show time changed
    print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Edit !\"></TD>\n";
				# show button to ``Edit !''
    print "</FORM>\n";					# close each form
#     print "$joinkey : $joinkeys{$joinkey}<BR>\n";
  } # foreach my $joinkey (sort {$joinkeys{$b} <=> $joinkeys{$a}} keys %joinkeys)
  print "<TR><TD>joinkey</TD><TD>matches</TD><TD>Authors</TD><TD>Title</TD><TD>Journal</TD><TD>pages</TD><TD>Volume</TD><TD>year</TD><TD>Hardcopy</TD><TD>pdf</TD><TD>Html</TD><TD>Tif</TD><TD>Tif_Pdf</TD><TD>Lib_Pdf</TD><TD>Edit</TD></TR>\n";
  print "</TABLE>\n";
} # sub searchPg

sub printTimeCell {
  my ($joinkey) = @_;
  my $result = $conn->exec( "SELECT ref_timestamp FROM ref_cgc WHERE joinkey = \'$joinkey\';" );
  my @row = $result->fetchrow;
  print "<TD>$row[0]</TD>";
} # sub printTimeCell

sub printEditCell {
  my ($joinkey, $ref_edit_table) = @_;
  my $result = $conn->exec( "SELECT $ref_edit_table FROM $ref_edit_table WHERE joinkey = \'$joinkey\';" );
  my @row = $result->fetchrow; 
  unless ($row[0]) { 
    print "<TD>&nbsp;</TD>\n";
  } else { 
    print "<TD WIDTH=40>$row[0]</TD>\n";
  } # print data or space
} # sub printEditCell

sub numerically { $a <=> $b }

sub getJoinkeys {
  my ($table, $value) = @_;
  my @joinkeys;					
  my $result = $conn->exec( "SELECT joinkey FROM $table WHERE $table \~ \'$value\';" );
  while (my @row = $result->fetchrow) {
    unless ($row[0]) { 
      print "<FONT COLOR=blue>ERROR : Bad query in subroutine getJoinkeys</FONT><BR>\n";
    } else { 
#       print "VAL : $row[0]<BR>\n"; 
      push @joinkeys, $row[0];
    } # print data or space
  } # while (my @row = $result->fetchrow)
  return @joinkeys;
} # sub getJoinkeys

sub confirmData {
  $firstflag = 0;
  my $oop; 
  my $type_number; my $type;
  my @pg_ref_info_tables = qw(ref_author ref_title ref_journal ref_pages ref_volume ref_year ref_abstract ref_comment);
  my @pg_ref_copy_tables = qw(ref_hardcopy ref_pdf ref_html ref_tif ref_tif_pdf ref_lib_pdf );
  print $color_key;
  my $user = 'daniel';
#   my $email = "azurebrd\@minerva.caltech.edu";
#   my $email = "stier\@biosci.cbs.umn.edu, qwang\@its.caltech.edu";
  my $email = "qwang\@its.caltech.edu";
#   my $email = "qhw980806\@yahoo.com";
  my $subject = '';
  my $body = '';
  my $send_email = 0;

  unless ($query->param("number_type") ) { 
    print "<FONT COLOR=blue>ERROR : No type number</FONT><BR>\n";
  } else { # unless ($query->param("number_type") )
    $oop = $query->param("number_type");
    $type = &Untaint($oop);
  } # else # unless ($query->param("number_type") )

  unless ($query->param("type_number") ) { 
    print "<FONT COLOR=blue>ERROR : No type number</FONT><BR>\n";
  } else { # unless ($query->param("type_number") )
    $oop = $query->param("type_number");
    $type_number = &Untaint($oop);
  } # else # unless ($query->param("type_number") )
  print "TYPE : $type : NUMBER : $type_number<BR>\n";

  foreach my $pg_table (@pg_ref_info_tables) {
    if ($query->param("good_$pg_table") ) {	# if good (changed)
      $oop = $query->param("good_$pg_table");
      $oop =~ s/\"/TAG_QUOTE/g;			# account for double quotes
      my $pg_value = &Untaint($oop);
      $pg_value =~ s/TAG_QUOTE/\"/g;		# account for double quotes
      print "<FONT COLOR=green>$pg_table : $pg_value</FONT><BR>\n";
      $body .= "$pg_table changed to : $pg_value\n";
      unless ($pg_table eq 'ref_comment') {	# send email unless it's internal comment only
        $send_email++; 
      } # unless ($pg_table eq 'ref_comment')

        # check whether value already exists
      my $result = $conn->exec( "SELECT * FROM $pg_table WHERE joinkey = \'${type}${type_number}\';" );
      my @row = $result->fetchrow; 		# get row, must do just once, otherwise if fails,
						# won't get to else of following if for the new
						# data condition
      my $logfile = "/home/postgres/public_html/cgi-bin/daniel/changes.log";
      open (LOG, ">>$logfile") or die "Cannot create $logfile : $!";	# open to write out
      my $date = &Jex::getPgDate();
      print "DATE : $date : DATE<BR>\n";
      print LOG "$date\t";
      if ($row[0]) { 				# if exists, UPDATE
						# must check on row[0], because row[1] could be NULL
						# in which case exists, but inserts new row
        if (($pg_value ne 'NULL') && ($pg_value ne ' ')) {		# if not null, put in the value
          $pg_value =~ s/\'/\\\'/g;
          $result = $conn->exec( "UPDATE $pg_table SET $pg_table = \'$pg_value\' WHERE joinkey = \'${type}${type_number}\';" ); 
          print LOG "\$result = \$conn->exec( \"UPDATE $pg_table SET $pg_table = \'$pg_value\' WHERE joinkey = \'${type}${type_number}\';\" ); <BR>\n";
        } else {				# if null, put in NULL
          $result = $conn->exec( "UPDATE $pg_table SET $pg_table = NULL WHERE joinkey = \'${type}${type_number}\';" ); 
          print LOG "\$result = \$conn->exec( \"UPDATE $pg_table SET $pg_table = NULL WHERE joinkey = \'${type}${type_number}\';\" ); <BR>\n";
        } # else # if ($pg_value ne 'NULL')
      } else { # if row[1] 			# if new value, INSERT
        if (($pg_value ne 'NULL') && ($pg_value ne ' ')) {		# if not null, put in the value
          $pg_value =~ s/\'/\\\'/g;
          $result = $conn->exec( "INSERT INTO $pg_table VALUES (\'${type}${type_number}\', \'$pg_value\') ;" ); 
          print LOG "\$result = \$conn->exec( \"INSERT INTO $pg_table VALUES (\'${type}${type_number}\', \'$pg_value\') ;\" ); <BR>\n";
        } else {				# if null, put in NULL
          $result = $conn->exec( "INSERT INTO $pg_table VALUES (\'${type}${type_number}\', NULL) ;" ); 
          print LOG "\$result = \$conn->exec( \"INSERT INTO $pg_table VALUES (\'${type}${type_number}\', NULL) ;\" ); <BR>\n";
        } # else # if ($pg_value ne 'NULL')
      } # else # if row[1] 
      close (LOG) or die "Cannot close $logfile : $!";			# close the write out

    } elsif ($query->param("bad_$pg_table") ) {	# if bad (not changed)
      $oop = $query->param("bad_$pg_table");
      my $pg_value = &Untaint($oop);
      print "<FONT COLOR=red>$pg_table : $pg_value</FONT><BR>\n";
    } else { 
      print "<FONT COLOR=blue>ERROR : $pg_table unaccounted for</FONT><BR>\n";
    } # if ($query->param("good_$pg_table") )
  } # foreach my $pg_table (@pg_ref_info_tables)
  $subject = "Changed $send_email fields of cgc number $type_number";
  if ( ($type eq 'cgc') && ($send_email) ) { &Mailer($user, $email, $subject, $body); }

  foreach my $pg_table (@pg_ref_copy_tables) {
    if ($query->param("good_$pg_table") ) {	# if good (changed)
      $oop = $query->param("good_$pg_table");
      my $pg_value = &Untaint($oop);
      print "<FONT COLOR=green>$pg_table : $pg_value</FONT><BR>\n";
      if ($pg_value eq 'NULL') { 
# CHANGE        # UPDATE $pg_table SET $pg_table IS NULL WHERE joinkey = \'$type_number\';
        my $result = $conn->exec( "UPDATE $pg_table SET $pg_table = NULL WHERE joinkey = \'${type}${type_number}\';" );
      } else { # if ($pg_value eq 'NULL')
# CHANGE        # UPDATE $pg_table SET $pg_table '1' WHERE joinkey = \'$type_number\';
        my $result = $conn->exec( "UPDATE $pg_table SET $pg_table = \'1\' WHERE joinkey = \'${type}${type_number}\';" );
      } # else # if ($pg_value eq 'NULL')
    } elsif ($query->param("bad_$pg_table") ) {	# if bad (not changed)
      $oop = $query->param("bad_$pg_table");
      my $pg_value = &Untaint($oop);
      print "<FONT COLOR=red>$pg_table : $pg_value</FONT><BR>\n";
    } else { 
      print "<FONT COLOR=blue>ERROR : $pg_table unaccounted for</FONT><BR>\n";
    } # if ($query->param("good_$pg_table") )
  } # foreach my $pg_table (@pg_ref_info_tables)
# CHANGE        # UPDATE ref_type SET ref_timestamp = CURRENT TIMESTAMP WHERE joinkey = \'$type_number\';
  my $result = $conn->exec( "UPDATE ref_$type SET ref_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'${type}${type_number}\';" );
} # sub confirmData

sub changeData {
  $firstflag = 0;
  my $oop; 
  my $type_number;
  my @pg_ref_info_tables = qw(ref_type ref_author ref_title ref_journal ref_pages ref_volume ref_year ref_abstract ref_comment);
  my @pg_ref_copy_tables = qw(ref_hardcopy ref_pdf ref_html ref_tif ref_tif_pdf ref_lib_pdf );
  print $color_key;
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi\">";
#   if ($query->param("val_ref_type") ) {		# if there's a value, get the value
#     $oop = $query->param("val_ref_type");
#     $type_number = &Untaint($oop);
#   } else { # if ($query->param("val_ref_type") )	# if no value use the old hidden value
#     $oop = $query->param("type_number");
#     $type_number = &Untaint($oop);
#   } # else # if ($query->param("val_ref_type") )
#   my $type = $type_number;

  if ($query->param("type_number") ) {		# if there's a value, get the value
    $oop = $query->param("type_number");
    $type_number = &Untaint($oop);
  } else { # if ($query->param("type_number") )	# if no value use the old hidden value
    $oop = $query->param("type_number");
    $type_number = &Untaint($oop);
  } # else # if ($query->param("type_number") )
  my $type = $type_number;
  $type =~ s/\d//g;
  $type_number =~ s/\D//g;
  print "TYPE : $type : NUMBER : $type_number<BR>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_number\" VALUE=\"$type_number\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"number_type\" VALUE=\"$type\">\n";
  foreach my $pg_table (@pg_ref_info_tables) {
    if ($query->param("che_$pg_table") ) {	# if checked (changed)
      unless ($query->param("val_$pg_table") ) {		# warn if no value
        print "<FONT COLOR=blue>Warning : No value (checked) will be sent : $pg_table</FONT><BR>\n";
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"good_$pg_table\" VALUE=\"NULL\">\n";
      } else { # unless ($query->param("val_$pg_table") )	# get value if value
        $oop = $query->param("val_$pg_table");
        $oop =~ s/\"/TAG_QUOTE/g;		# account for double quotes
        my $pg_value = &Untaint($oop);
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"good_$pg_table\" VALUE=\"$pg_value\">\n";
        $pg_value =~ s/TAG_QUOTE/\"/g;		# account for double quotes
        print "<FONT COLOR=green>$pg_table : $pg_value</FONT><BR>\n";
      } # else # unless ($query->param("val_$pg_table") )
    } else { # if ($query->param("che_$pg_table") )
      unless ($query->param("val_$pg_table") ) {		# warn if no value
        print "<FONT COLOR=blue>Warning : No value (unchecked) : $pg_table</FONT><BR>\n";
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"bad_$pg_table\" VALUE=\"NULL\">\n";
      } else { # unless ($query->param("val_$pg_table") )	# get value if value
        $oop = $query->param("val_$pg_table");
        my $pg_value = &Untaint($oop);
        print "<FONT COLOR=red>$pg_table : $pg_value</FONT><BR>\n";
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"bad_$pg_table\" VALUE=\"$pg_value\">\n";
      } # else # unless ($query->param("val_$pg_table") )
    } # else # if ($query->param("che_$pg_table") )
  } # foreach my $pg_table (@pg_ref_info_tables)
  foreach my $pg_table (@pg_ref_copy_tables) {
    my ($checked, $default, $changed) = (0, 0, 0);
    if ($query->param("che_$pg_table") ) { $checked = 1; } 	# check if checked 
    if ($query->param("def_$pg_table") ) { $default = 1; }	# check if was default
    if ($default == $checked) { $changed = 0; } else { $changed = 1; }	# check if changed
    if ($changed) { 				# new value
      print "<FONT COLOR=green>$pg_table : changed to ";
      if ($checked) { print "HAVE "; } else { print "NO "; $checked = 'NULL'; }
      print "Copy</FONT><BR>\n";
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"good_$pg_table\" VALUE=\"$checked\">\n";
    } else { # if ($changed)			# no change
      print "<FONT COLOR=red>$pg_table : not changed, remains ";
      if ($checked) { print "HAVE "; } else { print "NO "; $checked = 'NULL';}
      print "Copy</FONT><BR>\n";
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"bad_$pg_table\" VALUE=\"$checked\">\n";
    } # else # if ($changed)
  } # foreach my $pg_table (@pg_ref_copy_tables)
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Confirm !\">\n";
  print "</FORM>\n";
} # sub changeData

sub editData {
  $firstflag = 0;
  unless ($query->param("type_number") ) { 
    print "<FONT COLOR=blue>ERROR : No type number</FONT><BR>\n";
  } else { # unless ($query->param("type_number") )
    my $oop = $query->param("type_number"); 
    my $type_number = &Untaint($oop);
    print "TYPE NUMBER : $type_number<BR>\n";
    my $type = $type_number;
    $type =~ s/\d//g;
    print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi\">";
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_number\" VALUE=\"$type_number\">\n";
    print "<TABLE border = 1 cellspacing = 2>\n";

      # ref and timestamp
    my $result = $conn->exec( "SELECT * FROM ref_$type WHERE joinkey = \'$type_number\';" );
    my @row = $result->fetchrow;
    print "<TR><TD>ref_timestamp</TD><TD>&nbsp;</TD><TD>$row[2]</TD></TR>\n";
    print "<TR><TD>ref_$type</TD><TD><INPUT NAME=\"che_ref_type\" TYPE=\"checkbox\" VALUE=\"yes\">";
    print "</TD><TD><INPUT NAME=\"val_ref_type\" VALUE=\"$row[1]\" SIZE=70></TD></TR>\n";

      # general info
    my @pg_ref_info_tables = qw(ref_author ref_title ref_journal ref_pages ref_volume ref_year ref_comment);
    foreach my $pg_table (@pg_ref_info_tables) {
      print "<TR><TD>$pg_table</TD><TD><INPUT NAME=\"che_$pg_table\" TYPE=\"checkbox\" ";
      print "VALUE=\"yes\"></TD><TD><INPUT NAME=\"val_$pg_table\" VALUE=\"";
      $result = $conn->exec( "SELECT * FROM $pg_table WHERE joinkey = \'$type_number\';" );
      while (my @row = $result->fetchrow) {
        if ($row[1]) { $row[1] =~ s/\"/&quot;/g; print $row[1]; } else { print "&nbsp;"; }	
					# print data or space (sub for double quotes)
      } # while (my @row = $result->fetchrow)
      print "\" SIZE=70></TD></TR>\n";
    } # foreach my $pg_table (@pg_ref_info_tables)

      # abstract
    $result = $conn->exec( "SELECT * FROM ref_abstract WHERE joinkey = \'$type_number\';" );
    @row = $result->fetchrow;
    print "<TR><TD>ref_abstract</TD><TD><INPUT NAME=\"che_ref_abstract\" TYPE=\"checkbox\" ";
    print "VALUE=\"yes\"></TD><TD><TEXTAREA NAME=\"val_ref_abstract\" ROWS=10 COLS=70>";
    unless ($row[1]) { print "";	# print nothing, want NULL
    } else { 				# if data
      my $newword; my $i = 0;		# prepare new word and counter for newlines
      my @chars = split //, $row[1];	# split into characters
      while (scalar(@chars) > 0) {	# while there are characters unaccounted for
        $_ = shift @chars;		# get the character
        $i++; $newword .= $_;		# up the counter, append to new word
        if (($i > 70) && ($_ eq ' ')) { $i = 0; $newword .= "\n"; }
					# if more than 70 characters and a
					# space, reset counter and add a newline
      } # while (@chars)		# until all characters are accounted
      $newword =~ s/</&lt;/g; $newword =~ s/>/&rt;/g;
      print $newword;			# output the value
    } # else # unless ($row[1]) 
    print "</TEXTAREA></TD></TR>\n";	# close textarea

      # paper status
    my @pg_ref_copy_tables = qw(ref_hardcopy ref_pdf ref_html ref_tif ref_tif_pdf ref_lib_pdf );
    foreach my $pg_table (@pg_ref_copy_tables) {
      $result = $conn->exec( "SELECT * FROM $pg_table WHERE joinkey = \'$type_number\';" );
      while (my @row = $result->fetchrow) {
        print "<TR><TD>$pg_table</TD><TD>";
        print "<INPUT NAME=\"che_$pg_table\" TYPE=\"checkbox\" VALUE=\"yes\" ";
        if ($row[1]) { print "CHECKED "; } else { print ""; }	# print checked or don't
        print "></TD><TD>&nbsp;</TD></TR>\n";
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"def_$pg_table\" VALUE=\"";
        if ($row[1]) { print "yes"; } else { }	# pass default value if there was a copy
        print "\">\n";
      } # while (my @row = $result->fetchrow)
    } # foreach my $pg_table (@pg_ref_copy_tables)
      # paper comment (not a checkbox, so separate)
   
    print "</TABLE>\n";
    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Change !\">\n";
    print "</FORM>\n";
  } # else # unless ($query->param("type_number") )
} # sub editData

sub ProcessTable {
	# Take in pgcommand from hidden field or from Pg ! button
	# Take in page number from Page ! button or 1 as default
	# Process sql query 
	# Output number of results as well as sql query
	# output page selector as well as selected page results
  my $page = shift; my $pgcommand = shift; my $action = shift;

    # process with this form, select new page, pass hidden values.
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi\">";

      # if new sorting button (not page) get new command
  if ($action) {
    if ($action eq 'Date !') { $pgcommand = $date_pgcommand; }
    if ($action eq 'Number !') { $pgcommand = $cgc_pgcommand; }
    if ($action eq 'Journal !') { $pgcommand = $journal_pgcommand; }
    if ($action eq 'Hardcopy !') { $pgcommand = $hardcopy_pgcommand; }
    if ($action eq 'Pdf !') { $pgcommand = $pdf_pgcommand; }
    if ($action eq 'No Pdf !') { $pgcommand = $nopdf_pgcommand; }
    if ($action eq 'Html !') { $pgcommand = $html_pgcommand; }
    if ($action eq 'Tif !') { $pgcommand = $tif_pgcommand; }
    if ($action eq 'Tif_Pdf !') { $pgcommand = $tif_pdf_pgcommand; }
    if ($action eq 'Lib_Pdf !') { $pgcommand = $lib_pdf_pgcommand; }
#     if ($action eq 'Lib !') { $pgcommand = $lib_pgcommand; }
    if ($action eq 'No Record !') { $pgcommand = $none_pgcommand; }

    my $oop;
    if ( ($action eq 'Page !') || ($action eq 'Date !') || ($action eq 'Number !') ||
         ($action eq 'Journal !') || ($action eq 'Hardcopy !') || ($action eq 'Pdf !') ||
         ($action eq 'Html !') || ($action eq 'Tif !') ) { # || ($action eq 'Lib !') )
      if ( $query->param("number_type") ) { $oop = $query->param("number_type"); } else { $oop = "cgc"; }
      my $number_type = &Untaint($oop);
      $pgcommand =~ s/cgc/$number_type/g;
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"number_type\" VALUE=\"$number_type\">\n";
    }

    if ($action eq 'Cgc !') { 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"number_type\" VALUE=\"cgc\">\n";
      $pgcommand = $default_pgcommand; 
    }
    if ($action eq 'Pmid !') { 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"number_type\" VALUE=\"pmid\">\n";
      $pgcommand = $pmid_pgcommand; 
    }
    if ($action eq 'Med !') { 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"number_type\" VALUE=\"med\">\n";
      $pgcommand = $med_pgcommand; 
    }
    if ($action eq 'Agp !') { 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"number_type\" VALUE=\"agp\">\n";
      $pgcommand = $agp_pgcommand; 
    }
  } # if ($action)

    my $result = $conn->exec( "$pgcommand" ); 
    my @row;
    @RowOfRow = ();
    while (@row = $result->fetchrow) {	# loop through all rows returned
      push @RowOfRow, [@row];
    } # while (@row = $result->fetchrow) 

      # show amount of results and compute page things
    print "There are " . ($#RowOfRow+1) . " results to \"$pgcommand\".<BR>\n";
    my $remainder = ($#RowOfRow + 1) % $MaxEntries;
    my $high_number = ($#RowOfRow + 1) - $remainder;
    my $divided_number = $high_number / $MaxEntries;
    my $number_of_pages = $divided_number + 1;
    my $entries_to_show = $MaxEntries;
    my $total_entries = $#RowOfRow + 1;
#     print "entries_to_show : $entries_to_show<BR>\n";
#     print "PAGE : $page : MAX : $MaxEntries<BR>\n";
#     print "Total Entries : $total_entries<BR>\n";
#     print "Remainder : $remainder<BR>\n";
    if ($page eq $number_of_pages) { 
#       print "LAST PAGE<BR>\n"; 
      $entries_to_show = $remainder;
#       print "entries_to_show changed : $entries_to_show<BR>\n";
    }
    my $first_entry = (($page-1)*$MaxEntries);
    my $last_entry = $first_entry + $entries_to_show - 1;
#     print "First Entry : $first_entry<BR>\n";
#     print "Last Entry : $last_entry<BR>\n";


    print "<INPUT TYPE=\"HIDDEN\" NAME=\"entries_page\" VALUE=\"$MaxEntries\">\n";
                                # pass entries_page value in hidden field
    print "<TABLE>\n";
    print "<TD>Select your page of $number_of_pages : </TD><TD><SELECT NAME=\"page\" SIZE=5> \n"; 
    for my $k ( 1 .. $number_of_pages ) {
      print "<OPTION>$k</OPTION>\n";
    } # for my $k ( 1 .. $number_of_pages ) 
    print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Page !\"></TD>";
    print "</TR>\n<TR>";
    print "<TD Align=right>Sort : </TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Date !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Number !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Journal !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Hardcopy !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pdf !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"No Pdf !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Html !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Tif !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Tif_Pdf !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Lib_Pdf !\"></TD>";
#     print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Lib !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"No Record !\"></TD></TR>";

    print "<TR>";
    print "<TD Align=right>Type : </TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Cgc !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Pmid !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Med !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Agp !\"></TD></TR>";

    print "<TR><TD></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Search !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count HC !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count PDF !\"></TD>";
#     print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count Lib !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count Html !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count Tif !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count Tif_Pdf !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Count Lib_Pdf !\"></TD>";
    print "</TR>\n<TR><TD></TD><TD></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"PDF no HC !\"></TD>";
#     print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Lib no HC !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Html no HC !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Tif no HC !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Tif_Pdf no HC !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Lib_Pdf no HC !\"></TD>";
    print "<TD Align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"HC Only !\"></TD></TR>";
  
    print "<BR><BR>\n";
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
    if (($pgcommand =~ $test_pgcommand) || ($pgcommand eq $none_pgcommand)) { print "<TR><TD ALIGN=CENTER>joinkey</TD><TD ALIGN=CENTER>journal</TD><TD ALIGN=CENTER>hardcopy</TD><TD ALIGN=CENTER>pdf</TD><TD ALIGN=CENTER>html</TD><TD ALIGN=CENTER>tif</TD><TD ALIGN=CENTER>tif_pdf</TD><TD ALIGN=CENTER>lib_pdf</TD><TD ALIGN=CENTER>comment</TD><TD ALIGN=CENTER>curate</TD></TR>\n"; }
				# show headers if default

    for my $i ( $first_entry .. $last_entry ) {
				# for the amount of entries chosen in the chosen page
      print "<TR>";
      print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi\">";
      my $row = $RowOfRow[$i];
      my $type_number = $row->[0];	# get type_number 
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"type_number\" VALUE=\"$type_number\">\n";
				# pass cgc (joinkey) as hidden to html
#       $cgc =~ s/cgc//;		# get cgc number
      $entries_to_show = $#{$row};	# initialize number of entries to show
      for my $j ( 0 .. $#{$row} ) {
        unless ($row->[$j]) { 
#         unless ( ($row->[$j]) || ($j == 2) ) 
				# if nothing there, print a space
          print "<TD>&nbsp;</TD>\n"; 
        } else { 		# if something there
#           unless ( ($pgcommand eq $default_pgcommand) && ($j == 3) ) {
                                # unless it's a pdf
            print "<TD ALIGN=CENTER>$row->[$j]</TD>\n";
#           } else {              # if it's a pdf, print a link
#             my $pdfexists = 0;
#             foreach my $pdffile (@pdffiles) {
#                                 # find the pdf that matches the joinkey
#               $pdffile =~ m/^\/home3\/allpdfs\/((\d+).*)$/; 	# get the pdf filename
#               if ($2 eq $cgc) { 				# exact number matches only
#                 print "<TD><A HREF=\"http://tazendra.caltech.edu/~azurebrd/allpdfs/$1\">$1</A></TD>\n" ;
# 								# print the link
#                 print "<INPUT TYPE=\"HIDDEN\" NAME=\"pdf_name\" VALUE=\"$1\">\n";
#                 $pdfexists = 1;	# pass pdf value in hidden field
#               } # if ($pdffile =~ m/^$cgc\w+/)
#             } # foreach my $pdffile (@pdffiles)
#             unless ($pdfexists) { print "<TD>&nbsp;</TD>\n"; }
#           } # else # unless ( ($pgcommand eq $default_pgcommand) && ($j == 2) )
        } # else # unless ($row->[$j]) 
      } # for my $j ( 0 .. $#{$row} ) 
      print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Edit !\"></TD>\n";
				# show button to ``Edit !''
      print "</FORM>\n";	# close each form
      print "</TR>\n";		# new table row
    } # for my $i ( 0 .. $#RowOfRow ) 

    if (($pgcommand =~ $test_pgcommand) || ($pgcommand eq $none_pgcommand)) { print "<TR><TD ALIGN=CENTER>joinkey</TD><TD ALIGN=CENTER>journal</TD><TD ALIGN=CENTER>hardcopy</TD><TD ALIGN=CENTER>pdf</TD><TD ALIGN=CENTER>html</TD><TD ALIGN=CENTER>tif</TD><TD ALIGN=CENTER>tif_pdf</TD><TD ALIGN=CENTER>lib_pdf</TD><TD ALIGN=CENTER>comment</TD><TD ALIGN=CENTER>curate</TD></TR>\n"; }
    print "</TABLE><BR>\n";		# close table
    print "PAGE : $page<BR>\n";	# show page number again
    print "</CENTER>\n";
} # sub ProcessTable 

sub ShowPgQuery {		# textarea box to make pgsql queries
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
} # sub ShowPgQuery

sub Mailer {            # send non-attachment mail
  my ($user, $email, $subject, $body) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => $user,
                  To      => $email,
#                 Cc      => 'curationmail@tazendra.caltech.edu, $user',
                  Subject => $subject,
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
} # sub Mailer



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
<CENTER>Documentation <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/endnoter_doc.txt" TARGET=NEW>here</A></CENTER><P>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 


# DEPRECATED 

sub PrintFormOpen {		# open form link to appropriate curation_name.cgi 
				# depending on the curator
# print "EDIT PrintFormOpen<BR>\n";
#   if ($curator eq 'Wen Chen') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_wen.cgi\">";
#   } elsif ($curator eq 'Raymond Lee') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_raymond.cgi\">";
#   } elsif ($curator eq 'Andrei Petcherski') {
#     print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_andrei.cgi\">";
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

