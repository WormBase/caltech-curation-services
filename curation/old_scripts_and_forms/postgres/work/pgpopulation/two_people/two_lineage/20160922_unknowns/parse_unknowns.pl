#!/usr/bin/perl -w

# parse two_lineage for unknowns, group by person  2016 09 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %knowns;
$result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_role !~ 'Unknown'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  next unless ($row[0]);
  next unless ($row[3]);
  if ($row[4]) { $knowns{$row[0]}{$row[3]}++; $knowns{$row[3]}{$row[0]}++; } }

my %hash;
$result = $dbh->prepare( "SELECT * FROM two_lineage WHERE two_role = 'Unknown'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($knowns{$row[0]}{$row[3]}); 
    $hash{$row[0]}{$row[3]}++; $hash{$row[3]}{$row[0]}++; } }

my %names; my %emails;
my $joinkeys = join"','", sort keys %hash;
$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN ('$joinkeys')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $names{$row[0]} = $row[2]; }
$result = $dbh->prepare( "SELECT * FROM two_email WHERE joinkey IN ('$joinkeys')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $emails{$row[0]}{$row[2]}++; }

my %filter;
foreach my $two (sort keys %hash) {
  my $name  = $names{$two};
  my $email = join", ", sort keys %{ $emails{$two} };
  my @others;
  foreach my $other (sort keys %{ $hash{$two} }) { push @others, $names{$other}; }
  my $others = join", ", @others;
  my $count  = scalar @others;
  my $line   = qq($two\t$name\t$count\t$email\t$others);
  $filter{$count}{$line}++;
} # foreach my $two (sort keys %hash)

foreach my $count (sort {$b<=>$a} keys %filter) { 
  foreach my $line (sort keys %{ $filter{$count} }) { 
    print qq($line\n); } }

__END__

