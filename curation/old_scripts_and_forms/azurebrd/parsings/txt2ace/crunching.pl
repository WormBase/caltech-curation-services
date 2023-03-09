#!/usr/bin/perl
#
# Program to parse .txt files for reference data, pass args to .endnote, find
# label, and set refenced data from .txt to .ace file.

if ($#ARGV != 0) {			# if no file specified, ask for it
  print "Required : input *.txt file. \n";
  print "What will input file be ? ";
  $infile = <STDIN>;
} else {
  $infile = $ARGV[0];			# if specified, use it
}
chomp($infile);
$textfile = ($infile . ".txt");		# assign the textfile
$nopfile = ($infile . ".ace");		# assign the file to write results to 
$warningfile = warningfile;
$allace = alltxt.ace;
$tempfile = ($infile . ".tmp");		# a dummy file for getting rid of
					# leading  spaces

open (TEXT, "$textfile") || die "cannot open $textfile : $!"; 	 # open read
open (TEMP, ">$tempfile") || die "cannot create $tempfile : $!"; # open write

TEMPWRITE : while ($textline = <TEXT>) {	# while data
  chomp($textline);
  
  # get rid off spaces at beginning
  @textline = split(/\s+/, $textline);	# split to see first word
  if ($textline[0]) {			# if doesn't have a leading space
    @newtextline = @textline;		# use the line
  } else {				# if has leading space
    ($a, @newtextline) = @textline; 	# get rid off it
  }
  $textline = join(" ", @newtextline);	# put it together again

  # get rid off non-tags Expression_of, Expressed_in, Type at beginning
  @textline = split(/\s+/, $textline);	# split to see if non-tag
  if ($textline[0] eq "Type") {		# if not a valid type, skip line
    unless ( ($textline[1] =~ eporter) ||
             ($textline[1] =~ situ) ||
             ($textline[1] =~ ntibody) ) { next TEMPWRITE; }
  }
  if ( ($textline[0] eq "Expression_of") ||	# not a real tag
       ($textline[0] eq "Expressed_in") ||	# not a real tag
       ($textline[0] eq "Type") ) {		# not a real tag
    ($a, @newtextline) = @textline;	# so get rid of it
  } else {
    @textline = @newtextline;		# fine tags or lines, so keep them
  }
  $textline = join(" ", @newtextline);	# put it together again
  print TEMP "$textline\n";		# write to the tempfile
}

close (TEXT) || die "cannot close $textfile : $!";		# close read
close (TEMP) || die "cannot close $tempfile : $!";		# close write
  

open (TEMP2, "$tempfile") || die "cannot open $tempfile : $!";	# reopen read

while ($textline = <TEMP2>) {			# while lines
  chomp($textline);
  @textline = split(/\s+/, $textline);		# split them

  SWITCH : {				# SWITCH block to not read extra from
					# while
  if ($textline[0] =~ "Reference") {		# if Reference line
    $lastname = $textline[1];			# assign lastname
    $textline = join(" ", @textline);		# rejoin for quote splitting
    if ($textline =~ m/\D+(\d+)\-(\d+)\./) { $pages = "$1-$2";}
    @textline = split(/"/, $textline);		# separate into quotes
    $title = $textline[1];			# get quotes into $title
  } elsif ($textline[0] =~ "Sequence") {	# if Sequence line
    ($a, @sequence) = @textline;		# get rid off tag
    $sequence = join(" ", @sequence);		# put together again
    @seq = (@seq, $sequence);			# add data to array
  } elsif ($textline[0] =~ "Clone") {		# same as Sequence
    ($a, @clone) = @textline;
    $clone = join(" ", @clone);
    @clo = (@clo, $clone);
  } elsif ($textline[0] =~ "Locus") {		# same as Sequence
    ($a, @locus) = @textline;
    $locus = join(" ", @locus);
    @loc = (@loc, $locus);
  } elsif ($textline[0] =~ "Protein") {		# same as Sequence
    ($a, @protein) = @textline;
    $protein = join(" ", @protein);
    @pro = (@pro, $protein);
  } elsif ($textline[0] =~ Cells) {		# Cells is similar to Sequence
    ($a, @cells) = @textline;
    $cells = join(" ", @cells);
    if ($cells) { 				# comma separator
      @cells = split(/,/, $cells);
      foreach $_ (@cells) {
        @temp = split(/\s+/, $_);
        if ($temp[0] eq "") {
          ($a, @temp) = @temp;
        }
        $cells = join(" ", @temp);
        @cel = (@cel, $cells);
      } 	# foreach $_ (@cells)
    } 	# if ($cells)
    # if ($cells) { @cel = (@cel, $cells);}	# unless blank, add data
    until ( ($textline[0] =~ Cell_group) ||	# until new tag
            ($textline[0] =~ Life_stage) ||
            ($textline[0] =~ "Localisation") ||
            ($textline[0] =~ "Subcellular_localization") ||
            ($textline[0] =~ "Reporter_gene") ||
            ($textline[0] =~ "In_situ") ||
            ($textline[0] =~ "Antibody") ||
            ($textline[0] =~ "Pattern") ) {
        # read new line and go on unless EOF, in that case end SWITCH block
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      @textline = split(/\s+/, $textline);
        # if tag, redo SWITCH for new data
      redo SWITCH if ( ($textline[0] =~ Cell_group) ||
                       ($textline[0] =~ Life_stage) ||
                       ($textline[0] =~ "Localisation") ||
                       ($textline[0] =~ "Subcellular_localization") ||
                       ($textline[0] =~ "Reporter_gene") ||
                       ($textline[0] =~ "In_situ") ||
                       ($textline[0] =~ "Antibody") ||
                       ($textline[0] =~ "Pattern") );
      $cells = join(" ", @textline);		# otherwise put together again
      if ($cells) { 				# comma separator
        @cells = split(/,/, $cells);
        foreach $_ (@cells) {
          @temp = split(/\s+/, $_);
          if ($temp[0] eq "") {
            ($a, @temp) = @temp;
          }
          $cells = join(" ", @temp);
          @cel = (@cel, $cells);
        } 	# foreach $_ (@cells)
      } 	# if ($cells)
      # if ($cells) { @cel = (@cel, $cells);}	# and unless blank, add data
    }
  } elsif ($textline[0] =~ Cell_group) {	# same as Cells
    ($a, @cell_group) = @textline;
    $cell_group = join(" ", @cell_group);
    if ($cell_group) { @cgp = (@cgp, $cell_group);}
    until ( ($textline[0] =~ Cells) ||
            ($textline[0] =~ Life_stage) ||
            ($textline[0] =~ "Localisation") ||
            ($textline[0] =~ "Subcellular_localization") ||
            ($textline[0] =~ "Reporter_gene") ||
            ($textline[0] =~ "In_situ") ||
            ($textline[0] =~ "Antibody") ||
            ($textline[0] =~ "Pattern") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      @textline = split(/\s+/, $textline);
      redo SWITCH if ( ($textline[0] =~ Cells) ||
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
  } elsif ($textline[0] =~ "Life_stage") {	# similar to Cells
    ($a, @life_stage) = @textline; 		# get rid of "Life_stage"
    $life_stage = join(" ", @life_stage);	# put together again
    if ($life_stage) { 				# unless blank
      @life_stage = split(/,/, $life_stage);	# split by commas
      foreach $_ (@life_stage) {		# foreach of these
        @temp = split(/\s+/, $_);		# get rid of spaces
        if ($temp[0] eq "") {			# if led by a space
          ($a, @temp) = @temp;			# get rid of it
        }
        $life_stage = join(" ", @temp);
        @lif = (@lif, $life_stage);		# otherwise, add data
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
          }
          $life_stage = join(" ", @temp);
          @lif = (@lif, $life_stage);
        } 	# foreach $_ (@life_stage)
      } 	# if ($life_stage)
    }		# until ( (blah) || (blah) || etc ) {
  } elsif ($textline[0] =~ "Localisation") {	# same as Sequence
    ($a, @localisation) = @textline;
    $localisation = join(" ", @localisation);
    @los = (@los, $localisation);
  } elsif ($textline[0] =~ "Subcellular_localization") {   # same as Sequence
    ($a, @subcellular_localization) = @textline;
    $subcellular_localization = join(" ", @subcellular_localization);
    @sub = (@sub, $subcellular_localization);
  } elsif ($textline[0] =~ "Reporter_gene") {	# same as Sequence
    ($a, @reporter_gene) = @textline;
    $reporter_gene = join(" ", @reporter_gene);
    @rep = (@rep, $reporter_gene);
  } elsif ($textline[0] =~ "In_situ") {		# same as Sequence
    ($a, @in_situ) = @textline;
    $in_situ = join(" ", @in_situ);
    @ins = (@ins, $in_situ);
  } elsif ($textline[0] =~ "Antibody") {	# same as Sequence
    ($a, @antibody) = @textline;
    $antibody = join(" ", @antibody);
    @ant = (@ant, $antibody);
  } elsif ($textline[0] =~ "Transgene") {	# same as Sequence
    ($a, @transgene) = @textline;
    $transgene = join(" ", @transgene);
    @tra = (@tra, $transgene);
  } elsif ($textline[0] =~ "Pattern") {		# similar to Sequence
    ($a, @pattern) = @textline;
    $pattern = join(" ", @pattern);
    if ($pattern) { @pat = (@pat, $pattern);}
    until ( ($textline[0] =~ "Remark") ||	# until next tag
            ($textline[0] =~ "Transgene") ) {
        # read next line; if EOF, exit SWITCH block
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      @textline = split(/\s+/, $textline);
        # if tag, redo SWITCH block
      redo SWITCH if ( ($textline[0] =~ "Remark") ||		
                        ($textline[0] =~ "Transgene") );
      $pattern = join(" ", @textline);
      if ($pattern) { @pat = (@pat, $pattern);}
    }
  } elsif ($textline[0] =~ "Remark") {		# same as Pattern
    ($a, @remark) = @textline;
    $remark = join(" ", @remark);
    if ($remark) { @rem = (@rem, $remark);}
    until ( ($textline[0] =~ "Transgene") ||
            ($textline[0] =~ "Pattern") ) {
      unless (defined ($textline = <TEMP2>) ) {last SWITCH}
      chomp($textline);
      @textline = split(/\s+/, $textline);
      redo SWITCH if ( ($textline[0] =~ "Transgene") ||
                        ($textline[0] =~ "Pattern") );
      $remark = join(" ", @textline);
      if ($remark) { @rem = (@rem, $remark);}
    }
  } elsif ($textline[0] eq "") {	# if blank line, ignore
  } else {				# if something not planned for
    $warning = 1;			# flag it
    @warning = (@warning, $textline);	# write lines that made problem
  } # if {} elsif { etc

  } # SWITCH
} # while

# get rid of repeats in Life_stage
LABEL : foreach $lif (@lif) {		# for all that are
  foreach $lif2 (@lif2) {		# for all that will be
    if ($lif2 eq $lif) {		# if they match
      next LABEL;			# skip and not write it
    }
  }	# foreach $lif2 (@lif2)		
  @lif2 = (@lif2, $lif);		# write each $lif that's not a copy
}	# LABEL : foreach $lif (@lif)

# get rid of repeats in Cells
LABEL2 : foreach $cel (@cel) {		# for all that are
  foreach $cel2 (@cel2) {		# for all that will be
    if ($cel2 eq $cel) {		# if they match
      next LABEL2;			# skip and not write it
    }
  }	# foreach $cel2 (@cel2)		
  @cel2 = (@cel2, $cel);		# write each $cel that's not a copy
}	# LABEL2 : foreach $cel (@cel)

close (TEMP2) || die "cannot close $tempfile : $!";

# empty tempfile
open (ERASE, ">$tempfile") || die "cannot create $tempfile : $!"; # open write
print ERASE "";				# write nothing to free space
close (ERASE) || die "cannot close $tempfile : $!";		  # close write

# search for label
open(ENDNOTE, "gophbib.endnote") || die "cannot open gophbib.endnote : $!";
while ($endline = <ENDNOTE>) {
  if ($endline =~ $lastname && $endline =~ $pages) {
    @endline = split(/\s+/, $endline);
    $label = $endline[0];
  }
}
close(ENDNOTE) || die "cannot close gophbib.endnote : $!";

# warnings for unhandled data
# open(WARN, ">> $warningfile ") || die "cannot open $warningfile : $!";
# if ($warning) {
#   print WARN "Warning : Some data may be lost from $textfile. \n";
#   print "Warning : Some data may be lost from $textfile. \n";
# }
# foreach $_ (@warning) {print WARN "Warning :       \"$_\"\n\n";}
# close(WARN) || die "cannot close $warningfile : $!";

# write to ace file
open(NOP, ">$nopfile") || die "cannot create $nopfile : $!"; 	# open write
if ($warning) {
  print NOP "Warning : Some data may be lost from $textfile. \n";
  print "Warning : Some data may be lost from $textfile. \n";
}
foreach $_ (@warning) {print NOP "Warning :       \"$_\"\n\n";}
print NOP "Reference       [cgc$label] \n";
foreach $_ (@seq) {print NOP "Sequence        \"$_\"\n";}
foreach $_ (@clo) {print NOP "Clone           \"$_\"\n";}
foreach $_ (@loc) {print NOP "Locus           \"$_\"\n";}
foreach $_ (@pro) {print NOP "Protein         \"$_\"\n";}
foreach $_ (@cel2) {print NOP "Cells           \"$_\"\n";}
foreach $_ (@cgp) {print NOP "Cell_group      \"$_\"\n";}
foreach $_ (@lif2) {print NOP "Life_stage      \"$_\"\n";}
foreach $_ (@los) {print NOP "Localisation    \"$_\"\n";}
foreach $_ (@sub) {print NOP "Subcellular_loc \"$_\"\n";}
foreach $_ (@rep) {print NOP "Reporter_gene   \"$_\"\n";}
foreach $_ (@ins) {print NOP "In_situ         \"$_\"\n";}
foreach $_ (@ant) {print NOP "Antibody        \"$_\"\n";}
# if ($pat[0]) {print NOP "Pattern         \"@pat\"\n";}
if ($pat[0]) {
  print NOP "Pattern         \"";
  foreach $_ (@pat) {print NOP "$_\t\t";}
  print NOP "\"\n";
}
# if ($rem[0]) {print NOP "Remark          \"@rem\"\n";}
if ($rem[0]) {
  print NOP "Remark          \"";
  foreach $_ (@rem) {print NOP "$_\t\t";}
  print NOP "\b\b\"\n";
}
foreach $_ (@tra) {print NOP "Transgene       \"$_\"\n";}
close(NOP) || die "cannot close $nopfile : $!";			# close write


