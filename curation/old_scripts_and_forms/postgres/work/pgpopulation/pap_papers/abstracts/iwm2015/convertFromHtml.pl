#!/usr/bin/perl

# iwm2015 has accent characters in html format.  This was an attempt to add line breaks to subsequently
# use html2text -width 9999 source.html > out.txt  but it doesn't work because there's paragraphs, and some
# characters don't get converted to well by html2text  2015 07 24
#
# DO NOT USE

use strict;

use Text::Unaccent;

# my $indirectory = 'Testing';
my $indirectory = 'AbsFilesOrig';
# my $outdirectory = 'AbsFiles';		# uncomment to overwrite files
my $outdirectory = 'AbsFilesHtml';

my (@files) = <${indirectory}/*>;


foreach my $infile (@files) {
#   print "IN $infile IN\n";
  my $outfile = $infile;
  $outfile =~ s/$indirectory/$outdirectory/;
  $outfile =~ s/txt$/html/;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    $line =~ s///;
    print OUT qq($line<br/>\n);
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
  close (OUT) or die "Cannot close $outfile : $!";
} # foreach my $infile (@files)

