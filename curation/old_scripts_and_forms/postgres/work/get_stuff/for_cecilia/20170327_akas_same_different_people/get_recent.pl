#!/usr/bin/perl -w

# query for akas with firstname and lastname corresponding to different people.  2017 03 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;


my %hash;

$result = $dbh->prepare( "SELECT two_lastname.joinkey, two_firstname.two_firstname, two_lastname.two_lastname  FROM two_lastname, two_firstname WHERE two_lastname.joinkey = two_firstname.joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $name = "$row[1] $row[2]";
  $hash{$name}{$row[0]}++;
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT two_aka_lastname.joinkey, two_aka_firstname.two_aka_firstname, two_aka_lastname.two_aka_lastname  FROM two_aka_lastname, two_aka_firstname WHERE two_aka_lastname.joinkey = two_aka_firstname.joinkey AND two_aka_lastname.two_order = two_aka_firstname.two_order;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $name = "$row[1] $row[2]";
  $hash{$name}{$row[0]}++;
} # while (@row = $result->fetchrow)

my %count;
foreach my $name (sort keys %hash) {
  my $count = scalar keys %{ $hash{$name} };
  $count{$name} = $count;
}

foreach my $name (sort {$count{$b} <=> $count{$a}} keys %count) {
  my $names = join", ", sort keys %{ $hash{$name} };
  print qq($name\t$count{$name}\t$names\n);
} 

__END__
