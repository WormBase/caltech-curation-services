#!/usr/bin/perl

use strict;

my %data;
my @dataFiles = qw( Antibody Expr_pattern Gene_regulation Interaction RNAi Transgene );
foreach my $datatype (@dataFiles) {
  my $infile = $datatype . '_timestamps.txt';
  my %fileCurator;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    if ( $line =~ m/^(.*?) : "(.*?)" -O "(.*?)"$/ ) {
        my ($dt, $obj, $ts) = ($1, $2, $3);
        my ($date, $time, $who) = split/_/, $ts;
        my $timestamp = qq($date $time);
        $data{$dt}{$obj}{ts} = $timestamp;
        $data{$dt}{$obj}{who} = $who;
        $fileCurator{$who}++;
      }
      else { print qq($datatype LINE fail $line\n); }
    
  } # while (my $line = <IN>)
  foreach my $fileCurator (sort keys %fileCurator) { 
    print qq($datatype\t$fileCurator\t$fileCurator{$fileCurator}\n); }
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $datatype (@dataFiles)

__END__ 

Antibody : "Expr58:mef-2" -O "2004-01-05_22:07:45_wen"
Antibody : "[cgc512]:MSP" -O "2004-07-05_21:34:13_wen"
Antibody : "[cgc541]:F-RAM" -O "2004-02-13_19:20:27_wen"
Antibody : "[cgc573]:5-4" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-9" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-11" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-12" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-13" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:5-19" -O "2004-02-27_16:30:42_wen"
Antibody : "[cgc573]:10.2.1" -O "2004-02-27_16:30:42_wen"
