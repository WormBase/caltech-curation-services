#!/usr/bin/perl -w

# get CEs from WBGene from got_protein, get CEs to Uniprot from
# ftp://ftp.sanger.ac.uk/pub/databases/wormpep/wormpep.table
# and take input gene_association.wb and get each second column
# and map them to UniProt (filtering stuff out).  
# Output to uniprot.out and uniprot.err  2007 07 19
#
# Was using wrong got_protein instead of gin_protein table.
# Want UniProts mapped to themselves.  2007 07 20
#
# Oops, was mapping to CEs not Uniprots.  2007 07 26

use strict;
use diagnostics;
use Pg;

use LWP::Simple;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %wbg_ce;
my $result = $conn->exec( "SELECT * FROM gin_protein ORDER BY gin_timestamp;" );
while (my @row = $result->fetchrow) { if ($row[0]) { 
  if ($row[1]) { if ($row[1] =~ m/WP:/) { $row[1] =~ s/WP://g; }
  if ($row[1] =~ m/CE/) { $wbg_ce{$row[0]}{$row[1]}++; } } } }

my %good; my %uniprot;
my $geneassoc_file = 'gene_association.wb';
open (IN, "<$geneassoc_file") or die "Cannot open $geneassoc_file : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^\!/);
  my ($stuff, $good, $morestuff) = split/\t/, $line;
  unless ($good) { print "$line has no 2nd column\n"; }
  if ($good =~ m/WBGene/) { $good{$good}++; }
    elsif ($good =~ m/(CE\d+)/) { $good{$1}++; }
  if ($stuff eq 'UniProt') { $uniprot{$good}++; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $geneassoc_file : $!";

my $outfile = 'uniprot.out';
my $errfile = 'uniprot.err';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!";

my %ce_uniprot;
my $wormpep = get "ftp://ftp.sanger.ac.uk/pub/databases/wormpep/wormpep.table";
my @lines = split/\n/, $wormpep;
foreach my $line (@lines) {
  my ($junk, $ce, $three, $four, $five, $uniprot, $morejunk) = split/\t/, $line;
  if ($ce =~ m/CE\d+/) {
    if ($uniprot =~ m/TR:(\w+)/) { $ce_uniprot{$ce} = $1; }
    elsif ($uniprot =~ m/SW:(\w+)/) { $ce_uniprot{$ce} = $1; }
#     else { print "ERR $line has no uniprot\n"; } 
  }
  else { print "ERR $line has no CE\n"; }
} # foreach my $line (@lines)

foreach my $good (sort keys %good) {
  if ($good =~ m/CE/) { 
      if ($ce_uniprot{$good}) { print OUT "WB:$good\tUniProtKB:$ce_uniprot{$good}\n"; }
        else { print ERR "WB:$good\n"; } 
    }
    elsif ($good =~ m/WBGene\d+/) {
#       my @ces = split/, /, $wbg_ce{$good};
#       my %temp_uni;
#       foreach my $ce (@ces) { $temp_uni{$ce_uniprot{$ce}}++; }
#       my @temp_uni = sort keys %temp_uni;
#       foreach (@temp_uni) { $_ = 'UniProtKB:' . $_; }
      my @temp_uni;
      $good =~ s/WBGene//g;
      foreach my $ce (sort keys %{ $wbg_ce{$good} }) { 
        my $uni = $ce_uniprot{$ce};
        $uni = 'UniProtKB:' . $uni; push @temp_uni, $uni; }
      my $uniprots = join";", @temp_uni;
      if ($uniprots =~ m/UniProtKB:./) { print OUT "WB:WBGene$good\t$uniprots\n"; } 
        else { print ERR "WB:WBGene$good\n"; } }
} # foreach my $good (sort keys %good)

foreach my $uni (sort keys %uniprot) {
  print OUT "UniProtKB:$uni\tUniProtKB:$uni\n";
} # foreach my $uni (sort keys %uniprot)

close (ERR) or die "Cannot close $errfile : $!";
close (OUT) or die "Cannot close $outfile : $!";
