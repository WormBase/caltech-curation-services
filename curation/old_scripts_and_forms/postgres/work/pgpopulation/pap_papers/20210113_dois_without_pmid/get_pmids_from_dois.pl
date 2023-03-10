#!/usr/bin/perl -w

# for papers in postgres that have a DOI but no PMID, find the PMID from pubmed API for Kimberly and Jae

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @dois;
# $result = $dbh->prepare( " SELECT * FROM pap_identifier WHERE pap_identifier ~ 'doi10' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') LIMIT 10;" );
$result = $dbh->prepare( " SELECT * FROM pap_identifier WHERE pap_identifier ~ 'doi10' AND joinkey NOT IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $doi = $row[1];
    $doi =~ s/^doi//g; 
    push @dois, $doi;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $dois = join",", @dois;
# print qq(DOIS $dois\n);

# my $url = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?format=json&ids=$dois";
my $url = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?format=csv&ids=$dois";
# print qq(URL $url\n);

my $data = get $url;
# print qq(DATA $data\n);

foreach my $doi (@dois) {
  my $url = "https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?format=csv&ids=$doi";
  my $data = get $url;
  print "$data\n";
  sleep(5);
} # foreach my $doi (@dois)
