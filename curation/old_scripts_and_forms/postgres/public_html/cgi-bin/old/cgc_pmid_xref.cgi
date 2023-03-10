#!/usr/bin/perl -w
#
# Table of CGCs and corresponding PMIDs and MEDs.
#
# Just look at the postgreSQL database for table correlation data  2002 03 30
#
# Created ref_xrefmed table for cgc-medline connections for Eimear.  
# View after cgc-pmid connection.  2003 10 02
#
# Created ref_xref_cgc and rex_xref_wb_oldwb for Eimear.  Kinda pointless
# with the wpa_ tables coming soon.  2005 05 26

use strict;
use CGI;
use Fcntl;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $query = new CGI;

our %pmHash;
our %cgcHash;
our %checkedoutHash;
our %medHash;		# hash of cgc-medline xref
our %cgcHash;		# hash of cgc-medline xref
our %wbHash;		# hash of cgc-medline xref

  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&PrintHeader();			# print the HTML header
&populateHashes();
&display();
&PrintFooter();			# print the HTML footer

sub display {
  print "<TABLE border=1 cellspacing=5>\n";
  print "<TR><TD ALIGN=CENTER>cgc</TD><TD ALIGN=CENTER>pmid</TD></TR>\n";
  foreach $_ (sort keys %cgcHash) { 
    print "<TR><TD ALIGN=CENTER>$_</TD><TD ALIGN=CENTER>$cgcHash{$_}</TD></TR>\n";
  } # foreach $_ (sort keys %cgcHash)
  foreach $_ (sort keys %medHash) { 
    print "<TR><TD ALIGN=CENTER>$_</TD><TD ALIGN=CENTER>$medHash{$_}</TD></TR>\n";
  } # foreach $_ (sort keys %medHash)
  foreach $_ (sort keys %cgcHash) { 
    print "<TR><TD ALIGN=CENTER>$_</TD><TD ALIGN=CENTER>$cgcHash{$_}</TD></TR>\n";
  } # foreach $_ (sort keys %cgcHash)
  foreach $_ (sort keys %wbHash) { 
    print "<TR><TD ALIGN=CENTER>$_</TD><TD ALIGN=CENTER>$wbHash{$_}</TD></TR>\n";
  } # foreach $_ (sort keys %wbHash)
  print "</TABLE>\n";
} # sub display

sub populateHashes {
  my $result = $conn->exec( "SELECT * FROM ref_xref;" ); 
  my @row;
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $cgcHash{$row[0]} = $row[1];
    $pmHash{$row[1]} = $row[0];
  } # while (my @row = $result->fetchrow) 
  $result = $conn->exec ( "SELECT * FROM ref_checked_out;" );
  while (@row = $result->fetchrow) {
    $checkedoutHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
  $result = $conn->exec ( "SELECT * FROM ref_xrefmed;" );
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $medHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
  $result = $conn->exec ( "SELECT * FROM ref_xref_cgc;" );
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $cgcHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
  $result = $conn->exec ( "SELECT * FROM ref_ref_xref_wb_oldwb;" );
  while (@row = $result->fetchrow) {	# loop through all rows returned
    $wbHash{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
} # sub populateHashes


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
<!--<CENTER>Documentation <A HREF="http://tazendra.caltech.edu/~postgres/cgi-bin/checkout_doc.txt" TARGET=NEW>here</A></CENTER><P>-->
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

