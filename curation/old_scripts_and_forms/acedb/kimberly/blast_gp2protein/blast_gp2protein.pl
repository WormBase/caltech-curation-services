#!/usr/bin/perl

# edited to get list of all WBGenes and print them by themselves if they don't
# have a matching UniProt.  Print all Uniprots matched to themselves.
# for Kimberly.  2008 01 10

use strict;
use diagnostics;
use Pg;
use LWP::Simple;

my $outfile = 'BLAST_gp2protein';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %ces;
my %uniprot;		# print all uniprots against themselves
my %wbg;		# print all wbgenes by themselves unless they have a CE

my $wormpep_file = get("ftp://ftp.sanger.ac.uk/pub/databases/wormpep/wormpep.table");
my @lines = split/\n/, $wormpep_file;
foreach my $line (@lines) {
  my ($one, $ce, $thr, $fou, $fiv, $uniprot) = split/\t/, $line;
  $uniprot =~ s/^.*?:/UniProtKB:/g;
  $uniprot{$uniprot}++;
  $ces{$ce}{count}++;
  if ($ces{$ce}{count} > 1) { 
    if ($uniprot ne $ces{$ce}{val}) { print "$ce has $ces{$ce}{count} values\n"; } }
  $ces{$ce}{val} = $uniprot;
  print OUT "WP:WB:$ce\t$uniprot\n";
} # foreach my $line (@lines)

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my @gin_tables = qw( gin_locus gin_molname gin_protein gin_seqname gin_seqprot gin_sequence gin_synonyms ); 
foreach my $gin_table (@gin_tables) {
  my $result = $conn->exec( "SELECT * FROM gin_protein WHERE gin_protein ~ 'CE';" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $wbg{$row[0]}++; } } }

my $result = $conn->exec( "SELECT * FROM gin_protein WHERE gin_protein ~ 'CE';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    my $ce = $row[1]; $ce =~ s/WP://g;
    if ($ces{$ce}{val}) {
      if ($wbg{$row[0]} !~ m/$ces{$ce}{val}/) { 	# if the value hasn't already been appended
        $wbg{$row[0]} .= "$ces{$ce}{val};"; } }		# append the value
#       else { print "No val for $ce\n"; }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

foreach my $wbg (sort keys %wbg) {
  my $val = $wbg{$wbg}; $val =~ s/;$//g; $val =~ s/^\d+//g;	# strip out the leading wbgene counter
  if ($val =~ m/UniProtKB/) { print OUT "WB:WBGene$wbg\t$val\n"; }
    else { print OUT "WB:WBGene$wbg\n"; }
} # foreach my $wbg (sort keys %wbg)

foreach my $uniprot (sort keys %uniprot) {
  print OUT "$uniprot\t$uniprot\n"; }


close (OUT) or die "Cannot close $outfile : $!";

__END__

