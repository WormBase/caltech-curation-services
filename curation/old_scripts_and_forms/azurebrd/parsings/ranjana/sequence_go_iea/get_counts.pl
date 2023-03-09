#!/usr/bin/perl

# take a dump of Sequence where GO_term exists.  Find out how many have IEA's
# under GO_term only.  How many have non-IEA under GO_term only.  Find out how
# many have both.  If there's a Locus_genomic_sequence, do the same for those
# Loci.  Find out how many Paper_evidence entries there are, and how many of
# those are unique.  2003 03 07

use strict;
use diagnostics;

# my $file = 'sequence_with_GO_terms.ace';
my $file = 'WS97Seq_with_GOterms.ace';
my $outfile = 'counts.outfile';

my %seq; 	# hash of sequence data
my %locus; 	# hash of locus data
my %paper; 	# hash of paper data

my $paper; 	# total count of papers

$/ = "";

open (IN, "<$file") or die "Cannot open $file : $!";
while (my $sequence_entry = <IN>) { 
  my @lines = split/\n/, $sequence_entry;
  my ($sequence) = $sequence_entry =~ m/^Sequence : "(.*?)"/;
  foreach my $line (@lines) {
    my $locus = '';
    if ($line =~ m/Locus_genomic_seq\s+\"(.*?)\"/) { $locus = $1; $seq{$sequence}{locus} = $locus; }
    if ($line =~ m/^GO_term/) { $seq{$sequence}{go_term}++; }
    if ($line =~ m/^GO_term\s+\"[^"]*?\" IEA/) { $seq{$sequence}{iea}++; }
    if ($line =~ m/^GO_term\s+\"[^"]*?\" Paper_evidence \"\[(.*?)\]\"/) { $seq{$sequence}{paper}{$1}++; $paper{$1}++; $paper++; }

  } # foreach my $line (@lines)
}
close (IN) or die "Cannot close $file : $!";

foreach my $seq (sort keys %seq) {
  if ($seq{$seq}{go_term}) { 			# if data
    if ($seq{$seq}{go_term} == $seq{$seq}{iea}) {	# same number of goterms and ieas
							# there are no non-iea
      $seq{iea}++;
      if ($seq{$seq}{locus}) {			# if there's a locus
        $locus{iea}++;
      }
    } elsif ($seq{$seq}{iea} == 0) {		# if no ieas
      $seq{nononly}++;
      if ($locus{$seq}{locus}) {		# if there's a locus
        $locus{nononly}++;
      }
    } else {					# sequence with iea and non iea
      $seq{ieaandnon}++;
      if ($seq{$seq}{locus}) {			# if there's a locus
        $locus{ieaandnon}++;
      }
    }
  }
} # foreach my $seq (sort keys %seq)

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

print OUT "sequences with IEA ONLY : $seq{iea}\n";
print OUT "sequences with NON-IEA ONLY : $seq{nononly}\n";
print OUT "sequences with BOTH IEA AND NON-IEA ONLY : $seq{ieaandnon}\n\n";

print OUT "locus with IEA ONLY : $locus{iea}\n";
print OUT "locus with NON-IEA ONLY : $locus{nononly}\n";
print OUT "locus with BOTH IEA AND NON-IEA ONLY : $locus{ieaandnon}\n\n";

print OUT "TOTAL Papers in all sequences : $paper\n";
print OUT "UNIQUE Papers in all sequences : " . scalar(keys %paper) . "\n";


close (OUT) or die "Cannot close $outfile : $!";
