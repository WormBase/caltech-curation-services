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
# Edited for Alessandro Puoti.  Sent text only, ignored attachment.
# 2004 03 11


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
# foreach $_ (sort keys %emails) { &mail_body("$_"); }	# THIS ONE
# foreach $_ (sort keys %emails) { &mimeAttacher("$_"); }

# Uncomment to print list of email addresses
# foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }

# Sample mailing to myself or Paul
# &mimeAttacher('azurebrd@minerva.caltech.edu');
# &mail_body('azurebrd@minerva.caltech.edu');
# &mail_body('alessandro.puoti@unifr.ch');
# &mimeAttacher('alessandro.puoti@unifr.ch');
# &mimeAttacher('azurebrd@minerva.caltech.edu');
# &mimeAttacher('pws@caltech.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@its.caltech.edu');
# &mimeAttacher('kishoreranjana@hotmail.com');

# Mail to wormbase-announce
# &mimeAttacher('wormbase-announce@wormbase.org');


# &mail_body('azurebrd@minerva.caltech.edu');

sub mail_body {
  my $email = shift;
  my $user = 'alessandro.puoti@unifr.ch';
  my $subject = 'European Worm Meeting 2004';
  my $body = "Dear colleagues,

We would like to inform you that the website for the European
C. elegans meeting 2004 in Interlaken, 22-25 May 2004 is now
open for registration.

The URL is :
http://www.kas.unibe.ch/ewm2004/wfrmWelcome.aspx

We hope to see you soon in Interlaken!

Best wishes.

Alex Puoti and Fritz Mueller";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data

  print "SENT TO $email\n";
} # sub mail_body


sub mimeAttacher {
  my $email = shift;
  my $user = 'alessandro.puoti@unifr.ch';
  my $subject = 'European Worm Meeting 2004';
  my $attachment = 'EWM2004_.doc';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "";

  my $msg = MIME::Lite->new(
               From     =>"\"Alessandro Puoti\" <$user>",
               To       =>"$email",
               Subject  =>"$subject",
               Type     =>'multipart/mixed',
               );
  $msg->attach(Type     =>'TEXT', 
               Data     =>"$body"
               );
  $msg->attach(Type     =>'Application/DOC', 
               Path     =>"$attachment",
               Filename =>"$attachment",
               Disposition => 'attachment'
               );
  $msg->send;

  print "SENT TO $email\n";
} # sub mimeAttacher

