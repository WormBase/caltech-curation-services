#!/usr/bin/perl -w 

use strict;
use diagnostics;

my %wbg; my %wbgcounter;
my %acedb; my %acedbcounter;
my %mary; my %marycounter;
my %reg; my %regcounter;
my %all; my %allcounter;

my $wbg = "/home/azurebrd/work/newsletter/wbg.txt";
my $acedb = "/home/azurebrd/work/newsletter/acedbemails";
my $mary = "/home/azurebrd/work/newsletter/worm_email_listtext";
my $reg = "/home/azurebrd/work/newsletter/registrants-word.doc";

open (WBG, "<$wbg") or die "Cannot open $wbg : $!";
$/ = "";
while (<WBG>) {
  my @lines = split /\n/, $_;
  my $name = $lines[0];
  my $email;
  foreach $_ (@lines) {
    if ($_ =~ m/@/) { $email = $_; }
  } # foreach $_ (@lines) 
  $wbg{$email} = $name;
  $all{$email} = $name;
  $wbgcounter{$email}++;
  $allcounter{$email}++;
} # while (<WBG>) 
close (WBG) or die "Cannot close $wbg : $!";

open (ACE, "<$acedb") or die "Cannot open $acedb : $!";
while (<ACE>) {
  my @lines = split /\n/, $_;
  my ($nothing, $name) = split /\t/, $lines[0];
  my ($nothing, $email) = split /\t/, $lines[1];
  $acedb{$email} = $name;
  $all{$email} = $name;
  $acedbcounter{$email}++;
  $allcounter{$email}++;
} # while (<ACE>)
close (ACE) or die "Cannot close $acedb : $!";

open (MAR, "<$mary") or die "Cannot open $mary : $!";
while (<MAR>) {
  my $email; my $name;
  my @array = split //, $_;
  foreach my $line (@array) {
    my ($name, $email) = split /\t/, $line;
    $email =~ s/^\s+//g; 
    $email =~ s/\s+$//g; 
    $name =~ s/^\s+//g; 
    $name =~ s/\s+$//g; 
    $mary{$email} = $name;
    $all{$email} = $name;
    $marycounter{$email}++;
    $allcounter{$email}++;
  }
}
close (MAR) or die "Cannot close $mary : $!";

open (REG, "<$reg") or die "Cannot open $reg : $!";
while (<REG>) {
  my $email; 
  my $name;
  my @array = split /\t/, $_;
  foreach $_ (@array) { 
    if ($_ =~ m/@/) { 
      $email = $_; 
      $email =~ s/^\s+//g; 
      $email =~ s/\s+$//g; 
      $name = $array[0];
      $name =~ s/^[\s\d]+//g; 
      $name =~ s/\s+$//g; 
      $reg{$email} = $name;
      $all{$email} = $name;
      $regcounter{$email}++;
      $allcounter{$email}++;
    }
  }
}
close (REG) or die "Cannot close $reg : $!";

&Output();

sub Output {
  foreach $_ (sort keys %allcounter) {
    if ($allcounter{$_} > 1) {
      print "TOO MANY EMAILS : $allcounter{$_} : $_\n";
    }
  }
  
  foreach $_ (sort keys %wbgcounter) {
    if ($wbgcounter{$_} > 1) {
      print "TOO MANY WBG : $wbgcounter{$_} : $_\n";
    }
  }
  
  foreach $_ (sort keys %acedbcounter) {
    if ($acedbcounter{$_} > 1) {
      print "TOO MANY ACE : $acedbcounter{$_} : $_\n";
    }
  }

  foreach $_ (sort keys %marycounter) {
    if ($marycounter{$_} > 1) {
      print "TOO MANY MARY : $marycounter{$_} : $_\n";
    }
  }
  
  foreach $_ (sort keys %regcounter) {
    if ($regcounter{$_} > 1) {
      print "TOO MANY REG : $regcounter{$_} : $_\n";
    }
  }
  
  foreach $_ (sort keys %wbgcounter) {
    unless ($acedbcounter{$_}) {
      print "EXCLUSIVE WBG : $wbgcounter{$_} : $_\n";
    }
  }
  
  foreach $_ (sort keys %acedbcounter) {
    unless ($wbgcounter{$_}) {
      print "EXCLUSIVE ACE : $acedbcounter{$_} : $_\n";
    }
  }
 
  print "\n\nSTART WBG " . scalar(keys %wbg) . "\n\n";
  foreach $_ (sort keys %wbg) {
    print "$_\n";
  }
  
  print "\n\nSTART ACE " . scalar(keys %acedb) . "\n\n";
  foreach $_ (sort keys %acedb) {
    print "$_\n";
  }
  
  print "\n\nSTART MARY " . scalar(keys %mary) . "\n\n";
  foreach $_ (sort keys %mary) {
    print "$_\n";
  }
  
  print "\n\nSTART REG " . scalar(keys %reg) . "\n\n";
  foreach $_ (sort keys %reg) {
    print "$_\n";
  }
  
  &Filter();
} # sub Output

my %nofullemail;
my %endsindot;
my %edus;
my %coms;
my %nets;
my %jps;
my %uks;
my %frs;
my %goodstuff;
my %oddstuff;

sub Filter {
  print "\n\nSTART ALL " . scalar(keys %all) . "\n\n";
  foreach $_ (sort keys %all) {
    if ($_ !~ m/@.*\./) {
      $nofullemail{$_} = $all{$_};
    } elsif ($_ =~ m/\.$/) {
      $endsindot{$_} = $all{$_};
    } elsif ($_ =~ m/\.[cC][oO][mM]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[eE][dD][uU]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[nN][eE][tT]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[mM][iI][lL]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[gG][oO][vV]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[oO][rR][gG]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[fF][rR]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[uU][kK]$/) {
if ($_ =~ m/hannah/) { print "HUH $_\n"; }
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[jJ][pP]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[cC][hH]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[bB][eE]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[cC][aA]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[dD][eE]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[aA][uU]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[sS][eE]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[bB][rR]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[kK][rR]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[iI][tT]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[iI][lL]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[nN][zZ]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[cC][zZ]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[hH][kK]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[aA][tT]$/) {
      $goodstuff{$_} = $all{$_};
    } elsif ($_ =~ m/\.[nN][lL]$/) {
      $goodstuff{$_} = $all{$_};
    } else {
if ($_ =~ m/hannah/) { print "HUH $_\n"; }
      $oddstuff{$_} = $all{$_};
    }
  }

  print "\n\nNO FULL EMAIL" . scalar(keys %nofullemail) . "\n\n";
  foreach $_ (sort keys %nofullemail) {
    print "$_\n";
  }

  print "\n\nENDS IN DOT " . scalar(keys %endsindot) . "\n\n";
  foreach $_ (sort keys %endsindot) {
    print "$_\n";
  }

  print "\n\nODD STUFF " . scalar(keys %oddstuff) . "\n\n";
  foreach $_ (sort keys %oddstuff) {
    print "$_\n";
  }

  print "\n\nGOOD STUFF " . scalar(keys %goodstuff) . "\n\n";
  foreach $_ (sort keys %goodstuff) {
    print "$_\n";
  }
} # sub Filter 
