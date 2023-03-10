#!/usr/bin/perl -w

# Direct queries to PostgreSQL database

use strict;
use CGI;
use Fcntl;
# use HTML::Template;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $query = new CGI;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $HTML_TEMPLATE_ROOT = "/home/postgres/public_html/cgi-bin/";

&PrintHeader();			# print the HTML header
&ShowPgQuery();
&Process();
#    &PrintPgTable();
&PrintFooter();			# print the HTML footer

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
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 


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
# if ( ($row[0] =~ m/^cgc100/) || ($row[0] =~ m/^cgc200/) || ($row[0] =~ m/^cgc12/) ) {
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

sub PrintTableLabels {		# Just a bunch of table down entries
  print "<TR><TD>joinkey</TD><TD>author</TD><TD>title</TD><TD>journal</TD><TD>volume</TD><TD>pages</TD><TD>year</TD><TD>abstract</TD><TD>hardcopy</TD><TD>pdf</TD><TD>html</TD><TD>tif</TD><TD>lib</TD></TR>\n";
} # sub PrintTableLabels 

sub ShowPgQuery {
  print <<"EndOfText";
  <BR>Would you like to make a PostgreSQL Query to the Curation Database ?<BR>
  <FORM METHOD="POST" ACTION="http://minerva.caltech.edu/~postgres/cgi-bin/referencedisplay.cgi">
  <TEXTAREA NAME="pgcommand" ROWS=5 COLS=80></TEXTAREA><BR>
  <INPUT TYPE="submit" NAME="action" VALUE="Pg !">
  </FORM>
EndOfText
}


sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none';
  }
  if ($action eq 'Pg !') {
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
            print "<TD>${_}&nbsp;</TD>\n";		# print the value returned
          }
          print "</TR>\n";
        } # while (@row = $result->fetchrow) 
        &PrintTableLabels();
        print "</TABLE>\n";
      }
    } # else # if ($pgcommand eq "nodatahere") 
  } # if ($action eq 'Pg !') 
} # sub Process


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

