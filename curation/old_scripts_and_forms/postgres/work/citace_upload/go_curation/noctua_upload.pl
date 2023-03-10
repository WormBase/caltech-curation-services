#!/usr/bin/perl -w

# generate data for noctua upload
# https://wiki.wormbase.org/index.php/Noctua_-_Upload_of_WB_Manual_Annotations

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( wbgene qualifier goid accession paper goinference with_wbgene with with_phenotype with_rnai with_wbvariation lastupdate xrefto curator comment falsepositive );
my %data;

my %curators;
foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM gop_${table}" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[1] =~ s///g;
      $data{$table}{$row[0]} = $row[1];
      if ($table eq 'curator') { my $curator = $row[1]; $curator =~ s/WBPerson/two/; $curators{$curator}++; }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

my $twoIds = join"','", sort keys %curators;
my %orcid;
$result = $dbh->prepare( "SELECT * FROM two_orcid WHERE joinkey IN ('$twoIds') AND two_order = '1'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $wbperson = $row[0];
  $wbperson =~ s/two/WBPerson/;
  $orcid{$wbperson} = "contributor-id=https://orcid.org/" . $row[2];
}

my %pmid;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $wbpaper = 'WBPaper' . $row[0];
  my $pmid = $row[1]; $pmid =~ s/pmid/PMID:/g;
  $pmid{$wbpaper} = $pmid;
}


my %ro;
$ro{"part_of"} = "BFO:0000050";
$ro{"enables"} = "RO:0002327";
$ro{"acts_upstream_of_or_within"} = "RO:0002264";
$ro{"colocalizes_with"} = "RO:0002325";
$ro{"involved_in"} = "RO:0002331";
$ro{"located_in"} = "RO:0001025";
$ro{"contributes_to"} = "RO:0002326";
$ro{"has_input"} = "RO:0002233";
$ro{"happens_during"} = "RO:0002092";

my %eco;
$eco{"ISS"} = "ECO:0000250";
$eco{"IEP"} = "ECO:0000270";
$eco{"NAS"} = "ECO:0000303";
$eco{"TAS"} = "ECO:0000304";
$eco{"IC"}  = "ECO:0000305";
$eco{"ND"}  = "ECO:0000307";
$eco{"IDA"} = "ECO:0000314";
$eco{"IMP"} = "ECO:0000315";
$eco{"IGI"} = "ECO:0000316";
$eco{"IPI"} = "ECO:0000353";

foreach my $pgid (sort keys %{ $data{wbgene} }) {
  if ($data{falsepositive}{$pgid}) {
    next if ($data{falsepositive}{$pgid} eq 'False Positive'); }
  my @row = ();
  for (0 .. 11) { push @row, ''; }
  if ($data{wbgene}{$pgid}) { $row[0] = 'WB:' . $data{wbgene}{$pgid}; }
  if ($data{qualifier}{$pgid}) { 
    if ($data{qualifier}{$pgid} eq 'NOT')  { $row[1] = 'NOT'; }
      elsif ($ro{$data{qualifier}{$pgid}}) { $row[2] = $ro{$data{qualifier}{$pgid}}; } }
  if ($data{goid}{$pgid}) { $row[3] = $data{goid}{$pgid}; }

  my @row4;
  if ($data{accession}{$pgid}) { my $data = $data{accession}{$pgid}; $data =~ s/"//g; push @row4, $data; }
  if ($data{paper}{$pgid}) { 
    my $paper = $data{paper}{$pgid};
    if ($pmid{$paper}) { push @row4, $pmid{$paper}; }
    push @row4, "WB:$paper";
  }
  if (scalar @row4 > 0) { $row[4] = join"|", @row4; }

  if ($data{goinference}{$pgid}) { $row[5] = $eco{$data{goinference}{$pgid}}; }

  my @row6;
  if ($data{with_wbgene}{$pgid}) { my $data = $data{with_wbgene}{$pgid}; $data =~ s/\"//g; $data =~ s/WBGene/WB:WBGene/g; push @row6, $data; }
  if ($data{with}{$pgid}) { my $data = $data{with}{$pgid}; $data =~ s/\|/,/g; push @row6, $data; }
  if ($data{with_phenotype}{$pgid}) { my $data = $data{with_phenotype}{$pgid}; $data =~ s/\"//g; push @row6, $data; }
  if ($data{with_phenotype}{$pgid}) { my $data = $data{with_phenotype}{$pgid}; $data =~ s/\"//g; push @row6, $data; }
  if ($data{with_rnai}{$pgid}) { my $data = $data{with_rnai}{$pgid}; $data =~ s/\"//g; push @row6, "WB:$data"; }
  if ($data{with_variations}{$pgid}) { my $data = $data{with_variations}{$pgid}; $data =~ s/\"//g; $data =~ s/WBVar/WB:WBVar/g; push @row6, $data; }
  if (scalar @row6 > 0) { $row[6] = join",", @row6; }

  if ($data{lastupdate}{$pgid}) { 
    $row[8] = $data{lastupdate}{$pgid}; $row[8] =~ s/ /T/g; 
    if ($row[8] =~ m/T(\d):/) { $row[8] =~ s/T(\d):/T0$1:/; }
  }
  $row[9] = 'WB'; 
  if ($data{xrefto}{$pgid}) { 
    my $data = $data{xrefto}{$pgid};
    foreach my $rokey (sort keys %ro) { $data =~ s/$rokey/$ro{$rokey}/g; } 
    $row[10] = $data;
  }
  my @row11;
  push @row11, "id:WBOA:$pgid";
  if ($data{curator}{$pgid}) {
    my $data = 'GOC:cab1';
    if ($orcid{$data{curator}{$pgid}}) { $data = $orcid{$data{curator}{$pgid}}; }
    push @row11, $data; }
  if ($data{comment}{$pgid}) { push @row11, "comment=$data{comment}{$pgid}"; }
  if (scalar @row11 > 0) { $row[11] = join"|", @row11; }
    
  my $line = join"\t", @row;
  print qq($line\n);
} # foreach my $pgid (sort keys %{ $data{wbgene} })

__END__

