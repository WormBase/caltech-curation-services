#!/usr/bin/perl -w

# populate abp_ tables based on Antibody data from citace.  2009 01 06

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

# Summary ""
# Gene    ""
# Clonality       Polyclonal/Monoclonal
# Animal          Rabbit/Mouse/Rat/Guinea_pig/Chicken/Goat/Other_animal
# Antigen         Peptide/Protein/Other_antigen
# Peptide         ""
# Protein         ""
# Source          Original_publication/No_original_publication
# Original_publication    ""
# Reference   ""
# Remark      ""
# Other_name  ""
# Location    ""
# Other_animal    ""
# Other_antigen   ""
# Possible_pseudonym      ""




my @tables = qw( name summary gene clonality animal antigen peptide protein source original_publication reference remark other_name location other_animal other_antigen possible_pseudonym );
my %tables;
my %unused_tag;

my $outfile = 'delete.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $table (@tables) { 
# don't recreate the tables.
#   &createTable($table); 
  $tables{$table}++; }

my $high_joinkey = 0; my %names; my $joinkey;
my $result = $conn->exec( "SELECT * FROM abp_name" );
while (my @row = $result->fetchrow) { 
  if ($row[0] > $high_joinkey) { $high_joinkey = $row[0]; } 
  $names{$row[1]} = $row[0];
} # while (my @row = $result->fetchrow) 
# my $infile = 'WS196Tg.ace';
# my $infile = 'NewTgforPostgres20081103.txt';
# my $infile = 'WS199Ab.ace';
my $infile = 'WS200Ab.ace';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  next unless ($para =~ m/Antibody\s+:\s+/);
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  my %data;
  my ($name) = $header =~ m/Antibody\s+:\s+\"(.*?)\"/;
  if ($names{$name}) { $joinkey = $names{$name}; }
    else { $high_joinkey++; $joinkey = $high_joinkey; }
  print OUT "$header\n";
  $data{'name'}{$name}++;
  foreach my $line (@lines) {
    my ($tag, $data) = $line =~ m/^(\w+)\s+(.*)$/;
    if ($tag eq 'Polyclonal') { $data = $tag; $tag = 'clonality'; }
    elsif ($tag eq 'Monoclonal') { $data = $tag; $tag = 'clonality'; }
    elsif ($tag eq 'Rabbit') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Mouse') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Rat') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Guinea_pig') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Rabbit') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Chicken') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Goat') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Other_animal') { $data = $tag; $tag = 'animal'; }
    elsif ($tag eq 'Peptide') { $data{'antigen'}{$tag}++; }
    elsif ($tag eq 'Protein') { $data{'antigen'}{$tag}++; }
    elsif ($tag eq 'Other_antigen') { $data{'antigen'}{$tag}++; }
    elsif ($tag eq 'Original_publication') { $data{'source'}{$tag}++; }
    elsif ($tag eq 'No_original_reference') { $data = $tag; $tag = 'source'; }
    ($tag) = lc($tag);
    if ($tables{$tag}) { 
      my $tag2 = ucfirst($tag);
      print OUT "-D $tag2\n"; 	# delete tags, is that what Wen wants ?
      print OUT "-D $line\n"; }
    next unless ($data);
    if ($data =~ m/^\"/) { $data =~ s/^\"//g; } if ($data =~ m/\"$/) { $data =~ s/\"$//g; }
    $data{$tag}{$data}++;
  } # foreach my $line (@lines)
  foreach my $tag (sort keys %data) {
    my $pgcommand = '';
#     foreach my $data (sort keys %{ $data{$tag} }) { print "$name T $tag D $data E\n"; }
    unless ($tables{$tag}) { $unused_tag{$tag}++; next; }
    my $data = '';
    my @data = keys %{ $data{$tag} }; $data = join" | ", @data;
    $data =~ s/^\\"//; $data =~ s/\\"$//; $data =~ s/\| \\"/\| /g; $data =~ s/\\" \|/ \|/g;
    ($data) = &filterForPostgres($data);
    $result = $conn->exec( "SELECT * FROM abp_$tag WHERE joinkey = '$joinkey'");
    my @row = $result->fetchrow();  
    if ($row[1]) {
        if ($row[1] eq $data) { print "// SKIP $joinkey $data had $row[1]\n"; }
          else { 
            if ( ($tag =~ m/reference/) || ($tag =~ m/marker_for_paper/) ) { $data = "$row[1] | $data"; }
            $pgcommand = "UPDATE abp_$tag SET abp_$tag = '$data' WHERE joinkey = '$joinkey'"; } }
      else { $pgcommand = "INSERT INTO abp_$tag VALUES ('$joinkey', '$data'); "; }
    print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#     $result = $conn->exec( "$pgcommand");
    $pgcommand = "INSERT INTO abp_${tag}_hst VALUES ('$joinkey', '$data'); ";
    print "$pgcommand\n";
# UNCOMMENT TO POPULATE
#     $result = $conn->exec( "$pgcommand");
  } # foreach my $tag (sort keys %tag)
  print "\n";
  print OUT "\n";
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";

foreach my $tag (sort keys %unused_tag) { 
  next if ($tag eq 'expr_pattern');
  next if ($tag eq 'gene_regulation');
  next if ($tag eq 'possible_pseudonym_of');
  print "Unsaved tag : $tag\n"; }

# Created in citace by XREF, so don't account for
# Unsaved tag : Expr_pattern
# Unsaved tag : Gene_regulation
# Unsaved tag : Possible_pseudonym_of



sub createTable {
  my $table = shift;
  my $result = $conn->exec( "DROP TABLE abp_${table}_hst;" );
  $result = $conn->exec( "CREATE INDEX abp_${table}_idx ON abp_$table USING btree (joinkey); ");
  $result = $conn->exec( "CREATE TABLE abp_${table}_hst (
    joinkey text, 
    abp_${table}_hst text,
    abp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE abp_${table}_hst FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE abp_${table}_hst TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE abp_${table}_hst TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE abp_${table}_hst TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE abp_${table}_hst TO azurebrd; ");
  $result = $conn->exec( "CREATE INDEX abp_${table}_hst_idx ON abp_${table}_hst USING btree (joinkey); ");

  $result = $conn->exec( "DROP TABLE abp_$table;" );
  $result = $conn->exec( "CREATE TABLE abp_$table (
    joinkey text, 
    abp_$table text,
    abp_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $conn->exec( "REVOKE ALL ON TABLE abp_$table FROM PUBLIC; ");
  $result = $conn->exec( "GRANT SELECT ON TABLE abp_$table TO acedb; ");
  $result = $conn->exec( "GRANT ALL ON TABLE abp_$table TO apache; ");
  $result = $conn->exec( "GRANT ALL ON TABLE abp_$table TO cecilia; ");
  $result = $conn->exec( "GRANT ALL ON TABLE abp_$table TO azurebrd; ");
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


