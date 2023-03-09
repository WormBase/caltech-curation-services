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

