#!/usr/bin/perl -w

# compare pic_source to file from daniela  2011 08 30

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my %source;
my $result = $dbh->prepare( "SELECT * FROM pic_source " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { $source{$row[1]}++; } }

my $infile = 'wormatlas.html';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  if ($source{$line}) { 1 ; } # { print "In Source $line\n"; }
    else { print "NEED $line\n"; }
}
close (IN) or die "Cannot close $infile : $!";

