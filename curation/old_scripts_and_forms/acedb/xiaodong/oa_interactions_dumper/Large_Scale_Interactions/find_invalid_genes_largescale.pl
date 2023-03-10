#!/usr/bin/perl -w

# find invalid wbgenes in largescale .ace file  2012 08 30

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %dead;
my $result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $dead = 'Dead';
  if ($row[1] =~ m/(WBGene\d+)/) { $dead = $1; }
  $dead{"WBGene$row[0]"}{$dead}++;
} # while (@row = $result->fetchrow)


$/ = undef;
my $infile = '/home/acedb/xiaodong/oa_interactions_dumper/Large_Scale_Interactions/Original_Large_Scale_Interactions_new_format.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or close "Cannot open $infile : $!";

my (@genes) = $all_file =~ m/(WBGene\d+)/g;
my %genes;
foreach my $gene (@genes) { $genes{$gene}++; }
foreach my $gene (sort keys %genes) {
  if ($dead{$gene}) { 
    my $deadGene = join", ", sort keys %{ $dead{$gene} };
    print "$gene NOW $deadGene\n"; }
} # foreach my $gene (@genes)


__END__

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

