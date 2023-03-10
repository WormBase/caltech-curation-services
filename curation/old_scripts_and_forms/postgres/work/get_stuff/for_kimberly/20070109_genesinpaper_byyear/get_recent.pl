#!/usr/bin/perl -w

# I'm not sure the results will be that helpful to you.
# There are 1651 papers published in 2006.
# The results of the query are in
# /home/postgres/work/get_stuff/for_kimberly/20070109_genesinpaper_byyear/out
# 
# There are 4498 lines, sorted by WBGene, and this is more than there 
# are WBGenes because the output of WBGenes shows them as curated, not 
# filtering down and getting a 3-letter name (if exists, I imagine quite
# a few don't).
# e.g. the first two lines :
# WBGene00000018  2
# WBGene00000018(abl-1)   4
# Would mean that that is 6, not 2 and 4, but twice it was curated 
# without a 3-letter name, and 4 times with the three letter name.
# Further down you can see things like :
# WBGene00021983(Y58G8A.4)        1
# 
# out2 has all the genes filtered down to WBGenes only, so there are 
# 3526 WBGenes with paper connections.  I'm not sure how useful that is
# either.
# 
# out3 has the same list sorted by paper count in reverse, so the top 99
# WBGenes have 10 or more paper connections.
#
# out4 has the same list minus abstracts and so forth
#
# for Kimberly  2007 01 09


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %hash;
my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey IN (SELECT joinkey FROM wpa_year WHERE wpa_year = '2006') AND joinkey NOT IN ( SELECT joinkey FROM wpa_type WHERE wpa_type = '7' OR wpa_type = '3' OR wpa_type = '4') ORDER BY wpa_timestamp;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[1] =~ m/(WBGene\d+)/) { $row[1] = $1; }
    if ($row[3] eq 'valid') { $hash{$row[1]}{$row[0]}++; }
      else { delete $hash{$row[1]}{$row[0]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)


my %count;
foreach my $gene (sort keys %hash) {
  my @papers = keys %{ $hash{$gene} };
  my $count = scalar (@papers);
  next unless $count;
  $count{$count}{$gene}++;
#   print "$gene\t$count\n";
} # foreach my $gene (sort keys %hash) 

foreach my $count (sort {$b <=> $a} keys %count) {
  foreach my $gene (sort keys %{ $count{$count} }) {
    print "$gene\t$count\n";
  } # foreach my $gene (sort keys %{ $count{$count} })
} # foreach my $count (sort keys %count)

__END__

