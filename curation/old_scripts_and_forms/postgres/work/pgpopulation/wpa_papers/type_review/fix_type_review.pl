#!/usr/bin/perl -w

# change type to review when cur_comment says ``review''.   for Andrei / Karen  2009 02 19

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %type;
my %joinkeys;

my $result = $conn->exec( "SELECT * FROM wpa_type ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $type{$row[0]}{$row[1]}++; }
    else { delete $type{$row[0]}{$row[1]}; } }

my @pgcommands;
$result = $conn->exec( "SELECT joinkey FROM cur_comment WHERE cur_comment ~ 'review' OR cur_comment ~ 'Review';" );
while (my @row = $result->fetchrow) {
  my $key = $row[0];
  next unless ($key =~ m/^\d{8}$/);
  next if ($type{$key}{"2"}); 
#   unless ($type{$key}{"2"}) { print "ADD $key\n"; }
  foreach my $type (keys %{ $type{$key} }) {
    my $command = "INSERT INTO wpa_type VALUES ('$key', '$type', NULL, 'invalid', 'two480');";
    push @pgcommands, $command;
  } # foreach my $type (keys %{ $type{$key} })
  my $command = "INSERT INTO wpa_type VALUES ('$key', '2', NULL, 'valid', 'two480');";
  push @pgcommands, $command;
}

foreach my $command (@pgcommands) {
  print "$command\n";
  $result = $conn->exec( $command );
} # foreach my $command (@pgcommands)


# my $result = $conn->exec( " SELECT joinkey FROM cur_comment WHERE cur_comment ~ 'review' AND joinkey NOT IN (SELECT joinkey FROM wpa_type WHERE wpa_type = '2');" );
# while (my @row = $result->fetchrow) { if ($row[0]) { $joinkeys{$row[0]}++; } } 
# 
# foreach my $joinkey (sort keys %joinkeys) {
#   my %type;
#   $result = $conn->exec( " SELECT * FROM wpa_type ORDER BY wpa_timestamp" );
#   while (my @row = $result->fetchrow) { 
#     if ($row[3] eq 'valid') { $type{$row[1]}++; }
#       else { delete $type{$row[1]}; } }
#   if ($type{"2"}) { print "ALREADY THERE $joinkey\n"; }
# #   foreach my $type (key
# } # foreach my $joinkey (sort keys %joinkeys)

__END__

