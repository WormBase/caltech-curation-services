#!/usr/bin/perl

use Jex;

my $startdate = &getPgDate();
print "DATE $startdate DATE\n";

my $filter_file = 'filter_20060307.txt'; 
my $html_file = 'html_20060307.txt';
my $err_file = 'err.simplify.html_20060307';
my $count = 0;			# line number read in
my $realcount = 0;		# line number of output file

open (IN, "<$filter_file") or die "Cannot open $filter_file : $!";
open (OUT, ">$html_file") or die "Cannot open $html_file : $!";
open (ERR, ">$err_file") or die "Cannot open $err_file : $!";
# while (my $line = <IN>) { $count++; if ($count == 10000) { print "$line"; } }

while (my $line = <IN>) {
  chomp $line;
  $count++;
  my ($paper, $sentence, $text) = $line =~ m/^\S+(WBPaper\d+) : \<sentence id='(s\d+)'>(.*?)$/;
#   if ($text =~ m/\<association[^>]*\>/) {
#     $text =~ s/\<association[^>]*\>/\<font color=green\>/g; }
#   if ($text =~ m/\<\/association[^>]*\>/) {
#     $text =~ s/\<\/association[^>]*\>/\<\/font\>/g; }
#   if ($text =~ m/\<regulation[^>]*\>/) {
#     $text =~ s/\<regulation[^>]*\>/\<font color=red\>/g; }
#   if ($text =~ m/\<\/regulation[^>]*\>/) {
#     $text =~ s/\<\/regulation[^>]*\>/\<\/font\>/g; }
#   if ($text =~ m/\<gene[^>]*\>/) {
#     $text =~ s/\<gene[^>]*\>/\<font color=blue\>/g; }
#   if ($text =~ m/\<\/gene[^>]*\>/) {
#     $text =~ s/\<\/gene[^>]*\>/\<\/font\>/g; }
  if ($text =~ m/\<association[^>]*\>/) {
    $text =~ s/\<association[^>]*\>/STARTgreen/g; }
  if ($text =~ m/\<\/association[^>]*\>/) {
    $text =~ s/\<\/association[^>]*\>/ENDcolorFONT/g; }
  if ($text =~ m/\<regulation[^>]*\>/) {
    $text =~ s/\<regulation[^>]*\>/STARTred/g; }
  if ($text =~ m/\<\/regulation[^>]*\>/) {
    $text =~ s/\<\/regulation[^>]*\>/ENDcolorFONT/g; }
  if ($text =~ m/\<gene[^>]*\'direct\'[^>]*\>/) {
    $text =~ s/\<gene[^>]*\>/STARTblue/g; }
  if ($text =~ m/\<\/gene[^>]*\>/) {
    $text =~ s/\<\/gene[^>]*\>/ENDcolorFONT/g; }
  if ($text =~ m/\<[a-z]{2,}[^>]+\>/) {
    $text =~ s/\<[a-z]{2,}[^>]+\>//g; }
  if ($text =~ m/\<\/[a-z]{2,}[^>]+\>/) {
    $text =~ s/\<\/[a-z]{2,}[^>]+\>//g; }
  my $genes; my @genes; my %genes;
  if ($text =~ m/STARTblue(.*?)ENDcolorFONT/) { (@genes) = $text =~ m/STARTblue(.*?)ENDcolorFONT/g; }
  foreach my $gene (@genes) {
    if ($gene =~ m/^\s+/) { $gene =~ s/^\s+//g; }
    if ($gene =~ m/\s+$/) { $gene =~ s/\s+$//g; }
    $genes{$gene}++; } 
  @genes = sort keys %genes;
  $genes = join"; ", @genes;
  if (scalar(@genes) < 2) { print ERR "less than 2 genes $count\tgenes\t$paper : $sentence\t$text\n"; }
    else {
      $realcount++;
      if ($text =~ m/STARTblue/) { $text =~ s/STARTblue/\<font color=blue\>/g; }
      if ($text =~ m/STARTred/) { $text =~ s/STARTred/\<font color=red\>/g; }
      if ($text =~ m/STARTgreen/) { $text =~ s/STARTgreen/\<font color=green\>/g; }
      if ($text =~ m/ENDcolorFONT/) { $text =~ s/ENDcolorFONT/\<\/font\>/g; }
      print OUT "$realcount\t$paper : $sentence\t$genes\t$text<BR>\n"; }
} # while (my $line = <IN>)

close (IN) or die "Cannot close $filter_file : $!";
close (OUT) or die "Cannot close $html_file : $!";
close (ERR) or die "Cannot close $err_file : $!";

my $enddate = &getPgDate();
print "DATE $enddate DATE\n";
