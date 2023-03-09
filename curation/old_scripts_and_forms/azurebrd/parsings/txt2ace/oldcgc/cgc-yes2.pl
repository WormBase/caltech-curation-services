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

  if ($textline =~ Reference) {
    print "$textline \n";
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
  if ($textline =~ Locus) {
    # print "$textline \n";
    ($a, $b, @locus) = split(/\s+/, $textline);
    print "Locus is @locus. \n";
  }
  if ( ($textline =~ Cell_groups) || ($textline =~ Cells) || 
       ($textline =~ Life_stag) ) {
    print "oop1, $textline \n";
    ($a, $b, @cellgroup) = split(/\s+/, $textline);
    until ( ($textline =~ Cells) || ($texline =~ Life_Stag) ||
        ($textline =~ Type) ) {
      $textline = <TEXT>;
      chomp($textline);
      last if ( ($textline =~ Cells) || ($texline =~ Life_Stag) ||
        ($textline =~ Type) );
      ($a, @temp) = split(/\s+/, $textline);
      push @cellgroupextra, [@temp];
      print "oop3 $textline \n";
    }
    print "$textline \n";
    ($a, $b, @cells) = split(/\s+/, $textline);
    until ( ($textline =~ Life_stag) || ($textline =~ Type) ) {
      $textline = <TEXT>;
      chomp($textline);
      last if ( ($textline =~ Life_stag) || ($textline =~ Type) ) ;
      ($a, @temp) = split(/\s+/, $textline);
      push @cellsextra, [@temp];
      print "$textline \n";
    } 
    print "oop2 $textline \n";
    ($a, $b, @temp) = split(/\s+/, $textline);
    foreach $temp (@temp) {
      $temp =~ s/,//;
      @temp2 = $temp;
      push @lifestages, [@temp2];
    }
    until ($textline =~ Type) {
      $textline = <TEXT>;
      chomp($textline);
      last if ($textline =~ Type);
      ($a, @temp) = split(/\s+/, $textline);
      foreach $temp (@temp) {
        $temp =~ s/,//;
        @temp2 = $temp;
        push @lifestagesextra, [@temp2];
      }
      print "$textline \n";
    } 
    print "$textline \n";
    ($a, $type, @genetype) = split(/\s+/, $textline);
    until ($textline =~ Pattern) {
      $textline = <TEXT>;
      chomp($textline);
      last if ($textline =~ Pattern);
      ($a, @temp) = split(/\s+/, $textline);
      push @genetypeextra, [@temp];
      print "$textline \n";
    } 
    print "$textline \n";
      while ($textline = <TEXT>) {
        chomp($textline);
        @pattern = (@pattern , split(/\s+/, $textline) );
        print "$textline \n";
      }
  }

}

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
print ACE "Locus           \"@locus\" \n";
if (@cellgroup) { print ACE "Cellgroup       \"@cellgroup\" \n"; }
for $row (@cellgroupextra) { 
  if (@$row) {
    print ACE "Cellgroup       \"@$row\" \n"; 
  }
}
if (@cells) { print ACE "Cells           \"@cells\" \n"; }
for $row (@cellsextra) { 
  if (@$row) {
    print ACE "Cells           \"@$row\" \n"; 
  }
}
foreach $lifestages (@lifestages) { 
  if (@$lifestages) {
    print ACE "Lifestages      \"@$lifestages\" \n"; 
  }
}
# if (@lifestages) { print ACE "Lifestages      \"@lifestages\" \n"; }
for $row (@lifestagesextra) { 
  if (@$row) {
    print ACE "Lifestages      \"@$row\" \n"; 
  }
}
if (@genetype) { print ACE "$type           \"@genetype\" \n"; }
for $row (@genetypeextra) { 
  if (@$row) {
    print ACE "$type           \"@$row\" \n"; 
  }
}
if (@pattern) { print ACE "Pattern         \"@pattern\" \n"; }
for $row (@patternextra) { 
  if (@$row) {
    print ACE "Pattern         \"@$row\" \n"; 
  }
}

close(ACE) || die "cannot close $acefile : $!";


