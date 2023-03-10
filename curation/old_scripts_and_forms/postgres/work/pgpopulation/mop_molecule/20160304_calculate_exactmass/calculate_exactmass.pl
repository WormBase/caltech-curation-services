#!/usr/bin/perl -w

# calculate exactmass based on molformula  2016 03 04

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use URI::Escape;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %flatMap;
my $flatfile = 'molformula_to_exactmass.txt';
open (IN, "<$flatfile") or die "Cannot open $flatfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($molf, $mass) = split/\t/, $line;
  $flatMap{$molf} = $mass;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $flatfile : $!";

my %mop;
$result = $dbh->prepare( "SELECT * FROM mop_molformula" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $mop{molfToId}{$row[1]} = $row[0];
    $mop{idToMolf}{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)
$result = $dbh->prepare( "SELECT * FROM mop_exactmass" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $mop{massToId}{$row[1]} = $row[0];
    $mop{idToMass}{$row[0]} = $row[1];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

open (OUT, ">>$flatfile") or die "Cannot open $flatfile : $!";
my $count = 0;
foreach my $molf (sort keys %{ $mop{molfToId} }) {
  my $origMolf = $molf;
  my $mass = 'cannot process';
  if ($flatMap{$molf}) {
      $mass = $flatMap{$molf}; }
    else {
      if ($molf =~ m/\)n/) { $molf =~ s/\)n//g; $molf =~ s/\(//g; }
      if ($molf =~ m/\./) {  $molf =~ s/\.//g;                    }
      my $urlEncoded = uri_escape($molf);
      my $url = 'http://www.lfd.uci.edu/~gohlke/molmass/?q=' . $urlEncoded;
      print qq(URL $url\n);
      my $page = get $url;
      if ($page =~ m|<strong>Monoisotopic mass</strong>: ([\d\.]+)</p>|) { $mass = $1; }
      print OUT qq($origMolf\t$mass\n);
#     $count++; last if ($count > 5);
      sleep(1);					# wait a bit for politeness
  }
  my $pgmass = '';
  my $pgid   = $mop{molfToId}{$origMolf};
  if ($mop{idToMass}{$pgid}) { $pgmass = $mop{idToMass}{$pgid}; }
  print qq($pgid\t$molf\t$mass\t$pgmass\n);
} # foreach my $molf (sort keys %{ $mop{molfToId} })
close (OUT) or die "Cannot close $flatfile : $!";

__END__
