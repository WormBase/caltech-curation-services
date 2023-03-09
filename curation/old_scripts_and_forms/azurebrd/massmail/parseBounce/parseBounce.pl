#!/usr/bin/perl

# print to the screen all emails that bounced, as well as email numbers that have no match or have not been categorized.  2012 05 20
#
# Jane's batch that ran on 20121211 started on 20121128_Jane/ and is in that subdirectory.  2012 12 11 

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my %pgEmails;
my $result = $dbh->prepare( "SELECT * FROM two_email;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  $row[2] =~ s/ //g;				# take out all spaces
  $pgEmails{$row[2]} = $row[0]; }



# my $dir = '/home/azurebrd/Mail/bounce3';
# my $dir = '/home/azurebrd/work/newsletter/parseBounce/20121211';
my $dir = '/home/azurebrd/work/newsletter/parseBounce/20140503';
# my $sender = 'mendelj@caltech.edu';
my $sender = 'spcurran@usc.edu';

my %allEmails;
my @bounceLines;

my %ok;
my %ignore;
my %bad;
my %list;

$ok{"out of office"}++;
$ok{"out of my office"}++;
$ok{"out of the office"}++;
$ok{"out of town"}++;
$ok{"away from my e-mail"}++;
$ok{"away from my email"}++;
$ok{"away from email"}++;
$ok{"sabbatical"}++;
$ok{"maternity"}++;
$ok{"paternity"}++;
$ok{"I am away"}++;
$ok{"I'm away"}++;
$ok{"I will be back"}++;
$ok{"I am at a workshop"}++;
$ok{"I am on the semester"}++;
$ok{"I am travelling"}++;
$ok{"I am working away"}++;
$ok{"I am on vacation"}++;
$ok{"I'll be away"}++;
$ok{"I will be in"}++;
$ok{"I am temporarily off"}++;

$ignore{"Encoding: base64"}++;					# encoded
$ignore{"unsolicited bulk"}++;
$ignore{"No action is required on your part"}++;
$ignore{"Temporary failure"}++;
$ignore{"YOU DO NOT NEED TO RESEND YOUR MESSAGE"}++;
$ignore{"try to resen=\nd the message later"}++;
$ignore{"this account will no longer be used"}++;
$ignore{"account is full"}++;
$ignore{"quota exceeded"}++;
$ignore{"mailbox is full"}++;
$ignore{"over quota"}++;
$ignore{"insufficient space"}++;

$ignore{"NotAuthorized"}++;
$ignore{"Relaying Denied"}++;
$ignore{"mail receiving disabled"}++;

$bad{"could not\nbe delivered"}++;				# most matches
$bad{"permanent fatal error"}++;
$bad{"This is a permanent error"}++;
$bad{"Delivery has failed"}++;
$bad{"permanent delivery errors"}++;
$bad{"Recipient address rejected"}++;
$bad{"Delivery to the following recipients failed"}++;
$bad{"User Unknown"}++;
$bad{"Unknown User"}++;
$bad{"Unknown address error"}++;
$bad{"User account is expired"}++;
$bad{"This person left"}++;
$bad{"This account has been disabled or discontinued"}++;
$bad{"not found user"}++;

$bad{"konnte nicht gefunden werden"}++;				# could not be found (german)
$bad{"No se ha podido rea"}++;					# could not be found (linebreak)
$bad{"Det gick inte att hitta e-postadressen du angav"}++;	# Could not find the email address you entered (swedish)
$bad{"Het door u ingevoerde e-mailadres is niet gevonden"}++;	# The email address you entered was not found (dutch)

$/ = undef;
my (@files) = <${dir}/*>;
foreach my $file (@files) {
  my ($filename) = $file =~ m/${dir}\/(\d+)/;
  next unless $filename;
#   next unless ($filename eq '199');				# test a specific file number
  open (IN, "<$file") or die "Cannot open $file : $!";
  my $data = <IN>;
  close (IN) or die "Cannot close $file : $!";
  my $found = 0;
  foreach my $ok (sort keys %ok) {
    if ($data =~ m/$ok/i) { $list{"ok"}{$filename}++; $found++; last; }
  } # foreach my $ok (sort keys %ok)
  next if ($found);
  foreach my $ignore (sort keys %ignore) {
    if ($data =~ m/$ignore/i) { $list{"ignore"}{$filename}++; $found++; last; }
  } # foreach my $ignore (sort keys %ignore)
  next if ($found);
  foreach my $bad (sort keys %bad) {
    if ($data =~ m/$bad/i) { $list{"bad"}{$filename}++; $found++; last; }
  } # foreach my $bad (sort keys %bad)
  next if ($found);
  $list{"unknown"}{$filename}++;
} # foreach my $file (@files)
$/ = "\n";

# foreach my $filename (sort {$a<=>$b} keys %{ $list{"ok"} }) {
#   print "OK $filename\n";
# } # foreach my $filename (sort keys %{ $list{"ok"} })
# 
# foreach my $filename (sort {$a<=>$b} keys %{ $list{"ignore"} }) {
#   print "IGNORE $filename\n";
# } # foreach my $filename (sort keys %{ $list{"ignore"} })

my $count = 0;
foreach my $filename (sort {$a<=>$b} keys %{ $list{"bad"} }) {
  &treatBad($filename);
  $count++;
#   last if ($count > 5);
} # foreach my $filename (sort keys %{ $list{"bad"} })

# To find all that looks like an email in whole directory
# foreach my $email (sort {$allEmails{$b} <=> $allEmails{$a}} keys %allEmails) {
#   my $count = $allEmails{$email};
#   print "$count\t$email\n";
# } # foreach my $email (sort {$allEmails{$a} <=> $allEmails{$b}} keys %allEmails)

foreach my $filename (sort {$a<=>$b} keys %{ $list{"unknown"} }) {
  print "UNKNOWN $filename\n";
} # foreach my $filename (sort keys %{ $list{"unknown"} })

foreach my $bounceLine (@bounceLines) { print $bounceLine; }

sub treatBad {
  my ($filename) = @_;
  my $file = $dir . '/' . $filename;
  $/ = undef;
  open (IN, "<$file") or die "Cannot open $file : $!";
  my $data = <IN>;
  close (IN) or die "Cannot close $file : $!";

  my $emailFound = 0;
  my (@emails) = $data =~ m/([^\s]+@[^\s]+)/g; my %emails;
  foreach my $email (@emails) {
    next if ($email =~ m/tazendra/);
    next if ($email =~ m/mangolassi/);
    next if ($email =~ m/$sender/);
    if ($email =~ m/rfc822;/) {             $email =~ s/rfc822;//; }
    if ($email =~ m/&lt;/) {                $email =~ s/&lt;/</;   }
    if ($email =~ m/&gt;/) {                $email =~ s/&gt;/>/;   }
    if ($email =~ m/<br>/) {                $email =~ s/<br>//;    }
    if ($email =~ m/<p>/) {                 $email =~ s/<p>//;     }
    if ($email =~ m/<\/a>/) {               $email =~ s/<\/a>//;   }
    if ($email =~ m/<\/p>/) {               $email =~ s/<\/p>//;   }
    if ($email =~ m/>\W+$/) {               $email =~ s/>\W+$//;   }
    if ($email =~ m/^</) {                  $email =~ s/^<//;      }
    if ($email =~ m/>$/) {                  $email =~ s/>$//;      }
    $emails{$email}++;
    $allEmails{$email}++;
  } # foreach my $email (@emails)
  $/ = "\n";

  my %emailMatch;
  foreach my $email (sort {$emails{$b} <=> $emails{$a}} keys %emails) {
#     my $count = $emails{$email};
    if ($pgEmails{$email}) { $emailFound++; $emailMatch{$email}++; }
      else { 
        foreach my $pgEmail (sort keys %pgEmails) {
          if ($email =~ m/$pgEmail/) { $emailFound++; $emailMatch{$pgEmail}++; }
        } # foreach my $pgEmail (sort keys %pgEmails)
      }
#     print "$count\t$email\n";
  } # foreach my $email (sort {$emails{$a} <=> $emails{$b}} keys %emails)

  if ($emailFound) {
    foreach my $email (sort keys %emailMatch) {
      my $count = $emailMatch{$email};
      my $two   = $pgEmails{$email};
      push @bounceLines, "$filename\t$two\t$email\n";
    } # foreach my $email (sort keys %emailMatch)
  } else {
    print "NO MATCH $filename\n";
  } # unless ($emailFound)

#   my $emails = join", ", sort keys %emails;
#   print "BAD $filename -- $data\n";
#   print "BAD $filename -- $emails\n";
} # sub treatBad
