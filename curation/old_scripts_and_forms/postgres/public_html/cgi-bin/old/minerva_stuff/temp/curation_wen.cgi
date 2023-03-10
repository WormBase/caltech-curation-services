#!/usr/bin/perl -w

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
# Note, the system calls to mutt appear to be insecure due to $ENV{PATH} under
# -T under CGI; this is not a problem under mod_perl.
#
# Fixed Reset Button 2001-11-01
# Fixed Checkboxes relation to text fields, still don't load state.  2001-11-01
# PG and HTML parameters and paramvalues now separate.  2001-11-01
# Pg !  Shows spaces on empty table entry (i.e. dividers)  Proper labels on top 
# and bottom.  2001-11-01
# Mail with bad or no PDFs.  A mutt error is noticed and mail is sent again
# without an attachment.  2001-11-08
# allpdfs.cgi written to pass on pdf_name to curator form.  ``Curate !''
# $action written to account for pdf_name, get cgc number, and query pgsql with
# cgc number as join_key for reference info.  2001-11-08

use strict;
use CGI;
use Fcntl;
use HTML::Template;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";


# files
my $data_file = '/home/postgres/public_html/cgi-bin/data/curation_data_wen.txt';
my $save_file = '/home/postgres/public_html/cgi-bin/data/curation_save_wen.txt';
my $html_file = '/home/postgres/public_html/cgi-bin/curation_html_wen.txt';
  # set this to the path of the folder with the pdf files
my $attachment_path = '/home3/allpdfs/';

# emails
# my $raymond = 'azurebrd@minerva.caltech.edu';
# my $erich = 'azurebrd@minerva.caltech.edu';
# my $wen = 'azurebrd@minerva.caltech.edu';
# my $rec_cgc = 'azurebrd@minerva.caltech.edu';
# my $rec_worm = 'azurebrd@minerva.caltech.edu';
# my $rec_syl = 'bounce@minerva.caltech.edu bounce@minerva.caltech.edu';
my $raymond = 'raymond@caltech.edu';
my $erich = 'emsch@its.caltech.edu';
my $wen = 'wchen@its.caltech.edu';
my $rec_cgc = 'cgc@mrc-lmb.cam.ac.uk';
my $rec_worm = 'worm@sanger.ac.uk';
my $rec_syl = 'sylvia@sanger.ac.uk';

# flags
our $displayform = 1;

# vars
my $pubID = "";
my $reference = "lala";
my @PGparameters = qw(pubID pdffilename curator reference newsymbol synonym 
			mappingdata genefunction associationequiv associationnew
			expression rnai transgene overexpression mosaic antibody 
			extractedallelename extractedallelenew newmutant 
			sequencechange genesymbols geneproduct structurecorrection 
			sequencefeatures cellname cellfunction ablationdata 
			newsnp stlouissnp goodphoto comment);
my @HTMLparameters = qw(pubID pdffilename curator reference newsymbol1 newsymbol2
			synonym1 synonym2 mappingdata1 mappingdata2 
			genefunction1 genefunction2 association1 association2
			association3 association4 expression1 expression2
			rnai1 rnai2 transgene1 transgene2 overexpression1
			overexpression2 mosaic1 mosaic2 antibody1 antibody2
			extractedallele1 extractedallele2 extractedallele3
			extractedallele4 newmutant1 newmutant2 sequencechange1
			sequencechange2 genesymbols1 genesymbols2 geneproduct1
			geneproduct2 structurecorrection1 structurecorrection2
			sequencefeatures1 sequencefeatures2 cellname1 cellname2
			cellfunction1 cellfunction2 ablationdata1 ablationdata2
			newsnp1 newsnp2 stlouissnp1 stlouissnp2 goodphoto
			comment);
my @PGparamvalues;
my @HTMLparamvalues;
  # values to determine whom which fields go to
my @PGparammail = qw(0 0 0 0 rec rec
			rec erich rec worm 
			wen ray wen erich 0 0
			0 rec erich 
			syl 0 0 worm 
			0 ray ray ray 
			0 0 0 0);
my @PGparamsubjects = ("", "", "", "", "Gene New Symbol", "Gene Synonym",
			"Gene Mapping Data", "Gene Function", "Gene Association", "Gene Association",
			"Gene Expression", "RNAi", "Transgene", "Overexpression", "", "", 
			"", "Allele Extracted", "New Mutant",
			"Allele Sequence Changed", "", "", "Gene Structure Correction",
			"", "Cell Name", "Cell Function", "Ablation Data",
			"", "", "", "");
my %variables;

&ResetForDisplay();		# Clear all Variables for HTML
&PrintHeader();			# print the HTML header
&Process();			# Essentially do everything
&DisplayForm();			# print the rest of the form
&PrintFooter();			# print the HTML footer

sub ResetForDisplay {
  foreach $_ (@HTMLparameters) {
    $variables{$_} = "";		# populate variables
  } # foreach $_ (@HTMLparameters)
  $variables{curator} = "Wen Chen";	# assign curator name
} # sub ResetForDisplay 

sub DisplayForm {
  if ($displayform) {
    &ClearForDisplay();		# clear empty fields for display
    my $template = HTML::Template->new(filename => "$html_file", die_on_bad_params => 0);
#     my %params = %variables;	# Unnecessary ?  Only used here...
#     $template->param(\%params);	# Replaced by following line, shouldn't break
    $template->param(\%variables);
    print $template->output();
  }
} # sub DisplayFrom 

sub ClearForDisplay {		# get rid of temp ``nodatahere'' for displaying html
  for (0.. scalar(@HTMLparameters)-1) {
				# for each parameter in arrays
    if ($variables{$HTMLparameters[$_]} eq "nodatahere") {
				# if it says ``nodatahere''
      $variables{$HTMLparameters[$_]} = "";
				# replace with proper empty space
    } # if ($variables{$HTMLparameters[$_]} eq "nodatahere") 
  } # for (0.. scalar(@HTMLparameters)-1) 
} # sub ClearForDisplay 

sub PGQueryRowify {		# Add lines to reference info
  my $result = shift;
  my @row;
  while (@row = $result->fetchrow) {
    $variables{reference} .= "$row[1]";
  } # while (@row = $result->fetchrow) 
} # sub PGQueryRowify 

sub PopulateReference {
  my @refparams = qw(author title journal volume pages year abstract);
				# name of reference parameters used in pgsql
  foreach $_ (@refparams) {	# for each pgsql reference data parameter
    my $result = $conn->exec( "SELECT * FROM $_ WHERE joinkey = '$variables{pubID}\';" );
    $variables{reference} .= "\n$_ == ";
				# add parameter name to reference info
    &PGQueryRowify($result);	
				# add reference info from pgsql to reference
				# info variable for html
  } # foreach $_ (@refparams) 
  my $result = $conn->exec( "UPDATE checked_out SET checked_out = \'$variables{curator}\' WHERE joinkey = \'$variables{pubID}\';" );
} # sub PopulateReference 

sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none';
  }

  if ($action eq 'Curate !') {
				# coming from the allpdfs.cgi, we have
				# the pdf_name, so we output the general info
				# by querying the reference data in pgsql
    my $oop;
    if ( $query->param('pdf_name') ) { 	
				# from allpdfs.cgi
      $oop = $query->param('pdf_name'); 
      $variables{pdffilename} = &Untaint($oop);
				# assign pdffilename
      $variables{pdffilename} =~ m/^(\d+)_/;
				# get cgc number
      $variables{pubID} = "cgc" . $1;
				# make number, i.e. pgsql joinkey
      &PopulateReference();
    } elsif ( $query->param('cgc_number') ) { 
				# from checkout.cgi
      $oop = $query->param('cgc_number');
      $variables{pubID} = &Untaint($oop);
				# assign pubID
      &PopulateReference();
    } else { $oop = "nodatahere"; }
				# if there's no pdf name, nothing.
  } # if ($action eq 'Curate !') 

  if ($action eq 'Load !') {
    open (LOAD, "$save_file") or die "cannot open $save_file : $!";
				# get saved file
    local $/ = "";		# get the whole things at once
    while (<LOAD>) { chomp; push @HTMLparamvalues, split("\t", $_); }
				# put stuff into array from tabs
    close (LOAD) or die "cannot close $save_file : $!";
				# close file
    for (0.. scalar(@HTMLparameters)-1) {
				# for each parameter in arrays
      $HTMLparamvalues[$_] =~ s/TABREPLACEMENT/\t/g;
				# put tabs back in
      $variables{$HTMLparameters[$_]} = $HTMLparamvalues[$_];
				# repopulate %variables hash
    } # for (0.. scalar(@HTMLparameters)-1) 
  } # if ($action eq 'Load') 

  elsif ($action eq 'Pg !') {
    $displayform = 0;
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
  } # elsif ($action eq 'Pg !') 

  elsif ( ($action eq 'Go !') || ($action eq 'Save !') ) {
    $displayform = 0;
    my $date = &GetDate();
    print "$date<BR>\n";
    @HTMLparamvalues = &QueryData();
    &HtmlToPg();

    if ($action eq 'Go !') {
      &OutputAndMail();
      &DealPg();
    } # if ($action eq 'Go !') 

    if ($action eq 'Save !') {
      &SaveState();
    } # if ($action eq 'Save !') 

  } # elsif ( ($action eq 'Go !') || ($action eq 'Save !') ) 

  elsif ($action eq 'Reset !') {
    &ResetForDisplay();		# Clear all Variables for HTML
  } # elsif ($action eq 'Reset !') {

  else { 1; }
} # sub Process 

sub SaveState {
  foreach $_ (@HTMLparamvalues) {
    $_ =~ s/\t/TABREPLACEMENT/g;
  } # foreach $_ (@HTMLparamvalues) 
  my $stufftosave = join("\t", @HTMLparamvalues);
  print "See all <A HREF=\"http://minerva.caltech.edu/~postgres/cgi-bin/data/curation_save_wen.txt\">saved</A>.<P>\n";
  open (SAVE, ">$save_file") or die "cannot create $save_file : $!";
    # Saving, not as file, but as list
  print SAVE "$stufftosave\n";
  close SAVE or die "Cannot close $save_file : $!";
} # sub SaveState 

sub OutputAndMail {
  print "See all <A HREF=\"http://minerva.caltech.edu/~postgres/cgi-bin/data/curation_data_wen.txt\">results</A> in the flatfile.<P>";
  open (OUT, ">>$data_file") || die "cannot create $data_file : $!";
  print "Here is the data you have entered : <BR>\n";
  for (0 .. scalar(@PGparameters)-1) {
    unless ( ($PGparamvalues[$_] eq $PGparameters[$_]) || ($PGparamvalues[$_] eq "") ) { 
      print "$PGparameters[$_] : $PGparamvalues[$_]<BR>\n";
      print OUT "$PGparameters[$_] :\t\"$PGparamvalues[$_]\"\n";
      if ( ($PGparammail[$_]) && ($PGparamvalues[$_] ne "yes") ) { &MuttMail($_); }
# MUTTMAIL REMOVE COMMENT
    } # unless ( ($PGparamvalues[$_] eq $PGparameters[$_]) ...
  } # for (0 .. scalar(@PGparameters)-1) 
  print "<P>\n";
  print OUT "\n"; 	# divider between .ace entries
  close OUT or die "Cannot close $data_file : $!";
} # sub OutputAndMail 

sub DealPg {		
# test that Pg is working
#   my $result = $conn->exec( "DELETE FROM testcuration2 WHERE pubid = 'ThePubID';");
#   $result = $conn->exec( "INSERT INTO testcuration2 VALUES ('ThePubID', 'ThePDFname', 'CuratorPerson', 'RefData', 'No1', 'NewSymbol', 'nosy1', 'Synonym2', '', '', '', '', '', '', '', '', 'noex1', 'Expression2', '', '', '', '', '', '', '', '', 'noan1', 'antibody2', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'noce1', 'Cellname2', '', '', '', '', '', '', '', '', '', '');" ); 
  &AddToPg();
#   &PrintPgTable();	# Show All in pgsql testcuration3
  &ShowPgQuery();
} # sub DealPg 

sub MuttMail {
  my $array_val = shift;	# get the array value
  my $attach = 0;		# flag to see whether to send attachment
  my $muttpath = "/usr/local/bin/mutt";
				# set path to mutt mailer
  my $subject = "Something Wrong with Default Subject Maker (check array)";
				# initialize subject
  if ($PGparamsubjects[$array_val]) { $subject = "$PGparamsubjects[$array_val]"; }
  my $email = "azurebrd\@minerva.caltech.edu";
				# initialize email
  if ($PGparammail[$array_val]) { 
    SWITCH : {			# use $PGparammail to reassign email to send to
      if ($PGparammail[$array_val] eq "rec") { $email = $rec_cgc; $attach = 1; last SWITCH; }			# send mail to cgc with attachment
      if ($PGparammail[$array_val] eq "worm") { $email = $rec_worm; $attach = 1; last SWITCH; }			# send mail to worm with attachment
      if ($PGparammail[$array_val] eq "syl") { $email = $rec_syl; $attach = 1; last SWITCH; }			# send mail to sylvia with attachment
      if ($PGparammail[$array_val] eq "wen") { $email = $wen; last SWITCH; }
      if ($PGparammail[$array_val] eq "ray") { $email = $raymond; last SWITCH; }
      if ($PGparammail[$array_val] eq "erich") { $email = $erich; last SWITCH; }
    } # SWITCH 
  } # if ($PGparammail[$array_val]) 
  my $date = &GetDate();	# get the date
  my $include_file ="/home/azurebrd/work/curationform/mutt/include";
				# file with body of email
  open (INC, ">$include_file") or die "Cannot create $include_file : $!";
				# open filehandle to write to it
  unless ($PGparamvalues[0] eq "nodatahere") { print INC "pubID :\t$PGparamvalues[0]\n"; }						# print pubID
  unless ($PGparamvalues[1] eq "nodatahere") { print INC "pdffilename :\t$PGparamvalues[1]\n"; }
						# print pdffilename
  print INC "Curator :\t$PGparamvalues[2]\n";	# print Curator name
  print INC "Date :\t$date\n";			# print date
  print INC "$PGparamsubjects[$array_val] : $PGparamvalues[$array_val]\n";	
				# print info
  unless ($PGparamvalues[3] eq "nodatahere") { print INC "Reference :\n$PGparamvalues[3]\n"; }	
				# print reference info
  close INC or die "Cannot close $include_file : $!";
  if ($attach) {		# if meant to send attachment
    &MailAttachment($muttpath, $include_file, $subject, $email);
  } else { # if ($attach) 	# if not meant to send attachment
    my $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" $email));
  }
    # for raymond, mails him without an attachment
#   $email = $raymond;				# for pseudo-cc
#   my $muttout = system(qq(echo "" | /usr/local/bin/mutt -i "/home/azurebrd/work/curationform/mutt/include" -s "$subject" $email));
} # sub MuttMail 

sub MailAttachment {
  my $muttpath = shift; my $include_file = shift; my $subject = shift; my $email
= shift;				# get subroutine parameters
  my $attachment = $PGparamvalues[1];	# get attachment file name
  my $muttout;				# define mutt return (possible error)
  if ($attachment =~ m/^(.*)\.\w+$/) { 	# if ends in a dot
    $attachment = $attachment_path . $1 . ".pdf"; 	# assign file
    $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" -a "$attachment" $email));			  # send mail
  } elsif ($attachment =~ m/^\w+$/) { 	# if no dot
    $attachment = $attachment_path . $attachment . ".pdf";	# assign file
    $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" -a "$attachment" $email));			  # send mail
  } else { 				# if doesn't look right
    print "POSSIBLY BAD PDF FILE NAME mail sent without attachment to $email<BR>\n"; 
					# print error warning
    my $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" $email));
					# mail again without attachment
  } # if ($attachment =~ m/^(.*)\.\w+$/) 
  if ($muttout) { 
    print "MUTT ERROR : $attachment : most likely no PDF email with attachment sent due to bad PDF file name or file not in directory.  Check errorlog.  Email without attachment sent.<BR>\n"; 
    my $muttout = system(qq(echo "" | $muttpath -i "$include_file" -s "$subject" $email));
					# mail again without attachment
  } # if ($muttout) 			# if mutt returns at error
} # sub MailAttachment 

sub QueryData {
  my $oop; # my @HTMLparamvalues;
  for (0 .. scalar(@HTMLparameters)-1 ) {
    if ( $query->param("$HTMLparameters[$_]") ) { $oop = $query->param("$HTMLparameters[$_]"); }
    else { $oop = "nodatahere"; }
    $HTMLparamvalues[$_] = &Untaint($oop);
  }
  return @HTMLparamvalues;
} # sub QueryData 

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
<TITLE>Wen's Curation Form</TITLE>
</HEAD>
  
<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
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


sub PrintTableLabels {		# Just a bunch of table down entries
  print "<TR><TD>pubID</TD><TD>pdffilename</TD><TD>curator</TD><TD>reference</TD><TD>newsymbol</TD><TD>synonym</TD><TD>mappingdata</TD><TD>genefunction</TD><TD>associationequiv</TD><TD>associationnew</TD><TD>expression</TD><TD>rnai</TD><TD>transgene</TD><TD>overexpression</TD><TD>mosaic</TD><TD>antibody</TD><TD>extractedallelename</TD><TD>extractedallelenew</TD><TD>newmutant</TD><TD>sequencechange</TD><TD>genesymbols</TD><TD>geneproduct</TD><TD>structurecorrection</TD><TD>sequencefeatures</TD><TD>cellname</TD><TD>cellfunction</TD><TD>ablationdata</TD><TD>newsnp</TD><TD>stlouissnp</TD><TD>goodphoto</TD><TD>comment</TD></TR>\n";
} # sub PrintTableLabels 

# sub PrintTableLabels {		# Just a bunch of table down entries
#   print "<TR><TD>pubID</TD><TD>pdffilename</TD><TD>curator</TD><TD>reference</TD><TD>newsymbol1</TD><TD>newsymbol2</TD><TD>synonym1</TD><TD>synonym2</TD><TD>mappingdata1</TD><TD>mappingdata2</TD><TD>genefunction1</TD><TD>genefunction2</TD><TD>association1</TD><TD>association2</TD><TD>association3</TD><TD>association4</TD><TD>expression1</TD><TD>expression2</TD><TD>rnai1</TD><TD>rnai2</TD><TD>transgene1</TD><TD>transgene2</TD><TD>overexpression1</TD><TD>overexpression2</TD><TD>mosaic1</TD><TD>mosaic2</TD><TD>antibody1</TD><TD>antibody2</TD><TD>extractedallele1</TD><TD>extractedallele2</TD><TD>extractedallele3</TD><TD>extractedallele4</TD><TD>newmutant1</TD><TD>newmutant2</TD><TD>sequencechange1</TD><TD>sequencechange2</TD><TD>genesymbols1</TD><TD>genesymbols2</TD><TD>geneproduct1</TD><TD>geneproduct2</TD><TD>structurecorrection1</TD><TD>structurecorrection2</TD><TD>sequencefeatures1</TD><TD>sequencefeatures2</TD><TD>cellname1</TD><TD>cellname2</TD><TD>cellfunction1</TD><TD>cellfunction2</TD><TD>ablationdata1</TD><TD>ablationdata2</TD><TD>newsnp1</TD><TD>newsnp2</TD><TD>stlouissnp1</TD><TD>stlouissnp2</TD><TD>goodphoto</TD><TD>comment</TD></TR>\n";
# } # sub PrintTableLabels 

sub AddToPg {			# Add values to Postgres
  my @valuesforpostgres = @PGparamvalues;		# copy values
  foreach $_ (@valuesforpostgres) {
    if ($_ eq "nodatahere") { $_ = ''; }	# empty out those with no data
    if ($_ =~ m/'/) { $_ =~ s/'/''/g; }
  } # foreach $_ (@valuesforpostgres) 
    # insert the data
  my $result = $conn->exec( "INSERT INTO testcuration3 VALUES ( '$valuesforpostgres[0]', '$valuesforpostgres[1]', '$valuesforpostgres[2]', '$valuesforpostgres[3]', '$valuesforpostgres[4]', '$valuesforpostgres[5]', '$valuesforpostgres[6]', '$valuesforpostgres[7]', '$valuesforpostgres[8]', '$valuesforpostgres[9]', '$valuesforpostgres[10]', '$valuesforpostgres[11]', '$valuesforpostgres[12]', '$valuesforpostgres[13]', '$valuesforpostgres[14]', '$valuesforpostgres[15]', '$valuesforpostgres[16]', '$valuesforpostgres[17]', '$valuesforpostgres[18]', '$valuesforpostgres[19]', '$valuesforpostgres[20]', '$valuesforpostgres[21]', '$valuesforpostgres[22]', '$valuesforpostgres[23]', '$valuesforpostgres[24]', '$valuesforpostgres[25]', '$valuesforpostgres[26]', '$valuesforpostgres[27]', '$valuesforpostgres[28]', '$valuesforpostgres[29]', '$valuesforpostgres[30]');" ); # , '$valuesforpostgres[31]', '$valuesforpostgres[32]', '$valuesforpostgres[33]', '$valuesforpostgres[34]', '$valuesforpostgres[35]', '$valuesforpostgres[36]', '$valuesforpostgres[37]', '$valuesforpostgres[38]', '$valuesforpostgres[39]', '$valuesforpostgres[40]', '$valuesforpostgres[41]', '$valuesforpostgres[42]', '$valuesforpostgres[43]', '$valuesforpostgres[44]', '$valuesforpostgres[45]', '$valuesforpostgres[46]', '$valuesforpostgres[47]', '$valuesforpostgres[48]', '$valuesforpostgres[49]', '$valuesforpostgres[50]', '$valuesforpostgres[51]', '$valuesforpostgres[52]', '$valuesforpostgres[53]', '$valuesforpostgres[54]', '$valuesforpostgres[55]');" );
} # sub AddToPg 

sub PrintPgTable {
  my @ary;
  Pg::doQuery($conn, "select * from testcuration3", \@ary);
  print "We have made an Entry on PostgreSQL.  We now query our PostgreSQL database to see all the information in it.<BR>\n";
  print "<CENTER><TABLE border=1 cellspacing=5>\n";
  &PrintTableLabels();
  for my $i ( 0 .. $#ary ) {
    print "<TR>";
    for my $j ( 0 .. $#{$ary[$i]} ) {
      print "<TD>$ary[$i][$j]</TD>";
    } # for my $j ( 0 .. $#{$ary[$i]} ) 
    print "</TR>\n";
  } # for my $i ( 0 .. $#ary ) 
  print "</TABLE></CENTER>\n";
} # sub PrintPgTable 

sub ShowPgQuery {
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://minerva.caltech.edu/~postgres/cgi-bin/curation_wen.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
}


sub HtmlToPg {
  my $i; my $j = 4;			# initialize

    # Reference Info
  for ($i = 0; $i < 5; $i++) {
    if ($HTMLparamvalues[$i] ne "nodatahere") { $PGparamvalues[$i] = $HTMLparamvalues[$i]; }
  } # for ($i = 0; $i < 5; $i++) 

    # Compress double fields into single PGparameters, PGparamvalues info
  for ($i = 5; $i <= 53; $i+=2) {	# increase $i by 2s
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
    } else { 1; }			# nothing
    $j++;				# increase $j by 1s
  } # for (my $i = 5; $i <= 53; $i+=2) 

    # Good Photo and Comments
  if ($HTMLparamvalues[54] ne "nodatahere") { $PGparamvalues[29] = $HTMLparamvalues[54]; }
  if ($HTMLparamvalues[55] ne "nodatahere") { $PGparamvalues[30] = $HTMLparamvalues[55]; }
} # sub HtmlToPg 

sub NOTHING {
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
}
