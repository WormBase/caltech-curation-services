#!/usr/bin/perl -w

# look at the DOIs get the papers, the PMIDs, and find the XML's DOI and PII.  2011 10 05

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pmid_path;

my (@xml) = </home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final/xml/*>;
my (@done_xml) = </home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/done/*>;

foreach my $file (@xml, @done_xml) {
  my ($pmid) = $file =~ m/\/(\d+)$/;
  $pmid_path{$pmid} = $file;
} # foreach my $file (@xml @done_xml)

my %pap_pmid;
my %doi_pap;

my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^doi'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $doi_pap{$row[1]} = $row[0]; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/pmid//;
  $pap_pmid{$row[0]} = $row[1]; } }

foreach my $pdoi (sort keys %doi_pap) {
  my $pap = $doi_pap{$pdoi};
#   unless ($pap_pmid{$pap}) { print "NO PMID FOR this doi $pdoi\n"; next; }
  next unless ($pap_pmid{$pap});
  my $pmid = $pap_pmid{$pap};
  unless ($pmid_path{$pmid}) { print "NO XML for $pmid\n"; }
  next unless $pmid_path{$pmid};
  my $path = $pmid_path{$pmid};
  my ($doi, $pii) = &getDoiPoi($path);
  unless ($pii) { print "NO PII $pmid\t$pap\t$doi\t$path\n"; }
  $pdoi =~ s/^doi//;
  unless ($doi eq $pdoi) { 
    print "$pap has $pdoi in postgres $doi in xml\n"; }
#   print "$pmid\t$pap\t$doi\t$pii\t$path\n";
} # foreach my $pap (sort keys %pap_pmid)

sub getDoiPoi {
  my ($path) = @_;
  $/ = undef;
  open (IN, "<$path") or die "Cannot open $path : $!";
  my $all_file = <IN>;
  close (IN) or die "Cannot close $path : $!";
  $/ = "\n";
  my ($artIdList) = $all_file =~ m/<ArticleIdList>(.*?)<\/ArticleIdList>/ms;
  my $doi; my $pii;
  if ($artIdList =~ m/<ArticleId IdType=\"pii\">(.*?)<\/ArticleId>/) { $pii = $1; }
  if ($artIdList =~ m/<ArticleId IdType=\"doi\">(.*?)<\/ArticleId>/) { $doi = $1; }
  return ($doi, $pii);
} # sub getDoiPoi

__END__

