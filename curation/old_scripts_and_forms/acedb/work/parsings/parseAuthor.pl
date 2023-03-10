#!/usr/bin/perl

my $infile = 'citacePaper.ace.backup';
my $outfile = 'citacePaperTemp.ace';

open (IN, "<$infile") or die "Cannot open $infile : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<IN>) {
  chomp $_;
  if ($_ =~ m/^Author/) { 
    if ( $_ =~ m/Affiliation/) { 1; }
    else { print OUT "$_ \"0\"\n"; }
  } elsif ($_ =~ m/^Old_lab/) { 1; 
  } else { print OUT "$_\n"; }
}

close (IN) or die "Cannot close $infile : $!";
close (OUT) or die "Cannot close $outfile : $!";
