#!/usr/bin/perl -w


use strict;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @wpas;
my $order_by = ' ORDER BY joinkey DESC';

my %bad; 
my $result = $conn->exec( "SELECT * FROM wpa_type WHERE wpa_type = '3'; "); 
while (my @row = $result->fetchrow) { $bad{$row[0]}++; }	# put meeting abstracts in bad hash to exclude

my @dates = ('2004-03-15', '2005-03-15', '2005-05-05', '2006-06-27');

foreach my $date (@dates) {
  my $count = 0;
  $result = $conn->exec( "SELECT * FROM wpa WHERE wpa_timestamp < '$date' $order_by ; ");
  while (my @row = $result->fetchrow) { unless ($bad{$row[0]}) { $count++; } }
  print "DATE $date TOTAL WBPapers $count\n"; 
}

__END__

  elsif ($sort_type eq 'not_curated') {										# not curated
    my %bad; $result = $conn->exec( "SELECT * FROM cur_curator WHERE joinkey ~ '^0'; "); 
    while (my @row = $result->fetchrow) { $bad{$row[0]}++; }	# put curated ones in bad hash to exclude
    $result = $conn->exec( "SELECT * FROM wpa_type WHERE wpa_type = '3'; ");					# exclude meeting abstracts since those are never curated
    while (my @row = $result->fetchrow) { $bad{$row[0]}++; }	# put meeting abstracts in bad hash to exclude
    my %invalid; $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp ; "); 			# get hash of invalid papers so as not to print those  2006 05 18
    while (my @row = $result->fetchrow) { if ($row[3] eq 'invalid') { $invalid{$row[0]}++; } else { delete $invalid{$row[0]}; } }
    $result = $conn->exec( "SELECT * FROM wpa $order_by ; "); 	# push into array if not to be excluded
    while (my @row = $result->fetchrow) { unless ($bad{$row[0]}) { unless ($invalid{$row[0]}) { push @wpas, $row[0]; } } } }
