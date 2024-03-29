#!/usr/bin/env perl

# send mass emails based on 'community_curation_source' generated by
# http://mangolassi.caltech.edu/~postgres/cgi-bin/community_curation_tracker.cgi 'Generate Mass Email File' 
# doing from cgi fails at some point, possibly from web server time out.  2018 06 21
#
# changed email link to send person's email, person id, person name to the phenotype form.  
# add paper info of up to 5 other papers for author to submit more papers.  2018 10 18
#
# skip entries without a paper or without an email.  2020 03 10
#
# for dockerizing, this requires
# /home/postgres/public_html/cgi-bin/data/community_curation/community_curation_source
# which doesn't exist on tazendra
# Also needs password from   /home/postgres/insecure/outreachwormbase
# It's been dockerized and symlinked from inside docker, but almost certainly doesn't do 
# what it needs.  2023 03 13
#
# Password file set at $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/insecure/outreachwormbase';
# 2023 03 19


use strict;
use Jex;		
use DBI;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my %twoName; my %papPmid; my %papTitle; my %papYear; my %papJournal; my %papAuthor; my %papAuthorIndex; 

&sendMassEmails();

sub sendMassEmails {
  my $max = 75;
# UNCOMMENT TO only send to one person
#   my $max = 1;

  $/ = undef;
  my $infile = '/home/postgres/public_html/cgi-bin/data/community_curation/community_curation_source';
  my $date = &getPgDate; $date =~ s/ /_/g;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $allfile = <IN>;
  close (IN) or die "Cannot close $infile : $!";
  my @lines = split/\n/, $allfile;
  my $total_count = scalar @lines;
# UNCOMMENT TO clear source file
  `mv $infile ${infile}.${date}`;
  $/ = "\n";

  $result = $dbh->prepare( "SELECT * FROM two_standardname" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $twoName{$row[0]} = $row[2]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $row[1] =~ s/pmid//; $papPmid{$row[0]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_title" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $papTitle{$row[0]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_year" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $papYear{$row[0]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_journal" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $papJournal{$row[0]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_author_index" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $papAuthorIndex{$row[0]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_order < 5" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      if ($row[2] eq '4') { $papAuthor{$row[0]}{$row[2]} = 'et al.'; }
        else { $papAuthor{$row[0]}{$row[2]} = $papAuthorIndex{$row[1]}; } } }

  my $outfile = '/home/postgres/public_html/cgi-bin/data/community_curation/community_curation_logfile.' . $date;
  my $count = 0;
  open (OUT, ">>$outfile") or die "Cannot append to $outfile : $!";
  print OUT qq(Total count of people that can be emailed $total_count.  Emailing $max.\n);
  close (OUT) or die "Cannot close $outfile : $!";
  my $toprint = qq(Total count of people that can be emailed $total_count.  Emailing $max.\n);
  foreach my $line (@lines) {
    my ($two, $email, $paper, $papers) = split/\t/, $line;
    next unless $paper;
    next unless $email;
    $count++;
    last if ($count > $max);
#     ($var, my $two)    = &getHtmlVar($query, "two_$i");
#     ($var, my $email)  = &getHtmlVar($query, "email_$i");
#     ($var, my $papers) = &getHtmlVar($query, "papers_$i");
#     my (@papers) = split/, /, $papers;
#     my $paper = $papers[0];
#     $toprint .= qq(\n$two\t$email\t$paper\t$papers\n);
    open (OUT, ">>$outfile") or die "Cannot append to $outfile : $!";
    print OUT qq(\n$two\t$email\t$paper\t$papers\n);
    close (OUT) or die "Cannot close $outfile : $!";
    my ($paperInfo) = &getPaperInfo($paper);
    my $additionalPapersInfo = '';
    my (@papers) = split/, /, $papers;
    shift @papers;
    my $paperCount = 0;
    foreach my $paper (@papers) {
      $paperCount++; last if ($paperCount > 5);
      $additionalPapersInfo .= &getPaperInfo($paper);
    }
#     print qq($paperInfo);
#     $toprint .= &sendIndividualMassEmail($paper, $two, $email, '', '', $twoName{$two}, $papPmid{$paper}, $paperInfo);
    my $emailLog = &sendIndividualMassEmail($paper, $two, $email, '', '', $twoName{$two}, $papPmid{$paper}, $paperInfo, $additionalPapersInfo);
    open (OUT, ">>$outfile") or die "Cannot append to $outfile : $!";
    print OUT $emailLog;
    close (OUT) or die "Cannot close $outfile : $!";
  } # for my $i (0 .. $total_count)
#   print qq(<a target="_blank" href="data/community_curation/community_curation_logfile.$date">logfile</a><br/>);
#   open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
# #   print $toprint;
# #   $toprint =~ s/<br\/>/\n/g;
#   print OUT $toprint;
#   close (OUT) or die "Cannot close $outfile : $!";
} # sub sendMassEmails

sub getPaperInfo {
  my ($paper) = @_;
  my $paperInfo = '';
  my @authors;
  foreach my $order (sort keys %{ $papAuthor{$paper} }) { push @authors, $papAuthor{$paper}{$order}; }
  my $authors = join ", ", @authors; 
  if ($authors) {            $paperInfo .= qq(Author(s): $authors\n);          }
  if ($papTitle{$paper}) {   $paperInfo .= qq(Title: $papTitle{$paper}\n);     }
  if ($papYear{$paper}) {    $paperInfo .= qq(Year: $papYear{$paper}\n);       }
  if ($papJournal{$paper}) { $paperInfo .= qq(Journal: $papJournal{$paper}\n); }
  if ($papPmid{$paper}) {    $paperInfo .= qq(PubMed ID: $papPmid{$paper}\n);  }
  $paperInfo .= "\n";
  return $paperInfo;
} # sub getPaperInfo

sub sendIndividualMassEmail {
  my ($paper, $two, $email, $response, $remark, $twoname, $pmid, $paperInfo, $additionalPapersInfo) = @_;
  my $additionalPaperSection = '';
  if ($additionalPapersInfo) { $additionalPaperSection = qq(Additional papers that are in need of phenotype curation are displayed below. We would greatly appreciate if you could forward this email to the relevant authors of those papers to contribute phenotypes via our form:\n\n<a href="https://wormbase.org/submissions/phenotype.cgi">https://wormbase.org/submissions/phenotype.cgi</a>\n\n$additionalPapersInfo.\n); }
  my $toprint = '';
  my $wbperson = $two; $wbperson =~ s/two/WBPerson/;
  my $pgcommand = qq(INSERT INTO com_massemail VALUES ('$paper', '$two', '$email'););
  $toprint .= qq($pgcommand\n);
# UNCOMMENT TO UPDATE postgres
  $dbh->do( $pgcommand );

#   my $emailaddress = 'closertothewake@gmail.com';
#   my $emailaddress = 'cgrove@caltech.edu';
#   my $emailaddress = 'cgrove@caltech.edu, closertothewake@gmail.com';
# UNCOMMENT TO SET RIGHT RECIPIENT
  my $emailaddress = $email;
  my $subject = 'Contribute phenotype data to WormBase';

  my $twoNameForUrl = $twoname; $twoNameForUrl =~ s/ /+/g;
  my $emailaddressForFormUrl = $email; $emailaddressForFormUrl =~ s/ /+/g; 
  my $emailaddressForUnsubscribeUrl = $emailaddressForFormUrl; $emailaddressForUnsubscribeUrl =~ s/@/AT/g;

  my $submitUrl = "https://wormbase.org/submissions/phenotype.cgi?input_1_pmid=$pmid&input_1_person=$twoNameForUrl&termid_1_person=$wbperson&input_1_email=$emailaddressForFormUrl";
  my $nophenotypeUrl = "https://wormbase.org/submissions/phenotype.cgi?action=noNematodePhenotypes&wbperson=$wbperson&name=$twoNameForUrl&pmid=$pmid&wbpaper=$paper&email=$emailaddressForUnsubscribeUrl";

  my $body = qq(Dear $twoname,\n\nIn an effort to improve WormBase's coverage of phenotypes, we are requesting your assistance to annotate nematode phenotypes from the following paper:\n\n${paperInfo}WormBase would greatly appreciate if you, or any of the other authors, could take a moment to contribute phenotype connections using our simple web-based tool:<br/>\n<a href="$submitUrl"><span style="font-size: 150%">Submit phenotypes for this paper</span></a>\n\n\n\nIf there are no nematode phenotypes in this paper click the following link:<br/>\n<a href="$nophenotypeUrl"><span style="font-size: 150%">No nematode phenotypes in this paper<span></a>\n\n\n\nIf you have any questions, comments or concerns, please let us know.\n\n${additionalPaperSection}Thank you so much!\n\nBest regards,\n\nThe WormBase Phenotype Team\n\n\n\nIf your email client does not render html links, please copy-paste the following URLs into your browser.\nSubmit phenotypes for this paper:\n$submitUrl\n\nNo nematode phenotypes in this paper:\n$nophenotypeUrl);

  $body =~ s/\n/<br\/>\n/g;


  my $sender = 'outreach@wormbase.org';
  my $replyto = 'curation@wormbase.org';
  my $email = Email::Simple->create(
    header => [
        From       => 'outreach@wormbase.org',
        'Reply-to' => 'curation@wormbase.org',
        To         => "$emailaddress",
        Subject    => "$subject",
        'Content-Type' => 'text/html', 
    ],
    body => "$body",
  );
  $body =~ s/\n/ /g;
  $toprint .= qq(send email to $emailaddress\nfrom $sender\nreplyto $replyto\nsubject $subject\nbody $body\n);

  my $passfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/insecure/outreachwormbase';
  # my $passfile = '/home/postgres/insecure/outreachwormbase';
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

  return $toprint;
} # sub sendIndividualMassEmail
