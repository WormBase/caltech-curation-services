#!/usr/bin/perl -w
#
# Email me.

use strict;
use CGI;
use Fcntl;
# use Pg;
use Mail::Mailer;

my $query = new CGI;
my $firstflag = 1;		# set flag for first time to do stuff

my $color_key = "COLOR KEY : <FONT COLOR=blue> blue are warnings</FONT>, <FONT COLOR=red>red doesn't change</FONT>, <FONT COLOR=green>green changes</FONT>, black is normal text.<BR><BR>\n"; 						# text for color_key

  # connect to the testdb database
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

&PrintHeader();			# print the HTML header
&Process();			# Do pretty much everything
&display(); 			# Select whether to show selectors for curator name
				# entries / page, and &ShowPgQuery();
&PrintFooter();			# print the HTML footer

sub Process {			# Essentially do everything
  my $action;			# what user clicked
  unless ($action = $query->param('action')) {
    $action = 'none'; 
  }

  if ($action eq 'Mail !') {
    $firstflag = 0;
    my $user = "Bob\@beano.com"; my $email = "azurebrd\@ugcs.caltech.edu";
    my $subject = "test"; my $body = "no body"; my $oop;
    if ( $query->param("mailuser") ) { $oop = $query->param("mailuser"); }
      else { $oop = "nodatahere"; }
    $user = &Untaint($oop); 
    if ( $query->param("mailsubject") ) { $oop = $query->param("mailsubject"); }
      else { $oop = "nodatahere"; }
    $subject = &Untaint($oop); 
    if ( $query->param("mailbody") ) { $oop = $query->param("mailbody"); }
      else { $oop = "nodatahere"; }
    $body = &Untaint($oop); 
    &Mailer($user, $email, $subject, $body);
  } # if ($action eq 'Mail !')
}

sub display {
  if ($firstflag) { 		# first time through, process didn't do anything
    &showTables();
  } # if ($firstflag) 		# first time through
} # sub display

sub showTables {
  print <<"EndOfText";
  <FORM METHOD="POST" ACTION="http://tazendra.caltech.edu/~azurebrd/cgi-bin/mailer.cgi">
  <TABLE>
  <TR><TD>Your Email</TD><TD><INPUT NAME="mailuser" SIZE=30></TD></TR>
  <TR><TD>Subject</TD><TD><INPUT NAME="mailsubject" SIZE=30></TD></TR>
  <TR><TD>Body</TD><TD><TEXTAREA NAME="mailbody" ROWS=5 COLS=80></TEXTAREA></TD></TR>
  <TR><TD><INPUT TYPE="submit" NAME="action" VALUE="Mail !"></TD></TR>
  </TABLE>
  </FORM>
EndOfText
} # sub showTables

sub Mailer {            # send non-attachment mail
  my ($user, $email, $subject, $body) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => $user,
                  To      => $email,
#                 Cc      => 'curationmail@minerva.caltech.edu, $user',
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
EndOfText
} # sub PrintHeader 

sub PrintFooter {
  print "</BODY>\n</HTML>\n";
} # sub PrintFooter 

