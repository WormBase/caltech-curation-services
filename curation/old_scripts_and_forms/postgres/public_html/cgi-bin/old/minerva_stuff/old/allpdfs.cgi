#!/usr/bin/perl -T
#
# Alternate check out form to select by PDF (Can print minerva PDF).
# 
# Show choice of curators. (&Process has no $action. &Display has neither $pdf
# nor $curator, so shows &ChooseCurator)  ``Curator !''
# Show chosen name and choice of PDFs.  (&Process has ``Curator !'' so queries
# curator name, displays curator name.  &Display has $curator and no $pdf, so
# shows &lspdfs() and print hidden input field with $curator.)  ``PDF !''
# Show chosen curator and PDF and request confimation to curate  (&Process 
# has ``PDF !'' so queries curator name and pdf name; displays both.
# &Display has both $pdf and $curator, so requests confirmation and refers to
# appropriate curation_person.cgi)  ``Curate !''
#
# Updated to get list of athena pdfs from athena, display and allow to choose.
# Updated to have a search feature by number match the beginning of those pdfs.
# Doesn't allow printing of athena pdfs (or search pdfs)
# 2002 05 16
#
# Updated link to Athena PDFs to point to /tif_pdf/  2002 07 30


use strict;
use CGI;
use LWP::Simple;

my $query = new CGI;

my $curator = "";
my $pdf = "";		# pdf on minerva
my $pdf2 = "";		# pdf on athena
my $pdf3 = "";		# pdf number searching for

&OpenHTML();
&Process();
&Display();
&CloseHTML();

sub Display {
  if ( !(($pdf)||($pdf2)||($pdf3)) && !($curator) ) { &ChooseCurator(); }
				# at first get curator
  if ( !(($pdf)||($pdf2)||($pdf3)) && ($curator) ) { &lspdfs(); }
				# when curator, get pdf
  if ( (($pdf) || ($pdf2)||($pdf3)) && ($curator) ) { 
				# when both, refer to appropriate curation.cgi
    if ($curator eq 'Wen Chen') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_wen.cgi\">";
    } elsif ($curator eq 'Raymond Lee') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_raymond.cgi\">";
    } elsif ($curator eq 'Andrei Petcherski') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_andrei.cgi\">";
    } elsif ($curator eq 'Erich Schwarz') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_erich.cgi\">";
    } elsif ($curator eq 'Paul Sternberg') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_paul.cgi\">";
    } elsif ($curator eq 'Andrei Testing') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_andrei_play.cgi\">";
    } elsif ($curator eq 'Juancarlos Testing') {
      print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/curation_azurebrd.cgi\">";
    } else { 
      print "You have not chosen a valid Curator, contact the admin.<P>\n";
    }

    print "<INPUT TYPE=\"hidden\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
				# pass curator value in hidden field
    print "<INPUT TYPE=\"hidden\" NAME=\"pdf_name\" VALUE=\"$pdf\">\n";
				# pass pdf value in hidden field
    print "<INPUT TYPE=\"hidden\" NAME=\"pdf2_name\" VALUE=\"$pdf\">\n";
				# pass pdf value in hidden field
    print "<INPUT TYPE=\"hidden\" NAME=\"pdf3_name\" VALUE=\"$pdf\">\n";
				# pass pdf value in hidden field
    print "Are these choices okay ? : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curate !\"><BR><BR>\n";
    print "<INPUT TYPE=\"hidden\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
    print "</FORM>\n";
  } # if ( ($pdf) && ($curator) ) 
} # sub Display 
  
sub Process {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
  } # unless ($action = $query->param('action')) 

  if ( ($action eq 'Curator !') || ($action eq 'PDF !') || ($action eq 'PDF2 !') || 
       ($action eq 'PDF3 !') || ($action eq 'Print !') ) {
			# at first point or second point get curator
    my $oop;
    if ( $query->param("curator_name") ) { 
      $oop = $query->param("curator_name"); 
      my $curator_name = &Untaint($oop);
      $curator = $curator_name;
    } else { $oop = "1"; }
  } # if ($action eq 'Curator !') 
  if ($curator) { print "You claim to be $curator<P>\n"; }
 
  if ($action eq 'PDF !') {	# at second point also get pdf
    my $oop;
    if ( $query->param("pdf_name") ) { 
      $oop = $query->param("pdf_name"); 
      my $pdf_name = &Untaint($oop);
      $pdf = $pdf_name;
    } else { $oop = "1"; }
  } # if ($action eq 'PDF !') 
  if ($pdf) { print "Your PDF is <A HREF=\"http://minerva.caltech.edu/~azurebrd/allpdfs/$pdf\">$pdf</A><P>\n"; }

  if ($action eq 'PDF2 !') {	# at second point also get pdf
    my $oop;
    if ( $query->param("pdf2_name") ) { 
      $oop = $query->param("pdf2_name"); 
      my $pdf2_name = &Untaint($oop);
      $pdf2 = $pdf2_name;
    } else { $oop = "1"; }
  } # if ($action eq 'PDF2 !') 
  if ($pdf2) { print "Your PDF is <A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/$pdf2\">$pdf2</A><P>\n"; }

  if ($action eq 'PDF3 !') {	# at second point also get pdf
    my $oop;
    if ( $query->param("pdf3_name") ) { 
      $oop = $query->param("pdf3_name"); 
      my $pdf3_name = &Untaint($oop);
      $pdf3 = $pdf3_name;
    } # if ( $query->param("pdf3_name") ) 
    my @pdfathena = &getAthenaPdfs();
    my @pdfminerva = &getMinervaPdfs();
    foreach $_ (@pdfminerva) {
      if ($_ =~ m/^$pdf3/) { print "Possible PDF : <A HREF=\"http://minerva.caltech.edu/~azurebrd/allpdfs/$pdf\">$_</A><P>\n"; }
    } # foreach $_ (@pdfminerva)
    foreach $_ (@pdfathena) {
      if ($_ =~ m/^$pdf3/) { print "Possible PDF : <A HREF=\"http://athena.caltech.edu/~daniel/tif_pdf/$pdf2\">$_</A><P>\n"; }
    } # foreach $_ (@pdfathena)
  } # if ($action eq 'PDF3 !') 

  if ($action eq 'Print !') {
    my $oop;
    if ( $query->param("pdf_name") ) { 
      $oop = $query->param("pdf_name"); 
      my $pdf_name = &Untaint($oop);
      $pdf = $pdf_name;
    &PrintPDF($pdf_name);
    } else { $oop = "1"; }
  } # if ($action eq 'Print !') 
} # sub ShowChoices

sub PrintPDF {
  my $oop = shift;
  my $pdftoprint = &Untaint($oop);
  my $path = "/home3/allpdfs/";
  $ENV{PATH} = &Untaint($ENV{PATH});
  my $result = qx`/usr/bin/pdftops ${path}${pdftoprint} - | /usr/bin/lpr`;
}

sub ChooseCurator {
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/allpdfs.cgi\">";
  print "<TABLE>\n";
  print "<TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=6> \n";
  print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Raymond Lee</OPTION>\n";
  print "<OPTION>Andrei Petcherski</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
#   print "<OPTION>Andrei Testing</OPTION>\n";
  print "<OPTION>Juancarlos Testing</OPTION>\n";
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD><BR><BR>\n";
  print "<INPUT TYPE=\"hidden\" NAME=\"pdf_name\" VALUE=\"$pdf\">\n";
  print "<INPUT TYPE=\"hidden\" NAME=\"pdf2_name\" VALUE=\"$pdf\">\n";
  print "<INPUT TYPE=\"hidden\" NAME=\"pdf3_name\" VALUE=\"$pdf\">\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub ChooseCurator 

sub lspdfs {
  print "<FORM METHOD=\"POST\" ACTION=\"http://minerva.caltech.edu/~postgres/cgi-bin/allpdfs.cgi\">";
  print "<TABLE>\n";

    # minerva pdfs
  my @pdfminerva = &getMinervaPdfs();
  print "<TR><TD>Select your PDF among these " . scalar(@pdfminerva) . " : </TD><TD><SELECT NAME=\"pdf_name\" SIZE=5> \n";
  foreach $_ (reverse @pdfminerva) {	# show all in descending order
    print "<OPTION>$_</OPTION>\n";	# show as html form option
  } # foreach $_ (reverse @pdfminerva) {
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"PDF !\"></TD>\n";
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Print !\"></TD></TR>\n";

    # athena pdfs
  my @pdfathena = &getAthenaPdfs();		# populate list of athena pdfs
  print "<TR><TD>Select your PDF among these " . scalar(@pdfathena) . " : </TD><TD><SELECT NAME=\"pdf2_name\" SIZE=5> \n";
  foreach my $pdfath (reverse @pdfathena) {		# deal with athena pdfs
    $pdfath =~ m/(\d+).*/;
    print "<OPTION>$pdfath</OPTION>\n";
  } # foreach my $pdfath (@pdfathena)
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"PDF2 !\"></TD></TR>\n";

    # search pdfs
  print "<TR><TD>Select your PDF by typing the number : </TD><TD><INPUT NAME=\"pdf3_name\" SIZE=40></TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"PDF3 !\"></TD></TR>\n";

  print "<INPUT TYPE=\"hidden\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub lspdfs 

sub getMinervaPdfs {
  my @filelist;
  push @filelist, </home3/allpdfs/*.pdf>;	# get all pdfs
  foreach $_ (reverse @filelist) {		# show all in descending order
    $_ =~ s/\/home3\/allpdfs\///g;		# get the filename
  } # foreach $_ (reverse @filelist) {
  return @filelist;
} # sub getMinervaPdfs

sub getAthenaPdfs {                     # populate array of athena pdfs
    # use LWP::Simple to get the list of PDFs from Athena
  my $page = get "http://athena.caltech.edu/~daniel/tif_pdf/";
  my @pdfathena = $page =~ m/HREF="(.*?tif\.pdf)"/g;       # get list of athena pdfs
  return @pdfathena;
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



sub OpenHTML {

print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://minerva.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<HEAD>
<TITLE>PGSQL display Minerva</TITLE>
</HEAD>
<BODY bgcolor=#000000 text=#aaaaaa link=#cccccc>
EndOfText

} # sub OpenHTML 


sub CloseHTML {
  print <<"EndOfText";
<BR>
</BODY>
EndOfText
} # sub CloseHTML 
