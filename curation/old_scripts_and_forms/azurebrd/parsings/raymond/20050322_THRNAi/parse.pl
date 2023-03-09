#!/usr/bin/perl

# parse out stuff for raymond.  2005 03 22
#
# made some changes for post-embryonic, remarks, etc.  2005 03 23

use strict;
use diagnostics;

my $phe_file = 'phenobank_primers_phenotypes.txt';
my $th_file = 'TH_rnai_object_name.txt';

my %th;		# hash of rnais, key th thing

open (TH, "<$th_file") or die "Cannot open $th_file : $!"; 
while (<TH>) {
  if ( $_ =~ m/\"(\w+)\"\t\"TH:([\w\-]+)\"/ ) {
# if ($2 eq "128-c8") { print "got 128-c8 $1\n"; } 
    $th{$2} = $1;
# my $pie = "128-c8";
# if ($th{$pie}) { print "got 128-c8\n"; }

  } else { # if ( $_ =~ m/\"(\w)+\"\t\"TH:([\w\-]+)\"/ )
    print "ERR bad th line $_";
  }
} # while (<TH>)
close (TH) or die "Cannot close $th_file : $!";

open (IN, "<$phe_file") or die "Cannot open $phe_file : $!";
<IN>;	# skip first line
while (my $line = <IN>) {
  my $header;
  chomp ($line);
  my @stuff = ();
  @stuff = split/\t/, $line;
  foreach (@stuff) { $_ =~ s/\"//g; $_ =~ s/^\s+//; $_ =~ s/\s+$//; }
  if ($th{$stuff[3]}) { 
    $header = "RNAi : $th{$stuff[3]}\nHistory_name \"TH:$stuff[3]\"\nLaboratory TH\nDate 2005-03-25\nDelivered_by \"Injection\"\n";
  } else { print "NO MATCH -= $stuff[3] =- $line\n"; }
  if ( !($stuff[6]) && !($stuff[7]) && !($stuff[8]) && !($stuff[9]) ) { 
#     print "skipping line $line\n";
    next; }
  if ($stuff[6]) {
    if ($stuff[6] eq 'Wild type') { 
      if ( !($stuff[8]) ) { $header .= "Phenotype \"WT\"\n"; } }
    else { $header .= "Remark \"early embryonic phenotype: $stuff[6]\"\n"; } }
  if ($stuff[7]) {
    $header .= "Remark \"early embryonic phenotype: $stuff[7]\"\n"; }
  if ($stuff[8]) {
    if ($stuff[8] eq 'Wild type') { $header .= "Phenotype \"WT\"\n"; }
    elsif ($stuff[8] eq 'Embryonic Lethal') { $header .= "Phenotype \"Emb\"\n"; }
    else { $header .= "Remark \"post-embryonic phenotype: $stuff[8]\"\n"; }
    if ($stuff[8] eq 'Adult Phenotype-Protruding Vulva (pvl)') { $header .= "Phenotype \"Pvl\"\n"; }
    elsif ($stuff[8] eq 'Larval Lethal-Late (L3/L4)') { $header .= "Phenotype \"Lvl\"\n"; }
    elsif ($stuff[8] eq 'Larval Arrest-Early (L1/L2)') { $header .= "Phenotype \"Lva\"\n"; }
    elsif ($stuff[8] eq 'Developmental Delay') { $header .= "Phenotype \"Gro\"\n"; }
    elsif ($stuff[8] eq 'Larval Lethal-Early (L1/L2)') { $header .= "Phenotype \"Lvl\"\n"; }
    elsif ($stuff[8] eq 'Larval Arrest-Late (L3/L4)') { $header .= "Phenotype \"Lva\"\n"; }
    elsif ($stuff[8] eq 'Sterile F0/Fertility Problems') { $header .= "Phenotype \"Ste\"\n"; }
    elsif ($stuff[8] eq 'Sterile F1') { $header .= "Phenotype \"Stp\"\n"; }
    elsif ($stuff[8] eq 'Adult Phenotype-Dumpy (dpy)') { $header .= "Phenotype \"Dpy\"\n"; }
    elsif ($stuff[8] eq 'Adult Phenotype-Egg Laying Defect (egl)') { $header .= "Phenotype \"Egl\"\n"; }
    elsif ($stuff[8] eq 'Adult Phenotype-Roller (rol)') { $header .= "Phenotype \"Rol\"\n"; }
    elsif ($stuff[8] eq 'Adult Phenotype-Uncoordinated (unc)') { $header .= "Phenotype \"Unc\"\n"; }
    else { 1; }
  } # if ($stuff[8])
  if ($stuff[9]) {
    $header .= "Remark \"post-embryonic phenotype: $stuff[9]\"\n"; }
  print "$header\n";
} # while (my $line = <IN>)
close (IN) or die "Cannot close $phe_file : $!";
