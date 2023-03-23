#!/usr/bin/perl -w

# group data by authors + date, get expr + pgids.  for Daniela.  2014 08 06

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %exprToPgid;
my $result = $dbh->prepare( "SELECT * FROM exp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $exprToPgid{$row[1]}{$row[0]}++; } }

my %hash;
$/ = "";
my $infile = 'ExprNoRef.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
   my (@authors) = $entry =~ m/Author\s+"(.*?)"/g; 
   my ($date) = $entry =~ m/Date\s+(.*?)\n/;
   unless ($date) { $date = 'no_date'; }
   my ($expr) = $entry =~ m/Expr_pattern : "(.*?)"/;
   next unless ($expr);
   unshift @authors, $date;
   my $key = join"\t", @authors;
   $hash{$key}{$expr}++;
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $key (sort keys %hash) {
  my %pgids;
  foreach my $expr (sort keys %{ $hash{$key} }) {
    if ($exprToPgid{$expr}) {
      foreach my $pgid (sort keys %{ $exprToPgid{$expr} }) { $pgids{$pgid}++; } }
  } # foreach my $expr (sort keys %{ $hash{$key} })
  my $exprs = join", ", sort keys %{ $hash{$key} };
  my $pgids = join",", sort keys %pgids;
  print "$key\n$exprs\n$pgids\n\n";
} # foreach my $key (sort keys %hash)

__END__

Expr_pattern : "Expr2"
Gene	 "WBGene00001863"
Reflects_endogenous_expression_of	 "WBGene00001863"
Life_stage	 "WBls:0000024"
Life_stage	 "WBls:0000027"
Life_stage	 "WBls:0000035"
Life_stage	 "WBls:0000038"
Life_stage	 "WBls:0000041"
Anatomy_term	 "WBbt:0005813" Certain
In_situ	 "Fluorescein labelled riboprobe made by in vitro transcription from T7 promoter using PCR product as template.  Primers for PCR-- 5711 F15G9S4 sense strand primer with SP6 promoter (in brackets)     [GAT TTA GGT GAC ACT ATA G] GGC TGA CAA TAC ACT TAT CG 7034 F15G9T4 antisense primer with T7 promoter (in brackets)     [TAA TAC GAC TCA CTA TAG] AAT CAC AAG AGT GCC GTC AG"
Pattern	 "Post-embryonic expression.  punctate signal body muscle"
Remark	 "Refer to Birchall,Fishpool &  Albertson (1995)"
Remark	 "life_stage summary : postembryonic"
Author	 "Albertson DG"
Author	 "Fishpool RM"
Date	 1995-05
Strain	 "N2"
Curated_by	 "HX"

