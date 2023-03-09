#!/usr/bin/perl

# based on lifestageMappings file, convert paper-lifestage mappings .ace file to delete and new mapping creation file.  2012 05 02

use strict;

my %map;
my $infile = 'lifestageMappings';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  my ($id, $name) = split/\t/, $line;
  $map{$name} = $id;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile : $!";

$/ = "";
$infile = 'WS232PaperLifeStage.ace';
my $outfile = 'WS232PaperLifeStageReplace.ace';
my $create; my $delete;
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my (@lines) = split/\n/, $para;
  my $header = shift @lines;
  $create .= "$header\n";
  $delete .= "$header\n";
  foreach my $line (@lines) {
    my ($term) = $line =~ m/^Life_stage\t \"(.*?)\"/;   
    if ($map{$term}) { 
        $delete .= "-D $line\n";
        $line =~ s/^Life_stage\t \"(.*?)\"/Life_stage\t \"$map{$term}\"/;   
        $create .= "$line\n";
      }
      else {
        print "ERR no mapping for $term in $line\n"; 
      }
  } # foreach $line (@lines)
  $create .= "\n";
  $delete .= "\n";
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";

open (OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT $delete;
print OUT $create;
close (OUT) or die "Cannot close $outfile : $!";
$/ = "\n";

__END__

Paper : "WBPaper00000075"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000092"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000094"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000104"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000316"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000354"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000404"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000541"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000731"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000747"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000781"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000869"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00000993"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001015"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001057"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001144"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001292"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001383"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001477"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001588"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00001782"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00002127"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00002220"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00002260"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00002640"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00002784"
Life_stage	 "adult"

Paper : "WBPaper00002790"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00003061"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00003131"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00003841"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00004455"
Life_stage	 "adult"

Paper : "WBPaper00004521"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00004549"
Life_stage	 "embryo"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00004594"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00004646"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"

Paper : "WBPaper00004651"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00004846"
Life_stage	 "embryo"

Paper : "WBPaper00004990"
Life_stage	 "postembryonic"

Paper : "WBPaper00005005"
Life_stage	 "embryo"

Paper : "WBPaper00005018"
Life_stage	 "postembryonic"

Paper : "WBPaper00005020"
Life_stage	 "adult"

Paper : "WBPaper00005038"
Life_stage	 "adult"

Paper : "WBPaper00005040"
Life_stage	 "postembryonic"

Paper : "WBPaper00005051"
Life_stage	 "adult"

Paper : "WBPaper00005054"
Life_stage	 "adult"

Paper : "WBPaper00005065"
Life_stage	 "adult"

Paper : "WBPaper00005079"
Life_stage	 "embryo"

Paper : "WBPaper00005086"
Life_stage	 "adult"

Paper : "WBPaper00005095"
Life_stage	 "embryo"

Paper : "WBPaper00005123"
Life_stage	 "embryo"

Paper : "WBPaper00005144"
Life_stage	 "adult"

Paper : "WBPaper00005152"
Life_stage	 "adult"

Paper : "WBPaper00005158"
Life_stage	 "embryo"

Paper : "WBPaper00005160"
Life_stage	 "embryo"

Paper : "WBPaper00005174"
Life_stage	 "adult"

Paper : "WBPaper00005183"
Life_stage	 "embryo"

Paper : "WBPaper00005197"
Life_stage	 "larva"

Paper : "WBPaper00005204"
Life_stage	 "adult"

Paper : "WBPaper00005214"
Life_stage	 "postembryonic"

Paper : "WBPaper00005230"
Life_stage	 "adult"
Life_stage	 "embryo"
Life_stage	 "larva"

Paper : "WBPaper00005245"
Life_stage	 "adult"

Paper : "WBPaper00005253"
Life_stage	 "adult"

Paper : "WBPaper00005258"
Life_stage	 "adult"

Paper : "WBPaper00005268"
Life_stage	 "adult"

Paper : "WBPaper00005300"
Life_stage	 "adult"

Paper : "WBPaper00005307"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00005319"
Life_stage	 "embryo"

Paper : "WBPaper00005321"
Life_stage	 "embryo"

Paper : "WBPaper00005346"
Life_stage	 "adult"

Paper : "WBPaper00005366"
Life_stage	 "adult"

Paper : "WBPaper00005379"
Life_stage	 "adult"

Paper : "WBPaper00005386"
Life_stage	 "embryo"

Paper : "WBPaper00005392"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00005433"
Life_stage	 "embryo"

Paper : "WBPaper00005441"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"

Paper : "WBPaper00005445"
Life_stage	 "embryo"

Paper : "WBPaper00005457"
Life_stage	 "embryo"

Paper : "WBPaper00005466"
Life_stage	 "adult"

Paper : "WBPaper00005484"
Life_stage	 "adult"

Paper : "WBPaper00005491"
Life_stage	 "embryo"

Paper : "WBPaper00005492"
Life_stage	 "embryo"

Paper : "WBPaper00005523"
Life_stage	 "adult"

Paper : "WBPaper00005538"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00005546"
Life_stage	 "adult"

Paper : "WBPaper00005548"
Life_stage	 "adult"

Paper : "WBPaper00005551"
Life_stage	 "postembryonic"

Paper : "WBPaper00005553"
Life_stage	 "postembryonic"

Paper : "WBPaper00005557"
Life_stage	 "postembryonic"

Paper : "WBPaper00005567"
Life_stage	 "postembryonic"

Paper : "WBPaper00005595"
Life_stage	 "adult"

Paper : "WBPaper00005608"
Life_stage	 "embryo"

Paper : "WBPaper00005612"
Life_stage	 "adult"

Paper : "WBPaper00005624"
Life_stage	 "adult"

Paper : "WBPaper00005633"
Life_stage	 "postembryonic"

Paper : "WBPaper00005639"
Life_stage	 "postembryonic"

Paper : "WBPaper00005657"
Life_stage	 "adult"

Paper : "WBPaper00005671"
Life_stage	 "adult"

Paper : "WBPaper00005690"
Life_stage	 "adult"

Paper : "WBPaper00005704"
Life_stage	 "postembryonic"

Paper : "WBPaper00005708"
Life_stage	 "postembryonic"

Paper : "WBPaper00005726"
Life_stage	 "adult"
Life_stage	 "larva"

Paper : "WBPaper00005729"
Life_stage	 "adult"

Paper : "WBPaper00005733"
Life_stage	 "adult"

Paper : "WBPaper00005758"
Life_stage	 "adult"

Paper : "WBPaper00005762"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00005778"
Life_stage	 "embryo"

Paper : "WBPaper00005822"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005824"
Life_stage	 "adult"

Paper : "WBPaper00005827"
Life_stage	 "embryo"

Paper : "WBPaper00005831"
Life_stage	 "adult"

Paper : "WBPaper00005835"
Life_stage	 "adult"

Paper : "WBPaper00005838"
Life_stage	 "embryo"

Paper : "WBPaper00005862"
Life_stage	 "adult"

Paper : "WBPaper00005867"
Life_stage	 "postembryonic"

Paper : "WBPaper00005877"
Life_stage	 "postembryonic"

Paper : "WBPaper00005882"
Life_stage	 "adult"

Paper : "WBPaper00005896"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"

Paper : "WBPaper00005897"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"

Paper : "WBPaper00005908"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005909"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005913"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005930"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005943"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005945"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script 20030725 - Eimear Kenny"

Paper : "WBPaper00005957"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"

Paper : "WBPaper00005962"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"

Paper : "WBPaper00005966"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"

Paper : "WBPaper00005971"
Life_stage	 "adult" Inferred_automatically "abstract2acePMID.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00005972"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"

Paper : "WBPaper00005979"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"

Paper : "WBPaper00005986"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"

Paper : "WBPaper00005991"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"

Paper : "WBPaper00005996"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-08-25 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2acePMID.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00006004"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006009"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2acePMID.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00006013"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006015"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006019"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006023"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-19 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-19 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"

Paper : "WBPaper00006024"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2acePMID.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00006047"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00006057"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-19 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006065"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"

Paper : "WBPaper00006070"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-19 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006079"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006084"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006085"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006087"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-19 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006096"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006104"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006111"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"

Paper : "WBPaper00006119"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"

Paper : "WBPaper00006121"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006137"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"

Paper : "WBPaper00006149"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"

Paper : "WBPaper00006162"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"

Paper : "WBPaper00006165"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006177"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"

Paper : "WBPaper00006178"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"

Paper : "WBPaper00006199"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"

Paper : "WBPaper00006207"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"

Paper : "WBPaper00006210"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"

Paper : "WBPaper00006222"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-12-01 - Eimear Kenny"

Paper : "WBPaper00006236"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"

Paper : "WBPaper00006237"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-09-07 - Eimear Kenny"

Paper : "WBPaper00006240"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-01 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-16 - Eimear Kenny"

Paper : "WBPaper00006254"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"

Paper : "WBPaper00006268"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"

Paper : "WBPaper00006276"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-29 - Eimear Kenny"

Paper : "WBPaper00006282"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-29 - Eimear Kenny"

Paper : "WBPaper00006295"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-29 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"

Paper : "WBPaper00006311"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"

Paper : "WBPaper00006327"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-02-12 - Eimear Kenny"

Paper : "WBPaper00006352"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-02-26 - Eimear Kenny"

Paper : "WBPaper00006354"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-02-26 - Eimear Kenny"

Paper : "WBPaper00006360"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"

Paper : "WBPaper00006367"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-02-26 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"

Paper : "WBPaper00006379"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"

Paper : "WBPaper00006385"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"

Paper : "WBPaper00006386"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"

Paper : "WBPaper00006394"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00006412"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"

Paper : "WBPaper00006422"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-02-12 - Eimear Kenny"

Paper : "WBPaper00006461"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00006476"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-29 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"

Paper : "WBPaper00006477"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00006484"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-02-26 - Eimear Kenny"

Paper : "WBPaper00006491"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00006497"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00006513"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-06-10 - Eimear Kenny"

Paper : "WBPaper00006519"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-06-10 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00006532"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-06-10 - Eimear Kenny"

Paper : "WBPaper00010014"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010027"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010028"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010033"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010035"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010036"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010038"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010055"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010060"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010067"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010073"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010075"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010076"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010079"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010081"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010093"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010099"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010103"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010104"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010107"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010113"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010127"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010130"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010131"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010133"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010134"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010144"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010147"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010148"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010150"
Life_stage	 "postembryonic"

Paper : "WBPaper00010152"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010160"
Life_stage	 "adult"

Paper : "WBPaper00010165"
Life_stage	 "adult"

Paper : "WBPaper00010166"
Life_stage	 "embryo"

Paper : "WBPaper00010172"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010177"
Life_stage	 "adult"

Paper : "WBPaper00010181"
Life_stage	 "adult"

Paper : "WBPaper00010182"
Life_stage	 "postembryonic"

Paper : "WBPaper00010188"
Life_stage	 "embryo"

Paper : "WBPaper00010192"
Life_stage	 "adult"

Paper : "WBPaper00010202"
Life_stage	 "adult"

Paper : "WBPaper00010206"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010207"
Life_stage	 "adult"

Paper : "WBPaper00010212"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00010220"
Life_stage	 "adult"

Paper : "WBPaper00010224"
Life_stage	 "embryo"

Paper : "WBPaper00010225"
Life_stage	 "adult"

Paper : "WBPaper00010227"
Life_stage	 "adult"

Paper : "WBPaper00010229"
Life_stage	 "embryo"

Paper : "WBPaper00010232"
Life_stage	 "larva"

Paper : "WBPaper00010237"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010240"
Life_stage	 "embryo"

Paper : "WBPaper00010242"
Life_stage	 "adult"

Paper : "WBPaper00010243"
Life_stage	 "adult"

Paper : "WBPaper00010246"
Life_stage	 "adult"

Paper : "WBPaper00010248"
Life_stage	 "embryo"

Paper : "WBPaper00010253"
Life_stage	 "embryo"

Paper : "WBPaper00010256"
Life_stage	 "embryo"

Paper : "WBPaper00010257"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010260"
Life_stage	 "adult"

Paper : "WBPaper00010265"
Life_stage	 "adult"

Paper : "WBPaper00010269"
Life_stage	 "adult"

Paper : "WBPaper00010275"
Life_stage	 "adult"

Paper : "WBPaper00010282"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00010283"
Life_stage	 "adult"

Paper : "WBPaper00010285"
Life_stage	 "adult"

Paper : "WBPaper00010287"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010288"
Life_stage	 "embryo"

Paper : "WBPaper00010293"
Life_stage	 "postembryonic"

Paper : "WBPaper00010299"
Life_stage	 "adult"

Paper : "WBPaper00010303"
Life_stage	 "adult"

Paper : "WBPaper00010307"
Life_stage	 "adult"

Paper : "WBPaper00010308"
Life_stage	 "adult"

Paper : "WBPaper00010342"
Life_stage	 "embryo"

Paper : "WBPaper00010344"
Life_stage	 "embryo"

Paper : "WBPaper00010354"
Life_stage	 "adult"

Paper : "WBPaper00010361"
Life_stage	 "postembryonic"

Paper : "WBPaper00010362"
Life_stage	 "embryo"

Paper : "WBPaper00010371"
Life_stage	 "adult"

Paper : "WBPaper00010373"
Life_stage	 "adult"

Paper : "WBPaper00010376"
Life_stage	 "postembryonic"

Paper : "WBPaper00010378"
Life_stage	 "embryo"

Paper : "WBPaper00010385"
Life_stage	 "adult"

Paper : "WBPaper00010389"
Life_stage	 "adult"

Paper : "WBPaper00010393"
Life_stage	 "adult"

Paper : "WBPaper00010468"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010543"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010626"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010631"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010639"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010641"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010651"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010653"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010657"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010658"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010668"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010677"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010679"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010680"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010681"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010686"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010690"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010695"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010697"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010700"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010702"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010704"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010708"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010711"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010712"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010713"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010715"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010721"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010727"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010728"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010735"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010736"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010738"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010739"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010745"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010747"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010750"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010757"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010768"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010773"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010796"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010811"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010815"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010816"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010817"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010818"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010820"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010830"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010835"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010836"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010842"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010849"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010853"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010854"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010858"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010869"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010870"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010873"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010882"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010883"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010888"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010890"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00010920"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010927"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010955"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010961"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010979"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00010990"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011034"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011038"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011147"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011175"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011276"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011278"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011292"
Life_stage	 "embryo"

Paper : "WBPaper00011293"
Life_stage	 "embryo"

Paper : "WBPaper00011298"
Life_stage	 "embryo"

Paper : "WBPaper00011300"
Life_stage	 "adult"
Life_stage	 "larva"

Paper : "WBPaper00011303"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00011308"
Life_stage	 "adult"

Paper : "WBPaper00011310"
Life_stage	 "adult"

Paper : "WBPaper00011341"
Life_stage	 "adult"

Paper : "WBPaper00011342"
Life_stage	 "adult"
Life_stage	 "larva"

Paper : "WBPaper00011344"
Life_stage	 "embryo"

Paper : "WBPaper00011359"
Life_stage	 "adult"

Paper : "WBPaper00011374"
Life_stage	 "adult"

Paper : "WBPaper00011378"
Life_stage	 "adult"

Paper : "WBPaper00011379"
Life_stage	 "adult"

Paper : "WBPaper00011382"
Life_stage	 "embryo"

Paper : "WBPaper00011395"
Life_stage	 "embryo"

Paper : "WBPaper00011400"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00011403"
Life_stage	 "embryo"

Paper : "WBPaper00011404"
Life_stage	 "adult"

Paper : "WBPaper00011408"
Life_stage	 "adult"

Paper : "WBPaper00011414"
Life_stage	 "adult"
Life_stage	 "embryo"
Life_stage	 "postembryonic"

Paper : "WBPaper00011415"
Life_stage	 "postembryonic"

Paper : "WBPaper00011424"
Life_stage	 "adult"

Paper : "WBPaper00011426"
Life_stage	 "adult"

Paper : "WBPaper00011432"
Life_stage	 "adult"

Paper : "WBPaper00011441"
Life_stage	 "adult"

Paper : "WBPaper00011443"
Life_stage	 "adult"

Paper : "WBPaper00011450"
Life_stage	 "adult"

Paper : "WBPaper00011461"
Life_stage	 "postembryonic"

Paper : "WBPaper00011469"
Life_stage	 "embryo"

Paper : "WBPaper00011470"
Life_stage	 "embryo"

Paper : "WBPaper00011472"
Life_stage	 "embryo"
Life_stage	 "larva"

Paper : "WBPaper00011477"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00011481"
Life_stage	 "embryo"

Paper : "WBPaper00011482"
Life_stage	 "adult"

Paper : "WBPaper00011492"
Life_stage	 "embryo"

Paper : "WBPaper00011505"
Life_stage	 "larva"

Paper : "WBPaper00011514"
Life_stage	 "embryo"

Paper : "WBPaper00011516"
Life_stage	 "embryo"

Paper : "WBPaper00011525"
Life_stage	 "embryo"

Paper : "WBPaper00011528"
Life_stage	 "embryo"

Paper : "WBPaper00011532"
Life_stage	 "adult"

Paper : "WBPaper00011533"
Life_stage	 "embryo"

Paper : "WBPaper00011928"
Life_stage	 "embryo"

Paper : "WBPaper00011935"
Life_stage	 "embryo"

Paper : "WBPaper00011936"
Life_stage	 "embryo"

Paper : "WBPaper00011937"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00011940"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00011941"
Life_stage	 "postembryonic"

Paper : "WBPaper00011943"
Life_stage	 "larva"

Paper : "WBPaper00011953"
Life_stage	 "larva"

Paper : "WBPaper00011964"
Life_stage	 "adult"

Paper : "WBPaper00011981"
Life_stage	 "adult"

Paper : "WBPaper00011986"
Life_stage	 "larva"

Paper : "WBPaper00011990"
Life_stage	 "embryo"

Paper : "WBPaper00011994"
Life_stage	 "embryo"

Paper : "WBPaper00011995"
Life_stage	 "adult"

Paper : "WBPaper00011998"
Life_stage	 "adult"

Paper : "WBPaper00011999"
Life_stage	 "adult"

Paper : "WBPaper00012007"
Life_stage	 "adult"
Life_stage	 "larva"
Life_stage	 "postembryonic"

Paper : "WBPaper00012197"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00012294"
Life_stage	 "embryo"

Paper : "WBPaper00012313"
Life_stage	 "adult"

Paper : "WBPaper00012318"
Life_stage	 "adult"

Paper : "WBPaper00012320"
Life_stage	 "embryo"

Paper : "WBPaper00012322"
Life_stage	 "embryo"

Paper : "WBPaper00012333"
Life_stage	 "embryo"

Paper : "WBPaper00012336"
Life_stage	 "adult"

Paper : "WBPaper00012363"
Life_stage	 "larva"

Paper : "WBPaper00012378"
Life_stage	 "adult"

Paper : "WBPaper00012379"
Life_stage	 "embryo"

Paper : "WBPaper00012386"
Life_stage	 "adult"

Paper : "WBPaper00012394"
Life_stage	 "adult"

Paper : "WBPaper00012500"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012506"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012507"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012517"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012529"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012530"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012543"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012551"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012560"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012564"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012565"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00012573"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00012712"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00012729"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00012759"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012762"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012776"
Life_stage	 "adult"

Paper : "WBPaper00012781"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012793"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012826"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012832"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012843"
Life_stage	 "adult"

Paper : "WBPaper00012846"
Life_stage	 "adult"

Paper : "WBPaper00012866"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012883"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00012898"
Life_stage	 "adult"

Paper : "WBPaper00012916"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00012930"
Life_stage	 "adult"

Paper : "WBPaper00012962"
Life_stage	 "adult"

Paper : "WBPaper00012986"
Life_stage	 "adult"

Paper : "WBPaper00013013"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013025"
Life_stage	 "adult"

Paper : "WBPaper00013043"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013068"
Life_stage	 "adult"

Paper : "WBPaper00013076"
Life_stage	 "adult"

Paper : "WBPaper00013085"
Life_stage	 "adult"

Paper : "WBPaper00013087"
Life_stage	 "adult"

Paper : "WBPaper00013117"
Life_stage	 "adult"

Paper : "WBPaper00013121"
Life_stage	 "embryo"

Paper : "WBPaper00013157"
Life_stage	 "embryo"

Paper : "WBPaper00013158"
Life_stage	 "larva"

Paper : "WBPaper00013183"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00013202"
Life_stage	 "embryo"

Paper : "WBPaper00013203"
Life_stage	 "adult"

Paper : "WBPaper00013245"
Life_stage	 "adult"

Paper : "WBPaper00013262"
Life_stage	 "embryo"

Paper : "WBPaper00013266"
Life_stage	 "larva"

Paper : "WBPaper00013267"
Life_stage	 "adult"

Paper : "WBPaper00013268"
Life_stage	 "adult"

Paper : "WBPaper00013286"
Life_stage	 "postembryonic"

Paper : "WBPaper00013311"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013329"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-10-31 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2003-11-13 - Eimear Kenny"

Paper : "WBPaper00013355"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-01-15 - Eimear Kenny"

Paper : "WBPaper00013365"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013387"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-04-03 - Eimear Kenny"

Paper : "WBPaper00013402"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00013403"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-07-15 - Eimear Kenny"

Paper : "WBPaper00013409"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00013416"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-07-15 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-07-15 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00013420"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-07-15 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-06 - Eimear Kenny"

Paper : "WBPaper00013442"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"

Paper : "WBPaper00013462"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-05-26 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00013467"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-07-15 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-06-10 - Eimear Kenny"

Paper : "WBPaper00013489"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-06-10 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00013500"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-07-05 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00013561"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013565"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013594"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00013612"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00013616"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00014449"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014503"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014521"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014583"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014589"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014592"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014620"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014622"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014658"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014661"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014666"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014684"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014700"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014734"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014753"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014812"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014827"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014840"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014869"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014930"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00014991"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015049"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015140"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015143"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015210"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015220"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015244"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015278"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015339"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015353"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015363"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015436"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015511"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015513"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015518"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015540"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015564"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015572"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015585"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015615"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015726"
Life_stage	 "L1 larva"

Paper : "WBPaper00015729"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015747"
Life_stage	 "embryo"

Paper : "WBPaper00015749"
Life_stage	 "adult"

Paper : "WBPaper00015763"
Life_stage	 "adult"

Paper : "WBPaper00015765"
Life_stage	 "adult"

Paper : "WBPaper00015769"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015783"
Life_stage	 "adult"

Paper : "WBPaper00015785"
Life_stage	 "adult"

Paper : "WBPaper00015789"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00015792"
Life_stage	 "adult"
Life_stage	 "larva"

Paper : "WBPaper00015798"
Life_stage	 "larva"

Paper : "WBPaper00015801"
Life_stage	 "adult"

Paper : "WBPaper00015803"
Life_stage	 "postembryonic"

Paper : "WBPaper00015804"
Life_stage	 "adult"

Paper : "WBPaper00016605"
Life_stage	 "embryo"
Life_stage	 "postembryonic"

Paper : "WBPaper00016624"
Life_stage	 "adult"

Paper : "WBPaper00016631"
Life_stage	 "embryo"

Paper : "WBPaper00016632"
Life_stage	 "adult"

Paper : "WBPaper00016633"
Life_stage	 "embryo"

Paper : "WBPaper00016637"
Life_stage	 "embryo"

Paper : "WBPaper00016640"
Life_stage	 "embryo"

Paper : "WBPaper00016650"
Life_stage	 "embryo"

Paper : "WBPaper00016659"
Life_stage	 "embryo"

Paper : "WBPaper00016663"
Life_stage	 "adult"

Paper : "WBPaper00016667"
Life_stage	 "adult"

Paper : "WBPaper00016669"
Life_stage	 "embryo"

Paper : "WBPaper00016670"
Life_stage	 "adult"

Paper : "WBPaper00016678"
Life_stage	 "embryo"

Paper : "WBPaper00016686"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00016699"
Life_stage	 "adult"

Paper : "WBPaper00016715"
Life_stage	 "adult"

Paper : "WBPaper00016762"
Life_stage	 "adult"

Paper : "WBPaper00016763"
Life_stage	 "adult"
Life_stage	 "embryo"

Paper : "WBPaper00016799"
Life_stage	 "adult"

Paper : "WBPaper00016804"
Life_stage	 "adult"

Paper : "WBPaper00016818"
Life_stage	 "larva"

Paper : "WBPaper00016820"
Life_stage	 "adult"

Paper : "WBPaper00016833"
Life_stage	 "adult"

Paper : "WBPaper00016834"
Life_stage	 "adult"

Paper : "WBPaper00016835"
Life_stage	 "embryo"
Life_stage	 "larva"

Paper : "WBPaper00016836"
Life_stage	 "embryo"

Paper : "WBPaper00016837"
Life_stage	 "embryo"

Paper : "WBPaper00016848"
Life_stage	 "adult"

Paper : "WBPaper00016850"
Life_stage	 "adult"

Paper : "WBPaper00016851"
Life_stage	 "adult"

Paper : "WBPaper00016856"
Life_stage	 "embryo"
Life_stage	 "postembryonic"

Paper : "WBPaper00016857"
Life_stage	 "adult"

Paper : "WBPaper00016861"
Life_stage	 "embryo"

Paper : "WBPaper00016862"
Life_stage	 "larva"

Paper : "WBPaper00017009"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017118"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017169"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017191"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017213"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017354"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017358"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017362"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017377"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017530"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017566"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017570"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017571"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017588"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017608"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017609"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017615"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017620"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017630"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017631"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017636"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017637"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017642"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017643"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017654"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017663"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017672"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017674"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017675"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017705"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017720"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017723"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017724"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017725"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017726"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017727"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017728"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017729"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017735"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017736"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017739"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017740"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017741"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017742"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017744"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017757"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017766"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017774"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017776"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017788"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017791"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017792"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017796"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017800"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017802"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017814"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017821"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017822"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017824"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017829"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017831"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017834"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017839"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017851"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017853"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017860"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017861"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017896"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017897"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017898"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00017900"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017902"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017904"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017905"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017911"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017912"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017925"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017934"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017935"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017939"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017940"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017944"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017948"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017957"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017959"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017961"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017962"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017964"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017966"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017973"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017975"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017984"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017995"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00017996"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018010"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018011"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018014"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018018"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018024"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018045"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018046"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018048"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018050"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018056"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018057"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018058"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018059"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018067"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018070"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018071"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018072"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018074"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018075"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018077"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018083"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018088"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018091"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018092"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018095"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018099"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018101"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018102"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018108"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018112"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018113"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018114"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018119"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018120"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018125"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018133"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018134"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018144"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018146"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018150"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018156"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018158"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018159"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018161"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018162"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018169"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018172"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018176"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018193"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018198"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018229"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018233"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018235"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018239"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018249"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018256"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018259"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018262"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018266"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018274"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018276"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018334"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018339"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018344"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018346"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018350"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018351"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018355"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018359"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018361"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018362"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018363"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018365"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018367"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018368"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018373"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018375"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018377"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018383"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018389"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018393"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018394"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018395"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018400"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018407"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018408"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018413"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018420"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018421"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018424"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018439"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018441"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018442"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018444"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018445"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018446"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018447"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018448"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018449"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018451"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018452"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018453"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018466"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018479"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018484"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018485"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018487"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018505"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018507"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018508"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018513"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018524"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018527"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018538"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018544"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018548"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018561"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018569"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018572"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018573"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018589"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018590"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018592"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018598"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018600"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018604"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018615"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018619"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018620"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018621"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018622"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018627"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018646"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018647"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018649"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018652"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018653"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018656"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00018680"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018681"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018683"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018688"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018689"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018712"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018714"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018716"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018724"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018727"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018728"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018731"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018735"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018736"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018742"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018743"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018752"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018753"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018754"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018761"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018772"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018781"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018786"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018800"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018803"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018812"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018839"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018845"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00018849"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018851"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018854"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018858"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018859"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018862"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018863"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018866"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018867"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018879"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018880"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018882"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018883"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018887"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018899"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018907"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018915"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018940"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018950"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018953"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018964"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018985"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018986"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018988"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018990"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018991"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018994"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018995"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00018997"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019002"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019003"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019005"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019011"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019013"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019030"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019049"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019070"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019077"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019089"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019094"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019097"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019099"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019101"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019105"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019111"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019115"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019117"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019121"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019139"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019141"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019143"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019147"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019154"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019160"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019162"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019179"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019183"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019196"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019198"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019212"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019221"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019226"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019228"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019234"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019236"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019246"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019257"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019262"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019263"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019264"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019271"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019274"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019284"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019285"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019299"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019304"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019318"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019327"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019334"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019335"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019337"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019347"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00019352"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019358"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019370"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019383"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019396"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019397"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019409"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019420"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019451"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019454"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019456"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019461"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019475"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019476"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00019480"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019481"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00019486"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019493"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019511"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019513"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019529"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019530"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019531"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019532"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019535"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00019541"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019544"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019546"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019547"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019557"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019563"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019566"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019569"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019570"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019579"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019580"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019588"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019592"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019594"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019597"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019601"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019604"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019607"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019609"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019610"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019611"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019622"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019631"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019632"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019634"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00019635"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019637"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019638"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019640"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019646"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019660"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019665"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019668"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019682"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019684"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019685"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019687"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019692"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019693"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019698"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019700"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019704"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019705"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019706"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019709"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019710"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019714"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019716"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019719"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019735"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019737"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019738"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019740"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019744"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019750"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019751"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019754"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019756"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019758"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019761"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00019765"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019768"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019769"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019771"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019777"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019779"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019783"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019784"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019786"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00019790"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM03.pl script, 20030725 - Eimear Kenny"

Paper : "WBPaper00021678"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021736"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021759"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021820"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021839"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021855"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021888"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00021926"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022041"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022065"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022071"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022110"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022192"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022194"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022212"
Life_stage	 "embryo"

Paper : "WBPaper00022227"
Life_stage	 "L1 larva"

Paper : "WBPaper00022247"
Life_stage	 "embryo"

Paper : "WBPaper00022262"
Life_stage	 "L4 larva"

Paper : "WBPaper00022265"
Life_stage	 "L3 larva"
Life_stage	 "L4 larva"

Paper : "WBPaper00022268"
Life_stage	 "embryo"

Paper : "WBPaper00022275"
Life_stage	 "L1 larva"

Paper : "WBPaper00022280"
Life_stage	 "embryo"
Life_stage	 "L1 larva"

Paper : "WBPaper00022285"
Life_stage	 "embryo"
Life_stage	 "L1 larva"

Paper : "WBPaper00022293"
Life_stage	 "embryo"

Paper : "WBPaper00022300"
Life_stage	 "embryo"

Paper : "WBPaper00022304"
Life_stage	 "embryo"

Paper : "WBPaper00022319"
Life_stage	 "L4 larva"

Paper : "WBPaper00022320"
Life_stage	 "embryo"
Life_stage	 "L3 larva"

Paper : "WBPaper00022321"
Life_stage	 "embryo"

Paper : "WBPaper00022324"
Life_stage	 "embryo"

Paper : "WBPaper00022326"
Life_stage	 "embryo"

Paper : "WBPaper00022335"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022337"
Life_stage	 "L1 larva"

Paper : "WBPaper00022338"
Life_stage	 "L1 larva"

Paper : "WBPaper00022340"
Life_stage	 "L1 larva"

Paper : "WBPaper00022342"
Life_stage	 "larva"

Paper : "WBPaper00022354"
Life_stage	 "embryo"

Paper : "WBPaper00022359"
Life_stage	 "L4 larva"

Paper : "WBPaper00022375"
Life_stage	 "embryo"
Life_stage	 "L1 larva"

Paper : "WBPaper00022378"
Life_stage	 "L1 larva"

Paper : "WBPaper00022386"
Life_stage	 "embryo"

Paper : "WBPaper00022387"
Life_stage	 "embryo"

Paper : "WBPaper00022390"
Life_stage	 "L3 larva"

Paper : "WBPaper00022396"
Life_stage	 "embryo"

Paper : "WBPaper00022402"
Life_stage	 "L3 larva"

Paper : "WBPaper00022412"
Life_stage	 "L1 larva"

Paper : "WBPaper00022420"
Life_stage	 "embryo"

Paper : "WBPaper00022424"
Life_stage	 "L1 larva"

Paper : "WBPaper00022431"
Life_stage	 "embryo"

Paper : "WBPaper00022433"
Life_stage	 "embryo"

Paper : "WBPaper00022446"
Life_stage	 "embryo"

Paper : "WBPaper00022447"
Life_stage	 "embryo"

Paper : "WBPaper00022448"
Life_stage	 "embryo"

Paper : "WBPaper00022449"
Life_stage	 "embryo"

Paper : "WBPaper00022461"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022468"
Life_stage	 "embryo"

Paper : "WBPaper00022471"
Life_stage	 "embryo"

Paper : "WBPaper00022495"
Life_stage	 "L1 larva"

Paper : "WBPaper00022501"
Life_stage	 "embryo"

Paper : "WBPaper00022502"
Life_stage	 "embryo"

Paper : "WBPaper00022518"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022521"
Life_stage	 "L3 larva"

Paper : "WBPaper00022525"
Life_stage	 "embryo"

Paper : "WBPaper00022531"
Life_stage	 "embryo"

Paper : "WBPaper00022533"
Life_stage	 "L1 larva"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"

Paper : "WBPaper00022535"
Life_stage	 "embryo"

Paper : "WBPaper00022538"
Life_stage	 "embryo"

Paper : "WBPaper00022546"
Life_stage	 "embryo"

Paper : "WBPaper00022549"
Life_stage	 "embryo"

Paper : "WBPaper00022551"
Life_stage	 "embryo"

Paper : "WBPaper00022555"
Life_stage	 "embryo"

Paper : "WBPaper00022559"
Life_stage	 "embryo"

Paper : "WBPaper00022561"
Life_stage	 "L4 larva"

Paper : "WBPaper00022564"
Life_stage	 "L1 larva"

Paper : "WBPaper00022569"
Life_stage	 "L1 larva"

Paper : "WBPaper00022570"
Life_stage	 "L1 larva"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"
Life_stage	 "L4 larva"

Paper : "WBPaper00022575"
Life_stage	 "embryo"

Paper : "WBPaper00022592"
Life_stage	 "L3 larva"

Paper : "WBPaper00022598"
Life_stage	 "embryo"
Life_stage	 "L1 larva"

Paper : "WBPaper00022607"
Life_stage	 "L1 larva"
Life_stage	 "L2 larva"

Paper : "WBPaper00022608"
Life_stage	 "embryo"

Paper : "WBPaper00022609"
Life_stage	 "embryo"

Paper : "WBPaper00022612"
Life_stage	 "embryo"

Paper : "WBPaper00022626"
Life_stage	 "embryo"

Paper : "WBPaper00022628"
Life_stage	 "embryo"

Paper : "WBPaper00022630"
Life_stage	 "L1 larva"
Life_stage	 "L2 larva"

Paper : "WBPaper00022636"
Life_stage	 "embryo"
Life_stage	 "L1 larva"

Paper : "WBPaper00022640"
Life_stage	 "L1 larva"

Paper : "WBPaper00022644"
Life_stage	 "embryo"

Paper : "WBPaper00022648"
Life_stage	 "L1 larva"

Paper : "WBPaper00022650"
Life_stage	 "embryo"

Paper : "WBPaper00022656"
Life_stage	 "L4 larva"

Paper : "WBPaper00022658"
Life_stage	 "L1 larva"

Paper : "WBPaper00022660"
Life_stage	 "embryo"

Paper : "WBPaper00022662"
Life_stage	 "L4 larva"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022665"
Life_stage	 "L1 larva"

Paper : "WBPaper00022666"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"
Life_stage	 "L4 larva"

Paper : "WBPaper00022668"
Life_stage	 "L1 larva"

Paper : "WBPaper00022670"
Life_stage	 "embryo"

Paper : "WBPaper00022674"
Life_stage	 "L1 larva"

Paper : "WBPaper00022681"
Life_stage	 "L1 larva"
Life_stage	 "L2 larva"

Paper : "WBPaper00022683"
Life_stage	 "embryo"

Paper : "WBPaper00022685"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022687"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022692"
Life_stage	 "embryo"

Paper : "WBPaper00022693"
Life_stage	 "embryo"

Paper : "WBPaper00022698"
Life_stage	 "embryo"

Paper : "WBPaper00022707"
Life_stage	 "embryo"

Paper : "WBPaper00022709"
Life_stage	 "L2 larva"

Paper : "WBPaper00022710"
Life_stage	 "embryo"

Paper : "WBPaper00022711"
Life_stage	 "L3 larva"

Paper : "WBPaper00022718"
Life_stage	 "embryo"
Life_stage	 "L1 larva"

Paper : "WBPaper00022726"
Life_stage	 "L1 larva"

Paper : "WBPaper00022732"
Life_stage	 "embryo"

Paper : "WBPaper00022739"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"

Paper : "WBPaper00022741"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022742"
Life_stage	 "larva"

Paper : "WBPaper00022746"
Life_stage	 "L4 larva"

Paper : "WBPaper00022749"
Life_stage	 "L4 larva"

Paper : "WBPaper00022762"
Life_stage	 "embryo"

Paper : "WBPaper00022765"
Life_stage	 "embryo"

Paper : "WBPaper00022772"
Life_stage	 "embryo"

Paper : "WBPaper00022782"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022784"
Life_stage	 "embryo"

Paper : "WBPaper00022785"
Life_stage	 "larva"

Paper : "WBPaper00022792"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"

Paper : "WBPaper00022794"
Life_stage	 "L1 larva"

Paper : "WBPaper00022797"
Life_stage	 "embryo"

Paper : "WBPaper00022801"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"

Paper : "WBPaper00022809"
Life_stage	 "embryo"

Paper : "WBPaper00022813"
Life_stage	 "L4 larva"

Paper : "WBPaper00022814"
Life_stage	 "embryo"

Paper : "WBPaper00022817"
Life_stage	 "embryo"

Paper : "WBPaper00022827"
Life_stage	 "L1 larva"
Life_stage	 "L3 larva"

Paper : "WBPaper00022842"
Life_stage	 "L3 larva"

Paper : "WBPaper00022851"
Life_stage	 "embryo"

Paper : "WBPaper00022852"
Life_stage	 "L2 larva"
Life_stage	 "L3 larva"

Paper : "WBPaper00022853"
Life_stage	 "L2 larva"

Paper : "WBPaper00022855"
Life_stage	 "L1 larva"

Paper : "WBPaper00022862"
Life_stage	 "embryo"

Paper : "WBPaper00022870"
Life_stage	 "L2 larva"

Paper : "WBPaper00022871"
Life_stage	 "L1 larva"

Paper : "WBPaper00022876"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00022881"
Life_stage	 "L1 larva"

Paper : "WBPaper00022890"
Life_stage	 "L1 larva"

Paper : "WBPaper00022941"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023023"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023097"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023223"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023302"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023317"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023445"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023480"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023508"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023541"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023582"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023621"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023654"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023662"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023712"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023722"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023750"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023808"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023811"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023926"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023942"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023944"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023949"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023975"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023983"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023990"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023993"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023996"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00023997"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00023999"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024019"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024020"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024023"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024028"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024035"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024039"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024040"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024069"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024092"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024094"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024096"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024100"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00024106"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024109"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024113"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024116"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024119"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00024128"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024130"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024139"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024143"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024163"
Life_stage	 "postembryonic" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024164"
Life_stage	 "adult" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024168"
Life_stage	 "embryo" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024171"
Life_stage	 "larva" Inferred_automatically "by abstract2aceLeonsFormat.pl eek"

Paper : "WBPaper00024201"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024206"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024242"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024251"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"

Paper : "WBPaper00024252"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024261"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024262"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024278"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024286"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00024320"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024324"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024331"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024337"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024347"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024349"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024374"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024378"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024393"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"

Paper : "WBPaper00024394"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00024397"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00024399"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024419"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024423"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"

Paper : "WBPaper00024424"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"

Paper : "WBPaper00024430"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024450"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00024467"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024472"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00024475"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"

Paper : "WBPaper00024498"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00024507"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-11-11 - Eimear Kenny"

Paper : "WBPaper00024543"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-11-11 - Eimear Kenny"

Paper : "WBPaper00024546"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-11-11 - Eimear Kenny"

Paper : "WBPaper00024590"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024621"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024645"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00024650"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024664"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024668"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024678"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024692"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-01-21 - Eimear Kenny"

Paper : "WBPaper00024708"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024710"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024712"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024727"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024728"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024731"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024735"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024738"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024741"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024742"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024743"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024744"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024747"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024757"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024758"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024767"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024773"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024774"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024794"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024802"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024816"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024827"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024828"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024840"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-08 - Eimear Kenny"

Paper : "WBPaper00024873"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024874"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"

Paper : "WBPaper00024878"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024879"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024887"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024903"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024913"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024930"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024931"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-02-09 - Eimear Kenny"

Paper : "WBPaper00024973"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-03-02 - Eimear Kenny"

Paper : "WBPaper00024974"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceCGC.pl script, 2005-03-02 - Eimear Kenny"

Paper : "WBPaper00024976"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00024977"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-03-02 - Eimear Kenny"

Paper : "WBPaper00024985"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00025033"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-03-24 - Eimear Kenny"

Paper : "WBPaper00025044"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-03-24 - Eimear Kenny"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00025057"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2005-04-14 - Eimear Kenny"

Paper : "WBPaper00025081"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025084"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025088"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025089"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025100"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025105"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00025106"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025109"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-05 - Eimear Kenny"

Paper : "WBPaper00025114"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025115"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025149"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-10-19 17:50"

Paper : "WBPaper00025163"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025184"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025188"
Life_stage	 "larva" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025191"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025194"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025196"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025200"
Life_stage	 "adult" Inferred_automatically "abstract2aceCGC.pl script, 2005-05-27 - Eimear Kenny"

Paper : "WBPaper00025229"
Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2005-06-14 - Eimear Kenny"

Paper : "WBPaper00025250"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025254"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025262"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025264"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025267"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025272"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025279"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025286"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025288"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025296"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025303"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025304"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025305"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025311"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025312"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025319"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025330"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025335"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025343"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025355"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025356"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025362"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025368"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025369"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025372"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025378"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025387"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025394"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025407"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025418"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025423"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025427"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025435"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025439"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025452"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025455"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025466"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025470"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025471"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025477"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025481"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025484"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025487"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025491"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025509"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025514"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025519"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025531"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025543"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025544"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025545"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025550"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025559"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025561"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025563"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025572"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025574"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025579"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025592"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025607"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025611"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025612"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025613"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025615"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025628"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025630"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025646"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025647"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025648"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025651"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025656"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025679"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025684"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025697"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025698"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025702"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025703"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025712"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025717"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025719"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025746"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025752"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025768"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025772"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025792"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025801"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025804"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025806"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025814"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025816"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025817"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025823"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025826"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025831"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025837"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025839"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025859"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025863"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025870"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025891"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025894"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025898"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025906"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025910"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025916"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025917"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025918"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025919"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025920"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025929"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025934"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025942"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025944"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025950"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025952"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025956"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025958"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025966"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025967"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025971"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025978"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025983"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025984"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025985"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025994"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00025999"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026000"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026001"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026003"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026010"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026022"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026025"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026029"
Life_stage	 "larva" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026043"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026044"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026045"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026046"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026050"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026063"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026076"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026079"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026080"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026088"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026097"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026098"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026105"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026106"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026111"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026121"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026127"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026140"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026165"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026170"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026175"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026179"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026180"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026181"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026183"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026187"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026189"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026190"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026192"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026193"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026195"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026202"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026213"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026215"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026229"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026230"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026234"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026239"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026243"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026257"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026265"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026266"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026267"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026280"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026281"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026285"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026295"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026297"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026302"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026341"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026351"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026355"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026357"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026363"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026366"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026367"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026370"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026372"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026375"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026379"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026386"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026388"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026391"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026392"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026395"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026396"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026412"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026416"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026424"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026433"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026436"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026437"
Life_stage	 "postembryonic" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026442"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026467"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026475"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026476"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026477"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026478"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026484"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026490"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026492"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026507"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026517"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026520"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026528"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026543"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026548"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026553"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026563"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026577"
Life_stage	 "embryo" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026584"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026585"
Life_stage	 "adult" Inferred_automatically "abstract2aceWM05.pl script, 2005-06-14 15:25"

Paper : "WBPaper00026609"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026624"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00026626"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00026630"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00026634"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00026650"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-07-28 14:48"

Paper : "WBPaper00026672"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-08-18 15:51"

Paper : "WBPaper00026712"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"

Paper : "WBPaper00026739"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"

Paper : "WBPaper00026753"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"

Paper : "WBPaper00026756"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-09-08 14:47"

Paper : "WBPaper00026776"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026780"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026784"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026786"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026791"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026793"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026795"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026810"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026833"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026845"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026860"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026891"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026912"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-11-17 16:04"

Paper : "WBPaper00026958"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-12-20 15:08"

Paper : "WBPaper00026965"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2005-12-20 15:08"

Paper : "WBPaper00027000"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027001"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027005"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027006"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027016"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027028"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027036"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-02-07 13:04"

Paper : "WBPaper00027074"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027075"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027080"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027092"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027100"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027103"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027110"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027122"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027124"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-02 17:32"

Paper : "WBPaper00027139"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00027142"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00027145"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00027153"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-03-23 14:00"

Paper : "WBPaper00027180"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027186"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027187"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027189"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027195"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027203"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027212"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027213"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-04-13 15:19"

Paper : "WBPaper00027230"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027235"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027236"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027244"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027261"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027278"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027282"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027283"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027300"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027316"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027327"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027335"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027339"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027340"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027341"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027346"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027351"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027373"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027374"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027375"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027377"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027390"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027395"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027396"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027398"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027404"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027409"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027410"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027412"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027416"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027426"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027434"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027436"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027453"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027457"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027460"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027465"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027479"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027492"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027500"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027507"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027541"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027546"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027575"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00027606"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-05 10:44"

Paper : "WBPaper00027607"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-25 18:30"

Paper : "WBPaper00027613"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-25 18:30"

Paper : "WBPaper00027630"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-05-25 18:30"

Paper : "WBPaper00027643"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-06-15 16:54"

Paper : "WBPaper00027660"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-06-15 16:54"

Paper : "WBPaper00027672"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-06-15 16:54"

Paper : "WBPaper00027690"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-06 16:26"

Paper : "WBPaper00027693"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-06 16:26"

Paper : "WBPaper00027696"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-06 16:26"

Paper : "WBPaper00027703"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-06 16:26"

Paper : "WBPaper00027716"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-06 16:26"

Paper : "WBPaper00027719"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-06 16:26"

Paper : "WBPaper00027774"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027775"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027776"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027778"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-29 11:24"

Paper : "WBPaper00027779"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027785"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027786"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027788"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027791"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027792"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027794"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027795"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027834"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027842"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027843"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027859"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027861"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027863"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027880"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027882"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027885"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027900"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027904"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027907"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027909"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027919"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027920"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027921"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027922"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027933"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027935"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027936"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027946"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027949"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027951"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027952"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027954"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027956"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027958"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027962"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027964"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027966"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027973"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027986"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00027999"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028015"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028018"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028040"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028045"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028048"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028052"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028053"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028056"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-07-28 10:51"

Paper : "WBPaper00028081"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028083"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028084"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028089"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028096"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028125"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028145"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028163"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028167"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028187"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028224"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028240"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028254"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028261"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028264"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028273"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028283"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028327"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00028339"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028344"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028386"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028390"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028394"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-08-17 17:19"

Paper : "WBPaper00028415"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-07 15:02"

Paper : "WBPaper00028441"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-07 15:02"

Paper : "WBPaper00028449"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-07 15:02"

Paper : "WBPaper00028458"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-07 15:02"

Paper : "WBPaper00028482"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-29 11:24"

Paper : "WBPaper00028515"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-29 11:24"

Paper : "WBPaper00028518"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-29 11:24"

Paper : "WBPaper00028522"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-29 11:24"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-09-29 11:24"

Paper : "WBPaper00028613"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028617"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028618"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028622"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028626"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028638"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028641"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028666"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028684"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028692"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028693"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028695"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028699"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028700"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028703"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028709"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028710"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028716"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028717"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028719"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028729"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028733"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028734"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028751"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028758"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028760"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-09 17:48"

Paper : "WBPaper00028769"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"

Paper : "WBPaper00028770"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"

Paper : "WBPaper00028785"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"

Paper : "WBPaper00028790"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"

Paper : "WBPaper00028802"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"

Paper : "WBPaper00028813"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-11-30 16:22"

Paper : "WBPaper00028826"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028848"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028855"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028857"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028862"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028878"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028908"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028911"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028916"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2006-12-21 17:34"

Paper : "WBPaper00028954"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-01-18 17:42"

Paper : "WBPaper00028964"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-01-18 17:42"

Paper : "WBPaper00028985"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-01-18 17:42"

Paper : "WBPaper00028991"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-01-18 17:42"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-01-18 17:42"

Paper : "WBPaper00029017"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-02-08 18:12"

Paper : "WBPaper00029059"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-02-08 18:12"

Paper : "WBPaper00029060"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-02-08 18:12"

Paper : "WBPaper00029091"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-02-08 18:12"

Paper : "WBPaper00029102"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00029104"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00029112"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00029124"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-02 14:18"

Paper : "WBPaper00029149"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-03-23 11:32"

Paper : "WBPaper00029203"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"

Paper : "WBPaper00029208"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"

Paper : "WBPaper00029220"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"

Paper : "WBPaper00029221"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"

Paper : "WBPaper00029231"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-04-12 16:57"

Paper : "WBPaper00029289"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029301"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029304"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029306"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029308"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029324"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029325"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029331"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029334"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-04 11:55"

Paper : "WBPaper00029341"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029343"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029354"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029360"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029365"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029381"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029404"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-05-25 11:20"

Paper : "WBPaper00029430"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029434"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029435"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029437"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029459"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029463"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029466"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029468"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029471"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029478"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029483"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029488"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029498"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029506"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029510"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029517"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029519"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029521"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029524"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029533"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029538"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029539"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029543"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029549"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029551"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029561"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029586"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029594"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029596"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029597"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029605"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029612"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029613"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029622"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029631"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029634"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029689"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029694"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029704"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029735"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029767"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029775"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029780"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029784"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029790"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029794"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029795"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029804"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029807"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029818"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029825"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029826"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029827"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029832"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029835"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029842"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029850"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029858"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029863"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029871"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029880"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029881"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029888"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029891"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029905"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029907"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029909"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029922"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029926"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029940"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029945"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029961"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029978"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029983"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029989"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029990"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029997"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00029999"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030005"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030006"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030009"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030010"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030017"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030025"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030027"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030034"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030051"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030062"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030078"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030086"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030088"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030090"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030102"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030107"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030111"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030116"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030117"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030121"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030143"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030169"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030171"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030183"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030192"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030202"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030205"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030240"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030259"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030264"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030266"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030269"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030280"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030286"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030292"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030295"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030296"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030314"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030350"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030358"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030367"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030368"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030369"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030385"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030402"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030409"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030425"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030430"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030441"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030444"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030450"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030457"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030460"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030477"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030484"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030489"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030499"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030506"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030509"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030514"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030520"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030525"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030542"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030552"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030560"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030565"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030574"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030576"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030577"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030578"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030579"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030585"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030587"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030588"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030595"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030601"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030609"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030615"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030625"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030627"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030629"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030638"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030642"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030644"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030645"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030650"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030652"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030659"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030663"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030673"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030674"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030676"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030685"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030687"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030704"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030713"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030714"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030721"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030733"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-06-14 16:32"

Paper : "WBPaper00030767"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-07-06 12:04"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-07-06 12:04"

Paper : "WBPaper00030802"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-07-27 16:31"

Paper : "WBPaper00030836"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-07-27 16:31"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-07-27 16:31"

Paper : "WBPaper00030890"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-09-07 09:38"

Paper : "WBPaper00030933"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-09-07 09:38"

Paper : "WBPaper00030936"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-09-07 09:38"

Paper : "WBPaper00030942"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00030978"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031001"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031004"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031006"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031009"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031011"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031019"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031040"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031042"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031065"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031069"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031097"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-10-19 11:44"

Paper : "WBPaper00031108"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-09 11:35"

Paper : "WBPaper00031118"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-09 11:35"

Paper : "WBPaper00031146"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-09 11:35"

Paper : "WBPaper00031167"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-09 11:35"

Paper : "WBPaper00031168"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-09 11:35"

Paper : "WBPaper00031171"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-09 11:35"

Paper : "WBPaper00031192"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-30 11:47"

Paper : "WBPaper00031233"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-30 11:47"

Paper : "WBPaper00031241"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-30 11:47"

Paper : "WBPaper00031247"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2007-11-30 11:47"

Paper : "WBPaper00031254"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031269"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031270"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031282"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031283"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031284"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031309"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031314"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031330"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031351"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031355"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-04 14:52"

Paper : "WBPaper00031378"
Life_stage	 "postembryonic" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-25 13:22"

Paper : "WBPaper00031381"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-25 13:22"

Paper : "WBPaper00031414"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-25 13:22"

Paper : "WBPaper00031415"
Life_stage	 "embryo" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-25 13:22"

Paper : "WBPaper00031447"
Life_stage	 "adult" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-25 13:22"
Life_stage	 "larva" Inferred_automatically "citace_upload\/papers\/find_diff.pl script, 2008-01-25 13:22"

