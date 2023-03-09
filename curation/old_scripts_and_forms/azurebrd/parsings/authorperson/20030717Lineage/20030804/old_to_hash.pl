#!/usr/bin/perl

# Parse data from the originally submitted .ace format, to Keith's
# hash-related .ace format.   2003 08 06

use strict;

my $old_file = 'old_file';
my $output = 'hash_ace';

my %hash_opt;
$hash_opt{phd} = 'Phd';
$hash_opt{postdoc} = 'Postdoc';
$hash_opt{masters} = 'Masters';
$hash_opt{undergrad} = 'Undergrad';
$hash_opt{highschool} = 'Highshool';
$hash_opt{sabbatical} = 'Sabbatical';
$hash_opt{lab_visitor} = 'Lab_visitor';
$hash_opt{collaborated} = 'Collaborated';
$hash_opt{research_staff} = 'Research_staff';
$hash_opt{unknown} = 'Unknown';

open (OUT, ">$output") or die "Cannot create $output : $!";
open (OLD, "<$old_file") or die "Cannot open $old_file : $!";
while (<OLD>) {
  chomp;
  if ($_ =~ m/^Person/) { print OUT "$_\n"; }
  elsif ($_ =~ m/^\s*$/) { print OUT "$_\n"; }
  elsif ($_ =~ m/^Trained(\w*?)_collaborated (WBPerson\d+)$/) {
#     print OUT "Worked_with\t$2\tWorked_with\tCollaborated\n"; }
    print OUT "Worked_with\t$2\tCollaborated\n"; }
  elsif ($_ =~ m/^Trainedwith_(\w+) (WBPerson\d+)$/) { 
    if ($hash_opt{$1}) { print OUT "Supervised_by\t$2\t$hash_opt{$1}\n"; }
    else { print "ERROR Supervised_by\t$2\t$hash_opt{$1}\n"; } }
#     if ($hash_opt{$1}) { print OUT "Supervised_by\t$2\tSupervised\t$hash_opt{$1}\n"; }
#     else { print "ERROR Supervised_by\t$2\tSupervised\t$hash_opt{$1}\n"; } }
  elsif ($_ =~ m/^Trained_(\w+) (WBPerson\d+)$/) { 
    if ($hash_opt{$1}) { print OUT "Supervised\t$2\t$hash_opt{$1}\n"; }
    else { print "ERROR Supervised\t$2\t$hash_opt{$1}\n"; } }
#     if ($hash_opt{$1}) { print OUT "Supervised\t$2\tSupervised_by\t$hash_opt{$1}\n"; }
#     else { print "ERROR Supervised\t$2\tSupervised_by\t$hash_opt{$1}\n"; } }
  else { print "ERROR $_\n"; }
} # while (<OLD>)
close (OLD) or die "Cannot close $old_file : $!";
close (OUT) or die "Cannot close $output : $!";
