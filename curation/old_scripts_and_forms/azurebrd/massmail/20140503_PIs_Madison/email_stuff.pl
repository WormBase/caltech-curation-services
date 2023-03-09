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
# TODO : switch to DBI
# TODO : add unsubscribe link to new CGI (write it) that adds entry to two_unsubscribe (create pg table)
#        and check / skip entries that have two_unsubscribe data before mailing them  2009 05 06
#
# Changed for Jane Mendel to send Worm Breeder's Gazette  .doc files.  
# Still haven't done  todo  stuff above.  2009 10 19 
#
# Did  todo  stuff above.  Changed for another set for Jane Mendel.  
# Not ready to sent, but uncomment the
# &mail_body($email, $twonum, $emails{$twonum}{passwd});
# and get rid of the delete emails lines when ready.  2009 12 15
#
# Ran 2009 12 16
#
#
# Might need these line ?  2010 02 25
# 'MIME-Version' => '1.0',
# "Content-type" => 'text/html; charset=ISO-8859-1',
#
#
# switched to &mail_simple instead of &mail_body to possibly have better headers.
# switched for Madison meeting for Dennis Kim.  2010 03 02
#
# changed for ahringer.  2010 03 29
#
# changed for Jane reminder.  2011 07 12
#
# changed for Jane WBG.  2011 11 10
#
# changed for PIs for Martha Soto for Development meeting.  2011 12 06
#
# changed for PIs for Madison meeting for Sean Curran.  sent from massmail@mangolassi  2014 05 03




use Jex;
use diagnostics;
# use MIME::Lite;
# use MIME::Lite::TT::HTML;
use Mail::Mailer;
use DBI;

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "azurebrd", "") or die "Cannot connect to database!\n";    # for remote access



my %emails;
# my $result = $dbh->prepare( "SELECT * FROM two_email WHERE two_email !~ '. .' ;" );	# to everyone
my $result = $dbh->prepare( "SELECT * FROM two_email WHERE two_email !~ '. .' AND joinkey IN (SELECT joinkey FROM two_pis WHERE two_pis IS NOT NULL);" );	# to PIs only
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g; $row[0] =~ s/two//g;
    $emails{$row[0]}{email}{$row[2]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM two ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g; $row[0] =~ s/two//g;
    my $pass = $row[2];
    $pass =~ s/\D//g; ($pass) = $pass =~ m/^(\d{8})/;
    $emails{$row[0]}{passwd} = $pass; } }

$result = $dbh->prepare( "SELECT * FROM two_status WHERE two_status = 'Invalid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g; $row[0] =~ s/two//g;
    delete $emails{$row[0]}; } }

$result = $dbh->prepare( "SELECT * FROM two_unsubscribe WHERE two_unsubscribe = 'unsubscribe';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g; $row[0] =~ s/two//g;
    delete $emails{$row[0]}; } }

my %ignore_for_now;		# we have some email addresses to ignore, but not remove from two_email yet (I didn't get this to Cecilia early enough to process from the 100303 run.
my $ignore_for_now_file = '/home/postgres/work/pgpopulation/two_people/bounce_email/20100303/ignore_for_now';
open (IN, "<$ignore_for_now_file") or die "Cannot open $ignore_for_now_file : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($two, $join, $email) = split/\t/, $line;
  $two =~ s/two//g;
  my $lower = lc($email);
  $ignore_for_now{$two}{$lower}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $ignore_for_now_file : $!";



my %send_to;			# who to send emails to
$send_to{'1823'}++;		# juancarlos chan
# $send_to{'2173'}++;		# sean curran madison topic meeting
# $send_to{'263'}++;		# barry something to test text/plain replacing text/txt
# $send_to{'1270'}++;		# jane mendel
# $send_to{'608'}++;		# martha soto
# $send_to{'1'}++;		# cecilia nakamura
# $send_to{'8'}++;		# julie ahringer
# $send_to{'11261'}++;		# samples to test ignore_for_now
# $send_to{'2667'}++;		# samples to test ignore_for_now
# $send_to{'625'}++;		# paul sternberg
# $send_to{'712'}++;		# karen
# $send_to{'1843'}++;		# kimberly
# $send_to{'324'}++;		# ranjana kishore
# $send_to{'2292'}++;		# dhkim@mit.edu

# HERE COMMENT OUT TO SEND TO EVERYONE, otherwise just sends to %send_to  two numbers above
# foreach my $two (keys %emails) {	# this deletes all emails except for %send_to emails above
# #   foreach my $email (sort keys %{ $emails{$two}{email} }) { print "EMAIL $email EM\n"; }	# list all emails going out to
#   unless ( $send_to{$two} ) { delete $emails{$two}; } }


foreach my $twonum (sort { $a<=>$b } keys %emails) { 
  next unless ($emails{$twonum}{passwd});
  foreach my $email (sort keys %{ $emails{$twonum}{email} }) {
    my $lower = lc($email);
    next if ($ignore_for_now{$twonum}{$lower});	# ignore these email addresses that bounced 2010 03 29

    print "$twonum E $email PASSWD $emails{$twonum}{passwd}\n";
# HERE UNCOMMENT TO SEND MIME MESSAGES	2010 04 19
#     &mimeMessage($email, $twonum, $emails{$twonum}{passwd});

# HERE UNCOMMENT TO SEND ATTACHMENTS
#     &mimeAttacher($email, $twonum, $emails{$twonum}{passwd});
# HERE UNCOMMENT TO SEND PLAIN EMAILS
#     &mail_body($email, $twonum, $emails{$twonum}{passwd});
# HERE UNCOMMENT TO SEND PLAIN EMAILS with possibly better headers
#     &mail_simple($email, $twonum, $emails{$twonum}{passwd});	# using this recently 2011 11 10
  } # foreach my $email (sort keys %{ $emails{$twonum}{email} }) 
} # foreach my $twonum (sort $a<=>$b keys %emails)



# my %emails;
# my $result = $conn->exec( "SELECT two_email FROM two_email WHERE two_email !~ '. .';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $emails{$row[0]}++;
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)
# 
# # HERE UNCOMMENT TO SEND TO EVERYONE
# # Uncomment to send to everyone 
# # foreach $_ (sort keys %emails) { &mimeAttacher("$_"); }
# 
# # Uncomment to print list of email addresses
# # foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }
# 
# # Sample mailing to myself or Paul
# # &mimeAttacher('azurebrd@its.caltech.edu');
# # &mimeAttacher('pws@caltech.edu');
# 
# # Sample mailing to jane
# # &mimeAttacher('mendelj@caltech.edu');
# 
# # Sample mailing to ranjana
# # &mimeAttacher('ranjana@its.caltech.edu');
# # &mimeAttacher('kishoreranjana@hotmail.com');
# 
# # Mail to wormbase-announce
# # &mimeAttacher('wormbase-announce@wormbase.org');
# 
# 
# # &mail_body('azurebrd@minerva.caltech.edu');

sub mimeMessage {		# always uses mail.txt and mail.html, but need to append unsubscription to those text files.  put body txt and html into files source.txt and source.html (leaving the closing body and html tags in the unsubscription appending)   2010 04 19
  my ($email, $twonum, $passwd) = @_;
#   $email = 'azurebrd@caltech.edu';			# to test to tazendra and gmail
  my $user = 'mendelj@caltech.edu';
  my $subject = "Worm Breeder's gazette reminder";

  `cp source.txt mail.txt`;
  `cp source.html mail.html`;

  my $htmlfile = 'mail.html'; my $txtfile = 'mail.txt';

  open (OUT, ">>$htmlfile") or die "Cannot append to $htmlfile : $!";
  print OUT "<div><br/><br/>Follow this <a href=\"http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd\">link</a> to unsubscribe from newsletter and meeting announcements.</div></body></html>";
  close (OUT) or die "Cannot close $htmlfile : $!";

  open (OUT, ">>$txtfile") or die "Cannot append to $txtfile : $!";
  print OUT "Follow this link to unsubscribe from newsletter and meeting announcements : http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd";
  close (OUT) or die "Cannot close $txtfile : $!";

  my %options; my %params;

  my $msg = MIME::Lite::TT::HTML->new(
               From     =>"\"Jane Mendel\" <$user>",
               To       =>"$email",
               Subject  =>"$subject",
               Encoding =>'quoted-printable',
               Charset  =>'US-ASCII',
               Template    => {
                   html => 'mail.html',
                   text => 'mail.txt',
               },
               TmplOptions => \%options,
               TmplParams  => \%params,
               );
#   $msg->attach(Type     =>'TEXT', 
#                Data     =>"$body"
# 
#                );
#   $msg->attach(Type     =>'HTML', 
#                Data     =>"$html_body"
#                );

#   $msg->attach(Type     =>'Application/MSWORD', 
#                Path     =>"$attachment",
#                Filename =>"$attachment",
#                Disposition => 'attachment'
#                );
#   $msg->attach(Type     =>'Application/MSWORD', 
#                Path     =>"$attachment2",
#                Filename =>"$attachment2",
#                Disposition => 'attachment'
#                );
  $msg->send;

#   print "SENT TO $email\n";
} # sub mimeMessage


sub mimeAttacher {
  my ($email, $twonum, $passwd) = @_;
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
  $body .= "\n\nFollow this link to unsubscribe from newsletter and meeting announcements : http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd";

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

sub mail_simple {
  my ($email, $twonum, $passwd) = @_;

  my $user = 'Sean P. Curran <spcurran@usc.edu>';
  my $subject = '2014 C. elegans "Topics" Meeting.  Abstract Deadline is Monday';
  my $body = "Please attend the 2014 C. elegans \"Topics\" Meeting, covering Aging,<br/>
Metabolism, Pathogenesis, Stress, and Small RNAs, will be held July 10-13,<br/>
2014 on the campus of the University of Wisconsin - Madison.<br/>
<br/>
Abstracts are due May 5th.  All poster abstracts will be accepted and we<br/>
are particularly invested in giving speaking opportunities to graduate<br/>
students and postdoctoral researchers.<br/>
<br/>
Please submit your abstract at the site below.<br/>
<br/>
<a href=\"http://www.union.wisc.edu/ceaging/oral-abstracts.html\">http://www.union.wisc.edu/ceaging/oral-abstracts.html<\/a><br/>
<br/>
Don't hesitate to contact me should you require further information.<br/>
<br/>
Best<br/>
Sean<br/>";
  $body .= "<br/>\n<br/>\nFollow this link to unsubscribe from newsletter and meeting announcements : http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd";

  my $command = 'sendmail';
  my $mailer = Mail::Mailer->new($command) ;
#   print "Mail to $email\n";
  $mailer->open({ From    => $user,
                  To      => $email,
                  Subject => $subject,
                  'MIME-Version' => '1.0',
                "Content-type" => 'text/html; charset=ISO-8859-1',
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
#                 "Content-type" => 'text/html; charset=ISO-8859-1',
#                 "Content-type" => 'text/plain; charset=ISO-8859-1',
} # sub mail_simple

# replaced with mail_simple, which hopefully has better headers.
# sub mail_body {
#   my ($email, $twonum, $passwd) = @_;
# #   my $user = 'pws@caltech.edu';
#   my $user = 'mendelj@caltech.edu';
#   $user = "\"Marty Chalfie and Jane Mendel\" <mendelj\@caltech.edu>",
#   my $subject = "The Worm Breeder's Gazette now available";
#   my $body = "Dear Worm Community,
# 
# The first issue of The Worm Breeder's Gazette in its new on-line
# format is now available at http://www.wormbook.org/wbg/.  This issue
# includes over 30 contributions on diverse topics including an
# editorial by Marty Chalfie, information on a common background
# mutation, new ways to visualize molecules, and several new
# techniques.  We thank the authors and the worm community for their
# enthusiastic response to the revival of The Worm Breeder's Gazette.
# 
# Sincerely,
# 
# Marty Chalfie and Jane Mendel
# 
# Jane Mendel
# Editor, WormBook
# Biology Division
# California Institute of Technology 156-29
# Pasadena, CA 91125
# 626/395-8903
# mendelj\@caltech.edu <mailto:mendelj\@caltech.edu>";
#   $body .= "\n\nFollow this link to unsubscribe from newsletter and meeting announcements : http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd";
# #   my $email = "cecilia\@minerva.caltech.edu";
#   &mailer($user, $email, $subject, $body);	# email cecilia data
# } # sub mail_body

