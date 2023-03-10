#!/usr/bin/perl -w

# Script to run (change the curator) when forgetting to click the ``functional
# annotation only'' checkbox.   2006 10 05

use strict;
use diagnostics;
use Pg;

use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();
my $outfile = 'outfile.' . $date;
open (PG, ">$outfile") or die "Cannot create $outfile : $!";

# CHANGE THIS as appropriate
my $two_num = 'two567';
# my @joinkeys = qw( 28533 );
# for my $joinkey ( 28533 .. 28545 ) 
# for my $joinkey ( 28571 .. 28574 ) 
# for my $joinkey ( 28594 .. 28595 ) 
for my $joinkey ( 28575 .. 28577 ) 
{

  $joinkey = '000' . $joinkey;
  my $pg_command = "INSERT INTO wpa_checked_out VALUES ('$joinkey', '$two_num', NULL, 'valid', '$two_num', CURRENT_TIMESTAMP);";
  print PG "$pg_command\n";
  my $result = $conn->exec( $pg_command );
  my $pg_command2 = "INSERT INTO cur_curator VALUES ('$joinkey', '$two_num', CURRENT_TIMESTAMP);";
  print PG "$pg_command2\n";
  my $result2 = $conn->exec( $pg_command2 );
  $pg_command2 = "INSERT INTO cur_comment VALUES ('$joinkey', 'the paper is used for functional annotations', CURRENT_TIMESTAMP);";
  print PG "$pg_command2\n";
  $result2 = $conn->exec( $pg_command2 );
  my $infile = '/home/postgres/public_html/cgi-bin/curation.cgi';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  $/ = undef; my $all_file = <IN>; $/ = "\n";
  close (IN) or die "Cannot close $infile : $!";
  my $params = '';
  if ($all_file =~ m/my \@PGparameters \= qw\((.*?)\)\;/ms) { $params = $1; }
  unless ($params) { print "ERROR can't find postgres tables cur_ paramters from curation.cgi so postgres not properly populated<BR>\n"; }
  if ($params) {
    my @params = split/\s+/, $params;
    foreach my $pgparam (@params) {
      next if ($pgparam eq 'curator');
      next if ($pgparam eq 'comment');
      next if ($pgparam eq 'pubID');
      next if ($pgparam eq 'pdffilename');
      next if ($pgparam eq 'reference');
      next if ($pgparam eq 'fullauthorname');
      my $pg_command2 = "INSERT INTO cur_$pgparam VALUES ('$joinkey', NULL, CURRENT_TIMESTAMP);";
      print PG "$pg_command2\n"; 
      my $result2 = $conn->exec( $pg_command2 );
} } }

close (PG) or die "Cannot close $outfile : $!";


__END__

