#!/usr/bin/perl

# Get list of two_emails from postgres and email attachment PDF with Paul's
# text.  2003 02 25
#
# Edited to check that two_email doesn't have a space in the middle because
# it got an error :
# qmail-inject: fatal: unable to parse this line:
# To: e-mail: assafrn@tx.technion.ac.il
# requiring creating email_missing.pl to email to the emails after that error
# (see file ``emails'')  2003 10 28
#
# Changed subject to February 2004  and made body one line.  2004 02 17
#
# Changed subject to May 2004  and made body one line.  2004 05 04
#
# Changed subject to Aug 2004.  2004 08 09
#
# Changed subject to Feb 2005.  2005 02 22
#
# Changed subject to Apr 2005.  2005 04 21
#
# Changed subject to Jun 2005.  2005 06 21
#
# Changed message for Jan 2006.  2006 01 12
#
# Changed message for June 2006.  2006 06 03
#
# Changed message for Nov 2006.  2006 11 17
#
# Changed message for Feb 2007.  2006 02 26
#
# Adapted for Pamela Padilla  2008 04 28


# use Jex;	# need to set Content-Type here  2008 04 28
use Mail::Mailer;
use diagnostics;
use Pg;
use MIME::Lite;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my %emails;
my $result = $conn->exec( "SELECT two_email FROM two_email WHERE two_email !~ '. .';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $emails{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mimeAttacher("$_"); }

# Uncomment to print list of email addresses
# foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }

# Sample mailing to myself or Paul
# &mimeAttacher('azurebrd@minerva.caltech.edu');
# &mimeAttacher('pws@caltech.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@its.caltech.edu');
# &mimeAttacher('kishoreranjana@hotmail.com');

# Mail to wormbase-announce
# &mimeAttacher('wormbase-announce@wormbase.org');


# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mail_body("$_"); }

# &mail_body('azurebrd@minerva.caltech.edu');
# &mail_body('azurebrd@its.caltech.edu');
# &mail_body('ppadilla@unt.edu');

sub mimeAttacher {
  my $email = shift;
  my $user = 'pws@caltech.edu';
  my $subject = 'WormBase Newsletter July 2007';
  my $attachment = 'WormBase_Newsletter_July_2007.pdf';
  my $body = "The latest issue of the WormBase Newsletter is released, please find 
it attached to this email.  

Please remember to complete the current WormBase survey at
http://www.wormbase.org/db/surveys/2007_wormbase

Thank you!

--The WormBase Consortium

";

  my $msg = MIME::Lite->new(
               From     =>"\"Paul Sternberg\" <$user>",
               To       =>"$email",
               Subject  =>"$subject",
               Type     =>'multipart/mixed',
               );
  $msg->attach(Type     =>'TEXT', 
               Data     =>"$body"
               );
  $msg->attach(Type     =>'Application/PDF', 
               Path     =>"$attachment",
               Filename =>"$attachment",
               Disposition => 'attachment'
               );
  $msg->send;

  print "SENT TO $email\n";
} # sub mimeAttacher

sub mail_body {
  my $email = shift;
  my $user = '"Pamela Padilla" <ppadilla@unt.edu>';
  my $subject = '2008 C. elegans Aging, Stress, Pathogenesis and Heterochronic Topic Meeting';
  my $contenttype = 'multipart/alternative; boundary="=__Part557C0639.0__="';
  my $body = '--=__Part557C0639.0__=
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: quoted-printable

Dear Worm Lab PIs and Lab Members,
We invite you to attend the 2008 C. elegans Aging, Stress, Pathogenesis
and Heterochrony Topic Meeting.
The meeting will be held at the University of Wisconsin-Madison campus on
August 3-6, 2008.

The meeting website URL is:  http://www.union.wisc.edu/ceaging/

We are delighted to announce the following confirmed featured speakers:
Donald Riddle, Keith Blackwell, Jonathan Hodgkin, Cynthia Kenyon, Rick
Morimoto and Ann Rougvie.

Topics include:
Aging
Age-Related Disease
Environmental Stress
Pathogenesis
Heterochronic Genes
Dauer Development
Teaching and Education

Abstracts will be due June 2, 2008.   Platform and poster notification
assignments will be posted at the Meeting website on or around Monday,
July 7, 2008.  There are limited openings for talks and posters so please
register early!

The Meeting Organizers are:
Todd Lamitina: University of Pennsylvania (lamitina@mail.med.upenn .edu)
Pamela Padilla: University of North Texas (ppadilla@unt.edu)
Ahna Skop: University of Wisconsin-Madison (skop@ wisc.edu) (Local
Organizer)
Please contact one of the organizers if you have any questions.

Organizing committee include:
Dennis Kim, Massachusetts Institute of Technology
Todd Lamitina, University of Pennsylvania
Gordon Lithgow, Buck Institute
Jim Lund, University of Kentucky
Eric Moss, The University of Medicine and Dentistry of New Jersey
Colleen Murphy, Princeton University
Pamela Padilla, University of North Texas
Jo Anne Powell-Coffman, Iowa State University
Marc van Gilst, Fred Hutchinson Cancer Research Center

We look forward to seeing you on the Terrace!
 
Pamela Padilla and Todd Lamitina



--=__Part557C0639.0__=
Content-Type: text/html; charset=US-ASCII
Content-Transfer-Encoding: quoted-printable

<html>
  <head>
    <style type=3D"text/css">
      <!--
        body { margin-right: 4px; line-height: normal; font-variant:
normal; margin-left: 4px; margin-top: 4px; margin-bottom: 1px }
      -->
    </style>
   
  </head>
  <body style=3D"margin-right: 4px; margin-left: 4px; margin-top: 4px;
margin-bottom: 1px">
    <DIV>      <font face=3D"Monospaced">Hi&#44;
    </DIV>
    <div>
      <DIV>        <font face=3D"New York" size=3D"3">Dear&#160;Worm&#160;Lab&#160;PIs&#160;and&#160;Lab&#160;Members&#44; </font><font size=3D"3">
      </DIV>
</font>    </div>
    <blockquote class=3D"cite" type=3D"cite" cite=3D"">
      <blockquote class=3D"cite" type=3D"cite" cite=3D"">
        <blockquote class=3D"cite" type=3D"cite" cite=3D"">
          <blockquote class=3D"cite" type=3D"cite" cite=3D"">
            <blockquote class=3D"cite" type=3D"cite" cite=3D"">
              <div>
                <div>
                  <DIV>                    <font size=3D"3">
                  </DIV>
</font>                </div>
                <div>
                  <DIV>                    <font size=3D"3" face=3D"New York">We invite you to attend the <b>2008 <i>C. elegans Aging&#44; 
Stress&#44; Pathogenesis</i>&#160;and Heterochrony Topic Meeting</b>.&#160;
<br>The meeting will be held at the University of Wisconsin-Madison campus 
on<b>&#160;August 3-6&#44; 2008.</b><br><br>The meeting website URL 
is:&#160;&#160;</font><u><font color=3D"#0000ff" size=3D"3" face=3D"New 
York"><i><a href=3D"http://www.union.wisc.edu/ceaging/">http://www.union.wisc.edu/ceaging/</a></i></font></u><font size=3D"3" face=3D"New York"><br><b
r>We are delighted to announce the following confirmed featured speakers:<br><b><i>Donald Riddle&#44; Keith Blackwell&#44; Jonathan Hodgkin&#44; 
Cynthia Kenyon&#44; Rick Morimoto and Ann Rougvie.<br><br></i><u>Topics 
include:</u></b><u><br></u>Aging<br>Age-Related Disease<br>Environmental 
Stress<br>Pathogenesis<br>Heterochronic Genes<br>Dauer Development<br>Teaching and Education<br><br></font><font color=3D"#ff0000" size=3D"3" 
face=3D"New York">Abstracts will be due June 2&#44; 2008.</font><font 
size=3D"3" face=3D"New York">&nbsp;&#160;&#160;Platform and poster 
notification assignments will be posted at the Meeting website on or 
around Monday&#44; July 7&#44; 2008.&#160;&#160;There are limited openings 
for talks and posters so please register early&#33;<br><br>The Meeting 
Organizers are:<br>Todd Lamitina: University of Pennsylvania &#40;<a 
href=3D"mailto:lamitina@mail.med.upenn.edu">lamitina@mail.med.upenn.edu</a>&#41;<br>Pamela Padilla: University of North Texas &#40;<a href=3D"mailto:ppadilla@unt.edu">ppadilla@unt.edu</a>&#41;<br>Ahna Skop: 
University of Wisconsin-Madison &#40;<a href=3D"mailto:skop@wisc.edu">skop@wisc.edu</a>&#41; &#40;Local Organizer&#41;<br>Please contact one of the 
organizers if you have any questions.<br>&#160;<br>Organizing committee 
include:<br>Dennis Kim&#44; Massachusetts Institute of Technology<br>Todd 
Lamitina&#44; University of Pennsylvania<br>Gordon Lithgow&#44; Buck 
Institute<br>Jim Lund&#44; University of Kentucky<br>Eric Moss&#44; The 
University of Medicine and Dentistry of New Jersey<br>Colleen Murphy&#44; 
Princeton University<br>Pamela Padilla&#44; University of North Texas<br>Jo Anne Powell-Coffman&#44; Iowa State University<br>Marc van Gilst&#44; 
Fred Hutchinson Cancer Research Center<br><br>We look forward to seeing 
you on the Terrace&#33;
                  </DIV>
</font>                </div>
                <div>
                  <DIV>                    <font size=3D"3" face=3D"New York">&#160;
                  </DIV>
</font>                </div>
                <div>
                  <DIV>                    <font size=3D"3" face=3D"New York">Pamela Padilla and Todd Lamitina</font><font size=3D"3">
                  </DIV>
</font>                </div>
              </div>
            </blockquote>
          </blockquote>
        </blockquote>
      </blockquote>
    </blockquote>
    <DIV>      <font size=3D"3"><br>
</font>    </DIV>
  </body>
</html>

--=__Part557C0639.0__=--';


#   my $body = "We attach the February 2003 WormBase Newsletter. To help us improve 
# WormBase, we would appreciate your taking time to complete a short 
# on-line survey about WormBase at 
# http://www.wormbase.org/about/survey_2003.html.
# Thank you!
# 
# --The WormBase Consortium";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body, $contenttype);	# email cecilia data
  print "SENT TO $email\n";
} # sub mail_body


sub mailer {                    # send non-attachment mail
  my ($user, $email, $subject, $body, $contenttype) = @_;
  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
  $mailer->open({ From    => "$user",
                  To      => "$email",
                  "Content-Type" => $contenttype,
                  Subject => $subject,
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
} # sub mailer




