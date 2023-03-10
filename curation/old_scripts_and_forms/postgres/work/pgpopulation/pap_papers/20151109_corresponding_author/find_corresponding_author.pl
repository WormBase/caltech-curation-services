#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $directory = '/home/postgres/work/pgpopulation/pap_papers/20151109_corresponding_author/convert_dir/';
chdir($directory) or die "Cannot change to $directory : $!";

my %pap;
my %afp;

$result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_email IS NOT NULL;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[1] =~ m/\n/) { $row[1] =~ s/\n/, /g; }
    my ($lcemail) = lc($row[1]); $afp{$row[0]} = $lcemail; } }


my $urlAnyFlaggedNCur = 'http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_curator=two1823&listDatatype=newmutant&method=any%20pos%20ncur&checkbox_cfp=on&checkbox_afp=on&checkbox_str=on&checkbox_svm=on';
my $dataAnyFlaggedNCur = get $urlAnyFlaggedNCur;
my (@papers) = $dataAnyFlaggedNCur =~ m/specific_papers=WBPaper(\d+)/g;
foreach (@papers) { $pap{$_}{flagnoncur}++; }

# $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { $row[1] =~ s/pmid//; $pap{$row[0]}{pmid}{$row[1]}++; } }
$result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{$row[0]}{pdf}{$row[1]}++; } }

my $count = 0;
foreach my $pap (sort {$b<=>$a} keys %pap) {
  next unless ($pap{$pap}{flagnoncur});
  my $sourcepdf = ''; my $bestpdf = ''; my $temppdf = '';
  my @pdfs;
  foreach my $path (sort keys %{ $pap{$pap}{pdf} }) {
    if ($path =~ m/\d\.pdf/) {           $bestpdf = $path; }
      elsif ($path =~ m/\d_temp\.pdf/) { $temppdf = $path; }
#     my ($pdfname) = $path =~ m/\/([^\/]*?)$/;
#     my $url = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdfname;
#     my $link = qq(<a href="$url" target="new">$pdfname</a>);
#     push @pdfs, $link; 
  }
  if ($bestpdf) {      $sourcepdf = $bestpdf; }
    elsif ($temppdf) { $sourcepdf = $temppdf; }
#   my $pdfs = join" ", @pdfs;
  my ($pdfname) = $sourcepdf =~ m/\/([^\/]*?)$/;
  next unless ($pdfname);
  my $workpdf = $directory . $pdfname;
  my $worktxt = $workpdf; $worktxt =~ s/\.pdf/\.txt/;
  unless (-e $worktxt) {
#     print qq($sourcepdf\n);
    `cp $sourcepdf $workpdf`;
    `pdftotext $workpdf`; 
  }
  my $email = ''; my @emails;
  next unless (-e $worktxt);			# some pdfs won't convert
  $/ = undef;					# to get all email addresses, comment out to get only in first line
  open (IN, "<$worktxt") or die "Cannot open $worktxt : $!";
  while (my $line = <IN>) {
    if ($line =~ m/(\S+@\S+)/) { (@emails) = $line =~ m/(\S+@\S+)/g; last; }
  } # while (my $line = <IN>)
  $/ = "\n";
  my @cleanEmails; my %filter;
  foreach my $email (@emails) {
    $email =~ s/\W+$//;
    if ($email =~ m/:/) { ($email) = $email =~ m/:(.*)/; }
    $email =~ s/^\W+//;
    unless ($filter{$email}) { push @cleanEmails, $email; }	# looking at whole file, emails may show up multiple times, but keep order
    $filter{$email}++; 
  } # foreach my $email (@emails)
  my $emails = join", ", @cleanEmails;
  ($emails) = lc($emails);
  close (IN) or die "Cannot close $worktxt : $!";
  my $afpEmail = '';
  if ($afp{$pap}) { $afpEmail = $afp{$pap}; }
  print qq($pap\t$emails\t$afpEmail\t$worktxt\n);
#   if ($afpEmail ne $emails) {
#     print qq($pap\t$emails\t$afpEmail\t$worktxt\n);
#   }
#   $count++; last if ($count > 33);
}


