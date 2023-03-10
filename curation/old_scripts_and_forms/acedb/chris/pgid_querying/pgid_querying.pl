#!/usr/bin/perl -w

# query for pgids to paste into OA

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $batch_size = '500';
my @lists;

my $result = $dbh->prepare( "SELECT * FROM int_detectionmethod WHERE int_detectionmethod ~ 'Yeast_two_hybrid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my $count = 0;
my @list = ();
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $count++;
    push @list, $row[0];
    if ($count > $batch_size) { 
      $count = 0;
      my $list = join",", @list;
      push @lists, $list;
      @list = ();
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach (@lists) {
  print "$_\n";
}

__END__

