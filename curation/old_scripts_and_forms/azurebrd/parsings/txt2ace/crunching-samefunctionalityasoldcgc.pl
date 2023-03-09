#!/usr/bin/perl
#
# Program to parse .txt files for reference data, pass args to .endnote, find
# label, and set refenced data from .txt to .ace file.

if ($#ARGV != 0) {
  print "Required : input *.txt file. \n";
  print "What will input file be ? ";
  $infile = <STDIN>;
} else {
  $infile = $ARGV[0];
}
chomp($infile);
$textfile = ($infile . ".txt");
$nopfile = ($infile . ".nop");
$tempfile = ($infile . ".tmp");


open (TEXT, "$textfile") || die "cannot open $textfile : $!";
open (TEMP, ">$tempfile") || die "cannot create $tempfile : $!";

while ($textline = <TEXT>) {
  chomp($textline);
  
  # get rid off spaces at beginning
  @textline = split(/\s+/, $textline);
  # foreach $_ (@textline) {if ($_) {print "$_ \n";} }
  if ($textline[0]) {
    @newtextline = @textline;
  } else {
    ($a, @newtextline) = @textline; 
  }
  $textline = join(" ", @newtextline);
  # print "$textline\n";

  # get rid off non-tags Expression_of, Expressed_in, Type at beginning
  @textline = split(/\s+/, $textline);
  if ( ($textline[0] eq "Expression_of") ||
       ($textline[0] eq "Expressed_in") ||
       ($textline[0] eq "Type") ) {
    ($a, @newtextline) = @textline;
  } else {
    @textline = @newtextline;
  }
  $textline = join(" ", @newtextline);
  print TEMP "$textline\n";
}

close (TEXT) || die "cannot close $textfile : $!";
close (TEMP) || die "cannot close $tempfile : $!";
  

open (TEMP2, "$tempfile") || die "cannot open $tempfile : $!";

while ($textline = <TEMP2>) {
  chomp($textline);
  @textline = split(/\s+/, $textline);

  SWITCH : {

  if ($textline[0] =~ "Reference") {
    ($a, @reference) = @textline;
    $reference = join(" ", @reference);
    @ref = (@ref, $reference);
      # print NOP "Reference : $reference\n";
  } elsif ($textline[0] =~ "Sequence") {
    ($a, @sequence) = @textline;
    $sequence = join(" ", @sequence);
    @seq = (@seq, $sequence);
      # print NOP "Sequence : $sequence\n";
  } elsif ($textline[0] =~ "Clone") {
    ($a, @clone) = @textline;
    $clone = join(" ", @clone);
    @clo = (@clo, $clone);
      # print NOP "Clone : $clone\n";
  } elsif ($textline[0] =~ "Locus") {
    ($a, @locus) = @textline;
    $locus = join(" ", @locus);
    @loc = (@loc, $locus);
      # print NOP "Locus : $locus\n";
  } elsif ($textline[0] =~ "Protein") {
    ($a, @protein) = @textline;
    $protein = join(" ", @protein);
    @pro = (@pro, $protein);
      # print NOP "Protein : $protein\n";
  } elsif ($textline[0] =~ "Cells") {
    ($a, @cells) = @textline;
    $cells = join(" ", @cells);
    if ($cells) { @cel = (@cel, $cells);}
    until ( ($textline[0] =~ "Cell_group") ||
            ($textline[0] =~ Life_stage) ||
            ($textline[0] =~ "Localisation") ||
            ($textline[0] =~ "Subcellular_localization") ||
            ($textline[0] =~ "Reporter_gene") ||
            ($textline[0] =~ "In_situ") ||
            ($textline[0] =~ "Antibody") ||
            ($textline[0] =~ "Pattern") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      print "$textline\n";
      @textline = split(/\s+/, $textline);
      redo SWITCH if ( ($textline[0] =~ "Cell_group") ||
                       ($textline[0] =~ Life_stage) ||
                       ($textline[0] =~ "Localisation") ||
                       ($textline[0] =~ "Subcellular_localization") ||
                       ($textline[0] =~ "Reporter_gene") ||
                       ($textline[0] =~ "In_situ") ||
                       ($textline[0] =~ "Antibody") ||
                       ($textline[0] =~ "Pattern") );
      $cells = join(" ", @textline);
      if ($cells) { @cgp = (@cgp, $cells);}
    }
  } elsif ($textline[0] =~ "Cell_group") {
    ($a, @cell_group) = @textline;
    $cell_group = join(" ", @cell_group);
    if ($cell_group) { @cel = (@cel, $cell_group);}
    until ( ($textline[0] =~ "Cells") ||
            ($textline[0] =~ Life_stage) ||
            ($textline[0] =~ "Localisation") ||
            ($textline[0] =~ "Subcellular_localization") ||
            ($textline[0] =~ "Reporter_gene") ||
            ($textline[0] =~ "In_situ") ||
            ($textline[0] =~ "Antibody") ||
            ($textline[0] =~ "Pattern") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      print "$textline\n";
      @textline = split(/\s+/, $textline);
      redo SWITCH if ( ($textline[0] =~ "Cells") ||
                       ($textline[0] =~ Life_stage) ||
                       ($textline[0] =~ "Localisation") ||
                       ($textline[0] =~ "Subcellular_localization") ||
                       ($textline[0] =~ "Reporter_gene") ||
                       ($textline[0] =~ "In_situ") ||
                       ($textline[0] =~ "Antibody") ||
                       ($textline[0] =~ "Pattern") );
      $cell_group = join(" ", @textline);
      if ($cell_group) { @cgp = (@cgp, $cell_group);}
    }
  } elsif ($textline[0] =~ "Life_stage") {
    ($a, @life_stage) = @textline; 		# get rid of "Life_stage"
    $life_stage = join(" ", @life_stage);	# put together again
    if ($life_stage) { 				# unless blank
      @life_stage = split(/,/, $life_stage);	# split by commas
      foreach $_ (@life_stage) {		# foreach of these
        @temp = split(/\s+/, $_);		# get rid of spaces
        if ($temp[0] eq "") {			# if led by a space
          ($a, @temp) = @temp;			# get rid of it
        } else {				# if not led by a space
          # @life_stage = @temp;		# nothing happens
        }
        $life_stage = join(" ", @temp);
        # foreach $_ (@temp) {			# foreach of these
        #   @lif = (@lif, $_);			# add to @lif
        # } 	# foreach $_ (@temp)
        @lif = (@lif, $life_stage);
      }		# foreach $_ (@life_stage)
    }		# if ($life_stage)
    until ( ($textline[0] =~ "Cell_group") ||
            ($textline[0] =~ "Cells") ||
            ($textline[0] =~ "Localisation") ||
            ($textline[0] =~ "Subcellular_localization") ||
            ($textline[0] =~ "Reporter_gene") ||
            ($textline[0] =~ "In_situ") ||
            ($textline[0] =~ "Antibody") ||
            ($textline[0] =~ "Pattern") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      @textline = split(/\s+/, $textline);
      unless ($textline[0] =~ eporter_gene) {print "$textline\n";}
      redo SWITCH if ( ($textline[0] =~ "Cell_group") ||
                       ($textline[0] =~ "Cells") ||
                       ($textline[0] =~ "Localisation") ||
                       ($textline[0] =~ "Subcellular_localization") ||
                       ($textline[0] =~ "Reporter_gene") ||
                       ($textline[0] =~ "In_situ") ||
                       ($textline[0] =~ "Antibody") ||
                       ($textline[0] =~ "Pattern") );
      $life_stage = join(" ", @textline);
      if ($life_stage) { 
        @life_stage = split(/,/, $life_stage);
        foreach $_ (@life_stage) {
          @temp = split(/\s+/, $_);
          if ($temp[0] eq "") {
            ($a, @temp) = @temp;
          } else {
            # @life_stage = @temp;
          }
          $life_stage = join(" ", @temp);
          @lif = (@lif, $life_stage);
        } 	# foreach $_ (@life_stage)
      } 	# if ($life_stage)
    }		# until ( (blah) || (blah) || etc ) {
  } elsif ($textline[0] =~ "Localisation") {
    ($a, @localisation) = @textline;
    $localisation = join(" ", @localisation);
    @los = (@los, $localisation);
  } elsif ($textline[0] =~ "Subcellular_localization") {
    ($a, @subcellular_localization) = @textline;
    $subcellular_localization = join(" ", @subcellular_localization);
    @sub = (@sub, $subcellular_localization);
  } elsif ($textline[0] =~ "Reporter_gene") {
    ($a, @reporter_gene) = @textline;
    $reporter_gene = join(" ", @reporter_gene);
    @rep = (@rep, $reporter_gene);
  } elsif ($textline[0] =~ "In_situ") {
    ($a, @in_situ) = @textline;
    $in_situ = join(" ", @in_situ);
    @ins = (@ins, $in_situ);
  } elsif ($textline[0] =~ "Antibody") {
    ($a, @antibody) = @textline;
    $antibody = join(" ", @antibody);
    @ant = (@ant, $antibody);
  } elsif ($textline[0] =~ "Transgene") {
    ($a, @transgene) = @textline;
    $transgene = join(" ", @transgene);
    @tra = (@tra, $transgene);
  } elsif ($textline[0] =~ "Pattern") {
    ($a, @pattern) = @textline;
    $pattern = join(" ", @pattern);
    if ($pattern) { @pat = (@pat, $pattern);}
    until ( ($textline[0] =~ "Remark") ||
            ($textline[0] =~ "Transgene") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      # print "$textline\n";
      @textline = split(/\s+/, $textline);
      redo SWITCH if ( ($textline[0] =~ "Remark") ||
                        ($textline[0] =~ "Transgene") );
      $pattern = join(" ", @textline);
      if ($pattern) { @pat = (@pat, $pattern);}
    }
  } elsif ($textline[0] =~ "Remark") {
    ($a, @remark) = @textline;
    $remark = join(" ", @remark);
    if ($remark) { @rem = (@rem, $remark);}
    until ( ($textline[0] =~ "Transgene") ||
            ($textline[0] =~ "Pattern") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      # print "$textline\n";
      @textline = split(/\s+/, $textline);
      redo SWITCH if ( ($textline[0] =~ "Transgene") ||
                        ($textline[0] =~ "Pattern") );
      $remark = join(" ", @textline);
      if ($remark) { @rem = (@rem, $remark);}
    }
      
     
  } else {
  }
  
  # foreach $_ (@newtextline) {print "$_ \n";}
  # print "newline \n";

  } # SWITCH
} # while

close (TEMP2) || die "cannot close $tempfile : $!";






# open(ENDNOTE, "gophbib.endnote") || die "cannot open gophbib.endnote : $!";
# while ($endline = <ENDNOTE>) {
#   if ($endline =~ $lastname && $endline =~ $title) {
#     @endline = split(/\s+/, $endline);
#     $label = $endline[0];
#     print "label is $label. \n";
#   }
# }
# close(ENDNOTE) || die "cannot close gophbib.endnote : $!";



open(NOP, ">$nopfile") || die "cannot create $nopfile : $!";
foreach $_ (@ref) {print NOP "Reference       \"$_\"\n";}
foreach $_ (@seq) {print NOP "Sequence        \"$_\"\n";}
foreach $_ (@clo) {print NOP "Clone           \"$_\"\n";}
foreach $_ (@loc) {print NOP "Locus           \"$_\"\n";}
foreach $_ (@pro) {print NOP "Protein         \"$_\"\n";}
foreach $_ (@cel) {print NOP "Cells           \"$_\"\n";}
foreach $_ (@cgp) {print NOP "Cell_group      \"$_\"\n";}
foreach $_ (@lif) {print NOP "Life_stage      \"$_\"\n";}
foreach $_ (@los) {print NOP "Localisation    \"$_\"\n";}
foreach $_ (@sub) {print NOP "Subcellular_loc \"$_\"\n";}
foreach $_ (@rep) {print NOP "Reporter_gene   \"$_\"\n";}
foreach $_ (@ins) {print NOP "In_situ         \"$_\"\n";}
foreach $_ (@ant) {print NOP "Antibody        \"$_\"\n";}
if ($pat[0]) {print NOP "Pattern         \"@pat\"\n";}
# foreach $_ (@rem) {print NOP "Remark          \"$_\"\n";}
if ($rem[0]) {print NOP "Remark          \"@rem\"\n";}
foreach $_ (@tra) {print NOP "Transgene       \"$_\"\n";}
close(NOP) || die "cannot close $nopfile : $!";

# open(ACE, ">$acefile") || die "cannot create $acefile : $!";
# print ACE "Reference       [cgc$label] \n";
# close(ACE) || die "cannot close $acefile : $!";


