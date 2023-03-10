#!/usr/bin/perl -w

# update DOIs based on Alliance reports of missing or different DOIs. from running 
# https://github.com/alliance-genome/agr_literature_service/blob/main/src/xml_processing/sort_dqm_json_reference_updates.py
# at alliance
#
# back up pap_identifer and h_pap_identifier before running this.  ran on tazendra 2021 10 14


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $hasError = '';
my %idents;
# $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' OR pap_identifier ~ 'doi'" );
$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $idents{highestOrder}{$row[0]} = $row[2];
    next unless (($row[1] =~ m/pmid/) || ($row[1] =~ m/doi/));
    $idents{toIdent}{$row[0]} = $row[1];
    if ($idents{toPap}{$row[1]}) { 
      if ($row[0] ne $idents{toPap}{$row[1]}) {
        $hasError .= qq($row[1] already existed for $idents{toPap}{$row[1]}, replacing with $row[0]\n); } }
    $idents{toPap}{$row[1]} = $row[0];
    $idents{toOrder}{$row[1]} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

if ($hasError) {
  print $hasError;
  exit;
}

my @pgcommands;

my $new_doi_file = 'wb_does_not';
open (IN, "<$new_doi_file") or die "Cannot open $new_doi_file : $!";
while (my $line = <IN>) {
  my ($doi, $pmid) = $line =~ m/has DOI (.*?), dqm (.*) does not/;
  $pmid =~ s/PMID:/pmid/;
  $doi = 'doi' . $doi;
  if ($idents{toPap}{$pmid}) { 
    my $joinkey = $idents{toPap}{$pmid};
    if ( ($idents{toPap}{$doi}) && ($idents{toPap}{$doi} eq $joinkey) ) {
      print qq(ALREADY IN\t$joinkey\tfrom\t$pmid\tadd\t$doi\n); 
      next; 
    }
    $idents{highestOrder}{$joinkey}++;
    my $order = $idents{highestOrder}{$joinkey};
    push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$joinkey', '$doi', '$order', 'two1823'););
    push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$joinkey', '$doi', '$order', 'two1823'););
    print qq($joinkey\tfrom\t$pmid\tadd\t$doi\n);
  } else {
    print qq(not found\t$pmid\tto add\t$doi\n);
  }
}
close (IN) or die "Cannot close $new_doi_file : $!";

my $doi_update_file = 'wb_doi_difference';
open (IN, "<$doi_update_file") or die "Cannot open $doi_update_file : $!";
while (my $line = <IN>) {
  my ($prefix, $new, $old) = $line =~ m/had (.*?) (.*?), dqm submitted (.*)$/;
  unless ($prefix && $old && $new) {
    print qq(ERROR $line\n);
  }
  if ($prefix eq 'PMID') {
    $old = 'pmid' . $old;
    $new = 'pmid' . $new; }
  if ($prefix eq 'DOI') {
    $old = 'doi' . $old;
    $new = 'doi' . $new; }
  if ($idents{toPap}{$old}) { 
    my $joinkey = $idents{toPap}{$old};
    my $order = $idents{toOrder}{$old};
    print qq($joinkey\tfrom\t$old\treplace with\t$new\n);
    push @pgcommands, qq(DELETE FROM pap_identifier WHERE joinkey = '$joinkey' and pap_identifier = '$old';);
    push @pgcommands, qq(INSERT INTO pap_identifier VALUES ('$joinkey', '$new', '$order', 'two1823'););
    push @pgcommands, qq(INSERT INTO h_pap_identifier VALUES ('$joinkey', '$new', '$order', 'two1823'););
  } else {
    print qq(not found\t$old\tto replace with\t$new\n);
  }
}
close (IN) or die "Cannot close $doi_update_file : $!";

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommands (@pgcommands)

__END__

COPY pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20211014_doi_updates/pap_identifier.pg.backup';
COPY h_pap_identifier TO '/home/postgres/work/pgpopulation/pap_papers/20211014_doi_updates/h_pap_identifier.pg.backup';


wb_does_not
2021-10-13 20:05:46,370 - literature logger - INFO - Notify curator AGR:AGR-Reference-0000605515 has DOI 10.1139/g69-116, dqm PMID:5370789 does not
2021-10-13 20:05:46,370 - literature logger - INFO - Notify curator AGR:AGR-Reference-0000605517 has DOI 10.1093/oxfordjournals.bmb.a071019, dqm PMID:4807330 does not


wb_doi_difference
2021-10-13 20:05:46,447 - literature logger - INFO - Notify curator, AGR:AGR-Reference-0000606812 had DOI 10.1128/mcb.14.4.2722-2730.1994, dqm submitted 10.1128/MCB.14.4.2722
2021-10-13 20:05:46,517 - literature logger - INFO - Notify curator, AGR:AGR-Reference-0000608063 had DOI 10.1002/(sici)1097-010x(19990415)285:1<3::aid-jez2>3.3.co;2-a, dqm submitted 10.1002/(SICI)1097-010X(19990415)285:1<3::AID-JEZ2>3.0.CO;2-J
