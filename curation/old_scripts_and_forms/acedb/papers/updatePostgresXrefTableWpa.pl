#!/usr/bin/perl

# This reads the .ace dump from cgc_from_2005-05-28_to_2005-06-14.27989.ace
# (created by abstract2aceCGC.pl), gets the WBPaper to PMID connections, and
# writes them to the wpa_xref postgres table.  Uncomment INSERT for live run.
# This is only for this batch, which only had PMID data.  Something else 
# should be written for when all citace is in wpa_ tables.  2005 06 14

use strict;
use diagnostics;
use Jex;
use Pg;

my $input_file = 'cgc_from_2005-05-28_to_2005-06-14.27989.ace';

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

$/ = '';
open(IN, "<$input_file") or die "Cannot open $input_file : $!";
while (my $entry = <IN>) {
  my $wbp = '';
  my $pmid = '';
  if ($entry =~ m/Paper\t\"(WBPaper.*?)\"/) { $wbp = $1; }
  if ($entry =~ m/PMID\t\"(\d+)\"/) { $pmid = 'pmid' . $1; }
  if ( ($pmid) && ($wbp) ) { 
# UNCOMMENT THIS FOR LIVE RUN
#     my $result = $conn->exec( "INSERT INTO wpa_xref VALUES ('$wbp', '$pmid');" );
    print "$wbp\t$pmid\n"; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $input_file : $!";

# my $result = $conn->exec( "SELECT * FROM one_groups;" );
# while (my @row = $result->fetchrow) {
#   if ($row[0]) { 
#     $row[0] =~ s///g;
#     $row[1] =~ s///g;
#     $row[2] =~ s///g;
#     print "$row[0]\t$row[1]\t$row[2]\n";
#   } # if ($row[0])
# } # while (@row = $result->fetchrow)

