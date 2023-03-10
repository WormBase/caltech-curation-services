#!/usr/bin/perl -w

# parse ggi objects to match with sentences from textpresso for Chris.  2011 12 01

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %ginToNum;
my $result = $dbh->prepare( "SELECT * FROM gin_sequence" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $ginToNum{$row[1]} = $row[0]; } }
$result = $dbh->prepare( "SELECT * FROM gin_synonyms" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $ginToNum{$row[1]} = $row[0]; } }
$result = $dbh->prepare( "SELECT * FROM gin_locus" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $ginToNum{$row[1]} = $row[0]; } }


my %junk_names; my %sentdata;
my @files = qw( html_20060307.txt ggi_20091002 ggi_20101130 );
foreach my $file (@files) {
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $line = <IN>) {
    chomp $line;
    my @genes;
    my $flag = 0;
    my ($num, $paper_stuff, $gene_names, $sentence, $extrasentence) = split/\t/, $line;
    unless ($sentence) { $sentence = $extrasentence; }	# some files have an extra tab before the sentence
    my ($paper) = $paper_stuff =~ m/(WBPaper\d+)/;
    my %gene_names;
    my (@temp) = split/; /, $gene_names;
    foreach my $temp (@temp) { 
      my (@temp2) = split/, /, $temp;
      foreach my $temp2 (@temp2) { $gene_names{$temp2}++; } }
    foreach my $gin (keys %gene_names) { 
      $gin =~ s/\s//g;
      my ($lcgin) = lc($gin);
      if ($ginToNum{$gin}) { 
#           if ($ginToNum{$gin} eq '00004760') { $flag++; print "LINE $line ENDLINE\n"; }
          push @genes, $ginToNum{$gin}; }
        elsif ($ginToNum{$lcgin}) { 
          push @genes, $ginToNum{$lcgin}; }
        else { $junk_names{$gin}++; }
    }
    my $genes = join",", @genes;
    $sentdata{$paper}{$genes}{$sentence}++;
#     if ($flag) { print "PAPER $paper GENES $genes SENT $sentence END\n"; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $file : $!";
} # foreach my $file (@files)

# foreach my $junk_gene (sort keys %junk_names) { print "$junk_gene does not match a WBGene\n"; }


my %filter;
my $infile = 'Textpresso_sentence_interactions_table.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($intid, $inttype, $paper, $gene) = split/\t/, $line;
  if ($filter{$intid}{$inttype}{$paper}{geneone}) { $filter{$intid}{$inttype}{$paper}{genetwo} = $gene; }
    elsif ($filter{$intid}{$inttype}{$paper}{genetwo}) { print "ERR $intid $inttype $paper has more than two genes\n"; }
    else { $filter{$intid}{$inttype}{$paper}{geneone} = $gene; }
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

# my %source;
foreach my $intid (keys %filter) {
  foreach my $inttype (keys %{ $filter{$intid} }) {
    foreach my $paper (keys %{ $filter{$intid}{$inttype} }) {
      my $geneone = $filter{$intid}{$inttype}{$paper}{geneone};
      my $genetwo = $filter{$intid}{$inttype}{$paper}{genetwo};
      $geneone =~ s/WBGene//; $genetwo =~ s/WBGene//;
      if ($sentdata{$paper}) {
        my $match_found = 0;
        foreach my $sentgenes (sort keys %{ $sentdata{$paper} }) {
          my $matches = 0;
          my (@sentgenes) = split/,/, $sentgenes;
          foreach my $sentgene (@sentgenes) { if ( ($geneone eq $sentgene) || ($genetwo eq $sentgene) ) { $matches++; } }
          if ($matches > 1) { 
            foreach my $sentence (sort keys %{ $sentdata{$paper}{$sentgenes} }) {
              $match_found++;
              print "MATCH\t$intid\t$paper\tWBGene$geneone\tWBGene$genetwo\t$sentence\n";
            } # foreach my $sentence (sort keys %{ $sentdata{$paper}{$sentgenes} })
          } # if ($matches > 1) 
        } # foreach my $sentgenes (sort keys %{ $sentdata{$paper} })
#         unless ($match_found) { print "NO SENTENCE MATCH $intid $inttype $paper WBGene$geneone WBGene$genetwo\n"; }
      } # if ($sentdata{$paper})
#       else { print "NO PAPER MATCH $intid $inttype $paper WBGene$geneone WBGene$genetwo\n"; }

#       my $lower = $geneone; my $higher = $genetwo;
#       unless ($higher) { 
# #         print "NO second gene for $intid\n"; 
#         $higher = 0; }
#       $lower =~ s/WBGene//; $higher =~ s/WBGene//;
#       if ($lower < $higher) { my $temp = $lower; $lower = $higher; $higher = $temp; }
#       my $key = "$paper\t$lower\t$higher";
#       $source{$key}{paper} = $paper;
#       $source{$key}{geneone} = $lower;
#       $source{$key}{genetwo} = $higher;
#       $source{$key}{inttype} = $inttype;
#       $source{$key}{intid} = $intid;
} } }

__END__


my $result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

WBInteraction0000646	Genetic	WBPaper00000031	WBGene00004856	
WBInteraction0000646	Genetic	WBPaper00000031	WBGene00003056	
WBInteraction0000131	Genetic	WBPaper00000164	WBGene00006787	
WBInteraction0000131	Genetic	WBPaper00000164	WBGene00006744	
WBInteraction0000132	Genetic	WBPaper00000164	WBGene00006788	
WBInteraction0000132	Genetic	WBPaper00000164	WBGene00006787	
WBInteraction0000133	Genetic	WBPaper00000164	WBGene00006789	
WBInteraction0000133	Genetic	WBPaper00000164	WBGene00006743	
WBInteraction0000685	Genetic	WBPaper00000317	WBGene00003515	
WBInteraction0000685	Genetic	WBPaper00000317	WBGene00006754	


1	WBPaper00026680 : s5	slt-1; vab-1	 A<font color=red> double-mutant </font>combination between<font color=blue> vab-1 </font>and<font color=blue> slt-1 </font>unmasks a role for the SLT-1 ligand in embryogenesis . <BR>
2	WBPaper00026680 : s25	sax-3; vab-1	 We report that<font color=red> double-mutant </font>combinations in<font color=blue> sax-3 </font>and<font color=blue> vab-1 </font>display a completely penetrant embryonic lethal phenotype . <BR>
3	WBPaper00026680 : s26	slt-1; vab-1	 Furthermore ,<font color=red> double-mutant </font>combinations between<font color=blue> vab-1 </font>and 3680 Development 132 ( 16 )<font color=blue> slt-1 </font>, the ligand for SAX-3 , show significantly<font color=red> enhanced</font> cell migration defects in comparison with<font color=blue> vab-1 </font>single mutants , revealing a role for SLT-1 in embryogenesis . <BR>
4	WBPaper00026680 : s34	dpy-10; ptp-3; vab-1	<font color=red> Rearrangement</font> : mIn1 [ mIs14<font color=blue> dpy-10 </font>( e128 ) ] II ( Edgley and Riddle , 2001 ) ; mIn1 mIs14 ( a . k . a . mIn1GFP throughout this paper ) is a dominant green fluorescent protein ( GFP ) balancer for chromosome II , including the region of<font color=blue> vab-1 </font>and<font color=blue> ptp-3 </font>. <BR>
5	WBPaper00026680 : s37	sax-3; vab-1	 De<font color=red> Double-mutant </font>constructs<font color=blue> vab-1 </font>( weak ) ;<font color=blue> sax-3 </font>double mutants were completely inviable and were maintained as balanced strains of the genotype<font color=blue> vab-1 </font>( e2 or e699 ) mIn GFP ;<font color=blue> sax-3 </font>( ky123 ) . <BR>
6	WBPaper00026680 : s76	sax-3; unc-54	 Transgenic rescue and reporter constructs To create a rescuing SAX-3 : : GFP reporter ( quEx89 ) , we used a PCR fusion-based approach ( Hobert , 2002 ) to generate a PCR ( Roche<font color=red> Expand </font>Long PCR ) product consisting of 1 . 2 kb of the<font color=blue> sax-3 </font>promoter , the<font color=blue> sax-3 </font>genomic region ( exons 1-5 ) followed by the rest of the<font color=blue> sax-3 </font>cDNA fused in frame to GFP and<font color=blue> unc-54 </font>3UTR sequences derived from pPD95 . 75 ( Dr A Fire is laboratory ) . <BR>
7	WBPaper00026680 : s96	slt-1; vab-1	<font color=blue> vab-1 </font>;<font color=blue> slt-1 </font>does not display synthetic lethality but the phenotypes are <font color=red>enhanced </font>. <BR>
8	WBPaper00026680 : s101	sax-3; vab-1	 We made<font color=red> double-mutant </font>combinations with a putative null allele of<font color=blue> sax-3 </font>( ky123 ) ( Zallen et al , 1998 ) and various alleles of<font color=blue> vab-1 </font>[ e2 , e699 , dx31 ; weak , intermediate and strong ( null ) , respectively ] ( George et al , 1998 ) . <BR>
9	WBPaper00026680 : s102	sax-3; vab-1	 All<font color=blue> vab-1 </font>alleles showed 100 embryonic lethality with<font color=blue> sax-3 </font>( ky123 ) , and the weak<font color=blue> vab-1 </font>alleles showed a <font color=green>synergistic</font><font color=green> interaction</font> with<font color=blue> sax-3 </font>, as the lethality was more than additive ( Fig 1 ) . <BR>
10	WBPaper00026680 : s103	gene-; sax-3; vab-1	 In the course of making<font color=red> double-mutant </font>combinations with<font color=blue> vab-1 </font>and sax-3Robo , we identified a <font color=blue>gene-</font>dosage dependence of<font color=blue> vab-1 </font>in that<font color=blue> vab-1 </font>( dx31 ) ;<font color=blue> sax-3 </font>heterozygotes were completely inviable ( see Materials and methods ) . <BR>
