#!/usr/bin/perl

# Find entries that are lacking tags with data.
# The results :
# Paper : "WBPaper00000938"
# Paper : "WBPaper00013006"
# Paper : "WBPaper00013326"
# Paper : "WBPaper00013339"
# Paper : "WBPaper00024181"

use strict;

$/ = "";
my $infile = 'citace20050609Papers.ace';
if ($ARGV[0]) { $infile = $ARGV[0]; }
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $count = 0;
while (my $entry = <IN>) {
#   if ($count > 1000) { last; }
  $count++;
  unless ( ($entry =~ m/CGC_name/) || ($entry =~ m/Medline_name/) || ($entry =~ m/Other_name/) || ($entry =~ m/Old_WBPaper/) || ($entry =~ m/WBG_abstract/) || ($entry =~ m/Meeting_abstract/) || ($entry =~ m/PMID/) || ($entry =~ m/Erratum/) || ($entry =~ m/Refers_to/) || ($entry =~ m/In_book/) || ($entry =~ m/Contained_in/) || ($entry =~ m/Contains/) || ($entry =~ m/Title/) || ($entry =~ m/Journal/) || ($entry =~ m/Page/) || ($entry =~ m/Volume/) || ($entry =~ m/Year/) || ($entry =~ m/Publisher/) || ($entry =~ m/Editor/) || ($entry =~ m/Author/) || ($entry =~ m/Affiliation/) || ($entry =~ m/Person/) || ($entry =~ m/Gene/) || ($entry =~ m/Strain/) || ($entry =~ m/Rearrangement/) || ($entry =~ m/Sequence/) || ($entry =~ m/Interaction/) || ($entry =~ m/Antibody/) || ($entry =~ m/Allele/) || ($entry =~ m/Expr_pattern/) || ($entry =~ m/Expr_profile/) || ($entry =~ m/CDS/) || ($entry =~ m/Cell/) || ($entry =~ m/Cell_group/) || ($entry =~ m/Life_stage/) || ($entry =~ m/RNAi/) || ($entry =~ m/Locus/) || ($entry =~ m/Clone/) || ($entry =~ m/Pseudogene/) || ($entry =~ m/Transgene/) || ($entry =~ m/Microarray_experiment/) || ($entry =~ m/Cluster/) || ($entry =~ m/SAGE_experiment/) || ($entry =~ m/Brief_citation/) || ($entry =~ m/Abstract/) || ($entry =~ m/Type/) || ($entry =~ m/Keyword/) ) { print "$entry\n"; }

#   my @lines = split/\n/, $entry;
#   my ($paper) = $entry =~ m/Paper : \"(.*)\"/;
#   my $new_entry = '';
#   foreach my $line (@lines) {
#     if ($line =~ m/^Paper : /) { next; }
#     elsif ($line =~ m/^CGC_name/) { next; }
#     elsif ($line =~ m/^Medline_name/) { next; }
#     elsif ($line =~ m/^Other_name/) { next; }
#     elsif ($line =~ m/^Old_WBPaper/) { next; }
#     elsif ($line =~ m/^WBG_abstract/) { next; }
#     elsif ($line =~ m/^Meeting_abstract/) { next; }
#     elsif ($line =~ m/^PMID/) { next; }
#     elsif ($line =~ m/^Erratum/) { next; }
#     elsif ($line =~ m/^Refers_to/) { next; }
#     elsif ($line =~ m/^In_book/) { next; }
#     elsif ($line =~ m/^Contained_in/) { next; }
#     elsif ($line =~ m/^Contains/) { next; }
#     elsif ($line =~ m/^Title/) { next; }
#     elsif ($line =~ m/^Journal/) { next; }
#     elsif ($line =~ m/^Page/) { next; }
#     elsif ($line =~ m/^Volume/) { next; }
#     elsif ($line =~ m/^Year/) { next; }
#     elsif ($line =~ m/^Publisher/) { next; }
#     elsif ($line =~ m/^Editor/) { next; }
#     elsif ($line =~ m/^Author/) { next; }
#     elsif ($line =~ m/^Affiliation/) { next; }
#     elsif ($line =~ m/^Person/) { next; }
#     elsif ($line =~ m/^Gene/) { next; }
#     elsif ($line =~ m/^Strain/) { next; }
#     elsif ($line =~ m/^Rearrangement/) { next; }
#     elsif ($line =~ m/^Sequence/) { next; }
#     elsif ($line =~ m/^Interaction/) { next; }
#     elsif ($line =~ m/^Antibody/) { next; }
#     elsif ($line =~ m/^Allele/) { next; }
#     elsif ($line =~ m/^Expr_pattern/) { next; }
#     elsif ($line =~ m/^Expr_profile/) { next; }
#     elsif ($line =~ m/^CDS/) { next; }
#     elsif ($line =~ m/^Cell/) { next; }
#     elsif ($line =~ m/^Cell_group/) { next; }
#     elsif ($line =~ m/^Life_stage/) { next; }
#     elsif ($line =~ m/^RNAi/) { next; }
#     elsif ($line =~ m/^Locus/) { next; }
#     elsif ($line =~ m/^Clone/) { next; }
#     elsif ($line =~ m/^Pseudogene/) { next; }
#     elsif ($line =~ m/^Transgene/) { next; }
#     elsif ($line =~ m/^Microarray_experiment/) { next; }
#     elsif ($line =~ m/^Cluster/) { next; }
#     elsif ($line =~ m/^SAGE_experiment/) { next; }
#     elsif ($line =~ m/^Brief_citation/) { next; }
#     elsif ($line =~ m/^Abstract/) { next; }
#     elsif ($line =~ m/^Type/) { next; }
#     elsif ($line =~ m/^Keyword/) { next; }
#     else { $new_entry .= "$line\n"; }
#   }
#   if ($new_entry) { print "$paper\n$new_entry\n"; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";

#     if ($entry =~ m/^Paper : /) { $entry =~ s/^CGC_name.*?$//g; }
#     if ($entry =~ m/^CGC_name/) { $entry =~ s/^CGC_name.*?$//g; }
#     if ($entry =~ m/^Title/) { $entry =~ s/^Title.*?$//g; }
#     if ($entry =~ m/^Journal/) { $entry =~ s/^Journal.*?$//g; }
#     if ($entry =~ m/^Page/) { $entry =~ s/^Page.*?$//g; }
#     if ($entry =~ m/^Volume/) { $entry =~ s/^Volume.*?$//g; }
#     if ($entry =~ m/^Year/) { $entry =~ s/^Year.*?$//g; }
#     if ($entry =~ m/^Author/) { $entry =~ s/^Author.*?$//g; }
#     if ($entry =~ m/^Brief_citation/) { $entry =~ s/^Brief_citation.*?$//g; }
#     if ($entry =~ m/^Abstract/) { $entry =~ s/^Abstract.*?$//g; }
#     if ($entry =~ m/^Type/) { $entry =~ s/^Type.*?$//g; }
#     if ($entry =~ m/^Keyword/) { $entry =~ s/^Keyword.*?$//g; }
