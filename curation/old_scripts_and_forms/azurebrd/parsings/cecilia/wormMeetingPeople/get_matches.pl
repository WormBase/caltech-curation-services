#!/usr/bin/perl -w
#
# get list of abstracts from intl meeting, match by last name, output matches
# with emails.  2003 06 17

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $infile = "grepOut";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $name = <IN>) {
  chomp $name;
  my ($last) = $name =~ m/\s(\S+)$/;
  print "MATCHES FOR $name :\n";
  &matchUp($last, $name);
  print "\n";
}
close (IN) or die "Cannot close $infile : $!";

sub matchUp {
  my %joink;
  my ($last, $name) = @_;
  my $result = $conn->exec( "SELECT * FROM two_lastname WHERE two_lastname = '$last';" );
  while (my @row = $result->fetchrow) { if ($row[0]) { $joink{$row[0]}++; } }
  $result = $conn->exec( "SELECT * FROM two_aka_lastname WHERE two_aka_lastname = '$last';" );
  while (my @row = $result->fetchrow) { if ($row[0]) { $joink{$row[0]}++; } }
  foreach my $joinkey (sort keys %joink) { &getOutput($joinkey, $name); }
} # sub matchUp

sub getOutput {
  my ($first, $last, $email);
  my ($joinkey, $name) = @_;
  my $result = $conn->exec( "SELECT * FROM two_firstname WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow; if ($row[2]) { $first = $row[2]; }
  $result = $conn->exec( "SELECT * FROM two_lastname WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow; if ($row[2]) { $last = $row[2]; }
  $result = $conn->exec( "SELECT * FROM two_email WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow; if ($row[2]) { $email = $row[2]; }
  print "$name\t$first $last\t$joinkey\t$email\n";
} # getOutput

