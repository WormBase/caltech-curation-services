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
# Changed to send only to PIs with &mail_body();  2006 03 24 
#
# Changed to send to PIs Diana Chu message.  2008 02 06
#
# Changed to use joinkey in %emails and %stdname instead of just the email addresses.  2009 01 20
#
# Changed for Ann Rougvie.  2009 02 08

use strict;
use warnings;
use Jex;
use diagnostics;
use Pg;
use MIME::Lite;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my %emails;
my %stdname;
my $result = $conn->exec( "SELECT joinkey, two_email FROM two_email WHERE two_email !~ '. .' AND joinkey IN (SELECT joinkey FROM two_pis) ;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[0] =~ s/two//g;
    $emails{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT joinkey, two_standardname FROM two_standardname ;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[0] =~ s/two//g;
    $stdname{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mail_body("$_"); }

# &mail_body("625");	# 2009 01 20  uses joinkey to get standardname

# &mail_body('azurebrd@tazendra.caltech.edu');
# &mail_body('pws@its.caltech.edu');
# &mail_body('Marian.Walhout@umassmed.edu');
# foreach $_ (sort keys %emails) { print "$_\n"; }

# Uncomment to print list of email addresses
# foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }

# Sample mailing to myself or Paul or Ann Rougvie
# &mimeAttacher('azurebrd@minerva.caltech.edu');
# &mimeAttacher('pws@caltech.edu');
# &mimeAttacher('rougvie@umn.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@its.caltech.edu');
# &mimeAttacher('kishoreranjana@hotmail.com');

# Mail to wormbase-announce
# &mimeAttacher('wormbase-announce@wormbase.org');


# &mail_body('azurebrd@minerva.caltech.edu');

sub mimeAttacher {
  my $email = shift;
  my $user = 'Ann Rougvie <rougvie@umn.edu>';
  my $subject = 'Curator, CGC';
  my $attachment = 'curator.pdf';
#   my $attachment = 'WormBase_Newsletter_Jan2006.pdf';
#   my $attachment = 'WormBase_Newsletter_June2005.pdf';
#   my $attachment = 'WormBase_Newsletter_April2005.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb2005.pdf';
#   my $attachment = 'WormBase_Newsletter_May2004.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "Dear Colleagues, 

Theresa Stiernagle has recently informed me that, after 16 years of tremendous service to the C. elegans community, she has decided to retire as head curator of the Caenorhabditis Genetics Center (CGC) effective June 1, 2009.  Thankfully, she has agreed to stay on beyond that date as needed in a training capacity.  I am asking for your help in identifying candidates to take her place and carry on her tradition of excellence.  I would like to identify an individual with significant C. elegans experience and exceptional organization skills and who has the ability to work independently and supervise others.  Computer skills, including the ability to manage databases, are also required.  Theresa has set the bar high and finding a replacement who shares her talents and commitment to the worm community will be a challenge.  With your help, I am hopeful we can make a smooth transition. 

Please encourage qualified candidates to send a letter of intent, a current curriculum vitae, and 3 letters of recommendation to the address listed below.  Materials will be reviewed beginning March 2, 2009.  Position title will be determined based on the applicant pool.  Selected applicants will then be invited to apply to a posted position beginning the formal application/hiring process.  
 

Thank you for your help. 

Sincerely,
Ann Rougvie
Director, Caenorhabditis Genetics Center
Professor, Genetics, Cell Biology and Development
University of Minnesota
rougvie\@umn.edu

For application materials sent via regular mail:

Ann Rougvie, Director, CGC
Re: Curator, CGC
University of Minnesota
6-160 Jackson Hall
321 Church St SE
Minneapolis, MN 55455
For application materials sent electronically:

Mary Muwahid
muwah001\@umn.edu
On subject line, please type: Curator, CGC";

  my $msg = MIME::Lite->new(
               From     =>"$user",
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
  my $key = shift;
  my $user = 'cecilia@tazendra.caltech.edu';
  my $email = $emails{$key};
  $email = $user;
  my $subject = 'Wormbase: Updating your personal and lab webpage';
#   my $body = "stuff";
  my $body = "Dear $stdname{$key}:

We at WormBase would like your help to update your personal and lab
webpages in Person and Lab classes.

http://wormbase.org/db/misc/person?name=WBPerson$key;class=Person

Please email back your current data. If your lab webpage does not
include lab members please email me a list of current members.

We'd really appreciate it.

Thanks,

Cecilia";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);
  print "SENT TO $email\n";
} # sub mail_body

