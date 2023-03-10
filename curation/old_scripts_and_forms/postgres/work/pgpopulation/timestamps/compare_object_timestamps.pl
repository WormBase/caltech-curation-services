#!/usr/bin/perl

use strict;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my %pg;
my %datatypes; 
$datatypes{abp} = "Antibody";
$datatypes{exp} = "Expr_pattern";
$datatypes{grg} = "Gene_regulation";
$datatypes{int} = "Interaction";
$datatypes{rna} = "RNAi";
$datatypes{trp} = "Transgene";
foreach my $dt (sort keys %datatypes) {
  $result = $dbh->prepare( "SELECT * FROM ${dt}_name" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pg{$datatypes{$dt}}{$row[1]} = $row[2]; } } }


my %data;
my @dataFiles = qw( Antibody Expr_pattern Gene_regulation Interaction RNAi Transgene );
foreach my $datatype (@dataFiles) {
  my $infile = $datatype . '_timestamps.txt';
  my %fileCurator;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    if ( $line =~ m/^(.*?) : "(.*?)" -O "(.*?)"$/ ) {
        my ($dt, $obj, $ts) = ($1, $2, $3);
        my ($date, $time, $who) = split/_/, $ts;
        my $timestamp = qq($date $time);
        $data{$dt}{$obj}{ts} = $timestamp;
        $data{$dt}{$obj}{who} = $who;
        $fileCurator{$who}++;
      }
      else { print qq($datatype LINE fail $line\n); }
    
  } # while (my $line = <IN>)
# show curators that exist in each file
#   foreach my $fileCurator (sort keys %fileCurator) { 
#     print qq($datatype\t$fileCurator\t$fileCurator{$fileCurator}\n); }
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $datatype (@dataFiles)

foreach my $datatype (sort keys %data) {
# show objects that exist only in file vs pg
#   foreach my $obj (sort keys %{ $data{$datatype} }) { 
#     unless ($pg{$datatype}{$obj}) { print qq($datatype\t$obj\tin file not pg\n); } }
#   foreach my $obj (sort keys %{ $pg{$datatype} }) { 
#     unless ($data{$datatype}{$obj}) { print qq($datatype\t$obj\tin pg not file\n); } }

  foreach my $obj (sort keys %{ $data{$datatype} }) { 
    if ($pg{$datatype}{$obj}) {
      my $fileTs = $data{$datatype}{$obj}{ts};
      my $pgTs   = $pg{$datatype}{$obj};
      if ($fileTs ne $pgTs) {
          print qq(DIFF\t$datatype\t$obj\t$fileTs\t$pgTs\n); }
        else {
          print qq(SAME\t$datatype\t$obj\t$fileTs\t$pgTs\n); }
    }
  } # foreach my $obj (sort keys %{ $data{$datatype} })
} # foreach my $datatype (sort keys %data)

__END__ 

Antibody : "Expr58:mef-2" -O "2004-01-05_22:07:45_wen"
Antibody : "[cgc512]:MSP" -O "2004-07-05_21:34:13_wen"
Antibody : "[cgc541]:F-RAM" -O "2004-02-13_19:20:27_wen"
Antibody : "[cgc573]:5-4" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-9" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-11" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-12" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-13" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-19" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:10.2.1" -O "2004-02-27_16:30:42_wen"

$result = $dbh->prepare( "SELECT * FROM exp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{Expr_pattern}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM grg_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{Gene_regulation}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM int_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{Interaction}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM rna_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{RNAi}{$row[1]} = $row[2]; } }
$result = $dbh->prepare( "SELECT * FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{Transgene}{$row[1]} = $row[2]; } }
