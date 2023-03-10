#!/usr/bin/perl

# wrapper script to create directory if necesasry, dump full dump from postgres
# into Juancarlos_full_date.ace, then diff with previously latest full dump
# with find_diff.pl into Cecilia_full_date.ace  2005 05 05

use strict;
use Jex;

my $date = &getSimpleDate();
print "DATE $date\n";

my $curdir = '/home/postgres/work/citace_upload/cecilia/';

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

`${curdir}get_wpa_person_ace.pl > old/${date}/Juancarlos_full_${date}.ace`;
`${curdir}find_diff.pl ${old_dir}/Juancarlos_full_${old_date}.ace old/${date}/Juancarlos_full_${date}.ace > old/${date}/Cecilia_full_${date}.ace`;
print "scp old/${date}/Cecilia_full_${date}.ace citace\@altair.caltech.edu:Data_for_CitaceMinus/Data_from_Cecilia/.\n";
