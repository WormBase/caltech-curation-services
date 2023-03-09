#!/usr/bin/perl -w

# Look through a mbox for some strings to find email bounces, then find the
# emails in pg table two_email, then find highest two_order if exists for that
# joinkey in two_old_email, copy the values using that two_order++, that
# joinkey, that two_email value, the date that it bounced, and
# current_timestamp.  If there's no email match in two_email add to %nomatch
# then lowercase emails and lowercase two_email values, then match those to
# find the proper email (if possible) and do the same thing as above for moving
# the email to two_old_email.  2005 11 08
#
# Uncommented execing of commands, ran, recommented.  2006 01 12
#
# Just get email addresses, try to get more stuff by matching the To: From: in
# lines next to each other.  Set out of office stuff together.  2008 10 12

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %allfilter;

my (@files) = </home/azurebrd/Mail/base/*>;


$/ = undef;
# my $infile = 'mbox_copy';

foreach my $infile (@files) {
my %filter;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $file = <IN>;
close (IN) or die "Cannot close $infile : $!";

my @delivery_failed;


my $type = 0;

$type++;
(@delivery_failed) = $file =~ m/Delivery to the following recipients failed.\s+(.*?)\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/The following addresses had permanent delivery errors -----\s+<(.*?)>\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/The following addresses had permanent fatal errors -----\s+<(.*?)>\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE $failed\n" } }

$type++;
(@delivery_failed) = $file =~ m/did not reach the following recipient\(s\):\s+(.*?)\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/Please make sure you have the correct address.\s+(.*?)\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/The Postfix program\s+<.*?> \(expanded from <(.*?)>\): unknown\s+user:\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/Your message cannot be delivered to the following recipients:\s+Recipient address: (.*?)\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/<(.*?)>\s+delivery failed; will not continue trying/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/550\s+<(.*?)> user unknown.\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/Diagnostic-Code: 550 5.1.1 <(.*?)>...\s+User unknown/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/<(.*?)>:\s+Sorry, no mailbox here by that name.\s+\(#5.1.1\)/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/<([^<]*?)>: User unknown in local recipient table/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE $failed\n" } }

$type++;
(@delivery_failed) = $file =~ m/We are unable to deliver a message to the address (.*?)\.\s+/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/\((.*?)\s*\) not listed in\s+Domino Directory/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

$type++;
(@delivery_failed) = $file =~ m/failed:\s+(.*?)\s+Unrouteable address/gm;
foreach my $failed (@delivery_failed) { $filter{$failed}++; }
foreach my $failed (@delivery_failed) { if ($failed =~ m/costav/) { print "$type MESSAGE\n" } }

# if ($file =~ m/To:\s+([^\n]*?)\nFrom:\s+\"Paul Sternberg\"/osgm) { $filter{$1}++; }
# if ($file =~ m/To:\s+([^\n]*?)\nFrom:\s+\"Paul Sternberg\"/os) { $filter{'smth'}++; }
if ($file =~ m/To:\s+(.*?)\nFrom:\s+\"Paul Sternberg\" \<pws\@caltech.edu\>\n/om) { $filter{$1}++; }
if ($file =~ m/From:\s+\"Paul Sternberg\" \<pws\@caltech.edu\>\nTo:\s+(.*?)\n/om) { $filter{$1}++; }
if ($file =~ m/To:\s+(.*?)\nFrom:\s+Paul Sternberg \<pws\@caltech.edu\>\n/om) { $filter{$1}++; }
if ($file =~ m/From:\s+Paul Sternberg \<pws\@caltech.edu\>\nTo:\s+(.*?)\n/om) { $filter{$1}++; }

if ($file =~ m/out of.*office/i) { $filter{'outofoffice'}++; }

  my (@matches) = keys %filter;
  unless ($matches[0]) { print "No match for $infile\n"; }
  foreach (@matches) { $allfilter{$_}++; }

} # foreach my $infile (@files)

foreach my $bad (sort keys %allfilter) { print OUT "$bad\n"; }

close (OUT) or die "Cannot close $outfile : $!";

__END__


# # manually added to hash since couldn't get a regex to match them without probably messing up other stuff (false positives)
# $filter{'Gopalakrishna.Ramaswamy@yale.edu'}++;
# $filter{'heather.hess@yale.edu'}++;
# $filter{'peng.huang@yale.edu'}++;
# $filter{'bpage@uchicago.edu'}++;

my %nomatch;
foreach my $bad (sort keys %allfilter) {
  my $good = 0;
  my $result = $conn->exec( "SELECT * FROM two_email WHERE two_email = '$bad'; ");
  while (my @row = $result->fetchrow) { if ($row[0]) { $good = "$row[0]\t$row[1]\t$row[2]"; } }
  if ($good) { 
      my ($joinkey, $order, $email) = split/\t/, $good;
      my $new_order = 1;
      my $result2 = $conn->exec( "SELECT two_order FROM two_old_email WHERE joinkey = '$joinkey' ORDER BY two_order DESC; ");
      my @row = $result->fetchrow; if ($row[0]) { $new_order = $row[0]; $new_order++; }
      my $command = "DELETE FROM two_email WHERE joinkey = '$joinkey' AND two_email = '$email'";
      print OUT "$command\n";
#       my $result3 = $conn->exec( "$command" );
      $command = "INSERT INTO two_old_email VALUES ('$joinkey', '$new_order', '$email', '2005-10-28 22:00:00', CURRENT_TIMESTAMP)";
      print OUT "$command\n";
#       my $result4 = $conn->exec( "$command" );
      print OUT "$bad $good\n"; }
    else { print OUT "No match $bad\n"; $nomatch{$bad}++; }
} # foreach my $bad (sort keys %allfilter)

my $result = $conn->exec( "SELECT * FROM two_email; ");
while (my @row = $result->fetchrow) {
  my $copy = $row[2]; $copy = lc($copy);
  foreach my $nomatch (sort keys %nomatch) {
    my $no_copy = $nomatch; $no_copy = lc($nomatch);
    if ($no_copy eq $copy) { 
      my ($joinkey, $order, $email) = ($row[0], $row[1], $row[2]);
      my $new_order = 1;
      my $result2 = $conn->exec( "SELECT two_order FROM two_old_email WHERE joinkey = '$joinkey' ORDER BY two_order DESC; ");
      my @row = $result->fetchrow; if ($row[0]) { $new_order = $row[0]; $new_order++; }
      my $command = "DELETE FROM two_email WHERE joinkey = '$joinkey' AND two_email = '$email'";
      print OUT "$command\n";
#       my $result3 = $conn->exec( "$command" );
# CHECK THAT NEW_ORDER IS AN ORDER NOT A TWONUMBER BEFORE RUNNING THIS.
      $command = "INSERT INTO two_old_email VALUES ('$joinkey', '$new_order', '$email', '2005-10-28 22:00:00', CURRENT_TIMESTAMP)";
      print OUT "$command\n";
#       my $result4 = $conn->exec( "$command" );
      print OUT "$nomatch is $row[0]\t$row[1]\t$row[2]\n"; }
  } # foreach my $nomatch (sort keys %nomatch)
}


# my $result = $conn->exec( "SELECT two_groups FROM two_groups WHERE joinkey = 'two2';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { print "$row[0]\n";}
# }


close (OUT) or die "Cannot close $outfile : $!";
