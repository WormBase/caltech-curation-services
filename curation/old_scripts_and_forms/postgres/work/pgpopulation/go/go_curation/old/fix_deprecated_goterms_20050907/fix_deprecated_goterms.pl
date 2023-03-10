#!/usr/bin/perl -w

# Look at the ``this_is.errors'' file (a grep -A2 "this is a secondary" errors
# from the script that Kimberly has from someone or other) to find xrefs of
# secondary terms and the terms they should now be.  Map the IDs and the Terms
# then update timestamps and values.
#
# The first run, the timestamp wasn't set properly, so the timestamps were not
# updated, then after fixing the script, the values were no longer wrong, so 
# those didn't get updated but the logfile got overwritten.  logfile now
# includes day and timestamp.  2005 09 07


use strict;
use diagnostics;
use Pg;
use Jex qw(getSimpleSecDate);


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();
my $outfile = "outfile." . $date;
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %old;
my $infile = 'this_is.errors';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/this is a secondary ID (GO:\d{7}) should use (GO:\d{7}) instead/) {
    my $old = $1; my $new = $2;
    $old{id}{$old} = $new;
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my @tables = qw(got_bio got_mol got_cell);

foreach my $old_id (sort keys %{ $old{id} }) {
  my $new_id = $old{id}{$old_id};
  my $result = $conn->exec( "SELECT got_goterm FROM got_goterm WHERE got_goid = '$old{id}{$old_id}';" );
  my @row = $result->fetchrow;
  if ($row[0]) { $old{term}{$old_id} = $row[0]; }
    else { 
      my $result = $conn->exec( "SELECT got_obsoleteterm FROM got_obsoleteterm WHERE got_goid = '$old{id}{$old_id}';" );
      my @row = $result->fetchrow;
      if ($row[0]) { $old{term}{$old_id} = $row[0]; }
        else { $old{term}{$old_id} = ''; } }
  print OUT "OID $old_id\tNID $new_id\tNTERM $old{term}{$old_id}\n";
  foreach my $table (@tables) {
    my $pg_table = $table . '_goid';
    my $result = $conn->exec( "SELECT * FROM $pg_table WHERE $pg_table = '$old_id';" );
    while (my @row = $result->fetchrow) {
      print OUT "$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
      my $pgcommand = "UPDATE ${table}_goterm SET got_timestamp = CURRENT_TIMESTAMP WHERE got_order = '$row[1]' AND joinkey = '$row[0]'; ";
      print OUT "$pgcommand\n";
      my $result2 = $conn->exec( "$pgcommand" );
      $pgcommand = "UPDATE ${table}_goterm SET ${table}_goterm = '$old{term}{$old_id}' WHERE got_order = '$row[1]' AND joinkey = '$row[0]'; ";
      print OUT "$pgcommand\n";
      $result2 = $conn->exec( "$pgcommand" );
      $pgcommand = "UPDATE ${table}_goid SET got_timestamp = CURRENT_TIMESTAMP WHERE got_order = '$row[1]' AND joinkey = '$row[0]'; ";
      print OUT "$pgcommand\n";
      $result2 = $conn->exec( "$pgcommand" );
      $pgcommand = "UPDATE ${table}_goid SET ${table}_goid = '$new_id' WHERE got_order = '$row[1]' AND joinkey = '$row[0]'; ";
      print OUT "$pgcommand\n";
      $result2 = $conn->exec( "$pgcommand" );
    } # while (my @row = $result->fetchrow)
  } # foreach my $table (@tables)
} # foreach my $old_id (sort keys %{ $old{$id} }) 


close (OUT) or die "Cannot close $outfile : $!";

