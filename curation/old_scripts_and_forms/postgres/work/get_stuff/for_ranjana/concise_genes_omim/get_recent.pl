#!/usr/bin/perl -w

# get all OMIM lines from concise description to give to Ranjana,
# then see which ones have locus entries from the go_curation from
# in the got_locus tables.  2006 08 03

use strict;
use diagnostics;
use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %list;		# keys wbgene have what ranjana wants

$/ = '';
my $inputfile = '/home/postgres/public_html/cgi-bin/data/concise_dump_new.ace';
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
while (my $para = <IN>) {
  my ($gene) = $para =~ m/Gene : \"(WBGene\d+)\"/;
  if ($para =~ m/Concise_description\t\"(.*?)\"/) { 
    my $line = $1;
    if ($line =~ m/\. .*?\./) { next; }
    if ($line =~ m/\(OMIM:\d+\)\.?$/) { $list{'all'}{$gene}++; }
  }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $inputfile : $!";

foreach my $gene (sort keys %{ $list{'all'} }) {
  my $result = $conn->exec( "SELECT * FROM got_locus WHERE joinkey = '$gene';" );
  my @row = $result->fetchrow;
  if ($row[0]) { $list{'locus'}{$gene}++; }
    else { $list{'nolocus'}{$gene}++; }
} # foreach my $gene (sort keys %list)

print "Locus\n";
foreach my $gene (sort keys %{ $list{'locus'} }) {
  print "$gene\n";
} # foreach my $gene (sort keys %{ $list{'locus'} })

print "\n\nNo Locus\n";
foreach my $gene (sort keys %{ $list{'nolocus'} }) {
  print "$gene\n";
} # foreach my $gene (sort keys %{ $list{'nolocus'} })

__END__


my $result = $conn->exec( "SELECT * FROM one_groups;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__
