#!/usr/bin/perl -w

# look at all reference data for car_ tables by dates, and get number of unique
# papers for that date.  2005 10 21

use strict;
use diagnostics;
use Pg;
use LWP::Simple;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %xref;
my $paper_map = get "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref.cgi";
my @lines = split/\n/, $paper_map;
foreach my $line (@lines) {
  if ($line =~ m/^(WBPaper\d{8})\t(.*?)\<BR/) { $xref{$2} = $1; }
} # foreach my $line (@lines)

my @PGsubparameters = qw( con ext seq fpa fpi bio mol exp oth phe );

my @dates = (
'2004-10-08 00:00:01',
'2004-10-22 00:00:01',
'2004-11-12 00:00:01',
'2004-12-01 00:00:01',
'2005-01-19 00:00:01',
'2005-02-11 00:00:01',
'2005-03-03 00:00:01',
'2005-03-24 00:00:01',
'2005-05-06 00:00:01',
'2005-05-27 00:00:01',
'2005-07-05 00:00:01',
'2005-07-28 00:00:01',
'2005-08-17 00:00:01',
'2005-09-09 00:00:01',
'2005-09-21 00:00:01',
'2005-09-28 00:00:01',
'2005-10-05 00:00:01',
'2005-10-12 00:00:01',
'2005-10-19 00:00:01' );


foreach my $date (@dates) {
  my %ref;
  foreach my $type (@PGsubparameters) {
    my %join;
    my $table = 'car_' . $type . '_ref_reference';
    my $result = $conn->exec( "SELECT joinkey, $table, car_timestamp FROM $table WHERE $table IS NOT NULL AND car_timestamp < '$date' ORDER BY car_timestamp;" );
    while (my @row = $result->fetchrow) {
      if ($row[0]) { 
        if ($row[0] =~ m/WBGene/) {
          $join{$row[0]} = $row[1]; } } }
    foreach my $join (sort keys %join) {
      my @refs;
      if ($join{$join}) {
      if ($join{$join} =~ m/,/) { (@refs) = split", ", $join{$join}; }
        else { push @refs, $join; }
      } else { print "NO JOIN $join\n"; }
      foreach my $ref (@refs) {
        next if ($ref =~ m/WBPerson/);
        next if ($ref =~ m/WBRNAi/);
        next if ($ref =~ m/Expr/);
        next if ($ref =~ m/WBGene/);
        if ($ref =~ m/^\s+/) { $ref =~ s/^\s+//g; }
        if ($ref =~ m/\s+$/) { $ref =~ s/\s+$//g; }
        if ($ref =~ m/,/) { $ref =~ s/,//g; }
        if ($ref =~ m/^WBPaper/) { $ref{$ref}++; }
        elsif ($xref{$ref}) { $ref{$xref{$ref}}++; }
#         else { 1; } # print "NO MAPPING for $ref\n";
        else { print "NO MAPPING for $ref\n"; }
      } # foreach my $ref (@refs)
    } # foreach my $join (sort keys %join)
  } # foreach my $type (@PGsubparameters)

  my $count = scalar(keys %ref);
  print OUT "$date : $count\n";
#   foreach my $ref (sort keys %ref) {
#     print OUT "REF $ref REF\n";
#   } # foreach my $ref (sort keys %ref)
#   print OUT "\n";
} # foreach my $type (@PGsubparameters)


close (OUT) or die "Cannot close $outfile : $!";
