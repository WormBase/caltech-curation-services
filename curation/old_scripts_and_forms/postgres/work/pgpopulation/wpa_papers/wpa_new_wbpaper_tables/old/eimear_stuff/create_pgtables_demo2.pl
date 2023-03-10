#!/usr/bin/perl

# parse from citace 2004 11 23 into postgres's new paper tables.  2004 11 23
#
# to test in demo database will need to create a sample entry (here 123)
# INSERT INTO two_standardname VALUES ('two123', '1', 'Bob');
# to put in real database, will need to make two_standardname_idx be a unique
# index for the joinkey of two_standardname to be a good constraint for all
# the wbp_ tables.  2005 03 02

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=demo2");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $result;

my $infile = '/home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/paper_sample20050120.ace';
$/ = '';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  unless ($entry =~ m/^Paper : /) { print "ERR no Paper in $entry\n"; next; }
  my ($joinkey) = $entry =~ m/Paper : \"WBPaper(\d+)\"/;
#   $joinkey = "\'$joinkey\'";

  $result = $conn->exec( "INSERT INTO wbp VALUES ('$joinkey', DEFAULT, CURRENT_TIMESTAMP, 'two123');");
  print "INSERT INTO wbp VALUES ($joinkey, DEFAULT, CURRENT_TIMESTAMP, 'two123');\n";

#   my $joinkey = '';
#   $result = $conn->exec( "SELECT wbp_id FROM wbp ORDER BY entered_when DESC;");
#   my @row = $result->fetchrow;
#   if ($row[0]) { $row[0] =~ s///g; $joinkey = $row[0]; }

  my ($wbp_name) = $entry =~ m/^Paper : \"(WBPaper\d+)\"/;
  my $cgc_name = 'NULL'; my $pmid_name = 'NULL'; my $meet_name = 'NULL'; my $wbg_name = 'NULL'; my $med_name = 'NULL'; my $oth_name = 'NULL'; my $wpa_oth = 'NULL';
# now serial, so no cgc or pmid in id
#   if ($entry =~ m/\nCGC_name/) { ($cgc_name) = $entry =~ m/CGC_name\s+\"([\w\.]+)\"/; $cgc_name = "\'$cgc_name\'"; }
#   if ($entry =~ m/\nPMID/) { ($pmid_name) = $entry =~ m/PMID\s+\"([\w\.]+)\"/; $pmid_name = 'pmid' . $pmid_name; $pmid_name = "\'$pmid_name\'"; }
  if ($entry =~ m/\nCGC_name/) { ($cgc_name) = $entry =~ m/CGC_name\s+\"([\w\.]+)\"/; $cgc_name =~ s/cgc//g; $cgc_name = "\'$cgc_name\'"; }
  if ($entry =~ m/\nPMID/) { ($pmid_name) = $entry =~ m/PMID\s+\"([\w\.]+)\"/; $pmid_name = "\'$pmid_name\'"; }
  if ($entry =~ m/\nMedline_name/) { ($med_name) = $entry =~ m/Medline_name\s+\"([\w\.]+)\"/; $med_name = 'med'.$med_name; $med_name = "\'$med_name\'"; }
  if ($entry =~ m/\nMeeting_abstract/) { ($meet_name) = $entry =~ m/Meeting_abstract\s+\"([\w\.]+)\"/; $meet_name = "\'$meet_name\'"; }
  if ($entry =~ m/\nWBG_abstract/) { ($wbg_name) = $entry =~ m/WBG_abstract\s+\"([\w\.]+)\"/; $wbg_name = "\'$wbg_name\'"; }
  if ($entry =~ m/\nOther_name/) { ($oth_name) = $entry =~ m/Other_name\s+\"([\w\.]+)\"/; $oth_name = "\'$oth_name\'"; }
  if ($entry =~ m/\nOld_WBPaper/) { ($wpa_oth) = $entry =~ m/Old_WBPaper\s+\"([\d]+)\"/; $wpa_oth = "\'$wpa_oth\'"; }
  $result = $conn->exec( "INSERT INTO wbp_identifier VALUES ($joinkey, $wpa_oth, $cgc_name, $pmid_name, $med_name, $meet_name, $wbg_name, $oth_name, CURRENT_TIMESTAMP, 'two123');");
  print "INSERT INTO wbp_identifier VALUES ($joinkey, $wpa_oth, $cgc_name, $pmid_name, $med_name, $meet_name, $wbg_name, $oth_name, CURRENT_TIMESTAMP, 'two123');\n";
  
  if ($entry =~ m/\nTitle/) { 
#     my ($title) = $entry =~ m/Title\s+\"([\-\{\}\w\.]+)\"/; 
    my ($title) = $entry =~ m/Title\s+\"([^\"]+)\"/; $title = "\'$title\'";
    $result = $conn->exec( "INSERT INTO wbp_title VALUES ($joinkey, $title, CURRENT_TIMESTAMP, 'two123');"); 
    print "INSERT INTO wbp_title VALUES ($joinkey, $title, CURRENT_TIMESTAMP, 'two123');\n" }
  if ($entry =~ m/\nPublisher/) { 
#     my ($publisher) = $entry =~ m/Publisher\s+\"([\w\.]+)\"/; 
    my ($publisher) = $entry =~ m/Publisher\s+\"([^\"]+)\"/; $publisher = "\'$publisher\'";
    print "INSERT INTO wbp_publisher VALUES ($joinkey, $publisher, CURRENT_TIMESTAMP, 'two123');\n"; 
    $result = $conn->exec( "INSERT INTO wbp_publisher VALUES ($joinkey, $publisher, CURRENT_TIMESTAMP, 'two123');"); }
  if ($entry =~ m/\nJournal/) { 
#     my ($journal) = $entry =~ m/Journal\s+\"([\w\.]+)\"/; 
    my ($journal) = $entry =~ m/Journal\s+\"([^\"]+)\"/; $journal = "\'$journal\'";
    $result = $conn->exec( "INSERT INTO wbp_journal VALUES ($joinkey, $journal, CURRENT_TIMESTAMP, 'two123');"); 
    print "INSERT INTO wbp_journal VALUES ($joinkey, $journal, CURRENT_TIMESTAMP, 'two123');\n" }
  if ($entry =~ m/\nVolume/) { 
#     my ($volume) = $entry =~ m/Volume\s+\"([\w\.]+)\"/; 
    my ($volume) = $entry =~ m/Volume\s+\"([^\"]+)\"/; $volume = "\'$volume\'";
    print "INSERT INTO wbp_volume VALUES ($joinkey, $volume, CURRENT_TIMESTAMP, 'two123');\n"; 
    $result = $conn->exec( "INSERT INTO wbp_volume VALUES ($joinkey, $volume, CURRENT_TIMESTAMP, 'two123');"); }
  if ($entry =~ m/\nPage/) { 
#     my ($page) = $entry =~ m/Page\s+\"([\w\.]+)\"/; 
# convert spaces to // for Eimear as separator  2005 03 03
    my ($page) = $entry =~ m/Page\s+\"(.+)\"\n/; $page =~ s/ /\/\//g; $page = "\'$page\'"; $page =~ s/\"//g;
    print "INSERT INTO wbp_pages VALUES ($joinkey, $page, CURRENT_TIMESTAMP, 'two123');\n";
    $result = $conn->exec( "INSERT INTO wbp_pages VALUES ($joinkey, $page, CURRENT_TIMESTAMP, 'two123');"); }
  if ($entry =~ m/\nYear/) { 
#     my ($year) = $entry =~ m/Year\s+([\w\.]+)/; 
    my ($year) = $entry =~ m/Year\s+([\d]+)/; # $year = "\'$year\'"; # year's an integer
    $result = $conn->exec( "INSERT INTO wbp_year VALUES ($joinkey, $year, CURRENT_TIMESTAMP, 'two123');");
    print "INSERT INTO wbp_year VALUES ($joinkey, $year, CURRENT_TIMESTAMP, 'two123');\n" }
  if ($entry =~ m/\nAbstract/) { 
#     my ($abstract) = $entry =~ m/Abstract\s+\"([\w\.]+)\"/; 
    my ($abstract) = $entry =~ m/Abstract\s+\"([^\"]+)\"/; $abstract = "\'$abstract\'";
    print "INSERT INTO wbp_abstract VALUES ($joinkey, $abstract, CURRENT_TIMESTAMP, 'two123');\n";
    $result = $conn->exec( "INSERT INTO wbp_abstract VALUES ($joinkey, $abstract, CURRENT_TIMESTAMP, 'two123');"); }
  if ($entry =~ m/\nAffiliation/) { 
#     my ($affiliation) = $entry =~ m/Affiliation\s+\"([\w\.]+)\"/; 
    my ($affiliation) = $entry =~ m/Affiliation\s+\"([^\"]+)\"/; $affiliation = "\'$affiliation\'";
    print "INSERT INTO wbp_affiliation VALUES ($joinkey, $affiliation, CURRENT_TIMESTAMP, 'two123');\n"; 
    $result = $conn->exec( "INSERT INTO wbp_affiliation VALUES ($joinkey, $affiliation, CURRENT_TIMESTAMP, 'two123');"); }
 
  if ($entry =~ m/\nAuthor/) { 
#     my (@authors) = $entry =~ m/Author\s+\"([\w\.]+)\"/g; 
    my (@authors) = $entry =~ m/Author\s+\"([^\"]+)\"/g; 
    my $auth_affiliation = 'NULL';
    my $rank = 0;
    foreach my $author (@authors) {
      $author = "\'$author\'";
      $rank++;
      print "Author $author Rank $rank\n";
      $result = $conn->exec( "INSERT INTO wbp_author_idx VALUES (DEFAULT, $author, $auth_affiliation, CURRENT_TIMESTAMP, 'two123');"); 
      print "INSERT INTO wbp_author_idx VALUES (DEFAULT, $author, $auth_affiliation, CURRENT_TIMESTAMP, 'two123')\n";
      my $auth_joinkey = '';
      $result = $conn->exec( "SELECT author_id FROM wbp_author_idx ORDER BY entered_when DESC;");
      my @row = $result->fetchrow;
      if ($row[0]) { $row[0] =~ s///g; $auth_joinkey = $row[0]; }
      $result = $conn->exec( "INSERT INTO wbp_author VALUES ($joinkey, $auth_joinkey, $rank, DEFAULT, CURRENT_TIMESTAMP, 'two123');"); 
      print "INSERT INTO wbp_author VALUES ($joinkey, $auth_joinkey, $rank, DEFAULT, CURRENT_TIMESTAMP, 'two123')\n";
    }
  }

}
close (IN) or die "Cannot close $infile : $!";

# ?Paper  Name    CGC_name 		# number only
#                 PMID     		# number only
#                 Medline_name 		# number only
#                 Meeting_abstract 
#                 WBG_abstract    
#                 Old_WBPaper 
#                 Other_name 
#         Reference       Title 
#                         Publisher
#                         Journal 
#                         Volume
#                         Page  
#                         Year 
#                         Editor 	# no table for this, boolean later in authors
#         Author ?Author XREF Paper #Affiliation        # into wbp_author_idx 's affiliation column
#         Person ?Person XREF Paper
#         Affiliation 	# into wbp_affiliation
#         Abstract 
#         Type 		# wait for Eimear's type table mapping.

# wbp 
# wbp_identifier
#     cgc_id varchar(10),
#     pmid_id varchar(20),
#     medline_id varchar(20),
#     meeting_id varchar(20),
#     wbg_id varchar(20),
#     other_id varchar(30),

# wbp_title
# wbp_publisher
# wbp_journal
# wbp_volume
# wbp_pages
# wbp_year
# wbp_abstract
# wbp_affiliation

# wbp_author_idx
# wbp_author
# wbp_author_person

# wbp_gene_idx
# wbp_gene
# wbp_paper
# wbp_hardcopy
# wbp_type_idx
# wbp_type
# wbp_electronic_type_idx
# wbp_electronic_status_idx
# wbp_fulltext_url
# wbp_comments

# Paper : "WBPaper00024500"
# PMID	 "15489511"
# Title	 "Convergent, RIC-8 Dependent G{alpha} Signaling Pathways in the C. elegans Synaptic Signaling Network."
# Journal	 "Genetics"
# Year	 2004
# Author	 "Reynolds NK"
# Author	 "Schade MA"
# Author	 "Miller K"
# Brief_citation	 "Reynolds NK (2004) Genetics \"Convergent, RIC-8 Dependent G{alpha} Signaling Pathways in the C. elegans ....\""
# Abstract	 "WBPaper00024500"
# Gene	 "WBGene00004367" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
# 
# Paper : "WBPaper00024501"
# PMID	 "15489852"
# Title	 "Two anterograde intraflagellar transport motors cooperate to build sensory cilia on C. elegans neurons."
# Journal	 "Nat Cell Biol"
# Year	 2004
# Author	 "Snow JJ"
# Author	 "Ou G"
# Author	 "Gunnarson AL"
# Author	 "Walker MR"
# Author	 "Zhou HM"
# Author	 "Brust-Mascher I"
# Author	 "Scholey JM"
# Brief_citation	 "Snow JJ (2004) Nat Cell Biol \"Two anterograde intraflagellar transport motors cooperate to build sensory ....\""
# Abstract	 "WBPaper00024501"
# 
# Paper : "WBPaper00024502"
# CGC_name	 "cgc6824"
# PMID	 "15490828"
# Title	 "Automatic tracking, feature extraction and classification of C elegans phenotypes."
# Journal	 "IEEE Trans Biomed Eng"
# Page	 "1811" "1820"
# Volume	 "51"
# Year	 2004
# Author	 "Geng W"
# Author	 "Cosman P"
# Author	 "Berry CC"
# Author	 "Feng Z"
# Author	 "Schafer WR"
# Brief_citation	 "Geng W (2004) IEEE Trans Biomed Eng \"Automatic tracking, feature extraction and classification of C elegans ....\""
# 
# Paper : "WBPaper00024503"
# PMID	 "15492042"
# Title	 "The forces that position a mitotic spindle asymmetrically are tethered until after the time of spindle assembly."
# Journal	 "J Cell Biol"
# Year	 2004
# Author	 "Labbe JC"
# Author	 "McCarthy EK"
# Author	 "Goldstein B"
# Brief_citation	 "Labbe JC (2004) J Cell Biol \"The forces that position a mitotic spindle asymmetrically are tethered until ....\""
# 
# Paper : "WBPaper00024504"
# PMID	 "15492222"
# Title	 "Feeding status and serotonin rapidly and reversibly modulate a Caenorhabditis elegans chemosensory circuit."
# Journal	 "Proc Natl Acad Sci U S A"
# Year	 2004
# Author	 "Chao MY"
# Author	 "Komatsu H"
# Author	 "Fukuto HS"
# Author	 "Dionne HM"
# Author	 "Hart AC"
# Brief_citation	 "Chao MY (2004) Proc Natl Acad Sci U S A \"Feeding status and serotonin rapidly and reversibly modulate a Caenorhabditis ....\""
# Abstract	 "WBPaper00024504"
# Gene	 "WBGene00001612" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
# 
# Paper : "WBPaper00024505"
# PMID	 "15492775"
# Title	 "Whole-Genome Analysis of Temporal Gene Expression during Foregut Development."
# Journal	 "PLoS Biol"
# Page	 "E352"
# Volume	 "2"
# Year	 2004
# Author	 "Gaudet J"
# Author	 "Muttumu S"
# Author	 "Horner M"
# Author	 "Mango SE"
# Brief_citation	 "Gaudet J (2004) PLoS Biol \"Whole-Genome Analysis of Temporal Gene Expression during Foregut ....\""
# Abstract	 "WBPaper00024505"
# Gene	 "WBGene00004013" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
# Cell_group	 "pharynx" Inferred_automatically "abstract2aceCGC.pl script, 2004-10-22 - Eimear Kenny"
# 
# Paper : "WBPaper00024506"
# PMID	 "15493014"
# Title	 "Isolation of mutations with dumpy-like phenotypes and of collagen genes in the nematode Pristionchus pacificus."
# Journal	 "Genesis"
# Page	 "176" "183"
# Volume	 "40"
# Year	 2004
# Author	 "Kenning C"
# Author	 "Kipping I"
# Author	 "Sommer RJ"
# Brief_citation	 "Kenning C (2004) Genesis \"Isolation of mutations with dumpy-like phenotypes and of collagen genes in the ....\""
# Abstract	 "WBPaper00024506"
# 
# Paper : "WBPaper00024507"
# CGC_name	 "cgc6785"
# Title	 "A clean start: degradation of maternal proteins at the oocyte-to-embryo transition."
# Journal	 "Trends in Cell Biology"
# Page	 "420" "426"
# Volume	 "14"
# Year	 2004
# Author	 "DeRenzo C"
# Author	 "Seydoux G"
# Brief_citation	 "DeRenzo C (2004) Trends in Cell Biology \"A clean start: degradation of maternal proteins at the oocyte-to-embryo ....\""
# Abstract	 "WBPaper00024507"
# Gene	 "WBGene00000837" Person_evidence "WBPerson627"
# Gene	 "WBGene00000838" Person_evidence "WBPerson627"
# Gene	 "WBGene00003150" Person_evidence "WBPerson627"
# Gene	 "WBGene00003183" Person_evidence "WBPerson627"
# Gene	 "WBGene00003184" Person_evidence "WBPerson627"
# Gene	 "WBGene00003209" Person_evidence "WBPerson627"
# Gene	 "WBGene00003228" Person_evidence "WBPerson627"
# Gene	 "WBGene00003230" Person_evidence "WBPerson627"
# Gene	 "WBGene00003231" Person_evidence "WBPerson627"
# Gene	 "WBGene00003864" Person_evidence "WBPerson627"
# Gene	 "WBGene00003916" Person_evidence "WBPerson627"
# Gene	 "WBGene00004027" Person_evidence "WBPerson627"
# Gene	 "WBGene00004078" Person_evidence "WBPerson627"
# Gene	 "WBGene00004341" Person_evidence "WBPerson627"
# Gene	 "WBGene00006977" Person_evidence "WBPerson627"
# Cell_group	 "zygote" Inferred_automatically "abstract2aceCGC.pl script, 2004-11-11 - Eimear Kenny"
# Life_stage	 "embryo" Inferred_automatically "abstract2aceCGC.pl script, 2004-11-11 - Eimear Kenny"
# 
