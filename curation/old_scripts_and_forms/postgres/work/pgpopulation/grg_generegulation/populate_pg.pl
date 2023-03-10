#!/usr/bin/perl

# expr pattern now multiontology after Daniela creation of obo table.  will be expr OA later on.
# error file now at populate_pg.err  2010 11 01
#
# read to tazendra  2010 11 08

use strict;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result ;


my %hash;

my @tables = qw( curator paper name summary antibody antibodyremark reportergene transgene insitu insitu_text northern northern_text western western_text rtpcr rtpcr_text othermethod othermethod_text type regulationlevel allele rnai transregulator moleculeregulator transregulatorseq otherregulator exprpattern nodump transregulated transregulatedseq otherregulated result anat_term lifestage subcellloc subcellloc_text remark );

my %abp_name;
&populateAbpName();

my %gin_sequence;
&populateGinSequence();
my %gin_wbgene;
&populateGinWBGene();
my %obo_transgene;
&populateTransgene();
my %obo_variation;
&populateVariation();
my %obo_anat_term;
&populateAnatTerm();
my %obo_lifestage;
&populateLifestage();
my %obo_exprpattern;
&populateExprpattern();
my %mop_molecule;
&populateMopMolecule();

my %ident_to_pap;
&populateIdentToPap();
my %cell_to_anat;
&populateCellToAnat();

my $errfile = 'populate_pg.err';
open(ERR, ">$errfile") or die "Cannot create $errfile : $!";


my %fields;
$fields{id}               = 'text';
$fields{curator}          = 'dropdown';
$fields{paper}            = 'ontology';
$fields{name}             = 'text';
$fields{summary}          = 'bigtext';
$fields{antibody}         = 'multiontology';
$fields{antibodyremark}   = 'text';
$fields{reportergene}     = 'multitext';
$fields{transgene}        = 'multiontology';
$fields{insitu}           = 'toggle_text';
$fields{insitu_text}      = 'text';
$fields{northern}         = 'toggle_text';
$fields{northern_text}    = 'text';
$fields{western}          = 'toggle_text';
$fields{western_text}     = 'text';
$fields{rtpcr}            = 'toggle_text';
$fields{rtpcr_text}       = 'text';
$fields{othermethod}      = 'toggle_text';
$fields{othermethod_text} = 'text';
$fields{allele}           = 'multiontology';
$fields{rnai}             = 'multitext';
$fields{type}             = 'multidropdown';
$fields{regulationlevel}  = 'multidropdown';
$fields{transregulator}   = 'multiontology';
$fields{transregulatorseq}  = 'multiontology';
$fields{moleculeregulator}  = 'multiontology';
$fields{otherregulator}     = 'multitext';
$fields{transregulated}     = 'multiontology';
$fields{transregulatedseq}  = 'multiontology';
$fields{otherregulated}     = 'multitext';
$fields{exprpattern}        = 'multiontology';
$fields{nodump}       = 'toggle';
$fields{result}       = 'dropdown';
$fields{anat_term}    = 'multiontology';
$fields{lifestage}    = 'multiontology';
$fields{subcellloc}   = 'toggle';
$fields{subcellloc_text}   = 'multitext';
$fields{remark}       = 'bigtext';


my %bad_tags;		# key tag, subkey line

my %ignore_tags;
$ignore_tags{Associated_feature}++;

my %tag_to_table;
$tag_to_table{Summary} = 'summary';
$tag_to_table{Reference} = 'paper';
$tag_to_table{Antibody} = 'antibodyremark';
$tag_to_table{Antibody_info} = 'antibody';
$tag_to_table{Reporter_gene} = 'reportergene';
$tag_to_table{Transgene} = 'transgene';
$tag_to_table{In_Situ} = 'insitu';
$tag_to_table{Northern} = 'northern';
$tag_to_table{Western} = 'western';
$tag_to_table{RT_PCR} = 'rtpcr';
$tag_to_table{Other_method} = 'othermethod';
$tag_to_table{Type} = 'type';
$tag_to_table{Change_of_localization} = 'type';
$tag_to_table{Change_of_expression_level} = 'type';
$tag_to_table{Regulation_level} = 'regulationlevel';
$tag_to_table{Post_transcriptional} = 'regulationlevel';
$tag_to_table{Post_translational} = 'regulationlevel';
$tag_to_table{Transcriptional} = 'regulationlevel';
$tag_to_table{Allele} = 'allele';
$tag_to_table{RNAi} = 'rnai';
$tag_to_table{Trans_regulator_gene} = 'transregulator';
$tag_to_table{Trans_regulator_seq} = 'transregulatorseq';
$tag_to_table{Molecule_regulator} = 'moleculeregulator';
$tag_to_table{Other_regulator} = 'otherregulator';
$tag_to_table{Expr_pattern} = 'exprpattern';
$tag_to_table{Trans_regulated_gene} = 'transregulated';
$tag_to_table{Trans_regulated_seq} = 'transregulatedseq';
$tag_to_table{Other_regulated} = 'otherregulated';
$tag_to_table{Result} = 'result';
$tag_to_table{Negative_regulate} = 'result';
$tag_to_table{Does_not_regulate} = 'result';
$tag_to_table{Positive_regulate} = 'result';
$tag_to_table{Anatomy_term} = 'anat_term';
$tag_to_table{Cell} = 'anat_term';
$tag_to_table{Life_stage} = 'lifestage';
$tag_to_table{Subcellular_localization} = 'subcellloc';
$tag_to_table{Remark} = 'remark';


my $count = 0;
my $infile = 'GR_OA.ace';
$/ = "";
open(IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  next unless ($entry =~ m/Gene_regulation : \"(.*)\"/);
  my $object = $1;
  my ($paper, $name) = split/_/, $object;
  if ( $ident_to_pap{$paper} ) { $paper = $ident_to_pap{$paper}; }

# #   unless (($paper =~ m/pmid/) || ($paper =~ m/cgc/)) { $hash{paper}{$count}{$paper}++; }


# cgc5878_pie-1.b

#   $count++;
#   $hash{object}{$count} = $object;
#   $hash{paper}{$count}{$paper}++;
#   $hash{name}{$count}{$object}++;
#   $hash{curator}{$count}{WBPerson1760}++;

  my (@lines) = split/\n/, $entry;
  shift (@lines);		# skip header

  my %result;
  my @normal_lines;
  foreach my $line (@lines) {
    my ($tag, $value) = $line =~ m/^(.*?)\s+(.*)/;
    unless ($tag) { $tag = $line; }
    if ($tag eq 'Negative_regulate') { $result{$tag}{$value}++; }
    elsif ($tag eq 'Positive_regulate') { $result{$tag}{$value}++; }
    elsif ($tag eq 'Does_not_regulate') { $result{$tag}{$value}++; }
    else { push @normal_lines, $line; }
  }

  foreach my $tag (sort keys %result) {
    $count++;
    $hash{object}{$count} = $object;
    $hash{paper}{$count}{$paper}++;
    $hash{name}{$count}{$object}++;
    $hash{curator}{$count}{WBPerson1760}++;
    $hash{result}{$count}{$tag}++;
    foreach my $rest_of_line (sort keys %{ $result{$tag} }) {
      next unless ($rest_of_line =~ m/\w/);
      my ($tag, $value) = $rest_of_line =~ m/^(.*?)\s+(.*)/;
      unless ($tag) { $tag = $rest_of_line; }
      if ($value =~ m/^\"/) { $value =~ s/^\"//; }
      if ($value =~ m/\"$/) { $value =~ s/\"$//; }
      if ($tag eq 'Cell') { if ($cell_to_anat{$value}) { $value = $cell_to_anat{$value}; } else { print ERR "ERR BAD Cell $value LINE $rest_of_line\n"; } }
      if ($tag eq 'Subcellular_localization') { 
        if ($value) { my $subtag = $tag_to_table{$tag} . '_text'; $hash{$subtag}{$count}{$value}++; }
        $value = $tag; }
      if ($tag_to_table{$tag}) {
          $hash{$tag_to_table{$tag}}{$count}{$value}++; }
        else { $bad_tags{$tag}{$rest_of_line}{$object}++; }
    } # foreach my $rest_of_line (sort keys %{ $result{$tag} })

    foreach my $line (@normal_lines) {
      next unless $line;
      my ($tag, $value) = $line =~ m/^(.*?)\s+(.*)/;
      unless ($tag) { $tag = $line; }
      next if ($ignore_tags{$tag});
      if ($value =~ m/^\s+/) { $value =~ s/\s+//; }
      if ($value =~ m/^\"/) { $value =~ s/^\"//; }
      if ($value =~ m/\"$/) { $value =~ s/\"$//; }
      if ($tag_to_table{$tag}) {
          if ($tag eq 'Change_of_localization') { $value = $tag; }
          elsif ($tag eq 'Change_of_expression_level') { $value = $tag; }
          elsif ($tag eq 'Post_transcriptional') { $value = $tag; }
          elsif ($tag eq 'Post_translational') { $value = $tag; }
          elsif ($tag eq 'Transcriptional') { $value = $tag; }
          elsif ($tag eq 'Reference') { $value =~ s/\"//g; }
          elsif ($tag eq 'Transgene') { unless ($obo_transgene{$value}) { print ERR "ERR BAD transgene $value\n"; next; } }
          elsif ($tag eq 'Allele') { unless ($obo_variation{$value}) { print ERR "ERR BAD variation $value\n"; next; } }
          elsif ($tag eq 'Trans_regulated_seq') { unless ($gin_sequence{$value}) { print ERR "ERR BAD sequence $value\n"; next; } }
          elsif ($tag eq 'Trans_regulator_seq') { unless ($gin_sequence{$value}) { print ERR "ERR BAD sequence $value\n"; next; } }
          elsif ($tag eq 'Trans_regulated_gene') { unless ($gin_wbgene{$value}) { print ERR "ERR BAD wbgene $value\n"; next; } }
          elsif ($tag eq 'Trans_regulator_gene') { unless ($gin_wbgene{$value}) { print ERR "ERR BAD wbgene $value\n"; next; } }
          elsif ($tag eq 'Life_stage') { unless ($obo_lifestage{$value}) { print ERR "ERR BAD lifestage $value\n"; next; } }
          elsif ($tag eq 'Expr_pattern') { unless ($obo_exprpattern{$value}) { print ERR "ERR BAD exprpattern $value\n"; next; } }
          elsif ($tag eq 'Anatomy_term') { unless ($obo_anat_term{$value}) { print ERR "ERR BAD anatomyTerm $value\n"; next; } }
          elsif ($tag eq 'Molecule_regulator') { unless ($mop_molecule{$value}) { print ERR "ERR BAD molecule $value\n"; next; } }
          elsif ($tag eq 'Antibody_info') { unless ($abp_name{$value}) { print ERR "ERR BAD antibody object $value\n"; next; } }
          elsif ($tag eq 'Antibody') { if ($abp_name{$value}) { $tag = 'Antibody_info'; } }
#           elsif ( ($tag eq 'Negative_regulate') || ($tag eq 'Does_not_regulate') || ($tag eq 'Positive_regulate') ) {
#             next unless ($value =~ m/\w/);
#             my ($subtag, $realvalue) = $value =~ m/^(.*?)\s+(.*)/;
#             unless ($subtag) { $subtag = $value; }
#             if ($realvalue =~ m/^\"/) { $realvalue =~ s/^\"//; }
#             if ($realvalue =~ m/\"$/) { $realvalue =~ s/\"$//; }
#             if ($subtag eq 'Cell') { if ($cell_to_anat{$realvalue}) { $realvalue = $cell_to_anat{$realvalue}; } else { print ERR "ERR BAD Cell $realvalue LINE $line\n"; } }
#             if ($subtag eq 'Subcellular_localization') { 
#               if ($realvalue) { my $subsubtag = $tag_to_table{$subtag} . '_text'; $hash{$subsubtag}{$count}{$realvalue}++; }
#               $realvalue = $subtag; }
#             if ($tag_to_table{$subtag}) {
#                 $hash{$tag_to_table{$subtag}}{$count}{$realvalue}++; }
#               else { $bad_tags{$subtag}{$line}{$object}++; }
#             $value = $tag; 
#           }
          elsif ( ($tag eq 'In_Situ') || ($tag eq 'Northern') || ($tag eq 'Western') || ($tag eq 'RT_PCR') || ($tag eq 'Other_method') ) { 
            if ($value) { my $subtag = $tag_to_table{$tag} . '_text'; $hash{$subtag}{$count}{$value}++; }
            $value = $tag;
          }
          $hash{$tag_to_table{$tag}}{$count}{$value}++; 
      }
      else { $bad_tags{$tag}{$line}{$object}++; }
    } # foreach my $line (@normal_lines)
  }
} # while (my $entry = <IN>)
close(IN) or die "Cannot close $infile : $!";

my @pgcommands;
foreach my $id (sort {$a<=>$b} keys %{ $hash{object} }) {
#   print "OBJECT $id\n";
  foreach my $table (@tables) {
    if ($hash{$table}{$id}) {
      my $data; 
      my @values = sort keys %{ $hash{$table}{$id} };
      if ($fields{$table} eq 'multitext') { $data = join" \| ", @values; }
      elsif ( ($fields{$table} eq 'multidropdown') || ($fields{$table} eq 'multiontology') ) { $data = join"\",\"", @values; if ($data) { $data = '"' . $data . '"'; } }
      elsif ( scalar(@values) > 1 ) { 
#         next if ( ($table eq 'result') || ($table eq 'subcellloc') || ($table eq 'subcellloc_text') );
        my $values = join" -- ", @values; print ERR "ERR multiple values for $hash{object}{$id} TABLE $table : $values\n"; }
      else { $data = $values[0]; }
      if ($data) { 
        print "ID $id TABLE $table DATA $data END\n"; 
        if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
        if ($data =~ m/\\/) { $data =~ s/\\//g; }
        push @pgcommands, "INSERT INTO grg_$table VALUES ('$id', '$data');";
        push @pgcommands, "INSERT INTO grg_${table}_hst VALUES ('$id', '$data');";
      }
    } # if ($hash{$table}{$id})
  } # foreach my $table (@tables)
} # foreach my $id (sort {$a<=>$b} keys %{ $hash{object} })

foreach my $pgcommand (@pgcommands) {
#   print "$pgcommand\n";
# UNCOMMENT TO populate
#   $result = $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)

foreach my $tag (sort keys %bad_tags) {
  foreach my $line (sort keys %{ $bad_tags{$tag} }) {
    my (@objects) = sort keys %{ $bad_tags{$tag}{$line} }; my $objects = join", ", @objects;
    print "TAG $tag LINE $line OBJECTS $objects END\n";
  } # foreach my $line (sort keys %{ $bad_tags{$tag} })
} # foreach my $tag (sort keys %bad_tags)


close(ERR) or die "Cannot close $errfile : $!";

sub populateGinWBGene {
  $result = $dbh->prepare( "SELECT * FROM gin_wbgene;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $gin_wbgene{$row[1]}++; }
  $gin_wbgene{"WBGene00003004"}++;		# not in list for some reason, but valid lin-15
} # sub populateGinWBGene
sub populateTransgene {
#   $result = $dbh->prepare( "SELECT * FROM obo_name_app_transgene;" );
  $result = $dbh->prepare( "SELECT * FROM trp_name;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $obo_transgene{$row[1]}++; }
} # sub populateTransgene
sub populateVariation {
  $result = $dbh->prepare( "SELECT * FROM obo_name_app_variation;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $obo_variation{$row[0]}++; }
} # sub populateVariation
sub populateAnatTerm {
  $result = $dbh->prepare( "SELECT * FROM obo_name_app_anat_term;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $obo_anat_term{$row[1]}++; }
} # sub populateAnatTerm
sub populateLifestage {
  $result = $dbh->prepare( "SELECT * FROM obo_name_app_lifestage;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $obo_lifestage{$row[1]}++; }
} # sub populateLifestage
sub populateExprpattern {
  $result = $dbh->prepare( "SELECT * FROM obo_name_pic_exprpattern;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $obo_exprpattern{$row[1]}++; }
} # sub populateExprpattern
sub populateMopMolecule {
  $result = $dbh->prepare( "SELECT * FROM mop_molecule;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $mop_molecule{$row[1]}++; }
} # sub populateMopMolecule

sub populateAbpName {
  $result = $dbh->prepare( "SELECT * FROM abp_name;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $abp_name{$row[1]}++; }
} # sub populateAbpName
sub populateGinSequence {
  $result = $dbh->prepare( "SELECT * FROM gin_sequence;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $gin_sequence{$row[1]}++; }
} # sub populateGinSequence
sub populateIdentToPap {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $ident_to_pap{$row[1]} = "WBPaper$row[0]"; }
} # sub populateIdentToPap

sub populateCellToAnat {
  my $infile = 'CellAO.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    if ($line =~ m/Cell : \"(.*?)\"\s+\"(.*?)\"/) { $cell_to_anat{$1} = $2; } }
  close (IN) or die "Cannot close $infile : $!";
# Cell : "ADAL"   "WBbt:0004013"
} # sub populateCellToAnat

__END__

// data dumped from keyset display

Gene_regulation : "cgc1664_mec-3.a"
Summary	 "UNC-86 and MEC-3 are required for mec-3 expression. u3m3 deletions abolishes the binding of mec-3 5' flanking region CS3 with UNC-86 and MEC-3 proteins. u3m3(-) animals showed no LacZ expression."
Reporter_gene	 "[mec-3(m)::lacZ]. Site-directed mutagenesis on mec-3 5' flanking region that are critical for binding with MEC-3 and UNC-86, and transforming animals with the mutagenized DNA."
Trans_regulator_gene	 "WBGene00006818"
Trans_regulator_gene	 "WBGene00003167"
Trans_regulated_gene	 "WBGene00003167"
Positive_regulate	
Reference	 "WBPaper00001664"

Gene_regulation : "cgc1664_mec-3.b"
Summary	 "UNC-86 is required for mec-3 expression. A two nucleotide change at position u2 greatly reduced the UNC-86 binding but not MEC-3 binding, at CS2 site of 5' flanking region of mec-3. Young L2 larva have normal beta-gal activity in PLML, PLMR, PVD and PVM, greatly reduced activity in FLPL, FLPR, and essentially no activity in ALML, ALMR and AVM. At later stages (L3 to adult), beta-gal expression in the usual mec-3-expressing cells gradually disppeared."
Reporter_gene	 "[mec-3(m)::lacZ]. Site-directed mutagenesis on mec-3 5' flanking region that are critical for binding with MEC-3 and UNC-86, and transforming animals with the mutagenized DNA."
Trans_regulator_gene	 "WBGene00006818"
Trans_regulated_gene	 "WBGene00003167"
Positive_regulate	 Life_stage "L3 larva"
Positive_regulate	 Life_stage "L4 larva"
Positive_regulate	 Life_stage "adult"
Positive_regulate	 Life_stage "L2 larva"
Positive_regulate	 Cell "FLPL"
Positive_regulate	 Cell "FLPR"
Positive_regulate	 Cell "ALML"
Positive_regulate	 Cell "ALMR"
Positive_regulate	 Cell "AVM"
Positive_regulate	 Cell "PLML"
Positive_regulate	 Cell "PLMR"
Positive_regulate	 Cell "PVD"
Positive_regulate	 Cell "PVM"
Reference	 "WBPaper00001664"

Gene_regulation : "cgc2583_par"
Summary	 "In wild-type embryos, both PAR-1 and PAR-2 proteins are localized to the posterior periphery of the one-cell embryo. This asymmetric distribution depends upon par-3 activity\; in one-cell embryos from par-3 mutants, both of these proteins are still peripherally localized but their distribution is uniform and the peripheral signal is weaker than in wild type. To determine whether par-6 function was also required, we examined PAR-1 and PAR-2 distributions in par-6 embryos. In more than 20 embryos examined for each, the distributions of PAR-1 and PAR-2 are similar to those seen in par-3 mutants."
Antibody	 "Anti PAR-1 antibody and anti PAR-2 antibody."
Trans_regulator_gene	 "WBGene00003918"
Trans_regulator_gene	 "WBGene00003921"
Trans_regulated_gene	 "WBGene00003916"
Trans_regulated_gene	 "WBGene00003917"
Positive_regulate	 Cell "P0"
Positive_regulate	 Subcellular_localization "posterior periphery"
Negative_regulate	 Cell "P0"
Negative_regulate	 Subcellular_localization "anterior periphery"
Reference	 "WBPaper00002583"

Gene_regulation : "cgc2583_par-3"
Summary	 "In wild-type embryos the PAR-3 protein has a complex and dynamic distribution. Briefly, PAR-3 is localized to the anterior periphery of a one-cell embryo\; after the first division, PAR-3 surrounds the AB blastomere, but is present only at the anterior periphery of P1. This pattern of expression is reciprocal to that of the PAR-1 and PAR-2 proteins, which are present at the posterior periphery of P1. par-6 embryos was stained with antibodies that recognize PAR-3, and found similar abnormalities in PAR-3 localization in each of the strains tested (par-6(zu170), par-6(zu222), and par-6(zu222)\/hDf15). In par-6 mutants PAR-3 peripheral staining is reduced or absent. In addition, when staining is detectable, it is not always asymmetric. Because par-6  mutants appear to have wild-type levels of PAR-3 protein, it seems that the wild-type pattern of PAR-3 localization requires par-6(+) activity."
Antibody	 "Anti PAR-3 antibody"
Trans_regulator_gene	 "WBGene00003921"
Trans_regulated_gene	 "WBGene00003918"
Positive_regulate	 Cell "P0"
Positive_regulate	 Subcellular_localization "anterior periphery"
Reference	 "WBPaper00002583"

Gene_regulation : "cgc2654_glp-1.a"
Summary	 "In wild type, whereas glp-1 mRNA is uniformly distributed in both oocytes and early embryos (1 to 4 cells), GLP-1 protein is first seen at the 2-cell stage, in the anterior AB but not the posterior P1 blastomere\; GLP-1 continues to be expressed in AB descendants through the 28-cell stage. In 100\% of par-1 mutant embryos GLP-1 was detected in all blastomeres. For par-1, all embryos had approximately equal levels of GLP-1 expression in all blastomeres. In embryos where P granules could be scored, they were distributed equally among the blastomeres (n = 4). Adult germ lines (n = 9), oocytes (n = 9), and 1-cell embryos (n = 8) had a normal GLP-1 pattern. Thus, par-1 is required for spatial but not temporal regulation of GLP-1 asymmetry. The time of onset of GLP-1 translation appears to be normal in mutant embryos, and the presence of GLP-1 in P1 descendants is likely to reflect ectopic translation there."
Antibody	 "To detect GLP-1, a mixture of anti-EGFL, anti-LNG, and anti-ANK polyclonal antibodies was used."
Trans_regulator_gene	 "WBGene00003916"
Trans_regulated_gene	 "WBGene00001609"
Positive_regulate	 Cell "AB"
Positive_regulate	 Cell "ABa"
Positive_regulate	 Cell "ABal"
Positive_regulate	 Cell "ABala"
Positive_regulate	 Cell "ABalaa"
Positive_regulate	 Cell "ABalap"
Positive_regulate	 Cell "ABalp"
Positive_regulate	 Cell "ABalpa"
Positive_regulate	 Cell "ABalpp"
Positive_regulate	 Cell "ABar"
Positive_regulate	 Cell "ABara"
Positive_regulate	 Cell "ABaraa"
Positive_regulate	 Cell "ABarap"
Positive_regulate	 Cell "ABarp"
Positive_regulate	 Cell "ABarpa"
Positive_regulate	 Cell "ABarpp"
Positive_regulate	 Cell "ABp"
Positive_regulate	 Cell "ABpl"
Positive_regulate	 Cell "ABpla"
Positive_regulate	 Cell "ABplaa"
Positive_regulate	 Cell "ABplap"
Positive_regulate	 Cell "ABplp"
Positive_regulate	 Cell "ABplpa"
Positive_regulate	 Cell "ABplpp"
Positive_regulate	 Cell "ABpr"
Positive_regulate	 Cell "ABpra"
Positive_regulate	 Cell "ABpraa"
Positive_regulate	 Cell "ABprap"
Positive_regulate	 Cell "ABprp"
Positive_regulate	 Cell "ABprpa"
Positive_regulate	 Cell "ABprpp"
Negative_regulate	 Cell "C"
Negative_regulate	 Cell "Ca"
Negative_regulate	 Cell "Caa"
Negative_regulate	 Cell "Cap"
Negative_regulate	 Cell "Cp"
Negative_regulate	 Cell "Cpa"
Negative_regulate	 Cell "Cpp"
Negative_regulate	 Cell "D"
Negative_regulate	 Cell "E"
Negative_regulate	 Cell "Ea"
Negative_regulate	 Cell "Ep"
