#!/usr/bin/perl -w

# Get allele-phenotype count-style data for Carol for the ABM2007
# 2006 12 21

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %theHash;
my $result = $conn->exec( "SELECT * FROM alp_term ORDER BY joinkey, alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $key = "$row[1] $row[2]";
    $theHash{$row[0]}{$key} = $row[3];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %count;
foreach my $joinkey (sort keys %theHash) {
  my $term_count = 0;
  foreach my $term (sort keys %{ $theHash{$joinkey} }) { $term_count++; }
  push @{ $count{$term_count} }, $joinkey;
} # foreach my $joinkey (sort keys %theHash)

print "First, Paul wanted to see a sort of histogram of what the data looks like.  For this, it would be useful to know how many alleles have one phenotype connection, two phenotype connections, three phenotype connections, etc. up to the maximum number of phenotype connections for one allele.\n";

foreach my $count (sort {$a<=>$b} keys %count) {
  my $terms = scalar( @{ $count{$count} });
  print "Amount of Terms : $count\tAmount of Alleles with $count Terms : $terms\n";
} # foreach my $count (sort keys %count)

print "\n\n";
print "Third, how many alleles have more than one paper connection?\n";

my %filter; %theHash = (); %count = (); my %more_than_one_paper;
$result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $paper = '';
    unless ($row[2]) { $filter{$row[0]}{$row[1]} = ''; next; }
    if ($row[2] =~ m/WBPaper(\d+)/) { $paper = $1; }
    $filter{$row[0]}{$row[1]} = $paper; } }
foreach my $allele (sort keys %filter) {
  my %papers; my $count;
  foreach my $box (sort keys %{ $filter{$allele} }) {
    my $paper = $filter{$allele}{$box};
    $papers{$paper}++; }
  foreach my $paper (sort keys %papers) { $count++; }
#   if ($count > 0) { push @{ $more_than_one_paper{$count} }, $allele; }
  push @{ $more_than_one_paper{$count} }, $allele;
} # foreach my $allele (sort keys %filter)
foreach my $count (sort {$a<=>$b} keys %more_than_one_paper) {
  my $alleles = scalar( @{ $more_than_one_paper{$count} });
  print "Amount of Paper connections : $count\tAmount of Alleles with $count Paper connections : $alleles\n";
} # foreach my $count (sort keys %count)




print "\n\n";
print "Second, I would like to know which papers were curated on which day (some papers will have been curated over more than one day), along with the number of associated alleles for that paper, and the number of associated phenotype connections.\n";

%filter = ();
$result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
# $result = $conn->exec( "SELECT * FROM alp_paper WHERE alp_paper ~ 'WBPaper00001404' ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $paper = '';
    unless ($row[2]) { delete $filter{$row[0]}{$row[1]}; next; }
    if ($row[2] =~ m/WBPaper(\d+)/) { $paper = $1; }
    $filter{$row[0]}{$row[1]}{$paper} = $row[3]; } }
my %papers;
foreach my $allele (sort keys %filter) {
  foreach my $box (sort keys %{ $filter{$allele} }) {
    foreach my $paper (sort keys %{ $filter{$allele}{$box} }) {
      push @{ $papers{$paper}{join_box}}, "$allele\t$box";
      $papers{$paper}{allele}{$allele}++;
      my $timestamp = $filter{$allele}{$box}{$paper};
      ($timestamp) = $timestamp =~ m/^(\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2})/;
      push @{ $papers{$paper}{paper}}, $timestamp; } } }
foreach my $paper (sort keys %papers) {
  my $allele_count = 0;
  my $times = join", ", @{ $papers{$paper}{paper} };
  print "Paper $paper, Timestamps : $times\n"; 
  foreach my $allele (sort keys %{ $papers{$paper}{allele} }) { $allele_count++; }
  print "Paper $paper, Allele Count : $allele_count\n"; 
  my $term_count = 0;
  foreach my $joinbox (@{ $papers{$paper}{join_box} }) {
    my ($joinkey, $box) = split/\t/, $joinbox;
    my %filter2;
    $result = $conn->exec( "SELECT * FROM alp_term WHERE joinkey = '$joinkey' AND alp_box = '$box' ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) { 
      my $key = "$row[1]" . '_' . $row[2];
      $filter2{$row[0]}{$key} = $row[3]; }
    foreach my $joinkey (sort keys %filter2) {
      foreach my $box (sort keys %{ $filter2{$joinkey} }) { $term_count++; } }
  }
  print "Paper $paper, Term Count : $term_count\n"; 
}
 


__END__

