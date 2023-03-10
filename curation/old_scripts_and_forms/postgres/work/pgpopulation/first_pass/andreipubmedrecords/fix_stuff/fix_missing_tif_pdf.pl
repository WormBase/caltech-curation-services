#!/usr/bin/perl -w

# read data from postgresql, store already in into a hash.  read new data from asn1 
# file; parse and print to errorfile if errors or already in pg database.  2002 05 22
#
# added ref_comment for endnoter.cgi 2002 06 25

use strict;
use diagnostics;
use Fcntl;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

  # connect to the testdb database
my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pgPmid;			# hash of pmids already in pg
my %pgRefTifPdf;		# hash of pmids with ref_tif_pdf

&populatePgPmid();
&populatePgTifPdf();

sub populatePgPmid {
  my $result = $conn->exec( "SELECT ref_pmid FROM ref_pmid");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { my $key = 'pmid' . $row[0]; $pgPmid{$key}++; }
  } # while (my @row = $result->fetchrow)
} # sub populatePgPmid

sub populatePgTifPdf {
  my $result = $conn->exec( "SELECT joinkey FROM ref_tif_pdf");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $pgRefTifPdf{$row[0]}++; }
  } # while (my @row = $result->fetchrow)
} # sub populatePgTifPdf

foreach my $pmid (sort keys %pgPmid) {
#   unless ($pgRefTifPdf{$pmid}) { print "$pmid\n"; }
  unless ($pgRefTifPdf{$pmid}) { 
    my $result = $conn->exec( "INSERT INTO ref_tif_pdf VALUES (\'$pmid\', NULL);" );
  } # unless ($pgRefTifPdf{$pmid})
} # foreach my $pmid (sort keys %pgPmid)
