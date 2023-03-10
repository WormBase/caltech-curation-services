#!/usr/bin/perl -w

# generate list of PI emails for MaryAnn, Todd, Cecilia.  2015 12 17

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %two;
$result = $dbh->prepare( "SELECT * FROM two_email WHERE joinkey IN (SELECT joinkey FROM two_pis) ORDER BY two_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[2]) { 
     $two{$row[0]}{email} = $row[2]; } }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM two_left_field;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $two{$row[0]}{left_field} = $row[2]; } }

$result = $dbh->prepare( "SELECT * FROM two_pis;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $two{$row[0]}{pis} = $row[2]; } }

$result = $dbh->prepare( "SELECT * FROM two_standardname WHERE joinkey IN (SELECT joinkey FROM two_pis);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $two{$row[0]}{name} = $row[2]; } }

foreach my $joinkey (sort { $two{$a}{pis} cmp $two{$b}{pis} } keys %two) {
  next if $two{$joinkey}{left_field};
  next unless $two{$joinkey}{pis};
  next unless ($two{$joinkey}{pis} =~ m/[A-Z]/);
  my $wbperson = $joinkey; $wbperson =~ s/two/WBPerson/;
  print qq($two{$joinkey}{pis}\t$wbperson\t$two{$joinkey}{name}\t$two{$joinkey}{email}\n);
} # foreach my $joinkey (sort keys %emails)

