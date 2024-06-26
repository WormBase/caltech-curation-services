#!/usr/bin/perl

# usage : ./find_diff.pl Citace_file Juancarlos_file > Diff_file
# take a dump of citace (or the previous file) and the current dump
# from pg (Juancarlos_file) and compare them to create a .ace file
# that will delete stuff that's no longer there and insert stuff
# that is new.  2003 04 30. 
# WARNING, this does not take into account the person_paper_author
# data in /home/postgres/work/get_stuff/person_ace/person_paper_author_for_now
# so this will have to be incorporated into this script the next time
# it's run (else all the papers will create extra -D's)  2003 04 30
#
# edited to use :
#  if ($_ =~ m/Paper\t\[(\w+)\]/) { $cit_hash{$1} = $_; }
#  if ($lines_to_print) { print "Paper\t[$num]\n$lines_to_print\n"; }
# instead of :
#  if ($_ =~ m/WBPerson(\d+)/) { $cit_hash{$1} = $_; }
#  if ($lines_to_print) { print "Person : \"WBPerson$num\"\n$lines_to_print\n"; }
# for reading cit_file and pg_file.  so far seems to work fine.
# 2003 08 21
#
# WBPapers don't have square brackets, so took them out.  2004 09 23

# Edited script to work with Gene - GO connections.  2005 01 26


my $cit_file = $ARGV[0];
my $pg_file = $ARGV[1];

my %cit_hash;
my %pg_hash;

$/ = "";
open (CIT, "<$cit_file") or die "Cannot open $cit_file : $!";
while (<CIT>) {
#   if ($_ =~ m/Paper\t\[(\w+)\]/) { $cit_hash{$1} = $_; }
  if ($_ =~ m/Gene : \"(\w+)\"/) { $cit_hash{$1} = $_; }
} # while (<CIT>)
close (CIT) or die "Cannot close $cit_file : $!";

open (PGF, "<$pg_file") or die "Cannot open $pg_file : $!";
while (<PGF>) {
#   if ($_ =~ m/Paper\t\[(\w+)\]/) { $pg_hash{$1} = $_; }
  if ($_ =~ m/Gene : \"(\w+)\"/) { $pg_hash{$1} = $_; }
} # while (<PGF>)
close (PGF) or die "Cannot close $pg_file : $!";

foreach my $pg_person (sort {$a <=> $b} keys %pg_hash) {
  unless ($cit_hash{$pg_person}) { print "$pg_hash{$pg_person}"; next; }	# if no cit entry for person
  if ($pg_hash{$pg_person} eq $cit_hash{$pg_person}) {	# they are the same
  } else { 						# they have changed
    &checkLines($pg_person);
  }
} # foreach my $pg_person (sort keys %pg_hash)

sub checkLines {
  my $num = shift; my %cit_lines; my %pg_lines;
  my $lines_to_print = '';
  my @cit_lines = split/\n/, $cit_hash{$num};
  my @pg_lines = split/\n/, $pg_hash{$num};
  foreach (@cit_lines) { $cit_lines{$_}++; }
  foreach (@pg_lines) { $pg_lines{$_}++; }
  foreach my $pg_line (sort keys %pg_lines) {
    if ($cit_lines{$pg_line}) { delete $pg_lines{$pg_line}; delete $cit_lines{$pg_line}; } }
  foreach my $cit_line (sort keys %cit_lines) {
    $lines_to_print .= "-D $cit_line\n"; }
  foreach my $pg_line (sort keys %pg_lines) {
    $lines_to_print .= "$pg_line\n"; }
#   if ($lines_to_print) { print "Person : \"WBPerson$num\"\n$lines_to_print\n"; }
#   if ($lines_to_print) { print "Paper\t[$num]\n$lines_to_print\n"; }
  if ($lines_to_print) { print "Gene : \"$num\"\n$lines_to_print\n"; }
} # sub checkLines
