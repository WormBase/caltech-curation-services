#!/usr/bin/perl -w

# reformat_longtext_annots.pl
# by Erich Schwarz <emsch@its.caltech.edu>, 4/8/04

# Purpose: reformat LongText annotations (human-writeable but obsolete) into newer Text format (machine-better but human-unreadable).

# Modified by Juancarlos to enter data into postgres.

# Read normal section of .ace file (Locus, CDS, etc. then Provisional, Concise, etc. then associate
# Paper_evidence and Person_evidence to the entry).  Then read the file and capture the LongText
# data and associate it to the entry.  Use Erich's list of parsing stuff to make sure that splitting
# by period (.) gives us the first sentence, then get the first sentence separate from the rest of
# the entry, and replace back with Erich's list of parsing stuff.  If it matches previous
# Paper_evidence, add to list of stuff to exec to Pg.  If it matches previous Person_evidence, 
# convert WBPerson#s to Person names, and add to list of stuff to exec to Pg (Add to car_con_curator
# for that data, car_lastcurator so the entry can be queried, and if there was extra sentences, to
# car_ext_curator).  If there was no Person_evidence, instead add Erich Schwartz as evidence.  If
# there is stuff for Pg, print to screen (redirect to log), and exec to Pg via $result. 
#
# usage : ./longtext_to_postgres.pl* > log_take4	2004 06 14
#
# Added e.g. i.e. i. e. 
# Some ***LongTextEnd***  said *** LongTextEnd ***
# New format has Gene instead of Locus, etc.
# Read in annots-15jun2004_old-format.ace without a problem.  2004 06 17
#
# Read in annots-05jul2004_old-format.ace without deleting old data.  2004 07 06
#
# Looked at postgres entries of car_ext_maindata that had ``LongText'' in them, found corresponding
# entries in the 07-30 annots file, manually created fixed entries for fix_20040809.ace, read those
# into pg, deleted car_ext_maindata with ``LongText''  2004 08 09

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



# my $inputfile = 'sample_annots.ace';
# my $inputfile = 'annots-27may2004_old-format.ace';
# my $inputfile = 'annots-15jun2004_old-format.ace';
# my $inputfile = 'annots-17jun2004_old-format.ace';
# my $inputfile = 'annots-05jul2004_old-format.ace';
my $inputfile = 'fix_20040809.ace';

my %hash;		# hash of data.

$/ = "";
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
while (my $entry = <IN>) {
#   if ($entry =~ /^Locus :/ || $entry =~ /^Sequence :/ || $entry =~ /^CDS :/ || $entry =~ /^Transcript :/) { 
  if ($entry =~ /^Gene :/) {
    my $id = 'ID';
    ($id) = $entry =~ m/^\w+ +: *\"?(.*?)\"?\s*\n/;
    $id =~ s/\"? .*$//g;
# if ($entry =~ m/let-2/) { print STDERR "WHAT $id WHAT let-2 $entry\n"; }
    unless ($id) { 
# if ($entry =~ m/let-2/) { print STDERR "let-2 no id1 \n"; }
      ($id) = $entry =~ m/^\w+ : ?\"?(.*?)\"?\s*\/\/.*?\n/; }
    unless ($id) { print "NO ID $entry\n"; }
    $hash{$id}{count}++;
    if ($entry =~ m/Person_evidence \"(.*?)\"/) {
      my (@persons) = $entry =~ m/Person_evidence \"(.*?)\"/g;
      if (scalar(@persons)>0) { 
        foreach (@persons) { 
          push @{ $hash{$id}{persons} }, $_; } } }
    if ($entry =~ m/Paper_evidence \"(.*?)\"/) {
      my (@papers) = $entry =~ m/Paper_evidence \"(.*?)\"/g;
      if (scalar(@papers)>0) { 
        foreach (@papers) {
          $_ =~ s/\[//g; $_ =~ s/\]//g;
          push @{ $hash{$id}{papers} }, $_; } } }
  } # if ($entry =~ /^Gene :/)
#   } # if ($entry =~ /^Locus :/ || $entry =~ /^Sequence :/ || $entry =~ /^CDS :/ || $entry =~ /^Transcript :/)
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $inputfile : $!";


$/ = undef;	# slurp
open (IN, "<$inputfile") or die "Cannot open $inputfile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $inputfile : $!";

# print $allfile . "\n";

my (@stuff) = $allfile =~ m/LongText : "(.*?)" ?\n\s*?\n(.*?)\n\s*?\n\*\*\* ?LongTextEnd ?\*\*\*/sg;
while (scalar(@stuff) > 0) { 
  my $gene = shift @stuff;
  my $pg_stuff = '';
  my @pg_exec = ();
  $gene =~ s/\"? .*$//g;
  my $entry = shift @stuff;
  $entry =~ s/\s+/ /g;						# switch out periods and stuff (erich)
  $entry =~ s/\"/\'/g;    # added to keep double-quotes out of annotation text
  $entry =~ s/^\s+//;
  $entry =~ s/C\. elegans/C__elegans/g;
  $entry =~ s/C\. briggsae/C__briggsae/g;
  $entry =~ s/D\. discoideum/D__discoideum/g;
  $entry =~ s/H\. sapiens/H__sapiens/g;
  $entry =~ s/D\. melanogaster/D__melanogaster/g;
  $entry =~ s/S\. cerevisiae/S__cerevisiae/g;
  $entry =~ s/S\. pombe/S__pombe/g;
  $entry =~ s/A\. nidulans/A__nidulans/g;
  $entry =~ s/E\. coli/E__coli/g;
  $entry =~ s/B\. subtilis/B__subtilis/g;
  $entry =~ s/A\. suum/A__suum/g;
  $entry =~ s/A\. thaliana/A__thaliana/g;
  $entry =~ s/1st\. ed/1st__ed/g;
  $entry =~ s/d\. ed/d__ed/g;
  $entry =~ s/et al\./et al__/g;
  $entry =~ s/e\. g\./e__g__/g;
  $entry =~ s/e\.g\./e_g__/g;
  $entry =~ s/i\.e\./i_e__/g;
  $entry =~ s/i\. e\./i__e__/g;
  $entry =~ s/Fig\. /Fig__/g;
  $entry =~ s/deg\. C /degrees C /g;
  $entry =~ s/deg\. C\./degrees C\./g;
  $entry =~ s/[\.]{2,}/\./g;
  my ($firstline, $restline) = $entry =~ m/^(.*?)\. (.*?)$/g;	# separate firstline and rest
  unless ($firstline) { $firstline = $entry; }
  if ($firstline) { 
    if ($firstline =~ m/C__elegans/) { $firstline =~ s/C__elegans/C\. elegans/g; }			# switch back
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
#     print "FIRST $firstline\n"; 
    $firstline =~ s/'/''/g;
    $firstline =~ s/\"/\\\"/g;
    $pg_stuff .= "INSERT INTO car_con_maindata VALUES (\'$gene\', \'$firstline.\');\n"; 
    push @pg_exec, $pg_stuff;
  } else { 
#     print "NO FIRST $entry\n"; 
  }
  if ($restline) { 
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
    $restline =~ s/'/''/g;
    $restline =~ s/\"/\\\"/g;
#     print "REST $restline\n"; 
    $pg_stuff .= "INSERT INTO car_ext_maindata VALUES (\'$gene\', \'$restline.\');\n"; 
    push @pg_exec, $pg_stuff;
  } else { 
#     print "NO REST $entry\n"; 
  }

  if ( $hash{$gene} ) { 
    if ($hash{$gene}{papers}) { 
      my $papers = join ", ", @{ $hash{$gene}{papers} };
      $pg_stuff .= "INSERT INTO car_con_ref_paper VALUES (\'$gene\', \'$papers\');\n";
      push @pg_exec, $pg_stuff; }
    
    if ($hash{$gene}{persons}) { 
      foreach my $person ( @{ $hash{$gene}{persons} } ) {
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

#         else { print STDERR "PERSON $gene -=${person}=-\n"; }
        $pg_stuff .= "INSERT INTO car_lastcurator VALUES (\'$gene\', \'$person\');\n";
        push @pg_exec, $pg_stuff;
        $pg_stuff .= "INSERT INTO car_con_ref_curator VALUES (\'$gene\', \'$person\');\n";
        push @pg_exec, $pg_stuff;
        if ($restline) { 
          $pg_stuff .= "INSERT INTO car_ext_ref_curator VALUES (\'$gene\', \'$person\');\n";
          push @pg_exec, $pg_stuff; }
#         print "car_con_curator $person\n";
      }
    } else {
      $pg_stuff .= "INSERT INTO car_lastcurator VALUES (\'$gene\', \'Erich Schwarz\');\n";
      push @pg_exec, $pg_stuff;
      $pg_stuff .= "INSERT INTO car_con_ref_curator VALUES (\'$gene\', \'Erich Schwarz\');\n";
      push @pg_exec, $pg_stuff;
      if ($restline) { 
        $pg_stuff .= "INSERT INTO car_ext_ref_curator VALUES (\'$gene\', \'Erich Schwarz\');\n";
        push @pg_exec, $pg_stuff; }
    }

    if ($pg_stuff) { 
      print "$pg_stuff\n"; 
#       my $result = $conn->exec( "$pg_stuff" );
    }
  #   print "GENE : $gene\nENTRY : $entry : END ENTRY\n";
  } else { 
    print "No Gene entry $gene\n"; 
  }
}


# sample deletion
# DELETE FROM car_concise WHERE car_timestamp > '2004-07-06 15:00:00' AND car_timestamp < '2004-07-06 17:00:00';
# DELETE FROM car_extra_provisional WHERE car_timestamp > '2004-07-06 15:00:00' AND car_timestamp < '2004-07-06 17:00:00';
# DELETE FROM car_con_ref1 WHERE car_timestamp > '2004-07-06 15:00:00' AND car_timestamp < '2004-07-06 17:00:00';
# DELETE FROM car_lastcurator WHERE car_timestamp > '2004-07-06 15:00:00' AND car_timestamp < '2004-07-06 17:00:00';
# DELETE FROM car_con_curator WHERE car_timestamp > '2004-07-06 15:00:00' AND car_timestamp < '2004-07-06 17:00:00';
# DELETE FROM car_ext_curator WHERE car_timestamp > '2004-07-06 15:00:00' AND car_timestamp < '2004-07-06 17:00:00';

