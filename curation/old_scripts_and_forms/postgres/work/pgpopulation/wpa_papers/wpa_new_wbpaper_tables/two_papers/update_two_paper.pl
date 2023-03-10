#!/usr/bin/perl -w

# update wbpapers in two_paper to use wbpapers
#
# store copies of two_paper's data in 
# /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/two_papers/20050822_non_converted_backup/two_paper.pg.20050822.162826
# 2005 08 22


use strict;
use diagnostics;
use Pg;
use Jex;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile.update_two_paper";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %wbPaper;
my $result = $conn->exec( "SELECT * FROM wpa_identifier ORDER BY wpa_timestamp ;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $wbPaper{$row[1]} = $row[0]; }
    else { delete $wbPaper{$row[1]}; }
} # while (my @row = $result->fetchrow) 

my %no_convertion;

# my $date = &getSimpleSecDate;
my %stored_data;

my $table = 'two_paper';
#   $result = $conn->exec( "COPY $table TO '/home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/two_papers/20050822_non_converted_backup/$table.pg.$date' ;" );
$result = $conn->exec( "SELECT * FROM $table ;" );
while (my @row = $result->fetchrow) {
  my $joinkey = ''; my $unconverted = ''; my $timestamp = '';
  if ($row[0]) { $joinkey = $row[0]; }
  if ($row[1]) { $unconverted = $row[1]; }
  if ($row[2]) { $timestamp = $row[2]; }
  my $two_number = '0';
  unless ($unconverted) { next; }	# skip if no data
  unless ($wbPaper{$unconverted}) {
    if ($row[1]) { $no_convertion{$row[1]}{$row[0]}++; }
    next; }			# skip if no wbpaper for that cgc / pmid
  my $wbpaper = $wbPaper{$unconverted};
  my $pg_command = "UPDATE $table SET $table = '$wbpaper' WHERE $table = '$unconverted'";
  my $result2 = $conn->exec( "$pg_command" ); 
  print OUT "$pg_command\n";
} # while (my @row = $result->fetchrow)

foreach my $paper (sort keys %no_convertion) {
  my @temp;
  foreach my $joinkey (sort keys %{ $no_convertion{$paper} }) { push @temp, $joinkey; }
  my $person = join", ", @temp;
  print "No convertion for paper $paper with persons $person\n"; 
} # foreach my $paper (sort keys %no_convertion)




close (OUT) or die "Cannot close $outfile : $!";


