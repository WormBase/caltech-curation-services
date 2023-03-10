#!/usr/bin/perl -w

# Add genes to postgres from a list by Igor.  2007 02 06

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$/ = '';
my $infile = 'gene_connection_for_postgres_02_05_07.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  if ($para =~ m/Paper : \"WBPaper(\d+)\"/) { 
    my $joinkey = $1;
    my (@genes) = $para =~ m/\"(WBGene\d+)\"/g;
    foreach my $gene (@genes) {
#       print "$joinkey $gene\n";
      my $command = "INSERT INTO wpa_gene VALUES ('$joinkey', '$gene', 'Curator_confirmed \"WBPerson22\"', 'valid', 'two22', CURRENT_TIMESTAMP)";
      my $result = $conn->exec( $command );
      print "$command\n";
    } # foreach my $gene (@genes)
  }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

__END__

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

