#!/usr/bin/perl

# Take get_allele_phenotype_ace.pm and rewrite to read all the data at once,
# then dump it all instead of reading in values one allele at a time.
# Not sure that Condition data is working right, since it seemed overly
# complicated and redundant in get_allele_phenotype_ace.pm   2007 01 04
#
# Comments were the wrong way (\\ instead of //)  2007 01 18
#
# Change Curator from a box to box + column.  2007 04 23
#
# Moved Condition stuff to work like Functional Change.  Added Anatomy Term
# to work like Life Stage.  Merged Preparation into Treatment.  For Carol.
# 2007 04 24
#
# Added a Paper -> Allele / Transgene .ace dump based on Paper_evidence
# 2007 06 08
#
# Brought back &filterAce for data and also filtering out all \n and \r
# for Gary  2007 10 24
#
# Edit &filterAce to not filter timestamps.  2008 01 08
#
# Edit &filterAce to append timestamps after filtering them.  2008 01 11


use strict;
use diagnostics;
use Pg;
use LWP;
use Jex;

my $date = &getSimpleSecDate();

my $directory = '/home/postgres/work/citace_upload/allele_phenotype';
my $outfile = $directory . '/old/allele_phenotype.' . $date . '.ace';

open (OUT, ">>$outfile") or die "Cannot create $outfile : $!";

my %bad_entries;	# filter bad entries
my %good_entries;	# filter good entries (unnecessary, but for consistency with bad entries


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my $start_date = &getSimpleSecDate();
# my $start_time = time;

my $result;

my %theHash;
my %curators;

my @genParams = qw ( type tempname finalname wbgene rnai_brief );
my @groupParams = qw ( paper person finished phenotype remark intx_desc);
my @multParams = qw ( curator not term phen_remark quantity_remark quantity go_sug suggested sug_ref sug_def genotype lifestage anat_term temperature strain treatment delivered nature penetrance percent range mat_effect pat_effect heat_sens heat_degree cold_sens cold_degree func haplo );


my $all_entry = '';
my $err_text = '';

my %validPersonPaper;				# existing wbpersons and wbpapers
&populateValidPersonPaper();
&populateCurators();				# to convert Curators to WBPersons
&populateHeaderFinalname();
&populateGeneral();
&populateEvidence();
&processAll();

close (OUT) or die "Cannot close $outfile : $!";
my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/allele_phenotype.ace';
unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";		# unlink symlink to latest
symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";


# my $end_date = &getSimpleSecDate();
# my $end_time = time;
# my $diff_time = $end_time - $start_time;
# print "$diff_time seconds between $start_date and $end_date\n";


sub processAll {
  my %filterHash;
  $result = $conn->exec( "SELECT * FROM alp_type WHERE alp_type = 'Transgene' OR alp_type = 'Allele';" );
  while (my @row = $result->fetchrow) { 				# get Alleles and Transgenes
    $filterHash{$row[0]}++; }						# used to get only those with final names, now get all and show message if there's no final name
#     my $result2 = $conn->exec( "SELECT * FROM alp_finalname WHERE joinkey = '$row[0]' ORDER BY alp_timestamp DESC;" );
#     while (my @row2 = $result2->fetchrow) { 				# if they have a finalname, queue to get values
#       if ($row[1]) { if ($row[1] =~ m/\w/) { $filterHash{$row[0]}++; } } }
  foreach my $joinkey (sort keys %filterHash) {
    unless ($theHash{type}{$joinkey}) { print OUT "NO type $joinkey\n"; }
#     unless ($theHash{type}{$joinkey}) { print "NO type $joinkey\n"; }
    &getStuff( $joinkey );
  } # foreach my $joinkey (sort keys %filterHash)

  foreach my $entry (sort keys %bad_entries) { print OUT $entry; }
  print OUT "\n\n";
  foreach my $entry (sort keys %good_entries) { print OUT "$entry\n"; }
  &processPapers();
} # sub processAll

sub processPapers {		# Added for Gary  2007 06 08
  my $pap_outfile = $directory . '/old/allele_phenotype_papers.' . $date . '.ace';

  open (PAP, ">>$pap_outfile") or die "Cannot create $pap_outfile : $!";
  my %papers;		# Paper to Variation and Transgene
  foreach my $entry (sort keys %good_entries) { 
    my $obj = '';
    if ($entry =~ m/Transgene : \"(.*?)\"/) { $obj = "Transgene\t\"$1\"\tInferred_Automatically\t\"Inferred automatically from curated phenotype\"\n"; }
      elsif ($entry =~ m/Variation : \"(.*?)\"/) { $obj = "Allele\t\"$1\"\tInferred_Automatically\t\"Inferred automatically from curated phenotype\"\n"; }
      else { $obj = ''; }
    my (@papers) = $entry =~ m/Paper_evidence\s+\"(WBPaper\d+)\"/;
    foreach my $paper (@papers) { $papers{$paper}{$obj}++; }
  }
  foreach my $paper (sort keys %papers) {
    print PAP "Paper : \"$paper\"\n"; 
    foreach my $obj (sort keys %{ $papers{$paper} }) {
      print PAP "$obj";
    } # foreach my $obj (sort keys %{ $papers{$paper} })
    print PAP "\n";
  } # foreach my $paper (sort keys %papers)
  close (PAP) or die "Cannot create $pap_outfile : $!";
  my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/allele_phenotype_papers.ace';
  unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";		# unlink symlink to latest
  symlink("$pap_outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";
} # sub processPapers



sub populateHeaderFinalname {
    # get Header and Final name
  $result = $conn->exec( "SELECT joinkey, alp_finalname FROM alp_finalname ORDER BY alp_timestamp ;" );
  while ( my @row = $result->fetchrow ) { if ($row[0]) { $theHash{finalname}{$row[0]} = $row[1]; } }
  $result = $conn->exec( "SELECT joinkey, alp_type FROM alp_type WHERE (alp_type = 'Transgene' OR alp_type = 'Allele') ORDER BY alp_timestamp ;");
  while (my @row = $result->fetchrow) {
    $theHash{type}{$row[0]} = $row[1]; 
    if ($theHash{finalname}{$row[0]}) {
        my $header = "$row[1] : \"$theHash{finalname}{$row[0]}\"\n";
        if ($header =~ m/Allele/) { $header =~ s/Allele/Variation/g; }
        $theHash{header}{$row[0]} = $header; }
      else { $theHash{header}{$row[0]} = "\/\/ NO finalname $row[0]\n"; } }
} # sub populateHeaderFinalname
    
sub populateGeneral {
    # get General data
  foreach my $type (@genParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$type ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) { 
          $row[1] = &filterAce($row[1]);
          $theHash{$type}{$row[0]} = $row[1]; }
        else { $theHash{$type}{$row[0]} = ''; } } }
  foreach my $type (@groupParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$type ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) {
      my $g_type = $type . '_' . $row[1] ;
      if ($row[2]) {												# if there's data
          $row[2] = &filterAce($row[2]);
          $theHash{$g_type}{$row[0]} = $row[2];									# store it by table name + box number and by joinkey
          if ($theHash{box_mult}{$row[0]}) { 									# if there's a box count
              if ($row[1] > $theHash{box_mult}{$row[0]}) { $theHash{box_mult}{$row[0]} = $row[1]; } }		# if more boxes than with previous data, store new high
            else { $theHash{box_mult}{$row[0]} = 1; } }								# if there isn't, make it one box
        else { $theHash{$g_type}{$row[0]} = ''; } } }								# if no data, store a blank
  foreach my $type (@multParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$type ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) {
      my $ts_type = $type . '_' . $row[1] . '_' . $row[2];
      if ($row[3]) {
          $row[3] = &filterAce($row[3]);
          $theHash{$ts_type}{$row[0]} = $row[3];
          if ($theHash{box_mult}{$row[0]}) {
              if ($row[1] > $theHash{box_mult}{$row[0]}) { $theHash{box_mult}{$row[0]} = $row[1]; } }
            else { $theHash{box_mult}{$row[0]} = 1; }
          if ($theHash{col_mult}{$row[0]}) {
              if ($row[2] > $theHash{col_mult}{$row[0]}) { $theHash{col_mult}{$row[0]} = $row[2]; } }
            else { $theHash{col_mult}{$row[0]} = 1; } }
        else { $theHash{$ts_type}{$row[0]} = ''; } } }
} # sub populateGeneral

sub populateEvidence {
    # get Evidence
  $result = $conn->exec( "SELECT * FROM alp_curator ORDER BY alp_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[0]) { 			# get all curator evidence	# for Carol 2006 05 17
    if ($curators{std}{$row[0]}) { $row[3] = $curators{std}{$row[3]}; $row[3] =~ s/two/WBPerson/g; }	# convert to WBPerson
    $theHash{evidence}{curator}{$row[0]}{$row[1]}{$row[2]} = $row[3]; } }
  $result = $conn->exec( "SELECT * FROM alp_person ORDER BY alp_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[0]) { 			# get latest person data
    $theHash{evidence}{person}{$row[0]}{$row[1]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
  while (my @row = $result->fetchrow) { if ($row[0]) { 			# get latest paper evidence
    $theHash{evidence}{paper}{$row[0]}{$row[1]} = $row[2]; } }
} # sub populateEvidence

sub populateValidPersonPaper {		# get hash of valid wbpersons and wbpapers
  my $result = $conn->exec( "SELECT * FROM two ORDER BY two" );
  while (my @row = $result->fetchrow) {
    $validPersonPaper{person}{$row[1]}++; }
  $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $validPersonPaper{paper}{$row[0]}++; }
      else { delete $validPersonPaper{paper}{$row[0]}; } }
} # sub populateValidPersonPaper

sub populateCurators {					# get curators to convert to WBPersons
  my $result = $conn->exec( "SELECT * FROM two_standardname; " );
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0];
  } # while (my @row = $result->fetchrow)
  $curators{std}{'Juancarlos Testing'} = 'two1823';
} # sub populateCurators

sub getStuff {
  my ($joinkey) = @_; my $ace_entry;
  return unless ($theHash{type}{$joinkey});
  my $condition_count = 0;
  for my $i (1 .. $theHash{box_mult}{$joinkey}) {			# different box values
    my $g_type = 'phenotype_' . $i ;					# get phenotype remark
    my $phen_rem = '';  if ($theHash{$g_type}{$joinkey}) { $phen_rem = $theHash{$g_type}{$joinkey}; }
    next unless ($theHash{col_mult}{$joinkey}); 
    for my $j (1 .. $theHash{col_mult}{$joinkey}) {			# different column values
      my $evidence = ''; ($evidence) = &getEvidence($joinkey, $i, $j);	# get the evidence multi-line for the joinkey and box
      next unless ($evidence); 
      if ($evidence) { if ($evidence eq 'ERROR') { return; } }
      my $cur_entry = '';
      if ($phen_rem) { $cur_entry .= &addEvi($evidence, "Phenotype_remark\t\"$phen_rem\""); }
      my $phenotype = '';
      my $ts_type = 'term_' . $i . '_' . $j;				# call ts_type (don't recall why)
      if ($theHash{$ts_type}{$joinkey}) { 				# Phenotype Ontology Term
          $phenotype = $theHash{$ts_type}{$joinkey}; 
          if ($phenotype =~ m/(WBPhenotype\d+)/) { $phenotype = $1; 	# Storing values as PhenotypeID (phenotype term) so it should always match	2005 12 22
            $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\""); } }	# always attach the Phenotype   2006 05 12
        else { next; }							# skip if there's no phenotype
      $ts_type = 'not_' . $i . '_' . $j;				# NOT
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tNOT"); }
      $ts_type = 'phen_remark_' . $i . '_' . $j;			# Remark (Phenotype)
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRemark\t\"$theHash{$ts_type}{$joinkey}\""); }
      $ts_type = 'quantity_remark_' . $i . '_' . $j;			# Quantity
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tQuantity_description\t\"$theHash{$ts_type}{$joinkey}\""); }
      $ts_type = 'quantity_' . $i . '_' . $j;				# Quantity Data
      if ($theHash{$ts_type}{$joinkey}) {
        my $value = $theHash{$ts_type}{$joinkey}; 
        if ($value =~ m/(\d+)\D+(\d+)/) { $value = "$1\"\t\"$2"; }
        elsif ($value =~ m/(\d+)/) { $value = "$1\"\t\"$1"; }
        else { $err_text .= '\/\/ ' . "$joinkey has bad quantity data data $value\n"; next; }		# skip entry if quantity data doesn't have an integer
        $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tQuantity\t\"$value\""); }
      $ts_type = 'nature_' . $i . '_' . $j;				# Dominance
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{$joinkey}"); }

      $ts_type = 'penetrance_' . $i . '_' . $j;				# Penetrance
      my $ts_percent = 'percent_' . $i . '_' . $j;			# Percent
      if ($theHash{$ts_type}{$joinkey}) {
        my $percent = ''; if ($theHash{$ts_percent}{$joinkey}) { $percent = $theHash{$ts_percent}{$joinkey}; }
        $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPenetrance\t$theHash{$ts_type}{$joinkey} \"$percent\""); }
      my $range = '100" "100';					# default Range for penetrance being Complete
      my $ts_range = 'range_' . $i . '_' . $j;			# Range
      if ($theHash{$ts_type}{$joinkey}) {
        unless ($theHash{$ts_type}{$joinkey} =~ m/Complete/) {		# range is not 100
          if ($theHash{$ts_range}{$joinkey}) {
            $range = $theHash{$ts_range}{$joinkey}; 
            if ($range =~ m/\s/) { $range =~ s/\s+/\" \"/g; }
              else { $range = "$range\" \"$range"; } }
      } }
      if ($theHash{$ts_range}{$joinkey}) {			# output a range if there's a range 
          $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRange\t\"$range\""); }
        elsif ($theHash{$ts_type}{$joinkey}) {
          if ($theHash{$ts_type}{$joinkey} =~ m/Complete/) {	# output a range if penetrance is Complete
            $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRange\t\"$range\""); } } 
        else { 1; }
      $ts_type = 'mat_effect_' . $i . '_' . $j;				# Mat Effect
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{$joinkey}"); }
      $ts_type = 'pat_effect_' . $i . '_' . $j;				# Pat Effect
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPaternal"); }
      my $degree = '';
      $ts_type = 'heat_degree_' . $i . '_' . $j;			# Heat_sensitive degree
      if ($theHash{$ts_type}{$joinkey}) { $degree = $theHash{$ts_type}{$joinkey}; }
      $ts_type = 'heat_sens_' . $i . '_' . $j;				# Heat_sensitive
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tHeat_sensitive\t\"$degree\""); }
      $ts_type = 'cold_degree_' . $i . '_' . $j;			# Cold_sensitive degree
      if ($theHash{$ts_type}{$joinkey}) { $degree = $theHash{$ts_type}{$joinkey}; }
      $ts_type = 'cold_sens_' . $i . '_' . $j;				# Cold_sensitive
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tCold_sensitive\t\"$degree\""); }
      $ts_type = 'func_' . $i . '_' . $j;				# Functional Change
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{$joinkey}"); }
      $ts_type = 'haplo_' . $i . '_' . $j;				# Haploinsufficient
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tHaplo_insufficient"); }
      unless ($cur_entry) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\""); }		# only add evidence hash if there's no other data  2005 12 20
      $ts_type = 'genotype' . '_' . $i . '_' . $j;
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tGenotype\t\"$theHash{$ts_type}{$joinkey}\""); }
      $ts_type = 'strain' . '_' . $i . '_' . $j;
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tStrain\t\"$theHash{$ts_type}{$joinkey}\""); }
#       $ts_type = 'preparation' . '_' . $i . '_' . $j;	# don't use preparation anymore, merged into treatment.  For Carol  2007 04 24
#       if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPreparation\t\"$theHash{$ts_type}{$joinkey}\""); }
      $ts_type = 'treatment' . '_' . $i . '_' . $j;
      if ($theHash{$ts_type}{$joinkey}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tTreatment\t\"$theHash{$ts_type}{$joinkey}\""); }
      $ts_type = 'anat_term' . '_' . $i . '_' . $j;
      if ($theHash{$ts_type}{$joinkey}) { 
        my $val = $theHash{$ts_type}{$joinkey};
        if ($val =~ m/\|/) { my @stuff = split/\|/, $val; foreach my $stuff (@stuff) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tAnatomy_term\t\"$stuff\""); } }
          else { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tAnatomy_term\t\"$val\""); } }		# split anatomy term by commas for Carol 2007 04 24
      $ts_type = 'temperature' . '_' . $i . '_' . $j;
      if ($theHash{$ts_type}{$joinkey}) { if ($theHash{$ts_type}{$joinkey} =~ m/(\d+)/) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tTemperature\t\"$1\""); } }
      $ts_type = 'lifestage' . '_' . $i . '_' . $j;
      if ($theHash{$ts_type}{$joinkey}) { 
        my $val = $theHash{$ts_type}{$joinkey};
        if ($val =~ m/\|/) { my @stuff = split/\|/, $val; foreach my $stuff (@stuff) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tLife_stage\t\"$stuff\""); } }
          else { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tLife_stage\t\"$val\""); } }		# split life_stage by commas for Carol 2006 09 08

      my $header = $theHash{header}{$joinkey};
      if ($header =~ m/NO finalname/) { $bad_entries{$header}++; }
        else { 
          my $entry = "$theHash{header}{$joinkey}$cur_entry";
# No longer use condition stuff  for Carol  2007 04 24
#           my ($condition, $condition_name) = &getCondition($joinkey, $i, $j);	# get condition data and condition header name for this .ace entry
#           if ($condition) { if ($theHash{finalname}{$joinkey}) {				# Show the appropriate tag in Condition based on $header  2006 11 08
#             if ($header =~ m/Transgene/) { $condition .= "Transgene\t\"$theHash{finalname}{$joinkey}\"\n"; } 
#             elsif ($header =~ m/Variation/) { $condition .= "Variation\t\"$theHash{finalname}{$joinkey}\"\n"; } 
#             elsif ($header =~ m/RNAi/) { $condition .= "RNAi\t\"$theHash{finalname}{$joinkey}\"\n"; } } }
#           if ($condition_name) {
#             $condition_count++;						# it's an entry, condition count goes up
#             $condition_name .= $condition_count;
#             $condition = "Condition : \"$condition_name\"\n" . $condition;
#             $entry .= "Phenotype\t\"$phenotype\"\tPhenotype_assay\t\"$condition_name\"\n";
#             $entry .= "\n$condition"; }					# add the condition
# #         if ($entry) { if ($joinkey eq 'jh113') { $good_entries{$entry}++; } }
# #         if ($entry) { if ($joinkey eq 'e1313') { $good_entries{$entry}++; } }
          if ($entry) { $good_entries{$entry}++; } }

  } } # for # for
} # sub getStuff


sub getEvidence {
  my ($joinkey, $alp_box, $alp_column) = @_; my $evidence;
  if ($theHash{evidence}{curator}{$joinkey}{$alp_box}{$alp_column}) { 
    my $value = $theHash{evidence}{curator}{$joinkey}{$alp_box}{$alp_column};
    if ($curators{std}{$value}) { $value = $curators{std}{$value}; $value =~ s/two/WBPerson/g; }	# convert to WBPerson
    $evidence .= "Curator_confirmed\t\"$value\"\n"; }
  if ( $theHash{evidence}{person}{$joinkey}{$alp_box} ) {					# get the latest person evidence
    my $value = $theHash{evidence}{person}{$joinkey}{$alp_box};
    my @people = split/\|/, $value;				# break up into people if more than one person
    foreach my $person (@people) { 
      my ($check_evi) = $person =~ m/WBPerson(\d+)/; 
      unless ($check_evi) { $evidence .= "// ERROR Person $person NOT a valid person\n"; next ; }
      unless ($validPersonPaper{person}{$check_evi}) { $evidence .= "// ERROR Person $person NOT a valid person\n"; next ; }
      $person =~ s/^\s+//g; $evidence .= "Person_evidence\t\"$person\"\n"; } }
  if ( $theHash{evidence}{paper}{$joinkey}{$alp_box} ) {					# get the latest paper evidence
    my $value = $theHash{evidence}{paper}{$joinkey}{$alp_box};
    if ($value =~ m/WBPaper\d+/) { 
        my ($check_evi) = $value =~ m/WBPaper(\d+)/;
        if ($validPersonPaper{paper}{$check_evi}) {
            $evidence .= "Paper_evidence\t\"WBPaper$check_evi\"\n"; } 	# 2006 08 23 get the WBPaper, not the data with comments
          else { $evidence .= "// ERROR Paper $value NOT a valid paper\n"; } }
      else { $err_text .= '\/\/ ' . "$joinkey has bad paper data $value\n"; return "ERROR"; } }
  if ($evidence) { return $evidence; }
} # sub getEvidence

sub addEvi {				# append evidence hash to a line, making it a multi-line line
  my ($evidence, $line) = @_; my $tag_data;
  chomp $line;
  $tag_data .= "$line\n";			# always print it without evidence (as well as with matching evidence later)
  my $line_ts = 0;
  if ($line =~ m/\-O \"[\d]{4}/) { 		# if the line has acedb timestamps
    $line_ts++; }				# flag it to have timestamp
  if ($evidence) {
      my @evidences = split/\n/, $evidence;			# break multi-line evidence into evidence array
      foreach my $evi (@evidences) { 
        if ($evi =~ m/Curator_confirmed/) { 	# if curator evidence, check that their acedb timestamp state matches
            my $evi_ts = 0; 
            if ($evi =~ m/\-O\s+\"[\d]{4}/) { $evi_ts++; }			# flag if evidence has timestamp
            if ($evi_ts && $line_ts) { $tag_data .= "$line\t$evi\n"; }		# append lines without timestamp if evidence is without timestamp 
            if (!$evi_ts && !$line_ts) { $tag_data .= "$line\t$evi\n"; }	# append lines with timestamp if evidence is with timestamp 
          }
          else { $tag_data .= "$line\t$evi\n"; }				# always append person and paper evidence
      }
      return $tag_data; }
    else { return "$line\n"; }
} # sub addEvi

sub filterAce {
  my $identifier = shift;
  my $timestamp;
  if ($identifier =~ m/\"\s+\-O/) { ($identifier, $timestamp) = $identifier =~ m/^(.*?)\s*(\"\s+\-O.*?)$/; }	# also escape the \ before the " before the timestamp  2008 01 09
  elsif ($identifier =~ m/\-O/) { ($identifier, $timestamp) = $identifier =~ m/^(.*?)(\-O.*?)$/; }
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\n/) { $identifier =~ s/\n/ /g; }
  if ($identifier =~ m/\r/) { $identifier =~ s/\r/ /g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/:/) { $identifier =~ s/:/\\:/g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/,/) { $identifier =~ s/,/\\,/g; }
  if ($identifier =~ m/-/) { $identifier =~ s/-/\\-/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  if ($timestamp) { $identifier .= " $timestamp"; }
  return $identifier;
} # sub filterAce



__END__

# No longer getting Condition  2007 04 24.  For Carol
sub getCondition {
  my ($joinkey, $i, $j) = @_;						# get the joinkey, box, and column
  my $g_type = 'paper_' . $i;
  my $g_type_person = 'person_' . $i;
  my $g_type_curator = 'curator_' . $i . '_' . $j;
  my $paper = ''; my $id = ''; my $condition_data = '';	

  if ($theHash{$g_type}{$joinkey}) { if ($theHash{$g_type}{$joinkey} =~ m/(WBPaper\d+)/) { $paper = $1; $id = $1; } }
  elsif ($theHash{$g_type_person}{$joinkey}) { if ($theHash{$g_type_person}{$joinkey} =~ m/(WBPerson\d+)/) { $id = 1; } }
  elsif ($theHash{$g_type_curator}{$joinkey}) { 
    if ($theHash{$g_type_curator}{$joinkey} =~ m/(WBPerson\d+)/) { $id = 1; }
    elsif ($curators{std}{$theHash{$g_type_curator}{$joinkey}}) { $id = $curators{std}{$theHash{$g_type_curator}{$joinkey}}; } }
  return unless $id;
  
    my $ts_type = 'genotype' . '_' . $i . '_' . $j;
    if ($theHash{$ts_type}{$joinkey}) { $condition_data .= "Genotype\t\"$theHash{$ts_type}{$joinkey}\"\n"; }
    $ts_type = 'strain' . '_' . $i . '_' . $j;
    if ($theHash{$ts_type}{$joinkey}) { $condition_data .= "Strain\t\"$theHash{$ts_type}{$joinkey}\"\n"; }
    $ts_type = 'preparation' . '_' . $i . '_' . $j;
    if ($theHash{$ts_type}{$joinkey}) { $condition_data .= "Preparation\t\"$theHash{$ts_type}{$joinkey}\"\n"; }
    $ts_type = 'treatment' . '_' . $i . '_' . $j;
    if ($theHash{$ts_type}{$joinkey}) { $condition_data .= "Treatment\t\"$theHash{$ts_type}{$joinkey}\"\n"; }
    $ts_type = 'temperature' . '_' . $i . '_' . $j;
    if ($theHash{$ts_type}{$joinkey}) { if ($theHash{$ts_type}{$joinkey} =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
    $ts_type = 'lifestage' . '_' . $i . '_' . $j;
    if ($theHash{$ts_type}{$joinkey}) { 
      my $val = $theHash{$ts_type}{$joinkey};
      if ($val =~ m/, /) { my @stuff = split/, /, $val; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
        else { $condition_data .= "Life_stage\t\"$val\"\n"; } }		# split life_stage by commas for Carol 2006 09 08
    if ($condition_data) {
      if ($paper) { $condition_data .= "Reference\t\"$paper\"\n"; }
      return ($condition_data, "${id}_${joinkey}:phenotype_"); }
} # sub getCondition





sub getAllelePhenotype {
  my ($flag) = shift;
  &populateCurators();				# to convert Curators to WBPersons
  if ( $flag eq 'all' ) {
    my %filterHash;
    $result = $conn->exec( "SELECT * FROM alp_type WHERE alp_type = 'Transgene' OR alp_type = 'Allele';" );
    while (my @row = $result->fetchrow) { 				# get Alleles and Transgenes
      my $result2 = $conn->exec( "SELECT * FROM alp_finalname WHERE joinkey = '$row[0]' ORDER BY alp_timestamp DESC;" );
      while (my @row2 = $result2->fetchrow) { 				# if they have a finalname, queue to get values
        if ($row[1]) { if ($row[1] =~ m/\w/) { $filterHash{$row[0]}++; } } } }
    foreach my $joinkey (sort keys %filterHash) {
      my ($entry) = &getStuff( $joinkey ); 
      if ($entry) { $all_entry .= $entry; } }				# if they have .ace entry, append to whole list
    return( $all_entry, $err_text ); }
  else { 
    my $joinkey = '';
    my $result = $conn->exec( "SELECT * FROM alp_tempname WHERE joinkey = '$flag';" );
    my @row = $result->fetchrow; if ($row[0]) { $joinkey = $row[0]; }	# check that it's a tempname
    unless ($joinkey) { 						# otherwise check that it's a finalname
      $result = $conn->exec( "SELECT * FROM alp_finalname WHERE alp_finalname = '$flag';" );
      @row = $result->fetchrow; if ($row[0]) { $joinkey = $row[0]; } }
    my $entry = '';
    if ($joinkey) { $entry .= &getStuff( $joinkey ); }	# get data
      else { $err_text .= '\/\/ ' . "$flag is neither a valid tempname nor a valid finalname\n"; } 
    return( $entry, $err_text ); }
} # sub getAllelePhenotype


sub getStuff {
  my ($joinkey) = @_; my $ace_entry;
  my $result = $conn->exec( "SELECT alp_type FROM alp_type WHERE joinkey = '$joinkey' AND (alp_type = 'Transgene' OR alp_type = 'Allele') ORDER BY alp_timestamp DESC;");
  my @row = $result->fetchrow; unless ($row[0]) { return ''; }		# if not a variation or a transgene, no ace_entry
  %theHash = ();							# reinit %%theHash to get new values only in &queryPostgres();
  &queryPostgres($joinkey);						# populate %theHash with the data for this joinkey
  my ($header, $finalname) = &getHeader($joinkey);			# get the object header for the joinkey
  for my $i (1 .. $theHash{group_mult}{html_value}) {			# different box values
    my $evidence = ''; ($evidence) = &getEvidence($joinkey, $i);	# get the evidence multi-line for the joinkey and box
    if ($evidence) { if ($evidence eq 'ERROR') { return; } }
    my $g_type = 'phenotype_' . $i ;					# get phenotype remark
    my $phen_rem = '';  if ($theHash{$g_type}{html_value}) { $phen_rem = $theHash{$g_type}{html_value}; }
    for my $j (1 .. $theHash{horiz_mult}{html_value}) {			# different column values
      my $cur_entry = '';
      if ($phen_rem) { $cur_entry .= &addEvi($evidence, "Phenotype_remark\t\"$phen_rem\""); }
      my $phenotype = '';
      my $ts_type = 'term_' . $i . '_' . $j;				# call ts_type (don't recall why)
      if ($theHash{$ts_type}{html_value}) { 				# Phenotype Ontology Term
          $phenotype = $theHash{$ts_type}{html_value}; 
          if ($phenotype =~ m/(WBPhenotype\d+)/) { $phenotype = $1; 	# Storing values as PhenotypeID (phenotype term) so it should always match	2005 12 22
            $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\""); } }	# always attach the Phenotype   2006 05 12
        else { next; }							# skip if there's no phenotype
      $ts_type = 'not_' . $i . '_' . $j;				# NOT
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tNOT"); }
      $ts_type = 'phen_remark_' . $i . '_' . $j;			# Remark (Phenotype)
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRemark\t\"$theHash{$ts_type}{html_value}\""); }
      $ts_type = 'quantity_remark_' . $i . '_' . $j;			# Quantity
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tQuantity_description\t\"$theHash{$ts_type}{html_value}\""); }
      $ts_type = 'quantity_' . $i . '_' . $j;				# Quantity Data
      if ($theHash{$ts_type}{html_value}) {
        my $value = $theHash{$ts_type}{html_value}; 
        if ($value =~ m/(\d+)\D+(\d+)/) { $value = "$1\"\t\"$2"; }
        elsif ($value =~ m/(\d+)/) { $value = "$1\"\t\"$1"; }
        else { $err_text .= '\/\/ ' . "$joinkey has bad quantity data data $value\n"; next; }		# skip entry if quantity data doesn't have an integer
        $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tQuantity\t\"$value\""); }
      $ts_type = 'nature_' . $i . '_' . $j;				# Dominance
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{html_value}"); }

      $ts_type = 'penetrance_' . $i . '_' . $j;				# Penetrance
      my $ts_percent = 'percent_' . $i . '_' . $j;			# Percent
      if ($theHash{$ts_type}{html_value}) {
        my $percent = ''; if ($theHash{$ts_percent}{html_value}) { $percent = $theHash{$ts_percent}{html_value}; }
        $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPenetrance\t$theHash{$ts_type}{html_value} \"$percent\""); }
      my $range = '100" "100';					# default Range for penetrance being Complete
      my $ts_range = 'range_' . $i . '_' . $j;			# Range
      if ($theHash{$ts_type}{html_value}) {
        unless ($theHash{$ts_type}{html_value} =~ m/Complete/) {		# range is not 100
          if ($theHash{$ts_range}{html_value}) {
            $range = $theHash{$ts_range}{html_value}; 
            if ($range =~ m/\s/) { $range =~ s/\s+/\" \"/g; }
              else { $range = "$range\" \"$range"; } }
      } }
      if ($theHash{$ts_range}{html_value}) {			# output a range if there's a range 
          $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRange\t\"$range\""); }
        elsif ($theHash{$ts_type}{html_value}) {
          if ($theHash{$ts_type}{html_value} =~ m/Complete/) {	# output a range if penetrance is Complete
            $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tRange\t\"$range\""); } } 
        else { 1; }
      $ts_type = 'mat_effect_' . $i . '_' . $j;				# Mat Effect
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{html_value}"); }
      $ts_type = 'pat_effect_' . $i . '_' . $j;				# Pat Effect
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tPaternal"); }
      my $degree = '';
      $ts_type = 'heat_degree_' . $i . '_' . $j;			# Heat_sensitive degree
      if ($theHash{$ts_type}{html_value}) { $degree = $theHash{$ts_type}{html_value}; }
      $ts_type = 'heat_sens_' . $i . '_' . $j;				# Heat_sensitive
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tHeat_sensitive\t\"$degree\""); }
      $ts_type = 'cold_degree_' . $i . '_' . $j;			# Cold_sensitive degree
      if ($theHash{$ts_type}{html_value}) { $degree = $theHash{$ts_type}{html_value}; }
      $ts_type = 'cold_sens_' . $i . '_' . $j;				# Cold_sensitive
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tCold_sensitive\t\"$degree\""); }
      $ts_type = 'func_' . $i . '_' . $j;				# Functional Change
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\t$theHash{$ts_type}{html_value}"); }
      $ts_type = 'haplo_' . $i . '_' . $j;				# Haploinsufficient
      if ($theHash{$ts_type}{html_value}) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\"\tHaplo_insufficient"); }
      unless ($cur_entry) { $cur_entry .= &addEvi($evidence, "Phenotype\t\"$phenotype\""); }		# only add evidence hash if there's no other data  2005 12 20

      my ($condition, $condition_name) = &getCondition($joinkey, $i, $j);	# get condition data and condition header name for this .ace entry
      if ($condition) { if ($finalname) {				# Show the appropriate tag in Condition based on $header  2006 11 08
        if ($header =~ m/Transgene/) { $condition .= "Transgene\t\"$finalname\"\n"; } 
        elsif ($header =~ m/Variation/) { $condition .= "Variation\t\"$finalname\"\n"; } 
        elsif ($header =~ m/RNAi/) { $condition .= "RNAi\t\"$finalname\"\n"; } } }
      if ($condition_name) {
        $cur_entry .= "Phenotype\t\"$phenotype\"\tPhenotype_assay\t\"$condition_name\"\n";
# Carol no longer wants curator tag for Phenotype_assay  2005 12 20
#         my $g_type = 'curator_' . $i;						# get the curator
#         if ($theHash{$g_type}{html_value}) { if ($curators{std}{$theHash{$g_type}{html_value}}) {
#           $theHash{$g_type}{html_value} = $curators{std}{$theHash{$g_type}{html_value}}; $theHash{$g_type}{html_value} =~ s/two/WBPerson/g; }	# convert to WBPerson
#           $cur_entry .= "Phenotype\t\"$phenotype\"\tPhenotype_assay\t\"$condition_name\"\tCurator_confirmed\t\"$theHash{$g_type}{html_value}\"\n"; }
        $cur_entry .= "\n$condition"; }					# add the condition
      if ($cur_entry) { $ace_entry .= "\n$header$cur_entry"; }		# create the ace entry
  } }

  if ($ace_entry) { return $ace_entry; }
  else { return "\n\/\/ NO ACE ENTRY $joinkey<BR>\n"; }
} # sub getStuff

sub getCondition {
  my ($joinkey, $i, $j) = @_;						# get the joinkey, box, and column
  my $g_type = 'paper_' . $i;
  my $other_g_type = 'person_' . $i;
  if ($theHash{$g_type}{html_value}) { if ($theHash{$g_type}{html_value} =~ m/(WBPaper\d+)/) {
    my $paper = $1; my $condition = ''; my $condition_data = '';	# find the paper

    my %condition; my $condition_count;		# hash of conditions to match a header name to the .ace condition data generated below, and the numbers used so far corresponding to them
    my %find_paper;				# find all joinkeys (tempnames) and boxes corresponding to papers (need hash because old values stored with current values in postgres)
    my $result = $conn->exec( "SELECT * FROM alp_paper ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) { $find_paper{$row[0]}{$row[1]} = $row[2]; }	# keys joinkey, box, value paper
    foreach my $joinkey (sort keys %find_paper) {
      foreach my $i (sort keys %{ $find_paper{$joinkey} }) {	# scoped $i is the box number of postgres-looping entry
        if ($find_paper{$joinkey}{$i}) {			# if there's paper data
          if ($find_paper{$joinkey}{$i} =~ m/(WBPaper\d+)/) {	# if there's a paper
            my $loop_paper = $1;				# get the paper
            if ($paper eq $loop_paper) { 			# if it matches the main paper
              my @condParams = qw ( genotype lifestage temperature strain preparation treatment );	# the six conditions
              my $alp_column_max = 0;				# how many columns to loop through for a given joinkey-box
              foreach my $type (@condParams) {			# get the max column number
                my $result2 = $conn->exec( "SELECT alp_column FROM alp_$type WHERE joinkey = '$joinkey' AND alp_box = '$i';" );
                while (my @row2 = $result2->fetchrow) { if ($row2[0] > $alp_column_max) { $alp_column_max = $row2[0]; } } }
              for my $j ( 1 .. $alp_column_max ) {		# for each column
                $condition_data = '';				# initialize data for the condition
                my $result2 = $conn->exec( "SELECT * FROM alp_genotype WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                my @row2 = $result2->fetchrow;			# get latest genotype data if there's any
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Genotype\t\"$row2[3]\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_lifestage WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { 
                  if ($row2[3] =~ m/, /) { my @stuff = split/, /, $row2[3]; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
                    else { $condition_data .= "Life_stage\t\"$row2[3]\"\n"; } } }	# split life_stage by commas for Carol 2006 09 08
                $result2 = $conn->exec( "SELECT * FROM alp_temperature WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_strain WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Strain\t\"$row2[3]\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_preparation WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Preparation\t\"$row2[3]\"\n"; } }
                $result2 = $conn->exec( "SELECT * FROM alp_treatment WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
                @row2 = $result2->fetchrow;
                if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Treatment\t\"$row2[3]\"\n"; } }
                if ($condition_data) { 				# if there's condition data
                  $condition_data .= "Reference\t\"$paper\"\n"; 						# only add reference if there is data in any of the other six fields
                  unless ($condition{$paper}{$condition_data}) {						# if it's a new condition
                    $condition_count++;										# add to count
                    $condition{$paper}{$condition_data} = "${paper}_${joinkey}:phenotype_${condition_count}"; } } }	# add header to hash 
								# add the variation object in the condition object name  for Carol 2006 09 08
          } } } } }

    $condition_data = '';					# init condition data for the entry generating a .ace
    my $ts_type = 'genotype_' . $i . '_' . $j;			# Genotype Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Genotype\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'lifestage_' . $i . '_' . $j;			# Life Stage Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { 
      if ($theHash{$ts_type}{html_value} =~ m/, /) { my @stuff = split/, /, $theHash{$ts_type}{html_value}; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
        else { $condition_data .= "Life_stage\t\"$theHash{$ts_type}{html_value}\"\n"; } } }	# split life_stage by commas for Carol 2006 09 08
    $ts_type = 'temperature_' . $i . '_' . $j;			# Temperature Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
    $ts_type = 'strain_' . $i . '_' . $j;			# Strain Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Strain\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'preparation_' . $i . '_' . $j;			# Preparation Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Preparation\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'treatment_' . $i . '_' . $j;			# Treatment Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Treatment\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    if ($condition_data) {
      $condition_data .= "Reference\t\"$paper\"\n"; 
      $condition = "Condition : \"$condition{$paper}{$condition_data}\"\n" . $condition_data;		# get paragraph
      return ($condition, $condition{$paper}{$condition_data});
  } } }

  else { 
    my $person = ''; my $condition = ''; my $condition_data = '';	# find the person
    if ($theHash{$other_g_type}{html_value}) { if ($theHash{$other_g_type}{html_value} =~ m/(WBPerson\d+)/) { $person = $1; } }
      # also allow Condition and Phenotype_assay to be dumped if there's a Person evidence for Carol 2006 07 27
    unless ($person) {						# if no person, infer it from curator, for Carol  2006 09 08
      my $result2 = $conn->exec( "SELECT alp_curator FROM alp_curator WHERE joinkey = '$joinkey' AND alp_box = '$i' ORDER BY alp_timestamp DESC;" );
      my @row2 = $result2->fetchrow;
      my $std_name = $row2[0];
      if ($std_name =~ m/WBPerson(\d+)/) { $person = $1; }
      $result2 = $conn->exec( "SELECT joinkey FROM two_standardname WHERE two_standardname = '$std_name';" );
      @row2 = $result2->fetchrow;
      if ($row2[0]) { $row2[0] =~ s/two/WBPerson/; $person = $row2[0]; } }
    next unless $person;					# if still no person, skip it

    my %condition; my $condition_count;		# hash of conditions to match a header name to the .ace condition data generated below, and the numbers used so far corresponding to them
    my @condParams = qw ( genotype lifestage temperature strain preparation treatment );	# the six conditions
    my $alp_column_max = 0;				# how many columns to loop through for a given joinkey-box
    foreach my $type (@condParams) {			# get the max column number
      my $result2 = $conn->exec( "SELECT alp_column FROM alp_$type WHERE joinkey = '$joinkey' AND alp_box = '$i';" );
      while (my @row2 = $result2->fetchrow) { if ($row2[0] > $alp_column_max) { $alp_column_max = $row2[0]; } } }
    for my $j ( 1 .. $alp_column_max ) {		# for each column
      $condition_data = '';				# initialize data for the condition
      my $result2 = $conn->exec( "SELECT * FROM alp_genotype WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      my @row2 = $result2->fetchrow;			# get latest genotype data if there's any
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Genotype\t\"$row2[3]\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_lifestage WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { 
        if ($row2[3] =~ m/, /) { my @stuff = split/, /, $row2[3]; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
          else { $condition_data .= "Life_stage\t\"$row2[3]\"\n"; } } }		# split life_stage by commas for Carol 2006 09 08
      $result2 = $conn->exec( "SELECT * FROM alp_temperature WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_strain WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Strain\t\"$row2[3]\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_preparation WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Preparation\t\"$row2[3]\"\n"; } }
      $result2 = $conn->exec( "SELECT * FROM alp_treatment WHERE joinkey = '$joinkey' AND alp_box = '$i' AND alp_column = '$j' ORDER BY alp_timestamp DESC;" );
      @row2 = $result2->fetchrow;
      if ($row2[3]) { if ($row2[3] =~ m/\w/) { $condition_data .= "Treatment\t\"$row2[3]\"\n"; } }
      if ($condition_data) { 				# if there's condition data
        # $condition_data .= "Reference\t\"$person\"\n";		# person has person data here, which does not match Reference tag in acedb  for Carol  2006 09 08
        unless ($condition{$person}{$condition_data}) {						# if it's a new condition
          $condition_count++;										# add to count
          $condition{$person}{$condition_data} = "${person}_${joinkey}:phenotype_${condition_count}"; } } }	# add header to hash 
								# add the variation object in the condition object name  for Carol 2006 09 08

    $condition_data = '';					# init condition data for the entry generating a .ace
    my $ts_type = 'genotype_' . $i . '_' . $j;			# Genotype Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Genotype\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'lifestage_' . $i . '_' . $j;			# Life Stage Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { 
      if ($theHash{$ts_type}{html_value} =~ m/, /) { my @stuff = split/, /, $theHash{$ts_type}{html_value}; foreach my $stuff (@stuff) { $condition_data .= "Life_stage\t\"$stuff\"\n"; } }
        else { $condition_data .= "Life_stage\t\"$theHash{$ts_type}{html_value}\"\n"; } } }	# split life_stage by commas for Carol 2006 09 08
    $ts_type = 'temperature_' . $i . '_' . $j;			# Temperature Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/(\d+)/) { $condition_data .= "Temperature\t\"$1\"\n"; } }
    $ts_type = 'strain_' . $i . '_' . $j;			# Strain Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Strain\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'preparation_' . $i . '_' . $j;			# Preparation Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Preparation\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    $ts_type = 'treatment_' . $i . '_' . $j;			# Treatment Data
    if ($theHash{$ts_type}{html_value}) { if ($theHash{$ts_type}{html_value} =~ m/\w/) { $condition_data .= "Treatment\t\"$theHash{$ts_type}{html_value}\"\n"; } }
    if ($condition_data) {
      # $condition_data .= "Reference\t\"$person\"\n";		# person has person data here, which does not match Reference tag in acedb  for Carol  2006 09 08
      $condition = "Condition : \"$condition{$person}{$condition_data}\"\n" . $condition_data;		# get paragraph
      return ($condition, $condition{$person}{$condition_data});
  } }
} # sub getCondition

sub addEvi {				# append evidence hash to a line, making it a multi-line line
  my ($evidence, $line) = @_; my $tag_data;
  chomp $line;
  my $line_ts = 0;
  if ($line =~ m/\-O \"[\d]{4}/) { 		# if the line has acedb timestamps
    $tag_data .= "$line\n";			# always print it without evidence (as well as with matching evidence later)
    $line_ts++; }				# flag it to have timestamp
  if ($evidence) {
      my @evidences = split/\n/, $evidence;			# break multi-line evidence into evidence array
      foreach my $evi (@evidences) { 
#         $tag_data .= "$line\t$evi\n"; 
        if ($evi =~ m/Curator_confirmed/) { 	# if curator evidence, check that their acedb timestamp state matches
            my $evi_ts = 0; 
            if ($evi =~ m/\-O\s+\"[\d]{4}/) { $evi_ts++; }			# flag if evidence has timestamp
            if ($evi_ts && $line_ts) { $tag_data .= "$line\t$evi\n"; }		# append lines without timestamp if evidence is without timestamp 
            if (!$evi_ts && !$line_ts) { $tag_data .= "$line\t$evi\n"; }	# append lines with timestamp if evidence is with timestamp 
          }
          else { $tag_data .= "$line\t$evi\n"; }				# always append person and paper evidence
      }
      return $tag_data; }
    else { return "$line\n"; }
} # sub addEvi

sub getEvidence {
  my ($joinkey, $alp_box) = @_; my $evidence;
  my $result = $conn->exec( "SELECT alp_curator FROM alp_curator WHERE joinkey = '$joinkey' AND alp_box = '$alp_box' ORDER BY alp_timestamp DESC;" );
  while (my @row = $result->fetchrow) { if ($row[0]) { 			# get all curator evidence	# for Carol 2006 05 17
    if ($curators{std}{$row[0]}) { $row[0] = $curators{std}{$row[0]}; $row[0] =~ s/two/WBPerson/g; }	# convert to WBPerson
    $evidence .= "Curator_confirmed\t\"$row[0]\"\n"; } }
  $result = $conn->exec( "SELECT alp_person FROM alp_person WHERE joinkey = '$joinkey' AND alp_box = '$alp_box' ORDER BY alp_timestamp DESC;" );
  my @row = $result->fetchrow; 
  if ($row[0]) { 						# get the latest person evidence
    my @people = split/,/, $row[0];				# break up into people if more than one person
    foreach my $person (@people) { 
      my ($check_evi) = $person =~ m/WBPerson(\d+)/; 
      unless ($check_evi) { $evidence .= "// ERROR Person $person NOT a valid person\n"; next ; }
      unless ($existing_evidence{person}{$check_evi}) { $evidence .= "// ERROR Person $person NOT a valid person\n"; next ; }
      $person =~ s/^\s+//g; $evidence .= "Person_evidence\t\"$person\"\n"; } }
  $result = $conn->exec( "SELECT alp_paper FROM alp_paper WHERE joinkey = '$joinkey' AND alp_box = '$alp_box' ORDER BY alp_timestamp DESC;" );
  @row = $result->fetchrow; 
  if ($row[0]) { 						# get the latest paper evidence
#     if ($row[0] =~ m/(WBPaper\d+)/) { $evidence .= "Paper_evidence\t\"$1\"\n"; } 	# why did I ever do this ?
    if ($row[0] =~ m/WBPaper\d+/) { 
        my ($check_evi) = $row[0] =~ m/WBPaper(\d+)/;
        if ($existing_evidence{paper}{$check_evi}) {
            $evidence .= "Paper_evidence\t\"WBPaper$check_evi\"\n"; } 	# 2006 08 23 get the WBPaper, not the data with comments
          else { $evidence .= "// ERROR Paper $row[0] NOT a valid paper\n"; } }
      else { $err_text .= '\/\/ ' . "$joinkey has bad paper data $row[0]\n"; return "ERROR"; } }
  if ($evidence) { return $evidence; }
} # sub getEvidence

sub populateExistingEvidence {		# get hash of valid wbpersons and wbpapers
  my $result = $conn->exec( "SELECT * FROM two ORDER BY two" );
  while (my @row = $result->fetchrow) {
    $existing_evidence{person}{$row[1]}++; }
  $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $existing_evidence{paper}{$row[0]}++; }
      else { delete $existing_evidence{paper}{$row[0]}; } }
} # sub populateExistingEvidence



sub getHeader {				# get .ace object header, type and finalname
  my ($joinkey) = @_; my %tempHash; my $finalname = 'no_final_name'; my $type = ''; 
  my $result = $conn->exec( "SELECT alp_finalname FROM alp_finalname WHERE joinkey = '$joinkey' ORDER BY alp_timestamp DESC;" );
  my @row = $result->fetchrow; if ($row[0]) { $finalname = $row[0]; }
  $result = $conn->exec( "SELECT alp_type FROM alp_type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp DESC;" );
  @row = $result->fetchrow; if ($row[0]) { $type = $row[0]; }
  my $header .= "$type : \"$finalname\"\n";
  if ($header =~ m/Allele/) { $header =~ s/Allele/Variation/g; }
  return ($header, $finalname);
} # sub getHeader

sub filterAce {
  my $identifier = shift;
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\n/) { $identifier =~ s/\n/ /g; }
  if ($identifier =~ m/\r/) { $identifier =~ s/\r/ /g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/:/) { $identifier =~ s/:/\\:/g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/,/) { $identifier =~ s/,/\\,/g; }
  if ($identifier =~ m/-/) { $identifier =~ s/-/\\-/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  return $identifier;
} # sub filterAce

sub queryPostgres {					# populate %theHash with data for this joinkey
  my $joinkey = shift;
  $theHash{group_mult}{html_value} = 0; $theHash{horiz_mult}{html_value} = 0;
  foreach my $type (@genParams) {
    delete $theHash{$type}{html_value};                 # only wipe out the values, not the whole subhash  2005 11 16
    my $result = $conn->exec( "SELECT * FROM alp_$type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) { $theHash{$type}{html_value} = $row[1]; }
        else { $theHash{$type}{html_value} = ''; } } }
#   if ($theHash{finalname}{html_value}) { print "Based on postgres, finalname should be : $theHash{finalname}{html_value}<BR>\n"; }
#   if ($theHash{wbgene}{html_value}) { print "Based on postgres, wbgene should be : $theHash{wbgene}{html_value}<BR>\n"; }
  foreach my $type (@groupParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) {
      my $g_type = $type . '_' . $row[1] ;
      delete $theHash{$g_type}{html_value};
      if ($row[2]) {
          $theHash{$g_type}{html_value} = $row[2];
          if ($theHash{horiz_mult}{html_value}) { if ($row[1] > $theHash{horiz_mult}{html_value}) { $theHash{horiz_mult}{html_value} = $row[1]; } } }
        else { $theHash{$g_type}{html_value} = ''; } } }
  foreach my $type (@multParams) {
    my $result = $conn->exec( "SELECT * FROM alp_$type WHERE joinkey = '$joinkey' ORDER BY alp_timestamp;" );
    while (my @row = $result->fetchrow) {
      my $ts_type = $type . '_' . $row[1] . '_' . $row[2];
      delete $theHash{$ts_type}{html_value};
      if ($row[3]) {
          $theHash{$ts_type}{html_value} = $row[3];
          if ($row[1] > $theHash{group_mult}{html_value}) { $theHash{group_mult}{html_value} = $row[1]; }
          if ($row[2] > $theHash{horiz_mult}{html_value}) { $theHash{horiz_mult}{html_value} = $row[2]; } }
        else { $theHash{$ts_type}{html_value} = ''; } } }
} # sub queryPostgres

sub populateCurators {					# get curators to convert to WBPersons
  my $result = $conn->exec( "SELECT * FROM two_standardname; " );
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0];
  } # while (my @row = $result->fetchrow)
  $curators{std}{'Juancarlos Testing'} = 'two1823';
} # sub populateCurators


1;

# attach evidence with timestamps to data with timestamp only and viceversa
