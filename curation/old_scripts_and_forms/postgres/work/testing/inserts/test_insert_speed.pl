#!/usr/bin/perl -w

# test insert speed    2014 03 29
# 0.106122016906738 seconds for 10000 writes in batch
# 134.093772172928 seconds for 10000 writes in sequence

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Time::HiRes qw (time) ;

my $dbh = DBI->connect ( "dbi:Pg:dbname=insdb", "", "") or die "Cannot connect to database!\n"; 

my $table = 'testm';
$dbh->do( "DELETE FROM $table;" );

my $max   = 10000;
my $start = time;

my @values = ();
for my $i (1 .. $max) {
  push @values, "('one$i', 'two$i')";
} # for (1 .. $max)
my $values = join", ", @values;
my $insert = "INSERT INTO $table VALUES " . $values . ";";
# print "$insert\n";
$dbh->do( $insert );

my $end   = time;
my $diff = $end - $start;
print "$diff seconds for $max writes in batch";


$table = 'testy';
$dbh->do( "DELETE FROM $table;" );

$start = time;

for my $i (1 .. $max) {
  my $values = "('one$i', 'two$i')";
  my $insert = "INSERT INTO $table VALUES " . $values . ";";
  # print "$insert\n";
  $dbh->do( $insert );
} # for (1 .. $max)

$end   = time;
$diff = $end - $start;
print "$diff seconds for $max writes in sequence";

__END__

my $result = $dbh->prepare( "SELECT * FROM testy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

