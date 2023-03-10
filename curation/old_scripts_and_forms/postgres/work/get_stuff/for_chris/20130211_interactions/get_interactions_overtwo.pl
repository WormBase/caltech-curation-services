#!/usr/bin/perl -w

# get interaction rows with more than 3 objects in specific fields  2013 01 11

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @int = qw( genebait genetarget genenondir geneone genetwo rearrnondir rearrone rearrtwo otherone othertwo );
my @grg = qw( transregulator moleculeregulator otherregulator transregulated otherregulated );

my %int;
my %grg;

foreach my $table (@int) {
  $result = $dbh->prepare( "SELECT * FROM int_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
  if ($row[0]) { $int{$row[0]}{$table} = $row[1]; } }
} # foreach my $table (@int)

foreach my $pgid (sort {$a<=>$b} keys %int) {
  my @all_objs;
  foreach my $table (sort keys %{ $int{$pgid} }) {
    my @objs = split/,/, $int{$pgid}{$table};
    foreach (@objs) { push @all_objs, $_; }
  }
  if (scalar(@all_objs) > 2) { print "int_\t$pgid\t@all_objs\n"; }
} # foreach my $pgid (sort keys %int)


foreach my $table (@grg) {
  $result = $dbh->prepare( "SELECT * FROM grg_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
  if ($row[0]) { $grg{$row[0]}{$table} = $row[1]; } }
} # foreach my $table (@grg)

foreach my $pgid (sort {$a<=>$b} keys %grg) {
  my @all_objs;
  foreach my $table (sort keys %{ $grg{$pgid} }) {
    my @objs = split/,/, $grg{$pgid}{$table};
    foreach (@objs) { push @all_objs, $_; }
  }
  if (scalar(@all_objs) > 2) { print "grg_\t$pgid\t@all_objs\n"; }
} # foreach my $pgid (sort keys %grg)
