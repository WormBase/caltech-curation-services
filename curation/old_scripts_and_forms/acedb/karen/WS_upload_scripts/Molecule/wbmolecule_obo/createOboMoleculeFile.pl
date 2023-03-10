#!/usr/bin/perl

use strict;
use diagnostics;

#------------------ Move data under invalid papers -------------
#This script is an adaptation of Wen's createMoleculeFile.pl and Juancarlos' parse_to_obo
#The output is to be used for Jolene in phenote for curating molecule data
print "This script creates molecule ace files according to MeSH or CASRN.\n";
print "Input file 1: ChEBI_KEGG_CAS_mapping.txt\n";
print "Input file 2: CTD_chemicals.tsv\n";
print "Output file: MoleculeInfo.obo\n";


#open (IN1, "temp.txt") || die "can't open $!";
open (IN1, "ChEBI_KEGG_CAS_mapping.txt") || die "can't open $!";

my ($line, $tmp_length, $MeSH, $ChEBI, $KEGG, $CasRN, $PubName);
my %ChEBI2KEGG;
my %CasRN2ChEBI;
my $KeggID = 0;
my $ChebiID = 0;

my @tmp;

while ($line=<IN1>) {
    chomp($line);
    @tmp = split /\t/, $line;
    $tmp_length = @tmp;
    next unless ($tmp_length == 5);
    $ChEBI = $tmp[1];
    if ($tmp[3] =~ /^KEGG/) {
	$KEGG = $tmp[4];
	$ChEBI2KEGG{$ChEBI} = $KEGG;
	$KeggID++;
	#print "$ChEBI, $KEGG\n";
    } elsif ($tmp[3] =~ /^CAS/) {
	$CasRN = $tmp[4];
	$CasRN2ChEBI{$CasRN} = $ChEBI;
	$ChebiID++;
	#print "$CasRN, $ChEBI\n";
    }
}
close(IN1);
#print "$KeggID KEGG IDs found.\n";
#print "$ChebiID CHEBI IDs found.\n";

my $count = 0;
open (IN2, "CTD_chemicals.tsv") || die "can't open $!";
open (OUT, ">MoleculeInfo.obo") || die "can't open $!";
print "default-namespace: wbmol\n";
print "date: 24:05:2010 10:59\n";
print "\n\n";
$KeggID = 0;
$ChebiID = 0;
$line = <IN2>;
while ($line = <IN2>) {
    chomp($line);
    ($PubName, $CasRN, $MeSH) = split /\t/, $line;
    $count++; my $id = &padZeros($count);
    print OUT "[Term]\n";
    print OUT "id: WBMol:$id\n";
    print OUT "name: $PubName\n";
    print OUT "xref: MeSH_UID: \"$MeSH\"\n";
    print OUT "xref: CTD_ChemicalID: \"$MeSH\"\n";
    if ($CasRN){
	print OUT "xref: ChemIDplus: \"$CasRN\"\n";
	if ($CasRN2ChEBI{$CasRN}) {
	    $ChEBI = $CasRN2ChEBI{$CasRN};
	    print OUT "xref: ChEBI_CHEBI_ID: \"$ChEBI\"\n";
	    $ChebiID++;
	    if ($ChEBI2KEGG{$ChEBI}) {
		$KEGG=$ChEBI2KEGG{$ChEBI};
		#print "$MeSH $ChEBI $KEGG\n";
		print OUT "xref: KEGG COMPOUND_ACCESSION_NUMBER: \"$KEGG\"\n";
		$KeggID++;
	    }
	}
    }
    print OUT "\n";
}

close(IN2);
close(OUT);
print "$KeggID KEGG IDs found.\n";
print "$ChebiID CHEBI IDs found.\n";

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

