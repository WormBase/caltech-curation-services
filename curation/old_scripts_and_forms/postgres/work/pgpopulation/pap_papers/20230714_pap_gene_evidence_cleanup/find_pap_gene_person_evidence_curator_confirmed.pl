#!/usr/bin/perl -w

# find pap_gene with Person_evidence for curators and convert to Curator_confirmed if not in separate entry.
# convert as if was always Curator_confirmed, don't make new entry.
#
# populated on tazendra.  2023 07 18


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %curators;
$curators{'WBPerson2970'}++;
$curators{'WBPerson48'}++;
$curators{'WBPerson557'}++;
$curators{'WBPerson1843'}++;
$curators{'WBPerson1847'}++;
$curators{'WBPerson567'}++;
$curators{'WBPerson1841'}++;
$curators{'WBPerson627'}++;
$curators{'WBPerson625'}++;
$curators{'WBPerson363'}++;
$curators{'WBPerson480'}++;
$curators{'WBPerson324'}++;


my %curator_confirmed;
$result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Curator_confirmed'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = $row[0] . '\t' . $row[1];
    my ($wbperson) = $row[5] =~ m/(WBPerson\d+)/;
    next unless ($curators{$wbperson});
    $curator_confirmed{$key}{$wbperson}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my @pgcommands;
my %confirmed;
$result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Person_evidence'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = $row[0] . '\t' . $row[1];
    my ($wbperson) = $row[5] =~ m/(WBPerson\d+)/;
    next unless ($curators{$wbperson});
    if ($curator_confirmed{$key}{$wbperson}) {
      print qq($key\t$wbperson\tALREADY\n);
      push @pgcommands, qq(DELETE FROM pap_gene WHERE joinkey = '$row[0]' AND pap_gene = '$row[1]' AND pap_evidence ~ 'Person_evidence' AND pap_evidence ~ '$wbperson';);
      push @pgcommands, qq(DELETE FROM h_pap_gene WHERE joinkey = '$row[0]' AND pap_gene = '$row[1]' AND pap_evidence ~ 'Person_evidence' AND pap_evidence ~ '$wbperson';);
    } else {
      print qq($key\t$wbperson\tREMAP\n);
      push @pgcommands, qq(UPDATE pap_gene SET pap_evidence = 'Curator_confirmed "$wbperson"' WHERE joinkey = '$row[0]' AND pap_gene = '$row[1]' AND pap_evidence ~ 'Person_evidence' AND pap_evidence ~ '$wbperson';);
      push @pgcommands, qq(UPDATE h_pap_gene SET pap_evidence = 'Curator_confirmed "$wbperson"' WHERE joinkey = '$row[0]' AND pap_gene = '$row[1]' AND pap_evidence ~ 'Person_evidence' AND pap_evidence ~ '$wbperson';);
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)


__END__

COPY pap_gene TO '/home/postgres/work/pgpopulation/pap_papers/20230714_pap_gene_evidence_cleanup/pap_gene.pg';
COPY h_pap_gene TO '/home/postgres/work/pgpopulation/pap_papers/20230714_pap_gene_evidence_cleanup/h_pap_gene.pg';
