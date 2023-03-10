#!/usr/bin/perl -w

# update 'not_final' values in pap_pubmed_final and h_pap_pubmed_final.  2011 05 02

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @pgcommands;

# CHANGE THE NAME OF THIS FILE
my $infile = 'find_bad_pubmed_final.out';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($joinkey, $pmid, $final_or_not) = split/\t/, $line;
  if ($final_or_not eq 'not_final') { 
    push @pgcommands, "DELETE FROM pap_pubmed_final WHERE joinkey = '$joinkey';";
    push @pgcommands, "INSERT INTO pap_pubmed_final VALUES ('$joinkey', 'not_final', NULL, 'two10877');";
    push @pgcommands, "INSERT INTO h_pap_pubmed_final VALUES ('$joinkey', 'not_final', NULL, 'two10877');";
#     print "$joinkey\n";
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO update postgres
#   my $result = $dbh->do( $command );
} # foreach my $command (@pgcommands)

__END__

$/ = undef;

my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN (SELECT joinkey FROM pap_pubmed_final WHERE pap_pubmed_final = 'final')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  my $joinkey = $row[0];
  my $pmid = $row[1];
  my ($filename) = $pmid =~ m/(\d+)/;
  my $xmlfile = $directory1 . $filename;
  my $found = 0;
  if (-e $xmlfile) { $found++; }
    else { $xmlfile = $directory2 . $filename;
           if (-e $xmlfile) { $found++; } }
  unless ($found) { print "NO FILE $xmlfile\n"; next; }
  open (IN, "<$xmlfile") or die "Cannot open $xmlfile : $!";
  my $page = <IN>;
  close (IN) or die "Cannot close $xmlfile : $!";
  my $pubmed_final = 'not_final';
  my $medline_citation = '';
  if ($page =~ m/(\<MedlineCitation.*?>)/) { $medline_citation = $1; }
  if ($medline_citation =~ /\<MedlineCitation .*Status=\"MEDLINE\"\>/i) { $pubmed_final = 'final'; }    # final version
  elsif ($medline_citation =~ /\<MedlineCitation .*Status=\"PubMed-not-MEDLINE\"\>/i) { $pubmed_final = 'final'; }      # final version
  elsif ($medline_citation =~ /\<MedlineCitation .*Status=\"OLDMEDLINE\"\>/i) { $pubmed_final = 'final'; }      # final version
  print "$joinkey\t$pmid\t$pubmed_final\n";
} # while (@row = $result->fetchrow)

$/ = "\n";


