#!/usr/bin/perl -w

# Adapt wpa_match.pm to find duplicates already in postgres.  2005 09 06
#
# Change to match full author name instead of just parts of author names.
# For Daniel.  2005 10 10

use strict;
use diagnostics;
use Pg;
use Jex;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();
my $outfile = "outfile." . $date;
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";




my %keys_wpa; 

my %cdsToGene;


1;

sub getWpa {
  my %got_joinkey;
  my $result = $conn->exec( "SELECT joinkey, wpa_title FROM wpa_title WHERE wpa_title IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{title}{$row[0]}) { next; }
    if ($row[1]) {
      my $key_title = $row[1];
      if ($key_title =~ m/C\.? ?[Ee]legans\b/) { $key_title =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $key_title = substr($key_title, 0, 20);		# get just 20 chars
      $key_title = lc($key_title);
      $keys_wpa{title}{$key_title}{$row[0]}++; 
      $keys_wpa{joinkey}{$row[0]}{title} = $key_title;
      $got_joinkey{title}{$row[0]}++; } }

  $result = $conn->exec( "SELECT joinkey, wpa_abstract FROM wpa_abstract WHERE wpa_abstract IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{abstract}{$row[0]}) { next; }
    if ($row[1]) {
      my $key_abstract = $row[1];
      if ($key_abstract =~ m/C\.? ?[Ee]legans\b/) { $key_abstract =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $key_abstract = lc($key_abstract);
      if ($key_abstract =~ m/\W/) { $key_abstract =~ s/\W//g; }
      my $key_abstract_front = substr($key_abstract, 0, 20);		# get just 20 chars
      my $key_abstract_end = substr($key_abstract, -20);		# get just 20 chars
      $key_abstract = "$key_abstract_front\t$key_abstract_end";
      $keys_wpa{abstract}{$key_abstract}{$row[0]}++; 
      $keys_wpa{joinkey}{$row[0]}{abstract} = $key_abstract;
      $got_joinkey{abstract}{$row[0]}++; } }

  $result = $conn->exec( "SELECT joinkey, wpa_volume FROM wpa_volume WHERE wpa_volume IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{volume}{$row[0]}) { next; }
    if ($row[1]) {
      my $key_volume = $row[1];
      if ($key_volume =~ m/^\s+/) { $key_volume =~ s/^\s+//g; }
      if ($key_volume =~ m/^\-COMMENT.*$/) { $key_volume =~ s/^\-COMMENT.*$//g; }
      if ($key_volume =~ m/^(\w+)/) { $key_volume = $1; } # else { print STDERR "ODD VOLUME $row[0] -= $row[1] =-\n"; }
      $keys_wpa{volume}{$key_volume}{$row[0]}++;
      $keys_wpa{joinkey}{$row[0]}{volume} = $key_volume;
      $got_joinkey{volume}{$row[0]}++; } }

  $result = $conn->exec( "SELECT joinkey, wpa_pages FROM wpa_pages WHERE wpa_pages IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  while (my @row = $result->fetchrow) {
    if ($got_joinkey{pages}{$row[0]}) { next; }
    if ($row[1]) { 
      my $key_pages = $row[1];
      if ($key_pages =~ m/^\s+/) { $key_pages =~ s/^\s+//g; }
      if ($key_pages =~ m/^\-COMMENT.*$/) { $key_pages =~ s/^\-COMMENT.*$//g; }
      if ($key_pages =~ m/^(\w+)/) { $key_pages = $1; } # else { print STDERR "ODD PAGES $row[0] -= $row[1] =-\n"; }
      $keys_wpa{pages}{$key_pages}{$row[0]}++;
      $keys_wpa{joinkey}{$row[0]}{pages} = $key_pages;
      $got_joinkey{pages}{$row[0]}++; } }

  $result = $conn->exec( "SELECT author_id, wpa_author_index FROM wpa_author_index WHERE wpa_author_index IS NOT NULL AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
  while (my @row = $result->fetchrow) {		# store author_id -> author_name mappings in  $keys_wpa{author_id}{ a_id } = a_name
    if ($row[1] =~ m/^\s+/) { $row[1] =~ s/^\s+//g; }
    if ($row[1] =~ m/^\-COMMENT.*$/) { $row[1] =~ s/^\-COMMENT.*$//g; }
print "AID $row[0]\t$row[1]\n";
    if ($row[1]) { $keys_wpa{author_id}{$row[0]} = $row[1]; } }

#   my $current_joinkey = 0; my $got_an_author = 0;
#   $result = $conn->exec( "SELECT joinkey, wpa_author, wpa_order, wpa_valid FROM wpa_author ORDER BY joinkey, wpa_order, wpa_timestamp;" ); 
#   my %temp_hash; my $current_order = 0; my $flag_valid = 0; my $author_id = 0; my $joinkey = 0;
#   while (my @row = $result->fetchrow) {
#     my $joinkey = $row[0];
#     if ( ($joinkey eq $current_joinkey) && ($got_an_author) ) { next; }
#     unless ($current_joinkey) { $current_joinkey = $row[0]; }		# if first entry, set to current_joinkey
#     if ($current_joinkey ne $joinkey) { $current_joinkey = $joinkey; }	# new joinkey, set to current
#   }
  $result = $conn->exec( "SELECT joinkey, wpa_author, wpa_order, wpa_valid FROM wpa_author ORDER BY joinkey, wpa_order, wpa_timestamp;" ); 
  my %temp_hash; my $current_order = 0; my $flag_valid = 0; my $author_id = 0; my $joinkey = 0;
  while (my @row = $result->fetchrow) {
    if ($row[0] > $joinkey) {		# if new joinkey
      unless ($joinkey) { $joinkey = $row[0]; next; }	# skip first entry when there is no joinkey
      my $key_author_name = '';				# init they key for author names, if a_name for a_id, grab the a_name
      if ($keys_wpa{author_id}{$author_id}) { $key_author_name = $keys_wpa{author_id}{$author_id}; }

        # This matches the full author name		# Daniel doesn't want matches by single letters in author names  2005 10 10
      if ($key_author_name =~ m/(\w+)/) { 				# if the name matches words
        my $key_author_part = $key_author_name;
          $keys_wpa{joinkey}{$row[0]}{author} = $key_author_part;
          $keys_wpa{author}{$key_author_part}{$joinkey}++; } 		# store previous author name part and joinkey

#         # This matches any ``word'' in an author name
#       if ($key_author_name =~ m/(\w+)/) { 				# if the name matches words
#         my (@author_parts) = $key_author_name =~ m/(\w+)/g; 		# get parts of author since could be first last or last first
#         foreach my $key_author_part (@author_parts) {			# take each author part
#           $keys_wpa{joinkey}{$row[0]}{author} = $key_author_part;
#           $keys_wpa{author}{$key_author_part}{$joinkey}++; } } 		# store previous author name part and joinkey
      $flag_valid = 0; $current_order = 0; $author_id = 0; $joinkey = $row[0]; }	# reset flags and get new joinkey

    if ( ($row[2] > $current_order) && ($flag_valid) ) { next; }	# if done with current order and is valid, done with this joinkey
    if ($row[2] > $current_order) { $current_order = $row[2]; }		# if done with current order but not valid, switch order

    if ($row[3] eq 'valid') { $author_id = $row[1]; $flag_valid = 1; }	# if valid, save the id and set valid
      else { $author_id = 0; $flag_valid = 0; } }					# if not valid clear the id and set invalid
} # sub getWpa

&getWpa();
foreach my $joinkey (sort keys %{ $keys_wpa{joinkey} }) {
  my $title = $keys_wpa{joinkey}{$joinkey}{title};
  my $abstract = $keys_wpa{joinkey}{$joinkey}{abstract};
  my $volume = $keys_wpa{joinkey}{$joinkey}{volume};
  my $pages = $keys_wpa{joinkey}{$joinkey}{pages};
  my $author = $keys_wpa{joinkey}{$joinkey}{author};
  my $log_text = &matchLine($joinkey, $title, $abstract, $volume, $pages, $author);
  if ( ($log_text =~ m/FLAG/) || ($log_text =~ m/MERGE/) ) { print OUT "$log_text"; }
}
close (OUT) or die "Cannot close $outfile : $!";

  
sub matchLine {		# match endnote line to wpa_ data
  my ($joinkey, $key_title, $abstract, $key_volume, $key_pages, $key_author) = @_;
#   my ($flag, $line, $two_number) = @_;
#   unless ($two_number) { $two_number = 'two1823'; }
#   my ($cgc, $pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type);
#   $volume = ''; $authors = ''; $pages = ''; $title = '';
  my $log_text = ''; my $manual_text = '';
#   my $manual_checkfile = 'manual_check_file.endnote';
#   open (CHE, ">>$manual_checkfile") or die "Cannot open $manual_checkfile : $!";
# 
#   if ($flag eq 'cgc') {
#     ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type) = split/\t/, $line; }
#   if ($flag eq 'pmid') {
#     ($pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type) = split/\t/, $line; }
# 
#   my $key_author = ''; my $key_volume = ''; my $key_pages = ''; my $key_title = '';
#   if ($authors) { if ($authors =~ m/^(\w+)/) { $key_author = $1; } }
#   if ($volume) { if ($volume =~ m/^(\w+)/) { $key_volume = $1; } }
#   if ($pages) { if ($pages =~ m/^(\w+)/) { $key_pages = $1; } }
#   if ($title) { $key_title = $title;  }
  if ($key_title) { 
      if ($key_title =~ m/C\.? ?[Ee]legans\b/) { $key_title =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $key_title = substr($key_title, 0, 20);		# get just 20 chars
      $key_title = lc($key_title); }
    else { $key_title = ''; }
#   $log_text .= "$line\n";
  unless ($key_author) { $key_author = ''; } unless ($key_volume) { $key_volume = ''; }
  unless ($key_pages) { $key_pages = ''; } unless ($key_title) { $key_title = ''; }
  $log_text .= "J $joinkey : A : $key_author . V : $key_volume . P : $key_pages . T : $key_title\n"; 

  my %matching_joinkeys;
  if ($key_title) { if ( $keys_wpa{title}{$key_title} ) {
    foreach my $joinkey (sort keys %{ $keys_wpa{title}{$key_title} }) { $matching_joinkeys{$joinkey}++; } } }
  if ($key_author) { if ( $keys_wpa{author}{$key_author} ) { 
    foreach my $joinkey (sort keys %{ $keys_wpa{author}{$key_author} }) { $matching_joinkeys{$joinkey}++; } } }
  if ($key_volume) { if ( $keys_wpa{volume}{$key_volume} ) { 
    foreach my $joinkey (sort keys %{ $keys_wpa{volume}{$key_volume} }) { $matching_joinkeys{$joinkey}++; } } }
  if ($key_pages) { if ( $keys_wpa{pages}{$key_pages} ) { 
    foreach my $joinkey (sort keys %{ $keys_wpa{pages}{$key_pages} }) { $matching_joinkeys{$joinkey}++; } } }
  my $full_match = 0; 
  my @four_matches; my @three_matches; my @two_matches;		# joinkeys that match four and three and two fields
  foreach my $other_joinkey (sort { $matching_joinkeys{$b} <=> $matching_joinkeys{$a} || $a cmp $b } keys %matching_joinkeys) {
    if ($other_joinkey eq $joinkey) { next; }			# skip self
    if ($matching_joinkeys{$other_joinkey} == 4) { 
      push @four_matches, $other_joinkey;
      $full_match++; }
    if ($matching_joinkeys{$other_joinkey} == 3) { push @three_matches, $other_joinkey; }
    if ($matching_joinkeys{$other_joinkey} == 2) { push @two_matches, $other_joinkey; }
  } # foreach my $other_joinkey (sort { $matching_joinkeys{$b} <=> $matching_joinkeys{$a} || $a cmp $b } keys %matching_joinkeys)
  if ($full_match) {
    if (scalar(@four_matches) > 1) { 
      my $joins = join", ", @four_matches; 
      $log_text .= "TOO MANY wbpapers match four fields $joins\n\n"; 
      my $date = &getSimpleSecDate(); }
#       $manual_text .= "many\t$joins\t$flag\t$line\t$two_number\t$date\n"; 
    else { 
#       &mergeEntry($two_number, $four_matches[0], $flag, $line);
      if ($four_matches[0] ne $joinkey) { $log_text .= "MERGE WITH $four_matches[0]\n\n"; } } }
  elsif ($three_matches[0]) {
      my $joins = join", ", @three_matches; 
      if ($joins ne $joinkey) { $log_text .= "FLAG three fields : $joins\n\n"; }
      my $date = &getSimpleSecDate(); }
#       $manual_text .= "possible three\t$joins\t$flag\t$line\t$two_number\t$date\n"; 
  elsif ($two_matches[0]) {
    if ($abstract) {
      if ($abstract =~ m/C\.? ?[Ee]legans\b/) { $abstract =~ s/C\.?  ?[Ee]legans\b/Caenorhabditis elegans/g; }
      $abstract = lc($abstract);
      if ($abstract =~ m/\W/) { $abstract =~ s/\W//g; }
      my $abstract_front = substr($abstract, 0, 20);		# get just 20 chars
      my $abstract_end = substr($abstract, -20);		# get just 20 chars
      $abstract = "$abstract_front\t$abstract_end";
      my @possible_matches;
      foreach my $possible_joinkey (@two_matches) {
        if ($keys_wpa{abstract}{$abstract}{$possible_joinkey}) { push @possible_matches, $possible_joinkey; } }
      my $date = &getSimpleSecDate();
      if ($possible_matches[0]) {
          my $joins = join", ", @possible_matches; 
#           $manual_text .= "possible two plus abstract\t$joins\t$flag\t$line\t$two_number\t$date\n"; 
          if ($joinkey ne $joins) { $log_text .= "FLAG two fields plus abstract : $joins\n\n"; } }
        else {
#           my $joinkey = &createEntry($two_number, $flag, $line);
#           $log_text .= "LOW matching, two matches, no abstract create entry $joinkey\n\n";
        } }
    else { 
#       my $joinkey = &createEntry($two_number, $flag, $line);
#       $log_text .= "LOW matching, two matches, no abstract create entry $joinkey\n\n";
    } }
  else {
#       my $joinkey = &createEntry($two_number, $flag, $line);
#       $log_text .= "LOW matching, one or less matches, create entry $joinkey\n\n"; 
  }
#   print CHE $manual_text;
#   close (CHE) or die "Cannot close $manual_checkfile : $!";
  return ($log_text);
} # sub matchLine

sub mergeEntry {
  my ($two_number, $joinkey, $flag, $line) = @_;
  my ($cgc, $pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type);
  if ($flag eq 'cgc') {
    ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type) = split/\t/, $line; }
  if ($flag eq 'pmid') {
    ($pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type) = split/\t/, $line; }
#   if ($cgc) { &addPg($two_number, $joinkey, 'wpa_identifier', "cgc$cgc"); }
#   if ($pmid) { &addPg($two_number, $joinkey, 'wpa_identifier', "pmid$pmid"); }
# 
#   if ($title) { &checkPg($two_number, $joinkey, 'title', 'wpa_title', $title); }
#   if ($journal) { &checkPg($two_number, $joinkey, 'journal', 'wpa_journal', $journal); }
#   if ($volume) { &checkPg($two_number, $joinkey, 'volume', 'wpa_volume', $volume); }
#   if ($pages) { &checkPg($two_number, $joinkey, 'pages', 'wpa_pages', $pages); }
#   if ($year) { &checkPg($two_number, $joinkey, 'year', 'wpa_year', $year); }
#   if ($type) { &checkPg($two_number, $joinkey, 'type', 'wpa_type', $type); }
#   if ($abstract) { &checkPg($two_number, $joinkey, 'abstract', 'wpa_abstract', $abstract); }
#   if ($authors) { &checkPg($two_number, $joinkey, 'authors', 'wpa_author', $authors); }
#   if ($genes) { &checkPg($two_number, $joinkey, 'genes_theresa', 'wpa_gene', $genes); }
} # sub mergeEntry

sub createEntry {
  my ($two_number, $flag, $line) = @_;
  my ($cgc, $pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type);
  if ($flag eq 'cgc') {
    ($cgc, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type) = split/\t/, $line; }
  if ($flag eq 'pmid') {
    ($pmid, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type) = split/\t/, $line; }

  my $result = $conn->exec( "SELECT * FROM wpa ORDER BY joinkey DESC;" );
  my @row = $result->fetchrow; 
  my $wpa = $row[0] + 1;
  my $joinkey = &padZeros($wpa);

#   &addPg($two_number, $joinkey, 'wpa', $wpa);
#   if ($cgc) { &addPg($two_number, $joinkey, 'wpa_identifier', "cgc$cgc"); }
#   if ($pmid) { &addPg($two_number, $joinkey, 'wpa_identifier', "pmid$pmid"); }
#   if ($title) { &addPg($two_number, $joinkey, 'wpa_title', $title); }
#   if ($journal) { &addPg($two_number, $joinkey, 'wpa_journal', $journal); }
#   if ($volume) { &addPg($two_number, $joinkey, 'wpa_volume', $volume); }
#   if ($pages) { &addPg($two_number, $joinkey, 'wpa_pages', $pages); }
#   if ($year) { &addPg($two_number, $joinkey, 'wpa_year', $year); }
#   if ($type) { &addPg($two_number, $joinkey, 'wpa_type', $type); }
#   if ($abstract) { &addPg($two_number, $joinkey, 'wpa_abstract', $abstract); }
#   if ($authors) { &addPg($two_number, $joinkey, 'wpa_author', $authors); }
#   if ($genes) { &addPg($two_number, $joinkey, 'add_gene_theresa', $genes); }

  return ($joinkey);
} # sub createEntry

sub padZeros {
  my $joinkey = shift;
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros







