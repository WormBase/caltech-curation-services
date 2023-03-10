#!/usr/bin/perl -w

# calculate percentages of papers being reviews by journal.  2009 05 14

use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %journals;
my $result = $dbh->prepare( 'SELECT * FROM wpa_journal ORDER BY wpa_timestamp' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $journals{$row[1]}{$row[0]}++; }
      else { delete $journals{$row[1]}{$row[0]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %type;
$result = $dbh->prepare( 'SELECT * FROM wpa_type ORDER BY wpa_timestamp' );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') { $type{$row[0]}{$row[1]}++; }
      else { delete $type{$row[0]}{$row[1]}; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %forceReview;
# $forceReview{"Trends in Genetics"}++;
# $forceReview{"Trends in Neuroscience"}++;
# $forceReview{"Trends in Cell Biology"}++;
$forceReview{"Current Trends in Membranes"}++;
$forceReview{"Current Trends in Microbiology"}++;
$forceReview{"Trends in Biochemical Sciences"}++;
$forceReview{"Trends in Biotechnology"}++;
$forceReview{"Trends in Biotechnology Supp"}++;
$forceReview{"Trends in Cell Biology"}++;
$forceReview{"Trends in Ecology & Evolution"}++;
$forceReview{"Trends in Endocrinology and Metabolism"}++;
$forceReview{"Trends in Endocrinology & Metabolism"}++;
$forceReview{"Trends in Genetics"}++;
$forceReview{"Trends in Glycoscience and Glycotechnology"}++;
$forceReview{"Trends in Glycosylation"}++;
$forceReview{"Trends in Immunology"}++;
$forceReview{"Trends in Microbiology"}++;
$forceReview{"Trends in Neurosciences"}++;
$forceReview{"Trends in Parasitology"}++;
$forceReview{"Trends in Pharmacological Sciences"}++;
$forceReview{"Annual Review of Biophysics & Bioengineering"}++;
$forceReview{"Annual Review of Cell and Developmental Biology"}++;
$forceReview{"Annual Review of Cell Biology"}++;
$forceReview{"Annual Review of Cell & Developmental Biology"}++;
$forceReview{"Annual Review of Genetics"}++;
$forceReview{"Annual Review of Genomics & Human Genetics"}++;
$forceReview{"Annual Review of Microbiology"}++;
$forceReview{"Annual Review of Neuroscience"}++;
$forceReview{"Annual Review of Pharmacology and Toxicology"}++;
$forceReview{"Annual Review of Physiology"}++;
$forceReview{"Annual Review of Phytopathology"}++;
$forceReview{"Nature Reviews Genetics"}++;
$forceReview{"Nature Reviews Molecular Cell Biology"}++;
$forceReview{"Nature Reviews Neuroscience"}++;
$forceReview{"Nature Reviews Immunology"}++;

foreach my $journal (sort keys %journals) {
  my (@papers) = keys %{ $journals{$journal} };
  my $papsInJournal = scalar @papers;
  my $revInJournal = 0;
  my %revs;
  if ($papsInJournal > 2) { 
    foreach my $paper (@papers) {
      my (@types) = keys %{ $type{$paper} };
#       if (scalar @types > 1) { print "$journal $paper has multiple types @types\n"; }
#         else { print "$journal P $paper T $types[0]\n"; }
      if ($type{$paper}{'2'}) { $revInJournal++; $revs{$paper}++; }
    } # foreach my $paper (@papers)
#     if ($forceReview{$journal}) { 
      my $pct = &round( 100 * $revInJournal / $papsInJournal);
      if ($pct > 75) {
        print "$journal $papsInJournal papers, $revInJournal are review, which is $pct%\n";
      }
#     }
#     if ($revInJournal / $papsInJournal > .9) { print "with $papsInJournal, over 90 percent review $journal\n"; }
#     print "$journal\t$papsInJournal\n"; 
  }
} # foreach my $journal (sort keys %journals)

sub round {
  my ($number) = shift;
  return int($number + .5);
}



__END__

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us
