#!/usr/bin/perl -w
#
# dump flatfile of cgc - pmid - journal for eimear  2002 12 23

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_eimear/cgc_pmid_journal_dump/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";


my %pmids;
my %pmid_in_xref;

my $result = $conn->exec( "SELECT * FROM ref_xref;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    my $result2 = $conn->exec( "SELECT * FROM ref_journal WHERE joinkey = '$row[0]';" );
#     $pmid_in_xref{$row[1]}++;
    my @row2 = $result2->fetchrow;
    print OUT "$row[0]\t$row[1]\t$row2[1]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# $result = $conn->exec( "SELECT * FROM ref_pmid;");
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $pmids{$row[0]} = $row[2];
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)
# 
# my %pmids_without_xref;
# 
# foreach my $pmid (sort keys %pmids) {
#   unless ($pmid_in_xref{$pmid}) { $pmids_without_xref{$pmid} = $pmids{$pmid}; }
# } # foreach my $pmid (sort keys %pmids)
# 
# my @pmids_without_xref = keys %pmids_without_xref;
# my %sorted_pmid_output;
# 
# print "COUNT : " . scalar(@pmids_without_xref) . ".\n";
# 
# # foreach (sort keys %pmids_without_xref) { print "$_ : $pmids{$_}\n"; }
# foreach (sort keys %pmids_without_xref) { push @{ $sorted_pmid_output{$pmids_without_xref{$_}} }, $_; }
# 
# foreach my $date (sort keys %sorted_pmid_output) {
#   foreach (@{ $sorted_pmid_output{$date} }) { 
#     print "$date\t$_\n"; 
#   }
# } # foreach (sort keys %sorted_pmid_output)




close (OUT) or die "Cannot close $outfile : $!";
