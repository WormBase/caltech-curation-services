#!/usr/bin/perl -w

# transfer data to new tables, or to new formats.
# 
# It gets a list of valid transgene objects from trp_name, rnai objects
# from rna_name, and gene objects from gin_wbgene.
# 
# looks at int_transgeneone + int_transgenetwo, checking each value 
# against valid values and giving an error if invalid.  valid values are
# joined together as multiontology   "<one>","<two>","<three>"  and 
# stored in int_transgene
# 
# looks at int_paper and int_rnai.  gets individual rnai objects from 
# multiontology format.  if the rnai value is valid, adds to rnai list,
# if the paper is WBPaper00029258 adds to lsrnai list, otherwise gives 
# an error.  lsrnai values are joinkey with  <space>|<space>  and 
# entered into int_lsrnai.  rnai values are deleted for that pgid, and 
# entered again into int_rnai after being joined together as 
# multiontology   "<one>","<two>","<three>"  
# 
# looks at int_nondirectional + int_geneone + int_genetwo.  where the 
# value is nondirectional, get individual genes from geneone + genetwo,
# if invalid objects give an error.  that pgid is deleted from 
# int_geneone and int_genetwo.  valid values are joined together as 
# multiontology "<one>","<two>","<three>"  and stored in int_genenondir.
# 
# int_type values are changed to tag values for dump :
#   'Physical_interaction'   =>  'Physical'
#   'Predicted_interaction'  =>  'Predicted'
#   'Genetic'                =>  'Genetic_interaction'
# distinct values gotten from int_type and changed to multiontology 
#
# 2012 05 29
#
# live run on tazendra 2012 06 21


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %objects;
my @pgcommands;

$result = $dbh->prepare( "SELECT * FROM trp_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $objects{transgene}{$row[1]}++; } }

$result = $dbh->prepare( "SELECT * FROM rna_name" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $objects{rnai}{$row[1]}++; } }

$result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $objects{gene}{$row[1]}++; } }

$result = $dbh->prepare( "SELECT * FROM obo_name_variation" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $objects{variation}{$row[0]}++; } }


my %transgene;
$result = $dbh->prepare( "SELECT * FROM int_transgeneone" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  if ($objects{transgene}{$row[1]}) { $transgene{$row[0]}{$row[1]}++; }
    else { print "INVALID transgene transgeneone $row[0] : $row[1]\n"; } } }
$result = $dbh->prepare( "SELECT * FROM int_transgenetwo" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  if ($objects{transgene}{$row[1]}) { $transgene{$row[0]}{$row[1]}++; }
    else { print "INVALID transgene transgenetwo $row[0] : $row[1]\n"; } } }
foreach my $pgid (sort {$a<=>$b} keys %transgene) {
  my $data = join'","', sort keys %{ $transgene{$pgid} };
# UNCOMMENT to transfer transgenes
  push @pgcommands, qq(INSERT INTO int_transgene VALUES ('$pgid', '"$data"'););
  push @pgcommands, qq(INSERT INTO int_transgene_hst VALUES ('$pgid', '"$data"'););
} # foreach my $pgid (sort keys %transgene)


my %rnai; my %lsrnai; my %paper;
$result = $dbh->prepare( "SELECT * FROM int_paper" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $paper{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM int_rnai" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  if ($objects{rnai}{$row[1]}) { $rnai{$row[0]}{$row[1]}++; }				# valid normal rnai (non-ls)
    elsif ($paper{$row[0]} eq 'WBPaper00029258') { $lsrnai{$row[0]}{$row[1]}++; }	# ls paper
    else { print "INVALID rnai $row[0] : $row[1] with paper $paper{$row[0]}\n"; } } }	# invalid and unaccounted
foreach my $pgid (sort {$a<=>$b} keys %lsrnai) {
  my $data = join' | ', sort keys %{ $lsrnai{$pgid} };
# UNCOMMENT to transfer rnai to lsrnai
  push @pgcommands, qq(DELETE FROM int_rnai WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_lsrnai VALUES ('$pgid', '$data'););
  push @pgcommands, qq(INSERT INTO int_lsrnai_hst VALUES ('$pgid', '$data'););
} # foreach my $pgid (sort keys %lsrnai)
foreach my $pgid (sort keys %rnai) {
  my $data = join'","', sort keys %{ $rnai{$pgid} };
# UNCOMMENT to transfer rnai to multiontology
  push @pgcommands, qq(DELETE FROM int_rnai WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_rnai VALUES ('$pgid', '"$data"'););
  push @pgcommands, qq(INSERT INTO int_rnai_hst VALUES ('$pgid', '"$data"'););
} # foreach my $pgid (sort keys %rnai)


my %nondir; my %geneone; my %genetwo; my %genenondir; my %oldgeneone; my %oldgenetwo;
$result = $dbh->prepare( "SELECT * FROM int_nondirectional WHERE int_nondirectional != ''" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $nondir{$row[0]}++; } }
$result = $dbh->prepare( "SELECT * FROM int_transgeneonegene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/"//g;
  my @genes = split/,/, $row[1];
  foreach my $gene (@genes) {
    if ($objects{gene}{$gene}) { 
        if ($nondir{$row[0]}) { $genenondir{$row[0]}{$gene}++; }
          else { $geneone{$row[0]}{$gene}++; } }
      else { print "INVALID gene transgeneonegene $row[0] : $gene\n"; } } } }
$result = $dbh->prepare( "SELECT * FROM int_transgenetwogene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/"//g;
  my @genes = split/,/, $row[1];
  foreach my $gene (@genes) {
    if ($objects{gene}{$gene}) {
        if ($nondir{$row[0]}) { $genenondir{$row[0]}{$gene}++; }
          else { $genetwo{$row[0]}{$gene}++; } }
      else { print "INVALID gene transgenetwogene $row[0] : $gene\n"; } } } }
$result = $dbh->prepare( "SELECT * FROM int_geneone" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/"//g;
  my @genes = split/,/, $row[1];
  foreach my $gene (@genes) {
    if ($objects{gene}{$gene}) {
        $oldgeneone{$row[0]}{$gene}++;
        if ($nondir{$row[0]}) { $genenondir{$row[0]}{$gene}++; }
          else { $geneone{$row[0]}{$gene}++; } }
      else { print "INVALID gene geneone $row[0] : $gene\n"; } } } }
$result = $dbh->prepare( "SELECT * FROM int_genetwo" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/"//g;
  my @genes = split/,/, $row[1];
  foreach my $gene (@genes) {
    if ($objects{gene}{$gene}) {
        $oldgenetwo{$row[0]}{$gene}++;
        if ($nondir{$row[0]}) { $genenondir{$row[0]}{$gene}++; }
          else { $genetwo{$row[0]}{$gene}++; } }
      else { print "INVALID gene genetwo $row[0] : $gene\n"; } } } }

foreach my $pgid (sort {$a<=>$b} keys %geneone) {
  my $data = join'","', sort keys %{ $geneone{$pgid} };
  my $olddata = join'","', sort keys %{ $oldgeneone{$pgid} };
#   if ($data eq $olddata) { print "SAME for $pgid int_geneone $data\n"; }
  next if ($data eq $olddata);
  push @pgcommands, qq(DELETE FROM int_geneone WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_geneone VALUES ('$pgid', '"$data"'););
  push @pgcommands, qq(INSERT INTO int_geneone_hst VALUES ('$pgid', '"$data"'););
} # foreach my $pgid (sort {$a<=>$b} keys %geneone)
foreach my $pgid (sort {$a<=>$b} keys %genetwo) {
  my $data = join'","', sort keys %{ $genetwo{$pgid} };
  my $olddata = join'","', sort keys %{ $oldgenetwo{$pgid} };
#   if ($data eq $olddata) { print "SAME for $pgid int_genetwo $data\n"; }
  next if ($data eq $olddata);
  push @pgcommands, qq(DELETE FROM int_genetwo WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_genetwo VALUES ('$pgid', '"$data"'););
  push @pgcommands, qq(INSERT INTO int_genetwo_hst VALUES ('$pgid', '"$data"'););
} # foreach my $pgid (sort {$a<=>$b} keys %genetwo)
foreach my $pgid (sort {$a<=>$b} keys %genenondir) {
  my $data = join'","', sort keys %{ $genenondir{$pgid} };
  push @pgcommands, qq(DELETE FROM int_geneone WHERE joinkey = '$pgid';);
  push @pgcommands, qq(DELETE FROM int_genetwo WHERE joinkey = '$pgid';);
  push @pgcommands, qq(DELETE FROM int_genenondir WHERE joinkey = '$pgid';);
  push @pgcommands, qq(INSERT INTO int_genenondir VALUES ('$pgid', '"$data"'););
  push @pgcommands, qq(INSERT INTO int_genenondir_hst VALUES ('$pgid', '"$data"'););
} # foreach my $pgid (sort {$a<=>$b} keys %genenondir)

# old way of transferring from geneone/genetwo to genenondir without accounting for transgeneonegene nor transgenetwogene
# foreach my $pgid (sort {$a<=>$b} keys %nondir) {
#   my %genes;
#   foreach my $gene (sort keys %{ $geneone{$pgid} }) { $genes{$gene}++; }
#   foreach my $gene (sort keys %{ $genetwo{$pgid} }) { $genes{$gene}++; }
#   my $data = join'","', sort keys %genes;
# # UNCOMMENT to remove nondir genes from geneone + genetwo and add them to genenondir
#   push @pgcommands, qq(DELETE FROM int_geneone WHERE joinkey = '$pgid';);
#   push @pgcommands, qq(DELETE FROM int_genetwo WHERE joinkey = '$pgid';);
#   push @pgcommands, qq(INSERT INTO int_geneone_hst VALUES ('$pgid', ''););
#   push @pgcommands, qq(INSERT INTO int_genetwo_hst VALUES ('$pgid', ''););
#   push @pgcommands, qq(INSERT INTO int_genenondir VALUES ('$pgid', '"$data"'););
#   push @pgcommands, qq(INSERT INTO int_genenondir_hst VALUES ('$pgid', '"$data"'););
# } # foreach my $pgid (sort keys %nondir)



my %variationone; my %variationtwo; my %variationnondir;
$result = $dbh->prepare( "SELECT * FROM int_variationone" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/"//g;
  my @variations = split/,/, $row[1];
  foreach my $variation (@variations) {
    if ($objects{variation}{$variation}) { $variationone{$row[0]}{$variation}++; }
      else { print "INVALID variation variationone $row[0] : $variation\n"; } } } }
$result = $dbh->prepare( "SELECT * FROM int_variationtwo" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { 
  $row[1] =~ s/"//g;
  my @variations = split/,/, $row[1];
  foreach my $variation (@variations) {
    if ($objects{variation}{$variation}) { $variationtwo{$row[0]}{$variation}++; }
      else { print "INVALID variation variationtwo $row[0] : $variation\n"; } } } }
foreach my $pgid (sort {$a<=>$b} keys %nondir) {		# given nondirectional toggles, if variations, remove from one/two and put in nondir
  my %vars;
  foreach my $variation (sort keys %{ $variationone{$pgid} }) { $vars{$variation}++; }
  foreach my $variation (sort keys %{ $variationtwo{$pgid} }) { $vars{$variation}++; }
  my $data = join'","', sort keys %vars;
  if ($data) {
# UNCOMMENT to remove nondir vars from variationone + variationtwo and add them to variationnondir
    push @pgcommands, qq(DELETE FROM int_variationone WHERE joinkey = '$pgid';);
    push @pgcommands, qq(DELETE FROM int_variationtwo WHERE joinkey = '$pgid';);
    push @pgcommands, qq(INSERT INTO int_variationone_hst VALUES ('$pgid', ''););
    push @pgcommands, qq(INSERT INTO int_variationtwo_hst VALUES ('$pgid', ''););
    push @pgcommands, qq(INSERT INTO int_variationnondir VALUES ('$pgid', '"$data"'););
    push @pgcommands, qq(INSERT INTO int_variationnondir_hst VALUES ('$pgid', '"$data"'););
  }
} # foreach my $pgid (sort keys %nondir)



push @pgcommands, qq(UPDATE int_type SET int_type = 'Physical' WHERE int_type = 'Physical_interaction');
push @pgcommands, qq(UPDATE int_type SET int_type = 'Predicted' WHERE int_type = 'Predicted_interaction');
push @pgcommands, qq(UPDATE int_type SET int_type = 'Genetic_interaction' WHERE int_type = 'Genetic');
push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = 'Physical' WHERE int_type_hst = 'Physical_interaction');
push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = 'Predicted' WHERE int_type_hst = 'Predicted_interaction');
push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = 'Genetic_interaction' WHERE int_type_hst = 'Genetic');


push @pgcommands, "COPY int_remark TO '/home/postgres/work/pgpopulation/interaction/20120527_OA_newModel/backup_int_remark.pg';" ;
push @pgcommands, "COPY int_summary FROM '/home/postgres/work/pgpopulation/interaction/20120527_OA_newModel/backup_int_remark.pg';" ;
push @pgcommands, "COPY int_remark_hst TO '/home/postgres/work/pgpopulation/interaction/20120527_OA_newModel/backup_int_remark_hst.pg';" ;
push @pgcommands, "COPY int_summary_hst FROM '/home/postgres/work/pgpopulation/interaction/20120527_OA_newModel/backup_int_remark_hst.pg';" ;
push @pgcommands, "DELETE FROM int_remark ;" ;
push @pgcommands, "DELETE FROM int_remark_hst ;" ;


# the next block was to convert interaction type to multiontology by putting doublequotes around it.
# # UNCOMMENT to transfer values that change name
# push @pgcommands, qq(UPDATE int_type SET int_type = '"Physical"' WHERE int_type = 'Physical_interaction');
# push @pgcommands, qq(UPDATE int_type SET int_type = '"Predicted"' WHERE int_type = 'Predicted_interaction');
# push @pgcommands, qq(UPDATE int_type SET int_type = '"Genetic_interaction"' WHERE int_type = 'Genetic');
# push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = '"Physical"' WHERE int_type_hst = 'Physical_interaction');
# push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = '"Predicted"' WHERE int_type_hst = 'Predicted_interaction');
# push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = '"Genetic_interaction"' WHERE int_type_hst = 'Genetic');
# 
# my %types;
# $result = $dbh->prepare( "SELECT DISTINCT(int_type) FROM int_type" );	# some of these won't change because they will have already changed from update above
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) { if ($row[0]) { 
# # UNCOMMENT to transfer values to multiontology
#   push @pgcommands, qq(UPDATE int_type SET int_type = '"$row[0]"' WHERE int_type = '$row[0]');
#   push @pgcommands, qq(UPDATE int_type_hst SET int_type_hst = '"$row[0]"' WHERE int_type_hst = '$row[0]'); 
# } }
  



foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT for live transfer.  only run once, it updates source values, so won't work second time around, to run again recover from backup/ directory.
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)



__END__

 merge into int_transgene :
 int_transgenetwo
 int_transgeneone

 if valid make ontology, else move into int_lsrnai :
 int_rnai

 int_nondirectional + int_geneone / int_genetwo move to int_genenondir 
 leave non-nondirectional where they are

 int_type make multiontology
  UPDATE int_type SET int_type = 'Physical' WHERE int_type = 'Physical_interaction' ;
  UPDATE int_type SET int_type = 'Predicted' WHERE int_type = 'Predicted_interaction' ;
  UPDATE int_type SET int_type = 'Genetic_interaction' WHERE int_type = 'Genetic' ;

  UPDATE int_type_hst SET int_type_hst = 'Physical' WHERE int_type_hst = 'Physical_interaction' ;
  UPDATE int_type_hst SET int_type_hst = 'Predicted' WHERE int_type_hst = 'Predicted_interaction' ;
  UPDATE int_type_hst SET int_type_hst = 'Genetic_interaction' WHERE int_type_hst = 'Genetic' ;

 remove :
 int_transgeneonegene
 int_transgenetwogene

