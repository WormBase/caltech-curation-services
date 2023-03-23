#!/usr/bin/perl

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %jpgtogene;
my $infile = 'jpgtogene';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my $jpg; my $gene;
  if ($line =~ m/\S(.*?\.jpg)/) { $jpg = $1; }
  if ($line =~ m/(WBGene\d+)/) { $gene = $1; }
  $jpgtogene{$jpg} = $gene;
#   print "$jpg\t$gene\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my %validexpr;
$infile = 'WBPaper00031006.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  my $expr; 
  if ($line =~ m/(Expr\d+)/) { $validexpr{$1}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my %genetoexpr;
$/ = "";
$infile = '31006ExprGene.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $notbrokenfile = <IN>;
my @paras = split/\n\n/, $notbrokenfile;
while (my $para = shift @paras) {
  my $expr; my $gene;
  if ($para =~ m/(Expr\d+)/) { $expr = $1; }
  if ($para =~ m/(WBGene\d+)/) { $gene = $1; }
  next unless $expr;
  unless ($expr) { print "ERR no expr in $para\n"; }
  unless ($gene) { print "ERR no gene in $para\n"; }
#   print "31006\t$expr\t$gene\n";
  if ($validexpr{$expr}) { 
#     print "VALID $gene\t$expr\n";
    $genetoexpr{$gene}{$expr}++; }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $jpg (sort keys %jpgtogene) {
  my $gene = $jpgtogene{$jpg};
  if ($genetoexpr{$gene}) { 
      my $exprs = join",", sort keys %{ $genetoexpr{$gene} }; 
      print "$jpg\t$gene\t$exprs\n"; }
    else { print "$gene has no expr mapping\n"; }
} # foreach my $jpg (sort keys %jpgtogene)

# my %seqn;
# my $result = $dbh->prepare( "SELECT * FROM gin_seqname" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { $seqn{$row[1]} = "WBGene$row[0]"; } }
# 
# my $infile = 'Wormatlas_list.txt';
# open (IN, "<$infile") or die "Cannot open $infile : $!";
# while (my $line = <IN>) {
#   chomp $line;
#   my $pic = $line;
#   my ($seqname) = $line =~ m/^([^_]*?)_/;
#   if ($seqn{$seqname}) { print "$pic\t$seqname\t$seqn{$seqname}\n"; }
#     else { print "ERR no match for $seqname : $pic\n"; }
# } # while (my $line = <IN>)
# close (IN) or die "Cannot close $infile : $!";

__END__

atlas_parse.pl*
LargeScaleWormAtlas.ace
WBPaper00031006.ace

