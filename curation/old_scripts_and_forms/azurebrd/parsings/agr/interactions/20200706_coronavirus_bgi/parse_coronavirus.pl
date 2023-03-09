#!/usr/bin/perl

# generate file
# ./parse_coronavirus.pl > out; cat out | json_pp > coronavirus_biogrid.json
#
# validate the file works
# curl -H "Authorization: Bearer 4ca958223bd7fe9769160acca51cd84b" -X POST "https://fmsdev.alliancegenome.org/api/data/validate" -F "3.1.1_BGI_SARS-CoV-2=@coronavirus_biogrid.json"
# {"status":"success","fileStatus":{"3.1.0_BGI_SARS-CoV-2":"success"}}
#
# upload the file
# curl -H "Authorization: Bearer 4ca958223bd7fe9769160acca51cd84b" -X POST "https://fmsdev.alliancegenome.org/api/data/submit" -F "3.1.1_BGI_SARS-CoV-2=@coronavirus_biogrid.json"
# {"status":"success","fileStatus":{"3.1.0_BGI_SARS-CoV-2":"success"}}


# Updated to work off of .tsv output from Chris G's google doc spreadsheet instead of original source files.  2020 07 06
#
# Added "name" field to spreadsheet sheet and code.  2020 07 20
#
# BGI sample https://github.com/alliance-genome/agr_schemas/blob/master/ingest/gene/wbSample.BGI.json
# gff at https://raw.githubusercontent.com/GMOD/sars-cov-2-jbrowse/master/jbrowse/data/SARS-CoV-2/NC_045512.2.gff3  
# read gff file and map from Name in column 9 to get data for genomeLocations.  2020 07 21
#
#
# Later use
# ftp://ftp.uniprot.org/pub/databases/uniprot/pre_release/covid-19.rdf
# ftp://ftp.uniprot.org/pub/databases/uniprot/pre_release/covid-19.xml 
# .json version http://tazendra.caltech.edu/~azurebrd/var/work/chris/covid-19.json based on .xml above converted by uploading the file to https://www.convertjson.com/xml-to-json.htm (just entering the url on the form didn't work)
# get descriptions from .json from  entry>#>comment>#(with _type: "function")>text:>__text:
# or from .xml split on <entry></entry>   
# Then find <comment type="function"><text evidence="2 3">Component of the viral envelope that plays a central role in virus morphogenesis and assembly via its interactions with other viral proteins.</text></comment>
# and use the <accession>P0DTC5</accession>
# 2020 07 22


use strict;
use diagnostics;
use Jex;

# col 26 - 32
# 26 - primary id
# 27 - symbol
# 28 - commaSpace synonyms
# 29 - commaSpace crossreferences
# 30 - soterm id
# 31 - taxonid
# 32 - geneSynopsis

my $release = '3.1.1';

my %gff;
my $gff_file = 'NC_045512.2.gff3';
open (IN, "<$gff_file") or die "Cannot open $gff_file : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^#/);
  chomp $line;
  my @line = split/\t/, $line;
  next unless ($line[2]);
  next unless ($line[2] eq 'mature_protein_region');
  my $chromosome = $line[0];
  my $start = $line[3];
  my $end = $line[4];
  my $strand = $line[6];
  my $name = '';
  my @col9 = split/;/, $line[8];
  foreach my $col9 (@col9) {
    if ($col9 =~ m/Name=(.*)/) { 
      $name = $1; 
      if ($name =~ m/^(.*)\..*/) {	# YP_ entries will have a .something that should be ignored, P0DTD entries won't
        $name = $1; } } }
  if ($name) { 
    $gff{$name}{chromosome} = $chromosome;
    $gff{$name}{start} = $start;
    $gff{$name}{end} = $end;
    $gff{$name}{strand} = $strand;
  }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $gff_file : $!";
$gff{'YP_009725307'}{'start'} = 13442;
$gff{'YP_009725307'}{'end'} = 16236;

my %entries;
my $infile = 'coronavirus_mappings.tsv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;  
  my @line = split/\t/, $line;
  my ($primaryId, $name, $symbol, $taxonId, $synonyms, $crossref, $soTermId, $geneSynopsis) = ('', '', '', '', '', '', '', '');
  if ($line[25]) { $primaryId = $line[25]; }
  next unless ($primaryId);
  next if ($primaryId eq 'N/A');
  next if ($primaryId eq 'Proposed BGI JSON primaryId');
  if ($line[26]) { $symbol = $line[26]; }
  if ($line[27]) { $name = $line[27]; }
  if ($line[28]) { $synonyms = $line[28]; }
  if ($line[29]) { $crossref = $line[29]; }
  if ($line[30]) { $soTermId = $line[30]; }
  if ($line[31]) { $taxonId = $line[31]; }
  if ($line[32]) { 
    if ($line[32] ne 'N/A') { $geneSynopsis = $line[32]; } }
  my (@syns) = split/, /, $synonyms;
  if (scalar @syns > 1) { $synonyms = join'","', @syns; }
  my (@xref_temp) = split/, /, $crossref;
  my @xref;
  foreach my $xref (@xref_temp) {
    push @xref, qq("id" : "$xref");
  } # foreach my $xref (@xref_temp)
  if (scalar @xref > 1) { $crossref = join'},{', @xref; } 
  my @entry;
  my @bge;
  my $gff_name = $primaryId;
  $gff_name =~ s/RefSeq://;
  if ($gff{$gff_name}) {
      push @bge, qq("genomeLocations" : [ { "assembly" : "ASM985889v3", "chromosome" : "$gff{$gff_name}{'chromosome'}", "startPosition" : $gff{$gff_name}{'start'}, "endPosition" : $gff{$gff_name}{'end'}, "strand" : "$gff{$gff_name}{'strand'}" } ]); }
#     else { print qq(ERROR $gff_name does not have a GFF entry\n); }	# for error checking
  push @bge, qq("primaryId" : "$primaryId");
  push @bge, qq("taxonId" : "$taxonId");
  push @bge, qq("synonyms" : [ "$synonyms" ]);
  push @bge, qq("crossReferences" : [ { $crossref } ]);
  my $bge = join",\n", @bge;
  if ($bge) { push @entry, qq("basicGeneticEntity":{\n$bge\n}); }
  if ($symbol) { push @entry, qq("symbol" : "$symbol"); }
  if ($geneSynopsis) { push @entry, qq("geneSynopsis" : "$geneSynopsis"); }
  push @entry, qq("soTermId" : "$soTermId");
  push @entry, qq("name" : "$name");
  my $entry = join",\n", @entry;
  $entries{$entry}++;
#   print qq(PID $primaryId\tS $symbol\tSYN $synonyms\tXR $crossref\tSO $soTermId\tT $taxonId\n);
} # while (my $line = <IN>)

my $date = &getPgDate(); $date =~ s/ /T/; 
$date .= '-07:00';				# add timezone offset, should probably get it with  `date +"%Z %z"` or something like that.
my $metadata = '';
$metadata .= qq("dataProvider": { "crossReference": { "id":"Alliance of Genome Resources", "pages": ["homepage"] } },\n);
$metadata .= qq("dateProduced" : "$date",\n);
$metadata .= qq("release" : "$release");
my $output = join"},\n{", sort keys %entries;
print qq({\n"data" : [\n{\n$output\n}\n],\n"metaData": {\n$metadata\n}\n});

close (IN) or die "Cannot close $infile : $!";

__END__

  http://download.alliancegenome.org/3.1.0/BGI/SARS-CoV-2/1.0.1.1_BGI_SARS-CoV-2_0.json

#!/usr/bin/perl

# download from
# https://downloads.thebiogrid.org/Download/BioGRID/Latest-Release/BIOGRID-CORONAVIRUS-LATEST.tab3.zip
#
# parse into format like
# https://github.com/alliance-genome/agr_schemas/blob/master/ingest/gene/wbSample.BGI.json
#
# instructions at
# https://docs.google.com/document/d/1kiPwMC0fYaZ0Hh4wtbBzrdwJgnX6VYwOxZq9A4YRk0w/edit
#
# for Chris.  2020 05 19

# generate file
# ./parse_coronavirus.pl > out; cat out | json_pp > coronavirus_biogrid.json
#
# validate the file works
# curl -H "Authorization: Bearer 4ca958223bd7fe9769160acca51cd84b" -X POST "https://fmsdev.alliancegenome.org/api/data/validate" -F "3.1.0_BGI_SARS-CoV-2=@coronavirus_biogrid.json"
# {"status":"success","fileStatus":{"3.1.0_BGI_SARS-CoV-2":"success"}}
#
# upload the file
# curl -H "Authorization: Bearer 4ca958223bd7fe9769160acca51cd84b" -X POST "https://fmsdev.alliancegenome.org/api/data/submit" -F "3.1.0_BGI_SARS-CoV-2=@coronavirus_biogrid.json"
# {"status":"success","fileStatus":{"3.1.0_BGI_SARS-CoV-2":"success"}}



use strict;
use diagnostics;
use Jex;

my %entries;
my $infile = 'BIOGRID-CORONAVIRUS-3.5.185.tab3.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^#/);
  chomp $line;
  my @cols = split/\t/, $line;
  for my $i (0 .. $#cols) { if ($cols[$i] eq '-') { $cols[$i] = ''; } }
#   if ( ($cols[15] eq '2697049') && ($cols[17] eq '2697049') ) { print qq(BOTH $line\n); }
  my $soTermId = 'SO:0000104';
  if ($cols[15] eq '2697049') {
    my ($primaryId, $symbol, $taxonId, $synonyms, $crossref) = ('', '', '', '', '');
    my %syns; my %xref;
    if ($cols[27]) { $primaryId = "RefSeq:$cols[27]"; }
    $symbol = $cols[7];
    if ($symbol eq 'ORF9b') { $primaryId = "RefSeq:$cols[25]"; $xref{qq("id":"RefSeq:$cols[25]")}++; $xref{qq("id":"UniProtKB:$cols[25]")}++; }
    if ($symbol eq 'ORF9c') { $primaryId = "RefSeq:P0DTD3"; $xref{qq("id":"RefSeq:P0DTD3")}++; $xref{qq("id":"UniProtKB:P0DTD3")}++; }
    $taxonId = "NCBITaxon:$cols[15]";
    if ($cols[5]) { $syns{$cols[5]}++; }
    if ($cols[9]) { 
      my (@syns) = split/\|/, $cols[9]; 
      foreach (@syns) { $syns{$_}++; } }
    if (scalar keys %syns > 1) { $synonyms = join'","', sort keys %syns; }
    if ($cols[1]) { 
       my $entrez = qq("id":"NCBI_Gene:$cols[1]");
       $xref{$entrez}++; }
    if ($cols[25]) { $xref{qq("id":"UniProtKB:$cols[25]")}++; }
    if ($cols[27]) {
      my (@xref) = split/\|/, $cols[27]; 
      foreach (@xref) { $xref{qq("id":"RefSeq:$_")}++; } }
    if (scalar keys %xref > 1) { $crossref = join'},{', sort keys %xref; } 
    if ($primaryId) {
      if ($primaryId =~ m/\|/) { print qq(ERROR primary has a pipe $primaryId : $line\n); }
      my @entry;
      my @bge;
      push @bge, qq("primaryId" : "$primaryId");
      push @bge, qq("taxonId" : "$taxonId");
      push @bge, qq("synonyms" : [ "$synonyms" ]);
      push @bge, qq("crossReferences" : [ { $crossref } ]);
      my $bge = join",\n", @bge;
      if ($bge) { push @entry, qq("basicGeneticEntity":{\n$bge\n}); }
      if ($symbol) { push @entry, qq("symbol" : "$symbol"); }
      push @entry, qq("soTermId" : "$soTermId");
      my $entry = join",\n", @entry;
      $entries{$entry}++;
    }
  }
  if ($cols[17] eq '2697049') {
    my ($primaryId, $symbol, $taxonId, $synonyms, $crossref) = ('', '', '', '', '');
    my %syns; my %xref;
    if ($cols[30]) { $primaryId = "RefSeq:$cols[30]"; }
    $symbol = $cols[8];
    if ($symbol eq 'ORF9b') { $primaryId = "RefSeq:$cols[28]"; $xref{qq("id":"RefSeq:$cols[28]")}++; $xref{qq("id":"UniProtKB:$cols[28]")}++; }
    if ($symbol eq 'ORF9c') { $primaryId = "RefSeq:P0DTD3"; $xref{qq("id":"RefSeq:P0DTD3")}++; $xref{qq("id":"UniProtKB:P0DTD3")}++; }
    $taxonId = "NCBITaxon:$cols[17]";
    if ($cols[6]) { $syns{$cols[6]}++; }
    if ($cols[10]) { 
      my (@syns) = split/\|/, $cols[10]; 
      foreach (@syns) { $syns{$_}++; } }
    if (scalar keys %syns > 1) { $synonyms = join'","', sort keys %syns; }
    if ($cols[2]) { 
       my $entrez = qq("id":"NCBI_Gene:$cols[2]");
       $xref{$entrez}++; }
    if ($cols[28]) { $xref{qq("id":"UniProtKB:$cols[28]")}++; }
    if ($cols[30]) {
      my (@xref) = split/\|/, $cols[30]; 
      foreach (@xref) { $xref{qq("id":"RefSeq:$_")}++; } }
    if (scalar keys %xref > 1) { $crossref = join'},{', sort keys %xref; } 
    if ($primaryId) {
      if ($primaryId =~ m/\|/) { print qq(ERROR primary has a pipe $primaryId : $line\n); }
      my @entry;
      my @bge;
      push @bge, qq("primaryId" : "$primaryId");
      push @bge, qq("taxonId" : "$taxonId");
      push @bge, qq("synonyms" : [ "$synonyms" ]);
      push @bge, qq("crossReferences" : [ { $crossref } ]);
      my $bge = join",\n", @bge;
      if ($bge) { push @entry, qq("basicGeneticEntity":{\n$bge\n}); }
      if ($symbol) { push @entry, qq("symbol" : "$symbol"); }
      push @entry, qq("soTermId" : "$soTermId");
      my $entry = join",\n", @entry;
      $entries{$entry}++;
    }
  }
}
close (IN) or die "Cannot close $infile : $!";

my $date = &getPgDate(); $date =~ s/ /T/; 
$date .= '-07:00';				# add timezone offset, should probably get it with  `date +"%Z %z"` or something like that.
my $metadata = '';
$metadata .= qq("dataProvider": { "crossReference": { "id":"BioGrid", "pages": ["homepage"] } },\n);
$metadata .= qq("dateProduced" : "$date",\n);
$metadata .= qq("release" : "3.1.0");
my $output = join"},\n{", sort keys %entries;
print qq({\n"data" : [\n{\n$output\n}\n],\n"metaData": {\n$metadata\n}\n});


# foreach my $entry (sort keys %entries) {
#   print qq($entry\n);
# }

