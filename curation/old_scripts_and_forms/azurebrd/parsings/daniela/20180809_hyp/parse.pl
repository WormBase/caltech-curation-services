#!/usr/bin/perl

# for Daniela to parse some expr patterns against .ace data.  2018 08 09

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my %gin; my %anat;
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $gin{"WBGene$row[0]"} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM obo_name_anatomy" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { $anat{"$row[0]"} = $row[1]; } }


my %data;
my $file = 'source';
$/ = undef;
open (IN, "<$file") or die "Cannot open $file : $!";
my $data = <IN>;
close (IN) or die "Cannot close $file : $!";
my (@expr) = $data =~ m/>(Expr\d+)<\/a>/g;
foreach (@expr) { $data{$_}++; }


$file = 'expr_pattern.ace';
$/ = "";
open (IN, "<$file") or die "Cannot open $file : $!";
while (my $entry = <IN>) {
  next unless ($entry =~ m/Reporter_gene/);
  my ($expr) = $entry =~ m/Expr_pattern : \"(Expr\d+)\"/;
  next unless $expr;
  next unless ($data{$expr});
  my ($gene) = $entry =~ m/Gene\s+\"(WBGene\d+)\"/;
  my $locus = $gin{$gene} || $gene;
  my ($pattern) = $entry =~ m/Pattern\s+\"(.*)\"/;
  my (@anat) = $entry =~ m/Anatomy_term\s+\"(WBbt:\d+)\"/g;
  my @anat_names;
  foreach (@anat) { if ($anat{$_}) { push @anat_names, $anat{$_}; } else { push @anat_names, $_; } }
  my $anat = join", ", @anat_names;
  print qq("$expr","$locus","$pattern","$anat"\n);
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $file : $!";

$/ = "\n";



__END__

Expr_pattern : "Expr1"
Anatomy_term	"WBbt:0005813" Certain
Anatomy_term	"WBbt:0005821" Certain
Clone	"UL#4F5"
Construct	"WBCnstr00010018"
Gene	"WBGene00001386"
Life_stage	"WBls:0000057"
Pattern	"Body wall muscle cells and vulval muscle cells of adult  hermaphrodites. Beta-galactosidase is nuclear localized"
Reference	"WBPaper00001469"
Reflects_endogenous_expression_of	"WBGene00001386"
Reporter_gene
Strain	"UL3"

