#!/usr/bin/perl

# take the isi file, get the first author and first 3 words of title.
# same for pub file.  for pub entries without matching isi entries, 
# print them.  2002 10 22

use strict;
use diagnostics;

my $pub_file = 'pubmed_elegans.txt';
my $isi_file = 'isi_elegans.txt';

my %isi;
my %pub;

&getIsi();
&getPub();
&filterIsiMinusPub();

sub getIsi {
  $/ = '';
  open (ISI, "<$isi_file") or die "Cannot open $isi_file : $!";
  while (<ISI>) { 
    my ($author) = $_ =~ m/\nAU (.*)\n/;
    my ($title) = $_ =~ m/\nTI (.*)\n/;
    if ($title =~ m/^(\S+\s\S+\s\S+)/) { ($title) = $title =~ m/^(\S+\s\S+\s\S+)/; } 
# print "ISITITLE $title TITLE\n";
    my $key = $author . 'JOIN' . $title;
    $key = lc($key);
    $key =~ s/,//g;
# if ($key =~ m/van ross/) { print "ISI $key\n"; }
    $isi{$key} = $_;
  } # while (<ISI>)
  close (ISI) or die "Cannot close $isi_file : $!";
} # sub getIsi

sub getPub {
  $/ = '';
  open (PUB, "<$pub_file") or die "Cannot open $pub_file : $!";
  while (<PUB>) { 
    my ($author) = $_ =~ m/\nAU  - (.*)\n/;
    my ($title) = $_ =~ m/\nTI  - (.*)\n/;
    if ($title =~ m/^(\S+\s\S+\s\S+)/) { ($title) = $title =~ m/^(\S+\s\S+\s\S+)/; } 
# print "PUBTITLE $title TITLE\n";
    my $key = $author . 'JOIN' . $title;
    $key = lc($key);
    $key =~ s/,//g;
# if ($key =~ m/van ross/) { print "PUB $key\n"; }
    $pub{$key} = $_;
  } # while (<PUB>)
  close (PUB) or die "Cannot close $pub_file : $!";
} # sub getPub

sub filterIsiMinusPub {
  my $total = 0;
  my $counted = 0;
  foreach my $key (sort keys %isi) { 
# if ($key =~ m/van ross/) { print "DOING $key\n"; print $pub{$key} . "\n"; }
    $total++;
    unless ($pub{$key}) { print "$isi{$key}"; $counted++; }
  } # foreach my $key (sort keys %isi)
  print "TOTAL ENTRIES : $total\n";
  print "ENTRIES NOT IN PUBMED FILE : $counted\n";
} # sub filterIsiMinusPub
