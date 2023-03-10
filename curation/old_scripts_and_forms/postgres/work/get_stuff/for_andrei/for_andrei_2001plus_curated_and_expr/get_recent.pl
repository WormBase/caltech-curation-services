#!/usr/bin/perl -w
#
# Get the papers published 2001+, see if curated, and if so see how many have expr_patterns
# 2002 02 25

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %xref;

my %all_papers;
my %curated;


  # get papers published 2001 plus
my $result = $conn->exec( "SELECT joinkey FROM ref_year WHERE ref_year > '2000';" );
while (my @row = $result->fetchrow) { 
  if ($row[0]) { 
    $row[0] =~ s///g;
    $all_papers{$row[0]}++;			# add entry to all papers
} }
delete $all_papers{cgc3};			# delete junk entry

  # get the xref, and delete superfluous pmid entry
$result = $conn->exec( "SELECT * FROM ref_xref;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $xref{$row[0]} = $row[1];
    $xref{$row[1]} = $row[0];
    delete $all_papers{$row[1]};		# if in xref, delete the pmid from list
} }

print OUT "All papers 2001+ : " . scalar(keys %all_papers) . "\n";

$result = $conn->exec( "SELECT joinkey FROM cur_curator;" );	# get curators
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $curated{$row[0]}++;			# add entry to curated
} } 

foreach (sort keys %all_papers) {		# check all papers 
  unless ($curated{$_}) { delete $all_papers{$_}; }
						# if not curated, delete from list
} # foreach (sort keys %all_papers)

print OUT "Curated papers 2001+ : " . scalar(keys %all_papers) . "\n";

my $count;					# count of those with expr from list
$result = $conn->exec( "SELECT joinkey FROM cur_expression WHERE cur_expression IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  $row[0] =~ s///g;
  if ($all_papers{$row[0]}) {			# if there's an entry
    $count++;					# add to count
  } else {					# if there's no entry 
    if ($xref{$row[0]}) { 			# check opposite (the corresponding xref)
      if ($all_papers{ $xref{$row[0]} } ) { $count++; }	# if there's entry, add to count
    }
  }
} 

print OUT "Papers with Expression 2001+ : " . $count . "\n";


