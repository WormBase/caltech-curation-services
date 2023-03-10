#!/usr/bin/perl -w

# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04
#
# Added %theHash from curation.cgi to show which form field each table
# corresponds to.  2005 05 26
#
# Adapted to use updated tables which mostly store WBPaper joinkeys.  2005 10 25


use strict;
use diagnostics;
use Pg;
use LWP::Simple;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

&initializeHash();

my %theHash;		# curation.cgi hash which holds names in curation form
my %xref;

my $page = get("http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref.cgi");
my @lines = split/\n/, $page;
foreach my $line (@lines) {
  if ($line =~ m/WBPaper(\d+)\t(\w+)<BR/) { $xref{$2} = $1; } }

my @tables = qw( cur_ablationdata cur_antibody cur_associationequiv cur_associationnew cur_cellfunction cur_cellname cur_comment cur_covalent cur_curator cur_expression cur_extractedallelename cur_extractedallelenew cur_fullauthorname cur_functionalcomplementation cur_genefunction cur_geneinteractions cur_geneproduct cur_generegulation cur_genesymbol cur_genesymbols cur_goodphoto cur_invitro cur_mappingdata cur_microarray cur_mosaic cur_newmutant cur_newsnp cur_newsymbol cur_overexpression cur_rnai cur_sequencechange cur_sequencefeatures cur_site cur_stlouissnp cur_structurecorrection cur_structurecorrectionsanger cur_structurecorrectionstlouis cur_structureinformation cur_supplemental cur_synonym cur_transgene );

my $count;
foreach my $table (@tables) {
  $count = 0;
  my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      unless ($row[0] =~ m/^0/) { 
        unless ($xref{$row[0]}) { print "BAD $row[0] has no WBPaper match $table\n"; next; } }
      $count++;
  } }
  my ($temptable) = $table =~ m/cur_(.*?)$/;
  if ($theHash{$temptable}{html_field_name}) { $table .= " which is $theHash{$temptable}{html_field_name}"; }
  print OUT "$count $table\n";
}


sub initializeHash {
  $theHash{curator}{html_field_name} = 'Curator &nbsp; &nbsp;(REQUIRED)';
  $theHash{pubID}{html_field_name} = 'General Public ID Number &nbsp; &nbsp;(REQUIRED)';
  $theHash{pdffilename}{html_field_name} = 'PDF file name';
  $theHash{reference}{html_field_name} = 'Reference';
  $theHash{reference}{html_size_minor} = '8';		# default height 8 for reference
  $theHash{fullauthorname}{html_field_name} = 'Full Author Names (if known)';

  $theHash{genesymbol}{html_field_name} = 'Gene Symbol (main/other/sequence)';
  $theHash{mappingdata}{html_field_name} = 'Mapping Data';
  $theHash{genefunction}{html_field_name} = 'Gene Function';
  $theHash{generegulation}{html_field_name} = 'Gene Regulation on Expression Level';
  $theHash{expression}{html_field_name} = 'Expression Data';
  $theHash{microarray}{html_field_name} = 'Microarray';
  $theHash{rnai}{html_field_name} = 'RNAi';
  $theHash{transgene}{html_field_name} = 'Transgene';
  $theHash{overexpression}{html_field_name} = 'Overexpression';
  $theHash{structureinformation}{html_field_name} = 'Structure Information';
  $theHash{functionalcomplementation}{html_field_name} = 'Functional Complementation';
  $theHash{invitro}{html_field_name} = 'in vitro Protein Analysis';
  $theHash{mosaic}{html_field_name} = 'Mosaic Analysis';
  $theHash{site}{html_field_name} = 'Site of Action';
  $theHash{antibody}{html_field_name} = 'Extract Antibody';
  $theHash{covalent}{html_field_name} = 'Covalent Modification';
  $theHash{extractedallelenew}{html_field_name} = 'Extract Allele';
  $theHash{newmutant}{html_field_name} = 'Mutant Phenotype';
  $theHash{sequencechange}{html_field_name} = 'Sequence Change';
  $theHash{geneinteractions}{html_field_name} = 'Gene Interactions';
  $theHash{geneproduct}{html_field_name} = 'Gene Product Interaction';
  $theHash{structurecorrectionsanger}{html_field_name} = 'Sanger Gene Structure Correction';
  $theHash{structurecorrectionstlouis}{html_field_name} = 'St. Louis Gene Structure Correction';
  $theHash{sequencefeatures}{html_field_name} = 'Sequence Features';
  $theHash{cellname}{html_field_name} = 'Cell Name';
  $theHash{cellfunction}{html_field_name} = 'Cell Function';
  $theHash{ablationdata}{html_field_name} = 'Ablation Data';
  $theHash{newsnp}{html_field_name} = 'Extract New SNP';
  $theHash{stlouissnp}{html_field_name} = 'Extract SNP Verified by St. Louis';
  $theHash{supplemental}{html_field_name} = 'Supplemental Material';
  $theHash{comment}{html_field_name} = 'Comment';
} # sub initializeHash
########## theHASH ########## 




__END__

my $result = $conn->exec( "SELECT joinkey FROM ref_cgc;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $cgc{$row[0]}++;
} }

$result = $conn->exec( "SELECT joinkey FROM ref_pmid;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $pmid{$row[0]}++;
} }

$result = $conn->exec( "SELECT * FROM ref_xref;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $both{$row[0]}++;
    $both{$row[1]}++;
} }

foreach my $both (sort keys %both) {
  if ($cgc{$both}) { delete $cgc{$both}; }
  if ($pmid{$both}) { delete $pmid{$both}; }
} # foreach $_ (sort keys %both)

# my @tables = qw( cur_ablationdata cur_antibody cur_associationequiv cur_associationnew cur_cellfunction cur_cellname cur_comment cur_covalent cur_curator cur_expression cur_extractedallelename cur_extractedallelenew cur_fullauthorname cur_genefunction cur_geneproduct cur_genesymbol cur_genesymbols cur_goodphoto cur_mappingdata cur_mosaic cur_newmutant cur_newsnp cur_newsymbol cur_overexpression cur_rnai cur_sequencechange cur_sequencefeatures cur_site cur_stlouissnp cur_structurecorrection cur_structurecorrectionsanger cur_structurecorrectionstlouis cur_synonym cur_transgene );
  # tables from 2005 05 26
my @tables = qw( cur_ablationdata cur_antibody cur_associationequiv cur_associationnew cur_cellfunction cur_cellname cur_comment cur_covalent cur_curator cur_expression cur_extractedallelename cur_extractedallelenew cur_fullauthorname cur_functionalcomplementation cur_genefunction cur_geneinteractions cur_geneproduct cur_generegulation cur_genesymbol cur_genesymbols cur_goodphoto cur_invitro cur_mappingdata cur_microarray cur_mosaic cur_newmutant cur_newsnp cur_newsymbol cur_overexpression cur_rnai cur_sequencechange cur_sequencefeatures cur_site cur_stlouissnp cur_structurecorrection cur_structurecorrectionsanger cur_structurecorrectionstlouis cur_structureinformation cur_supplemental cur_synonym cur_transgene );
     

foreach my $table (@tables) {
  my $count = 0;
  foreach my $key (sort keys %both) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey = '$key';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $count++; }
  } # foreach my $key (sort keys %both)
  my ($temptable) = $table =~ m/cur_(.*?)$/;
  if ($theHash{$temptable}{html_field_name}) { $table .= " which is $theHash{$temptable}{html_field_name}"; }
  print OUT "There are $count entries for BOTH for $table\n";
} # foreach my $table (@tables)

foreach my $table (@tables) {
  my $count = 0;
  foreach my $key (sort keys %cgc) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey = '$key';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $count++; }
  } # foreach my $key (sort keys %cgc)
  my ($temptable) = $table =~ m/cur_(.*?)$/;
  if ($theHash{$temptable}{html_field_name}) { $table .= " which is $theHash{$temptable}{html_field_name}"; }
  print OUT "There are $count entries for CGC ONLY for $table\n";
} # foreach my $table (@tables)

foreach my $table (@tables) {
  my $count = 0;
  foreach my $key (sort keys %pmid) {
    my $result = $conn->exec( "SELECT * FROM $table WHERE $table IS NOT NULL AND joinkey = '$key';" );
    my @row = $result->fetchrow;
    if ($row[0]) { $count++; }
  } # foreach my $key (sort keys %pmid)
  my ($temptable) = $table =~ m/cur_(.*?)$/;
  if ($theHash{$temptable}{html_field_name}) { $table .= " which is $theHash{$temptable}{html_field_name}"; }
  print OUT "There are $count entries for PMID ONLY for $table\n";
} # foreach my $table (@tables)
