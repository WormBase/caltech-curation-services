#!/usr/bin/perl

my $endnotefile = "/home/postgres/work/pgpopulation/CGC2001_10_11.txt";
my %last;
my %penul;

open (IN, "<$endnotefile") or die "Cannot open $endnotefile : $!";
while (<IN>) {
  if ($_ =~ m/\d+/) {
    my @array = split/\t/, $_;
    $last{$array[scalar(@array-1)]}++;
    $penul{$array[scalar(@array-2)]}++;
  }
}

foreach $_ (sort keys %last) {
  print "last : $_\n";
}

foreach $_ (sort keys %penul) {
  print "penul : $_\n";
}
