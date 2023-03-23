#!/usr/bin/perl -w

# compare postgres values of exprpattern for a given paper+source against the Chronograms.ace file.  
# all the data was already in but didn't show in the OA because it's not in the ontology.  2011 03 22

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %ace;
my %pg;

my $result = $dbh->prepare( " SELECT pic_source.pic_source, pic_paper.pic_paper, pic_exprpattern.pic_exprpattern, pic_source.joinkey FROM pic_source, pic_paper, pic_exprpattern WHERE pic_source.joinkey = pic_paper.joinkey AND pic_source.joinkey = pic_exprpattern.joinkey; " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $key = "$row[1]\t$row[0]";
  if ($pg{$key}) { print "$key maps to $pg{$key} NOW @row\n"; }
  $pg{$key} = $row[2];
}

$/ = "";
my $infile = 'Chronograms.ace';
open (IN, "<$infile") or die "cannot open $infile : $!";
while (my $para = <IN>) {
  my $paper; my $source; my $expr;
  if ($para =~ m/Reference\s+\"(.*?)\"/) { $paper = $1; }
  if ($para =~ m/Picture\s+\"(.*?)\"/) { $source = $1; }
  if ($para =~ m/Expr_pattern\s+:\s+\"(.*?)\"/) { $expr = $1; }
  next unless ($expr);
  unless ($paper) { print "NO PAPER $para\n"; }
  unless ($source) { print "NO SOURCE $source\n"; }
  my $key = "$paper\t$source";
  if ($pg{$key}) { 
      print "$pg{$key} in postgres, $expr in ace file for $key\n"; }
    else { print "No value in postgres for $key ; $expr\n"; }
} # while (my $para = <IN>)
close (IN) or die "cannot close $infile : $!";
$/ = "\n";



__END__

