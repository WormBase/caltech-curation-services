#!/usr/bin/perl -w

# move abp_humandoid + abp_diseasepaper to abp_remark  For Daniela and Ranjana.  2021 06 12

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @tables = qw( humandoid diseasepaper remark );

my %pg;

my %doid;
$result = $dbh->prepare( "SELECT * FROM obo_name_humando" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $doid{$row[0]} = $row[1]; } } 

foreach my $table (@tables) {
  $result = $dbh->prepare( "SELECT * FROM abp_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pg{$table}{$row[0]} = $row[1]; } } }

my @pgcommands;

foreach my $pgid (sort keys %{ $pg{'humandoid'} }) {
  if ($pg{'remark'}{$pgid}) { print qq($pgid already has remark\n); next; }
  my @doids; my $papers;
  if ($pg{'humandoid'}{$pgid}) { (@doids) = $pg{'humandoid'}{$pgid} =~ m/(DOID:\d+)/g; }
  if ($pg{'diseasepaper'}{$pgid}) { 
    my (@papers) = $pg{'diseasepaper'}{$pgid} =~ m/(WBPaper\d+)/g; 
    $papers = join", ", @papers;
  }
  my @remark;
  foreach my $doid (@doids) {
    my $name = $doid{$doid};
    push @remark, qq($name ($doid; $papers));
  }
  my $remark = join"; ", @remark;
  $remark = "Antibody for disease: $remark";
#   print qq($pgid\t$remark\n);
  $remark =~ s/\'/''/g;
  push @pgcommands, qq(INSERT INTO abp_remark VALUES ('$pgid', E'$remark'););
  push @pgcommands, qq(INSERT INTO abp_remark_hst VALUES ('$pgid', E'$remark'););
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)
