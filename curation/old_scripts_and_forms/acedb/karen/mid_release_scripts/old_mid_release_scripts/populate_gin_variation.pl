#!/usr/bin/perl -w

# populate gin_variation for phenote text only queries based on variation name.
# Uses tab delimited file called  variation_tab_wbgene  2008 02 01

use strict;
use diagnostics;
use Pg;
use Jex;

my $time = &getSimpleSecDate;

my $outfile = 'pgcommands.' . $time;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $infile = 'variation_tab_wbgene';
open (IN, "<$infile") or die "Cannot open $infile : $!"; 
my $result = $conn->exec( "DELETE FROM gin_variation;" );
while (my $line = <IN>) { 
  chomp $line;
  my ($variation, $wbgene) = split/\t/, $line;
  $wbgene =~ s/WBGene//g;
  my $command = "INSERT INTO gin_variation VALUES ('$wbgene', '$variation');";
  print OUT "$command\n";
  $result = $conn->exec( $command );
} # while (my $line = <IN>) 
close (IN) or die "Cannot close $infile : $!"; 
close (OUT) or die "Cannot close $outfile : $!"; 

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

