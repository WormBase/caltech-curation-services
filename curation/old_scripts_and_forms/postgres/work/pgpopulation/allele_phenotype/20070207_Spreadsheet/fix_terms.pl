#!/usr/bin/perl -w

# fix bad entries that went in with terms instead of WBPhenotype##### (term)
# 2007 02 16

use strict;
use diagnostics;
use Pg;


my %phenotypeTerms;

&readCvs();



my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM alp_term WHERE alp_term !~ 'WBPh';" );
while (my @row = $result->fetchrow) {
  if ($phenotypeTerms{term}{$row[3]}) { 
      my $command = "UPDATE alp_term SET alp_term = '$phenotypeTerms{term}{$row[3]} ($row[3])' WHERE alp_term = '$row[3]';";
      print "$command\n";
      my $result2 = $conn->exec( $command );
      print "$row[3] IS $phenotypeTerms{term}{$row[3]}\n"; }
    else {
      print "NO MATCH $row[3] END\n"; }
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
} # while (@row = $result->fetchrow)

sub readCvs {
  my $directory = '/home/postgres/work/pgpopulation/allele_phenotype/20070207_Spreadsheet/temp';
  chdir($directory) or die "Cannot go to $directory ($!)";
  `cvs -d /var/lib/cvsroot checkout PhenOnt`;
  my $file = $directory . '/PhenOnt/PhenOnt.obo';
  $/ = "";
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $para = <IN>) {
    if ($para =~ m/id: WBPhenotype(\d+).*?\bname: (\w+)/s) {
      my $term = $2; my $number = 'WBPhenotype' . $1;
      $phenotypeTerms{term}{$term} = $number;
      $phenotypeTerms{number}{$number} = $term; } }
  $phenotypeTerms{term}{protein_localization_abnormal} = 'WBPhenotype0000436';
  close (IN) or die "Cannot close $file : $!";
  $directory .= '/PhenOnt';
#   `rm -rf $directory`;
#   foreach my $term (sort keys %{ $phenotypeTerms{term} }) { print "T $term N
#   $phenotypeTerms{term}{$term} E<BR>\n"; }
} # sub readCvs

