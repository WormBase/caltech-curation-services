#!/usr/bin/perl -w
#
# Pg query to get twos below 120 that have matching last names in papers to fix
# errors from the script overwriting old values.

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %lastnames;
for (my $two = 1; $two < 120; $two++) { 
  my $result = $conn->exec( "SELECT two_lastname FROM two_lastname WHERE joinkey = 'two$two';" );
  my @row = $result->fetchrow;
  if ($row[0]) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $lastnames{$row[0]}++; }
  $result = $conn->exec( "SELECT two_aka_lastname FROM two_aka_lastname WHERE joinkey = 'two$two';" );
  @row = $result->fetchrow;
  if ($row[0]) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $lastnames{$row[0]}++; }
  $result = $conn->exec( "SELECT two_apu_lastname FROM two_apu_lastname WHERE joinkey = 'two$two';" );
  @row = $result->fetchrow;
  if ($row[0]) { $row[0] =~ s/^\s+//g; $row[0] =~ s/\s+$//g; $lastnames{$row[0]}++; }
#   if ($row[0]) { push @lastnames, $row[0]; }
} # for my $two ($two = 0; $two < 1810; $two++) 

foreach my $lastname (sort keys %lastnames) { 
  my $result = $conn->exec( "SELECT joinkey FROM pap_view WHERE pap_author ~ '$lastname' ORDER BY joinkey; ");
  my @row = $result->fetchrow;
  if ($row[0]) { 
    my $joinkey = $row[0];
    my $result2 = $conn->exec( "SELECT pap_author FROM pap_view WHERE joinkey = '$joinkey' AND pap_author !~ '$lastname'; ");
    while (my @row2 = $result2->fetchrow) { 
      if ($row2[0]) { 
        foreach my $last2 (sort keys %lastnames) {
#           if ($row2[0] =~ $last2)
          if ($last2 =~ $row2[0]) { 
	    print OUT "$joinkey\t$lastname\t$row2[0]\n"; 
          } # if ($row2[0] =~ $last2)
        } # foreach my $last2 (sort keys %lastnames)
      }
    }
  }
}

close (OUT) or die "Cannot close $outfile : $!";
