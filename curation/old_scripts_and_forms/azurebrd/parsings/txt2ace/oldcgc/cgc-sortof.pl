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
$acefile = ($infile . ".ace");

open (TEXT, "$textfile") || die "cannot open $textfile : $!";

while ($textline = <TEXT>) {
  chomp($textline);

  SWITCH: {

    if ($textline =~ Reference) {
      print "Reference : $textline \n";
      @textline = split(/"/, $textline);
      # foreach $textline (@textline) { print "oop1  $textline \n"; }
  
      # $title is cut out to only be the first 3 words of the title because
      #  the .endnote file often does not have quotes around the title or
      #  has typos (ex : label 746) or uses different symbols (ex : label 1850)
      #  searching for the first 3 words of the title will hopefully minimize
      #  the number of mismatches (from same beginning of title) and lack of
      #  matches (from typos or different symbols).  still broken for label
      #  3049, Postembyonic vs Post-embryonic
      $title = $textline[1];
      @title = split(/\s+/, $title);
      $title = join(" ", $title[0], $title[1], $title[2]);
      # foreach $title (@title) {print "$title \n"; }
      print "Title is $title. \n";
   
      # $lastname is used as a primary search parameter since $title has
      #  various problems in differing with the .endnote.
      @textline = split(/\s+/, $textline);
      $lastname = $textline[1];
        print "Lastname is $lastname. \n";
    }

    if ( $textline =~ Expression_of ) {  
      # print "Text1 : $textline \n";
      #($a, @textline) = split(/\s+/, $textline);
      #$textline = join(" ", @textline);
      # print "Text2 : $textline \n";
      EXPOF: {
        until ( ($textline =~ Expressed_in) || ($textline =~ Type) || 
             ($textline eq "") ) {
          # print "Text3 : $textline \n";
          if ($textline =~ Sequence) {
            until ($a eq "Sequence") {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
            }
            until ( ($textline =~ Clone) || ($textline =~ Locus) ||
                 ($textline =~ Protein) || ($textline =~ Expressed_in) ) {
              print "Sequence : $textline \n";
              (@sequence) = split(/\s+/, $textline);
              print "Sequence is @sequence. \n";
              $textline = <TEXT>;
              chomp($textline);
              redo EXPOF if ( ($textline =~ Clone) || ($textline =~ Locus) ||
                  ($textline =~ Protein) || ($textline eq "") );
            }
          }
          if ($textline =~ Clone) {
            until ($a eq "Clone") {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
            }
            until ( ($textline =~ Sequence) || ($textline =~ Locus) ||
                 ($textline =~ Protein) || ($textline =~ Expressed_in) ) {
              print "Clone : $textline \n";
              (@clone) = split(/\s+/, $textline);
              print "Clone is @clone. \n";
              $textline = <TEXT>;
              chomp($textline);
              redo EXPOF if ( ($textline =~ Sequence) || ($textline =~ Locus) ||
                  ($textline =~ Protein) || ($textline eq "") );
            }
          }
          if ($textline =~ Locus) {
            # print "Text4 : $textline \n";
            until ($a eq "Locus") {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
            }
            until ( ($textline =~ Clone) || ($textline =~ Sequence) ||
                 ($textline =~ Protein) || ($textline =~ Expressed_in) ) {
              print "Locus : $textline \n";
              (@locus) = split(/\s+/, $textline);
              print "Locus is @locus. \n";
              $textline = <TEXT>;
              chomp($textline);
              redo EXPOF if ( ($textline =~ Clone) || ($textline =~ Sequence) ||
                  ($textline =~ Protein) || ($textline eq "") );
            }
          }
          if ($textline =~ Protein) {
            until ($a eq "Protein") {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
            }
            until ( ($textline =~ Clone) || ($textline =~ Locus) ||
                 ($textline =~ Sequence) || ($textline =~ Expressed_in) ) {
              print "Protein : $textline \n";
              (@protein) = split(/\s+/, $textline);
              print "Protein is @protein. \n";
              $textline = <TEXT>;
              chomp($textline);
              redo EXPOF if ( ($textline =~ Clone) || ($textline =~ Locus) ||
                  ($textline =~ Sequence) || ($textline eq "") );
            }
          } 	# if    Protein 
        }	# until Expressed_in 
      }		# EXPOF block
    } 		# if    Expression_of 

    if ( $textline =~ Expressed_in ) {
      EXPIN: {
        until ( ($textline =~ Localisation) || ($textline =~ 
            Subcellular_localization) || ($textline =~ Type) ||
            ($textline eq "") ) {

          if ( $textline =~ Cell_group )  {
            print "Cell_group :  $textline \n";
            until ( ($a eq "Cell_group") || ($a eq "Cell_groups") ) {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
              print "Oop1 : $textline \n";
            }
            @cellgroup = split(/\s+/, $textline);
            push @cellgroupextra, [@cellgroup];
            until ( ($textline =~ Cells) || ($textline =~ Life_stag) ||
                ($textline =~ Type) || ($textline =~ Localisation) ||
                ($textline =~ Subcellular_loc) ) { # ||
                #  ($textline eq "") ) {
              print "Oop2 : $textline \n";
              $textline = <TEXT>;
              chomp($textline);
              print "Oop3 : $textline \n";
              redo EXPIN if ( ($textline =~ Cells) || 
                  ($textline =~ Life_stag) || ($textline =~ Type) || 
                  ($textline =~ Localisation) ||
                  ($textline =~ Subcellular_loc) ); #|| 
                  # ($textline eq "") );
              @textline = split(/\s+/, $textline);
              if ($textline[0] eq "") {
                $textline = join(" ", @textline);
		print "Oop5 : $textline \n";
                ($a, @cellgroup) = split(/\s+/, $textline);
              }
              push @cellgroupextra, [@cellgroup];
            }
            $textline = <TEXT>;
            chomp($textline);
            if ($textline = "") {
              $textline = <TEXT>;
              chomp($textline);
            }
            print "Oop6 : $textline \n";
          }
        
          if ( $textline =~ Cells )  {
            print "Cells :  $textline \n";
            until ( ($a eq "Cells") || ($a eq "Cell") ) {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
              print "Koo1 : $textline \n";
            }
            @cells= split(/\s+/, $textline);
              push @cellsextra, [@cells];
            until ( ($textline =~ Cell_group) || ($textline =~ Life_stag) ||
                ($textline =~ Type) || ($textline =~ Localisation) ||
                ($textline =~ Subcellular_loc) ) { #||
                # ($textline eq "") ) {
              print "Koo2 : $textline \n";
              $textline = <TEXT>;
              chomp($textline);
              print "Koo3 : $textline \n";
              redo EXPIN if ( ($textline =~ Cell_group) || 
                  ($textline =~ Life_stag) || ($textline =~ Type) || 
                  ($textline =~ Localisation) ||
                ($textline =~ Subcellular_loc) ); # || ($textline eq "") );
              @textline = split(/\s+/, $textline);
              if ($textline[0] eq "") {
                $textline = join(" ", @textline);
		print "Koo4 : $textline \n";
                ($a, @cells) = split(/\s+/, $textline);
              }
              push @cellsextra, [@cells];
            }
            $textline = <TEXT>;
             chomp($textline);
             if ($textline = "") {
               $textline = <TEXT>;
               chomp($textline);
             }
             print "Koo6 : $textline \n";
          } # if =~ Cells

          if ( $textline =~ Life_stag )  {
            print "Life_stage :  $textline \n";
            until ( ($a eq "Life_stages") || ($a eq "Life_stage") ) {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
              print "oMo1 : $textline \n";
            }
            @lifestages = split(/\s+/, $textline);
              push @lifestagesextra, [@lifestages];
            until ( ($textline =~ Cell_group) || ($textline =~ Cells) ||
                ($textline =~ Type) || ($textline =~ Localisation) ||
                ($textline =~ Subcellular_loc) ) { # ||
                # ($textline eq "") ) {
              print "oMo2 : $textline \n";
              $textline = <TEXT>;
              chomp($textline);
              print "oMo3 : $textline \n";
              redo EXPIN if ( ($textline =~ Cell_group) || 
                  ($textline =~ Cells) || ($textline =~ Type) || 
                  ($textline =~ Localisation) ||
                  ($textline =~ Subcellular_loc) ); # || ($textline eq "") );
              @textline = split(/\s+/, $textline);
              if ($textline[0] eq "") {
                $textline = join(" ", @textline);
		print "oMo4 : $textline \n";
#about to mess here                ($a, @lifestages) = split(/\s+/, $textline);
              }
              push @lifestagesextra, [@lifestages];
            }
              $textline = <TEXT>;
              chomp($textline);
              if ($textline = "") {
                $textline = <TEXT>;
                chomp($textline);
              }
              print "oMo6 : $textline \n";
          } # if =~ Life_stag

    # if ( $textline =~ Life_stag ) {
      # print "Life_stag : $textline \n";
      # ($a, $b, @temp) = split(/\s+/, $textline);
      # foreach $temp (@temp) {
        # $temp =~ s/,//;
        # @temp2 = $temp;
        push @lifestages, [@temp2];
      # }
      # until ($textline =~ Type) {
        # $textline = <TEXT>;
        # chomp($textline);
        # redo SWITCH if ($textline =~ Type);
        # ($a, @temp) = split(/\s+/, $textline);
        # foreach $temp (@temp) {
          # $temp =~ s/,//;
          # @temp2 = $temp;
          # push @lifestagesextra, [@temp2];
        # }
        # print "$textline \n";
      # } 
    # }

        } # 	until 	Localisation
      } # 	EXPIN
    } # 	if 	Expressed_in 

    if ( $textline =~ Localisation) {
      until ( ($textline =~ Subcellular_localization) ||
          ($textline =~ Type) || ($textline =~ Pattern) ||
          ($textline eq "") ) {
        ($a, @localis) = split(/\s+/, $textline);
        $textline = <TEXT>;
        chomp($textline);
      }
    }

    if ( $textline =~ Subcellular_localization) {
      until ( ($textline =~ Localisation) ||
          ($textline =~ Type) || ($textline =~ Pattern) ||
          ($textline eq "") ) {
        ($a, @localiz) = split(/\s+/, $textline);
        $textline = <TEXT>;
        chomp($textline);
      }
    }

# WORK HERE, Type search for Reporter_gene (eporter_gene)
# In_situ (^In situ || ^In_situ), Antibody

    if ( $textline =~ Type ) {
      print "Type : $textline \n";
      TYPE: {
        until ( ($textline =~ Pattern) || ($textline =~ Remark) ||
            ($textline eq "") ) {
          unless ( ($textline =~ eporter_gene) || ($textline =~ situ) ||
              ($textline =~ Antibody) ) {
            until ( ($textline =~ Pattern) || ($textline =~ Remark) ) { # ||
              #  ($textline eq "") ) {
              $textline = <TEXT>;
              chomp($textline);
            }
          }
          if ($textline =~ eporter_gene) {
            print "Reporter_gene : $textline \n";
            until ( ($a eq "Reporter_gene") || ($a eq "eporter_gene") ) {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
              print "Eep1 : $textline \n";
            }
            @reportergene = split(/\s+/, $textline);
            push @reportergeneextra, [@reportergene];
            until ( ($textline =~ situ) || ($textline =~ Antibody) ||
                ($textline =~ Pattern) || ($textline =~ Remark) ) { 
              print "Eep2 : $textline \n";
              $textline = <TEXT>;
              chomp($textline);
              print "Eep3 : $textline \n";
              redo TYPE if ( ($textline =~ situ) || 
                  ($textline =~ Antibody) || ($textline =~ Pattern) || 
                  ($textline =~ Remark) ); 
              @textline = split(/\s+/, $textline);
              if ($textline[0] eq "") {
                $textline = join(" ", @textline);
                print "Eep5 : $textline \n";
                ($a, @reportergene) = split(/\s+/, $textline);
              }
              push @reportergeneextra, [@reportergene];
            }
            $textline = <TEXT>;
            chomp($textline);
            if ($textline = "") {
              $textline = <TEXT>;
              chomp($textline);
            }
            print "Eep6 : $textline \n";
          } # if =~ eporter_gene

          if ($textline =~ situ) {
            print "In_situ : $textline \n";
            until ( ($a eq "situ") || ($a eq "Situ") || ($a eq "In_situ") ) {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
              print "Fee1 : $textline \n";
            }
            @insitu = split(/\s+/, $textline);
            push @insituextra, [@insitu];
            until ( ($textline =~ eporter_gene) || ($textline =~ Antibody) ||
                ($textline =~ Pattern) || ($textline =~ Remark) ) { 
              print "Fee2 : $textline \n";
              $textline = <TEXT>;
              chomp($textline);
              print "Fee3 : $textline \n";
              redo TYPE if ( ($textline =~ eporter_gene) || 
                  ($textline =~ Antibody) || ($textline =~ Pattern) || 
                  ($textline =~ Remark) ); 
              @textline = split(/\s+/, $textline);
              if ($textline[0] eq "") {
                $textline = join(" ", @textline);
                print "Fee5 : $textline \n";
                ($a, @insitu) = split(/\s+/, $textline);
              }
              push @insituextra, [@insitu];
            }
            $textline = <TEXT>;
            chomp($textline);
            if ($textline = "") {
              $textline = <TEXT>;
              chomp($textline);
            }
            print "Fee6 : $textline \n";
          } # if =~ situ

          if ($textline =~ Antibody) {
            print "Antibody : $textline \n";
            until ( ($a eq "Antibody") || ($a eq "antibody")  ) {
              ($a, @textline) = split(/\s+/, $textline);
              $textline = join(" ", @textline);
              print "eVe1 : $textline \n";
            }
            @antibody = split(/\s+/, $textline);
            push @antibodyextra, [@antibody];
            until ( ($textline =~ eporter_gene) || ($textline =~ situ) ||
                ($textline =~ Pattern) || ($textline =~ Remark) ) { 
              print "eVe2 : $textline \n";
              $textline = <TEXT>;
              chomp($textline);
              print "eVe3 : $textline \n";
              redo TYPE if ( ($textline =~ eporter_gene) || 
                  ($textline =~ situ) || ($textline =~ Pattern) || 
                  ($textline =~ Remark) ); 
              @textline = split(/\s+/, $textline);
              if ($textline[0] eq "") {
                $textline = join(" ", @textline);
                print "eVe5 : $textline \n";
                ($a, @antibody) = split(/\s+/, $textline);
              }
              push @antibodyextra, [@antibody];
            }
            $textline = <TEXT>;
            chomp($textline);
            if ($textline = "") {
              $textline = <TEXT>;
              chomp($textline);
            }
            print "eVe6 : $textline \n";
          }

        } # 	until 	Pattern
      } #	TYPE
    } #		if 	Type



#      ($a, $type, @genetype) = split(/\s+/, $textline);
#      until ($textline =~ Pattern) {
#        $textline = <TEXT>;
#        chomp($textline);
#        redo SWITCH if ($textline =~ Pattern);
#        ($a, @temp) = split(/\s+/, $textline);
#        push @genetypeextra, [@temp];
#        print "$textline \n";
#      } 
#      unshift @genetypeextra, [@genetype];
#    } if =~ Type
  
    if ( $textline =~ Pattern ) {
      PAT: {
        if ($textline =~ Pattern) {
          until ( ($a eq "Pattern") || ($a eq "Patterns") ) {
            ($a, @pattern) = split (/\s+/, $textline);
            $textline = join(" ", @pattern);
          }
        }
        until ( ($textline =~ Remark) || ($textline =~ Transgene) ) { # ||
            # ($textline eq "") ) {
          print "Pattern : $textline \n";
          unless (defined ($textline = <TEXT>) ) {last PAT}
          chomp($textline);
          redo PAT if ( ($textline =~ Remark) || ($textline =~ Transgene) ); 
          @pattern = (@pattern , split(/\s+/, $textline) );
          print "$textline \n";
        }
      }
    } # if Pattern

    if ( $textline =~ Remark ) {
      REM: {
        if ($textline =~ Remark) {
          until ($a eq "Remark") {
            ($a, @remark) = split (/\s+/, $textline);
            $textline = join(" ", @remark);
          }
        }
        until ( ($textline =~ Transgene) || ($textline =~ Pattern) ) { # ||
            # ($textline eq "") ) {
          print "Remark : $textline \n";
          unless (defined ($textline = <TEXT>) ) {last REM}
          chomp($textline);
          redo REM if ( ($textline =~ Transgene) || ($textline =~ Pattern) ); 
          @remark = (@remark , split(/\s+/, $textline) );
          print "$textline \n";
        }
      }
    } # if Remark

    if ( $textline =~ Transgene ) {
      TRAN: {
        if ($textline =~ Transgene) {
          until ($a eq "Transgene") {
            ($a, @transgene) = split (/\s+/, $textline);
            $textline = join(" ", @transgene);
          }
        }
        until ( ($textline =~ Remark) || ($textline =~ Pattern) ) { # ||
            # ($textline eq "") ) {
          print "Transgene : $textline \n";
          unless (defined ($textline = <TEXT>) ) {last TRAN}
          chomp($textline);
          redo TRAN if ( ($textline =~ Remark) || ($textline =~ Pattern) ); 
          @transgene = (@transgene , split(/\s+/, $textline) );
          print "$textline \n";
        }
      }
    } # if Transgene

  } #	SWITCH
} #	while	<TEXT>

close (TEXT) || die "cannot close $textfile : $!";



# test open and output
  
open(ENDNOTE, "gophbib.endnote") || die "cannot open gophbib.endnote : $!";

while ($endline = <ENDNOTE>) {
  if ($endline =~ $lastname && $endline =~ $title) {
    # $matchnumber = 1;
    # $matching = 8;
    # for ($i = 0; $i <= 10; $i++) {
        # print "$title[$i] \n";
      # if ($endline =~ $title[$i]) {
        # $matching++;
        # print "$title[$i] \n";
      # }
    # }
    # if ($matching >= $matchnumber) {
      @endline = split(/\s+/, $endline);
      $label = $endline[0];
      print "label is $label. \n";
    # }
  }
}

close(ENDNOTE) || die "cannot close gophbib.endnote : $!";


open(ACE, ">$acefile") || die "cannot create $acefile : $!";

print ACE "Reference       [cgc$label] \n";
# print "Reference       [cgc$label]  \n";

if (@sequence) {print ACE "Sequence        \"@sequence\" \n";}
if (@clone) {print ACE "Clone           \"@clone\" \n";}
if ($locus[0]) {print ACE "Locus           \"@locus\" \n";}
if (@protein) {print ACE "Protein         \"@protein\" \n";}

# if (@cellgroup) { print ACE "Cellgroup       \"@cellgroup\" \n"; }
for $row (@cellgroupextra) { 
  if (@$row) {
    print ACE "Cellgroup       \"@$row\" \n"; 
  }
}

# if (@cells) { print ACE "Cells           \"@cells\" \n"; }
for $row (@cellsextra) { 
  if (@$row) {
    print ACE "Cells           \"@$row\" \n"; 
  }
}

# this loop commented out to see display of @lifestagesextra
#  foreach $lifestages (@lifestages) { 
#    if (@$lifestages) {
#      print ACE "Lifestages      \"@$lifestages\" \n"; 
#    }
#  }
# if (@lifestages) { print ACE "Lifestages      \"@lifestages\" \n"; }
for $row (@lifestagesextra) { 
  if (@$row) {
    print ACE "Lifestages      \"@$row\" \n"; 
  }
}

if (@localis) { print ACE "Localisation    \"@localis\" \n"; }

if (@localiz) { print ACE "Subcellular_loc \"@localiz\" \n"; }

if ($reportergeneextra[0]) {
  print ACE "Reporter_gene   \""; 
  for $row (@reportergeneextra) { 
    if (@$row) {
      print ACE " @$row"; 
    }
  }
  print ACE "\" \n"; 
}

if ($insituextra[0]) {
  print ACE "In_situ         \""; 
  for $row (@insituextra) { 
    if (@$row) {
      print ACE " @$row"; 
    }
  }
  print ACE "\" \n"; 
}

if ($antibodyextra[0]) {
  print ACE "Antibody        \""; 
  for $row (@antibodyextra) { 
    if (@$row) {
      print ACE " @$row"; 
    }
  }
  print ACE "\" \n"; 
}

#  if (@genetype) { 
#   print ACE "$type           \"@genetype"; 
#    for $row (@genetypeextra) { 
#      if (@$row) {
#        print ACE " @$row"; 
#      }
#    }
#    print ACE "\" \n"; 
#  }


if (@pattern) { print ACE "Pattern         \"@pattern\" \n"; }
# for $row (@patternextra) { 
#   if (@$row) {
#     print ACE "Pattern         \"@$row\" \n"; 
#   }
# }

if (@remark) { print ACE "Remark          \"@remark\" \n"; }

if (@transgene) { print ACE "Transgene       \"@transgene\" \n"; }

close(ACE) || die "cannot close $acefile : $!";


