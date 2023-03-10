#!/usr/bin/perl -w

# dump out go data for noctua.  for Kimberly.  2021 03 11
# https://wiki.wormbase.org/index.php/Noctua_-_Upload_of_WB_Manual_Annotations#OA_Annotations
#
# added $relationToRo{'occurs_in'} = 'BFO:0000066'; and $relationToRo{'part_of'} = 'BFO:0000050';  2021 05 13
#
# add contributor-id= to GOC:cab1 in col12.  Add date from col9 to col12 as creation-date= and modification-date=
# 2021 07 15

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgtables = qw( wbgene qualifier goid accession paper goinference with_wbgene with with_phenotype with_rnai with_wbvariation lastupdate xrefto curator comment );

my %qualifierToRo;
&populateQualifierToRo();
my %relationToRo;
&populateRelationsToRo();
my %goToEco;
&populateGoToEco();
my %personToOrcid;
&populatePersonToOrcid();

my %papToPmid;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $pmid = $row[1];
    $pmid =~ s/pmid/PMID:/;
    $papToPmid{"WBPaper$row[0]"} = $pmid; }
} # while (@row = $result->fetchrow)

my %ignore;
$result = $dbh->prepare( "SELECT * FROM gop_falsepositive WHERE gop_falsepositive = 'False Positive'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $ignore{$row[0]}++; }
} # while (@row = $result->fetchrow)
my $joinkeys = join"','", sort keys %ignore;

my %data;
foreach my $pgtable (@pgtables) {
#   $result = $dbh->prepare( "SELECT * FROM gop_$pgtable WHERE joinkey NOT IN ('$joinkeys')" );
  $result = $dbh->prepare( "SELECT * FROM gop_$pgtable" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    next if ($ignore{$row[0]});
    $data{$pgtable}{$row[0]} = $row[1];
  } # while (@row = $result->fetchrow)
}

my $count = 0;
my %curators;
foreach my $joinkey (sort keys %{ $data{'wbgene'} }) {
#   $count++; last if ($count > 5);
  my @row;
  for my $i (0 .. 11) { $row[$i] = ''; }
  $row[0] = 'WB:' . $data{'wbgene'}{$joinkey};
  my $qualifier = $data{'qualifier'}{$joinkey};
#   $row[1] = $qualifier;
  $row[1] = '';
  if ($qualifierToRo{$qualifier}) { $row[2] = $qualifierToRo{$qualifier}; }
    else { print qq(ERR\tqualifier $qualifier does not map to RO in pgid $joinkey\n); }
  if ($data{'goid'}{$joinkey}) {
    $row[3] = $data{'goid'}{$joinkey}; }
  if ($data{'accession'}{$joinkey}) {
    $row[4] = $data{'accession'}{$joinkey}; 
    $row[4] =~ s/"//g;
  }
  if ($data{'paper'}{$joinkey}) {
    my $wbpaper = $data{'paper'}{$joinkey};
    my @data = ("WB:$wbpaper");
    if ($papToPmid{$wbpaper}) { push @data, $papToPmid{$wbpaper}; }
    if ($row[4]) { push @data, $row[4]; }
    $row[4] = join"|", @data;
  }
  if ($data{'goinference'}{$joinkey}) {
    my $go = $data{'goinference'}{$joinkey};
    if ($goToEco{$go}) { $row[5] = $goToEco{$go}; }
      else { print qq(ERR\t$go does not map to ECO code in pgid $joinkey\n); }
  }
  my @row6;
  if ($data{'with_wbgene'}{$joinkey}) {
    my (@data) = split/","/, $data{'with_wbgene'}{$joinkey};
    foreach my $data (@data) {
      $data =~ s/"//g; $data = 'WB:' . $data; push @row6, $data;
    } # foreach my $data (@data)
  }
  if ($data{'with'}{$joinkey}) {
    my (@data) = split/\|/, $data{'with'}{$joinkey};
    foreach my $data (@data) {
      push @row6, $data;
    } # foreach my $data (@data)
  }
  if ($data{'with_phenotype'}{$joinkey}) {
    my $data = $data{'with_phenotype'}{$joinkey};
    $data =~ s/"//g;
    push @row6, $data;
  }
  if ($data{'with_rnai'}{$joinkey}) {
    my $data = $data{'with_rnai'}{$joinkey};
    $data =~ s/"//g;
    push @row6, "WB:$data";
  }
  if ($data{'with_wbvariation'}{$joinkey}) {
    my (@data) = split/","/, $data{'with_wbvariation'}{$joinkey};
    foreach my $data (@data) {
      $data =~ s/"//g; $data = 'WB:' . $data; push @row6, $data;
    } # foreach my $data (@data)
  }
  if (scalar @row6 > 0) { $row[6] = join",", @row6; }
    else { $row[6] = ''; }
  $row[7] = '';
  my $newDate = '';
  if ($data{'lastupdate'}{$joinkey}) {
    my $date = $data{'lastupdate'}{$joinkey};
    if ($date =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2})/) {
         $newDate = $1; $newDate =~ s/ /T/; $row[8] = $newDate; }
      elsif ($date =~ m/^(\d{4}\-\d{2}\-\d{2} \d{1}:\d{2})/) {
         $newDate = $1; $newDate =~ s/ /T/; $row[8] = $newDate; }
      elsif ($date =~ m/^(\d{4}\-\d{2}\-\d{2})$/) { $row[8] = $1; $newDate = $1; }
      else { print qq(ERR $date does not match pattern in pgid $joinkey\n); } }
  $row[9] = 'WB';
  if ($data{'xrefto'}{$joinkey}) {
    my $data = $data{'xrefto'}{$joinkey};
    foreach my $key (sort keys %relationToRo) {
      if ($data =~ m/$key/) { $data =~ s/$key/$relationToRo{$key}/g; } }
    $row[10] = $data; }
  my @row11 = ();
  push @row11, "id=WBOA:$joinkey";
  if ($data{'curator'}{$joinkey}) {
    if ($personToOrcid{$data{'curator'}{$joinkey}}) {
        push @row11, $personToOrcid{$data{'curator'}{$joinkey}}; }
      else {
        push @row11, "contributor-id=GOC:cab1"; }
  }
  if ($data{'comment'}{$joinkey}) { push @row11, "comment=$data{'comment'}{$joinkey}"; }
  if ($newDate) {
    push @row11, "creation-date=$newDate"; push @row11, "modification-date=$newDate"; }
  $row[11] = join"|", @row11;

  my $row = join"\t", @row;
  print qq($row\n);
} # foreach my $joinkey (sort keys %{ $data{'wbgene'} })

foreach my $curator (sort keys %curators) {  
  print qq($curator\n);
} # foreach my $curator (sort keys %curators)

sub populateQualifierToRo {
  $qualifierToRo{'acts_upstream_of_or_within'} = 'RO:0002264';
  $qualifierToRo{'located_in'} = 'RO:0001025';
  $qualifierToRo{'involved_in'} = 'RO:0002331';
  $qualifierToRo{'enables'} = 'RO:0002327';
  $qualifierToRo{'part_of'} = 'BFO:0000050';
} # sub populateQualifierToRo

sub populateRelationsToRo {
  $relationToRo{'has_input'} = 'RO:0002233';
  $relationToRo{'happens_during'} = 'RO:0002092';
  $relationToRo{'occurs_in'} = 'BFO:0000066';
  $relationToRo{'part_of'} = 'BFO:0000050';
} # sub populateRelationsToRo

sub populatePersonToOrcid {
  $personToOrcid{'WBPerson1843'} = 'contributor-id=https://orcid.org/0000-0002-1706-4196';
  $personToOrcid{'WBPerson324'} = 'contributor-id=https://orcid.org/0000-0002-1478-7671';
} # sub populatePersonToOrcid

sub populateGoToEco {
  $goToEco{'ISS'} = 'ECO:0000250';
  $goToEco{'IEP'} = 'ECO:0000270';
  $goToEco{'NAS'} = 'ECO:0000303';
  $goToEco{'TAS'} = 'ECO:0000304';
  $goToEco{'IC'} = 'ECO:0000305';
  $goToEco{'ND'} = 'ECO:0000307';
  $goToEco{'IDA'} = 'ECO:0000314';
  $goToEco{'IMP'} = 'ECO:0000315';
  $goToEco{'IGI'} = 'ECO:0000316';
  $goToEco{'IPI'} = 'ECO:0000353';
}

__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

