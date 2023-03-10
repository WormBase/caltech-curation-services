#!/usr/bin/perl -w
#
# check which one entries merge ace entries (and will need to make sure i don't
# break stuff dealing with it)

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result = $conn->exec( "SELECT * FROM got_cell_curator_evidence WHERE got_cell_curator_evidence ~ 'Josh';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    if ($row[2]) { if ($row[2] =~ m//) { $row[2] =~ s///g; } }
    my $join = $row[0]; my $order = $row[1];
    my $result2 = $conn->exec( "SELECT got_cell_goid FROM got_cell_goid WHERE joinkey = '$join' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
    my @row2 = $result2->fetchrow; my $goid = $row2[0];
    $result2 = $conn->exec( "SELECT got_cell_goterm FROM got_cell_goterm WHERE joinkey = '$join' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
    @row2 = $result2->fetchrow; my $goterm = $row2[0];
    print "Gene $join GOID $goid GOTERM $goterm\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# my %genes;
# my @stuff = qw(got_bio got_mol got_cell);
# foreach my $table (@stuff) {
#   my $result = $conn->exec( "SELECT * FROM ${table}_curator_evidence ORDER BY got_timestamp;" );
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { 
#       $row[0] =~ s///g;
#       $row[1] =~ s///g;
#       if ($row[2]) { if ($row[2] =~ m//) { $row[2] =~ s///g; } }
#       $genes{$table}{$row[0]}{$row[1]} = $row[2];
#     } # if ($row[0])
#   } # while (@row = $result->fetchrow)
# } # foreach my $table (@stuff)

# my %bad_genes;
# foreach my $table (@stuff) {
#   foreach my $gene (sort keys %{ $genes{$table} }) {
#     foreach my $order (sort keys %{ $genes{$table}{$gene} }) {
#       unless ($genes{$table}{$gene}{$order}) { 
#         my $result = $conn->exec( "SELECT ${table}_goid FROM ${table}_goid WHERE joinkey = '$gene' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
#         my @row = $result->fetchrow;
#         my $goid = $row[0];
#         $result = $conn->exec( "SELECT ${table}_goterm FROM ${table}_goterm WHERE joinkey = '$gene' AND got_order = '$order' ORDER BY got_timestamp DESC;" );
#         my @row = $result->fetchrow;
#         my $goterm = $row[0];
#         print "G $gene T $table O $order GOID $goid GOTERM $goterm\n";
#       } # unless ($genes{$table}{$gene}{$order})
#     } # foreach my $order (sort keys %{ $genes{$gene} })
#   } # foreach my $gene (sort keys %genes)
# } # foreach my $table (@stuff)
