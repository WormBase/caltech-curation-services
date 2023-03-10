#!/usr/bin/perl -w

# get FP comment data for ``no curated'' and get list of WBPapers that are not reviews or
# abstracts.  sort by journal.  For Karen.  2009 02 20

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %type;
my $result = $conn->exec( "SELECT * FROM wpa_type ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $type{$row[0]}{$row[1]}++; }
    else { delete $type{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)

my %type_index;
$result = $conn->exec( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { $type_index{$row[0]} = $row[1]; }

my %journal;
$result = $conn->exec( "SELECT * FROM wpa_journal ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $journal{$row[0]}{$row[1]}++; }
    else { delete $journal{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)


my %valid;
$result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $valid{$row[0]}{$row[1]}++; }
    else { delete $valid{$row[0]}{$row[1]}; }
} # while (@row = $result->fetchrow)

my %sort;
$result = $conn->exec( "SELECT * FROM cur_comment WHERE cur_comment ~ 'no curata';" );
while (my @row = $result->fetchrow) {
  next unless ($valid{$row[0]});
  next if ($type{$row[0]}{"2"});
  next if ($type{$row[0]}{"3"});
  next if ($type{$row[0]}{"4"});
  my @types; foreach my $type (sort keys %{ $type{$row[0]} }) { push @types, $type_index{$type}; }
  my $types = join ", ", @types;
  my @journals; foreach my $journal (sort keys %{ $journal{$row[0]} }) { push @journals, $journal; }
  my $journals = join ", ", @journals;
  $sort{$journals}{"$row[0]\t$journals\t$types\t$row[1]"}++;
} # while (@row = $result->fetchrow)

foreach my $journal (sort keys %sort) {
  foreach my $entry (sort keys %{ $sort{$journal} }) {
    print "$entry\n";
  }
} # foreach my $entry (sort keys %sort)

__END__

