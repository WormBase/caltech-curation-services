#!/usr/bin/perl 

# This script takes 4 files, a dump of Sequence data (from which to get GO
# terms), and 3 list of names (GO term data with function, component, or
# process).  It puts the 3 list of names into a hash, then reads through the
# Sequence data, grabs each GO term, and adds to the count depending on which 
# type it is (which hash it's in).  2003 03 11

use strict;
use diagnostics;

my $seq_file = 'WS97Seq_with_GOterms.ace';
my $fxn_file = 'WS97go_terms_function.ace';
my $cmp_file = 'WS97go_terms_component.ace';
my $prc_file = 'WS97go_terms_process.ace';

my $function = 0;
my $component = 0;
my $process = 0;

my @term_files = qw(WS97go_terms_function.ace WS97go_terms_component.ace WS97go_terms_process.ace);
my %type_hash;

foreach my $term_type_file (@term_files) {
  open (IN, "<$term_type_file") or die "Cannot open $term_type_file : $!";
  my ($type) = $term_type_file =~ m/terms_(.*)\.ace/;
  while (<IN>) {
    if ($_ =~ m/GO_term : \"(.*)\"/) { $type_hash{$type}{$1}++; }
  } # while (<IN>)
  close (IN) or die "Cannot close $term_type_file : $!";
} # foreach my $term_type_file (@term_files)

open (IN, "<$seq_file") or die "Cannot open $seq_file : $!";
while (<IN>) {
  if ($_ =~ m/^GO_term\s+\"(.*)\"/) {
    if ($type_hash{function}{$1}) { $function++; }
    if ($type_hash{component}{$1}) { $component++; }
    if ($type_hash{process}{$1}) { $process++; }
  } # if ($_ =~ m/^GO_term\s+\"(.*)\"/)
} # while (<IN>)
close (IN) or die "Cannot close $seq_file : $!";

print "FUNCTION $function\n";
print "COMPONENT $component\n";
print "PROCESS $process\n";
