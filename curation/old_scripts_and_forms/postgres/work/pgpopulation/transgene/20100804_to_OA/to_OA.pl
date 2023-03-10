#!/usr/bin/perl -w

# transfer trp_ tables from phenote (pipe separated fields) to OA ``"data","data"''
# populate trp_curator with Wen (WBPerson101) or Karen (WBPerson712) depending on 
# pgid   2010 08 04

# only these tables (and _hst tables)  needed updating :  driven_by_gene gene 
# reference map_paper marker_for_paper location
# this was the bad data on tazendra :
# trp_driven_by_gene ``WBGene00001524'' not valid in pgid 573 data: ``WBGene00001524''
# trp_driven_by_gene ``WBGene00003118'' not valid in pgid 7450 data: ``WBGene00003118''
# trp_driven_by_gene ``WBGene00003118'' not valid in pgid 7448 data: ``WBGene00007103 | WBGene00003118''
# trp_driven_by_gene ``WBGene00003118'' not valid in pgid 7449 data: ``WBGene00003118''
# trp_gene ``WBGene00010341"//F59F5.2'' not valid in pgid 5423 data: ``WBGene00010341" //F59F5.2''
# trp_gene ``WBGene00003118'' not valid in pgid 7448 data: ``WBGene00003118''
# trp_reference ``WBpaper00032252'' not valid in pgid 6326 data: ``WBPaper00026828 | WBpaper00032252''
# trp_reference ``WBpaper00004742'' not valid in pgid 6334 data: ``WBPaper00004124 | WBpaper00004742''
# trp_reference ``WBpaper00002316'' not valid in pgid 707 data: ``WBPaper00006431 | WBPaper00027305 | WBPaper00027646 | WBPaper00031828 | WBPaper00026785 | WBPaper00027711 | WBPaper00031592 | WBPaper00027091 | WBPaper00024617 | WBPaper00024523 | WBPaper00024955 | WBPaper00031996 | WBPaper00004409 | WBPaper00030940 | WBPaper00003191 | WBPaper00003350 | WBPaper00031605 | WBPaper00004146 | WBPaper00026711 | WBPaper00005014 | WBPaper00004942 | WBPaper00003678 | WBPaper00024212 | WBPaper00027305 | WBPaper00004523 | WBPaper00028525 | WBPaper00031466 | WBPaper00006494 | WBPaper00025465 | WBPaper00031872 | WBPaper00006427 | WBPaper00005871 | WBPaper00025150 | WBPaper00005543 | WBPaper00028376 | WBPaper00028874 | WBPaper00005092 | WBPaper00025084 | WBPaper00032207 | WBPaper00032456 | WBPaper00032515 | WBPaper00033002 | WBPaper00033075 | WBPaper00035181 | WBPaper00035198 | WBPaper00035545 | WBPaper00036056 | WBPaper00036184 | WBpaper00002316 | WBPaper00036253 | WBPaper00036363 | WBPaper00036365 | WBPaper00036664''
# 2010 08 19

# real run  2010 08 26



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %hash;
# my %clones;
# my %variations;
my @pgcommands;

my $result;

$result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{gene}{$row[1]}++; } }
$result = $dbh->prepare( "SELECT * FROM pap_status" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{paper}{"WBPaper$row[0]"}++; } }
$result = $dbh->prepare( "SELECT * FROM obo_name_trp_location" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $hash{lab}{$row[0]}++; } }

push @pgcommands, "DELETE FROM trp_curator";
push @pgcommands, "DELETE FROM trp_curator_hst"; 
$result = $dbh->prepare( "SELECT * FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $data = 'WBPerson101'; if ($row[0] > 5179) { $data = 'WBPerson712'; }
  push @pgcommands, "INSERT INTO trp_curator VALUES ('$row[0]', '$data')";
  push @pgcommands, "INSERT INTO trp_curator_hst VALUES ('$row[0]', '$data')"; }

my @pap_tables = qw( reference map_paper marker_for_paper );
my @gen_tables = qw( driven_by_gene gene );
my @lab_tables = qw( location );

foreach my $tab (@gen_tables) {
  my $table = 'trp_' . $tab;
  &process($table, 'gene');
  $table = 'trp_' . $tab . '_hst';
  &process($table, 'gene');
} # foreach my $table (@gen_tables)

foreach my $tab (@pap_tables) {
  my $table = 'trp_' . $tab;
  &process($table, 'paper');
  $table = 'trp_' . $tab . '_hst';
  &process($table, 'paper');
} # foreach my $table (@pap_tables)

foreach my $tab (@lab_tables) {
  my $table = 'trp_' . $tab;
  &process($table, 'lab');
  $table = 'trp_' . $tab . '_hst';
  &process($table, 'lab');
} # foreach my $table (@lab_tables)

sub process {
  my ($table, $type) = @_;
  $result = $dbh->prepare( "SELECT * FROM $table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      my (@objs) = split/ \| /, $row[1];
      my %good_objs;
      foreach my $obj (@objs) { $obj =~ s/\s//g; 
        if ($hash{$type}{$obj}) { $good_objs{$obj}++; }
          else { 
            unless ($table =~ m/_hst/) { print STDERR "$table ``$obj'' not valid in pgid $row[0] data: ``$row[1]''\n"; } } }
      my @gobj = sort keys %good_objs; my $gobj = join"\",\"", @gobj; $gobj = "\"$gobj\"";
#       print "$row[0]\t$row[1]\t$gobj\n";
      my $pgcommand = "UPDATE $table SET $table = '$gobj' WHERE joinkey = '$row[0]' AND $table = '$row[1]'";
      push @pgcommands, $pgcommand; } }
}


foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO update data
#   $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)

__END__

driven_by_gene -> multiontology         wbgene
gene -> multiontology                   wbgene
reference -> multiontology (wbpaper)    wbpaper
map_paper -> multiontology (paper)      wbpaper
marker_for_paper -> multiontology paper wbpaper
location -> multiontology (laboratory)  laboratory -> CONFIRM data matches ontology, | to ","

# these were already done  2010 08 19
# map_person -> multiontology (person)    wbperson
# rescues -> multiontology (variation) NEW        variation
# clone -> multiontology (clone) NEW      clone
# map -> multidropdown                    -> FIX some data not in quotes
# reporter_product -> multidropdown       -> FIX some data not in quotes
# integrated_by -> dropdown               only have single values, don't want multiple


$result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
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

$result = $dbh->prepare( "SELECT * FROM obo_name_trp_clone" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { $clones{$row[0]}++; } }

__END__

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

