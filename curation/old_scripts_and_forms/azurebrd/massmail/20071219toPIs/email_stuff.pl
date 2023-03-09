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


use Jex;
use diagnostics;
use Pg;
use MIME::Lite;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my %emails;
my $result = $conn->exec( "SELECT two_email FROM two_email WHERE two_email !~ '. .' AND joinkey IN (SELECT joinkey FROM two_pis) ;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $emails{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mail_body("$_"); }

# &mail_body('pws@its.caltech.edu');
# &mail_body('Marian.Walhout@umassmed.edu');
# foreach $_ (sort keys %emails) { print "$_\n"; }

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
  my $user = 'Marian.Walhout@umassmed.edu';
  my $subject = 'Worm Genomics and Systems Biology Meeting July 24/25 2008';
  my $attachment = 'WormSystemsGenomics2008.doc';
#   my $attachment = 'WormBase_Newsletter_Jan2006.pdf';
#   my $attachment = 'WormBase_Newsletter_June2005.pdf';
#   my $attachment = 'WormBase_Newsletter_April2005.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb2005.pdf';
#   my $attachment = 'WormBase_Newsletter_May2004.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "Worm Genomics and Systems Biology Meeting

July 24/25 2008

Broad Institute

Cambridge, MA 

Dear all: 

We would like to bring your attention to a worm topic meeting that we have
decided to organize for 2008. The meeting will focus on C. elegans genomics and
systems biology and will take place July 24 & 25 at the Broad Institute in
Cambridge, Massachusetts. 

We would like to have an estimate of how many people are interested in this
meeting so we can start preparing the Program. Please let us know by Nov 30 how
many people from your group (hopefully including yourself) are likely to attend. 

Details about registration and cost will follow. 

Thank you very much. We hope to see you in Cambridge in 2008. 

Best regards, 

Marian Walhout   University of Massachusetts Medical School

Hui Ge   Whitehead Institute for Biomedical Research

Stuart Milstein  Center for Cancer Systems Biology (CCSB) Dana-Farber Cancer
Institute (Vidal lab)";

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
  my $user = 'Marian.Walhout@umassmed.edu';
  my $subject = 'Worm Genomics and Systems Biology Meeting July 24/25 2008 Cambridge, MA';
  my $body = "Worm Genomics and Systems Biology Meeting

July 24/25 2008

Broad Institute

Cambridge, MA 

Dear all: 

We would like to bring your attention to a worm topic meeting that we have
decided to organize for 2008. The meeting will focus on C. elegans genomics and
systems biology and will take place July 24 & 25 at the Broad Institute in
Cambridge, Massachusetts. 

We would like to have an estimate of how many people are interested in this
meeting so we can start preparing the Program. Please let us know by Nov 30 how
many people from your group (hopefully including yourself) are likely to attend. 

Details about registration and cost will follow. 

Thank you very much. We hope to see you in Cambridge in 2008. 

Best regards, 

Marian Walhout   University of Massachusetts Medical School

Hui Ge   Whitehead Institute for Biomedical Research

Stuart Milstein  Center for Cancer Systems Biology (CCSB) Dana-Farber Cancer
Institute (Vidal lab)";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data
  print "SENT TO $email\n";
} # sub mail_body

