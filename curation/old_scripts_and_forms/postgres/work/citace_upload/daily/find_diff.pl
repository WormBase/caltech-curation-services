#!/usr/bin/perl

# usage : 
# ./find_diff.pl citace_person_20050303.ace Juancarlos_full_20050315.ace > re_ordering_address_etc_20050315.ace2
#
# usage 2005 07 17 :
# ./find_diff.pl citace_papers_20050629.ace papers.ace citace_abstracts_20050629.ace abstracts.ace > papers.diff8
# compare old and new list of papers.  compare old and new list of abstracts.

# Inferred words are only checked after an abstract is generated.  Since these
# entries are inferred, we cannot tell whether an entry that was previously
# inferred is in the list of items due to being inferred or being manually
# entered, so we do not delete previous connections, and only create inferred
# connections when an abstract's LongText is being entered.  2005 07 17
#
# -D citace papers not in postgres  2005 07 28
#
# Added deleted (merged) objects with Remark of their merge status.  2005 09 27
#
# Print new papers only once instead of while deleting and while inserting tags.
# no longer do this, since all papers are dumped, not just the valid ones, so
# dump remark from use_package.pl   2005 11 10
#
# Added Type for Andrei  2006 07 25
#
# No more Cell_group for Wen  2007 11 04
#
# Using this for testing daily uploads.  Had to manually create papers.ace and separate
# abstracts.ace   2011 03 03

use Jex;
use strict;
use diagnostics;
# use LWP::Simple;		# get from Pg Remark instead of website
# use Pg;
# 
# my $conn = Pg::connectdb("dbname=testdb");
# die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $starttime = time;
my ($date) = &getSimpleSecDate();
print STDERR "START $date\n";

my $err_file = 'find_diff.err';
open (ERR, ">$err_file") or die "Cannot create $err_file : $!"; 

my $cit_file = $ARGV[0];
my $pg_file = $ARGV[1];

my $cit_abs = $ARGV[2];
my $pg_abs = $ARGV[3];


my %cit_hash;
my %pg_hash;

my %ignore_tag;		# not dealing with these tags
my %unordered_tag;	# these don't have an order

$unordered_tag{'Keyword'}++;
$unordered_tag{'Gene'}++;
$unordered_tag{'CDS'}++;
$unordered_tag{'Affiliation'}++;
$unordered_tag{'WBG_abstract'}++;
$unordered_tag{'CGC_name'}++;
$unordered_tag{'Volume'}++;
$unordered_tag{'Editor'}++;

$unordered_tag{'Type'}++;		# Added for Andrei  2006 07 25
# $ignore_tag{'Type'}++;

# $ignore_tag{'Gene'}++;		# DELETE THIS, sanger's down
# $ignore_tag{'CDS'}++;			# DELETE THIS, sanger's down
# $ignore_tag{'Abstract'}++;		# COMMENT THIS OUT
# $ignore_tag{'Brief_citation'}++;	# COMMENT THIS OUT
$ignore_tag{'Person'}++;
$ignore_tag{'Strain'}++;
$ignore_tag{'Life_stage'}++;
$ignore_tag{'Interaction'}++;
$ignore_tag{'Rearrangement'}++;
$ignore_tag{'Antibody'}++;
$ignore_tag{'Sequence'}++;
# $ignore_tag{'Cell_group'}++;		# take out for Wen 2007 11 04
$ignore_tag{'Cell'}++;
$ignore_tag{'Allele'}++;
$ignore_tag{'Expr_pattern'}++;
$ignore_tag{'Expr_profile'}++;
$ignore_tag{'Clone'}++;
$ignore_tag{'Locus'}++;
$ignore_tag{'RNAi'}++;
$ignore_tag{'Transgene'}++;
$ignore_tag{'Gene_regulation'}++;
$ignore_tag{'Pseudogene'}++;
$ignore_tag{'Cluster'}++;
$ignore_tag{'Microarray_experiment'}++;
$ignore_tag{'SAGE_experiment'}++;

$/ = "";

my $count = 0;
open (CIT, "<$cit_file") or die "Cannot open $cit_file : $!";
while (my $cit_entry = <CIT>) {
  $count++;
#   if ($count > 1010) { last; }
#   if ($cit_entry =~ m/In_book/) { next; }
  if ($cit_entry =~ m/WBPaper(\d+)/) { 
    my $num = $1;
    if ($cit_entry =~ m/\\n\\\n/) { $cit_entry =~ s/\\n\\\n/NEWLINEREPLACEMENT/g; }
    $cit_hash{$num} = $cit_entry; }
} # while (<CIT>)
close (CIT) or die "Cannot close $cit_file : $!";

$count = 0;
open (PGF, "<$pg_file") or die "Cannot open $pg_file : $!";
while (my $pg_entry = <PGF>) {
  $count++;
#   if ($count > 1009) { last; }
#   if ($pg_entry =~ m/In_book/) { next; }
  if ($pg_entry =~ m/WBPaper(\d+)/) { $pg_hash{$1} = $pg_entry; }
} # while (<PGF>)
close (PGF) or die "Cannot close $pg_file : $!";

foreach my $cit_paper (sort {$a <=> $b} keys %cit_hash) {
  unless ($pg_hash{$cit_paper}) {		# -D citace papers not in postgres  2005 07 28
    print "-D Paper : \"WBPaper$cit_paper\"\n\n"; }
} # foreach my $cit_paper (sort {$a <=> $b} keys %cit_hash)

foreach my $pg_paper (sort {$a <=> $b} keys %pg_hash) {
#   unless ($cit_hash{$pg_paper}) { print "$pg_hash{$pg_paper}"; next; }	# do this below during insertions  2005 11 10
  if ($pg_hash{$pg_paper} eq $cit_hash{$pg_paper}) { 1; }					# they are the same
    else { &checkLinesDelete($pg_paper, $cit_hash{$pg_paper}, $pg_hash{$pg_paper}); }		# they have changed
} # foreach my $pg_paper (sort keys %pg_hash)

foreach my $pg_paper (sort {$a <=> $b} keys %pg_hash) {
  unless ($cit_hash{$pg_paper}) { print "$pg_hash{$pg_paper}"; next; }	# if no cit entry for person
  if ($pg_hash{$pg_paper} eq $cit_hash{$pg_paper}) { 1; }					# they are the same
    else { &checkLinesInsert($pg_paper, $cit_hash{$pg_paper}, $pg_hash{$pg_paper}); }		# they have changed
} # foreach my $pg_paper (sort keys %pg_hash)


# abstracts tag is now Longtext instead of LongText  2011 03 03

undef $/;
open (PG, "<$pg_abs") or die "Cannot open $pg_abs : $!";
my $pg_abs_all = <PG>;
close (PG) or die "Cannot close $pg_abs : $!";
my (@pg_abs) = $pg_abs_all =~ m/Longtext : \"WBPaper(.*?)\*\*\*LongTextEnd/sg;
my %pg_abs = ();
foreach my $pg_abs (@pg_abs) {
  if ($pg_abs =~ m/\n/) { $pg_abs =~ s/\n/ /g; }
  if ($pg_abs =~ m/\s+$/) { $pg_abs =~ s/\s+$//; }
  if ($pg_abs =~ m/\s+/) { $pg_abs =~ s/\s+/ /g; }
  if ($pg_abs =~ m/^(.+?)\"\s*(.*)$/) {
    my $key = $1; my $text = $2;
    $pg_abs{$key} = $text; }
  else { print STDERR "No KEY PG TEXT match $pg_abs NO MATCH\n"; }
} # foreach my $pg_abs (@pg_abs)

open (CIT, "<$cit_abs") or die "Cannot open $cit_abs : $!";
my $cit_abs_all = <CIT>;
close (CIT) or die "Cannot close $cit_abs : $!";
my (@cit_abs) = $cit_abs_all =~ m/Longtext : \"WBPaper(.*?)\*\*\*LongTextEnd/sg;
my %cit_abs = ();
foreach my $cit_abs (@cit_abs) {
  if ($cit_abs =~ m/\n/) { $cit_abs =~ s/\n/ /g; }
  if ($cit_abs =~ m/\s+$/) { $cit_abs =~ s/\s+$//; }
  if ($cit_abs =~ m/\s+/) { $cit_abs =~ s/\s+/ /g; }
  if ($cit_abs =~ m/^(.+?)\"\s*(.*)$/) {
    my $key = $1; my $text = $2;
    $cit_abs{$key} = $text; }
  else { print STDERR "No KEY CIT TEXT match $cit_abs NO MATCH\n"; }
#   my ($key, $text) = $cit_abs =~ m/^(\d+)\"\s*(.*)$/;
#   $cit_abs{$key} = $text;
} # foreach my $cit_abs (@cit_abs)
$/ = "";

foreach my $cit_abs (sort keys %cit_abs) {
  if ($pg_abs{$cit_abs}) {
    if ( $cit_abs{$cit_abs} eq $pg_abs{$cit_abs}) { delete $cit_abs{$cit_abs}; delete $pg_abs{$cit_abs}; } }
} # foreach my $cit_abs (sort keys %cit_abs)

foreach my $cit_abs (sort keys %cit_abs) {						# delete old LongText
#   print "-D LongText : \"WBPaper$cit_abs\"\n$cit_abs{$cit_abs}\n***LongTextEnd***\n\n";
  print "-D LongText : \"WBPaper$cit_abs\"\n\n"; }


my $rundate = &getSimpleMinDate();


$/ = "\n";
my %infer_auto;											# words to infer automatically
# my @list = qw( Allele Cell Cell_group Life_stage Strain Transgene ); my @exclusion;	# no more cell group for Wen 2007 10 19
my @list = qw( Allele Cell Life_stage Strain Transgene ); my @exclusion;
foreach my $list (@list) { push @exclusion, </home/acedb/papers/ACEDUMPS/${list}.dump.out>; }	# get list of words to get automatically

foreach my $file_name (@exclusion) {
  my ($file_type) = ($file_name =~ m/.*\/(\w*).*$/);					# get type of word
  open (EXC, "<$file_name") or die "Cannot open $file_name : $!";
  while (my $line = <EXC>) {
    chomp ($line);
# if ($line =~ m/ad1201/) { print STDERR "GOT ad1201 $line GOT\n"; }
    $infer_auto{$line} = $file_type; }							# assign each word to its type
  close (EXC) or die "Cannot close $file_name : $!";
} # foreach (@exclusion)

foreach my $pg_abs (sort keys %pg_abs) {
  print "LongText : \"WBPaper$pg_abs\"\n$pg_abs{$pg_abs}\n***LongTextEnd***\n\n";	# print LongText
  my (@words) = split/\s+/, $pg_abs{$pg_abs};						# get words
  my %infer_list = (); my $flag = 0;
  foreach my $word (@words) { 
# if ($pg_abs =~ m/00000003/) { print STDERR "PGABS word $word GOT\n"; }
# if ($word =~ m/ad1201/) { print STDERR "GOT ad1201 $word $pg_abs $pg_abs{$pg_abs}GOT\n"; }

    if ($infer_auto{$word}) { $infer_list{$word}++; $flag++; } }	# add to list if should be gotten automatically
  if ($flag) {										# if any words matched
    print "Paper : \"WBPaper$pg_abs\"\n";						# print the paper
    foreach my $word (sort keys %infer_list) {						# print each word
      print "$infer_auto{$word}\t\"$word\"\tInferred_automatically\t\"citace_upload/papers/find_diff.pl script, $rundate\"\n"; }
    print "\n"; }
} # foreach my $pg_abs (sort keys %pg_abs)


# &mergedPapers();				# get and print out the merged papers and their connections  2005 09 27
# no longer do this, since all papers are dumped, not just the valid ones, so
# dump remark from use_package.pl 2005 11 10

($date) = &getSimpleSecDate();
print STDERR "END $date\n";
my $endtime = time;
my $difftime = $endtime - $starttime;
print STDERR "DIFF $difftime seconds\n";

close (ERR) or die "Cannot close $err_file : $!";


# sub mergedPapers {			# print out the merged paper connections
# #   my $page = "http://tazendra.caltech.edu/~postgres/cgi-bin/merged_papers.cgi";
# #   my @lines = split /\n/, $page;
# #   foreach my $line (@lines) {
# #     if ($line =~ m/^(\d{8})\s+is now\s+(\d{8})<BR>$/) { 
# #       print "Paper : \"WBPaper$1\"\nRemark\t\"Obsolete.  Merged into WBPaper$2\"\n\n"; } }
#   my %print_hash;
#   my $result = $conn->exec( "SELECT * FROM wpa_remark WHERE wpa_remark ~ 'Obsolete' ORDER BY wpa_timestamp;" ); 
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq 'valid') { if ($row[1] =~ m/^Obsolete/) { $print_hash{$row[0]} = $row[1]; } }
#     else { delete $print_hash{$row[0]}; }
#   } # while (my @row = $result->fetchrow)
#   foreach my $joinkey (sort keys %print_hash) {
# #     print "Paper : \"WBPaper$joinkey\"\nRemark\t\"$print_hash{$joinkey}\"\n\n"; 
#     print "Paper : \"WBPaper$joinkey\"\nRemark\t\"$print_hash{$joinkey}\" Inferred_automatically \"populateMerged.pl\"\n\n"; 
#   } # foreach my $joinkey (sort keys %print_hash)
# } # sub mergedPapers


sub checkLinesInsert {
#   my ($num, $cit_entry, $pg_entry) = @_; 
  my ($num, $cit_entry, $pg_entry, $err_leader, $inb_leader) = @_; 
  my %cit_ordered; my %pg_ordered; my %cit_unordered; my %pg_unordered;
  my $lines_to_print = '';
  my $cit_erratum = ''; my $pg_erratum = ''; my $cit_in_book = ''; my $pg_in_book = '';
  my %cit_erratum = (); my %pg_erratum = (); my %cit_in_book = (); my %pg_in_book = ();

  my @cit_lines = split/\n/, $cit_entry;
  my @pg_lines = split/\n/, $pg_entry;

  foreach my $cit_line (@cit_lines) { 
    my ($tag) = $cit_line =~ m/^(\w+)\s/;	# grab the tag (address, etc. because lines must be ordered within a tag
    unless ($tag) { print ERR "NO TAG checkLinesInsert CIT_LINE $cit_line CIT ENTRY $cit_entry NUM $num NO TAG\n\n"; next; }
    if ($ignore_tag{$tag}) { next; }
    if ($cit_line =~ m/^In_book\s+/) { 
      $cit_line =~ s/^(In_book\s+)//; my $temp_inb_leader = $1;	# type of in_book in line
      $cit_in_book{$temp_inb_leader} .= "$cit_line\n"; 
      next; }
    if ($cit_line =~ m/^Erratum\s+/) { 
      $cit_line =~ s/^(Erratum\s+)//; my $temp_err_leader = $1;	# type of erratum in line
      $cit_erratum{$temp_err_leader} .= "$cit_line\n"; 
      next; }
    if ($unordered_tag{$tag}) { 
#         $cit_unordered{$tag} .= $cit_line . "\n"; 	# add to hash of unordered cit lines within a tag
        $cit_unordered{$tag}{$cit_line}++; }		# add to hash of unordered cit lines within a tag
      else {
        $cit_ordered{$tag} .= $cit_line . "\n"; }	# add to hash of ordered cit lines within a tag
  }

  foreach my $pg_line (@pg_lines) { 
    my ($tag) = $pg_line =~ m/^(\w+)\s/;      # grab the tag (address, etc. because lines must be ordered within a tag
    unless ($tag) { print ERR "NO TAG checkLinesInsert PG_LINE $pg_line NO TAG\n\n"; next; }
    if ($ignore_tag{$tag}) { next; }
    if ($pg_line =~ m/^In_book\s+/) { 
      $pg_line =~ s/^(In_book\s+)//; my $temp_inb_leader = $1; 	# type of in_book in line
      $pg_in_book{$temp_inb_leader} .= "$pg_line\n"; 
      next; }
    if ($pg_line =~ m/^Erratum\s+/) { 
      $pg_line =~ s/^(Erratum\s+)//; my $temp_err_leader = $1; 	# type of erratum in line
      $pg_erratum{$temp_err_leader} .= "$pg_line\n"; 
      next; }
    if ($unordered_tag{$tag}) { 
#         $pg_unordered{$tag} .= $pg_line . "\n"; 	# add to hash of unordered pg lines within a tag
        $pg_unordered{$tag}{$pg_line}++; }		# add to hash of unordered pg lines within a tag
      else {
        $pg_ordered{$tag} .= $pg_line . "\n"; }	# add to hash of ordered pg lines within a tag
  }

  foreach my $loop_leader (sort keys %cit_in_book) {
    if ($cit_in_book{$loop_leader}) {
      my $recursive_leader;
      unless ($pg_in_book{$loop_leader}) { $pg_in_book{$loop_leader} = ''; }
      if ($inb_leader) { $recursive_leader = $inb_leader . $loop_leader; }
        else { $recursive_leader = $loop_leader; }
      &checkLinesInsert($num, $cit_in_book{$loop_leader}, $pg_in_book{$loop_leader}, $recursive_leader, ''); }		# they have changed
  } # foreach my $loop_leader (sort keys %cit_in_book)

  foreach my $loop_leader (sort keys %cit_erratum) {
    if ($cit_erratum{$loop_leader}) {
      my $recursive_leader;
      unless ($pg_erratum{$loop_leader}) { $pg_erratum{$loop_leader} = ''; }
      if ($err_leader) { $recursive_leader = $err_leader . $loop_leader; }
        else { $recursive_leader = $loop_leader; }
      &checkLinesInsert($num, $cit_erratum{$loop_leader}, $pg_erratum{$loop_leader}, $recursive_leader, ''); }		# they have changed
  } # foreach my $loop_leader (sort keys %cit_erratum)


  foreach my $tag (sort keys %pg_unordered) {				# going through each tag
    foreach my $pg_line (sort keys %{ $pg_unordered{$tag} } ) {		# going through each line
      if ( ($cit_unordered{$tag}{$pg_line}) && ($pg_unordered{$tag}{$pg_line}) ) {
        delete $pg_unordered{$tag}{$pg_line}; delete $cit_unordered{$tag}{$pg_line}; } }
  }					# if they match, delete from hash, so as not to print it (not delete it from citace)

  foreach my $tag (sort keys %pg_ordered) {	# going through each tag
    if ( ($cit_ordered{$tag}) && ($pg_ordered{$tag}) ) {
      if ($cit_ordered{$tag} eq $pg_ordered{$tag}) { 
        delete $pg_ordered{$tag}; delete $cit_ordered{$tag}; } }
  }					# if they match, delete from hash, so as not to print it (not delete it from citace)

  foreach my $tag (sort keys %pg_unordered) {	# for the remaining tags (the different tags which need to be deleted)
    foreach my $pg_line (sort keys %{ $pg_unordered{$tag} } ) {
      $lines_to_print .= "$pg_line\n"; } }
#   foreach my $tag (sort keys %pg_unordered) {	# for the remaining tags (the different tags which need to be deleted)
#     $pg_unordered{$tag} =~ s/\n$//g;		# take out the extra newline at the end
#     $lines_to_print .= "$pg_unordered{$tag}\n"; }	# add to print

  foreach my $tag (sort keys %pg_ordered) {	# for the remaining tags (the different tags which need to be deleted)
    $pg_ordered{$tag} =~ s/\n$//g;		# take out the extra newline at the end
    $lines_to_print .= "$pg_ordered{$tag}\n"; }	# add to print

  if ($inb_leader) {
    if ($lines_to_print) {
      my (@temp) = split/\n/, $lines_to_print; 
      foreach (@temp) { $_ =~ s/^/$inb_leader/; } 
      $lines_to_print = join"\n", @temp; $lines_to_print .= "\n"; } }

  if ($err_leader) {
    if ($lines_to_print) {
      my (@temp) = split/\n/, $lines_to_print; 
      foreach (@temp) { $_ =~ s/^/$err_leader/; } 
      $lines_to_print = join"\n", @temp; $lines_to_print .= "\n"; } }

  if ($lines_to_print) { print "Paper : \"WBPaper$num\"\n$lines_to_print\n"; }
					# print the stuff to delete with Paper header
#   foreach my $tag (sort keys %pg_ordered) {
#     if ( ($cit_ordered{$tag}) && ($pg_ordered{$tag}) ) {
#       if ($cit_ordered{$tag} eq $pg_ordered{$tag}) { delete $pg_ordered{$tag}; delete $cit_ordered{$tag}; } }
#   }
#   foreach my $tag (sort keys %pg_ordered) {
#     $pg_ordered{$tag} =~ s/\n$//g;
#     $lines_to_print .= "$pg_ordered{$tag}\n"; }
#   if ($lines_to_print) { print "Paper : \"WBPaper$num\"\n$lines_to_print\n"; }
} # sub checkLinesInsert

sub checkLinesDelete {
  my ($num, $cit_entry, $pg_entry, $err_leader, $inb_leader) = @_; 
  my %cit_ordered; my %pg_ordered;	# ordered cit or pg entries, grouped by tag
  my %cit_unordered; my %pg_unordered;
  my $lines_to_print = '';
  my $cit_erratum = ''; my $pg_erratum = ''; my $cit_in_book = ''; my $pg_in_book = '';
  my %cit_erratum = (); my %pg_erratum = (); my %cit_in_book = (); my %pg_in_book = ();

# if ($num =~ m/00004137/) { print STDERR "NUM $num CIT $cit_entry PG $pg_entry END\n"; }

  my @cit_lines = split/\n/, $cit_entry;
  my @pg_lines = split/\n/, $pg_entry;

  foreach my $cit_line (@cit_lines) { 
    my ($tag) = $cit_line =~ m/^(\w+)\s/;	# grab the tag (address, etc. because lines must be ordered within a tag
    unless ($tag) { print ERR "NO TAG checkLinesDelete CIT_LINE $cit_line CIT ENTRY $cit_entry NUM $num NO TAG\n\n"; next; }
    if ($ignore_tag{$tag}) { next; }

# if ($num =~ m/00004137/) { print STDERR "CIT NUM $num TAG $tag CIT $cit_line END\n"; }

    if ($cit_line =~ m/^In_book\s+/) { 
      $cit_line =~ s/^(In_book\s+)//; my $temp_inb_leader = $1;	# type of in_book in line
      $cit_in_book{$temp_inb_leader} .= "$cit_line\n"; 
      next; }
    if ($cit_line =~ m/^Erratum\s+/) { 
      $cit_line =~ s/^(Erratum\s+)//; my $temp_err_leader = $1;	# type of erratum in line
      $cit_erratum{$temp_err_leader} .= "$cit_line\n"; 
# if ($num =~ m/00004137/) { print STDERR "CIT ERRATUM NUM $num TAG $tag CIT $cit_line END\n"; }
      next; }
    if ($unordered_tag{$tag}) { 
# if ($num =~ m/00004137/) { print STDERR "CIT UNORDERED NUM $num TAG $tag CIT $cit_line END\n"; }
#         $cit_unordered{$tag} .= $cit_line . "\n"; 	# add to hash of unordered cit lines within a tag
        $cit_unordered{$tag}{$cit_line}++; }		# add to hash of unordered cit lines within a tag
      else {
# if ($num =~ m/00004137/) { print STDERR "CIT ORDERED NUM $num TAG $tag CIT $cit_line END\n"; }
        $cit_ordered{$tag} .= $cit_line . "\n"; }	# add to hash of ordered cit lines within a tag
  }

  foreach my $pg_line (@pg_lines) {
    my ($tag) = $pg_line =~ m/^(\w+)\s/;      # grab the tag (address, etc. because lines must be ordered within a tag
    unless ($tag) { print ERR "NO TAG checkLinesDelete PG_LINE $pg_line NO TAG\n\n"; next; }
    if ($ignore_tag{$tag}) { next; }

# if ($num =~ m/00004137/) { print STDERR "PG NUM $num TAG $tag PG $pg_line END\n"; }

    if ($pg_line =~ m/^In_book\s+/) { 
      $pg_line =~ s/^(In_book\s+)//; my $temp_inb_leader = $1; 	# type of in_book in line
      $pg_in_book{$temp_inb_leader} .= "$pg_line\n"; 
      next; }
    if ($pg_line =~ m/^Erratum\s+/) { 
      $pg_line =~ s/^(Erratum\s+)//; my $temp_err_leader = $1; 	# type of erratum in line
      $pg_erratum{$temp_err_leader} .= "$pg_line\n"; 
# if ($num =~ m/00004137/) { print STDERR "PG ERRATUM NUM $num TAG $tag PG $pg_line END\n"; }
      next; }
    if ($unordered_tag{$tag}) { 
# if ($num =~ m/00004137/) { print STDERR "PG UNORDERED NUM $num TAG $tag PG $pg_line END\n"; }
#         $pg_unordered{$tag} .= $pg_line . "\n"; 	# add to hash of unordered pg lines within a tag
        $pg_unordered{$tag}{$pg_line}++; }		# add to hash of unordered pg lines within a tag
      else {
# if ($num =~ m/00004137/) { print STDERR "PG ORDERED NUM $num TAG $tag PG $pg_line END\n"; }
        $pg_ordered{$tag} .= $pg_line . "\n"; }	# add to hash of ordered pg lines within a tag
  }

  foreach my $loop_leader (sort keys %cit_in_book) {
    if ($cit_in_book{$loop_leader}) {
      my $recursive_leader;
      unless ($pg_in_book{$loop_leader}) { $pg_in_book{$loop_leader} = ''; }
      if ($inb_leader) { $recursive_leader = $inb_leader . $loop_leader; }
        else { $recursive_leader = $loop_leader; }
      &checkLinesDelete($num, $cit_in_book{$loop_leader}, $pg_in_book{$loop_leader}, $recursive_leader, ''); }		# they have changed
  } # foreach my $loop_leader (sort keys %cit_in_book)

  foreach my $loop_leader (sort keys %cit_erratum) {
    if ($cit_erratum{$loop_leader}) {
      my $recursive_leader;
      unless ($pg_erratum{$loop_leader}) { $pg_erratum{$loop_leader} = ''; }
      if ($err_leader) { $recursive_leader = $err_leader . $loop_leader; }
        else { $recursive_leader = $loop_leader; }
      &checkLinesDelete($num, $cit_erratum{$loop_leader}, $pg_erratum{$loop_leader}, $recursive_leader, ''); }		# they have changed
  } # foreach my $loop_leader (sort keys %cit_erratum)


  foreach my $tag (sort keys %pg_unordered) {				# going through each tag
    foreach my $pg_line (sort keys %{ $pg_unordered{$tag} } ) {		# going through each line
      if ( ($cit_unordered{$tag}{$pg_line}) && ($pg_unordered{$tag}{$pg_line}) ) {
# if ($num =~ m/00004137/) { print STDERR "TAG $tag CIT $cit_unordered{$tag} PG $pg_unordered{$tag} END\n"; }
        delete $pg_unordered{$tag}{$pg_line}; delete $cit_unordered{$tag}{$pg_line}; } }
  }					# if they match, delete from hash, so as not to print it (not delete it from citace)

  foreach my $tag (sort keys %pg_ordered) {	# going through each tag
    if ( ($cit_ordered{$tag}) && ($pg_ordered{$tag}) ) {
      if ($cit_ordered{$tag} eq $pg_ordered{$tag}) { 
# if ($num =~ m/00004137/) { print STDERR "TAG $tag CIT $cit_ordered{$tag} PG $pg_ordered{$tag} END\n"; }
        delete $pg_ordered{$tag}; delete $cit_ordered{$tag}; } }
  }					# if they match, delete from hash, so as not to print it (not delete it from citace)

  foreach my $tag (sort keys %cit_unordered) {				# for the remaining tags (the different tags which need to be deleted)
    foreach my $cit_line (sort keys %{ $cit_unordered{$tag} } ) {	# going through each line
      $lines_to_print .= "-D $cit_line\n"; } }

#   foreach my $tag (sort keys %cit_unordered) {	# for the remaining tags (the different tags which need to be deleted)
#     $cit_unordered{$tag} =~ s/\n$//g;		# take out the extra newline at the end
#     $cit_unordered{$tag} =~ s/\n/\n-D /g;		# replace with -D at the beginning
#     $lines_to_print .= "-D $cit_unordered{$tag}\n"; }	# add -D to first line

  foreach my $tag (sort keys %cit_ordered) {	# for the remaining tags (the different tags which need to be deleted)
    $cit_ordered{$tag} =~ s/\n$//g;		# take out the extra newline at the end
    $cit_ordered{$tag} =~ s/\n/\n-D /g;		# replace with -D at the beginning
    $lines_to_print .= "-D $cit_ordered{$tag}\n"; }	# add -D to first line

  if ($inb_leader) {
    if ($lines_to_print) {
      my (@temp) = split/\n/, $lines_to_print; 
      foreach (@temp) { $_ =~ s/^-D /-D $inb_leader/; } 
      $lines_to_print = join"\n", @temp; $lines_to_print .= "\n"; } }

  if ($err_leader) {
    if ($lines_to_print) {
      my (@temp) = split/\n/, $lines_to_print; 
      foreach (@temp) { $_ =~ s/^-D /-D $err_leader/; } 
      $lines_to_print = join"\n", @temp; $lines_to_print .= "\n"; } }

  if ($lines_to_print) { 
    if ($lines_to_print =~ m/NEWLINEREPLACEMENT/) { $lines_to_print =~ s/NEWLINEREPLACEMENT/\\n\\\n/g; }
    print "Paper : \"WBPaper$num\"\n$lines_to_print\n"; }
					# print the stuff to delete with Paper header
} # sub checkLinesDelete

sub getSimpleMinDate {                  # begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);  # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  my $shortdate = "${year}-${sam}-${mday} ${hour}:${min}";   # get final date
  return $shortdate;
} # sub getSimpleSecDate                        # end getSimpleDate

