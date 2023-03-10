#!/usr/bin/perl -w

# populate wpa_rnai_curation based on ref_checked_out  2005 09 19

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %id;
my $result = $conn->exec( "SELECT * FROM wpa_identifier ;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $id{$row[1]} = $row[0]; }
    else { delete $id{$row[1]}; }
}

$result = $conn->exec( "SELECT * FROM ref_checked_out WHERE ref_checked_out ~ 'RNAi';" );
while (my @row = $result->fetchrow) {
  if ($id{$row[0]}) { 
    my $two = '';
    if ($row[1] =~ m/Andrei/) { $two = 'two480'; }
    elsif ($row[1] =~ m/Igor/) { $two = 'two22'; }
    elsif ($row[1] =~ m/Kimberly/) { $two = 'two1843'; }
    else { $two = 'BAD $row[1]'; }
    if ($row[2] =~ m/\.\d+\-\d+$/) { $row[2] =~ s/\.\d+\-\d+$//; } 
    my $pg_command = "INSERT INTO wpa_rnai_curation VALUES ('$id{$row[0]}', '$two', NULL, 'valid', '$two', '$row[2]')";
    $conn->exec( $pg_command );
    print OUT "$pg_command\n";
  }
} # while (my @row = $result->fetchrow)


close (OUT) or die "Cannot close $outfile : $!";
