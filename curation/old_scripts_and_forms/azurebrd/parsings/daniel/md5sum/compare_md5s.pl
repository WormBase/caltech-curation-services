#!/usr/bin/perl

# take md5sum results that daniel made of cd data and athena data
# and compare them to see which corresponds to which and which ones
# don't.  2004 01 07

use strict;

my %cd;
my %ath;

my $cd = 'cd_md5sum';
my $athena = 'athena_tif_md5sum';

open (CD, "<$cd") or die "Cannot open $cd : $!";
open (ATH, "<$athena") or die "Cannot open $athena : $!";

while (<CD>) {
  chomp;
  my ($md5, $location) = split /\s+/, $_;
  $cd{$md5} = $location;
}

while (<ATH>) {
  chomp;
  my ($md5, $location) = split /\s+/, $_;
  $ath{$md5} = $location;
}

close (CD) or die "Cannot close $cd : $!";
close (ATH) or die "Cannot close $athena : $!";

my $outfile = 'outfile';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $ath_md5 (sort keys %ath) {
  if ($cd{$ath_md5}) { 
    print OUT "CD : $cd{$ath_md5}\tATH : $ath{$ath_md5}\n";
    delete $ath{$ath_md5};
    delete $cd{$ath_md5};
  }
} # foreach my $ath_md5 (sort keys %ath)

foreach my $ath_md5 (sort keys %ath) {
  print OUT "CD NO MATCH $ath_md5 $ath{$ath_md5}\n";
} # foreach my $ath_md5 (sort keys %ath)

foreach my $cd_md5 (sort keys %cd) {
  print OUT "ATHENA NO MATCH $cd_md5 $cd{$cd_md5}\n";
} # foreach my $cd_md5 (sort keys %cd)

close (OUT) or die "Cannot close $outfile : $!";
