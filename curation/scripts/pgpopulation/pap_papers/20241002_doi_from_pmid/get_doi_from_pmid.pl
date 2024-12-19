#!/usr/bin/env perl

# for papers that have a PMID but no DOI, get the DOI from http://www.pmid2doi.org/
# for Kimberly and Daniela.  2014 01 07
#
# used by :
# /home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/get_new_elegans_xml.pl
#
# Dockerized, but found out  pmid2doi.org  doesn't exist anymore.  Updated it to get
# batches of 200 for another tool, but that tool was for pmc only, so only has a 25%
# success rate.  2024 10 02
#
# Kimberly would like to look these up by PMID from ABC, and populate WB with curator
# being pubmed.  Basically anything that has a pmid at ABC would be considered data
# from PubMed.  Makes sense.  We're not looking things up by WBPaper because there 
# might be some conflict, or data might come from somewhere else and merged into 
# WBPaper at ABC, though that would be unlikely.
# For now, script is looking up references by pmid at ABC and outputting any DOI.
# 2024 10 03
#
# Populated caltech dev, use pubmed as curator, even though we just know they came 
# from abc. 2024 10 12
#
# Populated caltech prod, Daniela and Kimberly approved running it.  Many PMIDs 
# were not in ABC, while that wasn't an issue on dev.  2024 10 25
#
# Option to get data from europe pmc for Daniela and Kimberly.  Gets 137 more dois.
# 2024 10 25
#
# Updated abc script to look up from stage instead of prod, still bunch of failures.
# Updated to use UserAgent to get status codes, out of 946, 634 are success without
# a doi, 312 are 500 errors.  It might be that the API finds the pmid, but then
# trying to extract the data could have some ateam failure.  2024 10 28
# 
# getPmidFromAbcXrefToRef to look up xref get agrkb and look up ref, and this works
# so something likely wrong with reference/by_cross_reference/ endpoint.  2024 10 28
# 
# we processed a file that Daniela got from europe pmc, but someone on their end 
# needs to fix some issues with it before we can process from it.  2024 10 30  


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use LWP::UserAgent;
use JSON;
use Dotenv -load => '/usr/lib/.env';

my $ua = LWP::UserAgent->new;

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $json = JSON->new->allow_nonref;

my %epmcPmidToDoi;
&populatePmidFromEuropePmcCsv();


my %highestOrder;
my %pmidToDoi;
my %pmidToPap;
my @pmids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ '^doi') AND joinkey NOT IN (SELECT joinkey FROM pap_status WHERE pap_status = 'invalid')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[1] =~ s/pmid//g;
    $row[1] =~ s/ //g;
    $pmidToPap{$row[1]} = $row[0]; 
    push @pmids, $row[1];
#     print "$row[0]\t$row[1]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey NOT IN (SELECT joinkey FROM pap_status WHERE pap_status = 'invalid')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0] && $row[2]) { 
    my $joinkey = $row[0];
    my $order   = $row[2];
    my $highestSoFar = 0; my $replace = 0;
    if ($highestOrder{$joinkey}) { if ($order > $highestOrder{$joinkey}) { $replace++; } }
      else { $replace++; }
    if ($replace) { $highestOrder{$joinkey} = $order; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $count_wanted = scalar @pmids;
# print qq(@pmids\n);

my @pgcommands = ();
my $count_matches = 0;
my $count = 0;
my $pap_curator = 'two10877';
my $timestamp = 'CURRENT_TIMESTAMP';
foreach my $pmid (@pmids) {
#   my $doi = &getPmidFromAbc($pmid);	# this gets a 500 error sometimes, don't use it.
#   my $doi = &getPmidFromAbcXrefToRef($pmid);
#   my $doi = &getPmidFromEuropePmcUrl($pmid);
  my $doi = &getPmidFromEuropePmcCsv($pmid);
#   $count++; if ($count > 3) { last; }
#   $count++; if ($count > 1) { last; }
  if ($doi) {
    my $joinkey = $pmidToPap{$pmid};
    my $order   = $highestOrder{$joinkey} + 1;
    push @pgcommands, qq(INSERT INTO pap_identifier   VALUES ('$joinkey', '$doi', $order, '$pap_curator', $timestamp) );
    push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$joinkey', '$doi', $order, '$pap_curator', $timestamp) );
    $count_matches++; }
  print qq($pmid\t$doi\n);
}
print qq(found $count_matches dois out of $count_wanted pmids\n);

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   my $result2 = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


# my $max = 100;
# my $max = 200;
# while (scalar @pmids > 0) {
#   my @temp;
#   for (1 .. $max) { 
#     my $pmid = shift @pmids;
#     if ($pmid) { push @temp, $pmid; }
#   }
#   my $query = join",", @temp;
# print qq($query\n);
#   my $url = 'http://www.pmid2doi.org/rest/json/batch/doi?pmids=[' . $query . ']';
#   print "URL $url URL\n";
# 
#   my $page_data = get $url;
#   print "P $page_data P\n";
# 
#   my $perl_scalar = $json->decode( $page_data );
#   my @jsonArray = @$perl_scalar;
#   foreach my $entry (@jsonArray) {
#     my $pmid = $entry->{"pmid"};
#     my $doi  = $entry->{"doi"};
#     $pmidToDoi{$pmid} = $doi;
#   } # foreach my $entry (@jsonArray)
# 
#   last;
# }

# 2024 10 30  we processed a file that Daniela got from europe pmc, but someone on their end needs to fix some issues with it before we can process from it.
sub populatePmidFromEuropePmcCsv {
  my $infile = "/usr/caltech_curation_files/postgres/pgpopulation/pap_papers/20241002_doi_from_pmid/PMID_PMCID_DOI.csv";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($pmid, $pmic, $doi) = split/,/, $line;
    $doi =~ s/"//g;
    $epmcPmidToDoi{$pmid} = $doi;
  }
  close (IN) or die "Cannot close $infile : $!";
}

sub getPmidFromEuropePmcCsv {
  my $pmid = shift;
  unless (exists $epmcPmidToDoi{$pmid}) {
    print qq(PMID $pmid NOT IN EUROPE PMC\n);
    return;
  }
  if ($epmcPmidToDoi{$pmid}) {
    return $epmcPmidToDoi{$pmid}
  }
  return '';
}

sub getPmidFromEuropePmcUrl {
  my $pmid = shift;
  sleep 3;
  my $url = 'https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=' . $pmid;
  my $page_data = get $url;
  unless ($page_data) {
    print qq(PMID $pmid NOT IN EUROPE PMC\n);
    return;
  }
  my (@results) = split/<result>/, $page_data;
  foreach my $result (@results) {
    if ( ($result =~ m/<pmid>$pmid<\/pmid>/) && ($result =~ m/<doi>(.*?)<\/doi>/) ) { return $1; } }
  return '';
}


sub getPmidFromAbc {
  my $pmid = shift;
  # https://literature-rest.alliancegenome.org/reference/by_cross_reference/PMID%3A9221782
  # take
  #       "curie": "DOI:10.1523/JNEUROSCI.17-15-05843.1997",
  # strip out the DOI:  and put 'doi' in front.
  my $url = 'https://stage-literature-rest.alliancegenome.org/reference/by_cross_reference/PMID:' . $pmid;
#   my $page_data = get $url;
#   unless ($page_data) {
#     print qq(PMID $pmid NOT IN ABC\n);
#     return;
#   }
  my $response = $ua->get($url);
  my $r_code = $response->code;
  my $r_msg = $response->message;
  unless ($response->is_success) {
    print qq(PMID $pmid ABC FAILURE $r_code $r_msg\n);
    return '';
  }
  my $page_data = $response->decoded_content;
#   print "P $page_data P\n";
  my $perl_scalar = $json->decode( $page_data );
  my %hash = %$perl_scalar;
  my $doi = '';
  foreach my $xref (@{ $hash{cross_references} }) {
    if ($$xref{curie_prefix} eq 'DOI') { 
      my $doi = $$xref{curie};
      $doi =~ s/DOI:/doi/;
      return $doi;
    }
  }
  print qq(PMID $pmid ABC SUCCESS but no DOI $r_code $r_msg\n);
  return '';
}

sub getPmidFromAbcXrefToRef {
  my $pmid = shift;
  # https://literature-rest.alliancegenome.org/reference/by_cross_reference/PMID%3A9221782
  # take
  #       "curie": "DOI:10.1523/JNEUROSCI.17-15-05843.1997",
  # strip out the DOI:  and put 'doi' in front.
#   my $url = 'https://stage-literature-rest.alliancegenome.org/cross_reference/PMID:' . $pmid;
  my $url = 'https://literature-rest.alliancegenome.org/cross_reference/PMID:' . $pmid;
  my $response = $ua->get($url);
  my $r_code = $response->code;
  my $r_msg = $response->message;
  unless ($response->is_success) {
    print qq(PMID $pmid ABC XREF FAILURE $r_code $r_msg\n);
    return '';
  }
  my $page_data = $response->decoded_content;
#   print "P $page_data P\n";
  my $perl_scalar = $json->decode( $page_data );
  my %hash = %$perl_scalar;
  my $agrkb = $hash{reference_curie};

#   $url = 'https://stage-literature-rest.alliancegenome.org/reference/' . $agrkb;
  $url = 'https://literature-rest.alliancegenome.org/reference/' . $agrkb;
  $response = $ua->get($url);
  $r_code = $response->code;
  $r_msg = $response->message;
  unless ($response->is_success) {
    print qq(PMID $pmid AGRKB $agrkb ABC REFERENCE FAILURE $r_code $r_msg\n);
    return '';
  }
  $page_data = $response->decoded_content;
#   print "P $page_data P\n";
  $perl_scalar = $json->decode( $page_data );
  %hash = %$perl_scalar;
  my $doi = '';
  foreach my $xref (@{ $hash{cross_references} }) {
    if ($$xref{curie_prefix} eq 'DOI') { 
      my $doi = $$xref{curie};
      $doi =~ s/DOI:/doi/;
      return $doi;
    }
  }
  print qq(PMID $pmid ABC SUCCESS but no DOI $r_code $r_msg\n);
  return '';
}

__END__

my @pgcommands; 
my $pap_curator = 'two1843';
my $timestamp = 'CURRENT_TIMESTAMP';

foreach my $pmid (sort keys %pmidToDoi) {
  my $joinkey = $pmidToPap{$pmid};
  my $order   = $highestOrder{$joinkey} + 1;
  if ($pmidToDoi{$pmid} =~ m/&lt;/)     { $pmidToDoi{$pmid} =~ s/&lt;/</g;     }
  if ($pmidToDoi{$pmid} =~ m/&gt;/)     { $pmidToDoi{$pmid} =~ s/&gt;/>/g;     }
  if ($pmidToDoi{$pmid} =~ m/&amp;lt;/) { $pmidToDoi{$pmid} =~ s/&amp;lt;/</g; }
  if ($pmidToDoi{$pmid} =~ m/&amp;gt;/) { $pmidToDoi{$pmid} =~ s/&amp;gt;/>/g; }
#   print "$joinkey\t$order\tpmid$pmid\tdoi$pmidToDoi{$pmid}\n";
  push @pgcommands, qq(INSERT INTO pap_identifier   VALUES ('$joinkey', 'doi$pmidToDoi{$pmid}', $order, '$pap_curator', $timestamp) );
  push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$joinkey', 'doi$pmidToDoi{$pmid}', $order, '$pap_curator', $timestamp) );
} # foreach my $pmid (sort keys %pmidToDoi)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   my $result2 = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

