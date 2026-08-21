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
Getopt::Long::Configure('no_ignore_case');	# else -H for html collides with -h for help
$| = 1;				# unbuffered, so the mailer: lines on stderr stay in order with this output
use Jex;			# mailer getSimpleSecDate
use Dotenv -load => '/usr/lib/.env';

# -e, -c and -r each take a list of addresses.  Repeat the flag, or pass one
# comma separated value, or mix the two - the forms do the same thing, since
# Jex::mailer takes comma separated lists.
my @recipientArgs;
my @ccArgs;
my @replyToArgs;
my $subject      = '';
my $content_type = 'text/plain';
my $help         = 0;

GetOptions( 'email|e=s@'   => \@recipientArgs,
            'cc|c=s@'      => \@ccArgs,
            'subject|s=s'  => \$subject,
            'html|H'       => sub { $content_type = 'text/html'; },
            'replyto|r=s@' => \@replyToArgs,
            'help|h'       => \$help,
          ) or &usage(1);

if ($help) { &usage(0); }

my @recipientList = &addressList(@recipientArgs);
my @ccList        = &addressList(@ccArgs);
my @replyToList   = &addressList(@replyToArgs);
unless (@recipientList) { print qq(\nERROR : at least one -e <recipient> is required\n); &usage(1); }

my $recipient = join(', ', @recipientList);
my $cc        = join(', ', @ccList);
my $reply_to  = join(', ', @replyToList);

&checkJexIsCurrent();
&showConfiguration();

my $replyToForBody = $reply_to;
unless ($replyToForBody) { $replyToForBody = 'every recipient of this message'; }

my $timestamp = &getSimpleSecDate();
unless ($subject) { $subject = qq(WormBase curation mailer test $timestamp); }

my $body = qq(This is a test message from test_mailer.pl.

If you are reading it, Jex::mailer reached AWS SES with the credentials in
/usr/lib/.env, and the forms and cron jobs that call it can send mail again.

sent at       : $timestamp
content type  : $content_type
to            : $recipient
cc            : $cc
reply-to      : $replyToForBody
);
if ($content_type eq 'text/html') { $body =~ s/\n/<br\/>\n/g; }

print qq(sending $content_type to ) . scalar(@recipientList) . qq( recipient(s) : $recipient\n);
if ($cc)       { print qq(              cc ) . scalar(@ccList) . qq( : $cc\n); }
if ($reply_to) { print qq(        reply-to ) . scalar(@replyToList) . qq( : $reply_to\n); }
print qq(\n);

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
  my $replyto  = $ENV{EMAIL_REPLY_TO} || '(not set, so the reply goes to every recipient of the message)';
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
  else           { print qq(  Reply-To for this message          : the To and Cc addresses below\n); }
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

sub addressList {		# flatten repeated flags and comma separated values into one list
  my @values = @_;
  my @addresses;
  foreach my $value (@values) {
    foreach my $address (split /,/, $value) {
      $address =~ s/^\s+//; $address =~ s/\s+$//;	# trim around, but keep any display name intact
      if ($address =~ m/\S/) { push @addresses, $address; }
    }
  }
  return @addresses;
} # sub addressList

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

  -e, --email <list>        where to send the test message.  Required.
  -c, --cc <list>           cc recipients.
  -r, --replyto <list>      Reply-To for this message.  Without it, Jex::mailer
                            defaults the Reply-To to every recipient of the
                            message, which is what the forms rely on so that a
                            reply reaches all the curators on the thread.
  -s, --subject <text>      subject line.  Defaults to a timestamped one.
  -H, --html                send as text/html instead of text/plain.
  -h, --help                this message.

Each <list> is one or more addresses.  Repeat the flag, or pass a comma
separated value, or mix the two.

examples :

  docker compose exec curation /usr/lib/scripts/test_mailer.pl -e you\@example.org

  # the shape a form sends : submitter in To, curators in Cc, reply reaches all
  docker compose exec curation /usr/lib/scripts/test_mailer.pl \\
    -e submitter\@example.org \\
    -c cgrove\@caltech.edu -c garys\@caltech.edu -H

  # same thing with comma separated lists, and a fixed Reply-To
  docker compose exec curation /usr/lib/scripts/test_mailer.pl \\
    -e 'submitter\@example.org, second\@example.org' \\
    -c 'cgrove\@caltech.edu, garys\@caltech.edu' \\
    -r 'curation\@wormbase.org, outreach\@wormbase.org'

  make test-mailer TO=you\@example.org

);
  exit $exit;
} # sub usage
