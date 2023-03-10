#!/usr/bin/perl

# Curate Allele-Phenotype data
#
# AQL Query for Phenotype Description list : 
# select l->Description from l in class Phenotype where exists l->Description
#
# Created links to self in popup window for editing Phenotype and Paper list
# from a flat file.  2005 02 09
#
# Has a new front page, which allows curation of a new paper (which
# takes you to the previous default page), querying postgres (which
# doesn't do anything since there are no tables in postgres), and query
# dev.wormbase.org for a paper (in WBPaper00005357 format, if you want a
# different format, let me know, what people would want to type in, e.g.
# pmid123455612 or cgc1234 or whatever, or I could have a drop-down menu
# for pmid/cgc/WBPaper then the box for just the number, although people
# may not want that since it's an extra box [I wouldn't like that])
# 
# After selecting a Paper, there's a link to the Alleles, Transgenes,
# and RNAis in dev.wormbase.org, and can also click a Curate button.
# 
# If clicking any Curate button, it will enter the type and mainname if
# available.  It defaults to one Big Box, and two horizontal boxes.
# 
# The main Form now has a ``More Boxes !'' button, and an ``Add Big
# Boxes !'' button.  Clicking either button reads all the data,
# recreates the form with more boxes as appropriate, and fills in the
# data that was read.
# 
# Preview, Save, Load, Reset, and Query still don't do anything.  2005 04 06
#
# Front page queries paper or object.  (object query doesn't do anything
# though, since I'm not sure what the point of querying wormbase is)
# Query paper now has a new entry to curate as well as the found
# entries.
# There is no query button in the main page.
# There's a checkbox next to paper reference.
# Phenotype term editing has new order and includes Erich's file and
# Jonathan's files.  2005 04 13
#
# &checkWB{$type, $mainname} looks at Report page and tries to see if there's
# data there.  Then returns a $found flag 0 or 1.  2005 04 15
#
# Changed layout of &printHtmlForm(); to have multiple columns for most data
# for Carol.  2005 04 18
#
# Added Remark, Delivered By, and Haploinsufficient (checkbox).
# Created &printHtmlMultSelectInput('sensitivity', 'degree', $i, $theHash{horiz_mult}{html_value}, size);
# which is a side-by-side Select and Input for multiples of Penetrance /  Percent, 
# Temp. Sens. / Degree.
# Added a ``Toggle Hide !'' button which toggles the $theHash{hide_or_not}{html_value} 
# variable which is default 1, which prints the boxes.  2005 04 19
#
# Changed ``Query Paper !'' and ``Curate Object !'' to check that there's data
# and prints error if not.  ``Query Paper !'' now shows the ``Curate Object !'' 
# menu instead of a button for a new entry.  2005 04 21
#
# Took out link to Phenotype Ontology Terms since everyone has their own list
# in a different program.  Added function to link to Suggested Terms to edit
# like the PO Terms.  
# Replaced Penetrance values with Incomplete, Low, High, Complete.
# Added Suggested Term's Reference and Suggested Term's Definition (sug_ref sug_term)
# Added GO Term Suggestion (go_sug)
# Added Genetic Interaction Description (intx_desc)  2005 08 25
#
# NOTE this form's preview doesn't do anything, doesn't write to PG, etc.
#
# Added NOT checkbox, referring to Phenotype Ontology Term.  2005 10 13
#
# Created pg tables and added &preview(); &write(); and related subroutines.
# 2005 10 18
#
# Query Paper strips out pmid/PMID.
# Replaced mainname with tempname, which is always joinkey.
# finalname comes from postgres unless (no postgres entry) && (dev site entry)
# 2005 10 20
#
# Changed &write(); to only make changes if the form and postgres differ.
# Used &deep_copy(); to fully copy all the values from %theHash, then loading
# postgres values into %theHash, then copying the horiz/group/hide values from
# the copy if those were greater than the postgres values, then compaing each
# of the two hashes and making changes if they differ.  2005 10 25
#
# Extracted wbgenes always come from dev site, but show postgres values
# just in case.  Added for Transgene and Allele, but not yet RNAi.  2005 10 26
#
# Getting RNAi from tree display, getting wbgene and cds.  2005 10 27
#
# Added Multi-Allele option, which doesn't query wormbase.  2005 11 14
#
# There is an ``RNAi Brief Description'' box outside the big boxes.
# Off the front page there is an ``Update RNAi'' button, which shows a
# table of RNAi data sorted by tempname in two groups : without final 
# name ;  with final name.  There are links to the Paper Display to get
# PDFs.  There are links to ``Get Data'' which shows all the data in
# text format, which can be right-click + saved, or left-clicked and
# opened in a new window.  There's a Confirm RNAi button which works
# only on that row of data (that tempname).  
# 
# &getRNAi(); only wants text, so most of the form is now inside an else
# statement.  4 more subroutines : &updateRNAi(); which shows a table of
# RNAi data ;  &getRNAi(); which gives a text display of RNAi data ;  
# &confirmRNAi(); which updates RNAi data ;  &getRNAiLine(); which gets a
# line of RNAi data for &updateRNAi(); to display.  2005 11 14
#
# only show rnai brief description if the data refers to rnai.  2005 11 16
# Changed &findIfPgEntry(); to see if it's RNAi data, if so, check
# alp_finalname, (if fails) then alp_tempname, (if fails) then create a new
# temprnai name to use as the temp name.  
# Changed &checkWB(); to took at RNAi data from aceserver instead of dev
# site like other data types.  2005 11 16
#
# Changed &paperQuery(); to find the WBPaper number from dev.wormbase
# if curating via paper, then changed &curate(); to see if there's a value
# ( html_value_wbpaper_result ), and add a big box with that paper for paper
# reference if the paper doesn't already exist in that object.
# for Carol.  2005 11 17
#
# Further check if there are any values to determine whether to assign the
# wbpaper to the first big box (if there aren't any terms) or to create a 
# new big box and add it there.
# &paperQuery(); now also converts the paper to a wbpaper, checks all 
# tempnames in postgres associated with that wbpaper, the type for that
# tempname, then creates a line to curate that object.  2005 11 18
#
# No longer need the Query Gene button.  for Carol.  2005 11 18
#
# No longer hyperlink suggested term.  for Carol.  2005 11 22
#
# &getRNAiLine(); now also shows the pmid based on wpa_identifier.
# added Variation curation to work like RNAi curation.  2005 11 22 
#
# Added  Quantity Remark  and  Quantity  2005 11 22
#
# &paperQuery(); now checks wpa_rnai_curation to see if the paper has 
# been checked out for rnai curation.  Also filters wbpapers in a hash
# instead of pushing in an array.  2005 11 22
#
# Changed &updateRNAi(); to be &updateFinalname();  and &confirmRNAi();
# to be &confirmFinalname();.  Changed &getRNAi(); to be &getData();, so
# now all three data types use the same functions.  2005 11 23
#
# Replace sensitivity and degree with heat_sens & heat_degree and cold_sens
# & cold_degree (checkbox text).  change effect into mat_effect and 
# pat_effect (checkbox).  For Carol.  2005 12 05
#
# Changed &curate(); to no longer require a tempname when the type is RNAi.
# For Carol.  2005 12 05
#
# Changed &getHtmlValuesFromForm(); to convert paper entries into a 
# WBPaper (paper entry) to make it easier to check if a given paper has
# finished curating.  For Carol.
# Changed &paperQuery(); to check the joinkey and alp_box of objects with
# a given wbpaper being queried, to see if it's been finished curating in
# corresponding alp_finished.  For Carol.
# Changed &updateFinalname(); to sort entries by WBPaper.  For Mary Ann.
# 2005 12 06
#
# Changed &updateFinalname(); to have a separator line between those with and
# those without final name.  For Mary Ann.  2005 12 08
#
# Created &dump(); which syscalls a wrapper to dump all .ace objects and symlink
# to it.  2005 12 16
#
# If there's a phenotype term in a box, require a curator (check all boxes)
# 2006 04 02
#
# Show ale_ data from allele.cgi submission form if it hasn't been marked as
# curated for allele_phenotype data.  For Carol.  2006 04 20
#
# Added Penetrance Range, changed Penetrance / Percent to Penetrance / Text.
# For Carol.  2006 04 26
#
# Changed the class display for Life Stage to work based off of the aceserver.
# For Carol.  2006 05 18
#
# Changed the Update Variation and so forth to a checkbox system where multiple
# entries can be changed at once.  Added a Page system so that all things aren't
# shown at once (which takes forever to query everything).  For Mary Ann  2006 07 13
#
# Added a More Boxes button above the NOT field, and added column name shorthand 
# to all the boxes and options.  For Carol  2006 08 25
#
# Added alp_anat_term like temperature.  For Carol  2006 08 25
#
# For Mary Ann if Update Variation, only show those without a final name, and 
# split them up in older than a day and recent.  2006 10 23
#
# Added ale_haploinsufficient to &seeSubmissions(); and linked
# ale_person_evidence to ther person_name.cgi  
# Dumping data is causing a problem with Apache, so changed the wrapper.pl to
# find the entries individually and write them individually.  The page still
# hangs, but the output comes out okay.  2006 12 11
#
# Change alp_curator to have columns as well as boxes.  2007 04 23
# 
# Add a Strain check based on the Strain list from Ace Server
# Add a Life Stage check based on Life Stage link (pipe separated for multiple
# life stages).  For Carol.  2007 04 27
#
# Add symlink to allele_phenotype_papers.ace which has been created in
# get_all.pl  2007 06 08
#
# Added Jolene Fernandes and took out Carol  2007 07 13
#
# Added Karen Yook.
# Flipped order of  Curate Object  and  Query Paper  2007 08 01
#
# created new field Object Remark which stores data for a given object, but
# still want to keep association to Reference, so putting it inside the big box,
# but don't want to make it part of Reference List in Phenote, so putting it in
# a column for convenience.  Moved all but 2 Remark entries into Object Remark
# (alp_obj_remark) and renamed Remark into Paper Remark.  For Gary.  2007 08 22
#
# Paper Remark should now append to all paper remarks in all boxes with the same
# paper reference.  If there's a Paper Remark, check that there's a paper.  If
# so, get all objects/boxes with matching papers, get all their remarks,
# concatenate them (unless they're already in the concatenation), if the
# currently curating remark is not in the concatenation, concatenate it ;  then
# make this new full remark the Paper Remark for all those object/boxes with
# that Paper Reference.  For Gary.  2007 08 22
#
# Class data now comes from script that updates everyday off of aceserver to
# avoid having to query each time.  RNAi no longer queries aceserver (since it's
# not being used, and the aceserver has been crashing).  For Gary  2007 08 23
#
# Created alp_paper_remark to store all object names, wbpapers, and paper
# remarks.  Then when querying a postgres box check the alp_paper, and see if
# there are any paper remarks with that paper, and concatenate-display them in
# text only.  For Gary  2007 08 24
#
# Changed the order of the column fields, moved some of the group fields down,
# changed the hidden fields, made the geneace text un-editable, moved toggle
# hide to the top, moved ``more boxes'' to be with each column at the top, with
# the allele / object name.  Changed the order of the boxes and columns to
# reverse order (so that when creating it's at the top or left).  Hide toggle
# by default.  Only show field values when doing a getHtmlValuesFromForm when
# it's a Preview, Update, or New Entry.  Move cold sens up to heat sens and
# rename tag Temp sens again.  For Karen  2007 10 01
#
# made a popup new window for the geneace test.  For Karen  2007 10 02


use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate
use Pg;
use LWP::UserAgent;	# getting sanger files for querying
use Ace;
use lib qw( /home/postgres/work/citace_upload/allele_phenotype/ );
use get_allele_phenotype_ace;

my $query = new CGI;	# new CGI form
my $conn = Pg::connectdb("dbname=testdb");	# connect to postgres database
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %theHash;		# huge hash for each field with relevant values
my @PGparameters;	# array of names of pg values for html, pg, and theHash

my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper
my %phenotypeTerms;	# $phenotypeTerms{term} = number; $phenotypeTerms{number} = term;


my $curator = '';
my $data_file = '/home/postgres/public_html/cgi-bin/data/allele_phenotype.txt';

my @genParams = qw ( type tempname finalname wbgene rnai_brief );
# my @groupParams = qw ( paper person finished phenotype remark intx_desc );
my @groupParams = qw ( paper person finished phenotype paper_remark intx_desc );
my @multParams = qw ( curator not term phen_remark quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anat_term temperature strain preparation treatment delivered nature penetrance range percent mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo obj_remark );

my ($var, $action) = &getHtmlVar($query, 'action');
unless ($action) { $action = ' '; }
if ($action eq "Get Data !") { &getData(); }		# plain text
else {
  &printHeader('Allele-Phenotype Curation Form');	# normal form view
#   print "<FONT COLOR=red SIZE=+4>UNDER CONSTRUCTION don't use</FONT>\n";
  &initializeHash();	# Initialize theHash structure for html names and box sizes
  &process();		# do everything
  &printFooter(); }

sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { $action = ''; }
  if ($action eq '') { &printHtmlMenu(); }		# Display form, first time, no action
  else { 						# Form Button
    print "ACTION : $action : ACTION<BR>\n"; 
    if ($action eq 'Curate Object !') { &curate(); } 	# check locus and curator 
    elsif ($action eq 'Preview !') { &preview(); } 	# check locus and curator 
    elsif ($action eq 'New Entry !') { &write(); } 	# write to postgres (INSERT)
    elsif ($action eq 'Update !') { &write(); }		# write to postgres (UPDATE)
    elsif ($action eq 'Query Paper !') { &paperQuery(); }		# query wormbase for papers
#     elsif ($action eq 'Query WBGene !') { &geneQuery(); }		# don't need the query button
    elsif ($action eq 'Update RNAi !') { &updateFinalname('RNAi'); }		# table of RNAi data for Igor
    elsif ($action eq 'Update Transgene !') { &updateFinalname('Transgene'); }	# table of Transgene data for Wen
    elsif ($action eq 'Update Variation !') { &updateFinalname('Allele'); }	# table of Variation data for Mary Ann
    elsif ($action eq 'Dump .ace !') { &dump(); }	# dump all .ace data
#     elsif ($action eq 'Test cvs !') { &testCvs(); }	# test cvs
    elsif ($action eq 'Confirm Final Name !') { &confirmFinalname(); }		# confirm final name data for Igor, Wen, Mary Ann
    elsif ($action eq 'Reset !') { &reset(); }		# reinitialize %theHash and display form
    elsif ($action eq 'Save !') { &saveState(); }		# save to file
    elsif ($action eq 'Load !') { &loadState(); }		# load from file
    elsif ($action eq 'Options !') { &options(); }		# options menu (empty)
    elsif ($action eq 'paper') { &paper(); }		# Paper sub-form
    elsif ($action eq 'term') { &term(); }			# Term sub-form
    elsif ($action eq 'suggested') { &suggested(); }		# Suggested sub-form
    elsif ($action eq 'Update paper !') { &updatePaper(); }	# change Paper Data
    elsif ($action eq 'Update Kimberly !') { &updateTerm(); }		# change Term Data
    elsif ($action eq 'Update Erich !') { &updateTerm(); }		# change Term Data
    elsif ($action eq 'Update Jonathan !') { &updateTerm(); }		# change Term Data
    elsif ($action eq 'Update Jonathan Non !') { &updateTerm(); }	# change Term Data
    elsif ($action eq 'Update Suggested !') { &updateTerm(); }		# change Suggested Data
    elsif ($action eq 'Add Big Boxes !') { &addGroup(); }		# 
    elsif ($action eq 'More Boxes !') { &addMult(); }			# 
    elsif ($action eq 'Toggle Hide !') { &toggleHide(); }		# 
    elsif ($action eq 'See Submissions') { &seeSubmissions(); }		# see allele.cgi submission form data needing curation
    elsif ($action eq 'Done !') { &submissionCurated(); }		# mark ale_curated table for allele submission data
    elsif ($action eq 'Class') { &displayClass(); }		# show data for a given acedb class
    elsif ($action eq 'popup') { &popup(); }		# show data for a given acedb class
    print "ACTION : $action : ACTION<BR>\n"; 
  } # else # if ($action eq '') { &printHtmlForm(); }
} # sub process

sub popup {
  my ($var, $popup) = &getHtmlVar($query, 'value');
  print "$popup<BR>\n";
} # sub popup

sub readCvs {
  my $directory = '/home/postgres/work/citace_upload/allele_phenotype/temp';
  chdir($directory) or die "Cannot go to $directory ($!)";
  `cvs -d /var/lib/cvsroot checkout PhenOnt`;
  my $file = $directory . '/PhenOnt/PhenOnt.obo';
  $/ = "";
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $para = <IN>) { 
    if ($para =~ m/id: WBPhenotype(\d+).*?\bname: (\w+)/s) { 
      my $term = $2; my $number = 'WBPhenotype' . $1;
      $phenotypeTerms{term}{$term} = $number;
      $phenotypeTerms{number}{$number} = $term; } }
  close (IN) or die "Cannot close $file : $!";
  $/ = "\n";
  $directory .= '/PhenOnt';
  `rm -rf $directory`;
#   foreach my $term (sort keys %{ $phenotypeTerms{term} }) { print "T $term N $phenotypeTerms{term}{$term} E<BR>\n"; }
} # sub readCvs

sub confirmFinalname {							# update postgres with the finalname assigned by Igor
  my ($var, $per_page) = &getHtmlVar($query, 'per_page');		# use a checkbox system for Mary Ann to update multiple things at once  2006 07 13
  for my $line_count ( 1 .. $per_page ) {
    my ($var, $checked) = &getHtmlVar($query, "checked_$line_count");
    next unless ($checked eq 'checked');
    ($var, my $tempname) = &getHtmlVar($query, "tempname_$line_count");
    ($var, my $final) = &getHtmlVar($query, "final_$line_count");
    my $command = "INSERT INTO app_finalname VALUES ('$tempname', '$final', CURRENT_TIMESTAMP); ";
    my $result = $conn->exec( "$command" );
    print "$command<BR>\n";
    print "$tempname : $final<BR>\n";
  } # for my $line_count ( 1 .. $per_page )
  ($var, my $page) = &getHtmlVar($query, 'page');			# display a page selector to go back to the previous page
  ($var, my $pages) = &getHtmlVar($query, 'pages');
  ($var, my $type) = &getHtmlVar($query, 'type');
  print "<FORM METHOD=POST ACTION=http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi>\n";
  print "Go back to the same page : <SELECT NAME=\"page\" SIZE=1>\n";
  foreach (1 .. $pages) { if ($_ == $page) { print "      <OPTION SELECTED>$_</OPTION>\n"; } else { print "      <OPTION>$_</OPTION>\n"; } }
  print "    </SELECT>\n";
  if ($type eq 'RNAi') { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update RNAi !\">\n"; }
  elsif ($type eq 'Transgene') { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Trasgene !\">\n"; }
  elsif ($type eq 'Allele') { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Variation !\">\n"; }
  print "</FORM>\n";
} # sub confirmFinalname

sub updateFinalname {							# get list of $type data for curators to assign a final name
  my $type = shift;							# this should work for rnai, variation (allele), transgene 
  my ($var, $page) = &getHtmlVar($query, 'page');
  unless ($page) { $page = 0; } else { $page--; }			# subtract from page to count arrays from zero
  my %rnai; my %final; my %paper; my @rnai; my @final; my @nofinal;
  my $result = $conn->exec( "SELECT * FROM app_type WHERE app_type = '$type'; ");
  while (my @row = $result->fetchrow) { $rnai{$row[0]}++; }
  $result = $conn->exec( "SELECT * FROM app_finalname ORDER BY app_timestamp; ");
  while (my @row = $result->fetchrow) { $final{$row[0]} = $row[1]; }
  $result = $conn->exec( "SELECT * FROM app_paper ORDER BY app_timestamp; ");
  while (my @row = $result->fetchrow) { if ($row[2]) { $paper{$row[0]} = $row[2]; } }
  print "<TABLE BORDER=1>\n";
  print "<TR><TD>temp name</TD><TD>final name</TD><TD>WBPaper</TD><TD>Get text data</TD><TD>Confirm final name</TD></TR>\n";
  my $withfinal = ''; my $withoutfinal = '';				# entries with finalname / without finalname for printing
  foreach my $tempname (sort { $paper{$a} <=> $paper{$b} } keys %rnai) {	# sort by papers for Mary Ann 2005 12 06
    if ($final{$tempname}) { push @final, $tempname; }			# store finals and no finals in an array
      else { push @nofinal, $tempname; } }
  if ($type eq 'Allele') { 	# for Mary Ann only show those without Final name in two groups, older than a day and recent 2006 10 23
    @final = (); 							# don't show final names for Variation for Mary Ann
    my %nofinal = ();  foreach my $nofinal (@nofinal) { $nofinal{$nofinal}++; }	# put in hash to check if should store them
    my @first; my @second; @nofinal = ();				# order nofinals in two groups for Mary Ann (one day recent, and older)
    $result = $conn->exec( " SELECT * FROM app_type WHERE app_type = 'Allele' AND app_timestamp > ( SELECT date_trunc('second', now())-'1 days'::interval ) ORDER BY joinkey; " );
    while (my @row = $result->fetchrow) { if ($nofinal{$row[0]}) { push @first, $row[0]; } }	# those recent than one day in apphabetical order
    $result = $conn->exec( " SELECT * FROM app_type WHERE app_type = 'Allele' AND app_timestamp <= ( SELECT date_trunc('second', now())-'1 days'::interval ) ORDER BY joinkey; " );
    while (my @row = $result->fetchrow) { if ($nofinal{$row[0]}) { push @second, $row[0]; } }	# those older than one day in apphabetical order
    foreach (@first) { push @nofinal, $_; } foreach (@second) { push @nofinal, $_; }	# put them back in nofinal array for display
  } # if ($type eq 'Allele') 
  my $nofinals = scalar(@nofinal);					# entries without a final name
  my $per_page = 20;							# entries per page
  my $pages = 1 + (scalar (@final) / $per_page) + (scalar (@nofinal) / $per_page);		# find out how many pages there are
  for (1 .. ($page * $per_page)) { if (@nofinal) { shift @nofinal; } else { shift @final; } }	# depending on the page, skip entries from nofinal and then from final
  for my $line_number (1 .. $per_page) {
    my $tempname;							# grab the tempname from nofinal or final as appropriate
    if (@nofinal) { $tempname = shift @nofinal; }
      elsif (@final) { $tempname = shift @final; }
      else { next; }
    my $line = &getFinalnameLine($tempname, $final{$tempname}, $paper{$tempname}, $line_number);	# generate the line
    if ($final{$tempname}) { $withfinal .= $line; }			# put it with final or without final as appropriate
      else { $withoutfinal .= $line; } }

  $page++;								# add back the subtracted one for displaying the page number counting from 1
  print "<FORM METHOD=POST ACTION=http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi>\n";
  print "<INPUT TYPE=HIDDEN NAME=per_page VALUE=$per_page>\n";
  print "<INPUT TYPE=HIDDEN NAME=pages VALUE=$pages>\n";
  print "<INPUT TYPE=HIDDEN NAME=type VALUE=$type>\n";
  print "Select another page : <SELECT NAME=\"page\" SIZE=1>\n";
  foreach (1 .. $pages) { if ($_ == $page) { print "      <OPTION SELECTED>$_</OPTION>\n"; } else { print "      <OPTION>$_</OPTION>\n"; } }
  print "    </SELECT>\n";
  if ($type eq 'RNAi') { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update RNAi !\">\n"; }
  elsif ($type eq 'Transgene') { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Trasgene !\">\n"; }
  elsif ($type eq 'Allele') { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Variation !\">\n"; }
  print " (and click this button)<BR><BR>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Confirm Final Name !\"><BR>\n"; 
  print "$withoutfinal<TR><TD colspan=5><FONT COLOR=green>The following already have been curated and already have a final name.</FONT></TD></TR>$withfinal";
  print "</TABLE>\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Confirm Final Name !\"><BR>\n"; 
  print "</FORM>\n";
} # sub updateFinalname

sub getFinalnameLine {							# get a table row of type data
  my ($tempname, $final, $paper, $line_number) = @_;
#   my $line = "<FORM METHOD=POST ACTION=http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi>\n";
  my $line = "<INPUT TYPE=HIDDEN NAME=\"tempname_$line_number\" VALUE=\"$tempname\">\n";
  $line .= "<TR><TD>$tempname</TD><TD><INPUT NAME=\"final_$line_number\" VALUE=$final></TD>\n";
  my $paper_link = $paper; if ($paper =~ m/(\d{8})/) { $paper_link = $1; }
  if ($paper_link) { my $result = $conn->exec( "SELECT wpa_identifier FROM wpa_identifier WHERE joinkey ~ '$paper_link' AND wpa_identifier ~ 'pmid';" );
    my @row = $result->fetchrow; if ($row[0]) { $paper .= '(' . $row[0] . ')'; } }		# add pmid for Mary Ann  2005 11 22
  $line .= "<TD><A HREF=http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_display.cgi?action=Number+%21&number=$paper_link TARGET=new>$paper</A>&nbsp;</TD>\n";
  $line .= "<TD><A HREF=http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=Get+Data+%21&tempname=$tempname TARGET=new>Get Data</A></TD>\n";
  $line .= "<TD><INPUT NAME=\"checked_$line_number\" TYPE=\"checkbox\" VALUE=\"checked\">";
#   $line .= "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Confirm Final Name !\"></TD></TR>\n"; 
#   $line .= "</FORM>\n";
  return $line;
} # sub getFinalnameLine

sub getData {								# get data in text format for igor (or whoever)
  print "Content-type: text/plain\n\n";
  my ($var, $tempname) = &getHtmlVar($query, 'tempname');
  &initializeHash();					# reset all %theHash values to prevent any %form values to linger if postgres values don't exist to replace them
  &queryPostgres($tempname);				# get postgres values
  my $temp_horiz = $theHash{horiz_mult}{html_value}; my $temp_group = $theHash{group_mult}{html_value}; my $temp_hide = $theHash{hide_or_not}{html_value};
  foreach my $type (@genParams) {
    if ($theHash{$type}{html_value}) {
      print "$type\t\"$theHash{$type}{html_value}\"\n"; } }
  foreach my $type (@groupParams) {
    for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
      my $g_type = $type . '_' . $i;					# call g_type (group, maybe)
      if ($theHash{$g_type}{html_value}) {
        print "$g_type\t\"$theHash{$g_type}{html_value}\"\n"; } } }
  foreach my $type (@multParams) {
    for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
      for my $j (1 .. $theHash{horiz_mult}{html_value}) {		# different column values
        my $ts_type = $type . '_' . $i . '_' . $j;			# call ts_type (don't recall why)
        if ($theHash{$ts_type}{html_value}) {
          print "$ts_type\t\"$theHash{$ts_type}{html_value}\"\n"; } } } }
} # sub getData


sub preview {
  my $joinkey = &getHtmlValuesFromForm(); 		# populate %theHash and get joinkey

  print <<"  EndOfText";
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi">
    <INPUT TYPE="HIDDEN" NAME="horiz_mult" VALUE="$theHash{horiz_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="group_mult" VALUE="$theHash{group_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="hide_or_not" VALUE="$theHash{hide_or_not}{html_value}">
  EndOfText


  if ($theHash{type}{html_value}) { 
    if ($theHash{type}{html_value} =~ m/\"/) { $theHash{type}{html_value} =~ s/\"/&quot;/g; } 
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_type\" VALUE=\"$theHash{type}{html_value}\">\n"; }
  if ($theHash{tempname}{html_value}) { 
    if ($theHash{tempname}{html_value} =~ m/\"/) { $theHash{tempname}{html_value} =~ s/\"/&quot;/g; }
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_tempname\" VALUE=\"$theHash{tempname}{html_value}\">\n"; }
  if ($theHash{finalname}{html_value}) { 
    if ($theHash{finalname}{html_value} =~ m/\"/) { $theHash{finalname}{html_value} =~ s/\"/&quot;/g; }
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_finalname\" VALUE=\"$theHash{finalname}{html_value}\">\n"; }

  foreach my $type (@genParams) {
    my $val = $theHash{$type}{html_value};
    if ($val) { 
      if ($val =~ m/\"/) { $val =~ s/\"/&quot;/g; }
      print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_$type\" VALUE=\"$val\">\n"; } }

  foreach my $type (@groupParams) {
    for my $i (1 .. $theHash{group_mult}{html_value}) {
      my $g_type = $type . '_' . $i;
      my $val = $theHash{$g_type}{html_value};
      if ($val) { 
        if ($val =~ m/\"/) { $val =~ s/\"/&quot;/g; }
        print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_$g_type\" VALUE=\"$val\">\n"; } } }

  foreach my $type (@multParams) {
    for my $i (1 .. $theHash{group_mult}{html_value}) {
      for my $j (1 .. $theHash{horiz_mult}{html_value}) {
        my $ts_type = $type . '_' . $i . '_' . $j;
        my $val = $theHash{$ts_type}{html_value};
        if ($val) { 
          if ($val =~ m/\"/) { $val =~ s/\"/&quot;/g; }
          print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_$ts_type\" VALUE=\"$val\">\n"; } } } }

  my $data_bad = 0;
  for my $i (0 .. $theHash{group_mult}{html_value}) {	# if there's a phenotype term in a box, require a curator 2006 04 02
    for my $j (0 .. $theHash{horiz_mult}{html_value}) {	# if there's a phenotype term in a column, require a curator 2007 04 23
      my $term = 'term_' . $i . '_'. $j;
      if ($theHash{$term}{html_value}) { 
        $term = 'curator_' . $i . '_' . $j;
        unless ($theHash{$term}{html_value}) { print "<FONT COLOR='red'>BAD no curator in box $i column $j</FONT><BR>\n"; $data_bad++; } }
    } # for my $j (0 .. $theHash{horiz_mult}{html_value}) 
  } # for (0 .. $theHash{group_mult}{html_value})
  if ($data_bad) { return; }
  
  my $found = &findIfPgEntry("$theHash{tempname}{html_value}");		# if tempname, check if already in Pg
  if ($found) { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update !\"> <FONT COLOR=red>(this will overwrite previous entries)</FONT>\n"; }
    else { print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"New Entry !\">\n"; } 
  print "</FORM>\n";
} # sub preview

sub findIfPgEntry {	# check postgres for locus entry already in
  my $joinkey = shift;
  my $found;
  if ($theHash{type}{html_value} eq 'RNAi') { 
    my $result = $conn->exec( "SELECT * FROM app_finalname WHERE app_finalname = '$joinkey' ORDER BY app_timestamp DESC;" );
    my @row = $result->fetchrow; 
    if ($row[0]) { $theHash{tempname}{html_value} = $row[0]; return $row[0]; }			# found finalname
    $result = $conn->exec( "SELECT * FROM app_tempname WHERE joinkey = '$joinkey';" );
      # if there's null or blank data, change it to a space so it will update, not insert 
    while (my @row = $result->fetchrow) { $found = $row[1]; if ($found eq '') { $found = ' '; } }
    if ($found) { return $found; }			# found tempname
    $result = $conn->exec( "SELECT * FROM app_tempname WHERE joinkey ~ 'temprnai' ORDER BY joinkey DESC;" );
    @row = $result->fetchrow; print "Getting new tempname number<BR>\n"; my $tempname;
    if ($row[0]) { $tempname = $row[0]; $tempname =~ s/temprnai//g; $tempname++; }
      else { $tempname = 1; }
    $tempname = &padZeros($tempname); $tempname = 'temprnai' . $tempname; 
    $theHash{tempname}{html_value} = $tempname;		# creating a new tempname
    return ''; }
  else {
    my $result = $conn->exec( "SELECT * FROM app_tempname WHERE joinkey = '$joinkey';" );
      # if there's null or blank data, change it to a space so it will update, not insert 
    while (my @row = $result->fetchrow) { $found = $row[1]; if ($found eq '') { $found = ' '; } } }
  return $found;
} # sub findIfPgEntry

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey; 
} # sub padZeros


sub deep_copy {		# got this code from http://www.stonehenge.com/merlyn/UnixReview/col30.html by Randal L. Schwartz
  my $this = shift;
  if (not ref $this) { $this; } 
  elsif (ref $this eq "ARRAY") { [map deep_copy($_), @$this]; } 
  elsif (ref $this eq "HASH") { +{map { $_ => deep_copy($this->{$_}) } keys %$this}; } 
  else { die "what type is $_?" }
} # sub deep_copy

sub write {
    # currently it only writes data when there's values, so it requires blank to overwrite old data with empty data
  print "Scroll below to see what the .ace will look like.<P>\n";
  my $joinkey = &getHtmlValuesFromForm(); 		# populate %theHash and get joinkey
  print "<P>JOINKEY $joinkey<BR>\n";			# display joinkey
  my $href = \%theHash;					# make a hashref for &deep_copy() to work
  my $fref = &deep_copy($href);				# create a hashref to a full copy of %theHash
  my %form = %$fref;					# create a hash corresponding to that hash's values, that is, the form's values
  my $temp_horiz = $theHash{horiz_mult}{html_value}; 	# back up three values that will be wiped out when initialized 
  my $temp_group = $theHash{group_mult}{html_value}; my $temp_hide = $theHash{hide_or_not}{html_value};
  &initializeHash();					# reset all %theHash values to prevent any %form values to linger if postgres values don't exist to replace them
  &queryPostgres($joinkey);				# get postgres values
  if ($temp_horiz > $theHash{horiz_mult}{html_value}) { $theHash{horiz_mult}{html_value} = $temp_horiz; }	# if form had more, set to those
  if ($temp_group > $theHash{group_mult}{html_value}) { $theHash{group_mult}{html_value} = $temp_group; }	# if form had more, set to those
  if ($temp_hide > $theHash{hide_or_not}{html_value}) { $theHash{hide_or_not}{html_value} = $temp_hide; }	# if form had more, set to those
  my %pg = %theHash;					# shallow (bad) copy of %theHash, is okay unless %theHash changes again
  my $pgcommand = '';					# the commands for postgres

  print "<P>\n";
  foreach my $type (@genParams) {
    unless ($form{$type}{html_value}) { $form{$type}{html_value} = ''; }
    unless ($pg{$type}{html_value}) { $pg{$type}{html_value} = ''; }
    if ($form{$type}{html_value} ne $pg{$type}{html_value}) {		# if values are different do something, otherwise don't
      my $fval = $form{$type}{html_value};				# the form value
      my $pval = $pg{$type}{html_value};				# the postgres value
      $fval = &filterForPostgres($fval);
      if ($fval) { $fval = "'$fval'"; } else { $fval = 'NULL'; }	# put quotes or NULL for $pgcommand to work
      if ($pval) { $pval = "'$pval'"; } else { $pval = "BLANK"; }	# put quotes or BLANK for display
      $pgcommand = "INSERT INTO app_$type VALUES ('$joinkey', $fval, CURRENT_TIMESTAMP);"; 		# command to insert values
      my $result = $conn->exec( "$pgcommand" );								# insert to postgres
      print "$type said <FONT COLOR=blue>$pval</FONT> now says <FONT COLOR=green>$fval</FONT>.<BR>\n";	# display changes
      print "$pgcommand<BR>\n"; } }									# display command for error checking

  foreach my $type (@groupParams) {
#     if ($type eq 'remark') {				# paper remark needs to concatenate all remarks for the same paper  2007 08 22
#       for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
#         my $paper_type = 'paper_' . $i;  my ($paper) = $form{$paper_type}{html_value} =~ m/(WBPaper\d+)/;	# grab the WBPaper\d+ 
#         unless ($paper) { print "<FONT COLOR=red>ERR No paper found, not updating paper remark</FONT><BR>\n"; next; } # if there's no paper skip this box / object
#         my $full_remark;				# grow the full remark into this variable by appending after `` -- ''
#         my %has_paper;					# store join and box with matching papers here
#         my $result = $conn->exec( "SELECT * FROM app_paper WHERE app_paper ~ '$paper';" );	# get join and box with matching papers
#         while (my @row = $result->fetchrow) { 		# loop through all of these
#           my $join = $row[0]; my $box = $row[1]; $has_paper{$join}{$box}++;			# store them in the hash
#           my $result2 = $conn->exec( "SELECT * FROM app_remark WHERE joinkey ~ '$join' AND app_box = '$box' ORDER BY app_timestamp DESC;" );
#           my @row2 = $result2->fetchrow; 		# get the latest remark from each of those join / box with that paper
#           if ($row2[2]) { unless ($full_remark =~ m/\Q$row2[2]\E/) { $full_remark .= " -- $row2[2]"; } } }		# unless it's already in the full remark, append it
# 							# (don't interpolate the variable to get an exact match)
#         my $g_type = $type . '_' . $i;					# call g_type (group, maybe)
#         unless ($full_remark =~ m/\Q$form{$g_type}{html_value}\E/) {	# if the form data is not already in the full remark
# 									# (don't interpolate the variable to get an exact match)
#           $full_remark .= " -- $form{$g_type}{html_value}"; 		# append it to the full remark
#           $full_remark =~ s/^ -- //;					# get rid of wrong leading separator
#           $has_paper{$joinkey}{$i}++; 					# add current join and box to list of joins and box with paper
#           foreach my $joinkey (sort keys %has_paper) {			# for all joins and box with matching paper
#             foreach my $i (sort keys %{ $has_paper{$joinkey} }) {
#               $pgcommand = "INSERT INTO app_remark VALUES ('$joinkey', '$i', '$full_remark', CURRENT_TIMESTAMP);"; 
#               my $result = $conn->exec( "$pgcommand" );			# add the full remark overwriting the old remark
#               print "remark said now says <FONT COLOR=green>$full_remark</FONT>.<BR>\n";
#               print "$pgcommand<BR>\n"; } } } } }
    if ($type eq 'paper_remark') {			# append all paper remarks
      for my $i (1 .. $theHash{group_mult}{html_value}) {		# different box values
        my $g_type = $type . '_' . $i;					# call g_type (group, maybe)
        next unless ($form{$g_type}{html_value});	# skip if there's no value (don't append blanks)
        my $paper_type = 'paper_' . $i;  my ($paper) = $form{$paper_type}{html_value} =~ m/(WBPaper\d+)/;	# grab the WBPaper\d+ 
        unless ($paper) { print "<FONT COLOR=red>ERR No paper found, not updating paper remark</FONT><BR>\n"; next; } # if there's no paper skip this box / object
        my $fval = $form{$g_type}{html_value};
        $fval = &filterForPostgres($fval);
        $pgcommand = "INSERT INTO app_$type VALUES ('$joinkey', '$paper', '$fval', CURRENT_TIMESTAMP);"; 
        my $result = $conn->exec( "$pgcommand" );
        print "Appending $fval for paper $paper.<BR>\n";
        print "<FONT COLOR=green>$pgcommand</FONT><BR>\n";
    } }
    else {						# everything but remark updates current data for that cell only
      for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
        my $g_type = $type . '_' . $i;					# call g_type (group, maybe)
        unless ($form{$g_type}{html_value}) { $form{$g_type}{html_value} = ''; }
        unless ($pg{$g_type}{html_value}) { $pg{$g_type}{html_value} = ''; }
        if ($form{$g_type}{html_value} ne $pg{$g_type}{html_value}) {	# if values are different
          my $fval = $form{$g_type}{html_value};
          my $pval = $pg{$g_type}{html_value};
          $fval = &filterForPostgres($fval);
          if ($fval) { $fval = "'$fval'"; } else { $fval = 'NULL'; }
          if ($pval) { $pval = "'$pval'"; } else { $pval = "BLANK"; }
          $pgcommand = "INSERT INTO app_$type VALUES ('$joinkey', '$i', $fval, CURRENT_TIMESTAMP);"; 
          my $result = $conn->exec( "$pgcommand" );
          print "$type said <FONT COLOR=blue>$pval</FONT> now says <FONT COLOR=green>$fval</FONT>.<BR>\n";
          print "$pgcommand<BR>\n"; } } } }
  
  foreach my $type (@multParams) {
    for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
      for my $j (1 .. $theHash{horiz_mult}{html_value}) {		# different column values
        my $ts_type = $type . '_' . $i . '_' . $j;			# call ts_type (don't recall why)
        unless ($form{$ts_type}{html_value}) { $form{$ts_type}{html_value} = ''; }
        unless ($pg{$ts_type}{html_value}) { $pg{$ts_type}{html_value} = ''; }
        if ($form{$ts_type}{html_value} ne $pg{$ts_type}{html_value}) {	# if values are different
          my $fval = $form{$ts_type}{html_value};
          my $pval = $pg{$ts_type}{html_value};
          $fval = &filterForPostgres($fval);
          if ($fval) { $fval = "'$fval'"; } else { $fval = 'NULL'; }
          if ($pval) { $pval = "'$pval'"; } else { $pval = "BLANK"; }
          $pgcommand = "INSERT INTO app_$type VALUES ('$joinkey', '$i', '$j', $fval, CURRENT_TIMESTAMP);"; 
          my $result = $conn->exec( "$pgcommand" );
          print "$type said <FONT COLOR=blue>$pval</FONT> now says <FONT COLOR=green>$fval</FONT>.<BR>\n";
          print "$pgcommand<BR>\n"; } } } }

  print "To see results dump the data : \n";		# get_allele_phenotype_ace.pm out of date now that using `/home/postgres/work/citace_upload/allele_phenotype/get_all.pl`;   2007 01 04
  print '<FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi"><INPUT TYPE="submit" NAME="action" VALUE="Dump .ace !">';
#   my ($ace_entry, $err_text) = &getAllelePhenotype( $joinkey );
#   if ($ace_entry) { $ace_entry =~ s/\n/<BR>\n/g; print "The ace entry will look like :<BR><FONT COLOR=green>$ace_entry</FONT><BR><BR>\n"; }
#   if ($err_text) { print "The errors look like :<BR><FONT COLOR=red>$err_text</FONT><BR>\n"; }
} # sub write

sub paperQuery {		# show results of querying dev.wormbase.org for papers
# potentially useful aql query
# select l from l in class Paper where exists l->Rnai and exists l->Transgene and exists l->Allele
  my ($var, $paperquery) = &getHtmlVar($query, 'html_value_main_paperquery');
  if ($paperquery =~ m/^[pP][mM][iI][dD]/) { $paperquery =~ s/^[pP][mM][iI][dD]//g; }
  print "QUERY $paperquery QUERY<BR>\n";
  unless ($paperquery) { print "<FONT COLOR=red><B>ERROR : You must enter a Paper</B></FONT><BR>\n"; return; }
  my $u = "http://dev.wormbase.org/db/misc/paper?name=$paperquery;class=Paper";
#   my $u = "http://dev.wormbase.org/db/misc/etree?name=$paperquery;class=Paper;expand=Refers_to#Refers_to&expand=Allele#Allele";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  unless ($response-> is_success) { print "Wormbase Site is down, $u won't work<BR>\n"; }
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  if ($response->content =~ m/No more information about this object in the database/) { print "$paperquery not in dev.wormbase<BR>\n"; }
  my $wbpaper = ''; if ($response->content =~ m/(WBPaper\d{8});class=Paper\">Tree Display/) { $wbpaper = $1; }
  my (@lines) = $response->content =~ m/\<li\>(.*?)\<\/li\>/g;
  print "<TABLE border=1><TR><TD colspan=2>dev site result</TD></TR>\n";
  foreach my $type ( @{ $theHash{type}{types} } ) { foreach my $line (@lines) { if ($line =~ m/$type/) {
    my (%stuff) = $line =~ m/\"(.*?)\">(.*?)</g;
    %stuff = reverse(%stuff);
    foreach my $name (sort keys %stuff) {
      my $link = 'http://dev.wormbase.org' . $stuff{$name};
      print "<TR><TD>$type : <A HREF=\"$link\">$name</A></TD>\n";	# output link to object in dev site
      printPaperQueryLine($wbpaper, $type, $name); 			# output hidden values for form and button to curate
    } # foreach my $name (sort keys %stuff)
  } } } # foreach my $type ( @{ $theHash{type}{types} } ) foreach my $line (@lines) if ($line =~ m/$type/) 
  my %wbpapers; 
  if ($paperquery =~ m/WBPaper/) { $wbpapers{$paperquery}++; }	# if it's a wbpaper, use it
    else {								# otherwise translate it to wbpapers
      my $result = $conn->exec( "SELECT joinkey FROM wpa_identifier WHERE wpa_identifier ~ '$paperquery';" );
      while (my @row = $result->fetchrow) { if ($row[0]) { $wbpapers{$row[0]}++; } } }	# translate the paper to a wbpaper
  foreach my $wbpaper (sort keys %wbpapers) { 				# check each paper in postgres
    print "<TR><TD colspan=2>$paperquery is wbpaper $wbpaper in postgres</TD></TR>\n";
    my $finished = '';							# flag to see if this paper has been finished being curated
    my $result3 = $conn->exec( "SELECT joinkey, app_box FROM app_paper WHERE app_paper ~ 'WBPaper$wbpaper';" );
    while (my @row3 = $result3->fetchrow) { 				# get all joinkeys and app_box for objects that have that paper
      my $result4 = $conn->exec( "SELECT joinkey FROM app_finished WHERE app_finished = 'checked' AND joinkey = '$row3[0]' AND app_box = '$row3[1]';" );
      while (my @row4 = $result4->fetchrow) { if ($row4[0]) { $finished++; } } }	# see if they've been finished curating in app_finished
    if ($finished) { print "<TR><TD colspan=2><FONT COLOR=red>$wbpaper has been finished curating</FONT></TD></TR>\n"; }	# for Carol 2005 12 06
    my $result2 = $conn->exec( "SELECT wpa_rnai_curation FROM wpa_rnai_curation WHERE wpa_rnai_curation IS NOT NULL AND joinkey = '$wbpaper';" ); 
    my @row2 = $result2->fetchrow; 				# see if it's been checked out for RNAi curation.  2005 11 22
    if ($row2[0]) { print "<TR><TD colspan=2><FONT COLOR='red'>$wbpaper RNAi last curator is $row2[0], do not curate for RNAi.</FONT></TD></TR>\n"; }
    my $result = $conn->exec( "SELECT joinkey FROM app_paper WHERE app_paper ~ '$wbpaper';" );	# get the tempnames
    my %tempnames; while (my @row = $result->fetchrow) { if ($row[0]) { $tempnames{$row[0]}++; } }
    foreach my $tempname (sort keys %tempnames) {			# for each of the tempnames for that paper get the type
      $result = $conn->exec( "SELECT app_type FROM app_type WHERE joinkey = '$tempname' ORDER BY app_timestamp DESC;" );
      my @row = $result->fetchrow; if ($row[0]) { 
        print "<TR><TD>$row[0] : $tempname</TD>\n";			# output link to object in dev site
        &printPaperQueryLine($wbpaper, $row[0], $tempname); } } }	# output hidden values for form and button to curate
  print <<"  EndOfText";		# option for new entry
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi">
  <TABLE border=0>
  <TR><TD COLSPAN=2> </TD></TR>
  <TR>
    <TD><B>Curate New Object : </B></TD>
    <INPUT TYPE="HIDDEN" NAME="horiz_mult" VALUE="$theHash{horiz_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="group_mult" VALUE="$theHash{group_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="hide_or_not" VALUE="$theHash{hide_or_not}{html_value}">
  EndOfText
  &printHtmlSelect('type');
  &printHtmlInputQuery('tempname', 'Curate Object');        		# 25 characters
  print "</TABLE></FORM>\n";
} # sub paperQuery

sub printPaperQueryLine {
  my ($wbpaper, $type, $name) = @_;
  print <<"  EndOfText";
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi">
    <INPUT TYPE="HIDDEN" NAME="html_value_wbpaper_result" VALUE="$wbpaper">
    <INPUT TYPE="HIDDEN" NAME="html_value_main_type" VALUE="$type">
    <INPUT TYPE="HIDDEN" NAME="html_value_main_tempname" VALUE="$name">
    <INPUT TYPE="HIDDEN" NAME="horiz_mult" VALUE="$theHash{horiz_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="group_mult" VALUE="$theHash{group_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="hide_or_not" VALUE="$theHash{hide_or_not}{html_value}">
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Curate Object !"></TD></TR>
  </FORM>
  EndOfText
} # sub printPaperQueryLine

sub printHtmlMenu {		# show main menu page
  print <<"  EndOfText";
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi">
  <TABLE border=0>
  <TR><TD COLSPAN=2> </TD></TR>
  <TR>
    <TD><B>Curate Object : </B></TD>
    <INPUT TYPE="HIDDEN" NAME="horiz_mult" VALUE="$theHash{horiz_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="group_mult" VALUE="$theHash{group_mult}{html_value}">
    <INPUT TYPE="HIDDEN" NAME="hide_or_not" VALUE="$theHash{hide_or_not}{html_value}">
  EndOfText
  &printHtmlSelect('type');
  &printHtmlInputQuery('tempname', 'Curate Object');        		# 25 characters
  print <<"  EndOfText";
  <TR><TD><B>OR</B></TD></TR>
  <TR>
    <TD><B>Query Paper : </B></TD><TD><BR>&nbsp;</TD>
    <TD><INPUT NAME="html_value_main_paperquery" VALUE=""  SIZE=20></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Query Paper !"></TD>
  </TR>
  <TR><TD><B>OR</B></TD></TR>
  <TR>
    <TD COLSPAN=3><B>Update RNAi : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Update RNAi !"></TD>
  <TR>
  <TR><TD><B>OR</B></TD></TR>
  <TR>
    <TD COLSPAN=3><B>Update Transgene : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Update Transgene !"></TD>
  <TR>
  <TR><TD><B>OR</B></TD></TR>
  <TR>
    <TD COLSPAN=3><B>Update Variation : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Update Variation !"></TD>
  <TR>
  <TR>
    <TD COLSPAN=1><B>Dump .ace : </B></TD>
    <TD COLSPAN=2 ALIGN=CENTER><A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/data/allele_phenotype.ace">latest allele_phenotype.ace</A><BR>
                               <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/data/allele_phenotype_papers.ace">latest allele_phenotype_papers.ace</A></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Dump .ace !"></TD>
  <TR>
  <TR>
    <TD COLSPAN=3><B>Test cvs : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Test cvs !"></TD>
  <TR>
  EndOfText
  print "</TABLE>\n";

  my %exists; my %curated;
  my $result = $conn->exec( "SELECT joinkey FROM ale_allele;" );
  while (my @row = $result->fetchrow) { $exists{$row[0]}++; }
  $result = $conn->exec( "SELECT joinkey FROM ale_curated;" );
  while (my @row = $result->fetchrow) { if ($exists{$row[0]}) { delete $exists{$row[0]}; } }
  if (scalar keys %exists) { print "<A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=See%20Submissions\">There are " . scalar(keys %exists) . " entries from allele submission form to curate.</A><BR>\n"; }

  print "</FROM>\n";
} # sub printHtmlMenu

sub seeSubmissions {			# show submissions from allele.cgi user submission form that haven't been marked as curated for allele_phenotype data
  my %exists; my %curated;
  my $result = $conn->exec( "SELECT joinkey FROM ale_allele;" );
  while (my @row = $result->fetchrow) { $exists{$row[0]}++; }
  $result = $conn->exec( "SELECT joinkey FROM ale_curated;" );
  while (my @row = $result->fetchrow) { if ($exists{$row[0]}) { delete $exists{$row[0]}; } }
  foreach my $submission (sort {$a<=>$b} keys %exists) { &showSubEntry($submission); }
} # sub seeSubmissions
sub showSubEntry {			# show values from ale_ tables relevant to allele_phenotype data
  my $num = shift;
  my @tables = qw( ale_allele ale_submitter_email ale_person_evidence ale_strain ale_genotype ale_gene ale_nature_of_allele ale_haploinsufficient ale_loss_of_function ale_gain_of_function ale_penetrance ale_phenotypic_description ale_cold_sensitive ale_cold_temp ale_heat_sensitive ale_hot_temp ale_comment );
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "<TABLE border=2><TR><TD>Entry number $num</TD>\n";
#   print "<TD><B>Curator : </B><INPUT NAME=\"html_value_main_curator\" VALUE=\"\"  SIZE=20>\n";
  my @curators = ('Gary Schindelman', 'Jolene Fernandes', 'Karen Yook', 'Ranjana Kishore', 'Erich Schwarz', 'Kimberly Van Auken', 'Igor Antoshechkin', 'Raymond Lee', 'Wen Chen', 'Tuco', 'Paul Sternberg',  'Juancarlos Testing');
  print "<TD><B>Curator : </B><SELECT NAME=\"html_value_main_curator\" SIZE=1>\n";
  print "      <OPTION > </OPTION>\n";
  foreach (@curators) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT>\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_number\" VALUE=\"$num\"><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Done !\"></TD></TR>\n";
  foreach my $table (@tables) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE joinkey = '$num';" );
    while (my @row = $result->fetchrow) { 
      print "<TR><TD>$table</TD>";
      if ($table eq 'ale_allele') { print "<TD><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=Curate+Object+%21&html_value_main_type=Allele&html_value_main_tempname=$row[1]&group_mult=1&horiz_mult=2\" TARGET=new>$row[1]</A></TD></TR>\n"; }
      elsif ($table eq 'ale_person_evidence') { print "<TD><A HREF=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person_name.cgi?name=$row[1]\" TARGET=new>$row[1]</A></TD></TR>\n"; }
      else { print "<TD>$row[1]</TD></TR>\n"; } }
  } # foreach my $table (@tables)
  print "</TABLE></FORM><P>\n";
} # sub showSubEntry
sub submissionCurated {			# mark ale_curated table for allele submission data
  my ($oop, $curator) = &getHtmlVar($query, 'html_value_main_curator');
  ($oop, my $number) = &getHtmlVar($query, 'html_value_number');
  my $result = $conn->exec( "INSERT INTO ale_curated VALUES ('$number', '$curator');" );
  print "Curator $curator<BR>\n";
  print "Number $number<BR>\n";
} # sub submissionCurated

sub curate {
  my $joinkey = &getHtmlValuesFromForm(); 			# populate %theHash and get joinkey
  if ($theHash{type}{html_value}) {				# check if there's a type, which is mandatory
    my $found; my $wbgene;
    if ( $theHash{tempname}{html_value} ) {			# if there's a tempname, query for it in WB (aceserver / dev)
      ($found, $wbgene) = &checkWB( $theHash{type}{html_value}, $theHash{tempname}{html_value}); }
    elsif ( $theHash{type}{html_value} eq 'RNAi' ) { 1; }	# if it's an RNAi, it's okay that there isn't one
    else { print "<FONT COLOR=red><B>ERROR : You must enter a Mainname for non-RNAi.</B></FONT><BR>\n"; return; }	# if it's another type, ERROR
    $found = &findIfPgEntry("$theHash{tempname}{html_value}"); 	# check if already in Pg, if it's an RNAi and it's not found, create a temprnai tempname
    if ($found) { print "$joinkey already in postgres, querying it out<BR>\n"; &queryPostgres($theHash{tempname}{html_value}); }
      else { print "$joinkey is not already in postgres, new entry.<BR>\n"; }		# if it's in Pg query out values
    if ($theHash{wbgene}{html_value}) { 			# if there's a postgres value for wbgene
      print "postgres has wbgene $theHash{wbgene}{html_value}, not being used.<BR>\n"; 
      $theHash{wbgene}{html_value} = ''; }			# show wbgene value in postgres but don't use it
    if ($wbgene) {						# if there's a dev site wbgene value
      print "dev site has wbgene ${wbgene}, using this value.<BR>\n";
      $theHash{wbgene}{html_value} = $wbgene; }			# get wbgene from dev site into theHash
    my ($var, $wbpaper_result) = &getHtmlVar($query, 'html_value_wbpaper_result');	# check if checking out from a wbpaper
    if ($wbpaper_result) {								# if checking out from a paper
      print "WBPaper Result $wbpaper_result .<BR>\n";
      my $already_in_flag = ''; my $not_first_entry_flag;		# check all paper fields and see if the paper already exists
      for my $i (1 .. $theHash{group_mult}{html_value}) {
        my $g_type = 'paper_' . $i;
        if ($theHash{$g_type}{html_value}) { if ( $theHash{$g_type}{html_value} =~ m/$wbpaper_result/ ) { $already_in_flag++; } } }	# if it already exists, flag it
      unless ($already_in_flag) {			# if it's not already in, add the paper to the first box or to a new box
        for my $j (1 .. $theHash{horiz_mult}{html_value}) {					# check for a term in the first box
          my $ts_type = 'term_1_' . $j;
          if ($theHash{$ts_type}{html_value}) { $not_first_entry_flag++; } }			# if there's a term, this is not the first entry, add a new big box
        if ($not_first_entry_flag) {					# if already have some term data, add to group_mult and assign a new value in a new big box
            print "This entry already has data, adding a new big box with paper $wbpaper_result .<BR>\n";
            $theHash{group_mult}{html_value}++; $theHash{"paper_$theHash{group_mult}{html_value}"}{html_value} = $wbpaper_result; }
          else { 							# if there is no data, change the paper value in the first big box
            print "This entry has no data, changing the first big box to have paper $wbpaper_result .<BR>\n";
            $theHash{paper_1}{html_value} = $wbpaper_result; } } }
    &printHtmlForm(); }
  else { print "<FONT COLOR=red><B>ERROR : You must enter an Object Type.</B></FONT><BR>\n"; }
} # sub curate

# THIS WORKS, but requires something in tempname for RNAi, which it then ignores
# sub curate {
#   my $joinkey = &getHtmlValuesFromForm(); 		# populate %theHash and get joinkey
#   if ( ($theHash{type}{html_value}) && ($theHash{tempname}{html_value}) ) {
#     my ($found, $wbgene) = &checkWB( $theHash{type}{html_value}, $theHash{tempname}{html_value});
#     $found = &findIfPgEntry("$theHash{tempname}{html_value}");		# if tempname, check if already in Pg
#     if ($found) { print "$joinkey already in postgres, querying it out<BR>\n"; &queryPostgres($theHash{tempname}{html_value}); }
#       else { print "$joinkey is not already in postgres, new entry.<BR>\n"; } 
#     if ($theHash{wbgene}{html_value}) { 
#       print "postgres has wbgene $theHash{wbgene}{html_value}, not being used.<BR>\n"; 
#       $theHash{wbgene}{html_value} = ''; }		# show wbgene value in postgres but don't use it
#     if ($wbgene) { 
#       print "dev site has wbgene ${wbgene}, using this value.<BR>\n";
#       $theHash{wbgene}{html_value} = $wbgene; }		# get wbgene from dev site
#     my ($var, $wbpaper_result) = &getHtmlVar($query, 'html_value_wbpaper_result');	# check if checking out from a wbpaper
#     if ($wbpaper_result) {								# if checking out from a paper
#       print "WBPaper Result $wbpaper_result .<BR>\n";
#       my $already_in_flag = ''; my $not_first_entry_flag;		# check all paper fields and see if the paper already exists
#       for my $i (1 .. $theHash{group_mult}{html_value}) {
#         my $g_type = 'paper_' . $i;
#         if ( $theHash{$g_type}{html_value} =~ m/$wbpaper_result/ ) { $already_in_flag++; } }	# if it already exists, flag it
#       unless ($already_in_flag) {			# if it's not already in, add the paper to the first box or to a new box
#         for my $j (1 .. $theHash{horiz_mult}{html_value}) {					# check for a term in the first box
#           my $ts_type = 'term_1_' . $j;
#           if ($theHash{$ts_type}{html_value}) { $not_first_entry_flag++; } }			# if there's a term, this is not the first entry, add a new big box
#         if ($not_first_entry_flag) {					# if already have some term data, add to group_mult and assign a new value in a new big box
#             print "This entry already has data, adding a new big box with paper $wbpaper_result .<BR>\n";
#             $theHash{group_mult}{html_value}++; $theHash{"paper_$theHash{group_mult}{html_value}"}{html_value} = $wbpaper_result; }
#           else { 							# if there is no data, change the paper value in the first big box
#             print "This entry has no data, changing the first big box to have paper $wbpaper_result .<BR>\n";
#             $theHash{paper_1}{html_value} = $wbpaper_result; } } }
#     &printHtmlForm(); }
#   else { print "<FONT COLOR=red><B>ERROR : You must enter an Object Type and Mainname</B></FONT><BR>\n"; }
# } # sub curate

sub queryPostgres {
  my $joinkey = shift;
  if ($action eq 'Curate Object !') { &readCvs(); }		# populate %phenotypeTerms
  foreach my $type (@genParams) {
#     delete $theHash{$type};
    delete $theHash{$type}{html_value};			# only wipe out the values, not the whole subhash  2005 11 16
    my $result = $conn->exec( "SELECT * FROM app_$type WHERE joinkey = '$joinkey' ORDER BY app_timestamp;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) { $theHash{$type}{html_value} = $row[1]; }
        else { $theHash{$type}{html_value} = ''; } } }
  if ($theHash{finalname}{html_value}) { print "Based on postgres, finalname should be : $theHash{finalname}{html_value}<BR>\n"; }
  if ($theHash{wbgene}{html_value}) { print "Based on postgres, wbgene should be : $theHash{wbgene}{html_value}<BR>\n"; }
  foreach my $type (@groupParams) {
    next if ($type eq 'paper_remark');			# get this for history later instead  2007 08 24
    my $result = $conn->exec( "SELECT * FROM app_$type WHERE joinkey = '$joinkey' ORDER BY app_timestamp;" );
    while (my @row = $result->fetchrow) {
      my $g_type = $type . '_' . $row[1] ;
      delete $theHash{$g_type}{html_value};
      if ($row[2]) {
          $theHash{$g_type}{html_value} = $row[2];
          if ($row[1] > $theHash{group_mult}{html_value}) { $theHash{group_mult}{html_value} = $row[1]; } } 
        else { $theHash{$g_type}{html_value} = ''; } } }
  foreach my $type (@multParams) {
    my $result = $conn->exec( "SELECT * FROM app_$type WHERE joinkey = '$joinkey' ORDER BY app_timestamp;" );
    while (my @row = $result->fetchrow) {
      my $ts_type = $type . '_' . $row[1] . '_' . $row[2];
      delete $theHash{$ts_type}{html_value};
      if ($row[3]) {
          if (($type eq 'term') && ($action eq 'Curate Object !')) {	# if it's a term and curating an object, convert to phenotype id (phenotype term) 
            if ($row[3] =~ m/(WBPhenotype\d+)/) { my $num = $1; if ($phenotypeTerms{number}{$num}) { $row[3] = "$num ($phenotypeTerms{number}{$num})"; } } }
          $theHash{$ts_type}{html_value} = $row[3];
          if ($row[1] > $theHash{group_mult}{html_value}) { $theHash{group_mult}{html_value} = $row[1]; }
          if ($row[2] > $theHash{horiz_mult}{html_value}) { $theHash{horiz_mult}{html_value} = $row[2]; } }
        else { $theHash{$ts_type}{html_value} = ''; } } }
  for my $i (1 .. $theHash{group_mult}{html_value}) {	# get the historical paper remark  2007 08 24
    my $g_type = 'paper_' . $i ; 
    my ($paper) = $theHash{$g_type}{html_value} =~ m/(WBPaper\d+)/;
    next unless $paper;					# skip if there's no paper
    my $result = $conn->exec( "SELECT * FROM app_paper_remark WHERE app_wbpaper ~ '$paper' ORDER BY app_timestamp;" );
    my $hist_remark = '';				# append all the remarks with matching paper here 
#     while (my @row = $result->fetchrow) { if ($row[2]) { $hist_remark .= "$row[0] <FONT COLOR=blue>says</FONT> $row[2]<BR>\n"; }
    while (my @row = $result->fetchrow) { if ($row[2]) { $hist_remark .= "$row[2]<BR>\n"; } }
    $g_type = 'hist_remark_' . $i ;
    $theHash{$g_type}{html_value} = $hist_remark; }	# assign the remark
} # sub queryPostgres

sub checkWB {
  my ($type, $tempname) = @_;
  my $found = 0; my $wbgene = 0;
  if ($type eq 'RNAi') {		# check RNAi data from aceserver instead of dev.site
#     use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
#     use constant PORT => $ENV{ACEDB_PORT} || 2005;
#     my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;
#     my $query = "find RNAi $tempname";
#     my @rnai = $db->fetch(-query=>$query);
#     if ($rnai[0]) { print "aceserver found $rnai[0]<BR>\n"; $found++; }
#     if ($found) { print "Based on aceserver, finalname should be : $tempname ; RNAi does not query out wbgene.<BR>\n"; } 
    print "we're not looking at aceserver anymore for finalname information<BR>\n"; }	# 2007 08 23
  else {
    my $url = '';
    if ($type eq 'Allele') { $url = "http://dev.wormbase.org/db/gene/variation?name=${tempname};class=Variation"; }
#     elsif ($type eq 'RNAi') { $url = "http://dev.wormbase.org/db/seq/rnai?name=${tempname};class=RNAi"; }
    elsif ($type eq 'Transgene') { $url = "http://dev.wormbase.org/db/gene/transgene?name=${tempname};class=Transgene"; }
    elsif ($type eq 'Multi-Allele') { print "Not checking dev.wormbase for Multi-Allele.<BR>\n"; return; }
    my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
    my $request = HTTP::Request->new(GET => $url); #grabs url
    my $response = $ua->request($request);       #checks url, dies if not valid.
    if ($response-> is_success) {
      if ($response->content =~ m/Variation report for: $tempname/) { 
        print "$tempname found here : <A HREF=$url>$url</A><BR>\n"; $found++; 
        if ($response->content =~ m/Corresponding gene:.*?(WBGene\d+);class=Gene\"\>(.*?)\</s) { $wbgene = "$1 ($2)"; } }	# get wbgene value from dev site
      elsif ($response->content =~ m/Transgene Report for: $tempname/s) { 
        print "$tempname found here : <A HREF=$url>$url</A><BR>\n"; $found++; 
        if ($response->content =~ m/Driven by gene:.*?(WBGene\d+);class=Gene\"\>(.*?)\</) { $wbgene = "$1 ($2)"; } }	# get wbgene value from dev site
# No longer get wbgene for RNAi  2005 11 16
#       elsif ($response->content =~ m/WormBase RNAi ID<\/th> <td>$tempname/s) { 
#         print "$tempname found here : <A HREF=$url>$url</A><BR>\n"; $found++; 
#         my $url2 = "http://dev.wormbase.org/db/misc/etree?name=${tempname};class=RNAi"; 		# grab tree display to get wbgene data
#         my $request2 = HTTP::Request->new(GET => $url2);	# grabs url
#         my $response2 = $ua->request($request2);		# checks url, dies if not valid.
#         if ($response2-> is_success) { 
#           if ($response2->content =~ m/Gene.*?name\=(WBGene\d+);class=Gene/) { $wbgene = $1; }	# Add the wbgene if it exists
#           if ($response2->content =~ m/Predicted_gene.*?name\=(.+?);class=CDS/) { 
#             if ($wbgene) { $wbgene .= ' '; }	# add a space if already have first part
#             $wbgene .= " ($1)"; } } }		# add the CDS in parenthesis
      else { print "$tempname not in dev.wormbase <A HREF=$url>$url</A><BR>\n"; } }
    else { print "Wormbase Server error <A HREF=$url>$url</A> won't work<BR>\n"; } 
    if ($found) { print "Based on dev site, finalname should be : $tempname<BR>\n"; } }
  if ($found) { $theHash{finalname}{html_value} = $tempname; }
  return ($found, $wbgene);
#   die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
} # sub checkWB

sub displayClass {			# show all data for a given class based on aceserver  2006 05 18
  my ($var, $class) = &getHtmlVar($query, 'class');			# class always Life_stage for now
#   use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
#   use constant PORT => $ENV{ACEDB_PORT} || 2005;
#   my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;
#   my $query = "find $class";
#   my @class = $db->fetch(-query=>$query);
  my $src_dir = '/home/azurebrd/public_html/sanger/app_class/';
  my $src_file = $src_dir . $class;  my @class;
  open (IN, "<$src_file") or die "Cannot open $src_file : $!";
  while (my $line = <IN>) { chomp $line; push @class, $line; }
  close (IN) or die "Cannot close $src_file : $!";
  print "<TABLE border=1>\n";
  print "<TR><TD>Class $class " . scalar(@class) . " results :</TD></TR>\n";
  foreach my $class_object (@class) { print "<TR><TD>$class_object</TD></TR>\n"; }
  print "</TABLE>\n";
} # sub displayClass

sub toggleHide {
  print "HIDE EXTRA <BR>\n";
  my $joinkey = &getHtmlValuesFromForm(); 		# populate %theHash and get joinkey
  $theHash{hide_or_not}{html_value} = !$theHash{hide_or_not}{html_value}; 
  &printHtmlForm();
} # sub toggleHide

sub addMult {
  print "ADD MULT <BR>\n";
  my $joinkey = &getHtmlValuesFromForm(); 		# populate %theHash and get joinkey
  $theHash{horiz_mult}{html_value}++; 
  &printHtmlForm();
} # sub addMult

sub addGroup {
  print "ADD GROUP <BR>\n";
  my $joinkey = &getHtmlValuesFromForm(); 		# populate %theHash and get joinkey
  $theHash{group_mult}{html_value}++; 
  &printHtmlForm();
} # sub addGroup

sub updateTerm {		# update text files for phenotype term data
  my ($var, $action) = &getHtmlVar($query, 'action');
  my $flag = 0;
  my $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_kimberly_phe.txt';
  if ($action eq 'Update Kimberly !') { $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_kimberly_phe.txt'; }
  elsif ($action eq 'Update Erich !') { $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_erich_phe.txt'; }
  elsif ($action eq 'Update Jonathan !') { $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_jonathan_phe.txt'; }
  elsif ($action eq 'Update Jonathan Non !') { $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_jonathan_nonphe.txt'; }
  elsif ($action eq 'Update Suggested !') { $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_suggested_term.txt'; $flag++; }
  ($var, my $data_value) = &getHtmlVar($query, 'html_value_main_data');
  open (KIM, ">$data_file") or die "Cannot write $data_file : $!";
  print KIM "$data_value\n";
  close (KIM) or die "Cannot close $data_file : $!";
  if ($flag) { print "Suggested term data $data_file updated.<BR>\n"; }
    else { print "Phenotype ontology term data $data_file updated.<BR>\n"; }
} # sub updateTerm

sub suggested {
  print "<TABLE border=1>\n";
  print "<TR><TD>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "Suggested Term Data\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Suggested !\"><BR>\n";
  my $suggested_term_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_suggested_term.txt';
  my $suggested_term_value = '';
  open (SUG, "<$suggested_term_file") or die "Cannot open $suggested_term_file : $!";
  while (<SUG>) { $suggested_term_value .= $_; }
  close (SUG) or die "Cannot close $suggested_term_file : $!";
  print "<TEXTAREA NAME=html_value_main_data ROWS=50 COLS=100>$suggested_term_value</TEXTAREA><BR>\n";
  print "</FORM>\n";
  print "</TABLE>\n";
} # sub suggested

sub term {
  my $wormbase_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_wormbase_phe.txt';
  open (WRM, "<$wormbase_file") or die "Cannot open $wormbase_file : $!";
  print "<TABLE border=1>\n";
  print "<TR><TD align=center>WormBase Terms</TD></TR>\n";
  print "<TR><TD>From AQL query : select l->Description from l in class Phenotype where exists l->Description</TD></TR>\n";
  while (<WRM>) {
    s/\t//g;
    print "<TR><TD>$_</TD></TR>\n";
  }
  print "</TABLE>\n";
  close (WRM) or die "Cannot close $wormbase_file : $!";
  print "<P><P>\n";

  print "<TABLE border=1>\n";
  print "<TR><TD>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "Kimberly Phenotype Ontology Term Data\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Kimberly !\"><BR>\n";
  my $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_kimberly_phe.txt';
  my $data_value = '';
  open (KIM, "<$data_file") or die "Cannot open $data_file : $!";
  while (<KIM>) { $data_value .= $_; }
  close (KIM) or die "Cannot close $data_file : $!";
  print "<TEXTAREA NAME=html_value_main_data ROWS=50 COLS=100>$data_value</TEXTAREA><BR>\n";
  print "</FORM>\n";
  print "</TD></TR>\n";
  print "<TR><TD></TD></TR><TR><TD></TD></TR> <TR><TD></TD></TR><TR><TD></TD></TR>\n";
  
  print "<TR><TD>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "Erich Phenotype Ontology Term Data\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Erich !\"><BR>\n";
  $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_erich_phe.txt';
  $data_value = '';
  open (KIM, "<$data_file") or die "Cannot open $data_file : $!";
  while (<KIM>) { $data_value .= $_; }
  close (KIM) or die "Cannot close $data_file : $!";
  print "<TEXTAREA NAME=html_value_main_data ROWS=50 COLS=100>$data_value</TEXTAREA><BR>\n";
  print "</FORM>\n";
  print "</TD></TR>\n";
  print "<TR><TD></TD></TR><TR><TD></TD></TR> <TR><TD></TD></TR><TR><TD></TD></TR>\n";

  print "<TR><TD>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "Jonathan Phenotype Ontology Term Data\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Jonathan !\"><BR>\n";
  $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_jonathan_phe.txt';
  $data_value = '';
  open (KIM, "<$data_file") or die "Cannot open $data_file : $!";
  while (<KIM>) { $data_value .= $_; }
  close (KIM) or die "Cannot close $data_file : $!";
  print "<TEXTAREA NAME=html_value_main_data ROWS=50 COLS=100>$data_value</TEXTAREA><BR>\n";
  print "</FORM>\n";
  print "</TD></TR>\n";
  print "<TR><TD></TD></TR><TR><TD></TD></TR> <TR><TD></TD></TR><TR><TD></TD></TR>\n";

  print "<TR><TD>\n";
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "Jonathan Non-Phenotype Ontology Term Data\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update Jonathan Non !\"><BR>\n";
  $data_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_jonathan_nonphe.txt';
  $data_value = '';
  open (KIM, "<$data_file") or die "Cannot open $data_file : $!";
  while (<KIM>) { $data_value .= $_; }
  close (KIM) or die "Cannot close $data_file : $!";
  print "<TEXTAREA NAME=html_value_main_data ROWS=50 COLS=100>$data_value</TEXTAREA><BR>\n";
  print "</FORM>\n";
  print "</TD></TR>\n";
  print "<TR><TD></TD></TR><TR><TD></TD></TR> <TR><TD></TD></TR><TR><TD></TD></TR>\n";

  print "</TABLE>\n";
} # sub term

sub updatePaper {
  my $paper_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_papers.txt';
print "STARTIN Paper<BR>\n";
  my ($var, $paper_value) = &getHtmlVar($query, 'html_value_main_paper');
print "WRITING $paper_value<BR>\n";
  open (PAP, ">$paper_file") or die "Cannot write $paper_file : $!";
  print PAP "$paper_value\n";
  close (PAP) or die "Cannot close $paper_file : $!";
  print "Paper reference data updated.<BR>\n";
} # sub updatePaper

sub paper {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi\">\n";
  print "Paper Reference Data\n";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Update paper !\"><BR>\n";
  my $paper_file = '/home/postgres/public_html/cgi-bin/data/ale_phe_papers.txt';
  my $paper_value = '';
  open (PAP, "<$paper_file") or die "Cannot open $paper_file : $!";
  while (<PAP>) { $paper_value .= $_; }
  close (PAP) or die "Cannot close $paper_file : $!";
  print "<TEXTAREA NAME=html_value_main_paper ROWS=50 COLS=100>$paper_value</TEXTAREA><BR>\n";
  print "</FORM>\n";
} # sub paper


sub getHtmlValuesFromForm {	# read PGparameters value from html form, then display to html
  (my $var, $theHash{horiz_mult}{html_value} ) = &getHtmlVar($query, 'horiz_mult');
  ($var, $theHash{group_mult}{html_value} ) = &getHtmlVar($query, 'group_mult');
  ($var, $theHash{hide_or_not}{html_value} ) = &getHtmlVar($query, 'hide_or_not');

  if ($action eq 'Preview !') { &readCvs(); }		# populate %phenotypeTerms

  foreach my $type (@genParams) {
    my $html_type = 'html_value_main_' . $type;
    my ($var, $val) = &getHtmlVar($query, $html_type);
    if ($val) { 					# if there is a value
      $theHash{$type}{html_value} = $val;		# put it in theHash for webpage
      $val = &filterToPrintHtml($val);			# filter Html to print it
      if (($action eq 'Preview !') || ($action eq 'Update !') || ($action eq 'New Entry !')) { print "$type : $val<BR>"; } }			# print it
  } # foreach my $type (@genParams)

  my $lifestage_list = &populateClass('Life_stage');	# populate Life_stage data and put into a hash  2007 04 27
  my %lifestage_hash; foreach my $lifestage (@$lifestage_list) { $lifestage_hash{$lifestage}++; }
  my $strain_list = &populateClass('Strain');		# populate Strain data and put into a hash  2007 04 27
  my %strain_hash; foreach my $strain (@$strain_list) { $strain_hash{$strain}++; }

  for my $i (1 .. $theHash{group_mult}{html_value}) {	# get variables by box instead of type first for Karen and Jolene when looking at preview  2007 11 01
    foreach my $type (@groupParams) {
      my $g_type = $type . '_' . $i;
      my $html_type = 'html_value_main_' . $g_type ;
      my ($var, $val) = &getHtmlVar($query, $html_type);
      if ($val) { 					# if there is a value
        if ($type eq 'paper') {			# if it's a paper, try to match to a wbpaper, warn if there are multiples or no matches
          unless ($val =~ m/WBPaper/) { 	# store WBPaper (othername) to be able to check if finshed curating a paper in paperQuery app_finished  for Carol 2005 12 06
            my %wbpaper; my $result = $conn->exec( "SELECT joinkey, wpa_valid FROM wpa_identifier WHERE wpa_identifier = '$val';" );
            while (my @row = $result->fetchrow) { if ($row[0]) { if ($row[1] eq 'valid') { $wbpaper{$row[0]}++; } else { delete $wbpaper{$row[0]}; } } }
            if ( scalar(keys %wbpaper) > 1 ) { my $papers = join", ", keys %wbpaper;
                print "<FONT COLOR=red>WARNING $val could be multiple wbpapers : $papers go back and enter the WBPaper in the paper field instead of $val.</FONT><BR>\n"; }
              elsif ( scalar(keys %wbpaper) < 1 ) { 
                print "<FONT COLOR=red>WARNING $val doesn't have a matching WBPaper, go back and enter the WBPaper in the paper field instead of $val.</FONT><BR>\n"; }
              else { my $temp_val = each %wbpaper; $val = "WBPaper$temp_val ($val)"; } } }
        $theHash{$g_type}{html_value} = $val;		# put it in theHash for webpage
        $val = &filterToPrintHtml($val);			# filter Html to print it
        if (($action eq 'Preview !') || ($action eq 'Update !') || ($action eq 'New Entry !')) { print "$g_type : $val<BR>"; } }			# print it
#   { # } # for my $i (1 .. $theHash{group_mult}{html_value})
    } # foreach my $type (@genParams)

#     for my $i (1 .. $theHash{group_mult}{html_value}) { # }
    foreach my $type (@multParams) {
      my $g_type = $type . '_' . $i;
# this can't happen, delete it later.  2005 10 18
#       my $html_type = 'html_value_main_' . $g_type ;
#       my ($var, $val) = &getHtmlVar($query, $html_type);
#       if ($val) { 					# if there is a value
#         $theHash{$g_type}{html_value} = $val;		# put it in theHash for webpage
#         $val = &filterToPrintHtml($val);			# filter Html to print it
#         print "$g_type : $val<BR>"; }			# print it
      for my $j (1 .. $theHash{horiz_mult}{html_value}) {
        my $ts_type = $g_type . '_' . $j;
        my $html_type = 'html_value_main_' . $ts_type ;
        my ($var, $val) = &getHtmlVar($query, $html_type);
        if ($val) { 					# if there is a value
          if (($type eq 'term') && ($action eq 'Preview !')) {	# if it's a term and previewing, convert to phenotype id (phenotype term) like paper data	2005 12 22
            if ($val =~ m/WBPhenotype\d+ \(\w+\)/) { 1; }	# already good
            elsif ($val =~ m/(WBPhenotype\d+)/) { my $num = $1; if ($phenotypeTerms{number}{$num}) { $val = "$num ($phenotypeTerms{number}{$num})"; } }
            elsif ($phenotypeTerms{term}{$val}) { $val = "$phenotypeTerms{term}{$val} ($val)"; }
            else { print "<FONT COLOR=red>ERROR ``$val'' does not match a phenotype term in cvs, go back and enter a proper term.</FONT><BR>\n"; die "invalid phenotype value $val not in cvs : $!"; } }
          elsif ( ($type eq 'heat_degree') || ($type eq 'cold_degree') ) { if ($val =~ m/\D/) {
            print "<FONT COLOR=red>ERROR $type needs to be an Integer only instead of ``$val''.</FONT><BR>\n"; die "invalid $type value $val not an integer : $!"; } }
          elsif ($type eq 'lifestage') { 		# check that Life_stage values are in the aceserver  2007 04 27
            my @vals = split/\|/, $val; foreach my $val (@vals) { unless ($lifestage_hash{$val}) { 
            print "<FONT COLOR=red>ERROR $type needs to be a valid Life_stage object instead of ``$val''.</FONT><BR>\n"; die "invalid $type value $val not a valid Life_stage : $!"; } } }
          elsif ($type eq 'strain') { unless ($strain_hash{$val}) {	# check that Strain values are in the aceserver  2007 04 27
            print "<FONT COLOR=red>ERROR $type needs to be a valid Strain object instead of ``$val''.</FONT><BR>\n"; die "invalid $type value $val not a valid Strain : $!"; } }
          $theHash{$ts_type}{html_value} = $val;		# put it in theHash for webpage
          $val = &filterToPrintHtml($val);			# filter Html to print it
          if (($action eq 'Preview !') || ($action eq 'Update !') || ($action eq 'New Entry !')) { print "$ts_type : $val<BR>"; } }			# print it
      } # for my $j (1 .. $theHash{group_mult}{html_value})
    } # foreach my $type (@genParams)
  } # for my $i (1 .. $theHash{group_mult}{html_value})

  return $theHash{tempname}{html_value};			# return the joinkey

} # sub getHtmlValuesFromForm 

sub populateClass {					# populate Class data from aceserver into an array reference
  my $class = shift;					# class is Life_stage or Strain
#   use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
#   use constant PORT => $ENV{ACEDB_PORT} || 2005;
#   my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;
#   my $query = "find $class";
#   my @class = $db->fetch(-query=>$query);
  my $src_dir = '/home/azurebrd/public_html/sanger/alp_class/';
  my $src_file = $src_dir . $class;  my @class;
  open (IN, "<$src_file") or die "Cannot open $src_file : $!";
  while (my $line = <IN>) { chomp $line; push @class, $line; }
  close (IN) or die "Cannot close $src_file : $!";
  return \@class;
} # sub populateLifestage

sub getCurator {					# get the curator and convert for save file
  $curator = $theHash{curator}{value};			# get the curator
  if ($curator =~ m/Juancarlos/) { $curator = 'azurebrd'; }
  elsif ($curator =~ m/Carol/) { $curator = 'carol'; }
  elsif ($curator =~ m/Ranjana/) { $curator = 'ranjana'; }
  elsif ($curator =~ m/Kimberly/) { $curator = 'kimberly'; }
  elsif ($curator =~ m/Erich/) { $curator = 'erich'; } 
  elsif ($curator =~ m/Igor/) { $curator = 'igor'; } 
  elsif ($curator =~ m/Raymond/) { $curator = 'raymond'; } 
  elsif ($curator =~ m/Wen/) { $curator = 'wen'; } 
  elsif ($curator =~ m/Andrei/) { $curator = 'andrei'; } 
  elsif ($curator =~ m/Paul/) { $curator = 'paul'; } 
  else { 1; }
} # sub getCurator


#################  HTML SECTION #################

sub printHtmlForm {	# Show the form 
# my $horiz_mult = 3;	# default number of phenotype / suggested boxes
# my $group_mult = 4;	# default groups of curators, etc. giant tables
  &printHtmlFormStart();
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"horiz_mult\" VALUE=\"$theHash{horiz_mult}{html_value}\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"group_mult\" VALUE=\"$theHash{group_mult}{html_value}\">\n";
  print "<INPUT TYPE=\"HIDDEN\" NAME=\"hide_or_not\" VALUE=\"$theHash{hide_or_not}{html_value}\">\n";
  &printHtmlSelect('type');
#   &printHtmlInputQuery('tempname');        		# 25 characters
  &printHtmlInputH('tempname','20');        		# 20 characters
  &printHtmlInputH('finalname','20');        		# 20 characters
  &printHtmlInputH('wbgene','25');        		# 25 characters
#   &printHtmlInputQuery('wbgene', 'Query WBGene');	# don't need the query button 2005 11 18
#   &printHtmlSelect('nature');
#   &printHtmlSelect('penetrance');
#   &printHtmlInputH('percent','5');        		# 5 characters
#   print "</TR><TR>\n";
#   &printHtmlSelect('effect');
#   &printHtmlSelect('sensitivity');
#   &printHtmlInputH('degree','5');        		# 5 characters
#   &printHtmlSelect('func');
    # only show rnai brief description if the data refers to rnai  2005 11 16
  if ($theHash{type}{html_value} eq 'RNAi') { &printHtmlTextareaOutside('rnai_brief',40,3,2,2); }
  print "<TR><TD align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Add Big Boxes !\"></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Toggle Hide !\"></TD></TR>\n";
  print "</TR></TABLE><TABLE border=2>";
#   for my $i (1 .. $theHash{group_mult}{html_value}) {
  for (my $i = $theHash{group_mult}{html_value}; $i >= 1; $i--) {
    print "<TR><TD><TABLE>\n";
#     &printHtmlSelectCurators('curator', $i);		# print html select blocks for curators
    &printHtmlInputCheckbox('paper', 'finished', $i,30);        	
    &printHtmlInput('person', $i,30);        	
    print "</TABLE><TABLE><TR>\n";
#     if ( ($theHash{type}{html_value} eq 'Allele') || ($theHash{type}{html_value} eq 'Multi-Allele') ) { &printHtmlTextarea('phenotype', $i,80,7); }
      # only show phenotype text box for Allele or Multi-Allele  for Carol 2006 05 17
    if ( ($theHash{type}{html_value} eq 'Allele') || ($theHash{type}{html_value} eq 'Multi-Allele') ) { &printHtmlTextOnly('phenotype', $i, 'short'); }
#     if ( ($theHash{type}{html_value} eq 'Allele') || ($theHash{type}{html_value} eq 'Multi-Allele') ) { &printHtmlTextOnly('phenotype', $i); }
#     &printHtmlInputTermSuggested('term','suggested', $i, $theHash{horiz_mult}{html_value}, 20);        	
    print "</TR></TABLE><TABLE>\n";
#     print "<TR><TD align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"More Boxes !\"></TD><TD align=left><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Toggle Hide !\"></TD></TR>\n";				# added more boxes button here for Carol  2006 08 25
    &printHtmlMultButton('curator', $i, $theHash{horiz_mult}{html_value}, 'More Boxes !');
    &printHtmlMultSelect('curator', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultCheckbox('not', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultInput('term', $i, $theHash{horiz_mult}{html_value}, 30);        	
    &printHtmlMultTextarea('phen_remark', $i, $theHash{horiz_mult}{html_value}, 30, 5);        	
    &printHtmlMultInput('lifestage', $i, $theHash{horiz_mult}{html_value}, 30);        	
    &printHtmlMultInput('anat_term', $i, $theHash{horiz_mult}{html_value}, 30);        	
    &printHtmlMultSelect('nature', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultSelect('func', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultSelectInput('penetrance', 'percent', $i, $theHash{horiz_mult}{html_value}, 16);
    &printHtmlMultInput('range', $i, $theHash{horiz_mult}{html_value}, 30);        	
    &printHtmlMultDoubleCheckboxInput('heat_sens', 'heat_degree', 'cold_sens', 'cold_degree', $i, $theHash{horiz_mult}{html_value}, 4);
#     &printHtmlMultCheckboxInput('heat_sens', 'heat_degree', $i, $theHash{horiz_mult}{html_value}, 4);
#     &printHtmlMultCheckboxInput('cold_sens', 'cold_degree', $i, $theHash{horiz_mult}{html_value}, 4);
    &printHtmlMultSelect('mat_effect', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultCheckbox('pat_effect', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultCheckbox('haplo', $i, $theHash{horiz_mult}{html_value});
    &printHtmlMultInput('temperature', $i, $theHash{horiz_mult}{html_value}, 30);        	
    &printHtmlMultTextarea('treatment', $i, $theHash{horiz_mult}{html_value}, 30, 5);        	
    &printHtmlMultInput('genotype', $i, $theHash{horiz_mult}{html_value}, 30);        	
    &printHtmlMultInput('strain', $i, $theHash{horiz_mult}{html_value}, 30);        	
    if ($theHash{type}{html_value} eq 'RNAi') { &printHtmlMultSelect('delivered', $i, $theHash{horiz_mult}{html_value}); } 	# for RNAi only 2007 04 24
#     &printHtmlMultTextarea('preparation', $i, $theHash{horiz_mult}{html_value}, 30, 5);        	# this doesn't exist anymore  2007 04 26
#   &printHtmlMultSelect('penetrance', $i, $theHash{horiz_mult}{html_value});
#   &printHtmlMultInput('percent', $i, $theHash{horiz_mult}{html_value}, 5);        		# 5 characters
#   &printHtmlMultSelect('sensitivity', $i, $theHash{horiz_mult}{html_value});
#   &printHtmlMultInput('degree', $i, $theHash{horiz_mult}{html_value}, 5);        		# 5 characters
#   &printHtmlMultSelectInput('sensitivity', 'degree', $i, $theHash{horiz_mult}{html_value}, 5);
    &printHtmlMultTextarea('obj_remark', $i, $theHash{horiz_mult}{html_value}, 30, 5);

    if ($theHash{hide_or_not}{html_value}) { 		# if not meant to hide, show stuff
      &printHtmlMultInput('quantity_remark', $i, $theHash{horiz_mult}{html_value}, 30);        	
      &printHtmlMultInput('quantity', $i, $theHash{horiz_mult}{html_value}, 30);        	
      &printHtmlMultInput('go_sug', $i, $theHash{horiz_mult}{html_value}, 30);        	
      &printHtmlMultInput('suggested', $i, $theHash{horiz_mult}{html_value}, 30);        	
      &printHtmlMultInput('sug_ref', $i, $theHash{horiz_mult}{html_value}, 30);        	
      &printHtmlMultInput('sug_def', $i, $theHash{horiz_mult}{html_value}, 30);        	
    } else {						# if meant to hide, pass hidden values
      &printHtmlMultHidden('quantity_remark', $i, $theHash{horiz_mult}{html_value});        	
      &printHtmlMultHidden('quantity', $i, $theHash{horiz_mult}{html_value});        	
      &printHtmlMultHidden('go_sug', $i, $theHash{horiz_mult}{html_value});        	
      &printHtmlMultHidden('suggested', $i, $theHash{horiz_mult}{html_value});        	
      &printHtmlMultHidden('sug_ref', $i, $theHash{horiz_mult}{html_value});        	
      &printHtmlMultHidden('sug_def', $i, $theHash{horiz_mult}{html_value});        	
    }
#     print "<TR><TD align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"More Boxes !\"></TD><TD align=left><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Toggle Hide !\"></TD></TR>\n";
    print "</TABLE><TABLE>\n";
    &printHtmlTextOnly('hist_remark', $i);        	
    &printHtmlTextarea('paper_remark', $i,80,2);        	
    &printHtmlTextarea('intx_desc', $i,80,7);        	
    print "</TABLE></TD></TR>\n";

  } # for my $i (1 .. $group_mult)
  print "</TABLE><TABLE>\n";	

#     print "<TR><TD align=right><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"More Boxes !\"></TD><TD align=left><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Toggle Hide !\"></TD></TR>\n";
#     print "</TABLE></TD></TR>\n";
#   } # for my $i (1 .. $group_mult)
#   print "</TABLE><TABLE>\n";
  &printHtmlFormEnd();
} # sub printHtmlForm

sub printHtmlMultHidden {
  my ($type, $group_mult_count, $horiz_mult) = @_;             # get type, use hash for html parts
#   for my $j ( 1 .. $horiz_mult ) 
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $g_type = $type . "_" . $group_mult_count . "_" . $j;
    if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
    print "<INPUT TYPE=\"HIDDEN\" NAME=\"html_value_main_$g_type\" VALUE=\"$theHash{$g_type}{html_value}\">\n";
  } # for my $j ( 1 .. $horiz_mult )
} # sub printHtmlMultHidden

sub printHtmlMultButton {
  my ($type, $group_mult_count, $horiz_mult, $button_text ) = @_;             # get type, use hash for html parts
  print "<TR><TD></TD>\n";
  for (my $j = $horiz_mult; $j >= 1; $j--) { print "<TD align=left>$theHash{tempname}{html_value}<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"$button_text\"></TD>\n"; }
  print "</TR>\n";
} # sub printHtmlMultButton

sub printHtmlMultInput {            # print html inputs
  my ($type, $group_mult_count, $horiz_mult, $size) = @_;             # get type, use hash for html parts
  if ($size) { $theHash{$type}{html_size_main} = $size; }
  my $td_header = "<TD ALIGN=\"right\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></TD>";
#   if ( ($type eq 'term') || ($type eq 'suggested') ) { $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=$type\" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; }	# link to phenotype ontology term and suggested term.  removed for carol 2005 08 25
#   if ($type eq 'suggested') { $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=$type\" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; }	# carol no longer wants link.  2005 11 22
#   if ( $type eq 'paper' ) { 	# now in InputCheckbox
#      $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=$type\" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; }
  if ( $type eq 'lifestage' ) {
#     $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/phenotype_curation.cgi?class=Life_stage&class_type=WormBase&action=Class \" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; 
    $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?class=Life_stage&action=Class \" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; }
  print <<"  EndOfText";
    <TR>
    $td_header
  EndOfText
#   for my $j ( 1 .. $horiz_mult )
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $g_type = $type . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type}{html_value}) { $theHash{$g_type}{html_value} = ''; }
    if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
    print "<TD><FONT SIZE-=2 COLOR=green>$type</FONT><BR><INPUT NAME=\"html_value_main_$g_type\" VALUE=\"$theHash{$g_type}{html_value}\"  SIZE=$theHash{$type}{html_size_main}></TD>\n";
  } # for my $j ( 1 .. $horiz_mult )
  print "  </TR>\n";
} # sub printHtmlMultInput

sub printHtmlMultTextarea {         # print html textareas
  my ($type, $group_mult_count, $horiz_mult, $major, $minor) = @_;             # get type, use hash for html parts
  if ($major) { $theHash{$type}{html_size_main} = $major; }
  if ($minor) { $theHash{$type}{html_size_minor} = $minor; }
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
  EndOfText
#   for my $j ( 1 .. $horiz_mult )
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $g_type = $type . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type}{html_value}) { $theHash{$g_type}{html_value} = ''; }
    if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
    print "  <TD><FONT SIZE-=2 COLOR=green>$type</FONT><BR><TEXTAREA NAME=\"html_value_main_$g_type\" ROWS=$theHash{$type}{html_size_minor}
                  COLS=$theHash{$type}{html_size_main}>$theHash{$g_type}{html_value}</TEXTAREA></TD>\n";
  } # for my $j ( 1 .. $horiz_mult )
  print "  </TR>\n";
} # sub printHtmlMultTextarea

sub printHtmlMultSelect {	
  my ($type, $group_mult_count, $horiz_mult ) = @_;             # get type, use hash for html parts
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_label} :</STRONG></TD>
    <!--<TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>-->
  EndOfText
#   for my $j ( 1 .. $horiz_mult )
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $g_type = $type . "_" . $group_mult_count . "_" . $j;
    print "    <TD ALIGN=left><FONT SIZE-=2 COLOR=green>$type</FONT><BR><SELECT NAME=\"html_value_main_$g_type\" SIZE=1>\n";
    if ($theHash{$g_type}{html_value}) { 
      if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
      print "      <OPTION selected>$theHash{$g_type}{html_value}</OPTION>\n"; }
    print "      <OPTION > </OPTION>\n";
      # if loaded or queried, show option, otherwise default to '' option
    foreach (@{ $theHash{$type}{types} }) { print "      <OPTION>$_</OPTION>\n"; }
    print "    </SELECT></TD>\n ";
  } # for my $j ( 1 .. $horiz_mult )
  print "  </TR>\n";
} # sub printHtmlMultSelect

sub printHtmlMultDoubleCheckboxInput {
  my ($type_one, $type_two, $type_three, $type_four, $group_mult_count, $horiz_mult, $size ) = @_;             # get type, use hash for html parts
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type_one}{html_label} :</STRONG></TD>
  EndOfText
#   for my $j ( 1 .. $horiz_mult )
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $checked = '';
    my $g_type_one = $type_one . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type_one}{html_value}) { $theHash{$g_type_one}{html_value} = ''; }
    if ($theHash{$g_type_one}{html_value}) { $checked = 'CHECKED'; } else { $checked = ''; }
    if ($theHash{$g_type_one}{html_value} =~ m/\"/) { $theHash{$g_type_one}{html_value} =~ s/\"/&quot;/g; } 
    print "<TD><FONT SIZE-=2 COLOR=green>$type_one $type_three</FONT><BR><INPUT NAME=\"html_value_main_$g_type_one\" TYPE=\"checkbox\" $checked $theHash{$g_type_one}{html_value} VALUE=\"checked\">";
    my $g_type_two = $type_two . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type_two}{html_value}) { $theHash{$g_type_two}{html_value} = ''; }
    if ($theHash{$g_type_two}{html_value} =~ m/\"/) { $theHash{$g_type_two}{html_value} =~ s/\"/&quot;/g; } 
    print "<INPUT NAME=\"html_value_main_$g_type_two\" VALUE=\"$theHash{$g_type_two}{html_value}\"  SIZE=$size>\n";
    my $g_type_three = $type_three . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type_three}{html_value}) { $theHash{$g_type_three}{html_value} = ''; }
    if ($theHash{$g_type_three}{html_value}) { $checked = 'CHECKED'; } else { $checked = ''; }
    if ($theHash{$g_type_three}{html_value} =~ m/\"/) { $theHash{$g_type_three}{html_value} =~ s/\"/&quot;/g; } 
    print "<INPUT NAME=\"html_value_main_$g_type_three\" TYPE=\"checkbox\" $checked $theHash{$g_type_three}{html_value} VALUE=\"checked\">";
    my $g_type_four = $type_four . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type_four}{html_value}) { $theHash{$g_type_four}{html_value} = ''; }
    if ($theHash{$g_type_four}{html_value} =~ m/\"/) { $theHash{$g_type_four}{html_value} =~ s/\"/&quot;/g; } 
    print "<INPUT NAME=\"html_value_main_$g_type_four\" VALUE=\"$theHash{$g_type_four}{html_value}\"  SIZE=$size></TD>\n";
  } # for my $j ( 1 .. $horiz_mult )
  print "  </TR>\n";
} # sub printHtmlMultCheckboxInput 


sub printHtmlMultSelectInput {	
  my ($type_one, $type_two, $group_mult_count, $horiz_mult, $size ) = @_;             # get type, use hash for html parts
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type_one}{html_label} :</STRONG></TD>
    <!--<TD ALIGN="right"><STRONG>$theHash{$type_one}{html_field_name} :</STRONG></TD>-->
  EndOfText
#   for my $j ( 1 .. $horiz_mult )
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $g_type_one = $type_one . "_" . $group_mult_count . "_" . $j;
    print "    <TD ALIGN=left><FONT SIZE-=2 COLOR=green>$type_one</FONT><BR><SELECT NAME=\"html_value_main_$g_type_one\" SIZE=1>\n";
    if ($theHash{$g_type_one}{html_value} =~ m/\"/) { $theHash{$g_type_one}{html_value} =~ s/\"/&quot;/g; } 
    if ($theHash{$g_type_one}{html_value}) { print "      <OPTION selected>$theHash{$g_type_one}{html_value}</OPTION>\n"; }
    print "      <OPTION > </OPTION>\n";
      # if loaded or queried, show option, otherwise default to '' option
    foreach (@{ $theHash{$type_one}{types} }) { print "      <OPTION>$_</OPTION>\n"; }
    print "    </SELECT>\n ";
    my $g_type_two = $type_two . "_" . $group_mult_count . "_" . $j;
    unless ($theHash{$g_type_two}{html_value}) { $theHash{$g_type_two}{html_value} = ''; }
    if ($theHash{$g_type_two}{html_value} =~ m/\"/) { $theHash{$g_type_two}{html_value} =~ s/\"/&quot;/g; } 
    print "<INPUT NAME=\"html_value_main_$g_type_two\" VALUE=\"$theHash{$g_type_two}{html_value}\"  SIZE=$size></TD>\n";
  } # for my $j ( 1 .. $horiz_mult )
  print "  </TR>\n";
} # sub printHtmlMultSelectInput 


sub printHtmlMultCheckbox {            # print html checkboxes
  my ($type, $group_mult_count, $horiz_mult) = @_;             # get type, use hash for html parts
  my $td_header = "<TD ALIGN=\"right\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></TD>";
  print <<"  EndOfText";
    <TR>
    $td_header
  EndOfText
#   for my $j ( 1 .. $horiz_mult )
  for (my $j = $horiz_mult; $j >= 1; $j--) {
    my $g_type = $type . "_" . $group_mult_count . "_" . $j;
    if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
    print "<TD><FONT SIZE-=2 COLOR=green>$type</FONT><BR><INPUT NAME=\"html_value_main_$g_type\" TYPE=\"checkbox\" $theHash{$g_type}{html_value} VALUE=\"checked\"></TD>";
  } # for my $j ( 1 .. $horiz_mult )
  print "  </TR>\n";
} # sub printHtmlMultCheckbox 


sub printHtmlSelect {
  my $type = shift;
  unless ($theHash{$type}{html_value}) { $theHash{$type}{html_value} = ''; }
  print "    <TD ALIGN=center>$theHash{$type}{html_label}<BR><SELECT NAME=\"html_value_main_$type\" SIZE=1>\n";
  if ($theHash{$type}{html_value}) { 
    if ($theHash{$type}{html_value} =~ m/\"/) { $theHash{$type}{html_value} =~ s/\"/&quot;/g; } 
    print "      <OPTION selected>$theHash{$type}{html_value}</OPTION>\n"; }
  print "      <OPTION > </OPTION>\n";
    # if loaded or queried, show option, otherwise default to '' option
  foreach (@{ $theHash{$type}{types} }) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n ";
} # sub printHtmlSelect

sub printHtmlInputQuery {       # print html inputs with queries (just pubID)
#   my $type = shift;             # get type, use hash for html parts
  my ($type, $message) = @_;             # get type, use hash for html parts
  unless ($theHash{$type}{html_value}) { $theHash{$type}{html_value} = ''; }
  my $size = 25; if ($theHash{$type}{html_size_main}) { $size = $theHash{$type}{html_size_main}; }
  if ($theHash{$type}{html_value} =~ m/\"/) { $theHash{$type}{html_value} =~ s/\"/&quot;/g; } 
  print <<"  EndOfText";
    <TD>$type<BR><INPUT NAME="html_value_main_$type" VALUE="$theHash{$type}{html_value}"  SIZE=$size></TD>
    <TD ALIGN="left"><BR><INPUT TYPE="submit" NAME="action" VALUE="$message !"></TD>
  EndOfText
} # sub printHtmlInputQuery

sub printHtmlInputH {            # print html inputs
  my ($type, $size) = @_;             # get type, use hash for html parts
  if ($size) { $theHash{$type}{html_size_main} = $size; }
  unless ($theHash{$type}{html_value}) { $theHash{$type}{html_value} = ''; }
  if ($theHash{$type}{html_value}) { if ($theHash{$type}{html_value} =~ m/\"/) { $theHash{$type}{html_value} =~ s/\"/&quot;/g; } }
  if ($theHash{$type}{html_value} =~ m/\"/) { $theHash{$type}{html_value} =~ s/\"/&quot;/g; } 
  print <<"  EndOfText";
    <TD>$type<BR><INPUT NAME="html_value_main_$type" VALUE="$theHash{$type}{html_value}"  SIZE=$theHash{$type}{html_size_main}></TD>
  EndOfText
} # sub printHtmlInputH

#     &printHtmlInputCheckbox('paper', $i,30);        	
sub printHtmlInputCheckbox {            # print html inputs
  my ($type_one, $type_two, $group_mult_count, $size) = @_;             # get type, use hash for html parts
  my $g_type_one = $type_one . "_$group_mult_count";
  my $g_type_two = $type_two . "_$group_mult_count";
  if ($size) { $theHash{$type_one}{html_size_main} = $size; }
  my $td_header = "<TD ALIGN=\"right\"><STRONG>$theHash{$type_one}{html_field_name} : </STRONG></TD>";
  if ( $type_one eq 'paper' ) { 
     $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=$type_one\" target=\"_blank\"><STRONG>$theHash{$type_one}{html_field_name} : </STRONG></A></TD>"; }
  unless ($theHash{$g_type_one}{html_value}) { $theHash{$g_type_one}{html_value} = ''; }
  unless ($theHash{$g_type_two}{html_value}) { $theHash{$g_type_two}{html_value} = ''; }
  if ($theHash{$g_type_one}{html_value} =~ m/\"/) { $theHash{$g_type_one}{html_value} =~ s/\"/&quot;/g; } 
  if ($theHash{$g_type_two}{html_value} =~ m/\"/) { $theHash{$g_type_two}{html_value} =~ s/\"/&quot;/g; } 
  print <<"  EndOfText";
    <TR>
    $td_header
    <TD><INPUT NAME="html_value_main_$g_type_one" VALUE="$theHash{$g_type_one}{html_value}"  SIZE=$theHash{$type_one}{html_size_main}></TD>
    <TD><INPUT NAME="html_value_main_$g_type_two" TYPE="checkbox" $theHash{$g_type_two}{html_value} VALUE="checked">check if completed curating</TD>
    </TR>
  EndOfText
} # sub printHtmlInputCheckbox


sub printHtmlInput {            # print html inputs
  my ($type, $group_mult_count, $size) = @_;             # get type, use hash for html parts
  my $g_type = $type . "_$group_mult_count";
  if ($size) { $theHash{$type}{html_size_main} = $size; }
  my $td_header = "<TD ALIGN=\"right\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></TD>";
#   if ( $type eq 'paper' ) { 	# now in InputCheckbox
#      $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=$type\" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; }
  if ( $type eq 'lifestage' ) { 
     $td_header = "<TD ALIGN=\"right\"><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/phenotype_curation.cgi?class=Life_stage&class_type=WormBase&action=Class \" target=\"_blank\"><STRONG>$theHash{$type}{html_field_name} : </STRONG></A></TD>"; }
  unless ($theHash{$g_type}{html_value}) { $theHash{$g_type}{html_value} = ''; }
  if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
  print <<"  EndOfText";
    <TR>
    $td_header
    <TD><INPUT NAME="html_value_main_$g_type" VALUE="$theHash{$g_type}{html_value}"  SIZE=$theHash{$type}{html_size_main}></TD>
    </TR>
  EndOfText
} # sub printHtmlInput

sub printHtmlTextareaOutside {         # print html textareas
  my ($type, $major, $minor, $span_1, $span_2) = @_;             # get type, use hash for html parts
  if ($major) { $theHash{$type}{html_size_main} = $major; }
  if ($minor) { $theHash{$type}{html_size_minor} = $minor; }
  if ($theHash{$type}{html_value} =~ m/\"/) { $theHash{$type}{html_value} =~ s/\"/&quot;/g; } 
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right" COLSPAN=$span_1><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
    <TD COLSPAN=$span_2><TEXTAREA NAME="html_value_main_$type" ROWS=$theHash{$type}{html_size_minor}
                  COLS=$theHash{$type}{html_size_main}>$theHash{$type}{html_value}</TEXTAREA></TD>
  </TR>
  EndOfText
} # sub printHtmlTextareaOutside

sub printHtmlTextOnly {
  my ($type, $group_mult_count, $short) = @_;             # get type, use hash for html parts
  my $g_type = $type . "_$group_mult_count";
  unless ($theHash{$g_type}{html_value}) { $theHash{$g_type}{html_value} = ''; }
  my $string = "<TD>$theHash{$g_type}{html_value}</TD>";
  if ($short eq 'short') {
    if ($theHash{$g_type}{html_value} =~ m/^(.{80})/) {
    my ($short_text) = $theHash{$g_type}{html_value} =~ m/^(.{80})/;	# THIS DOESN'T show everything in span
    $string = "<TD><A HREF=\"http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi?action=popup&value=$theHash{$g_type}{html_value}\" target=new >$short_text ...</A></TD>";
  } }
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
    $string
    <INPUT TYPE=HIDDEN NAME="html_value_main_$g_type" VALUE="$theHash{$g_type}{html_value}">
  </TR>
  EndOfText
}

sub printHtmlTextarea {         # print html textareas
  my ($type, $group_mult_count, $major, $minor) = @_;             # get type, use hash for html parts
  my $g_type = $type . "_$group_mult_count";
  if ($major) { $theHash{$type}{html_size_main} = $major; }
  if ($minor) { $theHash{$type}{html_size_minor} = $minor; }
  unless ($theHash{$g_type}{html_value}) { $theHash{$g_type}{html_value} = ''; }
  if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
    <TD><TEXTAREA NAME="html_value_main_$g_type" ROWS=$theHash{$type}{html_size_minor}
                  COLS=$theHash{$type}{html_size_main}>$theHash{$g_type}{html_value}</TEXTAREA></TD>
  </TR>
  EndOfText
} # sub printHtmlTextarea

sub printHtmlFormStart {        # beginning of form
  print <<"  EndOfText";
  <A NAME="form"><H1>Add your entries : </H1></A>
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~postgres/cgi-bin/app.cgi">
  <TABLE>
  <TR><TD COLSPAN=2> </TD></TR>
  <TR>
    <TD> </TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Preview !"><!--
        <INPUT TYPE="submit" NAME="action" VALUE="Save !">
        <INPUT TYPE="submit" NAME="action" VALUE="Load !">
        <INPUT TYPE="submit" NAME="action" VALUE="Reset !">--></TD>
  </TR>
  </TABLE>
  <TABLE>
  <TR><TD></TD></TR><TR><TD></TD></TR> <TR><TD></TD></TR><TR><TD></TD></TR> 
  EndOfText
} # sub printHtmlFormStart

sub printHtmlFormEnd {          # ending of form
  print <<"  EndOfText";
  <TR><TD COLSPAN=2> </TD></TR>
  <TR>
    <TD> </TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Preview !"><!--
        <INPUT TYPE="submit" NAME="action" VALUE="Save !">
        <INPUT TYPE="submit" NAME="action" VALUE="Load !">
        <INPUT TYPE="submit" NAME="action" VALUE="Reset !">--></TD>
  </TR>
  </TABLE>
  </FORM>
  EndOfText
} # sub printHtmlFormEnd

#################  HTML SECTION #################

#################  HASH SECTION #################

sub initializeHash {
  # initialize the html field name, mailing codes, html mailing addresses, and mailing subjects.
  # in case of new fields, add to @PGparameters array and create html_field_name entry in %theHash
  # and other %theHash fields as necessary.  if new email address, add to %emails.
  %theHash = ();

  $theHash{horiz_mult}{html_value} = 2;	# default number of phenotype / suggested boxes
  $theHash{group_mult}{html_value} = 1;	# default groups of curators, etc. giant tables
  $theHash{hide_or_not}{html_value} = 0;	# default hide extra columns	# switched to hide 2007 10 01 for Karen

  @{ $theHash{type}{types} } = qw(Allele Transgene RNAi Multi-Allele);
  @{ $theHash{nature}{types} } = qw(Recessive Semi_dominant Dominant);
  @{ $theHash{delivered}{types} } = ('Injection', 'Bacterial Feeding', 'Soaking', 'Transgene Expression');
#   @{ $theHash{penetrance}{types} } = ('Partially Penetrant', 'Fully Penetrant');
  @{ $theHash{penetrance}{types} } = ('Incomplete', 'Low', 'High', 'Complete');
  @{ $theHash{mat_effect}{types} } = ('Maternal', 'Strictly_maternal', 'With_maternal_effect');
#   @{ $theHash{sensitivity}{types} } = qw(Cold-sensitive Heat-sensitive Both);
  @{ $theHash{func}{types} } = qw(Amorph Hypomorph Isoallele Uncharacterised_loss_of_function Wild_type Hypermorph Uncharacterised_gain_of_function Neomorph Dominant_negative Mixed Gain_of_function Loss_of_function);
#   @{ $theHash{curator}{types} } = ('Carol Bastiani', 'Ranjana Kishore', 'Erich Schwarz', 'Kimberly Van Auken', 'Igor Antoshechkin', 'Raymond Lee', 'Wen Chen', 'Andrei Petcherski', 'Gary Schindelman', 'Paul Sternberg',  'Juancarlos Testing');
  @{ $theHash{curator}{types} } = ('Gary Schindelman', 'Jolene Fernandes', 'Karen Yook', 'Ranjana Kishore', 'Erich Schwarz', 'Kimberly Van Auken', 'Igor Antoshechkin', 'Raymond Lee', 'Wen Chen', 'Tuco', 'Paul Sternberg',  'Juancarlos Testing');

  $theHash{curator}{html_label} = 'Curator';
  $theHash{type}{html_label} = 'Type';
  $theHash{nature}{html_label} = 'Nature of Allele';
  $theHash{delivered}{html_label} = 'Delivered by';
  $theHash{penetrance}{html_label} = 'Penetrance / Text';
  $theHash{range}{html_label} = 'Penetrance / Range';
  $theHash{mat_effect}{html_label} = 'Mat Effect';
  $theHash{pat_effect}{html_label} = 'Pat Effect';
  $theHash{heat_sens}{html_label} = 'Temp_sensitive /<BR>Degree (Int)';
#   $theHash{sensitivity}{html_label} = 'Temp. Sens. / Degree';
#   $theHash{heat_sens}{html_label} = 'Heat_sensitive / Degree (Int)';
#   $theHash{cold_sens}{html_label} = 'Cold_sensitive / Degree (Int)';
  $theHash{func}{html_label} = 'Func. Change?';
  $theHash{haplo}{html_label} = 'Haploinsufficient';
  $theHash{obj_remark}{html_label} = 'Object Remark (no dump)';

  $theHash{rnai_brief}{html_field_name} = 'RNAi Brief Description';
  $theHash{curator}{html_field_name} = 'Curator';
  $theHash{paper}{html_field_name} = 'Paper Reference';
  $theHash{person}{html_field_name} = 'Person Reference';
  $theHash{not}{html_field_name} = 'NOT';			# This x3 (horizontal) + option to add underneath
  $theHash{term}{html_field_name} = 'Phenotype Ontology Term';	# This x3 (horizontal) + option to add underneath
  $theHash{phen_remark}{html_field_name} = 'Remark (Phenotype)';	# This x3 (horizontal) + option to add underneath
  $theHash{quantity_remark}{html_field_name} = 'Quantity Remark';	# This x3 (horizontal) + option to add underneath
  $theHash{quantity}{html_field_name} = 'Quantity (put one or two #s)';	# This x3 (horizontal) + option to add underneath
  $theHash{go_sug}{html_field_name} = 'GO Term Suggestion';	# Add this  This x3 + option to add
  $theHash{suggested}{html_field_name} = 'Suggested Term';	# Add this  This x3 + option to add
  $theHash{sug_ref}{html_field_name} = "Suggested Term's Reference";	# Add this  This x3 + option to add
  $theHash{sug_def}{html_field_name} = "Suggested Term's Definition";	# Add this  This x3 + option to add
#   $theHash{phenotype}{html_field_name} = 'Phenotype Text<BR>Data from<BR>geneace only';
  $theHash{phenotype}{html_field_name} = 'Geneace Text';	# changed label for Karen  2007 10 01
  $theHash{intx_desc}{html_field_name} = 'Genetic<BR>Interaction<BR>Description<BR>No dump';
  $theHash{paper_remark}{html_field_name} = 'Paper Remark<BR><FONT SIZE=-2>No dump<BR><FONT COLOR=red>This will append<BR>to all objects with<BR>the same paper</FONT></FONT>';
  $theHash{hist_remark}{html_field_name} = 'History of<BR>Paper Remark';
  $theHash{condition}{html_field_name} = 'Condition';		# move to top of block like first pass
  $theHash{genotype}{html_field_name} = 'Genotype';		# Add this (like paper ref for text)
  $theHash{treatment}{html_field_name} = 'Treatment';		# Add this (like Condition for text)
  $theHash{lifestage}{html_field_name} = 'Life Stage';		# Add this (like paper ref for text) with link to http://tazendra.caltech.edu/~postgres/cgi-bin/phenotype_curation.cgi?class=Life_stage&class_type=WormBase&action=Class
  $theHash{anat_term}{html_field_name} = 'Anatomy Term';	# Add this (like paper ref for text) 
  $theHash{temperature}{html_field_name} = 'Temperature';	# Add this (like paper ref for text)
  $theHash{strain}{html_field_name} = 'Strain';			# Add this (like paper ref for text)
  $theHash{preparation}{html_field_name} = 'Preparation';	# Add this (like condition for text)
  $theHash{treatment}{html_field_name} = 'Treatment';		# Add this (like condition for text)
  $theHash{nature}{html_field_name} = 'Nature';
  $theHash{delivered}{html_field_name} = 'Delivered by';	
  $theHash{penetrance}{html_field_name} = 'Penetrance Text';
  $theHash{range}{html_field_name} = 'Penetrance Range<BR>(put one or two #s)';
  $theHash{percent}{html_field_name} = 'Percent';
  $theHash{mat_effect}{html_field_name} = 'Mat Effect';	
  $theHash{pat_effect}{html_field_name} = 'Pat Effect';	
#   $theHash{sensitivity}{html_field_name} = 'Sensitivity';
#   $theHash{degree}{html_field_name} = 'Degree';	
  $theHash{func}{html_field_name} = 'Func';
  $theHash{haplo}{html_field_name} = 'Haploinsufficient';
  $theHash{obj_remark}{html_field_name} = 'Object Remark (no dump)';
} # sub initializeHash

#################  HASH SECTION #################



sub dump {
#   print "This should take a long time (10 mins ?), please wait for the link to show below.<BR>\n";
  my $date = &getSimpleSecDate(); print "START $date<BR>\n";
  print "This link may work when the page stops loading, to be safe wait 10 seconds and see that the last entry is yt5 or something late in the alphabet like that.<BR>\n";
  print "<A TARGET=new HREF=http://tazendra.caltech.edu/~postgres/cgi-bin/data/allele_phenotype.ace>latest allele_phenotype.ace</A></BR>\n";
  print "<A TARGET=new HREF=http://tazendra.caltech.edu/~postgres/cgi-bin/data/allele_phenotype_papers.ace>latest allele_phenotype_papers.ace</A></BR>\n";
#   `/home/postgres/work/citace_upload/allele_phenotype/wrapper.pl`;
  `/home/postgres/work/citace_upload/allele_phenotype/get_all.pl`;
  $date = &getSimpleSecDate(); print "END $date<BR>\n";
} # sub dump


sub filterForPostgres {	# filter values for postgres
  my $value = shift;
  $value =~ s/\'/\\\'/g;
  return $value;
} # sub filterForPostgres


__END__

  # moved curators to printHtmlMultSelect 2007 04 23
sub printHtmlSelectCurators {	# print html select blocks for curators
  my ($type, $group_mult_count) = @_;
  my $g_type = $type . "_$group_mult_count";
  my @curators = ('Carol Bastiani', 'Ranjana Kishore', 'Erich Schwarz', 'Kimberly Van Auken', 'Igor Antoshechkin', 'Raymond Lee', 'Wen Chen', 'Andrei Petcherski', 'Gary Schindelman', 'Paul Sternberg',  'Juancarlos Testing');
  print <<"  EndOfText";
  <TR>
    <TD ALIGN="right"><STRONG>$theHash{$type}{html_field_name} :</STRONG></TD>
  EndOfText
  print "    <TD><SELECT NAME=\"html_value_main_$g_type\" SIZE=1>\n";
  if ($theHash{$g_type}{html_value} =~ m/\"/) { $theHash{$g_type}{html_value} =~ s/\"/&quot;/g; } 
  if ($theHash{$g_type}{html_value}) { print "      <OPTION selected>$theHash{$g_type}{html_value}</OPTION>\n"; }
  print "      <OPTION > </OPTION>\n";
    # if loaded or queried, show option, otherwise default to '' option
  foreach (@curators) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n  </TR>\n";
} # sub printHtmlSelectCurators
