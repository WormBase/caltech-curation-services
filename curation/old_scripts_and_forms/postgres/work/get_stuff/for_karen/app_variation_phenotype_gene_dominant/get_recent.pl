#!/usr/bin/perl -w

# Karen :I need a list of all alleles, their associated gene, and phenotype where the phenotype is marked as "Dominant".
# I think the app tables are app_variation, app_term where app_nature value ="Dominant".  I don't know how you get gene. 
#
# For some help desk user, probably.  Querying stuff.  2013 01 18

 
use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %pgids;
my $result = $dbh->prepare( "SELECT * FROM app_nature WHERE app_nature = 'Dominant'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $pgids{$row[0]}++; } }
my $pgids = join"','", sort keys %pgids;

my %terms; my %all_terms; my %term_name;
$result = $dbh->prepare( "SELECT * FROM app_term WHERE joinkey IN ('$pgids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $terms{$row[0]} = $row[1]; $all_terms{$row[1]}++; }

my $terms = join"','", sort keys %all_terms;
$result = $dbh->prepare( "SELECT * FROM obo_name_phenotype WHERE joinkey IN ('$terms')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $term_name{$row[0]} = $row[1]; }


my %vars; my %all_vars; my %var_name; my %var_genes;
$result = $dbh->prepare( "SELECT * FROM app_variation WHERE joinkey IN ('$pgids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $vars{$row[0]} = $row[1]; $all_vars{$row[1]}++; }

my %all_genes;
my $vars = join"','", sort keys %all_vars;
$result = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE joinkey IN ('$vars')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  my ($name) = $row[1] =~ m/name: "(.*?)"/;
  my (@genes) = $row[1] =~ m/(WBGene\d+)/g;
  foreach my $gene (@genes) { $var_genes{$row[0]}{$gene}++; $gene =~ s/WBGene//; $all_genes{$gene}++; }
  $var_name{$row[0]} = $name; }

my $genes = join"','", sort keys %all_genes; my %gene_names;
$result = $dbh->prepare( "SELECT * FROM gin_seqname WHERE joinkey IN ('$genes')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gene_names{"WBGene$row[0]"} = $row[1]; }
$result = $dbh->prepare( "SELECT * FROM gin_locus WHERE joinkey IN ('$genes')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gene_names{"WBGene$row[0]"} = $row[1]; }

foreach my $pgid (sort keys %pgids) {
  my $term = $terms{$pgid};
  my $tname = $term_name{$term};
  my $var = $vars{$pgid};
  my $vname = $var_name{$var};
  my @vgenes;
  foreach my $gene (sort keys %{ $var_genes{$var} }) { push @vgenes, "$gene ( $gene_names{$gene} )"; }
#   my $vgenes = join", ", sort keys %{ $var_genes{$var} };
  my $vgenes = join", ", @vgenes;
  print qq($pgid\t$term\t$tname\t$var\t$vname\t$vgenes\n);
} # foreach my $pgid (sort keys %pgids)


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

