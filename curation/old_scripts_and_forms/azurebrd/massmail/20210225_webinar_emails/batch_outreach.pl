#!/usr/bin/perl

use strict;
use DBI;
use Mail::Sendmail;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;


my $user = 'outreach@wormbase.org';
my $subject = 'WormBase Webinar #7: Author First Pass & Textpresso 2/26 (Fri.) 10am PST';
my $body = <<'EOM';
Dear Worm Researchers,

Just a reminder that our webinar tomorrow for Textpresso and Author First Pass.

Kimberly Van Auken and Daniela Raciti will give the feature presentation on Textpresso & Author First Pass. WormBase staff will be there to answer your questions.

If you have any questions, please contact outreach@wormbase.org.

We look forward to meeting you!

Take care and stay safe,

The WormBase Team

****************************************************************
Topic: WormBase Webinar #7: Author First Pass & Textpresso
Time: Feb 26, 2021 10:00 AM Pacific Time (US and Canada)

Join Zoom Meeting
https://caltech.zoom.us/j/86245679789?pwd=RTZ2YlYwY3BESTErWnN6WFNsYkY0QT09

Meeting ID: 862 4567 9789
Passcode: Textpresso
EOM

$body =~ s/\n/<br\/>\n/g;

# my $email = 'closertothewake@gmail.com';
# my $email = 'azurebrd@tazendra.caltech.edu';
# my $email = 'wen@wormbase.org';
# my $email = 'daniela@wormbase.org';
# my $email = 'scott.cain@wormbase.org';
# &mailSendmail($user, $email, $subject, $body);

my %sent;
# my @sentfiles = qw( sent_20201026_1049 sent_20201026_1056 );
my @sentfiles = qw( );
foreach my $sentfile (@sentfiles) {
  open (IN, "<$sentfile") or die "Cannot open $sentfile : $!";
  while (my $line = <IN>) {
    chomp $line;
    if ($line =~ m/send to (.*)/) { $sent{$1}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $sentfile : $!";
}


my $seminar = 7;
$result = $dbh->prepare( "SELECT * FROM sem_data WHERE seminar = '$seminar' AND going = 'going' ORDER BY sem_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my ($email, $name, $wbperson, $seminar, $going, $ip, $timestamp) = @row;
  next if ($sent{$email});
  print qq(send to $email\n);
  # UNCOMMENT TO SEND
#   sleep(5); &mailSendmail($user, $email, $subject, $body);
  # wait 5 seconds between requests, to see if that prevents failure from gmail
}


sub mailSendmail {
  my ($user, $email, $subject, $body) = @_;

  my $emailaddress = $email;
  my $sender = 'outreach@wormbase.org';
  my $email = Email::Simple->create(
    header => [
        From       => 'outreach@wormbase.org',
        To         => "$emailaddress",
        Subject    => "$subject",
        'Content-Type' => 'text/html',
    ],
    body => "$body",
  );

  my $passfile = '/home/postgres/insecure/outreachwormbase';
  open (IN, "<$passfile") or die "Cannot open $passfile : $!";
  my $password = <IN>; chomp $password;
  close (IN) or die "Cannot close $passfile : $!";
  my $sender = Email::Send->new(
    {   mailer      => 'Gmail',
        mailer_args => [
           username => 'outreach@wormbase.org',
           password => "$password",
        ]
    }
  );
  eval { $sender->send($email) };
  die "Error sending email: $@" if $@;

} # sub mailSendmail

