#!/usr/bin/perl

# find stuff that mentions loci_all or genes2molecular_names in three homedirs
# (not cecilia), since they're no longer being maintained by sanger.  2006 12 14

use strict;
use Jex;

my $outfile = 'find_lociall.out';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
my $start = &getSimpleSecDate();
print OUT "$start\n";


my @directory; my @file;

# my @Reference = qw( /home/postgres/public_html/cgi-bin /home/azurebrd/public_html/cgi-bin/forms );
# my @Reference = qw( /home/postgres /home/acedb /home/azurebrd );
my @Reference = qw( /home/acedb );
foreach (@Reference) {
  if (-d $_) { push @directory, $_; }
  if (-f $_) { push @file, $_; }
} # foreach (@Reference)
foreach (@directory) {
#   if ($_ =~ m/\/home\/azurebrd\/arch/) { print "SKIP $_\n"; }
#   if ($_ =~ m/\/home\/azurebrd\/Desktop/) { print "SKIP $_\n"; }
  next if ($_ =~ m/\/home\/azurebrd\/arch/);
  next if ($_ =~ m/\/home\/azurebrd\/Desktop/);
  my @array = <$_/*>;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
}

my %matches;
foreach my $file (@file) {
  next if ($file =~ m/\/home\/azurebrd\/mbox/);
  my ($output) = `grep "loci_all" $file`;
  if ($output) { $matches{$file}++; }
  next if $output;
  ($output) = `grep "genes2molecular_names" $file`;
  if ($output) { $matches{$file}++; }
}


foreach my $file (sort {$matches{$a}<=>$matches{$b}} keys %matches) {
  print "$matches{$file}\t$file\n"; 
  print OUT "$matches{$file}\t$file\n"; 
}

my $end = &getSimpleSecDate();
print OUT "$end\n";
close (OUT) or die "Cannot close $outfile : $!";
