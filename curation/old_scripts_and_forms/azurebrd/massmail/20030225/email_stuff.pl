#!/usr/bin/perl

# Get list of two_emails from postgres and email attachment PDF with Paul's
# text.  2003 02 25
#
# Update to email in Oct 28.  A bad address in two_email produced this error :
# qmail-inject: fatal: unable to parse this line:
# To: e-mail: assafrn@tx.technion.ac.il
# Perhaps next time check that there no spaces in two_email first.
# 2003 10 28


use Jex;
use diagnostics;
use Pg;
use MIME::Lite;

print "blih\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



my %emails;
# my $result = $conn->exec( "SELECT * FROM two_email WHERE two_email ~ 'com';" );
print "blah\n";
my $result = $conn->exec( "SELECT * FROM pap_verified WHERE pap_verified ~ 'NO' ;" );
print "bl3h\n";

while (my @row = $result->fetchrow) {
print "$row[0]\n";
  if ($row[0]) { 
    $row[0] =~ s///g;
    $emails{$row[0]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mimeAttacher("$_"); }

# Uncomment to print list of email addresses
foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }

# Sample mailing to myself or Paul
# &mimeAttacher('azurebrd@minerva.caltech.edu');
# &mimeAttacher('pws@caltech.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@caltech.edu');

# &mail_body('azurebrd@minerva.caltech.edu');

sub mimeAttacher {
  my $email = shift;
  my $user = 'pws@caltech.edu';
  my $subject = 'WormBase Newsletter & Survey Plus Attachment';
  my $attachment = 'WormBase_Newsletter_2003Feb.pdf';
  my $body = "We attach the February 2003 WormBase Newsletter. To help us improve 
WormBase, we would appreciate your taking time to complete a short 
on-line survey about WormBase at 
http://www.wormbase.org/about/survey_2003.html.
Thank you!

--The WormBase Consortium";
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

