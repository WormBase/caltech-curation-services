#!/usr/bin/perl -w

# remove YH by making no dump and adding remark.  for Chris.  2014 05 27
# live run 2014 05 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %gin_dead;
$result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gin_dead{$row[0]}++; }

my %gin;
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($gin_dead{$row[0]});
    $gin{$row[1]} = "WBGene$row[0]"; }
} # while (@row = $result->fetchrow)

my %baitTarget;
$result = $dbh->prepare( "SELECT int_genebait.joinkey, int_genebait.int_genebait, int_genetarget.int_genetarget FROM int_genebait, int_genetarget WHERE int_genetarget.joinkey = int_genebait.joinkey AND int_genebait.joinkey IN (SELECT joinkey FROM int_paper WHERE int_paper = 'WBPaper00006332') ");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $pgid = $row[0];
  my $one  = $row[1];
  my $two  = $row[2];
  my (@two) = $two =~ m/(WBGene\d+)/g;
  foreach my $two (@two) {
    my $key = $one . "\t" . $two;
    $baitTarget{$key}{$pgid}++;
  } # foreach my $two (@two)
} # while (my @row = $result->fetchrow)





my %pgidToRemove;
my $infile = 'Gene_pairs_to_REMOVE_from_OA_5-23-2014.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($one, $two) = split/\t/, $line; 
  if ($gin{$one}) { $one = $gin{$one}; }
    else { print "NO MATCH FOR $one\n"; }
  if ($gin{$two}) { $two = $gin{$two}; }
    else { print "NO MATCH FOR $two\n"; }
  my %matches;
  my $key = $one . "\t" . $two;
  if ($baitTarget{$key}) { foreach my $pgid (keys %{ $baitTarget{$key} }) { $matches{$pgid}++; } }
  $key = $two . "\t" . $one;
  if ($baitTarget{$key}) { foreach my $pgid (keys %{ $baitTarget{$key} }) { $matches{$pgid}++; } }
  my @matches = sort keys %matches; my $matches = join",", @matches;
  if (scalar @matches < 1) { print "NO MATCH $line\n"; }
    else { foreach my $pgid (keys %matches) { $pgidToRemove{$pgid}++; } }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my $pgids = join",", sort keys %pgidToRemove;
$result = $dbh->prepare( "SELECT * FROM int_remark WHERE joinkey IN ('$pgids')" );
print "SELECT * FROM int_remark WHERE joinkey IN ('$pgids')\n";
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  print "ALREADY HAS REMARK : @row\n";
}

$result = $dbh->prepare( "SELECT * FROM int_nodump WHERE joinkey IN ('$pgids')" );
print "SELECT * FROM int_nodump WHERE joinkey IN ('$pgids')\n";
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  print "ALREADY HAS NODUMP : @row\n";
}

my $count = scalar keys %pgidToRemove;
print "$count pgids\n\n";

my @pgcommands;
foreach my $pgid (sort keys %pgidToRemove) {
  push @pgcommands, qq(DELETE FROM int_nodump WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_nodump VALUES ('$pgid', 'NO DUMP'););
  push @pgcommands, qq(INSERT INTO int_nodump_hst VALUES ('$pgid', 'NO DUMP'););
  my $remark = "Annotated from original publication; this interaction has since been removed from the dataset by the Vidal group. See WBPaper00032484 (Simonis et al 2009) for details of reprocessing of the data.";
  push @pgcommands, qq(DELETE FROM int_remark WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_remark VALUES ('$pgid', '$remark'););
  push @pgcommands, qq(INSERT INTO int_remark_hst VALUES ('$pgid', '$remark'););
} # foreach my $pgid (sort keys %pgidToRemove)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)


__END__

C30B5.4	T04H1.2
C32D5.9	Y87G2A.3
C32F10.6	Y51H4A.8
C33E10.10	F35H8.5
C34C12.5	F14D12.2
C34C6.7	M01E11.2
C34E10.2	Y75B8A.14
C34E10.6	Y110A7A.10
C36B1.12	K01G5.4
C39D10.7	Y65B4A.7
C40A11.2	F01F1.12
C43C3.1	F47G6.1
C44B9.2	F47G6.1
C45G9.5	M176.2
C47D12.2	M106.4
C47E8.4	T04H1.2
C47E8.5	Y92C3B.2
C49A1.4	Y113G7B.23
C49H3.11	K01G5.4
C50E3.13	F47G6.1
C54E10.2	F08G2.5
C55C3.1	T07C4.1
D2007.4	Y37E11AR.2
D2013.2	W06A7.3
F07A5.7	F47G6.1
F08B6.4	K06H7.6
F08G2.5	F53G12.10
F08G2.5	H02I12.1
F08G2.5	W10C8.2
F09E5.1	T26E3.3
F10C1.2	Y75B8A.30
F10C1.7	F47G6.1
F11G11.11	F17A2.5
F11G11.11	F43C1.2
F13B10.2	Y106G6H.14
F13H10.1	T28D6.4
F14D12.2	F54B11.7
F15C11.2	T12D8.7
F15C11.2	Y62E10A.16
F15D4.2	F40F9.1
F17C11.9	Y47D3A.27
F21F8.7	F38A6.1
F22B7.5	ZC504.4
F23C8.4	Y105E8B.8
F23F1.8	F47G6.1
F25D1.5	K08B4.1
F25H2.10	T06E6.10
F26B1.3	K08B4.1
F26D11.11	F39H12.1
F26D11.11	F44G3.9
F26D11.11	T11B7.1
F26D11.11	W07G1.5
F26F12.1	R12B2.1
F27C8.2	T08B2.5
F31C3.2	ZK849.2
F31E3.1	F59B1.7
F31E3.1	H14N18.1
F31E3.1	T21B6.3
F31E3.1	T28F12.2
F33D4.6	F47G6.1
F35F10.12	R06B9.3
F35G12.9	Y69H2.3
F36G9.11	Y51H4A.8
F37C4.5	Y51H4A.17
F38A6.1	Y62E10A.14
F39B1.1	R02F2.5
F39B1.1	R06B9.1
F39H12.1	R13A5.8
F42A10.3	F54E7.3
F42A10.5	R08D7.3
F42F12.3	ZK632.12
F42G4.3	F44A6.2
F42H10.7	K04D7.1
F43C11.7	T27F2.3
F44A6.2	H02I12.5
F44A6.2	R02F2.5
F44A6.2	Y62E10A.14
F44D12.1	F47G6.1
F44G3.9	Y62E10A.14
F46F11.2	T11B7.4
F47G6.1	F59C12.3
F47G6.1	F59C6.5
F47G6.1	M6.1
F47G6.1	R04E5.10
F47G6.1	T27A3.1
F47G6.1	W04D2.1
F47G6.1	Y39G10AR.10
F47G6.1	Y48C3A.17
F47G6.1	Y56A3A.13
F47G6.1	Y59A8B.22
F47G6.1	Y79H2A.1
F48E8.1	Y2H9A.1
F52D10.3	Y110A7A.17
F53A3.3	T07C4.1
F53B3.3	R09B5.5
F53G12.10	R09B5.5
F55B12.3	Y41C4A.12
F55C9.11	Y47D7A.1
F56F3.5	T07C4.1
F57B10.10	F58A4.8
F57B10.4	F59E12.10
F59E12.2	H28O16.1
H02I12.5	Y59E9AR.5
H04J21.3	Y69H2.3
H05C05.2	Y69A2AR.30
H08J11.2	W09H1.6
H38K22.2	R02F2.5
K01G5.2	Y55F3AM.13
K01G5.4	W02G9.2
K02D3.2	T01D1.6
K08B4.1	K11D2.2
K08B4.1	M117.2
K08B4.1	T05A10.1
K08B4.1	T22A3.3
K08B4.1	Y11D7A.12
K08E3.7	Y53H1A.2
K08E5.3	Y39E4A.2
K08F4.2	T01D1.6
K08F8.4	Y116A8C.26
K10B3.8	ZC581.1
K12H4.7	ZK1058.4
M01E11.2	M01E11.2
M117.2	Y51H4A.8
M7.2	R05D3.7
R02F11.1	T20B3.2
R02F2.1	Y73B6A.5
R05F9.10	W09H1.6
R05F9.10	ZK1067.7
R06B9.3	R06B9.3
R06B9.3	T22A3.3
R06B9.3	Y42H9AR.1
R06B9.3	ZK1098.4
R09B5.5	R09F10.7
R09B5.5	T01D1.6
R09B5.5	Y71F9AL.13
R12B2.1	T05H10.3
R12B2.1	W08D2.4
R12B2.1	Y47G6A.12
R13A5.8	W01B6.9
T01D1.6	T25F10.6
T01D1.6	W03G1.5
T01D1.6	Y43B11AR.4
T01D1.6	Y69H2.3
T01D1.6	Y87G2A.8
T04C12.6	W06F12.1
T04H1.2	T07E3.5
T04H1.2	Y45G5AM.1
T04H1.2	ZK1053.3
T06E6.10	Y39B6A.1
T07C4.1	Y37D8A.10
T09A12.4	T27F2.3
T09A12.4	W09H1.6
T09F3.3	Y79H2A.11
T11B7.4	Y73B6BL.33
T18H9.2	Y2H9A.1
T20G5.1	T26A5.9
T20G5.1	Y92C3B.2
T21C9.4	ZK616.3
T27A3.1	W06F12.1
T27F2.3	Y37E11AR.2
VW02B12L.3	Y69A2AR.30
W05H7.4	Y57G11C.24
W06A7.3	W06H8.1
W07B3.2	W07G4.5
W07B3.2	W10D9.4
W07B3.2	Y105E8B.1
W07B3.2	Y119C1A.1
W07B3.2	Y37A1B.1
W07B3.2	Y39B6A.46
W07B3.2	Y42G9A.1
W07B3.2	Y42H9AR.1
W07B3.2	Y43H11AL.1
W07B3.2	Y46G5A.31
W07B3.2	Y53H1A.1
W07B3.2	Y54E10BR.8
W07B3.2	Y54E2A.3
W07B3.2	Y57G11C.24
W07B3.2	Y65B4BR.4
W07B3.2	Y77E11A.7
W07B3.2	Y79H2A.1
W07B3.2	ZC8.4
W07B3.2	ZK1098.10
W07B3.2	ZK512.5
W07B3.2	ZK652.6
W07B3.2	ZK849.2
W07B3.2	ZK930.3
W07G4.3	ZK546.11
W08F4.8	Y39B6A.12
W10C6.1	ZK858.4
Y113G7B.23	Y51H4A.8
Y17G7B.14	Y69H2.3
Y39G10AR.10	Y69A2AR.30
Y48A6B.9	Y63D3A.4
Y50E8A.9	Y79H2A.1
Y51F10.2	Y63D3A.4
Y54G9A.6	ZK328.5
Y65B4A.7	Y69H2.3
Y87G2A.3	ZK593.6
