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


use Jex;
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


# &mail_body('azurebrd@minerva.caltech.edu');

sub mimeAttacher {
  my $email = shift;
  my $user = 'pws@caltech.edu';
  my $subject = 'WormBase Newsletter Jan 2006';
  my $attachment = 'WormBase_Newsletter_Jan2006.pdf';
#   my $attachment = 'WormBase_Newsletter_June2005.pdf';
#   my $attachment = 'WormBase_Newsletter_April2005.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb2005.pdf';
#   my $attachment = 'WormBase_Newsletter_May2004.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "The latest issue of the WormBase Newsletter is released, please find 
it attached to this email.  This issue features a response to the 
results of the survey held in November & December 2005.

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
  my $user = 'pws@caltech.edu';
  my $subject = 'WormBase Newsletter & Survey';
  my $body = "We attach the February 2003 WormBase Newsletter. To help us improve 
WormBase, we would appreciate your taking time to complete a short 
on-line survey about WormBase at 
http://www.wormbase.org/about/survey_2003.html.
Thank you!

--The WormBase Consortium";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data
} # sub mail_body

