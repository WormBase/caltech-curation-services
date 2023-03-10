#!/usr/bin/perl -w

# take pmids from querying pubmed for dois lacking pmids, and add them to postgres

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %doiToPmid;
my $infile = '/home/postgres/work/pgpopulation/pap_papers/20210113_dois_without_pmid/dois_to_pmid';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $headers = <IN>;
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/^\"//;
  $line =~ s/\"$//;
  my (@line) = split/","/, $line;
  if ($line[0]) {
    my $doi = "doi" . lc($line[2]);
    $doiToPmid{$doi} = "pmid$line[0]";
  }
}
close (IN) or die "Cannot close $infile : $!";


my %doiToPap;
my %papHighestOrder;
my %papToPmid;

my $curator = 'two10877';

$result = $dbh->prepare( "SELECT * FROM pap_identifier ORDER BY joinkey, pap_order;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $ident = lc($row[1]);
    $papHighestOrder{$row[0]} = $row[2];
    if ($doiToPmid{$ident}) { 
      $doiToPap{$ident} = $row[0]; 
    }
    if ($ident =~ m/pmid/) { $papToPmid{$row[0]}{$row[1]}++; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $doi (sort keys %doiToPmid) {
  my $pmid  = $doiToPmid{$doi};
  if ($doiToPap{$doi}) {
      my $pap   = $doiToPap{$doi};
      if ($papToPmid{$pap}{$pmid}) {
          print qq(ERR\t$pap\t$pmid\t$doi\talready in postgres\n); }
        else {
          my $order = $papHighestOrder{$pap} + 1;
          print qq($pap\t$pmid\t$doi\t$order\n); } }
    else {
      print qq(ERR\t$pmid\t$doi\tnot in postgres\n); }
} # foreach my $doi (sort keys %doiToPmid)


__END__
