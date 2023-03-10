#!/usr/bin/perl -w

# To create full data set ./get_person_ace.pl > full_person.ace
# fixed Fax entries that had an extra \tOther_phone in them
# added &left_fieldPrint(); for those who have left the field
# added ``AND two IS NOT NULL'' to filter those that do not
# wish to be in wormbase.   2002 12 19
#
# Updated to have a delete_Person.ace file to append to beginning
# of file for next time, to delete entries before inserting new
# ones.  Fixed spaces at end or beginning of entries.  Fixed
# middlename problem that wasn't outputting some standard_names
# because they contained the word NULL.  2003 02 20
#
# Added two_wormbase_comment for comments that go to wormbase.
# 2003 02 28
#
# Changed Standard_name to be Full_name.  Created Standard_name
# as a new table (two_thestandardname) and populated it.  
# 2003 03 22
#
# Changed two_standardname (view) to be two_fullname (view),
# copied two_thestandardname to two_standardname, and deleted
# two_thestandardname.  2003 03 24
#
# Changed to no longer print apu's because they were sent by people
# and that may have typos or not exactly match an acedb author or
# not be an elegans paper's author.  2003 04 10
#
# Deleting -O tags because Wen & Raymond don't want forced timestamp
# override, so will create dumps, and compare to previous to create
# -D and insertion lines in another .ace file.  2003 04 30
#
# Added two_hide, so check for existence, if so, skip the entry so
# as not to display on wormbase.  Filter .'s and ,'s from names and
# aka_names.  2003 05 13
#
# Last_verified should not be affected by last attempt to contact
# since that is not verification (for Cecilia)  2004 02 03
#
# Added Institution for Keith, Todd, Cecilia.  2004 03 31
#
############
#
# Modified for Concise Description data for Carol.  2004 05 16
#
# Modified to use single reference box for multiple references
# separated by ``, '' instead of multiple boxes for references.
# Get rid of multiple spaces and leading and trailing spaces.
# Added 5 curators to the list (Paul, Igor, Raymond, Andrei, Wen)
# 2004 05 28
#
# Allow WBPerson\d{8} entries from dumping in Erich's data.
# Made 777 so that nobody can execute this from the concise_desciption.cgi
# directly to create a dump on a website.  2004 06 17
#
# &getConcise(); now adds stuff to a variable to print at the end to be
# able to write WBGene -D for provisional and concise whenever they have
# data.  (presumably to delete everything before repopulating everything,
# for Erich)  2004 08 10
#
# Error file wasn't being created by form, so got rid of it since was 
# outputting errors to STDERR anyway. (probably SELinux error, or just an
# error from migrating to Fedora Core 3)  2005 02 09
#
#
# Repopulated reference data with :
# /home/postgres/work/pgpopulation/concise_description/move_paper_person_reference_to_reference_accession/create_and_populate_tables.pl
# Looks okay.  2005 07 05
#
# Get loci and genes2molecular_names from tazendra instead of sanger.  
# 2005 07 13
#
# Allow Provisional_description to have multiple Curator_confirmed evidence
# data.  For Carol.  2005 10 12
#
# No longer want Date Last Verified where the date is 2004-06-17.  
# For Kimberly.  2005 11 17
#
# If the wbgene is not in loci_all.txt nor genes2molecular_names.txt ERROR 
# message it.  for Kimberly 2006 01 17
#
# &getConcise(); wasn't returning values properly which was creating an extra
# line between the Provisional lines and the extra lines.  2006 01 20
#
# Added a car_con_nodump table which checks whether a gene should be dumped of
# not.  Delete nodump genes from %genes to prevent dumping.  2006 01 27
#
# No longer printing .ace deletions  2006 02 27
#
# Updated to get gene info from postgres instead of loci_all and
# genes2molecular_names  2006 12 19
#
# print gene count for Kimberly.  2009 09 21
#
# Date_last_updated wasn't printing because the SELECT was looking for 
# !~ '2004-06-17', which wasn't proper syntax.  2009 12 22
#
# Updated for DBI, forgot to do it with main batch, Kimberly caught it.
# 2010 07 29
#
# Added Karen as a possible curator.  2010 07 29
#
# Added conversion of Snehalata to WBPerson12884 .  2011 06 05




use strict;
use diagnostics;
use Jex;
use LWP;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 



my $result;
my @dates = ();
my %genes;
my %wbGene;
my %wbGeneBack;

my %evidences;		# any evidence in a curated a field gets a mention in concise description paper evidence 

my %theHash;
my %acePapers;
my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper

my @PGsubparameters = qw( seq fpa fpi bio mol exp oth );	# no longer have phenotype 2005 05 16


  # get sanger conversion
# my $url_locus = "http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt";
# &readCurrentLocus($url_locus);
&getSangerConversion();
&readConvertions;


$result = $dbh->prepare( "SELECT * FROM car_lastcurator WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp DESC;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# $result = $dbh->prepare( "SELECT * FROM car_lastcurator WHERE joinkey ~ 'WBGene' ORDER BY car_timestamp DESC;" );
  # don't include test entry
my %errors_filter;		# some are repeats, so filter them out
while ( my @row = $result->fetchrow ) { 
#   unless ($wbGeneBack{$row[0]}) { $errors_filter{"// ERROR $row[0] not in loci_all.txt\n"}++; }	
#     # if the wbgene is not in loci_all.txt nor genes2molecular_names.txt ERROR message it.  for Kimberly 2006 01 17
  unless ($wbGeneBack{$row[0]}) { $errors_filter{"// ERROR $row[0] not in locus list from nameserver in postgres\n"}++; }	
    # if the wbgene is not in loci_all.txt nor genes2molecular_names.txt ERROR message it.  for Kimberly 2006 01 17
  $genes{$row[0]}++; }
foreach my $error (sort keys %errors_filter) { print "$error"; }	# output gene-locus errors at top of file

my %nodump;
$result = $dbh->prepare( "SELECT * FROM car_con_nodump ORDER BY car_timestamp;" );	# check if flagged not to dump
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  unless ($row[1]) { $row[1] = ''; }
  if ($row[1] eq 'nodump') { $nodump{$row[0]}++; } 	# if set not to dump add to hash
    else { delete $nodump{$row[0]}; } }			# if not set not to dump remove from hash
foreach my $joinkey (keys %nodump) { delete $genes{$joinkey}; }		# if not meant to dump remove from list of genes.  2006 01 27

&readPg();

my @genes = keys %genes;
my $gene_count = scalar(@genes);
print "// $gene_count genes\n\n";			# print gene count for Kimberly.  2009 09 21

# my $count = 0;
foreach my $gene (sort keys %genes) {
#   $count++;
#   if ($count > 100) { last; }
  if ($gene !~ m/^WBGene\d{8}/) {
    if ($wbGene{$gene}) {
      $gene = $wbGene{$gene}; }
    else {
      print STDERR "$gene is not approved by Sanger\n"; next; }
  } # if ($gene !~ m/^WBGene\d{8}/)
  %evidences = ();
  (my $categories, my $ace_delete) = &getCategories($gene); 
  ($ace_delete, my $ace_entry) = &getConcise($gene, $ace_delete);
# DELETE THIS WHEN CATEGORIES SHOULD BE BACK.  right now they are out because not in model (erich)  2004 07 01
#   my $categories = "\n";				# overwrite categories with newline separator

#   unless ($wbGeneBack{$gene}) { # } 			# if the wbgene is not in loci_all.txt nor genes2molecular_names.txt .ace-comment-out the entry before printing it.  for Kimberly 2006 01 17
#     print "// ERROR $gene not in loci_all.txt\n";
  unless ($wbGeneBack{$gene}) { 			# if the wbgene is not in postgres gene info tables
    print "// ERROR $gene not in locus list from nameserver in postgres\n";
    $ace_delete =~ s/\n/\n\/\/ /g; $ace_delete = '// ' . $ace_delete; 
    if ($ace_entry) { if ($ace_entry =~ m/\n/) { $ace_entry =~ s/\n/\n\/\/ /g; $ace_entry = '// ' . $ace_entry; } }
    $categories =~ s/\n/\n\/\/ /g; $categories = '// ' . $categories; }
#   if ($ace_delete) { print "$ace_delete\n"; }		# no longer printing .ace deletions  2006 02 27
  if ($ace_entry) { print "$ace_entry"; }
  if ($categories) { print $categories; }
  print "\n";
} # foreach my $gene (sort keys %genes)

sub readConvertions {
#   my $u = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.cgi";	# changed from 2am dump .txt to on the fly .cgi 2006 08 15
  my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";	# suexec problem with paper2wbpaper.cgi  2007 10 08
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      $convertToWBPaper{$2} = $2;	# map wbpapers to themselves to check that they exist (as opposed to matching for WBPaper, match the full paper exactly)  for Kimberly 2008 04 04
      $convertToWBPaper{$1} = $2; } }
} # sub readConvertions

sub getSangerConversion {
  my @pgtables = qw( gin_sequence gin_synonyms gin_locus );		# synonyms before locus so locus can overwrite synonyms
  foreach my $table (@pgtables) {                                       # updated to get values from postgres 2006 12 19
    my $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      my $wbgene = 'WBGene' . $row[0];
      $wbGene{$row[1]} = $wbgene;
      $wbGeneBack{$wbgene} = $row[1]; } }
  $wbGene{'test-1'} = 'WBGene00000000';
  $wbGeneBack{'WBGene00000000'} = 'test-1';
} # sub getSangerConversion

sub readPg {
  my $result = $dbh->prepare( "SELECT * FROM car_lastcurator ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $found = $row[1];                                  # curator from car_lastcurator
    my $joinkey = $row[0];
    if ($theHash{$joinkey}{gene}{html_value}) { next; }	# if already did this gene, skip
    $theHash{$joinkey}{gene}{html_value} = $joinkey;
  } # while (my @row = $result->fetchrow)

#   $result = $dbh->prepare( "SELECT * FROM car_con_maindata WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  $result = $dbh->prepare( "SELECT * FROM car_con_maindata ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    if ($theHash{$joinkey}{concise}) { next; }	# skip entry if already have the latest one
    if ($row[1]) {
      my $concise = &clearSpaces($row[1]);
      $theHash{$joinkey}{concise} = $concise; }
    else { $theHash{$joinkey}{concise} = ''; }
  }

#   $result = $dbh->prepare( "SELECT * FROM car_con_ref_curator WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  $result = $dbh->prepare( "SELECT * FROM car_con_ref_curator ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
#     if ($theHash{$joinkey}{evidences}{curator}) { next; }	# uncomment this to only get the latest curator for carol  2005 10 12
    my $found = $row[1];
    if ($found) {
      $found = &clearSpaces($found);
      $found = &convertPerson($found, $joinkey);
      $theHash{$joinkey}{evidences}{curator}{Curator_confirmed}{$found}++; }
    else { $theHash{$joinkey}{evidences}{curator}{Curator_confirmed}{NODATA}++;  }
  }

    # get most of the evidence from reference field
  my $table = "car_con_ref_reference";
#   $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  $result = $dbh->prepare( "SELECT * FROM $table ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    if ($theHash{$joinkey}{evidences}{reference}) { next; }
    my $found = $row[1];
    if ($found) {
      $found = &clearSpaces($found);
      my @found = split/, /, $found;
      foreach my $reference (@found) { 
        $reference = &clearReferenceTrail($reference);
        if ($reference =~ m/WBPerson/) {
          my $person = &convertPerson($reference, $joinkey); 
          $theHash{$joinkey}{evidences}{reference}{Person_evidence}{$person}++; } 
        elsif ( ($reference =~ m/pmid.*_.*/) || ($reference =~ m/cgc.*_.*/) ) {
          $theHash{$joinkey}{evidences}{reference}{Gene_regulation_evidence}{$reference}++; }
        elsif ( $reference =~ m/^GO:/ ) {
          $theHash{$joinkey}{evidences}{reference}{GO_term_evidence}{$reference}++; }
        elsif ( $reference =~ m/^Expr/ ) {
          $theHash{$joinkey}{evidences}{reference}{Expr_pattern_evidence}{$reference}++; }
        elsif ( ($reference =~ m/^Aff_/) || ($reference =~ m/^SMD_/) ) {
          $theHash{$joinkey}{evidences}{reference}{Microarray_results_evidence}{$reference}++; }
        elsif ( $reference =~ m/^WBRNAi/ ) {
          $theHash{$joinkey}{evidences}{reference}{RNAi_evidence}{$reference}++; }
        else {
#           if ($reference =~ m/^WBPaper/) {
#             $theHash{$joinkey}{evidences}{reference}{Paper_evidence}{$reference}++; }
          if ($convertToWBPaper{$reference}) { 			# conver to WBPaper or print ERROR
            my $wbpaper = $convertToWBPaper{$reference};
            $theHash{$joinkey}{evidences}{reference}{Paper_evidence}{$wbpaper}++; }
          else { print "// ERROR No conversion for $reference : $joinkey\n"; }
        }
      } # foreach my $reference (@found) 
    } # if ($found)
    else { $theHash{$joinkey}{evidences}{reference}{somethingBlank}{NODATA}++; }
  } # while (my @row = $result->fetchrow)

  $table = "car_con_ref_accession";				# get accession evidence
#   $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  $result = $dbh->prepare( "SELECT * FROM $table ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    if ($theHash{$joinkey}{evidences}{accession}) { next; }
    my $found = $row[1];
    if ($found) { 
      $found = &clearSpaces($found);
      my @found = split/, /, $found;
      foreach my $reference (@found) { 
        $theHash{$joinkey}{evidences}{accession}{Accession_evidence}{$reference}++; }
    } else { $theHash{$joinkey}{evidences}{accession}{Accession_evidence}{NODATA}++; }
  } # while (my @row = $result->fetchrow)

  $table = "car_con_last_verified";				# get last verified timestamp 
#   $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
#   $result = $dbh->prepare( "SELECT * FROM $table ORDER BY car_timestamp DESC;" );
    # No longer want Date Last Verified where the date is 2004-06-17.  For Kimberly.  2005 11 17
  $result = $dbh->prepare( "SELECT * FROM $table WHERE car_timestamp < '2004-06-17' OR car_timestamp > '2004-06-17' ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   print "SELECT * FROM $table WHERE car_timestamp < '2004-06-17' OR car_timestamp > '2004-06-17' ORDER BY car_timestamp DESC;\n" ;
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    if ($theHash{$joinkey}{evidences}{last_verified}) { next; }
    my $found = $row[2];
    if ($found) { 
      $found = &clearSpaces($found);
      my ($reference) = $found =~ m/^(\d{4}.\d{2}.\d{2})/;
      $theHash{$joinkey}{evidences}{last_verified}{Date_last_updated}{$reference}++; 
    }
  } # while (my @row = $result->fetchrow)

#   $result = $dbh->prepare( "SELECT * FROM car_ext_maindata WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  $result = $dbh->prepare( "SELECT * FROM car_ext_maindata ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my $joinkey = $row[0];
    if ($theHash{$joinkey}{extra}) { next; }
    my $found = $row[1];
    if ($found) {
      $found =~ s/\s+/ /g;                                          # switch out periods and stuff (erich)
      $found =~ s/\"/\'/g;    # added to keep double-quotes out of annotation text
      $found =~ s/^\s+//;
      $found =~ s/C\. elegans/C__elegans/g;
      $found =~ s/C\. briggsae/C__briggsae/g; 
      $found =~ s/D\. discoideum/D__discoideum/g;
      $found =~ s/H\. sapiens/H__sapiens/g;
      $found =~ s/D\. melanogaster/D__melanogaster/g;
      $found =~ s/S\. cerevisiae/S__cerevisiae/g;
      $found =~ s/S\. pombe/S__pombe/g;
      $found =~ s/A\. nidulans/A__nidulans/g;
      $found =~ s/E\. coli/E__coli/g; 
      $found =~ s/B\. subtilis/B__subtilis/g;
      $found =~ s/A\. suum/A__suum/g;
      $found =~ s/A\. thaliana/A__thaliana/g;
      $found =~ s/1st\. ed/1st__ed/g;
      $found =~ s/d\. ed/d__ed/g;
      $found =~ s/et al\./et al__/g;
      $found =~ s/e\. g\./e__g__/g;
      $found =~ s/e\.g\./e_g__/g;
      $found =~ s/i\.e\./i_e__/g;
      $found =~ s/i\. e\./i__e__/g;
      $found =~ s/Fig\. /Fig__/g;
      $found =~ s/deg\. C /degrees C /g;
      $found =~ s/deg\. C\./degrees C\./g;
      $found =~ s/[\.]{2,}/\./g;
      my @found = split/\. /, $found;
      foreach my $found2 (@found) {
        if ($found2 =~ m/C__elegans/) { $found2 =~ s/C__elegans/C\. elegans/g; } # switch back
        if ($found2 =~ m/C__briggsae/) { $found2 =~ s/C__briggsae/C\. briggsae/g; }
        if ($found2 =~ m/D__discoideum/) { $found2 =~ s/D__discoideum/D\. discoideum/g; }
        if ($found2 =~ m/H__sapiens/) { $found2 =~ s/H__sapiens/H\. sapiens/g; }
        if ($found2 =~ m/D__melanogaster/) { $found2 =~ s/D__melanogaster/D\. melanogaster/g; }
        if ($found2 =~ m/S__cerevisiae/) { $found2 =~ s/S__cerevisiae/S\. cerevisiae/g; }
        if ($found2 =~ m/S__pombe/) { $found2 =~ s/S__pombe/S\. pombe/g; }
        if ($found2 =~ m/A__nidulans/) { $found2 =~ s/A__nidulans/A\. nidulans/g; }
        if ($found2 =~ m/E__coli/) { $found2 =~ s/E__coli/E\. coli/g; }
        if ($found2 =~ m/B__subtilis/) { $found2 =~ s/B__subtilis/B\. subtilis/g; }
        if ($found2 =~ m/A__suum/) { $found2 =~ s/A__suum/A\. suum/g; }
        if ($found2 =~ m/A__thaliana/) { $found2 =~ s/A__thaliana/A\. thaliana/g; }
        if ($found2 =~ m/1st__ed/) { $found2 =~ s/1st__ed/1st\. ed/g; }
        if ($found2 =~ m/d__ed/) { $found2 =~ s/d__ed/d\. ed/g; }
        if ($found2 =~ m/et al__/) { $found2 =~ s/et al__/et al\. /g; }
        if ($found2 =~ m/e__g__/) { $found2 =~ s/e__g__/e\. g\./g; }
        if ($found2 =~ m/e_g__/) { $found2 =~ s/e_g__/e\.g\./g; }
        if ($found2 =~ m/i_e__/) { $found2 =~ s/i_e__/i\.e\./g; }
        if ($found2 =~ m/i__e__/) { $found2 =~ s/i__e__/i\. e\./g; }
        if ($found2 =~ m/Fig__/) { $found2 =~ s/Fig__/Fig\. /g; }
        if ($found2 =~ m/[\.]$/) { $found2 =~ s/[\.]$//; }
        push @{ $theHash{$joinkey}{extra} }, $found2;
      } # foreach my $found2 (@found)
    } # if ($found) 
    else { push @{ $theHash{$joinkey}{extra} }, ''; }	# if there's no data, don't get next oldest field with data
  } # while (my @row = $result->fetchrow)

  
  foreach my $sub (@PGsubparameters) {
    # get highest row value (not by timestamp because it could have a single row edited later
    # that's not the highest row
#     $result = $dbh->prepare( "SELECT * FROM car_${sub}_maindata WHERE joinkey = '$gene' AND car_order = $i ORDER BY car_timestamp DESC;" );
    $result = $dbh->prepare( "SELECT * FROM car_${sub}_maindata ORDER BY car_timestamp DESC;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row=$result->fetchrow) {
      my $value = ''; 
      if ($row[2]) { $value = &clearSpaces($row[2]); }
      my $car_order = $row[1];
      my $joinkey = $row[0];
      if ($theHash{$joinkey}{$sub}{$car_order}{html_value}) { next; }	# skip entry if already have the latest one
      $theHash{$joinkey}{$sub}{$car_order}{html_value} = $value; }
  
    my @subtypes = qw( curator reference accession );
    foreach my $type (@subtypes) {
      if ( ($sub ne 'seq') && ($type eq 'accession') ) { next; }	# skip accession if not sequence (which is the only one that has it)
#       $result = $dbh->prepare( "SELECT * FROM car_${sub}_ref_$type WHERE joinkey = '$gene' AND car_order = $i ORDER BY car_timestamp DESC;" );
      $result = $dbh->prepare( "SELECT * FROM car_${sub}_ref_$type ORDER BY car_timestamp DESC;" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row=$result->fetchrow) {
        my $joinkey = $row[0];
        my $car_order = $row[1];
        if ($theHash{$joinkey}{$sub}{$car_order}{$type}) { next; }	# skip entry if already have the latest one
        if ($row[2]) {							# if there's a value
          my $value = ''; 
          if ($row[2]) { $value = &clearSpaces($row[2]); }
          $theHash{$joinkey}{$sub}{$car_order}{$type} = $value; }	# store it
        else {
          $theHash{$joinkey}{$sub}{$car_order}{$type} = ''; }		# else store a blank
      } # while (my @row=$result->fetchrow)
    } # foreach my $type (@subtypes)
  } # foreach my $sub (@PGsubparameters)
} # sub readPg

sub getCategories {
  my $categories = '';
  my $gene = shift;
  my %aceTrans;
  $aceTrans{seq} = "Sequence_features";
  $aceTrans{fpa} = "Functional_pathway";
  $aceTrans{fpi} = "Functional_physical_interaction";
  $aceTrans{bio} = "Biological_process";
  $aceTrans{mol} = "Molecular_function";
  $aceTrans{exp} = "Expression";
  $aceTrans{oth} = "Other_description";

  my $ace_delete = '';
  my %delHash = ();

  foreach my $sub (@PGsubparameters) {
    foreach my $i ( sort keys %{ $theHash{$gene}{$sub}} ) {
      next unless ($i =~ m/^\d+$/) ;
      if ($theHash{$gene}{$sub}{$i}{curator}) {
        my $curator = $theHash{$gene}{$sub}{$i}{curator};
        $curator = &convertPerson($curator, $gene);
        my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
									# use Curator_confirmed for drop-down curator data
        $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tCurator_confirmed\t\"$curator\"\n"; }	

      if ($theHash{$gene}{$sub}{$i}{reference}) {
        my @found = split/, /, $theHash{$gene}{$sub}{$i}{reference};
        foreach my $reference (@found) { 
          $reference = &clearReferenceTrail($reference);
          if ($reference =~ m/WBPerson/) {
            my $person = &convertPerson($reference, $gene); 
            my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tPerson_evidence\t\"$person\"\n"; }
          elsif ( ($reference =~ m/pmid.*_.*/) || ($reference =~ m/cgc.*_.*/) ) {
            my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tGene_regulation_evidence\t\"$reference\"\n"; }
          elsif ( $reference =~ m/^GO:/ ) {
            my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tGO_term_evidence\t\"$reference\"\n"; }
          elsif ( $reference =~ m/^Expr/ ) {
            my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tExpr_pattern_evidence\t\"$reference\"\n"; }
          elsif ( ($reference =~ m/^Aff_/) || ($reference =~ m/^SMD_/) ) {
            my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tMicroarray_results_evidence\t\"$reference\"\n"; }
          elsif ( $reference =~ m/^WBRNAi/ ) {
            my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tRNAi_evidence\t\"$reference\"\n"; }
          else {
#             if ($reference =~ m/^WBPaper/) {
#               my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
#               $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tPaper_evidence\t\"$reference\"\n"; }
            if ($convertToWBPaper{$reference}) { 			# convert to WBPaper or print ERROR
              my $wbpaper = $convertToWBPaper{$reference};
              my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
              $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tPaper_evidence\t\"$wbpaper\"\n"; }
            else { print "// ERROR No conversion for $reference : $gene\n"; }
          }
        } # foreach my $reference (@found) 
      } # if ($theHash{$gene}{$sub}{$i}{reference})

      if ($theHash{$gene}{$sub}{$i}{accession}) {		# don't need to check for seq since only seq gets accession in %theHash{$gene} above
        my @found = split/, /, $theHash{$gene}{$sub}{$i}{accession};
        foreach my $reference (@found) { 
          my $del_line = "-D $aceTrans{$sub}"; $delHash{$del_line}++; 
          $categories .= "$aceTrans{$sub}\t\"$theHash{$gene}{$sub}{$i}{html_value}\"\tAccession_evidence\t\"$reference\"\n"; }
      } # if ($theHash{$gene}{$sub}{$i}{accession})

    } # foreach my $i (@{ sort keys %{ $theHash{$gene}{$sub}} })
  } # foreach my $sub (@PGsubparameters)
  $categories .= "\n";

  foreach my $line (sort keys %delHash) { $ace_delete .= $line . "\n"; }
  return ($categories, $ace_delete);
} # sub getCategories

sub getConcise {
  my ($gene, $other_ace_delete) = @_;
  my $ace_entry = '';
  my $ace_delete = '';
  my $ace_provisional = '';

  unless ($theHash{$gene}{concise}) { print "// ERROR : NO Concise Description for $gene\n"; return 0; }

  my $concise = $theHash{$gene}{concise};

  $ace_entry .= "Gene : \"$gene\"\n"; 
  $ace_entry .= "Concise_description\t\"$concise\"\n"; 
  $ace_delete .= "Gene : \"$gene\"\n"; 
  $ace_delete .= "-D Concise_description\n"; 

  foreach my $input_field ( sort keys %{ $theHash{$gene}{evidences} } ) {			# append to print each evidence
#       $theHash{$joinkey}{evidences}{last_verified}{Date_last_updated}{$reference}++; 
    foreach my $evidence_type ( sort keys %{ $theHash{$gene}{evidences}{$input_field} } ) {
      foreach my $evidence ( sort keys %{ $theHash{$gene}{evidences}{$input_field}{$evidence_type} } ) {
        unless ($evidence eq 'NODATA') { 
          $ace_entry .= "Provisional_description\t\"$concise\"\t$evidence_type\t\"$evidence\"\n";
          $ace_provisional .= "Provisional_description\t\"$concise\"\t$evidence_type\t\"$evidence\"\n"; 
        } } } } 

  if ($theHash{$gene}{extra}) {
    foreach my $line (@{ $theHash{$gene}{extra} }) {
      if ($line) {				# only print a line if there's data (don't print if used to be and then replaced with blank)
        $ace_entry .= "Provisional_description\t\"$line.\"\n"; 
        $ace_provisional .= "Provisional_description\t\"$line.\"\n"; 
      } } }

  if ($ace_provisional) { $ace_delete .= "-D Provisional_description\n"; }
  if ($other_ace_delete) { $ace_delete .= $other_ace_delete; }
  return ($ace_delete, $ace_entry);
} # sub getConcise

sub convertPerson {
  my ($found, $gene) = @_;
unless ($found) { print "NO PERSON $found GENE $gene END\n"; }
  $found = &clearSpaces($found);
  if ($found =~ m/WBPerson\d+/) { 1; }
  elsif ($found =~ m/Juancarlos/) { $found = 'WBPerson1823'; }
  elsif ($found =~ m/Carol/) { $found = 'WBPerson48'; }
  elsif ($found =~ m/Ranjana/) { $found = 'WBPerson324'; }
  elsif ($found =~ m/Kimberly/) { $found = 'WBPerson1843'; }
  elsif ($found =~ m/Snehalata/) { $found = 'WBPerson12884'; }
  elsif ($found =~ m/Karen/) { $found = 'WBPerson712'; }
  elsif ($found =~ m/Erich/) { $found = 'WBPerson567'; }
  elsif ($found =~ m/Paul/) { $found = 'WBPerson625'; }
  elsif ($found =~ m/Igor/) { $found = 'WBPerson22'; }
  elsif ($found =~ m/Raymond/) { $found = 'WBPerson363'; }
  elsif ($found =~ m/Andrei/) { $found = 'WBPerson480'; }
  elsif ($found =~ m/Wen/) { $found = 'WBPerson101'; }
  elsif ($found =~ m/James Kramer/) { $found = 'WBPerson345'; } 
  elsif ($found =~ m/Massimo Hilliard/) { $found = 'WBPerson258'; } 
  elsif ($found =~ m/Verena Gobel/) { $found = 'WBPerson204'; } 
  elsif ($found =~ m/Graham Goodwin/) { $found = 'WBPerson2104'; }
  elsif ($found =~ m/Thomas Burglin/) { $found = 'WBPerson83'; }  
  elsif ($found =~ m/Thomas Blumenthal/) { $found = 'WBPerson71'; }  
  elsif ($found =~ m/Jonathan Hodgkin/) { $found = 'WBPerson261'; } 
  elsif ($found =~ m/Marie Causey/) { $found = 'WBPerson638'; } 
  elsif ($found =~ m/Mark Edgley/) { $found = 'WBPerson154'; } 
  elsif ($found =~ m/Alison Woollard/) { $found = 'WBPerson699'; } 
  elsif ($found =~ m/Ian Hope/) { $found = 'WBPerson266'; } 
  elsif ($found =~ m/Geraldine Seydoux/) { $found = 'WBPerson575'; } 
  elsif ($found =~ m/Marta Kostrouchova/) { $found = 'WBPerson344'; } 
  elsif ($found =~ m/Malcolm Kennedy/) { $found = 'WBPerson2522'; }
  elsif ($found =~ m/Berndt Mueller/) { $found = 'WBPerson1874'; }
  elsif ($found =~ m/Steven Kleene/) { $found = 'WBPerson327'; } 
  elsif ($found =~ m/Michael Koelle/) { $found = 'WBPerson330'; } 
  elsif ($found =~ m/Giovanni Lesa/) { $found = 'WBPerson365'; } 
  elsif ($found =~ m/Benjamin Leung/) { $found = 'WBPerson366'; } 
  elsif ($found =~ m/Robyn Lints/) { $found = 'WBPerson377'; } 
  elsif ($found =~ m/Leo Liu/) { $found = 'WBPerson381'; } 
  elsif ($found =~ m/Margaret MacMorris/) { $found = 'WBPerson395'; } 
  elsif ($found =~ m/Jacob Varkey/) { $found = 'WBPerson669'; }
  elsif ($found =~ m/Kim McKim/) { $found = 'WBPerson1264'; }
  elsif ($found =~ m/Bob Johnsen/) { $found = 'WBPerson1119'; }
  elsif ($found =~ m/Gerhard Schad/) { $found = 'WBPerson553'; }
  elsif ($found =~ m/David Baillie/) { $found = 'WBPerson36'; }
  else { print STDERR "$found is not a valid curator in $gene\n"; }
  return $found;
} # sub convertPerson


sub clearReferenceTrail {
  my $cleaning = shift;
  if ($cleaning =~ m/\s$/) { $cleaning =~ s/\s$//g; }
  if ($cleaning =~ m/\.$/) { $cleaning =~ s/\.$//g; }
  if ($cleaning =~ m/,$/) { $cleaning =~ s/,$//g; }
  return $cleaning;
} # sub clearReferenceTrail

sub clearSpaces {
  my $cleaning = shift;
  if ($cleaning =~ m//) { $cleaning =~ s///g; }
  if ($cleaning =~ m/\n/) { $cleaning =~ s/\n/ /g; }
  if ($cleaning =~ m/\s+/) { $cleaning =~ s/\s+/ /g; }
  if ($cleaning =~ m/^\s/) { $cleaning =~ s/^\s//g; }
  if ($cleaning =~ m/\s$/) { $cleaning =~ s/\s$//g; }
  return $cleaning;
} # sub clearSpaces

__END__

### DEPRECATED ###
sub oldgetCategories {
  my $categories = '';
  my $gene = shift;
  my @PGsubparameters = qw( seq fpa fpi bio mol exp oth );	# no longer have phenotype 2005 05 16
  my %aceTrans;
  $aceTrans{seq} = "Sequence_features";
  $aceTrans{fpa} = "Functional_pathway";
  $aceTrans{fpi} = "Functional_physical_interaction";
  $aceTrans{bio} = "Biological_process";
  $aceTrans{mol} = "Molecular_function";
  $aceTrans{exp} = "Expression";
  $aceTrans{oth} = "Other_description";
  my $u = "http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    my ($three, $wb) = $_ =~ m/^(.*?),(.*?),/;      # added to convert genes
    $wbGene{$three} = $wb;                      # from 3-letter to WBGene type
    $wbGeneBack{$wb} = $three;                  # from WBGene to 3-letter type
    if ($_ =~ m/,([^,]*?) ,CGC approved$/) {        # 2004 05 05
      my @things = split/ /, $1;
      foreach my $thing (@things) {
        if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) { $wbGene{$thing} = $wb; $wbGene{$wb} = $thing; } } }
  } # foreach (@tmp)
  $wbGene{'test-1'} = 'WBGene00000000';
  $wbGeneBack{'WBGene00000000'} = 'test-1';

  my $result = $dbh->prepare( "SELECT * FROM car_lastcurator WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow;
  my $found = $row[1];                                  # curator from car_lastcurator
  if ($found eq '') {
    print "Entry $gene not found, please click ``back'' and create it.\n"; return; }
  else {
    %theHash = ();
    $theHash{gene}{html_value} = $gene;

# lifted from form, not needed in categories section
#     my $result=$dbh->prepare( "SELECT * FROM car_con_maindata WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" );
#     my @row=$result->fetchrow; $theHash{con}{html_value} = $row[1];
#     $result=$dbh->prepare( "SELECT * FROM car_con_ref_curator WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" );
#     @row=$result->fetchrow; $theHash{con}{curator} = $row[1];
#     $result=$dbh->prepare( "SELECT * FROM car_con_ref_paper WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" );
#     @row=$result->fetchrow; $theHash{con}{paper} = $row[1];
#     $result=$dbh->prepare( "SELECT * FROM car_con_ref_person WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" );
#     @row=$result->fetchrow; $theHash{con}{person} = $row[1];
#     $result=$dbh->prepare( "SELECT * FROM car_ext_maindata WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" );
#     @row=$result->fetchrow; $theHash{ext}{html_value} = $row[1];
#     $result=$dbh->prepare( "SELECT * FROM car_ext_ref_curator WHERE joinkey = '$joinkey' ORDER BY car_timestamp DESC;" );
#     @row=$result->fetchrow; $theHash{ext}{curator} = $row[1];
  
    foreach my $sub (@PGsubparameters) {
        # get highest row value (not by timestamp because it could have a single row edited later
        # that's not the highest row
      $result = $dbh->prepare( "SELECT * FROM car_${sub}_maindata WHERE joinkey = '$gene' ORDER BY car_order DESC;" );
      my @row=$result->fetchrow; $theHash{$sub}{num_pg} = $row[1];
      next unless ($theHash{$sub}{num_pg});
      for my $i ( 1 .. $theHash{$sub}{num_pg} ) {
        $result = $dbh->prepare( "SELECT * FROM car_${sub}_maindata WHERE joinkey = '$gene' AND car_order = $i ORDER BY car_timestamp DESC;" );
        my @row=$result->fetchrow;
        $row[2] = &clearSpaces($row[2]);
        $theHash{$sub}{$row[1]}{html_value} = $row[2];
        my @subtypes = qw( curator reference accession );

        foreach my $type (@subtypes) {
          if ( ($sub ne 'seq') && ($type eq 'accession') ) { next; }	# skip accession if not sequence (which is the only one that has it)
          $result = $dbh->prepare( "SELECT * FROM car_${sub}_ref_$type WHERE joinkey = '$gene' AND car_order = $i ORDER BY car_timestamp DESC;" );
          my @row=$result->fetchrow;
          if ($row[2]) { 
            $row[2] = &clearSpaces($row[2]);
            $theHash{$sub}{$row[1]}{$type} = $row[2]; }
        } # foreach my $type (@subtypes)

      } # for my $i ( 1 .. $theHash{$sub}{num} )
    } # foreach my $sub (@PGsubparameters)
  } # else # if ($found eq '') 

  foreach my $sub (@PGsubparameters) {
    foreach my $i ( sort keys %{ $theHash{$sub}} ) {
      next unless ($i =~ m/^\d+$/) ;
      if ($theHash{$sub}{$i}{curator}) {
        $gene .= $sub . "curator";
        my $curator = &convertPerson($theHash{$sub}{$i}{curator}, $gene);
        $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tCurator_confirmed\t\"$curator\"\n"; }	# use Curator_confirmed for drop-down curator data

      if ($theHash{$sub}{$i}{reference}) {
        my @found = split/, /, $theHash{$sub}{$i}{reference};
        foreach my $reference (@found) { 
          $reference =~ s/\.$//g;				# take out dots at the end that are typos
          if ($reference =~ m/WBPerson/) {
            my $person = &convertPerson($reference, $gene); 
            $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tPerson_evidence\t\"$person\"\n"; }
          elsif ( ($reference =~ m/pmid.*_.*/) || ($reference =~ m/cgc.*_.*/) ) {
            $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tGene_regulation_evidence\t\"$reference\"\n"; }
          elsif ( $reference =~ m/^GO:/ ) {
            $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tGO_term_evidence\t\"$reference\"\n"; }
          elsif ( $reference =~ m/^Expr/ ) {
            $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tExpr_pattern_evidence\t\"$reference\"\n"; }
          elsif ( ($reference =~ m/^Aff_/) || ($reference =~ m/^SMD_/) ) {
            $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tMicroarray_results_evidence\t\"$reference\"\n"; }
          elsif ( $reference =~ m/^WBRNAi/ ) {
            $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tRNAi_evidence\t\"$reference\"\n"; }
          else {
#             if ($reference =~ m/^WBPaper/) {
#               $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tPaper_evidence\t\"$reference\"\n"; }
            if ($convertToWBPaper{$reference}) { 			# conver to WBPaper or print ERROR
              my $wbpaper = $convertToWBPaper{$reference};
              $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tPaper_evidence\t\"$wbpaper\"\n"; }
            else { print "// ERROR No conversion for $reference : $gene\n"; }
          }
        } # foreach my $reference (@found) 
      } # if ($theHash{$sub}{$i}{reference})

      if ($theHash{$sub}{$i}{accession}) {		# don't need to check for seq since only seq gets accession in %theHash above
        my @found = split/, /, $theHash{$sub}{$i}{accession};
        foreach my $reference (@found) { 
          $categories .= "$aceTrans{$sub}\t\"$theHash{$sub}{$i}{html_value}\"\tAccession_evidence\t\"$reference\"\n"; }
      } # if ($theHash{$sub}{$i}{accession})

    } # foreach my $i (@{ sort keys %{ $theHash{$sub}} })
  } # foreach my $sub (@PGsubparameters)
  $categories .= "\n";
  return ($categories);
} # sub oldgetCategories

sub oldgetConcise {
  my ($gene) = shift;
  my $result = $dbh->prepare( "SELECT * FROM car_con_maindata WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
  my @row = $result->fetchrow;
  my $found = $row[1];
  my $ace_entry = '';
  my $ace_delete = '';
  my $ace_provisional = '';
  if ($found) {
    $found = &clearSpaces($found);
    my $concise = $found;
    $ace_entry .= "Gene : \"$gene\"\n"; 
    $ace_entry .= "Concise_description\t\"$concise\"\n"; 
    $ace_delete .= "Gene : \"$gene\"\n"; 
    $ace_delete .= "-D Concise_description\n"; 
    $result = $dbh->prepare( "SELECT * FROM car_con_ref_curator WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
    @row = $result->fetchrow;
    $found = $row[1];
    if ($found) { $found = &convertPerson($found, $gene);
      $evidences{Curator_confirmed}{$found}++; }

      # get most of the evidence from reference field
    my $table = "car_con_ref_reference";
    $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
    @row = $result->fetchrow;
    $found = $row[1];
    if ($found) { 
      $found =~ s/\s+/ /g; $found =~ s/^\s//g; $found =~ s/\s$//g;
      my @found = split/, /, $found;
      foreach my $reference (@found) { 
        $reference = &clearReferenceTrail($reference);
        if ($reference =~ m/WBPerson/) {
          my $person = &convertPerson($reference, $gene); 
          $evidences{Person_evidence}{$person}++; } 
        elsif ( ($reference =~ m/pmid.*_.*/) || ($reference =~ m/cgc.*_.*/) ) {
          $evidences{Gene_regulation_evidence}{$reference}++; }
        elsif ( $reference =~ m/^GO:/ ) {
          $evidences{GO_term_evidence}{$reference}++; }
        elsif ( $reference =~ m/^Expr/ ) {
          $evidences{Expr_pattern_evidence}{$reference}++; }
        elsif ( ($reference =~ m/^Aff_/) || ($reference =~ m/^SMD_/) ) {
          $evidences{Microarray_results_evidence}{$reference}++; }
        elsif ( $reference =~ m/^WBRNAi/ ) {
          $evidences{RNAi_evidence}{$reference}++; }
        else {
#           if ($reference =~ m/^WBPaper/) {
#             $evidences{Paper_evidence}{$reference}++; }
          if ($convertToWBPaper{$reference}) { 			# conver to WBPaper or print ERROR
            my $wbpaper = $convertToWBPaper{$reference};
            $evidences{Paper_evidence}{$wbpaper}++; }
          else { print "// ERROR No conversion for $reference : $gene\n"; }
        }
      } # foreach my $reference (@found) 
    } # if ($found)

    $table = "car_con_ref_accession";				# get accession evidence
    $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
    @row = $result->fetchrow;
    $found = $row[1];
    if ($found) { 
      $found =~ s/\s+/ /g; $found =~ s/^\s//g; $found =~ s/\s$//g;
      my @found = split/, /, $found;
      foreach my $reference (@found) { 
        $evidences{Accession_evidence}{$reference}++; } 
    }

    $table = "car_con_last_verified";				# get last verified timestamp 
    $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
    @row = $result->fetchrow;
    $found = $row[2];
    if ($found) { 
      $found =~ s/\s+/ /g; $found =~ s/^\s//g; $found =~ s/\s$//g;
      my ($reference) = $found =~ m/^(\d{4}.\d{2}.\d{2})/;
      $evidences{Date_last_updated}{$reference}++; 
    }

    foreach my $evidence_type ( sort keys %evidences ) {	# append to print each evidence
      foreach my $evidence ( sort keys %{ $evidences{$evidence_type} } ) {
        $ace_entry .= "Provisional_description\t\"$concise\"\t$evidence_type\t\"$evidence\"\n";
        $ace_provisional .= "Provisional_description\t\"$concise\"\t$evidence_type\t\"$evidence\"\n"; 
      } # foreach my $evidence ( sort keys %{ $evidences{$evidence_type} } )
    } # foreach my $evidence ( sort keys %evidences )

      # begin extra sentences
    $result = $dbh->prepare( "SELECT * FROM car_ext_maindata WHERE joinkey = \'$gene\' ORDER BY car_timestamp DESC;" );
    @row = $result->fetchrow;
    $found = $row[1];
    if ($found) { 
      $found =~ s/\s+/ /g;                                          # switch out periods and stuff (erich)
      $found =~ s/\"/\'/g;    # added to keep double-quotes out of annotation text
      $found =~ s/^\s+//;
      $found =~ s/C\. elegans/C__elegans/g;
      $found =~ s/C\. briggsae/C__briggsae/g; 
      $found =~ s/D\. discoideum/D__discoideum/g;
      $found =~ s/H\. sapiens/H__sapiens/g;
      $found =~ s/D\. melanogaster/D__melanogaster/g;
      $found =~ s/S\. cerevisiae/S__cerevisiae/g;
      $found =~ s/S\. pombe/S__pombe/g;
      $found =~ s/A\. nidulans/A__nidulans/g;
      $found =~ s/E\. coli/E__coli/g; 
      $found =~ s/B\. subtilis/B__subtilis/g;
      $found =~ s/A\. suum/A__suum/g;
      $found =~ s/A\. thaliana/A__thaliana/g;
      $found =~ s/1st\. ed/1st__ed/g;
      $found =~ s/d\. ed/d__ed/g;
      $found =~ s/et al\./et al__/g;
      $found =~ s/e\. g\./e__g__/g;
      $found =~ s/e\.g\./e_g__/g;
      $found =~ s/i\.e\./i_e__/g;
      $found =~ s/i\. e\./i__e__/g;
      $found =~ s/Fig\. /Fig__/g;
      $found =~ s/deg\. C /degrees C /g;
      $found =~ s/deg\. C\./degrees C\./g;
      $found =~ s/[\.]{2,}/\./g;
      my @found = split/\. /, $found;
      foreach my $found2 (@found) {
        if ($found2 =~ m/C__elegans/) { $found2 =~ s/C__elegans/C\. elegans/g; } # switch back
        if ($found2 =~ m/C__briggsae/) { $found2 =~ s/C__briggsae/C\. briggsae/g; }
        if ($found2 =~ m/D__discoideum/) { $found2 =~ s/D__discoideum/D\. discoideum/g; }
        if ($found2 =~ m/H__sapiens/) { $found2 =~ s/H__sapiens/H\. sapiens/g; }
        if ($found2 =~ m/D__melanogaster/) { $found2 =~ s/D__melanogaster/D\. melanogaster/g; }
        if ($found2 =~ m/S__cerevisiae/) { $found2 =~ s/S__cerevisiae/S\. cerevisiae/g; }
        if ($found2 =~ m/S__pombe/) { $found2 =~ s/S__pombe/S\. pombe/g; }
        if ($found2 =~ m/A__nidulans/) { $found2 =~ s/A__nidulans/A\. nidulans/g; }
        if ($found2 =~ m/E__coli/) { $found2 =~ s/E__coli/E\. coli/g; }
        if ($found2 =~ m/B__subtilis/) { $found2 =~ s/B__subtilis/B\. subtilis/g; }
        if ($found2 =~ m/A__suum/) { $found2 =~ s/A__suum/A\. suum/g; }
        if ($found2 =~ m/A__thaliana/) { $found2 =~ s/A__thaliana/A\. thaliana/g; }
        if ($found2 =~ m/1st__ed/) { $found2 =~ s/1st__ed/1st\. ed/g; }
        if ($found2 =~ m/d__ed/) { $found2 =~ s/d__ed/d\. ed/g; }
        if ($found2 =~ m/et al__/) { $found2 =~ s/et al__/et al\. /g; }
        if ($found2 =~ m/e__g__/) { $found2 =~ s/e__g__/e\. g\./g; }
        if ($found2 =~ m/e_g__/) { $found2 =~ s/e_g__/e\.g\./g; }
        if ($found2 =~ m/i_e__/) { $found2 =~ s/i_e__/i\.e\./g; }
        if ($found2 =~ m/i__e__/) { $found2 =~ s/i__e__/i\. e\./g; }
        if ($found2 =~ m/Fig__/) { $found2 =~ s/Fig__/Fig\. /g; }
        if ($found2 =~ m/[\.]$/) { $found2 =~ s/[\.]$//; }
        $ace_entry .= "Provisional_description\t\"$found2.\"\n"; 
        $ace_provisional .= "Provisional_description\t\"$found2.\"\n"; 
      } # foreach my $found2 (@found)
    } # if ($found) 
  } # if ($found)
  if ($ace_provisional) { $ace_delete .= "-D Provisional_description\n"; }
  print "$ace_delete\n$ace_entry";
} # sub oldgetConcise


sub readCurrentLocus {
  my $u = shift;
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;

  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    my ($three, $wb) = $_ =~ m/^(.*?),(.*?),/;      # added to convert genes
    $wbGene{$three} = $wb;                  # from 3-letter to WBGene type
    if ($_ =~ m/,([^,]*?) ,CGC approved$/) {        # 2004 05 05
      my @things = split/ /, $1;
      foreach my $thing (@things) {
        if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) { $wbGene{$thing} = $wb; } } }
  } # foreach (@tmp)
#   $wbGene{'test-1'} = 'WBGene12345';
} # sub readCurrentLocus



sub getSangerConversionObsolete {
  # get sanger conversion
  my $u = "http://tazendra.caltech.edu/~azurebrd/sanger/loci_all.txt";
#   my $u = "http://www.sanger.ac.uk/Projects/C_elegans/LOCI/loci_all.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
#   print "getting data from $u<BR>\n";
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    my ($three, $wb) = $_ =~ m/^(.*?),(.*?),/;      # added to convert genes
    $wbGene{$three} = $wb;                      # from 3-letter to WBGene type
    $wbGeneBack{$wb} = $three;                  # from WBGene to 3-letter type
    if ($_ =~ m/,([^,]*?) ,approved$/) {        # 2005 05 06  the CGC was removed at some point
      my @things = split/ /, $1;
      foreach my $thing (@things) {
        if ($thing =~ m/[a-zA-Z][a-zA-Z][a-zA-Z]\-\d+/) { $wbGene{$thing} = $wb; $wbGene{$wb} = $thing; } } }
  } # foreach (@tmp)
#   print "added data from $u<BR>\n";
  $wbGene{'test-1'} = 'WBGene00000000';
  $wbGeneBack{'WBGene00000000'} = 'test-1';

  $u = 'http://tazendra.caltech.edu/~azurebrd/sanger/genes2molecular_names.txt';
#   $u = 'http://www.sanger.ac.uk/Projects/C_elegans/LOCI/genes2molecular_names.txt';
#   print "getting data from $u<BR>\n";
  $request = HTTP::Request->new(GET => $u); #grabs url
  $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    my ($wb, $cds, $three) = $_ =~ m/^(.*?)\t(.*?) (.*?)$/;      # added to convert genes
    $wbGene{$cds} = $wb;                        # from 3-letter to WBGene type
    $wbGeneBack{$wb} = $cds;                    # from WBGene to 3-letter type
    if ($three) {
      $wbGene{$three} = $wb;                    # from 3-letter to WBGene type
      $wbGeneBack{$wb} .= ' ' . $three;         # from WBGene to 3-letter type
    }
  } # foreach (@tmp)
#   print "added data from $u<BR>\n\n";
} # sub getSangerConversionObsolete
