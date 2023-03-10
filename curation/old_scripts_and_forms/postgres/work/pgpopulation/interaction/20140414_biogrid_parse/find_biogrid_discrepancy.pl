#!/usr/bin/perl -w

# compare biogrid file from http://thebiogrid.org/downloads/datasets/WORMBASE.tab.txt
# to what's in postgres under int_genebait + int_genetarget .  We don't know if Biogrid
# has things properly ordered, so arbitrarily sort pairs numerically.  Sometimes in pg, 
# there will only be bait or target and not both ;  this is wrong, so ignore these.
# 2014 04 14

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pg;
$result = $dbh->prepare( "SELECT int_genetarget.joinkey, int_genetarget.int_genetarget, int_genebait.int_genebait FROM int_genebait, int_genetarget WHERE int_genebait.joinkey = int_genetarget.joinkey AND int_genetarget.joinkey IN (SELECT joinkey FROM int_paper WHERE int_paper = 'WBPaper00006332') " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my @to_sort;
  if ($row[1]) { $row[1] =~ s/"//g; push @to_sort, $row[1]; }	# strip doublequotes from target, there should only ever be one value in multiontology
  if ($row[2]) { push @to_sort, $row[2]; }
  my $sorted = join"\t", sort @to_sort;
  $pg{$sorted}{$row[0]}++;
} # while (@row = $result->fetchrow)

my %biogrid;
my $infile = 'WORMBASE.tab.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@fields) = split/\t/, $line;
  next unless ($fields[9]);
  if ($fields[9] eq '14704431') {
    my @to_sort;
    if ($fields[4] =~ m/(WBGene\d+)/) { push @to_sort, $1; }
    if ($fields[5] =~ m/(WBGene\d+)/) { push @to_sort, $1; }
    my $sorted = join"\t", sort @to_sort;
    $biogrid{$sorted}++;
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $pair (sort keys %biogrid) {
  unless ($pg{$pair}) { 
    print "BG not PG\t$pair\n";
  }
} # foreach my $pair (sort keys %pg)

print "\n\n";

foreach my $pair (sort keys %pg) {
  unless ($biogrid{$pair}) { 
    my $pgids = join", ", sort keys %{ $pg{$pair} };
    print "PG not BG\t$pair\t$pgids\n";
  }
} # foreach my $pair (sort keys %pg)


