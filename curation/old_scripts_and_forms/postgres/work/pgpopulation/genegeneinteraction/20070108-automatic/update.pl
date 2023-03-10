#!/usr/bin/perl

# Get new sentences that match from textpresso, simplify the data, and append to
# sourcefile for
# http://tazendra.caltech.edu/~postgres/cgi-bin/gene_gene_interaction.cgi
# 2007 01 08

# cronjob set :
# 0 5 1 * * /home/postgres/work/pgpopulation/andrei_genegeneinteraction/20070108-automatic/update.pl



use Jex;
use LWP::Simple;

my $startdate = &getSimpleSecDate();
# print "DATE $startdate DATE\n";

my $directory = '/home/postgres/work/pgpopulation/andrei_genegeneinteraction/20070108-automatic';
chdir($directory) or die "Cannot go to $directory ($!)";

my $source = get("http://main.textpresso.org/azurebrd/ggi_updates/ggi_update");
my @lines = split/\n/, $source;

# my $filter_file = 'filter_20060307.txt'; 
# my $filter_file = 'ggi_update'; 
my $out_file = 'ggi_update.filter';
my $err_file = 'errors/err.simplify.html_' . $startdate;
my $count = 0;			# line number read in
my $realcount = 0;		# line number of output file

open (IN, "<$out_file") or die "Cannot open $out_file : $!";
while (my $line = <IN>) { if ($line =~ m/^(\d+)/) { $realcount = $1; } }
close (IN) or die "Cannot close $out_file : $!";

open (OUT, ">>$out_file") or die "Cannot append to $out_file : $!";
open (ERR, ">$err_file") or die "Cannot open $err_file : $!";

# while (my $line = <IN>) { # }	# used to get data from a sourcefile instead of web
#   chomp $line;
foreach my $line (@lines) {
  $count++;
  my ($paper, $sentence, $text) = $line =~ m/^\S+(WBPaper\d+) : \<sentence id='(s\d+)'>(.*?)$/;
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
} # foreach my $line (@lines)

close (OUT) or die "Cannot close $out_file : $!";
close (ERR) or die "Cannot close $err_file : $!";

my $enddate = &getSimpleSecDate();
# print "DATE $enddate DATE\n";
