#!/usr/bin/perl

# script to check which two_number entries have a pap_email that is not set to SENT and add these to a
# queue. for each of those, compose an email to the two_person listing those set to email and those 
# set to verified (for double checking).  then updates those pap_email entries to be SENT.  
# 2002 01 08

use strict;
use Pg;
use Jex;	# mailer

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result;

my %twos;

my $errorfile = 'errors.paper_mailer';
open (ERR, ">>$errorfile") or die "Cannot append to $errorfile : $!";

$result = $conn->exec( "SELECT * FROM pap_view WHERE pap_email IS NOT NULL AND pap_email !~ 'SENT';" );
while (my @row = $result->fetchrow) {
  my ($joinkey, $author, $two_number, $email, $verified) = @row;
#   print "$joinkey\t$author\t$two_number\t$email\t$verified\n";;
  $twos{$two_number}++;
} # while (my @row = $result->fetchrow)

foreach my $two_number (sort keys %twos) {
  my @verified; my @email;
  my ($body, $header, $email_address);

  my $user = 'cecilia@minerva.caltech.edu';
  my $subject = 'WormBase Paper Verification';

  $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_possible = '$two_number'; " );
  while (my @row = $result->fetchrow) {
    my ($joinkey, $author, $two_number, $email, $verified) = @row;
    if ($verified) { push @verified, $joinkey; }
    elsif ($email) { push @email, $joinkey; }
  } # while (my @row = $result->fetchrow)

  ($header, $email_address) = &headerLetter($two_number);

  $body = &openLetter($two_number, $body);

  $body .= "Please let us know if these papers have been published by you :\n";
  foreach my $paper_key (@email) { $body = &displayPaperDataFromKey($paper_key, $body); }
  $body .= "\n\nPlease verify that these papers that have been associated to you have been published by you :\n";
  foreach my $paper_key (@verified) { $body = &displayPaperDataFromKey($paper_key, $body); }

  $body = &closeLetter($body);

# my $sample_email = 'azurebrd@minerva.caltech.edu, bounce@minerva.caltech.edu';
# my $sample_email = 'pws@its.caltech.edu, raymond@its.caltech.edu';
my $sample_email = 'pws@its.caltech.edu';

  if ($email_address eq 'ERROR : NO EMAIL IN DATABASE') {	# no email, mail error
    &mailer($user, $sample_email, "error email nonexistent : $two_number", $body);
  } else {							# email good, send it
#     print "DIV\n$header\n$body\n\nDIV\n";
    &mailer($user, $sample_email, $subject, $body);
#     print "mailer($user, $email_address, $subject, $body)\n";
  }

  &updatePapemail($two_number, $email_address);

} # foreach my $two_number (sort keys %twos)

sub updatePapemail {		# for each pap_possible two entry, update the relevant pap_emails
				# to being SENT (this could be done all at once, since the twos
				# are grouped already, so there's no need to do number by number
				# but this feels more correct)
  my $two_number = shift;
  my $email_error = shift;	# if there's no email address, flag as error that no email sent

  my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_possible = '$two_number' AND pap_email IS NOT NULL AND pap_email !~ 'SENT'; " );
#   print "my \$result = \$conn->exec( \"SELECT * FROM pap_view WHERE pap_possible = '$two_number' AND pap_email IS NOT NULL AND pap_email !~ 'SENT'; \" );\n";
  while (my @row = $result->fetchrow) {
    my ($joinkey, $author, $possible, $email) = @row;
    if ($email_error eq 'ERROR : NO EMAIL IN DATABASE') { $email = 'SENT : NO EMAIL : ' . $email; }
      else { $email = 'SENT : ' . $email; }
#     my $result2 = $conn->exec( "UPDATE pap_email SET pap_email = '$email' WHERE joinkey = '$joinkey' AND pap_author = '$author'; " );
#     print "my \$result2 = \$conn->exec( \"UPDATE pap_email SET pap_email = '$email' WHERE joinkey = '$joinkey' AND pap_author = '$author'; \" );\n";
  } # while (my @row = $result->fetchrow)
} # sub updatePapemail

sub headerLetter {
  my $two_number = shift;
  my $header; my @headers; my $emails;
  my $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = '$two_number'; " );
  while (my @row = $result->fetchrow) {
    if ($row[2]) { push @headers, $row[2]; }
  }
  $emails = join ", ", @headers;
  if ($emails) { $emails .= ', cecilia@minerva.caltech.edu'; }
    else { $emails = 'ERROR : NO EMAIL IN DATABASE'; }
  $header = "From: cecilia\@minerva.caltech.edu\nTo: $emails\nSubject: WormBase Paper Verification\n";
  return ($header, $emails);
} # sub headerLetter

sub closeLetter {
  my $body = shift;
  $body .= "\n\n\nThank you,\nCecilia Nakamura\n";
  return $body;
} # sub closeLetter

sub openLetter {
  my ($two_number, $body) = @_;
  my $first = 'No first name found';
  my $last = 'No last name found';

  my $result = $conn->exec( "SELECT * FROM two_firstname WHERE joinkey = '$two_number'; " );
  my @row = $result->fetchrow;
  if ($row[2]) { $first = $row[2]; }
  $result = $conn->exec( "SELECT * FROM two_lastname WHERE joinkey = '$two_number'; " );
  @row = $result->fetchrow;
  if ($row[2]) { $last = $row[2]; }
#   unless ($first && $last) { print ERR "ERROR $two_number has no lastname or firstname\n"; }
#   else { $body .= "
  $body .= "Dear $first $last,\n
We at WormBase are curating the Paper information to manually associate 
published Authors with their corresponding Papers.  These are the papers
that we have associated with you, would you please verify that they belong
to you (or that they do not) and email us back?\n\n";

  return $body;
} # sub openLetter

sub displayPaperDataFromKey {             # show all paper info from key, and checkbox for each 
  my ($paper_key, $body) = @_;
  my $title = 'No title found';
  my $journal = 'No journal found';

  my $result = $conn->exec( "SELECT * FROM pap_title WHERE joinkey = '$paper_key';" );
  my @row = $result->fetchrow;
  if ($row[1]) { $title = $row[1]; }
  $result = $conn->exec( "SELECT * FROM pap_journal WHERE joinkey = '$paper_key';" );
  @row = $result->fetchrow;
  if ($row[1]) { $journal = $row[1]; }
  else {
    my $result = $conn->exec( "SELECT * FROM pap_type WHERE joinkey = '$paper_key';" );
    my @row = $result->fetchrow;
    if ($row[1]) { $journal = $row[1]; }
  }

#   unless ($title && $journal) { print ERR "ERROR $paper_key has no journal or title\n"; }
#   else { $body .= "$journal\t--\t$title\n"; }
  $body .= "$journal\t--\t$title\n";

  return $body;
} # sub displayPaperDataFromKey



