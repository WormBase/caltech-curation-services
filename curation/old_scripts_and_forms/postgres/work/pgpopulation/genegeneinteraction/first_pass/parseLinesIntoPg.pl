#!/usr/bin/perl

# take in 101 random lines from textpresso that have 2 direct genes and an association
# get the genes and associations, filter for repeats, and if there are more than 1 gene
# create pg entry for the (, separated) genes, interaction, location (paper and sentence id), 
# and full text with markup.  2003 11 05

use Pg;
use strict;
use diagnostics;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $infile = 'sample101random';
my $infile = 'all_gene_gene_interactions_new_random';
my $count = 0;				# id for line number
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp ($line);
  my ($location, $id, $text) = $line =~ m/^.*?xml\/(.*?) : <sentence id='(.*?)'>(.*)$/;
  print "LOC $location $id\nTEXT $text\n";
  my (@genes) = $text =~ m/<gene grammar[^>]*?'direct'[^>]*?>(.*?)<\/gene>/g;
  my (@ind_genes) = $text =~ m/<gene grammar[^>]*?'indirect'[^>]*?>(.*?)<\/gene>/g;
  my (@associations) = $text =~ m/<association [^>]*?>(.*?)<\/association>/g;
  my %genes; my %assoc;
  foreach my $gene (@genes) { $gene =~ s/\-$//g; $gene =~ s/^\s+//g; $gene =~ s/\s+$//g; $gene =~ s/\s+/ /g; $genes{$gene}++; }
  foreach my $assoc (@associations) { $assoc =~ s/^\s+//g; $assoc =~ s/\s+$//g; $assoc =~ s/\s+/ /g; $assoc{$assoc}++; }
  my $genes = join(", ", keys(%genes));
  unless ($genes =~ m/, /) { next; }	# skip if only one gene in that line
  $count++; 
  my $joinkey = 'and' . $count;
  my $result = $conn->exec( "INSERT INTO and_genes VALUES ( '$joinkey', '$genes' );" );
  my $associations = join(", ", keys(%assoc));
#   $result = $conn->exec( "INSERT INTO and_interaction VALUES ( '$joinkey', '$associations' );" );
  $location .= " : $id"; 
  $result = $conn->exec( "INSERT INTO and_location VALUES ( '$joinkey', '$location' );" );
  $text =~ s/\'/\\'/g;
  $result = $conn->exec( "INSERT INTO and_text VALUES ( '$joinkey', '$text' );" );
} # while (my $line = <IN>)
print "COUNT $count\n";
close (IN) or die "Cannot close $infile : $!";
