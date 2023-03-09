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
#
# Again for Pamela Padilla  2008 05 30


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
  my $subject = 'C. elegans Aging Topic Meeting- Abstracts Due June 2';
  my $contenttype = 'multipart/alternative; boundary="=__Part557C0639.0__="';
  my $body = '--=__Part557C0639.0__=
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: quoted-printable

Dear Worm Lab PIs and Lab Members, 

This is a reminder to let you know that Abstracts for the 2008 C. elegans Aging,
Stress, Pathogenesis and Heterochrony Meeting are due Monday June 2, 2008. The
meeting runs from August 3-6, 2008 at the University of Wisconsin-Madison
campus. The meeting website is: http://www.union.wisc.edu/ceaging/ 

We hope to see you in Madison!
Todd Lamitina and Pamela Padilla

lamitina@mail.med.upenn.edu

ppadilla@unt.edu



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
<font size="3" face="Arial">Dear Worm Lab PIs and Lab Members,</font> <br>
</p>

<p><font size="3" face="Arial">This is a reminder to let you know that 
Abstracts for the 2008 C. elegans Aging, Stress, Pathogenesis and Heterochrony 
Meeting are due Monday June 2, 2008. The meeting runs from August 3-6, 
2008 at the University of Wisconsin-Madison campus. The meeting website 
is: <a href="http://www.union.wisc.edu/ceaging/"
target="_blank">http://www.union.wisc.edu<WBR>/ceaging/</a></font> <br></p>
<p><font size="3" face="Arial">We hope to see you in Madison!</font></p>
<h1><font size="3" face="Arial">Todd Lamitina and Pamela Padilla</font></h1>
<p><a href="mailto:lamitina@mail.med.upenn.edu" target="_blank"><font
color="#0000FF" size="3"
face="Arial"><u>lamitina@mail.med.upenn.edu</u></font></a></p>
<p><a href="mailto:ppadilla@unt.edu" target="_blank"><font color="#0000FF"
size="3" face="Arial"><u>ppadilla@unt.edu</u></font></a></p>

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




