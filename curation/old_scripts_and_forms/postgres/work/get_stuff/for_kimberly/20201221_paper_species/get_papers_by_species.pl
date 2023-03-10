#!/usr/bin/perl -w

# get curatable nematode papers by species count

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pap;
my %species;

$result = $dbh->prepare( " SELECT * FROM pap_primary_data WHERE pap_primary_data = 'primary'; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{primary}{$row[0]}++; } }

$result = $dbh->prepare( " SELECT * FROM pap_curation_flags WHERE pap_curation_flags !~ 'nematode'; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{nematode}{$row[0]}++; } }

$result = $dbh->prepare( " SELECT * FROM pap_species; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pap{species}{$row[0]}{$row[1]}++; } }

$result = $dbh->prepare( " SELECT * FROM pap_species_index; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $species{$row[0]} = $row[1]; } }

my %counts;

foreach my $pap (sort keys %{ $pap{primary} }) {
  next unless $pap{nematode}{$pap};
  my $hasElegans = 0;
  my $noElegans = 0;
  foreach my $taxon (sort keys %{ $pap{species}{$pap} }) {
    if ($taxon eq '6239') { $hasElegans++; }
      else  { $noElegans++; }
  } # foreach my $taxon (sort keys %{ $pap{species}{$pap} })
  if ($hasElegans && !($noElegans)) { $counts{eleOnly}{6239}++; }
    elsif (!($hasElegans) && $noElegans) {
      foreach my $taxon (sort keys %{ $pap{species}{$pap} }) {
        $counts{noOnly}{$taxon}++; } }
    else {
      foreach my $taxon (sort keys %{ $pap{species}{$pap} }) {
        next if ($taxon eq '6239');
        $counts{both}{$taxon}++; } }
} # foreach my $pap (sort keys %{ $pap{primary} })

print qq(C. elegans only - $counts{eleOnly}{6239}\n);
foreach my $taxon (sort { $counts{noOnly}{$b} <=> $counts{noOnly}{$a} } keys %{ $counts{noOnly} }) {
  my $species = $species{$taxon};
  print qq($species (taxon $taxon) only - $counts{noOnly}{$taxon}\n);
} 
foreach my $taxon (sort { $counts{both}{$b} <=> $counts{both}{$a} } keys %{ $counts{both} }) {
  my $species = $species{$taxon};
  print qq(C. elegans and $species (taxon $taxon) - $counts{both}{$taxon}\n);
} 



__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

