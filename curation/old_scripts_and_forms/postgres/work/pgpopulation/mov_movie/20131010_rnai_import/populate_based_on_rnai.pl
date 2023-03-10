#!/usr/bin/perl -w

# populate mov_ data based on rna_ data.  for Daniela.  2013 10 10
#
# live run on tazendra.  2013 10 14

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;
my @pgcommands;

my %rnais;
my $infile = 'RNAiList.txt';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
my (@rnais) = $allfile =~ m/(WBRNAi\d+)/g;
foreach (@rnais) { $rnais{$_}++; }
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my %rnaiToPaper; my %rnaiToMovie;
my $rnais = join"','", sort keys %rnais;
$result = $dbh->prepare( "SELECT rna_name.rna_name, rna_paper.rna_paper, rna_movie.rna_movie FROM rna_paper, rna_name, rna_movie WHERE rna_name.joinkey = rna_movie.joinkey AND rna_name.joinkey = rna_paper.joinkey AND rna_name.joinkey IN (SELECT joinkey FROM rna_name WHERE rna_name IN ('$rnais'));" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $rnaiToMovie{$row[0]} = $row[2];
  $rnaiToPaper{$row[0]} = $row[1]; }

my ($mov_pgid) = &getHighestPgid('mov');

foreach my $rnai (sort keys %rnaiToPaper) {
  my $movies = $rnaiToMovie{$rnai};
  my (@movies) = split/\|/, $movies;
  foreach my $movie (@movies) {
    $mov_pgid++;
    my $movId = &pad10Zeros($mov_pgid);
    my $mov_name = 'WBMovie' . $movId;
    my $mov_curator = 'WBPerson12028';
    my $mov_rnai = $rnai;
    my $mov_paper = $rnaiToPaper{$rnai};
    $movie =~ s/^\s+//; $movie =~ s/\s+$//;
    my $removeString = 'http://www.rnai.org/movies/';
    $movie =~ s/$removeString//;
    my $mov_dbinfo = 'RNAi id ' . $movie;
    &addToPg($mov_pgid, 'mov_name', $mov_name);
    &addToPg($mov_pgid, 'mov_curator', $mov_curator);
    &addToPg($mov_pgid, 'mov_rnai', $mov_rnai);
    &addToPg($mov_pgid, 'mov_paper', $mov_paper);
    &addToPg($mov_pgid, 'mov_dbinfo', $mov_dbinfo);
  }
}

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)





sub getHighestPgid {
  my ($type) = @_;
  my $highest = 0;
  my @tables = qw( name curator );
  foreach my $table (@tables) {
    my $pgtable = $type . '_' . $table;
    my $result = $dbh->prepare( "SELECT joinkey FROM $pgtable ORDER BY joinkey::INTEGER DESC" ); $result->execute();
    my @row = $result->fetchrow(); if ($row[0] > $highest) { $highest = $row[0]; }
  } # foreach my $table (@tables)
  return $highest;
} # sub getHighestPgid

sub pad10Zeros {                # take a number and pad to 10 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '000000000' . $number; }
  elsif ($number < 100) { $number = '00000000' . $number; }
  elsif ($number < 1000) { $number = '0000000' . $number; }
  elsif ($number < 10000) { $number = '000000' . $number; }
  elsif ($number < 100000) { $number = '00000' . $number; }
  elsif ($number < 1000000) { $number = '0000' . $number; }
  elsif ($number < 10000000) { $number = '000' . $number; }
  elsif ($number < 100000000) { $number = '00' . $number; }
  elsif ($number < 1000000000) { $number = '0' . $number; }
  return $number;
} # sub pad10Zeros

sub addToPg {
  my ($pgid, $table, $value) = @_;
  if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  push @pgcommands, "INSERT INTO $table VALUES ('$pgid', E'$value');";
  push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$pgid', E'$value');";
} # sub addToPg


__END__
SELECT rna_name.rna_name, rna_movie.rna_movie FROM rna_name, rna_movie WHERE rna_name.joinkey = rna_movie AND rna_name.joinkey IN (SELECT joinkey FROM rna_name WHERE rna_name IN ('$rnais'));

  my ($newPgid, $curator_two) = @_; my $curator = $curator_two; $curator =~ s/two/WBPerson/;
  my ($returnValue) = &insertToPostgresTableAndHistory('mov_curator', $newPgid, $curator);
  if ($returnValue eq 'OK') {
    my $movId = &pad10Zeros($newPgid);
    ($returnValue)  = &insertToPostgresTableAndHistory('mov_name', $newPgid, "WBMovie$movId"); }
  if ($returnValue eq 'OK') { $returnValue = $newPgid; }
  return $returnValue; }

$result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

