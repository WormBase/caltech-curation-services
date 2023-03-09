#!/usr/bin/perl

# search deep within all subdirectories of $root_dir for $search in .pl and .cgi
# files.  2008 10 06

use strict;

# my $search = 'unctional annot';
my $search = 'wpa';
# my $search = '/curation.cgi';

my $root_dir = '/home/';

# my $root_dir = '/home/azurebrd/work/parsings/';

my %results;
my @directory; my @file;

my @dirs = <${root_dir}*>;
foreach (@dirs) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
  next if ($_ =~ m/home\/azurebrd\/work\/parsings/);
  next if ($_ eq '/home/azurebrd/work/parsings/spider');
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
  print "grep \"$search\" ${_}/*.pl >> '/home/azurebrd/work/parsings/spider/out'\n";
  `grep "$search" ${_}/*.pl >> '/home/azurebrd/work/parsings/spider/out'`;
  print "grep \"$search\" ${_}/*.cgi >> '/home/azurebrd/work/parsings/spider/out'\n";
  `grep "$search" ${_}/*.cgi >> '/home/azurebrd/work/parsings/spider/out'`;
}
# foreach my $file (@file) {
#   my ($file_name) = $file =~ m/.*\/(.*?)$/;
#   if ($file_name !~ m/pdf$/) { next; }		# skip non-pdfs
# }
