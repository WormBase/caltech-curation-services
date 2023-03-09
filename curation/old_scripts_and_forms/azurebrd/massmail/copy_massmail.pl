#!/usr/bin/perl -w

# copy perl scripts for github archiving

use strict;
use diagnostics;

use File::Path qw(make_path);

my $output_base_dir = '/home/azurebrd/git/caltech-curation-services/curation/old_scripts_and_forms/azurebrd/';
my $input_base_dir = '/home/azurebrd/work/';

my @directories; my @files;
my $dir_root = '/home/azurebrd/work/massmail/';

my @Reference = <${dir_root}*>;
foreach (@Reference) {
  if (-d $_) { push @directories, $_; }
  if (-f $_) { push @files, $_; }
} # foreach (@Reference)
foreach (@directories) {
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directories, $_; }
    if (-f $_) { push @files, $_; } } }


foreach my $dir (@directories) {
  my $new_dir = $dir;
  $new_dir =~ s/$input_base_dir/$output_base_dir/;
  make_path($new_dir);
  print qq(DIR $dir TO $new_dir DIR\n);
}

foreach my $file (@files) {
  if ($file =~ m/\.pl$/) { 
    my $outfile = $file;
    $outfile =~ s/$input_base_dir/$output_base_dir/;
    `cp -p $file $outfile`;
    print qq(FILE $file TO $outfile FILE\n);
  }
}
