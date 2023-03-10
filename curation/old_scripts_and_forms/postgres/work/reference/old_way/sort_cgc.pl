#!/usr/bin/perl -w
#
# Take in the input parsed file from /home/wen and sort it numerically, and
# don't output the accession number (since it doesn't go into the database and
# it changes a bit)  This was written to get the first ``current'' file to check
# against for new versions of cgc data.  2002-01-26

my $infile = '/home/wen/CGC2001_12_20.txt';
my $outfile = 'CGC2001_12_20.parsed';

my %hash;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (<IN>) {
  chomp;
  if ($_) { 
    my ($key, $acc, @rest) = split/\t/, $_;
    $_ =~ m/^(.*?\t).*?\t(.*)$/;
    my $new = $1 . $2;   
    $hash{$key} = $new;
#     $hash{$key} = $key . "\t" . join("\t", @rest);
  } # if ($_)
} # while (<IN>)

foreach (sort numerically keys %hash) {
  print OUT $hash{$_} . "\n";
} # foreach (sort numerically keys %hash)

sub numerically { $a <=> $b }                   # sort numerically

