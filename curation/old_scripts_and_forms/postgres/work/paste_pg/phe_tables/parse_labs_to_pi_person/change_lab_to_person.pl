#!/usr/bin/perl

my $pi_file = 'labpi_personnumer.txt';
my $ref_file = 'phe_reference.pg';

my %labHash;

open (PIS, "<$pi_file") or die "Cannot open $pi_file : $!";
while (<PIS>) {
  my ($lab, $name, $number) = split/\t/, $_;
  $lab =~ s/^\s+//g; $lab =~ s/\s+$//g;
  $number =~ s/^\s+//g; $number =~ s/\s+$//g;
  $labHash{$lab} = $number;
} # while (<PIS>)
close (PIS) or die "Cannot close $pi_file : $!";

open (REF, "<$ref_file") or die "Cannot open $ref_file : $!";
while (<REF>) {
  my ($phen, $main, $lab, $date) = split/\t/, $_;
  if ($lab =~ m/laboratory: ([A-Z]+)/) {
    if ($labHash{$1}) {
      print "$phen\t$main\tWBPerson$labHash{$1}\t$date";
    } else { print STDERR "not a matching lab $1\n"; }
  } else { print STDERR "not lab $lab\n"; }
} # while (<REF>)
close (REF) or die "Cannot close $ref_file : $!";
