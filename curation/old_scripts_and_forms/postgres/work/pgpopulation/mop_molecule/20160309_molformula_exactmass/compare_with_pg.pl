#!/usr/bin/perl -w

# compare mop_molformula and mop_exactmass to Karen's data.  2016 03 09

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
my $infile = 'mop_exactmass.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $header = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($pgid, $molf, $mass) = split/\t/, $line;
  $hash{$pgid}{molf} = $molf;
  $hash{$pgid}{mass} = $mass;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my $keys = join"','", sort keys %hash;

my %pg;
$result = $dbh->prepare( "SELECT * FROM mop_molformula WHERE joinkey IN ('$keys')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{$row[0]}{molf} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM mop_exactmass WHERE joinkey IN ('$keys')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pg{$row[0]}{mass} = $row[1]; } }

my @pgcommands;
foreach my $pgid (sort {$a<=>$b} keys %hash) {
  next if ( ($hash{$pgid}{molf} eq $pg{$pgid}{molf}) && ($hash{$pgid}{mass} eq $pg{$pgid}{mass}) );
  my $molfFlag = 'same';
  if ($hash{$pgid}{molf} && !$pg{$pgid}{molf}) { $molfFlag = 'new'; }
    elsif ($hash{$pgid}{molf} ne $pg{$pgid}{molf}) { $molfFlag = 'diff'; }
  my $massFlag = 'same';
  if ($hash{$pgid}{mass} && !$pg{$pgid}{mass}) { $massFlag = 'new'; }
    elsif ($hash{$pgid}{mass} ne $pg{$pgid}{mass}) { $massFlag = 'diff'; }
#   print qq($pgid\t$hash{$pgid}{molf}\t$pg{$pgid}{molf}\t$molfFlag\t$hash{$pgid}{mass}\t$pg{$pgid}{mass}\t$massFlag\n);
  if ($hash{$pgid}{mass}) {
    my $newmass = $hash{$pgid}{mass};
    if ($pg{$pgid}{mass}) { 
      push @pgcommands, qq(DELETE FROM mop_exactmass WHERE joinkey = '$pgid';); }
    push @pgcommands, qq(INSERT INTO mop_exactmass VALUES ('$pgid', '$newmass'););
    push @pgcommands, qq(INSERT INTO mop_exactmass_hst VALUES ('$pgid', '$newmass'););
  }
} # foreach my $pgid (sort {$a<=>$b} keys %hash)

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)
