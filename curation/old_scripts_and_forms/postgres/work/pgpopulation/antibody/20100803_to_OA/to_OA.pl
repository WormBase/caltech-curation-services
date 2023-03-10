#!/usr/bin/perl -w

# transfer abp_ tables from phenote (pipe separated fields) to OA ``"data","data"''
# populate abp_curator with Wen (WBPerson101)   2010 08 03
#
# populated postgres on tazendra, there were still some errors for some genes :
# abp_gene ``WBGene00017903'' not valid in pgid 933 data: ``WBGene00006498 | WBGene00017903''
# abp_gene ``WBGene00003557'' not valid in pgid 1260 data: ``WBGene00003557''
# abp_gene ``WBGene00003557'' not valid in pgid 1384 data: ``WBGene00003557''
# abp_gene_hst ``WBGene00017903'' not valid in pgid 933 data: ``WBGene00006498 | WBGene00017903''
# abp_gene_hst ``WBGene00003557'' not valid in pgid 1260 data: ``WBGene00003557''
# abp_gene_hst ``WBGene00003557'' not valid in pgid 1384 data: ``WBGene00003557''
#
# Last data had changed on 2010 07 22 (pgid 2128).    2010 08 10


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %genes;
my %papers;
my %labs;
my @pgcommands;

my $result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $genes{$row[1]}++; } }

$result = $dbh->prepare( "SELECT * FROM pap_status" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $papers{"WBPaper$row[0]"}++; } }

$result = $dbh->prepare( "SELECT * FROM obo_name_trp_location" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $labs{$row[0]}++; } }

$result = $dbh->prepare( "SELECT * FROM abp_gene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@genes) = split/ \| /, $row[1];
    my %good_genes;
    foreach my $gene (@genes) { 
      if ($genes{$gene}) { $good_genes{$gene}++; }
        else { print STDERR "abp_gene ``$gene'' not valid in pgid $row[0] data: ``$row[1]''\n"; } }
    my @gg = sort keys %good_genes; my $gg = join"\",\"", @gg; if ($gg) { $gg = "\"$gg\""; }
#     print "$row[0]\t$row[1]\t$gg\n"; 
    my $pgcommand = "UPDATE abp_gene SET abp_gene = '$gg' WHERE joinkey = '$row[0]'";
    push @pgcommands, $pgcommand; } }
$result = $dbh->prepare( "SELECT * FROM abp_gene_hst" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@genes) = split/ \| /, $row[1];
    my %good_genes;
    foreach my $gene (@genes) { 
      if ($genes{$gene}) { $good_genes{$gene}++; }
        else { print STDERR "abp_gene_hst ``$gene'' not valid in pgid $row[0] data: ``$row[1]''\n"; } }
    my @gg = sort keys %good_genes; my $gg = join"\",\"", @gg; if ($gg) { $gg = "\"$gg\""; }
#     print "$row[0]\t$row[1]\t$gg\n"; 
    my $pgcommand = "UPDATE abp_gene_hst SET abp_gene_hst = '$gg' WHERE joinkey = '$row[0]'";
    push @pgcommands, $pgcommand; } }

$result = $dbh->prepare( "SELECT * FROM abp_reference" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@paps) = split/ \| /, $row[1];
    my %good_paps;
    foreach my $pap (@paps) { $pap =~ s/\s//g; 
      if ($papers{$pap}) { $good_paps{$pap}++; }
        else { print STDERR "abp_reference ``$pap'' not valid in pgid $row[0] data: ``$row[1]''\n"; } }
    my @gpap = sort keys %good_paps; my $gpap = join"\",\"", @gpap; $gpap = "\"$gpap\"";
#     print "$row[0]\t$row[1]\t$gpap\n";
    my $pgcommand = "UPDATE abp_reference SET abp_reference = '$gpap' WHERE joinkey = '$row[0]'";
    push @pgcommands, $pgcommand; } }
$result = $dbh->prepare( "SELECT * FROM abp_reference_hst" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@paps) = split/ \| /, $row[1];
    my %good_paps;
    foreach my $pap (@paps) { $pap =~ s/\s//g; 
      if ($papers{$pap}) { $good_paps{$pap}++; }
        else { print STDERR "abp_reference_hst ``$pap'' not valid in pgid $row[0] data: ``$row[1]''\n"; } }
    my @gpap = sort keys %good_paps; my $gpap = join"\",\"", @gpap; $gpap = "\"$gpap\"";
#     print "$row[0]\t$row[1]\t$gpap\n";
    my $pgcommand = "UPDATE abp_reference_hst SET abp_reference_hst = '$gpap' WHERE joinkey = '$row[0]'";
    push @pgcommands, $pgcommand; } }

$result = $dbh->prepare( "SELECT * FROM abp_location" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@labs) = split/ \| /, $row[1];
    my %good_labs;
    foreach my $lab (@labs) { $lab =~ s/\s//g; 
      if ($labs{$lab}) { $good_labs{$lab}++; }
        else { print STDERR "abp_location ``$lab'' not valid in pgid $row[0] data: ``$row[1]''\n"; } }
    my @glab = sort keys %good_labs; my $glab = join"\",\"", @glab; $glab = "\"$glab\"";
#     print "$row[0]\t$row[1]\t$glab\n";
    my $pgcommand = "UPDATE abp_location SET abp_location = '$glab' WHERE joinkey = '$row[0]'";
    push @pgcommands, $pgcommand; } }
$result = $dbh->prepare( "SELECT * FROM abp_location_hst" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@labs) = split/ \| /, $row[1];
    my %good_labs;
    foreach my $lab (@labs) { $lab =~ s/\s//g; 
      if ($labs{$lab}) { $good_labs{$lab}++; }
        else { print STDERR "abp_location_hst ``$lab'' not valid in pgid $row[0] data: ``$row[1]''\n"; } }
    my @glab = sort keys %good_labs; my $glab = join"\",\"", @glab; $glab = "\"$glab\"";
#     print "$row[0]\t$row[1]\t$glab\n";
    my $pgcommand = "UPDATE abp_location_hst SET abp_location_hst = '$glab' WHERE joinkey = '$row[0]'";
    push @pgcommands, $pgcommand; } }

$result = $dbh->prepare( "SELECT * FROM abp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  push @pgcommands, "INSERT INTO abp_curator VALUES ('$row[0]', 'WBPerson101')";
  push @pgcommands, "INSERT INTO abp_curator_hst VALUES ('$row[0]', 'WBPerson101')"; }


foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO update data
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)


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

