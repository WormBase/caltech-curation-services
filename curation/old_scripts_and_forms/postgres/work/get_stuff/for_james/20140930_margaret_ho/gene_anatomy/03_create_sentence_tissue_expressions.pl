#!/usr/bin/env perl
#
# Author: J. Done, California Institute of Technology
# This perl script is written to address the needs of 
# writing concise descriptions for tissue expression.
#
# See http://wiki.wormbase.org/index.php/Textpresso-based_automated_extraction_of_concise_descriptions
 
use strict;
use diagnostics;
# use DBI;
use File::Slurp;
use List::MoreUtils qw(uniq);
use List::Util qw/first/;
use Data::Dumper;
use LWP::Simple;

# Define the ace file and ontology for anatomy
my $input_ace_file = "anatomy_obo_terms.ace";
my $ontology = "WBbt";
# build parent/child hash for granularity
my ($parents_ref, $children_ref) =  get_ontology_parents_children($input_ace_file, $ontology);
my %parents = %$parents_ref;
my %children = %$children_ref;
# helper verb
my $helper_verb = " is expressed in the ";
my $helper_verb_widely = " is expressed widely";
my $helper_verb_several = " is expressed in several tissues including the ";
my $helper_verb_neuron  = " nervous system";
# infile is the sorted file containing the list of gene ids with no concise description
my $infile  = "./my_wbgene_list.txt";
my @files = read_file($infile); 
my %gene_name=();
my @gene_list;
   foreach (@files){
     my $file_line = $_;
     chomp($file_line);
      my @files = split(/\,/,$file_line);
      my $file = $files[0];
      my $name = $files[1];
      chomp($file);
      chomp($name);
      $gene_name{$file} = $name;
      push(@gene_list, $file);
    }
# $anatomy_file is created by the script, get_obo_terms_only.pl, for anatomy ontology 
my $anatomy_file = "./anatomy_terms.txt";
# Create WBbt hash so that terms can be referenced by WBbt ID.
my %anatomy_ontology;
my @anat_lines = read_file($anatomy_file); 
my @keys_anatomy;
foreach my $anat_line (@anat_lines){
 chomp($anat_line);
 my $key   = $anat_line;
 my $value = $anat_line;
 $key  =~ /\((WBbt.+?)\)/;
 $key = $1; 
 $value =~ s/\(.*//g;
 chomp($value);
 $value =~ s/^\s+//;
 $value =~ s/\s+$//;
 chomp($key);
 push(@keys_anatomy, $key);
 $anatomy_ontology{$key} = $value;
}

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "acedb", "") or die "Cannot connect to database!\n";

my $outfile = "./tissue_expression_gene.txt";
my $output = "./gene_tissue_expression.txt";
my $output_genes = "./gene_ids_tissue_expression.txt";
print "Getting data from postgres DB...\n";

my $sql_query="SELECT exp_gene.joinkey, exp_gene.exp_gene, exp_name.exp_name, exp_anatomy.exp_anatomy, exp_paper.exp_paper, exp_endogenous.exp_endogenous, exp_qualifier.exp_qualifier  FROM exp_gene, exp_name, exp_anatomy, exp_paper, exp_endogenous, exp_qualifier WHERE (exp_endogenous='Endogenous') AND (exp_gene.joinkey=exp_endogenous.joinkey) AND (exp_gene.joinkey=exp_paper.joinkey) AND (exp_name.joinkey=exp_gene.joinkey) AND (exp_anatomy.joinkey=exp_gene.joinkey) AND (exp_qualifier.joinkey=exp_gene.joinkey) ORDER by exp_gene;";

# my $result = $dbh->prepare($sql_query);
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";

my $baseUrl = 'http://tazendra.caltech.edu/~postgres/cgi-bin/referenceform.cgi';
my $url = $baseUrl . '?action=Pg+!&perpage=all&pgcommand=' . $sql_query;
my $urlData = get $url;
my ($table) = $urlData =~ m/<TABLE border=1 cellspacing=5>\n<TR>(.*?)\n<\/TR>\n<\/TABLE>/ms;
my (@tableRows) = split/<\/TR>\n<TR>/, $table;



my $wbgene ="";
my $wbexpr ="";
my $wbbt   ="";
my $wbpaper="";
my $endogenous="";
my $qualifier ="";
my %genes=();
my %expressions=();
my %exp_anatomy=();
my %exp_qualifer=();
# while (my @row = $result->fetchrow) { # }
foreach my $row (@tableRows) {
        $row =~ s/^<TD>//; $row =~ s/<\/TD>$//;
        my (@row) = split/<\/TD>\n<TD>/, $row; 
        my @anatomies=();
        my $Anatomy = "";
        my $Name    = "";
        $wbgene     = $row[1];
        $wbexpr     = $row[2];
        $wbbt       = $row[3];
        $wbpaper    = $row[4];
        $endogenous = $row[5];
        $qualifier  = $row[6];

        $wbgene     =~s/"//g;
        $wbexpr     =~s/"//g;
        $wbbt       =~s/"//g;
        $wbpaper    =~s/"//g;
        $endogenous =~s/"//g;
        $qualifier  =~s/"//g;

        $wbgene    =~ s/^\s+//;
        $wbgene    =~ s/\s+$//;
        $wbexpr    =~ s/^\s+//;
        $wbexpr    =~ s/\s+$//;
        $wbpaper   =~ s/^\s+//;
        $wbpaper   =~ s/\s+$//;
        $qualifier =~ s/^\s+//;
        $qualifier =~ s/\s+$//;

        my @wbbt_elements = split(/\,/,$wbbt);
        foreach my $element (@wbbt_elements){
          chomp($element);
          $element =~ s/^\s+//;
          $element =~ s/\s+$//;
# Replace neuron (WBbt:0003679) with nervous system (WBbt:0005735)
          $element =~s/WBbt\:0003679/WBbt\:0005735/g;
          $element =~s/WBbt:0003679/WBbt:0005735/g;
          my $a = $anatomy_ontology{$element};
           push(@anatomies, $a); 
        }
          $Anatomy = join("\,", @anatomies);
          $Name = $gene_name{$wbgene};
        if ($Name){ 
          if (($qualifier =~/Certain/) or ($qualifier =~/Partial/)){
            if ($genes{$wbgene}){
                $genes{$wbgene} .= "\," . $wbbt;
               } else{
                $genes{$wbgene} = $wbbt;
               }
           }
          print "$wbgene\t$Name\t$wbexpr\t$Anatomy\t$wbpaper\t$endogenous\t$qualifier\n";
        }
} # foreach my $row (@tableRows)

#  $result->dump_results( );
#  $result->finish();

foreach my $gene_id  (sort keys %genes) {
    my $anatomy = $genes{$gene_id};
    my $name = $gene_name{$gene_id};
           my @wbbt_elements = split(/\,/,$anatomy);
        my @anatomies=();

my @child_array=();
my @parent_array=();
        foreach my $element (@wbbt_elements){
          chomp($element);
          $element =~s/WBbt\:0003679/WBbt\:0005735/g;
          $element =~s/WBbt:0003679/WBbt:0005735/g;
         }
 
# Check @unique_anatomies; keep higher level terms and discard children.
# For each anatomy term, find the parents and the children
         
         foreach my $a (@wbbt_elements){
          my @c_array=();
          my @p_array=();
          chomp($a);
          my $ancestors = $parents{$a};
          my $child     = $children{$a};
          if ($child) {$child =~ s/,$//; @c_array = split/\,/,$child;}
          if ($ancestors) {$ancestors =~ s/,$//; @p_array = split/\,/,$ancestors;}
# Do not include "The Cell" as either a parent or a child
          foreach my $c (@c_array){
            if ($c ne "WBbt:0004017"){
            push(@child_array, $c);
           }
          }
          foreach my $p (@p_array){
            if ($p ne "WBbt:0004017"){
            push(@parent_array, $p);
           }
          }
        }
my @unique_child_array = uniq(@child_array);
my @unique_parent_array = uniq(@parent_array);
#
# Now use the new array with the lower redundant children removed.
#
foreach my $p (@unique_child_array){
my $pointer = 0;
while ($pointer <= $#wbbt_elements) {
#   print "\@wbbt_elements[$pointer] is $wbbt_elements[$pointer]\n";

   if ($wbbt_elements[$pointer] eq $p) {
#      print "parents must be removed.\n";
      splice(@wbbt_elements, $pointer, 1);
   }
   else {
      $pointer++;
   }
 }
}

         foreach my $element (@wbbt_elements){
          my $a = $anatomy_ontology{$element};
          if ($a =~/neuron/){
           if (($a=~/I3/)or($a=~/I4/)or($a=~/I5/)or($a=~/I6/)or($a=~/M1/)or
               ($a=~/M4/)or($a=~/M5/)or($a=~/MI/)){
#            print "exception\t$a\n";
          } else {
            $a =~s/neuron/neurons/g;
          }
         }
           push(@anatomies, $a); 
        }
          my @unique_anatomies = uniq(@anatomies);
#
#
    my $Anatomy = join("\,", @unique_anatomies);   
    my $summary = "$gene_id\t$name\t$Anatomy\n";
    my $gene_output = "$gene_id\n";

    my $size = @unique_anatomies;
    my $sentence = $name . $helper_verb;
    if ($size == 1){
      $sentence .= $unique_anatomies[0];
    if ($sentence =~/Cell/){
        $sentence = $name . $helper_verb_widely;
    }
    } elsif ($size ==2){
      $sentence .= $unique_anatomies[0] . " and the " . $unique_anatomies[1];
      if ($sentence =~/Cell/){
        my $not_cell = "";
        if ($unique_anatomies[0] =~/Cell/){
            $not_cell = $unique_anatomies[1];
        } else {
            $not_cell = $unique_anatomies[0];
        }
        $sentence = $name . $helper_verb_several . $not_cell;
      }
    } else {
       my $count = 0;
       foreach my $a (@unique_anatomies){
        $count++;
        my $index = $count-1;
        if ($count == $size){
         $sentence .= "\, and the " . $unique_anatomies[$index];
        } elsif ($count == 1) {
         $sentence .= $unique_anatomies[$index];
       } else {
         $sentence .= "\, " . $unique_anatomies[$index];
       }
      }
      if ($sentence =~/Cell/){
          $sentence = $name . $helper_verb_several;
          $count = 0;
          my @no_cell = ();
       foreach my $a (@unique_anatomies){
          next if ($a =~/Cell/);
          push(@no_cell, $a);
       }
       my $new_size = @no_cell;
       if ($new_size gt 2){
       foreach my $a (@no_cell){
        $count++;
        my $index = $count-1;
        if ($count == $new_size){
         $sentence .= "\, and the " . $no_cell[$index];
        } elsif ($count == 1) {
         $sentence .= $no_cell[$index];
        } else {
         $sentence .= "\, " . $no_cell[$index];
        }
       }
      } else {
      $sentence .= $no_cell[0] . " and the " . $no_cell[1];
      }
     }
    }
    $sentence .="\;\n";

    write_file($output, {append => 1 }, $summary);
    write_file($output_genes, {append => 1 }, $gene_output);
    write_file($gene_id, $sentence);
}


sub get_ontology_parents_children {
my $input_file = shift;
my $ontology = shift;

my $ace_file = read_file($input_file);

my %parents=();
my %children=();
my (@terms) = split/$ontology\_term\:/, $ace_file;
foreach my $term (@terms){
  
  my $wb="";
  my $definition="";
  $term =~ s/^\s+//;
  $term =~ s/\s+$//;
  if ($term =~ m/^\"$ontology\:(.*)/) {
      $wb = $1; 
      $wb=~s/^\s+//; 
      $wb=~s/\s+$//; 
      $wb=~s/\"//g;
      chomp($wb); 
      $definition = "$ontology\:" . $wb;
  }
           
  my (@lines) = split/\n/, $term;
  foreach my $line (@lines) {
   if ($line =~/Descendent\t(.*)/){
      my $descendent = $1; 
      $descendent=~s/^\s+//; 
      $descendent=~s/\s+$//; 
      $descendent=~s/\"//g;
      chomp($descendent);   
#      print "$descendent\n";
      if ($definition){
          $children{$definition} .= $descendent . "\,"; 
      }   
    }
   if ($line =~/Ancestor\t(.*)/){
      my $ancestor = $1;
      $ancestor=~s/^\s+//; 
      $ancestor=~s/\s+$//; 
      $ancestor=~s/\"//g;
      chomp($ancestor);  
#      print "$ancestor\n";
      if ($definition){
          $parents{$definition} .= $ancestor . "\,";
      }    
    }

  }
} # foreach term

 return (\%parents, \%children);

}

1;
