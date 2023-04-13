#!/usr/bin/perl -w

# look at first pass numbers  2012 08 27


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;

# my @tables = qw( afp_ablationdata afp_comment afp_genefunc afp_humdis afp_matrices afp_newprotein afp_overexpr afp_siteaction afp_antibody afp_covalent afp_geneint afp_invitro afp_microarray afp_newsnp afp_structcorr afp_authors afp_domanal afp_geneprod afp_mosaic afp_newstrains afp_phylogenetic afp_structinfo afp_celegans afp_genereg afp_lsrnai afp_nematode afp_review afp_supplemental afp_cellfunc afp_expression afp_genestudied afp_mappingdata afp_newbalancers afp_nonnematode afp_rnai afp_timeaction afp_chemicals afp_extvariation afp_genesymbol afp_marker afp_newcell afp_otherexpr afp_seqchange afp_transgene afp_cnonbristol afp_funccomp afp_gocuration afp_massspec afp_newmutant afp_othersilico afp_seqfeat );

# don't care about genestudied because it's probably just a list of genes
my @tables = qw( afp_ablationdata afp_comment afp_genefunc afp_humdis afp_matrices afp_newprotein afp_overexpr afp_siteaction afp_antibody afp_covalent afp_geneint afp_invitro afp_microarray afp_newsnp afp_structcorr afp_authors afp_domanal afp_geneprod afp_mosaic afp_newstrains afp_phylogenetic afp_structinfo afp_celegans afp_genereg afp_lsrnai afp_nematode afp_review afp_supplemental afp_cellfunc afp_expression afp_mappingdata afp_newbalancers afp_nonnematode afp_rnai afp_timeaction afp_chemicals afp_extvariation afp_genesymbol afp_marker afp_newcell afp_otherexpr afp_seqchange afp_transgene afp_cnonbristol afp_funccomp afp_gocuration afp_massspec afp_newmutant afp_othersilico afp_seqfeat );

foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      if ($row[1] ne 'checked') { $hash{$row[0]}{$table} = $row[1]; } } }
} # foreach my $table (@tables)

my $result = $dbh->prepare( "SELECT COUNT(*) FROM afp_lasttouched" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
print "There are $row[0] papers with a lasttouched\n";

$result = $dbh->prepare( "SELECT COUNT(*) FROM afp_passwd" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
@row = $result->fetchrow();
print "There are $row[0] papers with a passwd\n";


my $count = 0;
$result = $dbh->prepare( "SELECT * FROM afp_lasttouched" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($hash{$row[0]}) { $count++; } }

print "There are $count papers with non-checked data in some field\n";

$result = $dbh->prepare( "SELECT * FROM afp_lasttouched" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($hash{$row[0]}) { 
    print "\nPAPER $row[0]\n";
    foreach my $table (@tables) {
      if ($hash{$row[0]}{$table}) { 
        print "$table : $hash{$row[0]}{$table}\n"; } } } }

  
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

