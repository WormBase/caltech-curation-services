#!/usr/bin/perl -w

# Update gop_project values based on WBGene list to "Reference Genomes"
# Should probably make into list field, but all values are "Reference Genomes"
# so just adding instead.  If another set, check that all values are actually
# not being overwritten from other good values.
# this query gives the values of the gop_project from that list of $wbgenes.
# my $result = $dbh->prepare( "SELECT * FROM gop_project WHERE joinkey IN (SELECT joinkey FROM gop_wbgene WHERE gop_wbgene IN ('$wbgenes'))" );
# 2010 03 11


use strict;
use diagnostics;
use DBI;


my $infile = '/home/acedb/ranjana/Worm_genes_RefGenome.txt';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!";
my (@wbgenes) = $all_file =~ m/(WBGene\d+)/g;
my %wbgenes; foreach (@wbgenes) { $wbgenes{$_}++; }
$/ = "\n";

# foreach my $wbgene (sort keys %wbgenes) { print "$wbgene\n"; }	# to show which wbgenes


my $wbgenes = join"', '", keys %wbgenes;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %project;
my $result = $dbh->prepare( "SELECT * FROM gop_project" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $project{$row[0]} = $row[1]; }
} # while (@row = $result->fetchrow)

$result = $dbh->prepare( "SELECT joinkey FROM gop_wbgene WHERE gop_wbgene IN ('$wbgenes')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($project{$row[0]}) { print "$row[0]\t$project{$row[0]}\n"; }
      else {
# UNCOMMENT TO UPDATE gop_project values based on WBGene list   2010 03 11
#         my $result2 = $dbh->do( "DELETE FROM gop_project WHERE joinkey = '$row[0]'" );
#         $result2 = $dbh->do( "INSERT INTO gop_project VALUES ('$row[0]', 'Reference Genomes')" );
#         $result2 = $dbh->do( "INSERT INTO gop_project_hst VALUES ('$row[0]', 'Reference Genomes')" );
        print "NEW $row[0]\n";
      }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

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
