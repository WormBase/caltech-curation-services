#!/usr/bin/env perl

# generate list of papers from this criteria for Chris.
# http://wiki.wormbase.org/index.php/Contacting_the_Community#Criteria_for_choosing_papers_for_allele-phenotype_requests
# 2015 10 11
#
# add afp_email email address, matching two_email person + person standardname.  2015 10 13
#
# when checking on afp_email in past 3 months, do it by email address, not by paper.  2015 10 14
#
# dockerized, but this was originally just at ~postgres/ instead of in get_stuff/ as it should have been.
# now outputs to local directory instead of public_html/ so might need to figure out where to output
# to pub/ somewhere it can be seen if Chris needs that.  2023 03 13


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pap;
my %afpemail;			# email addresses sent in the last 3 months
my %email;
my %two;

my $urlAnyFlaggedNCur = $ENV{THIS_HOST} . 'priv/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_curator=two1823&listDatatype=newmutant&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
# my $urlAnyFlaggedNCur = 'http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_curator=two1823&listDatatype=newmutant&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
my $dataAnyFlaggedNCur = get $urlAnyFlaggedNCur;
my (@papers) = $dataAnyFlaggedNCur =~ m/specific_papers=WBPaper(\d+)/g;
foreach (@papers) { $pap{$_}{flagnoncur}++; }

$result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_email IS NOT NULL;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { my ($lcemail) = lc($row[1]); $email{afp}{$row[0]} = $lcemail; } }
$result = $dbh->prepare( "SELECT * FROM two_email" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { my ($lcemail) = lc($row[2]); $email{two}{$lcemail} = $row[0]; } }
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
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '1'" );
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

$result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_timestamp > current_date - interval '3 months' " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@afpemails) = split/\s+/, $row[1];
    foreach my $afpemail (@afpemails) {
      $afpemail =~ s/,//g; $afpemail{$afpemail}++; } } }
# $result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_timestamp > current_date - interval '3 months' " );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { $pap{$row[0]}{afp}++; } }
# $result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'emailed_community_gene_descrip'" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { $pap{$row[0]}{done}++; } }
$result = $dbh->prepare( "SELECT * FROM app_paper WHERE app_paper ~ 'WBPaper'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
    foreach (@paps) { $pap{$_}{curated}++; } } }

my %filter;
foreach my $pap (sort keys %pap) {
  next unless ($pap{$pap}{flagnoncur});
  next unless ($pap{$pap}{valid});
  next unless ($pap{$pap}{pubmedfinal});
  next unless ($pap{$pap}{journalarticle});
  next unless ($pap{$pap}{pdf});

  next if ($pap{$pap}{email});
  next if ($pap{$pap}{done});
  next if ($pap{$pap}{curated});
  $filter{$pap}++;
} # foreach my $pap (sort keys %pap)

my %twoEmail;
$result = $dbh->prepare( "SELECT * FROM two_email ORDER BY joinkey, two_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { push @{ $twoEmail{$row[0]} }, $row[2]; } }

# foreach my $pap (sort keys %filter) { print qq($pap\n); } 

my %aids;
my $joinkeys = join"','", sort keys %filter;
$result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey IN ('$joinkeys');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{$row[0]}{aid} = $row[1]; $aids{$row[1]}{any}++; } }
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

my $outfile = 'newmutant_list_to_email.html';
# my $outfile = '/home/acedb/public_html/chris/newmutant_list_to_email.html';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT qq(<html><table border="1">);
foreach my $pap (reverse sort keys %filter) {
  my $aid = ''; if ($pap{$pap}{aid}) { $aid = $pap{$pap}{aid}; }
  my $pmids = join", ", sort keys %{ $pap{$pap}{pmid} };
  my @pdfs;
  foreach my $path (sort keys %{ $pap{$pap}{pdf} }) {
    my ($pdfname) = $path =~ m/\/([^\/]*?)$/;
    my $url = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdfname;
    my $link = qq(<a href="$url" target="new">$pdfname</a>);
    push @pdfs, $link; }
  my $pdfs = join" ", @pdfs;
  my ($two, $personName, $person, $emails) = ('', '', '', '');
  if ($aids{$aid}{ver}) { 
    my $join = $aids{$aid}{ver}; 
    if ($aids{$aid}{two}{$join}) {
      $two         = $aids{$aid}{two}{$join};
      $personName  = $two{name}{$two}; 
      $person      = $two; $person =~ s/two/WBPerson/;
      $emails      = join", ", @{ $twoEmail{$two} };
    }
  }
  my ($cEmail, $cTwo, $cName) = ('', '', '');	# generate from afp_email the person id and name
  my $recentlyEmailed = 0;
  if ($email{afp}{$pap}) {    
    my @emails; my @twos; my @names;
    my (@afpemails) = split/\s+/, $email{afp}{$pap};
    foreach my $afpemail (@afpemails) {
      my ($two, $name) = ('', '');
      $afpemail =~ s/,//g;
      if ($afpemail{$afpemail}) { $recentlyEmailed++; }
      if ($email{two}{$afpemail}) {
        $two   = $email{two}{$afpemail}; 
        if ($two{name}{$two}) { 
          $name  = $two{name}{$two}; } }
      my $wbperson = $two; $wbperson =~ s/two/WBPerson/g;
      push @emails, $afpemail; push @twos, $wbperson; push @names, $name;
    }
    $cEmail = join", ", @emails;
    $cTwo   = join", ", @twos;
    $cName  = join", ", @names;
  }
  next if ($recentlyEmailed);
  print OUT qq(<tr><td>WBPaper$pap\t</td><td>$pmids</td><td>$aids{$aid}{name}\t</td><td>$personName\t</td><td>$person\t</td><td>$emails\t</td><td>$cName</td><td>$cTwo</td><td>$cEmail</td><td>$pdfs</td></tr>\n); 
} 
print OUT "</table></html>";
close (OUT) or die "Cannot open $outfile : $!";



