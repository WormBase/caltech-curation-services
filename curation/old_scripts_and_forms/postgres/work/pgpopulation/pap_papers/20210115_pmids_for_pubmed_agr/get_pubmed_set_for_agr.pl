#!/usr/bin/perl -w

# get a set of pmids to test batch query against pubmed

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %papPmid;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN (SELECT joinkey FROM pap_status WHERE pap_status = 'valid') ORDER BY pap_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $papPmid{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pap (reverse sort keys %papPmid) {
  print qq($papPmid{$pap}\t$pap\n);
}

__END__
