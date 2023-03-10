#!/usr/bin/perl

# Routinely check all merged papers and populate wpa_remark to show which one it
# has been merged with.
# 0 3 * * wed /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/wpa_remark/populateMerged.pl
# Run on Wednesdays to coincide with the build.  2005 09 27
#
# I don't think we need this anymore, since papers that become obsolete have their data deleted 
# in the pap tables, so we wouldn't store anything in remark for these.  2010 06 23


use Jex;
use strict;
use LWP::Simple;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();

my %obsolete;
my %in_remark;

&mergedPapers();

my $result = $conn->exec( "SELECT * FROM wpa_remark WHERE wpa_remark ~ 'Obsolete' ORDER BY wpa_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    if ($row[3] eq 'valid') {
      if ($row[1] =~ m/^Obsolete.  Merged into WBPaper(\d{8})/) { $in_remark{$row[0]} = $1; } }
    else { delete $in_remark{$row[0]}; } }
} # while (@row = $result->fetchrow)

foreach my $rem_key (sort keys %obsolete) { 
  if ($in_remark{$rem_key}) { delete $obsolete{$rem_key}; delete $in_remark{$rem_key}; } }

my $logfile = '/home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/wpa_remark/logfile.' . $date;
open (LOG, ">$logfile") or die "Cannot create $logfile : $!";

foreach my $obs_key (sort keys %obsolete) { 
  print LOG "Add to Remark $obs_key $obsolete{$obs_key}\n";
  my $pgcommand = "INSERT INTO wpa_remark VALUES ('$obs_key', 'Obsolete.  Merged into WBPaper$obsolete{$obs_key}', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);";
  my $result = $conn->exec( "$pgcommand" );
  print LOG "$pgcommand\n\n"; 
}

foreach my $rem_key (sort keys %in_remark) { 
  print LOG "Delete from Remark $rem_key $in_remark{$rem_key}\n";
  my $pgcommand = "INSERT INTO wpa_remark VALUES ('$rem_key', 'Obsolete.  Merged into WBPaper$in_remark{$rem_key}', NULL, 'invalid', 'two1823', CURRENT_TIMESTAMP);";
  my $result = $conn->exec( "$pgcommand" );
  print LOG "$pgcommand\n\n"; 
}

close (LOG) or die "Cannot close $logfile : $!";


sub mergedPapers {                      # print out the merged paper connections
  my $page = get "http://tazendra.caltech.edu/~postgres/cgi-bin/merged_papers.cgi";
  my @lines = split /\n/, $page;
  foreach my $line (@lines) { 
    if ($line =~ m/^(\d{8})\s+is now\s+(\d{8})<BR>$/) { 
      $obsolete{$1} = $2; } }
} # sub mergedPapers

