#!/usr/bin/perl -w

# get stuff for Andrei all ggi data, if two entries for same paper_sentence,
# consider the interaction one over the no-interaction one (error).  only care
# if no-interaction, possible_genetic, or treat the rest as interaction.  get
# two files, one with all sentence words (minus just numbers) and one further
# without the genes.  2008 05 06

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %hash;
my %data;

my $result = $conn->exec( "SELECT * FROM ggi_gene_gene_interaction ;" );
while (my @row = $result->fetchrow) {
  my $key = $row[1];
  my $intxn = $row[4];
  if ($hash{$key}) { if ($hash{$key} eq 'No_interaction') { $hash{$key} = $intxn; } }
    else { $hash{$key} = $intxn; } }

my $infile = '/home/postgres/work/pgpopulation/andrei_genegeneinteraction/20080310-newtextpresso/ggi_lines';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($a, $key, $genes, $sentence) = split/\t/, $line;
  $sentence =~ s/<[^>]+>//g;
  my @stuff = split/\s+/, $sentence; my @blah;
  foreach (@stuff) { if ($_ =~ m/\D/) { push @blah, $_; } }
  $sentence = join" ", @blah;
  $data{sent}{$key} = $sentence;
  $data{genes}{$key} = $genes;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

my $outfile = 'with_genes';
open (ONE, ">$outfile") or die "Cannot create $outfile : $!";
my $outfile2 = 'without_genes';
open (TWO, ">$outfile2") or die "Cannot create $outfile2 : $!";
foreach my $key (sort keys %hash) {
  my $intxn = $hash{$key};
  if ($intxn eq 'No_interaction') { 1; }
  elsif ($intxn eq 'Possible_genetic') { $intxn = 'Possible'; }
  else { $intxn = 'Interaction'; }
  my $sentence = $data{sent}{$key};

  my @words = split/\s+/, $sentence;
  my $words1 = join"\t", @words;

  my @genes = split/; /, $data{genes}{$key};
  foreach my $gene (@genes) { $sentence =~ s/$gene//; }
  @words = split/\s+/, $sentence;
  my $words2 = join"\t", @words;

  $key =~ s/ : /\t/;
  print ONE "$key\t$intxn\t$words1\n";
  print TWO "$key\t$intxn\t$words2\n";
  
} # foreach my $key (sort keys %hash)
close (ONE) or die "Cannot close $outfile : $!";
close (TWO) or die "Cannot close $outfile2 : $!";

__END__

