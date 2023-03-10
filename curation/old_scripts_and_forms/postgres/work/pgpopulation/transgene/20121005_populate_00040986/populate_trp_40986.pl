#!/usr/bin/perl -w

# populate tab-delimited file for Karen into trp_ tables.  2012 10 04
#
# live run on tazendra.  2012 10 05

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $pgid = '0';
$result = $dbh->prepare( "SELECT * FROM trp_curator ORDER BY joinkey::INTEGER DESC" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow(); if ($row[0]) { $pgid = $row[0]; }

my %genes;
$result = $dbh->prepare( "SELECT * FROM gin_seqname" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }
$result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }
$result = $dbh->prepare( "SELECT * FROM gin_locus " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $genes{$row[1]} = 'WBGene' . $row[0]; }

my $paper = '"WBPaper00040986"';
my $curator = 'WBPerson712';

my %addQuotes;
$addQuotes{'driven_by_gene'}++;
$addQuotes{'gene'}++;
$addQuotes{'reporter_product'}++;
$addQuotes{'paper'}++;

# print "PGID $pgid\n";

my $infile = 'WBPaper00040986S1_ListOfStrains.txt';
open(IN, "<$infile") or die "Cannot open $infile : $!";
my $headers = <IN>;
while (my $line = <IN>) {
  chomp $line;
  my ($publicname, $driven_by_gene, $gene, $summary, $reporter_product, $remark, $strain, $integration_method) = split/\t/, $line;
  $pgid++;
  my $trpId = &pad8Zeros($pgid);
  my $objId = 'WBTransgene'. $trpId;
  if ($driven_by_gene) { 
    if ($genes{$driven_by_gene}) { $driven_by_gene = $genes{$driven_by_gene}; } 
      else { print "$driven_by_gene not a gene\n"; } }
  if ($gene) { 
    if ($genes{$gene}) { $gene = $genes{$gene}; } 
      else { print "$gene not a gene\n"; } }
# COMMENT OUT TO POPULATE
  next;
  &insertToPostgresTableAndHistory('trp_name',    $pgid, $objId);
  &insertToPostgresTableAndHistory('trp_paper',   $pgid, $paper);
  &insertToPostgresTableAndHistory('trp_curator', $pgid, $curator);
  if ($publicname)         { &insertToPostgresTableAndHistory('trp_publicname',         $pgid, $publicname); }
  if ($driven_by_gene)     { &insertToPostgresTableAndHistory('trp_driven_by_gene',     $pgid, $driven_by_gene); }
  if ($gene)               { &insertToPostgresTableAndHistory('trp_gene',               $pgid, $gene); }
  if ($summary)            { &insertToPostgresTableAndHistory('trp_summary',            $pgid, $summary); }
  if ($reporter_product)   { &insertToPostgresTableAndHistory('trp_reporter_product',   $pgid, $reporter_product); }
  if ($remark)             { &insertToPostgresTableAndHistory('trp_remark',             $pgid, $remark); }
  if ($strain)             { &insertToPostgresTableAndHistory('trp_strain',             $pgid, $strain); }
  if ($integration_method) { &insertToPostgresTableAndHistory('trp_integration_method', $pgid, $integration_method); }
} # while (my $line = <IN>)
close(IN) or die "Cannot close $infile : $!";

sub insertToPostgresTableAndHistory {
  my ($table, $joinkey, $newValue) = @_;
  if ($newValue =~ m/\'/) { $newValue =~ s/\'/''/g; }
  unless (is_utf8($newValue)) { from_to($newValue, "iso-8859-1", "utf8"); }
  my $returnValue = '';
  my $result = $dbh->prepare( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
  $result->execute() or $returnValue .= "ERROR, failed to insert to $table &insertToPostgresTableAndHistory\n";
  $result = $dbh->prepare( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
  $result->execute() or $returnValue .= "ERROR, failed to insert to ${table}_hst &insertToPostgresTableAndHistory\n";
  unless ($returnValue) { $returnValue = 'OK'; }
  return $returnValue;
} # sub insertToPostgresTableAndHistory

sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros

__END__


DELETE FROM trp_name                WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_curator             WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_paper               WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_publicname          WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_driven_by_gene      WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_gene                WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_summary             WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_reporter_product    WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_remark              WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_strain              WHERE trp_timestamp > '2012-10-05 17:13';
DELETE FROM trp_integration_method  WHERE trp_timestamp > '2012-10-05 17:13';


trp_public_name	trp_driven_by_gene	trp_gene	trp_summary	trp_reporter_product	trp_remark	trp_strain	trp_integration_method
stIs10685	ceh-39	HIS-24	[pJIM20_ceh-39prom::HIS-24::mCherry; zuIs178(ubiquitous histone H3.3-GFP)]          	mCherry	"PCR primers were designed to amplify the upstream intergenic sequences (UIS) by using the program Primer3 (Rozen and Skaletsky 1998). For genes with short UIS, a minimum target length of 2250 base pairs was used and for genes with long UIS amaximum target length of 5750kb was used. Primer3 was used to pick the best distal primer within 250bp of the target and fixed the proximal primer by anchoring it at the translation start site (including up to 6aa of the endogenous protein, which increased PCR success rates). Each UIS PCR product was cloned into pJIM20 (containing a cloning site followed by histone-mCherry and a permissive let-858 3Õ UTR) (Murray et al. 2008) using standard cloning methods. The resulting plasmid was used to generate transgenic C. elegans by microparticle bombardment of the strain CB4845[unc-119(ed3)] (Praitis et al. 2001).  left/right primers  tgtggcagtaaattaggtttcatgagct/tgtgttggagaagtccattatgcagatct"	RW10614	Particle_bombardment

