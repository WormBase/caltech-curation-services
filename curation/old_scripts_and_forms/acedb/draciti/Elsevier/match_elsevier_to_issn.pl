#!/usr/bin/perl -w

# look at list of journals in Elsevier_journal_list.txt get PMID look at XML for ISSN

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pmid_path;

my (@xml) = </home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final/xml/*>;
my (@done_xml) = </home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/*>;

foreach my $file (@xml, @done_xml) {
  my ($pmid) = $file =~ m/\/(\d+)$/;
  $pmid_path{$pmid} = $file;
} # foreach my $file (@xml @done_xml)

my %journal;			# ISSNs for this journal

my $els_file = 'Elsevier_journal_list.txt';
open (IN, "<$els_file") or die "Cannot open $els_file : $!";
while (my $journal = <IN>) { 
  chomp $journal;
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN (SELECT joinkey FROM pap_journal WHERE pap_journal = '$journal')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my $found = 0;
  while (my @row = $result->fetchrow) {
#     print "$journal\t$row[0]\t$row[1]\n";
    my $pmid = $row[1];
    $pmid =~ s/pmid//;
    if ( $pmid_path{$pmid} ) {
      $found++;
      my $path = $pmid_path{$pmid};
      $/ = undef;
      open (FI, "<$path") or die "Cannot open $path : $!";
      my $all_file = <FI>;
      close (FI) or die "Cannot close $path : $!";
      $/ = "\n";
      my ($issn) = $all_file =~ m/<ISSN IssnType=\"Electronic\">(.*?)<\/ISSN>/;
      unless ($issn) { $issn = "NO_ISSN_TYPE"; }
      if ($issn) {  $journal{$journal}{issn1}{$issn}++; }
      my ($issn2) = $all_file =~ m/<ISSNLinking>(.*?)<\/ISSNLinking>/;
      unless ($issn2) { $issn2 = "NO_ISSN_LINK"; }
      if ($issn2) { $journal{$journal}{issn2}{$issn2}++; }
#     } else {
#       $journal{$journal}{issn1}{"NOPMID"}++;
#       $journal{$journal}{issn2}{"NOPMID"}++; 
    }
  }
  unless ($found) { 
#     print "NOT FOUND $journal\n";
    $journal{$journal}{issn1}{"NOT_IN_POSTGRES"}++; }
} # while (my $journal = <IN>)
close (IN) or die "Cannot close $els_file : $!";

foreach my $journal (sort keys %journal) {
  my @issn1 = sort keys %{ $journal{$journal}{issn1} };
  my $issn1 = join ", ", @issn1;
  my @issn2 = sort keys %{ $journal{$journal}{issn2} };
  my $issn2 = join ", ", @issn2;
  print "$journal\t$issn1\t$issn2\n";
} # foreach my $journal (sort keys %journal)

__END__

<ISSN IssnType="Electronic">1097-4172</ISSN>



my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

