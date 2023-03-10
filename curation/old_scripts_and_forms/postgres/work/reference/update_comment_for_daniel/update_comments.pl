#!/usr/bin/perl -w
#

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @nums;
my $infile = "comment_file.txt";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $num = <IN>) {
  chomp $num;
  my $result = $conn->exec( "SELECT ref_comment FROM ref_comment WHERE joinkey = 'cgc$num';" );
  my $comment = '';
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $comment = $row[0];
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  $comment .= 'Own Book';

  $result = $conn->exec( "UPDATE ref_comment SET ref_comment = '$comment' WHERE joinkey = 'cgc$num';" );
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";

