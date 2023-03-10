#!/usr/bin/perl -w

# find out which papers in the curation status table lack a pap_species value.  2016 05 28

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my $query;

my %cfp_curator;
$query = "SELECT * FROM cfp_curator";
$result = $dbh->prepare( $query );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $cfp_curator{$row[0]} = $row[1]; }

  my %curatablePapers;
  my %caltechWormPapers;
  my @taxonIDs = qw( 6239 860376 135651 6238 6239 281687 1611254 31234 497829 1561998 1195656 54126 );
  my $taxonIDs = join"','", @taxonIDs;
  $query = "SELECT * FROM pap_species WHERE pap_species IN ('$taxonIDs')";
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $caltechWormPapers{$row[0]} = $row[1]; }
  $query = "SELECT * FROM pap_status WHERE pap_status = 'valid' AND joinkey IN (SELECT joinkey FROM pap_primary_data WHERE pap_primary_data = 'primary') AND joinkey NOT IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode')";
  $result = $dbh->prepare( $query );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $cfp_curator = $cfp_curator{$row[0]} || '';
    unless ($caltechWormPapers{$row[0]}) { print qq($row[0]\tmissing pap_species\t$cfp_curator\n); next; }          # skip papers that are not in list of caltech taxon IDs
    $curatablePapers{$row[0]} = $row[1]; }

__END__

