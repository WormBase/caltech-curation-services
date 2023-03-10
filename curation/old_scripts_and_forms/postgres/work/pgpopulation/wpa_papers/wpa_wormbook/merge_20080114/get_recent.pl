#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $pmid_file = 'mergelist';
my @pmids;
open (IN, "<$pmid_file") or die "Cannot open $pmid_file : $!";
while (my $line = <IN>) {
  chomp $line; push @pmids, $line;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $pmid_file : $!";

my %titles;
my $result = $conn->exec( "SELECT * FROM wpa_title ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { 
  my $title = $row[1];
  ($title) = &parseTitle($title);
  if ($row[3] eq 'valid') { $titles{$title}{$row[0]}++; } else { delete $titles{$title}{$row[0]}; }
}

sub parseTitle {
  my $title = shift;
  $title =~ s/\.//g;
  $title =~ s/\,//g;
  $title =~ s/\;//g;
  $title =~ s/\s+/ /g;
  $title =~ s/\-\-/\-/g;
  $title =~ s/C elegans/Caenorhabditis elegans/g;
  ($title) = lc($title);
  return $title;
} # sub parseTitle

my %wormbook;
$result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'wormbook' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) { if ($row[3] eq 'valid') { $wormbook{$row[0]}++; } else { delete $wormbook{$row[0]}; } }


foreach my $wormbook (sort keys %wormbook) {
  my $result = $conn->exec( "SELECT wpa_title FROM wpa_title WHERE joinkey = '$wormbook' ORDER BY wpa_timestamp DESC;" );
  my @row = $result->fetchrow;
  my ($title) = &parseTitle($row[0]);
  if ($titles{$title}) { 
    foreach my $joinkey (sort keys %{ $titles{$title} }) { 
      my ($ids) = &getIds($joinkey);
      unless ($joinkey eq $wormbook) { print "$wormbook\t$title\t$joinkey\t$ids\n"; } }
  }
#   print "WB $wormbook\n";
}

sub getIds {
  my $joinkey = shift; my %identifiers;
  my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE joinkey = '$joinkey';" );
  while (my @row = $result->fetchrow) { 
    if ($row[3] eq 'valid') { $identifiers{$row[1]}++; } else { delete $identifiers{$row[1]}; } }
  my @ids = sort keys %identifiers;
  my $ids = join", ", @ids;
  return $ids;
} # sub getIds

__END__

# was mistakenly trying to find 2 papers with the same title for a given list of
# PMIDs



my %time;
foreach my $pmid (@pmids) { 
  my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier = 'pmid$pmid' ORDER BY wpa_timestamp;" );
  my $found = 0; my $time = 'notfound'; my $joinkey = '';
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      if ($row[5] =~ m/2008/) { $time = 'new'; } else { $time = 'old'; }
      $joinkey = $row[0];
#       print "J $row[0] ID $row[1] T $row[5] E\n";
#       $found++;
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
  $time{$time}{$pmid} = $joinkey;
#   unless ($found) { print "$pmid NOT FOUND\n"; }
} # foreach my $pmid (@pmids)

foreach my $time (sort keys %time) {
  foreach my $pmid (sort keys %{ $time{$time} }) {
    my $joinkey = $time{$time}{$pmid};
    if ($time eq 'new') { &findCopy($joinkey); }
    print "T $time P $pmid E\n"; 
  } # foreach my $pmid (sort keys %{ $time{$time} })
} # foreach my $time (sort keys %time)

sub findCopy {
  my $joinkey = shift;
  my $result = $conn->exec( "SELECT wpa_title FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC;" );
  my @row = $result->fetchrow(); my $title = $row[0];
  print "J $joinkey T $title\n";
  $result = $conn->exec( "SELECT * FROM wpa_title WHERE wpa_title ~ '$title' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { 
    next if ($row[0] eq '$joinkey');
    print "R @row R\n"; 
  }
  
} # sub findCopy

__END__


