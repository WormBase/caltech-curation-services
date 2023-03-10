#!/usr/bin/perl -w

# look at the DOIs get the papers, the PMIDs, and find the XML's DOI and PII.  2011 10 05
#
# Daniela doesn't want PIIs anymore.  2011 10 17
#
# Original script was never used.  Revisited to enter DOIs that never happenned due to the DOI service we used going down.  
# Live run on tazendra.  2014 07 22

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

my %pii_pm;			# pii values already entered in postgres
my %doi_pm;			# doi values already entered in postgres
my %paper_doi_pg;		# papers have doi in postgres, regardless of the doi value

my %pap_pmid;			# joinkey to pmid mapping
my %pmid_pap;			# pmid to joinkey mapping

my %ident_order;		# highest existing order used in pap_identifier by joinkey

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/pmid//;
  $pmid_pap{$row[1]} = $row[0];
  $pap_pmid{$row[0]} = $row[1]; } }

# $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^doi' AND pap_curator = 'two10877'" );
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^doi'" );	# don't enter the same doi multiple times by different curator
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $paper_doi_pg{$row[0]}++; $doi_pm{$row[1]}{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^pii' AND pap_curator = 'two10877'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $pii_pm{$row[1]}{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $ident_order{$row[0]} = $row[2]; } }

my %joinkeys;

foreach my $pmid (sort keys %pmid_path) {
#   unless ($pmid_pap{$pmid}) { print "NO WBPaper for $pmid\n"; }
  next unless ($pmid_pap{$pmid});
  my $joinkey = $pmid_pap{$pmid};
  $joinkeys{$joinkey}{$pmid}++;
} # foreach my $pmid (sort keys %pmid_path)

my @pgcommands;
$/ = undef;
foreach my $joinkey (sort keys %joinkeys) {
  my $order = $ident_order{$joinkey};
  my @doi; my @pii;
  foreach my $pmid (sort keys %{ $joinkeys{$joinkey} }) {
    my ($doi, $pii) = &getDoiPoi($pmid_path{$pmid});
    if ($doi) { push @doi, $doi; }
    if ($pii) { push @pii, $pii; }
  } # foreach my $pmid (sort keys %{ $joinkeys{$joinkey} })
  if (scalar @doi > 1) { print "Too many DOIs @doi for $joinkey\n"; }
  if (scalar @pii > 1) { print "Too many PIIs @pii for $joinkey\n"; }
  if ($doi[0]) { 
    next if ($paper_doi_pg{$joinkey});
#     next if ($doi_pm{"doi$doi[0]"}{$joinkey});		# skip those already entered by pubmed curator
    $order++; 
    push @pgcommands, "INSERT INTO pap_identifier VALUES ('$joinkey', 'doi$doi[0]', $order, 'two10877')";
    push @pgcommands, "INSERT INTO h_pap_identifier VALUES ('$joinkey', 'doi$doi[0]', $order, 'two10877')"; }
#   if ($pii[0]) {
#     next if ($pii_pm{"pii$pii[0]"}{$joinkey});		# skip those already entered by pubmed curator
#     $order++; 
#     push @pgcommands, "INSERT INTO pap_identifier VALUES ('$joinkey', 'pii$pii[0]', $order, 'two10877')";
#     push @pgcommands, "INSERT INTO h_pap_identifier VALUES ('$joinkey', 'pii$pii[0]', $order, 'two10877')"; }
#   print "$joinkey\t$order\t$doi[0]\t$pii[0]\n";
} # foreach my $joinkey (sort keys %joinkeys)
$/ = "\n";

foreach my $pgcommand (@pgcommands) { 
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub getDoiPoi {
  my ($path) = @_;
  $/ = undef;
  open (IN, "<$path") or die "Cannot open $path : $!";
  my $all_file = <IN>;
  close (IN) or die "Cannot close $path : $!";
  $/ = "\n";
  my ($artIdList) = $all_file =~ m/<ArticleIdList>(.*?)<\/ArticleIdList>/ms;
  unless ($artIdList) { return; }
#   unless ($artIdList) { print "NO ArticleIdList $path\n"; }
  my $doi; my $pii;
  if ($artIdList =~ m/<ArticleId IdType=\"pii\">(.*?)<\/ArticleId>/) { $pii = $1; }
  if ($artIdList =~ m/<ArticleId IdType=\"doi\">(.*?)<\/ArticleId>/) { $doi = $1; }
  return ($doi, $pii);
} # sub getDoiPoi


__END__

