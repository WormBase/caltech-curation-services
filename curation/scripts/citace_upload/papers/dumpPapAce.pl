#!/usr/bin/env perl

# dump .ace data for pap tables
#
# only dump genes if exactly 8 digit WBGene for Kimberly / Wen  2010 08 30
#
# use  &getBriefCitation( $author, $year, $journal, $title );  from package for Daniela / Raymond.  2010 11 18
#
# don't filterAce for abstracts because LongText doesn't need it.  2016 12 15
#
# dump Species for Kimberly.  2017 03 02
#
# brief citation was generating from pap_author order 1 instead of lowest order, so was failing
# when there wasn't an author there.  2019 10 21
#
# dump Author_first_pass from afp_contributor for Kimberly.  2020 09 17
#
# dump pap_gene_comp for Kimberly.  2022 02 11

use strict;
use diagnostics;
use DBI;
use Jex;		# filter for Pg
use Dotenv -load => '/usr/lib/.env';

use lib qw( /usr/lib/scripts/citace_upload/papers/ );	# for general ace dumping functions
# use lib qw( /home/postgres/work/citace_upload/papers/ );
use get_brief_citation;


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $result;


# unique (single value) tables :  status title journal publisher pages volume year month day pubmed_final primary_data abstract );

my %single;
$single{'status'}++;
$single{'title'}++;
$single{'journal'}++;
$single{'publisher'}++;
$single{'volume'}++;
$single{'pages'}++;
$single{'year'}++;
$single{'month'}++;
$single{'day'}++;
$single{'pubmed_final'}++;
$single{'primary_data'}++;
$single{'abstract'}++;

# multivalue tables :  editor type author affiliation fulltext_url contained_in gene gene_comp identifier ignore remark erratum_in internal_comment curation_flags 

my %multi;
$multi{'editor'}++;
$multi{'type'}++;
$multi{'author'}++;
$multi{'affiliation'}++;
$multi{'fulltext_url'}++;
$multi{'contained_in'}++;
$multi{'gene'}++;
$multi{'gene_comp'}++;
$multi{'identifier'}++;
$multi{'ignore'}++;
$multi{'remark'}++;
$multi{'erratum_in'}++;
$multi{'retraction_in'}++;
$multi{'internal_comment'}++;
$multi{'curation_flags'}++;
$multi{'electronic_path'}++;
$multi{'author_possible'}++;
$multi{'author_sent'}++;
$multi{'author_verified'}++;
$multi{'author_verified'}++;
$multi{'species'}++;



my %tableToTag;
$tableToTag{title}	= 'Title';
$tableToTag{type}	= 'Type';
$tableToTag{journal}	= 'Journal';
$tableToTag{publisher}	= 'Publisher';
$tableToTag{pages}	= 'Page';
$tableToTag{volume}	= 'Volume';
$tableToTag{year}	= 'Publication_date';
$tableToTag{abstract}	= 'Abstract';
$tableToTag{editor}	= 'Editor';
$tableToTag{affiliation}	= 'Affiliation';
$tableToTag{fulltext_url}	= 'URL';
$tableToTag{contained_in}	= 'Contained_in';
$tableToTag{identifier}	= 'Name';
$tableToTag{remark}	= 'Remark';
$tableToTag{erratum_in}	= 'Erratum_in';
$tableToTag{retraction_in}	= 'Retraction_in';
$tableToTag{gene}	= 'Gene';
$tableToTag{gene_comp}	= 'Gene';
$tableToTag{author}	= 'Author';
$tableToTag{curation_flags}	= 'Curation_pipeline';
$tableToTag{species}	= 'Species';

my @normal_tables = qw( status type title journal publisher pages volume year month day abstract editor affiliation fulltext_url contained_in identifier remark erratum_in retraction_in curation_flags author gene gene_comp species );

my %indices;
$result = $dbh->prepare( "SELECT * FROM pap_type_index");	
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $indices{type}{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_species_index");	
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $indices{species}{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT * FROM pap_author_index");	
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $indices{author}{$row[0]} = $row[1]; }

$result = $dbh->prepare( "SELECT pap_author_verified.author_id, pap_author_possible.pap_author_possible, pap_author_verified.pap_author_verified FROM pap_author_verified, pap_author_possible WHERE pap_author_verified.pap_author_verified ~ 'YES' AND pap_author_possible.pap_author_possible ~ 'two' AND pap_author_verified.author_id = pap_author_possible.author_id AND pap_author_verified.pap_join = pap_author_possible.pap_join;");
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { 
  $row[1] =~ s/two/WBPerson/;
  $indices{person}{$row[0]} = $row[1]; }

my %hash; 
foreach my $table (@normal_tables) {
#   next if ($table eq 'gene');			# UNCOMMENT TO BE FASTER
  $result = $dbh->prepare( "SELECT * FROM pap_$table");	
  if ($table eq 'gene') {			# for genes, don't get the dead ones
#     $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE pap_gene NOT IN (SELECT joinkey FROM gin_dead) AND joinkey = '00005672';");
    $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE pap_gene NOT IN (SELECT joinkey FROM gin_dead);");	
  }
  elsif ($table eq 'gene_comp') {			# for comparator genes, don't get the dead ones
    $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE pap_gene_comp NOT IN (SELECT joinkey FROM gic_dead);");	
  }
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    unless ($row[2]) { $row[2] = 0; }
    if ($table eq 'type') {            $hash{$table}{$row[0]}{$row[2]}{curator} = $row[3];       }
      elsif ($table eq 'gene') {       $hash{$table}{$row[0]}{$row[2]}{evi}     = $row[5];       }
      elsif ($table eq 'gene_comp') {  $hash{$table}{$row[0]}{$row[2]}{evi}     = $row[5];       }
      elsif ($table eq 'species') {    $hash{$table}{$row[0]}{$row[2]}{evi}     = $row[5];       }
    $hash{$table}{$row[0]}{$row[2]}{data} = $row[1]; }
}

my %afp;
$result = $dbh->prepare( "SELECT * FROM afp_contributor");	
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my $two = $row[1]; $two =~ s/two/WBPerson/g;
  $afp{$row[0]}{$two}++; }



my $abstracts;

foreach my $joinkey (sort keys %{ $hash{status} }) {
  next if ($joinkey eq '00000001');
#   next unless ($joinkey eq '00002159');
  print "\nPaper : \"WBPaper$joinkey\"\n";
  print "Status\t\"" . ucfirst($hash{status}{$joinkey}{0}{data}) . "\"\n";
  next if ($hash{status}{$joinkey}{0}{data} ne 'valid');
  my @authors;
  foreach my $table (@normal_tables) {
    next if ($table eq 'status');
    next if ($table eq 'month');
    next if ($table eq 'day');
    foreach my $order (sort {$a<=>$b} keys %{ $hash{$table}{$joinkey} }) {
      my $tag = $tableToTag{$table};
      my $data = $hash{$table}{$joinkey}{$order}{data};
      unless ($table eq 'abstract') {  
        ($data) = &filterAce($data); }	# filter here, future changes will have doublequotes and what not that shouldn't be escaped
      if ($table eq 'year') { 
        if ($hash{month}{$joinkey}{0}{data}) { 
          my $month = $hash{month}{$joinkey}{0}{data};
          if ($month < 10) { $month = "0$month"; }
          $data .= "-$month"; }
        if ($hash{day}{$joinkey}{0}{data}) { 
          my $day = $hash{day}{$joinkey}{0}{data};
          if ($day < 10) { $day = "0$day"; }
          $data .= "-$day"; }
      }
      elsif ($table eq 'identifier') {  
        if ($data =~ m/^\d{8}$/) { $tag = 'Acquires_merge'; $data = "WBPaper$data"; }
        elsif ($data =~ m/^pmid(\d+)$/) { $tag = "Database\t\"MEDLINE\"\t\"PMID\""; $data = $1; }
      }
      elsif ($table eq 'abstract') {  
        $abstracts .= "Longtext : \"WBPaper$joinkey\"\n\n$data\n\n***LongTextEnd***\n\n\n";
        $data = "WBPaper$joinkey";
      }
      elsif ($table eq 'species') {  
        next unless ($indices{species}{$data});		# must have a species
        $data = $indices{species}{$data};
        if ($hash{$table}{$joinkey}{$order}{evi}) {		# if there's evidence column
          my $evi = $hash{$table}{$joinkey}{$order}{evi};
          unless ($evi =~ m/Manually_connected/) {		# skip evidence for Manually_connected tag not in acedb
            $evi =~ s/\"$//;					# strip out last doublequote for print below
            $data .= "\"\t$evi"; } }				# append closing quote, tab, evi
      }
      elsif ($table eq 'author') {  
        my $aid = $data;
        next unless ($indices{author}{$aid});		# must have an author
        next unless ($indices{author}{$aid} =~ m/\S/);	# author must have a word in it
# unless ($indices{author}{$aid}) { print "ERROR author_id missing $aid in paper WBPaper$joinkey\n"; }
        push @authors, $indices{author}{$aid};
        if ($indices{person}{$aid}) { $data = "$indices{author}{$aid}\"\tPerson\t\"$indices{person}{$aid}"; }
          else { $data = $indices{author}{$aid}; }
      }
      elsif ( ($table eq 'erratum_in') || ($table eq 'retraction_in') || ($table eq 'contained_in') ) {  
        $data = 'WBPaper'. $data; 
      }
      elsif ($table eq 'gene') {
        next unless ($data =~ m/[0-9]{8}/);			# only dump if 8 digit WBGene for Kimberly / Wen  2010 08 30
        $data = 'WBGene'. $data;
        if ($hash{$table}{$joinkey}{$order}{evi}) {		# if there's evidence column
          my $evi = $hash{$table}{$joinkey}{$order}{evi};
          unless ($evi =~ m/Manually_connected/) {		# skip evidence for Manually_connected tag not in acedb
            $evi =~ s/\"$//;					# strip out last doublequote for print below
            $data .= "\"\t$evi"; } }				# append closing quote, tab, evi
      }
      elsif ($table eq 'gene_comp') {
        if ($hash{$table}{$joinkey}{$order}{evi}) {		# if there's evidence column
          my $evi = $hash{$table}{$joinkey}{$order}{evi};
          unless ($evi =~ m/Manually_connected/) {		# skip evidence for Manually_connected tag not in acedb
            $evi =~ s/\"$//;					# strip out last doublequote for print below
            $data .= "\"\t$evi"; } }				# append closing quote, tab, evi
      }
      elsif ($table eq 'type') {  
        my $curator = $hash{$table}{$joinkey}{$order}{curator};
        $curator =~ s/two/WBPerson/;
        $data = "$indices{type}{$data}\"\tPerson_evidence\t\"$curator";
      }
      elsif ($table eq 'curation_flags') {  
        next unless ($data eq 'Phenotype2GO');
      }
# unless ($data) { print "ERROR NO DATA $tag $joinkey\n"; }
      if ($data) {
        print "$tag\t\"$data\"\n";
      }
    } # foreach my $order (sort keys %{ $hash{$table}{$joinkey} })
  } # foreach my $table (@normal_tables)
  my ($author, $year, $journal, $title);
  if ($authors[0]) { $author = $authors[0]; }
  if ($authors[1]) { $author .= " et al."; }
#   if ($hash{author}{$joinkey}{1}{data}) { 			# this won't work if pap_author order doesn't start a 1
#     if ($indices{author}{$hash{author}{$joinkey}{1}{data}}) { 
#       $author = $indices{author}{$hash{author}{$joinkey}{1}{data}}; } 
#     if ($hash{author}{$joinkey}{2}{data}) { $author .= " et al."; }
#   }
  if ($hash{year}{$joinkey}{0}{data}) { $year = $hash{year}{$joinkey}{0}{data}; }
  if ($hash{journal}{$joinkey}{0}{data}) { $journal = $hash{journal}{$joinkey}{0}{data}; }
  if ($hash{title}{$joinkey}{0}{data}) { $title = $hash{title}{$joinkey}{0}{data}; }
#   my ($brief_citation) = &getEimearBriefCitation( $author, $year, $journal, $title );
  my ($brief_citation) = &getBriefCitation( $author, $year, $journal, $title );	# from package
  if ($brief_citation) { print "Brief_citation\t\"$brief_citation\"\n"; }
  if ($afp{$joinkey}) { 
    foreach my $person (sort keys %{ $afp{$joinkey} }) {
       print "Author_first_pass\t\"$person\"\n"; } }

} # foreach my $joinkey (sort keys %{ $hash{status} })

print "\n\n$abstracts";

  

# special stuff :
# author author_index


# SELECT wpa_author_verified.author_id, wpa_author_possible.wpa_author_possible, wpa_author_verified.wpa_author_verified FROM wpa_author_verified, wpa_author_possible WHERE wpa_author_verified.wpa_author_verified ~ 'YES' AND wpa_author_possible.wpa_author_possible ~ 'two' AND wpa_author_verified.author_id = wpa_author_possible.author_id AND wpa_author_verified.wpa_join = wpa_author_possible.wpa_join;

# special tables :
# gene -> need evidence : joinkey, gene, order, curator, timestamp, evidence
# gene_comp -> need evidence : joinkey, gene_comp, order, curator, timestamp, evidence
# electronic_path -> from electronic_path_type, which has wpa_type instead of order
# author_index -> author_id instead of joinkey
# author_possible -> author_id instead of joinkey
# author_sent -> author_id instead of joinkey
# author_verified -> author_id instead of joinkey
# type_index -> index, type_id instead of joinkey


# sub getEimearBriefCitation {
#   my ($author, $year, $journal, $title) = @_;
#   my $brief_citation = '';
#   my $brief_title = '';                     # brief title (70 chars or less)
#   if ($title) {
#     $title =~ s/"//g;			# some titles properly have doublequotes but don't want them in brief citation
#     my @chars = split //, $title;
#     if ( scalar(@chars) < 70 ) {
#         $brief_title = $title;
#     } else {
#         my $i = 0;                            # letter counter (want less than 70)
#         my $word = '';                        # word to tack on (start empty, add characters)
#         while ( (scalar(@chars) > 0) && ($i < 70) ) { # while there's characters, and less than 70 been read
#             $brief_title .= $word;            # add the word, because still good (first time empty)
#             $word = '';                       # clear word for next time new word is used
#             my $char = shift @chars;          # read a character to start / restart check
#             while ( (scalar(@chars) > 0) && ($char ne ' ') ) {        # while not a space and still chars
#                 $word .= $char; $i++;         # build word, add to counter (less than 70)
#                 $char = shift @chars;         # read a character to check if space
#             } # while ($_ ne '')              # if it's a space, exit loop
#             $word .= ' ';                     # add a space at the end of the word
#         } # while ( (scalar(@chars) > 0) && ($i < 70) )
#         $brief_title = $brief_title . "....";
#     } }
#   if ($author) { if ( length($author) > 0) { $brief_citation .= $author; } }
#   if ($year) { 
#     if ($year =~ m/ -C .*$/) { $year =~ s/ -C .*$//g; }
#     if ( length($year) > 0) { $brief_citation .= " ($year)"; } }
#   if ($journal) { 
#     $journal =~ s/"//g;			# some journals are messed up and have doublequotes
#     if ( length($journal) > 0) { $brief_citation .= " $journal"; } }
#   if ($brief_title) { if ( length($brief_title) > 0) { $brief_citation .= " \\\"$brief_title\\\""; } }
#   if ($brief_citation) { return $brief_citation; }
# } # sub getEimearBriefCitation


sub filterAce {
  my $identifier = shift;
  my $comment = '';
  if ($identifier =~ m/-COMMENT (.*)/) { $comment = $1; $identifier =~ s/-COMMENT .*//; }
  if ($identifier =~ m/HTTP:\/\//i) { $identifier =~ s/HTTP:\/\//PLACEHOLDERASDF/ig; }
  if ($identifier =~ m/\//) { $identifier =~ s/\//\\\//g; }
  if ($identifier =~ m/\"/) { $identifier =~ s/\"/\\\"/g; }
#   if ($identifier =~ m/\\\/\\\//) { $identifier =~ s/\\\/\\\//" "/g; }	# convert // into " " for old pages / volume
  if ($identifier =~ m/\s+$/) { $identifier =~ s/\s+$//; }
  if ($identifier =~ m/PLACEHOLDERASDF/) { $identifier =~ s/PLACEHOLDERASDF/HTTP:\\\/\\\//g; }
  if ($identifier =~ m/;/) { $identifier =~ s/;/\\;/g; }
  if ($identifier =~ m/%/) { $identifier =~ s/%/\\%/g; }
  if ($comment) {
    if ($identifier =~ m/[^"]$/) { $identifier .= "\" "; }
    $identifier .= "-C \"$comment"; }
  return $identifier;
} # sub filterAce


