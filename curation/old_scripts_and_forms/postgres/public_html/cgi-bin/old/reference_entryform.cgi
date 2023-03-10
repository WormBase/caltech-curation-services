#!/usr/bin/perl 

# Alternate form to enter reference data for paper not in database.
 
# Show choice of curators. (&Process has no $action. &Display has neither $pdf
# nor $curator, so shows &ChooseCurator)  ``Curator !''
# Show chosen name and choice of PDFs.  (&Process has ``Curator !'' so queries
# curator name, displays curator name.  &Display has $curator and no $pdf, so
# shows &lspdfs() and print hidden input field with $curator.)  ``PDF !''
# Show chosen curator and PDF and request confimation to curate  (&Process 
# has ``PDF !'' so queries curator name and pdf name; displays both.
# &Display has both $pdf and $curator, so requests confirmation and refers to
# appropriate curation_person.cgi)  ``Curate !''
# Added ``med'' table to Pg and script.  2001-12-06
# Prints .endnote format to $outfile.  2001-12-06
# Created ref_ tables (ref_cgc ref_pmid ref_med ref_author ref_title
# ref_journal, etc for the @params) and changed the INSERT INTOs to insert data
# into those tables instead (which will now have timestamps)
# Update &GetReferenceInfo(); to query ref_journal for distinct journal entries,
# and present html OPTION for each of those, so as to not introduce extra
# journals.  (only choose those without quotes, as those with quotes seem to be
# books)  2002-02-02
#
# Added ref_other table for non-wbpaper paper types.  2005 05 26
#
# Insert CURRENT_TIMESTAMP into ref_origtime for Eimear's dumping script.  
# Take out Shirin and put in Ranjana Kishore, Igor Antoshechkin, Carol Bastiani,
# Cecilia Nakamura, Kimberly Van Auken.   2005 06 02


use Jex;	# &mailer();
use strict;
use CGI;
use Fcntl;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $query = new CGI;

my $outfile = "/home/postgres/work/pgpopulation/pg.endnote";
open (OUT, ">>$outfile") or die "Cannot open $outfile : $!";

my $curator = "";
my $type = "";
my @params = qw(type_number_name author_name title_name journal_name volume_name pages_name year_name abstract_name hardcopy_name pdf_name html_name tif_name lib_pdf_name);
my %variables;
# my $author = "";
# my $title = "";
# my $journal = "";
# my $volume = "";
# my $pages = "";
# my $year = "";
# my $abstract = "";
# my $hardcopy = "";
# my $pdf = "";
# my $html = "";
# my $tif = "";
# my $lib = "";

&OpenHTML();
&Process();
&Display();
&CloseHTML();

close (OUT) or die "Cannot close $outfile : $!";

sub Display {
  if ( !($type) && !($curator) ) { &ChooseCurator(); }
				# at first get curator
  if ( !($type) && ($curator) ) { &ChooseType(); }
				# when curator, get type
  if ( ($type) && ($curator) ) { &GetReferenceInfo(); }
				# when both, show info form
#     if ($curator eq 'Wen Chen') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_wen.cgi\">";
#     } elsif ($curator eq 'Raymond Lee') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_raymond.cgi\">";
#     } elsif ($curator eq 'Andrei Petcherski') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_andrei.cgi\">";
#     } elsif ($curator eq 'Erich Schwarz') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_erich.cgi\">";
#     } elsif ($curator eq 'Paul Sternberg') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_paul.cgi\">";
#     } elsif ($curator eq 'Andrei Testing') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_andrei_play.cgi\">";
#     } elsif ($curator eq 'Juancarlos Testing') {
#       print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/curation_azurebrd.cgi\">";
#     } else { 
#       print "You have not chosen a valid Curator, contact the admin.<P>\n";
#     }

} # sub Display 
  
sub Process {
  my $action;
  unless ($action = $query->param('action')) {
    $action = 'none';
  } # unless ($action = $query->param('action')) 

  if ( ($action eq 'Curator !') || ($action eq 'Type !') || ($action eq 'Populate !') ) {
			# at first point or second point get curator
    my $oop;
    if ( $query->param("curator_name") ) { 
      $oop = $query->param("curator_name"); 
      my $curator_name = &Untaint($oop);
      $curator = $curator_name;
    } else { $oop = "1"; }
  } # if ($action eq 'Curator !') 
 
  if ( ($action eq 'Type !') || ($action eq 'Populate !') ) {
			# at second point also get type
    my $oop;
    if ( $query->param("type_name") ) { 
      $oop = $query->param("type_name"); 
      my $type_name = &Untaint($oop);
      $type = $type_name;
    } else { $oop = "1"; }

  } # if ($action eq 'Type !') 
  
  LABEL : if ($action eq 'Populate !') {
    my $endnote = "";	# endnote entry, to be appended to

    my $oop;
    foreach $_ (@params) { 
      my $var = $_;
      $var =~ s/_name$//;
      if ( $query->param("$_") ) {
        $oop = $query->param("$_"); 
        $variables{$var} = &Untaint($oop);
      } # if ( $query->param("$_") ) 
    } # foreach $_ (@params) 

    my $joinkey = "";
    if ($type eq "Pubmed") { $joinkey .= "pmid"; }
    elsif ($type eq "CGC") { $joinkey .= "cgc"; }
    elsif ($type eq "Medline") { $joinkey .= "med"; }
    elsif ($type eq "Other") { $joinkey .= "oth"; }
    else { print "NOT A VALID TYPE $type<P>\n"; last LABEL; }
#     if ($variables{type_number} !~ m/[^\d]/) { 
# 				# if what entered is only digits
      $joinkey .= $variables{type_number}; 
# no longer care that it's only digits for Eimear's other type  2005 05 26
#     } else { print "NOT A VALID TYPE $variables{type_number}<P>\n"; last LABEL; }

    my $already_there_flag = &CheckIfExists($joinkey);
    if ($already_there_flag) {
      print "Entry $joinkey already there.<BR>\n";
    } else { # if ($already_there_flag) 
      print "Endnote file <A HREF=\"http://tazendra.caltech.edu/~azurebrd/out/pg.endnote\">here</A>.\n";		# link to endnote file being produced.
      print "ENTERING data for $joinkey : <BR>\n";
      my $result = $conn->exec( "INSERT INTO ref_reference_by VALUES ('$joinkey', '$curator')");
      $result = $conn->exec( "INSERT INTO ref_checked_out VALUES ('$joinkey', NULL)");
      $result = $conn->exec( "INSERT INTO ref_origtime VALUES ('$joinkey', CURRENT_TIMESTAMP)");	# insert into origtime for Eimear's dumping script  2005 06 02
      foreach $_ (@params) {
        my $var = $_;
        $var =~ s/_name$//;
        if ($variables{$var}) { 
          print "$var : $variables{$var}<BR>\n"; 
        } # if ($variables{$var}) 
        if ($var eq 'type_number') {
				# type_number is not a real key
          $endnote .= $joinkey . "\t";
				# add type
          $endnote .= $variables{$var} . "\t";
				# add pure number, extra \t for acc number

          if ($type eq "Pubmed") {
				# for pubmed, put in pmid table
            my $result = $conn->exec( "INSERT INTO ref_pmid VALUES ('$joinkey', '$variables{$var}')");
          } elsif ($type eq "CGC") {
				# for cgc, put in cgc table
            my $result = $conn->exec( "INSERT INTO ref_cgc VALUES ('$joinkey', '$variables{$var}')");
          } elsif ($type eq "Medline") {
				# for medline, put in med table
            my $result = $conn->exec( "INSERT INTO ref_med VALUES ('$joinkey', '$variables{$var}')");
          } elsif ($type eq "Other") {
            my $result = $conn->exec( "INSERT INTO ref_other VALUES ('$joinkey', '$variables{$var}')");
          } else { 1; }
        } else { # if ($var eq 'type_number')
				# for real keys
          if ($variables{$var}) {	
				# if an entry, make an entry (tab entry)
            my $result = $conn->exec( "INSERT INTO ref_$var VALUES ('$joinkey', '$variables{$var}')");
            $endnote .= "\t" . $variables{$var};
            if ($var eq 'journal') { &mailer('', 'qwang@its.caltech.edu', "$joinkey journal $variables{$var}", ''); }
          } else { # if ($variables{$var})
				# if no entry, write in NULL (tab)
            my $result = $conn->exec( "INSERT INTO ref_$var VALUES ('$joinkey', NULL)");
            $endnote .= "\t";
          } # else # if ($variables{$var})
        } # else # if ($var eq 'type_number')
      } # foreach $_ (@params) 
      print "<BR>\nEnter another $type entry ?<P>\n";
      print OUT "$endnote\n";	# enter endnote
    } # else # if ($already_there_flag) 

  } # LABEL : if ($action eq 'Populate !') 

    # Show values if known
  if ($curator) { print "You claim to be $curator<P>\n"; }
  if ($type) { print "You have chosen type $type<P>\n"; }
} # sub ShowChoices

sub CheckIfExists {	# hopefully this works, seems to
			# don't see how it could have, should have been ref_pmid, etc. instead of pmid  2005 05 26
  my $joinkey = shift;
  my $already_there_flag = "";
  if ($type eq "Pubmed") { 
#     my $result = $conn->exec( "SELECT * FROM pmid WHERE joinkey=\'$joinkey\'" );
    my $result = $conn->exec( "SELECT * FROM ref_pmid WHERE joinkey=\'$joinkey\'" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[0]) { $already_there_flag++; }
    }
  } elsif ($type eq "CGC") { 
#     my $result = $conn->exec( "SELECT * FROM cgc WHERE joinkey=\'$joinkey\'" );
    my $result = $conn->exec( "SELECT * FROM ref_cgc WHERE joinkey=\'$joinkey\'" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[0]) { $already_there_flag++; }
    }
  } elsif ($type eq "Medline") { 
#     my $result = $conn->exec( "SELECT * FROM med WHERE joinkey=\'$joinkey\'" );
    my $result = $conn->exec( "SELECT * FROM ref_med WHERE joinkey=\'$joinkey\'" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[0]) { $already_there_flag++; }
    }
  } elsif ($type eq "Other") { 
    my $result = $conn->exec( "SELECT * FROM ref_other WHERE joinkey=\'$joinkey\'" );
    my @row;
    while (@row = $result->fetchrow) {
      if ($row[0]) { $already_there_flag++; }
    }
  } else { 1; }
  return $already_there_flag;
} # sub CheckIfExists 

sub ChooseCurator {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/reference_entryform.cgi\">";
  print "<TABLE>\n";
  print "<TD>Select your Name among : </TD><TD><SELECT NAME=\"curator_name\" SIZE=13> \n";
  print "<OPTION>Igor Antoshechkin</OPTION>\n";
  print "<OPTION>Carol Bastiani</OPTION>\n";
  print "<OPTION>Wen Chen</OPTION>\n";
  print "<OPTION>Eimear Kenny</OPTION>\n";
  print "<OPTION>Ranjana Kishore</OPTION>\n";
  print "<OPTION>Raymond Lee</OPTION>\n";
  print "<OPTION>Cecilia Nakamura</OPTION>\n";
  print "<OPTION>Andrei Petcherski</OPTION>\n";
  print "<OPTION>Erich Schwarz</OPTION>\n";
  print "<OPTION>Paul Sternberg</OPTION>\n";
  print "<OPTION>Kimberly Van Auken</OPTION>\n";
  print "<OPTION>Daniel Wang</OPTION>\n";
  print "<OPTION>Juancarlos Testing</OPTION>\n";
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Curator !\"></TD><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub ChooseCurator 

sub ChooseType {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/reference_entryform.cgi\">";
  print "<INPUT TYPE=\"hidden\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
  print "<TABLE>\n";
  print "<TD>Select your Type among : </TD><TD><SELECT NAME=\"type_name\" SIZE=5> \n";
  print "<OPTION></OPTION>\n";
  print "<OPTION>CGC</OPTION>\n";
  print "<OPTION>Pubmed</OPTION>\n";
  print "<OPTION>Medline</OPTION>\n";
  print "<OPTION>Other</OPTION>\n";
  print "</SELECT></TD><TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Type !\"></TD><BR><BR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub ChooseType 

sub GetReferenceInfo {
  print "<FORM METHOD=\"POST\" ACTION=\"http://tazendra.caltech.edu/~postgres/cgi-bin/reference_entryform.cgi\">";
  print "<INPUT TYPE=\"hidden\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
				# pass curator value in hidden field
  print "<INPUT TYPE=\"hidden\" NAME=\"type_name\" VALUE=\"$type\">\n";
				# pass type value in hidden field
  print "<TABLE>\n";
  print "<TR><TD>Number / ID : </TD><TD><INPUT NAME=\"type_number_name\" SIZE=\"15\"></TD></TR>\n";
  print "<TR><TD>Authors : </TD><TD><INPUT NAME=\"author_name\" SIZE=\"45\"></TD><TD>Separate authors with // e.g. Drickamer, K//Dodd, RB</TD></TR>\n";
  print "<TR><TD>Title : </TD><TD><INPUT NAME=\"title_name\" SIZE=\"45\"></TD></TR>\n";

  print "<TR><TD>Journal : </TD><TD><INPUT NAME=\"journal_name\" SIZE=\"45\"></TD><TD>Type in Journal name here, OR click one from the list below</TR>\n";
  print "<TR><TD>Journal List : </TD><TD colspan=2><SELECT NAME=\"journal_name\" SIZE=6>\n";
  my $result = $conn->exec( "SELECT DISTINCT ref_journal FROM ref_journal WHERE ref_journal !\~ \'\\\"\'; " );
  print "<OPTION></OPTION>\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { print "<OPTION>$row[0]</OPTION>\n"; }
  } # while (my @row = $result->fetchrow)
  print "</SELECT></TD></TR>\n";
# SELECT * FROM pmid WHERE joinkey=\'$joinkey\'

  print "<TR><TD>Volume : </TD><TD><INPUT NAME=\"volume_name\" SIZE=\"15\"></TD></TR>\n";
  print "<TR><TD>Pages : </TD><TD><INPUT NAME=\"pages_name\" SIZE=\"15\"></TD></TR>\n";
  print "<TR><TD>Year : </TD><TD><INPUT NAME=\"year_name\" SIZE=\"15\"></TD></TR>\n";
  print "<TR><TD>Abstract : </TD><TD colspan=2><TEXTAREA NAME=\"abstract_name\" ROWS=\"10\" COLS=\"80\"></TEXTAREA></TD></TR>\n";
  print "<TR><TD>Hardcopy : </TD><TD><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"hardcopy_name\"></TD></TR>\n";
  print "<TR><TD>PDF : </TD><TD><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"pdf_name\"></TD></TR>\n";
  print "<TR><TD>HTML : </TD><TD><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"html_name\"></TD></TR>\n";
  print "<TR><TD>tif : </TD><TD><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"tif_name\"></TD></TR>\n";
  print "<TR><TD>lib (PDF) : </TD><TD><INPUT TYPE=\"checkbox\" VALUE=\"1\" NAME=\"lib_pdf_name\"></TD></TR>\n";

  print "</TABLE>\n";
  print "Are these choices okay ? : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Populate !\"><BR><BR>\n";
  print "<INPUT TYPE=\"hidden\" NAME=\"curator_name\" VALUE=\"$curator\">\n";
  print "</FORM>\n";
} # sub GetReferenceInfo 

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
<LINK rel="stylesheet" type="text/css" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<HEAD>
<TITLE>PGSQL display Minerva</TITLE>
</HEAD>
<BODY bgcolor=#000000 text=#aaaaaa link=#cccccc>
<CENTER>Documentation is <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/reference_entryform_doc.txt" TARGET="new">here</A>.</CENTER>
EndOfText

} # sub OpenHTML 


sub CloseHTML {
  print <<"EndOfText";
<BR>
</BODY>
EndOfText
} # sub CloseHTML 
