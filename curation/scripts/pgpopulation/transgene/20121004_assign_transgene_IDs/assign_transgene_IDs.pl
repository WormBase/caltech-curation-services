#!/usr/bin/env perl

# assign ID to trp_name where there is a curator, there isn't already a trp_name and is not trp_objpap_falsepos
# for Karen.  2012 10 04
#
# symlinked to acedb, Karen cronjob set
# 0 4 * * * /home/acedb/karen/transgene/assign_transgene_IDs.pl
#
# dockerized, cronjob at
# 0 4 * * * /usr/lib/scripts/pgpopulation/transgene/20121004_assign_transgene_IDs/assign_transgene_IDs.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %has_name;
my %is_fail;
my %curator;

$result = $dbh->prepare( "SELECT * FROM trp_objpap_falsepos" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $is_fail{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $has_name{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM trp_curator" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $curator{$row[0]}++; } }

my @pgcommands;
foreach my $pgid (sort {$a<=>$b} keys %curator) {
  next if $is_fail{$pgid};
  next if $has_name{$pgid};
  my $trpId = &pad8Zeros($pgid);
  my $objId = 'WBTransgene' . $trpId;
  push @pgcommands, "INSERT INTO trp_name VALUES ('$pgid', '$objId');";
  push @pgcommands, "INSERT INTO trp_name_hst VALUES ('$pgid', '$objId');";
#   print "set $pgid to $objId\n";
} # foreach my $pgid (sort {$a<=>$b} keys %curator)

foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros


__END__
