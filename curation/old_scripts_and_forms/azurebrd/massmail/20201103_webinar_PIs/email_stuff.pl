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
#
# Changed to send to PIs Diana Chu message.  2008 02 06
#
# Changed to use joinkey in %emails and %stdname instead of just the email addresses.  2009 01 20
#
# Changed for Ann Rougvie.  2009 02 08
#
# Changed for webinar outreach for Wen, Daniela, Paul.  Sent form mangolassi, not tazendra.  2020 11 03

use strict;
use warnings;
use Jex;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Mail::Sendmail;



my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;




my %emails;
my %stdname;
# UNDO
$result = $dbh->prepare( "SELECT joinkey, two_email FROM two_email WHERE two_email !~ '. .' AND joinkey IN (SELECT joinkey FROM two_pis) ;" );	# PIs only
# $result = $dbh->prepare( "SELECT joinkey, two_email FROM two_email WHERE two_email !~ '. .' ;" );	# everyone
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[0] =~ s/two//g;
    $emails{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT joinkey, two_standardname FROM two_standardname ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[0] =~ s/two//g;
    $stdname{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mail_body("$_"); }

# &mail_body("625");	# 2009 01 20  uses joinkey to get standardname

# &mail_body('1823');	# needs to get all email addresses, not just PIs
# &mail_body('12028');	# daniela
# &mail_body('closertothewake@gmail.com');
# &mail_body('azurebrd@tazendra.caltech.edu');
# &mail_body('pws@its.caltech.edu');
# &mail_body('Marian.Walhout@umassmed.edu');
# foreach $_ (sort keys %emails) { print "$_\n"; }

# Uncomment to print list of email addresses
# foreach $_ (sort keys %emails) { print "$_ : $emails{$_}\n"; }

# Sample mailing to myself or Paul or Ann Rougvie
# &mimeAttacher('azurebrd@minerva.caltech.edu');
# &mimeAttacher('pws@caltech.edu');
# &mimeAttacher('rougvie@umn.edu');

# Sample mailing to ranjana
# &mimeAttacher('ranjana@its.caltech.edu');
# &mimeAttacher('kishoreranjana@hotmail.com');

# Mail to wormbase-announce
# &mimeAttacher('wormbase-announce@wormbase.org');


# &mail_body('azurebrd@minerva.caltech.edu');

sub mail_body {
  my $key = shift;
  my $user = 'wormbase-webinar@mangolassi.caltech.edu';
  my $email = $emails{$key};
#   $email = $user;
  my $subject = 'WormBase Webinar Series';
#   my $body = "stuff";
  my $body = <<'EOM';
Dear Principal Investigators,<br/>
<br/>
For those of you who have not received a notification yet, we are happy to announce that WormBase has organized a series of webinars to feature various data types and tools. We think that the webinars might be beneficial to you and to the members of your lab.<br/>
<br/>
We opened the series last Thursday with an overview of WormBase Data and Tools, the recording is available on the <a href="https://www.youtube.com/watch?v=I0-R_nplBao&amp;t=6s">WormBase YouTube channel</a>.<br/>
<br/>
The next webinar, on November 9th at 9 am Pacific, will feature microPublication. Paul Sternberg and Tim Schedl will give an overview of the microPublication journal and the microPublication team will be there to answer your questions.<br/>
<br/>
We have posted the webinar information to the <a href="https://blog.wormbase.org/2020/10/08/register-for-the-upcoming-wormbase-webinar-series/">WormBase Blog</a>/<a href="https://twitter.com/wormbase">Twitter</a> as well as the <a href="https://www.facebook.com/groups/428842060463832">Worm Facebook</a> and <a href="https://app.slack.com/client/TDHV23VS6/CDHV243RQ">Slack</a> channel, however, most of the new worm researchers do not follow our social media.<br/>
<br/>
We also hope to take the opportunity to hear from the research community about what should be our priority of curation and software development.<br/>
<br/>
We look forward to seeing you there!<br/>
<br/>
Registration is required: <a href="https://wormbase.org/tools/webinar.cgi">https://wormbase.org/tools/webinar.cgi</a><br/>
<br/>
Webinar schedule:<br/>
<br/>
Nov. 9, 2020 (Mon.), 9 am PST, MicroPublication<br/>
Nov. 20, 2020 (Fri.), 10 am PST, JBrowse<br/>
Dec. 18, 2020 (Fri.), 10 am PST, WormMine<br/>
Jan. 11, 2021 (Mon.), 8 am PST, Parasite BioMart<br/>
Feb. 22, 2021 (Mon.), 10 am PST, Data mining strategies and workflows<br/>
Feb. 26, 2021 (Fri.), 10 am PST, Author First Pass & Textpresso<br/>
March 8, 2021 (Mon.), 10 am PST, Gene Function Graphs and Gene Set Enrichment Analysis<br/>
March 22, 2021 (Mon.), 10 am PDT, High-throughput Expression: WormBase SPELL & RNASeq related tools<br/>
EOM
#   my $body = "Dear $stdname{$key}:
# 
# We at WormBase would like your help to update your personal and lab
# webpages in Person and Lab classes.
# 
# http://wormbase.org/db/misc/person?name=WBPerson$key;class=Person
# 
# Please email back your current data. If your lab webpage does not
# include lab members please email me a list of current members.
# 
# We'd really appreciate it.
# 
# Thanks,
# 
# Cecilia";
#   my $email = "cecilia\@minerva.caltech.edu";
  if ($email) {
  my %mail;
    $mail{from}           = $user;
    $mail{to}             = $email;
    $mail{subject}        = $subject;
    $mail{body}           = $body;
    $mail{'content-type'} = 'text/html; charset="iso-8859-1"';
# UNCOMMENT TO SEND EMAIL
#     sendmail(%mail) || print qq(<span style="color:red">Error, confirmation email failed</span> : $Mail::Sendmail::error<br/>\n);
    print "SENT TO $email\n";
  }
} # sub mail_body

