#!/usr/bin/perl

use strict;
use DBI;
use Mail::Sendmail;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my $seminar = 9;

my $user = 'outreach@wormbase.org';
my $subject = 'WormBase Webinar #9: High-throughput Expression Data & Tools in WormBase 3/22 10am PDT';
my $body = <<'EOM';
Dear Worm Researchers,

Thank you for registering for our WormBase Webinar Series! We are going to have a session this coming Monday featuring high-throughput expression.

Wen Chen will introduce the current data and tools in WormBase, including SPELL, RNASeq related tools, and expression clusters derived from Microarray, RNASeq, and Proteomics analyses. Eduardo Beltrame will introduce the prototypes that we are currently developing for Single-Cell RNASeq studies. 

We hope you can attend the webinar live to provide us feedback!

The WormBase Team

*************************************************************************
Topic: WormBase Webinar #9: High-throughput Expression: WormBase SPELL & RNASeq related tools
Time: Mar 22, 2021 10:00 AM Pacific Time (US and Canada)

Join Zoom Meeting
https://caltech.zoom.us/j/85175636122?pwd=aG5lNGFwRnE5ODNuL3g1VTNEdFRhZz09

Meeting ID: 851 7563 6122
Passcode: RNASeq
One tap mobile
+12133388477,,85175636122# US (Los Angeles)
+16699006833,,85175636122# US (San Jose)

Dial by your location
        +1 213 338 8477 US (Los Angeles)
        +1 669 900 6833 US (San Jose)
        +1 346 248 7799 US (Houston)
        +1 646 558 8656 US (New York)
        +1 301 715 8592 US (Washington DC)
        +1 312 626 6799 US (Chicago)
Meeting ID: 851 7563 6122
Find your local number: https://caltech.zoom.us/u/kdfvZZT8ux

Join by SIP
85175636122@zoomcrc.com

Join by H.323
162.255.37.11 (US West)
162.255.36.11 (US East)
115.114.131.7 (India Mumbai)
115.114.115.7 (India Hyderabad)
213.19.144.110 (Amsterdam Netherlands)
213.244.140.110 (Germany)
103.122.166.55 (Australia Sydney)
103.122.167.55 (Australia Melbourne)
149.137.40.110 (Singapore)
64.211.144.160 (Brazil)
69.174.57.160 (Canada Toronto)
65.39.152.160 (Canada Vancouver)
207.226.132.110 (Japan Tokyo)
149.137.24.110 (Japan Osaka)
Meeting ID: 851 7563 6122
Passcode: 825569
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

