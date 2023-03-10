#!/usr/bin/perl -w

# check multivalue construct OA fields to see if any history objects have been removed.
# 2014 11 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( exp_construct grg_construct int_construct pro_construct sqf_construct trp_construct trp_coinjectionconstruct );

my %objects;

foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM ${table}_hst" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      my (@objs) = $row[1] =~ m/(WBCnstr\d+)/g;
      foreach (@objs) { $objects{$table}{$row[0]}{$_}++; } }
  } # while (@row = $result->fetchrow)
  $result = $dbh->prepare( "SELECT * FROM ${table}" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my %cur;
    my $pgid = $row[0];
    my (@objs) = $row[1] =~ m/(WBCnstr\d+)/g;
    foreach (@objs) { $cur{$_}++; }
    my $cur    = join'","', sort keys %cur;
    my $allObj = join'","', sort keys %{ $objects{$table}{$pgid} };
    unless ($cur eq $allObj) { print qq($table\t$pgid\t"$cur"\t"$allObj"\n); }
  }
}

