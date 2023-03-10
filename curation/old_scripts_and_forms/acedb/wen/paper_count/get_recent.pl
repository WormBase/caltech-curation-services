#!/usr/bin/perl -w

# get list of papers with expression data, transgene, antibody

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @types = qw( generegulation transgene antibody expression );

foreach my $type (@types) {
  my $outfile = "/home/acedb/wen/paper_count/${type}.out";
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT "$type :\n";
  my $table = 'cur_' . $type;
  my $result = $conn->exec( "SELECT joinkey FROM $table WHERE $table IS NOT NULL ORDER BY joinkey;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      print OUT "$row[0]\n";
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  print OUT "\n\n";
  close (OUT) or die "Cannot close $outfile : $!";
}

__END__

