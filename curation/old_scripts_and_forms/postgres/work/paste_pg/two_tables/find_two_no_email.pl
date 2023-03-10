#!/usr/bin/perl

# find two entries without an email address

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %last;
my %email; 
my @none;		# twos without email

my $result = $conn->exec( "SELECT joinkey FROM two_lastname;" );
while (my @row = $result->fetchrow) {
  my $joinkey = '';
  if ($row[0]) { $last{$row[0]}++; }
}

$result = $conn->exec( "SELECT joinkey FROM two_email;" );
while (my @row = $result->fetchrow) {
  my $joinkey = '';
  if ($row[0]) { $email{$row[0]}++; }
}

foreach $_ (sort keys %last) {
  unless ($email{$_}) { push @none, $_; }
} # foreach $_ (sort keys %last)

print "There are " . scalar(@none) . " entries without email out of " . scalar(keys %last) . "\n";

