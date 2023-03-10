#!/usr/bin/perl -w

# Could you please query Postgres and let us know the following:
# --How many genes have the reference genome tag (in the field 'Project' of the OA)--this would
#  give us how many reference genome genes we have annotated at all.
# --How many reference genome genes have annotations in more than one ontology, i.e in two diff
# erent ontologies, for examples--Process and Function or Component and Function etc.
#
# 2010 03 22




use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;

my $result = $dbh->prepare( "SELECT * FROM gop_wbgene WHERE joinkey IN (SELECT joinkey FROM gop_project WHERE gop_project ~ 'Reference')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $hash{genes}{$row[1]}{$row[0]}++;
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT * FROM gop_goontology WHERE joinkey IN (SELECT joinkey FROM gop_project WHERE gop_project ~ 'Reference')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $hash{ontology}{$row[0]}{$row[1]}++;
} # while (@row = $result->fetchrow)

my $multi_count = 0;
my $gene_count = 0;
foreach my $gene (sort keys %{ $hash{genes} }) {
  $gene_count++;
  my %multi;
  foreach my $joinkey (keys %{ $hash{genes}{$gene} } ) {
    foreach my $type (keys %{ $hash{ontology}{$joinkey} } ) { 
      $multi{$type}++; }
  } # foreach my $joinkey (keys %{ $hash{genes}{$gene} )
  my (@types) = keys %multi;
  if (scalar(@types) > 1) { $multi_count++; }
} # foreach my $gene (sort keys %{ $hash{genes} })
print "Genes with Reference : $gene_count\n";
print "Genes with multiple ontologies : $multi_count\n";




__END__

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

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

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';
