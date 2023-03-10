#!/usr/bin/perl -w

# add entries in pap_species_index not in obo_*_ncbitaxonid to obo_*_ncbitaxonid  2018 10 08

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %name;
my %syn;

$result = $dbh->prepare( "SELECT * FROM obo_name_ncbitaxonid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $name{$row[0]}{$row[1]}++; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM obo_syn_ncbitaxonid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $syn{$row[0]}{$row[1]}++; }
} # while (@row = $result->fetchrow)

my @pgcommands;
$result = $dbh->prepare( "SELECT * FROM pap_species_index" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $id = $row[0];
  my $name = $row[1];
  my $timestamp = $row[4];
  if (exists ($name{$id})) {
    next if ($name{$id}{$name});
    next if ($syn{$id}{$name});
    print qq(ID $name{$id}\n); 
    push @pgcommands, qq(INSERT INTO obo_syn_ncbitaxonid VALUES ('$id', '$name', '$timestamp'););
  }
  else {
    push @pgcommands, qq(INSERT INTO obo_name_ncbitaxonid VALUES ('$id', '$name', '$timestamp'););
  }
}

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)


__END__

testdb=# SELECT * FROM pap_species_index ;
 joinkey |       pap_species_index        | pap_join | pap_curator |         pap_timestamp         
---------+--------------------------------+----------+-------------+-------------------------------
 293684  | Acrobeles complexus            |          | two1843     | 2016-10-14 18:26:26.610776-07
 70226   | Aphelenchus avenae             |          | two1843     | 2016-10-14 18:26:26.637269-07
 27828   | Cooperia oncophora             |          | two1843     | 2016-10-14 18:26:26.665439-07

