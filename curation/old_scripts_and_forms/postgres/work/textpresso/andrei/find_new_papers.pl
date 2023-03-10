#!/usr/bin/perl

# pick 101 random sentences with gene gene interaction (no two from same paper)
# by looking at cde's for codes, then getting relative xml.  2003 11 04
#
# commented out %cde stuff so that papers will be randomly ordered, but all
# sentenced for a given paper are together.  2003 12 02


# Look at a file ``papers'' that contains a list of all papers that have
# previously been already looked at by this script.  Exclude those files from
# reading sentences from them.  Look at all WBPapers and update the ``papers''
# file, then looking at the new papers, match some paramenters and create an
# output file in /var/www/html for tazendra cronjob to grab for the
# gene_gene_interaction.cgi and create a copy locally for reference.  20070108

# cronjob set every 1st of the month at 1am
# 0 1 1 * * /home/azurebrd/work/get_andrei_gene_gene/20070108_automatic/find_new_papers.pl

# TODO 
# start from paper WBPaper00027070
# filter out - before and after genes
# lower case all gene word
# filter out any genes with the word locus, gene, bcl-2, apaf-1
# if only two genes and they are in pair list, filter them out
# if only three genes and all three pair combinations are in the list, filter them out
# see interactors_pairs.txt
# 
# look for "association grammar" and/or "regulation grammar" in a sentence
# as well as two "gene_celegans.*reference='direct'"  in a sentence at :
# /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans/Data/annotations/body/semantic
# and get the full sentences at :
# /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans/Data/processedfiles/body/




use strict;
use diagnostics;

use HTTP::Request;
use LWP::UserAgent;

# srand;

my $semantic_dir = '/usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans/Data/annotations/body/semantic/';
my $sentence_dir = '/usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans/Data/processedfiles/body/';

# my $directory = '/home/azurebrd/work/get_andrei_gene_gene/20070108_automatic';
my $directory = '/home/azurebrd/work/get_andrei_gene_gene/20080307_newtextpresso';
chdir($directory) or die "Cannot go to $directory ($!)";


my %intp;	# interactor pairs
&populateIntp();

my %locWbg;	# locus to wbgene
&popLocWbg();

sub popLocWbg {
# PUT THIS BACK
  `wget http://tazendra.caltech.edu/~postgres/cgi-bin/wbgene_locus.cgi`;
  my $infile = $directory . '/wbgene_locus.cgi';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) { chomp $line; next unless ($line); my ($a, $b) = split/\t/, $line; $locWbg{$a} = $b; }
  close (IN) or die "Cannot close $infile : $!";
# PUT THIS BACK
  `rm $infile`;
} # sub popLocWbg

sub populateIntp {
  my $infile = $directory . '/interactors_pairs.txt';
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) { chomp $line; my ($a, $b) = split/\t/, $line; $intp{$a}{$b}++; $intp{$b}{$a}++; }
  close (IN) or die "Cannot close $infile : $!";
} # sub populateIntp

my %old_papers;
my $source = 'ggi_papers';
open (IN, "<$source") or die "Cannot open $source : $!";
while (<IN>) { $_ =~ m/(WBPaper\d+)/; $old_papers{$1}++; }
close (IN) or die "Cannot close $source : $!";

my $date = &getSimpleSecDate();


# my @wbfiles = </var/www/html/tdb/art/cde/WBPaper*>;		# 2004 07 30 pmid abstract set
my @allwbfiles = </usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans/Data/annotations/body/semantic/WBPaper*>;		# 2004 07 30 pmid abstract set
my @wbfiles;
foreach my $file (@allwbfiles) { if ($file =~ m/(WBPaper\d+)/) { my $paper = $1; unless ($old_papers{$paper}) { push @wbfiles, $paper; } } }

my $sent_count = 0;			# the sentence number counter to use when adding a new sentence

my $total = scalar(@wbfiles);
my $ggifile = 'ggi_lines';		# file of source lines for gene_gene_interaction.cgi
my $outfile = 'ggi_papers';		# history of wbpapers already looked at
my $outfile2 = 'ggi_papers.' . $date;	# wbpapers looked at on this date

$/ = undef;
open (IN, "<$ggifile") or die "Cannot open $ggifile : $!";		# get the latest used sentence count number
my $all_file = <IN>; my (@lines) = split/\n/, $all_file; my $line = pop @lines; ($sent_count, my @junk) = split/\t/, $line;
close (IN) or die "Cannot close $ggifile : $!";
$/ = "\n";

# print "SC $sent_count SC\n";

open (GGI, ">>$ggifile") or die "Cannot create $ggifile : $!";
# PUT THIS BACK
open (OUT, ">>$outfile") or die "Cannot create $outfile : $!";
# PUT THIS BACK
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!";


foreach my $wbpaper (@wbfiles) {
#   my $wbpaper = shift @wbfiles;
#   my $wbpaper = 'WBPaper00028370';
# PUT THIS BACK
  print OU2 "FILE /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans/Data/annotations/body/semantic/$wbpaper FILE\n";
# PUT THIS BACK TO ADD TO IGNORE LIST
  print OUT "$wbpaper\n";

  my $sem_file = $semantic_dir . $wbpaper;

  $/ = undef;
  open (IN, "<$sem_file") or warn "Cannot open $sem_file : $!";
  my $all_paper = <IN>;
  close (IN) or warn "Cannot close $sem_file : $!";
  $/ = "\n";
  my (@sentences) = split/### EOS ###/, $all_paper;
  foreach my $sentence (@sentences) {
    my ($sid) = $sentence =~ m/^\s*### s(\d+) ###/m;
    &parseSentence($sentence, $wbpaper, $sid);
  } # foreach my $sentence (@sentences)
} # foreach my $wbpaper (@wbfiles)

# PUT THIS BACK
close (OUT) or die "Cannot close $outfile : $!";
# PUT THIS BACK
close (OU2) or die "Cannot close $outfile2 : $!";

close (GGI) or die "Cannot close $ggifile : $!";



sub parseSentence {
  my ($sentence, $wbpaper, $sid) = @_;
  my (@words) = split/## EOA ##\n## BOA ##/, $sentence;

# look for "association grammar" and/or "regulation grammar" in a sentence
# as well as two "gene_celegans.*reference='direct'"  in a sentence at :

  my %reg; my %ass; my %genes; my %wbgenes;
  foreach my $word (@words) {
    $word =~ s/^## BOA ##\n//g;
    $word =~ s/^\n//g;
    $word =~ s/\n## EOA ##$//g;
    if ($word =~ m/gene_celegans.*reference='direct'/) { 
      next if ($word =~ m/reporter_gene_celegans/); 		# don't use reporter genes
      if ($word =~ m/^(.*?)\n(\d+)\n/) { 
        my $gene = $1; ($gene) = lc($gene); $gene =~ s/^\-//; $gene =~ s/\-$//; $genes{$gene}++; } }
    if ($word =~ m/association grammar/) { if ($word =~ m/^(.*?)\n(\d+)\n/) { $ass{$1}++; } }
    if ($word =~ m/regulation grammar/) { if ($word =~ m/^(.*?)\n(\d+)\n/) { $reg{$1}++; } }
  } # foreach my $word (@words)
  my (@genes) = keys %genes;
  my (@ass) = keys %ass;
  my (@reg) = keys %reg;
  if ( (scalar(@genes) > 1) && ( (scalar(@reg) > 0) || (scalar(@ass) > 0) )) {
# print "SENT $sentence SENT\n"; 
    my $done = 0;		# if already in list of interactors_pairs.txt, call it done
    if (scalar(@genes) < 3) {
      my $loc1 = $genes[0]; my $loc2 = $genes[1]; my $wbg1 = ''; my $wbg2 = '';
      if ($locWbg{$loc1}) { $wbg1 = $locWbg{$loc1}; }
      if ($locWbg{$loc2}) { $wbg2 = $locWbg{$loc2}; }
      if ($intp{$wbg1}{$wbg2}) { if ($intp{$wbg1}{$wbg2} > 1) { $done++; } } }
    elsif (scalar(@genes) < 4) {
      my $loc1 = $genes[0]; my $loc2 = $genes[1]; my $loc3 = $genes[2]; my $wbg1 = ''; my $wbg2 = ''; my $wbg3 = ''; 
      if ($locWbg{$loc1}) { $wbg1 = $locWbg{$loc1}; }
      if ($locWbg{$loc2}) { $wbg2 = $locWbg{$loc2}; }
      if ($locWbg{$loc3}) { $wbg3 = $locWbg{$loc3}; }
      if ($intp{$wbg1}{$wbg2}) { if ($intp{$wbg1}{$wbg2} > 1) { $done++; } }
      if ($intp{$wbg1}{$wbg3}) { if ($intp{$wbg1}{$wbg3} > 1) { $done++; } }
      if ($intp{$wbg3}{$wbg2}) { if ($intp{$wbg3}{$wbg2} > 1) { $done++; } } 
      unless ($done == 3) { $done = 0; } }		# call it done only if all three interactions are there
    if ($done > 0) { return; }			# don't return the sentence if interactions are already done
    $sent_count++;					# valid sentence, up the sentence count
    $/ = undef;
    my $sent_file = $sentence_dir . $wbpaper;
    open (IN, "<$sent_file") or warn "Cannot open $sent_file : $!";
    my $all_paper = <IN>;
    close (IN) or warn "Cannot close $sent_file : $!";
    my (@actual_sentences) = split/\n/, $all_paper;
    for (2 .. $sid) { shift @actual_sentences; }
    my $actual_sentence = shift @actual_sentences;
    my $parsed_sentence = $actual_sentence;
    foreach my $loc (@genes) { if ($parsed_sentence =~ m/$loc/i) { $parsed_sentence =~ s/($loc)/<FONT COLOR=blue>$1<\/FONT>/gi; } }
    foreach my $ass (@ass) { if ($parsed_sentence =~ m/$ass/i) { $parsed_sentence =~ s/($ass)/<FONT COLOR=green>$1<\/FONT>/gi; } }
    foreach my $reg (@reg) { if ($parsed_sentence =~ m/$reg/i) { $parsed_sentence =~ s/($reg)/<FONT COLOR=red>$1<\/FONT>/gi; } }
#     print "SENTFILE $sent_file SENTFILE\n";
#     print "SID $sid SID\n";
#     print "GENES @genes here\n";
#     print "REGULATION @reg here\n"; 
#     print "ASSOCIATION @ass here\n"; 
#     print "ACT $actual_sentence ACT\n\n"; 
#     print "PAR $parsed_sentence PAR\n\n"; 
    my $genes = join"; ", @genes;
    print GGI "$sent_count\t$wbpaper : s$sid\t$genes\t$parsed_sentence\n";
  } # if ( (scalar(@genes) > 1) && ( (scalar(@reg) > 0) || (scalar(@ass) > 0) ))

#   foreach my $convert_word ( sort keys %{ $convert_hash{convertifier} }) {
#     my $actual_word = $convert_hash{convertifier}{$convert_word};
#     $actual_sentence =~ s/$convert_word/$actual_word/g; }
#   my @genes = sort keys %genes; my $genes = join", ", @genes;
#   my @components = sort keys %components; my $components = join", ", @components;
#   my $return_val = "$genes\t$components\t$actual_sentence\n";
#   my $return_val = 'something';
#   return $return_val;
} # sub parseSentence





sub getSimpleSecDate {                  # begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}.${hour}${min}${sec}";   # get final date
  return $shortdate;
} # sub getSimpleSecDate                # end getSimpleDate



__END__


my @cde = ();	# files and lines in cde format

# my $good = 0;
# foreach my $pap (sort keys %files) {
#   if ($good > 100) { last; }		# uncomment this for sample size
#   my $file = shift @files;
#   my $file = $files{$key};
#   open (IN, "<$file") or die "Cannot open $file : $!";
#   while (<IN>) {
#     # if ( ( ($_ =~ m/\d+ged.*\d+ged/) || ($_ =~ m/\d+ged.*\d+fud\w+?yete/) || ($_ =~ m/\d+ged.*\d+fud\w+?yete.*/) || ($_ =~ m/\d+fud\w+?yete.*\d+fud\w+?yete/) ) && ( ($_ =~ m/\d+as/) || ($_ =~ m/\d+re/) ) ) 	# for direct proteins as well as genes.
#     if ( ($_ =~ m/\d+ged.*\d+ged/) && ( ($_ =~ m/\d+as/) || ($_ =~ m/\d+re/) ) ) {
#       $good++;
#       push @cde, "$file : $_\n"; 
#     }
#   } # while (<IN>)
#   close (IN) or die "Cannot close $file : $!";
# } # foreach my $file (keys %files)



$outfile = '/var/www/html/azurebrd/ggi_updates/ggi_update';
$outfile2 = 'ggi_update.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
open (OU2, ">$outfile2") or die "Cannot create $outfile2 : $!";


foreach my $cde (@cde) {
# foreach my $key (sort keys %cde)
#   my $cde = $cde{$key};
# print "CDE $cde\n";
  my ($file, $cdline) = split/ : /, $cde;
# print "FILE $file\n";
  $file =~ s/cde/xml/;
# print "FILE $file\n";
  my ($line) = $cdline =~ m/^(s\d+)+/;
# print "LINE $line\n";
  open (IN, "<$file") or die "Cannot open $file : $!";
# print "FILE $file\n";
  while (<IN>) {
    if ($_ =~ m/sentence id=\'$line\'/) { 
      print OUT "$file : $_";
      print OU2 "$file : $_"; 
    }
  } # while (<IN>)
  close (IN) or die "Cannot close $file : $!";
# } # foreach my $key (sort keys %cde)
} # foreach my $cde (@cde)

close (OUT) or die "Cannot close $outfile2 : $!";
close (OU2) or die "Cannot close $outfile2 : $!";





sub padZeros {
  my $number = shift;
  if ($number < 10) { $number = '0000000' . $number; }
    elsif ($number < 100) { $number = '000000' . $number; }
    elsif ($number < 1000) { $number = '00000' . $number; }
    elsif ($number < 10000) { $number = '0000' . $number; }
    elsif ($number < 100000) { $number = '000' . $number; }
    elsif ($number < 1000000) { $number = '00' . $number; }
    elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub padZeros



__END__
# to prepopulate papers
# for my $i (1 .. 27069) {
#   my ($number) = &padZeros($i);
#   print "WBPaper$number\n";
# } # for my $i (1 .. 27070)
