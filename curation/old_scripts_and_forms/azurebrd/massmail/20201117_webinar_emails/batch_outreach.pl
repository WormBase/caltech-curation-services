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
my $subject = 'WormBase Webinar #3: Jbrowse 11/20/2020 10 am PST';
my $body = <<'EOM';
Dear Worm Researchers,

Thank you for registering for our WormBase Webinar Series! The meeting invitation and details for our coming JBrowse webinar are enclosed.

Scott Cain will give an overview of JBrowse and tell us the most recent development. WormBase staff will be there to answer your questions.

If you have any questions, please contact outreach@wormbase.org.

We look forward to meeting you!

Take care and stay safe,

The WormBase Team

***********************************************************

Topic: WormBase Webinar #3: Jbrowse
Time: Nov 20, 2020 10:00 AM Pacific Time (US and Canada)

Join Zoom Meeting
https://caltech.zoom.us/j/89767951187?pwd=M3J0TUJyM0xiWHo2WldCMThRczRHQT09

Meeting ID: 897 6795 1187
Passcode: JBrowse
One tap mobile
+16699006833,,89767951187# US (San Jose)
+13462487799,,89767951187# US (Houston)

Dial by your location
        +1 669 900 6833 US (San Jose)
        +1 346 248 7799 US (Houston)
        +1 253 215 8782 US (Tacoma)
        +1 312 626 6799 US (Chicago)
        +1 646 558 8656 US (New York)
        +1 301 715 8592 US (Washington D.C)
Meeting ID: 897 6795 1187
Find your local number: https://caltech.zoom.us/u/kdDrRISuri

Join by SIP
89767951187@zoomcrc.com

Join by H.323
162.255.37.11 (US West)
162.255.36.11 (US East)
115.114.131.7 (India Mumbai)
115.114.115.7 (India Hyderabad)
213.19.144.110 (Amsterdam Netherlands)
213.244.140.110 (Germany)
103.122.166.55 (Australia)
149.137.40.110 (Singapore)
64.211.144.160 (Brazil)
69.174.57.160 (Canada)
207.226.132.110 (Japan)
Meeting ID: 897 6795 1187
Passcode: 4429011
EOM

$body =~ s/\n/<br\/>\n/g;

my $email = 'closertothewake@gmail.com';
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


my $seminar = 3;
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

