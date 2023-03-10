#!/usr/bin/perl -w

# fix proteins that got deleted but shouldn't have.  2006 11 30

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $infile = 'proteins.reinsert';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  if ($line =~ m/KEEP/) { 
    if ($line =~ m/KEEP (WBGene\d{8}) (.*?) (\d{4}\-.*?)$/) {
      my $gene = $1; my $prot = $2; my $time = $3;
      my $result = $conn->exec( "SELECT * FROM got_protein WHERE joinkey = '$gene' AND got_timestamp = '$time';" );
      unless ($result->fetchrow) { 
        print "NO MATCH $gene $prot $time\n"; 
        my $command = "INSERT INTO got_protein VALUES ('$gene', '$prot', '$time');";
        print "$command\n";
        my $result2 = $conn->exec( $command ); } }
      else { print "BAD LINE $line\n"; } }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

# Clear Hash, new joinkey WBGene00000000
# KEEP WBGene00000000 CE36419 2004-07-15 14:55:56.280864-07
# DELETE FROM got_protein WHERE joinkey = 'WBGene00000000' AND got_timestamp = '2004-07-15 14:55:56.280864-07';
# KEEP WBGene00000000 CE02903, CE32289 2004-09-09 13:49:09.417278-07

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

