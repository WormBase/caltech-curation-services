#!/usr/bin/perl
#
# Program to parse .txt files for reference data, pass args to .endnote, find
# label, and set .ace file.

open (TEXT, "act4.txt") || die "cannot open act4.txt : $!";

while ($textline = <TEXT>) {
  chomp($textline);

  if ($textline =~ Reference) {
    print "$textline \n";
    @textline = split(/\s+/, $textline);
    $lastname = $textline[1];
    print "lastname is $lastname. \n";
  }
  if ($textline =~ Locus) {
    print "$textline \n";
    ($a, $b, @locus) = split(/\s+/, $textline);
    print "locus is @locus. \n";
  }
  if ($textline =~ Cell_groups) {
    print "$textline \n";
    ($a, $b, @cellgroup) = split(/\s+/, $textline);
    until ($textline =~ Cells) {
      $textline = <TEXT>;
      chomp($textline);
      last if ($textline =~ Cells);
      ($a, @temp) = split(/\s+/, $textline);
      push @cellgroupextra, [@temp];
      print "$textline \n";
    }
    print "$textline \n";
    ($a, $b, @cells) = split(/\s+/, $textline);
    until ($textline =~ Life_stages) {
      $textline = <TEXT>;
      chomp($textline);
      last if ($textline =~ Life_stages);
      ($a, @temp) = split(/\s+/, $textline);
      push @cellsextra, [@temp];
      print "$textline \n";
    } 
    print "$textline \n";
    ($a, $b, @lifestages) = split(/\s+/, $textline);
    until ($textline =~ Reporter_gene) {
      $textline = <TEXT>;
      chomp($textline);
      last if ($textline =~ Reporter_gene);
      ($a, @temp) = split(/\s+/, $textline);
      foreach $temp (@temp) {
        $temp =~ s/,//;
        @temp2 = $temp;
        push @lifestagesextra, [@temp2];
      }
      print "$textline \n";
    } 
    print "$textline \n";
    ($a, $b, @reportergene) = split(/\s+/, $textline);
    until ($textline =~ Pattern) {
      $textline = <TEXT>;
      chomp($textline);
      last if ($textline =~ Pattern);
      ($a, @temp) = split(/\s+/, $textline);
      push @reportergeneextra, [@temp];
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

close (TEXT) || die "cannot close act4.txt : $!";



# test open and output
  
open(ENDNOTE, "test.endnote") || die "cannot open test.endnote : $!";

while ($endline = <ENDNOTE>) {
  if ($endline =~ $lastname) {
    @endline = split(/\s+/, $endline);
    $label = $endline[0];
    print "label is $label. \n";
  }
}

close(ENDNOTE) || die "cannot close test.endnote : $!";


open(ACE, ">act4.ace") || die "cannot create act4.ace : $!";

print ACE "Reference       [cgc$label] \n";
print "Reference       [cgc$label]  \n";
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
if (@lifestages) { print ACE "Lifestages      \"@lifestages\" \n"; }
for $row (@lifestagesextra) { 
  if (@$row) {
    print ACE "Lifestages      \"@$row\" \n"; 
  }
}
if (@reportergene) { print ACE "Reporter Gene   \"@reportergene\" \n"; }
for $row (@reportergeneextra) { 
  if (@$row) {
    print ACE "Reporter Gene   \"@$row\" \n"; 
  }
}
if (@pattern) { print ACE "Pattern         \"@pattern\" \n"; }
for $row (@patternextra) { 
  if (@$row) {
    print ACE "Pattern         \"@$row\" \n"; 
  }
}

close(ACE) || die "cannot close act4.ace : $!";


