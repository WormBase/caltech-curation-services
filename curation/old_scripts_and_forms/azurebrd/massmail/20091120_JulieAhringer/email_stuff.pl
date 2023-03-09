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
# Changed for Julie Ahringer.  
# Ran from 03:22 to 13:52 for 6781 emails sent.  2009 11 20
#
# TODO : switch to DBI
# TODO : add unsubscribe link to new CGI (write it) that adds entry to two_unsubscribe (create pg table)
#        and check / skip entries that have two_unsubscribe data before mailing them  2009 05 06
#
# Changed for Jane Mendel to send Worm Breeder's Gazette  .doc files.  
# Still haven't done  todo  stuff above.  2009 10 19 


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
# &mimeAttacher('azurebrd@its.caltech.edu');
# &mimeAttacher('pws@caltech.edu');

# Sample mailing to jane
# &mimeAttacher('mendelj@caltech.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@its.caltech.edu');
# &mimeAttacher('kishoreranjana@hotmail.com');

# Mail to wormbase-announce
# &mimeAttacher('wormbase-announce@wormbase.org');


# &mail_body('azurebrd@minerva.caltech.edu');

# foreach $_ (sort keys %emails) { 
#   print "$_\n";
#   &mail_body("$_");
# }
# &mail_body('ja219@cam.ac.uk');	# sample to Julie Ahringer

sub mimeAttacher {
  my $email = shift;
  my $user = 'mendelj@caltech.edu';
  my $subject = "Worm Breeder's Gazette Invitation";
  my $attachment = 'WBG_Author_Instructions.doc';
#   my $attachment2 = 'WBG_invitation_letter_Oct19.doc';
#   my $attachment = 'WormBase_Newsletter_April_2009.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct_2008.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb_2007.pdf';
#   my $attachment = 'WormBase_Newsletter_June_2006.pdf';
#   my $attachment = 'WormBase_Newsletter_Jan2006.pdf';
#   my $attachment = 'WormBase_Newsletter_June2005.pdf';
#   my $attachment = 'WormBase_Newsletter_April2005.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb2005.pdf';
#   my $attachment = 'WormBase_Newsletter_May2004.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "                                                                                    October 19, 2009

Dear Worm Workers,
 
            As we announced at the International Worm Meeting in June, WormBook has decided to revive the Worm Breeders’ Gazette (WBG) in electronic form.  The original WBG let researchers announce experimental results that were not yet published, correct errors in published work, and describe methods and techniques that might be useful to the whole community.  Informal conversations with many of you indicate that these features of the WBG are missed.  In particular people most regret not learning about new techniques and improvements in older methods in a timely fashion. 
 
            We at WormBook are willing to try to get the WBG going again, and we encourage you to consider submitting a short note for inclusion in the first issue of the new WBG, especially if you have a new method you would like to share.  As with the previous WBG, submissions should be kept to a single page in length including figures, tables and videos.  Detailed author instructions are attached and can also be found at http://www.wormbook.org/wbg_instructions.html.  As with the previous version of the WBG (and abstracts for the Worm Meetings), contributions for the WBG will be linked to WormBase and will be considered personal communications and cannot be cited without the permission of the authors.
 
            We would like to publish on a twice/year schedule (June and December for each year).  To be able to assemble each issue, we would like to receive your contributions one month before the publication date.  For our first issue, to be published December 10, 2009, please email your submission to Jane Mendel (mendelj\@caltech.edu) by this November 15.  We look forward to receiving your contribution.
 

                                                                                    All the best,
 

                                                                                    Marty Chalfie
                                                                                    Editor-in-Chief, Wormbook


                                                                                    Jane Mendel
                                                                                    Editor, WormBook";

  my $msg = MIME::Lite->new(
               From     =>"\"Marty Chalfie and Jane Mendel\" <$user>",
               To       =>"$email",
               Subject  =>"$subject",
               Type     =>'multipart/mixed',
               );
  $msg->attach(Type     =>'TEXT', 
               Data     =>"$body"
               );
  $msg->attach(Type     =>'Application/MSWORD', 
               Path     =>"$attachment",
               Filename =>"$attachment",
               Disposition => 'attachment'
               );
#   $msg->attach(Type     =>'Application/MSWORD', 
#                Path     =>"$attachment2",
#                Filename =>"$attachment2",
#                Disposition => 'attachment'
#                );
  $msg->send;

  print "SENT TO $email\n";
} # sub mimeAttacher

sub mail_body {
  my $email = shift;
  my $user = 'Julie Ahringer <ja219@cam.ac.uk>';
  my $subject = '2010 Topic Meeting on C. elegans Development and Gene expression';
  my $body = "Dear Worm Breeders,

We are pleased to announce that the 2010 Topic meeting on C. elegans Development and Gene Expression will be held June 17-20 at the new EMBL ATC conference center (Heidelberg, Germany).

http://www.embl.de/training/courses_conferences/conference/2010/ECE10-01/index.html

Talks will be selected from abstracts, plus there will be a great set of Keynote speakers:

Abby Dernburg  UC Berkeley, USA
Michael Hengartner  Zurich University, Switzerland
Tony Hyman  MPI-CBG Dresden, Germany
Michael Krause  NIH Bethesda, USA
Benjamin Podbilewicz  Technion University, Israel
Jim Priess  FHCRC, USA
Susan Strome  UCSC, USA
Asako Sugimoto  CDB-Riken, Japan

Heidelberg is located within 30 minutes by bus or train from
Frankfurt airport, the largest international airport in Europe.  We
will be able to offer some registration fee waivers and travel
assistance to help defray costs for those with financial difficulty.

We are looking forward to seeing you there!

Julie Ahringer, University of Cambridge (ja219\@cam.ac.uk)
Michel Labouesse, IGBMC (lmichel\@igbmc.fr)
Iain Mattaj, EMBL (mattaj\@embl.de)";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data
} # sub mail_body

