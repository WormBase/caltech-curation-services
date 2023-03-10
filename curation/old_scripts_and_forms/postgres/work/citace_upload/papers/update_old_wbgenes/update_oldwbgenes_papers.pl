#!/usr/bin/perl -w

# Get Dead genes and Merged_into genes from aceserver.  Invalidate and create
# merged entries those that are both Dead and Merged_into in wpa_gene.
# Invalidate those that are only Dead.  for Mary Ann and Andrei  2006 10 04
#
# 0 5 * * wed /home/postgres/work/citace_upload/papers/update_old_wbgenes/update_old_wbgenes.pl
#
# this isn't properly making things invalid, it's doing it for paper-gene instead of paper-gene-evidence.
# also aceserver might not be at cshl anymore.  taking it offline.  2010 04 08


use strict;
use diagnostics;
use Pg;

use Jex;
use Ace;

my $directory = '/home/postgres/work/citace_upload/papers/update_old_wbgenes';
chdir($directory) or die "Cannot go to $directory ($!)";


my $date = &getSimpleSecDate();
my $outfile = '/home/postgres/work/citace_upload/papers/update_old_wbgenes/updatepaperwbgenes.out.' . $date;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

$date = &getSimpleDate();

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2005;
my $db = Ace->connect(-host=>HOST,-port=>PORT) or warn "Connection failure: ",Ace->error;
my $tempname = 'WBPaper00000003';
my $query = "find Gene Dead";
my @genes = $db->fetch(-query=>$query);
my %dead;
foreach my $gene (@genes) {
  $dead{$gene}++;
#   print "aceserver found dead gene $gene\n"; 
} 
$query = "find Gene Merged_into";
@genes = $db->fetch(-query=>$query);
my %merged;
foreach my $gene (@genes) {
  my $merge = $gene->Merged_into;
  $merged{$gene} = $merge;
#   print "aceserver found merged gene $gene $merge\n"; 
} 

foreach my $gene (sort keys %merged) {
  if ($dead{$gene}) {
      delete $dead{$gene};
      &merge($gene, $merged{$gene}); } 
    else { print OUT "Ignore $gene\n"; } }

foreach my $gene (sort keys %dead) { &invalidate($gene) }

close (OUT) or die "Cannot close $outfile : $!";

sub invalidate {
  my $gene = shift;
  my %gene;
  print OUT "Invalidate $gene\n";
  my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE wpa_gene ~ '$gene' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      if ($row[3] eq 'valid') { $gene{$row[0]}{$row[1]}++; }
        else { delete $gene{$row[0]}{$row[1]}; } } }
  foreach my $joinkey (sort keys %gene) {
    foreach my $wpa_gene (sort keys %{ $gene{$joinkey} }) {
      my $pgcommand = "INSERT INTO wpa_gene VALUES ('$joinkey', '$wpa_gene', 'Inferred_automatically \"update_oldwbgenes_papers.pl $date\"', 'invalid', 'two480', CURRENT_TIMESTAMP);";
      print OUT "$pgcommand\n"; 
      my $result2 = $conn->exec( $pgcommand ); } }
} # sub merge

sub merge {
  my ($gene, $new) = @_;
  my %gene;
  print OUT "Move $gene into $merged{$gene}\n";
  my $result = $conn->exec( "SELECT * FROM wpa_gene WHERE wpa_gene ~ '$gene' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      if ($row[3] eq 'valid') { $gene{$row[0]}{$row[1]}++; }
        else { delete $gene{$row[0]}{$row[1]}; } } }
  foreach my $joinkey (sort keys %gene) {
    foreach my $wpa_gene (sort keys %{ $gene{$joinkey} }) {
      my $pgcommand = "INSERT INTO wpa_gene VALUES ('$joinkey', '$wpa_gene', 'Inferred_automatically \"update_oldwbgenes_papers.pl $date\"', 'invalid', 'two480', CURRENT_TIMESTAMP);";
      print OUT "$pgcommand\n"; 
      my $result2 = $conn->exec( $pgcommand );
      $pgcommand = "INSERT INTO wpa_gene VALUES ('$joinkey', '$new', 'Inferred_automatically \"update_oldwbgenes_papers.pl $date\"', 'valid', 'two480', CURRENT_TIMESTAMP);";
      print OUT "$pgcommand\n";
      $result2 = $conn->exec( $pgcommand );
  } }
} # sub merge

# my $tempname = 'WBPaper00000003';
# my $query = "find Paper $tempname";
# my @rnai = $db->fetch(-query=>$query);
# if ($rnai[0]) { print "aceserver found $rnai[0]<BR>\n"; $found++; }
# if ($found) { print "Based on aceserver, finalname should be : $tempname ; RNAi does not query out wbgene.<BR>\n"; }


__END__

#!/usr/bin/perl -w

# take Mary Ann's list and make old genes invalid and assign to new genes.  2006 09 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $infile = 'dead_genes_references.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($old, $new, $paper) = split/\t/, $line;
  $paper =~ s/WBPaper//;
  my $pgcommand = "INSERT INTO wpa_gene VALUES ('$paper', '$old', 'Inferred_automatically \"Mary Ann Tuli dead and merged gene dump 2006 09 29\"', 'invalid', 'two480', CURRENT_TIMESTAMP);";
  print "$pgcommand\n";
  my $result = $conn->exec( $pgcommand );
  $pgcommand = "INSERT INTO wpa_gene VALUES ('$paper', '$new', 'Inferred_automatically \"Mary Ann Tuli dead and merged gene dump 2006 09 29\"', 'valid', 'two480', CURRENT_TIMESTAMP);";
  print "$pgcommand\n";
  $result = $conn->exec( $pgcommand );
} # while (my $line = <IN>)
close (IN) or die "Cannot open $infile : $!";


my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

