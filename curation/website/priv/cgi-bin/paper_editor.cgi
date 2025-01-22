#!/usr/bin/env perl

# edit pap tables's paper data

# The search feature is much more generalized, allowing search on
# any field, and allowing substring matches, as well as case insensitive
# matches (which are substring searches by default).
# 
# Instead of search for a given field, just type in as many different
# fields as you like, with the independent substring / case options, and
# it will search all those things, ranking results with how many matches
# something has.
# 
# So, e.g., searching for year "2001" and author "paul sternb" (case
# insensitive), gives 8 papers with 2 categories matching, and a ton of
# papers that match either "paul sternb" or "2001" below that.
# 
# Typing in anything with a number in the number search will override
# other search parameters and give back that exact paper ID match.
# (padding zeroes for you and excluding non-digit text).
# 
# electronic_path converts to PDF links
# author, gene, and type  show the author name (as well as ID), locus
# name (as well as WBGene), and type name (instead of type index value)
# 
# author information also shows in a separate table the corresponding
# person data, if there's any.
# 
# Toggling on the history display uses the history tables instead of the
# normal tables.  2010 03 01
#
# author verification is now through this form instead of confirm_paper.cgi
# by making a toggleTripleField in &paperAuthorPersonGroup();  2010 06 09
#
# changed &authorGeneDisplay() to use pap tables instead of wpa tables,
# although it's still querying for Curator_confirmed instead of 
# Manually_connected.  Possibly want Manually_connected to show what was
# entered when the WBGene was connected.  2010 06 24
#
# Live 2010 06 25
#
# only show pap_status = 'valid' papers in &rnaiCuration();  2010 08 04
#
# added a blank curator option and give error if not picked one.  2010 08 09
#
# made this curators in frontpage an array of two#, instead of the changing 
# standard names.  less convenient, but won't fail when someone changes 
# their name  (idea on 2010 04 23, on 2010 08 25 Chris had this problem, and 
# I finally did it)  2010 08 25
#
# Added Daniela.  two12028 |         1 | Daniela Raciti.  2010 09 10
#
# changed  &rnaiCuration()  to look at both cfp_rnai and afp_rnai (and cfp_lsrnai
# and afp_lsrnai)  instead of just the cfp tables.  2010 09 15
#
# added two4025 Gary Williams.  2010 09 20

# added  remove  option to  &showConfirmXmlTable   which allows  &confirmAbstracts 
# to treat removed papers the same as rejected papers, but storing them at
# /home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/removed_pmids
# for Kimberly.  2010 11 12
#
# pubmed_final is not an editable field, don't display to prevent errors.
# for Daniela / Kimberly.   2010 12 13
#
# changed  &updatePostgresAuthorIndexField  because it was passing @row2 variables
# to  &updatePostgresByTableJoinkeyNewvalue  which meant the first call of
# &updatePostgresByTableJoinkeyNewvalue  would replace the values of @row2 and
# make the 2nd and 3rd fail (for sent and verified).  2011 04 21
#
# changed  &updatePostgresTableField  because $newValue wasn't getting the 
# singlequotes escaped for postgres.  2011 04 25
#
# changed  &search  to only count multiple matches on a given joinkey-table once 
# (it was counting multiples, e.g. identifier ~ '12' would say 'cgc12' 'pmid123'
# as 2 matches) ;  also to display all matches (would only show 'pmid123' and now
# shows ``cgc12, pmid123'').
# changed  &firstPage  to have dropdowns for 'status', 'pubmed_final', 
# 'curation_flags', 'primary_data'.  For Kimberly.  2011 05 03
#
# To  &enterNewPapers  added  &showEnterNonpmidPaper  for display of sectin / button
# to create a new WBPaperID.  Calls  &enterNonPmids  to create the id and display it.
# For Kimberly.  2011 05 06
#
# changed  &findDeadGenes  to point at the paper_editor instead of old wbpaper_editor.
# changed  &authorGeneDisplay  to point at the paper_editor instead of old 
# wbpaper_editor.  2011 05 09
#
# changed  &enterNonPmids  because it displayed the editor, and when editing, it would
# reload the page, which would re-create yet another new paperId.  Changed javascript
# for  window load  for whichPage === 'enterNonPmids'.  2011 05 23
#
# got rid of false positive buttons and subroutines since they should now go in the 
# curation status form.  2013 02 01
#
# added Kevin Home and Michael Paulini.  2013 04 18
#
# changed 'functional_annotation' to 'non_nematode' in postgres and form.  2013 12 05
#
# added 'x' button next to number query field for Mary Ann, approved by Kimberly. 
# 2014 06 19
# 
# added 'emailed_community_gene_descrip' as option for 'curation_flags'.  for Ranjana.
# 2015 10 06
#
# added  pap_author_corresponding  and can edit those with a new
#  makeToggleDoubleField  for Chris, Cecilia, Kimberly.  2015 11 17
#
# added  pap_type_index  Micropublication for Daniela and Kimberly to form and to 
# postgres.  2016 10 13
#
# added  species  field to section for entering PMIDs.  
# made 'priority' default and removed blank option.  2016 10 18
#
# added Marie-Claire Harrison.  2018 07 17
#
# added Jae Cho.  2018 07 17
#
# pap_species now has an evidence column, allow deletion of rows like pap_gene.
# always add a couple of evidences.  pass speciesTaxons instead of just taxons 
# to pap_match.pm  2019 02 05
#
# added Jane Mendel.  2019 03 28
#
# added pap_retraction_in  2019 11 14
#
# added Stavros Diamantakis  2021 11 08
#
# http for .js wasn't working anymore after tazendra move to Chen and back, and possibly because of ssl cert that Valerio wanted.
# cloudflare links Sybil found weren't working because of a type error or something.  Downloaded needed files and pointed to
# https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/  2021 11 16
#
# pap_gene_comp added for comparator genes using gic_ table.  Had to generalize
# stuff to work like 'gene' but for 'gene_comp'.  for Kimberly.  2022 02 11
#
# Dockerized but added back pubmed xml pipeline to create papers from xml.  2023 04 17
#
# paper editor species curator was showing logged in curator instead of database curator, fixed.  2025 01 22



# 1) Identifiers - Identifier, Contained_in, Erratum_in, Status, Remark
# 2) Publication Info - Title, Author, Affiliation, Journal, Publisher,
# Editor, Page, Volume, Publication date (year, month, day), Abstract,
# Full_text URL
# 3) Genes
# 4) Electronic Path



use strict;
use CGI;
use Fcntl;
use Jex;
use DBI;
use Tie::IxHash;
use LWP::Simple;
use POSIX qw(ceil);
use Dotenv -load => '/usr/lib/.env';

# in dockerized no longer process pubmed xml	# OBSOLETE when Biblio SoT to ABC  2023 04 17
# use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use lib qw(  /usr/lib/scripts/perl_modules/ );                      # for paper matching and generating
use pap_match qw( processXmlIds );


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $query = new CGI;
my $oop;

my $frontpage = 1;
# my $blue = '#00ffcc';			# redefine blue to a mom-friendly color
my $blue = '#e8f8ff';			# redefine blue to a mom-friendly color
my $red = '#ff00cc';			# redefine red to a mom-friendly color


my %curators;                           # $curators{two}{two#} = std_name ; $curators{std}{std_name} = two#
my %type_index;				# hash of possible 7 types of paper
&populateTypeIndex();	
my %valid_paper_index;			# hash of papers that are valid
&populateValidPaperIndex();	
my %month_index;				# hash of possible 7 types of paper
&populateMonthIndex();	

my @normal_tables = qw( status species electronic_path pubmed_final identifier contained_in erratum_in retraction_in title author affiliation journal abstract publisher editor pages volume year month day type fulltext_url remark gene gene_comp curation_flags curation_done internal_comment primary_data );
# my @normal_tables = qw( gene status electronic_path pubmed_final identifier contained_in erratum_in retraction_in title author affiliation journal abstract publisher editor pages volume year month day type fulltext_url remark curation_flags internal_comment primary_data );

my %single; my %multi;			# whether tables are single value or multivalue
&populateSingleMultiTableTypes();

&display();


# my @generic_tables = qw( title publisher journal volume pages year abstract affiliation comments paper );

# my @generic_tables = qw( wpa wpa_identifier wpa_title wpa_publisher wpa_journal wpa_volume wpa_pages wpa_year wpa_date_published wpa_fulltext_url wpa_abstract wpa_affiliation wpa_type wpa_author wpa_hardcopy wpa_comments wpa_editor wpa_nematode_paper wpa_contained_in wpa_contains wpa_keyword wpa_erratum wpa_in_book );



sub display {
  my $action; my $normal_header_flag = 1;

  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Search') { &search(); }
  elsif ($action eq 'Merge') { &displayMerge(); }
  elsif ($action eq 'Page') { &enterNewPapers('page'); }
  elsif ($action eq 'Enter New Papers') { &enterNewPapers('wormbase'); }
  elsif ($action eq 'Enter New Parasite Papers') { &enterNewPapers('parasite'); }
  elsif ($action eq 'Enter PMIDs') { &enterPmids(); }				# obsolete in dockerized 2023 03 21  # comment out when SoT to ABC 2023 04 17
  elsif ($action eq 'Enter non-PMID paper') { &enterNonPmids(); }
  elsif ($action eq 'Confirm Abstracts') { &confirmAbstracts(); }		# obsolete in dockerized 2023 03 21  # comment out when SoT to ABC 2023 04 17
  elsif ($action eq 'Find Dead Genes') { &findDeadGenes(); }				# sort by genes, link to each paper per gene
#   elsif ($action eq 'Flag False Positives') { &flagFalsePositives(); }
#   elsif ($action eq 'Enter False Positives') { &enterFalsePositives(); }
#   elsif ($action eq 'Show False Positives') { &showFalsePositives(); }
  elsif ($action eq 'RNAi Curation') { &rnaiCuration(); }
  elsif ($action eq 'Person Author Curation') { &personAuthorCuration(); }
  elsif ($action eq 'Paper Author Person Group') { &paperAuthorPersonGroup(); }
  elsif ($action eq 'Author Gene Curation') { &authorGeneDisplay(); }			# for Karen
  elsif ($action eq 'updatePostgresTableField') { &updatePostgresTableField(); }
  elsif ($action eq 'autocompleteXHR') { &autocompleteXHR(); }

#   elsif ($action eq 'deletePostgresTableField') { &deletePostgresTableField(); }	# use blank &updatePostgresByTableJoinkeyNewvalue(); instead

#   if ($action eq 'Number !') { &pickNumber(); }
#   elsif ($action eq 'Author !') { &pickAuthor(); }
#   elsif ($action eq 'Title !') { &pickTitle(); }
#   else { 1; }
} # sub display

sub autocompleteXHR {		# made for pap_species, not really generalized
  print "Content-type: text/plain\n\n";
  (my $var, my $words) = &getHtmlVar($query, 'query');
  ($var, my $order) = &getHtmlVar($query, 'order');
  ($var, my $field) = &getHtmlVar($query, 'field');
  my $table = 'two_' . $field; my $column = $table;
  if ($field eq 'species') { $table = 'pap_species_index'; $column = 'joinkey'; }
  my $max_results = 20; if ($words =~ m/^.{5,}/) { $max_results = 500; }
  ($words) = lc($words);                                        # search insensitively by lowercasing query and LOWER column values
  my %matches; my $t = tie %matches, "Tie::IxHash";     # sorted hash to filter results
  my $result = $dbh->prepare( "SELECT joinkey, $table FROM $table WHERE LOWER($table) ~ '^$words' ORDER BY $table;" );
#   print qq( "SELECT joinkey, $table FROM $table WHERE LOWER($table) ~ '^$words' ORDER BY $table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) { $matches{"$row[1] $row[0]"}++; }
  $result = $dbh->prepare( "SELECT joinkey, $table FROM $table WHERE LOWER($table) ~ '$words' AND LOWER($table) !~ '^$words' ORDER BY $table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while ( (my @row = $result->fetchrow()) && (scalar keys %matches < $max_results) ) { $matches{"$row[1] $row[0]"}++; }
  if (scalar keys %matches >= $max_results) { $t->Replace($max_results - 1, 'no value', 'more ...'); }
  my $matches = join"\n", keys %matches; print $matches;
} # sub autocompleteXHR

sub stub {
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"stub\">";
  print "Code not ready yet<br />\n";
  &printFooter();
}

sub paperAuthorPersonGroup {
  &printHtmlHeader();
  &populateCurators();						# for verified yes / no standard name
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  print "<input type=\"hidden\" name=\"curator_id\" id=\"curator_id\" value=\"$curator_id\">";
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"paperAuthorPersonGroup\">";

  ($oop, my $two_id) = &getHtmlVar($query, 'two_id');
  ($oop, my $paper_aid_in_group) = &getHtmlVar($query, 'paper_aid_in_group');
  my ($lastnames_arrayref, $all_names_hashref) = &displayPersonInfo($two_id);

  my $category_index_hashref = &populateCategoryIndex();
  my %category_index = %$category_index_hashref;

  my %papers; my %aids; my @papers = split/\t/, $paper_aid_in_group;
  foreach my $paper_aid_color (@papers) {
    my ($joinkey, $aid, $category) = split/, /, $paper_aid_color;
    $aids{$aid}++;
    $papers{$joinkey}{aid} = $aid;
    $papers{$joinkey}{category} = $category;
    $papers{$joinkey}{color} = $category_index{$category}{color}; }
  my (@joinkeys) = sort keys %papers; my $joinkeys = join"', '", @joinkeys;
  my (@aids) = sort keys %aids; my $aids = join"', '", @aids;
 
  my %paper_hash; my @tables = qw( title identifier electronic_path year );
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE joinkey IN ('$joinkeys');" );
#     if ($table eq 'identifier') { $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN ('$joinkeys')"); }		# for only pmids, but Cecilia wants all to see abstracts
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      unless ($row[2]) { $row[2] = 0; }
      $paper_hash{$table}{$row[0]}{$row[2]} = $row[1]; } }

  my %aid_hash; my @author_tables = qw( index possible verified );
  foreach my $table (@author_tables) {
    $result = $dbh->prepare( "SELECT * FROM pap_author_$table WHERE author_id IN ('$aids');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      unless ($row[2]) { $row[2] = 0; }
      $aid_hash{$row[0]}{$row[2]}{$table} = $row[1]; } }

  print "<table style=\"border-style: none;\" border=\"1\" >";
  foreach my $joinkey (@joinkeys) {
    my $pap_link = "paper_editor.cgi?curator_id=$curator_id&action=Search&data_number=$joinkey";
    print "<tr><td class=\"normal_odd\" colspan=\"5\"><br/><a href=\"$pap_link\">$joinkey</a></td></tr>\n";
    foreach my $table (@tables) {
      if ($paper_hash{$table}{$joinkey}) {
        foreach my $order (sort {$a<=>$b} keys %{ $paper_hash{$table}{$joinkey} }) {
          my $data = $paper_hash{$table}{$joinkey}{$order};
          my $table_name = $table;
          if ($table eq 'identifier') { if ($data =~ m/pmid/) { ($data) = &makeNcbiLinkFromPmid($data); } }
          elsif ($table eq 'electronic_path') { ($data) = &makePdfLinkFromPath($data); $table_name = 'pdf'; }
          print "<tr><td class=\"normal_odd\" colspan=\"1\">$table_name</td><td class=\"normal_odd\" colspan=\"4\">$data</td></tr>\n"; } } }
    my $aid = $papers{$joinkey}{aid};
    my $color = $papers{$joinkey}{color};
    my $category = $papers{$joinkey}{category};
    my $aid_name = ''; my @entries; my $flag_show_buttons = 1;
    if ($aid_hash{$aid}{0}{index}) { $aid_name = "<span style=\"color: $color\">$aid_hash{$aid}{0}{index}</span>"; }
    foreach my $join (sort {$a<=>$b} keys %{ $aid_hash{$aid} }) {
      next if ($join == 0);				# skip non-existing joins
      my $possible = ''; my $verified = ''; 
      my $alink_color = 'grey';				# possible that do not match current two_id have links in this colour
      if ($aid_hash{$aid}{$join}{possible}) { 
        $possible = $aid_hash{$aid}{$join}{possible}; 
        if ($possible eq $two_id) { $flag_show_buttons = 0; $alink_color = 'blue'; } }		# if possible matches person, it's already connected, don't show buttons
      if ($aid_hash{$aid}{$join}{verified}) { $verified = $aid_hash{$aid}{$join}{verified}; }
      my $on = "YES  $curators{two}{$curator_id}"; my $off = "NO  $curators{two}{$curator_id}";
      my ($td_author_verified) = &makeToggleTripleField($verified, 'author_verified', $aid, $join, $curator_id, 1, 1, 'normal_odd', $on, $off, '');	# make this a toggleTripleField instead of just a display  2010 06 09
      my $entry = "<td class=\"normal_odd\">$join</td><td class=\"normal_odd\"><a href=\"cecilia/person_editor.cgi?curator_two=$curator_id&action=Search&display_or_edit=display&input_number_1=$possible\" style=\"color: $alink_color\" target=\"new\">$possible</a></td>$td_author_verified";
      # my $entry = "<td class=\"normal_odd\">$join</td><td class=\"normal_odd\"><a href=\"http://tazendra.caltech.edu/~postgres/cgi-bin/cecilia/two_display.cgi?action=Number+!&number=$possible\" style=\"color: $alink_color\" target=\"new\">$possible</a></td>$td_author_verified";
      push @entries, $entry; }
    my $lines_count = scalar(@entries); unless ($lines_count) { $lines_count = 1; } my $first_entry = shift @entries; 
    print "<tr><td rowspan=\"$lines_count\" class=\"normal_odd\" colspan=\"1\">author</td><td rowspan=\"$lines_count\" class=\"normal_odd\" colspan=\"1\">$aid_name ($aid)</td>$first_entry</tr>\n";
    foreach my $entry (@entries) { print "<tr>$entry</tr>\n"; }
#     if ($category > 6) { # }				# this didn't help, we're force reloading after button press, so actually need to check if any possible matches instead
    if ($flag_show_buttons) { 
      my @joins = sort {$b<=>$a} keys %{ $aid_hash{$aid} }; my $new_join = $joins[0] + 1;
      print "<tr><td id=\"td_connect_buttons_$aid\" class=\"normal_odd\" colspan=6>\n";
      print "<button onclick=\"updatePostgresTableField('author_possible', '$aid', '$new_join', '$curator_id', '$two_id', '', ''); document.getElementById('td_connect_buttons_$aid').innerHTML = '';\">connect to $two_id, no verification</button>\n";
      print "<button onclick=\"updatePostgresTableField('author_possible', '$aid', '$new_join', '$curator_id', '$two_id', '', 'nothing'); updatePostgresTableField('author_verified', '$aid', '$new_join', '$curator_id', 'YES  $curators{two}{$curator_id}', '', ''); document.getElementById('td_connect_buttons_$aid').innerHTML = '';\">connect to $two_id and verify YES</button>\n";
      print "<button onclick=\"updatePostgresTableField('author_possible', '$aid', '$new_join', '$curator_id', '$two_id', '', 'nothing'); updatePostgresTableField('author_verified', '$aid', '$new_join', '$curator_id', 'NO  $curators{two}{$curator_id}', '', ''); document.getElementById('td_connect_buttons_$aid').innerHTML = '';\">connect to $two_id and verify NO</button>\n";
#       print "<button onclick=\"updatePostgresTableField('author_possible', '$aid', '$new_join', '$curator_id', '$two_id', '', 'nothing');\">connect to $two_id, no verification</button>\n";
#       print "<button>connect to $two_id and verify YES</button> <button>connect to $two_id and verify NO</button></td>
      print "</tr>\n"; }
#         $curate_link = "<a href=\"#\" onclick=\"updatePostgresTableField('curation_flags', '$joinkey', '$order', '$curator_id', 'rnai_curation', '', 'nothing'); document.getElementById('td_curate_$joinkey').innerHTML = '$curators{two}{$curator_id}'; return false\">curate</a>";
  } # foreach my $joinkey (@joinkeys)
  print "</table>";

  &printFooter();
} # sub paperAuthorPersonGroup

sub personAuthorCuration {
  &printHtmlHeader();
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  ($oop, my $two_number_search) = &getHtmlVar($query, 'two_number_search');
  if ($two_number_search) { if ($two_number_search =~ m/(\d+)/) { $two_number_search = $1; } }
    else { $two_number_search = ''; }
  print "<input type=\"hidden\" name=\"curator_id\" id=\"curator_id\" value=\"$curator_id\">\n";
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"personAuthorCuration\">\n";
  print "two number : <input id=\"two_number_search\" value=\"$two_number_search\" onblur=\"var url = 'paper_editor.cgi?curator_id=$curator_id&action=Person+Author+Curation&two_number_search=' + document.getElementById('two_number_search').value; window.location = url\"><br />\n";
  if ($two_number_search) { 
    my $two_id = 'two' . $two_number_search;
    my ($lastnames_arrayref, $all_names_hashref) = &displayPersonInfo($two_id);
    &displayPaperAuthorMatchesByPerson($curator_id, $two_id, $lastnames_arrayref, $all_names_hashref); }
  &printFooter();
} # sub personAuthorCuration

sub populateCategoryIndex {
  my %category_index;
  $category_index{1}{desc} = 'Verified YES Cecilia';
  $category_index{2}{desc} = 'Verified YES Raymond';
  $category_index{3}{desc} = 'Verified YES';
  $category_index{4}{desc} = 'Verified NO ';
  $category_index{5}{desc} = 'Verified YES to Other possible (not shown)';
  $category_index{6}{desc} = 'Connected not verified';
  $category_index{7}{desc} = 'Connected to Other not verfied';
  $category_index{8}{desc} = 'Exact Match not connected to anyone';
  $category_index{9}{desc} = 'Last name Match';
  $category_index{1}{color} = '#0000ff';
  $category_index{2}{color} = '#880088';
  $category_index{3}{color} = '#00ff00';
  $category_index{4}{color} = '#ff0000';
  $category_index{5}{color} = '#cdb79e';
#   $category_index{5}{color} = 'NO';
  $category_index{6}{color} = '#ff00cc';
  $category_index{7}{color} = '#aaaa00';
  $category_index{8}{color} = '#00ffcc';
  $category_index{9}{color} = '#000000';
  return \%category_index;
}

sub displayPaperAuthorMatchesByPerson {
  my ($curator_id, $two_id, $lastnames_arrayref, $all_names_hashref) = @_;
  my %all_names = %$all_names_hashref;

  my $category_index_hashref = &populateCategoryIndex();
  my %category_index = %$category_index_hashref;

  print "Color index : ";
  foreach my $cat (sort {$a<=>$b} keys %category_index) {
    my $color = $category_index{$cat}{color};
    my $desc = $category_index{$cat}{desc};
    print "<span style=\"color: $color\">$desc</span> "; }
  print "</br><br/><br/>\n";

my $start = time;

  foreach my $lastname (@$lastnames_arrayref) {
    print "$lastname matches :<br />\n";
    my %category;
    my %aid_names;
    $result = $dbh->prepare( "SELECT * FROM pap_author_index WHERE pap_author_index ~ '^$lastname ' OR pap_author_index ~ ' ${lastname}\$' OR pap_author_index ~ '^${lastname},';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      if ($row[1] =~ m/,/) { $row[1] =~ s/,//g; }
      $aid_names{$row[0]} = $row[1]; }
    my (@aids) = sort keys %aid_names; my $author_ids = join"', '", @aids;
    my %paper;
#     $result = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_author IN ('$author_ids') AND joinkey NOT IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'non_nematode') ;" );		# papers must be in list of matching author names and not non_nematode flag
    $result = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_author IN ('$author_ids') AND joinkey IN (SELECT joinkey FROM pap_curation_flags WHERE pap_curation_flags = 'author_person') ;" );	# papers must be in list of matching author names and author_person flag	Kimberly / Cecilia 2014 01 21
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $paper{pap_aid}{$row[0]}{$row[1]}++; $paper{aid_pap}{$row[1]}{$row[0]}++; }

    my %possible; my %verified;
    $result = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id IN ('$author_ids');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $possible{$row[0]}{$row[2]} = $row[1]; }
    $result = $dbh->prepare( "SELECT * FROM pap_author_verified WHERE author_id IN ('$author_ids');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $verified{$row[0]}{$row[2]} = $row[1]; }

    foreach my $aid (keys %aid_names) {
      my $cat = 9;
      if ($possible{$aid}) {								# connected to someone
          foreach my $join (keys %{ $possible{$aid} }) {				
            my $possible = $possible{$aid}{$join};
            if ($verified{$aid}{$join}) {
                my $verified = $verified{$aid}{$join};
                if ($possible eq $two_id) {						# connected to this person
                    if ($verified =~ m/^YES/) {						# verified yes
                        if ($verified =~ m/Cecilia/) { $cat = 1; }			# by Cecilia
                        elsif ($verified =~ m/Raymond/) { if ($cat > 2) { $cat = 2; } }	# by Raymond
                        else { if ($cat > 3) { $cat = 3; } } }				# by someone else
                      elsif ($verified =~ m/^NO/) { if ($cat > 4) { $cat = 4; } } }	# verified no
                  else {								# connected to someone else
                    if ($verified =~ m/^YES/) { if ($cat > 5) { $cat = 5; } } } }	# verified yes by someone else
              else {									# not verified
                if ($possible eq $two_id) { if ($cat > 6) { $cat = 6; } }		# connected to this person
                  else { if ($cat > 7) { $cat = 7; } } } } }				# connected to other person
        else {										# not connected to anyone
          my $match_name = $aid_names{$aid};
          if ($match_name =~ m/,/) { $match_name =~ s/,//g; }                           # filter out commas for exact matches
          if ($match_name =~ m/\s+/) { $match_name =~ s/\s+/ /g; }                      # filter out extra spaces for exact matches
          if ($all_names{$match_name}) { if ($cat > 8) { $cat = 8; } } }		# if exact aka/name match to author name
      if ($cat < 5) { $category{done}{$aid} = $cat; }				# store into %category depending on category
        elsif ($cat > 5) { $category{not_done}{$aid} = $cat; }
        else { $category{ignore}{$aid} = $cat; }
    } # foreach my $aid (keys %aid_names)

    foreach my $type ('not_done', 'done') {
      print "<table style=\"border-style: none;\" border=\"1\" >";
      my $cell_data = ''; my @paper_aid_in_group;
      my %paps; my $count = 0; my $start = 1;
      foreach my $aid (keys %{ $category{$type} }) {
        foreach my $paper (keys %{ $paper{aid_pap}{$aid} }) { $paps{$paper}++; } }
      foreach my $joinkey (sort keys %paps) {
        foreach my $aid (keys %{ $paper{pap_aid}{$joinkey} }) {
          if ($category{$type}{$aid}) {
            $count++;
            my $color = $category_index{$category{$type}{$aid}}{color};
            my $pap_link = "paper_editor.cgi?curator_id=$curator_id&action=Search&data_number=$joinkey";
            $cell_data .= "<a style=\"color: $color; text-decoration: none\" href=\"$pap_link\">$joinkey ( $aid $aid_names{$aid} )</a><br />\n";
            push @paper_aid_in_group, "$joinkey, $aid, $category{$type}{$aid}";
#             $cell_data .= "<span style=\"color: $color\">J $joinkey A $aid C $category{$type}{$aid} E</span><br />\n";
            if ($count % 10 == 0) { 							# divisible by 10, make a new set
              &formTrPaperAuthorMatchesByPerson($curator_id, $two_id, \@paper_aid_in_group, $start, $count, $cell_data);
              $start = $count + 1; $cell_data = ''; @paper_aid_in_group = (); } } } }
      if ($cell_data) { &formTrPaperAuthorMatchesByPerson($curator_id, $two_id, \@paper_aid_in_group, $start, $count, $cell_data); }	# still stuff to print, print it out
      print "</table>";
    } # foreach my $type ('not_done', 'done')

#     foreach my $joinkey (sort keys %{ $paper{pap_aid} }) {
#       foreach my $aid (sort keys %{ $paper{pap_aid}{$joinkey} }) {
#         my $color = $category_index{$category{$aid}}{color};
#         print "<span style=\"color: $color\">J $joinkey A $aid C $category{$aid} E</span><br />\n";
#       } # foreach my $aid (sort keys %{ $paper{pap_aid}{$joinkey} })
#     } # foreach my $joinkey (sort keys %{ $paper{pap_aid} })

  } # foreach my $lastname (@$lastnames_arrayref)

  foreach my $all_name (sort keys %all_names) {
    print "Exact name match to $all_name<br />\n";
  } # foreach my $all_name (sort keys %all_names)

my $end = time;
my $diff = $end - $start;
print "$diff seconds<br/>\n";
} # sub displayPaperAuthorMatchesByPerson

sub formTrPaperAuthorMatchesByPerson {		# make a tr and form for a set of paper author matches by person
  my ($curator_id, $two_id, $paper_aid_in_group_arrayref, $start, $count, $cell_data) = @_;
  my $paper_aid_in_group = join"\t", @$paper_aid_in_group_arrayref;
  print "<form name='form1' method=\"get\" action=\"paper_editor.cgi\">\n";
  print "<input type=\"hidden\" name=\"paper_aid_in_group\" value=\"$paper_aid_in_group\">";
  print "<input type=\"hidden\" name=\"two_id\" value=\"$two_id\">";
  print "<input type=\"hidden\" name=\"curator_id\" value=\"$curator_id\">";
  print "<tr><td class=\"normal_odd\">$start to $count</td><td class=\"normal_odd\">$cell_data</td><td class=\"normal_odd\"><input type=\"submit\" name=\"action\" value=\"Paper Author Person Group\"></td></tr>\n";
  print "</form>\n";
} # sub formTrPaperAuthorMatchesByPerson

sub displayPersonInfo {
  my ($two_id) = @_;
  my %hash; my %all_lastnames; my %all_names;
  my @show_tables = qw( institution firstname middlename lastname aka_firstname aka_middlename aka_lastname );
  my %shown; foreach (@show_tables) { $shown{$_}++; }
  my @tables = qw( firstname middlename lastname street city state post country institution mainphone labphone officephone otherphone fax email old_email lab oldlab pis left_field unable_to_contact privacy aka_firstname aka_middlename aka_lastname webpage );
  my @simple_tables = qw( comment );
  foreach my $table (@tables) {
    $result = $dbh->prepare( "SELECT * FROM two_$table WHERE joinkey = '$two_id';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      $hash{$table}{$row[1]} = $row[2]; } }
  foreach my $table (@simple_tables) {
    $result = $dbh->prepare( "SELECT * FROM two_$table WHERE joinkey = '$two_id';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      $hash{$table}{1} = $row[2]; } }
  print "<table style=\"border-style: none;\" border=\"1\" >";
  print "<tr><td class=\"normal_even\" colspan=\"4\">$two_id</td></tr>\n";
  foreach my $order (sort {$a<=>$b} keys %{ $hash{institution} }) {
    print "<tr><td class=\"normal_even\" colspan=\"1\">institution</td><td class=\"normal_even\" colspan=\"3\">$hash{institution}{$order}</td></tr>\n"; }
#   print "<tr><td class=\"normal_even\">first</td><td class=\"normal_even\">middle</td><td class=\"normal_even\">last</td>\n";
  foreach my $order (sort {$a<=>$b} keys %{ $hash{lastname} }) {
    my ($first, $middle, $last) = ('', '', '');
    if ($hash{firstname}{$order}) { $first = $hash{firstname}{$order}; }
    if ($hash{middlename}{$order}) { $middle = $hash{middlename}{$order}; }
    if ($hash{lastname}{$order}) { $last = $hash{lastname}{$order}; $all_lastnames{$last}++; }
    my $name = "$first $last"; $all_names{$name}++;
    $name = "$last $first"; $all_names{$name}++;
    if ($middle) {
      $name = "$last $first $middle"; $all_names{$name}++;
      $name = "$first $middle $last"; $all_names{$name}++; }
    print "<tr><td class=\"normal_even\">name</td><td class=\"normal_even\">$first</td><td class=\"normal_even\">$middle</td><td class=\"normal_even\">$last</td></tr>\n"; }
  foreach my $order (sort {$a<=>$b} keys %{ $hash{aka_lastname} }) {
    my ($first, $middle, $last) = ('', '', '');
    if ($hash{aka_firstname}{$order}) { $first = $hash{aka_firstname}{$order}; }
    if ($hash{aka_middlename}{$order}) { $middle = $hash{aka_middlename}{$order}; if ($middle eq 'NULL') { $middle = ''; } }
    if ($hash{aka_lastname}{$order}) { $last = $hash{aka_lastname}{$order}; $all_lastnames{$last}++; }
    my $name = "$first $last"; $all_names{$name}++;
    $name = "$last $first"; $all_names{$name}++;
    if ($middle) {
      $name = "$last $first $middle"; $all_names{$name}++;
      $name = "$first $middle $last"; $all_names{$name}++; }
    print "<tr><td class=\"normal_even\">aka</td><td class=\"normal_even\">$first</td><td class=\"normal_even\">$middle</td><td class=\"normal_even\">$last</td></tr>\n"; }
  print "</table>";
  print "<table id=\"table_secondary_data\" style=\"border-style: none; display: none\" border=\"1\" onclick=\"document.getElementById('link_show').style.display = ''; document.getElementById('table_secondary_data').style.display = 'none';\" >";
  foreach my $table (@tables) {
    next if ($shown{$table});
    foreach my $order (sort {$a<=>$b} keys %{ $hash{$table} }) {
      if ($hash{$table}{$order}) {
        my $data = $hash{$table}{$order}; 
        print "<tr><td class=\"normal_even\">$table</td><td class=\"normal_even\">$data</td></tr>\n"; } } }
  print "</table>";
  print "<a href=\"#\" id=\"link_show\" onclick=\"document.getElementById('link_show').style.display = 'none'; document.getElementById('table_secondary_data').style.display = ''; return false\">show</a>"; 
  print "<br /><br />\n";
  my (@lastnames) = sort keys %all_lastnames;
  return (\@lastnames, \%all_names);
} # sub displayPersonInfo




# not used anywhere  2023 03 21
# sub getFirstPassTables {
#   my $tables = get "http://tazendra.caltech.edu/~postgres/cgi-bin/curator_first_pass.cgi?action=ListPgTables";
#   my (@fptables) = $tables =~ m/PGTABLE : (.*)<br/g;
#   return \@fptables; }


sub findDeadGenes {	# for Kimberly to find dead genes and update them in the paper editor.  will need to update to point to paper_editor later.  2010 04 09
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"findDeadGenes\">";
  (my $oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  print "Genes in pap_gene table that are also in gin_dead.  Also genes in pap_gene_comp table that are also in gic_dead.<br/>\n";
  print "<table border=1>";
  print "<tr><td>WBPaperID</td><td>WBGene</td><td>Evidence</td><td>Dead status</td></tr>\n";
  $result = $dbh->prepare( "SELECT gin_dead.gin_dead, pap_gene.joinkey, pap_gene.pap_gene, pap_gene.pap_evidence, pap_gene.pap_curator FROM pap_gene, gin_dead WHERE pap_gene.pap_gene = gin_dead.joinkey ORDER BY pap_gene.pap_gene, pap_gene.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
#     print "<tr><td><a href=\"http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_editor.cgi?curator_name=$curator_id&number=$row[1]&action=Number+!\" target=\"new\">$row[1]</a></td><td>$row[2]</td><td>$row[3]</td><td>$row[0]</td></tr>\n";
    print "<tr><td><a href=\"paper_editor.cgi?curator_id=$curator_id&data_number=$row[1]&action=Search\" target=\"new\">$row[1]</a></td><td>$row[2]</td><td>$row[3]</td><td>$row[0]</td></tr>\n";
  } # while (my @row = $result->fetchrow)

  $result = $dbh->prepare( "SELECT gic_dead.gic_dead, pap_gene_comp.joinkey, pap_gene_comp.pap_gene_comp, pap_gene_comp.pap_evidence, pap_gene_comp.pap_curator FROM pap_gene_comp, gic_dead WHERE pap_gene_comp.pap_gene_comp = gic_dead.joinkey ORDER BY pap_gene_comp.pap_gene_comp, pap_gene_comp.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
#     print "<tr><td><a href=\"http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_editor.cgi?curator_name=$curator_id&number=$row[1]&action=Number+!\" target=\"new\">$row[1]</a></td><td>$row[2]</td><td>$row[3]</td><td>$row[0]</td></tr>\n";
    print "<tr><td><a href=\"paper_editor.cgi?curator_id=$curator_id&data_number=$row[1]&action=Search\" target=\"new\">$row[1]</a></td><td>$row[2]</td><td>$row[3]</td><td>$row[0]</td></tr>\n";
  } # while (my @row = $result->fetchrow)

  print "</table>";
  &printFooter();
} # sub findDeadGenes

sub enterPmids {	# OBSOLETE when Biblio SoT to ABC  2023 04 17
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"enterPmids\">";
  (my $oop, my $curator_id) = &getHtmlVar($query, 'curator_id');		# some tables assign the curator, most will be overridden by two10877 for pubmed
  ($oop, my $wormbaseVsParasite) = &getHtmlVar($query, 'wormbaseVsParasite');

  # my $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads';
  my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/pmid_downloads';
  if ($wormbaseVsParasite eq 'parasite') { 
    $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_parasite_downloads';
    $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/pmid_parasite_downloads'; }

  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  my $functional_flag = ''; my $primary_flag = ''; my $aut_per_priority = '';
  ($oop, $functional_flag) = &getHtmlVar($query, 'functional_flag');
  ($oop, $primary_flag) = &getHtmlVar($query, 'primary_flag');
  ($oop, $aut_per_priority) = &getHtmlVar($query, 'author_person_priority_flag');
  my @speciesTaxons;
  for my $j (1 .. 10) { 
    ($oop, my $speciesTaxon) = &getHtmlVar($query, "species_0_${j}");		
#     my ($taxon) = $species =~ m/(\d+)$/; if ($taxon) { push @taxons, $taxon; } 
    if ($speciesTaxon) { push @speciesTaxons, $speciesTaxon; } 
  }
  my $speciesTaxons = join"|", @speciesTaxons;

  ($oop, my $pmids) = &getHtmlVar($query, 'pmids');
  my (@pmids) = $pmids =~ m/(\d+)/g;
  my @pairs; 
  foreach my $pmid (@pmids) { 
    push @pairs, "$pmid, $primary_flag, $aut_per_priority, $speciesTaxons"; }
  my $list = join"\t", @pairs;

  my ($link_text) = &processXmlIds($curator_id, $functional_flag, $list, $directory);
  $link_text =~ s/\n/<br \/>\n/g;
  print "<br/>$link_text<br/>\n";
  $list =~ s/\t/<br \/>/g;
  print "Processed $curator_id $functional_flag<br/>$list.<br/>\n";
  &printFooter();
} # sub enterPmids

sub confirmAbstracts {	# OBSOLETE when Biblio SoT to ABC  2023 04 17
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"confirmAbstracts\">";
  my ($oop, $wormbaseVsParasite) = &getHtmlVar($query, 'wormbaseVsParasite');

  # my $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads';
  my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/pmid_downloads';
  if ($wormbaseVsParasite eq 'parasite') { 
    $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_parasite_downloads';
    $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/pmid_parasite_downloads'; }
  my $rejected_file = $directory . '/rejected_pmids';
  my $removed_file  = $directory . '/removed_pmids';
  
  ($oop, my $count) = &getHtmlVar($query, 'count');
  my @process_list;
  my @move_queue;
  for my $i (0 .. $count - 1) {
    ($oop, my $choice) = &getHtmlVar($query, "approve_reject_$i");
    unless ($choice) { $choice = 'ignore'; }
    ($oop, my $pmid) = &getHtmlVar($query, "pmid_$i");
    print "$pmid $choice<BR>\n";
    if ($choice eq 'reject') {
# UNCOMMENT THESE
        open (OUT, ">>$rejected_file") or die "Cannot append to $rejected_file : $!";
        print OUT "$pmid\n";
        close (OUT) or die "Cannot close $rejected_file : $!";
# print "REJECT<br />\n";
# print "mv ${directory}/xml/$pmid ${directory}/done/<br/>"; 
        `mv -f ${directory}/xml/$pmid ${directory}/done/`; 
      }
      elsif ($choice eq 'remove') {
        open (OUT, ">>$removed_file") or die "Cannot append to $removed_file : $!";
        print OUT "$pmid\n";
        close (OUT) or die "Cannot close $removed_file : $!";
        `mv -f ${directory}/xml/$pmid ${directory}/done/`; 
      }
      elsif ($choice eq 'approve') {
        my $primary_flag     = ""; ($oop, $primary_flag)     = &getHtmlVar($query, "primary_$i");		
        my $aut_per_priority = ""; ($oop, $aut_per_priority) = &getHtmlVar($query, "author_person_priority_$i");		
        my @speciesTaxons;
        for my $j (1 .. 10) { 
          ($oop, my $speciesTaxon) = &getHtmlVar($query, "species_${i}_${j}");		
#           my ($taxon) = $species =~ m/(\d+)$/; if ($taxon) { push @taxons, $taxon; } 
          if ($speciesTaxon) { push @speciesTaxons, $speciesTaxon; } }
        my $speciesTaxons = join"|", @speciesTaxons;
        push @process_list, "$pmid, $primary_flag, $aut_per_priority, $speciesTaxons";
#         my ($link_text) = &processLocal($pmid, $curators{std}{$theHash{curator}}, '');
# no longer move here, approved stuff gets into @process_list and moved by processXmlIds
#         my $move = "mv -f ${directory}/xml/$pmid ${directory}/done/"; 	# need to force move in ubuntu
#         push @move_queue, $move;
      } }
  my $list = join"\t", @process_list;
# print "LIST $list L<br />\n";
  if ($list) {
    ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');		# some tables assign the curator, most will be overridden by two10877 for pubmed
    my $functional_flag = '';
#     &processStuff($list);
    my ($link_text) = &processXmlIds($curator_id, $functional_flag, $list, $directory);
    $link_text =~ s/\n/<br \/>\n/g;
    print "<br/>$link_text<br/>\n";
    $list =~ s/\t/<br \/>/g;
    print "Processed $curator_id $functional_flag<br/>$list.<br/>\n"; }
#   foreach my $move (@move_queue) { `$move`; }
# print "CREATED<br>\n";
  &printFooter();
} # sub confirmAbstracts

sub enterNewPapers {	# OBSOLETE when Biblio SoT to ABC  2023 04 17
  my ($wormbaseVsParasite) = @_;
  if ($wormbaseVsParasite eq 'page') { 
    ($oop, $wormbaseVsParasite) = &getHtmlVar($query, 'wormbaseVsParasite'); }
  &printHtmlHeader();
  print "<form name='form1' method=\"post\" action=\"paper_editor.cgi\">\n";
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"mergePage\">";
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  print "<input type=\"hidden\" name=\"curator_id\" id=\"curator_id\" value=\"$curator_id\">";
  print "You are $curator_id<br />\n";
  &showEnterPmidBox($curator_id);
  &showEnterNonpmidPaper($curator_id);
  &showConfirmXmlTable($curator_id, $wormbaseVsParasite);
  print "</form>\n";
  &printFooter();
}

sub enterNonPmids {
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"enterNonPmids\">";
  (my $oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  $result = $dbh->prepare( "SELECT joinkey FROM pap_status ORDER BY joinkey DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); my $joinkey = $row[0];
  $joinkey++;
  my $pgcommand = "INSERT INTO pap_status VALUES ('$joinkey', 'valid', NULL, '$curator_id');";
#   print "$pgcommand<br />\n";
  $result = $dbh->do( $pgcommand );
  $pgcommand = "INSERT INTO h_pap_status VALUES ('$joinkey', 'valid', NULL, '$curator_id');";
#   print "$pgcommand<br />\n";
  $result = $dbh->do( $pgcommand );
  my $url = "paper_editor.cgi?action=Search&data_number=$joinkey&curator_id=$curator_id";
  print "You have created : <a href=\"$url\">WBPaper$joinkey</a>.  This page will now redirect to $url\n";
  print "<input type=\"hidden\" name=\"redirect_to\" id=\"redirect_to\" value=\"$url\">";
#   if ($joinkey =~ m/(\d+)/) { &displayNumber(&padZeros($1), $curator_id); return; }	# do not display editor, any reload would create another new joinkey
  &printFooter();
} # sub enterNonPmids

sub showEnterNonpmidPaper {
  print "<hr>\n";
  my ($curator_id) = @_;
  print "<input type=submit name=action value=\"Enter non-PMID paper\">\n";
} # sub showEnterNonpmidPaper

sub showConfirmXmlTable {
  print "<hr>\n";
  my ($curator_id, $wormbaseVsParasite) = @_;
  ($oop, my $page) = &getHtmlVar($query, 'page');
  ($oop, my $perpage) = &getHtmlVar($query, 'perpage');
  unless ($page) { $page = 1; }
  unless ($perpage) { $perpage = 20; }
  
  # my $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads';
  my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/pmid_downloads';
  if ($wormbaseVsParasite eq 'parasite') { 
    $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_parasite_downloads';
    $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers/pmid_parasite_downloads'; }
  # my $rejected_file = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/rejected_pmids';
  my $rejected_file = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/work/pgpopulation/pap_papers/pmid_downloads/rejected_pmids';
  my @read_pmids = <$directory/xml/*>;
  foreach (@read_pmids) { $_ =~ s|$directory/xml/||g; }
  my @sorted_pmids = reverse sort {$a<=>$b} @read_pmids;
  my $totalCount = scalar @sorted_pmids;
  my $pageCount  = ceil($totalCount/$perpage);
  print qq(There are $totalCount PMIDs in $pageCount pages<br/>);
  print qq(<select name="page">);
  for my $i (1 .. $pageCount) { 
    my $selected = ''; if ($page == $i) { $selected = 'selected' } else { $selected = ''; }
    print qq(<option $selected>$i</option>); }
  print qq(</select>);
  print qq(<input type=submit name=action value="Page">\n);
  print qq(Entries per page <input name=perpage value="$perpage"><br/>\n);
  print qq(<input type=submit name=action value="Confirm Abstracts">\n);
  print qq(<input type="hidden" name="wormbaseVsParasite" value="$wormbaseVsParasite">\n);
  print "<table border=1>\n";
#   print "<tr><td>pmid</td><td>title</td><td>authors</td><td>abstract</td><td>type</td><td>journal</td><td>Approve</td><td>primary</td></tr>\n";
  print qq(<tr><td>pmid</td><td>title</td><td>authors</td><td>abstract</td><td>type</td><td>journal</td><td width="300">Species</td><td>Flags</td></tr>\n);
  my $count = 1;	# use count zero for pmid species, but include zero for total count for javascript
  for (2 .. $page) { for (1 .. $perpage) { shift @sorted_pmids; } }
  foreach my $infilename (@sorted_pmids) {
    my $infile = $directory . '/xml/' . $infilename;
    $/ = undef;
    open (IN, "<$infile") or die "Cannot open $infile : $!";
    my $file = <IN>;
    close (IN) or die "Cannot open $infile : $!";
    my ($abstract) = $file =~ /\<AbstractText\>(.+?)\<\/AbstractText\>/i;
    unless ($abstract) {                          # if there is no abstract match, try to get label and concatenate multiple matches.
      my @abstracts = $file =~ /\<AbstractText(.+?)\<\/AbstractText\>/gi;
      foreach my $ab (@abstracts) {
        if ($ab =~ m/Label=\"(.*?)\"/i) { $abstract .= "${1}: "; }
        if ($ab =~ m/^.*\>/) { $ab =~ s/^.*\>//; } $abstract .= "$ab "; }
      if ($abstract) { if ($abstract =~ m/ +$/) { $abstract =~ s/ +$//; } } }
    my ($type) = $file =~ /\<PublicationType\>(.+?)\<\/PublicationType\>/i;
    unless ($type) { 
      ($type) = $file =~ /\<PublicationType UI=\".*?\"\>(.+?)\<\/PublicationType\>/i; }
    my ($journal) = $file =~ /\<MedlineTA\>(.+?)\<\/MedlineTA\>/i;	# show Journal to reject 
    my ($title) = $file =~ /\<ArticleTitle\>(.+?)\<\/ArticleTitle\>/i;	# show article Title to reject 
    my @authors = $file =~ /\<Author.*?\>(.+?)\<\/Author\>/isg;
    my $authors = "";
    foreach (@authors){
      my ($lastname, $initials) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>.+\<Initials\>(.+?)\<\/Initials\>/is;
      $authors .= $lastname . " " . $initials . ', '; }
    $authors =~ s/\W+$//;
    my ($pmid) = $infile =~ m/(\d+)$/;
    my ($doi) = $file =~ /\<ArticleId IdType=\"doi\"\>(.+?)\<\/ArticleId\>/i;
    my $input_buttons = "<td>approve_reject<br/><select size=1 name=approve_reject_$count><option></option><option>approve</option><option>reject</option><option>remove</option></select>";
    $input_buttons .= "<br /><br />primary<br/><select size=1 name=primary_$count><option></option><option selected=\"selected\" value=\"primary\">primary</option><option value=\"not_primary\">not_primary</option><option value=\"not_designated\">not_designated</option></select>\n";
    $input_buttons .= "<br /><br />aut-per_priority<br/><select size=1 name=author_person_priority_$count><option selected=\"selected\" value=\"author_person\">priority</option><option value=\"\">not_priority</option></select></td>\n";
    if ($journal eq 'Genetics') { 
        print "<TR bgcolor='$red'>\n"; 					# show Genetics papers in red	2009 07 21
        if ($doi) { $journal .= "<br />$doi"; } 			# show DOI			2009 07 23
          else { $input_buttons = "<td>&nbsp;</td><td><input type=checkbox name=\"primary_$count\" checked=\"checked\" value=\"primary\"></td><td>&nbsp;</td>"; } } # don't show approve / reject	2009 07 23
      else { print "<TR>\n"; }
    unless ($abstract) { $abstract = ''; }
    unless ($title) { $title = ''; }
    print "<td>$pmid</td><td>$title</td><td>$authors</td><td>$abstract</td>";
    print "<td>$type</td>";
    print "<td>$journal</td>";
#     print "<td>"; for my $j (1 .. 10) { &printSpeciesDropdown($count, $j); } print "</td>";
    &printSpeciesAutocompleteField($count);
#     print "<td>species stub</td>";
    print "<input type=hidden name=pmid_$count value=$pmid>\n";
    print "$input_buttons\n";
    print "</tr>\n";
    $count++;
    last if ($count >= $perpage);
  } # foreach my $infile (@sorted_pmids)
  print "</table>\n";
  print "<input type=hidden name=count id=papersCount value=$count>\n";
  print "<input type=submit name=action value=\"Confirm Abstracts\">\n";
} # sub showConfirmXmlTable


sub printSpeciesDropdown {
  my ($i, $j) = @_;
  my %speciesParaShort;
  $speciesParaShort{"Acanthocheilonema viteae"} = "6277";
  $speciesParaShort{"Ancylostoma caninum"} = "29170";
  $speciesParaShort{"Ancylostoma ceylanicum"} = "53326";
  $speciesParaShort{"Ancylostoma duodenale"} = "51022";
  $speciesParaShort{"Angiostrongylus cantonensis"} = "6313";
  $speciesParaShort{"Angiostrongylus costaricensis"} = "334426";
  $speciesParaShort{"Anisakis simplex"} = "6269";
  $speciesParaShort{"Ascaris lumbricoides"} = "6252";
  $speciesParaShort{"Ascaris suum"} = "6253";
  $speciesParaShort{"Brugia malayi"} = "6279";
  $speciesParaShort{"Brugia pahangi"} = "6280";
  $speciesParaShort{"Brugia timori"} = "42155";
  $speciesParaShort{"Bursaphelenchus xylophilus"} = "6326";
  $speciesParaShort{"Caenorhabditis angaria"} = "860376";
  $speciesParaShort{"Caenorhabditis brenneri"} = "135651";
  $speciesParaShort{"Caenorhabditis briggsae"} = "6238";
  $speciesParaShort{"Caenorhabditis elegans"} = "6239";
  $speciesParaShort{"Caenorhabditis japonica"} = "281687";
  $speciesParaShort{"Caenorhabditis remanei"} = "31234";
  $speciesParaShort{"Caenorhabditis sinica"} = "1550068";
  $speciesParaShort{"Caenorhabditis tropicalis"} = "1561998";
  $speciesParaShort{"Cylicostephanus goldi"} = "71465";
  $speciesParaShort{"Dictyocaulus viviparus"} = "29172";
  $speciesParaShort{"Dirofilaria immitis"} = "6287";
  $speciesParaShort{"Dracunculus medinensis"} = "318479";
  $speciesParaShort{"Elaeophora elaphi"} = "1147741";
  $speciesParaShort{"Enterobius vermicularis"} = "51028";
  $speciesParaShort{"Globodera pallida"} = "36090";
  $speciesParaShort{"Gongylonema pulchrum"} = "637853";
  $speciesParaShort{"Haemonchus contortus"} = "6289";
  $speciesParaShort{"Haemonchus placei"} = "6290";
  $speciesParaShort{"Heligmosomoides polygyrus"} = "375939";
  $speciesParaShort{"Heterorhabditis bacteriophora"} = "37862";
  $speciesParaShort{"Litomosoides sigmodontis"} = "42156";
  $speciesParaShort{"Loa loa"} = "7209";
  $speciesParaShort{"Meloidogyne floridensis"} = "298350";
  $speciesParaShort{"Meloidogyne hapla"} = "6305";
  $speciesParaShort{"Meloidogyne incognita"} = "6306";
  $speciesParaShort{"Necator americanus"} = "51031";
  $speciesParaShort{"Nippostrongylus brasiliensis"} = "27835";
  $speciesParaShort{"Oesophagostomum dentatum"} = "61180";
  $speciesParaShort{"Onchocerca flexuosa"} = "387005";
  $speciesParaShort{"Onchocerca ochengi"} = "42157";
  $speciesParaShort{"Onchocerca volvulus"} = "6282";
  $speciesParaShort{"Panagrellus redivivus"} = "6233";
  $speciesParaShort{"Parascaris equorum"} = "6256";
  $speciesParaShort{"Parastrongyloides trichosuri"} = "131310";
  $speciesParaShort{"Pristionchus exspectatus"} = "1195656";
  $speciesParaShort{"Pristionchus pacificus"} = "54126";
  $speciesParaShort{"Rhabditophanes sp. KR3021"} = "114890";
  $speciesParaShort{"Romanomermis culicivorax"} = "13658";
  $speciesParaShort{"Soboliphyme baturini"} = "241478";
  $speciesParaShort{"Steinernema carpocapsae"} = "34508";
  $speciesParaShort{"Steinernema feltiae"} = "52066";
  $speciesParaShort{"Steinernema glaseri"} = "37863";
  $speciesParaShort{"Steinernema monticolum"} = "90984";
  $speciesParaShort{"Steinernema scapterisci"} = "90986";
  $speciesParaShort{"Strongyloides papillosus"} = "174720";
  $speciesParaShort{"Strongyloides ratti"} = "34506";
  $speciesParaShort{"Strongyloides stercoralis"} = "6248";
  $speciesParaShort{"Strongyloides venezuelensis"} = "75913";
  $speciesParaShort{"Strongylus vulgaris"} = "40348";
  $speciesParaShort{"Syphacia muris"} = "451379";
  $speciesParaShort{"Teladorsagia circumcincta"} = "45464";
  $speciesParaShort{"Thelazia callipaeda"} = "103827";
  $speciesParaShort{"Toxocara canis"} = "6265";
  $speciesParaShort{"Trichinella nativa"} = "6335";
  $speciesParaShort{"Trichinella spiralis"} = "6334";
  $speciesParaShort{"Trichuris muris"} = "70415";
  $speciesParaShort{"Trichuris suis"} = "68888";
  $speciesParaShort{"Trichuris trichiura"} = "36087";
  $speciesParaShort{"Wuchereria bancrofti"} = "6293";
  $speciesParaShort{"Clonorchis sinensis"} = "79923";
  $speciesParaShort{"Diphyllobothrium latum"} = "60516";
  $speciesParaShort{"Echinococcus canadensis"} = "519352";
  $speciesParaShort{"Echinococcus granulosus"} = "6210";
  $speciesParaShort{"Echinococcus multilocularis"} = "6211";
  $speciesParaShort{"Echinostoma caproni"} = "27848";
  $speciesParaShort{"Fasciola hepatica"} = "6192";
  $speciesParaShort{"Hydatigera taeniaeformis"} = "6205";
  $speciesParaShort{"Hymenolepis diminuta"} = "6216";
  $speciesParaShort{"Hymenolepis microstoma"} = "85433";
  $speciesParaShort{"Hymenolepis nana"} = "102285";
  $speciesParaShort{"Mesocestoides corti"} = "53468";
  $speciesParaShort{"Opisthorchis viverrini"} = "6198";
  $speciesParaShort{"Protopolystoma xenopodis"} = "117903";
  $speciesParaShort{"Schistocephalus solidus"} = "70667";
  $speciesParaShort{"Schistosoma curassoni"} = "6186";
  $speciesParaShort{"Schistosoma haematobium"} = "6185";
  $speciesParaShort{"Schistosoma japonicum"} = "6182";
  $speciesParaShort{"Schistosoma mansoni"} = "6183";
  $speciesParaShort{"Schistosoma margrebowiei"} = "48269";
  $speciesParaShort{"Schistosoma mattheei"} = "31246";
  $speciesParaShort{"Schistosoma rodhaini"} = "6188";
  $speciesParaShort{"Schmidtea mediterranea"} = "79327";
  $speciesParaShort{"Spirometra erinaceieuropaei"} = "99802";
  $speciesParaShort{"Taenia asiatica"} = "60517";
  $speciesParaShort{"Taenia solium"} = "6204";
  $speciesParaShort{"Trichobilharzia regenti"} = "157069";
  print qq(<select name="species_${i}_${j}" id="species_${i}_${j}"><option></option>);
  foreach my $species (sort keys %speciesParaShort) { 
    my $taxon = $speciesParaShort{$species};
    print qq(<option value="$taxon">$species</option>);
  } 
  print qq(</select>);
} # sub printSpeciesDropdown

sub printSpeciesAutocompleteField {
  my ($count) = (@_);
  print qq(<td id="td_AutoComplete_species">);
  for my $order (1 .. 10) { 
    my $display = 'none'; if ($order < 2) { $display = ''; }
    my $input_id = 'species_' . $count . '_' . $order;
    print qq(<div id="div_AutoComplete_$input_id" class="div-autocomplete" style="display: $display; width: 98%;">
    <input size="100" id="$input_id" name="$input_id" style="width: 98%">
    <div id="div_Container_$input_id" width="98%"></div></div>);
  }
  print qq(</td>);
} # sub printSpeciesAutocompleteField

sub showEnterPmidBox {
  print "<hr>\n";
  my ($curator_id) = @_;
  print "<table border=0 cellspacing=2>\n";
  print "<tr><td>Enter the PMID numbers, one per line.  e.g. :<br/>\n";
  print "16061202<br />16055504<br />16055082<br />\n";
  print "<td><textarea name=\"pmids\" rows=6 cols=60 value=\"\"></textarea></td>\n";
  print "<td align=left><input name=\"functional_flag\" type=checkbox value=\"non_nematode\">non_nematode flag<br />\n";
  print "<select size=1 name=\"primary_flag\"><option value=\"primary\" selected=\"selected\">primary</option><option value=\"not_primary\">not_primary</option><option value=\"not_designated\">not_designated</option></select><br />\n";
  print "author-person : <select size=1 name=\"author_person_priority_flag\"><option value=\"author_person\" selected=\"selected\">priority</option><option value=\"\">not_priority</option></select><br />\n";
  print qq(<table><tr><td width="300">species :</td></tr>);
  print qq(<tr>); &printSpeciesAutocompleteField(0); print qq(</tr>);	# use count zero for pmids
  print qq(</table>);
  print "<input type=\"submit\" name=\"action\" value=\"Enter PMIDs\"></td></tr>\n";
  print "</table>\n";
} # sub showEnterPmidBox

sub deletePostgresTableField {                          # if updating postgres table values, update postgres and return OK if ok
  print "Content-type: text/html\n\n";
  my $uid = 'joinkey'; my $sorter = 'pap_order';
  ($oop, my $field) = &getHtmlVar($query, 'field');
  ($oop, my $joinkey) = &getHtmlVar($query, 'joinkey');
  ($oop, my $order) = &getHtmlVar($query, 'order');
  ($oop, my $curator) = &getHtmlVar($query, 'curator');
  my @pgcommands;
  if ($order) { 
      my $command = "DELETE FROM pap_$field WHERE $uid = '$joinkey' AND $sorter = '$order'";
      push @pgcommands, $command;
      $order = "'$order'"; }
    else { 
      my $command = "DELETE FROM pap_$field WHERE $uid = '$joinkey' AND $sorter IS NULL";
      push @pgcommands, $command;
      $order = 'NULL'; }
  my $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', NULL, $order, '$curator')";
  push @pgcommands, $command;
  foreach my $command (@pgcommands) {
#     print "$command<br />\n";
    $result = $dbh->do( $command );
  }
  print "OK";
}

sub movePdfsToMerged {
  my $joinkey = shift;
# TODO  when clicking here, also move the PDFs into some invalid_paper_pdf/ directory  2010 04 08
}

sub updatePostgresTableField {                          # if updating postgres table values, update postgres and return OK if ok
  print "Content-type: text/html\n\n";
  ($oop, my $field) = &getHtmlVar($query, 'field');
  ($oop, my $joinkey) = &getHtmlVar($query, 'joinkey');
  ($oop, my $order) = &getHtmlVar($query, 'order');
  ($oop, my $curator) = &getHtmlVar($query, 'curator');
  ($oop, my $newValue) = &getHtmlVar($query, 'newValue');
  ($oop, my $evi) = &getHtmlVar($query, 'evi');
  ($newValue) = &filterForPg($newValue);                  # replace ' with ''

  my $isOk = 'NO';

    # if identifier field is acquiring a WBPaperId (exactly 8 digits only), move the PDFs to some merged directory
  if ($field eq 'identifier') {	if ($newValue =~ m/^\d{8}$/) { &movePdfsToMerged($newValue); } }

  if ($field eq 'author_reorder') {	# author order data is special if re-ordering
      ($isOk) = &updatePostgresAuthorReorderField('author', $joinkey, $order, $curator, $newValue); }
    elsif ($field eq 'author_new')  {	# author field data is special	
      ($isOk) = &updatePostgresAuthorNewvalueField('author', $joinkey, $order, $curator, $newValue); }
    elsif ($field eq 'species') { 
      my $species = $newValue; my ($taxon) = $newValue =~ m/(\d+)$/;
      $species =~ s/ $taxon//g;
      my $curator_evidence = $curator; $curator_evidence =~ s/two/WBPerson/;		# store WBPerson in evidence
      ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $curator, $taxon, "Curator_confirmed\t\"$curator_evidence\"");
      $order++;
      ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $curator, $taxon, "Manually_connected\t\"$species\""); }
    elsif ( ($field eq 'gene') || ($field eq 'gene_comp') )  {		# gene data is special
      if ($evi) {
        ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $curator, $newValue, $evi); }
      elsif ($newValue =~ m/\(.*?\)/) {
        ($isOk) = &updatePostgresGeneBatchField($field, $joinkey, $order, $curator, $newValue); }
      else {
        ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $curator, ''); } }
    elsif ($field eq 'status')  {	# status can only delete whole paper
      ($isOk) = &deletePaper($joinkey, $curator); }
    elsif ($field eq 'author_possible')  {		# convert AutoComplete value to two#
      ($isOk) = &updatePostgresAuthorPossibleField($field, $joinkey, $order, $curator, $newValue); }
    elsif ($field eq 'author_index')  {			# if change, change author_index, if delete, remove all existence of author_id
      ($isOk) = &updatePostgresAuthorIndexField($field, $joinkey, $order, $curator, $newValue); }
    elsif ( ($field eq 'curation_flags') && ($newValue eq 'rnai_curation') && ($order eq 'new') ) {	# get order and only change if new flag
      ($isOk) = &updatePostgresRnaiCuration($field, $joinkey, $order, $curator, $newValue); }
    else {						# normal fields
      ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $curator, $newValue); }

  if ($isOk eq 'OK') { print "OK"; }
} # sub updatePostgresTableField

sub updatePostgresByTableJoinkeyNewvalue {
  my ($field, $joinkey, $order, $curator, $newValue, $evi) = @_;
# print "F $field J $joinkey O $order C $curator N $newValue E $evi E<br/>\n";
  my $uid = 'joinkey'; my $sorter = 'pap_order';
  if ($field =~ m/author_/) { $uid = 'author_id'; $sorter = 'pap_join'; }
  my @pgcommands;
  if ($order) { 
      my $command = "DELETE FROM pap_$field WHERE $uid = '$joinkey' AND $sorter = '$order'";
      push @pgcommands, $command;
      $order = "'$order'"; } 
    else { 
      my $command = "DELETE FROM pap_$field WHERE $uid = '$joinkey' AND $sorter IS NULL";
      push @pgcommands, $command;
      $order = 'NULL'; }

  if ($newValue) { $newValue = "'$newValue'"; }
    else { $newValue = 'NULL'; }

  my $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', $newValue, $order, '$curator', CURRENT_TIMESTAMP)";
  if ($evi) { 
    if ($evi eq 'merge') { $evi = 'NULL'; } else { $evi = "'$evi'"; $evi =~ s/ESCTAB/\t/g; }	# tabs don't get passed by html/javascript for some reason
    $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', $newValue, $order, '$curator', CURRENT_TIMESTAMP, $evi )"; }
  push @pgcommands, $command;

  if ($newValue ne 'NULL') {
    $command = "INSERT INTO pap_$field VALUES ('$joinkey', $newValue, $order, '$curator', CURRENT_TIMESTAMP)";
    if ($evi) { 
      $command = "INSERT INTO pap_$field VALUES ('$joinkey', $newValue, $order, '$curator', CURRENT_TIMESTAMP, $evi )"; }
    push @pgcommands, $command;  }

  foreach my $command (@pgcommands) {
#     print "$command<br />\n";
    $result = $dbh->do( $command );
  }

#   print "INSERT INTO pap_$field VALUES ('$joinkey', $order, '$curator', '$newValue')<br>" ;
#   my $result = $dbh->do( "INSERT INTO oa_test VALUES ('$joinkey', '$table', '$newValue')" );  # test entering in oa_test table

#   my $result = $dbh->do( "INSERT INTO ${table}_hst VALUES ('$joinkey', '$newValue')" );
#   $result = $dbh->do( "DELETE FROM $table WHERE joinkey = '$joinkey'" );
#   $result = $dbh->do( "INSERT INTO $table VALUES ('$joinkey', '$newValue')" );
  return "OK";
} # sub updatePostgresByTableJoinkeyNewvalue

sub deletePaper {				# to delete a paper by joinkey and curator
  my ($joinkey, $curator) = @_;
  my @pgcommands;
#   $result = $dbh->do( "INSERT INTO pap_status VALUES ('$joinkey', 'invalid', NULL, '$curator')" );
  my $command = "INSERT INTO pap_status VALUES ('$joinkey', 'invalid', NULL, '$curator')" ;
  push @pgcommands, $command;
  my %aids;					# author_ids to potentially delete if not associated with another paper
  foreach my $table (@normal_tables) {
    my $pg_table = 'pap_' . $table; 
    $result = $dbh->prepare( "SELECT * FROM $pg_table WHERE joinkey = '$joinkey' ORDER BY pap_order" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      next unless ($row[1]);				# skip blank entries
      my $new_value = 'NULL'; if ($table eq 'status') { $new_value = "'invalid'"; }
      my $order = 'NULL'; my $check_order = 'IS NULL';
      if ($multi{$table}) { $order = "'$row[2]'"; $check_order = "= '$row[2]'"; }
      $command = "INSERT INTO h_${pg_table} VALUES ('$joinkey', $new_value, $order, '$curator')";
      push @pgcommands, $command;
      $command = "DELETE FROM ${pg_table} WHERE joinkey = '$joinkey' AND pap_order $check_order";
      push @pgcommands, $command;
      if ($table eq 'author') { $aids{$row[1]}++; } } }

  foreach my $aid (sort {$a<=>$b} keys %aids) {		# for each author_id in pap_author, check that the author_id doesn't exist in another paper.  if it exists is another paper, remove from %aids, which will delete all pap_author_<stuff> entries for it
    $result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey != '$joinkey' AND pap_author = '$aid'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow(); 
    if ($row[0]) { delete $aids{$aid}; } }		# remove from %aids since it exists for another paper
 
  my @aut_tables = qw( author_index author_possible author_sent author_verified );
  foreach my $aid (sort {$a<=>$b} keys %aids) {		# delete from author subtables 
    foreach my $table (@aut_tables) {
      my $pg_table = 'pap_' . $table; 
      $result = $dbh->prepare( "SELECT * FROM $pg_table WHERE author_id = '$aid' ORDER BY pap_join" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
        next unless ($row[1]);				# skip blank entries
        my $join = 'NULL'; my $check_join = 'IS NULL';
        if ($multi{$table}) { $join = "'$row[2]'"; $check_join = "= '$row[2]'"; }
        $command = "INSERT INTO h_${pg_table} VALUES ('$aid', NULL, $join, '$curator')";
        push @pgcommands, $command;
        $command = "DELETE FROM ${pg_table} WHERE author_id = '$aid' AND pap_join $check_join";
        push @pgcommands, $command; } } }

  $command = "INSERT INTO pap_status VALUES ('$joinkey', 'invalid', NULL, '$curator')";
  push @pgcommands, $command;				# add an invalid status to the pap_status table

  foreach my $command (@pgcommands) {
#     print "$command<br />\n";
    $result = $dbh->do( $command );
  }
  return "OK";
} # sub deletePaper


sub updatePostgresRnaiCuration {
  my ($field, $joinkey, $order, $curator, $newValue) = @_;
  my $isOk = 'OK';
  my $result = $dbh->prepare( "SELECT * FROM pap_$field WHERE pap_$field = '$newValue' AND joinkey = '$joinkey';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); if ($row[1]) { return $isOk; }		# value already in, leave it alone
  if ($order eq 'new') {
    my $result = $dbh->prepare( "SELECT * FROM pap_$field WHERE pap_order IS NOT NULL AND joinkey = '$joinkey' ORDER BY pap_order DESC;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow(); $order = $row[2] + 1; }
  ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $joinkey, $order, $curator, $newValue);
  return $isOk;
} # sub updatePostgresRnaiCuration

sub updatePostgresGeneBatchField {		# batch genes, normal
  my ($field, $joinkey, $order, $curator, $newValue) = @_;
  my $curator_evidence = $curator; $curator_evidence =~ s/two/WBPerson/;		# store WBPerson in evidence
  my @pgcommands;				# commands for postgres
  my $published_as = '';
  if ($newValue =~ m/ Published_as (.*)$/) { $published_as = $1; }
  my @genes = split/, /, $newValue;		# split values by comma and space
  foreach my $genePair (@genes) {
#     my ($name, $wbgene) = $genePair =~ m/^(.*?) \(WBGene(\d+)\)/;	# get the matched name, and the wbgene's ID
    my ($name, $wbgene) = $genePair =~ m/^(.*?) \((.*?)\)/;	# get the matched name, and the wbgene's ID
    if ($wbgene =~ m/WBGene(\d+)/) { $wbgene = $1; }		# for wbgenes that are a WBGene\d+ only store the numbers part, for comparator genes store the whole thing
    my $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', '$wbgene', '$order', '$curator', CURRENT_TIMESTAMP, 'Curator_confirmed\t\"$curator_evidence\"')";
    push @pgcommands, $command;
    $command = "INSERT INTO pap_$field VALUES ('$joinkey', '$wbgene', '$order', '$curator', CURRENT_TIMESTAMP, 'Curator_confirmed\t\"$curator_evidence\"')";
    push @pgcommands, $command;
    $order++;					# different evidence, so update the order
    $command = "INSERT INTO pap_$field VALUES ('$joinkey', '$wbgene', '$order', '$curator', CURRENT_TIMESTAMP, 'Manually_connected\t\"$name\"')";
    push @pgcommands, $command;
    $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', '$wbgene', '$order', '$curator', CURRENT_TIMESTAMP, 'Manually_connected\t\"$name\"')";
    push @pgcommands, $command;
    $order++;					# multiple genes, so update the order
    if ($published_as) {			# has published_as evidence, make new entry
      $command = "INSERT INTO pap_$field VALUES ('$joinkey', '$wbgene', '$order', '$curator', CURRENT_TIMESTAMP, 'Published_as\t\"$published_as\"')";
      push @pgcommands, $command;
      $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', '$wbgene', '$order', '$curator', CURRENT_TIMESTAMP, 'Published_as\t\"$published_as\"')";
      push @pgcommands, $command;
      $order++; }				# additional entry for published_as
  }
  foreach my $command (@pgcommands) { $result = $dbh->do( $command ); }
  return 'OK';
}

sub updatePostgresAuthorIndexField {

  my ($field, $aid, $order, $curator, $newValue) = @_;
  my $isOk = 'OK';
  if ($newValue) { ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $aid, $order, $curator, $newValue); }
    else {			# there's no new value, it's a delete, remove author_id from pap_author and all subtables
      &updatePostgresByTableJoinkeyNewvalue($field, $aid, $order, $curator, '');
      my $result2 = $dbh->prepare( "SELECT * FROM pap_author WHERE pap_author = '$aid'" );
      $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row2 = $result2->fetchrow) {
        &updatePostgresByTableJoinkeyNewvalue('author', $row2[0], $row2[2], $curator, ''); }
      $result2 = $dbh->prepare( "SELECT * FROM pap_author_possible WHERE author_id = '$aid'" );
      $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row2 = $result2->fetchrow) {
        my $aid = $row2[0]; my $order = $row2[2];	# need to assign variables because @row2 would change before second updatePostgresByTableJoinkeyNewvalue  2011 04 48
        &updatePostgresByTableJoinkeyNewvalue('author_possible', $aid, $order, $curator, '');
        &updatePostgresByTableJoinkeyNewvalue('author_sent', $aid, $order, $curator, '');
        &updatePostgresByTableJoinkeyNewvalue('author_verified', $aid, $order, $curator, ''); }
    }
  return $isOk;
} # sub updatePostgresAuthorIndexField
sub updatePostgresAuthorPossibleField {
  my ($field, $aid, $order, $curator, $newValue) = @_;
  my $isOk = 'OK';
  if ( ($newValue eq '') && ($order =~ m/^\d+$/) ) {	# blank and has order, so blank it
      ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $aid, $order, $curator, $newValue); }
    elsif ($newValue =~ m/WBPerson(\d+)/) { 
      if ($order eq 'new') {
        my $result = $dbh->prepare( "SELECT pap_join FROM pap_author_possible WHERE pap_join IS NOT NULL AND author_id = '$aid' ORDER BY pap_join DESC;" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        my @row = $result->fetchrow(); $order = $row[0] + 1; }
      $newValue = 'two' . $1;		# convert to two#
      ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $aid, $order, $curator, $newValue); }
    elsif ($newValue =~ m/^two\d+$/) { 			# direct update of two# from connecting by paper person author group
      ($isOk) = &updatePostgresByTableJoinkeyNewvalue($field, $aid, $order, $curator, $newValue); }
    else { 1; } 			# no matching WBPerson value, don't do anything
  return $isOk;
} # sub updatePostgresAuthorPossibleField

sub updatePostgresAuthorNewvalueField {
  my ($field, $joinkey, $order, $curator, $newValue) = @_;
  my @pgcommands;
  my $result = $dbh->prepare( "SELECT pap_author FROM pap_author ORDER BY CAST (pap_author AS integer) DESC" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); my $highest_aid = $row[0];
  my $aid = $highest_aid + 1;
  my $command = "INSERT INTO h_pap_author VALUES ('$joinkey', '$aid', '$order', '$curator')";
  push @pgcommands, $command;
  $command = "INSERT INTO pap_author VALUES ('$joinkey', '$aid', '$order', '$curator')";
  push @pgcommands, $command;
  $command = "INSERT INTO h_pap_author_index VALUES ('$aid', '$newValue', NULL, '$curator')";
  push @pgcommands, $command;
  $command = "INSERT INTO pap_author_index VALUES ('$aid', '$newValue', NULL, '$curator')";
  push @pgcommands, $command;
  foreach my $command (@pgcommands) { $result = $dbh->do( $command ); }
  return 'OK';  
} # sub updatePostgresAuthorNewvalueField

sub updatePostgresAuthorReorderField {		# author field deletes all current values, updates values of current and history tables up to the highest order on current record, entering NULL in history for blank entries
  my ($field, $joinkey, $order, $curator, $newValue) = @_;
  my @pgcommands;
  my $result = $dbh->prepare( "SELECT pap_order FROM pap_author WHERE joinkey = '$joinkey' ORDER BY pap_order DESC" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); my $highest_order = $row[0];
  my (@author_order) = split/_TAB_/, $newValue;
  my $command = "DELETE FROM pap_$field WHERE joinkey = '$joinkey'";	# delete all authors
  push @pgcommands, $command;
  for my $order (1 .. $highest_order ) {
    my $i = $order - 1;
    my $author_value = 'NULL';
    if ($author_order[$i]) { $author_value = "'$author_order[$i]'"; }
#     print "$order\t$author_value<br />\n";
    $command = "INSERT INTO h_pap_$field VALUES ('$joinkey', $author_value, '$order', '$curator')";
    push @pgcommands, $command;
    if ($author_order[$i]) {				# only insert to current table if there are values
      $command = "INSERT INTO pap_$field VALUES ('$joinkey', $author_value, '$order', '$curator')";
      push @pgcommands, $command; } }
  foreach my $command (@pgcommands) { $result = $dbh->do( $command ); }
  return 'OK';  
} # sub updatePostgresAuthorReorderField 


sub makeSelectField {
  my ($current_value, $table, $joinkey, $order, $curator_id) = @_;
  my $data = "<td colspan=\"3\"><select id=\"select_${table}_$order\" name=\"select_${table}_$order\" onchange=\"changeSelect('$table', '$joinkey', '$order', '$curator_id')\">\n";
  $data .= "<option value=\"\"></option>\n";
  my $found_value = '';
  if ($table eq 'type') {
    foreach my $value (sort {$a<=>$b} keys %type_index) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$type_index{$value}</option>\n"; } }
# this is waaaay too slow
#   elsif ( ($table eq 'erratum_in') || ($table eq 'contained_in') ) {
#     my @curation_flags = qw(  Phenotype2GO rnai_curation rnai_int_done );
#     foreach my $value (sort {$a<=>$b} keys %valid_paper_index) {
#       my $selected = "";
#       if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
#       $data .= "<option value=\"$value\" $selected>$value</option>\n"; } }
  elsif ($table eq 'primary_data') {
    my @curation_flags = qw( primary not_primary not_designated );
    foreach my $value (@curation_flags) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$value</option>\n"; } }
  elsif ($table eq 'curation_flags') {
#     my @curation_flags = qw( functional_annotation genestudied_done Phenotype2GO rnai_curation rnai_int_done );
    my @curation_flags = qw( author_person emailed_community_gene_descrip non_nematode Phenotype2GO rnai_curation );	# got rid of rnai_int_done, not being used 2011 05 03  moved genestudied_done to curation_done as 'genestudied' 2011 05 18
    foreach my $value (@curation_flags) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$value</option>\n"; } }
  elsif ($table eq 'curation_done') {
    my @curation_flags = qw( author_person genestudied gocuration );
    foreach my $value (@curation_flags) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$value</option>\n"; } }
  elsif ($table eq 'year') {
    my $date = &getPgDate(); my ($year) = $date =~ m/^(2\d{3})/; $year += 2;
    foreach my $value (reverse (1900 .. $year)) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$value</option>\n"; } }
  elsif ($table eq 'month') {
    foreach my $value (01 .. 12) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$month_index{$value}</option>\n"; } }
  elsif ($table eq 'day') {
    foreach my $value (01 .. 31) {
      my $selected = "";
      if ($current_value) { if ($current_value eq $value) { $selected = "selected=\"selected\""; $found_value++; } }
      $data .= "<option value=\"$value\" $selected>$value</option>\n"; } }
  $data .= "</select>";
  unless ($found_value) { $data .= $current_value; }
  $data .= "</td>";
  return $data;
} # sub makeSelectField

# sub makeAuthorInputField {
#   my ($current_value, $table, $aid, $join, $curator_id, $colspan, $rowspan, $class) = @_;
#   # the $order here is usually the pap_order value of a normal table, but it's the author_id of an author_<stuff> table to server as a unique identifier for the html ids
# #   my $div_display = ""; my $input_display = "none";
# #   if ($current_value eq "NEW") { $div_display = "none"; $input_display = ""; $current_value = ''; }
#   my $data = "<td class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" onclick=\"toggleDivToInput('$table', '$order')\">
#   <input style=\"display: none\" size=\"40\" id=\"input_${table}_$order\" name=\"input_${table}_$order\" value=\"$current_value\" onblur=\"toggleInputToDiv('$table', '$joinkey', '$order', '$curator_id')\">
#   <div id=\"div_${table}_$order\" name=\"div_${table}_$order\" >$current_value</div></td>";
#   return $data;
# } # sub makeAuthorInputField

sub makeInputField {
  my ($current_value, $table, $joinkey, $order, $curator_id, $colspan, $rowspan, $class) = @_;
  # the $order here is usually the pap_order value of a normal table, but it's the author_id of an author_<stuff> table to server as a unique identifier for the html ids
#   my $div_display = ""; my $input_display = "none";
#   if ($current_value eq "NEW") { $div_display = "none"; $input_display = ""; $current_value = ''; }
  my $data = "<td class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" onclick=\"toggleDivToInput('$table', '$joinkey', '$order')\">
  <input style=\"display: none\" size=\"40\" id=\"input_${table}_${joinkey}_$order\" name=\"input_${table}_${joinkey}_$order\" value=\"$current_value\" onblur=\"toggleInputToDiv('$table', '$joinkey', '$order', '$curator_id')\">
  <div id=\"div_${table}_${joinkey}_$order\" name=\"div_${table}_${joinkey}_$order\" >$current_value</div></td>";
  return $data;
} # sub makeInputField


#   print "<tr><td colspan=5><div id=\"forcedPersonAutoComplete\">
#         <input id=\"forcedPersonInput\" type=\"text\">
#         <div id=\"forcedPersonContainer\"></div></div></td></tr>";
#       var forcedOAC = new YAHOO.widget.AutoComplete("forcedPersonInput", "forcedPersonContainer", oDS);


sub makeOntologyField {
  my ($current_value, $table, $joinkey, $order, $curator_id, $colspan, $rowspan, $class) = @_;
  my $div_value = $current_value; my $input_value = $current_value;
  my $freeForced = 'forced';
  my $input_id = "input_${table}_${joinkey}_$order";
# in div_table_joinkey_order  make current value something that will match dropdown
  if ( $curators{two}{$current_value} ) { 
    my ($num) = $current_value =~ m/(\d+)/;
    $div_value =  "$curators{two}{$current_value} ( WBPerson$num )";
    $input_value =  "$curators{two}{$current_value}"; } 

  my $data = "<td id=\"td_display_$input_id\" class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" onclick=\"toggleDivToSpanInput('$table', '$joinkey', '$order')\">

  <div id=\"div_${table}_${joinkey}_$order\" name=\"div_${table}_${joinkey}_$order\" >$div_value</div></td>

  <td id=\"td_AutoComplete_$input_id\" class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" style=\"display: none\" width=\"400\">
  <div id=\"div_AutoComplete_$input_id\" class=\"div-autocomplete\">
  <input size=\"40\" id=\"$input_id\" name=\"$input_id\" value=\"$input_value\" onblur=\"toggleAcInputToTd('$table', '$joinkey', '$order', '$curator_id')\">
  <div id=\"div_Container_$input_id\"></div></div></td>";

  return ($input_id, $data);
#   <input id=\"input_$table\" name=\"input_$table\" size=\"40\">
} # sub makeOntologyField

sub makeToggleDoubleField {
  my ($current_value, $table, $joinkey, $order, $curator_id, $colspan, $rowspan, $class, $one, $two) = @_;
  my $data = "<td class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" onclick=\"toggleDivDoubleToggle('$table', '$joinkey', '$order', '$curator_id', '$one', '$two')\">
  <div id=\"div_${table}_${joinkey}_$order\" name=\"div_${table}_${joinkey}_$order\" >$current_value</div></td>";
  return $data;
} # sub makeToggleDoubleField

sub makeToggleTripleField {
  my ($current_value, $table, $joinkey, $order, $curator_id, $colspan, $rowspan, $class, $one, $two, $three) = @_;
  my $data = "<td class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" onclick=\"toggleDivTripleToggle('$table', '$joinkey', '$order', '$curator_id', '$one', '$two', '$three')\">
  <div id=\"div_${table}_${joinkey}_$order\" name=\"div_${table}_${joinkey}_$order\" >$current_value</div></td>";
  return $data;
} # sub makeToggleTripleField

sub makeUneditableField {
  my ($current_value, $table, $joinkey, $order, $curator_id, $colspan, $rowspan, $class) = @_;
  my $data = "<td class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\">
  <div id=\"div_${table}_${joinkey}_$order\" name=\"div_${table}_${joinkey}_$order\" >$current_value</div></td>";
  return $data;
} # sub makeUneditableField


# for new genes, two types
# published_as, which when clicked gives input for published_as evidence, then click out give box for locus / gene, then click out to convert into blue row, and clear published_as field
# 3 rows per gene, curator_confirmed, manually_connected, published_as
# batch genes, which when clicked gives textarea, enter lots of loci, show what they match to like curation_FP form genestudied field.  when click out convert each into blue row, clear batch genes.  
# 2 rows per gene, curator_confirmed, manually_connected
sub makeGeneDeleteField {			# for deleting genes, has evidence
  # add confirmation button here TODO  ( or maybe not ? seems good as is  -- 2010 03 26)
  my ($current_value, $table, $joinkey, $order, $curator_id, $evidence) = @_;
  my $name = &getGeneName($current_value);
  if ($name) { $name = "( " . $name . ")"; }
#   my $data = "<td><input onclick=\"deletePostgresTableField('$table', '$order', '$curator_id'); this.parentNode.parentNode.style.display='none'\" type=\"button\" value=\"delete\" ></td><td>$current_value ( $name )</td><td>$evidence</td>"; 	# replaced deletePostgresTableField with updatePostgresTableField to blank value
  my $data = "<td><input onclick=\"updatePostgresTableField('$table', '$joinkey', '$order', '$curator_id', ''); this.parentNode.parentNode.style.display='none'\" type=\"button\" value=\"delete\" ></td><td>$current_value $name</td><td>$evidence</td>"; 
  return $data;
} # sub makeGeneDeleteField

sub getGeneName {
  my ($current_value) = @_;
  my $name = '';
  my $result = $dbh->prepare( "SELECT * FROM gin_locus WHERE joinkey = '$current_value'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); $name = $row[1];
  unless ($name) {
    my $result = $dbh->prepare( "SELECT * FROM gin_seqname WHERE joinkey = '$current_value'" );	# check gin_seqname instead of gin_sequence for Kimberly 2011 05 06
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    my @row = $result->fetchrow(); $name = $row[1]; }
  return $name;
} # sub getGeneName

sub getGeneDisplay {
  my ($display_data, $evi) = @_;
  my $name = &getGeneName($display_data);
  $display_data = "<td>$display_data ( $name )</td><td>$evi</td>";
  return $display_data;
} # sub getGeneDisplay

sub makeGeneTextareaField {		# to enter new genes.  gene textarea field has extra div_gene_display field for now
  my ($current_value, $table, $joinkey, $order, $curator_id, $datatype, $rows, $cols) = @_;
  my $data = "<td colspan=\"3\" onclick=\"toggleDivToTextarea('$table', '$joinkey', '$order')\">
  <textarea style=\"display: none\" rows=\"$rows\" cols=\"$cols\" id=\"textarea_${table}_$order\" name=\"textarea_${table}_$order\" onKeyUp=\"matchGeneTextarea('$order', 'batch', '$datatype')\" onblur=\"toggleGeneTextareaToDiv('$table', '$joinkey', '$order', '$curator_id')\">$current_value</textarea>
  <div id=\"div_${table}_display\" name=\"div_${table}_display\"></div>
  <div id=\"div_${table}_$order\" name=\"div_${table}_$order\" >$current_value</div></td>";
  return $data;
} # sub makeGeneTextareaField

sub makeGeneEvidenceField {		# to enter evidence and new genes.  gene evidence field + autocomplete
  my ($current_value, $table, $joinkey, $order, $curator_id, $datatype, $colspan, $rowspan, $class) = @_;
  my $warning = "<div style=\"color:red\">Are you sure you know how this works ?  If not confirm with Kimberly, if so tell Juancarlos to get rid of this warning.</div><br />\n";
  if ( ($curator_id eq 'two1843') || ($curator_id eq 'two1823') ) { $warning = ''; }	# clear warning for Kimberly and me
  my $data = "
  <td id=\"td_${table}_placeholder\" class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\" onclick=\"toggleTdToGeneEvi('$table', '$joinkey', '$order')\"></td>
  <td id=\"td_${table}_info\" style=\"display: none\" class=\"$class\" rowspan=\"$rowspan\" colspan=\"$colspan\">
    $warning
    Published_as :
    <input size=\"40\" id=\"input_${table}_published_as\" name=\"input_${table}_published_as\" value=\"\" onblur=\"verifyEviFocusOnGene('$table', '$joinkey', '$order', '$curator_id')\"><br />
    Gene (or genes if all have the same Published_as evidence) :<br />
    <textarea rows=\"2\" cols=\"40\" id=\"textarea_evi_${table}_$order\" name=\"textarea_evi_${table}_$order\" onKeyUp=\"matchGeneTextarea('$order', 'evi', '$datatype')\" onblur=\"geneEviToDiv('$table', '$joinkey', '$order', '$curator_id')\">$current_value</textarea>
    <div id=\"div_evi_${table}_display\" name=\"div_evi_${table}_display\"></div>
    <div id=\"display_div_${table}_${joinkey}_$order\" name=\"display_div_${table}_${joinkey}_$order\" >$current_value</div>
  </td>";
  return $data;
} # sub makeGeneEvidenceField 



sub makeStatusField {			# to delete papers
  my ($current_value, $table, $joinkey, $order, $curator_id) = @_;
#   my $data = "<td colspan=\"3\">$current_value <input onclick=\"alert('$table', '$order')\" type=\"button\" value=\"make invalid\"></td>"; 
  my $data = "<td colspan=\"3\">$current_value <input onclick=\"confirmInvalid('$joinkey')\" type=\"button\" value=\"make invalid\"></td>"; 
  return $data;
}


sub makeTextareaField {
  my ($current_value, $table, $joinkey, $order, $curator_id, $rows, $cols) = @_;
  my $data = "<td colspan=\"3\" onclick=\"toggleDivToTextarea('$table', '$joinkey', '$order')\">
  <textarea style=\"display: none\" rows=\"$rows\" cols=\"$cols\" id=\"textarea_${table}_$order\" name=\"textarea_${table}_$order\" onblur=\"toggleTextareaToDiv('$table', '$joinkey', '$order', '$curator_id')\">$current_value</textarea>
  <div id=\"div_${table}_$order\" name=\"div_${table}_$order\" >$current_value</div></td>";
  return $data;
}

sub displayMerge {
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"mergePage\">";
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  ($oop, my $acquires_joinkey) = &getHtmlVar($query, 'joinkey');
  ($oop, my $merge_into) = &getHtmlVar($query, 'merge_into');
  my $merge_joinkey = $merge_into;
  if ($merge_into =~ m/(\d+)/) { $merge_joinkey = &padZeros($1); }
  print "C $curator_id J $acquires_joinkey acquires $merge_joinkey <br />\n";
  my %data;
  foreach my $joinkey ($acquires_joinkey, $merge_joinkey) {
    foreach my $table (@normal_tables) {
      $result = $dbh->prepare( "SELECT * FROM pap_$table WHERE joinkey = '$joinkey' ORDER BY pap_order" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
        my ($pg_joinkey, $data, $order, $curator, $timestamp, $evi) = @row;
        $data{$table}{$joinkey}{$order}{data} = $data;
        $data{$table}{$joinkey}{$order}{curator} = $curator;
        $data{$table}{$joinkey}{$order}{timestamp} = $timestamp;
        if ($table eq 'gene') { $data{$table}{$joinkey}{$order}{evi} = $evi; }
      }
    } # foreach my $table (@normal_tables)
  } # foreach my $joinkey ($acquires_joinkey, $merge_joinkey)
  my $identifier_highest_order = 0;
  print "<table border=0>\n";
  foreach my $table (@normal_tables) {
    next if ($table eq 'electronic_path');	# skip this for now
    my @data_trs;
    my $original_highest_order = 0;
    foreach my $joinkey ($acquires_joinkey, $merge_joinkey) {
      my $bgcolor = 'white'; my $td_button = "<td></td>";
      if ($curator_id eq 'two1843') { $td_button = "<td>$acquires_joinkey</td><td></td>"; }

      foreach my $order (sort { $a<=>$b } keys %{ $data{$table}{$joinkey} }) {
        my $jsevi = 'merge'; my $evi = '';
        if ($data{$table}{$joinkey}{$order}{evi}) { 
          $evi = $data{$table}{$joinkey}{$order}{evi};
          $jsevi = $data{$table}{$joinkey}{$order}{evi}; $jsevi =~ s/"/&quot;/g; $jsevi =~ s/\t/ESCTAB/g; }	# tabs don't get passed for some reason

        my $data = $data{$table}{$joinkey}{$order}{data};
        my $curator = $data{$table}{$joinkey}{$order}{curator};
        my $timestamp = $data{$table}{$joinkey}{$order}{timestamp}; $timestamp =~ s/\.[\d\-]+$//;
        if ($joinkey eq $acquires_joinkey) {
          if ($table eq 'identifier') { $identifier_highest_order = $order + 1; }	# get highest order of identifier for final merge
          $original_highest_order = $order + 1; }	# get highest order
        if ($joinkey eq $merge_joinkey) {
          $bgcolor = '#ffbbbb'; 
          $td_button = "<td onclick=\"updatePostgresTableField(\'$table\', \'$acquires_joinkey\', \'\', \'$curator_id\', \'$data\'); updatePostgresTableField(\'$table\', \'$merge_joinkey\', \'\', \'$curator_id\', \'\')\">replace</td>";
          if ($multi{$table}) {
            $td_button = "<td onclick=\"updatePostgresTableField(\'$table\', \'$acquires_joinkey\', \'$original_highest_order\', \'$curator_id\', \'$data\'); updatePostgresTableField(\'$table\', \'$merge_joinkey\', \'$order\', \'$curator_id\', \'\')\">merge</td>"; 
            if ($table eq 'gene') {
              $td_button = "<td onclick=\"updatePostgresTableField(\'$table\', \'$acquires_joinkey\', \'$original_highest_order\', \'$curator_id\', \'$data\', \'$jsevi\'); updatePostgresTableField(\'$table\', \'$merge_joinkey\', \'$order\', \'$curator_id\', \'\')\">merge</td>"; } 
} }
        if ($curator_id eq 'two1843') { $td_button = "<td>$merge_joinkey</td>" . $td_button; }
        my $td_display_data = "<td colspan=\"2\">$data</td>";
        if ($table eq 'author') { $td_display_data = &getAidDataForDisplay($data); }
        elsif ($table eq 'type') { $td_display_data = "<td colspan=\"2\">$type_index{$data}</td>"; }
        elsif ($table eq 'gene') { $td_display_data = &getGeneDisplay($data, $evi); } 
        push @data_trs, "<tr bgcolor='$bgcolor'>${td_button}${td_display_data}<td>$order</td><td>$curator</td><td style=\"width:11em\">$timestamp</td></tr>\n";
      } # foreach my $order (sort { $a<=>$b } keys %{ $data{$table}{$joinkey} })
    } # foreach my $joinkey ($acquires_joinkey, $merge_joinkey)
    if ($data_trs[0]) {
      print "<tr bgcolor='#dddddd'><td colspan=7 align=\"center\">$table</td></tr>\n"; 
      foreach my $data_tr (@data_trs) { print "$data_tr"; } }
  } # foreach my $table (@normal_tables)
  print "</table>\n";
  print "<hr/><input type=\"button\" onclick=\"updatePostgresTableField(\'identifier\', \'$acquires_joinkey\', \'$identifier_highest_order\', \'$curator_id\', \'$merge_joinkey\', \'\', \'paper_editor.cgi?curator_id=$curator_id&action=Search&data_number=$merge_joinkey\');\" value=\"merge WBPaper$merge_into into pap_identifier of WBPaper$acquires_joinkey and review WBPaper$merge_joinkey for deletion\">";
# my $identifier_highest_order = 0;
  &printFooter();
} # sub displayMerge

sub getAidDataForDisplay {
  my $aid = shift;
  my $result2 = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id = '$aid'" );
  $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row2 = $result2->fetchrow(); my $name = $row2[1];
  
  my %aid_data;
  my @aut_tables = qw( possible sent verified );
  foreach my $table (@aut_tables) {
    $result = $dbh->prepare( "SELECT * FROM pap_author_$table WHERE author_id = '$aid';" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      $aid_data{$row[2]}{$table}{time} = $row[4]; 
      $aid_data{$row[2]}{$table}{data} = $row[1]; } }

  my @entries;
  foreach my $join (sort {$a<=>$b} keys %aid_data ) {
    my $possible = ''; my $pos_time = ''; my $sent = ''; my $verified = ''; my $ver_time = '';
    if ($aid_data{$join}{possible}{data}) { $possible = $aid_data{$join}{possible}{data}; }
    if ($aid_data{$join}{possible}{time}) { $pos_time = $aid_data{$join}{possible}{time}; $pos_time =~ s/ [\:\.\d\-]+$//; }
    if ($aid_data{$join}{sent}{data}) { $sent = $aid_data{$join}{sent}{data}; }
    if ($aid_data{$join}{verified}{data}) { $verified = $aid_data{$join}{verified}{data}; }
    if ($aid_data{$join}{verified}{time}) { $ver_time = $aid_data{$join}{verified}{time}; $ver_time =~ s/ [\:\.[\d\-]+$//; }
    my $entry = "<td class=\"normal_even\">$join</td><td class=\"normal_even\">$possible</td><td class=\"normal_even\">$pos_time</td><td class=\"normal_even\">$sent</td><td class=\"normal_even\">$verified</td><td class=\"normal_even\">$ver_time</td>";
    push @entries, $entry; }

  my $lines_count = scalar(@entries); my $first_entry = shift @entries; 
  my $display_data = "<table style=\"border-style: none;\" border=\"1\" ><tr bgcolor='$blue'><td rowspan=\"$lines_count\" class=\"normal_even\">$aid</td><td rowspan=\"$lines_count\" class=\"normal_even\">$name</td>$first_entry</tr>";
  foreach my $entry (@entries) { $display_data .= "<tr>$entry</tr>\n"; }
  $display_data .= "</table>";

  return "<td colspan=\"2\">$display_data</td>";
} # sub getAidDataForDisplay

sub displayNumber {
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"displayNumber\">";
#   my ($joinkey, $history) = @_;
  my ($joinkey, $curator_id) = @_;
  print "<input type=\"hidden\" name=\"paper_joinkey\" id=\"paper_joinkey\" value=\"$joinkey\">";
  print "<input type=\"hidden\" name=\"curator_id\" id=\"curator_id\" value=\"$curator_id\">";
  my @authors; my %aid_data; my %author_list;
  my $species_max_order = 0;			# amount of species fields to check
  my @species_autocomplete_input_ids;
  my %display_data;
  my $header_bgcolor = '#dddddd'; my $header_color = 'black';
  if ($curator_id eq 'two1843') { $header_bgcolor = '#aaaaaa'; $header_color = 'white'; }

#   print "<tr bgcolor='#aaaaaa'><td colspan=5><div style=\"color:white\">Publication Information</div></td></tr>\n";
#   foreach my $table (@normal_tables, "electronic_path") { # }
  foreach my $table (@normal_tables) {
    my $entry_data;
    if ($table eq 'gene') { $entry_data .= "<tr bgcolor='$header_bgcolor'><td colspan=7><div style=\"color:$header_color\">Genes and Curation Flags</div></td></tr>\n"; }
    elsif ($table eq 'status') { $entry_data .= "<tr bgcolor='$header_bgcolor'><td colspan=7><div style=\"color:$header_color\">Publication Information</div></td></tr>\n"; }
    my $table_has_data = 0;
    my $highest_order = 0;
    my $pg_table = 'pap_' . $table; 
#     if ($history eq 'on') { $pg_table = 'h_pap_' . $table; }
#     print "SELECT * FROM $pg_table WHERE joinkey = '$joinkey' ORDER BY pap_order<br />\n" ;
    $result = $dbh->prepare( "SELECT * FROM $pg_table WHERE joinkey = '$joinkey' ORDER BY pap_order" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      $row[0] = $table;
#       if ($table eq 'type') { $row[1] = $type_index{$row[1]}; }
#       if ($table eq 'type') { 
#           ($row[1]) = &makeTypeSelect($row[1], $table, $joinkey, $order, $curator_id); }
      next unless ($row[1]);				# skip blank entries
      $table_has_data++; 				# set flag that there was data
      shift @row;					# don't store joinkey
      my $data = shift @row; my $td_data = $data;
      my $order = shift @row; unless ($order) { $order = ''; }
      if ($multi{$table}) { if ($order > $highest_order) { $highest_order = $order; } }	# get the highest order if in %multi 
      my $row_curator = shift @row;
      my $timestamp = shift @row; $timestamp =~ s/\.[\d\-]+$//;

      if ($table eq 'pubmed_final') { 
          $td_data = "<td colspan=\"3\">$data</td>"; }	# display as is
        elsif ($table eq 'electronic_path') {
          my ($pdf) = $data =~ m/\/([^\/]*)$/;
          my $additional_text = ''; if ($pdf =~ m/^\d{8}$/) { $additional_text = ' additional info'; }
          $pdf = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdf;
          $td_data = "<td colspan=\"3\"><a href=\"$pdf\">$pdf</a>$additional_text</td>\n"; }
# This is replaced by makeGeneDeleteField
#         elsif ($table eq 'gene') { 
#           my $name = '';
#           my $result2 = $dbh->prepare( "SELECT * FROM gin_locus WHERE joinkey = '$data'" );
#           $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#           my @row2 = $result2->fetchrow(); $name = $row[2];
#           $td_data = "WBGene$data ($row2[1])"; }
        elsif ($table eq 'author') {
          push @authors, $data;
          my $result3 = $dbh->prepare( "SELECT * FROM pap_author_corresponding WHERE author_id = '$data'" );
          $result3->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
          my @row3 = $result3->fetchrow();
          $aid_data{$data}{corresponding} = $row3[1]; 
          my $result2 = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id = '$data'" );
          $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
          my @row2 = $result2->fetchrow();
          $aid_data{$data}{index} = $row2[1]; 
#           $data .= " ($row2[1])"; 
          $author_list{$order}{corresponding} = $row3[1];
          $author_list{$order}{name} = $row2[1];
          $author_list{$order}{aid} = $data;
          $author_list{$order}{row_curator} = $row_curator;
          $author_list{$order}{timestamp} = $timestamp; }
        elsif ($table eq 'species') {
          my $result2 = $dbh->prepare( "SELECT * FROM pap_species_index WHERE joinkey = '$data';" );
          $result2->execute() or die "Cannot prepare statement: $DBI::errstr\n";
          my @row2 = $result2->fetchrow(); 
          if ($row2[1]) { $data = $row2[1] . ' - ' . $row2[0]; }
          $td_data = "<td><input onclick=\"updatePostgresTableField('$table', '$joinkey', '$order', '$curator_id', ''); this.parentNode.parentNode.style.display='none'\" type=\"button\" value=\"delete\" ></td><td>$data</td><td>$row[0]</td>"; 
#           ($td_data) = &makeInputField($data, $table, $joinkey, $order, $curator_id, '3', '1', '');
#           my $input_id = 'input_species_' . $joinkey . '_' . $order;
#           push @species_autocomplete_input_ids, $input_id;
#           $td_data = qq(<td rowspan="1" colspan="3"><div id="div_AutoComplete_$input_id" width="80%" class="div-autocomplete">
#           <input size="80" id="$input_id" name="$input_id" style="width: 98%;" value="$data" onblur="checkInputEmptyUpdatePg('$table', '$joinkey', '$order', '$curator_id')">
#           <div id="div_Container_$input_id" style="width: 98%;"></div></div></td>);
          $species_max_order = $order;
          $entry_data .= "<tr bgcolor=\"$blue\"><td>$table</td>$td_data<td>$order</td><td>$row_curator</td><td>$timestamp</td></tr>\n"; }
#         my @data; foreach (@row) { if ($_) { push @data, $_; } else { push @data, ""; } }		# some data is undefined
#         my $data = join"</td><td>", @data;
        elsif ( ($table eq 'type') || ($table eq 'curation_flags') || ($table eq 'curation_done') || ($table eq 'primary_data') 
                              || ($table eq 'year') || ($table eq 'month') || ($table eq 'day') ) {
          ($td_data) = &makeSelectField($data, $table, $joinkey, $order, $curator_id); }
        elsif ( ($table eq 'electronic_path') || ($table eq 'pubmed_final') ) { 1; }
#         elsif ( ($table eq 'title') || ($table eq 'gene') ) { ($td_data) = &makeTextareaField($data, $table, $joinkey, $order, $curator_id, "8", "80"); }
        elsif ( ($table eq 'title') ) { ($td_data) = &makeTextareaField($data, $table, $joinkey, $order, $curator_id, "8", "80"); }
        elsif ($table eq 'abstract') { ($td_data) = &makeTextareaField($data, $table, $joinkey, $order, $curator_id, "40", "80"); }
        elsif ($table eq 'status') { ($td_data) = &makeStatusField($data, $table, $joinkey, $order, $curator_id); }
        elsif ($table eq 'gene') { ($td_data) = &makeGeneDeleteField($data, $table, $joinkey, $order, $curator_id, $row[0]); }
        elsif ($table eq 'gene_comp') { ($td_data) = &makeGeneDeleteField($data, $table, $joinkey, $order, $curator_id, $row[0]); }
        else { ($td_data) = &makeInputField($data, $table, $joinkey, $order, $curator_id, '3', '1', ''); }

      unless ( ($table eq 'author') || ($table eq 'species') ) {
        $entry_data .= "<tr bgcolor='$blue'><td>$table</td>$td_data<td>$order</td><td>$row_curator</td><td style=\"width:11em\">$timestamp</td></tr>\n"; }
    } # while (my @row = $result->fetchrow)

# INSERT INTO pap_species VALUES ('00042061', '6239', '1', 'two1843', '2016-05-20 16:31:02.796279-07', 'Inferred_automatically "from author first pass afp_species"');

    if ( ($multi{$table}) || ($table_has_data == 0) ) {
#       next if ($table eq 'author');				# do not allow new authors here
      my $order = ""; if ($multi{$table}) { $order = 1; }	# set default order for non-multi and multi tables
      if ($highest_order) { $order = $highest_order + 1; }
      my $td_data = '';			# default new values are blank
      if ($table eq 'electronic_path') { 1; }			# not an editable field
        elsif ($table eq 'pubmed_final') { 1; }			# not an editable field	# don't display to prevent errors  2010 12 13
        elsif ( ($table eq 'type') || ($table eq 'curation_flags') || ($table eq 'curation_done') || ($table eq 'year') || ($table eq 'month') || ($table eq 'day') ) { 
          ($td_data) = &makeSelectField("", $table, $joinkey, $order, $curator_id); 
          $entry_data .= "<tr bgcolor=\"white\"><td>$table</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        elsif ($table eq 'gene') { 
          ($td_data) = &makeGeneTextareaField('', $table, $joinkey, $order, $curator_id, 'genestudied', "8", "80");
          $entry_data .= "<tr bgcolor=\"white\"><td>$table (batch)</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n";
          ($td_data) = &makeGeneEvidenceField('', $table, $joinkey, $order, $curator_id, 'genestudied', '3', '1', '');
          $entry_data .= "<tr bgcolor=\"white\"><td>$table (evi)</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        elsif ($table eq 'gene_comp') { 
          ($td_data) = &makeGeneTextareaField('', $table, $joinkey, $order, $curator_id, 'genecomparator', "8", "80");
          $entry_data .= "<tr bgcolor=\"white\"><td>$table (batch)</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n";
          ($td_data) = &makeGeneEvidenceField('', $table, $joinkey, $order, $curator_id, 'genecomparator', '3', '1', '');
          $entry_data .= "<tr bgcolor=\"white\"><td>$table (evi)</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        elsif ($table eq 'title') { 
          ($td_data) = &makeTextareaField($td_data, $table, $joinkey, $order, $curator_id, "8", "80");
          $entry_data .= "<tr bgcolor=\"white\"><td>$table</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        elsif ($table eq 'abstract') { 
          ($td_data) = &makeTextareaField($td_data, $table, $joinkey, $order, $curator_id, "40", "80");
          $entry_data .= "<tr bgcolor=\"white\"><td>$table</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        elsif ($table eq 'author') { 
          ($td_data) = &makeInputField("", 'author_new', $joinkey, $order, $curator_id, '3', '1', '');
          $entry_data .= "<tr bgcolor=\"white\"><td>$table</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        elsif ($table eq 'species') { 
          $species_max_order++;
          my $input_id = 'input_species_' . $joinkey . '_' . $species_max_order;
          push @species_autocomplete_input_ids, $input_id;
          $td_data = qq(<td rowspan="1" colspan="3"><div id="div_AutoComplete_$input_id" width="80%" class="div-autocomplete">
          <input size="80" id="$input_id" name="$input_id" style="width: 98%;" value="">
          <div id="div_Container_$input_id" style="width: 98%;"></div></div></td>);
          $entry_data .= "<tr bgcolor=\"white\"><td>$table</td>$td_data<td>$species_max_order</td><td>$curator_id</td><td>current</td></tr>\n"; }
        else { 
          ($td_data) = &makeInputField("", $table, $joinkey, $order, $curator_id, '3', '1', '');
          $entry_data .= "<tr bgcolor=\"white\"><td>$table</td>$td_data<td>$order</td><td>$curator_id</td><td>current</td></tr>\n"; }
    }
    $entry_data .= qq(<input type="hidden" id="species_max_order" value="$species_max_order">);	# pass species fields to javascript
#     $entry_data .= qq(<input type="hidden" id="papersCount" value="1">);			# using code from pmid entering which allows multiple papers
    if ($table eq 'author') { $entry_data = &getAuthorDisplay(\%author_list) . $entry_data; }
    $display_data{$table} = $entry_data;
  } # foreach my $table (@normal_tables)
  my $species_input_ids = join", ",  @species_autocomplete_input_ids;		# ids of input fields for species autocomplete
  print "<input type=\"hidden\" id=\"species_input_ids\" value=\"$species_input_ids\">";

#   if ( ($curator_id eq 'two1823') || ($curator_id eq 'two1') ) { # }
  if ( $curator_id eq 'two1' ) {
    &displayAuthorPersonSection(\@authors, \%aid_data, $curator_id); 
    &displayMainPaperSection($joinkey, \%display_data); }
  else {
    &displayMainPaperSection($joinkey, \%display_data);
    &displayAuthorPersonSection(\@authors, \%aid_data, $curator_id); }

  if ( ($curator_id eq 'two1823') || ($curator_id eq 'two1843') || ($curator_id eq 'two1') )  {
    print "<tr><td colspan=\"5\">Merge WBPaper <input size=10 name=\"merge_into\" id=\"merge_into\" onblur=\"mergePaper('$joinkey', '$curator_id')\"> into this WBPaper$joinkey <input type=\"button\" onclick=\"mergePaper('$joinkey', '$curator_id')\" value=\"click for merging page\"></td></tr>\n"; }

} # sub displayNumber


sub displayAuthorPersonSection {
  my ($authors_ref, $aid_data_ref, $curator_id) = @_;
  &populateCurators();						# for verified yes / no standard name
  my @person_autocomplete_input_ids;				# ids of input fields for person autocomplete
  my @authors = @$authors_ref;
  my %aid_data = %$aid_data_ref;
  print "<table style=\"border-style: none;\" border=\"1\" >\n";
  my @aut_tables = qw( possible sent verified );
  my $aids = join"', '", @authors;
  foreach my $table (@aut_tables) {
#     print "SELECT * FROM pap_author_$table WHERE author_id IN ('$aids');<br />\n";
    $result = $dbh->prepare( "SELECT * FROM pap_author_$table WHERE author_id IN ('$aids');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { 
      $aid_data{$row[0]}{join}{$row[2]}{$table}{time} = $row[4]; 
      $aid_data{$row[0]}{join}{$row[2]}{$table}{data} = $row[1]; }
  } # foreach my $table (@aut_tables)
  print "<tr bgcolor='$blue'><td class=\"normal_even\">aid</td><td class=\"normal_even\">author</td><td class=\"normal_even\">corresponding</td><td class=\"normal_even\">new</td><td class=\"normal_even\">join</td><td class=\"normal_even\">possible</td><td class=\"normal_even\">pos_time</td><td class=\"normal_even\">sent</td><td class=\"normal_even\">verified</td><td class=\"normal_even\">ver_time</td></tr>\n";
  foreach my $aid (@authors) {
    my @entries;
    my $class = 'normal_even';
    my $author = '';        if ($aid_data{$aid}{index})         { $author        = $aid_data{$aid}{index};         }
    my $corresponding = ''; if ($aid_data{$aid}{corresponding}) { $corresponding = $aid_data{$aid}{corresponding}; }
    foreach my $join (sort {$a<=>$b} keys %{ $aid_data{$aid}{join} } ) {
      my $possible = ''; my $pos_time = ''; my $sent = ''; my $verified = ''; my $ver_time = '';
      if ($aid_data{$aid}{join}{$join}{possible}{data}) { $possible = $aid_data{$aid}{join}{$join}{possible}{data}; }
      if ($aid_data{$aid}{join}{$join}{possible}{time}) { $pos_time = $aid_data{$aid}{join}{$join}{possible}{time}; $pos_time =~ s/ [\:\.\d\-]+$//; }
      if ($aid_data{$aid}{join}{$join}{sent}{data}) { $sent = $aid_data{$aid}{join}{$join}{sent}{data}; }
      if ($aid_data{$aid}{join}{$join}{verified}{data}) { $verified = $aid_data{$aid}{join}{$join}{verified}{data}; }
      if ($aid_data{$aid}{join}{$join}{verified}{time}) { $ver_time = $aid_data{$aid}{join}{$join}{verified}{time}; $ver_time =~ s/ [\:\.[\d\-]+$//; }
#       my ($td_author_possible) = &makeInputField($possible, 'author_possible', $aid, $join, $curator_id, 1, 1, $class); 
      my ($input_id, $td_author_possible) = &makeOntologyField($possible, 'author_possible', $aid, $join, $curator_id, 1, 1, $class);
      push @person_autocomplete_input_ids, $input_id;
      my ($td_author_sent) = &makeUneditableField($sent, 'author_sent', $aid, $join, $curator_id, 1, 1, $class); 
      my ($td_author_verified) = &makeUneditableField($verified, 'author_verified', $aid, $join, $curator_id, 1, 1, $class); 
      if ($possible) {
        my $on = "YES  $curators{two}{$curator_id}"; my $off = "NO  $curators{two}{$curator_id}";
        ($td_author_verified) = &makeToggleTripleField($verified, 'author_verified', $aid, $join, $curator_id, 1, 1, $class, $on, $off, '');  }
      my $entry = "<td class=\"normal_even\">$join</td>$td_author_possible<td class=\"normal_even\">$pos_time</td>${td_author_sent}${td_author_verified}<td class=\"normal_even\">$ver_time</td>";
      push @entries, $entry;
    } # foreach my $join (sort {$a<=>$b} keys %{ $aid_data{$aid}{join} } )
    unless ($entries[0]) {				# if there are no entries already, make a blank one
      my $join = '1';
#       my ($td_author_possible) = &makeInputField('', 'author_possible', $aid, $join, $curator_id, 1, 1, $class); 
      my ($input_id, $td_author_possible) = &makeOntologyField('', 'author_possible', $aid, $join, $curator_id, 1, 1, $class);
      push @person_autocomplete_input_ids, $input_id;
      my ($td_author_sent) = &makeUneditableField('', 'author_sent', $aid, $join, $curator_id, 1, 1, $class); 
      my ($td_author_verified) = &makeUneditableField('', 'author_verified', $aid, $join, $curator_id, 1, 1, $class);	# there cannot be a value under possible, so do not allow verify edit
      my $entry = "<td class=\"normal_even\">$join</td>$td_author_possible<td class=\"normal_even\"></td>${td_author_sent}${td_author_verified}<td class=\"normal_even\"></td>";
      push @entries, $entry; }
    my $lines_count = scalar(@entries); 
    my $first_entry = shift @entries;
    my ($input_id, $td_author_possible_new) = &makeOntologyField('', 'author_possible', $aid, 'new', $curator_id, 1, $lines_count, $class);
    push @person_autocomplete_input_ids, $input_id;
    my ($td_author_index) = &makeInputField($author, 'author_index', $aid, '', $curator_id, 1, $lines_count, $class); 
    my ($td_author_corresponding) = &makeToggleDoubleField($corresponding, 'author_corresponding', $aid, '', $curator_id, 1, $lines_count, $class, 'corresponding', '');
    print "<tr bgcolor='$blue'><td rowspan=\"$lines_count\" class=\"normal_even\">$aid</td>$td_author_index$td_author_corresponding$td_author_possible_new$first_entry</tr>";
    foreach my $entry (@entries) { print "<tr>$entry</tr>\n"; }
    
  } # foreach my $aid (@authors)

#   print "<tr><td colspan=5><div id=\"forcedPersonAutoComplete\">
#         <input id=\"forcedPersonInput\" type=\"text\">
#         <div id=\"forcedPersonContainer\"></div></div></td></tr>";
  print "</table>\n";
  my $person_input_ids = join", ",  @person_autocomplete_input_ids;		# ids of input fields for person autocomplete
  print "<input type=\"hidden\" id=\"person_input_ids\" value=\"$person_input_ids\">";
} # sub displayAuthorPersonSection


sub displayMainPaperSection {
  my ($joinkey, $display_data_ref) = @_;
  my %display_data = %$display_data_ref;
  print "<table border=0>\n";
  print "<tr bgcolor='$blue'><td colspan=7>WBPaper$joinkey</td></tr>\n";
  foreach my $table (@normal_tables) { 
    if ($display_data{$table}) { print $display_data{$table}; } }
  print "</table><br />";
} # sub displayMainPaperSection

sub getAuthorDisplay {
  my ($author_list_ref) = @_;
  my %author_list = %$author_list_ref;
  my @other_row_data; my $highest_order = 0;
  my $ul = "<ul id=\"author_list\" class=\"draglist\">";
  foreach my $order (sort {$a<=>$b} keys %author_list) {
    $highest_order = $order;
    my $corresponding = $author_list{$order}{corresponding} || '';
    my $name          = $author_list{$order}{name}          || '';
    my $aid           = $author_list{$order}{aid}           || '';
    my $curator       = $author_list{$order}{row_curator}   || '';
    my $timestamp     = $author_list{$order}{timestamp}     || '';
    $ul .= "<li class=\"list1\" id=\"author_li_$order\" value=\"$aid\">$aid $corresponding ($name)</li>";
    push @other_row_data, "<td>$order</td><td>$curator</td><td>$timestamp</td>";
  }
  $ul .= "</ul>";
  my $lines_count = scalar(@other_row_data);
  my $first_entry = shift @other_row_data;
  if ($lines_count == 0) { return ''; }			# no authors return blank for section to reorder existing authors
  my $to_return = "<tr bgcolor='$blue'><td rowspan=\"$lines_count\">author</td><td rowspan=\"$lines_count\" colspan=\"3\">$ul</td>$first_entry";
  foreach (@other_row_data) { $to_return .= "<tr bgcolor='$blue'>$_</tr>"; }
  $to_return .= "<input type=\"hidden\" id=\"author_max_order\" value=\"$highest_order\">";
  return $to_return;
} # sub getAuthorDisplay

sub search {
  &printHtmlHeader();
#   my $history = 'off';
#   ($oop, my $temp_history) = &getHtmlVar($query, "history");
#   if ($temp_history) { $history = $temp_history; }
#   print "History display $history<br/>\n"; 

  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  #&updateCurator($curator_id);

  ($oop, my $number) = &getHtmlVar($query, "data_number");
  if ($number) { 
#     if ($number =~ m/(\d+)/) { &displayNumber(&padZeros($1), $history); return; }
    if ($number =~ m/(\d+)/) { &displayNumber(&padZeros($1), $curator_id); return; }
      else { print "Not a number in a number search for $number<br />\n"; } }

  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"searchResults\">";

  my %hash;
  foreach my $table (@normal_tables) {
    ($oop, my $data) = &getHtmlVar($query, "data_$table");
    next unless ($data);	# skip those with search params
    my $substring = ''; my $case = ''; my $operator = '=';
    ($oop, $substring) = &getHtmlVar($query, "substring_$table");
    ($oop, $case) = &getHtmlVar($query, "case_$table");
    if ($case eq 'on') { $operator = '~*'; }
    elsif ($substring eq 'on') { $operator = '~'; }
    if ($table eq 'author') {
#       print "SELECT joinkey, pap_author FROM pap_author WHERE pap_author IN (SELECT author_id FROM pap_author_index WHERE pap_author_index $operator '$data')<br />\n";
      print "SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index FROM pap_author, pap_author_index WHERE pap_author.pap_author = pap_author_index.author_id AND pap_author_index $operator '$data'<br />\n";
      $result = $dbh->prepare( "SELECT pap_author.joinkey, pap_author.pap_author, pap_author_index.pap_author_index FROM pap_author, pap_author_index WHERE pap_author.pap_author = pap_author_index.author_id AND pap_author_index $operator '$data'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
        $hash{matches}{$row[0]}{$table}++; 
        push @{ $hash{table}{$table}{$row[0]} }, "$row[1] ($row[2])"; } }
    else {
      print "SELECT joinkey, pap_$table FROM pap_$table WHERE pap_$table $operator '$data'<br />\n";
      $result = $dbh->prepare( "SELECT joinkey, pap_$table FROM pap_$table WHERE pap_$table $operator '$data'" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { 
        $hash{matches}{$row[0]}{$table}++; 
        push @{ $hash{table}{$table}{$row[0]} }, $row[1]; } }
  } # foreach my $table (@normal_tables)
  my %matches; 
  foreach my $joinkey (keys %{ $hash{matches} }) {
    my $count = scalar keys %{ $hash{matches}{$joinkey} }; $matches{$count}{$joinkey}++; }
  foreach my $count (reverse sort {$a<=>$b} keys %matches) {
    print "<br />Matches $count<br />\n";
    foreach my $joinkey (sort {$a<=>$b} keys %{ $matches{$count} }) {
#       print "<a href=\"http://tazendra.caltech.edu/~postgres/cgi-bin/paper_editor.cgi?action=Search&data_number=$joinkey&history=$history\">WBPaper$joinkey</a>\n";
      print "<a href=\"paper_editor.cgi?action=Search&data_number=$joinkey&curator_id=$curator_id\">WBPaper$joinkey</a>\n";
      foreach my $table (keys %{ $hash{table} }) {
        next unless $hash{table}{$table}{$joinkey};
        my $data_match = join", ", @{ $hash{table}{$table}{$joinkey} }; 
        if ($table eq 'type') { $data_match = $type_index{$data_match}; }
        print "$table : <font color=\"green\">$data_match</font>\n"; }
      print "<br />\n";
    } # foreach my $joinkey (sort {$a<=>$b} keys %{ $matches{$count} })
  }
  &printFooter();
} # sub search

sub firstPage {
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"firstPage\">";
  my $date = &getDate();
    # using post instead of get makes a confirmation request when javascript reloads the page after a change.  2010 03 12
  print "<form name='form1' method=\"get\" action=\"paper_editor.cgi\">\n";
  print "<table border=0 cellspacing=5>\n";

  print "<tr><td colspan=\"2\">Select your Name : <select name=\"curator_id\" size=\"1\" onChange=\"saveCuratorIdInCookieFromSelect(this)\">\n";
  print "<option value=\"\"></option>\n";
  &populateCurators();

  my $saved_curator = &readSavedCuratorFromCookie();

  my @curator_list = qw( two1823 two101 two38423 two1983 two51134 two8679 two2021 two2987 two42118 two40194 two3111 two324 two363 two28994 two1270 two1 two4055 two12028 two36183 two557 two567 two625 two2970 two1843 two736 two1760 two712 two9133 two480 two1847 two627 two4025 );
#   my @curator_list = ('', 'Juancarlos Chan', 'Wen Chen', 'Jae Cho', 'Paul Davis', 'Stavros Diamantakis', 'Ruihua Fang', 'Jolene S. Fernandes', 'Chris', 'Marie-Claire Harrison', 'Kevin Howe',  'Ranjana Kishore', 'Raymond Lee', 'Jane Mendel', 'Cecilia Nakamura', 'Michael Paulini', 'Gary C. Schindelman', 'Erich Schwarz', 'Paul Sternberg', 'Mary Ann Tuli', 'Kimberly Van Auken', 'Qinghua Wang', 'Xiaodong Wang', 'Karen Yook', 'Margaret Duesbury', 'Tuco', 'Anthony Rogers', 'Theresa Stiernagle', 'Gary Williams' );
  foreach my $joinkey (@curator_list) {                         # display curators in alphabetical (array) order, if IP matches existing ip record, select it
    my $curator = 0;
    if ($curators{two}{$joinkey}) { $curator = $curators{two}{$joinkey}; }
    if ($joinkey eq $saved_curator) { print "<option value=\"$joinkey\" selected=\"selected\">$curator</option>\n"; }
      else { print "<option value=\"$joinkey\" >$curator</option>\n"; } }
  print "</select></td>";
  print "<td colspan=\"2\">Date : $date</td></tr>\n";

  print "<tr><td>&nbsp;</td></tr>\n";

  print "<tr>\n";
  print "<td><input type=submit name=action value=\"Search\"></td>\n";
#   print "<td><input type=\"checkbox\" name=\"history\" value=\"on\">display history (not search history)</td>\n";
  print "</tr>\n";
  foreach my $table ("number", @normal_tables) { 
    my $style = ''; 
    if ( ($table eq 'number') || ($table eq 'status') || ($table eq 'type') ) { $style = 'display: none'; }
    print "<tr><td>$table</td>";
    if ( $table eq 'type' ) {					# for type show dropdown instead of text input
        print "<td><select id=\"data_$table\" name=\"data_$table\">\n";
        print "<option value=\"\"></option>\n";
        foreach my $value (sort {$a<=>$b} keys %type_index) {
          print "<option value=\"$value\">$type_index{$value}</option>\n"; }
        print "</select></td>"; }
      elsif ( ($table eq 'status') || ($table eq 'pubmed_final') || ($table eq 'curation_flags') || ($table eq 'curation_done') || ($table eq 'primary_data') ) {
        my @values = ();
        if ($table eq 'status') { @values = qw( valid invalid ); }
        if ($table eq 'pubmed_final') { @values = qw( final not_final ); }
        if ($table eq 'curation_flags') { @values = qw( author_person emailed_community_gene_descrip non_nematode Phenotype2GO rnai_curation ); }
        if ($table eq 'curation_done') { @values = qw( author_person genestudied gocuration ); }
        if ($table eq 'primary_data') { @values = qw( primary not_primary not_designated ); }
        print "<td><select id=\"data_$table\" name=\"data_$table\">\n";
        print "<option value=\"\"></option>\n";
        foreach my $value (@values) {
          print "<option value=\"$value\">$value</option>\n"; }
        print "</select></td>"; }
      else { print "<td><input size=40 id=\"data_$table\" name=\"data_$table\"></td>\n"; }	# normal tables have input
    if ( $table eq 'number' ) {					# for number show an X to clear the field for Mary Ann approved by Kimberly  2014 06 18
#       print qq(<td><span style="border:1px solid" onclick="document.getElementById('data_$table').value = '';">&nbsp;x&nbsp;</span>&nbsp;&nbsp;<button onclick="document.getElementById('data_$table').value = '';">x</button>\n);
      print qq(<td><button onclick="document.getElementById('data_$table').value = '';">x</button>\n); }
    print "<td style='$style'><input type=\"checkbox\" value=\"on\" name=\"substring_$table\">substring</td>\n";
    print "<td style='$style'><input type=\"checkbox\" value=\"on\" name=\"case_$table\">case insensitive (automatic substring)</td></tr>\n";
  } # foreach my $table ("number", @normal_tables)

  print "<tr><td>&nbsp;</td></tr>\n";
  print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Enter New Papers\"></td></tr>\n";
  print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Enter New Parasite Papers\"></td></tr>\n";
#   print "<tr><td colspan=\"2\"><!-- This is LIVE --> <input type=\"submit\" name=\"action\" VALUE=\"Flag False Positives\"></td></tr>\n";
  print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"RNAi Curation\"></td></tr>\n";
  print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Find Dead Genes\"></td></tr>\n";
  print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Author Gene Curation\"></td></tr>\n";
  print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Person Author Curation\"></td></tr>\n";

  print "</table>\n";
  print "</form>\n";
  &printFooter();
} # sub firstPage



sub makePdfLinkFromPath {
  my ($path) = shift;
  my ($pdf) = $path =~ m/\/([^\/]*)$/;
  my $link = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdf;
  my $data = "<a href=\"$link\" target=\"new\">$pdf</a>"; return $data; }
sub makeNcbiLinkFromPmid {
  my $pmid = shift;
  my ($id) = $pmid =~ m/(\d+)/;
  my $link = 'https://www.ncbi.nlm.nih.gov/pubmed/' . $id; 
  my $data = "<a href=\"$link\" target=\"new\">$pmid</a>"; return $data; }

sub rnaiCuration {
  &printHtmlHeader();
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  print "<input type=\"hidden\" name=\"curator_id\" id=\"curator_id\" value=\"$curator_id\">";
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"rnaiCuration\">";

  &populateCurators();						# for verified yes / no standard name

  my $table_menu = "<tr><td align=center>WBPaperID</td><td align=center>Identifiers</td><td align=center>pdf</td><td align=center>RNAi data</td><td align=center>LS RNAi data</td><td align=center>curate</td></tr>\n";
  print "<table border=0>";
  print $table_menu;

  my %rnai; my %idents; my %pdfs; my %curated; # my %highest;
  $result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE pap_curation_flags = 'rnai_curation'"); $result->execute;
  while (my @row = $result->fetchrow) { $curated{$row[0]} = $row[3]; }
#   my (@not_joinkeys) = keys %curated;
#   my $not_joinkeys = join"', '", @not_joinkeys;

  my %valid_papers; my $valid_papers;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid'"); $result->execute;
  while (my @row = $result->fetchrow) { $valid_papers{$row[0]}++; }
  my (@valid_papers) = keys %valid_papers; $valid_papers = join"', '", @valid_papers;

  $result = $dbh->prepare( "SELECT joinkey, cfp_rnai FROM cfp_rnai WHERE cfp_rnai IS NOT NULL AND joinkey ~ '^0' AND joinkey IN ('$valid_papers'); ");
#   $result = $dbh->prepare( "SELECT joinkey, cfp_rnai FROM cfp_rnai WHERE cfp_rnai IS NOT NULL AND joinkey ~ '^0' AND joinkey NOT IN ('$not_joinkeys'); ");
  $result->execute;
#   while (my @row = $result->fetchrow) { $rnai{$row[0]}{rnai} = $row[1]; }	# populate most valid joinkeys for type
  while (my @row = $result->fetchrow) { $rnai{$row[0]}{rnai}{$row[1]}++; }	# populate most valid joinkeys for type
  $result = $dbh->prepare( "SELECT joinkey, afp_rnai FROM afp_rnai WHERE afp_rnai IS NOT NULL AND joinkey ~ '^0' AND joinkey IN ('$valid_papers'); ");
  $result->execute;
  while (my @row = $result->fetchrow) { $rnai{$row[0]}{rnai}{$row[1]}++; }	# populate most valid joinkeys for type
  $result = $dbh->prepare( "SELECT joinkey, cfp_lsrnai FROM cfp_lsrnai WHERE cfp_lsrnai IS NOT NULL AND joinkey ~ '^0' AND joinkey IN ('$valid_papers'); ");
#   $result = $dbh->prepare( "SELECT joinkey, cfp_lsrnai FROM cfp_lsrnai WHERE cfp_lsrnai IS NOT NULL AND joinkey ~ '^0' AND joinkey NOT IN ('$not_joinkeys'); ");
  $result->execute;
#   while (my @row = $result->fetchrow) { $rnai{$row[0]}{lsrnai} = $row[1]; }	# populate lsrnai valid joinkeys
  while (my @row = $result->fetchrow) { $rnai{$row[0]}{lsrnai}{$row[1]}++; }	# populate lsrnai valid joinkeys
  $result = $dbh->prepare( "SELECT joinkey, afp_lsrnai FROM afp_lsrnai WHERE afp_lsrnai IS NOT NULL AND joinkey ~ '^0' AND joinkey IN ('$valid_papers'); ");
  $result->execute;
  while (my @row = $result->fetchrow) { $rnai{$row[0]}{lsrnai}{$row[1]}++; }	# populate lsrnai valid joinkeys

  my (@joinkeys) = keys %rnai;
  my $joinkeys = join"', '", @joinkeys;

#   $result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE joinkey IN ('$joinkeys') AND pap_curation_flags = 'rnai_curation'"); $result->execute;
#   while (my @row = $result->fetchrow) { $curated{$row[0]} = $row[3]; }
#   $result = $dbh->prepare( "SELECT * FROM pap_curation_flags WHERE joinkey IN ('$joinkeys') ORDER BY pap_order"); $result->execute;
#   while (my @row = $result->fetchrow) { $highest{$row[0]} = $row[2]; }
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN ('$joinkeys')"); $result->execute;
  while (my @row = $result->fetchrow) { 
    my ($data) = &makeNcbiLinkFromPmid($row[1]);
    $idents{$row[0]}{$data}++; }
  $result = $dbh->prepare( "SELECT * FROM pap_electronic_path WHERE joinkey IN ('$joinkeys')"); $result->execute;
  while (my @row = $result->fetchrow) { 
    my ($data) = &makePdfLinkFromPath($row[1]);
    $pdfs{$row[0]}{$data}++; }

  my $alignment = 'center';
  foreach my $joinkey (reverse sort keys %rnai) {
    my ($idents, $pdfs, $rnai_data, $lsrnai_data, $curate_link) = ('', '', '', '', '');
#     if ($rnai{$joinkey}{rnai}) { $rnai_data = $rnai{$joinkey}{rnai}; }
#     if ($rnai{$joinkey}{lsrnai}) { $lsrnai_data = $rnai{$joinkey}{lsrnai}; }
    if ($rnai{$joinkey}{rnai}) { 
      my @rnai_data = sort keys %{ $rnai{$joinkey}{rnai} };
      $rnai_data = join" -- ", @rnai_data; }
    if ($rnai{$joinkey}{lsrnai}) { 
      my @rnai_data = sort keys %{ $rnai{$joinkey}{lsrnai} };
      $lsrnai_data = join" -- ", @rnai_data; }
    if ($idents{$joinkey}) { my @idents = sort keys %{ $idents{$joinkey} }; $idents = join"<br/>", @idents; }
    if ($pdfs{$joinkey}) { my @pdfs = reverse sort keys %{ $pdfs{$joinkey} }; $pdfs = join"<br/>", @pdfs; }
    if ($curated{$joinkey}) { $curate_link = $curators{two}{$curated{$joinkey}}; }
      else {
#         my $order = 1; if ($highest{$joinkey}) { $order = $highest{$joinkey} + 1; }
        $curate_link = "<a href=\"#\" onclick=\"updatePostgresTableField('curation_flags', '$joinkey', 'new', '$curator_id', 'rnai_curation', '', 'nothing'); document.getElementById('td_curate_$joinkey').innerHTML = '$curators{two}{$curator_id}'; return false\">curate</a>"; }
    print "<tr>";
    print "<td align=\"$alignment\"><a href=\"paper_editor.cgi?curator_id=$curator_id&action=Search&data_number=$joinkey\" target=\"new\">$joinkey</a></td>";
    print "<td align=\"$alignment\">$idents</td>";
    print "<td align=\"$alignment\">$pdfs</td>";
    print "<td align=\"$alignment\">$rnai_data</td>";
    print "<td align=\"$alignment\">$lsrnai_data</td>";
    print "<td align=\"$alignment\" id=\"td_curate_$joinkey\">$curate_link</td>";
    print "</tr>";
  } # foreach my $joinkey (reverse sort keys %rnai)
  print $table_menu;

  &printFooter();
} # sub rnaiCuration

sub authorGeneDisplay {			# for Karen
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"authorGeneDisplay\">";
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  #&updateCurator($curator_id);
#   my $who = '';
#   if ($curator_id eq 'two712') { $who = 'Karen Yook'; }
#   if ($curator_id eq 'two1843') { $who = 'Kimberly Van Auken'; }

  my %data; tie %{ $data{when} }, "Tie::IxHash";

  $result = $dbh->prepare( "SELECT * FROM afp_lasttouched ORDER BY afp_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $data{when}{$row[0]} = $row[2]; }
  my $joinkeys = join"', '", keys %{ $data{when} };

  $result = $dbh->prepare( "SELECT * FROM afp_genestudied ORDER BY afp_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $data{author}{$row[0]} = $row[1]; }

  $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE pap_evidence ~ 'Inferred_automatically' AND joinkey IN ('$joinkeys') ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $abstract_read = '';
    if ($row[5] =~ m/\"Abstract read (.*?)\"/) { $abstract_read = $1; }
    $data{inferred}{$row[0]}{"WBGene$row[1]($abstract_read)"}{$row[2]}++; }
  $result = $dbh->prepare( "SELECT * FROM pap_gene WHERE (pap_evidence ~ 'Curator_confirmed' OR pap_evidence ~ 'cfp_genestudied') AND joinkey IN ('$joinkeys') ORDER BY pap_timestamp" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    my $name = &getGeneName($row[1]);
    $data{curator}{$row[0]}{"WBGene$row[1]($name)"}{$row[2]}++; }

# the old tables used to have the name in parenthesis in the gene column, instead of under Manually_connected
#   $result = $dbh->prepare( "SELECT * FROM wpa_gene WHERE wpa_evidence ~ 'Inferred_automatically' AND joinkey IN ('$joinkeys') ORDER BY wpa_timestamp" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq 'valid') { $data{inferred}{$row[0]}{$row[1]}{$row[2]}++; }
#       else { delete $data{inferred}{$row[0]}{$row[1]}{$row[2]}; } }
#   $result = $dbh->prepare( "SELECT * FROM wpa_gene WHERE (wpa_evidence ~ 'Curator_confirmed' OR wpa_evidence ~ 'cfp_genestudied') AND joinkey IN ('$joinkeys') ORDER BY wpa_timestamp" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[3] eq 'valid') { $data{curator}{$row[0]}{$row[1]}{$row[2]}++; }
#       else { delete $data{curator}{$row[0]}{$row[1]}{$row[2]}; } }

  print "<table border=1>\n";
  print "<tr bgcolor='$blue'><td class=\"normal_odd\">WBPaper ID</td><td class=\"normal_odd\">author date</td><td class=\"normal_odd\" width=\"30%\">Inferred_automatically</td><td class=\"normal_odd\" width=\"30%\">Author FP</td><td class=\"normal_odd\" width=\"30%\">Curator confirmed</td></tr>\n";
#   foreach my $joinkey (sort {$data{when}{$b} <=> $data{when}{$a}} keys %{ $data{when} })
  foreach my $joinkey (reverse keys %{ $data{when} }) {
    my $author = ''; my $inferred = ''; my $curator = '';
    my $when = $data{when}{$joinkey};
    $when =~ s/\.[\-\d]+$//;
    if ($data{author}{$joinkey}) { 
      $author = $data{author}{$joinkey};
      if ($author =~ m/^(.{1000})/s) { $author = $1 . " ..."; } }
    if ($data{curator}{$joinkey}) { 
      $curator = join", ", sort keys %{ $data{curator}{$joinkey} }; 
      if ($curator =~ m/^(.{1000})/s) { $curator = $1 . " ..."; } }
    if ($data{inferred}{$joinkey}) { 
      $inferred = join", ", sort keys %{ $data{inferred}{$joinkey} }; 
      if ($inferred =~ m/^(.{1000})/s) { $inferred = $1 . " ..."; } }
    print "<tr bgcolor='$blue'>\n";
#     print "<td valign=\"top\" class=\"normal_odd\"><a href=\"http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_editor.cgi?number=$joinkey&action=Number+%21&curator_name=$who\" target=\"new\">$joinkey</a></td>\n";
    print "<td valign=\"top\" class=\"normal_odd\"><a href=\"paper_editor.cgi?data_number=$joinkey&action=Search&curator_id=$curator_id\" target=\"new\">$joinkey</a></td>\n";
    print "<td valign=\"top\" class=\"normal_odd\">$when</td>\n";
    print "<td valign=\"top\" class=\"normal_odd\">$inferred</td>\n";
    print "<td valign=\"top\" class=\"normal_odd\">$author</td>\n";
    print "<td valign=\"top\" class=\"normal_odd\">$curator</td>\n";
    print "</tr>\n";
  } # foreach my $joinkey (sort {$data{when}{$a} <=> $data{when}{$b}} keys %{ $data{when} })
  print "</table>\n";
  &printFooter();
} # sub authorGeneDisplay


sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '0000000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '000000' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '00000' . $joinkey; }
  elsif ($joinkey < 10000) { $joinkey = '0000' . $joinkey; }
  elsif ($joinkey < 100000) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 1000000) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 10000000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros


#sub updateCurator {
#  my ($joinkey) = @_;
#  my $ip = $query->remote_host();
#  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip' AND joinkey = '$joinkey';" );
#  $result->execute;
#  my @row = $result->fetchrow;
#  unless ($row[0]) {
#    $result = $dbh->do( "DELETE FROM two_curator_ip WHERE two_curator_ip = '$ip' ;" );
#    $result = $dbh->do( "INSERT INTO two_curator_ip VALUES ('$joinkey', '$ip')" );
#    print "IP $ip updated for $joinkey<br />\n"; } }

sub populateCurators {
#   my $result = $conn->exec( "SELECT * FROM two_standardname; " );
  my $result = $dbh->prepare( "SELECT * FROM two_standardname; " );
  $result->execute;
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0];
  } # while (my @row = $result->fetchrow)
} # sub populateCurators

sub populateMonthIndex {
  $month_index{1} = 'January';
  $month_index{2} = 'February';
  $month_index{3} = 'March';
  $month_index{4} = 'April';
  $month_index{5} = 'May';
  $month_index{6} = 'June';
  $month_index{7} = 'July';
  $month_index{8} = 'August';
  $month_index{9} = 'September';
  $month_index{10} = 'October';
  $month_index{11} = 'November';
  $month_index{12} = 'December';
} # sub populateMonthIndex

sub populateValidPaperIndex {
  my $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'valid';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $valid_paper_index{$row[0]} = $row[1]; } }
} # sub populateValidPaperIndex

sub populateTypeIndex {
  my $result = $dbh->prepare( "SELECT * FROM pap_type_index;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($row[0]) { $type_index{$row[0]} = $row[1]; }
  }
#   $result = $dbh->prepare( "SELECT * FROM pap_electronic_type_index;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   while (my @row = $result->fetchrow) {
#     if ($row[0]) { $electronic_type_index{$row[0]} = $row[1]; }
#   }
} # sub populateTypeIndex

sub populateSingleMultiTableTypes {
# unique (single value) tables :  status title journal publisher pages volume year month day pubmed_final primary_data abstract );
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
  
  # multivalue tables :  editor type author affiliation fulltext_url contained_in gene identifier ignore remark erratum_in internal_comment curation_flags 
  
  $multi{'species'}++;
  $multi{'editor'}++;
  $multi{'type'}++;
  $multi{'author'}++;
  $multi{'affiliation'}++;
  $multi{'fulltext_url'}++;
  $multi{'contained_in'}++;
  $multi{'gene'}++;
  $multi{'gene_comp'}++;
  $multi{'identifier'}++;
#   $multi{'ignore'}++;			# getting rid of this table  2011 05 27
  $multi{'remark'}++;
  $multi{'erratum_in'}++;
  $multi{'retraction_in'}++;
  $multi{'internal_comment'}++;
  $multi{'curation_flags'}++;
  $multi{'curation_done'}++;
  $multi{'electronic_path'}++;
  $multi{'author_possible'}++;
  $multi{'author_sent'}++;
  $multi{'author_verified'}++;
} # sub populateSingleMultiTableTypes


sub printHtmlHeader {
  print "Content-type: text/html\n\n";
  my $title = 'Paper Editor';
  my $header = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><HTML><HEAD>';
  $header .= "<title>$title</title>\n";

  $header .= '<link rel="stylesheet" href="../../pub/stylesheets/jex.css" />';
#   $header .= '<link rel="stylesheet" href="https://tazendra.caltech.edu/~azurebrd/stylesheets/jex.css" />';
#   $header .= '<link rel="stylesheet" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/jex.css" />';
#   $header .= '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/fonts/fonts-min.css" />';
#   $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"http://yui.yahooapis.com/2.7.0/build/autocomplete/assets/skins/sam/autocomplete.css\" />";
#   $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdnjs.cloudflare.com/ajax/libs/yui/2.7.0/build/autocomplete/assets/skins/sam/autocomplete.css\" />";
#   $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/autocomplete.css\" />";
  $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"javascript/yui/2.7.0/autocomplete.css\" />";


  $header .= "<style type=\"text/css\">#forcedPersonAutoComplete { width:25em; padding-bottom:2em; } .div-autocomplete { padding-bottom:1.5em; }</style>";

  $header .= '
    <!-- always needed for yui -->
    <script type="text/javascript" src="javascript/yui/2.7.0/yahoo-dom-event.js"></script>
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/yahoo-dom-event.js"></script>-->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/yahoo-dom-event/yahoo-dom-event.js"></script>-->

    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/element/element-min.js"></script>-->

    <!-- for autocomplete calls -->
    <script type="text/javascript" src="javascript/yui/2.7.0/datasource-min.js"></script>
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/datasource-min.js"></script>-->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/datasource/datasource-min.js"></script>-->

    <!-- OPTIONAL: Connection Manager (enables XHR for DataSource)	needed for Connect.asyncRequest -->
    <script type="text/javascript" src="javascript/yui/2.7.0/connection-min.js"></script>
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/connection-min.js"></script>-->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/connection/connection-min.js"></script>-->

    <!-- Drag and Drop source file --> 
    <script src="javascript/yui/2.7.0/dragdrop-min.js" ></script>
    <!--<script src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/dragdrop-min.js" ></script>-->
    <!--<script src="http://yui.yahooapis.com/2.7.0/build/dragdrop/dragdrop-min.js" ></script>-->

    <!-- At least needed for drag and drop easing -->
    <script type="text/javascript" src="javascript/yui/2.7.0/animation-min.js"></script>
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/animation-min.js"></script>-->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/animation/animation-min.js"></script>-->


    <!-- OPTIONAL: JSON Utility (for DataSource) -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/json/json-min.js"></script>-->

    <!-- OPTIONAL: Get Utility (enables dynamic script nodes for DataSource) -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/get/get-min.js"></script>-->

    <!-- OPTIONAL: Drag Drop (enables resizeable or reorderable columns) -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/dragdrop/dragdrop-min.js"></script>-->

    <!-- OPTIONAL: Calendar (enables calendar editors) -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/calendar/calendar-min.js"></script>-->

    <!-- Source files -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/datatable/datatable-min.js"></script>-->

    <!-- Resize not needed to resize data table, just change div height -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/resize/resize.js"></script> -->

    <!-- autocomplete js -->
    <script type="text/javascript" src="javascript/yui/2.7.0/autocomplete-min.js"></script>
    <!--<script type="text/javascript" src="https://tazendra.caltech.edu/~azurebrd/javascript/yui/2.7.0/autocomplete-min.js"></script>-->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/autocomplete/autocomplete-min.js"></script>-->

    <!-- container_core js -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/container/container-min.js"></script>-->

    <!-- form-specific js put this last, since it depends on YUI above -->
    <script type="text/javascript" src="javascript/paper_editor.js"></script>
    <script>
      function setCookie(name, value) { var expiry = new Date(); expiry.setFullYear(expiry.getFullYear() +10); document.cookie = name + "=" + escape(value) + "; path=/; expires=" + expiry.toGMTString(); }
      function saveCuratorIdInCookieFromSelect(selectElement) { var selectedValue = selectElement.value; setCookie("SAVED_CURATOR_ID", selectedValue); }
    </script>
  ';
  $header .= "</head>";
  $header .= '<body class="yui-skin-sam">';
  print $header;
} # printHtmlHeader


