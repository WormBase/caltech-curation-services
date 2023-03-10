#!/usr/bin/perl -w

# Find stuff from pap_possible that Cecilia connected (without necessarily having verification)
# that's not under aka or name.  2004 09 01

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

# my $result = $conn->exec( "SELECT * FROM two_unable_to_contact WHERE two_unable_to_contact != 'NULL';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     my $result2 = $conn->exec( "SELECT * FROM two_email WHERE joinkey = '$row[0]';" );
#     my @row2 = $result2->fetchrow;
#     if ($row2[0]) { print OUT "$row[0]\t$row2[2]\t$row[2]\n"; }
#   }
# }

my %pos;
my %temp_aka;
my %aka;

my $result = $conn->exec( "SELECT * FROM pap_possible WHERE pap_possible IS NOT NULL;" ); 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[1] =~ s/\".*$//g;
    $pos{$row[2]}{$row[1]}++; } }

my @tables = qw (first middle last);
foreach my $table (@tables) {
  $result = $conn->exec ( "SELECT * FROM two_aka_${table}name;" );
  while ( my @row = $result->fetchrow ) {
    $temp_aka{$row[0]}{$row[1]}{$table} = $row[2]; }
} # foreach my $table (@tables)
foreach my $two (sort keys %temp_aka) {
  foreach my $order (sort keys %{ $temp_aka{$two} }) {
    my $name = $temp_aka{$two}{$order}{first} . ' ' .  $temp_aka{$two}{$order}{middle} . ' ' .  $temp_aka{$two}{$order}{last};
    $name =~ s/NULL//g; $name =~ s/\s+/ /g;
if ($two eq 'two959') { print "AKA ONE -=${name}=-\n"; }
    $aka{$two}{$name}++; 
    $name = $temp_aka{$two}{$order}{last} . ' ' .  $temp_aka{$two}{$order}{first};
    $name =~ s/NULL//g; $name =~ s/\s+/ /g;
if ($two eq 'two959') { print "AKA TWO -=${name}=-\n"; }
    $aka{$two}{$name}++; } }
%temp_aka = ();
foreach my $table (@tables) {
  $result = $conn->exec ( "SELECT * FROM two_${table}name;" );
  while ( my @row = $result->fetchrow ) {
    $temp_aka{$row[0]}{$row[1]}{$table} = $row[2]; }
} # foreach my $table (@tables)
foreach my $two (sort keys %temp_aka) {
  foreach my $order (sort keys %{ $temp_aka{$two} }) {
    my $name = $temp_aka{$two}{$order}{first} . ' ' .  $temp_aka{$two}{$order}{middle} . ' ' .  $temp_aka{$two}{$order}{last};
    $name =~ s/NULL//g; $name =~ s/\s+/ /g;
if ($two eq 'two959') { print "NAME ONE -=${name}=-\n"; }
    $aka{$two}{$name}++;
    $name = $temp_aka{$two}{$order}{last} . ' ' .  $temp_aka{$two}{$order}{first};
    $name =~ s/NULL//g; $name =~ s/\s+/ /g;
if ($two eq 'two959') { print "NAME TWO -=${name}=-\n"; }
    $aka{$two}{$name}++; } }

foreach my $two_num (sort keys %pos) {
  foreach my $pos_name (sort keys %{ $pos{$two_num} }) {
    print OUT "$two_num\t$pos_name\n" unless ($aka{$two_num}{$pos_name}); } }


close (OUT) or die "Cannot close $outfile : $!";
