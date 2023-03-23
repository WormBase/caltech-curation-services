#!/usr/bin/perl -w

# map paper identifiers to wbpapers.  for Daniela.  2013 01 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
my $result = $dbh->prepare( "SELECT * FROM pap_identifier" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{$row[1]} = "WBPaper$row[0]"; } }

my $infile = 'cgc_negative.txt';
my $outfile = 'wbpaper_negative.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
while (my $line = <IN>) {
  my $map = '';
  my (@stuff) = split/\t/, $line;
  my $name = $stuff[0]; $name =~ s/\s+//g;
  if ($hash{$name}) { $map = $hash{$name}; }
  print OUT "$map\t$line";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";


__END__

