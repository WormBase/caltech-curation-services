#!/usr/bin/perl -w

# find pap_identifiers that are probably doi but don't have doi in front and add 'doi'.  
# for Kimberly  2023 02 18
#
# Ran on tazendra  2023 02 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# should be like doi10.1016/j.jmb.2016.12.012

my @pgcommands;

my %exists;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE joinkey IN (SELECT joinkey FROM pap_identifier WHERE pap_identifier ~ '^10');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $exists{$row[0]}{$row[1]} = $row[2]; } }

$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ '^10';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    my $newval = 'doi' . $row[1];
    if ($exists{$row[0]}{$newval}) { 
      push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$row[0]' AND pap_order = '$row[2]';);
      push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$row[0]', NULL, '$row[2]', 'two1843'););
      print qq(EXISTS\t$row[0]\t$newval\tfrom order $row[2]\talready exists at order $exists{$row[0]}{$newval}\n); }
    else {
      print "$row[0]\t$row[1]\t$row[2]\tTO\t$newval\n";
      push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$row[0]' AND pap_order = '$row[2]';);
      push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$row[0]', '$newval', '$row[2]', 'two1843'););
      push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$row[0]', '$newval', '$row[2]', 'two1843'););
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

__END__

backup
COPY pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/pap_identifier.pg';
COPY h_pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/h_pap_identifier.pg';

restore
DELETE FROM pap_identifier ;
DELETE FROM h_pap_identifier ;
COPY pap_identifier FROM '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/pap_identifier.pg';
COPY h_pap_identifier FROM '/home/postgres/work/pgpopulation/pap_papers/20230218_fix_doi/h_pap_identifier.pg';

