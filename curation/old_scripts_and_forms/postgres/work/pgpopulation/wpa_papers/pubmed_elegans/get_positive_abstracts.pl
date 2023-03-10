#!/usr/bin/perl -w

# get the set of positives of searching pubmed for ``elegans'' with publication > 2002-07-01
# by looking at our set of abstracts with PMIDs.  2009 01 28

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %pm;
my $highest = 0;

my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
while (my @row = $result->fetchrow) {
  my ($pmid) = $row[1] =~ m/pmid *(\d+)/;
  unless ($pmid) { print "BAD @row\n"; }
  my $abstract = '';
  my $result2 = $conn->exec( "SELECT * FROM cur_comment WHERE joinkey = '$row[0]';" );
  my @row2 = $result2->fetchrow;
  next if ($row2[1] =~ m/functional annotations/);
  while (@row2 = $result2->fetchrow) { if ($row2[3] eq 'valid') { $abstract = $row2[1]; } else { $abstract = ''; } }
  $result2 = $conn->exec( "SELECT * FROM wpa_abstract WHERE joinkey = '$row[0]' ORDER BY wpa_timestamp;" );
  while (my @row2 = $result2->fetchrow) { if ($row2[3] eq 'valid') { $abstract = $row2[1]; } else { $abstract = ''; } }
  if ($abstract) { print "PMID : $pmid\nABSTRACT : $abstract\n\n"; }
} # while (@row = $result->fetchrow)


__END__

