#!/usr/bin/perl -w

# update curators from cur_curator to be two#### instead of full names
# of curators.  2005 08 22


use strict;
use diagnostics;
use Pg;
use Jex;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile.update_cur_curator";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";


my $result = $conn->exec( "SELECT * FROM cur_curator ;" );
while (my @row = $result->fetchrow) {
  my $joinkey = ''; my $data = ''; my $timestamp = '';
  if ($row[0]) { $joinkey = $row[0]; }
  if ($row[1]) { $data = $row[1]; }
  if ($row[2]) { $timestamp = $row[2]; }
  if ($row[1] eq "Andrei Petcherski") { $data = 'two480'; }
  elsif ($row[1] eq "Raymond Lee") { $data = 'two363'; }
  elsif ($row[1] eq "Erich Schwarz") { $data = 'two567'; }
  elsif ($row[1] eq "Ranjana Kishore") { $data = 'two324'; }
  elsif ($row[1] eq "Gene Function Only") { $data = 'two324'; }
  elsif ($row[1] eq "Paul Sternberg") { $data = 'two625'; }
  elsif ($row[1] eq "Wen Chen") { $data = 'two101'; }
  elsif ($row[1] eq "Carol Bastiani") { $data = 'two48'; }
  elsif ($row[1] eq "Kimberly Van Auken") { $data = 'two1843'; }
  elsif ($row[1] eq "Kimberly Van Auken : RNAi Only") { $data = 'two1843'; }
  elsif ($row[1] eq "Igor Antoshechkin") { $data = 'two22'; }
  elsif ($row[1] eq "Juancarlos Testing") { $data = 'two1823'; }
  else { 
    my @stuff = split"\t", $data;
    my $greatest_timestamp = 0; my $greatest_copy_timestamp = 0;
    my $current_curator = '';
    while (@stuff) { 
      my $joinkey = shift @stuff;
      my $each_data = shift @stuff;
      my $timestamp = shift @stuff;
      my $copy_timestamp = $timestamp; $copy_timestamp =~ s/\D//g; $copy_timestamp =~ m/(\d{12})/; $copy_timestamp = $1;
      if ($copy_timestamp > $greatest_copy_timestamp) { 
        $current_curator = $each_data;
        $greatest_timestamp = $timestamp; $greatest_copy_timestamp = $copy_timestamp; }
    } # while (@stuff) 
    if ($current_curator eq "Andrei Petcherski") { $data = 'two480'; }
    elsif ($current_curator eq "Raymond Lee") { $data = 'two363'; }
    elsif ($current_curator eq "Erich Schwarz") { $data = 'two567'; }
    elsif ($current_curator eq "Ranjana Kishore") { $data = 'two324'; }
    elsif ($current_curator eq "Gene Function Only") { $data = 'two324'; }
    elsif ($current_curator eq "Paul Sternberg") { $data = 'two625'; }
    elsif ($current_curator eq "Wen Chen") { $data = 'two101'; }
    elsif ($current_curator eq "Carol Bastiani") { $data = 'two48'; }
    elsif ($current_curator eq "Kimberly Van Auken") { $data = 'two1843'; }
    elsif ($current_curator eq "Kimberly Van Auken : RNAi Only") { $data = 'two1843'; }
    elsif ($current_curator eq "Igor Antoshechkin") { $data = 'two22'; }
    elsif ($current_curator eq "Juancarlos Testing") { $data = 'two1823'; }
    else { print "ERR $joinkey $data\n"; }
  }
  my $pg_command = "UPDATE cur_curator SET cur_curator = '$data' WHERE joinkey = '$joinkey';";
  my $result2 = $conn->exec( "$pg_command" ); 
  print OUT "$pg_command\n";
} # while (my @row = $result->fetchrow)



close (OUT) or die "Cannot close $outfile : $!";


