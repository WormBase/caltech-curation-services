#!/usr/bin/perl -w

# query data from multiple tables used by concise description cgi and move 
# into new tables, storing the column (order) number into the tables themselves.
# this allows any number of columns instead of just one column per table.
# (which requires creating more tables).  also move car_concise into car_con_maindata,
# car_con_curator into car_con_ref_curator, car_con_ref1 into car_con_ref_paper, etc.
# (these are the tables without car_order, see newtables file)  2004 07 20
#
# Took 18 mins to copy data to new tables up to 2004-08-18 15:00:00  2004 08 18
#
# Took 15 secs to copy data to new tables between 2004-08-18 15:00:00 and 2004-09-09
# 16:00:00   2004 09 09

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @ontology = qw( bio cell mol );
my @column_types = qw( goterm goid paper_evidence person_evidence goinference dbtype with qualifier goinference_two dbtype_two with_two qualifier_two similarity comment );
my $max_columns = 8;

my %theHash;

my $result = $conn->exec( "SELECT * FROM got_curator;" );
my @allkeys;
while (my @row=$result->fetchrow) { push @allkeys, $row[0]; }

foreach my $ontology (@ontology) {          # loop through each of three ontology types
  foreach my $column_type (@column_types) {
    for my $i (1 .. $max_columns) {         # loop through each column allowed
      my $type = $ontology . '_' . $column_type . $i;
      my $result = $conn->exec( "SELECT * FROM got_$type WHERE got_timestamp > '2004-09-09 16:00:00';" );
#       my $result = $conn->exec( "SELECT * FROM got_$type WHERE got_timestamp > '2004-08-18 15:00:00';" );
#       my $result = $conn->exec( "SELECT * FROM got_$type;" );
      while (my @row=$result->fetchrow) { 
        if ($row[1]) { 
          if ($row[1] =~ m/ --/) { $row[1] =~ s/ --.*$//g; }
#           if ($row[0] !~ m/[a-zA-Z]/) { print "ERR ONT $ontology\tCOL $column_type\tI $i\tJOIN $row[0]\tVAL $row[1]\tTIME $row[2]\n"; next; }
          if ($row[0] !~ m/[a-zA-Z]/) { next; }
          $theHash{$ontology}{$column_type}{$i} = $row[1];
	  $row[1] =~ s///g; $row[1] =~ s/\s+$//; $row[1] =~ s/^\s+//; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
          my $pgtable = 'got_' . $ontology . '_' . $column_type;
	  my $command = "INSERT INTO $pgtable VALUES ('$row[0]', $i, '$row[1]', '$row[2]');"; 
          print OUT "$command\n";
# Uncomment this to update into postgres.
          my $result2 = $conn->exec( "INSERT INTO $pgtable VALUES ('$row[0]', $i, '$row[1]', '$row[2]');");
          print "ONT $ontology\tCOL $column_type\tI $i\tJOIN $row[0]\tVAL $row[1]\tTIME $row[2]\n"; 
      } }
    } } }
 



# my @values_in_pg = qw( WBGene00006697 WBGene00006714 WBGene00006719 WBGene00006725 WBGene00006816 );
# 
# my %wbgenes;
# my @categories = qw( ort gen phy exp oth );
# foreach my $joinkey ( @values_in_pg ) {
#   foreach my $cat (@categories) {
#     for my $i (1 .. 6) {                                # six is max amount, some have less but won't have box checked
#       my $field = 'car_' . $cat . $i;
#       my @types = ( '', '_curator', '_ref1' );
#       foreach my $type (@types) {
#         my $pg_table = $field . $type;
#         my $result = $conn->exec( "SELECT * FROM $pg_table WHERE joinkey = '$joinkey';" );
#         while (my @row = $result->fetchrow) {
#           if ($row[0]) { 
#             $row[0] =~ s///g;
#             $row[1] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
#             $row[2] =~ s///g;
#             my $newtype = ''; my $newcat;
#             if ($cat eq 'ort') { $newcat = 'seq'; }
#             elsif ($cat eq 'gen') { $newcat = 'fpa'; }
#             elsif ($cat eq 'phy') { $newcat = 'fpi'; }
#             elsif ($cat eq 'exp') { $newcat = 'exp'; }
#             elsif ($cat eq 'oth') { $newcat = 'oth'; }
#             else { print "ERROR bad CAT $cat $joinkey $pg_table\n"; }
#             if ($type eq '') { $newtype = '_maindata'; }
#             elsif ($type eq '_curator') { $newtype = '_ref_curator'; }
#             elsif ($type eq '_ref1') { $newtype = '_ref_paper'; }
#             else { print "ERROR bad TYPE $type $joinkey $pg_table\n"; }
#             print OUT "INSERT INTO car_$newcat$newtype VALUES ('$joinkey', $i, '$row[1]', '$row[2]');\n";
#             my $result2 = $conn->exec( "INSERT INTO car_$newcat$newtype VALUES ('$joinkey', $i, '$row[1]', '$row[2]');" );
#             $wbgenes{$row[0]}++; } }
# } } } }
# 
# my $result = $conn->exec( "SELECT * FROM car_concise WHERE joinkey != 'WBGene00000000';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
#     my $result2 = $conn->exec( "INSERT INTO car_con_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');" );
#     print OUT "INSERT INTO car_con_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
# $result = $conn->exec( "SELECT * FROM car_con_curator WHERE joinkey != 'WBGene00000000';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
#     my $result2 = $conn->exec( "INSERT INTO car_con_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');" );
#     print OUT "INSERT INTO car_con_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
# $result = $conn->exec( "SELECT * FROM car_con_ref1 WHERE joinkey != 'WBGene00000000';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
#     my $result2 = $conn->exec( "INSERT INTO car_con_ref_paper VALUES ('$row[0]', '$row[1]', '$row[2]');" );
#     print OUT "INSERT INTO car_con_ref_paper VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
# $result = $conn->exec( "SELECT * FROM car_ext_curator WHERE joinkey != 'WBGene00000000';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
#     my $result2 = $conn->exec( "INSERT INTO car_ext_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');" );
#     print OUT "INSERT INTO car_ext_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
# $result = $conn->exec( "SELECT * FROM car_ext_curator WHERE joinkey != 'WBGene00000000';" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
#     my $result2 = $conn->exec( "INSERT INTO car_ext_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');" );
#     print OUT "INSERT INTO car_ext_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }


