#!/usr/bin/perl -w

# filter alp_paper and get all current WBPapers.  Testing for populate_app.pl  2008 03 05  

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;  my %pap;
my $result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{$row[0]}{$row[1]} = $row[2]; } }
foreach my $joinkey (sort keys %hash) {
  foreach my $order (sort keys %{ $hash{$joinkey} }) {
    my $data = $hash{$joinkey}{$order};
    if ($data =~ m/(WBPaper\d+)/) { $pap{$1}++; } } }
foreach my $pap (sort keys %pap) {
  print "$pap E\n"; }

__END__

