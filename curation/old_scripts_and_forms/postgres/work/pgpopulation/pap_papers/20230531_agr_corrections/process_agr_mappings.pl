#!/usr/bin/perl -w

# take a list of PMIDs from Kimberly after going through differences between ABC and WB postgres,
# take mappings from ABC  agrkb->pmid agrkb->agrkb (comment correction), mappings from postgres
# wbp->pmid  and create pap_erratum_in.  Some papers don't have the pmid in Caltech postgres and
# Kimberly will deal with those manually.  2023 05 31


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pmids = qw( 27154433 29195124 19322353 25699681 25742442 25995025 26018900 26075908 26123112 26186524 26199050 26200340 26272998 26354977 26366869 26394001 26394399 26448567 26472915 26496836 26527203 26754975 26773128 26779766 26812166 26858445 26887572 26940883 26998588 27053124 27091988 27161120 27186651 27199683 27259058 27270701 27315557 27546571 27611795 27681440 27716778 27767314 27851730 28135330 28253172 28265088 28446204 28722650 28903539 28958135 28973870 28980937 29186542 29300951 29378783 29398010 29449617 29520042 29595188 29596525 29611099 29618594 29727664 29972787 30014746 30054291 30161120 30264564 30643216 30778531 30860672 30936176 31112701 31164751 31189735 31211967 31420004 31488913 31527152 31582857 31641239 31644902 31791661 31874958 31904130 31970719 32066719 32127597 32240648 32246130 32259491 32392217 32482730 32499511 32517851 32541926 32636309 32694680 32788717 32792670 32818474 32820264 32842787 32857619 32957446 32958656 32968790 33049908 33061934 33077719 33219230 33315465 33433002 33461481 33526707 33710400 33846265 33854240 34021339 34100189 34137639 34145433 34163038 34312490 34357389 34370007 34370030 34385439 34524417 34548611 34605047 34614410 34625497 34873162 34880238 34907327 34932600 35411089 35665632 );

my %pmidToWbp;

my %pap_erratum_in_order;
$result = $dbh->prepare( "SELECT * FROM pap_erratum_in ORDER BY pap_order;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pap_erratum_in_order{$row[0]} = $row[2]; }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[1] =~ s/pmid//;
    $pmidToWbp{$row[1]} = $row[0];
  } # if ($row[0])
} # while (@row = $result->fetchrow)


my %pmidToAgr;
my %agrToPmid;
my %agrComCor;

my $infile = 'agr_pmid_comcor';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@line) = split/\t/, $line;
  if ($line =~ m/^PMID/) { $line[2] =~ s/PMID://; $pmidToAgr{$line[2]} = $line[1]; $agrToPmid{$line[1]} = $line[2]; }
    elsif ($line =~ m/^COMCOR/) { $agrComCor{$line[1]}{$line[2]}{$line[3]}++; }
}
close (IN) or die "Cannot open $infile : $!";

my @pgcommands;
foreach my $pmid (sort @pmids) {
  my $agr = '';
  if ($pmidToAgr{$pmid}) { $agr = $pmidToAgr{$pmid}; }
    else { print qq(NO value for $pmid\n); }
  foreach my $type (sort keys %{ $agrComCor{$agr} }) {
    foreach my $otherAgr (sort keys %{ $agrComCor{$agr}{$type} }) {
      my $otherPmid = $agrToPmid{$otherAgr};
      my $otherWbp = $pmidToWbp{$otherPmid};
      print qq($pmid\t$pmidToWbp{$pmid}\t$agr\t$type\t$otherAgr\t$otherPmid\t$otherWbp\n);
      if ($otherWbp) {
        my $joinkey = $otherWbp; my $erratum_in = $pmidToWbp{$pmid};
        if ($type eq 'ErratumIn') { $joinkey = $pmidToWbp{$pmid}; $erratum_in = $otherWbp; }
        my $order = 1;
        if ($pap_erratum_in_order{$joinkey}) { $pap_erratum_in_order{$joinkey}++; $order = $pap_erratum_in_order{$joinkey}; }
        push @pgcommands, qq(INSERT INTO pap_erratum_in VALUES ('$joinkey', '$erratum_in', '$order', 'two1843'););
        push @pgcommands, qq(INSERT INTO h_pap_erratum_in VALUES ('$joinkey', '$erratum_in', '$order', 'two1843'););
      }
  } }
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)



__END__

# this causes seg fault, probably not enough memory on mangolassi.  2023 05 31

use strict;
use JSON;
use Text::Unaccent;
use utf8;

binmode STDOUT, ':utf8';

my $infile = 'reference_WB_20230522.json';
# my $infile = 'files/reference_WB_20230428.json';
# my $infile = 'files/reference_WB_comcor.json';
# my $infile = 'files/reference_WB_doublequotes.json';
# my $infile = 'files/reference_WB_accents.json';
# my $infile = 'files/reference_WB_nightly.json';
# my $infile = '/usr/lib/scripts/pgpopulation/pap_papers/20230322_agr_xrefs/reference_WB_nightly.json';

$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
print "Start reading $infile\n";
my $json_data = <IN>;
print "Done reading $infile\n";
close (IN) or die "Cannot open $infile : $!";

my $unaccent_json_data = unac_string("utf-8", $json_data);

print "Start decoding json\n";
# my %perl = parse_json($json_data);    # JSON::Parse, not installed in dockerized
# my $perl = JSON::XS->new->utf8->decode ($json_data);
# my $perl = decode_json($json_data);   # JSON  very very slow on dockerized without JSON::XS, but fast on tazendra.  with JSON::XS installed is fast even without directly calling JSON::XS->new like below, and without use JSON::XS, just use JSON
my $perl = decode_json($unaccent_json_data);    # escape accent characters

print "Done decoding json\n";
my %agr = %$perl;
foreach my $key (sort keys %agr) {
  print qq($key\n);
}

my %agrs;
my %wbps;
my %wbpToAgr;
my %doiToAgr;
my %pmidToAgr;
my %agrToWbp;
my %agrToDoi;
my %agrToPmid;
my %agrObsId;
my %agrData;
my %agrCategory;

foreach my $papobj_href (@{ $agr{data} }) {
#   print qq(papobj_href\n);
  my %papobj = %$papobj_href;
#   $count++; last if ($count > 400);
  my $agr = $papobj{curie};
  $agrs{$agr}++;
  if ($papobj{category}) { $agrCategory{$agr} = $papobj{category}; }
  my $wbp = ''; my $doi = ''; my $pmid = '';
#   print qq($agr\n);
  my %xrefs;
  foreach my $xref_href (@{ $papobj{cross_references} }) {
    my %xref = %$xref_href;
    if ($xref{curie} =~ m/^WB:WBPaper(\d+)/) {
      $wbp = $1;           $agrToWbp{$agr}  = $wbp;  $wbpToAgr{$wbp}   = $agr;
      if ($xref{is_obsolete}) { $agrObsId{$wbp}++; } }
    if ($xref{curie} =~ m/^PMID:(\d+)/) {
      $pmid = 'pmid' . $1; $agrToPmid{$agr} = $pmid; $pmidToAgr{$pmid} = $agr;
      if ($xref{is_obsolete}) { $agrObsId{$pmid}++; } }
  }
# PUT THIS BACK
  &comparePgAgr($papobj_href);
  print qq(\n);
  if ($wbp) {
    $wbps{$wbp}++;
#     print qq($wbp : $agr\n);
  } else {
    $agrData{$agr} = $papobj_href;
    # $agrData{$agr} = \%papobj;
  }
}
