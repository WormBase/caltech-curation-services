#!/usr/bin/perl -w

# look at all verified data and see if any author_id has been verified as YES
# more than once (under different wpa_join)  2008 08 21

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %check;
# $check{'42881'}++;
# $check{'46308'}++;
# $check{'5096'}++;
# $check{'5281'}++;
# $check{'61449'}++;
# $check{'63418'}++;
# $check{'64243'}++;
$check{'64648'}++;
# $check{'64976'}++;
# $check{'64997'}++;
# $check{'65078'}++;
# $check{'66382'}++;
$check{'67117'}++;
# $check{'68932'}++;
# $check{'69575'}++;
# $check{'69592'}++;
# $check{'69717'}++;
# $check{'69719'}++;
# $check{'69743'}++;
# $check{'70143'}++;
# $check{'70370'}++;
# $check{'71284'}++;
# $check{'71380'}++;
# $check{'71491'}++;
# $check{'71845'}++;
# $check{'72052'}++;
# $check{'72057'}++;
# $check{'72177'}++;
# $check{'76584'}++;
# $check{'77096'}++;
# $check{'77508'}++;
# $check{'78200'}++;
# $check{'78701'}++;
# $check{'79401'}++;
# $check{'79403'}++;
# $check{'80049'}++;
# $check{'81900'}++;
# $check{'84115'}++;
# $check{'85154'}++;
# $check{'86989'}++;
# $check{'90398'}++;
# $check{'94212'}++;
# $check{'96675'}++;


my %hash;
# my $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id = '42881' AND wpa_join IS NOT NULL ORDER BY wpa_timestamp DESC;" );
my $result = $conn->exec( "SELECT * FROM wpa_author_verified WHERE author_id IS NOT NULL AND wpa_join IS NOT NULL ORDER BY wpa_timestamp ;" );
while (my @row = $result->fetchrow) {
#   next unless ($check{$row[0]});
# print "LOOK at @row\n";
#   next unless ($row[0]);
#   next unless ($row[2]);
  if ($row[3] eq 'valid') { $hash{$row[0]}{$row[2]} = $row[1]; }
    else { delete $hash{$row[0]}{$row[2]}; }
} # while (@row = $result->fetchrow)

foreach my $aid (sort keys %hash) {
# print "AID $aid\n";
  my $yes_count = 0;
  foreach my $order (keys %{ $hash{$aid} }) {
# print "ORDER $order\n";
    if ($hash{$aid}{$order}) { 
# print "IF\n";
      if ($hash{$aid}{$order} =~ m/YES/) { 
# print "YES\n"; 
        $yes_count++; } } }
  if ($yes_count > 1) { print "AID $aid has $yes_count Yes\n"; }
}

__END__

