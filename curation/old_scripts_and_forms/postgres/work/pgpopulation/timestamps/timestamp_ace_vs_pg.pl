#!/usr/bin/perl

# for 6 files of .ace data, compare the objects's curator and timestamp to the original postgres value
# from the curator history table, and update postgres to match the .ace value.  If postgres only has one 
# value, also update the corresponding curator data table, since it's the most current.  2016 05 19
#
# ran on tazendra  2016 06 02

use strict;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

# SELECT joinkey, COUNT(joinkey) FROM trp_curator_hst GROUP BY joinkey ORDER BY COUNT(joinkey) DESC;

my %curatorToWBPerson;
$curatorToWBPerson{'wen'}      = 'WBPerson101';
$curatorToWBPerson{'acedb'}    = 'WBPerson13481';
$curatorToWBPerson{'citace'}   = 'WBPerson13481';
$curatorToWBPerson{'daniela'}  = 'WBPerson12028';
$curatorToWBPerson{'geneace'}  = 'WBPerson13481';
$curatorToWBPerson{'sylvia'}   = 'WBPerson1250';
$curatorToWBPerson{'wormpub'}  = 'WBPerson13481';
$curatorToWBPerson{'xiaodong'} = 'WBPerson1760';
$curatorToWBPerson{'chris'}    = 'WBPerson2987';
$curatorToWBPerson{'gary'}     = 'WBPerson557';
$curatorToWBPerson{'igor'}     = 'WBPerson22';
$curatorToWBPerson{'andrei'}   = 'WBPerson480';
$curatorToWBPerson{'fiona'}    = 'WBPerson1978';
$curatorToWBPerson{'kimberly'} = 'WBPerson1843';
$curatorToWBPerson{'lstein'}   = 'WBPerson1482';
$curatorToWBPerson{'raymond'}  = 'WBPerson363';
$curatorToWBPerson{'eimear'}   = 'WBPerson1841';

my %pgName;
my %pgTs; my %pgPublicnameToPgid;
my %datatypes; 
$datatypes{abp} = "Antibody";
$datatypes{exp} = "Expr_pattern";
$datatypes{grg} = "Gene_regulation";
$datatypes{int} = "Interaction";
$datatypes{rna} = "RNAi";
$datatypes{trp} = "Transgene";
foreach my $dt (sort keys %datatypes) {
  my $table = 'name'; if ($dt eq 'trp') { $table = 'publicname'; }
  $result = $dbh->prepare( "SELECT * FROM ${dt}_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $pgPublicnameToPgid{$datatypes{$dt}}{$row[1]} = $row[0];
      $pgName{$datatypes{$dt}}{$row[1]}             = $row[2]; } }
  $result = $dbh->prepare( "SELECT * FROM ${dt}_curator_hst ORDER BY ${dt}_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pgTs{$datatypes{$dt}}{$row[0]}{$row[2]} = $row[1]; } }
}


my %data;
# my @dataFiles = qw( Antibody Expr_pattern Gene_regulation Interaction RNAi Transgene );
# foreach my $datatype (@dataFiles) 
foreach my $dt (sort keys %datatypes) {
  my $datatype = $datatypes{$dt};
  my $infile   = $datatype . '_timestamps.txt';
  my %fileCurator;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    if ( $line =~ m/^(.*?) : "(.*?)" -O "(.*?)"$/ ) {
        my ($objdt, $obj, $ts) = ($1, $2, $3);
        my ($date, $time, $who) = split/_/, $ts;
        my $timestamp = qq($date $time);
        $data{$dt}{$obj}{ts}  = $timestamp;
        $data{$dt}{$obj}{who} = $curatorToWBPerson{$who};
        $fileCurator{$who}++;
      }
      else { print qq($datatype LINE fail $line\n); }
    
  } # while (my $line = <IN>)
# show curators that exist in each file
#   foreach my $fileCurator (sort keys %fileCurator) { 
#     print qq($datatype\t$fileCurator\t$fileCurator{$fileCurator}\n); }
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $datatype (@dataFiles)

my @pgcommands;
foreach my $dt (sort keys %data) {
  my $datatype = $datatypes{$dt};
  foreach my $obj (sort keys %{ $data{$dt} }) { 
    if ($pgPublicnameToPgid{$datatype}{$obj}) {
      my $pgid = $pgPublicnameToPgid{$datatype}{$obj};
      my $pgFirstTs      = (sort(keys %{ $pgTs{$datatype}{$pgid} }))[0];
      my $pgFirstCurator = $pgTs{$datatype}{$pgid}{$pgFirstTs};
      my $fileTs      = $data{$dt}{$obj}{ts};
      my $fileCurator = $data{$dt}{$obj}{who};
      if (scalar keys %{ $pgTs{$datatype}{$pgid} } == 1) { 	# only one history timestamp, also update data table
        print qq($datatype\t$pgid\tupdate    data table $pgFirstCurator to $fileCurator and $pgFirstTs to $fileTs\n);
        push @pgcommands, qq(DELETE FROM ${dt}_curator WHERE joinkey = '$pgid';);
        push @pgcommands, qq(INSERT INTO ${dt}_curator VALUES ('$pgid', '$fileCurator', '$fileTs'););
      }
      print qq($datatype\t$pgid\tupdate history table $pgFirstCurator to $fileCurator and $pgFirstTs to $fileTs\n);
      push @pgcommands, qq(DELETE FROM ${dt}_curator_hst WHERE joinkey = '$pgid' AND ${dt}_timestamp = '$pgFirstTs';);
      push @pgcommands, qq(INSERT INTO ${dt}_curator_hst VALUES ('$pgid', '$fileCurator', '$fileTs'););
#       if ($fileTs ne $pgTs) {
#           print qq(DIFF\t$datatype\t$obj\t$fileTs\t$pgTs\n); }
#         else {
#           print qq(SAME\t$datatype\t$obj\t$fileTs\t$pgTs\n); }
    }
  } # foreach my $obj (sort keys %{ $data{$datatype} })
} # foreach my $datatype (sort keys %data)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO UPDATE POSTGRES
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)


__END__ 

foreach my $datatype (sort keys %data) {
# show objects that exist only in file vs pg
#   foreach my $obj (sort keys %{ $data{$datatype} }) { 
#     unless ($pg{$datatype}{$obj}) { print qq($datatype\t$obj\tin file not pg\n); } }
#   foreach my $obj (sort keys %{ $pg{$datatype} }) { 
#     unless ($data{$datatype}{$obj}) { print qq($datatype\t$obj\tin pg not file\n); } }

  foreach my $obj (sort keys %{ $data{$datatype} }) { 
    if ($pgName{$datatype}{$obj}) {
      my $fileTs = $data{$datatype}{$obj}{ts};
      my $pgTs   = $pgName{$datatype}{$obj};
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


