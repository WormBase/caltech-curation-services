#!/usr/bin/perl -w

# map picture name to expr to expr gene.  for Daniela and Wen.  2014 07 31

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %exprToGene;
my $result = $dbh->prepare( "SELECT exp_name.exp_name, exp_gene.exp_gene FROM exp_name, exp_gene WHERE exp_name.joinkey = exp_gene.joinkey" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $exprToGene{$row[0]} = $row[1]; }
} # while (@row = $result->fetchrow)

my %nameToExpr;
$/ = "";
my $picfile = 'pictures.ace';
open (IN, "<$picfile") or die "Cannot open $picfile : $!";
while (my $entry = <IN>) {
  my ($name) = $entry =~ m/Name\s+"(.*)\.jpg"/;
  my ($expr) = $entry =~ m/Expr_pattern\s+"(.*)"/;
  if ($name && $expr) {
    $nameToExpr{$name} = $expr; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $picfile : $!";

$/ = "\n";
my $outfile = 'Onset_for_wormbase.txt.edited';
my $infile = 'Onset_for_wormbase.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
while (my $line = <IN>) {
  chomp $line;
  my (@cols) = split/\t/, $line;
  my $expr = ''; my $gene = '';
  if ($nameToExpr{$cols[0]}) { $expr = $nameToExpr{$cols[0]}; }
  if ($exprToGene{$expr}) { $gene = $exprToGene{$expr}; $gene =~ s/"//g; }
  push @cols, $expr; 
  push @cols, $gene; 
  my $outline = join"\t", @cols;
  print OUT "$outline\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";


__END__

-rw-r--r-- 1 acedb acedb 8141189 Jul 31 10:03 Onset_for_wormbase.txt
-rw-r--r-- 1 acedb acedb 8443104 Jul 31 09:53 pictures.ace
