#!/usr/bin/perl -w

# Oliver thought there were too many German and UK results, generate the labs and PIs for a given set of countries.  2020 06 16


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %labs;
$result = $dbh->prepare( "SELECT * FROM two_pis WHERE two_pis ~ '[A-Z]'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $labs{$row[2]}{$row[0]}++; }
} # while (@row = $result->fetchrow)

my %name;
$result = $dbh->prepare( "SELECT * FROM two_standardname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $name{$row[0]} = $row[2]; }
} # while (@row = $result->fetchrow)

my $count = 0;
my %state;
my %country;

my %filterCountry;
$filterCountry{'Germany'}++;
$filterCountry{'United Kingdom'}++;

foreach my $lab (sort keys %labs) {
  my %location;
  foreach my $two (sort keys %{ $labs{$lab} }) {
    $result = $dbh->prepare( "SELECT * FROM two_country WHERE joinkey = '$two' AND two_order = 1" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow();
    if ($row[2]) { 
      if ($filterCountry{$row[2]}) {
        $country{$row[2]}{$lab}{$two}++;
    } }
  }
#     if ($row[2]) { 
#       if ($row[2] !~ m/United States/) { $location{$row[2]}++; $country{$row[2]}++; }
#         else {
#           $result = $dbh->prepare( "SELECT * FROM two_state WHERE joinkey = '$two' AND two_order = 1" );
#           $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#           @row = $result->fetchrow();
#           if ($row[2]) { $location{$row[2]}++; $state{$row[2]}++; } } }
#     $count++;
# #     last if ($count > 100);
#   } # foreach my $two (sort keys %{ $labs{$lab} })
#   my @location = sort keys %location;
#   my $location = join", ", @location;
#   my @pis = sort keys %{ $labs{$lab} };
#   my $pis = join", ", @pis;
#   if (scalar @location > 1) { print qq($lab has multiple PIs $pis at $location\n); }
} # foreach my $lab (sort keys %labs)

foreach my $country (sort keys %country) {
  print qq($country\n);
  foreach my $lab (sort keys %{ $country{$country} }) {
    my %names;
    foreach my $two (sort keys %{ $country{$country}{$lab} }) {
#       print qq(TWO $two\n);
      $names{$name{$two}}++;
    }
    my @names = sort keys %names;
    my $names = join", ", @names;
    print qq($lab\t$names\n);
  }
  print qq(\n);
} 
# foreach my $state (sort keys %state) {
#   print qq($state\t$state{$state}\n);
# } 

__END__
