#!/usr/bin/perl -w
#
# Find the pmids without xref (to cgc) from postgres for Eimear
# and sort by batches of dates.  2002 12 18
#
# Also output the reference data to another file.  2003 01 10
# Also output the ref_xref table and journals for each entry.  2003 01 10
# Also back up the list file.
# Also get the listfile from the last run and compare it to ref_xref
# and print out stuff that has new cgcs.  2003 02 10


use strict;
use diagnostics;
use Pg;
use Jex;	# getSimpleDate

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $listfile = "/home/postgres/work/get_stuff/for_eimear/pmids_without_cgcxref/listfile";
my $listoldfile = "/home/postgres/work/get_stuff/for_eimear/pmids_without_cgcxref/listoldfile";
my $reffile = "/home/postgres/work/get_stuff/for_eimear/pmids_without_cgcxref/reffile";
my $xreffile = "/home/postgres/work/get_stuff/for_eimear/pmids_without_cgcxref/xreffile";

my %oldpmid;			# pmids w/o cgc from previous run
&getOldPmidList();		# get the pmids w/o cgc from previous run

open(LIS, ">$listfile") or die "Cannot create $listfile : $!";
open(REF, ">$reffile") or die "Cannot create $reffile : $!";
open(XRF, ">$xreffile") or die "Cannot create $xreffile : $!";

# print OUT "GENE FUNCTION\n\n";

my %pmids;
my %pmid_in_xref;		# key pmid, val cgc

my $result = $conn->exec( "SELECT * FROM ref_xref;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;			# cgc
    $row[1] =~ s///g;			# pmid
    $pmid_in_xref{$row[1]} = $row[0];	# key pmid, val cgc
  } # if ($row[0])
} # while (@row = $result->fetchrow)

$result = $conn->exec( "SELECT * FROM ref_pmid;");
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $pmids{$row[0]} = $row[2];
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my %pmids_without_xref;

foreach my $pmid (sort keys %pmids) {
  unless ($pmid_in_xref{$pmid}) { $pmids_without_xref{$pmid} = $pmids{$pmid}; }
} # foreach my $pmid (sort keys %pmids)

my @pmids_without_xref = keys %pmids_without_xref;
my %sorted_pmid_output;

print "COUNT : " . scalar(@pmids_without_xref) . ".\n";

# foreach (sort keys %pmids_without_xref) { print "$_ : $pmids{$_}\n"; }
foreach (sort keys %pmids_without_xref) { push @{ $sorted_pmid_output{$pmids_without_xref{$_}} }, $_; }

foreach my $date (sort keys %sorted_pmid_output) {
  foreach my $pmid (@{ $sorted_pmid_output{$date} }) { 
    print LIS "$date\t$pmid\n"; 
    &getRef($pmid);
  }
} # foreach (sort keys %sorted_pmid_output)

&getXref();
&checkPmidsWithNewXref();

close (LIS) or die "Cannot close $listfile : $!";
close (REF) or die "Cannot close $reffile : $!";
close (XRF) or die "Cannot close $xreffile : $!";

&backupListfile();

sub checkPmidsWithNewXref {
  open (OLD, ">$listoldfile") or die "Cannot create $listoldfile : $!";
  foreach my $old_pmid (sort keys %oldpmid) {
    if ($pmid_in_xref{$old_pmid}) { print OLD "$old_pmid\t$pmid_in_xref{$old_pmid}\n"; }
  } # foreach my $old_pmid (sort keys %oldpmid)
  close (OLD) or die "Cannot close $listoldfile : $!";
} # sub checkPmidsWithNewXref

sub backupListfile {		# copy listfile in case it gets overwritten
  my $date = &getSimpleDate();
#   print "DATE $date\n";
  `cp listfile listfile.$date`;
} # sub backupListfile


sub getXref {
  my $result = $conn->exec( "SELECT * FROM ref_xref ORDER BY ref_cgc;");
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      print XRF "$row[0]\t$row[1]";
      my $result2 = $conn->exec( "SELECT * FROM ref_journal WHERE joinkey = '$row[0]';");
      while (my @row2 = $result2->fetchrow) {
        if ($row2[1]) { print XRF "\t$row2[1]"; }
      }
      print XRF "\n";
    } # if ($row[1])
  } # while (my @row = $result->fetchrow)
} # sub getXref

sub getRef {
  my $pmid = shift;
  my @fields = qw(title author journal volume pages year abstract);
  print REF "$pmid";
  foreach my $field (@fields) {
    $field = 'ref_' . $field;
    my $result = $conn->exec( "SELECT * FROM $field WHERE joinkey = '$pmid';");
    my $out = '';
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
        $row[1] =~ s///g;
#         $row[1] =~ s// /g;
        $row[1] =~ s/\n//g;
        $out = $row[1];
      } # if ($row[0])
    } # while (@row = $result->fetchrow)
    print REF "\t$out";
  } # foreach my $field (@fields)
  print REF "\n";
} # sub getRef

sub getOldPmidList {
  open(LIS, "<$listfile") or die "Cannot create $listfile : $!";
  while (<LIS>) { 
    chomp;
    my ($junk, $pmid) = split/\t/, $_;
    $oldpmid{$pmid}++;
  }
  close (LIS) or die "Cannot close $listfile : $!";
} # sub getOldPmidList
