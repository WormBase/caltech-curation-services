#!/usr/bin/perl -w

# populate app_ tables based on alp_ tables.  
# Drop and Create the tables and indices with psql -e testdb < app_tables
# Then copy the data with perl.  2007 05 03
#
# added obj_remark table.  2007 08 22
#
# added obj_remark table to the actual table list in app_tables.
# added paper_remark table (DIFFERENT)  2007 08 28
#
# starting over again with unique ID tables and shadow tables.  2008 01 16
#
# prepopulate curation_status with alp_paper papers as happy, and if any from
# alp_finished exist with timestamp use that instead.  2008 03 05
#
# Create a -D file for what's being inserted.  2008 10 12
#
# Updated for a new .ace file to append to postgres.  If doing this again, be
# careful that data isn't overwritten when it should be appended in doing the
# UPDATEs (like papers that only have 1 new paper when the table/joinkey already
# has many papers).  2008 11 03
#
# Update for a new .ace file.  This .ace file is in dos format, so had to read
# it all in and split into paragraphs instead of reading para by para.  Also,
# Wen wants them all to be new entries, even though maIs134 was already in there
# (don't overwrite it).  2009 02 13

use strict;
use diagnostics;
use Pg;
use LWP::Simple;
use Jex;	# &getPgDate();

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


# name
# summary
# driven_by_gene
# reporter_product
# other_reporter
# gene
# integrated_by
# particle_bombardment
# strain
# map
# map_paper
# map_person
# marker_for
# marker_for_paper
# reference
# remark
# species
# synonym
# driven_by_construct
# location
# movie
# picture
# 
# obo :
# integrated_by	Gamma_ray	X_ray	Spontaneous	UV	Particle_bombardment	Not_integrated
# 
# list :
# reporter_product	GFP	LacZ
# map	I	II	III	IV	V	X


my @tables = qw( name summary driven_by_gene reporter_product other_reporter gene integrated_by particle_bombardment strain map map_paper map_person marker_for marker_for_paper reference remark species synonym driven_by_construct location movie picture );
my %tables;
my %unused_tag;

# my $outfile = 'delete.ace';
# open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $table (@tables) { 
# don't recreate the tables.
#   &createTable($table); 
  $tables{$table}++; }

my $high_joinkey = 0; my %names; my $joinkey;
my $result = $conn->exec( "SELECT * FROM trp_name" );
while (my @row = $result->fetchrow) { 
  if ($row[0] > $high_joinkey) { $high_joinkey = $row[0]; } 
  $names{$row[1]} = $row[0];
} # while (my @row = $result->fetchrow) 
# my $infile = 'WS196Tg.ace';
# my $infile = 'NewTgforPostgres20081103.txt';
my $infile = 'WBP32329.ace';
# $/ = "";
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $all_file = <IN>;
close (IN) or die "Cannot close $infile : $!";
$all_file =~ s///g;
my (@paras) = split/\n\n/, $all_file;
# while (my $para = <IN>) {
# } # while (my $para = <IN>)
foreach my $para (@paras) {
  next unless ($para =~ m/Transgene\s+:\s+/);
  $para =~ s///g;
  ($para) =~ s/\/\/.*?\n/\n/g;
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my %data;
  my ($name) = $header =~ m/Transgene\s+:\s+\"(.*?)\"/;
# IN THIS CASE ONLY FOR WEN, ENTER DATA AS NEW OBJECTS 2009 02 13
  $high_joinkey++; $joinkey = $high_joinkey;
#   if ($names{$name}) { $joinkey = $names{$name}; }
#     else { $high_joinkey++; $joinkey = $high_joinkey; }
#   print OUT "$header\n";
  $data{'name'}{$name}++;
  foreach my $line (@lines) {
    next unless ($line);
    my ($tag, $data) = $line =~ m/^(\w+)\s+(.*)$/;
    unless ($tag) { print "BAD LINE $line\n"; }
    if ($tag eq 'LacZ') { $data = $tag; $tag = 'reporter_product'; }
    elsif ($tag eq 'GFP') { $data = $tag; $tag = 'reporter_product'; }
    elsif ($tag eq 'Gamma_ray') { $data = $tag; $tag = 'integrated_by'; }
    elsif ($tag eq 'X_ray') { $data = $tag; $tag = 'integrated_by'; }
    elsif ($tag eq 'Spontaneous') { $data = $tag; $tag = 'integrated_by'; }
    elsif ($tag eq 'UV') { $data = $tag; $tag = 'integrated_by'; }
    elsif ($tag eq 'Particle_bombardment') { $data = $tag; $tag = 'integrated_by'; }
    elsif ($tag eq 'Not_integrated') { $data = $tag; $tag = 'integrated_by'; }
    ($tag) = lc($tag);
    if ($tag eq 'marker_for') {
      ($data, my $data2) = $data =~ m/\"(.*?)\"\s+Paper_evidence\s+\"(.*?)\"/;
      $data{'marker_for_paper'}{$data2}++; }
    elsif ($tag eq 'map') { ($data) = $data =~ m/^\"(.*?)\"/; }
    elsif ($tag eq 'map_evidence') {
      if ($data =~ m/Paper_evidence \"(.*?)\"/) { $tag = 'map_paper', $data = $1; }
      elsif ($data =~ m/Person_evidence \"(.*?)\"/) { $tag = 'map_person', $data = $1; } }
#     if ($tables{$tag}) { print OUT "-D $line\n"; }
# #       else { print OUT "\\\\ -D $line\n"; }
    next unless ($data);
    if ($data =~ m/^\"/) { $data =~ s/^\"//g; } if ($data =~ m/\"$/) { $data =~ s/\"$//g; }
    $data{$tag}{$data}++;
  } # foreach my $line (@lines)
  foreach my $tag (sort keys %data) {
    my $pgcommand = '';
#     foreach my $data (sort keys %{ $data{$tag} }) { print "$name T $tag D $data E\n"; }
    unless ($tables{$tag}) { $unused_tag{$tag}++; next; }
    my $data = '';
    if ( ($tag eq 'reporter_product') || ($tag eq 'map') ) {
        my @data = keys %{ $data{$tag} }; $data = join"\",\"", @data;
        if ($data =~ m/\"/) { $data = "\"$data\""; }
        ($data) = &filterForPostgres($data); }
      else {
        my @data = keys %{ $data{$tag} }; $data = join" | ", @data;
        $data =~ s/^\\"//; $data =~ s/\\"$//; $data =~ s/\| \\"/\| /g; $data =~ s/\\" \|/ \|/g;
        ($data) = &filterForPostgres($data); }
# IN THIS CASE ONLY FOR WEN, ENTER DATA AS NEW OBJECTS 2009 02 13
    $pgcommand = "INSERT INTO trp_$tag VALUES ('$joinkey', '$data'); "; 
#     $result = $conn->exec( "SELECT * FROM trp_$tag WHERE joinkey = '$joinkey'");
#     my @row = $result->fetchrow();  
#     if ($row[1]) {
#         if ($row[1] eq $data) { print "// SKIP $joinkey $data had $row[1]\n"; }
#           else { 
#             if ( ($tag =~ m/reference/) || ($tag =~ m/marker_for_paper/) ) { $data = "$row[1] | $data"; }
#             $pgcommand = "UPDATE trp_$tag SET trp_$tag = '$data' WHERE joinkey = '$joinkey'"; } }
#       else { $pgcommand = "INSERT INTO trp_$tag VALUES ('$joinkey', '$data'); "; }
    print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#     $result = $conn->exec( "$pgcommand");
    $pgcommand = "INSERT INTO trp_${tag}_hst VALUES ('$joinkey', '$data'); ";
    print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#     $result = $conn->exec( "$pgcommand");
  } # foreach my $tag (sort keys %tag)
  print "\n";
#   print OUT "\n";
} # foreach my $para (@paras) 
# close (IN) or die "Cannot close $infile : $!";
# close (OUT) or die "Cannot close $outfile : $!";

foreach my $tag (sort keys %unused_tag) { print "Unsaved tag : $tag\n"; }


sub createTable {
  my $table = shift;
  my $result = $conn->exec( "DROP TABLE trp_${table}_hst;" );
  $result = $conn->exec( "CREATE INDEX trp_${table}_idx ON trp_$table USING btree (joinkey); ");
  $result = $conn->exec( "CREATE TABLE trp_${table}_hst (
    joinkey text, 
    trp_${table}_hst text,
    trp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE trp_${table}_hst FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE trp_${table}_hst TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE trp_${table}_hst TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE trp_${table}_hst TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE trp_${table}_hst TO azurebrd; ");
  $result = $conn->exec( "CREATE INDEX trp_${table}_hst_idx ON trp_${table}_hst USING btree (joinkey); ");

  $result = $conn->exec( "DROP TABLE trp_$table;" );
  $result = $conn->exec( "CREATE TABLE trp_$table (
    joinkey text, 
    trp_$table text,
    trp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE trp_$table FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE trp_$table TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE trp_$table TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE trp_$table TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE trp_$table TO azurebrd; ");
}


sub filterForPostgres {
  my $data = shift;
  if ($data) { if ($data =~ m/\\;/) { $data =~ s/\\;/;/g; } }
  if ($data) { if ($data =~ m/\\%/) { $data =~ s/\\%/%/g; } }
  if ($data) { if ($data =~ m/\\\//) { $data =~ s/\\\//\//g; } }
  if ($data) { if ($data =~ m/'/) { $data =~ s/'/''/g; } }
  if ($data) { if ($data =~ m/^\s+/) { $data =~ s/^\s+//g; } }
  if ($data) { if ($data =~ m/\s+$/) { $data =~ s/\s+$//g; } }
  return $data;
} # sub filterForPostgres


__END__ 

sub popUns {
  my ($joinkey, $table) = @_;
  foreach my $time (sort keys %{ $uns{$joinkey}{$table}{history} }) {
    my $data = $uns{$joinkey}{$table}{history}{$time};
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n";
    my $result = $conn->exec( $command2 ); } 
  if ($table eq 'curation_status') {	# only put normal table data for curation_status
    my $data = $uns{$joinkey}{$table}{latest}{data};
    my $time = $uns{$joinkey}{$table}{latest}{time};
    return unless ($time && $data);
    my $command = "INSERT INTO app_$table VALUES ('$joinkey', '$data', '$time');";
    print "$command\n";
    my $result = $conn->exec( $command ); } }
sub popGen {
  my ($joinkey, $tempname, $table) = @_;
  my $data = $alp{$tempname}{$table}{latest}{data};
  my $time = $alp{$tempname}{$table}{latest}{time};
  return unless ($time && $data);
  my $command = "INSERT INTO app_$table VALUES ('$joinkey', '$data', '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history} }) {
    $data = $alp{$tempname}{$table}{history}{$time};
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n";
    my $result = $conn->exec( $command2 ); } }
sub popGroup {
  my ($joinkey, $tempname, $table, $box) = @_;
  my $table_name = $table; 
  if ($table eq 'phenotype') { $table_name = 'nbp'; }
  if ($table eq 'preparation') { $table_name = 'treatment'; }
  next if ($table eq 'finished');	# this was put in uns curation_status
  my $data = $alp{$tempname}{$table}{latest}{$box}{data};
  if ($table eq 'paper') { $data = &paperFilt($data); }
  elsif ($table eq 'person') { $data = &personFilt($data); }
  my $time = $alp{$tempname}{$table}{latest}{$box}{time};
  return unless ($time && $data);
  my $command = "INSERT INTO app_$table_name VALUES ('$joinkey', '$data', '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box} }) {
    $data = $alp{$tempname}{$table}{history}{$box}{$time};
    if ($table eq 'paper') { $data = &paperFilt($data); }
    elsif ($table eq 'person') { $data = &personFilt($data); }
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table_name}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n";
    my $result = $conn->exec( $command2 ); } }
sub popMult {
  my ($joinkey, $tempname, $table, $box, $col) = @_;
  my $data = $alp{$tempname}{$table}{latest}{$box}{$col}{data};
  if ($table eq 'term') { $data = &termFilt($data, 'real', $tempname); }
  elsif ($table eq 'anat_term') { $data = &anatFilt($data, 'real', $tempname); }
  elsif ($table eq 'lifestage') { $data = &lsFilt($data, 'real', $tempname); }
  elsif ($table eq 'curator') { $data = &curatorFilt($data, 'real', $tempname); }
  elsif ($table eq 'nature') { $data = &natureFilt($data, 'real', $tempname); }
  elsif ($table eq 'func') { $data = &funcFilt($data, 'real', $tempname); }
  elsif ($table eq 'penetrance') { $data = &penetranceFilt($data, 'real', $tempname); }
  elsif ($table eq 'mat_effect') { $data = &mat_effectFilt($data, 'real', $tempname); }
  my $time = $alp{$tempname}{$table}{latest}{$box}{$col}{time};
  return unless ($time && $data);
  if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
#   if ($time) { $time = "'$time'"; } else { $time = 'CURRENT_TIMESTAMP'; }
  unless ($time) { print "NO TIME $table $tempname $box $col\n"; }
  my $command = "INSERT INTO app_$table VALUES ('$joinkey', $data, '$time');";
  print "$command\n";
  my $result = $conn->exec( $command );
  foreach $time (sort keys %{ $alp{$tempname}{$table}{history}{$box}{$col} }) {
    $data = $alp{$tempname}{$table}{history}{$box}{$col}{$time};
    if ($table eq 'term') { $data = &termFilt($data, 'hist'); }
    elsif ($table eq 'anat_term') { $data = &anatFilt($data, 'hist'); }
    elsif ($table eq 'lifestage') { $data = &lsFilt($data, 'hist'); }
    elsif ($table eq 'curator') { $data = &curatorFilt($data, 'hist'); }
    elsif ($table eq 'nature') { $data = &natureFilt($data, 'hist'); }
    elsif ($table eq 'func') { $data = &funcFilt($data, 'hist'); }
    elsif ($table eq 'penetrance') { $data = &penetranceFilt($data, 'hist'); }
    elsif ($table eq 'mat_effect') { $data = &mat_effectFilt($data, 'hist'); }
    if ($data) { $data = "'$data'"; } else { $data = 'NULL'; }
    my $command2 = "INSERT INTO app_${table}_hst VALUES ('$joinkey', $data, '$time');";
    print "$command2\n"; 
    my $result = $conn->exec( $command2 ); } }

