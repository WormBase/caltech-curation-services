#!/usr/bin/env perl

# query expression OA data to find constructs, map them to transgenes in transgene OA, and see if that transgene is in same pgid of expression OA.
# for the set in exp_ where the construct maps to transgenes in trp_ and any of them are also in exp_transgene, remove the construct from exp_construct.
# 2021 02 10
#
# originally at /home/postgres/work/pgpopulation/exp_exprpattern/20210210_construct_transgene/query_expression_constructs_transgenes.pl

#  grep "does not" out > does_not
#  grep "is in" out > is_in
#  grep "is not" out > is_not
#  wc -l is_in is_not does_not 


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %expTrg;
$result = $dbh->prepare( "SELECT * FROM exp_transgene;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my (@transgenes) = $row[1] =~ m/(WBTransgene\d+)/g;
    foreach my $trg (@transgenes) {
      $expTrg{$trg}{$row[0]}++;
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %expCnsPgid;
my %expPgidCns;
$result = $dbh->prepare( "SELECT * FROM exp_construct;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my (@constructs) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach my $cns (@constructs) {
      $expCnsPgid{$cns}{$row[0]}++;
      $expPgidCns{$row[0]}{$cns}++;
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %cnsToTrg;
$result = $dbh->prepare( "SELECT trp_name, trp_construct FROM trp_construct, trp_name WHERE trp_construct.joinkey = trp_name.joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my (@constructs) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach my $cns (@constructs) {
      $cnsToTrg{$cns}{$row[0]}++;
  } }
} # while (my @row = $result->fetchrow)

my %cnsToRemove;
my %pgidHasTransgeneNotInExpTransgene;
foreach my $cns (sort keys %expCnsPgid) {
  foreach my $pgid (sort keys %{ $expCnsPgid{$cns} }) {
    my $found = 0;
    my $hasTransgene = 0;
    my %trgFound;
    foreach my $trg (sort keys %{ $cnsToTrg{$cns} }) {
      $hasTransgene++;
      if ($expTrg{$trg}{$pgid}) {
        $found++;
        $trgFound{$trg}++;
      }
    }
    if ($found) {
      my $trgFound = join", ", sort keys %trgFound;
      $cnsToRemove{$pgid}{$cns}++;
#       print qq($pgid has $cns that is $trgFound and is in exp_transgene\n); 
    }
    elsif ($hasTransgene) {
      my $potentialTransgenes = join", ", sort keys %{ $cnsToTrg{$cns} };
      $pgidHasTransgeneNotInExpTransgene{$pgid}++;
#       print qq($pgid has $cns that is $potentialTransgenes and is not in exp_transgene\n); 
    }
    else {
#       print qq($pgid has $cns that does not map to a transgene\n); 
    }
} }
  
my $pgids = join",", sort keys %pgidHasTransgeneNotInExpTransgene;
# print qq($pgids\n);

my @pgcommands;
foreach my $pgid (sort keys %expPgidCns) {
  my %cnsToKeep;
  my $remove = 0;
  foreach my $cns (sort keys %{ $expPgidCns{$pgid} }) {
    if ($cnsToRemove{$pgid}{$cns}) { $remove++; }
      else { $cnsToKeep{$cns}++; }
  } # foreach my $cns (sort keys %{ $expPgidCns{$pgid} })
  if ($remove) {
    my $newValue = join'","', sort keys %cnsToKeep;
    my $oldValue = join", ", sort keys %{ $expPgidCns{$pgid} };
    print qq($pgid OLD $oldValue\tNEW $newValue\n);
    push @pgcommands, qq(DELETE FROM exp_construct WHERE joinkey = '$pgid');
    if ($newValue) {
      push @pgcommands, qq(INSERT INTO exp_construct_hst VALUES ('$pgid', '"$newValue"'));
      push @pgcommands, qq(INSERT INTO exp_construct VALUES ('$pgid', '"$newValue"'));
    } else {
      push @pgcommands, qq(INSERT INTO exp_construct_hst VALUES ('$pgid', NULL));
    }
  }
} # foreach my $pgid (sort keys %expPgidCns)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

__END__

COPY exp_construct TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210210_construct_transgene/exp_construct.pg';
COPY exp_construct_hst TO '/home/postgres/work/pgpopulation/exp_exprpattern/20210210_construct_transgene/exp_construct_hst.pg';

