#!/usr/bin/perl

# symlink file to gene_association.wb :
# ln -s ../stuff/go_curation.go.dump.20050818.1 gene_association.wb
# 
# run script :
# ./wrapper.pl
# 
# creates :       
#         old/gene_ontology.20051004.163216.obo
#         old/GO.20051004.163216.xrf_abbs
#         and copies of them in current directory
# then runs :
#         ./filter-gene-association.pl -i gene_association.wb -e > old/out.20051004.163216.filter
#         creating the list of lines that are being suppressed
# then creates :
#         old/gene_association.20051004.163216.wb
#         by reading out.filter and gene_association.wb and filtering out the bad lines
# 2005 10 04



use Jex;
use LWP::Simple;

my $date = &getSimpleSecDate();

my $directory = '/home/postgres/work/get_stuff/for_ranjana/go_curation_dumper/post_process';
my $outfile = $directory . '/old/concise_dump.' . $date . '.ace';

chdir($directory) or die "Cannot go to $directory ($!)";


  # get files and write to old/ for history and to this directory for filter-gene-association.pl
my $obo = get "ftp://ftp.geneontology.org/pub/go/ontology/gene_ontology.obo";
my $outfile = $directory . '/old/gene_ontology.' . $date . '.obo';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $obo;
close (OUT) or die "Cannot close $outfile : $!";
$outfile = $directory . 'gene_ontology.obo';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $obo;
close (OUT) or die "Cannot close $outfile : $!";

my $abbs = get "ftp://ftp.geneontology.org/pub/go/doc/GO.xrf_abbs";
$outfile = $directory . '/old/GO.' . $date . '.xrf_abbs';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $abbs;
close (OUT) or die "Cannot close $outfile : $!";
$outfile = $directory . 'GO.xrf_abbs';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $abbs;
close (OUT) or die "Cannot close $outfile : $!";

  # run script that does most work
`/home/postgres/work/get_stuff/for_ranjana/go_curation_dumper/post_process/filter-gene-association.pl -i gene_association.wb -e > old/out.${date}.filter`;


  # read in lines to suppress
my %bad_lines;
my $bad_lines_file = 'old/out.' . $date . '.filter';
open (IN, "<$bad_lines_file") or die "Cannot open $bad_lines_file : $!";
while (my $line = <IN>) {
  if ($line =~ m/^(\d+):/) { $bad_lines{$1}++; }
} #while (my $lines = <IN>)
close (IN) or die "Cannot close $bad_lines_file : $!";

  # read file, and print out to old/ except for lines to suppress
my $count = 0;
my $infile = 'gene_association.wb';
my $outfile = $directory . '/old/gene_association.' . $date . '.wb';
open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
while (<IN>) {
  $count++;
  if ($bad_lines{$count}) { next; }
  else { print OUT; }
} # while (<IN>)
close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
