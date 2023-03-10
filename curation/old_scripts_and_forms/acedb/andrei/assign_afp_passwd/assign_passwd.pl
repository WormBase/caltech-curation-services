#!/usr/bin/perl -w

# find the email to the last author and assign passwords to afp papers.  2008 06 30
#
# modified to get the last N months worth of papers and see who would get
# emailed.  2008 08 08
# modified to get output of textpresso grep for emails to see if results match.
# 2008 08 08
#
# filter out functional annotations, papers from not-2008, papers that already
# got emailed.  at most send 2 emails to each email address per run.  2008 08 21
#
# use wpa_ignore instead of cur_comment.  2008 10 08

use strict;
use diagnostics;
use Pg;
use Jex;

my $result;
srand;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my @papers = qw( 00031030 00031958 00031936 00031807 );
# my @papers = qw( 00031030 00031936 00031807 );

# my @papers = qw( 00031318 00031883 00031914 );




my $time = time;
# print "TIME $time TIME\n\n";

sub getMonthAgoDate {
  my $monthsago = shift;		# amount of months ago
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);             # get time
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  my $sam = $mon+1;                     # get right month
  $sam -= $monthsago;			# get month ago
  if ($sam < 1) { $year--; $sam += 12; }# subtract a year if the month is less than 1
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "${year}-${sam}-${mday}";	# set current date
#   my $date = $todaydate . " $hour\:$min\:$sec";
  my $date = $todaydate;
  return $date;
}

my %ignore;
$result = $conn->exec( "SELECT * FROM wpa_ignore ORDER BY wpa_timestamp");
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $ignore{$row[0]}++; } else { delete $ignore{$row[0]}; } }

my %wpa_year;
$result = $conn->exec( "SELECT * FROM wpa_year ORDER BY wpa_timestamp");
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $wpa_year{$row[0]} = $row[1]; } else { delete $wpa_year{$row[0]}; } }

my %afp_passwd;
$result = $conn->exec( "SELECT * FROM afp_passwd ORDER BY afp_timestamp");
while (my @row = $result->fetchrow) { $afp_passwd{$row[0]}++; }

my %already_curated;
$result = $conn->exec( "SELECT * FROM cur_curator");
while (my @row = $result->fetchrow) { $already_curated{$row[0]}++; }

my %temp_type; my %wpa_type;					# exclude meeting abstract, gazette abstract, review, wormbook
$result = $conn->exec( "SELECT * FROM wpa_type ORDER BY wpa_timestamp");
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $temp_type{$row[0]} = $row[1]; } else { delete $temp_type{$row[0]}; } }
foreach my $paper (keys %temp_type) { if ( ($temp_type{$paper} != '2') && ($temp_type{$paper} != '3') && ($temp_type{$paper} != '4') && ($temp_type{$paper} != '18') ) { $wpa_type{$paper}++; } }

my %textpresso;
# my $t_file = 'textpresso_grep_@.parsed';
# my $t_file = 'grep_output.parsed';
my $t_file = 'output.20081205';
open (IN, "$t_file") or die "Cannot open $t_file : $!";
while (my $line = <IN>) { chomp $line; my ($paper, $email) = split/\t/, $line; $textpresso{$paper} = $email; }
close (IN) or die "Cannot close $t_file : $!";

my $monthago = &getMonthAgoDate(6);
my %wpa;
# $result = $conn->exec( "SELECT * FROM wpa WHERE wpa_timestamp > '$monthago'" );
# $result = $conn->exec( "SELECT * FROM wpa WHERE joinkey >= '00031420';" );
$result = $conn->exec( "SELECT * FROM wpa WHERE joinkey >= '00032239';" );
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $wpa{$row[0]} = $row[5]; } else { delete $wpa{$row[0]}; } }
my (@papers) = sort {$b<=>$a} keys %wpa;


my %email_emailed;
my $emailed_count = 0;
foreach my $paper (@papers) {
#   last if ($emailed_count > 99);
  next if ($already_curated{$paper});
  next if ($ignore{$paper});
  next if ($afp_passwd{$paper});
# if restricting by joinkey, year and type probably don't matter 20081205
#   next unless ( $wpa_type{$paper} );
#   next unless ( ($wpa_year{$paper}) && ($wpa_year{$paper} eq '2008') );	
#   next unless ($wpa_year{$paper} eq '2008');
  my $message = "Paper $paper entered on $wpa{$paper}\n"; 
  my %hash;
  $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$paper' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $hash{$row[2]} = $row[1]; }
      else { delete $hash{$row[2]}; } }
  my ($join) = reverse sort {$a<=>$b} keys %hash; 
  next unless ($join);			# paper 00032005 has no authors for some reason
  my $aid = $hash{$join};
  if ($aid) { $message .= "Last Author has author ID $aid\n"; }
    else { $message .= "Last Author has no author ID\n"; }
  %hash = ();
  $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '$aid' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
#     my ($time) = $row[5] =~ m/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;
#     $time =~ s/\D//g;
#     if ($row[3] eq 'valid') { $hash{$row[2]}{who} = $row[1]; $hash{$row[2]}{time} = $time; }
#     my %time;
    if ($row[3] eq 'valid') { $hash{$row[2]} = $row[1]; }
      else { delete $hash{$row[2]}; } }
  my $wpa_join = '';
  foreach my $join (sort keys %hash) { if ($hash{$join} =~ m/YES/) { $wpa_join = $join; last; } }
  if ($wpa_join) { $message .= "wpa_join for verified author is $wpa_join\n"; }
    else { $message .= "Last author has not verified\n"; }
  %hash = ();
  $result = $conn->exec( "SELECT * FROM wpa_author_possible WHERE author_id = '$aid' AND wpa_join = '$wpa_join' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $hash{$row[2]} = $row[1]; }
      else { delete $hash{$row[2]}; } }
  my $two = '';
  foreach my $join (sort keys %hash) { if ($hash{$join} =~ m/two(\d+)/) { $two = $1; last; } }
  if ($two) { $message .= "Person for verified author is WBPerson$two\n"; }
    else { $message .= "No Person ID for verified author\n"; }
  $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = 'two$two' ORDER BY two_order ;" );
  my @row = $result->fetchrow(); my $email = $row[2];
  if ($email) { $message .= "Email for verified author is $email\n"; }
    else { $message .= "No Email address for for verified author\n"; }
  if ($textpresso{$paper}) { 
    $message .= "textpresso email for author is $textpresso{$paper}\n";
    if ($email) { 
      ($email) = lc($email); my $temail = $textpresso{$paper}; $temail = lc($temail);
      unless ($email eq $temail) { $message .= "Textpresso and verified author email don't match\n"; } }
    $email = $textpresso{$paper}; }					# always use textpresso email as main email  2008 08 21
  if ($email) {
#     next if ( ($email_emailed{$email}) && ($email_emailed{$email} > 1) );
    if ( ($email_emailed{$email}) && ($email_emailed{$email} > 0) ) {	# for second round skip if emailed once already  2008 10 17
      print "Already emailed $email, skipping $paper\n\n"; next; }
    $email_emailed{$email}++; $emailed_count++;
# COMMENT THIS OUT TO TEST RUN
    &passwordEmail($two, $paper, $email); 
    print "Emailed $paper to $email\n\n$message\n";
  }
#   if ($email) { &passwordEmail($two, $paper, $email); }
#     else { print "$message\n"; }
} # foreach my $paper (@papers)

print "Emailed to $emailed_count paper-emails\n";

sub passwordEmail {
  my ($two, $paper, $email) = @_;

  my $rand = rand;
  $rand += $time;
  ($rand) = sprintf("%.7f", $rand); 
# print "RAND $rand RAND\n\n";

  $result = $conn->exec( "INSERT INTO afp_passwd VALUES ('$paper', '$rand');" );
  print "Paper $paper Send email to $email\n\n"; 

  my $url = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/paper_fields.cgi?action=Curate&paper=$paper&passwd=$rand";

  my $result = $conn->exec( "SELECT * FROM two_standardname WHERE joinkey = 'two$two' ;" );
  my @row = $result->fetchrow(); my $name = $row[2];

  $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$paper' ORDER BY wpa_timestamp DESC;;" );
  @row = $result->fetchrow(); my $title = $row[1];
  $result = $conn->exec( "SELECT * FROM wpa_journal WHERE joinkey = '$paper' ORDER BY wpa_timestamp DESC;;" );
  @row = $result->fetchrow(); my $journal = $row[1];
  $result = $conn->exec( "SELECT * FROM wpa_year WHERE joinkey = '$paper' ORDER BY wpa_timestamp DESC;;" );
  @row = $result->fetchrow(); my $year = $row[1];

# temp while still unsure how to find emails
# if ($paper =~ m/00031318/) { $email = 'ts@genetics.wustl.edu'; }
# if ($paper =~ m/00031883/) { $email = 'cori@rockefeller.edu'; }
# if ($paper =~ m/00031914/) { $email = 'jekimble@facstaff.wisc.edu'; }

  my $user = 'petcherski@gmail.com';
#   $email = 'azurebrd@tazendra.caltech.edu';
# COMMENT THIS OUT TO EMAIL TO PROPER AUTHORS
#   $email = 'petcherski@gmail.com';
  my $subject = 'Help Wormbase curate your paper';
  my $body = "Dear $name,
We email you because you recently published the paper $title, $journal, $year. To speed up the data flow to Wormbase, we are conducting a pilot project where the papers that have been categorized by the authors get the highest priority in our curation pipeline.  Please take a ~3-10 minutes to complete the form :
$url
You can forward this url to any of your co-authors. Please contact Andrei (petcherski\@gmail.com) or wormbase-help\@wormbase.org if you need more info, etc..

We are looking forward to your reply!
Wormbase";
  &mailer($user, $email, $subject, $body);


} # sub passwordEmail

__END__

my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

