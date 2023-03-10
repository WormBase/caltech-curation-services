#!/usr/bin/perl -w

# compare Karen's .txt file with postgres data in trp_publicname to see what's missing.  2013 02 27

use strict; #to limit the variables used in a script to things that have been defined
use diagnostics; #makes error messages more understandable
use DBI;  #this module says to connect to a database
use Encode qw( from_to is_utf8 ); #this module allows character conversion, needed to convert non-utf8 recognizable things into a utf8 recognizable character

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; #connects to the postgres database called testdb and if cannot connect it will die if want to connect from a different machine, need to add tazendra's  IP and my IP to some postgresql config file

my %file;	# names in file
my $infile = 'transgene_report_latest.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";#opens a file for reading, pay attention to the direction of <
while (my $line = <IN>) {
  chomp $line;
  if ($line =~ m/Transgene\s+:\s+(.*?)$/) { $file{$1}++; } }
close (IN) or die "Cannot close $infile : $!";

my %pg;	# names in postgres
my $result = $dbh->prepare( "SELECT trp_publicname.trp_publicname FROM trp_publicname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $pg{$row[0]}++; }

foreach my $name (sort keys %file) { unless ($pg{$name}) { print "$name in file, not postgres\n"; } }


