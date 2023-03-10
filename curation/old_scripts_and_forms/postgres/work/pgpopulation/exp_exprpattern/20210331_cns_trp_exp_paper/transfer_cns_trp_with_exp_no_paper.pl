#!/usr/bin/perl -w

# for Daniela to clean up constructs and transgenes that don't have papers, but do have expression from which we can get papers.  2021 03 31

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %cns_name;
my %trp_name;
my %exp_name;
my %exp_name_to_pgid;
my %cns_paper;
my %trp_paper;
my %exp_paper;
my %cnsToExp;
my %trpToExp;

$result = $dbh->prepare( "SELECT * FROM exp_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $exp_paper{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM cns_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cns_paper{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM trp_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $trp_paper{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM exp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $exp_name_to_pgid{$row[1]} = $row[0];
    $exp_name{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM cns_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $cns_name{$row[0]} = $row[1]; } }

$result = $dbh->prepare( "SELECT * FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $trp_name{$row[0]} = $row[1]; } }


$result = $dbh->prepare( "SELECT * FROM exp_construct" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $expName = $exp_name{$row[0]};
    my (@cns) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach my $cns (@cns) {
      $cnsToExp{$cns} = $expName } } }

$result = $dbh->prepare( "SELECT * FROM exp_transgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $expName = $exp_name{$row[0]};
    my (@trp) = $row[1] =~ m/(WBTransgene\d+)/g;
    foreach my $trp (@trp) {
      $trpToExp{$trp} = $expName } } }

my @pgcommands;

my $cnsoutfile = 'cns_no_paper_with_expr';
open (CNS, ">$cnsoutfile") or die "Cannot create $cnsoutfile : $!";
foreach my $pgid (sort keys %cns_name) {
  next if ($cns_paper{$pgid});
  my $cns = $cns_name{$pgid};
  if ($cnsToExp{$cns}) { 
    my $expName = $cnsToExp{$cns};
    my $expPgid = $exp_name_to_pgid{$expName};
    my $expPaper = $exp_paper{$expPgid} || 'no paper';
    print CNS qq($cns\t$pgid\tno paper\t$expName\t$expPgid\t$expPaper\n);
    if ($exp_paper{$expPgid}) {
      push @pgcommands, qq(INSERT INTO cns_paper VALUES ('$pgid', '$expPaper'););
      push @pgcommands, qq(INSERT INTO cns_paper_hst VALUES ('$pgid', '$expPaper');); }
  }
}
close (CNS) or die "Cannot close $cnsoutfile : $!";

my $trpoutfile = 'trp_no_paper_with_expr';
open (TRP, ">$trpoutfile") or die "Cannot create $trpoutfile : $!";
foreach my $pgid (sort keys %trp_name) {
  next if ($trp_paper{$pgid});
  my $trp = $trp_name{$pgid};
  if ($trpToExp{$trp}) { 
    my $expName = $trpToExp{$trp};
    my $expPgid = $exp_name_to_pgid{$expName};
    my $expPaper = $exp_paper{$expPgid} || 'no paper';
    print TRP qq($trp\t$pgid\tno paper\t$expName\t$expPgid\t$expPaper\n);
    if ($exp_paper{$expPgid}) {
      push @pgcommands, qq(INSERT INTO trp_paper VALUES ('$pgid', '$expPaper'););
      push @pgcommands, qq(INSERT INTO trp_paper_hst VALUES ('$pgid', '$expPaper');); }
  }
}
close (TRP) or die "Cannot close $trpoutfile : $!";

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
}

__END__

COPY cns_paper     TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210331_cns_trp_exp_paper/backup/cns_paper.pg';
COPY cns_paper_hst TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210331_cns_trp_exp_paper/backup/cns_paper_hst.pg';
COPY trp_paper     TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210331_cns_trp_exp_paper/backup/trp_paper.pg';
COPY trp_paper_hst TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210331_cns_trp_exp_paper/backup/trp_paper_hst.pg';

