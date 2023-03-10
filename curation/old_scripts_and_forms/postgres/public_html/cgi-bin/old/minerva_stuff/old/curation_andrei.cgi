#!/usr/bin/perl -w

# Curation form.
#
# Buttons / Fields :
# 
# Site Map : Link to Site Map for ~postgres/cgi-bin/ on minerva.
# 
# Documentation : Link to this CGI which outputs the documentation at the top of
# the curation_azurebrd.cgi.
#
# General Public ID number : The cgc, pmid, or med number which relates to the
# postgreSQL and endnote entry.  This is used as the joinkey for the postgreSQL
# tables, as well, as for querying the postgreSQL tables for the
# endnote-generated Reference Information.
#
# Query ! : Takes in the value entered in the General Public ID number field,
# and queries postgreSQL for the relevant Reference info which is based on
# endnote entries, as well as previously entered information for updating.  This
# automatically checks off the Mailing Checkbox, since presumably this is an
# updating function which will only change some data, not all data.
# 
# PDF file name : The name of the PDF in /home3/allpdfs/  The curation form
# checks to see if this is a value PDF and warns if not found (After clicking 
# ``Go !'' at the bottom of the form.)
#
# Curator : The name of the curator, which is different based on which cgi is
# being used.  This is the value that gets entered into postgreSQL tables, as
# well as for checking if something has been curated (though any other table
# could also be used). 
#
# Reference : User entered, or queried from the ``Query !'' button, or
# automatically filled in if arrived here from allpdfs.cgi or checkout.cgi
#
# ``Go Big !'', ``Teenify !'', ``Defaultify !'' : Save the state of
# curationform, and change the html loaded (Presumably with different TEXTAREA
# values)
#
# First Checkbox : Enter only the words ``yes'' for that field.
#
# Textarea : Enter whatever you would like to enter for that field.
#
# Second Checkbox (if exists) : Mail to the address following it if checked, do
# not mail if not checked.  Default checked for first pass, default unchecked if
# ``Query !'', maintains state from ``Load !'' and resizing.
#
# ``Go !'' : Go to preview page, which shows the date, color key, warning if pdf
# does not exist, all data entered in fields, and the ``New Entry !'' or
# ``Update !'' button as appropriate.
#
# ``Save !'' : Save current state of form.  Note, resizing updates the saved
# state.
#
# ``Load !'' : Load last saved state of form.  Note, resizing updates the saved
# state.
#
# ``Reset !'' : Set all textarea values to blank, first checkboxes to unchecked,
# second checkboxes to checked, Curator to curator named in cgi name.
# 
# ``New Entry !'' : Same as ``Go !'', but also adds a new entry to postgreSQL,
# mails to appropriate fields, and shows a ``Pg !'' query option.
#
# ``Update !'' : Same as ``New Entry !'', but updates the already entered
# postgreSQL entry.
#
# ``Pg !'' : Make a postgreSQL query, and return the value.
#
# <HR> Logic :
#
# UPDATEcgis.pl is used to update the cgis, making a copy of
# curation_azurebrd.cgi onto curation_bak.cgi.time, and changing appropriate
# mailing fields as well as $user and $User.
#
# HTML::Template is used to allow different curators to have different HTML
# forms, for ease of customization.
#
# Pg is used to open a connection to the postgreSQL database.
# 
# Mail::Mailer is used to mail each textarea field as appropriate to the address
# shown on the form, and cc to curationform@minerva.caltech.edu and the
# curator's email address.
#
# MIME::Lite is used to mail attachments to the non-caltech-wormbase addresses
# if the pdf exists, and at any point any of the fields with their address had 
# data and was submitted.
#
# $user is defined to be the mail addresses for sending, the value for calling 
# the cgi, and saving data
#
# $User is defined to be the Curator field and part of the HTML title.
#
# files are defined to save data and call up html files.
#
# email addresses are defined for mailing.
#
# flags are defined to display the form, check the mail buttons (second
# checkboxes), load the saved value (for resizing), and mail the attachments.
#
# @HTMLparameters and @PGparameters are defined.  A subroutine converts between
# values.
#
# @HTMLparamvalues and @PGparamvalues are generated to contain the values of
# above.  A subroutine converts between values.
#
# @PGparammail states whom to mail stuff to.
#
# @PGparamsubjects contains the subject headings for the emails.
#
# @PGparammailcheckvalues is generated to see if second checkboxes checked to
# mail.
#
# @Flags contains which html_file to use, as well as future flags.
#
# %variables has data for html_files using the various arrays above.
#
# &ResetForDisplay() is called, restoring default values.
#
# &PrintHeader() is called, printing form headers.
#
# &Process() is called (See Processing)
#
# &DisplayFrom() is called checking flag values to display the form or not, and
# what values to pass to it.
#
# &PrintFooter() is called to close the html.
#
# <HR> Processing :
#
# Check which button was pressed.  
#
# Curate ! : Coming from allpdfs.cgi or checkout.cgi : Get the public ID and
# populate the Reference field using postgreSQL data.
#
# Query ! : Get the public ID and populate the Reference field using postgreSQL
# data, and the previously entered data if available.
#
# Load ! : Open the saved file, parse it, populate the %variables, set flag to
# keep the values.
#
# Pg ! : Check if it's valid command.  If SELECT, display data in a table.  If
# not, process and state that it has been processed.
#
# Go ! : Show date and color key.  Get the values from the form, convert to Pg
# format.  Check if new entry by public ID looking at postgreSQL tables.  Show
# entered data and appropriate button (New Entry ! or Update !)
#
# Save ! : Show date and color key.  Get the values from the form, convert to Pg
# format.  Parse, write to save file, show link to save file.  
#
# New Entry ! and Update ! : Show date and color key.  Get Pg values, checkbox
# values, and flag values.  Check if the attachment file exists, and display
# warning if not.  Show values entered, mail to appropriate if checkbox was
# checked, field has someone to mail to.  For each field, mail to the address 
# in the field, cc to the curator, and curatormail@minerva; if not from caltech, 
# flag to mail attachment.  Mail the attachment if flagged.  Enter data to
# various postgreSQL tables with pubID as joinkey between tables, as well as 
# testcuration3 table with all data.  Show Pg ! query for user.
#
# Go Big ! Defaultify ! and Teenify ! : Get the values from the form, convert to
# Pg values.  Set appropriate html file, save data, set flag to load data while
# displaying the form.
#
# Reset ! : Set all %variables to blank, curator to $User.
#
# <HR> Original Documentation and Changes :
# 
# To use this, fill out the form, and specify a PDF file name (any extension
# will be replaced with .pdf).  If it is not a proper filename (i.e. mutt
# doesn't work because it can't find the attachment file) a MUTT ERROR warning
# is printed out.
#
# The following characters are allowed on the form, the rest are stripped out.
# -.,;:?/\@#$%^&*(){}[]+=!~|'_ and all letters and digits.  (" stripped out
# because they may affect .ace files; if you'd like this feature removed, add a
# " between the [] in the $tainted regex match in the &Untaint subroutine.
#
# To send email to multiple recepients, change the variable to have as many
# addresses as you'd like separated by a single space (all between the single
# quotes).  Alternatively at the end of the &MuttMail subroutine, there are two
# lines commented out that could be uncommented to make a second system call to
# mutt to email the same content to the address defined on the line above it,
# but without the attachment.
# 
# Information is saved in tab-delimited format in a single line of the save_file.  
# Tabs are replaced with the text ``TABREPLACEMENT'' which is then replaced when
# loading.
#
# To use this : 
# Replace the current email addresses with the commented out ones
# in the # emails section.
# Replace the $attachment_path with the proper path to the pdf directory
#
#
# Request : Query pgsql for cgc# entry.  Update button.  --  Erich 2001-11-16
#	DONE 2001-11-26
# Request : Button for each field to save data, load page with huge textarea
# box, button there to add entry to save, load data into original CGI 
# page.  --  Erich 2001-11-16
# 	DONE 2001-12-08
#
# Fixed Reset Button 2001-11-01
#
# Fixed Checkboxes relation to text fields, still don't load state.  2001-11-01
# PG and HTML parameters and paramvalues now separate.  2001-11-01
# Pg !  Shows spaces on empty table entry (i.e. dividers)  Proper labels on top 
# and bottom.  2001-11-01
#
# Mail with bad or no PDFs.  A mutt error is noticed and mail is sent again
# without an attachment.  2001-11-08
#
# allpdfs.cgi written to pass on pdf_name to curator form.  ``Curate !''
# $action written to account for pdf_name, get cgc number, and query pgsql with
# cgc number as join_key for reference info.  2001-11-08
# checkout.cgi written to pass reference info to curator form while choosing
# by cgc (or rather, reference info) .  ``Curate !'' edited to allow cgc_number
# to key off of to get reference info from pgsql.  2001-11-14
# &AddToPg() changed to allow entry from each field into a separate pgsql table
# (except for reference, which should be coming from pgsql tables, and pubID
# which is the joinkey).  2001-11-16
#
# Query !  by joinkey (cgc#)  2001-11-26
#
# Mailer rewritten using &MimeMail();, with MIME::Lite and Mail::Mailer.  No
# more stupid system calls !  2001-12-04
#
# Changed postgreSQL indexes to be UNIQUE.  Updated CGI to &FindIfPgEntry() to
# see if there's an entry.  If there is an entry, ``Query !''loads or fails and
# says so.  If there's an entry, ``Go !'' shows the ``Update !'' button,
# otherwise the ``New Entry !'' button.  &DealPg() does the same thing for both
# buttons, checking &FindIfPgEntry(), and calling &UpdatePg(); or &AddToPg();
# (rewritten to just add to Pg)  2001-12-04
#
# Changed HTML to add Mail buttons.  Default checked by $to_mail = 1;.  Upon
# &DisplayForm(), &CheckMailButtons(); is called, setting %variables with key
# check_mail_$PGparameters[$_] (for those with valid $PGparammail[$_] values) 
# to ``checked'' or ``'' depending on the $to_mail flag.  &Preview(); and
# &OutputAndMail(); somewhat merged with &OutputEntered($state); which prints
# whether it will be mailed or not; and passes hidden values, if $state eq
# 'preview'; and calls &MimeMail(); if appropriate, if $state eq 'real'.  
# ``Go !'', ``Save !'', ``New Entry !'', and ``Update !''
# &QueryDataMailToCheck(); for data related to mail checkboxes.  2001-12-08
#
# Changed HTML to add ``Go Big !'' and ``Teenify !'' buttons, to toggle to
# larger and smaller html pages (also created them) as well as a 
# ``Defaultify !'' button to go back to the default page.  The form passes a
# hidden input flag which tells which html template to use.  @Flags and
# @Flagsvalues created to store this and future flags.  Upon clicking one of the
# new buttons, the data is saved, a flag ($load_saved) is set to load saved
# data, and when the page is displayed, the saved data is shown.  2001-12-08
# 
# Changed Mail logic to Mail everything even if just ``yes''  2001-12-10
#
# Added $attach option 2 for $rec_wormerich emailing with pdf to worm, and
# without to erich.  Added mail checkboxes to html for missing fields.
# 2001-12-11
#
# Possibly broke it by deleting a bunch of text.  Tried to fix it, hope I did.
# 2001-12-12
#
# Changed &MimeMail(); to use Mailer to mail everyone, and then set a flag to
# mail to $rec_cgc, $rec_worm, $rec_syl.  Changed &Mailer(); to have a Cc field
# to mail to $ccemail.  Changed &OutputEntered(); to check the flag and send 
# attachment mail if pdf attachment exists to appropriate address.  Added 
# curationmail user as a repository for mail sent out (minus attachments).
# Updated UPDATEcgis.pl to also update these mail features.  2001-12-14
#
# Wrote curationform_doc.cgi, which reads this file, and matches
# /^#!.*?\n\n#\s*(.*?\n\n\n)/s so will print stuff between first blank line to
# second blank line)  2001-12-16(?)
#
# Updated according to Keith to email Allele info to Jonathan Hodgkin instead of
# to Keith or CGC (so changed the value of rec_syl and the flags on mailing to
# syl).  Updated to not send attachments by default at all (deleted the part
# that changed the counter that was checked to mail attachments to people)
# 2002-01-21
#
# Updated checkout.cgi, made new tables (ref_ ) to replace the old tables (which
# lacked timestamps).  Changed the Curate ! action to UPDATE the proper (ref_ )
# tables.  2002-01-29
#
# Updated &AddToPg(); &UpdatePg(); &CuratePopulate(); &PopulateReference(); and
# &PopulateNonReference(); to work with the cur_ and ref_ tables with timestamps
# instead of the old tables.  Updated postgreSQL database and dropped old
# tables.  Update the _html_file's to keep the txt files in a different
# curation_docs/ directory to neatness.  2002-02-02
#
# Updated &OutputEntered to email John Spieth a PDF if $johnmail is flagged to 
# do so.  Updated &MimeMail to check PGparamsubject[$array_val] to see if it's
# one of those he wants to be mailed a PDF for.  Added $rec_john to have his 
# email address.  Update UPDATEcgis.pl to account for new email address.  
# 2002-02-25
#
# Created &populateXref(); for checking potential alternate (if cgc, pmid; if 
# pmid, cgc).  Updated &Process() to check if pubID $found, and if not, to
# run &populateXref(); to look and use alternate pubID.  2002-05-03
#
# Update to work with new html for new fields, and different kind of fields.
# 2002 06 17
#
# Updated to &OutputEntered(); to (if $state eq 'real') open the data_file and
# append the data that goes to the screen.  2002 07 02
#
# Updated &PopulateNonReference(); to include the new fields added on 2002 06 17
# (genesymbol [as opposed to genesymbols], site, structurecorrectionsanger, and
# structurecorrectionstlouis) because they weren't appearing on queries.  Fixed
# postgres for those fields because they were missing a UNIQUE idx (sanger and 
# stlouis got a truncated idx to _i and _ respectively).  Added new Full Author 
# Names field.  2002 07 14
#
# Added new covalent modification field (cur_covalent) 2002 07 15
#
# Fixed &HtmlToPg(); Being misaligned due to new fields  2002 07 17
#
# To FIX : Insecure $ENV{PATH} while running with -T switch at
# /usr/lib/perl5/site_perl/5.6.1/MIME/Lite.pm line 2550.



use strict;
use CGI;
use Fcntl;
use HTML::Template;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use MIME::Lite;
use Mail::Mailer;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";


# files
my $user = 'andrei';
my $User = 'Andrei Petcherski';
my $data_file = "/home/postgres/public_html/cgi-bin/data/curation_data_$user.txt";
my $save_file = "/home/postgres/public_html/cgi-bin/data/curation_save_$user.txt";
my $default_html_file = "/home/postgres/public_html/cgi-bin/curation_docs/curation_html_$user.txt";
my $big_html_file = "/home/postgres/public_html/cgi-bin/curation_docs/curation_html_big_${user}.txt";
my $tiny_html_file = "/home/postgres/public_html/cgi-bin/curation_docs/curation_html_tiny_${user}.txt";
my $html_file = $default_html_file;
  # set this to the path of the folder with the pdf files
my $attachment_path = '/home3/allpdfs/';

# emails
# my $raymond = 'azurebrd@minerva.caltech.edu';
# my $erich = 'azurebrd@minerva.caltech.edu';
# my $raneri = 'azurebrd@minerva.caltech.edu';
# my $wen = 'azurebrd@minerva.caltech.edu';
# my $rec_cgc = 'azurebrd@minerva.caltech.edu';
# my $rec_worm = 'azurebrd@minerva.caltech.edu';
# my $rec_wormerich = 'azurebrd@minerva.caltech.edu';
# my $rec_syl = 'azurebrd@minerva.caltech.edu';
# my $rec_john = 'azurebrd@minerva.caltech.edu';
# my $ccemail = '';
my $raymond = 'raymond@its.caltech.edu';
my $erich = 'emsch@its.caltech.edu';
my $raneri = 'ranjana@eysturoy.caltech.edu, emsch@its.caltech.edu';
my $wen = 'wchen@its.caltech.edu';
my $rec_cgc = 'cgc@wormbase.org';
my $rec_worm = 'worm@sanger.ac.uk';
my $rec_wormerich = 'worm@sanger.ac.uk, emsch@its.caltech.edu';
my $rec_syl = 'jonathan.hodgkin@bioch.ox.ac.uk';
my $rec_john = 'jspieth@watson.wustl.edu';
my $ccemail = 'curationmail@minerva.caltech.edu';

# flags
our $displayform = 1;	# display the html form by default
our $to_mail = 1;	# check the mail buttons by default
our $load_saved = 0;	# don't load the saved file by default

our $recmail = 0;	# don't mail attachment to rec_cgc by default
our $wormmail = 0;	# don't mail attachment to rec_worm by default
our $sylmail = 0;	# don't mail attachment to sylvia by default
our $johnmail = 0;	# don't mail attachment to john by default

# vars
my $pubID = "";
my $reference = "lala";
my @PGparameters = qw(pubID pdffilename curator reference fullauthorname 	
                        genesymbol mappingdata genefunction 			
			expression rnai transgene overexpression mosaic 	
			site antibody covalent extractedallelenew newmutant 	
			sequencechange genesymbols geneproduct 			
			structurecorrectionsanger structurecorrectionstlouis 	
			sequencefeatures cellname cellfunction ablationdata 	
			newsnp stlouissnp goodphoto comment);			
my @HTMLparameters = qw(pubID pdffilename curator reference fullauthorname 	
                        genesymbol1 genesymbol2 mappingdata1 mappingdata2 	
			genefunction1 genefunction2 expression1 expression2	
			rnai1 rnai2 transgene1 transgene2 			
			overexpression1	overexpression2 mosaic1 mosaic2 	
			site1 site2 antibody1 antibody2 covalent1 covalent2	
			extractedallele3 extractedallele4			
			newmutant1 newmutant2 sequencechange1 sequencechange2 	
			genesymbols1 genesymbols2 geneproduct1 geneproduct2 	
			structurecorrection1 structurecorrection2		
			structurecorrection3 structurecorrection4		
			sequencefeatures1 sequencefeatures2 cellname1 cellname2	
			cellfunction1 cellfunction2 ablationdata1 ablationdata2	
			newsnp1 newsnp2 stlouissnp1 stlouissnp2 goodphoto	
			comment);						
my @PGparamvalues;
my @HTMLparamvalues;
  # values to determine whom which fields go to
my @PGparammail = qw(0 0 0 0 0
			rec rec raneri 
			wen ray wen erich ray 
			ray 0 0 ray erich 
			0 erich erich 
			worm worm 
			wormerich ray ray ray 
			0 0 0 0);
my @PGparamsubjects = ("", "", "", "", "",
			"Gene Symbol", "Gene Mapping Data", "Gene Function", 
			"Gene Expression", "RNAi", "Transgene", "Overexpression", "Mosaic", 
			"Site of Action", "", "", "Allele Extracted", "New Mutant",
			"Allele Sequence Changed", "Gene Symbols", "Gene Product Interaction", 
			"Gene Structure Correction : Sanger", "Gene Structure Correction : St. Louis",
			"Sequence Features", "Cell Name", "Cell Function", "Ablation Data",
			"", "", "", "");
my @PGparammailcheckvalues;	# values generated corresponding to values from
				# @PGparammail that have been checked (looking
				# at the value of mail_@PGparameter from the HTML
my @Flags = qw( html_file );	# array of flags, currently just which html_file to load
my @Flagsvalues = ( "$html_file" );
				# default value
my %variables;
my %cgcHash;			# xref hash of alternative paper
my %pmHash;			# xref hash of alternative paper

&ResetForDisplay();		# Clear all Variables for HTML
&PrintHeader();			# print the HTML header
&Process();			# Essentially do everything
&DisplayForm();			# print the rest of the form
&PrintFooter();			# print the HTML footer

sub ResetForDisplay {
  foreach $_ (@HTMLparameters) {
    $variables{$_} = "";		# populate variables
  } # foreach $_ (@HTMLparameters)
  $variables{curator} = "$User";	# assign curator name
} # sub ResetForDisplay 

sub DisplayForm {
  if ($displayform) {	# display the form if flag set to (not zero)
    &CheckMailButtons();	# look whether to set html mail checkboxes to checked
    &CheckFlags();		# put flag related stuff into %variables for $template
    if ($load_saved) { &LoadState(); }
    				# load the saved data (only for resizing)
    my $template = HTML::Template->new(filename => "$html_file", die_on_bad_params => 0);
    $template->param(\%variables);
    print $template->output();
  }
} # sub DisplayFrom 

sub CheckFlags {		# put flag related stuff into %variables for $template
  for (0 .. scalar(@Flags)-1 ) {
    $variables{$Flags[$_]} = $Flagsvalues[$_];
  } # for (0 .. scalar(@Flagsvalues)-1 ) 
} # sub CheckFlags 

sub CheckMailButtons {		# look whether to set html mail checkboxes to checked
  my $mail; 
  if ($to_mail eq "0") { $mail = ""; }
				# set to no checkbox
  elsif ($to_mail eq "1") { $mail = "checked"; }
				# set to checkbox
  elsif ($to_mail eq "skip") { 1; }
				# won't go into loop
  else { 1; }			# nothing
  unless ($to_mail eq "skip") {	# don't overwrite checkboxes
    for (0.. scalar(@PGparammail)-1) {
      if ($PGparammail[$_] eq "0") { 1;	# nothing
      } else { # if ($_ eq "0") 
        my $param = "check_mail_" . $PGparameters[$_];
        $variables{$param} = "$mail"; 
      } # else # if ($_ eq "0") 
    } # for (0.. scalar(@PGparammail)-1) 
  } # unless ($to_mail eq "skip") 
} # sub CheckMailButtons 

sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none';
  }

  my $color_key = "COLOR KEY : <FONT COLOR=blue> blue are warnings</FONT>, <FONT COLOR=red>red doesn't mail</FONT>, <FONT COLOR=green>green mails</FONT>, black is not a mailing field.<BR><BR>\n";
				# text for color_key

  if ($action eq 'Curate !') {
    &CuratePopulate();		# from another cgi
  } # if ($action eq 'Curate !') 

  elsif ($action eq 'Query !') {
    my $oop;
    $to_mail = "0";
    if ( $query->param('pubID') ) {
      $oop = $query->param('pubID');
      $variables{pubID} = &Untaint($oop);
    } else { $oop = "nodatahere"; }

      # check if curated, and if not, check xreferences to see if alternate was curated
    my $found = &FindIfPgEntry('curator'); 	# See if there's an entry
    unless ($found) { 			# if not found, check alternates
      &populateXref(); 			# make correlations between cgc and pmid in hashes
      if ($variables{pubID} =~ m/cgc/) { 	# for cgcs
        print "<CENTER><ALIGN=center><FONT SIZE=+2 COLOR=orange>$variables{pubID} curated as $cgcHash{$variables{pubID}}</FONT></CENTER><BR>\n"; 		# print potential link
        $variables{pubID} = $cgcHash{$variables{pubID}}; 	# reassign pubID to potentially good one
      } elsif ($variables{pubID} =~ m/pmid/) { 
        print "<CENTER><ALIGN=center><FONT SIZE=+2 COLOR=orange>$variables{pubID} curated as $pmHash{$variables{pubID}}</FONT></CENTER><BR>\n"; 
        $variables{pubID} = $pmHash{$variables{pubID}}; 	# reassign pubID to potentially good one
      } else { print "Not a valid ID type<BR>\n"; }
    } # unless ($found)

    &PopulateReference();
    &PopulateNonReference();
  } # elsif ($action eq 'Query !') 

  elsif ($action eq 'Load !') {
    &LoadState();
  } # elsif ($action eq 'Load') 

  elsif ($action eq 'Pg !') {
    $displayform = 0;		# don't display the form
    &PgCommand();
  } # elsif ($action eq 'Pg !') 

  elsif ( ($action eq 'Go !') || ($action eq 'Save !') ) { 
    $displayform = 0;		# don't display the form
    my $date = &GetDate();
    print "$date<BR><BR>\n";
    print $color_key;		# print the color_key
    @HTMLparamvalues = &QueryDataHTML();
				# get html values
    &HtmlToPg();		# make them into pg values
    &QueryDataMailToCheck();	# get mail related values into @PGparammailcheckvalues
    &QueryFlags();		# currently just check which form to use

    if ($action eq 'Go !') {
      &Preview();
    } # if ($action eq 'Go !') 

    elsif ($action eq 'Save !') {
      &SaveState();
    } # if ($action eq 'Save !') 
  } # elsif ( ($action eq 'Go !') || ($action eq 'Save !') ) 

  elsif ( ($action eq 'New Entry !') || ($action eq 'Update !') ) {
    $displayform = 0;
    my $date = &GetDate();
    print "$date<BR><BR>\n";
    print $color_key;
    @PGparamvalues = &QueryDataPG();
    &QueryDataMailToCheck();	# get mail related values into @PGparammailcheckvalues
    &QueryFlags();		# currently just check which form to use (useless here) 

    &OutputAndMail();		# Print stuff and Mail as appropriate
    &DealPg();			# Insert or Update postgresql database
    &ShowPgQuery();		# simple query
  } # elsif ( ($action eq 'New Entry !') || ($action eq 'Update !') ) 

  elsif ( ($action eq 'Go Big !') || ($action eq 'Defaultify !') || ($action eq 'Teenify !') ) { 
    @HTMLparamvalues = &QueryDataHTML();
    &HtmlToPg();
    &QueryDataMailToCheck(); 	# get mail related values into @PGparammailcheckvalues
    &QueryFlags();		# currently just check which form to use (useless here) 
    if ($action eq 'Go Big !') { $html_file = $big_html_file; }
    elsif ($action eq 'Defaultify !') { $html_file = $default_html_file; }
    elsif ($action eq 'Teenify !') { $html_file = $tiny_html_file; }
    else { 1; }			# set template for saving
    shift @Flagsvalues;		# change values for saving
    push @Flagsvalues, $html_file; 
    &SaveState(); 		# save data
    $load_saved = 1;		# flag to load the saved data (only for resizing)
  } # elsif ( ($action eq 'Go Big !') || ($action eq 'Defaultify !') || ($action eq 'Teenify !') )

  elsif ($action eq 'Reset !') {
    &ResetForDisplay();		# Clear all Variables for HTML
  } # elsif ($action eq 'Reset !') 

  else { 1; }
} # sub Process 



sub CuratePopulate {
	# if someone got to this form by clicking 'Curate !' in another form,
	# attempt to populate the form with values from the Pg database
				# coming from the allpdfs.cgi, we have
				# the pdf_name, so we output the general info
				# by querying the reference data in pgsql
  my $oop;
  if ( $query->param('pdf_name') ) { 	
				# from allpdfs.cgi or checkout.cgi
    $oop = $query->param('pdf_name'); 
    $variables{pdffilename} = &Untaint($oop);
				# assign pdffilename
    $variables{pdffilename} =~ m/^(\d+)_/;
				# get cgc number
    $variables{pubID} = "cgc" . $1;
				# make number, i.e. pgsql joinkey
    if ( $query->param('cgc_number') ) {
				# check for number regardless in case it's a pmid
      $oop = $query->param('cgc_number');
      $variables{pubID} = &Untaint($oop);
    } # if ( $query->param('cgc_number') ) 
    &PopulateReference();
    my $result = $conn->exec( "UPDATE ref_checked_out SET ref_checked_out = \'$variables{curator}\' WHERE joinkey = \'$variables{pubID}\';" );
    $result = $conn->exec( "UPDATE ref_checked_out SET ref_timestamp = CURRENT_TIMESTAMP WHERE joinkey = \'$variables{pubID}\';" );
  } elsif ( $query->param('cgc_number') ) { # if ( $query->param('pdf_name') ) 
				# from checkout.cgi
    $oop = $query->param('cgc_number');
    $variables{pubID} = &Untaint($oop);
				# assign pubID
    &PopulateReference();
    my $result = $conn->exec( "UPDATE ref_checked_out SET ref_checked_out = \'$variables{curator}\' WHERE joinkey = \'$variables{pubID}\';" );
  } else { $oop = "nodatahere"; }
				# if there's no pdf name, nothing.
} # sub CuratePopulate 

sub PGQueryRowify {		# Add lines to reference info
  my $result = shift;
  my @row;
  while (@row = $result->fetchrow) {
    $variables{reference} .= "$row[1]";
  } # while (@row = $result->fetchrow) 
} # sub PGQueryRowify 

sub populateXref {		# if not found, get ref_xref data to try to find alternate
  my $result = $conn->exec( "SELECT * FROM ref_xref;" );
  while (my @row = $result->fetchrow) {    # loop through all rows returned
    $cgcHash{$row[0]} = $row[1];	# hash of cgcs, values pmids
    $pmHash{$row[1]} = $row[0];		# hash of pmids, values cgcs
  } # while (my @row = $result->fetchrow)
} # sub populateXref

sub PopulateReference {		# Get the reference info from the $variables{pubID}, i.e. 
				# the joinkey.  UPDATE the checked_out table on pgsql
  my @refparams = qw(author title journal volume pages year abstract);
				# name of reference parameters used in pgsql
  foreach $_ (@refparams) {	# for each pgsql reference data parameter
    my $result = $conn->exec( "SELECT * FROM ref_$_ WHERE joinkey = '$variables{pubID}\';" );
    $variables{reference} .= "\n$_ == ";
				# add parameter name to reference info
    &PGQueryRowify($result);	
				# add reference info from pgsql to reference
				# info variable for html
  } # foreach $_ (@refparams) 
#   my $result = $conn->exec( "UPDATE ref_checked_out SET cref_hecked_out = \'$variables{curator}\' WHERE joinkey = \'$variables{pubID}\';" );	# populating reference does not mean checking out.
} # sub PopulateReference 

sub PopulateNonReference {
  my @HTMLparameters = qw(fullauthorname genesymbol2 synonym2 
			mappingdata2 genefunction2 association2 association4 
			expression2 rnai2 transgene2 overexpression2 mosaic2 
			site2 antibody2 covalent2
			extractedallele2 extractedallele4 newmutant2 
			sequencechange2 genesymbols2 geneproduct2 
			structurecorrection2 structurecorrection4
			sequencefeatures2 cellname2 cellfunction2 ablationdata2 
			newsnp2 stlouissnp2 goodphoto comment);
  my @non_refparams = qw(fullauthorname genesymbol synonym 
			mappingdata genefunction associationequiv associationnew
			expression rnai transgene overexpression mosaic 
			site antibody covalent
			extractedallelename extractedallelenew newmutant 
			sequencechange genesymbols geneproduct 
			structurecorrectionsanger structurecorrectionstlouis
			sequencefeatures cellname cellfunction ablationdata 
			newsnp stlouissnp goodphoto comment);

  my $found = &FindIfPgEntry('curator'); # See if there's an entry
  unless ($found) { 		# if not found, say not found
    print "<CENTER><MARQUEE ALIGN=center LOOP=infinite BEHAVIOR=alternate BGCOLOR=yellow SCROLLDELAY=.2><FONT SIZE=+4 COLOR=orange>No entries Found</FONT></MARQUEE></CENTER><BR>\n"; 
  } else { # unless ($found) 	# else say found and get values
    print "<CENTER><MARQUEE ALIGN=center LOOP=infinite BEHAVIOR=alternate BGCOLOR=yellow SCROLLDELAY=.2><FONT SIZE=+4 COLOR=orange>Query successful</FONT></MARQUEE></CENTER><BR>\n"; 

    for (my $i = 0; $i < scalar(@non_refparams); $i++) {
				# get value
      my $result = $conn->exec( "SELECT * FROM cur_$non_refparams[$i] 
                                 WHERE joinkey = '$variables{pubID}\';" );
      my @row;
      while (@row = $result->fetchrow) {
        $variables{$HTMLparameters[$i]} = $row[1];
				# fill in the value
      } # while (@row = $result->fetchrow) 
        # if no value, put a blank
      unless ($variables{$HTMLparameters[$i]}) { $variables{$HTMLparameters[$i]} = ""; }
      
    } # for (my $i = 0; $i < scalar(@non_refparams); $i++) 
  } # else # unless ($found) 
} # sub PopulateNonReference 

sub PgCommand {
	# 'Pg !'  Process the Query and show the results
  my $oop;
  if ( $query->param("pgcommand") ) { $oop = $query->param("pgcommand"); }
  else { $oop = "nodatahere"; }
  my $pgcommand = &Untaint($oop);
  if ($pgcommand eq "nodatahere") { 
    print "You must enter a valid PG command<BR>\n"; 
  } else { # if ($pgcommand eq "nodatahere") 
    my $result = $conn->exec( "$pgcommand" ); 
    if ( $pgcommand !~ m/select/i ) {
      print "PostgreSQL has processed it.<BR>\n";
      &ShowPgQuery();
    } else {
      print "<CENTER><TABLE border=1 cellspacing=5>\n";
      &PrintTableLabels();
      my @row;
      while (@row = $result->fetchrow) {	# loop through all rows returned
        print "<TR>";
        foreach $_ (@row) {
          print "<TD>${_}&nbsp;</TD>\n";	# print the value returned
        }
        print "</TR>\n";
      } # while (@row = $result->fetchrow) 
      &PrintTableLabels();
      print "</TABLE>\n";
    }
  } # else # if ($pgcommand eq "nodatahere") 
} # sub PgCommand 


sub SaveState { 	# Save form values to flatfile
    # replace tabs so as to divide saved data with tabs
  foreach $_ (@HTMLparamvalues) {
    $_ =~ s/\t/TABREPLACEMENT/g;
  } # foreach $_ (@HTMLparamvalues) 
  my $html_values = join("\t", @HTMLparamvalues);
				# compress html data
  my $mail_check_values = join ("\t", @PGparammailcheckvalues); 
				# compress mail checkboxes data
  my $flags = join ("\t", @Flagsvalues);
				# compress flags data
  my $stufftosave = $html_values . "CHECKBOXESDIVIDER" . $mail_check_values .  "FLAGSDIVIDER" . $flags;
  print "See all <A HREF=\"http://minerva.caltech.edu/~postgres/cgi-bin/data/curation_save_$user.txt\">saved</A>.<P>\n";
  open (SAVE, ">$save_file") or die "cannot create $save_file : $!";
    # Saving, not as file, but as list
  print SAVE "$stufftosave\n";
  close SAVE or die "Cannot close $save_file : $!";
} # sub SaveState 

sub LoadState {
  $to_mail = "skip";		# tell &CheckMailButtons(); not to overwrite
				# what we load here (to skip itself)
	# Load values to form from saved flatfile
  open (LOAD, "$save_file") or die "cannot open $save_file : $!";
				# get saved file
  local $/ = "";		# get the whole things at once
  my $saved_values = <LOAD>; 
  chomp($saved_values);		# munch munch
  close (LOAD) or die "cannot close $save_file : $!";
				# close file
  my ($html_values, $mail_check_values, $flags) = $saved_values =~ m/(.*)CHECKBOXESDIVIDER(.*)FLAGSDIVIDER(.*)/s;
#   my ($html_values, $mail_check_values) = split/CHECKBOXESDIVIDER/, $saved_values;
				# split up html and checkbox stuff
  push @HTMLparamvalues, split("\t", $html_values);
				# repopulate @HTMLparamvalues
  push @PGparammailcheckvalues, split("\t", $mail_check_values);
				# repopulate @PGparammailcheckvalues
  @Flagsvalues = ();		# clear values for pushing saved ones
  push @Flagsvalues, split("\t", $flags);
				# repopulate @Flagsvalues
  $html_file = $Flagsvalues[0];	# change the file to load

  for ( 0 .. scalar(@HTMLparameters)-1 ) {
				# for each parameter in arrays
    $HTMLparamvalues[$_] =~ s/TABREPLACEMENT/\t/g;
				# put back tabs
    $HTMLparamvalues[$_] =~ s/nodatahere//g;
				# take out bad data
    $variables{$HTMLparameters[$_]} = $HTMLparamvalues[$_];
				# put in %variables for HTML form
  } # for ( 0 .. scalar(@HTMLparameters)-1 )

  for (0.. $#PGparammail) { 	# get the mailcheckvalues
    my $param = "check_mail_" . $PGparameters[$_];
				# make the name of the field in html
    if ($PGparammailcheckvalues[$_] eq "0") { 
      $variables{$param} = '';	# if zero stored, not checked
    } else { # if ($_ eq "0") 	# if not zero, then checked
      $variables{$param} = 'checked'; 
    } # else # if ($_ eq "0") 
  } # for (0.. scalar(@PGparammail)-1) 
} # sub LoadState

sub Preview {
#   my $attachment = &CheckAttach();

  $variables{pubID} = $PGparamvalues[0];
				# get the pubID / joinkey for &FindIfPgEntry();
  my $found = &FindIfPgEntry('curator');

  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_$user.cgi\">\n";
  &OutputEntered('preview');	# preview state

  for ( 0 .. scalar(@PGparammail)-1 ) {
    my $param = "mail_" . $PGparameters[$_];
    if ($PGparammail[$_] eq "0") {
#       push @PGparammailcheckvalues, "0";
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"$param\" VALUE=\"\">\n";
    } else { # if ($_ eq "0") 
#       push @PGparammailcheckvalues, &Untaint($oop);
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"$param\" VALUE=\"$PGparammailcheckvalues[$_]\">\n";
    } # else # if ($_ eq "0") 
  } # for ( 0 .. scalar(@PGparammail)-1 ) 

  if ($found) { 
    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update !\">\n"; 
  } else { # if ($found) 
    print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Entry !\">\n"; 
  } # else # if ($found) 
  print "</FORM>\n";
} # sub Preview

sub OutputAndMail {
  &OutputEntered('real');
} # sub OutputAndMail


sub OutputEntered {
  my $state = shift;				# preview or real
#   print "You have entered : $state<BR>\n";

  my $attachment = &CheckAttach();		# get attachment file and warn

  if ($state eq 'real') { open (DATA, ">>$data_file") or die "cannot create $data_file : $!"; }
						# open data file to append new data

  for (0 .. scalar(@PGparameters)-1) {		# for each postgres parameter
    if ( ($PGparamvalues[$_] eq $PGparameters[$_]) || ($PGparamvalues[$_] eq "") ) {
						# if there's no data
      if ($state eq 'preview') {
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"$PGparameters[$_]\" VALUE=\"\">\n";
      } # if ($state eq 'preview') 		# if preview, pass value as a hidden parameter

    } else { # if ( ($PGparamvalues[$_] eq $PGparameters[$_]) || ($PGparamvalues[$_] eq "") ) 
						# if there's data
      if ($state eq 'preview') {
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"$PGparameters[$_]\" VALUE=\"$PGparamvalues[$_]\">\n";
      } # if ($state eq 'preview') 		# if preview, pass value as a hidden parameter

#       if ($state eq 'real') { &DealPg(); } 	# if it's real, do Pg stuff
      if ($state eq 'real') { print DATA "$PGparameters[$_] : $PGparamvalues[$_]\n"; }
						# print to data file

      if ($PGparammail[$_] eq "0") {		# if doesn't have address to mail
        print "$PGparameters[$_] : $PGparamvalues[$_]<BR>\n";
						# print in black
      } else { # if ($PGparammail[$_] eq "0") 	# if does have address to mail

        if ($PGparammailcheckvalues[$_] eq "0") {
						# if box was not checked to mail
						# print in red, don't mail
          print "<FONT COLOR=red>$PGparameters[$_] : $PGparamvalues[$_]</FONT><BR>\n";
        } else { # if ($PGparammailcheckvalues[$_] eq "0") 
						# if box was checked to mail
						# print in green, mail if real
          print "<FONT COLOR=green>$PGparameters[$_] : $PGparamvalues[$_]</FONT><BR>\n";
          if ($state eq "real") {		# if for real (not previewing)
 				&MimeMail($_); 	# MIMEMAIL REMOVE COMMENT
          } # if ($state eq "real")
        } # else # if ($PGparammailcheckvalues[$_] eq "0") 
      } # else # if ($PGparammail[$_] eq "0") 	# if does have address to mail
    } # unless ( ($PGparamvalues[$_] eq $PGparameters[$_]) ...
  } # for (0 .. scalar(@PGparameters)-1) 

  if ($state eq 'real') { print DATA "\n"; close (DATA) or die "cannot close $data_file : $!"; }
						# close data file

  if ($attachment) {				# if there's an attachment
    my ($attachname) = $attachment =~ m/.*\/(.*)/;
						# catch name of the attachment
    my $subject = $attachname;			# set the subject
    my $body = "Here is the attachment : $attachname\n\n";
    if ($recmail) { &MimeAttacher($user, $rec_cgc, $subject, $body, $attachment); }
    if ($wormmail) { &MimeAttacher($user, $rec_worm, $subject, $body, $attachment); }
    if ($sylmail) { &MimeAttacher($user, $rec_syl, $subject, $body, $attachment); }
    if ($johnmail) { &MimeAttacher($user, $rec_john, $subject, $body, $attachment); }
  } # if ($attachment)
  print "<P></P>\n";
} # sub OutputEntered 


sub MimeMail {
    # Send Mail with MIME::Lite, or if no attachment with Mail::Mailer
  my $array_val = shift;	# get the array value
#   my $attach = 0;		# flag to see whether to send attachment
  my $subject = "Something Wrong with Default Subject Maker (check array)";
				# initialize subject
  if ($PGparamsubjects[$array_val]) { $subject = "$PGparamsubjects[$array_val]"; }
  my $email = "azurebrd\@minerva.caltech.edu";
				# initialize email
  if ($PGparammail[$array_val]) { 
    if ( ($PGparammail[$array_val] eq 'Gene Structure Correction') || 
         ($PGparammail[$array_val] eq 'Sequence Features') ) { $johnmail++; }
				# if one of John's wanted fields, set flag to mail him attachment
    SWITCH : {			# use $PGparammail to reassign email to send to
      if ($PGparammail[$array_val] eq "rec") { $email = $rec_cgc; last SWITCH; }			# set flag to mail attachment to rec_cgc
      if ($PGparammail[$array_val] eq "worm") { $email = $rec_worm; last SWITCH; }			# set flag to mail attachment to worm
      if ($PGparammail[$array_val] eq "syl") { $email = $rec_syl; last SWITCH; }			# set flag to mail attachment to sylvia
      if ($PGparammail[$array_val] eq "wormerich") { $email = $rec_wormerich; last SWITCH; }			# send mail to worm with attachment
#       if ($PGparammail[$array_val] eq "rec") { $email = $rec_cgc; $recmail++; last SWITCH; }			# set flag to mail attachment to rec_cgc
#       if ($PGparammail[$array_val] eq "worm") { $email = $rec_worm; $wormmail++; last SWITCH; }			# set flag to mail attachment to worm
#       if ($PGparammail[$array_val] eq "syl") { $email = $rec_syl; $sylmail++; last SWITCH; }			# set flag to mail attachment to sylvia
#       if ($PGparammail[$array_val] eq "wormerich") { $email = $rec_wormerich; $wormmail++; last SWITCH; }			# send mail to worm with attachment
      if ($PGparammail[$array_val] eq "wen") { $email = $wen; last SWITCH; }
      if ($PGparammail[$array_val] eq "ray") { $email = $raymond; last SWITCH; }
      if ($PGparammail[$array_val] eq "erich") { $email = $erich; last SWITCH; }
      if ($PGparammail[$array_val] eq "raneri") { $email = $raneri; last SWITCH; }
    } # SWITCH 
  } # if ($PGparammail[$array_val]) 
  my $date = &GetDate();	# get the date

				# make with body of email
  my $attachment = &CheckAttach();
  my ($attachname) = $attachment =~ m/.*\/(.*)/;
				# catch name of the attachment
  my $body = ""; 		# initialize body
  if ($attachment) { $body .= "Attachment $attachname in following mail\n\n"; }
  unless ($PGparamvalues[0] eq "nodatahere") { $body .= "pubID :\t$PGparamvalues[0]\n"; }
				# print pubID
  unless ($PGparamvalues[1] eq "nodatahere") { $body .= "pdffilename :\t$PGparamvalues[1]\n"; }
				# print pdffilename
  $body .= "Curator :\t$PGparamvalues[2]\n";	# print Curator name
  $body .= "Date :\t$date\n";			# print date
  $body .= "$PGparamsubjects[$array_val] : $PGparamvalues[$array_val]\n";	
				# print info
  unless ($PGparamvalues[3] eq "nodatahere") { $body .= "Reference :\n$PGparamvalues[3]\n"; }	
				# print reference info
 
  &Mailer($user, $email, $subject, $body);
				# mail single mail to all

    # path to attachment if exists, print warning if not.
#   my $attachment = &CheckAttach();
#   if ( ($attachment) && ($attach == 1) ) {		
# 				# if meant to send attachment because the
# 				# attachment exists, and it's flagged to attach
#     &MimeAttacher($user, $email, $subject, $body, $attachment);
#   } elsif ( ($attachment) && ($attach == 2) ) {
# 				# wormerich, mail erich w/o pdf, worm w/pdf
#     $email = $rec_worm;
#     &MimeAttacher($user, $email, $subject, $body, $attachment);
#     $email = $erich;
#     &Mailer($user, $email, $subject, $body);
#     # my $rec_wormerich = 'worm@sanger.ac.uk, emsch@its.caltech.edu';
#   } else { # if ( ($attach) && ($attachment) ) 	# if not meant to send attachment
#     &Mailer($user, $email, $subject, $body);
#   } # else # if ( ($attach) && ($attachment) ) 	# if not meant to send attachment
} # sub MimeMail 

sub MimeAttacher {	# send attachment mail
  my ($user, $email, $subject, $body, $attachment) = @_;
#   $body = &Untaint($body);
#   $user = &Untaint($user);
#   $email = &Untaint($email);
#   $subject = &Untaint($email);
#   $attachment = &Untaint($attachment);
#   $PGparamvalues[1] = &Untaint($PGparamvalues[1]);
#   $ENV{PATH} = &Untaint($ENV{PATH});
  my $msg = MIME::Lite->new(
#                From     =>"\"$user\" <$user@minerva.caltech.edu>",
#                From     =>'nobody@minerva.caltech.edu',
               From     =>"\"$user\" <$user>",
               To       =>"$email",
               Subject  =>"$subject",
               Type     =>'multipart/mixed',
               );
  $msg->attach(Type     =>'TEXT',
               Data     =>"$body"
               );
  $msg->attach(Type     =>'Application/PDF',
               Path     =>"$attachment",
               Filename =>"$PGparamvalues[1]",
               Disposition => 'attachment'
               );
#   print "ENV : $ENV{PATH}<BR>\n";
#   {
# #     local $ENV{PATH} = '/sbin:/usr/sbin:/bin:/usr/bin:/usr/lib/perl5/site_perl/5.6.1/MIME:/var/qmail/bin:/usr/local/src/qmail-1.03';
#     print "ENV : $ENV{PATH}<BR>\n";
# #     $msg = Untaint($msg);
#     print "NOT STUCK YET<BR>\n";
#     MIME::Lite->send('sendmail'); # , "/var/qmail/bin/sendmail -t -oi -oem");
# #     $msg->send('sendmail'); # , "/var/qmail/bin/sendmail -t -oi -oem");
#     print "STUCK NOW<BR>\n";
#   }
# #   $ENV{PATH} = &Untaint($ENV{PATH});
  $msg->send;
} # sub MimeAttacher 

sub Mailer {		# send non-attachment mail
  my ($user, $email, $subject, $body) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => $user,
                  To      => $email,
# 		  Cc	  => 'curationmail@minerva.caltech.edu, $user',
		  Cc	  => $ccemail,
                  Subject => $subject,
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
} # sub Mailer 

sub CheckAttach {
    # see if attached file exists.  return "" if not.
  my $attachment = $PGparamvalues[1];	# get attachment file name
  if ($attachment =~ m/^(.*)\.\w+$/) { 	# if ends in a dot
    $attachment = $attachment_path . $1 . ".pdf"; 		# assign file
  } elsif ($attachment =~ m/^\w+$/) { 	# if no dot
    $attachment = $attachment_path . $attachment . ".pdf";	# assign file
  } else { 				# if doesn't look right
    $attachment = "";			# reset attachment
  }
  unless (-e $attachment) { $attachment = ""; print "<FONT COLOR=blue>WARNING : pdf $PGparamvalues[1] not in filesystem.  Will not send mail with attachment.</FONT><BR>\n"; }
  return $attachment;
}

sub QueryDataPG {		# get pg related values from html into @PGparamvalues
  my $oop; 
  for (0 .. scalar(@PGparameters)-1 ) {
    if ( $query->param("$PGparameters[$_]") ) { 
      $oop = $query->param("$PGparameters[$_]"); 
      $PGparamvalues[$_] = &Untaint($oop);
    } else { # if ( $query->param("$PGparameters[$_]") ) 
      $PGparamvalues[$_] = "";
    } # else # if ( $query->param("$PGparameters[$_]") ) 
  } # for (0 .. scalar(@PGparameters)-1 ) 
  return @PGparamvalues;
} # sub QueryDataPG 

sub QueryDataMailToCheck {	# get mail related values from html into @PGparammailcheckvalues
  my $oop;
  for ( 0 .. scalar(@PGparammail)-1 ) {
    if ($PGparammail[$_] eq "0") {
      push @PGparammailcheckvalues, "0";
    } else { # if ($_ eq "0") 
      my $param = "mail_" . $PGparameters[$_];
      if ( $query->param("$param") ) { 
        $oop = $query->param("$param"); 
      } else { $oop = "0"; }
      push @PGparammailcheckvalues, &Untaint($oop);
    } # else # if ($_ eq "0") 
  } # for ( 0 .. scalar(@PGparammail)-1 ) 
} # sub QueryDataMailToCheck 

sub QueryFlags {		# get flags related values from html into @Flagsvalues
  my $oop;
  for (0 .. scalar(@Flags)-1 ) {
    if ( $query->param("$Flags[$_]") ) {
      $oop = $query->param("$Flags[$_]");
    } else { $oop = ""; }
    shift @Flagsvalues;			# take out a value
    push @Flagsvalues, &Untaint($oop); 	# push in value from html
  } # for (0 .. scalar(@Flags)-1 )
} # sub QueryFlags

sub QueryDataHTML {		# get html related values from html into @HTMLparamvalues
  my $oop; # my @HTMLparamvalues;
  for (0 .. scalar(@HTMLparameters)-1 ) {
    if ( $query->param("$HTMLparameters[$_]") ) { $oop = $query->param("$HTMLparameters[$_]"); }
    else { $oop = "nodatahere"; }	# set default for saving / loading
    $HTMLparamvalues[$_] = &Untaint($oop);
  } # for (0 .. scalar(@HTMLparameters)-1 ) 
  return @HTMLparamvalues;
} # sub QueryDataHTML 

sub Untaint {
  my $tainted = shift;
  my $untainted;
  if ($tainted eq "") {
    $untainted = "";
  } else { # if ($tainted eq "")
    $tainted =~ s/[^\w\-.,;:?\/\\@#\$\%\^&*(){}[\]+=!~|' \t\n\r\f]//g;
    if ($tainted =~ m/^([\w\-.,;:?\/\\@#\$\%&\^*(){}[\]+=!~|' \t\n\r\f]+)$/) {
      $untainted = $1;
    } else {
      die "Bad data in $tainted";
    }
  } # else # if ($tainted eq "")
  return $untainted;
} # sub Untaint 

sub PrintHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://www.wormbase.org/stylesheets/wormbase.css">
  
<HEAD>
EndOfText
  print "<TITLE>${User}'s Curation Form</TITLE>";
					# get user's name 
  print <<"EndOfText";
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
<CENTER><A HREF="http://minerva.caltech.edu/~postgres/cgi-bin/sitemap.cgi">Site Map</A></CENTER>
<CENTER><A HREF="http://minerva.caltech.edu/~postgres/cgi-bin/curationform_doc.cgi">Documentation</A></CENTER>
<CENTER><A HREF="http://whitney.caltech.edu/~raymond/curation_guidlines.htm">Guidelines</A></CENTER>
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

sub GetDate {                           # begin GetDate
  my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
                                        # set array of days
  my @months = qw(January February March April May June 
          July August September October November December);
                                        # set array of months
  my $time = time;                   	# set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                  	# get right month
  my $shortdate = "$mday/$sam/$year";   # get final date
  my $ampm = "AM";                   	# fiddle with am or pm
  if ($hour eq 12) { $ampm = "PM"; }    # PM if noon
  if ($hour eq 0) { $hour = "12"; }     # AM if midnight
  if ($hour > 12) {               	# get hour right from 24
    $hour = ($hour - 12);
    $ampm = "PM";           		# reset PM if after noon
  }
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  $year = 1900+$year;             	# get right year in 4 digit form
  my $todaydate = "$days[$wday], $mday $months[$mon] $year";
                                        # set current date
  my $date = $todaydate . " $hour\:$min $ampm";
                                        # set final date
  return $date;
} # sub GetDate                         # end GetDate


sub DealPg {				# Add values to Postgres
  my @valuesforpostgres = @PGparamvalues;	# copy values
  foreach $_ (@valuesforpostgres) {
# print "VAL $_<BR>\n";
    if ($_ eq "nodatahere") { $_ = ''; }	# empty out those with no data
    if ($_ =~ m/'/) { $_ =~ s/'/''/g; }
  } # foreach $_ (@valuesforpostgres) 

  $variables{pubID} = $PGparamvalues[0];
#   my $found = &FindIfPgEntry();	# old way with two separate subs for add and update
#   if ($found) { &UpdatePg(@valuesforpostgres); } else { &AddToPg(@valuesforpostgres); }
  &AddToPg(@valuesforpostgres);
  &AddToTest3(@valuesforpostgres);
} # sub DealPg 

sub AddToPg { 				# insert or update all separate data
  my @valuesforpostgres = @_;
  for (0 .. scalar(@PGparameters)-1) { 	# for each parameter from the CGI
    if ($PGparameters[$_] eq 'Curator') {
      my $result = $conn->exec( "INSERT INTO cur_$PGparameters[$_] VALUES ('$valuesforpostgres[0]', '$valuesforpostgres[$_]', CURRENT_TIMESTAMP);" );
    } # if ($PGparameters[$_] eq 'Curator') 
    unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || 
             ($PGparameters[$_] eq 'reference') ) {	 	 
					# exclude pubID and pdffilename and reference because 
					# they have no matching pgsql tables
# print "VA2 $valuesforpostgres[$_]<BR>\n";
      if ($valuesforpostgres[$_] eq "") { 	# no entry, enter NULL
					# insert entries
        my $found = &FindIfPgEntry($PGparameters[$_]);
        if ($found) { 
          my $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_$PGparameters[$_] = NULL WHERE joinkey = '$valuesforpostgres[0]';" );
#           print "my \$result = \$conn->exec( \"UPDATE cur_$PGparameters[$_] SET cur_$PGparameters[$_] = NULL WHERE joinkey = '$valuesforpostgres[0]';\" );<BR>\n";
          $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';" );
#           print "\$result = \$conn->exec( \"UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';\" );<BR>\n";
        } else { 
          my $result = $conn->exec( "INSERT INTO cur_$PGparameters[$_] VALUES ('$valuesforpostgres[0]', NULL, CURRENT_TIMESTAMP);" );
#           print "my \$result = \$conn->exec( \"INSERT INTO cur_$PGparameters[$_] VALUES ('$valuesforpostgres[0]', NULL, CURRENT_TIMESTAMP);\" );<BR>\n";
        } # if ($found)
      } else {				# a real entry, enter the value
        my $found = &FindIfPgEntry($PGparameters[$_]);
        if ($found) { 
          my $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_$PGparameters[$_] = '$valuesforpostgres[$_]' WHERE joinkey = '$valuesforpostgres[0]';" );
#           print "my \$result = \$conn->exec( \"UPDATE cur_$PGparameters[$_] SET cur_$PGparameters[$_] = '$valuesforpostgres[$_]' WHERE joinkey = '$valuesforpostgres[0]';\" );<BR>\n";
          $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';" );
#           print "\$result = \$conn->exec( \"UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';\" );<BR>\n";
        } else { 
          my $result = $conn->exec( "INSERT INTO cur_$PGparameters[$_] VALUES ('$valuesforpostgres[0]', '$valuesforpostgres[$_]', CURRENT_TIMESTAMP);" );
#           print "my \$result = \$conn->exec( \"INSERT INTO cur_$PGparameters[$_] VALUES ('$valuesforpostgres[0]', '$valuesforpostgres[$_]', CURRENT_TIMESTAMP);\" );<BR>\n";
        } # if ($found)
      } # else # if ($valuesforpostgres[$_] eq "") 
    } # unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') )
  } # for (0 .. scalar(@PGparameters)-1) 
} # sub AddToPg 

sub FindIfPgEntry {	# look at postgresql by pubID (joinkey) to see if entry exists
	# use the pubID and the curator table to see if there's an entry already
  my $cur_table = shift;		# figure out which table to check for data from
  my $result = $conn->exec( "SELECT * FROM cur_$cur_table WHERE joinkey = '$variables{pubID}';" );
  my @row; my $found;
  while (@row = $result->fetchrow) { $found = $row[1]; if ($found eq '') { $found = ' '; } }  
    # if there's null or blank data, change it to a space so it will update, not insert
  return $found;
} # sub FindIfPgEntry 


sub AddToTest3 { 			# insert all data in one table
  my @valuesforpostgres = @_;
  my $result = $conn->exec( "INSERT INTO testcuration3 VALUES ( '$valuesforpostgres[0]', '$valuesforpostgres[1]', '$valuesforpostgres[2]', '$valuesforpostgres[3]', '$valuesforpostgres[4]', '$valuesforpostgres[5]', '$valuesforpostgres[6]', '$valuesforpostgres[7]', '$valuesforpostgres[8]', '$valuesforpostgres[9]', '$valuesforpostgres[10]', '$valuesforpostgres[11]', '$valuesforpostgres[12]', '$valuesforpostgres[13]', '$valuesforpostgres[14]', '$valuesforpostgres[15]', '$valuesforpostgres[16]', '$valuesforpostgres[17]', '$valuesforpostgres[18]', '$valuesforpostgres[19]', '$valuesforpostgres[20]', '$valuesforpostgres[21]', '$valuesforpostgres[22]', '$valuesforpostgres[23]', '$valuesforpostgres[24]', '$valuesforpostgres[25]', '$valuesforpostgres[26]', '$valuesforpostgres[27]', '$valuesforpostgres[28]', '$valuesforpostgres[29]', '$valuesforpostgres[30]');" ); # , '$valuesforpostgres[31]', '$valuesforpostgres[32]', '$valuesforpostgres[33]', '$valuesforpostgres[34]', '$valuesforpostgres[35]', '$valuesforpostgres[36]', '$valuesforpostgres[37]', '$valuesforpostgres[38]', '$valuesforpostgres[39]', '$valuesforpostgres[40]', '$valuesforpostgres[41]', '$valuesforpostgres[42]', '$valuesforpostgres[43]', '$valuesforpostgres[44]', '$valuesforpostgres[45]', '$valuesforpostgres[46]', '$valuesforpostgres[47]', '$valuesforpostgres[48]', '$valuesforpostgres[49]', '$valuesforpostgres[50]', '$valuesforpostgres[51]', '$valuesforpostgres[52]', '$valuesforpostgres[53]', '$valuesforpostgres[54]', '$valuesforpostgres[55]');" );
} # sub AddToTest3 


sub ShowPgQuery {
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://minerva.caltech.edu/~postgres/cgi-bin/curation_$user.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
} # sub ShowPgQuery 


sub HtmlToPg {
	# Change 56 HTML parameters into 31 Postgres parameters
  my $i; my $j = 5;			# initialize

    # Reference Info
  for ($i = 0; $i < 6; $i++) {
    if ($HTMLparamvalues[$i] ne "nodatahere") { $PGparamvalues[$i] = $HTMLparamvalues[$i]; } 
      else { $PGparamvalues[$i] = ""; }
  } # for ($i = 0; $i < 6; $i++) 

    # Compress double fields into single PGparameters, PGparamvalues info
  for ($i = 6; $i <= 54; $i+=2) {	# increase $i by 2s
    if ($HTMLparamvalues[$i] ne "nodatahere") { 
					# if data
      $PGparamvalues[$j] = $HTMLparamvalues[$i]; 
					# pass it on to PG
    } elsif ($HTMLparamvalues[$i - 1] ne "nodatahere") { 
					# if data in checkbox
      $PGparamvalues[$j] = $HTMLparamvalues[$i - 1]; 
					# pass it on to PG
      $HTMLparamvalues[$i] = $HTMLparamvalues[$i - 1]; 
					# move in HTML to Save or Go
    } else { $PGparamvalues[$j] = ""; }	# set to blank
#      else { 1; }			# nothing
    $j++;				# increase $j by 1s
  } # for (my $i = 6; $i <= 54; $i+=2) 

    # Good Photo and Comments
  if ($HTMLparamvalues[53] ne "nodatahere") { $PGparamvalues[29] = $HTMLparamvalues[53]; } 
    else { $PGparamvalues[29] = ""; }
  if ($HTMLparamvalues[54] ne "nodatahere") { $PGparamvalues[30] = $HTMLparamvalues[54]; } 
    else { $PGparamvalues[30] = ""; }
} # sub HtmlToPg 


sub PrintTableLabels {		# Just a bunch of table down entries
  print "<TR><TD>pubID</TD><TD>pdffilename</TD><TD>curator</TD><TD>reference</TD><TD>newsymbol</TD><TD>synonym</TD><TD>mappingdata</TD><TD>genefunction</TD><TD>associationequiv</TD><TD>associationnew</TD><TD>expression</TD><TD>rnai</TD><TD>transgene</TD><TD>overexpression</TD><TD>mosaic</TD><TD>antibody</TD><TD>extractedallelename</TD><TD>extractedallelenew</TD><TD>newmutant</TD><TD>sequencechange</TD><TD>genesymbols</TD><TD>geneproduct</TD><TD>structurecorrection</TD><TD>sequencefeatures</TD><TD>cellname</TD><TD>cellfunction</TD><TD>ablationdata</TD><TD>newsnp</TD><TD>stlouissnp</TD><TD>goodphoto</TD><TD>comment</TD></TR>\n";
} # sub PrintTableLabels 

# sub PrintTableLabels {		# Just a bunch of table down entries
#   print "<TR><TD>pubID</TD><TD>pdffilename</TD><TD>curator</TD><TD>reference</TD><TD>newsymbol1</TD><TD>newsymbol2</TD><TD>synonym1</TD><TD>synonym2</TD><TD>mappingdata1</TD><TD>mappingdata2</TD><TD>genefunction1</TD><TD>genefunction2</TD><TD>association1</TD><TD>association2</TD><TD>association3</TD><TD>association4</TD><TD>expression1</TD><TD>expression2</TD><TD>rnai1</TD><TD>rnai2</TD><TD>transgene1</TD><TD>transgene2</TD><TD>overexpression1</TD><TD>overexpression2</TD><TD>mosaic1</TD><TD>mosaic2</TD><TD>antibody1</TD><TD>antibody2</TD><TD>extractedallele1</TD><TD>extractedallele2</TD><TD>extractedallele3</TD><TD>extractedallele4</TD><TD>newmutant1</TD><TD>newmutant2</TD><TD>sequencechange1</TD><TD>sequencechange2</TD><TD>genesymbols1</TD><TD>genesymbols2</TD><TD>geneproduct1</TD><TD>geneproduct2</TD><TD>structurecorrection1</TD><TD>structurecorrection2</TD><TD>sequencefeatures1</TD><TD>sequencefeatures2</TD><TD>cellname1</TD><TD>cellname2</TD><TD>cellfunction1</TD><TD>cellfunction2</TD><TD>ablationdata1</TD><TD>ablationdata2</TD><TD>newsnp1</TD><TD>newsnp2</TD><TD>stlouissnp1</TD><TD>stlouissnp2</TD><TD>goodphoto</TD><TD>comment</TD></TR>\n";
# } # sub PrintTableLabels 

# sub UpdatePg { 				# update all separate data
#   my @valuesforpostgres = @_;
#   for (0 .. scalar(@PGparameters)-1) { 	# for each parameter from the CGI
#     if ($PGparameters[$_] eq 'Curator') {
#       my $result = $conn->exec( "INSERT INTO cur_$PGparameters[$_] VALUES ('$valuesforpostgres[0]', '$valuesforpostgres[$_]', CURRENT_TIMESTAMP);" );
#     } # if ($PGparameters[$_] eq 'Curator') 
#     unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') || ($PGparameters[$_] eq 'Curator') ) {	 
# 					# exclude pubID and pdffilename and reference because 
# 					# they have no matching pgsql tables
#       if ($valuesforpostgres[$_] eq "") { 	# no entry, enter NULL
# 					# update entries
#         my $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_$PGparameters[$_] = NULL WHERE joinkey = '$valuesforpostgres[0]';" );
#         $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';" );
#         print "\$result = \$conn->exec( \"UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';\" );<BR>\n";
#       } else {			# a real entry, enter the value
#         my $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_$PGparameters[$_] = '$valuesforpostgres[$_]' WHERE joinkey = '$valuesforpostgres[0]';" );
#         $result = $conn->exec( "UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';" );
#         print "\$result = \$conn->exec( \"UPDATE cur_$PGparameters[$_] SET cur_timestamp = CURRENT_TIMESTAMP WHERE joinkey = '$valuesforpostgres[0]';\" );<BR>\n";
#       } # else # if ($valuesforpostgres[$_] eq "") 
#     } # unless ( ($PGparameters[$_] eq 'pubID') || ($PGparameters[$_] eq 'pdffilename') || ($PGparameters[$_] eq 'reference') )
#   } # for (0 .. scalar(@PGparameters)-1) 
# } # sub UpdatePg 

# sub FindIfPgEntry {	# old way to check entries, only checking the curator instead of each separetly
# 	# use the pubID and the curator table to see if there's an entry already
#   my $result = $conn->exec( "SELECT * FROM cur_curator WHERE joinkey = '$variables{pubID}';" );
#   my @row; my $found;
#   while (@row = $result->fetchrow) { $found = $row[1]; }
#   return $found;
# } # sub FindIfPgEntry 


# sub NOTHING {
# my @PGparameters = qw(pubID pdffilename curator reference newsymbol synonym 5
# 			mappingdata genefunction associationequiv associationnew 9
# 			expression rnai transgene overexpression mosaic antibody 15
# 			extractedallelename extractedallelenew newmutant 18
# 			sequencechange genesymbols geneproduct structurecorrection 22
# 			sequencefeatures cellname cellfunction ablationdata 26
# 			newsnp stlouissnp goodphoto comment); 30
# my @HTMLparameters = qw(pubID pdffilename curator reference newsymbol1 newsymbol2 5
# 			synonym1 synonym2 mappingdata1 mappingdata2 9
# 			genefunction1 genefunction2 association1 association2 13
# 			association3 association4 expression1 expression2 17
# 			rnai1 rnai2 transgene1 transgene2 overexpression1 22
# 			overexpression2 mosaic1 mosaic2 antibody1 antibody2 27
# 			extractedallele1 extractedallele2 extractedallele3 30
# 			extractedallele4 newmutant1 newmutant2 sequencechange1 34
# 			sequencechange2 genesymbols1 genesymbols2 geneproduct1 38
# 			geneproduct2 structurecorrection1 structurecorrection2 41
# 			sequencefeatures1 sequencefeatures2 cellname1 cellname2 45
# 			cellfunction1 cellfunction2 ablationdata1 ablationdata2 49
# 			newsnp1 newsnp2 stlouissnp1 stlouissnp2 goodphoto 54
# 			comment);
# my @PGparammail = qw(0 0 0 0 rec rec
# 			rec erich rec worm 
# 			wen ray wen erich 0 0
# 			0 rec erich 
# 			syl 0 0 worm 
# 			0 ray ray ray 
# 			0 0 0 0);
# my @PGparamsubjects = qw("", "", "", "", "Gene New Symbol", "Gene Synonym",
# 			"Gene Mapping Data", "Gene Function", "Gene Association", "Gene Association",
# 			"Gene Expression", "RNAi", "Transgene", "Overexpression", "", "", 
# 			"", "Allele Extracted", "New Mutant",
# 			"Allele Sequence Changed", "", "", "Gene Structure Correction",
# 			"", "Cell Name", "Cell Function", "Ablation Data",
# 			"", "", "", "");
#
# my @PGparamvalues;
# my @HTMLparamvalues;
#   # values to determine whom which fields go to
# my @parammail = qw(0 0 0 0 0 rec
# 			0 rec 0 rec
# 			0 erich 0 rec
# 			0 worm 0 wen
# 			0 ray 0 wen 0
# 			erich 0 0 0 0
# 			0 0 0
# 			rec 0 erich 0
# 			syl 0 0 0
# 			0 0 worm
# 			0 0 0 ray
# 			0 ray 0 ray
# 			0 0 0 0 0
# 			0);
#   # values for Subject heading for each field parameter
# my @paramsubjects = ("", "", "", "", "", "Gene New Symbol", 
# 			"", "Gene Synonym", "", "Gene Mapping Data",
# 			"", "Gene Function", "", "Gene Association",
# 			"", "Gene Association", "", "Gene Expression",
# 			"", "RNAi", "", "Transgene", "", 
# 			"Overexpression", "", "", "", "",
# 			"", "", "",
# 			"Allele Extracted", "", "New Mutant", "",
# 			"Allele Sequence Changed", "", "", "",
# 			"", "", "Gene Structure Correction",
# 			"", "", "", "Cell Name",
# 			"", "Cell Function", "", "Ablation Data",
# 			"", "", "", "", "", 
# 			"");
# my %variables;
# 
# &ResetForDisplay();		# Clear all Variables for HTML
# &PrintHeader();			# print the HTML header
# &Process();			# Essentially do everything
# &DisplayForm();			# print the rest of the form
# &PrintFooter();			# print the HTML footer
# }


# Old Deal with Pg.  AddToPg renamed to DealPg with separate AddToPg and UpdatePg subroutines
# sub DealPg {
# # test that Pg is working
# #   my $result = $conn->exec( "DELETE FROM testcuration2 WHERE pubid = 'ThePubID';");
# #   $result = $conn->exec( "INSERT INTO testcuration2 VALUES ('ThePubID', 'ThePDFname', 'CuratorPerson', 'RefData', 'No1', 'NewSymbol', 'nosy1', 'Synonym2', '', '', '', '', '', '', '', '', 'noex1', 'Expression2', '', '', '', '', '', '', '', '', 'noan1', 'antibody2', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'noce1', 'Cellname2', '', '', '', '', '', '', '', '', '', '');" ); 
#   &AddToPg();
# #   &PrintPgTable();	# Show All in pgsql testcuration3
#   &ShowPgQuery();
# } # sub DealPg 

# sub PrintPgTable {
#   my @ary;
#   Pg::doQuery($conn, "select * from testcuration3", \@ary);
#   print "We have made an Entry on PostgreSQL.  We now query our PostgreSQL database to see all the information in it.<BR>\n";
#   print "<CENTER><TABLE border=1 cellspacing=5>\n";
#   &PrintTableLabels();
#   for my $i ( 0 .. $#ary ) {
#     print "<TR>";
#     for my $j ( 0 .. $#{$ary[$i]} ) {
#       print "<TD>$ary[$i][$j]</TD>";
#     } # for my $j ( 0 .. $#{$ary[$i]} ) 
#     print "</TR>\n";
#   } # for my $i ( 0 .. $#ary ) 
#   print "</TABLE></CENTER>\n";
# } # sub PrintPgTable 


# Old Mail system used MuttMail instead of MimeMail
# sub MuttMail {
#   my $array_val = shift;	# get the array value
#   my $attach = 0;		# flag to see whether to send attachment
#   my $muttpath = "/usr/local/bin/mutt";
# 				# set path to mutt mailer
#   my $subject = "Something Wrong with Default Subject Maker (check array)";
# 				# initialize subject
#   if ($PGparamsubjects[$array_val]) { $subject = "$PGparamsubjects[$array_val]"; }
#   my $email = "azurebrd\@minerva.caltech.edu";
# 				# initialize email
#   if ($PGparammail[$array_val]) { 
#     SWITCH : {			# use $PGparammail to reassign email to send to
#       if ($PGparammail[$array_val] eq "rec") { $email = $rec_cgc; $attach = 1; last SWITCH; }			# send mail to cgc with attachment
#       if ($PGparammail[$array_val] eq "worm") { $email = $rec_worm; $attach = 1; last SWITCH; }			# send mail to worm with attachment
#       if ($PGparammail[$array_val] eq "syl") { $email = $rec_syl; $attach = 1; last SWITCH; }			# send mail to sylvia with attachment
#       if ($PGparammail[$array_val] eq "wen") { $email = $wen; last SWITCH; }
#       if ($PGparammail[$array_val] eq "ray") { $email = $raymond; last SWITCH; }
#       if ($PGparammail[$array_val] eq "erich") { $email = $erich; last SWITCH; }
#     } # SWITCH 
#   } # if ($PGparammail[$array_val]) 
#   my $date = &GetDate();	# get the date
#   my $include_file ="/home/azurebrd/work/curationform/mutt/include";
# 				# file with body of email
#   open (INC, ">$include_file") or die "Cannot create $include_file : $!";
# 				# open filehandle to write to it
#   unless ($PGparamvalues[0] eq "nodatahere") { print INC "pubID :\t$PGparamvalues[0]\n"; }						# print pubID
#   unless ($PGparamvalues[1] eq "nodatahere") { print INC "pdffilename :\t$PGparamvalues[1]\n"; }
# 						# print pdffilename
#   print INC "Curator :\t$PGparamvalues[2]\n";	# print Curator name
#   print INC "Date :\t$date\n";			# print date
#   print INC "$PGparamsubjects[$array_val] : $PGparamvalues[$array_val]\n";	
# 				# print info
#   unless ($PGparamvalues[3] eq "nodatahere") { print INC "Reference :\n$PGparamvalues[3]\n"; }	
# 				# print reference info
#   close INC or die "Cannot close $include_file : $!";
#   if ($attach) {		# if meant to send attachment
#     &MailAttachment($muttpath, $include_file, $subject, $email);
#   } else { # if ($attach) 	# if not meant to send attachment
#     my $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" $email));
#   }
#     # for raymond, mails him without an attachment
# #   $email = $raymond;				# for pseudo-cc
# #   my $muttout = system(qq(echo "" | /usr/local/bin/mutt -i "/home/azurebrd/work/curationform/mutt/include" -s "$subject" $email));
# } # sub MuttMail 
# 
# sub MailAttachment {		# Mutt
#   my $muttpath = shift; my $include_file = shift; my $subject = shift; my $email
# = shift;				# get subroutine parameters
#   my $attachment = $PGparamvalues[1];	# get attachment file name
#   my $muttout;				# define mutt return (possible error)
#   if ($attachment =~ m/^(.*)\.\w+$/) { 	# if ends in a dot
#     $attachment = $attachment_path . $1 . ".pdf"; 	# assign file
#     $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" -a "$attachment" $email));			  # send mail
#   } elsif ($attachment =~ m/^\w+$/) { 	# if no dot
#     $attachment = $attachment_path . $attachment . ".pdf";	# assign file
#     $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" -a "$attachment" $email));			  # send mail
#   } else { 				# if doesn't look right
#     print "POSSIBLY BAD PDF FILE NAME mail sent without attachment to $email<BR>\n"; 
# 					# print error warning
#     my $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" $email));
# 					# mail again without attachment
#   } # if ($attachment =~ m/^(.*)\.\w+$/) 
#   if ($muttout) { 
#     print "MUTT ERROR : $attachment : most likely no PDF email with attachment sent due to bad PDF file name or file not in directory.  Check errorlog.  Email without attachment sent.<BR>\n"; 
#     my $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" $email));
# 					# mail again without attachment
#   } # if ($muttout) 			# if mutt returns at error
# } # sub MailAttachment 
