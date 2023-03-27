#!/usr/bin/perl -w

# generate list of papers from this criteria for Ranjana.
# http://wiki.wormbase.org/index.php/Contacting_the_Community#Criteria_for_choosing_papers_for_community_gene_descriptions
# 2015 10 07

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pap;
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
$result = $dbh->prepare( "SELECT * FROM pap_primary_data WHERE pap_primary_data = 'primary';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{$row[0]}{primary}++; } }
$result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_gene ~ '0';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{$row[0]}{gene}++; } }

$result = $dbh->prepare( "SELECT * FROM afp_email WHERE afp_timestamp > current_date - interval '3 months' " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{$row[0]}{afp}++; } }
$result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'emailed_community_gene_descrip'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{$row[0]}{done}++; } }
$result = $dbh->prepare( "SELECT * FROM con_paper WHERE con_paper ~ 'WBPaper'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    my (@paps) = $row[1] =~ m/WBPaper(\d+)/g;
    foreach (@paps) { $pap{$_}{curated}++; } } }

my %filter;
foreach my $pap (sort keys %pap) {
  next unless ($pap{$pap}{valid});
  next unless ($pap{$pap}{pubmedfinal});
  next unless ($pap{$pap}{journalarticle});
  next unless ($pap{$pap}{pdf});
  next unless ($pap{$pap}{primary});
  next unless ($pap{$pap}{gene});

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

my $outfile = '/home/acedb/public_html/ranjana/concise_list_to_email.html';
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT "<html><table>";
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
  if ($aids{$aid}{ver}) { 
    my $join = $aids{$aid}{ver}; 
    if ($aids{$aid}{two}{$join}) {
      my $two    = $aids{$aid}{two}{$join};
      my $person = $two; $person =~ s/two/WBPerson/;
      my $emails = join", ", @{ $twoEmail{$two} };
      print OUT qq(<tr><td>WBPaper$pap\t</td><td>$aids{$aid}{name}\t</td><td>$person\t</td><td>$emails\t</td><td>$pdfs</td><td>$pmids</td></tr>\n); 
    }
  }
} 
print OUT "</table></html>";
close (OUT) or die "Cannot open $outfile : $!";



