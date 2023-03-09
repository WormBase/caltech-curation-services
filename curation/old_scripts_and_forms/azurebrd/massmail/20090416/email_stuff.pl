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
# TODO : check two_status to only send to  Valid  values.  2009 10 21
#
# Switched to DBI
# check two_status and ignore Invalid
# check two_unsubscribe and ingnore unsubscribed
# add link to unsubscribe off of person form
#   http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two1823&passwd=20030207
# changed %emails to hold twonum -> email -> <actual email> and twonum -> passwd -> actual password
#   password is the date of the timestamp of the two table without the hyphens
#   sort numerically while sending emails
# added %send_to hash, which while not having that section commented out, will delete all
#   emails except for those in %send_to (for testing sending emails).  2009 11 24


use Jex;
use diagnostics;
use MIME::Lite;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

# use Pg;
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


# my %emails;
# my $result = $dbh->prepare( "SELECT two_email FROM two_email WHERE two_email !~ '. .';" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $emails{$row[0]}++;
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)


my %emails;
my $result = $dbh->prepare( "SELECT * FROM two_email WHERE two_email !~ '. .';" );
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



my %send_to;			# who to send emails to
$send_to{'1823'}++;
# $send_to{'625'}++;
# $send_to{'324'}++;
# HERE COMMENT OUT TO SEND TO EVERYONE, otherwise just sends to %send_to  two numbers above
foreach my $two (keys %emails) {	# this deletes all emails except for %send_to emails above
  unless ( $send_to{$two} ) { delete $emails{$two}; } }


foreach my $twonum (sort { $a<=>$b } keys %emails) { 
  next unless ($emails{$twonum}{passwd});
  foreach my $email (sort keys %{ $emails{$twonum}{email} }) {
    print "$twonum E $email PASSWD $emails{$twonum}{passwd}\n";
# HERE UNCOMMENT TO SEND ATTACHMENTS
#     &mimeAttacher($email, $twonum, $emails{$twonum}{passwd});
# HERE UNCOMMENT TO SEND PLAIN EMAILS
#     &mail_body($email, $twonum, $emails{$twonum}{passwd});
  } # foreach my $email (sort keys %{ $emails{$twonum}{email} }) 
} # foreach my $twonum (sort $a<=>$b keys %emails)


# # HERE UNCOMMENT TO SEND TO EVERYONE
# # Uncomment to send to everyone 
# # foreach $_ (sort keys %emails) { &mimeAttacher("$_"); }
# 
# # Uncomment to print list of email addresses
# # foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }
# 
# # Sample mailing to myself or Paul
# # &mimeAttacher('azurebrd@minerva.caltech.edu');
# # &mimeAttacher('pws@caltech.edu');
# 
# # Sample mailing to ranjana
# # &mimeAttacher('ranjana@its.caltech.edu');
# # &mimeAttacher('kishoreranjana@hotmail.com');
# 
# # Mail to wormbase-announce
# # &mimeAttacher('wormbase-announce@wormbase.org');


# &mail_body('azurebrd@minerva.caltech.edu');

sub mimeAttacher {
#   my $email = shift;
  my ($email, $twonum, $passwd) = @_;
  my $user = 'pws@caltech.edu';
  my $subject = 'WormBase Newsletter April 2009';
  my $attachment = 'WormBase_Newsletter_April_2009.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct_2008.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb_2007.pdf';
#   my $attachment = 'WormBase_Newsletter_June_2006.pdf';
#   my $attachment = 'WormBase_Newsletter_Jan2006.pdf';
#   my $attachment = 'WormBase_Newsletter_June2005.pdf';
#   my $attachment = 'WormBase_Newsletter_April2005.pdf';
#   my $attachment = 'WormBase_Newsletter_Feb2005.pdf';
#   my $attachment = 'WormBase_Newsletter_May2004.pdf';
#   my $attachment = 'WormBase_Newsletter_Oct2003.pdf';
  my $body = "The latest issue of the WormBase Newsletter is released, please find 
it attached to this email.  

Thank you!

--The WormBase Consortium

";
  $body .= "\n\nFollow this link to unsubscribe from newsletter and meeting announcements : http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd";

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
#   my $email = shift;
  my ($email, $twonum, $passwd) = @_;
  my $user = 'pws@caltech.edu';
  my $subject = 'WormBase Newsletter & Survey';
  my $body = "We attach the February 2003 WormBase Newsletter. To help us improve 
WormBase, we would appreciate your taking time to complete a short 
on-line survey about WormBase at 
http://www.wormbase.org/about/survey_2003.html.
Thank you!

--The WormBase Consortium";
  $body .= "\n\nFollow this link to unsubscribe from newsletter and meeting announcements : http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/person.cgi?action=unsubscribe&two=two$twonum&passwd=$passwd";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data
} # sub mail_body

