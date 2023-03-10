#!/usr/bin/perl

# Same as wrapper.pl at /home/postgres/work/citace_upload/cecilia/wrapper.pl
# Create directory if necessary.  Get full dump, diff with previously oldest 
# full dump.  2005 05 05

use strict;
use Jex;

my $date = &getSimpleDate();
print "DATE $date\n";

my $curdir = '/home/postgres/work/citace_upload/locus/';

my (@old_dirs) = <${curdir}old/20*>;
my $old_dir = pop @old_dirs;
my ($old_date) = $old_dir =~ m/(20.*?)$/;
print "old dir $old_dir  old_date $old_date\n";

my (@stuff) = <$curdir*>;
my $dir_exists = 0;
foreach (@stuff) { 
  my $dir_to_create = $curdir . $date;
  if ($_ eq $dir_to_create) { $dir_exists++; }
}
unless ($dir_exists) { `mkdir old/$date`; }

`${curdir}code_two.pl > old/${date}/Locus_${date}.ace`;
`${curdir}find_diff.pl ${old_dir}/Locus_${old_date}.ace old/${date}/Locus_${date}.ace > old/${date}/Locus_update_${date}.ace`;
print "scp old/${date}/Locus_update_${date}.ace citace\@altair.caltech.edu:.\n";
