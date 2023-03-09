#!/usr/bin/perl -w

use strict;
use diagnostics;
# use Ace;

my $file = 'Iino_RNAi_data.txt';
my $cDNA = 'cDNA_positions.ace';

my %cDNA;	# hash of cDNA output by relevant sequence as key
my %seqs;	# hash of sequences in WS92

my $seqs = 'WS93_sequence_name.ace';
open (SEQ, "<$seqs") or die "Cannot open $seqs : $!";
while (<SEQ>) {
  $_ =~ m/Sequence : \"(.*?)[\"]/;
  # $_ =~ m/Sequence : \"(.*?)[\.\"]/;
  $seqs{$1}++;
} # while (<SEQ>)
close (SEQ) or die "Cannot close $seqs : $!";


$/ = '';
open (CDN, "<$cDNA") or die "Cannot open $cDNA : $!";
while (my $line = <CDN>) {
  my $line2 = <CDN>;
  my ($seq) = $line2 =~ m/^Sequence : (.*?)\n/;
  if ($seqs{$seq}) {		# in acedb, don't include the whole thing
    $line = $line2;		# get stuff from line2
    $line =~ s/Method.*\n//g;	# take out extra lines
    $line =~ s/From_Laboratory.*\n//g;
    $line =~ s/Remark.*\n//g;
  } else {			# not in acedb, include everything
    $line .= $line2;		# use line and line2
    $line =~ s/RNAi \"(.*?)\"/RNAi $1/g;		# take out quotes
    $line =~ s/Method \"(.*?)\"/Method $1/g;
    $line =~ s/From_Laboratory \"JN\"/From_Laboratory YK/g;
  } # if ($seqs{$seq})

  $cDNA{$seq} = $line;
} # while (<CDN>)
close (CDN) or die "Cannot close $cDNA : $!";
$/ = "\n";

# my $ace_query = 'Find Sequence';
# my $db = Ace->connect(-path  =>  '/home/acedb/WS_current',
#                       -program => '/home/acedb/bin/tace'
# 		     ) or die "Connection failure: ",Ace->error;
# my @ready_names= $db->fetch(-query=>$ace_query);
# print scalar(@ready_names) . "</FONT> results<BR>\n";



open (IN, "<$file") or die "Cannot open $file : $!";
while (my $line = <IN>) {
  next if ($line =~ m/^\D/);
  chomp $line;

  $line =~ s/\"//g;
  my @array = split/\t/, $line;

  print "RNAi : JN:$array[1]\n";
  print "Method  RNAi\n";
  print "Laboratory      JN\n";
  print "Laboratory      YK\n";
  print "Author  \"Hanazawa M\"\n";
  print "Author  \"Mochii M\"\n";
  print "Author  \"Ueno N\"\n";
  print "Author  \"Kohara Y\"\n";
  print "Author  \"Iino Y\"\n";
  print "Date    \"2001-07-17\"\n";
  print "Strain  \"peIs1[let-60::gfp]\"\n";
  print "Delivered_by    \"Injection\"\n";
  print "Reference       [cgc4769]\n";
  if ($array[2]) { print "Phenotype       $array[2]\n"; }
    else { print "Phenotype       WT\n"; }
  print "Remark  \"co-injectin of gfp dsRNA as a control\"\n";
  print "Remark  \"Authors\' Web Link-General <http://park.itc.u-tokyo.ac.jp/mgrl/germline/>\"\n";
  print "Remark  \"Authors\' Web Link-Specific <http://park.itc.u-tokyo.ac.jp/mgrl/germline/clones/" . $array[0] . ".html>\"\n";
  print "\n";
  print $cDNA{$array[1]} . "\n";
#   print "Sequence : XXX\n";
#   print "Nongenomic      $array[1] N1 N2\n";
#   print "\n";
#   print "Sequence : $array[1]\n";
#   print "RNAi    JN:$array[1] 1 N3\n";
#   print "Method  cDNA_for_RNAi\n";
#   print "From_Laboratory YK\n";
#   print "Remark  \"EST clone used in RNAi assay\"\n\n\n";
  
} # while (<IN>)
close (IN) or die "Cannot close $file : $!";

