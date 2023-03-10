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
#
# sent 10 test papers to Paul.  2009 04 06
#
# mistakenly sent them to myself.  sent them to Paul now  2009 04 09
#
# DON'T FORGET TO ENTER INTO afp_passwd AND afp_email.  2009 04 20
#
# changed email to make more sense, sent from Karen.
# adds to afp_passwd and afp_email.
# sending to 50 people from now on (every two weeks, probably).
# real run, 49 papers.  2009 04 23
#
# added code to send reminder emails between 18 and 25 days ago that have 
# not replied in that time, and that are still not curated.  
# also, a time only run for much older emails.  2009 05 15
#
# remove reminders for Karen.  2009 06 19
#
# send genetics papers to Karen  2009 07 24
#
# No more reminder emails, no one's looking at author results anyway  2009 09 10
#
# Added warning about email handler splitting URLs  2009 09 28
#
# Updated from wpa to pap tables, even though not live  2010 06 23
#
# Updated to ignore paper unless they have a file (all are pdf) from pap_electronic_path, for Raymond.  2011 04 30
#
# Changed cronjob to 1pm because of tazendra reboot after first monthly conf calls.  2011 05 11
#
# Changed email address to kyook@wormbase.org for Todd.  2013 05 24
#
# Changed email to text/html to have links, and changed text for Karen at Mary Ann's suggestion.  2013 07 15
#
# Changed 'functional_annotation' to 'non_nematode' to match change to postgres.  2013 12 05
#
# Made a one-of mailing for Karen.  To do this again change the @em_emails when looping %match_paper.  2014 04 14
#
# No emails for Micropublications for Daniela.  2017 08 30
# Only Journal Articles for Raymond and Kimberly.  2017 08 30
#
# Daniela wanted changes to the email, generate a shortened url.  2017 12 18
#
# Turned off for Valerio, since he has a new pipeline.  2019 06 03


# crontab set to every thursday at 1 pm :
# 0 13 * * thu /home/postgres/work/pgpopulation/afp_papers/assign_passwd.pl




use strict;
use diagnostics;
use DBI;
use Jex;
use Mail::Mailer;		# replace Jex.pm's &mailer with this text/html version

my $directory = '/home/postgres/work/pgpopulation/afp_papers';
chdir ($directory) or die "Cannot change to $directory : $!";

my $result;
srand;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $date = &getSimpleSecDate();
my $outfile = '/home/postgres/work/pgpopulation/afp_papers/sent/batch.' . $date;
# my $outfile = 'testing';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $time = time;

my %ignore;
# $result = $dbh->prepare( "SELECT * FROM wpa_ignore ORDER BY wpa_timestamp");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $ignore{$row[0]}++; } else { delete $ignore{$row[0]}; } }

$result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode'; " ); $result->execute;
while (my @row = $result->fetchrow) { $ignore{$row[0]}++; }

my %has_pdf;
$result = $dbh->prepare( "SELECT * FROM pap_electronic_path WHERE pap_electronic_path IS NOT NULL; " ); $result->execute;
while (my @row = $result->fetchrow) { $has_pdf{$row[0]}++; }


my %pap_year;
$result = $dbh->prepare( "SELECT * FROM pap_year ORDER BY pap_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap_year{$row[0]} = $row[1]; } 

my %pap_journal;
$result = $dbh->prepare( "SELECT * FROM pap_journal ORDER BY pap_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap_journal{$row[0]} = $row[1]; } 

my %afp_passwd;
$result = $dbh->prepare( "SELECT * FROM afp_passwd ORDER BY afp_timestamp");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $afp_passwd{$row[0]}++; }

my %already_curated;
$result = $dbh->prepare( "SELECT * FROM cfp_curator");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $already_curated{$row[0]}++; }

my %pap_type;
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '1' ORDER BY pap_timestamp");	# only journal articles for Raymond and Kimberly  2017 08 30
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap_type{$row[0]}++; } 
# my %temp_type;					# exclude meeting abstract, gazette abstract, review, wormbook
# while (my @row = $result->fetchrow) { $temp_type{$row[0]}{$row[1]}++; } 
# foreach my $paper (keys %temp_type) { if ( !($temp_type{$paper}{'2'}) && !($temp_type{$paper}{'3'}) && !($temp_type{$paper}{'4'}) && !($temp_type{$paper}{'18'}) && !($temp_type{$paper}{'26'}) ) { $pap_type{$paper}++; } }

my %textpresso;
my $t_file = '/home/postgres/work/pgpopulation/afp_papers/textpresso_emails';
open (IN, "$t_file") or die "Cannot open $t_file : $!";
while (my $line = <IN>) { chomp $line; my ($paper, $email) = split/\t/, $line; $textpresso{$paper} = $email; }
close (IN) or die "Cannot close $t_file : $!";

my %pap;
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# $result = $dbh->prepare( "SELECT * FROM wpa WHERE joinkey >= '00032239';" );	# arbitrarily reset to 00030000
# $result = $dbh->prepare( "SELECT * FROM pap_status WHERE CAST(joinkey AS INTEGER) >= 30000 AND pap_status = 'valid';" );	# this cast is way too slow, so going by timestamp
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_timestamp > '2008-01-01' AND pap_status = 'valid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap{$row[0]} = $row[4]; } 
my (@papers) = sort {$b<=>$a} keys %pap;


my $result2; my $result3;

$result2 = $dbh->prepare( 'SELECT * FROM afp_email WHERE joinkey = ?' );

# really old emails : (only run once 2009 05 15)
# $result3 = $dbh->prepare( "SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '25 days';" );
# $result3->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row3 = $result3->fetchrow) { 
#   next unless ($row3[0]);
#   $result2->execute( $row3[0] );
#   my @row2 = $result2->fetchrow();
#   next unless ($row2[1]);
#   &passwordEmail( $row3[0], $row2[1], 'oldstyle' ); 
# }

# NO MORE REMINDER EMAILS 2009 09 10, no one's looking at author results anyway
# # normal reminder emails :
# $result3 = $dbh->prepare( "SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '18 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '25 days'; ");
# $result3->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row3 = $result3->fetchrow) { 
#   next unless ($row3[0]);
#   $result2->execute( $row3[0] );
#   my @row2 = $result2->fetchrow();
#   next unless ($row2[1]);
# # UNCOMMENT TO SEND REMINDER EMAILS between 18 and 25 days ago   2009 05 15
# #   &passwordEmail( $row3[0], $row2[1], 'reminder' ); 
# }


my %match_email;
my %match_paper;
my %nomatch;
my %email_emailed;
my $emailed_count = 0;
foreach my $paper (@papers) {
  next if ($already_curated{$paper});
  next if ($ignore{$paper});
  next if ($afp_passwd{$paper});
  next unless ( $has_pdf{$paper} );
  next unless ( $pap_type{$paper} );
  if ($textpresso{$paper}) { 
      my $email = $textpresso{$paper};
      $match_paper{$paper}{$email}++;
      $match_email{$email}{$paper}++; }
    else { &findVerified($paper); }
}

my $match_count = 0;

foreach my $paper (sort { $b <=> $a } keys %match_paper) {
#   next unless ($paper eq '00045092');					# to do one-of mailings, for Karen 2014 04 14
  my (@em_emails) = keys %{ $match_paper{$paper} };
#   @em_emails = ( 'azurebrd@tazendra.caltech.edu' );
  if ($pap_journal{$paper} eq 'Genetics') { @em_emails = ( 'kyook@its.caltech.edu' ); }		# send genetics papers to Karen  2009 07 24
#   if ($paper eq '00045092') { @em_emails = ('yshi@hms.harvard.edu', 'yang_shi@hms.harvard.edu', 'kyook@caltech.edu'); }	# to do one-of mailings, for Karen 2014 04 14
  push @em_emails, 'daniela.raciti@micropublication.org';
  my $emails = join ", ", @em_emails;
  print OUT "$paper has " . scalar(@em_emails) . " emails : " . $emails . "\n";
  $match_count++;
# UNCOMMENT TO SEND EMAILS AND CONNECT  2009 04 23
  if ($match_count < 51) { &passwordEmail( $paper, $emails, 'new' ); }
#   if ($match_count < 2) { &passwordEmail( $paper, $emails, 'new' ); }
} # foreach my $email (sort keys %match)

close (OUT) or die "Cannot close $outfile : $!";

# sort by emails
# foreach my $email (sort keys %match_email) {
#   my (@em_papers) = keys %{ $match_email{$email} };
#   my $papers = join ", ", @em_papers;
#   print "$email has " . scalar(@em_papers) . " papers : " . $papers . "\n";
#   $match_count += scalar(@em_papers);
# #   print "$email has " . scalar(keys %{ $match_email{$email} }) . " papers : " . join ", ", @{ keys %{ $match_email{$email} } } . "\n";
# } # foreach my $email (sort keys %match)


# uncomment to show which papers have no matches
# my $no_match_count = 0;
# foreach my $paper (sort keys %nomatch) {
#   next unless ($nomatch{$paper}{fail});		# skip if hasn't failed
#   $no_match_count++; 
#   print OUT "no match $paper";
#   if ($nomatch{$paper}{name}) { print OUT "\twith name \"$nomatch{$paper}{name}\""; }
#   if ($nomatch{$paper}{possible}) { print OUT "\tunverified by \"$nomatch{$paper}{possible}\""; }
#   if ($nomatch{$paper}{title}) { print OUT "\twith title \"$nomatch{$paper}{title}\""; }
#   print OUT "\n";
# } # foreach my $paper (sort keys %nomatch)
# print OUT "There are $match_count paper matches\n";
# print OUT "There are $no_match_count paper NO matches\n";

sub findVerified {
  my $joinkey = shift;
  $result = $dbh->prepare( "SELECT * FROM pap_title WHERE joinkey = '$joinkey' ORDER BY pap_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  unless ($result->rows == 0) { my @row = $result->fetchrow(); $nomatch{$joinkey}{title} = $row[1]; }
  $result = $dbh->prepare( "SELECT pap_author FROM pap_author WHERE joinkey = '$joinkey' ORDER BY pap_order DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  if ($result->rows == 0) { $nomatch{$joinkey}{fail}++; return; }
  my @row = $result->fetchrow(); my $aid = $row[0];
  $result = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id = '$aid' ORDER BY pap_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  if ($result->rows == 0) { $nomatch{$joinkey}{fail}++; return; }
  @row = $result->fetchrow(); 
  $nomatch{$joinkey}{name} = $row[1];
  $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id = '$aid' ORDER BY pap_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  if ($result->rows == 0) { $nomatch{$joinkey}{fail}++; return; }
  @row = $result->fetchrow(); $row[1] =~ s/two/WBPerson/;
  $nomatch{$joinkey}{possible} = $row[1];
  $result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE author_id = '$aid' AND pap_author_verified ~ 'YES';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  if ($result->rows == 0) { $nomatch{$joinkey}{fail}++; return; }
  @row = $result->fetchrow(); 
  my $pap_join = $row[2];
  $result = $dbh->prepare( "SELECT two_email FROM two_email WHERE joinkey IN (SELECT pap_author_possible FROM pap_author_possible WHERE author_id = '$aid' AND pap_join = '$pap_join');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  if ($result->rows == 0) { $nomatch{$joinkey}{fail}++; return; }
  @row = $result->fetchrow(); 
  $match_email{$row[0]}{$joinkey}++;
  $match_paper{$joinkey}{$row[0]}++;
#   print "$joinkey MATCHES $row[0]\n";
} # sub findVerified


sub passwordEmail {
  my ($paper, $email, $new_or_reminder) = @_;
  my $url = '';

  if ($new_or_reminder eq 'new') {
    my $rand = rand;
    $rand += $time;
    ($rand) = sprintf("%.7f", $rand); 
  
    my $pgcommand = "INSERT INTO afp_passwd VALUES ('$paper', '$rand');";
    $result = $dbh->do( $pgcommand );
    $pgcommand = "INSERT INTO afp_email VALUES ('$paper', '$email');";
    $result = $dbh->do( $pgcommand );
    $pgcommand = "INSERT INTO afp_passwd_hst VALUES ('$paper', '$rand');";
    $result = $dbh->do( $pgcommand );
    $pgcommand = "INSERT INTO afp_email_hst VALUES ('$paper', '$email');";
    $result = $dbh->do( $pgcommand );
    print OUT "Paper $paper Send email to $email\n\n"; 

    $url = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/first_pass.cgi?action=Curate&paper=$paper&passwd=$rand";
  }
  elsif ( ($new_or_reminder eq 'reminder') || ($new_or_reminder eq 'oldstyle') ) {
    $result = $dbh->prepare( "SELECT * FROM afp_passwd WHERE joinkey = '$paper' ORDER BY afp_timestamp DESC;;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow(); my $pass = $row[1];
    print OUT "Paper $paper Send reminder to $email\n\n"; 
    $url = "http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/first_pass.cgi?action=Curate&paper=$paper&passwd=$pass";
  }

#   my $curlOut = `curl "https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBmE-gGUGKA_lag1suXlC4uo7j2kugEufU"  -H 'Content-Type: application/json' -d '{"longUrl": "$url"}'`;
#   my ($shortUrl) = $curlOut =~ m/"id": "(.*?)",/;
# curl is giving a 403 error, switching back to full url  2019 04 15

  $result = $dbh->prepare( "SELECT * FROM pap_title WHERE joinkey = '$paper' ORDER BY pap_timestamp DESC;;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); my $title = $row[1];
  $result = $dbh->prepare( "SELECT * FROM pap_journal WHERE joinkey = '$paper' ORDER BY pap_timestamp DESC;;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  @row = $result->fetchrow(); my $journal = $row[1];
  $result = $dbh->prepare( "SELECT * FROM pap_year WHERE joinkey = '$paper' ORDER BY pap_timestamp DESC;;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  @row = $result->fetchrow(); my $year = $row[1];

  my $user = 'kyook@wormbase.org';
# COMMENT THESE OUT TO EMAIL TO PROPER AUTHORS
#   $email = 'daniela.raciti@micropublication.org';
#   $email = 'azurebrd@tazendra.caltech.edu';
#   $email = 'azurebrd@its.caltech.edu';
#   $email = 'kyook@its.caltech.edu';
  my $subject = 'Help Wormbase curate your paper';
  my $body = qq(Dear Author,<br/>
<br/>
We have identified you as the corresponding author for the recently published paper:<br/>
<br/>
"$title" $journal, $year.<br/>
<br/>
We are contacting you for help in alerting a WormBase curator to data that need to be extracted from your paper and entered into our database.<br/>
<br/>
If you would like to flag* your paper for detailed curation, please visit: <a href="$url">$url</a><br/>
*Flagging your paper involves identifying the types of data present and should take &lt;10 minutes.<br/>
<br/>
In addition, WormBase has recently launched Micropublication:biology, a peer-reviewed journal that publishes citable, single experimental results, such as those often omitted from standard journal articles due to space constraints or confirmatory or negative results. If you have such unpublished data generated during this study, we encourage you to submit it at <a href="http://bit.ly/2BcFas0">http://bit.ly/2BcFas0</a>.<br/>
<br/>
Please contact help\@wormbase.org or contact\@micropublication.org if you would like more information about flagging your paper for curation or Micropublication. <br/>
Please accept our congratulations on your publication!<br/>
Best Wishes,<br/>
WormBase<br/>);

  if ($new_or_reminder eq 'reminder') {
    $body = "Dear Author,

Sometime ago we sent you a form to ask for your help with identifying the different data-types present in your paper.
Completing this form would help us incorporate the data in WormBase.
We hope you will respond to this second request.

previous email :\n\n" . $body; }
  elsif ($new_or_reminder eq 'oldstyle') {
    $body = "Dear Author,

Sometime ago we sent you a form to ask for your help with identifying the different data-types present in your paper.
Completing this form would help us incorporate the data in WormBase.
We have changed the form to be clearer in our request of data types.
We hope you will respond to this second request.

this email links to the new form :\n\n" . $body; }

#   &mailer($user, $email, $subject, $body);	# replace Jex.pm's &mailer with this text/html version
  my $mailcommand = 'sendmail';
  my $mailer = Mail::Mailer->new($mailcommand) ;
#   print "Mail to $email\n";
  $mailer->open({ From    => $user,
                  To      => $email,
                  Subject => $subject,
                  'MIME-Version' => '1.0',
                "Content-type" => 'text/html; charset=ISO-8859-1',
                })
      or die "Can't open: $!\n";
  print $mailer $body;
  $mailer->close();
  
  $emailed_count++; 

} # sub passwordEmail

