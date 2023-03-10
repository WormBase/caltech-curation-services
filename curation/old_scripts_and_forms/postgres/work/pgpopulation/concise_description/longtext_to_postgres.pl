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


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;



# my $inputfile = 'sample_annots.ace';
# my $inputfile = 'annots-27may2004_old-format.ace';
# my $inputfile = 'annots-15jun2004_old-format.ace';
my $inputfile = 'annots-17jun2004_old-format.ace';

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
  my ($firstline, $restline) = $entry =~ m/^(.*?)\.(.*?)$/g;	# separate firstline and rest
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
    $pg_stuff .= "INSERT INTO car_concise VALUES (\'$gene\', \'$firstline.\');\n"; 
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
    $pg_stuff .= "INSERT INTO car_extra_provisional VALUES (\'$gene\', \'$restline.\');\n"; 
    push @pg_exec, $pg_stuff;
  } else { 
#     print "NO REST $entry\n"; 
  }

  if ( $hash{$gene} ) { 
    if ($hash{$gene}{papers}) { 
      my $papers = join ", ", @{ $hash{$gene}{papers} };
      $pg_stuff .= "INSERT INTO car_con_ref1 VALUES (\'$gene\', \'$papers\');\n";
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
#         else { print STDERR "PERSON $gene -=${person}=-\n"; }
        $pg_stuff .= "INSERT INTO car_lastcurator VALUES (\'$gene\', \'$person\');\n";
        push @pg_exec, $pg_stuff;
        $pg_stuff .= "INSERT INTO car_con_curator VALUES (\'$gene\', \'$person\');\n";
        push @pg_exec, $pg_stuff;
        if ($restline) { 
          $pg_stuff .= "INSERT INTO car_ext_curator VALUES (\'$gene\', \'$person\');\n";
          push @pg_exec, $pg_stuff; }
#         print "car_con_curator $person\n";
      }
    } else {
      $pg_stuff .= "INSERT INTO car_lastcurator VALUES (\'$gene\', \'Erich Schwarz\');\n";
      push @pg_exec, $pg_stuff;
      $pg_stuff .= "INSERT INTO car_con_curator VALUES (\'$gene\', \'Erich Schwarz\');\n";
      push @pg_exec, $pg_stuff;
      if ($restline) { 
        $pg_stuff .= "INSERT INTO car_ext_curator VALUES (\'$gene\', \'Erich Schwarz\');\n";
        push @pg_exec, $pg_stuff; }
    }

    if ($pg_stuff) { 
      print "$pg_stuff\n"; 
      my $result = $conn->exec( "$pg_stuff" );
    }
  #   print "GENE : $gene\nENTRY : $entry : END ENTRY\n";
  } else { 
    print "No Gene entry $gene\n"; 
  }
}




# my $input                 = "";
# my $output                = "";
# my $reading_in_references = "no";
# my $reading_in_longtext   = "no";
# my $input_line            = "";
# my $longtext_line         = "";
# my @longtext_array        = "";
# my $i                     = "";
# my $annotation_textline   = "";
# my $descript_type         = "";
# my $old_longtext_line     = "";
# my @paper_references      = "";
# my $reference_to_print    = "";
# my $indiv_reference       = "";
# 
# 
# if ($#ARGV != 0) 
# {
#     print "LongText .ace file to be reformatted?: ";
#     chomp($input = <STDIN>);
#     $output = $input . ".reformatted_dot_ace";
# } 
# else 
# {
#     chomp($input = $ARGV[0]);
#     $output = $input . ".reformatted_dot_ace";
# }
# 
# open (INPUT, "$input") || die "Couldn't open input file. $!\n";
# open (OUTPUT, ">$output") || die "Couldn't open output file. $!\n";
# 
# while (<INPUT>) 
# {
#     chomp ($input_line = $_);
# 
#     if ($input_line =~ /LongTextEnd/)
#     {
#         $reading_in_longtext = "no";
# 
#         # Time to rework a long, long annotation text line (>=1 sentences).
#         # Clean up extra spaces; protect species names and oddities like "1st ed." and "et al.".
# 
#         $longtext_line =~ s/\s+/ /g;
#         $longtext_line =~ s/\"/\'/g;    # added to keep double-quotes out of annotation text
#         $longtext_line =~ s/^\s+//;
#         $longtext_line =~ s/C\. elegans/C__elegans/g;
#         $longtext_line =~ s/C\. briggsae/C__briggsae/g;
#         $longtext_line =~ s/D\. discoideum/D__discoideum/g;
#         $longtext_line =~ s/H\. sapiens/H__sapiens/g;
#         $longtext_line =~ s/D\. melanogaster/D__melanogaster/g;
#         $longtext_line =~ s/S\. cerevisiae/S__cerevisiae/g;
#         $longtext_line =~ s/S\. pombe/S__pombe/g;
#         $longtext_line =~ s/A\. nidulans/A__nidulans/g;
#         $longtext_line =~ s/E\. coli/E__coli/g;
#         $longtext_line =~ s/B\. subtilis/B__subtilis/g;
#         $longtext_line =~ s/A\. suum/A__suum/g;
#         $longtext_line =~ s/A\. thaliana/A__thaliana/g;
#         $longtext_line =~ s/1st\. ed/1st__ed/g;
#         $longtext_line =~ s/d\. ed/d__ed/g;
#         $longtext_line =~ s/et al\./et al__/g;
#         $longtext_line =~ s/e\. g\./e__g__/g;
#         $longtext_line =~ s/Fig\. /Fig__/g;
#         $longtext_line =~ s/deg\. C /degrees C /g;
#         $longtext_line =~ s/deg\. C\./degrees C\./g;
#         $longtext_line =~ s/[\.]{2,}/\./g;
# 
#         # Having de-periodized species names, split into an annotation sentence array.
# 
#         @longtext_array = split /\. /, $longtext_line;
#      
#         $i = 0;   # (re-)initialize "$i" for annotation sentence array.
# 
#         if ($longtext_array[0] eq "") 
#         {
#             print "Failed to detect longtext as sentence array.\n";
# 
#             # This is a pretty important check against formatting errors.
#         }
#         else 
#         {
#             until ($i > $#longtext_array)
#             { 
# 
#                 # Reformat back from protected periods (e.g., species names) to normal writing.
# 
#                 $longtext_array[$i] =~ s/C__elegans/C\. elegans/g;
#                 $longtext_array[$i] =~ s/C__briggsae/C\. briggsae/g;
#                 $longtext_array[$i] =~ s/D__discoideum/D\. discoideum/g;
#                 $longtext_array[$i] =~ s/H__sapiens/H\. sapiens/g;
#                 $longtext_array[$i] =~ s/D__melanogaster/D\. melanogaster/g;
#                 $longtext_array[$i] =~ s/S__cerevisiae/S\. cerevisiae/g;
#                 $longtext_array[$i] =~ s/S__pombe/S\. pombe/g;
#                 $longtext_array[$i] =~ s/A__nidulans/A\. nidulans/g;
#                 $longtext_array[$i] =~ s/E__coli/E\. coli/g;
#                 $longtext_array[$i] =~ s/B__subtilis/B\. subtilis/g;
#                 $longtext_array[$i] =~ s/A__suum/A\. suum/g;
#                 $longtext_array[$i] =~ s/A__thaliana/A\. thaliana/g;
#                 $longtext_array[$i] =~ s/1st__ed/1st\. ed/g;
#                 $longtext_array[$i] =~ s/d__ed/d\. ed/g;
#                 $longtext_array[$i] =~ s/et al__/et al\. /g;
#                 $longtext_array[$i] =~ s/e__g__/e\. g\./g;
#                 $longtext_array[$i] =~ s/Fig__/Fig\. /g;
#                 $longtext_array[$i] =~ s/[\.]$//;
# 
#                 $annotation_textline = $descript_type . " " . "\"$longtext_array[$i]\.\"";
# 
#                 if ($i == 0)
#                 {
#                     print OUTPUT "Concise_description";
#                     print OUTPUT " ";
#                     print OUTPUT "\"$longtext_array[$i]\.\"\n";
#                 }
# 
#                 elsif ($i > 0) 
#                 {
#                     print OUTPUT "$annotation_textline\n";
#                 }
# 
#                 $i += 1;
# 
#                 if ($i == 1)    # This means that the first line alone gets all the references.
#                                 # This was a quick-and-dirty solution.  It needs to be replaced by a better 
#                                 #   solution involving individually referenced annotation sentences.
#                 {
#                     foreach $reference_to_print (@paper_references)
#                     {
#                         unless ($reference_to_print eq "")
#                         {
#                             print OUTPUT "$descript_type" . " " . "\"$longtext_array[0]\.\" ";
#                             print OUTPUT "$reference_to_print\n";
#                         }
#                     }
#                 }
#             }
#         }
#     }
# 
#     elsif ($reading_in_longtext eq "yes")
#     {
#         $old_longtext_line = $longtext_line;
#         $longtext_line = $old_longtext_line . " " . $input_line;
#     }
# 
#     elsif ($input_line =~ /^Locus :/ || $input_line =~ /^Sequence :/ || $input_line =~ /^CDS :/ || $input_line =~ /^Transcript :/) 
#     {
#         print OUTPUT "\n";
#         print OUTPUT "$input_line\n";
# 
#         $descript_type         = "";
#         @paper_references      = "";
#         $reading_in_references = "yes";
#         $reading_in_longtext   = "no";
#         $longtext_line         = "";
#         @longtext_array        = "";
# 
#     }
# 
# # needs to cope with stuff like:
# # Detailed_description "chi-2" PMID_evidence "11163442"
# 
#     elsif ( ($input_line =~ /^Provisional_description\s+\"\S+\"\s+(\S+_evidence.+)/) && ($reading_in_references eq "yes") )
#     {
#         $indiv_reference = $1;   
#         chomp ($indiv_reference);
#         $descript_type = "Provisional_description";
#         push (@paper_references, $indiv_reference);
#     }
# 
#     elsif ( ($input_line =~ /^Detailed_description\s+\"\S+\"\s+(\S+_evidence.+)/) && ($reading_in_references eq "yes") )
#     {
#         $indiv_reference = $1;
#         chomp ($indiv_reference);
#         $descript_type = "Detailed_description";
#         push (@paper_references, $indiv_reference);
#     }
# 
#     elsif ($input_line =~ /^LongText :/) 
#     {
#         $reading_in_references = "no";
#         $reading_in_longtext = "yes";
#     }
#     elsif ($input_line =~ /^LongText:/)  # quite common typographical error, so this error-check is important
#     {
#         print "Warning!  There is an improperly formatted \'LongText:\' entry in the .ace record!\n";
#         die;
#     }
# }
# 
# close INPUT;
# close OUTPUT;
