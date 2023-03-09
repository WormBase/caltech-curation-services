#!/usr/bin/perl

$data1 = 'boasdf';
$data2 = 'Iino_RNAi_data.txt';


open (DA1, "<$data1") or die "Cannot open $data1 : $!";
while (<DA1>) { chomp; $dat1{$_}++; }
close (DA1);

open (DA2, "<$data2") or die "Cannot open $data2 : $!";
while (<DA2>) { 
  chomp; 
  next if ($_ =~ m/^\D/);
  $_ =~ s/\"//g;
  my ($junk, $val, $junk2) = split/\t/, $_;
  $dat2{$val}++; 
}
close (DA2);

foreach (sort keys %dat2) {
  unless ($dat1{$_}) { print "$_\n"; }
} # foreach (sort keys %dat2)
