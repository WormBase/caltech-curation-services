#!/usr/bin/env perl

# edit pap_species_index for curated taxon list

# dockerized, but there's a ton of stuff from paper editor that is probably not necessary here, and 
# I don't know what this form's supposed to do, so getting rid of a lot, but it needs cleanup after
# hearing form Kimberly.  2023 04 12



use strict;
use CGI;
use Fcntl;
use Jex;
use DBI;

use Tie::IxHash;
use LWP::Simple;
use POSIX qw(ceil);

# use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
# use pap_match qw( processXmlIds );

use Dotenv -load => '/usr/lib/.env';

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
# my %type_index;				# hash of possible 7 types of paper
# &populateTypeIndex();	
# my %valid_paper_index;			# hash of papers that are valid
# &populateValidPaperIndex();	
# my %month_index;				# hash of possible 7 types of paper
# &populateMonthIndex();	

my @normal_tables = qw( status species electronic_path pubmed_final identifier contained_in erratum_in title author affiliation journal abstract publisher editor pages volume year month day type fulltext_url remark gene curation_flags curation_done internal_comment primary_data );
# my @normal_tables = qw( gene status electronic_path pubmed_final identifier contained_in erratum_in title author affiliation journal abstract publisher editor pages volume year month day type fulltext_url remark curation_flags internal_comment primary_data );

# my %single; my %multi;			# whether tables are single value or multivalue
# &populateSingleMultiTableTypes();

&display();


# my @generic_tables = qw( title publisher journal volume pages year abstract affiliation comments paper );

# my @generic_tables = qw( wpa wpa_identifier wpa_title wpa_publisher wpa_journal wpa_volume wpa_pages wpa_year wpa_date_published wpa_fulltext_url wpa_abstract wpa_affiliation wpa_type wpa_author wpa_hardcopy wpa_comments wpa_editor wpa_nematode_paper wpa_contained_in wpa_contains wpa_keyword wpa_erratum wpa_in_book );



sub display {
  my $action; my $normal_header_flag = 1;

  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  if ($action eq 'Create') { &create(); }
  elsif ($action eq 'Update') { &update(); }
#   elsif ($action eq 'Search') { &search(); }
#   elsif ($action eq 'Merge') { &displayMerge(); }
#   elsif ($action eq 'Page') { &enterNewPapers('page'); }
#   elsif ($action eq 'Enter New Papers') { &enterNewPapers('wormbase'); }
#   elsif ($action eq 'Enter New Parasite Papers') { &enterNewPapers('parasite'); }
#   elsif ($action eq 'Enter PMIDs') { &enterPmids(); }
#   elsif ($action eq 'Enter non-PMID paper') { &enterNonPmids(); }
#   elsif ($action eq 'Confirm Abstracts') { &confirmAbstracts(); }
#   elsif ($action eq 'Find Dead Genes') { &findDeadGenes(); }				# sort by genes, link to each paper per gene
# #   elsif ($action eq 'Flag False Positives') { &flagFalsePositives(); }
# #   elsif ($action eq 'Enter False Positives') { &enterFalsePositives(); }
# #   elsif ($action eq 'Show False Positives') { &showFalsePositives(); }
#   elsif ($action eq 'RNAi Curation') { &rnaiCuration(); }
#   elsif ($action eq 'Person Author Curation') { &personAuthorCuration(); }
#   elsif ($action eq 'Paper Author Person Group') { &paperAuthorPersonGroup(); }
#   elsif ($action eq 'Author Gene Curation') { &authorGeneDisplay(); }			# for Karen
#   elsif ($action eq 'updatePostgresTableField') { &updatePostgresTableField(); }
#   elsif ($action eq 'autocompleteXHR') { &autocompleteXHR(); }

#   elsif ($action eq 'deletePostgresTableField') { &deletePostgresTableField(); }	# use blank &updatePostgresByTableJoinkeyNewvalue(); instead

#   if ($action eq 'Number !') { &pickNumber(); }
#   elsif ($action eq 'Author !') { &pickAuthor(); }
#   elsif ($action eq 'Title !') { &pickTitle(); }
#   else { 1; }
} # sub display


sub update {
  &printHtmlHeader();
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  &updateCurator($curator_id);
  ($oop, my $taxonid) = &getHtmlVar($query, "taxonid");
  ($oop, my $species) = &getHtmlVar($query, "species");
  ($oop, my $oldtaxonid) = &getHtmlVar($query, "oldtaxonid");
  ($oop, my $oldspecies) = &getHtmlVar($query, "oldspecies");
#   print qq(T $taxonid S $species OT $oldtaxonid OS $oldspecies C $curator_id E<br>);
  if ($oldtaxonid) { &pgdelete('taxonid', $oldtaxonid, $curator_id); }
  if ($oldspecies) { &pgdelete('species', $oldspecies, $curator_id); }
  if ($taxonid && $species) { &pginsert($taxonid, $species, $curator_id); }
  &printFooter();
} # sub update

sub pgdelete {
  my ($column, $value, $curator_id) = @_;
  if ($column eq 'taxonid') { 
      print qq(INSERT INTO h_pap_species_index VALUES ('$value', NULL, NULL, '$curator_id');<br/>\n); 
      $dbh->do("INSERT INTO h_pap_species_index VALUES ('$value', NULL, NULL, '$curator_id');"); 
      print qq(DELETE FROM pap_species_index WHERE joinkey = '$value'<br>\n);
      $dbh->do("DELETE FROM pap_species_index WHERE joinkey = '$value'");
    }
    elsif ($column eq 'species') { 
      print qq(INSERT INTO h_pap_species_index VALUES (NULL, '$value', NULL, '$curator_id');<br/>\n); 
      $dbh->do("INSERT INTO h_pap_species_index VALUES (NULL, '$value', NULL, '$curator_id');"); 
      print qq(DELETE FROM pap_species_index WHERE pap_species_index = '$value'<br>\n);
      $dbh->do("DELETE FROM pap_species_index WHERE pap_species_index = '$value'");
    }
} # sub pgdelete

sub pginsert {
  my ($taxonid, $species, $curator_id) = @_;
  print qq(INSERT INTO h_pap_species_index VALUES ('$taxonid', '$species', NULL, '$curator_id')<br/>\n);
  print qq(INSERT INTO pap_species_index VALUES ('$taxonid', '$species', NULL, '$curator_id')<br/>\n);
  $dbh->do("INSERT INTO h_pap_species_index VALUES ('$taxonid', '$species', NULL, '$curator_id')");
  $dbh->do("INSERT INTO pap_species_index VALUES ('$taxonid', '$species', NULL, '$curator_id')");
}

sub create {
  &printHtmlHeader();
  ($oop, my $curator_id) = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  &updateCurator($curator_id);
  ($oop, my $taxonid) = &getHtmlVar($query, "taxonid");
  ($oop, my $species) = &getHtmlVar($query, "species");
  unless ($species) { print "ERROR no species<br />\n"; return; }
  unless ($taxonid) { print "ERROR no taxonid<br />\n"; return; }
  my $lcspecies = lc($species);
  my %pg;
  my $result = $dbh->prepare( "SELECT * FROM pap_species_index WHERE LOWER(pap_species_index) = '$lcspecies';" );
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      $pg{species}{$row[1]}{$row[0]}++;
      $pg{taxonid}{$row[0]}{$row[1]}++; } }
  $result = $dbh->prepare( "SELECT * FROM pap_species_index WHERE joinkey = '$taxonid';" );
  $result->execute;
  while (my @row = $result->fetchrow) {
    if ($row[1]) {
      $pg{species}{$row[1]}{$row[0]}++;
      $pg{taxonid}{$row[0]}{$row[1]}++; } }
  if ( (exists $pg{taxonid}) && exists ($pg{taxonid}{$taxonid}) && exists ($pg{taxonid}{$taxonid}{$species}) ) {
      print qq(Species '$species' already in pap_species_index with taxonid $taxonid.<br />\n); }
    else {
      my $alreadyInPg = 0;
      if ($pg{taxonid}{$taxonid}) { 
        $alreadyInPg++;
        my $alreadySpecies = join", ", sort keys %{ $pg{taxonid}{$taxonid} };
        my $update_link = "species_taxon_editor.cgi?curator_id=$curator_id&action=Update&taxonid=$taxonid&species=$species&oldtaxonid=$taxonid";
        print qq(Taxonid $taxonid already in pap_species_index with species $alreadySpecies. <a href="$update_link">Overwrite with '$species'</a>.<br/>\n); }
      if ($pg{species}{$species}) { 
        $alreadyInPg++;
        my $alreadyTaxonid = join", ", sort keys %{ $pg{species}{$species} };
        my $update_link = "species_taxon_editor.cgi?curator_id=$curator_id&action=Update&taxonid=$taxonid&species=$species&oldspecies=$species";
        print qq(Species '$species' already in pap_species_index with taxonId $alreadyTaxonid. <a href="$update_link">Overwrite with $taxonid</a>.<br/>\n); }
      unless ($alreadyInPg) {
        print qq(Creating mapping of taxonid $taxonid to species '$species'.<br />\n); 
        if ($taxonid && $species) { &pginsert($taxonid, $species, $curator_id); }
      } # unless ($alreadyInPg)
    }
  &printFooter();
}

sub firstPage {
  &printHtmlHeader();
  print "<input type=\"hidden\" name=\"which_page\" id=\"which_page\" value=\"firstPage\">";
  my $date = &getDate();
    # using post instead of get makes a confirmation request when javascript reloads the page after a change.  2010 03 12
  print "<form name='form1' method=\"get\" action=\"species_taxon_editor.cgi\">\n";
  print "<table border=0 cellspacing=5>\n";

  print "<tr><td colspan=\"2\">Select your Name : <select name=\"curator_id\" size=\"1\">\n";
  print "<option value=\"\"></option>\n";
  &populateCurators();
  my $ip = $query->remote_host();                               # select curator by IP if IP has already been used
  my $curator_by_ip = '';
  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip';" ); $result->execute; my @row = $result->fetchrow;
  if ($row[0]) { $curator_by_ip = $row[0]; }

  my @curator_list = qw( two1823 two101 two1983 two8679 two2021 two2987 two42118 two40194 two3111 two324 two363 two28994 two1 two4055 two12028 two36183 two557 two567 two625 two2970 two1843 two736 two1760 two712 two9133 two480 two1847 two627 two4025 );
#   my @curator_list = ('', 'Juancarlos Chan', 'Wen Chen', 'Paul Davis', 'Ruihua Fang', 'Jolene S. Fernandes', 'Chris', 'Marie-Claire Harrison', 'Kevin Howe',  'Ranjana Kishore', 'Raymond Lee', 'Cecilia Nakamura', 'Michael Paulini', 'Gary C. Schindelman', 'Erich Schwarz', 'Paul Sternberg', 'Mary Ann Tuli', 'Kimberly Van Auken', 'Qinghua Wang', 'Xiaodong Wang', 'Karen Yook', 'Margaret Duesbury', 'Tuco', 'Anthony Rogers', 'Theresa Stiernagle', 'Gary Williams' );
  foreach my $joinkey (@curator_list) {                         # display curators in alphabetical (array) order, if IP matches existing ip record, select it
    my $curator = 0;
    if ($curators{two}{$joinkey}) { $curator = $curators{two}{$joinkey}; }
    if ($joinkey eq $curator_by_ip) { print "<option value=\"$joinkey\" selected=\"selected\">$curator</option>\n"; }
      else { print "<option value=\"$joinkey\" >$curator</option>\n"; } }
  print "</select></td>";
  print "<td colspan=\"2\">Date : $date</td></tr>\n";

  print "<tr><td>&nbsp;</td></tr>\n";

  print "<tr><td>taxon ID</td><td><input size=40 id=\"taxonid\" name=\"taxonid\"></td></tr>\n";
  print "<tr><td>species name</td><td><input size=40 id=\"species\" name=\"species\"></td></tr>\n";
  print "<tr><td><input type=submit name=action value=\"Create\"></td>\n";

#   print "<tr>\n";
#   print "<td><input type=submit name=action value=\"Search\"></td>\n";
# #   print "<td><input type=\"checkbox\" name=\"history\" value=\"on\">display history (not search history)</td>\n";
#   print "</tr>\n";
#   foreach my $table ("number", @normal_tables) { 
#     my $style = ''; 
#     if ( ($table eq 'number') || ($table eq 'status') || ($table eq 'type') ) { $style = 'display: none'; }
#     print "<tr><td>$table</td>";
#     if ( $table eq 'type' ) {					# for type show dropdown instead of text input
#         print "<td><select id=\"data_$table\" name=\"data_$table\">\n";
#         print "<option value=\"\"></option>\n";
#         foreach my $value (sort {$a<=>$b} keys %type_index) {
#           print "<option value=\"$value\">$type_index{$value}</option>\n"; }
#         print "</select></td>"; }
#       elsif ( ($table eq 'status') || ($table eq 'pubmed_final') || ($table eq 'curation_flags') || ($table eq 'curation_done') || ($table eq 'primary_data') ) {
#         my @values = ();
#         if ($table eq 'status') { @values = qw( valid invalid ); }
#         if ($table eq 'pubmed_final') { @values = qw( final not_final ); }
#         if ($table eq 'curation_flags') { @values = qw( author_person emailed_community_gene_descrip non_nematode Phenotype2GO rnai_curation ); }
#         if ($table eq 'curation_done') { @values = qw( author_person genestudied gocuration ); }
#         if ($table eq 'primary_data') { @values = qw( primary not_primary not_designated ); }
#         print "<td><select id=\"data_$table\" name=\"data_$table\">\n";
#         print "<option value=\"\"></option>\n";
#         foreach my $value (@values) {
#           print "<option value=\"$value\">$value</option>\n"; }
#         print "</select></td>"; }
#       else { print "<td><input size=40 id=\"data_$table\" name=\"data_$table\"></td>\n"; }	# normal tables have input
#     if ( $table eq 'number' ) {					# for number show an X to clear the field for Mary Ann approved by Kimberly  2014 06 18
# #       print qq(<td><span style="border:1px solid" onclick="document.getElementById('data_$table').value = '';">&nbsp;x&nbsp;</span>&nbsp;&nbsp;<button onclick="document.getElementById('data_$table').value = '';">x</button>\n);
#       print qq(<td><button onclick="document.getElementById('data_$table').value = '';">x</button>\n); }
#     print "<td style='$style'><input type=\"checkbox\" value=\"on\" name=\"substring_$table\">substring</td>\n";
#     print "<td style='$style'><input type=\"checkbox\" value=\"on\" name=\"case_$table\">case insensitive (automatic substring)</td></tr>\n";
#   } # foreach my $table ("number", @normal_tables)
# 
#   print "<tr><td>&nbsp;</td></tr>\n";
#   print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Enter New Papers\"></td></tr>\n";
#   print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Enter New Parasite Papers\"></td></tr>\n";
# #   print "<tr><td colspan=\"2\"><!-- This is LIVE --> <input type=\"submit\" name=\"action\" VALUE=\"Flag False Positives\"></td></tr>\n";
#   print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"RNAi Curation\"></td></tr>\n";
#   print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Find Dead Genes\"></td></tr>\n";
#   print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Author Gene Curation\"></td></tr>\n";
#   print "<tr><td colspan=\"2\"><input type=\"submit\" name=\"action\" VALUE=\"Person Author Curation\"></td></tr>\n";

  print "</table>\n";
  print "</form>\n";
  &printFooter();
} # sub firstPage


sub printHtmlHeader {
  print "Content-type: text/html\n\n";
  my $title = 'Species Taxon Editor';
  my $header = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><HTML><HEAD>';
  $header .= "<title>$title</title>\n";

  $header .= '<link rel="stylesheet" href="http://tazendra.caltech.edu/~azurebrd/stylesheets/jex.css" />';
#   $header .= '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/2.7.0/build/fonts/fonts-min.css" />';
  $header .= "<link rel=\"stylesheet\" type=\"text/css\" href=\"http://yui.yahooapis.com/2.7.0/build/autocomplete/assets/skins/sam/autocomplete.css\" />";


  $header .= "<style type=\"text/css\">#forcedPersonAutoComplete { width:25em; padding-bottom:2em; } .div-autocomplete { padding-bottom:1.5em; }</style>";

  $header .= '
    <!-- always needed for yui -->
    <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/yahoo-dom-event/yahoo-dom-event.js"></script>

    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/element/element-min.js"></script>-->

    <!-- for autocomplete calls -->
    <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/datasource/datasource-min.js"></script>

    <!-- OPTIONAL: Connection Manager (enables XHR for DataSource)	needed for Connect.asyncRequest -->
    <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/connection/connection-min.js"></script> 

    <!-- Drag and Drop source file --> 
    <script src="http://yui.yahooapis.com/2.7.0/build/dragdrop/dragdrop-min.js" ></script>

    <!-- At least needed for drag and drop easing -->
    <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/animation/animation-min.js"></script>


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
    <script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/autocomplete/autocomplete-min.js"></script>

    <!-- container_core js -->
    <!--<script type="text/javascript" src="http://yui.yahooapis.com/2.7.0/build/container/container-min.js"></script>-->

    <!-- form-specific js put this last, since it depends on YUI above -->
    <script type="text/javascript" src="javascript/paper_editor.js"></script>

  ';
  $header .= "</head>";
  $header .= '<body class="yui-skin-sam">';
  print $header;
} # printHtmlHeader

sub populateCurators {
#   my $result = $conn->exec( "SELECT * FROM two_standardname; " );
  my $result = $dbh->prepare( "SELECT * FROM two_standardname; " );
  $result->execute;
  while (my @row = $result->fetchrow) {
    $curators{two}{$row[0]} = $row[2];
    $curators{std}{$row[2]} = $row[0];
  } # while (my @row = $result->fetchrow)
} # sub populateCurators

sub updateCurator {
  my ($joinkey) = @_;
  my $ip = $query->remote_host();
  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip' AND joinkey = '$joinkey';" );
  $result->execute;
  my @row = $result->fetchrow;
  unless ($row[0]) {
    $result = $dbh->do( "DELETE FROM two_curator_ip WHERE two_curator_ip = '$ip' ;" );
    $result = $dbh->do( "INSERT INTO two_curator_ip VALUES ('$joinkey', '$ip')" );
    print "IP $ip updated for $joinkey<br />\n"; } }


__END__

