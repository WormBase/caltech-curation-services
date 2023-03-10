#!/usr/bin/perl -w

# Try to get what I think Theresa wants.  Not sure it's right.  2007 02 14

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM wpa WHERE joinkey > '00028824'; " );
while (my @row = $result->fetchrow) {
  next if ($row[3] ne 'valid');
  my $joinkey = $row[0];
  print "WBPaper\t$joinkey<BR>\n";
  my $result2 = $conn->exec( "SELECT * FROM wpa_journal WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC; " );
  my @row2 = $result2->fetchrow();
  print "Journal\t$row2[1]<BR>\n";
  $result2 = $conn->exec( "SELECT * FROM wpa_pages WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC; " );
  @row2 = $result2->fetchrow();
  $row2[1] =~ s/\/\// through /g;
  print "Page\t$row2[1]<BR>\n";
  $result2 = $conn->exec( "SELECT * FROM wpa_electronic_path_type WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC; " );
  @row2 = $result2->fetchrow();
  my ($link) = $row2[1] =~ m/\/(\d+[\w\.]+pdf)$/;
  $link = 'http://tazendra.caltech.edu/~acedb/daniel/' . $link;
  print "Link\t<A HREF=\"$link\">$link</A><BR>\n";
  my %authors = ();
  $result2 = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp ; " );
  while (my @row2 = $result2->fetchrow) {
    if ($row2[3] eq 'valid') { $authors{$row2[1]}++; }
      else { delete $authors{$row2[1]}; }
  }
  foreach my $author (sort keys %authors) {
    $result2 = $conn->exec( "SELECT * FROM wpa_author_index WHERE author_id = '$author' ORDER BY wpa_timestamp DESC; " );
    my @row2 = $result2->fetchrow();
    print "Author\t$row2[1]<BR>\n";
  } # foreach my $author (sort keys %authors)
  print "<BR>\n";
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

