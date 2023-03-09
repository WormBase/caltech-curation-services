#!/usr/bin/perl

# look at access logs to see how much people are using the new user submission forms.  exclude caltech IPs.  exclude some self-referential actions.
# separate get from post.  2015 06 30

use strict;
use diagnostics;

my $path = '/var/log/httpd/';

my @cgis = qw( /~azurebrd/cgi-bin/forms/community_gene_description.cgi /~azurebrd/cgi-bin/forms/allele_phenotype.cgi /~azurebrd/cgi-bin/forms/allele_phenotype.cgi /~azurebrd/cgi-bin/forms/allele_sequence.cgi /~azurebrd/cgi-bin/forms/expr_micropub.cgi );

my %matches;
my %ips;

# my @infiles = qw( access.log access.log.1 );
my @infiles = qw( access.log.20150621_20150629 access.log.20150629_20150630 );
foreach my $file (@infiles) { 
#   my $infile = $path . $file;
  my $infile = $file;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    chomp $line;
    next if ($line =~ m/^[a-z\.]*\.caltech.edu/);
    next if ($line =~ m/^131.215./);
    next if ($line =~ m/autocompleteXHR/);
    next if ($line =~ m/asyncTermInfo/);
    next if ($line =~ m/asyncFieldCheck/);
    next if ($line =~ m/asyncWbdescription/);
    next if ($line =~ m/pmidToTitle/);
    my $match = 0;
    foreach my $cgi (@cgis) {
      if ($line =~ m/GET $cgi/) {  $matches{$cgi}{get}{$line}++;  $match++; }
      if ($line =~ m/POST $cgi/) { $matches{$cgi}{post}{$line}++; $match++; }
    } # foreach my $cgi (@cgis)
    if ($match) {
      my ($ip) = $line =~ m/^([^ ]+) /; $ips{$ip}++; 
    }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
}

foreach my $ip (sort { $ips{$b} <=> $ips{$a} } keys %ips) {
  print qq(IP $ip\t$ips{$ip}\n);
} # foreach my $ip (sort keys %ips)

foreach my $cgi (sort keys %matches) {
  foreach my $line (sort keys %{ $matches{$cgi}{get} }) {
    print qq($cgi\tget\t$line\n);
  } # foreach my $line (sort keys %{ $matches{$cgi}{get} })
  foreach my $line (sort keys %{ $matches{$cgi}{post} }) {
    print qq($cgi\tpost\t$line\n);
  } # foreach my $line (sort keys %{ $matches{$cgi}{post} })
} # foreach my $cgi (sort keys %matches)
