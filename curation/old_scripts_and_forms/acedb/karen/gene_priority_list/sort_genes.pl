#!/usr/bin/perl -w

# complicated thing for Karen.  Take WBGene and WBRNAi dump from WS.  Look at
# WBGenes and if any alleles are in postgres app_ tables with a phenotype, skip
# it.  If any RNAi for that gene has any Phenotype terms that are neither not 
# nor in the list she wrote, skip that _gene_.  sort remaining genes by amount
# of papers that are not abstracts, then by date, then by wbgene.  also mention
# whether there's a concise description or not.  2008 08 12
#
# modified because app_tempname and app_type are replaced by app_variation, and
# wpa tables are replaced with pap tables.  2011 05 02



use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %phen_skip;
my $skip_file = 'RNAi_phenotypes_to_skip.txt';
open (IN, "<$skip_file") or die "Cannot open $skip_file : $!";
while (my $line = <IN>) { chomp $line; $phen_skip{$line}++; }
close (IN) or die "Cannot close $skip_file : $!";

$/ = "";

my %rnai_skip;
my $rnai_file = 'RNAi.ace';
open (IN, "<$rnai_file") or die "Cannot open $rnai_file : $!";
while (my $para = <IN>) {
  chomp $para;
  my ($rnai) = $para =~ m/RNAi : \"(WBRNAi\d+)\"/;
  my @lines = split/\n/, $para;
  foreach my $line (@lines) {
    next unless ($line =~ m/^Phenotype\t/);		# make sure it's got a tab, meaning it's the tag name.  2011 05 04 
    next if ($line =~ m/Not/);
    my ($phen) = $line =~ m/(WBPhenotype:\d+)/;
    unless ($phen_skip{$phen}) { $rnai_skip{$rnai}++; }
  } # foreach my $line (@lines)
} # while (my $para = <IN>)
close (IN) or die "Cannot close $rnai_file : $!";

# foreach my $rnai (sort keys %rnai_skip) { print "$rnai\n"; }

my %allele;
# my $result = $dbh->prepare( "SELECT app_type.app_type, app_tempname.app_tempname, app_term.app_term FROM app_type, app_tempname, app_term WHERE app_type.joinkey = app_tempname.joinkey AND app_type.joinkey = app_term.joinkey AND app_type = 'Allele' ");
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { $allele{$row[1]}++; }
my $result = $dbh->prepare( "SELECT app_variation.app_variation, app_term.app_term FROM app_variation, app_term WHERE app_term.joinkey = app_variation.joinkey ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $allele{$row[0]}++; }

# foreach my $allele (sort keys %allele) { print "ALLELE $allele\n"; }

my %wpa;
my %type;
# $result = $dbh->prepare( "SELECT * FROM wpa_type ORDER BY wpa_timestamp" );
# while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $type{$row[0]} = $row[1]; } else { delete $type{$row[0]}; } }
$result = $dbh->prepare( "SELECT * FROM pap_type ORDER BY pap_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $type{$row[0]} = $row[1]; }
# print "00005614 TYPE $type{'00005614'}\n";
my %valid;
# $result = $dbh->prepare( "SELECT * FROM wpa ORDER BY wpa_timestamp" );
# while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $valid{$row[0]} = $row[5]; } else { delete $valid{$row[0]}; } }
$result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid' ORDER BY pap_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]} = $row[4]; }
# print "00005614 VALID $valid{'00005614'}\n";
foreach my $paper (sort keys %type) {
  next if ($type{$paper} eq '3'); next if ($type{$paper} eq '4');
  next unless ($valid{$paper});
  my $timestamp = $valid{$paper}; 
  ($timestamp) = $timestamp =~ m/^(\d{4}\-\d{2}\-\d{2})/;
  $timestamp =~ s/\D+//g;
# print "$paper TIME $timestamp\n";
  $wpa{$paper} = $timestamp; }

my %gin;
$result = $dbh->prepare( "SELECT * FROM gin_locus ORDER BY gin_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gin{"WBGene$row[0]"} = $row[1]; }


my %hash;
my $gene_file = 'wbgene.ace';
open (IN, "<$gene_file") or die "Cannot open $gene_file : $!";
while (my $para = <IN>) {
  chomp $para;
  next unless ($para =~ m/Gene : \"(WBGene\d+)\"/);
  my ($wbg) = $para =~ m/Gene : \"(WBGene\d+)\"/;
  my $skip = 0;
  if ($para =~ m/RNAi_result/) {
    my (@rnai) = $para =~ m/RNAi_result\s+\"(WBRNAi\d+)\"/g;
    foreach my $rnai (@rnai) { if ($rnai_skip{$rnai}) { $skip++; } } }
  next if ($skip > 0); 
  if ($para =~ m/Allele/) { 
    my (@alleles) = $para =~ m/Allele\s+\"([^\"]+)\"/g;
    foreach my $allele (@alleles) { if ($allele{$allele}) { $skip++; } } }
  next if ($skip > 0); 
  
  if ($para =~ m/Reference/) { 
    my (@papers) = $para =~ m/Reference\s+\"WBPaper(\d+)\"/g;
    my $count = 0; my $recent = 0;
    foreach my $paper (@papers) {
#       unless ($wpa{$paper}) { print "NO $paper WPA\n"; }
      next unless ($wpa{$paper});
      if ($wpa{$paper} > $recent) { $recent = $wpa{$paper}; }
      $hash{$wbg}{papers}{$paper}++;
      $count++; }
    $hash{$wbg}{paper_count} = $count;
    $hash{$wbg}{paper_recent} = $recent;
# print "IN $wbg\t$count\t$recent\n";
  } else { $hash{$wbg}{paper_count} = 0; $hash{$wbg}{paper_recent} = 0; }

  if ($para =~ m/Concise_description/) { $hash{$wbg}{concise}++; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $gene_file : $!";

foreach my $wbg (sort { ($hash{$b}{paper_count} <=> $hash{$a}{paper_count}) ||
                        ($hash{$b}{paper_recent} <=> $hash{$a}{paper_recent}) ||
                        ($a cmp $b) } keys %hash) {
  my $concise = ''; if ($hash{$wbg}{concise}) { $concise = 'yes'; }
  my $locus = $wbg;
  if ($gin{$locus}) { $locus = $gin{$locus}; }
  print "$locus\t$concise\t$hash{$wbg}{paper_count}\t$hash{$wbg}{paper_recent}\n";
}


__END__

my $result = $dbh->prepare( "SELECT * FROM one_groups;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

WBPhenotype:0000050
WBPhenotype:0000031
WBPhenotype:0000059
WBPhenotype:0000688
WBPhenotype:0000154
WBPhenotype:0000643
WBPhenotype:0000689
WBPhenotype:0000697
WBPhenotype:0000054
WBPhenotype:0000269
WBPhenotype:0000032
WBPhenotype:0001037
WBPhenotype:0000961
WBPhenotype:0001425
WBPhenotype:0000062
WBPhenotype:0001183
WBPhenotype:0000535
WBPhenotype:0000038
WBPhenotype:0000583
WBPhenotype:0000017
WBPhenotype:0000679
WBPhenotype:0000229
WBPhenotype:0000640
WBPhenotype:0000164
WBPhenotype:0000638
WBPhenotype:0001171
WBPhenotype:0001236
WBPhenotype:0000061
WBPhenotype:0001010
WBPhenotype:0000644
WBPhenotype:0000700
WBPhenotype:0000039
WBPhenotype:0000365
WBPhenotype:0000055
WBPhenotype:0000270
WBPhenotype:0001184
WBPhenotype:0000646
WBPhenotype:0001595
WBPhenotype:0000195
WBPhenotype:0001208
WBPhenotype:0000022
WBPhenotype:0000057
