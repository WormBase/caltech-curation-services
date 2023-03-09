#!/usr/bin/perl -w 

my $meaning = "/home/azurebrd/work/parsemountain/mount_meaning";
my $t1 = "/home/azurebrd/work/parsemountain/t1.ace";
my $outfile = "/home/azurebrd/work/parsemountain/outfile.ace";

my %meaning;
my %count;

open (MEA, "<$meaning") or die "Cannot open $meaning : $!";
open (TON, "<$t1") or die "Cannot open $t1 : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

while (<MEA>) {
  chomp;
  if ($_ =~ m/^\d/) {
    my @array = split/\t/, $_;
# print "huh$array[0]\t$array[2]\n";
    if ($array[2]) {
      $meaning{$array[0]} = $array[2];
    }
  }
}

foreach $_ (sort keys %meaning) {
#   print "--" . $meaning{$_} . "--\n";
}

$/ = "";
while (<TON>) {
  if ($_ =~ m/Mountain\s+(\d+)/) {
    if ($meaning{$1}) {
      my $mount = $1;
      my @array = split/\n/, $_;
      print OUT "$array[0]\nRemark: \"Mountain " . $mount . " contains -- ". $meaning{$mount} . "\"\n\n";
#       print "$array[0]\nRemark: \"". $meaning{$mount} . "\"\n\n";
      $count{$mount}++;
    }
  }
}
  
foreach $_ (sort keys %count) {
  print OUT "Mountain $_, $count{$_} cases\n";
}
