#!/usr/bin/perl -w

# query data from multiple tables used by concise description cgi and move 
# into new tables, storing the column (order) number into the tables themselves.
# this allows any number of columns instead of just one column per table.
# (which requires creating more tables).  also move car_concise into car_con_maindata,
# car_con_curator into car_con_ref_curator, car_con_ref1 into car_con_ref_paper, etc.
# (these are the tables without car_order, see newtables file)  2004 07 20

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my @values_in_pg = qw( WBGene00006697 WBGene00006714 WBGene00006719 WBGene00006725 WBGene00006816 );

my %wbgenes;
my @categories = qw( ort gen phy exp oth );
foreach my $joinkey ( @values_in_pg ) {
  foreach my $cat (@categories) {
    for my $i (1 .. 6) {                                # six is max amount, some have less but won't have box checked
      my $field = 'car_' . $cat . $i;
      my @types = ( '', '_curator', '_ref1' );
      foreach my $type (@types) {
        my $pg_table = $field . $type;
        my $result = $conn->exec( "SELECT * FROM $pg_table WHERE joinkey = '$joinkey';" );
        while (my @row = $result->fetchrow) {
          if ($row[0]) { 
            $row[0] =~ s///g;
            $row[1] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
            $row[2] =~ s///g;
            my $newtype = ''; my $newcat;
            if ($cat eq 'ort') { $newcat = 'seq'; }
            elsif ($cat eq 'gen') { $newcat = 'fpa'; }
            elsif ($cat eq 'phy') { $newcat = 'fpi'; }
            elsif ($cat eq 'exp') { $newcat = 'exp'; }
            elsif ($cat eq 'oth') { $newcat = 'oth'; }
            else { print "ERROR bad CAT $cat $joinkey $pg_table\n"; }
            if ($type eq '') { $newtype = '_maindata'; }
            elsif ($type eq '_curator') { $newtype = '_ref_curator'; }
            elsif ($type eq '_ref1') { $newtype = '_ref_paper'; }
            else { print "ERROR bad TYPE $type $joinkey $pg_table\n"; }
            print OUT "INSERT INTO car_$newcat$newtype VALUES ('$joinkey', $i, '$row[1]', '$row[2]');\n";
            my $result2 = $conn->exec( "INSERT INTO car_$newcat$newtype VALUES ('$joinkey', $i, '$row[1]', '$row[2]');" );
            $wbgenes{$row[0]}++; } }
} } } }

my $result = $conn->exec( "SELECT * FROM car_concise WHERE joinkey != 'WBGene00000000';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
    my $result2 = $conn->exec( "INSERT INTO car_con_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');" );
    print OUT "INSERT INTO car_con_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
$result = $conn->exec( "SELECT * FROM car_con_curator WHERE joinkey != 'WBGene00000000';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
    my $result2 = $conn->exec( "INSERT INTO car_con_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');" );
    print OUT "INSERT INTO car_con_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
$result = $conn->exec( "SELECT * FROM car_con_ref1 WHERE joinkey != 'WBGene00000000';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
    my $result2 = $conn->exec( "INSERT INTO car_con_ref_paper VALUES ('$row[0]', '$row[1]', '$row[2]');" );
    print OUT "INSERT INTO car_con_ref_paper VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
$result = $conn->exec( "SELECT * FROM car_ext_curator WHERE joinkey != 'WBGene00000000';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
    my $result2 = $conn->exec( "INSERT INTO car_ext_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');" );
    print OUT "INSERT INTO car_ext_maindata VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }
$result = $conn->exec( "SELECT * FROM car_ext_curator WHERE joinkey != 'WBGene00000000';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g; $row[1] =~ s/\'/''/g; $row[1] =~ s/\"/\\\"/g;
    my $result2 = $conn->exec( "INSERT INTO car_ext_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');" );
    print OUT "INSERT INTO car_ext_ref_curator VALUES ('$row[0]', '$row[1]', '$row[2]');\n"; } }

# foreach my $wbgene (sort keys %wbgenes) {
#   print "GENE $wbgene\n"; }

