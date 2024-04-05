#!/usr/bin/env perl

# phenotype_history.html.bk has 13GB of data, but less than a month ago it was only 20MB
# This splits file into lines smaller than 100000 characters into a filtered file, and
# lines larger into their own files for someone to look at.  Those files have a ton of 
# junk characters in the middle of some text.  2024 03 27

use strict;

# my $infile = '/usr/caltech_curation_files/pub/cgi-bin/data/phenotype_history.html';
my $infile = '/usr/caltech_curation_files/pub/cgi-bin/data/phenotype_history.html.bk';

# my $infile = '/usr/caltech_curation_files/parsings/chris/20240327_phenotype_history/lines/6989_33556621';

my $outfile = 'filtered_linebreak';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $count = 0;
open (IN, "<$infile") or die "Cannot open $infile :$!";

# there's line breaks in the file, but cannot read the whole thing to strip them because of 
# /usr/local/sbin/perl: line 3: 224511 Segmentation fault      (core dumped) /usr/local/bin/perl -COo "$@"
#
# $/ = undef;
# open (IN, "<$infile") or die "Cannot open $infile :$!";
# my $all_file = <IN>;
# close (IN) or die "Cannot close $infile :$!";
# 
# $all_file =~ s// /g;
# print OUT $all_file;
# close (OUT) or die "Cannot close $outfile : $!";

my $year = '2024';
while (my $line = <IN>) {
  chomp $line;
  $count++;

  my $len = length($line);
  if ($len > 100000) {
    print qq(HUGE\t$count\t$len\n); }

#     $line =~ s/ÃÂÃ//g;
#     $line =~ s/[^\x00-\x7f]//g;

  my (@cells) = split/<td/, $line;
  foreach my $cell (@cells) {
    my $len_cell = length($cell);
    if ($len_cell > 100000) {
      $cell =~ s/[^\x00-\x7f]//g; }
  }
  # there's line breaks in file, keep track of latest year and assume next line is the same year
  if ($cells[2] =~ m/>(\d{4})\-/) { $year = $1; }
#   unless ($year) {		# this doesn't work, there's linebreaks in file
#     print qq(skip $count : no year $line\n); 
#     next; }
#   print qq(YEAR $year\n);
  $line = join"<td", @cells;
  my $outfile = 'phenotype_history_' . $year . '.html';
  if (!(-e $outfile)) {
    open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
    print OUT qq(<table border="1"><tr><th>ip</th><th>timestamp</th><th>person</th><th>email</th><th>pgid</th><th>paper</th><th>allele</th><th>transgene</th><th>caused_by</th><th>rnai gene</th><th>rnai reagent</th><th>species</th><th>personal</th><th>phenotype</th><th>not</th><th>phenotype remark</th><th>suggested definition</th><th>nature</th><th>func</th><th>penetrance</th><th>heat_sens</th><th>cold_sens</th><th>genotype</th><th>strain</th><th>comment</th></tr>\n);
    close (OUT) or die "Cannot close $outfile : $!";
  }
  open (OUT, ">>$outfile") or die "Cannot append $outfile : $!";
  print OUT qq($line\n);
  close (OUT) or die "Cannot close $outfile : $!";
#   {
#     my $linefile = 'lines/' . $count . '_' . $len;
#     my $linefile = 'linetest_' . $count . '_' . $len;
#     open (LIN, ">$linefile") or die "Cannot create $linefile : $!";
#     print LIN qq($line\n);
#     close (LIN) or die "Cannot close $linefile : $!";
#   } else {
#     print OUT qq($line\n);
#   }
  if ($count % 1000 == 0) { 
    print qq($count\t$len\n);
  }
#   last if ($count > 200);
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile :$!";

# close (OUT) or die "Cannot close $outfile : $!";


__END__

my $outfile = 'filtered';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $count = 0;
open (IN, "<$infile") or die "Cannot open $infile :$!";
while (my $line = <IN>) {
  chomp $line;
  $count++;
  my $len = length($line);
  if ($len > 100000) {
    print qq(HUGE\t$count\t$len\n);
    my $linefile = 'lines/' . $count . '_' . $len;
    open (LIN, ">$linefile") or die "Cannot create $linefile : $!";
    print LIN qq($line\n);
    close (LIN) or die "Cannot close $linefile : $!";
  } else {
    print OUT qq($line\n);
  }
  if ($count % 1000 == 0) { 
    print qq($count\t$len\n);
  }
#   last if ($count > 200);
} # while (my $line = <IN>)
close (IN) or die "Cannot close $infile :$!";

close (OUT) or die "Cannot close $outfile : $!";

__END__

ÃÂÃÂ
