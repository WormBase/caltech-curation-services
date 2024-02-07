#!/usr/bin/env perl

# Track community curation
#
# * PDF links
# * WBPaper ID
# * PubMed ID (WBPaper00001435 is the only example I could find that has two PMIDs and either, or both, is fine)
# * First author Name (if available)
# * First Author WBPerson ID (if available)
# * First Author Email (if available)
# * Corresponding Author(s) Name (pending a new method, yes)
# * Corresponding Author(s) WBPerson ID (pending a new method, yes)
# * Corresponding Author(s) Email(s) (pending a new method, yes)
# * Date e-mailed for allele-phenotype (if at all) (eventually automated by standardized e-mail, but for now could use the "E-mail Sent" button on the filter page, as I mentioned above)
# * E-mail response, free text, manually entered
# * Form response (timestamp or yes/no), automated, meaning someone has made an entry in the Allele-Phenotype form for this paper (could check Phenotype OA for entry for that paper where curator is "Community Curator")
# * Remark, free text
#
# http://wiki.wormbase.org/index.php/Contacting_the_Community

# com_app_emailsent 
# com_app_emailresponse 
# com_app_remark 
# com_app_skip

# Live at some point by 2015 11 20 
# 
# Added skip tables, and looking at  pap_author_corresponding  for Chris and Ranjana.  2015 12 07
#
# new mutant tracker separate column for rnai.  2016 01 19
#
# changed links to www.wormbase.org/submissions  2016 02 10
#
# tracker should map email addresses to WBPerson IDs for Chris.  2016 02 18
#
# emails for newmutant link to phenotype form with pgid field.  2016 02 21
#
# changed newmutant email a bit for Chris.  2016 03 01
#
# changed recent-ness interval to 1 month for Chris.  2016 05 20
#
# skip papers that have been recently emailed to corresponding authors.
# This was an oversight, should have been happening already.  2016 08 22
#
# remove papers that have been curated for RNAi for Chris.  2016 08 23
#
# No longer require papers to have been AFPed first, nor filter out emails that have been AFPed in the last month.
# No longer look at corresponding author data.  If there's a first author, just email the first author.  2017 07 31
#
# Mass email batches of people in repeatable way according to. 
# https://docs.google.com/document/d/1OW-qteWy_ANLVgm0wdEii6g8qtaebb4qsLjf2IEBQPM/edit
# Keep log of emails sent to authors.  2018 06 20
#
# input/textarea fields's ids for remark and response should also key off of timestamp since papers are no longer unique.  
# javascript escape user values so that special characters go through.  2018 06 27
#
# skip papers that have been recently emailed, not just people that have been recently emailed.  2018 06 28
#
# send mass emails stuff apparently didn't work for some reason, so it's running from 
#   /home/postgres/public_html/cgi-bin/data/community_curation/generate_community_curation_emails.pl
# after clicking 'Generate Mass Email File'  
# when sending mass email, skip all papers that have ever been mass emailed.  2018 10 18
#
# added com_ table filtering to massEmails.  2019 01 28
# 
# Some papers should map to a specific person that wouldn't be captured by the systerm, so
# if there's a manual override, use the one that Chris sets.  2019 06 05
#
# Add text output for &tracker for New Mutant and Concise Description, for Chris.  2020 02 24
#
# Skip emails found in Email_addresses_to_omit.txt  2020 03 09
#
# Skip emails and persons from frm_ postgres tables instead of txt files.  2020 03 23
#
# Only get pap_type that is 1 but not in paper that has 26 (micropublication)  2020 03 28
#
# Ranjana no longer needs to track concise descriptions through here.  2021 01 29
#
# pdf_email created in postgres to stop using obsolete
# http://tazendra.caltech.edu/~postgres/out/email_pdf_afp
# which is not going to be supported by textpresso-dev data anymore.  2021 02 04
#
# Password file set at $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/insecure/outreachwormbase';
# 2023 03 19
#
# Data wasn't getting generated because trying to access curation_status form on tazendra
# without access, now gets it from local curation status form and data works.  File generation
# for mass emails saves to /usr/caltech_curation_files/priv/community_curation/community_curation_source
# which can be viewed in a browser at 
# https://caltech-curation-dev.textpressolab.com/files/priv/community_curation/community_curation_source
# (based on ENV variables).
# Links to PDFs still use tazendra, which won't be maintained in the future, but need 
# feedback on whether to update to point to ABC.  2023 05 12



use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate mailer
use LWP::UserAgent;	# getting sanger files for querying
use LWP::Simple;	# get the PhenOnt.obo from a cgi
use DBI;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;
use Tie::IxHash;
use Dotenv -load => '/usr/lib/.env';

my %curator;

my $query = new CGI;	# new CGI form
my $result;
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";

my $thishost = $ENV{THIS_HOST};

# my $curation_status_url = 'http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi';
my $curation_status_url = $thishost . 'priv/cgi-bin/curation_status.cgi';	# dockerized

my $filesPath = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/priv/community_curation/';

sub printHtmlHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<HEAD>
<LINK rel="stylesheet" type="text/css" href="$ENV{THIS_HOST_AS_BASE_URL}pub/stylesheets/wormbase.css">
<title>Community Curation Tracker</title>
  <script type="text/javascript" src="js/jquery-1.9.1.min.js"></script>
  <script type="text/javascript" src="js/jquery.tablesorter.min.js"></script>
  <script type="text/javascript">\$(document).ready(function() { \$("#sortabletable").tablesorter(); } );</script>
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
</body></html>

EndOfText
} # sub printHtmlHeader


# &printHeader('Community Curation Tracker');
&process();

sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { $action = ''; }
  if ($action eq '') { &printHtmlMenu(); }		# Display form, first time, no action
  else { 						# Form Button
    if ($action eq 'Mass Email Tracker') { 1; }
      elsif ($action eq 'New Mutant Tracker') { 1; }
#       elsif ($action eq 'Concise Description Tracker') { 1; }
      else { 
        &printHtmlHeader();
        print qq(ACTION : $action : ACTION <a href="community_curation_tracker.cgi">start over</a><br/>\n); 
      }

    if ($action eq 'New Mutant Ready') {                 &readyToGo('app');         }
      if ($action eq 'New Mutant Tracker') {             &tracker('app');           }
#       elsif ($action eq 'Concise Description Ready') {   &readyToGo('con');         }	
#       elsif ($action eq 'Concise Description Tracker') { &tracker('con');           }	
      elsif ($action eq 'generate email') {              &generateEmail();          }
      elsif ($action eq 'skip paper') {                  &skipPaper();              }
      elsif ($action eq 'send email') {                  &sendEmail();              }
      elsif ($action eq 'ajaxUpdate') {                  &ajaxUpdate();             }
      elsif ($action eq 'Mass Email') {                  &massEmail();              }
#       elsif ($action eq 'Send Mass Emails') {            &sendMassEmails();         }
      elsif ($action eq 'Generate Mass Email File') {    &generateMassEmailFile();  }
      elsif ($action eq 'Mass Email Tracker') {          &massEmailTracker();       }
#       elsif ($action eq 'Mass Email Tracker') {          &massEmailTracker('html'); }
#       elsif ($action eq 'Mass Email Tracker Text') {     &massEmailTracker('text'); }
#     print "ACTION : $action : ACTION<BR>\n"; 
  } # else # if ($action eq '') { &printHtmlForm(); }
  if ($action eq 'Mass Email Tracker') { 1; }
    elsif ($action eq 'New Mutant Tracker') { 1; }
#     elsif ($action eq 'Concise Description Tracker') { 1; }
    else { &printFooter(); }
} # sub process

sub massEmail {
#   my $debugPaper = '00003469';
  my $debugPaper = '';

  my %flagged;
  my $flaggedRnaiUrl = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=rnai&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  my $dataFlaggedRnai = get $flaggedRnaiUrl;
  my (@papers) = $dataFlaggedRnai =~ m/specific_papers=WBPaper(\d+)/g;
  foreach (@papers) { 
    if ($_ eq $debugPaper) { print qq(PAP $_ FLAGGED RNAI URL $flaggedRnaiUrl <br>\n); }
    $flagged{$_}{rnai}++; }
  my $flaggedNmutUrl = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=newmutant&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on'; 
  my $dataFlaggedNmut = get $flaggedNmutUrl;
  (@papers) = $dataFlaggedNmut =~ m/specific_papers=WBPaper(\d+)/g;
  foreach (@papers) { 
    if ($_ eq $debugPaper) { print qq(PAP $_ FLAGGED NMUT URL $flaggedNmutUrl <br>\n); }
    $flagged{$_}{nmut}++; }

  my $valNegativeRnaiUrl   = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=rnai&method=allval%20neg&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  my $dataCurated = get $valNegativeRnaiUrl;
  (@papers) = $dataCurated =~ m/specific_papers=WBPaper(\d+)/g;
  foreach (@papers) { 
    if ($_ eq $debugPaper) { print qq(PAP $_ VALIDATED NEGATIVE RNAI URL $valNegativeRnaiUrl <br>\n); }
    delete $flagged{$_}{rnai}; }
  my $valNegativeNmutUrl   = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=newmutant&method=allval%20neg&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  my $dataCurated = get $valNegativeNmutUrl;
  (@papers) = $dataCurated =~ m/specific_papers=WBPaper(\d+)/g;
  foreach (@papers) { 
    if ($_ eq $debugPaper) { print qq(PAP $_ VALIDATED NEGATIVE NMUT URL $valNegativeNmutUrl <br>\n); }
    delete $flagged{$_}{nmut}; }

  my %curated;
  my @urlsRnai; my @urlsNmut;
#   my $curatedRnaiUrl = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=rnai&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
#     my $dataCuratedRnai = get $curatedRnaiUrl;
#     (@papers) = $dataCuratedRnai =~ m/specific_papers=WBPaper(\d+)/g;
#     foreach (@papers) { $curated{$_}++; }
#   my $curatedNmutUrl = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=newmutant&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
#   my $dataCuratedNmut = get $curatedNmutUrl;
#   (@papers) = $dataCuratedNmut =~ m/specific_papers=WBPaper(\d+)/g;
#   foreach (@papers) { $curated{$_}++; }
  my $curatedValPosRnaiUrl = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=rnai&method=allval%20pos%20cur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  my $valConflictRnaiUrl   = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=rnai&method=allval%20conf&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  push @urlsRnai, $curatedValPosRnaiUrl; push @urlsRnai, $valConflictRnaiUrl;
  foreach my $url (@urlsRnai) {
    my $dataCurated = get $url;
    (@papers) = $dataCurated =~ m/specific_papers=WBPaper(\d+)/g;
    foreach (@papers) { 
      if ($_ eq $debugPaper) { print qq(PAP $_ CURATED RNAI URL $url <br>\n); }
      $curated{$_}{rnai}++; }
  }

  my $curatedValPosNmutUrl = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two2987&listDatatype=newmutant&method=allval%20pos%20cur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  my $valConflictNmutUrl   = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two1823&listDatatype=newmutant&method=allval%20conf&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
  push @urlsNmut, $curatedValPosNmutUrl; push @urlsNmut, $valConflictNmutUrl;
  foreach my $url (@urlsNmut) {
    my $dataCurated = get $url;
    (@papers) = $dataCurated =~ m/specific_papers=WBPaper(\d+)/g;
    foreach (@papers) { 
      if ($_ eq $debugPaper) { print qq(PAP $_ CURATED NMUT URL $url <br>\n); }
      $curated{$_}{nmut}++; }
  }

    # community curated papers that don't necessarily show up in curation status form (which excludes community curated as being 'curated')
  $result = $dbh->prepare( "SELECT DISTINCT(app_paper) FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_curator WHERE app_curator = 'WBPerson29819')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[0]) { $row[0] =~ s/WBPaper//; $curated{$row[0]}{nmut}++; } }
  $result = $dbh->prepare( "SELECT DISTINCT(rna_paper) FROM rna_paper WHERE joinkey IN (SELECT joinkey FROM rna_curator WHERE rna_curator = 'WBPerson29819')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[0]) { $row[0] =~ s/WBPaper//; $curated{$row[0]}{rnai}++; } }

  my %com;
  $result = $dbh->prepare( "SELECT * FROM com_app_skip" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $com{$row[0]}{skip} = $row[1]; } }
# no longer care about old pipeline for individual emails  2019 02 01
#   $result = $dbh->prepare( "SELECT * FROM com_app_emailsent" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { 
#       $com{$row[0]}{date}  = $row[2]; 
#       $com{$row[0]}{email} = $row[1]; } }

  my %pap;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{valid}++; } }
# not important for Chris.  2018 06 01
#   $result = $dbh->prepare( "SELECT * FROM pap_pubmed_final WHERE pap_pubmed_final = 'final'" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $pap{$row[0]}{pubmedfinal}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '1' AND joinkey NOT IN (SELECT joinkey FROM pap_type WHERE pap_type = '26')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{journalarticle}++; } }
#   $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $row[1] =~ s/pmid//; $pap{$row[0]}{pmid}{$row[1]}++; } }
#   $result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $pap{$row[0]}{pdf}{$row[1]}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_primary_data WHERE pap_primary_data = 'primary';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{primary}++; } }


  my %omitPerson;
  my %omitEmail;
#   my $omitPersonFile = '/home/postgres/public_html/cgi-bin/data/community_curation/WBPersons_to_omit.txt';
#   if (-e $omitPersonFile) {
#     open (IN, "<$omitPersonFile") or die "Cannot open $omitPersonFile : $!";
#     while (my $line = <IN>) { chomp $line; $omitPerson{$line}++; }
#     close (IN) or die "Cannot close $omitPersonFile : $!"; }
#   my $omitEmailFile = '/home/postgres/public_html/cgi-bin/data/community_curation/Email_addresses_to_omit.txt';
#   if (-e $omitEmailFile) {
#     open (IN, "<$omitEmailFile") or die "Cannot open $omitEmailFile : $!";
#     while (my $line = <IN>) { chomp $line; my $lcemail = lc($line); $omitEmail{$lcemail}++; }
#     close (IN) or die "Cannot close $omitEmailFile : $!"; }
  $result = $dbh->prepare( "SELECT * FROM frm_wbperson_skip ;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $omitPerson{$row[0]}++; } }
  $result = $dbh->prepare( "SELECT * FROM frm_email_skip ;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my $lcemail = lc($row[0]); $omitEmail{$lcemail}++; } }


  my %two;
  $result = $dbh->prepare( "SELECT * FROM two_standardname" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $two{name}{$row[0]} = $row[2]; } }
  my %twoEmail;
  $result = $dbh->prepare( "SELECT * FROM two_email ORDER BY joinkey, two_order" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[2] =~ s/\s//g; 
      my $email = lc($row[2]);
      next if ($omitEmail{$email});
      push @{ $twoEmail{$row[0]} }, $row[2]; } }
  my %twoRecentSent;
  $result = $dbh->prepare( "SELECT * FROM com_massemail WHERE com_timestamp > current_date - interval '3 months'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { $twoRecentSent{$row[1]}++; $pap{$row[0]}{recent}++; } }
#   $result = $dbh->prepare( "SELECT * FROM com_massemail" );	# for now always skip all papers that have been emailed.  2018 10 18
  $result = $dbh->prepare( "SELECT * FROM com_massemail WHERE com_timestamp > current_date - interval '6 months'" );	# skip papers emailed more than 6 months ago.  2019 02 01
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { $pap{$row[0]}{hasBeenEmailed}++; } }

  my %filter;
  foreach my $pap (sort keys %flagged) {
    if ($pap eq $debugPaper) { print qq(PAP FLAGGED NMUT $flagged{$pap}{nmut} END<br>\n); }
    if ($pap eq $debugPaper) { print qq(PAP FLAGGED RNAI $flagged{$pap}{rnai} END<br>\n); }
    next unless ($flagged{$pap}{nmut} || $flagged{$pap}{rnai});
    if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED<br>\n); }

# thought needed to still email if curated for one type but not the other, but don't mail if curated for either
#     my $needsCuration = 0;
#     if ($flagged{$pap}{rnai}) { 
# if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED RNAI<br>\n); }
#       unless ($curated{$pap}{rnai}) { 
# if ($pap eq $debugPaper) { print qq(PAP $pap NEEDS CURATION RNAI<br>\n); }
#         $needsCuration++; } }
#     if ($flagged{$pap}{nmut}) { 
# if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NMUT<br>\n); }
#       unless ($curated{$pap}{nmut}) { 
# if ($pap eq $debugPaper) { print qq(PAP $pap NEEDS CURATION NMUT<br>\n); }
#         $needsCuration++; } }
#     next unless $needsCuration;

    next if ($curated{$pap});
    if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NOT CURATED<br>\n); }
    next unless ($pap{$pap}{valid});
    if ($pap eq $debugPaper) { print qq(PAP $pap VALID<br>\n); }
    next if ($pap{$pap}{recent});
    if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NOT RECENT<br>\n); }
    next if ($pap{$pap}{hasBeenEmailed});
     if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NOT BEEN EMAILED<br>\n); }
    next if ($com{$pap}{skip}); 		# already flagged to skip in com_<datatype>_skip
    if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NOT SKIP<br>\n); }
# no longer care about old pipeline for individual emails  2019 02 01
#     next if ($com{$pap}{email});		# already emailed in com_<datatype>_emailsent
    if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NOT EMAIL<br>\n); }
#     next unless ($pap{$pap}{pubmedfinal});	# not important for Chris.  2018 06 01
    next unless ($pap{$pap}{journalarticle});
    next unless ($pap{$pap}{primary});
    if ($pap eq $debugPaper) { print qq(PAP $pap FLAGGED NOT PRIMARY<br>\n); }
    $filter{$pap}++; }

  my %email;

# Old way of getting pdf's emails from flatfile that's no longer being maintained.  2021 02 04
#   my $pdfEmailUrl = 'http://tazendra.caltech.edu/~postgres/out/email_pdf_afp';
#   my $pdfEmailFile = get $pdfEmailUrl;
#   my (@lines) = split/\n/, $pdfEmailFile;
#   foreach my $line (@lines) {
# #     my ($pap, $email, $afpEmail, $source) = split/\t/, $line;
#     my ($pap, $email) = split/\t/, $line;
#     my $lcemail = lc($email);
#     next if ($omitEmail{$lcemail});
#     $email{pdf}{$pap} = $email; }
  $result = $dbh->prepare( "SELECT * FROM pdf_email WHERE pdf_email IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[1]); $email{pdf}{$row[0]} = $lcemail; } }
  
  $result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_email IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[1]); next if ($omitEmail{$lcemail}); $email{afp}{$row[0]} = $lcemail; } }
  $result = $dbh->prepare( "SELECT * FROM two_email" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[2]); $lcemail =~ s/\s//g; next if ($omitEmail{$lcemail}); $email{two}{$lcemail} = $row[0]; } }
#   $result = $dbh->prepare( "SELECT * FROM two_old_email" );
  $result = $dbh->prepare( "SELECT * FROM two_old_email WHERE joinkey IN (SELECT joinkey FROM two_email)" );	# only get old email of people we have an email  2018 05 15
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[2]); $lcemail =~ s/\s//g; next if ($omitEmail{$lcemail}); $email{old}{$lcemail} = $row[0]; } }
  
  my %aids;
  my $joinkeys = join"','", sort keys %filter;
  $result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey IN ('$joinkeys') ORDER BY pap_order::INTEGER DESC;" );	# get most recent aid last for loop
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{aid}{$row[2]} = $row[1]; $aids{$row[1]}{any}++; } }
  my $aids = join"','", sort {$a<=>$b} keys %aids;
  $result = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id IN ('$aids');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $aids{$row[0]}{name} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id IN ('$aids');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ( ($row[1]) && ($row[0]) ) { 
      next unless ($twoEmail{$row[1]});
      $aids{$row[0]}{two}{$row[2]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE author_id IN ('$aids') AND pap_author_verified ~ 'YES';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $aids{$row[0]}{ver} = $row[2]; } }
# Chris no longer wants corresponding author data looked at  2017 07 17
#   $result = $dbh->prepare( "SELECT * FROM pap_author_corresponding WHERE author_id IN ('$aids');" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { 
#       $aids{$row[0]}{cor} = $row[1]; } }
    
#   my $countThreshold = 100;
#   print qq(Showing most recent $countThreshold entries<br/>\n);
#   print qq(<table style="border-style: none;" border="1" >\n);

  my %bestTwoOverride; 
  $bestTwoOverride{'00055999'} = 'two342';
  
  my %papersByTwo;
  my %paperMultTwo;
  my %personToName;
  my %personToEmail;

  print qq(<table style="border-style: none;" border="1">);
  my $header = qq(<tr><th>ID</th><th>valid</th><th>journalarticle</th><th>primary</th><th>good</th><th>bestTwo</th><th>person</th><th>name</th><th>email</th><th>first author initials</th><th>first author's person name</th><th>first author's person id</th><th>first author's person emails</th><th>corresponding author name</th><th>corresponding person</th><th>corresponding email</th><th>afp author name</th><th>afp person</th><th>afp email</th><th>pdf author name</th><th>pdf person</th><th>pdf email</th></tr>);
#   my $header = qq(<tr><th>generate</th><th>skip</th><th>WBPaper</th><th>pmids</th><th>pdfs</th><th>first author initials</th><th>first author's person name</th><th>first author's person id</th><th>first author's person emails</th><th>corresponding author name</th><th>corresponding person</th><th>corresponding email</th><th>afp author name</th><th>afp person</th><th>afp email</th><th>pdf author name</th><th>pdf person</th><th>pdf email</th></tr>\n); 
  print $header;
  my $count = 0;
  foreach my $pap (reverse sort keys %filter) {
#   foreach my $pap (sort keys %flagged)
#     my $pmids = join", ", sort keys %{ $pap{$pap}{pmid} };
#     my @pdfs;
#     foreach my $path (sort keys %{ $pap{$pap}{pdf} }) {
#       my ($pdfname) = $path =~ m/\/([^\/]*?)$/;
#       my $url = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdfname;
#       my $link = qq(<a href='$url' target='new'>$pdfname</a>);
#       push @pdfs, $link; }
#     my $pdfs = join" ", @pdfs;
#     my $recentlyEmailed = 0;
    my %bestTwo;
    my ($two, $personName, $person, $emails) = ('', '', '', '');
    my $aidFirstAuthor = ''; if ($pap{$pap}{aid}{1}) { $aidFirstAuthor = $pap{$pap}{aid}{1}; }
# if ($pap eq '00046127') { print "AFA $aidFirstAuthor PAP $pap E<br>"; }
    my @cEmails; my @cTwos; my @cNames;
    my ($cEmail, $cTwo, $cName) = ('', '', '');	# generate from afp_email the person id and name
    foreach my $order (sort {$a<=>$b} keys %{ $pap{$pap}{aid} }) {
# if ($pap eq '00046127') { print "ORDER $order PAP $pap E<br>"; }
      my $aid = $pap{$pap}{aid}{$order};
# if ($pap eq '00046127') { print "ORDER $order AID $aid PAP $pap E<br>"; }
      if ($aids{$aid}{ver}) {
        my $join = $aids{$aid}{ver}; 
# if ($pap eq '00046127') { print "VER JOIN $join ORDER $order AID $aid PAP $pap E<br>"; }
        if ($aids{$aid}{two}{$join}) {
# if ($pap eq '00046127') { print "AID two $aid HERE<br>"; }
          if ($aid eq $aidFirstAuthor) {
# if ($pap eq '00046127') { print "AID AFA $aid HERE<br>"; }
            $two         = $aids{$aid}{two}{$join};
            $bestTwo{$two}++;				# THIS
            $personName  = $two{name}{$two}; 
            $person      = $two; $person =~ s/two/WBPerson/;
            $emails      = join", ", @{ $twoEmail{$two} }; }
#           if ($recentpeople{$two}) { $recentlyEmailed++; }
          if ($aids{$aid}{cor}) {
            my $cTwo         = $aids{$aid}{two}{$join};
            unless (%bestTwo) { $bestTwo{$cTwo}++; }				# THIS
            my $cPersonName  = $two{name}{$cTwo}; 
            my $cEmails      = join", ", @{ $twoEmail{$cTwo} };
#             if ( !($emails) && ($recentpeople{$cTwo}) )  { $recentlyEmailed++; }	# if corresponding person was recently emailed and there is no fa->person->email, skip the row  2017 08 03
            push @cEmails, $cEmails;
            push @cTwos,   $cTwo;
            push @cNames,  $cPersonName;
          }
        }
      }
    }
    if ($bestTwoOverride{$pap}) {			# if there's a manual override, use the one that Chris sets.  2019 06 05
      $two = $bestTwoOverride{$pap};
      $bestTwo{$two}++;	
      $personName  = $two{name}{$two}; 
      $person      = $two; $person =~ s/two/WBPerson/;
      $emails      = join", ", @{ $twoEmail{$two} };
    } 
    $cEmail = join", ", @cEmails;
    $cTwo   = join", ", @cTwos;
    $cName  = join", ", @cNames;
# if ($pap eq '00046127') { print qq(PAP $pap CEM $cEmail E<br>); }
    my %categories;
    $categories{good}{color} = 'black';
    $categories{old}{color}  = 'orange';
    $categories{bad}{color}  = 'red';
    my ($afpEmail, $afpTwo, $afpName) = ('', '', '');	# generate from afp_email the person id and name
    my ($pdfEmail, $pdfTwo, $pdfName) = ('', '', '');	# generate from pdf extraction
    unless ($cEmail) {
      if ($email{afp}{$pap}) {
        my %twos; my %emails;
        my @emails; my @twos; my @names; my @bestTwos;
        my (@afpemails) = split/\s+/, $email{afp}{$pap};
        foreach my $afpemail (@afpemails) {
          next if ($afpemail =~ m/micropublication.org/);
          my ($two, $name) = ('', '');
          $afpemail =~ s/,//g;
#           if ($recentemail{email}{afp}{$afpemail}) { $recentlyEmailed++; }	# to filter by emails recently emailed
#           if ($recentemail{email}{app}{$afpemail}) { $recentlyEmailed++; }	# to filter by emails recently emailed
#           if ($recentemail{email}{con}{$afpemail}) { $recentlyEmailed++; }	# to filter by emails recently emailed
          if ($email{two}{$afpemail}) {
              $two   = $email{two}{$afpemail}; 
#               if ( !($emails) && ($recentemail{email}{app}{$afpemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check afpemail has not been emailed recently for this pipeline
              $emails{good}{$afpemail} = $two; 
              $twos{good}{$two}++; }
            elsif ($email{old}{$afpemail}) {
              $two   = $email{old}{$afpemail}; 
#               if ( !($emails) && ($recentemail{email}{app}{$afpemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check afpemail has not been emailed recently for this pipeline
              $emails{old}{$afpemail} = $two; 
              $twos{old}{$two}++; }
            else {
              $emails{bad}{$afpemail} = 'nowbperson'; }
        }
        foreach my $afpemail (@afpemails) {
          $afpemail =~ s/,//g;
          foreach my $category (sort keys %categories) {
            my $color = $categories{$category}{color} || 'yellow';
            if ($emails{$category}{$afpemail}) {
              my $two = $emails{$category}{$afpemail} || ''; push @emails, qq(<span style='color: $color'>$afpemail</span>);
              if ($two ne 'nowbperson') {
                push @bestTwos, $two;
                my $wbperson = $two; $wbperson =~ s/two/WBPerson/g; push @twos, qq(<span style='color: $color'>$wbperson</span>);
                if ($two{name}{$two}) { push @names, qq(<span style='color: $color'>$two{name}{$two}</span>);} } } } }
        unless (%bestTwo) { foreach (@bestTwos) { $bestTwo{$_}++; } }
        $afpEmail = join", ", @emails;
        $afpTwo   = join", ", @twos;
        $afpName  = join", ", @names;
      }
      if ($email{pdf}{$pap}) {
        my %twos; my %emails;
        my @emails; my @twos; my @names; my @bestTwos;
        my (@pdfemails) = split/\s+/, $email{pdf}{$pap};
        foreach my $pdfemail (@pdfemails) {
          my ($two, $name) = ('', '');
          $pdfemail =~ s/,//g;
          if ($email{two}{$pdfemail}) {
              $two   = $email{two}{$pdfemail}; 
#               if ( !($emails) && ($recentemail{email}{app}{$pdfemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check pdfemail has not been emailed recently for this pipeline
              $emails{good}{$pdfemail} = $two; 
if ($pap eq '00060032') { print "GOOD $pdfemail TWO $two PAP $pap E<br>"; }
              $twos{good}{$two}++; }
            elsif ($email{old}{$pdfemail}) {
              $two   = $email{old}{$pdfemail}; 
#               if ( !($emails) && ($recentemail{email}{app}{$pdfemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check pdfemail has not been emailed recently for this pipeline
              $emails{old}{$pdfemail} = $two; 
              $twos{old}{$two}++; }
            else {
              $emails{bad}{$pdfemail} = 'nowbperson'; }
        }
        foreach my $pdfemail (@pdfemails) {
          $pdfemail =~ s/,//g;
          foreach my $category (sort keys %categories) {
            my $color = $categories{$category}{color} || 'yellow';
            if ($emails{$category}{$pdfemail}) {
              my $two = $emails{$category}{$pdfemail} || ''; push @emails, qq(<span style='color: $color'>$pdfemail</span>);
              if ($two ne 'nowbperson') {
                push @bestTwos, $two;
                my $wbperson = $two; $wbperson =~ s/two/WBPerson/g; push @twos, qq(<span style='color: $color'>$wbperson</span>);
                if ($two{name}{$two}) { push @names, qq(<span style='color: $color'>$two{name}{$two}</span>);} } } } }
        unless (%bestTwo) { foreach (@bestTwos) { $bestTwo{$_}++; } }
        $pdfEmail = join", ", @emails;
        $pdfTwo   = join", ", @twos;
        $pdfName  = join", ", @names;
      }
    }
    print qq(<tr><td>$pap</td>);
#     print qq(<td>$curated{$pap}</td>);
    print qq(<td>$pap{$pap}{valid}</td>);
#     print qq(<td>$pap{$pap}{pubmedfinal}</td>);
    print qq(<td>$pap{$pap}{journalarticle}</td>);
    print qq(<td>$pap{$pap}{primary}</td>);
    my $good = 0;
    if (!($curated{$pap}) && ($pap{$pap}{valid}) && ($pap{$pap}{journalarticle}) && ($pap{$pap}{primary})) {
      $good = 'good'; }
    print qq(<td>$good</td>);
    my $bestTwo = join", ", sort keys %bestTwo;
    print qq(<td>$bestTwo</td>);
    my $name = ''; my $email = ''; my $two;
    if ($personName) {   $name = $personName; $email = $emails;   $two = $person;  $personToName{$two}{1} = $name; $personToEmail{$two}{1} = $email; }
      elsif ($cName) {   $name = $cName;      $email = $cEmail;   $two = $cTwo;    $personToName{$two}{2} = $name; $personToEmail{$two}{2} = $email; }
      elsif ($afpName) { $name = $afpName;    $email = $afpEmail; $two = $afpTwo;  $personToName{$two}{3} = $name; $personToEmail{$two}{3} = $email; }
      elsif ($pdfName) { $name = $pdfName;    $email = $pdfEmail; $two = $pdfTwo;  $personToName{$two}{4} = $name; $personToEmail{$two}{4} = $email; }
    my $wbperson = $two; if ($two =~ m/(WBPerson\d+)/) { $wbperson = $1; }
    if ($omitPerson{$wbperson}) { print qq(<td>OMIT $two </td>); }
      else { print qq(<td>$two</td>); }
    print qq(<td>$name</td>);
    print qq(<td>$email</td>);
    print qq(<td>$aids{$aidFirstAuthor}{name}\t</td><td>$personName\t</td><td>$person\t</td><td>$emails\t</td><td>$cName</td><td>$cTwo</td><td>$cEmail</td><td>$afpName</td><td>$afpTwo</td><td>$afpEmail</td><td>$pdfName</td><td>$pdfTwo</td><td>$pdfEmail</td></tr>);
    next if ($omitPerson{$wbperson});
#     $papersByTwo{twos}{$two}{$pap}++;
#     $papersByTwo{count}{$two}++;
    if (scalar keys %bestTwo > 1) { 
#       print qq(<tr><td>MULTIPLE</td><td>); print keys %bestTwo; print qq(</td></tr>\n);
        foreach my $two (keys %bestTwo) {
          $paperMultTwo{$pap}{$two}++; } }
      else {
        foreach my $two (keys %bestTwo) {
          $papersByTwo{twos}{$two}{$pap}++;
          $papersByTwo{count}{$two}++; } }
  }
  print qq(</table>);


  foreach my $pap (sort keys %paperMultTwo) {
#     print qq(P $pap P<br/>);
    my $best = '';
    my $least = 100000000;
    foreach my $two (sort keys %{ $paperMultTwo{$pap} }) {
      my $count = $papersByTwo{count}{$two};
      if ($count < $least) { $least = $count; $best = $two; }
    } # foreach my $two (sort keys %{ $paperMultTwo{$pap} })
    $papersByTwo{twos}{$best}{$pap}++;
    $papersByTwo{count}{$best}++;
  }
  

  print qq(<form method="post" action="community_curation_tracker.cgi"\n>);
  my $counter = 0;
  print qq(<br/>People by Papers :<br/>\n);
  print qq(<table style="border-style: none;" border="1">);
  foreach my $two (sort { $papersByTwo{count}{$b} <=> $papersByTwo{count}{$a} } keys %{ $papersByTwo{count} }) {
    next unless $two;
    next if ($twoRecentSent{$two}); 			# skip people that have been emailed recently

    my $count = $papersByTwo{count}{$two};
    my $papers = join", ", reverse sort keys %{ $papersByTwo{twos}{$two} };
    my $name   = $two{name}{$two};
    my $email  = 'noemail';
    if ($twoEmail{$two}) { $email = join", ", @{ $twoEmail{$two} }; }
      else { next; }
    $counter++;

#     if ($personToName{$two}{1}) {        $name = $personToName{$two}{1};   }
#       elsif ($personToName{$two}{2}) {   $name = $personToName{$two}{2};   }
#       elsif ($personToName{$two}{3}) {   $name = $personToName{$two}{3};   }
#       elsif ($personToName{$two}{4}) {   $name = $personToName{$two}{4};   }
#     if ($personToEmail{$two}{1}) {      $email = $personToEmail{$two}{1};  }
#       elsif ($personToEmail{$two}{2}) { $email = $personToEmail{$two}{2};  }
#       elsif ($personToEmail{$two}{3}) { $email = $personToEmail{$two}{3};  }
#       elsif ($personToEmail{$two}{4}) { $email = $personToEmail{$two}{4};  }
    print qq(<tr><td>$two</td><td>$name</td><td>$email</td><td>$count</td><td>$papers</td></tr>\n);
    print qq(<input type="hidden" name="two_$counter" value="$two">\n);
    print qq(<input type="hidden" name="email_$counter" value="$email">\n);
    print qq(<input type="hidden" name="papers_$counter" value="$papers">\n);
  }

#   print qq(<table style="border-style: none;" border="1">);
#   print qq(<tr><td>ID</td><td>curated</td><td>valid</td><td>pubmedfinal</td><td>journalarticle</td><td>primary</td><td>good</td></tr>);
#   foreach my $pap (sort keys %flagged) {
#     print qq(<tr><td>$pap</td>);
#     print qq(<td>$curated{$pap}</td>);
#     print qq(<td>$pap{$pap}{valid}</td>);
#     print qq(<td>$pap{$pap}{pubmedfinal}</td>);
#     print qq(<td>$pap{$pap}{journalarticle}</td>);
#     print qq(<td>$pap{$pap}{primary}</td>);
# #     next if ($curated{$pap});
# #     next unless ($pap{$pap}{valid});
# #     next unless ($pap{$pap}{pubmedfinal});
# #     next unless ($pap{$pap}{journalarticle});
# #     next unless ($pap{$pap}{primary});
#     my $good = 0;
#     if (!($curated{$pap}) && ($pap{$pap}{valid}) && ($pap{$pap}{pubmedfinal}) && ($pap{$pap}{journalarticle}) && ($pap{$pap}{primary})) {
#       $good = 'good'; }
#     print qq(<td>$good</td>);
#     print qq(</tr>);
#   } # foreach my $pap (sort keys %flagged)
  print qq(</table>);
  print qq(<input type="hidden" name="total_count" value="$counter">\n);
#   print qq(<input type="submit" name="action" value="Send Mass Emails">\n);
  print qq(<input type="submit" name="action" value="Generate Mass Email File">\n);
  print qq(</form>);
} # sub massEmail

sub generateMassEmailFile {
  # my $outfile = '/home/postgres/public_html/cgi-bin/data/community_curation/community_curation_source';
  # print qq(<a target="_blank" href="data/community_curation/community_curation_source">source file</a><br/>);
  my $outfile = $filesPath . 'community_curation_source';
  print qq(<a target="_blank" href="$ENV{THIS_HOST_AS_BASE_URL}files/priv/community_curation/community_curation_source">source file</a><br/>);
  my ($var, $total_count)          = &getHtmlVar($query, 'total_count');
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  for my $i (1 .. $total_count) { 
    ($var, my $two)    = &getHtmlVar($query, "two_$i");
    ($var, my $email)  = &getHtmlVar($query, "email_$i");
    ($var, my $papers) = &getHtmlVar($query, "papers_$i");
    my (@papers) = split/, /, $papers;
    my $paper = $papers[0];
    print OUT qq($two\t$email\t$paper\t$papers\n); }
  close (OUT) or die "Cannot close $outfile : $!";
  chmod(0666, $outfile);
} # sub generateMassEmailFile

sub massEmailTracker {
#   my ($htmlOrText) = @_;
  my ($var, $htmlOrText)          = &getHtmlVar($query, 'html_or_text');
  if ($htmlOrText eq 'text') { print qq(Content-type: text/plain\n\n); }
    else { 
      &printHtmlHeader();
      print qq(<a href="community_curation_tracker.cgi">start over</a><br/>\n); }

  ($var, my $yearSelected)        = &getHtmlVar($query, 'year_selected');
  my $pgclause = '';
  if ($yearSelected) { $pgclause = qq(WHERE com_timestamp::text ~ '^$yearSelected'); }

  my %two;
  $result = $dbh->prepare( "SELECT * FROM two_standardname" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $two{name}{$row[0]} = $row[2]; } }

  my %pap;
  $result = $dbh->prepare( "SELECT * FROM app_paper WHERE app_paper ~ 'WBPaper' AND joinkey IN (SELECT joinkey FROM app_curator WHERE app_curator = 'WBPerson29819')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach (@paps) { $pap{$_}{communityCurated}{app}++; } } }
  $result = $dbh->prepare( "SELECT * FROM rna_paper WHERE rna_paper ~ 'WBPaper' AND joinkey IN (SELECT joinkey FROM rna_curator WHERE rna_curator = 'WBPerson29819')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) {
        my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
        foreach (@paps) { $pap{$_}{communityCurated}{rna}++; } } }

  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $row[1] =~ s/pmid//; $pap{$row[0]}{pmid}{$row[1]}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{pdf}{$row[1]}++; } }


#   my $header = qq(<thead><tr><th>email response</th><th>remark</th><th>email date</th><th>email addresses sent request</th><th>person ID</th><th>person name</th></th><th>community curated app</th><th>community curated rna</th><th>WBPaper</th><th>pmids</th><th>pdfs</th></tr></thead><tbody>\n); 
  my $headerText = qq(email response\tremark\temail date\temail addresses sent request\tperson ID\tperson name\tcommunity curated app\tcommunity curated rna\tWBPaper\tpmids\tpdfs\n); 
  my $header = $headerText; $header =~ s/\t/<\/th><th>/g; $header = "<thead><tr><th>$header</th></tr></thead><tbody>"; 

  if ($htmlOrText eq 'html') {
#       print qq(Download table <a href="community_curation_tracker.cgi?action=Mass+Email+Tracker+Text" download="community_curation_tracker.txt">link</a><br />\n);
      print qq(Download table <a href="community_curation_tracker.cgi?action=Mass+Email+Tracker&html_or_text=text&year_selected=$yearSelected" download="community_curation_tracker.txt">link</a><br />\n);
      print qq(<table style="border-style: none;" border="1">);
      print qq($header); }
    else { print qq($headerText); }

  $result = $dbh->prepare( "SELECT * FROM com_massemail $pgclause ORDER BY joinkey DESC, com_timestamp DESC" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my ($pap, $two, $emailedAddresses, $response, $remark, $timestamp) = @row;
    my $person = $two; $person =~ s/two/WBPerson/;
    my $personname = $two{name}{$two};

    $response =~ s/\n/ /msg;
    $remark =~ s/\n/ /msg;
    if ($htmlOrText eq 'html') {
      $response =~ s/</&lt;/g; $response =~ s/>/&gt;/g;
      $remark   =~ s/</&lt;/g; $remark   =~ s/>/&gt;/g; }

    my $communityCuratedApp  = 'NOT'; 
    my $communityCuratedRnai = 'NOT'; 
    if ($pap{$pap}{communityCurated}{app}) { $communityCuratedApp  = 'curated'; }
    if ($pap{$pap}{communityCurated}{rna}) { $communityCuratedRnai = 'curated'; }

    my $datatype = 'massemail';
    my $textareacols = '40';
    my $responseAjaxUrl = "community_curation_tracker.cgi?action=ajaxUpdate&papid=$pap&field=response&datatype=$datatype&timestamp=$timestamp&value=";
    my $responseInput = qq(<input name="response" id="${pap}_${timestamp}_inputresponse" value="$response" onfocus="document.getElementById('${pap}_${timestamp}_inputresponse').style.display = 'none'; document.getElementById('${pap}_${timestamp}_textarearesponse').style.display = ''; document.getElementById('${pap}_${timestamp}_textarearesponse').focus(); "/>);
    my $responseTextarea = qq(<textarea id="${pap}_${timestamp}_textarearesponse" rows="5" cols="$textareacols" style="display:none;" onblur="document.getElementById('${pap}_${timestamp}_inputresponse').style.display = ''; document.getElementById('${pap}_${timestamp}_textarearesponse').style.display = 'none'; var inputValue = document.getElementById('${pap}_${timestamp}_inputresponse').value; var textareaValue = document.getElementById('${pap}_${timestamp}_textarearesponse').value; if (inputValue !== textareaValue) { document.getElementById('${pap}_${timestamp}_inputresponse').value = textareaValue; var ajaxUrl = '${responseAjaxUrl}' + escape(document.getElementById('${pap}_${timestamp}_textarearesponse').value); \$.ajax({ url: ajaxUrl }); }" >$response</textarea>);
    my $remarkAjaxUrl = "community_curation_tracker.cgi?action=ajaxUpdate&papid=$pap&field=remark&datatype=$datatype&timestamp=$timestamp&value=";
    my $remarkInput = qq(<input name="remark" id="${pap}_${timestamp}_inputremark" value="$remark" onfocus="document.getElementById('${pap}_${timestamp}_inputremark').style.display = 'none'; document.getElementById('${pap}_${timestamp}_textarearemark').style.display = ''; document.getElementById('${pap}_${timestamp}_textarearemark').focus(); "/>);
    my $remarkTextarea = qq(<textarea id="${pap}_${timestamp}_textarearemark" rows="5" cols="$textareacols" style="display:none;" onblur="document.getElementById('${pap}_${timestamp}_inputremark').style.display = ''; document.getElementById('${pap}_${timestamp}_textarearemark').style.display = 'none'; var inputValue = document.getElementById('${pap}_${timestamp}_inputremark').value; var textareaValue = document.getElementById('${pap}_${timestamp}_textarearemark').value; if (inputValue !== textareaValue) { document.getElementById('${pap}_${timestamp}_inputremark').value = textareaValue; var ajaxUrl = '${remarkAjaxUrl}' + escape(document.getElementById('${pap}_${timestamp}_textarearemark').value); \$.ajax({ url: ajaxUrl }); }" >$remark</textarea>);
    my ($emailedDate)      = $timestamp =~ m/^([\d\-]{10})/; 

    my $pmids = join", ", sort keys %{ $pap{$pap}{pmid} };
    my @pdfs;
    foreach my $path (sort keys %{ $pap{$pap}{pdf} }) {
      my ($pdfname) = $path =~ m/\/([^\/]*?)$/;
      my $url = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdfname;
      my $link = qq(<a href="$url" target="new">$pdfname</a>);
      push @pdfs, $link; }
    my $pdfs = join" ", @pdfs;

    my $rowText = qq($response\t$remark\t$emailedDate\t$emailedAddresses\t$person\t$personname\t$communityCuratedApp\t$communityCuratedRnai\tWBPaper$pap\t$pmids\t$pdfs\n);
    my $rowHtml = qq(<tr><td>${responseInput}${responseTextarea}</td><td>${remarkInput}${remarkTextarea}</td><td>$emailedDate</td><td>$emailedAddresses</td><td>$person</td><td>$personname</td><td>$communityCuratedApp</td><td>$communityCuratedRnai</td><td>WBPaper$pap\t</td><td>$pmids</td><td>$pdfs</td></tr>\n); 
#     my $row = qq(<tr><td>${responseInput}${responseTextarea}</td><td>${remarkInput}${remarkTextarea}</td><td>$emailedDate</td><td>$emailedAddresses</td><td>$communityCurated</td><td>$communityCuratedRnai</td><td>WBPaper$pap\t</td><td>$pmids</td><td>$pdfs</td></tr>\n); 
    if ($htmlOrText eq 'html') { print qq($rowHtml); }
      else { print qq($rowText); }
  }
  if ($htmlOrText eq 'text') { 1; }
    else { &printFooter(); }
} # sub massEmailTracker



sub ajaxUpdate {				# update field's pgtable data
  my ($var, $papid)          = &getHtmlVar($query, 'papid');
  ($var, my $datatype)       = &getHtmlVar($query, 'datatype');
  ($var, my $field)          = &getHtmlVar($query, 'field');
  ($var, my $value)          = &getHtmlVar($query, 'value');
  ($var, my $timestamp)      = &getHtmlVar($query, 'timestamp');
  $value =~ s/\'/''/g;
  my @pgcommands;
  if ($datatype eq 'massemail') {
      push @pgcommands, qq(UPDATE com_${datatype} SET com_${field} = '$value' WHERE joinkey = '$papid' AND com_timestamp = '$timestamp';); }
    else {
      push @pgcommands, qq(DELETE FROM com_${datatype}_${field} WHERE joinkey = '$papid';);
      push @pgcommands, qq(INSERT INTO com_${datatype}_${field} VALUES ( '$papid', '$value'););
      push @pgcommands, qq(INSERT INTO com_${datatype}_${field}_hst VALUES ( '$papid', '$value');); }
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand<br/>);
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # sub ajaxUpdate

sub sendEmail {
  my ($var, $papid)          = &getHtmlVar($query, 'papid');
  ($var, my $emailaddress)   = &getHtmlVar($query, 'email');
  ($var, my $subject)        = &getHtmlVar($query, 'subject');
  ($var, my $body)           = &getHtmlVar($query, 'body');
  ($var, my $datatype)       = &getHtmlVar($query, 'datatype');
  my $sender = 'outreach@wormbase.org';
  my $replyto = 'curation@wormbase.org';
  print qq(send email to $emailaddress<br/>from $sender<br/>replyto $replyto<br/>subject $subject<br/>body $body<br/>);
  my $email = Email::Simple->create(
    header => [
        From       => 'outreach@wormbase.org',
        'Reply-to' => 'curation@wormbase.org',
        To         => "$emailaddress",
        Subject    => "$subject",
    ],
    body => "$body",
  );

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
  my @pgcommands;
  push @pgcommands, qq(DELETE FROM com_${datatype}_emailsent WHERE joinkey = '$papid';);
  push @pgcommands, qq(INSERT INTO com_${datatype}_emailsent VALUES ( '$papid', '$emailaddress'););
  push @pgcommands, qq(INSERT INTO com_${datatype}_emailsent_hst VALUES ( '$papid', '$emailaddress'););
  foreach my $pgcommand (@pgcommands) {
#     print qq($pgcommand<br/>);
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
  print qq(<a href="community_curation_tracker.cgi">back to start</a><br/>);
} # sub sendEmail

#     print qq(<input type="hidden" name="papid"    value="$pap" />\n);
#     print qq(<input type="hidden" name="pmids"    value="$pmids" />\n);
#     print qq(<input type="hidden" name="aidname"  value="$aids{$aid}{name}"/>\n);
#     print qq(<input type="hidden" name="anames"   value="$personName"/>\n);
#     print qq(<input type="hidden" name="atwos"    value="$person"/>\n);
#     print qq(<input type="hidden" name="aemails"  value="$emails"/>\n);
#     print qq(<input type="hidden" name="cnames"   value="$cName"/>\n);
#     print qq(<input type="hidden" name="ctwos"    value="$cTwo"/>\n);
#     print qq(<input type="hidden" name="cemails"  value="$cEmail"/>\n);
#     print qq(<input type="hidden" name="pnames"   value="$pName"/>\n);
#     print qq(<input type="hidden" name="ptwos"    value="$pTwo"/>\n);
#     print qq(<input type="hidden" name="pemails"  value="$pEmail"/>\n);
#     print qq(<input type="hidden" name="pdfs"     value="$pdfs"/>\n);
#     print qq(<input type="hidden" name="datatype" value="app"/>\n);
# 
# 
#     my $submit = '';
#     if ( ($pmids) && ($emails || $cEmail) ) { $submit = qq(<input type="submit" name="action" value="generate email">\n); }
# #     print qq(<tr><td>$submit</td><td>WBPaper$pap\t</td><td>$pmids</td><td>$aids{$aid}{name}\t</td><td>$personName\t</td><td>$person\t</td><td>$emails\t</td><td>$cName</td><td>$cTwo</td><td>$cEmail</td><td>$pdfs</td></tr>\n); 

sub skipPaper {
  my ($var, $papid    ) = &getHtmlVar($query, 'papid');
  ($var, my $datatype ) = &getHtmlVar($query, 'datatype');
  my @pgcommands;
  push @pgcommands, qq(DELETE FROM com_${datatype}_skip WHERE joinkey = '$papid';);
  push @pgcommands, qq(INSERT INTO com_${datatype}_skip VALUES ( '$papid', 'skip'););
  push @pgcommands, qq(INSERT INTO com_${datatype}_skip_hst VALUES ( '$papid', 'skip'););
  foreach my $pgcommand (@pgcommands) {
#     print qq($pgcommand<br/>);
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
  &tracker($datatype);  
} 

sub generateEmail {
  my ($var, $papid      ) = &getHtmlVar($query, 'papid');
  ($var, my $pmids      ) = &getHtmlVar($query, 'pmids');
  ($var, my $aidname    ) = &getHtmlVar($query, 'aidname');
  ($var, my $anames     ) = &getHtmlVar($query, 'anames');
  ($var, my $atwos      ) = &getHtmlVar($query, 'atwos');
  ($var, my $aemails    ) = &getHtmlVar($query, 'aemails');
  ($var, my $cnames     ) = &getHtmlVar($query, 'cnames');
  ($var, my $ctwos      ) = &getHtmlVar($query, 'ctwos');
  ($var, my $cemails    ) = &getHtmlVar($query, 'cemails');
  ($var, my $afpnames   ) = &getHtmlVar($query, 'afpnames');
  ($var, my $afptwos    ) = &getHtmlVar($query, 'afptwos');
  ($var, my $afpemails  ) = &getHtmlVar($query, 'afpemails');
  ($var, my $pdfnames   ) = &getHtmlVar($query, 'pdfnames');
  ($var, my $pdftwos    ) = &getHtmlVar($query, 'pdftwos');
  ($var, my $pdfemails  ) = &getHtmlVar($query, 'pdfemails');
  ($var, my $pdfs       ) = &getHtmlVar($query, 'pdfs');
  ($var, my $genes      ) = &getHtmlVar($query, 'genes');
  ($var, my $datatype   ) = &getHtmlVar($query, 'datatype');
#   ($var, my $aggemails) = &getHtmlVar($query, 'aggemails');
# print qq(DT $datatype EM $aemails CE $cemails E<br>);
  my (@pmids) = $pmids =~ m/(\d+)/g;
  my @sorted_pmids = sort {$b<=>$a} @pmids;
  my $pmid = shift @sorted_pmids;
  print qq(<form method="post" action="community_curation_tracker.cgi"\n>);
  print qq(<input type="hidden" name="papid"   value="$papid" />\n);

  print qq(<table style="border-style: none;" border="1">);
#   print qq(<tr><td>WBPaper</td><td>pmids</td><td>first author initials</td><td>first author's person name</td><td>first author's person id</td><td>first author's person emails</td><td>corresponding author name</td><td>corresponding person</td><td>corresponding email</td><td>pdf author name</td><td>pdf person</td><td>pdf email</td><td>pdfs</td></tr>\n); 
  my $row = qq(<tr><td>WBPaper$papid\t</td><td>$pmids</td><td>$pdfs</td><td>$aidname\t</td><td>$anames\t</td><td>$atwos\t</td><td>$aemails\t</td><td>$cnames</td><td>$ctwos</td><td>$cemails</td><td>$afpnames</td><td>$afptwos</td><td>$afpemails</td><td>$pdfnames</td><td>$pdftwos</td><td>$pdfemails</td></tr></table>\n); 
  if ($datatype eq 'con') { $row = qq(<tr><td>WBPaper$papid\t</td><td>$pmids</td><td>$pdfs</td><td>$genes</td><td>$aidname\t</td><td>$anames\t</td><td>$atwos\t</td><td>$aemails\t</td><td>$cnames</td><td>$ctwos</td><td>$cemails</td><td>$afpnames</td><td>$afptwos</td><td>$afpemails</td><td>$pdfnames</td><td>$pdftwos</td><td>$pdfemails</td></tr></table>\n); }
  print qq($row);
#   print qq(PMID $pmid 1AUT $aemails<br/>);
#   print qq(AFP $cemails, PDF $pemails<br/>);
#   print qq(AFP $ctwos, PDF $ptwos<br/>);
#   print qq(PAPID $papid END<br/>);
  my %names; tie %names, "Tie::IxHash";
  my @nameSources = ($cnames, $pdfnames, $afpnames, $anames);
  if ($anames) { @nameSources = ( $anames ); }		# if there's first author name, only use that one  2017 07 21
  foreach my $nameSource (@nameSources) {
    $nameSource =~ s/<.*?>//g;
    my (@names) = split/, /, $nameSource;
    foreach my $name (@names) { $names{$name}++; } }
  my $names = join", ", keys %names;
#   print qq(N $names AN $anames CN $cnames PN $pnames E<br/>\n);
  my @emails; my %emails; tie %emails, "Tie::IxHash";
  if ($aemails) {
      my (@aemails) = split/, /, $aemails;
      foreach my $email (@aemails) { $emails{$email}++; } }
    else {
      my %oldEmails;
      my @checkEmails = (); push @checkEmails, $cemails; push @checkEmails, $afpemails; push @checkEmails, $pdfemails;
      foreach my $emailset (@checkEmails) {
        my (@spans) = split/, /, $emailset;
        foreach my $span (@spans) {
          if ($span =~ m/>(.*?)</) {			# some emails in spans
              my ($email) = $span =~m/>(.*?)</;
              if ( $span =~m/color: black/ ) { $emails{$email}++; }
                elsif ( $span =~m/color: orange/ ) { $oldEmails{$email}++; } }
            else { $emails{$span}++; } } }			# other are just emails
      foreach my $oldEmail (sort keys %oldEmails) {
        my @emails;
        $result = $dbh->prepare( "SELECT joinkey FROM two_old_email WHERE two_old_email = '$oldEmail';" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        my @row = $result->fetchrow(); my $two = $row[0];
        $result = $dbh->prepare( "SELECT * FROM two_email WHERE joinkey = '$two' ORDER BY two_timestamp DESC;" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        @row = $result->fetchrow(); my $email = $row[2] || 'no current email';
        $email =~ s/\s//g;
        if ($row[2]) { $emails{$email}++; }
        print qq(old email $oldEmail is person : '$two' with email : '${email}'<br/>);
      } # foreach my $oldEmail (sort keys %oldEmails)
#       if ($cemails) { push @emails, $cemails; }
#       if ($pemails) { push @emails, $pemails; }
    } # else # if ($aemails)
  
  my $email = join", ", keys %emails; 
#   if ($aggemails) { $email = $aggemails; }
  my $ncbiurl = 'http://www.ncbi.nlm.nih.gov/pubmed/' . $pmid . '?report=docsum&format=text';
  my $ncbidata = get($ncbiurl);
  my ($body) = $ncbidata =~ m/1: (.*?)\s*<\/pre>/s;
  my $subject; my $author;
  if ($datatype eq 'app') {
      $subject = 'Contribute phenotype data to WormBase';
      $author = 'Author'; if ($email =~ m/,/) { $author = 'Author(s)'; }
      if ($names) { $author = $names; }
      $body = qq(Dear $author,\n\nIn an effort to improve WormBase's coverage of phenotypes, we are requesting your assistance to annotate nematode phenotypes from the following paper:\n\n$body\n\nWormBase would greatly appreciate if you, or any of the other authors, could take a moment to contribute phenotype connections using our simple web-based tool:\n\nhttp://www.wormbase.org/submissions/phenotype.cgi?input_1_pmid=${pmid}\n\nIf you have any questions, comments or concerns, please let us know.\n\nThank you so much!\n\nBest regards,\n\nThe WormBase Phenotype Team);
    }
    elsif ($datatype eq 'con') {
      $subject = 'WormBase request for community curation of gene descriptions ';
      $author = 'Author'; if ($email =~ m/,/) { $author = 'Author(s)'; }
      if ($names) { $author = $names; }
      $body = qq(Dear $author,\n\nIn an effort to keep the gene descriptions in WormBase updated, we are requesting your assistance either to update an existing gene description or write a new gene description if none exists, for any genes studied in your publication: \n\n$body\n\nGene descriptions appear in the 'Overview' widget on WormBase gene pages. We would greatly appreciate if you, or any of the other authors, could use our simple web-based tool, to either write or update gene descriptions:\n\nhttp://www.wormbase.org/submissions/community_gene_description.cgi\n\nIf you have any questions, comments or concerns, please let us know.\n\nThank you so much!\n\nBest regards,\n\nThe WormBase Gene Description Team);
    }
  print qq(<input type="hidden" name="datatype" value="$datatype"/>\n);
  print qq(<table>);
  print qq(<tr><td>Email</td>  <td><input name="email"   value="$email"   size="100"/></td></tr>\n);
  print qq(<tr><td>Subject</td><td><input name="subject" value="$subject" size="100"/></td></tr>\n);
  print qq(<tr><td>Body</td>   <td><textarea name="body" rows="30" cols="90">$body</textarea></td></tr>\n);
  print qq(<tr><td>Submit</td> <td><input type="submit" name="action" value="send email"></td></tr>\n);
  print qq(</table>);
  print qq(</form>);
} # sub generateEmail


sub readyToGo {
  my ($datatype) = @_;
#   ($var, my $datatype)       = &getHtmlVar($query, 'datatype');

  my %pap;
  my %recentemail;			# email addresses sent in the last month
  my %recentpeople;			# people with an email addresses sent in the last month
  my %email;
  my %two;
  my %com;
  my %gin;

# Old way of getting pdf's emails from flatfile that's no longer being maintained.  2021 02 04
#   my $pdfEmailUrl = 'http://tazendra.caltech.edu/~postgres/out/email_pdf_afp';
#   my $pdfEmailFile = get $pdfEmailUrl;
#   my (@lines) = split/\n/, $pdfEmailFile;
#   foreach my $line (@lines) { 
#     my ($pap, $email, $afpEmail, $source) = split/\t/, $line;
#     $email{pdf}{$pap} = $email; }
  $result = $dbh->prepare( "SELECT * FROM pdf_email WHERE pdf_email IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[1]); $lcemail =~ s/\s//g; $email{pdf}{$row[0]} = $lcemail; } }
  
  $result = $dbh->prepare( "SELECT * FROM com_${datatype}_skip" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $com{$row[0]}{skip} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM com_${datatype}_emailsent" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $com{$row[0]}{date}  = $row[2]; 
      $com{$row[0]}{email} = $row[1]; } }

  $result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_email IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[1]); $lcemail =~ s/\s//g; $email{afp}{$row[0]} = $lcemail; } }
  $result = $dbh->prepare( "SELECT * FROM two_email" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[2]); $lcemail =~ s/\s//g; $email{two}{$lcemail} = $row[0]; } }
  $result = $dbh->prepare( "SELECT * FROM two_old_email" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my ($lcemail) = lc($row[2]); $lcemail =~ s/\s//g; $email{old}{$lcemail} = $row[0]; } }
  $result = $dbh->prepare( "SELECT * FROM two_standardname" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $two{name}{$row[0]} = $row[2]; } }
  
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{valid}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_pubmed_final WHERE pap_pubmed_final = 'final'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{pubmedfinal}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '1' AND joinkey NOT IN (SELECT joinkey FROM pap_type WHERE pap_type = '26')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{journalarticle}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $row[1] =~ s/pmid//; $pap{$row[0]}{pmid}{$row[1]}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{pdf}{$row[1]}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_primary_data WHERE pap_primary_data = 'primary';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{primary}++; } }

  $result = $dbh->prepare( "SELECT * FROM com_app_emailsent WHERE com_timestamp > current_date - interval '1 months' " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
#     $recentemail{pap}{app}{$row[0]}++; 
    if ($row[1]) { ($row[1]) = lc($row[1]);
      my (@recentemails) = split/\s+/, $row[1];
      foreach my $recentemail (@recentemails) {
        $recentemail =~ s/,//g; $recentemail{email}{app}{$recentemail}++; } } }
  $result = $dbh->prepare( "SELECT * FROM com_con_emailsent WHERE com_timestamp > current_date - interval '1 months' " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
#     $recentemail{pap}{con}{$row[0]}++; 
    if ($row[1]) { ($row[1]) = lc($row[1]);
      my (@recentemails) = split/\s+/, $row[1];
      foreach my $recentemail (@recentemails) {
        $recentemail =~ s/,//g; $recentemail{email}{con}{$recentemail}++; } } }
# No longer filter out emails that have been AFPed in the last month.  2017 07 31
#   $result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_timestamp > current_date - interval '1 months' " );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) { 
# #     $recentemail{pap}{afp}{$row[0]}++; 
#     if ($row[1]) { ($row[1]) = lc($row[1]);
#       my (@recentemails) = split/\s+/, $row[1];
#       foreach my $recentemail (@recentemails) {
#         $recentemail =~ s/,//g; $recentemail{email}{afp}{$recentemail}++; } } }
  foreach my $type (sort keys %{ $recentemail{email} }) {
    foreach my $email (sort keys %{ $recentemail{email}{$type} }) {
      if ( $email{old}{$email} ) { $recentpeople{$email{old}{$email}}++; }
      if ( $email{two}{$email} ) { $recentpeople{$email{two}{$email}}++; } } }

  $result = $dbh->prepare( "SELECT * FROM ${datatype}_paper WHERE ${datatype}_paper ~ 'WBPaper'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach (@paps) { $pap{$_}{curated}++; } } }

  if ($datatype eq 'app') {
    my $urlAnyFlaggedNCur = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_curator=two1823&listDatatype=newmutant&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
    my $dataAnyFlaggedNCur = get $urlAnyFlaggedNCur;
    my (@papers) = $dataAnyFlaggedNCur =~ m/specific_papers=WBPaper(\d+)/g;
    foreach (@papers) { $pap{$_}{flaggeddatatype}++; }

      # remove papers that have been curated for RNAi for Chris.  2016 08 23
    my $urlRnaiCurated = $curation_status_url . '?action=listCurationStatisticsPapersPage&select_curator=two1823&listDatatype=rnai&method=allcur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
    my $dataRnaiCurated = get $urlRnaiCurated;
    my (@rnaiPapers) = $dataRnaiCurated =~ m/specific_papers=WBPaper(\d+)/g;
    foreach (@rnaiPapers) { 
      if ($pap{$_}{flaggeddatatype}) {
        delete $pap{$_}{flaggeddatatype}; } }
  } # if ($datatype eq 'app')

# Ranjana no longer needs to track concise descriptions through here
#   if ($datatype eq 'con') {
#     my %toWBGene;
#     $result = $dbh->prepare( "SELECT * FROM gin_locus ;" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         $toWBGene{$row[1]} = $row[0];
#         $gin{$row[0]}      = $row[1]; } }
#     my $urlTextpressoPap  = 'http://textpresso-dev.caltech.edu/concise_descriptions/textpresso/textpresso_papers_results_genes.txt';
#     my $dataTextpressoPap = get $urlTextpressoPap;
#     my (@lines) = split/\n/, $dataTextpressoPap;
#     foreach my $line (@lines) {
#       my ($paper, $loci) = split/\t/, $line;
#       if ($paper =~ m/WBPaper(\d{8})/) {
#         my $pap = $1; 
#         $pap{$pap}{flaggeddatatype}++;
#         $loci =~ s/\(.*?\)//g;
#         my (@loci) = split/\s+/, $loci;
#         foreach my $locus (@loci) {
#           my $wbgene = $locus; if ($toWBGene{$locus}) { $wbgene = $toWBGene{$locus}; }
#           $pap{$pap}{gene}{$wbgene}++; } }
#     } # foreach my $line (@lines)
#   } # if ($datatype eq 'con')
  
  
  
  my %filter;
  foreach my $pap (sort keys %pap) {
    next unless ($pap{$pap}{flaggeddatatype});
    next unless ($pap{$pap}{valid});
    next unless ($pap{$pap}{primary});
    next unless ($pap{$pap}{pubmedfinal});
    next unless ($pap{$pap}{journalarticle});
    next unless ($pap{$pap}{pdf});
#     next unless ($email{afp}{$pap});		# paper must have been AFPed first	# Chris no longer wants this restriction 2017 07 31

#     next if ($pap{$pap}{email});
    next if ($com{$pap}{email});		# already emailed in com_<datatype>_emailsent
    next if ($com{$pap}{skip}); 		# already flagged to skip in com_<datatype>_skip
    next if ($pap{$pap}{done});
    next if ($pap{$pap}{curated});
    $filter{$pap}++;
  } # foreach my $pap (sort keys %pap)
  
  my %twoEmail;
  $result = $dbh->prepare( "SELECT * FROM two_email ORDER BY joinkey, two_order" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $row[2] =~ s/\s//g; push @{ $twoEmail{$row[0]} }, $row[2]; } }
  
  # foreach my $pap (sort keys %filter) { print qq($pap\n); } 
  
  my %aids;
  my $joinkeys = join"','", sort keys %filter;
  $result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey IN ('$joinkeys') ORDER BY pap_order::INTEGER DESC;" );	# get most recent aid last for loop
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{aid}{$row[2]} = $row[1]; $aids{$row[1]}{any}++; } }
  my $aids = join"','", sort {$a<=>$b} keys %aids;
  $result = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id IN ('$aids');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $aids{$row[0]}{name} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id IN ('$aids');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ( ($row[1]) && ($row[0]) ) { 
      next unless ($twoEmail{$row[1]});
      $aids{$row[0]}{two}{$row[2]} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE author_id IN ('$aids') AND pap_author_verified ~ 'YES';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $aids{$row[0]}{ver} = $row[2]; } }
# Chris no longer wants corresponding author data looked at  2017 07 17
#   $result = $dbh->prepare( "SELECT * FROM pap_author_corresponding WHERE author_id IN ('$aids');" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { 
#       $aids{$row[0]}{cor} = $row[1]; } }
    
  my $countThreshold = 100;
  print qq(Showing most recent $countThreshold entries<br/>\n);
  print qq(<table style="border-style: none;" border="1" >\n);
  

  my $header = qq(<tr><th>generate</th><th>skip</th><th>WBPaper</th><th>pmids</th><th>pdfs</th><th>first author initials</th><th>first author's person name</th><th>first author's person id</th><th>first author's person emails</th><th>corresponding author name</th><th>corresponding person</th><th>corresponding email</th><th>afp author name</th><th>afp person</th><th>afp email</th><th>pdf author name</th><th>pdf person</th><th>pdf email</th></tr>\n); 
  if ($datatype eq 'con') { $header = qq(<tr><th>generate</th><th>skip</th><th>WBPaper</th><th>pmids</th><th>pdfs</th><th>genes</th><th>first author initials</th><th>first author's person name</th><th>first author's person id</th><th>first author's person emails</th><th>corresponding author name</th><th>corresponding person</th><th>corresponding email</th><th>afp author name</th><th>afp person</th><th>afp email</th><th>pdf author name</th><th>pdf person</th><th>pdf email</th></tr>\n); }
  print $header;
  my $count = 0;
  foreach my $pap (reverse sort keys %filter) {
    my $pmids = join", ", sort keys %{ $pap{$pap}{pmid} };
    my @pdfs;
    foreach my $path (sort keys %{ $pap{$pap}{pdf} }) {
      my ($pdfname) = $path =~ m/\/([^\/]*?)$/;
      my $url = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdfname;
      my $link = qq(<a href='$url' target='new'>$pdfname</a>);
      push @pdfs, $link; }
    my $pdfs = join" ", @pdfs;
    my $recentlyEmailed = 0;
    my ($two, $personName, $person, $emails) = ('', '', '', '');
    my $aidFirstAuthor = ''; if ($pap{$pap}{aid}{1}) { $aidFirstAuthor = $pap{$pap}{aid}{1}; }
# if ($pap eq '00046127') { print "AFA $aidFirstAuthor PAP $pap E<br>"; }
    my @cEmails; my @cTwos; my @cNames;
    my ($cEmail, $cTwo, $cName) = ('', '', '');	# generate from afp_email the person id and name
    foreach my $order (sort {$a<=>$b} keys %{ $pap{$pap}{aid} }) {
# if ($pap eq '00046127') { print "ORDER $order PAP $pap E<br>"; }
      my $aid = $pap{$pap}{aid}{$order};
# if ($pap eq '00046127') { print "ORDER $order AID $aid PAP $pap E<br>"; }
      if ($aids{$aid}{ver}) {
        my $join = $aids{$aid}{ver}; 
# if ($pap eq '00046127') { print "VER JOIN $join ORDER $order AID $aid PAP $pap E<br>"; }
        if ($aids{$aid}{two}{$join}) {
# if ($pap eq '00046127') { print "AID two $aid HERE<br>"; }
          if ($aid eq $aidFirstAuthor) {
# if ($pap eq '00046127') { print "AID AFA $aid HERE<br>"; }
            $two         = $aids{$aid}{two}{$join};
            $personName  = $two{name}{$two}; 
            $person      = $two; $person =~ s/two/WBPerson/;
            $emails      = join", ", @{ $twoEmail{$two} }; }
          if ($recentpeople{$two}) { $recentlyEmailed++; }
          if ($aids{$aid}{cor}) {
            my $cTwo         = $aids{$aid}{two}{$join};
            my $cPersonName  = $two{name}{$cTwo}; 
            my $cEmails      = join", ", @{ $twoEmail{$cTwo} };
            if ( !($emails) && ($recentpeople{$cTwo}) )  { $recentlyEmailed++; }	# if corresponding person was recently emailed and there is no fa->person->email, skip the row  2017 08 03
            push @cEmails, $cEmails;
            push @cTwos,   $cTwo;
            push @cNames,  $cPersonName;
          }
        }
      }
    }
    $cEmail = join", ", @cEmails;
    $cTwo   = join", ", @cTwos;
    $cName  = join", ", @cNames;
# if ($pap eq '00046127') { print qq(PAP $pap CEM $cEmail E<br>); }
    my %categories;
    $categories{good}{color} = 'black';
    $categories{old}{color}  = 'orange';
    $categories{bad}{color}  = 'red';
    my ($afpEmail, $afpTwo, $afpName) = ('', '', '');	# generate from afp_email the person id and name
    my ($pdfEmail, $pdfTwo, $pdfName) = ('', '', '');	# generate from pdf extraction
    unless ($cEmail) {
      if ($email{afp}{$pap}) {
        my %twos; my %emails;
        my @emails; my @twos; my @names;
        my (@afpemails) = split/\s+/, $email{afp}{$pap};
        foreach my $afpemail (@afpemails) {
          my ($two, $name) = ('', '');
          $afpemail =~ s/,//g;
          if ($recentemail{email}{afp}{$afpemail}) { $recentlyEmailed++; }	# to filter by emails recently emailed
          if ($recentemail{email}{app}{$afpemail}) { $recentlyEmailed++; }	# to filter by emails recently emailed
          if ($recentemail{email}{con}{$afpemail}) { $recentlyEmailed++; }	# to filter by emails recently emailed
          if ($email{two}{$afpemail}) {
              $two   = $email{two}{$afpemail}; 
#               if ($recentpeople{$two}) { $recentlyEmailed++; }	# 2017 07 18 no longer prevent showing on the list from an afp email having been emailed
              if ( !($emails) && ($recentemail{email}{app}{$afpemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check afpemail has not been emailed recently for this pipeline
              $emails{good}{$afpemail} = $two; 
              $twos{good}{$two}++; }
            elsif ($email{old}{$afpemail}) {
              $two   = $email{old}{$afpemail}; 
#               if ($recentpeople{$two}) { $recentlyEmailed++; }	# 2017 07 18 no longer prevent showing on the list from an afp email having been emailed
              if ( !($emails) && ($recentemail{email}{app}{$afpemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check afpemail has not been emailed recently for this pipeline
              $emails{old}{$afpemail} = $two; 
              $twos{old}{$two}++; }
            else {
              $emails{bad}{$afpemail} = 'nowbperson'; }
        }
        foreach my $afpemail (@afpemails) {
          $afpemail =~ s/,//g;
          foreach my $category (sort keys %categories) {
            my $color = $categories{$category}{color} || 'yellow';
            if ($emails{$category}{$afpemail}) {
              my $two = $emails{$category}{$afpemail} || ''; push @emails, qq(<span style='color: $color'>$afpemail</span>);
              if ($two ne 'nowbperson') {
                my $wbperson = $two; $wbperson =~ s/two/WBPerson/g; push @twos, qq(<span style='color: $color'>$wbperson</span>);
                if ($two{name}{$two}) { push @names, qq(<span style='color: $color'>$two{name}{$two}</span>);} } } } }
        $afpEmail = join", ", @emails;
        $afpTwo   = join", ", @twos;
        $afpName  = join", ", @names;
      }
      if ($email{pdf}{$pap}) {
        my %twos; my %emails;
        my @emails; my @twos; my @names;
        my (@pdfemails) = split/\s+/, $email{pdf}{$pap};
        foreach my $pdfemail (@pdfemails) {
          my ($two, $name) = ('', '');
          $pdfemail =~ s/,//g;
          if ($email{two}{$pdfemail}) {
              $two   = $email{two}{$pdfemail}; 
#               if ($recentpeople{$two}) { $recentlyEmailed++; }	# 2017 07 18 no longer prevent showing on the list from an pdf email having been emailed
              if ( !($emails) && ($recentemail{email}{app}{$pdfemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check pdfemail has not been emailed recently for this pipeline
              $emails{good}{$pdfemail} = $two; 
              $twos{good}{$two}++; }
            elsif ($email{old}{$pdfemail}) {
              $two   = $email{old}{$pdfemail}; 
#               if ($recentpeople{$two}) { $recentlyEmailed++; }	# 2017 07 18 no longer prevent showing on the list from an pdf email having been emailed
              if ( !($emails) && ($recentemail{email}{app}{$pdfemail}) ) { $recentlyEmailed++; }	# 2017 08 03 if no fa->person->email check pdfemail has not been emailed recently for this pipeline
              $emails{old}{$pdfemail} = $two; 
              $twos{old}{$two}++; }
            else {
              $emails{bad}{$pdfemail} = 'nowbperson'; }
        }
        foreach my $pdfemail (@pdfemails) {
          $pdfemail =~ s/,//g;
          foreach my $category (sort keys %categories) {
            my $color = $categories{$category}{color} || 'yellow';
            if ($emails{$category}{$pdfemail}) {
              my $two = $emails{$category}{$pdfemail} || ''; push @emails, qq(<span style='color: $color'>$pdfemail</span>);
              if ($two ne 'nowbperson') {
                my $wbperson = $two; $wbperson =~ s/two/WBPerson/g; push @twos, qq(<span style='color: $color'>$wbperson</span>);
                if ($two{name}{$two}) { push @names, qq(<span style='color: $color'>$two{name}{$two}</span>);} } } } }
        $pdfEmail = join", ", @emails;
        $pdfTwo   = join", ", @twos;
        $pdfName  = join", ", @names;
      }
    }
    next if ($recentlyEmailed);						# to filter by emails recently emailed
#     my $genes = join"<br/>", sort keys %{ $pap{$pap}{gene} };
    my @genes;
    foreach my $wbgene (sort keys %{ $pap{$pap}{gene} }) {
      my $locus = ''; if ($gin{$wbgene}) { $locus = $gin{$wbgene}; }
      push @genes, qq(WBGene$wbgene,$locus); }
    my $genes = join"<br/>", @genes;
    my $submitButton = ''; my $skipButton = '';
    if ( ($pmids) && ($emails || $cEmail || $afpEmail || $pdfEmail) ) {
      print qq(<form method="post" action="community_curation_tracker.cgi"\n>);
      print qq(<input type="hidden" name="papid"      value="$pap" />\n);
      print qq(<input type="hidden" name="pmids"      value="$pmids" />\n);
      print qq(<input type="hidden" name="aidname"    value="$aids{$aidFirstAuthor}{name}"/>\n);
      print qq(<input type="hidden" name="anames"     value="$personName"/>\n);
      print qq(<input type="hidden" name="atwos"      value="$person"/>\n);
      print qq(<input type="hidden" name="aemails"    value="$emails"/>\n);
      print qq(<input type="hidden" name="cnames"     value="$cName"/>\n);
      print qq(<input type="hidden" name="ctwos"      value="$cTwo"/>\n);
      print qq(<input type="hidden" name="cemails"    value="$cEmail"/>\n);
      print qq(<input type="hidden" name="afpnames"   value="$afpName"/>\n);
      print qq(<input type="hidden" name="afptwos"    value="$afpTwo"/>\n);
      print qq(<input type="hidden" name="afpemails"  value="$afpEmail"/>\n);
      print qq(<input type="hidden" name="pdfnames"   value="$pdfName"/>\n);
      print qq(<input type="hidden" name="pdftwos"    value="$pdfTwo"/>\n);
      print qq(<input type="hidden" name="pdfemails"  value="$pdfEmail"/>\n);
      print qq(<input type="hidden" name="pdfs"       value="$pdfs"/>\n);
      print qq(<input type="hidden" name="genes"      value="$genes"/>\n);
      print qq(<input type="hidden" name="datatype"   value="$datatype"/>\n);
      $submitButton = qq(<input type="submit" name="action" value="generate email">\n); 
      $skipButton   = qq(<input type="submit" name="action" value="skip paper">\n); 

      my $row = qq(<tr><td>$submitButton</td><td>$skipButton</td><td>WBPaper$pap\t</td><td>$pmids</td><td>$pdfs</td><td>$aids{$aidFirstAuthor}{name}\t</td><td>$personName\t</td><td>$person\t</td><td>$emails\t</td><td>$cName</td><td>$cTwo</td><td>$cEmail</td><td>$afpName</td><td>$afpTwo</td><td>$afpEmail</td><td>$pdfName</td><td>$pdfTwo</td><td>$pdfEmail</td></tr>\n);
      if ($datatype eq 'con') { $row = qq(<tr><td>$submitButton</td><td>$skipButton</td><td>WBPaper$pap\t</td><td>$pmids</td><td>$pdfs</td><td>$genes</td><td>$aids{$aidFirstAuthor}{name}\t</td><td>$personName\t</td><td>$person\t</td><td>$emails\t</td><td>$cName</td><td>$cTwo</td><td>$cEmail</td><td>$afpName</td><td>$afpTwo</td><td>$afpEmail</td><td>$pdfName</td><td>$pdfTwo</td><td>$pdfEmail</td></tr>\n); }
      print qq($row);
      print qq(</form>);
      $count++; last if ($count > $countThreshold);
    }
  }
  print qq(<table>);
#   print qq(COUNT $count found<br/>\n);
} # sub readyToGo


sub tracker {
  my ($var, $htmlOrText)          = &getHtmlVar($query, 'html_or_text');
  if ($htmlOrText eq 'text') { print qq(Content-type: text/plain\n\n); }
    else { 
      &printHtmlHeader();
      print qq(<a href="community_curation_tracker.cgi">start over</a><br/>\n); }

  my ($datatype) = @_;
#   ($var, my $datatype)       = &getHtmlVar($query, 'datatype');

  my %pap;
  my %com;
  my %gin;
  my %emailToPerson;

  $result = $dbh->prepare( "SELECT joinkey, LOWER(two_old_email) FROM two_old_email" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[1]) { $row[0] =~ s/two/WBPerson/; $emailToPerson{$row[1]} = $row[0]; } }
  $result = $dbh->prepare( "SELECT joinkey, LOWER(two_email) FROM two_email" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[1]) { $row[0] =~ s/two/WBPerson/; $emailToPerson{$row[1]} = $row[0]; } }
  
  $result = $dbh->prepare( "SELECT * FROM com_${datatype}_emailsent" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $com{$row[0]}{date}  = $row[2]; 
      my (@emails) = split/,/, $row[1];
      my @emailPersons = ();
      foreach my $email (@emails) { $email =~ s/\s+//g; my $lcemail = lc($email); push @emailPersons, qq($email \($emailToPerson{$lcemail}\)); }
      my $emailPersons = join", ", @emailPersons;
      $com{$row[0]}{email} = $emailPersons; } }
  $result = $dbh->prepare( "SELECT * FROM com_${datatype}_emailresponse" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $com{$row[0]}{response} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM com_${datatype}_remark" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $com{$row[0]}{remark} = $row[1]; } }
  $result = $dbh->prepare( "SELECT * FROM com_${datatype}_skip" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $com{$row[0]}{skip} = $row[1]; } }
  
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $row[1] =~ s/pmid//; $pap{$row[0]}{pmid}{$row[1]}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pap{$row[0]}{pdf}{$row[1]}++; } }
  
  if ($datatype eq 'app') {
    $result = $dbh->prepare( "SELECT * FROM app_paper WHERE app_paper ~ 'WBPaper' AND joinkey IN (SELECT joinkey FROM app_curator WHERE app_curator = 'WBPerson29819')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) {
        my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
        foreach (@paps) { $pap{$_}{communityCurated}{app}++; } } }
    $result = $dbh->prepare( "SELECT * FROM rna_paper WHERE rna_paper ~ 'WBPaper' AND joinkey IN (SELECT joinkey FROM rna_curator WHERE rna_curator = 'WBPerson29819')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      if ($row[0]) {
        my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
        foreach (@paps) { $pap{$_}{communityCurated}{rna}++; } } }
  } # if ($datatype eq 'app')

# Ranjana no longer needs to track concise descriptions through here
#   if ($datatype eq 'con') {
#     my %toWBGene;
#     $result = $dbh->prepare( "SELECT * FROM gin_locus ;" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) { 
#         $toWBGene{$row[1]} = $row[0];
#         $gin{$row[0]}      = $row[1]; } }
#     my $urlTextpressoPap  = 'http://textpresso-dev.caltech.edu/concise_descriptions/textpresso/textpresso_papers_results_genes.txt';
#     my $dataTextpressoPap = get $urlTextpressoPap;
#     my (@lines) = split/\n/, $dataTextpressoPap;
#     foreach my $line (@lines) {
#       my ($paper, $loci) = split/\t/, $line;
#       if ($paper =~ m/WBPaper(\d{8})/) {
#         my $pap = $1; 
#         $pap{$pap}{flaggeddatatype}++;
#         $loci =~ s/\(.*?\)//g;
#         my (@loci) = split/\s+/, $loci;
#         foreach my $locus (@loci) {
#           my $wbgene = $locus; if ($toWBGene{$locus}) { $wbgene = $toWBGene{$locus}; }
#           $pap{$pap}{gene}{$wbgene}++; } }
#     } # foreach my $line (@lines)
#     $result = $dbh->prepare( "SELECT con_paper.joinkey, con_paper.con_paper, con_wbgene.con_wbgene FROM con_paper, con_wbgene WHERE con_paper.joinkey = con_wbgene.joinkey AND con_paper ~ 'WBPaper' AND con_paper.joinkey IN (SELECT joinkey FROM con_person WHERE con_person IS NOT NULL)" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     while (my @row = $result->fetchrow) {
#       if ($row[0]) {
#         my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
#         foreach (@paps) { $pap{$_}{communityCurated}{$row[2]}++; } } }
#   } # if ($datatype eq 'con')

  my %filter;
  foreach my $pap (sort keys %pap) {
    next unless ($com{$pap}{email});
    $filter{$pap}++;
  } # foreach my $pap (sort keys %pap)

  foreach my $pap (sort keys %com) {			# get all skipped papers to show on tracker
    if ($com{$pap}{skip}) { $filter{$pap}++; } }

#     if ($htmlOrText eq 'html') {
#       $response =~ s/</&lt;/g; $response =~ s/>/&gt;/g;
#       $remark   =~ s/</&lt;/g; $remark   =~ s/>/&gt;/g; }

  my $header = qq(<thead><tr><th>email response</th><th>remark</th><th>allele-phenotype email date</th><th>email addresses sent request</th><th>community curated app</th><th>community curated rna</th><th>WBPaper</th><th>pmids</th><th>pdfs</th></tr></thead><tbody>\n); 
   if ($datatype eq 'con') { $header = qq(<thead><tr><th>email response</th><th>remark</th><th>concise email date</th><th>email addresses sent request</th><th>community curated</th><th>WBPaper</th><th>pmids</th><th>pdfs</th><th>genes</th></tr></thead><tbody>\n); }
  my $headerText = $header; 
  $headerText =~ s/<\/th><th>/\t/g; $headerText =~ s/<thead><tr><th>//; $headerText =~ s/<\/th><\/tr><\/thead><tbody>//;

  if ($htmlOrText eq 'html') {
      ($var, my $action) = &getHtmlVar($query, 'action');
      print qq(Download table <a href="community_curation_tracker.cgi?action=$action&html_or_text=text" download="community_curation_tracker.txt">link</a><br />\n);
      print qq(<table id="sortabletable" style="border-style: none;" border="1">\n);
      print qq($header); }
    else { print qq($headerText); }

  foreach my $pap (reverse sort keys %filter) {
    my $rowHtml = '';
    my $pmids = join", ", sort keys %{ $pap{$pap}{pmid} };
    my @pdfs;
    foreach my $path (sort keys %{ $pap{$pap}{pdf} }) {
      my ($pdfname) = $path =~ m/\/([^\/]*?)$/;
      my $url = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdfname;
      my $link = qq(<a href="$url" target="new">$pdfname</a>);
      push @pdfs, $link; }
    my $pdfs = join" ", @pdfs;
    $rowHtml .= qq(<form method="post" action="community_curation_tracker.cgi"\n>);
    $rowHtml .= qq(<input type="hidden" name="pmids"   value="$pmids" />\n);
    my $communityCurated     = 'NOT'; 
    my $communityCuratedRnai = 'NOT'; 
    if ($datatype eq 'app') {
      if ($pap{$pap}{communityCurated}{app}) { $communityCurated     = 'curated'; }
      if ($pap{$pap}{communityCurated}{rna}) { $communityCuratedRnai = 'curated'; } }
    if ($datatype eq 'con') {
      if (scalar keys %{ $pap{$pap}{communityCurated}} > 0) {
        my @genes;
        foreach my $wbgene (sort keys %{ $pap{$pap}{communityCurated} }) {
          $wbgene =~ s/WBGene//;
          my $locus = ''; if ($gin{$wbgene}) { $locus = $gin{$wbgene}; }
          push @genes, qq(WBGene$wbgene,$locus); }
        $communityCurated = join"<br/>", @genes; } }
    if ($com{$pap}{skip}) { $communityCurated = 'skip'; }
    my $textareacols = '40';
    my $response = ''; if ($com{$pap}{response}) { $response = $com{$pap}{response}; }
    my $responseAjaxUrl = "community_curation_tracker.cgi?action=ajaxUpdate&papid=$pap&field=emailresponse&datatype=$datatype&value=";
    my $responseInput = qq(<input name="response" id="${pap}_inputresponse" value="$response" onfocus="document.getElementById('${pap}_inputresponse').style.display = 'none'; document.getElementById('${pap}_textarearesponse').style.display = ''; document.getElementById('${pap}_textarearesponse').focus(); "/>);
    my $responseTextarea = qq(<textarea id="${pap}_textarearesponse" rows="5" cols="$textareacols" style="display:none;" onblur="document.getElementById('${pap}_inputresponse').style.display = ''; document.getElementById('${pap}_textarearesponse').style.display = 'none'; var inputValue = document.getElementById('${pap}_inputresponse').value; var textareaValue = document.getElementById('${pap}_textarearesponse').value; if (inputValue !== textareaValue) { document.getElementById('${pap}_inputresponse').value = textareaValue; var ajaxUrl = '${responseAjaxUrl}' + document.getElementById('${pap}_textarearesponse').value; \$.ajax({ url: ajaxUrl }); }" >$response</textarea>);
    my $remark = ''; if ($com{$pap}{remark}) { $remark = $com{$pap}{remark}; }
    my $remarkAjaxUrl = "community_curation_tracker.cgi?action=ajaxUpdate&papid=$pap&field=remark&datatype=$datatype&value=";
    my $remarkInput = qq(<input name="remark" id="${pap}_inputremark" value="$remark" onfocus="document.getElementById('${pap}_inputremark').style.display = 'none'; document.getElementById('${pap}_textarearemark').style.display = ''; document.getElementById('${pap}_textarearemark').focus(); "/>);
    my $remarkTextarea = qq(<textarea id="${pap}_textarearemark" rows="5" cols="$textareacols" style="display:none;" onblur="document.getElementById('${pap}_inputremark').style.display = ''; document.getElementById('${pap}_textarearemark').style.display = 'none'; var inputValue = document.getElementById('${pap}_inputremark').value; var textareaValue = document.getElementById('${pap}_textarearemark').value; if (inputValue !== textareaValue) { document.getElementById('${pap}_inputremark').value = textareaValue; var ajaxUrl = '${remarkAjaxUrl}' + document.getElementById('${pap}_textarearemark').value; \$.ajax({ url: ajaxUrl }); }" >$remark</textarea>);
    my $emailedDate      = ''; if ($com{$pap}{date}) {  ($emailedDate)    = $com{$pap}{date} =~ m/^([\d\-]{10})/;  }
    my $emailedAddresses = ''; if ($com{$pap}{email}) { $emailedAddresses = $com{$pap}{email}; }
    my $genes = '';
    if ($datatype eq 'con') {
      my @genes;
      foreach my $wbgene (sort keys %{ $pap{$pap}{gene} }) {
        my $locus = ''; if ($gin{$wbgene}) { $locus = $gin{$wbgene}; }
        push @genes, qq(WBGene$wbgene,$locus); }
        $genes = join"<br/>", @genes; }
    my $rowHtml = qq(<tr><td>${responseInput}${responseTextarea}</td><td>${remarkInput}${remarkTextarea}</td><td>$emailedDate</td><td>$emailedAddresses</td><td>$communityCurated</td><td>$communityCuratedRnai</td><td>WBPaper$pap</td><td>$pmids</td><td>$pdfs</td></tr>\n); 
    my $rowText = qq($response\t$remark\t$emailedDate\t$emailedAddresses\t$communityCurated\t$communityCuratedRnai\tWBPaper$pap\t$pmids\t$pdfs); 
    if ($datatype eq 'con') { 
      $rowHtml = qq(<tr><td>${responseInput}${responseTextarea}</td><td>${remarkInput}${remarkTextarea}</td><td>$emailedDate</td><td>$emailedAddresses</td><td>$communityCurated</td><td>WBPaper$pap\t</td><td>$pmids</td><td>$pdfs</td><td>$genes</td></tr>\n);
      $rowText = qq($response\t$remark\t$emailedDate\t$emailedAddresses\t$communityCurated\tWBPaper$pap\t\t$pmids\t$pdfs\t$genes); }
    if ($htmlOrText eq 'html') { 
        print qq($rowHtml);
        print qq(</form>); }
      else { print qq($rowText\n); }
  }
  if ($htmlOrText eq 'html') { print qq(</tbody></table>); }
} # sub tracker
  
sub asdf {
  1;
}

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

sub printHtmlMenu {		# show main menu page
  &printHtmlHeader();
  my $date = &getPgDate; my ($thisyear) = $date =~ m/^(\d{4})/;
  print <<"  EndOfText";
  <FORM METHOD="POST" ACTION="community_curation_tracker.cgi">
  <TABLE border=0>
  <TR>
    <TD COLSPAN=3><B>Html or Text : </B></TD>
    <TD><INPUT NAME="html_or_text" TYPE="radio" VALUE="html" CHECKED>html</TD>
    <TD><INPUT NAME="html_or_text" TYPE="radio" VALUE="text">text<br/></TD>
  </TR>
  <TR>
    <TD COLSPAN=3><B>Mass Email : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Mass Email"></TD>
    <TD>
    <INPUT TYPE="submit" NAME="action" VALUE="Mass Email Tracker"><br/>
    Year: <select name="year_selected">
  EndOfText
    for my $year (2018 .. $thisyear) {
      my $selected = ''; if ($year == $thisyear) { $selected = 'selected' } else { $selected = ''; }
      print qq(<option $selected>$year</option>); }
  print <<"  EndOfText";
  </select><br/></td>
  </TR>
  <TR>
    <TD COLSPAN=3><B>New Mutant : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="New Mutant Ready"></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="New Mutant Tracker"></TD>
  </TR>
<!--
  <TR>
    <TD COLSPAN=3><B>Concise Description : </B></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Concise Description Ready"></TD>
    <TD><INPUT TYPE="submit" NAME="action" VALUE="Concise Description Tracker"></TD>
  </TR>-->
<!--
  <TR><TD><B>OR</B></TD></TR>
  <TR>
    <TD COLSPAN=3><B>Query Variation : </B></TD>
    <TD><textarea rows=5 cols=40 name=variations></textarea><br /><INPUT TYPE="submit" NAME="action" VALUE="Query Variation !"></TD>
  </TR>-->
  EndOfText
  print "</TABLE>\n";
  print "</FROM>\n";
} # sub printHtmlMenu


sub populateCurators {
  $curator{name_to_joinkey}{"Igor Antoshechkin"} = 'two22';
  $curator{name_to_joinkey}{"Juancarlos Chan"} = 'two1823';
  $curator{name_to_joinkey}{"Wen Chen"} = 'two101';
  $curator{name_to_joinkey}{"Paul Davis"} = 'two1983';
  $curator{name_to_joinkey}{"Jolene S. Fernandes"} = 'two2021';
  $curator{name_to_joinkey}{"Chris"} = 'two2987';
  $curator{name_to_joinkey}{"Ranjana Kishore"} = 'two324';
  $curator{name_to_joinkey}{"Raymond Lee"} = 'two363';
  $curator{name_to_joinkey}{"Cecilia Nakamura"} = 'two1';
  $curator{name_to_joinkey}{"Tuco"} = 'two480';
  $curator{name_to_joinkey}{"Anthony Rogers"} = 'two1847';
  $curator{name_to_joinkey}{"Gary C. Schindelman"} = 'two557';
  $curator{name_to_joinkey}{"Erich Schwarz"} = 'two567';
  $curator{name_to_joinkey}{"Paul Sternberg"} = 'two625';
  $curator{name_to_joinkey}{"Mary Ann Tuli"} = 'two2970';
  $curator{name_to_joinkey}{"Kimberly Van Auken"} = 'two1843';
  $curator{name_to_joinkey}{"Qinghua Wang"} = 'two736';
  $curator{name_to_joinkey}{"Xiaodong Wang"} = 'two1760';
  $curator{name_to_joinkey}{"Karen Yook"} = 'two712';
  $curator{joinkey_to_name}{'two22'} = "Igor Antoshechkin";
  $curator{joinkey_to_name}{'two1823'} = "Juancarlos Chan";
  $curator{joinkey_to_name}{'two101'} = "Wen Chen";
  $curator{joinkey_to_name}{'two1983'} = "Paul Davis";
  $curator{joinkey_to_name}{'two2021'} = "Jolene S. Fernandes";
  $curator{joinkey_to_name}{'two2987'} = "Chris";
  $curator{joinkey_to_name}{'two324'} = "Ranjana Kishore";
  $curator{joinkey_to_name}{'two363'} = "Raymond Lee";
  $curator{joinkey_to_name}{'two1'} = "Cecilia Nakamura";
  $curator{joinkey_to_name}{'two480'} = "Tuco";
  $curator{joinkey_to_name}{'two1847'} = "Anthony Rogers";
  $curator{joinkey_to_name}{'two557'} = "Gary C. Schindelman";
  $curator{joinkey_to_name}{'two567'} = "Erich Schwarz";
  $curator{joinkey_to_name}{'two625'} = "Paul Sternberg";
  $curator{joinkey_to_name}{'two2970'} = "Mary Ann Tuli";
  $curator{joinkey_to_name}{'two1843'} = "Kimberly Van Auken";
  $curator{joinkey_to_name}{'two736'} = "Qinghua Wang";
  $curator{joinkey_to_name}{'two1760'} = "Xiaodong Wang";
  $curator{joinkey_to_name}{'two712'} = "Karen Yook";
} # sub populateCurators



__END__
