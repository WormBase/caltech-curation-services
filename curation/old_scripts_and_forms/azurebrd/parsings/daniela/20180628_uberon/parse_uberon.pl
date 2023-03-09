#!/usr/bin/perl

# parse uberon to sort by count of xrefs to anatomy from MODs.  2018 08 28

use strict;

my $infile = 'uberon.owl';
$/ = undef;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $file = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my (@entries) = split/<!--/, $file;

my %hash;
foreach my $entry (@entries) {
  next unless ($entry =~ m/^ http:\/\/purl.obolibrary.org\/obo\/(UBERON_\d+)/);
  my %here;
  my $ubid = $1;
  my $count = 0;
  my $name = '';
# only one entry per mod
  if ($entry =~ m/<rdfs:label.*?>(.*?)<\/rdfs:label>/) { $name = $1; }
  if ($entry =~ m/oboInOwl:hasDbXref.*(EMAPA:\d+)/)    { $here{$1}++; }
  if ($entry =~ m/oboInOwl:hasDbXref.*(ZFA:\d+)/)      { $here{$1}++; }
  if ($entry =~ m/oboInOwl:hasDbXref.*(WBbt:\d+)/)     { $here{$1}++; }
  if ($entry =~ m/oboInOwl:hasDbXref.*(FBbt:\d+)/)     { $here{$1}++; }
# separate mod entries separately
#   my (@lines) = split/\n/, $entry;
#   foreach my $line (@lines) {
#     if ($line =~ m/<rdfs:label.*?>(.*?)<\/rdfs:label>/) { $name = $1; }
#     if ($line =~ m/oboInOwl:hasDbXref.*(EMAPA:\d+)/)    { $here{$1}++; }
#     if ($line =~ m/oboInOwl:hasDbXref.*(ZFA:\d+)/)      { $here{$1}++; }
#     if ($line =~ m/oboInOwl:hasDbXref.*(WBbt:\d+)/)     { $here{$1}++; }
#     if ($line =~ m/oboInOwl:hasDbXref.*(FBbt:\d+)/)     { $here{$1}++; }
#   } # foreach my $line (@lines)
  my $data = join"\t", sort keys %here;
  my $count = scalar keys %here;
  $hash{$count}{$ubid}{data} = $data;
  $hash{$count}{$ubid}{name} = $name;
} # foreach my $entry (@entries)

foreach my $count (sort {$b <=> $a} keys %hash) {
  foreach my $ubid (sort keys %{ $hash{$count} }) {
    my $data = $hash{$count}{$ubid}{data};
    my $name = $hash{$count}{$ubid}{name};
    print qq($ubid\t$name\t$count\t$data\n);
  } # foreach my $ubid (sort keys %{ $hash{$count} })
} # foreach my $count (sort {$b <=> $a} keys %hash)

__END__

    <!-- http://purl.obolibrary.org/obo/UBERON_0001016 -->

    <owl:Class rdf:about="http://purl.obolibrary.org/obo/UBERON_0001016">
        <rdfs:subClassOf rdf:resource="http://purl.obolibrary.org/obo/UBERON_0000467"/>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="http://purl.obolibrary.org/obo/RO_0002492"/>
                <owl:someValuesFrom rdf:resource="http://purl.obolibrary.org/obo/UBERON_0000066"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <rdfs:subClassOf>
            <owl:Restriction>
                <owl:onProperty rdf:resource="http://purl.obolibrary.org/obo/RO_0002495"/>
                <owl:someValuesFrom rdf:resource="http://purl.obolibrary.org/obo/UBERON_0016880"/>
            </owl:Restriction>
        </rdfs:subClassOf>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0001033"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0001434"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002204"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002294"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002330"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002390"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002405"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002416"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0002423"/>
        <owl:disjointWith rdf:resource="http://purl.obolibrary.org/obo/UBERON_0004456"/>
        <obo:IAO_0000115 rdf:datatype="http://www.w3.org/2001/XMLSchema#string">The nervous system is an organ system containing predominantly neuron and glial cells. In bilaterally symmetrical organism, it is arranged in a network of tree-like structures connected to a central body. The main functions of the nervous system are to regulate and control body functions, and to receive sensory input, process this information, and generate behavior [CUMBO].</obo:IAO_0000115>
        <obo:UBPROP_0000001 rdf:datatype="http://www.w3.org/2001/XMLSchema#string">A regulatory system of the body that consists of neurons and neuroglial cells. The nervous system is divided into two parts, the central nervous system (CNS) and the peripheral nervous system (PNS). (Source: BioGlossary, www.Biology-Text.com)[TAO]</obo:UBPROP_0000001>
        <obo:UBPROP_0000001 rdf:datatype="http://www.w3.org/2001/XMLSchema#string">Anatomical system consisting of nerve bodies and nerve fibers which regulate the response of the body to external and internal stimuli.[AAO]</obo:UBPROP_0000001>
        <obo:UBPROP_0000003 rdf:datatype="http://www.w3.org/2001/XMLSchema#string">Nervous systems evolved in the ancestor of Eumetazoa.[well established][VHOG]</obo:UBPROP_0000003>
        <obo:UBPROP_0000007 rdf:datatype="http://www.w3.org/2001/XMLSchema#string">nervous</obo:UBPROP_0000007>
        <obo:UBPROP_0000007 rdf:datatype="http://www.w3.org/2001/XMLSchema#string">neural</obo:UBPROP_0000007>
        <oboInOwl:hasDbXref rdf:resource="http://braininfo.rprc.washington.edu/centraldirectory.aspx?ID=3236"/>
        <oboInOwl:hasDbXref rdf:resource="http://en.wikipedia.org/wiki/Nervous_system"/>
        <oboInOwl:hasDbXref rdf:resource="http://linkedlifedata.com/resource/umls/id/C0027763"/>
        <oboInOwl:hasDbXref rdf:resource="http://uri.neuinfo.org/nif/nifstd/birnlex_844"/>
        <oboInOwl:hasDbXref rdf:resource="http://www.snomedbrowser.com/Codes/Details/278196006"/>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">AAO:0000324</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">BILA:0000079</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">BTO:0001484</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">CALOHA:TS-1313</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">EFO:0000802</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">EHDAA2:0001246</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">EHDAA:826</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">EMAPA:16469</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">EV:0100162</oboInOwl:hasDbXref>
        <oboInOwl:hasDbXref rdf:datatype="http://www.w3.org/2001/XMLSchema#string">FBbt:00005093</oboInOwl:hasDbXref>

