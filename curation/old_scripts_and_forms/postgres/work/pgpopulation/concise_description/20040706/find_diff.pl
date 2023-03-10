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
#
#
# Changed to deal with annots-05jul2004_old-format.ace and 
# concise_readable.ace   Read files into hash, read longtexts
# ``diff'' longtexts and create INSERTs for concise and extra
# (and flag them)  then ``diff'' hashes, if new gene create
# lastcurator entry, if not just create person and paper entries
# and if flagged, add person to ext_curator and con_curator.
# 2004 07 07


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $cit_file = $ARGV[0];
my $pg_file = $ARGV[1];

my %cit_hash;
my %pg_hash;

$/ = "";
open (CIT, "<$cit_file") or die "Cannot open $cit_file : $!";
while (<CIT>) {
  if ($_ =~ m/Gene : \"(WBGene\d+)\"/) { $cit_hash{$1} = $_; }
} # while (<CIT>)
close (CIT) or die "Cannot close $cit_file : $!";

open (PGF, "<$pg_file") or die "Cannot open $pg_file : $!";
while (<PGF>) {
  if ($_ =~ m/Gene : \"(WBGene\d+)\"/) { $pg_hash{$1} = $_; }
} # while (<PGF>)
close (PGF) or die "Cannot close $pg_file : $!";

$/ = undef;
my %cit_long;
my %pg_long;
open (CIT, "<$cit_file") or die "Cannot open $cit_file : $!";
my $allfile = <CIT>;
close (CIT) or die "Cannot close $cit_file : $!";
my (@stuff) = $allfile =~ m/LongText : "(.*?)" ?\n\s*?\n(.*?)\n\s*?\n\*\*\* ?LongTextEnd ?\*\*\*/sg;
while (scalar(@stuff)) {
  my $gene = shift @stuff;
  $gene =~ s/\"? .*$//g;
  my $entry = shift @stuff;
  $entry =~ s/\n/ /g; $entry =~ s/\s+/ /g;
  $cit_long{$gene} = $entry;
#   print "CIT GENE $gene\nENTRY $entry\n";
}
open (PGF, "<$pg_file") or die "Cannot open $pg_file : $!";
$allfile = <PGF>;
close (PGF) or die "Cannot close $pg_file : $!";
(@stuff) = $allfile =~ m/LongText : "(.*?)" ?\n\s*?\n(.*?)\n\s*?\n\*\*\* ?LongTextEnd ?\*\*\*/sg;
while (scalar(@stuff)) {
  my $gene = shift @stuff;
  $gene =~ s/\"? .*$//g;
  my $entry = shift @stuff;
  $entry =~ s/\n/ /g; $entry =~ s/\s+/ /g;
  $pg_long{$gene} = $entry;
#   print "PG GENE $gene\nENTRY $entry\n";
}

my @pg_exec = ();
my %has_extra;					# hash of genes with extra provisonal data
my %has_concise;				# hash of genes with concise data
foreach my $pg_gene (sort keys %pg_long) {
  my $stuff_to_add; 
  unless ($cit_long{$pg_gene}) { 
    $stuff_to_add = $pg_long{$pg_gene};
#     print "$pg_long{$pg_gene}"; 
    next; }	# if no cit entry for person
  if ($pg_long{$pg_gene} eq $cit_long{$pg_gene}) {	# they are the same
  } else { 						# they have changed
    $stuff_to_add = $pg_long{$pg_gene};
#     print "DIFF $pg_gene\nNEW$pg_long{$pg_gene}NEW\nOLD$cit_long{$pg_gene}OLD\n";
#     &checkLinesInsert($pg_gene);
  }
  if ($stuff_to_add) {
    $stuff_to_add =~ s/\s+/ /g;                                          # switch out periods and stuff (erich)
    $stuff_to_add =~ s/\"/\'/g;    # added to keep double-quotes out of annotation text
    $stuff_to_add =~ s/^\s+//;
    $stuff_to_add =~ s/C\. elegans/C__elegans/g;
    $stuff_to_add =~ s/C\. briggsae/C__briggsae/g;
    $stuff_to_add =~ s/D\. discoideum/D__discoideum/g;
    $stuff_to_add =~ s/H\. sapiens/H__sapiens/g;
    $stuff_to_add =~ s/D\. melanogaster/D__melanogaster/g;
    $stuff_to_add =~ s/S\. cerevisiae/S__cerevisiae/g;
    $stuff_to_add =~ s/S\. pombe/S__pombe/g;
    $stuff_to_add =~ s/A\. nidulans/A__nidulans/g;
    $stuff_to_add =~ s/E\. coli/E__coli/g;
    $stuff_to_add =~ s/B\. subtilis/B__subtilis/g;
    $stuff_to_add =~ s/A\. suum/A__suum/g;
    $stuff_to_add =~ s/A\. thaliana/A__thaliana/g;
    $stuff_to_add =~ s/1st\. ed/1st__ed/g;
    $stuff_to_add =~ s/d\. ed/d__ed/g;
    $stuff_to_add =~ s/et al\./et al__/g;
    $stuff_to_add =~ s/e\. g\./e__g__/g;
    $stuff_to_add =~ s/e\.g\./e_g__/g;
    $stuff_to_add =~ s/i\.e\./i_e__/g;
    $stuff_to_add =~ s/i\. e\./i__e__/g;
    $stuff_to_add =~ s/Fig\. /Fig__/g;
    $stuff_to_add =~ s/deg\. C /degrees C /g;
    $stuff_to_add =~ s/deg\. C\./degrees C\./g;
    $stuff_to_add =~ s/[\.]{2,}/\./g;
# print "STUFF $stuff_to_add STUFF\n";
    my ($firstline, $restline) = $stuff_to_add =~ m/^(.*?)\.(.*?)$/g;    # separate firstline and rest
    unless ($firstline) { $firstline = $stuff_to_add; }
    if ($firstline) {
      $has_concise{$pg_gene}++;
      if ($firstline =~ m/C__elegans/) { $firstline =~ s/C__elegans/C\. elegans/g; } # switch back
      if ($firstline =~ m/C__briggsae/) { $firstline =~ s/C__briggsae/C\. briggsae/g; }
      if ($firstline =~ m/D__discoideum/) { $firstline =~ s/D__discoideum/D\. discoideum/g; }
      if ($firstline =~ m/H__sapiens/) { $firstline =~ s/H__sapiens/H\. sapiens/g; }
      if ($firstline =~ m/D__melanogaster/) { $firstline =~ s/D__melanogaster/D\. melanogaster/g; }
      if ($firstline =~ m/S__cerevisiae/) { $firstline =~ s/S__cerevisiae/S\. cerevisiae/g; }
      if ($firstline =~ m/S__pombe/) { $firstline =~ s/S__pombe/S\. pombe/g; }
      if ($firstline =~ m/A__nidulans/) { $firstline =~ s/A__nidulans/A\. nidulans/g; }
      if ($firstline =~ m/E__coli/) { $firstline =~ s/E__coli/E\. coli/g; }
      if ($firstline =~ m/B__subtilis/) { $firstline =~ s/B__subtilis/B\. subtilis/g; }
      if ($firstline =~ m/A__suum/) { $firstline =~ s/A__suum/A\. suum/g; }
      if ($firstline =~ m/A__thaliana/) { $firstline =~ s/A__thaliana/A\. thaliana/g; }
      if ($firstline =~ m/1st__ed/) { $firstline =~ s/1st__ed/1st\. ed/g; }
      if ($firstline =~ m/d__ed/) { $firstline =~ s/d__ed/d\. ed/g; }
      if ($firstline =~ m/et al__/) { $firstline =~ s/et al__/et al\. /g; }
      if ($firstline =~ m/e__g__/) { $firstline =~ s/e__g__/e\. g\./g; }
      if ($firstline =~ m/e_g__/) { $firstline =~ s/e_g__/e\.g\./g; }
      if ($firstline =~ m/i_e__/) { $firstline =~ s/i_e__/i\.e\./g; }
      if ($firstline =~ m/i__e__/) { $firstline =~ s/i__e__/i\. e\./g; }
      if ($firstline =~ m/Fig__/) { $firstline =~ s/Fig__/Fig\. /g; }
      if ($firstline =~ m/[\.]$/) { $firstline =~ s/[\.]$//; }
      $firstline =~ s/'/''/g;
      $firstline =~ s/\"/\\\"/g;
      my $pg_stuff .= "INSERT INTO car_concise VALUES (\'$pg_gene\', \'$firstline.\');\n";
      push @pg_exec, $pg_stuff; }
    if ($restline =~ m/\S/) {
      $has_extra{$pg_gene}++;
      if ($restline =~ m/C__elegans/) { $restline =~ s/C__elegans/C\. elegans/g; }
      if ($restline =~ m/C__briggsae/) { $restline =~ s/C__briggsae/C\. briggsae/g; }
      if ($restline =~ m/D__discoideum/) { $restline =~ s/D__discoideum/D\. discoideum/g; }
      if ($restline =~ m/H__sapiens/) { $restline =~ s/H__sapiens/H\. sapiens/g; }
      if ($restline =~ m/D__melanogaster/) { $restline =~ s/D__melanogaster/D\. melanogaster/g; }
      if ($restline =~ m/S__cerevisiae/) { $restline =~ s/S__cerevisiae/S\. cerevisiae/g; }
      if ($restline =~ m/S__pombe/) { $restline =~ s/S__pombe/S\. pombe/g; }
      if ($restline =~ m/A__nidulans/) { $restline =~ s/A__nidulans/A\. nidulans/g; }
      if ($restline =~ m/E__coli/) { $restline =~ s/E__coli/E\. coli/g; }
      if ($restline =~ m/B__subtilis/) { $restline =~ s/B__subtilis/B\. subtilis/g; }
      if ($restline =~ m/A__suum/) { $restline =~ s/A__suum/A\. suum/g; }
      if ($restline =~ m/A__thaliana/) { $restline =~ s/A__thaliana/A\. thaliana/g; }
      if ($restline =~ m/1st__ed/) { $restline =~ s/1st__ed/1st\. ed/g; }
      if ($restline =~ m/d__ed/) { $restline =~ s/d__ed/d\. ed/g; }
      if ($restline =~ m/et al__/) { $restline =~ s/et al__/et al\. /g; }
      if ($restline =~ m/e__g__/) { $restline =~ s/e__g__/e\. g\./g; }
      if ($restline =~ m/e_g__/) { $restline =~ s/e_g__/e\.g\./g; }
      if ($restline =~ m/i_e__/) { $restline =~ s/i_e__/i\.e\./g; }
      if ($restline =~ m/i__e__/) { $restline =~ s/i__e__/i\. e\./g; }
      if ($restline =~ m/Fig__/) { $restline =~ s/Fig__/Fig\. /g; }
      if ($restline =~ m/[\.]$/) { $restline =~ s/[\.]$//; }
      if ($restline =~ m/^\s+/) { $restline =~ s/^\s+//; }
      if ($restline =~ m/\s+$/) { $restline =~ s/\s+$//; }
      if ($restline =~ m/\.$/) { $restline =~ s/\.$//; }
      $restline =~ s/'/''/g;
      $restline =~ s/\"/\\\"/g;
      my $pg_stuff .= "INSERT INTO car_extra_provisional VALUES (\'$pg_gene\', \'$restline.\');\n";
      push @pg_exec, $pg_stuff; }
  } # if ($stuff_to_add)
} # foreach my $pg_gene (sort keys %pg_hash)


# not deleting anything, only inserting
# foreach my $pg_person (sort {$a <=> $b} keys %pg_hash) {
#   unless ($cit_hash{$pg_person}) { print "$pg_hash{$pg_person}"; next; }	# if no cit entry for person
#   if ($pg_hash{$pg_person} eq $cit_hash{$pg_person}) {	# they are the same
# #     print "GOOD $pg_person\n";
#   } else { 						# they have changed
# #     print "$pg_person\n$cit_hash{$pg_person}\n$pg_hash{$pg_person}\n";
#     &checkLinesDelete($pg_person);
#   }
# } # foreach my $pg_person (sort keys %pg_hash)

foreach my $pg_person (sort keys %pg_hash) {
  unless ($cit_hash{$pg_person}) {			# if no cit entry for person
#     print "$pg_hash{$pg_person}"; 
    &insertEvidenceStuff($pg_hash{$pg_person});
    next; }
  if ($pg_hash{$pg_person} eq $cit_hash{$pg_person}) {	# they are the same
  } else { 						# they have changed
    &checkLinesInsert($pg_person);
  }
} # foreach my $pg_person (sort keys %pg_hash)

my %pg_filter;
foreach my $pg_exec (@pg_exec) { $pg_filter{$pg_exec}++; }
foreach my $pg_exec (sort keys %pg_filter) { 
#   my $result = $conn->exec( "$pg_exec" );
  print "$pg_exec"; }



sub checkLinesInsert {
  my $num = shift; my %cit_lines; my %pg_lines;
  my $lines_to_print = '';
  my @cit_lines = split/\n/, $cit_hash{$num};
  my @pg_lines = split/\n/, $pg_hash{$num};
  foreach (@cit_lines) { 
    $_ =~ s/\s+/ /g; $_ =~ s/\s*\/\/.*?$//g; $_ =~ s/\s+$//g; 
    last unless $_;
    $cit_lines{$_}++; 
  }
  foreach (@pg_lines) { 
    $_ =~ s/\s+/ /g; $_ =~ s/\s*\/\/.*?$//g; $_ =~ s/\s+$//g; 
    last unless $_;
    $pg_lines{$_}++; 
  }
  foreach my $pg_line (sort keys %pg_lines) {
    if ($cit_lines{$pg_line}) { delete $pg_lines{$pg_line}; delete $cit_lines{$pg_line}; } }
#   foreach my $cit_line (sort keys %cit_lines) {
#     $lines_to_print .= "-D $cit_line\n"; }
  foreach my $pg_line (sort keys %pg_lines) {
    $lines_to_print .= "$pg_line\n"; }
  if ($lines_to_print) { 
#     print "$lines_to_print\n"; 
    &insertEvidenceStuff($lines_to_print);
  }
} # sub checkLinesInsert

sub insertEvidenceStuff {
my $count = 0;
  my $lines_to_print = shift;
  my @persons = (); my @wbpersons;
  my @papers = ();
  my $pg_stuff = '';
  my ($gene) = $lines_to_print =~ m/(WBGene\d{8})/;
  if ($lines_to_print =~ m/Person_evidence\s\"(WBPerson\d+)\"/) {
    (@wbpersons) = $lines_to_print =~ m/Person_evidence\s\"(.*?)\"/g ;
    foreach my $person (@wbpersons) {
      if ($person eq 'WBPerson567') { $person = 'Erich Schwarz'; }
      elsif ($person eq 'WBPerson1823') { $person = 'Juancarlos Chan'; }
      elsif ($person eq 'WBPerson1843') { $person = 'Kimberly Van Auken'; }
      elsif ($person eq 'WBPerson345') { $person = 'James Kramer'; }
      elsif ($person eq 'WBPerson324') { $person = 'Ranjana Kishore'; }
      elsif ($person eq 'WBPerson258') { $person = 'Massimo Hilliard'; }
      elsif ($person eq 'WBPerson48') { $person = 'Carol Bastiani'; }
      elsif ($person eq 'WBPerson204') { $person = 'Verena Gobel'; }
      elsif ($person eq 'WBPerson2104') { $person = 'Graham Goodwin'; }
      elsif ($person eq 'WBPerson625') { $person = 'Paul Sternberg'; }
      elsif ($person eq 'WBPerson363') { $person = 'Raymond Lee'; }
      elsif ($person eq 'WBPerson480') { $person = 'Andrei Petcherski'; }
      elsif ($person eq 'WBPerson83') { $person = 'Thomas Burglin'; }
      elsif ($person eq 'WBPerson71') { $person = 'Thomas Blumenthal'; }
      elsif ($person eq 'WBPerson261') { $person = 'Jonathan Hodgkin'; }
      elsif ($person eq 'WBPerson638') { $person = 'Marie Causey'; }
      elsif ($person eq 'WBPerson154') { $person = 'Mark Edgley'; }
      elsif ($person eq 'WBPerson699') { $person = 'Alison Woollard'; }
      elsif ($person eq 'WBPerson266') { $person = 'Ian Hope'; }
      elsif ($person eq 'WBPerson575') { $person = 'Geraldine Seydoux'; }
      elsif ($person eq 'WBPerson344') { $person = 'Marta Kostrouchova'; }
      elsif ($person eq 'WBPerson2522') { $person = 'Malcolm Kennedy'; }
      elsif ($person eq 'WBPerson1874') { $person = 'Berndt Mueller'; }
      elsif ($person eq 'WBPerson327') { $person = 'Steven Kleene'; }
      elsif ($person eq 'WBPerson330') { $person = 'Michael Koelle'; }
      elsif ($person eq 'WBPerson365') { $person = 'Giovanni Lesa'; }
      elsif ($person eq 'WBPerson366') { $person = 'Benjamin Leung'; }
      elsif ($person eq 'WBPerson377') { $person = 'Robyn Lints'; }
      elsif ($person eq 'WBPerson381') { $person = 'Leo Liu'; }
      elsif ($person eq 'WBPerson395') { $person = 'Margaret MacMorris'; }
      elsif ($person eq 'WBPerson669') { $person = 'Jacob Varkey'; }
      elsif ($person eq 'WBPerson1264') { $person = 'Kim McKim'; }
      elsif ($person eq 'WBPerson1119') { $person = 'Bob Johnsen'; }
      elsif ($person eq 'WBPerson553') { $person = 'Gerhard Schad'; }
      elsif ($person eq 'WBPerson36') { $person = 'David Baillie'; }
      push @persons, $person; } }
  if ($lines_to_print =~ m/Paper_evidence\s\"(\[.*?\])\"/) {
    (@papers) = $lines_to_print =~ m/Paper_evidence\s\"\[(.*?)\]\"/g } 
  if ($lines_to_print =~ m/Gene : \"(WBGene\d{8})\"/) {
    unless ($persons[0]) { $persons[0] = 'Erich Schwarz'; }
    push @pg_exec, "INSERT INTO car_lastcurator VALUES (\'$gene\', \'$persons[0]\');\n";
  }
  if ($has_concise{$gene}) {
    if ($persons[0]) { 
      foreach my $person (@persons) {
        push @pg_exec, "INSERT INTO car_con_curator VALUES (\'$gene\', \'$person\');\n"; } }
    else { 
      push @pg_exec, "INSERT INTO car_con_curator VALUES (\'$gene\', \'Erich Schwarz\');\n"; } }
  if ($has_extra{$gene}) {
    if ($persons[0]) { 
      foreach my $person (@persons) {
        push @pg_exec, "INSERT INTO car_ext_curator VALUES (\'$gene\', \'$person\');\n"; } }
    else { 
      push @pg_exec, "INSERT INTO car_ext_curator VALUES (\'$gene\', \'Erich Schwarz\');\n"; } }
  foreach my $person (@persons) {
    push @pg_exec, "INSERT INTO car_con_curator VALUES (\'$gene\', \'$person\');\n"; }
  my $paper = join', ', @papers;
  if ($paper) { 
    push @pg_exec, "INSERT INTO car_con_ref1 VALUES (\'$gene\', \'$paper\');\n"; }
#   foreach my $paper (@papers) {
#     push @pg_exec, "INSERT INTO car_con_ref1 VALUES (\'$gene\', \'$paper\');\n"; }
} # sub insertEvidenceStuff

sub checkLinesDelete {
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
#   foreach my $pg_line (sort keys %pg_lines) {
#     $lines_to_print .= "$pg_line\n"; }
  if ($lines_to_print) { print "Person : WBPerson$num\n$lines_to_print\n"; }
} # sub checkLinesDelete
