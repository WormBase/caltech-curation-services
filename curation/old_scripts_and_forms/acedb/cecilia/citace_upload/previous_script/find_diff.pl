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
# Also works for Lineage stuff.  2003 10 27
#
# Edited to have two passes.  One to write deletions, and then one
# to write insertions.  Otherwise it would sometimes delete something
# with hash data and re-enter it without hash data.  2004 01 14
#
# Changed to keep data within a tag in order (like Address, so that
# the emails or Street lines will be in the same order as they are
# in postgres), then check tag data for equality instead of individual
# lines.  This will fix bad data pointed out by Cecilia.  2005 03 15
#
# Added an unordered_tag hash, so as not to delete and recreate chunks
# of same-tag data when only one or two lines would do.  2005 07 16
#
# If a WBPerson has been completely removed from postgres, delete them  
# 2007 07 25
#
# usage : 
# ./find_diff.pl citace_person_20050303.ace Juancarlos_full_20050315.ace > re_ordering_address_etc_20050315.ace2


my $cit_file = $ARGV[0];
my $pg_file = $ARGV[1];

my %cit_hash;
my %pg_hash;

my %unordered_tag = ();
$unordered_tag{'Paper'}++;
$unordered_tag{'Possibly_publishes_as'}++;
$unordered_tag{'Supervised_by'}++;
$unordered_tag{'Supervised'}++;
$unordered_tag{'Worked_with'}++;

$/ = "";
open (CIT, "<$cit_file") or die "Cannot open $cit_file : $!";
while (<CIT>) {
  if ($_ =~ m/WBPerson(\d+)/) { $cit_hash{$1} = $_; }
} # while (<CIT>)
close (CIT) or die "Cannot close $cit_file : $!";

open (PGF, "<$pg_file") or die "Cannot open $pg_file : $!";
while (<PGF>) {
  if ($_ =~ m/WBPerson(\d+)/) { $pg_hash{$1} = $_; }
} # while (<PGF>)
close (PGF) or die "Cannot close $pg_file : $!";

foreach my $pg_person (sort {$a <=> $b} keys %pg_hash) {
  unless ($cit_hash{$pg_person}) { print "$pg_hash{$pg_person}"; next; }	# if no cit entry for person
  if ($pg_hash{$pg_person} eq $cit_hash{$pg_person}) {	# they are the same
#     print "GOOD $pg_person\n";
  } else { 						# they have changed
#     print "$pg_person\n$cit_hash{$pg_person}\n$pg_hash{$pg_person}\n";
    &checkLinesDelete($pg_person);
  }
} # foreach my $pg_person (sort keys %pg_hash)

foreach my $pg_person (sort {$a <=> $b} keys %pg_hash) {
  unless ($cit_hash{$pg_person}) { print "$pg_hash{$pg_person}"; next; }	# if no cit entry for person
  if ($pg_hash{$pg_person} eq $cit_hash{$pg_person}) {	# they are the same
  } else { 						# they have changed
    &checkLinesInsert($pg_person);
  }
} # foreach my $pg_person (sort keys %pg_hash)

foreach my $cit_person (sort {$a <=> $b} keys %cit_hash) {	# if a WBPerson has been completely removed from postgres, delete them  2007 07 25
  unless ($pg_hash{$cit_person}) { print "-D Person : WBPerson$cit_person\n\n"; } }

sub checkLinesInsert {
  my $num = shift; my %cit_lines; my %pg_lines; my %cit_ordered; my %pg_ordered;
  my %cit_unordered; my %pg_unordered;
  my $lines_to_print = '';
  my @cit_lines = split/\n/, $cit_hash{$num};
  my @pg_lines = split/\n/, $pg_hash{$num};

  foreach (@cit_lines) { 
    $cit_lines{$_}++; 			# add to hash of cit lines
    my ($tag) = $_ =~ m/^(\w+)\s/;	# grab the tag (address, etc. because lines must be ordered within a tag
    if ($unordered_tag{$tag}) { $cit_unordered{$tag} .= $_ . "\n"; }	# add to hash of ordered pg lines within a tag
    else { $cit_ordered{$tag} .= $_ . "\n"; }			# add to hash of ordered cit lines within a tag
  }

  foreach (@pg_lines) { 
    $pg_lines{$_}++; 			# add to hash of pg lines
    my ($tag) = $_ =~ m/^(\w+)\s/;      # grab the tag (address, etc. because lines must be ordered within a tag
    if ($unordered_tag{$tag}) { $pg_unordered{$tag} .= $_ . "\n"; }	# add to hash of ordered pg lines within a tag
    else { $pg_ordered{$tag} .= $_ . "\n"; }		# add to hash of ordered pg lines within a tag
  }

  foreach my $tag (sort keys %pg_ordered) {	# deal with ordered stuff
    if ($cit_ordered{$tag} eq $pg_ordered{$tag}) { delete $pg_ordered{$tag}; delete $cit_ordered{$tag}; } }
  foreach my $tag (sort keys %pg_ordered) {
    $pg_ordered{$tag} =~ s/\n$//g;
    $lines_to_print .= "$pg_ordered{$tag}\n"; }

  foreach my $tag (sort keys %pg_unordered) {	# deal with unordered stuff
    my %cit_temp; my %pg_temp;
    my (@temp) = split/\n/, $cit_unordered{$tag};
    foreach my $line (@temp) { $cit_temp{$line}++; }
    (@temp) = split/\n/, $pg_unordered{$tag};
    foreach my $line (@temp) { $pg_temp{$line}++; }
    foreach my $pg_line (sort keys %pg_temp) {
      unless ($cit_temp{$pg_line}) { $lines_to_print .= "$pg_line\n"; } } }

  if ($lines_to_print) { print "Person : WBPerson$num\n$lines_to_print\n"; }
} # sub checkLinesInsert

sub checkLinesDelete {
  my $num = shift; 
  my %cit_ordered; my %pg_ordered;	# ordered cit or pg entries, grouped by tag
  my %cit_unordered; my %pg_unordered;
  my $lines_to_print = '';

  my @cit_lines = split/\n/, $cit_hash{$num};	# get each of the lines
  my @pg_lines = split/\n/, $pg_hash{$num};	# get each of the lines

  foreach (@cit_lines) { 
    my ($tag) = $_ =~ m/^(\w+)\s/;	# grab the tag (address, etc. because lines must be ordered within a tag
    if ($unordered_tag{$tag}) { $cit_unordered{$tag} .= $_ . "\n"; }	# add to hash of ordered cit lines within a tag
    else { $cit_ordered{$tag} .= $_ . "\n"; }			# add to hash of ordered cit lines within a tag
  }

  foreach (@pg_lines) { 
    my ($tag) = $_ =~ m/^(\w+)\s/;      # grab the tag (address, etc. because lines must be ordered within a tag
    if ($unordered_tag{$tag}) { $pg_unordered{$tag} .= $_ . "\n"; }	# add to hash of ordered pg lines within a tag
    else { $pg_ordered{$tag} .= $_ . "\n"; }			# add to hash of ordered pg lines within a tag
  }

  foreach my $tag (sort keys %pg_ordered) {	# going through each tag
    if ($cit_ordered{$tag} eq $pg_ordered{$tag}) { delete $pg_ordered{$tag}; delete $cit_ordered{$tag}; } 
  }					# if they match, delete from hash, so as not to print it (not delete it from citace)
  foreach my $tag (sort keys %cit_ordered) {	# for the remaining tags (the different tags which need to be deleted)
    $cit_ordered{$tag} =~ s/\n$//g;		# take out the extra newline at the end
    $cit_ordered{$tag} =~ s/\n/\n-D /g;		# replace with -D at the beginning
    $lines_to_print .= "-D $cit_ordered{$tag}\n"; }	# add -D to first line

  foreach my $tag (sort keys %cit_unordered) {	# deal with unordered stuff
    my %cit_temp; my %pg_temp;
    my (@temp) = split/\n/, $cit_unordered{$tag};
    foreach my $line (@temp) { $cit_temp{$line}++; }
    (@temp) = split/\n/, $pg_unordered{$tag};
    foreach my $line (@temp) { $pg_temp{$line}++; }
    foreach my $cit_line (sort keys %cit_temp) {
      unless ($pg_temp{$cit_line}) { $lines_to_print .= "-D $cit_line\n"; } } }

  if ($lines_to_print) { print "Person : WBPerson$num\n$lines_to_print\n"; }
					# print the stuff to delete with Person header
} # sub checkLinesDelete
