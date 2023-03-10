#!/usr/bin/perl

# use this package so that both : the dumping script for .ace uploads and
# find_diff.pl ;  and the wpa_editor.cgi  can use this to dump, or create a
# preview page respectively.  2005 07 13
#
# check the validity of a paper
#
# Add an option to get all data as well as just valid data.  When getting
# valid data then, check that the wpa is valid.
# dump Remark data as well.  2005 11 10
#
# Fixed Brief citation to say ``et al.'' instead of ``et.al'' for Kris
# Gunsalus.  2006 01 03
#
# Dump Person in #Affiliation  2008 08 19



# our @ISA	= qw(Exporter);
# # our @EXPORT	= qw(untaint getDate printHeader printFooter getPgDate cshlNew caltechOld getHtmlVar mailer getSimpleSecDate getSimpleDate filterToPrintHtml );
# our @EXPORT	= qw(getPaper );
# our $VERSION	= 1.00;



use strict;
use diagnostics;
use Pg;
use LWP;


my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my $result;

my %theHash;
my %author_index;
my %type_index;
my %author_valid;

my @generic_tables = qw( wpa_identifier wpa_title wpa_publisher wpa_journal wpa_volume wpa_pages wpa_year wpa_fulltext_url wpa_abstract wpa_affiliation wpa_hardcopy wpa_comments wpa_editor wpa_nematode_paper wpa_contained_in wpa_contains wpa_keyword wpa_erratum wpa_in_book wpa_type wpa_author );

my $ace_entry = '';
my $all_entry = '';
my $long_text = '';
my $err_text = '';


sub getIndices {
  $result = $conn->exec( "SELECT * FROM wpa_type_index ORDER BY wpa_timestamp ;" );
  while (my @row = $result->fetchrow) {
    if ($row[3] eq 'valid') { $type_index{$row[0]} = $row[1]; } }

  my %aid_two;
  $result = $conn->exec( "SELECT * FROM wpa_author_verified ORDER BY wpa_timestamp ;" );
  while (my @row = $result->fetchrow) {
    next unless ($row[0]); next unless ($row[2]);
    if ($row[3] eq 'valid') { $aid_two{ver}{$row[0]}{$row[2]} = $row[1]; } else { delete $aid_two{ver}{$row[0]}{$row[2]}; } }
  $result = $conn->exec( "SELECT * FROM wpa_author_possible ORDER BY wpa_timestamp ;" );
  while (my @row = $result->fetchrow) {
    next unless ($row[0]); next unless ($row[2]);
    if ($row[3] eq 'valid') { $aid_two{pos}{$row[0]}{$row[2]} = $row[1]; } else { delete $aid_two{pos}{$row[0]}{$row[2]}; } }
  foreach my $aid (keys %{ $aid_two{ver} }) { foreach my $join (keys %{ $aid_two{ver}{$aid} }) {
    if ($aid_two{ver}{$aid}{$join}) { if ($aid_two{ver}{$aid}{$join} =~ m/YES/) { 
      if ($aid_two{pos}{$aid}{$join}) { $aid_two{two}{$aid} = $aid_two{pos}{$aid}{$join}; } } } } }
  
  $result = $conn->exec( "SELECT * FROM wpa_author_index ORDER BY wpa_timestamp ;" );
  while (my @row = $result->fetchrow) {
    $author_valid{valid}{$row[0]} = $row[3];
    $author_valid{name}{$row[0]} = $row[1];
    $author_valid{affiliation}{$row[0]} = $row[2];
  } # while (my @row = $result->fetchrow)
  foreach my $author_id (sort keys %{ $author_valid{valid} }) {
    if ($author_valid{valid}{$author_id} eq 'valid') {
      my ($author_name) = &filterAce($author_valid{name}{$author_id});
      next unless ($author_name);
      my $printed_author = 0;
      if ($author_valid{affiliation}{$author_id}) { 
        my ($affi) = &filterAce($author_valid{affiliation}{$author_id}); $printed_author++;
#     $author_index{$author_id} .= " Affiliation_address \"$author_valid{affiliation}{$author_id}\""; 
        $author_index{$author_id} .= "Author\t \"$author_name\" Affiliation_address \"$affi\"\n"; }
# PUT THIS BACK WHEN MODEL CHANGES  2008 08 19
#       if ($aid_two{two}{$author_id}) { 
#         my $person = $aid_two{two}{$author_id}; $person =~ s/two/WBPerson/g; $printed_author++;
#         $author_index{$author_id} .= "Author\t \"$author_name\" Person \"$person\"\n"; }
      unless ($printed_author) { $author_index{$author_id} = "Author\t \"$author_name\"\n"; }
#         if ($author_name =~ m/^-C/) {
#             $author_index{$author_id} = "Author\t $author_name\"\n"; }
#           else {
#             $author_index{$author_id} = "Author\t \"$author_name\"\n"; }
#       $author_index{$author_id} .= "\n";
    }
  } # foreach my $author_id (sort keys %{ $author_valid{valid} })
} # sub getIndices



sub getPaper {
  my ($flag) = shift;

  &getIndices();

#   if ( ($flag eq 'valid') || ($flag eq 'all') ) {
#     my $count;
#     $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp ;" );
#     while (my @row = $result->fetchrow) {
#       $theHash{valid}{$row[0]} = $row[3];
#     } # while (my @row = $result->fetchrow)
#     foreach my $joinkey (sort keys %{ $theHash{valid} }) {
#         # if only want valid values and a value is not valid, skip it.  2005 11 10
#       next if ( ($flag eq 'valid') && ($theHash{valid}{$joinkey} ne 'valid') );
#       $ace_entry = '';
#       my ($entry) = &getStuff($joinkey, $ace_entry); 
#       if ($entry) { $all_entry .= "Paper : \"WBPaper$joinkey\"\n$entry\n"; } 
#     } # foreach my $joinkey (sort keys %{ $theHash{valid} })
#   }
  if ($flag eq 'valid') {
    my $count;
    $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp ;" );
    while (my @row = $result->fetchrow) {
      $theHash{valid}{$row[0]} = $row[3];
    } # while (my @row = $result->fetchrow)
    foreach my $joinkey (sort keys %{ $theHash{valid} }) {
        # if only want valid values and a value is not valid, skip it.  2005 11 10
      if ($theHash{valid}{$joinkey} eq 'valid') {		# get valid data
          $ace_entry = '';
          my ($entry) = &getStuff($joinkey, $ace_entry); 
          if ($entry) { $all_entry .= "Paper : \"WBPaper$joinkey\"\nStatus\t\"Valid\"\n$entry\n"; } }
        else {							# if not valid, check if it's been merged into, and show merged_into and invalid if so  2006 11 08
          my $to_print = '';
          my $result2 = $conn->exec( "SELECT joinkey FROM wpa_identifier WHERE wpa_identifier ~ '$joinkey';" );
          while (my @row2 = $result2->fetchrow) { $to_print .= "Merged_into\t\"WBPaper$row2[0]\"\n"; }
          if ($to_print) { $all_entry .= "Paper : \"WBPaper$joinkey\"\nStatus\t\"Invalid\"\n$to_print\n"; } }
    } # foreach my $joinkey (sort keys %{ $theHash{valid} })
  }
  elsif ($flag =~ m/(\d{8})/) {
    my $joinkey = $1;
    $ace_entry = '';
    my ($is_not_valid) = &getValid($joinkey, $ace_entry);	# added 2005 08 09 because it was previewing even when the paper was changed to be invalid
    if ($is_not_valid) { $ace_entry = "-D Paper : \"WBPaper$joinkey\""; return $ace_entry; }
    else { 
      my ($entry) = &getStuff($joinkey, $ace_entry); 
      if ($entry) { $all_entry .= "Paper : \"WBPaper$joinkey\"\n$entry\n"; } }
  } else { print "ERR not a valid Flag for &getPaper, try 'valid' or an 8 digit wbpaper number\n"; }

  return( $all_entry, $long_text, $err_text );
} # sub getPaper





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
  ($ace_entry) = &getRemark($joinkey, $ace_entry);
  ($ace_entry) = &getFulltextUrl($joinkey, $ace_entry);
  ($ace_entry) = &getGene($joinkey, $ace_entry);
  if ($title ne 'WormBook') {		# don't dump brief citation for WormBook (In_book) for Igor  2006 05 01
    ($ace_entry) = &getEimearBriefCitation($author, $year, $journal, $title, $ace_entry); }
  ($ace_entry) = &getErratum($joinkey, $ace_entry);
  ($ace_entry) = &getIn_book($joinkey, $ace_entry);
  if ($ace_entry) { return $ace_entry; }
} # sub getStuff


sub getGene {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa_gene WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { 
    $tempHash{value}{$row[1]} = $row[3]; 
    if ($row[2]) { 
#       print "ID $row[1] EVI $row[2] VALID $row[3]<BR>\n"; 
      $tempHash{evidence}{$row[1]}{$row[2]}++; } }
  foreach my $identifier (sort keys %{ $tempHash{value} } ) {
    if ($tempHash{value}{$identifier} eq 'valid') { 
      my ($gene, $cds, $evidence); my @evidence;
      if ($identifier =~ m/^(.*?)\t(.*?)$/) { $gene = $1; $cds = $2; }
        else { $gene = $identifier; }
      if ($tempHash{evidence}{$identifier}) {
        foreach my $evi (sort keys %{ $tempHash{evidence}{$identifier} } ) {
# print "LOOP ID $identifier EVI $evi END<BR>\n";
#           ($evidence) = &filterAce($evi); 
          ($evidence) = $evi; 			# evidence reparsed into postgres to be unparsed as far as " goes
# print "LOOP ID $identifier EVIDENCE $evidence END<BR>\n";
#           if ($evidence =~ m/^Gene\"/) { $evidence =~ s/Gene\"/Gene/g; }
#           elsif ($evidence =~ m/Inferred_automatically\"/) { $evidence =~ s/Inferred_automatically\"/Inferred_automatically/g; }
#           elsif ($evidence =~ m/Author_evidence\"/) { $evidence =~ s/Author_evidence\"/Author_evidence/g; }
#           elsif ($evidence =~ m/Person_evidence\"/) { $evidence =~ s/Person_evidence\"/Person_evidence/g; }
#           $evidence = " $evidence\""; 
          push @evidence, $evidence; } }
      if ($gene =~ m/\(.*?\)$/) { $gene =~ s/\(.*?\)$//; }	# take out 3-letter locus
      if ($gene) {
        if ($evidence) { foreach my $evidence (@evidence) { $ace_entry .= "Gene\t \"$gene\" $evidence\n"; } }
          else { $ace_entry .= "Gene\t \"$gene\"\n"; } }
      if ($cds) {
        if ($evidence) { foreach my $evidence (@evidence) { $ace_entry .= "CDS\t \"$cds\" $evidence\n"; } }
          else { $ace_entry .= "CDS\t \"$cds\"\n"; } }
    } # if ($tempHash{$identifier} eq 'valid') 
  } # foreach my $identifier (sort keys %tempHash)
  return $ace_entry;
} # sub getGene

sub getEimearBriefCitation {
  my ($author, $year, $journal, $title, $ace_entry) = @_;
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
      if ($author_count == 2) { $author .= " et al."; }
      if ($author_index{$identifier}) { $ace_entry .= $author_index{$identifier}; } } }
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
  while (my @row = $result->fetchrow) { if ($row[1]) { if ($row[3]) { $tempHash{$row[1]} = $row[3]; } } }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { 
      ($identifier) = &filterAce($identifier);
      if ($identifier) {
        $ace_entry .= "Editor\t \"$identifier\"\n"; } } }
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
#       ($identifier) = &filterAce($identifier);	# don't filter abstracts because they're longtext, so don't have escape characters
#       if ($identifier =~ m/\\/) { $identifier =~ s/\\/\\\\/g; }		# do escape \
#       if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }		# do escape "
      $long_text .= "LongText : \"WBPaper$joinkey\"\n\n$identifier\n\n***LongTextEnd***\n\n\n";
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
#       elsif ($identifier =~ m/^WBPaper/) { $ace_entry .= "Old_WBPaper\t \"$identifier\"\n"; }
      elsif ($identifier =~ m/^WBPaper/) { $ace_entry .= "Acquires_merge\t \"$identifier\"\n"; }
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

sub getValid {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  $result = $conn->exec( "SELECT * FROM wpa WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC;" );
  my @row = $result->fetchrow; 
  if ($row[3] ne 'valid') { return 'invalid'; }		# return if not valid
  return 0;						# return nothing if valid
} # sub getValid

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
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Title USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Title : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($title, my @junk) = keys %valid_entry; }
    else { 1; }
  if ($title) { 
    ($title) = &filterAce($title);
    if ($title =~ m/\n/) { $title =~ s/\n/ /g; }	# filter out newlines, which can be entered by pasting two lines into the editor  2005 10 19
    if ($title =~ m/\s+/) { $title =~ s/\s+/ /g; }
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
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Year USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Year : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($year, my @junk) = keys %valid_entry; }
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
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Journal USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Journal : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($journal, my @junk) = keys %valid_entry; }
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
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Pages USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Pages : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($pages, my @junk) = keys %valid_entry; }
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
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Type USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Type : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($type, my @junk) = keys %valid_entry; }
    else { 1; }
  if ($type) {
    if ($type_index{$type}) {
      $ace_entry .= "Type\t \"$type_index{$type}\"\n"; } 
    else { $err_text .= "Invalid Type Index type $type in $joinkey\n"; } }
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
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Publisher USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Publisher : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($publisher, my @junk) = keys %valid_entry; }
    else { 1; }
  if ($publisher) {
    ($publisher) = &filterAce($publisher);
    $ace_entry .= "Publisher\t \"$publisher\"\n"; }
  return $ace_entry;
} # sub getPublisher

sub getFulltextUrl {			# dump this to remark.  for Igor.  2006 05 01
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $fulltext_url = ''; my %valid_entry;
  $result = $conn->exec( "SELECT * FROM wpa_fulltext_url WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_fulltext_url =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_fulltext_url FROM wpa_fulltext_url WHERE wpa_fulltext_url = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $fulltext_url = $row2[0];
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Remark USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Remark : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($fulltext_url, my @junk) = keys %valid_entry; }
    else { 1; }
  if ($fulltext_url) {
    ($fulltext_url) = &filterAce($fulltext_url);
    $ace_entry .= "Remark\t \"$fulltext_url\"\n"; }
  return $ace_entry;
} # sub getFulltextUrl

sub getRemark {
  my ($joinkey, $ace_entry) = @_; my %tempHash;
  my $remark = ''; my %valid_entry;
  $result = $conn->exec( "SELECT * FROM wpa_remark WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) { $tempHash{$row[1]} = $row[3]; }
  foreach my $identifier (sort keys %tempHash) {
    if ($tempHash{$identifier} eq 'valid') { $valid_entry{$identifier}++; } }
  if (scalar (keys %valid_entry) > 1) {			# if multiple entries on unique thing
      my ($requery) = join"\' OR wpa_remark =\'", keys %valid_entry;
      my $result2 = $conn->exec( "SELECT wpa_remark FROM wpa_remark WHERE wpa_remark = '$requery' AND wpa_valid = 'valid' ORDER BY wpa_timestamp DESC;" );
      my @row2 = $result2->fetchrow;  $remark = $row2[0];
      $err_text .= "Multiple valid entries for $joinkey UNIQUE Remark USING : $row2[0]\n"; 
      foreach my $entry (sort keys %valid_entry) { $err_text .= "Multiple valid entries for $joinkey UNIQUE Remark : $entry\n"; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($remark, my @junk) = keys %valid_entry; }
    else { 1; }
  if ($remark) {
    ($remark) = &filterAce($remark);
    $ace_entry .= "Remark\t \"$remark\"\n"; }
  return $ace_entry;
} # sub getRemark

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
          else { $valid_volume{old}{$valid_entry}++; } } }
      else { $valid_volume{latest}{$volume}++; } }
    elsif (scalar (keys %valid_entry) == 1) { 		# if there's only one valid entry, store it as latest
      ($volume, my @junk) = keys %valid_entry; $valid_volume{latest}{$volume}++; }
    else { 1; }						# if no volume, don't do anything
  foreach my $volume (sort keys %{ $valid_volume{old} }) {
    ($volume) = &filterAce($volume);			# for all old entries warn that it's not being printed
    $err_text .= "Multiple valid entries for $joinkey UNIQUE Volume IGNORING : $volume\n"; }
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
  if ($identifier =~ m/HTTP:\/\//i) { $identifier =~ s/HTTP:\/\//PLACEHOLDERASDF/ig; }
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

1;
