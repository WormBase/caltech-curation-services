#!/usr/bin/perl

# take the latest phenote_go_dump with pgids to map lines to pgids.  
# take p2go rejected syntax_check files to find rejected lines and map to pgids.
# take gene_association.wb files to find sent lines and map to pgids.
# subtract rejected from sent to find accepted pgids.  2013 02 05

use strict;
use warnings;

my %map;
my $mapfile = 'phenote_go_withcurator.go.20130205';
open (IN, "<$mapfile") or die "Cannot open $mapfile : $!";
while (my $line = <IN>) {
  next unless ($line =~ m/^WB/);
  chomp $line;
  my @cols = split/\t/, $line;
  my $pgid = pop @cols;
  my $curator = pop @cols;
  my $newline = join"\t", @cols;
  $map{$newline}{$pgid}++;
} # while (my $line = <IN>)
close (IN) or die "Cannot close $mapfile : $!";

# find lines that map to multiple pgids
# foreach my $line (sort keys %map) {
#   if (scalar(keys %{ $map{$line} }) > 1) { 
#     my @pgids = keys %{ $map{$line} }; my $pgids = join", ", @pgids;
#     print "$pgids\t$line has " . scalar(keys %{ $map{$line} }) . " mapping\n"; }
# } # foreach my $line (sort keys %map)

my %rejected;
my @bounceFiles = qw( syntax_check.log.CarolBastiani syntax_check.log.JoshJaffery syntax_check.log.KimberlyVanAuken syntax_check.log.RanjanaKishore );
foreach my $infile (@bounceFiles) {
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    next unless ($line =~ m/^\d+> /);
    chomp $line;
    $line =~ s/^\d+> //;
    if ($map{$line}) { foreach my $pgid (sort keys %{ $map{$line} }) { $rejected{$pgid}++; } }
      else { print "REJECTED $line has no mapping\n"; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@bounceFiles)

my %sent;
my @sentFiles = qw( gene_association.wb.CarolBastiani gene_association.wb.JoshJaffery gene_association.wb.KimberlyVanAuken gene_association.wb.RanjanaKishore );
foreach my $infile (@sentFiles) {
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $line = <IN>) {
    next unless ($line =~ m/^WB/);
    chomp $line;
    if ($map{$line}) { foreach my $pgid (sort keys %{ $map{$line} }) { $sent{$pgid}++; } }
      else { print "SENT $line has no mapping\n"; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $infile : $!";
} # foreach my $infile (@sentFiles)

my %accepted;
foreach my $sent (sort keys %sent) {
  unless ($rejected{$sent}) { $accepted{$sent}++; } }

my $rejected = join", ", keys %rejected;
print "REJECTED " . scalar(keys %rejected) . " pgids : $rejected\n";

my $sent = join", ", keys %sent;
print "SENT " . scalar(keys %sent) . " pgids : $sent\n";

my $accepted = join", ", keys %accepted;
print "ACCEPTED " . scalar(keys %accepted) . " pgids : $accepted\n";


