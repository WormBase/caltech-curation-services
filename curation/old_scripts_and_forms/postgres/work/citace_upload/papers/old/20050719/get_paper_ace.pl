#!/usr/bin/perl -w

# This seems to work and has been ported to perl module get_paper_ace.pm
# at /home/postgres/work/citace_upload/papers/
# 2005 07 13


use strict;
use diagnostics;
use Pg;
use Jex;
use LWP;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 147;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
print "START $date -> Estimate $hour:$min:$sec\n";

my $result;

my %theHash;
my %author_index;
my %type_index;

my @generic_tables = qw( wpa_identifier wpa_title wpa_publisher wpa_journal wpa_volume wpa_pages wpa_year wpa_fulltext_url wpa_abstract wpa_affiliation wpa_hardcopy wpa_comments wpa_editor wpa_nematode_paper wpa_contained_in wpa_contains wpa_keyword wpa_erratum wpa_in_book wpa_type wpa_author );

my $ace_entry = '';

my $outfile = 'papers.ace';
my $outlong = 'abstracts.ace';
my $errfile = 'err.out';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
open (LON, ">$outlong") or die "Cannot create $outlong : $!\n";
open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";

print "STARTING AUTHOR\n";

$result = $conn->exec( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp ;" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $type_index{$row[0]} = $row[1]; } }

$result = $conn->exec( "SELECT * FROM wpa_author_index ORDER BY wpa_timestamp ;" );
my %author_valid;
while (my @row = $result->fetchrow) {
  $author_valid{valid}{$row[0]} = $row[3];
  $author_valid{name}{$row[0]} = $row[1];
  $author_valid{affiliation}{$row[0]} = $row[2];
} # while (my @row = $result->fetchrow)
foreach my $author_id (sort keys %{ $author_valid{valid} }) {
  if ($author_valid{valid}{$author_id} eq 'valid') {
    my ($author_name) = &filterAce($author_valid{name}{$author_id});
    if ($author_name =~ m/^-C/) {
        $author_index{$author_id} = "Author\t $author_name\""; }
      else {
        $author_index{$author_id} = "Author\t \"$author_name\""; }
    if ($author_valid{affiliation}{$author_id}) { 
      my ($affi) = &filterAce($author_valid{affiliation}{$author_id}); 
#       $author_index{$author_id} .= " Affiliation_address \"$author_valid{affiliation}{$author_id}\""; 
      $author_index{$author_id} .= " Affiliation_address \"$affi\""; }
    $author_index{$author_id} .= "\n"; }
} # foreach my $author_id (sort keys %{ $author_valid{valid} })

print "DONE WITH AUTHOR VALID\n";

my $count;
$result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp ;" );
while (my @row = $result->fetchrow) {
  $count++;
#   if ($count > 1000) { last; }
  $theHash{valid}{$row[0]} = $row[3];
} # while (my @row = $result->fetchrow)

print "STARTING\n";

foreach my $joinkey (sort keys %{ $theHash{valid} }) {
#   next unless $joinkey eq '00004169';		# DELETE ME
  if ($theHash{valid}{$joinkey} eq 'valid') { 
    $ace_entry = '';
    my ($entry) = &getStuff($joinkey, $ace_entry); 
    if ($entry) { print OUT "Paper : \"WBPaper$joinkey\"\n$entry\n"; } 
  } # if ($theHash{valid}{$joinkey} eq 'valid')
} # foreach my $joinkey (sort keys %{ $theHash{valid} })

close (OUT) or die "Cannot close $outfile : $!";
close (LON) or die "Cannot close $outlong : $!";
close (ERR) or die "Cannot close $errfile : $!";

$date = &getSimpleSecDate();
my $end_time = time;
my $diff_time = $end_time - $start_time;
print "DIFF $diff_time\n";
print "END $date\n";





sub getStuff {
  my ($joinkey, $ace_entry) = @_;
  ($ace_entry) = &getIdentifier($joinkey, $ace_entry);
  (my $title, $ace_entry) = &getTitle($joinkey, $ace_entry);
  ($ace_entry) = &getPublisher($joinkey, $ace_entry);
  (my $journal, $ace_entry) = &getJournal($joinkey, $ace_entry);
  ($ace_entry) = &getVolume($joinkey, $ace_entry);
  ($ace_entry) = &getPages($joinkey, $ace_entry);
  (my $year, $ace_entry) = &getYear($joinkey, $ace_entry);
  ($ace_entry) = &getAbstract($joinkey, $ace_entry);
  ($ace_entry) = &getAffiliation($joinkey, $ace_entry);
  ($ace_entry) = &getEditor($joinkey, $ace_entry);
  ($ace_entry) = &getContained_in($joinkey, $ace_entry);
  ($ace_entry) = &getContains($joinkey, $ace_entry);
  ($ace_entry) = &getKeyword($joinkey, $ace_entry);
  ($ace_entry) = &getType($joinkey, $ace_entry);
  (my $author, $ace_entry) = &getAuthor($joinkey, $ace_entry);
  ($ace_entry) = &getGene($joinkey, $ace_entry);
  ($ace_entry) = &getEimearBriefCitation($author, $year, $journal, $title, $ace_entry); 
  ($ace_entry) = &getErratum($joinkey, $ace_entry);
  ($ace_entry) = &getIn_book($joinkey, $ace_entry);
  if ($ace_entry) { return $ace_entry; }
} # sub getStuff


sub getGene {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{value}{$row[1]} = $row[3]; $tempHash{evidence}{$row[1]} = $row[2]; }
  foreach my $identifier (sort keys %{ $tempHash{evidence} } ) {
    if ($tempHash{value}{$identifier} eq 'valid') { 
      my ($gene, $cds, $evidence);
      if ($identifier =~ m/^(.*?)\t(.*?)$/) { $gene = $1; $cds = $2; }
        else { $gene = $identifier; }
      if ($tempHash{evidence}{$identifier}) { 
        ($evidence) = &filterAce($tempHash{evidence}{$identifier}); 
        if ($evidence =~ m/Inferred_automatically\"/) { $evidence =~ s/Inferred_automatically\"/Inferred_automatically/g; }
        elsif ($evidence =~ m/Author_evidence\"/) { $evidence =~ s/Author_evidence\"/Author_evidence/g; }
        elsif ($evidence =~ m/Person_evidence\"/) { $evidence =~ s/Person_evidence\"/Person_evidence/g; }
        $evidence = " $evidence\""; }
      if ($gene =~ m/\(.*?\)$/) { $gene =~ s/\(.*?\)$//; }	# take out 3-letter locus
      $ace_entry .= "Gene\t \"$gene\"";
      if ($evidence) { $ace_entry .= $evidence; }
      $ace_entry .= "\n"; 
      if ($cds) {
        $ace_entry .= "CDS\t \"$cds\""; 
        if ($evidence) { $ace_entry .= $evidence; }
        $ace_entry .= "\n"; }
    } # if ($tempHash{$identifier} eq 'valid') 
  } # foreach my $identifier (sort keys %tempHash)
  return $ace_entry;
} # sub getGene

sub getEimearBriefCitation {
  my ($author, $year, $journal, $title, $ace_entry) = @_;
#       $aut = $authors[0];
      my @chars = split //, $title;
      my $brief_title = '';                     # brief title (70 chars or less)
      if ( scalar(@chars) < 70 ) {
          $brief_title = $title;
      } else {
          my $i = 0;                            # letter counter (want less than 70)
          my $word = '';                        # word to tack on (start empty, add characters)
          while ( (scalar(@chars) > 0) && ($i < 70) ) { # while there's characters, and less than 70 been read
              $brief_title .= $word;            # add the word, because still good (first time empty)
              $word = '';                       # clear word for next time new word is used
              my $char = shift @chars;          # read a character to start / restart check
              while ( (scalar(@chars) > 0) && ($char ne ' ') ) {        # while not a space and still chars
                  $word .= $char; $i++;         # build word, add to counter (less than 70)
                  $char = shift @chars;         # read a character to check if space
              } # while ($_ ne '')              # if it's a space, exit loop
              $word .= ' ';                     # add a space at the end of the word
          } # while ( (scalar(@chars) > 0) && ($i < 70) )
          $brief_title = $brief_title . "....";
      }
      if ($year =~ m/ -C .*$/) { $year =~ s/ -C .*$//g; }
      my $brief_citation = '';
      if ( length($author) > 0) { $brief_citation .= $author; }
      if ( length($year) > 0) { $brief_citation .= " ($year) "; }
      if ( length($journal) > 0) { $brief_citation .= "$journal"; }
      if ( length($brief_title) > 0) { $brief_citation .= " \\\"$brief_title\\\""; }
      if ($brief_citation) { $ace_entry .= "Brief_citation\t \"$brief_citation\"\n"; }
#       $out .= "Brief_citation\t\"".$aut unless (length($aut) == 0);
#        $out .= " et.al" if (scalar(@authors) => 2);
#       $out .=  " (".$year.") " unless (length($year) == 0);
#       $out .= $journal." \\\"".$brief_title."\\\"\"\n";
  return $ace_entry;
} # sub getEimearBriefCitation


  ### NON UNIQUE TYPES ###

sub getAuthor {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_author WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  my $author = ''; my $author_count = 0;
  foreach my $identifier (sort { $a<=>$b } keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      $author_count++;
      if ($author_count == 1) { $author = $author_valid{name}{$identifier}; }
      if ($author_count == 2) { $author .= " et.al"; }
      $ace_entry .= $author_index{$identifier}; } }
  return ($author, $ace_entry); 
} # sub getAuthor

sub getIn_book {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_in_book WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      my ($entry) = &getStuff($identifier, ''); 
      if ($entry) { 
        my (@entry) = split/\n/, $entry;
        if ($entry =~ m/\t/) { $entry =~ s/\t//; }	# take out first tab, which doesn't show in .ace dumps
        foreach my $line (@entry) { 
          if ($line =~ m/\t/) { $line =~ s/\t//; }	# take out first tab, which doesn't show in .ace dumps
          $ace_entry .= "In_book\t $line\n"; } } } }
  return $ace_entry;
} # sub getIn_book

sub getErratum {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_erratum WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      my ($entry) = &getStuff($identifier, ''); 
      if ($entry) { 
        my (@entry) = split/\n/, $entry;
        foreach my $line (@entry) { 
          if ($line =~ m/\t/) { $line =~ s/\t//; }	# take out first tab, which doesn't show in .ace dumps
          $ace_entry .= "Erratum\t $line\n"; } } } }
  return $ace_entry;
} # sub getErratum

sub getKeyword {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_keyword WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      $ace_entry .= "Keyword\t \"$identifier\"\n"; } }
  return $ace_entry;
} # sub getKeyword

sub getContained_in {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_contained_in WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      $ace_entry .= "Contained_in\t \"$identifier\"\n"; } }
  return $ace_entry;
} # sub getContained_in

sub getContains {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_contains WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      $ace_entry .= "Contains\t \"$identifier\"\n"; } }
  return $ace_entry;
} # sub getContains

sub getEditor {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_editor WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      $ace_entry .= "Editor\t \"$identifier\"\n"; } }
  return $ace_entry;
} # sub getEditor

sub getAffiliation {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_affiliation WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      $ace_entry .= "Affiliation\t \"$identifier\"\n"; } }
  return $ace_entry;
} # sub getAffiliation

sub getAbstract {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_abstract WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      print LON "LongText : \"WBPaper$joinkey\"\n\n$identifier\n\n***LongTextEnd***\n\n\n";
      $ace_entry .= "Abstract\t \"WBPaper$joinkey\"\n"; } }
  return $ace_entry;
} # sub getAbstract

sub getIdentifier {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      if ($identifier =~ m/^c?wbg/) { $ace_entry .= "WBG_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^cgc/) { $ace_entry .= "CGC_name\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^pmid/) { $identifier =~ s/^pmid//g; $ace_entry .= "PMID\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^med/) { $identifier =~ s/^med//g; $ace_entry .= "Medline_name\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^WBPaper/) { $ace_entry .= "Old_WBPaper\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^eawm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^ecwm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^euwm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^jwm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^mcwm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^mwwm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^wcwm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^wm/) { $ace_entry .= "Meeting_abstract\t \"$identifier\"\n"; }
      else  { $ace_entry .= "Other_name\t \"$identifier\"\n"; }
    } # if ($tempHash{$identifier} eq 'valid') 
  } # foreach my $identifier (sort keys %{ $tempHash{$row[1]} })
  return $ace_entry;
} # sub getIdentifier

  ### NON UNIQUE TYPES ###


  ### UNIQUE TYPES ###

sub getTitle {			
    # can't use Tie::IxHash because that stores in entry value.  If x gets entered, then x is made invalid, then y is entered,
    # then x is made valid again, it would show y instead of x, which came latest
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $title = ''; my %valid_entry = ();
  $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_title =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_title FROM wpa_title WHERE wpa_title = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $title = $row2[0];
      print ERR "Multiple valid entries for $joinkey UNIQUE Title USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { print ERR "Multiple valid entries for $joinkey UNIQUE Title : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($title, my @junk) = keys %tempHash; }
    else { 1; }
  if ($title) { 
    ($title) = &filterAce($title);
    $ace_entry .= "Title\t \"$title\"\n"; }
  return ($title, $ace_entry); 
} # sub getTitle

sub getYear {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $year = ''; my %valid_entry = ();
  $result = $conn->exec( "SELECT * FROM wpa_year WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_year =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_year FROM wpa_year WHERE wpa_year = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $year = $row2[0];
      print ERR "Multiple valid entries for $joinkey UNIQUE Year USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { print ERR "Multiple valid entries for $joinkey UNIQUE Year : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($year, my @junk) = keys %tempHash; }
    else { 1; }
  if ($year) {
    ($year) = &filterAce($year);
    if ($year =~ m/\" -C \".*?$/) { $year =~ s/\" -C (\".*?)$/ -C $1\"/; }	# year doesn't have quotes around it, but the comment does
    $ace_entry .= "Year\t $year\n"; }
  return ($year, $ace_entry);
} # sub getYear

sub getJournal {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $journal = ''; my %valid_entry;
  $result = $conn->exec( "SELECT * FROM wpa_journal WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_journal =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_journal FROM wpa_journal WHERE wpa_journal = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $journal = $row2[0];
      print ERR "Multiple valid entries for $joinkey UNIQUE Journal USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { print ERR "Multiple valid entries for $joinkey UNIQUE Journal : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($journal, my @junk) = keys %tempHash; }
    else { 1; }
  if ($journal) {
    ($journal) = &filterAce($journal);
    if ($journal =~ m/^-C/) {
        $ace_entry .= "Journal\t $journal\"\n"; }
      else {
        $ace_entry .= "Journal\t \"$journal\"\n"; } }
  return ($journal, $ace_entry); 
} # sub getJournal


sub getPages {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $pages = ''; my %valid_entry;
  $result = $conn->exec( "SELECT * FROM wpa_pages WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_pages =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_pages FROM wpa_pages WHERE wpa_pages = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $pages = $row2[0];
      print ERR "Multiple valid entries for $joinkey UNIQUE Pages USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { print ERR "Multiple valid entries for $joinkey UNIQUE Pages : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($pages, my @junk) = keys %tempHash; }
    else { 1; }
  if ($pages) {
    ($pages) = &filterAce($pages);
    if ($pages =~ m/^-C/) {
        $ace_entry .= "Page\t $pages\"\n"; }
      else {
        $ace_entry .= "Page\t \"$pages\"\n"; } }
  return $ace_entry;
} # sub getPages

sub getType {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $type = ''; my %valid_entry;
  $result = $conn->exec( "SELECT * FROM wpa_type WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_type =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_type FROM wpa_type WHERE wpa_type = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $type = $row2[0];
      print ERR "Multiple valid entries for $joinkey UNIQUE Type USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { print ERR "Multiple valid entries for $joinkey UNIQUE Type : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($type, my @junk) = keys %tempHash; }
    else { 1; }
  if ($type) {
    if ($type_index{$type}) {
      $ace_entry .= "Type\t \"$type_index{$type}\"\n"; } 
    else { print ERR "Invalid Type Index type $type in $joinkey\n"; } }
  return $ace_entry;
} # sub getType

sub getPublisher {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $publisher = ''; my %valid_entry;
  $result = $conn->exec( "SELECT * FROM wpa_publisher WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_publisher =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_publisher FROM wpa_publisher WHERE wpa_publisher = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $publisher = $row2[0];
      print ERR "Multiple valid entries for $joinkey UNIQUE Publisher USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { print ERR "Multiple valid entries for $joinkey UNIQUE Publisher : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($publisher, my @junk) = keys %tempHash; }
    else { 1; }
  if ($publisher) {
    ($publisher) = &filterAce($publisher);
    $ace_entry .= "Publisher\t \"$publisher\"\n"; }
  return $ace_entry;
} # sub getPublisher

sub getVolume {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $volume = ''; 
  my %valid_entry = (); my %valid_volume;
    # get all stuff from wpa_volume, order by timestamp and store validity for each value, that way only the most recent state of validity is store in the hash
  $result = $conn->exec( "SELECT * FROM wpa_volume WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 		# store valid entries in %valid_entry
      $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
        # query again for all valid entries in descending order, so that only the most recent one is retrieved
      my ($requery) = join"\' OR wpa_volume =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_volume FROM wpa_volume WHERE wpa_volume = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $volume = $row2[0];
      if ($volume =~ m/^(.+)\/\//) {			# only the first part of volume is unique, so it could have multiple secondary parts
        my $unique_part = $1;				# grab the unique part
        foreach my $valid_entry (sort keys %valid_entry) {
            # look at all valid entries, and matching the unique part, store as latest or old
          if ($valid_entry =~ m/^$unique_part/) { $valid_volume{latest}{$valid_entry}++; }
          else { $valid_volume{old}{$valid_entry}++; } } } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($volume, my @junk) = keys %tempHash; $valid_volume{valid}{$volume}++; }
    else { 1; }						# if no volume, don't do anything
  foreach my $volume (sort keys %{ $valid_volume{old} }) {
    ($volume) = &filterAce($volume);			# for all old entries warn that it's not being printed
    print ERR "Multiple valid entries for $joinkey UNIQUE Volume IGNORING : $volume\n"; }
  foreach my $volume (sort keys %{ $valid_volume{latest} }) {
    ($volume) = &filterAce($volume);			# for all latest entries print out
    if ($volume) {
      if ($volume =~ m/^-C/) {
          $ace_entry .= "Volume\t $volume\"\n"; }
        else {
          $ace_entry .= "Volume\t \"$volume\"\n"; } } }
  return $ace_entry;
} # sub getVolume

   ### UNIQUE TYPES ###


sub filterAce {
  my $identifier = shift;
  my $comment = '';
  if ($identifier =~ m/-COMMENT (.*)/) { $comment = $1; $identifier =~ s/-COMMENT .*//; }
  if ($identifier =~ m/HTTP:\/\//i) { $identifier =~ s/HTTP:\/\//PLACEHOLDERASDF/g; }
#   if ($identifier =~ m/\" -C \"/) { $identifier =~ s/\" -C \"/PLACEHOLDERASDF/g; }
#   if ($identifier =~ m/^(.*?)\/\/-C\/\/(.*?)$/) {
#     my $leader = $1; my $trail = $2;
#     if ($leader =~ m/\/\//) { $leader =~ s/\/\//" "/g; }
#     if ($trail =~ m/\/\//) { $trail =~ s/\/\// /g; }
#     $identifier = "$leader\" -C \"$trail"; return $identifier; }
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
  if ($identifier =~ m/\\\/\\\//) { $identifier =~ s/\\\/\\\//" "/g; }
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
#   if ($identifier =~ m/PLACEHOLDERASDF/) { $identifier =~ s/PLACEHOLDERASDF/\" -C \"/g; }
  if ($identifier =~ m/PLACEHOLDERASDF/) { $identifier =~ s/PLACEHOLDERASDF/HTTP:\\\/\\\//g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  if ($comment) {
    if ($identifier =~ m/[^"]$/) { $identifier .= "\" "; }
    $identifier .= "-C \"$comment"; }
  return $identifier;
} # sub filterAce


__END__

my @two_tables = qw(two_firstname two_middlename two_lastname two_street two_city two_state two_post two_country two_institution two_mainphone two_labphone two_officephone two_otherphone two_fax two_email two_old_email two_lab two_oldlab two_left_field two_unable_to_contact two_privacy two_aka_firstname two_aka_middlename two_aka_lastname two_apu_firstname two_apu_middlename two_apu_lastname two_webpage);

my $highest_two_val = '4000';
my $lowest_two_val = '0';

my $result;
my @dates = ();

my $error_file = 'errors_in_person.ace';

open (ERR, ">$error_file") or die "Cannot create $error_file : $!"; 

my %paperHash;
&populatePaperHash;

my %convertToWBPaper;	# key cgc or pmid or whatever, value WBPaper
&readConvertions();


for (my $i = $lowest_two_val; $i < $highest_two_val; $i++) {
  my $joinkey = 'two' . $i;
  $result = $conn->exec( "SELECT * FROM two_hide WHERE joinkey = '$joinkey' AND two_hide IS NOT NULL;" );
  my @row = $result->fetchrow;
  if ($row[2]) { next; }		# skip if meant to hide
    # added two IS NOT NULL because there are three people that do not want to be displayed
  $result = $conn->exec( "SELECT * FROM two WHERE joinkey = '$joinkey' AND two IS NOT NULL;" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 				# if two exists
      @dates = ();
      print "Person : \"WBPerson$i\"\n"; 

      &namePrint($joinkey);
      &akaPrint($joinkey);
      &labPrint($joinkey);
      &streetPrint($joinkey);
      &countryPrint($joinkey);
      &institutionPrint($joinkey);
      &emailPrint($joinkey);
      &mainphonePrint($joinkey);
      &labphonePrint($joinkey);
      &officephonePrint($joinkey);
      &otherphonePrint($joinkey);
      &faxPrint($joinkey);
      &webpagePrint($joinkey);
      &old_emailPrint($joinkey);
      &last_attemptPrint($joinkey);
      &left_fieldPrint($joinkey);
      &oldlabPrint($joinkey);
#       &apuPrint($joinkey);		# don't print apu's because sent by person not actual acedb authors
#       &commentPrint($joinkey);	# don't print comments
      &wormbasecommentPrint($joinkey);	# don't print comments
      &lineagePrint($joinkey);
      &paperPrint($joinkey);
      &last_verifiedPrint();
      print "\n";  				# divider between Persons
    }
  }
} # for (my $i = 0; $i < $highest_two_val; $i++)

close (ERR) or die "Cannot close $error_file : $!";

sub lineagePrint {
  my $joinkey = shift;
  my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two'; " );
  my $stuff = '';
  while (my @row = $result->fetchrow) {
    my $num = $row[3]; $num =~ s/two//g;
    my $role = $row[4];
    if ($row[5]) { $role .= " $row[5]"; }
    if ($row[6]) { $role .= " $row[6]"; }
    if ($role =~ m/^Collaborated/) {
      $stuff .= "Worked_with\t \"WBPerson$num\" $role\n"; }
    elsif ($role =~ m/^with/) {
      $role =~ s/with//g;
      $stuff .= "Supervised_by\t \"WBPerson$num\" $role\n"; }
    else {
      $stuff .= "Supervised\t \"WBPerson$num\" $role\n"; }
  } # while (my @row = $result->fetchrow)

  if ($stuff) {
      # Ridiculously overcomplicated way to prevent Role Unknown to appear if already
      # have data under a different Role for that Tag and WBPerson  2004 01 13
    my @stuff = split/\n/, $stuff;
    my %filter;
    foreach my $line (@stuff) {
      my ($front, $role) = $line =~ m/^(.*?\t \"WB.*?) (.*?)$/;
      $filter{$front}{$role}++;
    } # foreach my $line (@stuff)
    foreach my $key (sort keys %filter) {
      my $not_unknown_flag = 0; my $unknown_flag = 0;
      foreach my $role (sort keys %{ $filter{$key} }) {
        if ($role !~ m/^Unknown/) { $not_unknown_flag++; }
        if ($role =~ m/^Unknown/) { $unknown_flag++; }
      } # foreach my $role (sort keys %{ $filter{$key} })
      if ( ($not_unknown_flag > 0) && ($unknown_flag > 0) ) {
        my $take_out = "$key\tUnknown";
        # print "TAKE OUT $take_out\n";
        $stuff =~ s/$take_out.*\n//g;
      } # if ( ($not_unknown_flag > 0) && ($unknown_flag > 0) )
    } # foreach my $key (sort keys %filter)
    print $stuff;
  } # if ($stuff)
} # sub lineagePrint



sub left_fieldPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_left_field WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $left_field = $row[2];
      my $left_field_time = $row[3];
      my ($date_type) = $left_field_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($left_field !~ m/NULL/) { 
        $left_field =~ s/\s+/ /g; $left_field =~ s/^\s+//g; $left_field =~ s/\s+$//g;
        $left_field =~ s/\//\\\//g;
        print "Left_the_field\t \"$left_field\"\n"; 
        push @dates, $left_field_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub left_fieldPrint

sub last_verifiedPrint {
  my $date = ''; my $time_temp = ''; my $highest = 0;
  foreach my $time (@dates) {
    $time_temp = $time;
    ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
    unless ($time_temp) { $time_temp = '1970-01-01'; }
    if ($time_temp =~ m/\D/) { $time_temp =~ s/\D//g; }
    if ($time_temp > $highest) {
      $highest = $time_temp;
      $date = $time;
    } # if ($time_temp > $highest)
  } # foreach my $time (@dates)
  my ($date_type) = $date =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
  print "Last_verified\t $date_type\n";
} # sub last_verifiedPrint

sub last_attemptPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_unable_to_contact WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $unable_to_contact = $row[2];
      my $unable_to_contact_time = $row[3];
      my ($date_type) = $unable_to_contact_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($unable_to_contact !~ m/NULL/) { 
        $unable_to_contact =~ s/\s+/ /g; $unable_to_contact =~ s/^\s+//g; $unable_to_contact =~ s/\s+$//g;
        $unable_to_contact =~ s/\//\\\//g;
        $unable_to_contact =~ s/\;/\\\;/g;
        print "Last_attempt_to_contact\t $date_type \"$unable_to_contact\"\n";
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub last_attemptPrint

sub wormbasecommentPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_wormbase_comment WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $wormbase_comment = $row[2];
      my $wormbase_comment_time = $row[3];
      if ( ($wormbase_comment !~ m/NULL/) && ($wormbase_comment !~ m/nodatahere/) ) { 
        $wormbase_comment =~ s/\n/ /sg;
        if ($wormbase_comment !~ m/NULL/) { 
	  $wormbase_comment =~ s/\s+/ /g; $wormbase_comment =~ s/^\s+//g; $wormbase_comment =~ s/\s+$//g;
          $wormbase_comment =~ s/\//\\\//g;
          print "Comment\t \"$wormbase_comment\"\n"; 
          push @dates, $wormbase_comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
} # sub wormbasecommentPrint

sub commentPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_comment WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[2]) { 
      my $comment = $row[1];
      my $comment_time = $row[2];
      if ( ($comment !~ m/NULL/) && ($comment !~ m/nodatahere/) ) { 
        $comment =~ s/\n/ /sg;
        if ($comment !~ m/NULL/) { 
	  $comment =~ s/\s+/ /g; $comment =~ s/^\s+//g; $comment =~ s/\s+$//g;
          $comment =~ s/\//\\\//g;
          print "Comment\t \"$comment\"\n";
          push @dates, $comment_time;
        }
      }
    } # if ($row[2])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub oldlabPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_oldlab WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $oldlab = $row[2];
      my $oldlab_time = $row[3];
      if ($oldlab !~ m/NULL/) { 
	$oldlab =~ s/\s+/ /g; $oldlab =~ s/^\s+//g; $oldlab =~ s/\s+$//g;
        $oldlab =~ s/\//\\\//g;
        print "Old_laboratory\t \"$oldlab\"\n"; 
        push @dates, $oldlab_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub old_emailPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_old_email WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $old_email = $row[2];
      my $old_email_time = $row[3];
      my ($date_type) = $old_email_time =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
      if ($old_email !~ m/NULL/) { 
	$old_email =~ s/\s+/ /g; $old_email =~ s/^\s+//g; $old_email =~ s/\s+$//g;
        $old_email =~ s/\//\\\//g;
        $old_email =~ s/%/\\%/g;
        print "Old_address\t $date_type Email \"$old_email\"\n"; 
        push @dates, $old_email_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub webpagePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_webpage WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $webpage = $row[2];
      my $webpage_time = $row[3];
      if ($webpage !~ m/NULL/) { 
	$webpage =~ s/\s+/ /g; $webpage =~ s/^\s+//g; $webpage =~ s/\s+$//g;
        $webpage =~ s/\//\\\//g;
        $webpage =~ s/%/\\%/g;
        print "Address\t Web_page \"$webpage\"\n"; 
        push @dates, $webpage_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub faxPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_fax WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $fax = $row[2];
      my $fax_time = $row[3];
      if ($fax !~ m/NULL/) { 
	$fax =~ s/\s+/ /g; $fax =~ s/^\s+//g; $fax =~ s/\s+$//g;
        $fax =~ s/\//\\\//g;
        print "Address\t Fax \"$fax\"\n"; 
        push @dates, $fax_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub otherphonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_otherphone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $otherphone = $row[2];
      my $otherphone_time = $row[3];
      if ($otherphone !~ m/NULL/) { 
	$otherphone =~ s/\s+/ /g; $otherphone =~ s/^\s+//g; $otherphone =~ s/\s+$//g;
        $otherphone =~ s/\//\\\//g;
        print "Address\t Other_phone \"$otherphone\"\n"; 
        push @dates, $otherphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub officephonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_officephone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $officephone = $row[2];
      my $officephone_time = $row[3];
      if ($officephone !~ m/NULL/) { 
	$officephone =~ s/\s+/ /g; $officephone =~ s/^\s+//g; $officephone =~ s/\s+$//g;
        $officephone =~ s/\//\\\//g;
        print "Address\t Office_phone \"$officephone\"\n"; 
        push @dates, $officephone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub labphonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_labphone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $labphone = $row[2];
      my $labphone_time = $row[3];
      if ($labphone !~ m/NULL/) { 
	$labphone =~ s/\s+/ /g; $labphone =~ s/^\s+//g; $labphone =~ s/\s+$//g;
        $labphone =~ s/\//\\\//g;
        print "Address\t Lab_phone \"$labphone\"\n"; 
        push @dates, $labphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub mainphonePrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_mainphone WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $mainphone = $row[2];
      my $mainphone_time = $row[3];
      if ($mainphone !~ m/NULL/) { 
	$mainphone =~ s/\s+/ /g; $mainphone =~ s/^\s+//g; $mainphone =~ s/\s+$//g;
        $mainphone =~ s/\//\\\//g;
        print "Address\t Main_phone \"$mainphone\"\n"; 
        push @dates, $mainphone_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub emailPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_email WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $email = $row[2];
      my $email_time = $row[3];
      if ($email !~ m/NULL/) { 
	$email =~ s/\s+/ /g; $email =~ s/^\s+//g; $email =~ s/\s+$//g;
        $email =~ s/\//\\\//g;
        $email =~ s/%/\\%/g;
        print "Address\t Email \"$email\"\n"; 
        push @dates, $email_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub emailPrint

sub countryPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_country WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $country = $row[2];
      my $country_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $country =~ s/\s+/ /g; $country =~ s/^\s+//g; $country =~ s/\s+$//g;
        $country =~ s/\//\\\//g;
        print "Address\t Country \"$country\"\n"; 
        push @dates, $country_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub countryPrint

sub institutionPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_institution WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $institution = $row[2];
      my $institution_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $institution =~ s/\s+/ /g; $institution =~ s/^\s+//g; $institution =~ s/\s+$//g;
        $institution =~ s/\//\\\//g;
        if ($row[1] == 1) {			# put first thing in Address
          print "Address\t Institution \"$institution\"\n";  }
        else {					# put other things in Old_address
          my ($date_type) = $row[3] =~ m/^(\d\d\d\d\-\d\d\-\d\d)/;
          print "Old_address\t $date_type Institution \"$institution\"\n";  }
        push @dates, $institution_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub countryPrint

sub streetPrint {
  my $joinkey = shift;
  my %street_hash; my @row;
  my @tables = qw( two_street two_city two_state two_post );
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM ${table} WHERE joinkey = '$joinkey' ORDER BY two_order;" );
    while ( @row = $result->fetchrow ) {	# foreach line of data
      if ($row[3]) { 				# if there's data (date)
        if ($table eq 'two_street') { 		# street data print straight out
          my $street = $row[2];
          my $street_time = $row[3];
          if ($row[2] !~ m/NULL/) { 		# if there's data
            $street =~ s/\s+/ /g; $street =~ s/^\s+//g; $street =~ s/\s+$//g;
            $street =~ s/\//\\\//g;
            print "Address\t Street_address \"$street\"\n";
            push @dates, $street_time;
          } # if ($row[2] !~ m/NULL/)
        } else { 				# city, state, and post preprocess
          if ($row[2] !~ m/NULL/) { 		# if there's data
            $row[2] =~ s/\s+/ /g;
            $row[2] =~ s/\//\\\//g;
            $street_hash{$row[1]}{$table}{val} = $row[2];
            $street_hash{$row[1]}{$table}{time} = $row[3];
          }
        } 
      } # if ($row[3])
    } # while ( @row = $result->fetchrow )
  } # foreach my $table (@tables)

  foreach my $street_entry (sort keys %street_hash) {
    my $street_name; my $street_time = 0; my $street_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($street_hash{$street_entry}{$table}{time}) {
        $time_temp = $street_hash{$street_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $street_time_temp) { 
          $street_time_temp = $time_temp;
          $street_time = $street_hash{$street_entry}{$table}{time}; 
          push @dates, $street_time;
        }
      } # if ($street_hash{$street_entry}{$table}{time})
    } # foreach my $table (@tables)

    my $city; my $state; my $post; 
    if ($street_hash{$street_entry}{two_city}{val}) { $city = $street_hash{$street_entry}{two_city}{val}; }
    if ($street_hash{$street_entry}{two_state}{val}) { $state = $street_hash{$street_entry}{two_state}{val}; }
    if ($street_hash{$street_entry}{two_post}{val}) { $post = $street_hash{$street_entry}{two_post}{val}; }

    if ($city) { $city =~ s/\s+/ /g; $city =~ s/^\s+//g; $city =~ s/\s+$//g; }
    if ($state) { $state =~ s/\s+/ /g; $state =~ s/^\s+//g; $state =~ s/\s+$//g; }
    if ($post) { $post =~ s/\s+/ /g; $post =~ s/^\s+//g; $post =~ s/\s+$//g; }

    if ( ($city) && ($state) && ($post) ) { print "Address\t Street_address \"$city, $state $post\"\n"; }
    elsif ( ($city) && ($state) ) { print "Address\t Street_address \"$city, $state\"\n"; }
    elsif ( ($city) && ($post) ) { print "Address\t Street_address \"$city, $post\"\n"; }
    elsif ( ($state) && ($post) ) { print "Address\t Street_address \"$state $post\"\n"; }
    elsif ($city) { print "Address\t Street_address \"$city\"\n"; }
    elsif ($state) { print "Address\t Street_address \"$state\"\n"; }
    elsif ($post) { print "Address\t Street_address \"$post\"\n"; }
    else { 1; }
  } # foreach my $street_entry (sort keys %street_hash)
} # sub streetPrint

sub labPrint {
  my $joinkey = shift;
  $result = $conn->exec ( "SELECT * FROM two_lab WHERE joinkey = '$joinkey';" );
  while ( my @row = $result->fetchrow ) {
    if ($row[3]) { 
      my $lab = $row[2];
      my $lab_time = $row[3];
      if ($row[2] !~ m/NULL/) { 
        $lab =~ s/\s+/ /g; $lab =~ s/^\s+//g; $lab =~ s/\s+$//g;
        $lab =~ s/\//\\\//g;
        if ($lab !~ m/[A-Z][A-Z]/) { print ERR "ERROR $joinkey LAB $lab\n"; }
          else { 
	    print "Laboratory\t \"$lab\"\n"; 
	  }
        push @dates, $lab_time;
      }
    } # if ($row[3])
  } # while ( my @row = $result->fetchrow )
} # sub labPrint

sub apuPrint {
  my $joinkey = shift;
  my @row;
  my %apu_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_apu_${table}name WHERE joinkey = '$joinkey';" );
    while ( @row = $result->fetchrow ) { 
      if ($row[3]) { 
        $apu_hash{$row[1]}{$table}{val} = $row[2];
        $apu_hash{$row[1]}{$table}{time} = $row[3];
      }
    }
  } # foreach my $table (@tables)

  foreach my $apu_entry (sort keys %apu_hash) {
    my $apu_name; my $apu_time = 0; my $apu_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($apu_hash{$apu_entry}{$table}{time}) {
        $time_temp = $apu_hash{$apu_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        $time_temp =~ s/\D//g;
        if ($time_temp > $apu_time_temp) { 
          $apu_time_temp = $time_temp;
          $apu_time = $apu_hash{$apu_entry}{$table}{time}; 
        }
      } # if ($apu_hash{$apu_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($apu_hash{$apu_entry}{middle}{val}) { 
      $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{last}{val};
    } else {
      unless ($apu_hash{$apu_entry}{middle}{val} !~ m/NULL/) { 
        $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{last}{val};
      } else {
        $apu_name = $apu_hash{$apu_entry}{first}{val} . " " . $apu_hash{$apu_entry}{middle}{val} . " " . $apu_hash{$apu_entry}{last}{val};
      }
    }
    $apu_name =~ s/\s+/ /g; $apu_name =~ s/^\s+//g; $apu_name =~ s/\s+$//g;
    $apu_name =~ s/\//\\\//g;
    if ($apu_name !~ m/NULL/) { 
# DON'T PUT IN BECAUSE PERSON SENDS STUFF AND IT MAY NOT BE ACEDB-FORMAT AUTHOR
#       print "Publishes_as\t \"$apu_name\"\n";	# confirmed 
#       print "Possibly_publishes_as\t \"$apu_name\"\n";	
#       print "Possibly_publishes_as\t \"$apu_name\"\n";
      push @dates, $apu_time;
    }
  } # foreach my $apu_entry (sort keys %apu_hash)
} # sub apuPrint

sub akaPrint {
  my $joinkey = shift;
  my @row;
  my %aka_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) { 
    $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE joinkey = '$joinkey';" );
    while ( @row = $result->fetchrow ) { 
      if ($row[2]) { $aka_hash{$row[1]}{$table}{val} = $row[2]; } else { $aka_hash{$row[1]}{$table}{val} = ' '; }
      if ($row[3]) { $aka_hash{$row[1]}{$table}{time} = $row[3]; } else { $aka_hash{$row[1]}{$table}{time} = ' '; }
    }
  } # foreach my $table (@tables)

  foreach my $aka_entry (sort keys %aka_hash) {
    my $aka_name; my $aka_time = 0; my $aka_time_temp = 0; my $time_temp = 0;
  
    foreach my $table (@tables) { 
      if ($aka_hash{$aka_entry}{$table}{time}) {
        $time_temp = $aka_hash{$aka_entry}{$table}{time};
        ($time_temp) = $time_temp =~ m/^(\d\d\d\d\-\d\d\-\d\d \d\d)/;
        unless ($time_temp) { $time_temp = '1970-01-01'; }
        if ($time_temp =~ m/\D/) { $time_temp =~ s/\D//g; }
        if ($time_temp > $aka_time_temp) { 
          $aka_time_temp = $time_temp;
          $aka_time = $aka_hash{$aka_entry}{$table}{time}; 
        }
      } # if ($aka_hash{$aka_entry}{$table}{time})
    } # foreach my $table (@tables)
    
    unless ($aka_hash{$aka_entry}{middle}{val}) { 
      unless ($aka_hash{$aka_entry}{first}{val}) { $aka_hash{$aka_entry}{first}{val} = ' '; }
      unless ($aka_hash{$aka_entry}{last}{val}) { $aka_hash{$aka_entry}{last}{val} = ' '; }
      $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val};
      $aka_name =~ s/\s+/ /g; 
    } else {
      unless ($aka_hash{$aka_entry}{middle}{val}) { $aka_hash{$aka_entry}{middle}{val} = ''; }
      unless ($aka_hash{$aka_entry}{middle}{val} !~ m/NULL/) { 
        unless ($aka_hash{$aka_entry}{first}{val}) { $aka_hash{$aka_entry}{first}{val} = ' '; }
        unless ($aka_hash{$aka_entry}{last}{val}) { $aka_hash{$aka_entry}{last}{val} = ' '; }
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{last}{val}; 
        $aka_name =~ s/\s+/ /g; }
      else {
        $aka_name = $aka_hash{$aka_entry}{first}{val} . " " . $aka_hash{$aka_entry}{middle}{val} . " " . $aka_hash{$aka_entry}{last}{val}; $aka_name =~ s/\s+/ /g; }
    }
    $aka_name =~ s/\s+/ /g; $aka_name =~ s/^\s+//g; $aka_name =~ s/\s+$//g;
    $aka_name =~ s/\//\\\//g;
    if ($aka_name !~ m/NULL/) { 
      $aka_name =~ s/\.//g; $aka_name =~ s/\,//g;
      print "Also_known_as\t \"$aka_name\"\n";
      push @dates, $aka_time;
    }
  } # foreach my $aka_entry (sort keys %aka_hash)
} # sub akaPrint


sub namePrint	{	# name block
  my $joinkey = shift;
  my $firstname; my $middlename; my $lastname; my $standardname; my $timestamp; my $full_name;
  $result = $conn->exec ( "SELECT * FROM two_firstname WHERE joinkey = '$joinkey';" );
  my @row = $result->fetchrow;
  if ($row[3]) { 
    $firstname = $row[2];
    $timestamp = $row[3];
    if ($firstname !~ m/NULL/) { 
      $firstname =~ s/\s+/ /g; $firstname =~ s/^\s+//g; $firstname =~ s/\s+$//g;
      $firstname =~ s/\//\\\//g;
      $firstname =~ s/\.//g; $firstname =~ s/\,//g;
      print "First_name\t \"$firstname\"\n";
    } else { print ERR "ERROR no firstname for $joinkey : $firstname\n"; }
  }
  $result = $conn->exec ( "SELECT * FROM two_middlename WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) { 
    $middlename = $row[2];
    $timestamp = $row[3];
    if ($middlename !~ m/NULL/) { 
      $middlename =~ s/\s+/ /g; $middlename =~ s/^\s+//g; $middlename =~ s/\s+$//g;
      $middlename =~ s/\//\\\//g;
      $middlename =~ s/\.//g; $middlename =~ s/\,//g;
      print "Middle_name\t \"$middlename\"\n";
    } else { print ERR "ERROR no middlename for $joinkey : $middlename\n"; }
  }
  $result = $conn->exec ( "SELECT * FROM two_lastname WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) { 
    $lastname = $row[2];
    $timestamp = $row[3];
    if ($lastname !~ m/NULL/) { 
      $lastname =~ s/\s+/ /g; $lastname =~ s/^\s+//g; $lastname =~ s/\s+$//g;
      $lastname =~ s/\//\\\//g;
      $lastname =~ s/\.//g; $lastname =~ s/\,//g;
      print "Last_name\t \"$lastname\"\n";
    } else { print "ERROR no lastname for $joinkey : $lastname\n"; }
  }
  unless ($middlename) { $middlename = ''; }
  if ($middlename !~ m/NULL/) {
    $full_name = $firstname . " " . $middlename . " " . $lastname; }
  else {
    $full_name = $firstname . " " . $lastname; } 
  $standardname = $firstname . " " . $lastname;	# init as default first last
  $result = $conn->exec ( "SELECT * FROM two_standardname WHERE joinkey = '$joinkey';" );
  @row = $result->fetchrow;
  if ($row[3]) {
    $standardname = $row[2];
    $timestamp = $row[3];
    if ($standardname !~ m/NULL/) { 
      $standardname =~ s/\s+/ /g; $standardname =~ s/^\s+//g; $standardname =~ s/\s+$//g;
      $standardname =~ s/\//\\\//g;
    } else { print "ERROR no standardname for $joinkey : $standardname\n"; }
    print "Standard_name\t \"$standardname\"\n";
  }
  unless ($full_name) { $full_name = ''; }
  if ($full_name !~ m/NULL/) {
    $full_name =~ s/\s+/ /g; $full_name =~ s/^\s+//g; $full_name =~ s/\s+$//g;
    print "Full_name\t \"$full_name\"\n";
    push @dates, $timestamp; }
  else { print ERR "ERROR no full_name for $joinkey : $full_name\n"; }
} # sub namePrint	


sub populatePaperHash {
  my $result = $conn->exec( "SELECT * FROM pap_view WHERE pap_verified ~ 'YES';");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      my ($joinkey, $author, $person);
      if ($row[0]) { if ($row[0] =~ m//) { $row[0] =~ s///g; } $joinkey = $row[0]; }
      if ($row[1]) { if ($row[1] =~ m//) { $row[1] =~ s///g; } $author = $row[1]; }
      if ($row[2]) { if ($row[2] =~ m//) { $row[2] =~ s///g; } $person = $row[2]; }
      unless ($person) { $person = ' '; }
      unless ($joinkey) { $joinkey = ' '; }
      $paperHash{$person}{paper}{$joinkey}++; 
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)
  
  $result = $conn->exec( "SELECT * FROM pap_possible WHERE pap_possible IS NOT NULL;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      $row[1] =~ s///g; my $author = $row[1];
      $row[2] =~ s///g; my $person = $row[2];
      if ($author =~ m/^[\-\w\s]+"/) { $author =~ m/^([\-\w\s]+)\"/; $author = $1; }
      $paperHash{$person}{author}{$author}++;
    } # if ($row[0])
  } # while (my @row = $result->fetchrow)

} # sub populatePaperHash

sub paperPrint {
  my $joinkey = shift;
#   my $result = $conn->exec( "SELECT * FROM two_lineage WHERE joinkey = '$joinkey' AND two_number ~ 'two'; " );
  foreach my $paper (sort keys %{$paperHash{$joinkey}{paper}}) {
#     print "Paper\t\"[$paper]\"\n";
    $paper =~ s/\.$//g;					# take out dots at the end that are typos
    if ($paper =~ m/WBPaper/) { 
      print "Paper\t \"$paper\"\n"; }
    elsif ($convertToWBPaper{$paper}) {			# conver to WBPaper or print ERROR
      print "Paper\t \"$convertToWBPaper{$paper}\"\n"; }
    else { print STDERR "ERROR No conversion for $paper on $joinkey\n"; }
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
  foreach my $author (sort keys %{$paperHash{$joinkey}{author}}) {
    $author =~ s/\.//g; $author =~ s/,//g;
    if ($author =~ m/\" Affiliation_address/) { $author =~ s/\" Affiliation_address.*$//g; }
      # 2004 12 29 -- was dumping affiliation address data which is not in the model
    print "Possibly_publishes_as\t \"$author\"\n";
  } # foreach my $paper (sort keys %{$paperHash{$joinkey}})
} # sub paperPrint
  
sub readConvertions {
  my %ignoreHash;	# temporarily ignore list of stuff from Eimear because these WBPapers have been merged with others 
			# and are no longer the correct WBPaper 	2005 05 26
  my $eimearFileToIgnore = '/home/azurebrd/work/parsings/eimear/fixingEimearsPaper2WBPaperTable/Papers_with_only_Person_data.txt';
  open (IN, "<$eimearFileToIgnore") or die "Cannot open $eimearFileToIgnore : $!";
  while (<IN>) {
    my ($ignore) = $_ =~ m/^\"(.*?)\"\t/;
    $ignoreHash{$ignore}++;
  } # while (<IN>)

  my $u = "http://minerva.caltech.edu/~acedb/paper2wbpaper.txt";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      unless ($ignoreHash{$2}) {		# temporarily ignore list of stuff from Eimear  2005 05 26
      $convertToWBPaper{$1} = $2; } }
      }
} # sub readConvertions

