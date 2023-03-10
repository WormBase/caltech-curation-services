#!/usr/bin/perl -w

# dump Xiaodong gene-gene interactions.  2009 10 02
#
# Possible_genetic and Possible_non-genetic could have no WBGene, don't dump them.
# Other_genetic not in model, don't dump yet.  2010 01 28

# usage
# ./dump_ggi_ace.pl > xiaodong_ggi.ace



use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $intId = 100000;

my %locToGene;
my $result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $locToGene{$row[1]} = $row[0]; } } 
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $locToGene{$row[1]} = $row[0]; } } 
$result = $dbh->prepare( "SELECT * FROM gin_sequence" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $locToGene{$row[1]} = $row[0]; } } 
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $locToGene{$row[1]} = $row[0]; } } 

$result = $dbh->prepare( "SELECT * FROM ggi_gene_gene_interaction WHERE ggi_interaction != 'No_interaction' ORDER BY ggi_timestamp" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $intId++;
    my ($int) = "WBInteraction" . &padZeros($intId);
    if ($row[2]) { if ($row[2] =~ m/\s/) { $row[2] =~ s/\s+//g; }
      if ($row[3]) { if ($row[3] =~ m/\s/) { $row[3] =~ s/\s+//g; } }
      unless ($locToGene{$row[2]}) { print STDERR "No WBGene for $row[2]\n"; next; }
      my $wbg1 = "WBGene" . $locToGene{$row[2]};
      my $wbg2 = "WBGene" . $locToGene{$row[3]};
      my $type = $row[4];
      next if ($type eq 'Other_Genetic');			# remove this when it's in the model
      my ($pap) = $row[1] =~ m/(WBPaper\d+)/;
      print "Interaction : \"$int\"\n";
      print "Interactor\t\"$wbg1\"\n";
      print "Interactor\t\"$wbg2\"\n";
      print "$type\tEffector\t\"$wbg1\"\n";
      print "$type\tEffected\t\"$wbg2\"\n";
      print "Paper\t\"$pap\"\n";
      print "Remark\t\"Interaction data was extracted by a curator from sentences enriched by Textpresso.  The interaction was attributed to the paper(s) from which it was extracted.\"\n";
      print "\n";
    }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

