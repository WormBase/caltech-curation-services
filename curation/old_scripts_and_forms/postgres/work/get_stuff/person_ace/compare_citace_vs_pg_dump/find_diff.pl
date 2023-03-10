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


my $cit_file = $ARGV[0];
my $pg_file = $ARGV[1];

my %cit_hash;
my %pg_hash;

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
    &checkLines($pg_person);
  }
} # foreach my $pg_person (sort keys %pg_hash)

sub checkLines {
  my $num = shift; my %cit_lines; my %pg_lines;
  my $lines_to_print = '';
#   print "WBPerson$num\n";
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
  if ($lines_to_print) { print "Person : \"WBPerson$num\"\n$lines_to_print\n"; }

#   my $highest = scalar(@cit_lines);
#   if (scalar(@pg_lines) > $highest) { $highest = scalar(@pg_lines); }
#   for (my $i = 0; $i < $highest; $i++) {
#     if ($cit_lines[$i] eq $pg_lines[$i]) {		# they are the same
# #       print "GOOD LINE $i\n";
#     } else {						# they have changed
#       print "$num : $i\nCIT : $cit_lines[$i]\nPG : $pg_lines[$i]\n";
#     }
#   } # for (my $i = 0; $i < $highest; $i++)
} # sub checkLines
