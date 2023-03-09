#!/usr/bin/perl

# Get European countries by deleting non-European countires.  Perhaps this is a
# bad idea if new non-European countries get added.  Probably best to check each
# time before mailing to this generated list.  2006 01 13
#
# Sent 2006 03 01


use Jex;
use diagnostics;
use Pg;
use MIME::Lite;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM two_country ;" );
while (my @row = $result->fetchrow) {
  if ($row[2]) { 
    $row[2] =~ s///g;
    $countries{$row[2]}++; } }

  # Delete non-European countries
delete $countries{'08854'};
delete $countries{'1.- United States of America'};
delete $countries{'35294-4400'};
delete $countries{'47408'};
delete $countries{'AUSTRALIA'};
delete $countries{'Argentina'};
delete $countries{'Australia'};
delete $countries{'BRAZIL'};
delete $countries{'Brasil'};
delete $countries{'Brazil'};
delete $countries{'CANADA'};
delete $countries{'CANADA  '};
delete $countries{'Canada'};
delete $countries{'Canada.'};
delete $countries{'China'};
delete $countries{'Departmeni of Biological Sciences, Columbia University, New York, N. Y., USA'};
delete $countries{'Harvard Medical School, Boston	MA, USA'};
delete $countries{'Hong Kong'};
delete $countries{'Hong Kong PRC'};
delete $countries{'ISRAEL'};
delete $countries{'India'};
delete $countries{'Israel'};
delete $countries{'JAPAN'};
delete $countries{'Japan'};
delete $countries{'Japan '};
delete $countries{'Japana'};
delete $countries{'KOREA'};
delete $countries{'Korea'};
delete $countries{'Mexico'};
delete $countries{'New Zealand'};
delete $countries{"PEOPLE'S REPUBLIC OF CHINA"};
delete $countries{"People's Republic of China"};
delete $countries{'Republic of Korea'};
delete $countries{'Republic of Singapore'};
delete $countries{'SINGAPORE'};
delete $countries{'SINGAPORE '};
delete $countries{'SOUTH KOREA'};
delete $countries{'Singapore'};
delete $countries{'South Korea'};
delete $countries{'Taiwan'};
delete $countries{'Taiwan, ROC'};
delete $countries{'Taiwan, Republic of China'};
delete $countries{'U. S. A.'};
delete $countries{'U.S.A'};
delete $countries{'U.S.A.'};
delete $countries{'US'};
delete $countries{'USA'};
delete $countries{'USA.'};
delete $countries{'Uganda'};
delete $countries{'United States of America'};
delete $countries{'nodatahere'};

# foreach my $country (sort keys %countries) {
#   print "$country\n";
# } # foreach my $country (sort keys %countries)

my $in = join"', '", keys %countries;

$result = $conn->exec( "SELECT two_email FROM two_email WHERE joinkey IN (SELECT joinkey FROM two_country WHERE two_country IN ('$in') ) AND two_order = '1'; ");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $emails{$row[0]}++;
#     print "$row[0]\n";
  } # if ($row[0])
} # while (my @row = $result->fetchrow)

# Sample emails to myself and Nektarios
# &mail_body('azurebrd@minerva.caltech.edu');
# &mail_body('cecilia@tazendra.caltech.edu');
# &mail_body('tavernarakis@imbb.forth.gr');

# HERE UNCOMMENT TO SEND TO EVERYONE
# Uncomment to send to everyone 
# foreach $_ (sort keys %emails) { &mail_body("$_"); }

sub mail_body {
  my $email = shift;
  my $user = 'Nektarios Tavernarakis <tavernarakis@imbb.forth.gr>';
  my $subject = 'EWM2006';
  my $body = "Dear Colleagues,

The European Worm Meeting will take place between the 29th of April and the
3rd of May 2006, at the town of Hersonissos on the island of Crete, Greece.

MEETING DEADLINES:
Abstract Submission - 17 March 2006
Financial Aid Application - 24 March 2006
Early Registration - 24 March 2006
Housing Reservation - 24 March 2006

The web site for the meeting with information about the meeting venue,
registration, accommodation and abstract submission is accessible at:
http://www.imbb.forth.gr/ewm2006/

All meeting questions should be directed to Mrs. Georgia Houlaki, European
Worm Meeting 2006 Secretariat (ewm2006\@imbb.forth.gr).

Organizer: Nektarios Tavernarakis (Greece)

Organizing Committee:
Christian Eckmann (Germany)
Monica Gotta (Switzerland)
Neil Hopper (UK)
Fritz Muller (Switzerland)
Stephen Nurrish (UK)
Francesca Palladino (France)
Jerome Reboul (France)
Peter Swoboda (Sweden)

We look forward to welcoming you on Crete!";
#   my $email = "cecilia\@minerva.caltech.edu";
  &mailer($user, $email, $subject, $body);	# email cecilia data
  print "$email\n";
} # sub mail_body


__END__

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

