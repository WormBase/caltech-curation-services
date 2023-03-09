#!/usr/bin/perl -w

# Display WBGene to WBPhenotype data 

# Text display of WBGene to WBPhenotype relationship based on alp_wbgene and
# alp_term.  For Karen / Chris Mungall  2008 01 02
#
# converted to DBI from Pg.  2009 09 18
 
use diagnostics;
use strict;
use CGI;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $query = new CGI;

# use Pg;
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $frontpage = 1;
my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color

my %hash;

print "Content-type: text/plain\n\n";
&display();


sub display {
  my $action;

  my $result = $dbh->prepare( "SELECT * FROM alp_term ORDER BY alp_timestamp;" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $hash{term}{$row[0]}{$row[1]}{$row[2]} = $row[3]; }
  $result = $dbh->prepare( "SELECT * FROM alp_wbgene ORDER BY alp_timestamp;" ); 
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $hash{gene}{$row[1]} = $row[0]; }

  foreach my $gene (sort keys %{ $hash{gene} }) {
    next unless ($gene);
    my %terms; my $locus = '';
    my $joinkey = $hash{gene}{$gene};
    if ($gene =~ m/\((.*?)\)/) { $locus = $1; }
    if ($locus =~ m/\(.*/) { $locus =~ s/\(.*$//; }
    if ($gene =~ m/(WBGene\d+)/) { $gene = $1; }
    $gene .= "\t$locus";
    foreach my $box (sort keys %{ $hash{term}{$joinkey} }) {
      foreach my $column (sort keys %{ $hash{term}{$joinkey}{$box} }) {
        my $term = $hash{term}{$joinkey}{$box}{$column};
        $terms{$term}++; } }
    foreach my $term (sort keys %terms) { 
      my $name = '';
      if ($term =~ m/\((.*?)\)/) { $name = $1; }
      if ($term =~ m/(WBPhenotype\d+)/) { $term = $1; }
      $term = "$term\t$name";
      next unless ($gene =~ m/WBGene/);
      print "$gene\t$term\t$joinkey\n"; }
  }
} # sub display

