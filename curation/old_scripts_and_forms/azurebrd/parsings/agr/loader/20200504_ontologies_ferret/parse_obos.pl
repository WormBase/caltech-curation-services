#!/usr/bin/perl

# parse https://raw.githubusercontent.com/alliance-genome/agr_ferret/master/src/datasets/ONTOLOGY.yaml
# to get .obo files (see script 'urls')
# This reads through all .obo files, getting a set of prefixes and which files they come from, then prefixes (like ZFA/ZFS) + IDs (0000044) + tag in the line (e.g. def:) + line value.  Then mapped to unique prefix-ID-tag that had different line values (separated by |||)
# See message to Sierra at end of file.  2020 05 04




# In   agr_loader/src/etl/generic_ontology_etl.py   looking at line.get
#
# multiples allowed
# synonym
# subset
# is_a
# relationship
# 
# only one used
# def
# is_obsolete
# namespace
# name
#
# other tags probably ignored



use strict;
use diagnostics;

my %fileToType;
my %typeToFiles;
my %typeIdFiles;

# my @files = qw( adult_mouse_anatomy.obo apo.obo basic.obo bspo.obo cl.obo doid.obo dpo.obo eco.obo emapa.obo fbbt.obo fbcv.obo fypo.obo go.obo hp.obo mmo.obo mmusdv.obo mp.obo pato.obo so.obo wbbt.obo wbls.obo wbphenotype.obo zfa.obo zfs.obo );
my @files = qw( adult_mouse_anatomy.obo apo.obo basic.obo bspo.obo cl.obo doid.obo dpo.obo eco.obo emapa.obo fbbt.obo fbcv.obo fypo.obo go.obo hp.obo mmo.obo mmusdv.obo mp.obo obi.obo pato.obo so.obo wbbt.obo wbls.obo wbphenotype.obo zfa.obo zfs.obo );
# my @files = qw( fypo.obo );


$/ = undef;
foreach my $file (@files) {
  open (IN, "<$file") or die "Cannot open $file : $!";
  my $data = <IN>;
  close (IN) or die "Cannot close $file : $!";
  my (@terms) = split/\[Term\]\n/, $data;
  my (@stuff) = split/\n\n/, $terms[$#terms];
  $terms[$#terms] = $stuff[0];
  foreach my $term (@terms) {
#     print qq(TERM $term ENDTERM\n);
    my ($type, $id) = ('', '');
    if ($term =~ m/^id: (\w+):(\d+)/) { 
      ($type, $id) = $term =~ m/^id: (\w+):(\d+)/ }
    if ($type && $id) {
#     print qq(MATCH $1 EM\n);
      $typeIdFiles{$type}{$id}{$file} = $term;
      $typeToFiles{$type}{$file}++;
      $fileToType{$file}{$type}++; }
  } # foreach my $term (@terms)
}
$/ = "\n";

foreach my $file (sort keys %fileToType) {
  foreach my $type (sort keys %{ $fileToType{$file} }) {
    print qq($file\t$type\n);
  } # foreach my $type (sort keys %{ $fileToType{$file} })
} # foreach my $file (sort keys %fileToType)
print "\n";

my @unique = qw( def is_obsolete namespace name );
foreach my $type (sort keys %typeToFiles) {
  my (@files) = sort keys %{ $typeToFiles{$type} };
  my $files = join", ", @files; my $count = scalar @files;
  if ($count > 1) {
#     print qq($type\t$count\t$files\n);

    foreach my $id (sort keys %{ $typeIdFiles{$type} }) { 
      my (@idfiles) = sort keys %{ $typeIdFiles{$type}{$id} };
      if (scalar @idfiles > 1) {
        my $idfiles = join", ", @idfiles;
#         print qq($type\t$id\t$idfiles\n);
        my %multi;
        foreach my $idfile (@idfiles) {
          my $term = $typeIdFiles{$type}{$id}{$idfile};
          my (@lines) = split/\n/, $term;
          foreach my $line (@lines) {
            foreach my $key (@unique) {
              if ($line =~ m/^$key:/) { 
                my $stripped_line = $line;
                if ($line =~ m/^$key: "(.*?)" \[/) { $stripped_line = $1; }
#                 $multi{$key}{$line}{$idfile}++;
                $multi{$key}{$stripped_line}{$idfile}++; }
            } # foreach my $key (@unique)
          } # foreach my $line (@lines)
        } # foreach my $idfile (@idfiles)
        foreach my $key (sort keys %multi) {
          my (@lines) = sort keys %{ $multi{$key} };
          if (scalar @lines > 1) {
            my $lines = join"|||", @lines;
            print qq($type\t$id\t$key\t$lines\n);
          }
        } # foreach my $key (sort keys %multi)
      }
    } # foreach my $id (sort keys %{ $typeIdFiles{$type} })
  }
} # foreach my $type (sort keys %typeToFiles)



__END__

Cool !  Ah, gotcha.  Hm, if I was doing this processing for WormBase, it would probably be because a curator wanted it in, and then I'd go to them for questions about the source, like, whether there should be links going out to some OBI website.  Generally googling around for some OBI: terms, I don't find anything, and the names don't seem particularly specific (e.g. 'role of being consumer safety officer').  I see you're the reporer in AGR-2084, but is there someone else that requested this ?  

Ah, I see what you mean about ontology terms being loaded by another ontology.  I'm still playing around with neo, so I'm not sure I get the data in there, but don't ontology nodes get created based on the ontology that loaded them ?  I wrote a perl parser (easier for me to test things in perl) to go through the ontologies that Alliance uses, getting a set of prefixes and which files they come from, then prefixes (like ZFA/ZFS) + IDs (0000044) + tag in the line (e.g. def:) + line value.  Then mapped to unique prefix-ID-tag that had different line values (separated by |||), and basically got :
 

CHEBI   16842   def     def: "An aldehyde resulting from the formal oxidation of methanol." []|||def: "The simplest aldehyde." []
CHEBI   27899   def     def: "A diamminedichloroplatinum compound in which the two ammine ligands and two chloro ligands are oriented in a cis planar configuration around the central platinum ion. An anticancer drug that interacts with, and forms cross-links between, DNA and proteins, it is used as a neoplasm inhibitor to treat solid tumours, primarily of the testis and ovary. Commonly but incorrectly described as an alkylating agent due to its mechanism of action (but it lacks alkyl groups)." []|||def: "A diamminedichloroplatinum compound in which the two ammine ligands and two chloro ligands are oriented in a cis planar configuration around the central platinum ion. An anticancer drug that interacts with, and forms cross-links between, DNA and proteins, it is used as a neoplasm inhibitor to treat solid tumours, primarily of the testis and ovary." []
ZFS     0000044 name    name: Adult|||name: adult
ZFS     0100000 name    name: Stages|||name: zebrafish stage


Looking at ZFS

zfs.obo

id: ZFS:0000044
name: adult
xref: ZFIN:ZDB-STAGE-010723-39
is_a: ZFS:0100000 ! zebrafish stage
relationship: immediately_preceded_by ZFS:0000043 ! Juvenile:Days 45-89

id: ZFS:0100000
name: zebrafish stage

MATCH (n:Ontology:ZFSTerm) WHERE n.primaryKey = 'ZFS:0000044' return n.name;
"adult"

MATCH (n:Ontology:ZFSTerm) WHERE n.primaryKey = 'ZFS:0100000' return n.name;
"zebrafish stage"


zfa.obo

id: ZFS:0000044
name: Adult
namespace: zebrafish_stages
xref: ZFIN:ZDB-STAGE-010723-39
is_a: ZFS:0100000 ! Stages

id: ZFS:0100000
name: Stages
namespace: zebrafish_stages

MATCH (n:Ontology:ZFATerm) WHERE n.primaryKey = 'ZFS:0000044' return n.name;
"Adult"

MATCH (n:Ontology:ZFATerm) WHERE n.primaryKey = 'ZFS:0100000' return n.name;
"Stages"



Looking at CHEBI

fbcv.obo
id: CHEBI:16842
def: "An aldehyde resulting from the formal oxidation of methanol." []

MATCH (n:Ontology:FBCVTerm) WHERE n.primaryKey = 'CHEBI:16842' return n.definition;
"\"An aldehyde resulting from the formal oxidation of methanol.\" []"

id: CHEBI:27899
def: "A diamminedichloroplatinum compound in which the two ammine ligands and two chloro ligands are oriented in a cis planar configuration around the central platinum ion. An anticancer drug that interacts with, and forms cross-links between, DNA and proteins, it is used as a neoplasm inhibitor to treat solid tumours, primarily of the testis and ovary. Commonly but incorrectly described as an alkylating agent due to its mechanism of action (but it lacks alkyl groups)." []

MATCH (n:Ontology:FBCVTerm) WHERE n.primaryKey = 'CHEBI:27899' return n.definition;
"\"A diamminedichloroplatinum compound in which the two ammine ligands and two chloro ligands are oriented in a cis planar configuration around the central platinum ion. An anticancer drug that interacts with, and forms cross-links between, DNA and proteins, it is used as a neoplasm inhibitor to treat solid tumours, primarily of the testis and ovary. Commonly but incorrectly described as an alkylating agent due to its mechanism of action (but it lacks alkyl groups).\" []"



fypo.obo
id: CHEBI:16842
def: "The simplest aldehyde." []

MATCH (n:Ontology:FYPOTerm) WHERE n.primaryKey = 'CHEBI:16842' return n.definition;
(no result)

id: CHEBI:27899
def: "A diamminedichloroplatinum compound in which the two ammine ligands and two chloro ligands are oriented in a cis planar configuration around the central platinum ion. An anticancer drug that interacts with, and forms cross-links between, DNA and proteins, it is used as a neoplasm inhibitor to treat solid tumours, primarily of the testis and ovary." []

MATCH (n:Ontology:FYPOTerm) WHERE n.primaryKey = 'CHEBI:27899' return n.definition;
"\"A diamminedichloroplatinum compound in which the two ammine ligands and two chloro ligands are oriented in a cis planar configuration around the central platinum ion. An anticancer drug that interacts with, and forms cross-links between, DNA and proteins, it is used as a neoplasm inhibitor to treat solid tumours, primarily of the testis and ovary.\" []"


So everything seems to match based on the Ontology set that term came from, but I don't understand why I can't find CHEBI:16842 under FYPOTerm.  If it's because I'm using the test set, that would explain it, but I don't have access to the full set to query.  Olin didn't expect to have to get the data_only_release by next Monday, so he hasn't had time to get back to me about a way to run it on aws.  

When I include running this script against the new obi.obo, there's a only differences in the data in that the definition has extra stuff in the [] at the end of the line. e.g.
CL      0000000 def     def: "A material entity of anatomical origin (part of or deriving from an organism) that has as its parts a maximally connected cell compartment surrounded by a plasma membrane." [CARO:mah]|||def: "A material entity of anatomical origin (part of or deriving from an organism) that has as its parts a maximally connected cell compartment surrounded by a plasma membrane." []

cl.obo
id: CL:0000000
def: "A material entity of anatomical origin (part of or deriving from an organism) that has as its parts a maximally connected cell compartment surrounded by a plasma membrane." [CARO:mah]

obi.obo
id: CL:0000000
def: "A material entity of anatomical origin (part of or deriving from an organism) that has as its parts a maximally connected cell compartment surrounded by a plasma membrane." []

If the script strips out the ' [.*?]' at the end of definitions, the values are the same, and there are no irregularities added by the obi.obo
I notice that go gets processed by the go_etl.py, which strips out those values, while the generic_ontology_etl.py doesn't.

go.obo
def: "The ordered and organized complex of DNA, protein, and sometimes RNA, that forms the chromosome." [GOC:elh, PMID:20404130]

MATCH (n:Ontology:GOTerm) WHERE n.primaryKey = 'GO:0000785' return n.definition;
"The ordered and organized complex of DNA, protein, and sometimes RNA, that forms the chromosome."

apo.obo
def: "A form of macroautophagy selective for ribosomes that occurs in response to starvation, damage or during a shift in environmental conditions." [SGD:RSN]

MATCH (n:Ontology:APOTerm) WHERE n.primaryKey = 'APO:0000339' return n.definition;
"\"A form of macroautophagy selective for ribosomes that occurs in response to starvation, damage or during a shift in environmental conditions.\" [SGD:RSN]"

Would we be better off stripping them from all defintion fields ?



Cool about pull request approvals, I've merged it, thanks !

Yeah, Raymond Lee is on slack.  I mostly email with him, so I don't know how often he checks it, but writing him there should work.  If you like, I could start a group thread.  Cool that you have leads on ways that might resolve this !  I don't know whether he kept the logfiles of his runs, but I've put a compilation of the emails he wrote me at   http://wobr2.caltech.edu/~azurebrd/agr/agr_loader/raymond_notes   Yeah, all my runs halted on interactions.  From Raymond's notes it seems that his did too.  Good to know that yours do too.  Haha, I don't know that he wants to do devops, (he's the senior curator) but he's certainly the best and most persistent at it at Caltech.  I'll email him your loader ideas and devops suggestion :)

