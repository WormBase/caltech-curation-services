#!/usr/bin/env perl

# test_mailer.pl - send one test message through Jex::mailer, the same code path
# every form and cron job in this repo uses, to check that the AWS SES
# credentials in .env actually work.
#
# Run it inside the curation container, so that it reads the same /usr/lib/.env
# the forms read :
#   docker compose exec curation /usr/lib/scripts/test_mailer.pl -e you@example.org
# or
#   make test-mailer TO=you@example.org
#
# Jex.pm is copied into the image by curation/Dockerfile, it is not bind
# mounted, so after editing it you have to
#   docker compose up -d --build curation
# before this script can see the change.  It compares the copy it loaded against
# the one in the mounted source tree and complains if they differ, because
# otherwise a rebuild that did not happen looks exactly like a code change that
# did not work.
#
# Exits 0 when the message was accepted by the smtp server, 1 otherwise.
#
# 2026 08 21

use strict;
use Getopt::Long;
$| = 1;				# unbuffered, so the mailer: lines on stderr stay in order with this output
use Jex;			# mailer getSimpleSecDate
use Dotenv -load => '/usr/lib/.env';

my $recipient    = '';
my $cc           = '';
my $subject      = '';
my $content_type = 'text/plain';
my $reply_to     = '';
my $help         = 0;

GetOptions( 'email|e=s'    => \$recipient,
            'cc|c=s'       => \$cc,
            'subject|s=s'  => \$subject,
            'html|H'       => sub { $content_type = 'text/html'; },
            'replyto|r=s'  => \$reply_to,
            'help|h'       => \$help,
          ) or &usage(1);

if ($help) { &usage(0); }
unless ($recipient) { print qq(\nERROR : -e <recipient> is required\n); &usage(1); }

&checkJexIsCurrent();
&showConfiguration();

my $timestamp = &getSimpleSecDate();
unless ($subject) { $subject = qq(WormBase curation mailer test $timestamp); }

my $body = qq(This is a test message from test_mailer.pl.

If you are reading it, Jex::mailer reached AWS SES with the credentials in
/usr/lib/.env, and the forms and cron jobs that call it can send mail again.

sent at       : $timestamp
content type  : $content_type
recipients    : $recipient
cc            : $cc
);
if ($content_type eq 'text/html') { $body =~ s/\n/<br\/>\n/g; }

print qq(sending $content_type to $recipient);
if ($cc) { print qq( , cc $cc); }
print qq( ...\n\n);

# Same call the forms make.  $user is the first argument and is ignored by
# mailer, it is only still there so the old call sites did not have to change.
my $sent = &mailer('test_mailer.pl', $recipient, $subject, $body, $cc, $content_type, $reply_to);

print qq(\n);
if ($sent) {
  print qq(SUCCESS - the smtp server accepted the message.\n);
  print qq(Check the inbox of $recipient, and the spam folder too : a first message\n);
  print qq(from a new sending domain often lands there.\n);
  exit 0;
} else {
  print qq(FAILURE - the message was not sent.\n);
  print qq(The reason is on the 'mailer:' line above, printed to stderr by Jex::mailer.\n);
  print qq(Common causes :\n);
  print qq(  - EMAIL_SMTP_USER / EMAIL_PASSWD missing from /usr/lib/.env\n);
  print qq(  - the SES smtp credentials are for a different aws region than EMAIL_HOST\n);
  print qq(  - EMAIL_FROM is not a verified SES identity in that aws account\n);
  print qq(  - the SES account is still in the sandbox, which only allows verified recipients\n);
  exit 1;
}

sub showConfiguration {
  my $host     = $ENV{EMAIL_HOST}     || '(default in Jex.pm)';
  my $port     = $ENV{EMAIL_PORT}     || '(default in Jex.pm)';
  my $from     = $ENV{EMAIL_FROM}     || '(default in Jex.pm)';
  my $replyto  = $ENV{EMAIL_REPLY_TO} || '(default in Jex.pm)';
  # Never print the credentials themselves, this runs on a shared server and
  # the output gets pasted into tickets and emails.
  my $user     = $ENV{EMAIL_SMTP_USER} ? 'set (' . length($ENV{EMAIL_SMTP_USER}) . ' characters)' : 'NOT SET';
  my $passwd   = $ENV{EMAIL_PASSWD}    ? 'set (' . length($ENV{EMAIL_PASSWD})    . ' characters)' : 'NOT SET';
  print qq(\nmailer configuration, from /usr/lib/.env\n);
  print qq(  EMAIL_HOST      : $host\n);
  print qq(  EMAIL_PORT      : $port\n);
  print qq(  EMAIL_FROM      : $from\n);
  print qq(  EMAIL_REPLY_TO  : $replyto\n);
  print qq(  EMAIL_SMTP_USER : $user\n);
  print qq(  EMAIL_PASSWD    : $passwd\n);
  if ($reply_to) { print qq(  Reply-To for this message, from -r : $reply_to\n); }
  print qq(\n);
} # sub showConfiguration

sub checkJexIsCurrent {
  my $loaded = $INC{'Jex.pm'};
  unless ($loaded) { return; }
  my $source = '/usr/lib/scripts/perl_modules/Jex.pm';
  print qq(\nJex.pm loaded from $loaded\n);
  unless (-e $source)      { return; }
  if ($loaded eq $source)  { return; }
  my $loadedText = &slurp($loaded);
  my $sourceText = &slurp($source);
  unless (defined $loadedText && defined $sourceText) { return; }
  if ($loadedText eq $sourceText) { return; }
  print qq(\nWARNING : the Jex.pm in the image differs from $source\n);
  print qq(          The image was built from an older Jex.pm.  Run\n);
  print qq(            docker compose up -d --build curation\n);
  print qq(          and then this script again, otherwise you are testing the old mailer.\n);
} # sub checkJexIsCurrent

sub slurp {
  my $file = shift;
  open (IN, "<$file") or return undef;
  local $/;
  my $text = <IN>;
  close (IN);
  return $text;
} # sub slurp

sub usage {
  my $exit = shift;
  print qq(
usage : test_mailer.pl -e <recipient> [options]

  -e, --email <address>     where to send the test message.  Comma separated for
                            more than one recipient.  Required.
  -c, --cc <address>        comma separated cc recipients.
  -s, --subject <text>      subject line.  Defaults to a timestamped one.
  -H, --html                send as text/html instead of text/plain.
  -r, --replyto <address>   override the Reply-To for this message only.
  -h, --help                this message.

examples :

  docker compose exec curation /usr/lib/scripts/test_mailer.pl -e you\@example.org
  docker compose exec curation /usr/lib/scripts/test_mailer.pl -e you\@example.org -H
  make test-mailer TO=you\@example.org

);
  exit $exit;
} # sub usage
