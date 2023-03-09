#!/usr/bin/perl -w

# new ccc go curation for Kimberly + tair + dicty

# show all results for query, submit curates all in form.  2013 03 19
# editing an annotation gives is the delete flag and creates a new one with the current curator.  
# curated annotations show the curated genename-geneid, component-go-pair, and allow change.
#
# indexed in postgres yuling's sentence-components  in  ccc_componentindex 
#   sentence-geneprod|geneid|uniprot&uniprot<tab>geneprod|geneid|uniprot&uniprot  in   ccc_geneprodindex 
# search filters for AND matches across  sourcefiles, geneprod, paper, component, goterm  based on
#   data indexed in postgres (also  ccc_component_go_index  for curated component-goterm index)
# 2013 05 03

# change "new only" checkbox  to "sentece-curation" dropdown with "search all", "exclude curated", "exclude noncurated"
# clicking a gene shows an extra row
# allow selection of multiple gene products to create multiple annotations
# add goid field that is greyed out that matches values from goterm from obo_ with   namespace: cellular_component
#   store text term in postgres, send goid to ptgo ;  keep search of go term as is with substring matches to 
#   multiple goterms => multiple components
# restrict pair of component-goterm to only show those where the goterm maps to a goid
# write Search code to work with data in postgres
# selecting a geneproduct shows another annotation row (javascript)
# not sure when these changes happened, probably 2013 06 11

# pmids link to pubmed, wbpapers and tair IDs link to tazendra and a firewall-hidden local URL.
# section of sentence display is big bold and red.  2013 10 28
#
# changed font size of sentences to 14pt
# added sub  &printColorKey();  to show the meaning of color and underline for each sentence
# added sub  &printGeneProductLinks($sentenceCounter, $data{$papid}{$section}{$sentnum}{$filename}{geneprod});  to make
# links out to uniprot, wormbase, and dicty for each geneproduct
# search field for goterm now autocompletes based on ccc_component_go_index  2013 10 29

# use Net::Domain to get the hostname to determine whether to use ptgo server as 'test' or 'production'.  2013 11 25


# http://wiki.wormbase.org/index.php/CCC_Form_2.0_Specifications
# http://wiki.wormbase.org/index.php/Specifications_for_WB_gpi_file
# http://wiki.wormbase.org/index.php/Testing_Search_Results_-_20130509
# http://wiki.wormbase.org/index.php/WormBase#Feedback_on_Form_-_dictyBase
#
# http://www.ebi.ac.uk/seqdb/confluence/display/GOAP/Protein2GO+Web+Services

# to make annotations to ptgo, change the GOID to allow testing of a new annotation, change pmid to create new ones
# http://www.ebi.ac.uk/internal-tools/protein2go/InsertAnnotation?userid=test:vanauken@caltech.edu&AC=Q7JPE2&EVIDENCE=IDA&GOID=GO%3A0042643&QUALIFIER&REF_DBC=PMID&REF_ID=23283987&WITH_STR&ANN_EXT&EXTRA_TAXID
# http://www.ebi.ac.uk/internal-tools/protein2go/InsertAnnotation?userid=test:vanauken@caltech.edu&AC=O16850&EVIDENCE=IDA&GOID=GO%3A0005634&QUALIFIER&REF_DBC=PMID&REF_ID=23717214&WITH_STR&ANN_EXT&EXTRA_TAXID
# http://www.ebi.ac.uk/internal-tools/protein2go/InsertAnnotation?userid=test:vanauken@caltech.edu&AC=O16850&EVIDENCE=IPI&GOID=GO%3A0005680&QUALIFIER&REF_DBC=PMID&REF_ID=23717214&WITH_STR=UniProtKB:P81299&ANN_EXT&EXTRA_TAXID
# http://www.ebi.ac.uk/internal-tools/protein2go/InsertAnnotation?userid=test:vanauken@caltech.edu&AC=P81299&EVIDENCE=IPI&GOID=GO%3A0005680&QUALIFIER&REF_DBC=PMID&REF_ID=23717214&WITH_STR=UniProtKB:O16850&ANN_EXT&EXTRA_TAXID


# textpresso bibliography at
# http://textpresso-dev.caltech.edu/celegans//tdb/celegans/txt/bib-all/WBPaper00037556
# http://textpresso-dev.caltech.edu/dicty25/tdb/dicty25/txt/bib-all/19692569
# http://textpresso-dev.caltech.edu/arabidopsis/tdb/arabidopsis/txt/bib-all/11042
#
# textpresso modID to PMID mapping at 
# http://textpresso-dev.caltech.edu/ccc_results/accession

# curator login, maps to mods
# main page, search options, fields, one search button to find all fields
#   checkboxes for annotated and for not annotated (to allow both selected)
#   option of how many annotations to make to a given paper-sentence (say 3)
# search page searches all fields and returns sentences that match and all its
#   annotations regardless of whether the annotation has the search (like 
#   searching for a GO Term and getting all the annotation even those without
#   the matching GO Term).
#  - source_file, paper, gene, component  search sentence files
#  - go term, classification, curator, date, annotation_extension, with_string, p2goID  search postgres
#  - evidence code, qualifier  don't search
# search results with all papers listed at the top as links to anchors in page.
# each paper has own form and submit this paper button
# foreach paper show bibliography and list all sentences
# for each sentence show 1 set, hide all others, if any data in set show next one.
# for each sentence, show the paperID, sentence ID, sentence, classification 
#   multiselect (store this in separate table ?)
# submitting to paper-sentence with blank ID gets new ID, existing pairs already 
#   have an ID
# hide postgres id
# show Gene (list of IDs from textpresso)
# show component free text
# show component (list of terms from textpresso)
# show GO term free text
# show GO term (list from component_go_index mappings)
# evidence code (ida OR ipi)
# qualifiers (not / with) multiselect
# with_string multiselect
# annotation_extension free text
# curator   (display, don't allow manual change)
# p2go ID   (display, don't allow manual change)
# timestamp (display, don't allow manual change)
# in postgres 
# annotations : pg_annotation_id, paperId, sentNum, gene (id), component, go (id), evidence, qualifier, with, annot, curator, p2go, timestamp
# sentences_classification : paperId, sentNum, classification, curator, timestamp
# ?? sentences_to_files : paperId, sentNum, files-pipe-separated
# biblio for paper - generate once, store somewhere

# almost done.  2013 11 14








use strict;
use CGI;
use DBI;
use Jex;
use LWP::Simple;
use Time::HiRes qw(time);
use Tie::IxHash;
use Net::Domain qw(hostname hostfqdn hostdomain);	# only using hostname






my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $query = new CGI;

my $src_file_name = 'good_senteces_file.20070316.1802';
# my $src_directory = '/home2/postgres/work/pgpopulation/ccc_gocuration/sentences/';
# my $src_directory = '/home/azurebrd/public_html/cgi-bin/forms/ccc/source/';
my $src_directory = '/home/acedb/kimberly/ccc/ccc_source/';
my $src_file = $src_directory . $src_file_name;

# my %accession_map;	# mapping of paper accession IDs pmid to modid
# my %textpresso_chars;	# textpresso characters that got converted to underscored codes
# &popTextpressoChars();

my %comp_index;		# component to goterm index that have already been added to postgres
&popCompIndex();	# populate %comp_index;

my %curators;
my %curatorToEmail;
&populateCurators();

my $server_hostname = hostname(); my $ptgoServer = 'test';
if ($server_hostname eq 'tazendra') { $ptgoServer = 'production'; }

my %pgCurated;		# data queried from postgres

my %classificationOptions;
$classificationOptions{"scrambled"}   = "Scrambled sentence";
$classificationOptions{"runon"}       = "Run-on sentence";
$classificationOptions{"falsepos"}    = "False positive";
$classificationOptions{"poslocneggo"} = "Positive for localization, but not for GO";
# my @classificationOptions = ( 'Scrambled sentence', 'Run-on sentence', 'False positive', 'Positive for localization, but not for GO' );
my $maxAnnotationsPerSentence = '10';

my %paperInfo;		# paper information from mod flatfiles from textpresso, map pmid to modid/title/abstract

my %goTermGoId;		# mapping of go terms to go ids, terms are lowercased

# &printHeader('gene_product component goterm');
&process();
# &printFooter();


sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { $action = 'frontpage'; }
  if ($action eq "frontpage") { &frontPage(); }
  elsif ($action eq "Login !") { &searchPage(); }
  elsif ($action eq "List Component-GO Term !") { &listComponentGOTermPage(); }
  elsif ($action eq "Search !") { &searchResultsPage(); }
  elsif ($action eq "Submit") { &submitPage(); }
  elsif ($action eq "autocompleteJQ") { &autocompleteJQ(); }
}

sub printFormOpen { print qq(<form method="post" action="ccc.cgi">\n); }

sub autocompleteJQ {
  my ($var, $type)      = &getHtmlVar($query, 'type');
  ($var, my $term)      = &getHtmlVar($query, 'term');
  print qq(Content-type: text/html\n\n);
  my @matches = ();
  if ($type eq 'goterm') {			# for entering goterms in the annotations, need goid and gotermName
      my $lcterm = lc($term);
      $result = $dbh->prepare( "SELECT * FROM obo_name_goid WHERE LOWER(obo_name_goid) ~ '$lcterm' AND joinkey IN (SELECT joinkey FROM obo_data_goid WHERE obo_data_goid ~ 'cellular_component' AND obo_data_goid !~ 'is_obsolete');" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { push @matches, qq({"item":"label","value":"$row[0] $row[1]"}); }
    }
    elsif ($type eq 'searchGoTermName') {	# for search field, need just the go term name for mapping to components in ccc_component_go_index
      my $lcterm = lc($term);
      $result = $dbh->prepare( "SELECT DISTINCT(ccc_goterm) FROM ccc_component_go_index WHERE LOWER(ccc_goterm) ~ '^$lcterm' ORDER BY ccc_goterm;" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { push @matches, qq({"item":"label","value":"$row[0]"}); }
      $result = $dbh->prepare( "SELECT DISTINCT(ccc_goterm) FROM ccc_component_go_index WHERE LOWER(ccc_goterm) ~ '$lcterm' AND LOWER(ccc_goterm) !~ '^$lcterm' ORDER BY ccc_goterm;" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { push @matches, qq({"item":"label","value":"$row[0]"}); }
    }
  my $matches = join",", @matches; 
  print qq([$matches]\n);
#   print <<"EndOfText";			# sample json format
# Content-type: text/html\n\n
# [{"item":"mylabe1","value":"myvalu1"}, 
# {"item":"mylabe2","value":"myvalu2"}, 
# {"item":"mylabe3","value":"myvalu3"}, 
# {"item":"mylabe4","value":"myvalu4"}, 
# {"item":"mylabe5","value":"myvalu5"}, 
# {"item":"mylabe6","value":"myvalu6"}] 
# EndOfText
} # sub autocompleteJQ

sub submitPage {
  &printHeader('gene_product component goterm');
  &printFormOpen();
  my ($var, $curator)      = &getHtmlVar($query, 'curator');
  my $mod = $curators{$curator};

  my @pgcommands;			# inserts for new data go here
  &populateGoTermGoId(); 		# create mapping of valid goterms to goids

  my $tableClassification = qq(<table border="1");
  $tableClassification   .= qq(<tr>);
  $tableClassification   .= qq(<td>mod</td><td>filename</td><td>papid</td><td>section</td><td>sentnum</td>);
  $tableClassification   .= qq(<td>classification</td><td>comment</td><td>curator</td><td>timestamp</td></tr>);
  my $tableAnnotation     = qq(<table border="1">);
  $tableAnnotation       .= qq(<tr>);
  $tableAnnotation       .= qq(<td>mod</td><td>filename</td><td>papid</td><td>section</td><td>sentnum</td>);
  $tableAnnotation       .= qq(<td>geneprod</td><td>component</td><td>goterm</td><td>evidencecode</td><td>with</td><td>alreadycurated</td><td>valid</td><td>ptgo ID</td><td>curator</td><td>timestamp</td></tr>);
  ($var, my $sentenceCounter)      = &getHtmlVar($query, 'sentenceCounter');
  for my $i (1 .. $sentenceCounter) {
    my $valid = 'valid'; my $timestamp = 'now';		# all new annotations are valid and now
    my ($papid, $section, $sentnum, $filename, $comment, $pgComment, $pgClassification) = ('', '', '', '', '', '', '');
    ($var, $papid)            = &getHtmlVar($query, "papid_$i");
    ($var, $section)          = &getHtmlVar($query, "section_$i");
    ($var, $sentnum)          = &getHtmlVar($query, "sentnum_$i");
    ($var, $filename)         = &getHtmlVar($query, "filename_$i");
    ($var, $comment)          = &getHtmlVar($query, "comment_$i");
    ($var, $pgComment)        = &getHtmlVar($query, "pgComment_$i");
    ($var, $pgClassification) = &getHtmlVar($query, "pgClassification_$i");
#     print qq($i $papid $section $sentnum $filename $comment<br/>);
    my @chosenClassifications;
    foreach my $option (sort keys %classificationOptions) { 
      ($var, my $value)    = &getHtmlVar($query, "${option}_$i");
      if ($value) { push @chosenClassifications, $option; } }
    my $chosenClassifications = join"|", @chosenClassifications;
    if ($chosenClassifications || $comment || $pgComment || $pgClassification) {	# if a value existed or has been entered
      if ( ($comment ne $pgComment) || ($chosenClassifications ne $pgClassification) ) {	# if either value has changed
        push @pgcommands, qq(DELETE FROM ccc_sentenceclassification WHERE ccc_mod = '$mod' AND ccc_file = '$filename' AND ccc_paper = '$papid' AND ccc_section = '$section' AND ccc_sentnum = '$sentnum'; );	# delete classification for that sentence
#       print qq(CHOSE $chosenClassifications COMMENT $comment END<br/>\n); 
        if ($chosenClassifications || $comment) {					# if a value has been entered
          push @pgcommands, qq(INSERT INTO ccc_sentenceclassification VALUES ('$mod', '$filename', '$papid', '$section', '$sentnum', '$chosenClassifications', '$comment', '$curator', CURRENT_TIMESTAMP));	# add curation
          $tableClassification .= qq(<tr>);
          $tableClassification .= qq(<td>$mod</td><td>$filename</td><td>$papid</td><td>$section</td><td>$sentnum</td>);
          $tableClassification .= qq(<td>$chosenClassifications</td><td>$comment</td>);
          $tableClassification .= qq(<td>$curator</td><td>$timestamp</td></tr>); } } }

    ($var, my $pgCuratedAmount)    = &getHtmlVar($query, "pgCuratedAmount_$i");
    if ($pgCuratedAmount) { 
      for my $j (1 .. $pgCuratedAmount) {
        ($var, my $newValid)       = &getHtmlVar($query, "deleteCheckbox_${i}_${j}");
        ($var, my $prevTimestamp)  = &getHtmlVar($query, "pgCuratedTimestamp_${i}_${j}");
        if ($newValid && $prevTimestamp) { 
          push @pgcommands, qq(UPDATE ccc_sentenceannotation SET ccc_valid = '$newValid' WHERE ccc_timestamp = '$prevTimestamp' AND ccc_mod = '$mod' AND ccc_file = '$filename' AND ccc_paper = '$papid' AND ccc_section = '$section' AND ccc_sentnum = '$sentnum';);
        } # if ($newValid && $prevTimestamp)
      } # for my $j (1 .. $pgCuratedAmount)
    } # if ($pgCuratedAmount) 

    for my $j (1 .. $maxAnnotationsPerSentence) {
      my $snumRnum = $i . '_' . $j;
      my ($pair, $component, $component_new, $component_list, $goterm, $evidencecode, $with, $alreadycurated) = ('', '', '', '', '', '', '', '', '' );
      my (@geneprods)          = &getHtmlSelectVars($query, "geneprod_$snumRnum");	# allow multiple gene products
      ($var, $pair)            = &getHtmlVar($query, "pair_$snumRnum");
      ($var, $component_new)   = &getHtmlVar($query, "component_new_$snumRnum");
      ($var, $component_list)  = &getHtmlVar($query, "component_list_$snumRnum");
      ($var, $goterm)          = &getHtmlVar($query, "goterm_$snumRnum");
      ($var, $evidencecode)    = &getHtmlVar($query, "evidencecode_$snumRnum");
      ($var, $with)            = &getHtmlVar($query, "with_$snumRnum");
      ($var, $alreadycurated)  = &getHtmlVar($query, "alreadycurated_$snumRnum");
      my $annotcomment = 'NULL'; my $ptgoid = 'NULL';	# for now these values are always null
      if ($component_new) { $component = $component_new; }
        elsif ($component_list) { $component = $component_list; }
      unless ($component && $goterm) {
        if ($pair) { ($component, $goterm) = split/ -- /, $pair; } }
# print qq( G $geneprod C $component G $goterm EC $evidencecode E <br/> );
      my $goid = ''; if ($goterm =~ m/(GO:\d+)/) { $goid = $1; }
      my $gotermName = $goterm; if ($goterm =~ m/(GO:\d+) /) { $gotermName =~ s/GO:\d+ //; }
      my $ptgoUser = $curatorToEmail{$curator};
      foreach my $geneprod (@geneprods) {
        if ($geneprod && $component && $goid && $evidencecode) {
          my $ptgoId = 'notSent'; my $bgcolor = 'white';
          if ($ptgoUser) {
            my @ptgoFields = ();
            push @ptgoFields, "userid=$ptgoServer:$ptgoUser"; 
            my ($ac) = $geneprod =~ m/UniProtKB:(\w+)/;
            push @ptgoFields, "AC=$ac"; 
            push @ptgoFields, "EVIDENCE=$evidencecode"; 
            push @ptgoFields, "GOID=$goid"; 
            push @ptgoFields, "QUALIFIER"; 
            push @ptgoFields, "REF_DBC=PMID"; 
            my ($refId) = $papid =~ m/(\d+)/;
            push @ptgoFields, "REF_ID=$refId"; 
            if ($with) { push @ptgoFields, "WITH_STR=$with"; } else { push @ptgoFields, "WITH_STR"; }
            push @ptgoFields, "ANN_EXT"; 
            push @ptgoFields, "EXTRA_TAXID"; 
            my $ptgoFields = join"&", @ptgoFields;
            my $url = 'http://www.ebi.ac.uk/internal-tools/protein2go/InsertAnnotation?' . $ptgoFields;
#             print "URL <a href=\"$url\">$url</a> URL<br>";
            my ($ptgoPage) = get $url;		# LWP::Simple 
#             my $copy = $ptgoPage; $copy =~ s/</&lt;/g; print "\nPTGO $copy PTGO\n";	# print copy of &lt;-converted xml to screen

            if ($ptgoPage =~ m/<add_annotation ID="(\d+)" status="success"\/?>/) { $ptgoId = $1; }
              elsif ($ptgoPage =~ m/<add_annotation status="error">/) { 
                if ($ptgoPage =~ m/<error message=".*?"\/?>/) {
                  my (@errors) = $ptgoPage =~ m/<error message="(.*?)"\/?>/g; $ptgoId = join" | ", @errors; $bgcolor = 'red'; } }
              else { $ptgoId = "unaccounted for XML in ptgo"; $bgcolor = 'red'; }
          } # if ($ptgoUser)
          unless ($comp_index{$component}{$gotermName}) {		# add to  ccc_component_go_index  if it's a new entry
            push @pgcommands, qq(INSERT INTO ccc_component_go_index VALUES ('$component', '$gotermName'));
#             print qq(INSERT INTO ccc_component_go_index VALUES ('$component', '$gotermName')<br/>);
            $comp_index{$component}{$gotermName}++; }
          if ($alreadycurated || ($bgcolor eq 'white') ) {				# add to postgres if it was already curated, or ptgo didn't give an error message
            push @pgcommands, qq(INSERT INTO ccc_sentenceannotation VALUES ('$mod', '$filename', '$papid', '$section', '$sentnum', '$geneprod', '$component', '$goterm', '$evidencecode', '$with', '$alreadycurated', NULL, '$valid', '$ptgoId', '$curator', CURRENT_TIMESTAMP)); }
          $tableAnnotation .= qq(<tr style="background-color: $bgcolor">);
          $tableAnnotation .= qq(<td>$mod</td><td>$filename</td><td>$papid</td><td>$section</td><td>$sentnum</td>);
          $tableAnnotation .= qq(<td>$geneprod</td><td>$component</td><td>$goterm</td><td>$evidencecode</td><td>$with</td><td>$alreadycurated</td><td>$valid</td><td>$ptgoId</td>);
          $tableAnnotation .= qq(<td>$curator</td><td>$timestamp</td></tr>);
        } # if ($geneprod && $component && $goterm && $evidencecode)
      } # foreach my $geneprod (@geneprods)
    } # for my $i (1 .. $maxAnnotationsPerSentence)
  } # for my $i (1 .. $sentenceCounter)
  $tableClassification .= qq(</table>);
  $tableAnnotation .= qq(</table>);
  print qq($tableClassification\n);
  print qq($tableAnnotation\n);
  print qq(</form>);

  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand<br/>\n);
# UNCOMMENT TO POPULATE
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)

  &searchResultsSection();
  &printFooter();
} # sub submitPage

sub searchResultsPage {
  &printHeader('gene_product component goterm');
  &searchResultsSection();
  &printFooter();
} # sub searchResultsPage

sub searchResultsSection {
  &printFormOpen();
  my ($var, $curator)      = &getHtmlVar($query, 'curator');
  my $mod = $curators{$curator};
  my $src_dir = $src_directory . $mod;
  ($var, my $papersToShow) = &getHtmlVar($query, 'papersToShow');
  ($var, my $newOnly)      = &getHtmlVar($query, 'newOnly');	# all exclude_curated exclude_noncurated
# CONFIRMED : filtering out curated/noncurated works at the sentence level, not paper
  my (@sourcefiles)        = &getHtmlSelectVars($query, 'sourcefiles');
  ($var, my $geneprod)     = &getHtmlVar($query, 'geneprod');
  ($var, my $paper)        = &getHtmlVar($query, 'paper');
  ($var, my $annotcurator) = &getHtmlVar($query, 'annotcurator');
  ($var, my $annotdate)    = &getHtmlVar($query, 'annotdate');
  ($var, my $component)    = &getHtmlVar($query, 'component');
  ($var, my $goterm)       = &getHtmlVar($query, 'goterm');
  unless ($geneprod)         { $geneprod = '';     }
  unless ($paper)            { $paper = '';        }
  unless ($annotcurator)     { $annotcurator = ''; }
  unless ($annotdate)        { $annotdate = '';    }
  unless ($component)        { $component = '';    }
  unless ($goterm)           { $goterm = '';       }
  print qq(<input type="hidden" name="curator" value="$curator">\n);
  print qq(<table border="0">);

  &populateGoTermGoId(); 		# create mapping of valid goterms to goids for display pairs

  my %data;
  if (scalar @sourcefiles < 1) { (@sourcefiles) = <$src_dir/20*>; }	# if none selected, use all for that mod
  my @pgquery_sourcefiles;
  foreach my $infile (reverse @sourcefiles) {
    my $filename = $infile; $filename =~ s/$src_dir\///g; push @pgquery_sourcefiles, $filename; }
  my $pgquery_sourcefiles = join"','", @pgquery_sourcefiles;
  my $matchesCount = 0;

  my $searchParametersAmount = 0;
  my %searchResults;				# for all search parameters : file / paper / section / sentnum / found-type
  my %sentenceIndices;				# for sentence-source or postgres indices : paper / section / sentnum / file / index -> data
  my $geneprodPostgresPart = '';		# add restriction if searching for specific terms, otherwise find all
  if ($geneprod) { 
    my $lc_geneprod = lc($geneprod);		# make search case insensitive
    $geneprodPostgresPart = qq( AND LOWER(ccc_geneprodindex) ~ '$lc_geneprod' ); }
  $searchParametersAmount++;			# count this as being a search parameter, even if searching for blank
  $result = $dbh->prepare( "SELECT * FROM ccc_geneprodindex WHERE ccc_mod = '$mod' AND ccc_file IN ('$pgquery_sourcefiles') $geneprodPostgresPart ORDER BY ccc_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow()) { 
    my ($mod, $filename, $paper, $section, $sentnum, $data, $timestamp) = @row;
    $sentenceIndices{$paper}{$section}{$sentnum}{$filename}{geneprod} = $data;
    $searchResults{$filename}{$paper}{$section}{$sentnum}{geneprod}++;
  } # while (my @row = $result->fetchrow())

  my $componentPostgresPart = ''; my $lc_component = ''; if ($component) { $lc_component = lc($component); }
  $searchParametersAmount++;		# always search all components to index all components
  $result = $dbh->prepare( "SELECT * FROM ccc_componentindex WHERE ccc_mod = '$mod' AND ccc_file IN ('$pgquery_sourcefiles') ORDER BY ccc_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow()) { 
    my ($mod, $filename, $paper, $section, $sentnum, $data, $timestamp) = @row;
    $sentenceIndices{$paper}{$section}{$sentnum}{$filename}{component} = $data;		# always index all components
    if ($data =~ m/$lc_component/i) {	# if there is a search component, add to %searchResults
      $searchResults{$filename}{$paper}{$section}{$sentnum}{component}++; }
  } # while (my @row = $result->fetchrow())
      # find the sentence if it's been annotated to a component substring, skip if already found in textpresso indices ; need in case manual component

  if ($goterm) {
    $searchParametersAmount++;
    my $lc_goterm = lc($goterm); my %components;	# match the curated component-go index to the curator's go term, and get components
    $result = $dbh->prepare( "SELECT * FROM ccc_component_go_index WHERE LOWER(ccc_goterm) ~ '$lc_goterm'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow()) {
      next unless $row[0]; next unless $row[1]; $components{$row[0]}++; }
    foreach my $component (sort keys %components) {
      print "GO TERM $goterm matches with COMPONENT $component<br/>\n";
      my $lc_component = lc($component);		# match each component on the curated component-go index to the index of all sentence-components
      $result = $dbh->prepare( "SELECT * FROM ccc_componentindex WHERE ccc_mod = '$mod' AND ccc_file IN ('$pgquery_sourcefiles') AND LOWER(ccc_componentindex) ~ '$lc_component' ORDER BY ccc_timestamp DESC;" );
#       print "SELECT * FROM ccc_componentindex WHERE ccc_mod = '$mod' AND ccc_file IN ('$pgquery_sourcefiles') AND LOWER(ccc_componentindex) ~ '$lc_component' ORDER BY ccc_timestamp DESC;<br/>\n" ;
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow()) {
        my ($mod, $filename, $paper, $section, $sentnum, $data, $timestamp) = @row;
        my (@data) = split/\|/, $data; my $match = 0;	# it's a match if it's an exact match of an indexed sentence-component term, not a substring match of all terms
        foreach my $sent_component (@data) { if ($component eq $sent_component) { $match++; } }
        if ($match > 0) {
          $searchResults{$filename}{$paper}{$section}{$sentnum}{goterm}++; } }
    } # foreach my $component (sort keys %components)
  } # if ($goterm)

  if ($paper) {
    $searchParametersAmount++;
    my $lc_paper = lc($paper);
    $result = $dbh->prepare( "SELECT * FROM ccc_geneprodindex WHERE LOWER(ccc_paper) ~ '$lc_paper'" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow()) {
      my ($mod, $filename, $paper, $section, $sentnum, $data, $timestamp) = @row;
      $searchResults{$filename}{$paper}{$section}{$sentnum}{paper}++; } }

  if ($annotcurator) { $searchParametersAmount++; }	# if these have been searched, add to search amounts
  if ($annotdate) { $searchParametersAmount++; }	# if these have been searched, add to search amounts
  my %pgAnnotated;					# sentences annotated in postgres, to exclude with $newOnly flag in sentence-curation field
  $result = $dbh->prepare( "SELECT * FROM ccc_sentenceannotation WHERE ccc_mod = '$mod' AND ccc_file IN ('$pgquery_sourcefiles') ORDER BY ccc_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow()) { 
    my ($mod, $filename, $paper, $section, $sentnum, $geneprod, $pgcomponent, $pggoterm, $evidencecode, $with, $alreadycurated, $comment, $valid, $ptgoid, $pgcurator, $pgtimestamp) = @row;
    if ($annotdate) { if ($pgtimestamp =~ m/$annotdate/) { $searchResults{$filename}{$paper}{$section}{$sentnum}{annotdate}++; } }
    if ($annotcurator) { if ($pgcurator =~ m/$annotcurator/i) { $searchResults{$filename}{$paper}{$section}{$sentnum}{annotcurator}++; } }
    if ($component) { if ($pgcomponent =~ m/$component/i) { $searchResults{$filename}{$paper}{$section}{$sentnum}{component}++; } }
    if ($goterm) { if ($pggoterm =~ m/$goterm/i) { $searchResults{$filename}{$paper}{$section}{$sentnum}{goterm}++; } }
    $pgAnnotated{$filename}{$paper}{$section}{$sentnum}++; 
  } # while (my @row = $result->fetchrow())
  my %pgClassified;					# sentences annotated in postgres, to exclude with $newOnly flag in sentence-curation field
  $result = $dbh->prepare( "SELECT * FROM ccc_sentenceclassification WHERE ccc_mod = '$mod' AND ccc_file IN ('$pgquery_sourcefiles') ORDER BY ccc_timestamp DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow()) { 
    my ($mod, $filename, $paper, $section, $sentnum, $pgclassification, $pgcomment, $pgcurator, $pgtimestamp) = @row;
    $pgClassified{$filename}{$paper}{$section}{$sentnum}++; 
  } # while (my @row = $result->fetchrow())

  my %good;
  foreach my $filename (sort keys %searchResults) {
    foreach my $paper (sort keys %{ $searchResults{$filename} }) {
      foreach my $section (sort keys %{ $searchResults{$filename}{$paper} }) {
        foreach my $sentnum (sort keys %{ $searchResults{$filename}{$paper}{$section} }) {
            # if sentence-curation $newOnly set to exclude, skip if %pgAnnotated corresponds
          next if (($newOnly eq 'exclude_curated') && ($pgClassified{$filename}{$paper}{$section}{$sentnum} || $pgAnnotated{$filename}{$paper}{$section}{$sentnum}) );
          next if (($newOnly eq 'exclude_noncurated') && !( $pgClassified{$filename}{$paper}{$section}{$sentnum} || $pgAnnotated{$filename}{$paper}{$section}{$sentnum}) );

          my @searchParametersMatches = keys %{ $searchResults{$filename}{$paper}{$section}{$sentnum} };
          if (scalar @searchParametersMatches == $searchParametersAmount) {
            foreach my $searchParameter (sort keys %{ $searchResults{$filename}{$paper}{$section}{$sentnum} }) {
              $good{$paper}{$section}{$sentnum}{$filename}++;
            } # foreach my $searchParameter (sort keys %{ $searchResults{$filename}{$paper}{$section}{$sentnum} })
          } # if (scalar @searchParametersMatches == $searchParametersAmount)

        } # foreach my $sentnum (sort keys %{ $searchResults{$filename}{$paper}{$section} })
      } # foreach my $section (sort keys %{ $searchResults{$filename}{$paper} })
    } # foreach my $paper (sort keys %{ $searchResults{$filename} })
  } # foreach my $filename (sort keys %searchResults)

  my $in_papers = join"','", sort keys %good;
  $result = $dbh->prepare( "SELECT * FROM ccc_sentenceclassification WHERE ccc_paper IN ('$in_papers');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow()) {
    my ($mod, $file, $paper, $section, $sentnum, $classifications, $comment, $rowcurator, $timestamp) = @row;
    $pgCurated{$paper}{$section}{$sentnum}{$file}{classification} = $classifications;
    $pgCurated{$paper}{$section}{$sentnum}{$file}{comment} = $comment;
  }
  $result = $dbh->prepare( "SELECT * FROM ccc_sentenceannotation WHERE ccc_paper IN ('$in_papers');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow()) {
    my $mod = shift @row; my $file = shift @row; my $paper = shift @row; my $section = shift @row; my $sentnum = shift @row;
    push @{ $pgCurated{$paper}{$section}{$sentnum}{$file}{curated} }, \@row;
  }

  my %sourceFilesToRead;
  my $paperMatchCount = 0; my $sentenceMatchCount = 0;		# papers, sentences that match
  foreach my $paper (sort keys %good) { 
    $paperMatchCount++;
    foreach my $section (sort keys %{ $good{$paper} }) {
      foreach my $sentnum (sort keys %{ $good{$paper}{$section} }) {
        $sentenceMatchCount++; 
        foreach my $filename (sort keys %{ $good{$paper}{$section}{$sentnum} }) { $sourceFilesToRead{$filename}++; }
  } } }

  foreach my $filename (sort keys %sourceFilesToRead) {
    my $infile = $src_dir . '/' . $filename;
    open (IN, "<$infile") or die "Cannot open $infile : $!";
    while (my $line = <IN>) {
      chomp $line;
      my ($score, $pap, $geneprods, $components, $sentence) = split/\t/, $line;
      my ($paptype, $papnum, $section, $sentnum) = split/:/, $pap;
      my $paper = $paptype . ':' . $papnum;
      if ( $good{$paper} ) {					# only checking deepest creates hash keys
        if ( $good{$paper}{$section} ) {
          if ( $good{$paper}{$section}{$sentnum} ) {
            if ( $good{$paper}{$section}{$sentnum}{$filename} ) {
              $sentenceIndices{$paper}{$section}{$sentnum}{$filename}{sentence} = $sentence;  } } } }
    } # while (my $line = <IN>)
    close (IN) or die "Cannot close $infile : $!";
  } # foreach my $filename (sort keys %sourceFilesToRead)

  &populatePaperInfo($mod);

  my $papersShown = 0;
  my $sentenceCounter = 0;
  my $toPrint = '';
  my $paperHrefs = '';
  foreach my $papid (sort keys %good) {
    $papersShown++;
    last if ($papersShown > $papersToShow);
    $paperHrefs .= qq(<a href="#$papid">go to $papid</a><br/>\n);
    $toPrint .= qq(<table border="1" style="border-color: blue">);
    my $modid    = "textpresso does not have a ModID for $papid";
    my $title    = "textpresso does not have a ModID for $papid";
    my $abstract = "textpresso does not have a ModID for $papid";
    if ($paperInfo{$papid}{modid})    { $modid    = $paperInfo{$papid}{modid};    } 
    if ($paperInfo{$papid}{title})    { $title    = $paperInfo{$papid}{title};    }
    if ($paperInfo{$papid}{abstract}) { $abstract = $paperInfo{$papid}{abstract}; } 
    my $pubmedLink = $papid; if ($pubmedLink =~ m/PMID:(\d+)/) { $pubmedLink = qq(<a href="http://www.ncbi.nlm.nih.gov/pubmed/$1" target="new">$papid</a>); }
    my $modPaperLink = $modid; 
    if ($modid =~ m/WBPaper(\d+)/) { $modPaperLink = qq(<a href="http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/paper_display.cgi?action=Search+!&data_number=$1" target="new">$modid</a>); }
      elsif ($modid =~ m/TAIR:(\d+)/) { $modPaperLink = qq(<a href="http://lu:8080/pubsearch/DisplayArticle?article_id=$1" target="new">$modid</a>); }
    $toPrint .= qq(<tr><td><a name="$papid"></a>paper $pubmedLink $modPaperLink <input type="submit" name="action" value="Submit"></td></tr>\n);
    $toPrint .= qq(<tr><td style="background-color: #FFCCCC">Title : $title</td</tr>);
    $toPrint .= qq(<tr><td style="background-color: #FFCCCC">Abstract : $abstract</td</tr>);

    foreach my $section (sort keys %{ $good{$papid} }) {
      foreach my $sentnum (sort keys %{ $good{$papid}{$section} }) {
        foreach my $filename (sort keys %{ $good{$papid}{$section}{$sentnum} }) {
          $sentenceCounter++;
          $toPrint .= &showSentCuration(\%sentenceIndices, $papid, $section, $sentnum, $filename, $sentenceCounter );
        } # foreach my $filename (sort keys %{ $good{$papid}{$section}{$sentnum} })
      } # foreach my $sentnum (sort keys %{ $good{$papid}{$section} })
    } # foreach my $section (sort keys %{ $good{$papid} })
    $toPrint .= qq(</table>);
  } # foreach my $papid (sort keys %good)
  print qq(<input type="hidden" id="sentenceCounter" name="sentenceCounter" value="$sentenceCounter">\n);
  print qq(<input type="hidden" id="maxAnnotationsPerSentence" name="maxAnnotationsPerSentence" value="$maxAnnotationsPerSentence">\n);	# for javascript autocomplete

  &printSearchTable($curator, \@sourcefiles, $geneprod, $paper, $annotcurator, $annotdate, $component, $goterm, $newOnly, $papersToShow);
  my $papersDisplayed = 'all'; if ($papersToShow < $paperMatchCount) { $papersDisplayed = $papersToShow; }
  print qq(The above search has $paperMatchCount papers with $sentenceMatchCount sentences, here are $papersDisplayed papers :<br/>\n);

  print $paperHrefs;
  print qq(<table border="1" style="border-color: blue">);
  print $toPrint;
  print "<br>$curator";
  print qq(</table>);
  print qq(</form>);
  &printFooter();
} # sub searchResultsSection

sub populatePaperInfo {
  my ($mod) = @_;
  my $infile = $src_directory . $mod . '/pmid_data.' . $mod;
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (<IN>) { chomp;
    my ($pmid, $modid, $title, $abstract) = split/\t/, $_;
    $paperInfo{$pmid}{modid}    = $modid;
    $paperInfo{$pmid}{title}    = $title;
    $paperInfo{$pmid}{abstract} = $abstract;
  } # while (<IN>) 
  close (IN) or die "Cannot close $infile : $!";
} # sub populatePaperInfo

sub populateGoTermGoId {
  my $start = &time();
  $result = $dbh->prepare( "SELECT * FROM obo_name_goid WHERE joinkey IN (SELECT joinkey FROM obo_data_goid WHERE obo_data_goid ~ 'cellular_component' AND obo_data_goid !~ 'is_obsolete');" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { my $lcname = lc($row[1]); $goTermGoId{$lcname} = $row[0]; }	# .87 sec with lc
  my $end = &time(); my $diff = $end - $start; print "Reading GO name to ID mappings took $diff seconds<br/>";
} # sub populateGoTermGoId

sub listComponentGOTermPage {
  &printHeader('gene_product component goterm');
  &populateGoTermGoId(); 		# create mapping of valid goterms to goids
  print qq(<a href="ccc.cgi">front page</a>);
  print qq(<table>);
  print "<tr><td>component</td><td>GO Term</td><td>GO ID</td></tr>\n";
  foreach my $comp (sort keys %comp_index) {
    foreach my $goterm (sort keys %{ $comp_index{$comp} }) {
      my $fontcolor = 'red'; my $goid = 'no go id found';
      my $lc_goterm = lc($goterm); 
      if ($goTermGoId{$lc_goterm}) { $goid = $goTermGoId{$lc_goterm}; $fontcolor = 'black'; }
      print qq(<tr style='color: $fontcolor'><td>$comp</td><td>$goterm</td><td>$goid</td></tr>\n);
    } # foreach my $goterm (sort keys %{ $comp_index{$comp} })
  } # foreach my $comp (sort keys %comp_index)
  print qq(<table>);
  &printFooter();
} # sub listComponentGOTermPage

sub searchPage {
  &printHeader('gene_product component goterm');
  &printFormOpen();
  my ($var, $curator) = &getHtmlVar($query, 'curator');
  unless ($curator) { print "You must choose a curator<br>\n"; &frontPage(); last; }
  print qq(<input type="hidden" name="curator" value="$curator">\n);
  &printSearchTable($curator);
  print qq(</table>);
  print qq(</form>);
  &printFooter();
} # sub searchPage

sub printSearchTable {
  my ($curator, $sourcefilesRef, $geneprod, $paper, $annotcurator, $annotdate, $component, $goterm, $newOnly, $papersToShow) = @_;
  my %chosenSourceFiles; foreach (@$sourcefilesRef) { $chosenSourceFiles{$_}++; }
  print qq(<table border="0">);
  print qq(<tr><td>search</td><td><input type="submit" name="action" value="Search !"></td></tr>\n); 
  print qq(<tr><td>sentence-curation</td><td><select name="newOnly" size="1">);
  my %newOnlyHash; tie %newOnlyHash, "Tie::IxHash";
  $newOnlyHash{"all"} = "search all";
  $newOnlyHash{"exclude_curated"} = "exclude curated";
  $newOnlyHash{"exclude_noncurated"} = "exclude noncurated";
  foreach my $option_value (keys %newOnlyHash) {
    my $selected = '';
    if ($newOnly eq $option_value) { $selected = 'selected="selected"'; } 
    print qq(<option value="$option_value" $selected>$newOnlyHash{$option_value}</option>); }
  print qq(</select></td></tr>\n);
  print qq(</tr>\n);
  print qq(<tr><td>papers to show</td>);
  unless ($papersToShow) { $papersToShow = '10'; }
  print qq(<td><input name="papersToShow" value="$papersToShow"></td>);
  print qq(</tr>\n);
  my $mod = $curators{$curator};
  my $src_dir = $src_directory . $mod;
  my (@files) = <$src_dir/20*>;
  my $sou_size = '10';
  print qq(<tr><td>source</td><td><select name="sourcefiles" size="$sou_size" multiple="multiple">);
  foreach my $file (reverse @files) { 
    my $filename = $file;
    $filename =~ s/$src_dir\///; 
    my $selected = ""; if ($chosenSourceFiles{$file}) { $selected = qq(selected="selected"); }
    print qq(<option value="$file" $selected>$filename</option>); }
  print qq(</select></td></tr>\n);
  print qq(<tr><td>gene product</td>);
  print qq(<td><input name="geneprod" value="$geneprod"></td>);
  print qq(</tr>\n);
  print qq(<tr><td>paper</td>);
  print qq(<td><input name="paper" value="$paper"></td>);
  print qq(</tr>\n);
  print qq(<tr><td>annotation curator</td>);
  print qq(<td><input name="annotcurator" value="$annotcurator"></td>);
  print qq(</tr>\n);
  print qq(<tr><td>annotation date</td>);
  print qq(<td><input name="annotdate" value="$annotdate"></td>);
  print qq(</tr>\n);
  print qq(<tr><td>component</td>);
  print qq(<td><input name="component" value="$component"></td>);
  print qq(</tr>\n);
  print qq(<tr><td>go term</td>);
  print qq(<td><input id="searchGoTermName" name="goterm" value="$goterm"></td>);
  print qq(</tr>\n);
  print "$curator $mod $src_dir";
  print qq(<tr><td>search</td><td><input type="submit" name="action" value="Search !"></td></tr>\n); 
  print qq(</table>);
} # sub printSearchTable
  
sub frontPage {
  &printHeader('gene_product component goterm');
  &printFormOpen();
  my $cur_size = scalar keys %curators;
  print qq(<select name="curator" size="$cur_size">);
  foreach my $curator (sort keys %curators) { print "<option>$curator</option>"; }
  print qq(</select><br/>\n);
  print qq(<input type="submit" name="action" value="Login !"><br/>\n); 
  print qq(<input type="submit" name="action" value="List Component-GO Term !">\n); 
  print qq(</form>);
  &printFooter();
} # sub frontPage

sub showSentCuration {
  my ($dataHashRef, $papid, $section, $sentnum, $filename, $sentenceCounter) = @_;
  my $toPrint = '';
  my %data = %$dataHashRef;
  my $sentence          = ''; if ($data{$papid}{$section}{$sentnum}{$filename}{sentence}) { $sentence = $data{$papid}{$section}{$sentnum}{$filename}{sentence}; }
  my $comment           = ''; if ($pgCurated{$papid}{$section}{$sentnum}{$filename}{comment}) { $comment = $pgCurated{$papid}{$section}{$sentnum}{$filename}{comment}; }
  my $classification    = ''; if ($pgCurated{$papid}{$section}{$sentnum}{$filename}{classification}) { $classification = $pgCurated{$papid}{$section}{$sentnum}{$filename}{classification}; }
  if ($comment) {        $toPrint .= qq(<input type="hidden" name="pgComment_$sentenceCounter" value="$comment">); }
  if ($classification) { $toPrint .= qq(<input type="hidden" name="pgClassification_$sentenceCounter" value="$classification">); }
  
  my ($color_converted_sentence) = &convertSentenceXmlToSpans($sentence);
  $toPrint .= "<tr><td>";
  $toPrint .= qq(<table border="1" style="border-color: red">);
  $toPrint .= qq(<tr><td colspan="100">);
  $toPrint .= qq(<input type="hidden" name="papid_$sentenceCounter"    value="$papid">\n);
  $toPrint .= qq(<input type="hidden" name="section_$sentenceCounter"  value="$section">\n);
  $toPrint .= qq(<input type="hidden" name="sentnum_$sentenceCounter"  value="$sentnum">\n);
  $toPrint .= qq(<input type="hidden" name="filename_$sentenceCounter" value="$filename">\n);
  my $pubmedLink = $papid; if ($pubmedLink =~ m/PMID:(\d+)/) { $pubmedLink = qq(<a href="http://www.ncbi.nlm.nih.gov/pubmed/$1" target="new">$papid</a>); }
  $toPrint .= qq($pubmedLink <span style="color: red; font-weight: bold; font-size: 14pt">$section</span> $sentnum $filename<br/>);
  $toPrint .= qq(<span style="font-size: 14pt">$color_converted_sentence</span><br/>);
  $toPrint .= &printClassification($sentenceCounter, $classification);
  $toPrint .= qq(<textarea name="comment_$sentenceCounter">$comment</textarea><br/>);
  $toPrint .= &printColorKey();
  $toPrint .= &printGeneProductLinks($sentenceCounter, $data{$papid}{$section}{$sentnum}{$filename}{geneprod});
  $toPrint .= qq(</td></tr>);

  if ( $pgCurated{$papid}{$section}{$sentnum}{$filename}{curated} ) {
    my $pgCuratedAmount = scalar @{ $pgCurated{$papid}{$section}{$sentnum}{$filename}{curated} };
    print qq(<input type="hidden" name="pgCuratedAmount_$sentenceCounter" value="$pgCuratedAmount">\n);
    my $pgCuratedCounter = 0;
    foreach my $annotationRef (@{ $pgCurated{$papid}{$section}{$sentnum}{$filename}{curated} }) {
      $pgCuratedCounter++;
      my ($geneprod, $component, $goterm, $evidencecode, $with, $alreadycurated, $comment, $valid, $ptgoid, $rowcurator, $timestamp) = @$annotationRef;
      my $timestampToDisplay = ''; if ($timestamp) { if ($timestamp =~ m/^(\d+\-\d+\-\d+ \d+:\d+:\d+)/) { $timestampToDisplay = $1; } }
      my $validCell = qq(<td><input type="checkbox" name="deleteCheckbox_${sentenceCounter}_$pgCuratedCounter" value="invalid"> Delete</td>);
      if ($valid eq 'invalid') { $validCell = qq(<td style="background-color: red"><input type="checkbox" name="deleteCheckbox_${sentenceCounter}_$pgCuratedCounter" value="valid"> Undelete</td>); }
      print qq(<input type="hidden" name="pgCuratedTimestamp_${sentenceCounter}_$pgCuratedCounter" value="$timestamp">\n);
      $toPrint .= qq(<tr><td>$geneprod</td><td>$component</td><td>$goterm</td><td>$evidencecode $with</td><td>$alreadycurated</td>$validCell<td>$rowcurator $timestampToDisplay</td></tr>);
    } # foreach my $annotation (@{ $pgCurated{$papid}{$section}{$sentnum}{$filename}{curated} })
  }

  for my $i (1 .. $maxAnnotationsPerSentence) { 
    my $snumRnum = $sentenceCounter . '_' . $i;
    $toPrint .= &showAnnotationRows($snumRnum, \%data, $papid, $section, $sentnum, $filename); }
        #   for my $i (1 .. 10) { &showAnnotationRows($i); }
  $toPrint .= qq(</table>);
  $toPrint .= "</td></tr>";
  return $toPrint;
} # sub showSentCuration

sub convertSentenceXmlToSpans {
  my ($sentence) = @_;
  my %colorMap;
  $colorMap{"CCC_dicty"} = "brown";
  $colorMap{"CCC_TAIR"} = "brown";
  $colorMap{"localization_cell_components_082208"} = "brown";
  $colorMap{"localization_cell_components_2011-02-11"} = "brown";
  $colorMap{"protein_celegans"} = "blue";
  $colorMap{"genes_arabidopsis"} = "blue";
  $colorMap{"dicty_genes"} = "blue";
  $colorMap{"localization_verbs_082008"} = "green";
  $colorMap{"localization_verbs_082208"} = "green";
  $colorMap{"localization_other_082008"} = "orange";
  $colorMap{"localization_experimental_082008"} = "orange";
  $colorMap{"localization_experimental_082208"} = "orange ";
  foreach my $tag (sort keys %colorMap) {
    if ($colorMap{$tag} eq 'brown') { 
        if ($sentence =~ m/<${tag}>/) {   $sentence =~ s/<${tag}>/<span style="color: $colorMap{$tag}; text-decoration:underline">/g; }
        if ($sentence =~ m/<\/${tag}>/) { $sentence =~ s/<\/${tag}>/<\/span>/g; } }
      else {
        if ($sentence =~ m/<${tag}>/) {   $sentence =~ s/<${tag}>/<span style="color: $colorMap{$tag}">/g; }
        if ($sentence =~ m/<\/${tag}>/) { $sentence =~ s/<\/${tag}>/<\/span>/g; } }
  } # foreach my $tag (sort keys %colorMap)
  return $sentence;
} # sub convertSentenceXmlToSpans

sub printColorKey {			# petra wanted a color key
  my $toPrint = 'color key : ';
  my %colorMap;
  $colorMap{"Gene Product"} = 'blue';
  $colorMap{"Textpresso Cellular Component"} = 'brown';
  $colorMap{"Assay Term"} = 'orange';
  $colorMap{"Verb"} = 'green';
  my @types = ( "Gene Product", "Textpresso Cellular Component", "Assay Term", "Verb" );
  foreach my $type (@types) { 
    if ($colorMap{$type} eq 'brown') { $toPrint .= qq(<span style="color: $colorMap{$type}; text-decoration:underline">$type</span> ); }
      else { $toPrint .= qq(<span style="color: $colorMap{$type}">$type</span> ); } }
  $toPrint .= qq(<span>Terms underlined, but not brown, are also present in a Textpresso category other than cellular component.</span><br/>); 
  return $toPrint;
} # sub printColorKey

sub printGeneProductLinks {				# make links for gene products to mod and uniprot URLs
  my ($sentenceCounter, $geneprods) = @_;		# getting sentence counter in case we want to toggle show-hide later
  my $toPrint = '';
  my @geneprods;
  my (@triplets) = split/\t/, $geneprods;
  foreach my $triplet (@triplets) {
    my ($geneprod, $geneid, $uniprots) = split/\|/, $triplet;
    my @uniprots;
    if ($uniprots =~ m/&/) { (@uniprots) = split/\&/, $uniprots; }
      else { push @uniprots, $uniprots; }
    foreach my $uniprot (@uniprots) {
      my $uniprotLink = $uniprot;
      if ($uniprot =~ m/UniProtKB:(.{6})/) { $uniprotLink = qq(<a href="http://www.uniprot.org/uniprot/$1" target="new">$uniprot</a>); }
      my $geneidLink  = $geneid;
      if ($geneid =~ m/(WBGene\d{8})/) { $geneidLink = qq(<a href="http://www.wormbase.org/species/c_elegans/gene/$1" target="new">$geneid</a>); }
        elsif ($geneid =~ m/(DDB_.*)/) { $geneidLink = qq(<a href="http://dictybase.org/gene/$1" target="new">$geneid</a>); }
      $toPrint .= qq($geneprod $geneidLink $uniprotLink<br/>);
    } # foreach my $uniprot (@uniprots)
  } # foreach my $triplet (@triplets)
  return $toPrint;
} # sub printGeneProductLinks

sub printClassification {
  my ($sentenceCounter, $classifications) = @_;
  my $toPrint = '';
  my (@classifications) = split/\|/, $classifications;
  my %classifications; foreach (@classifications) { $classifications{$_}++; }
  foreach my $option (sort keys %classificationOptions) { 
    my $checked = ''; if ($classifications{$option}) { $checked = 'checked="checked"'; }
    $toPrint .= qq(<input type="checkbox" name="${option}_$sentenceCounter" $checked >$classificationOptions{$option} - );
  } # foreach my $option (sort keys %classificationOptions) 
  $toPrint .= qq(<br/>);
  return $toPrint;
} # sub printClassification

sub showAnnotationRows {
  my ($snumRnum, $dataHashRef, $papid, $section, $sentnum, $filename) = @_;
  my %data = %$dataHashRef;
  my $geneprods  =  $data{$papid}{$section}{$sentnum}{$filename}{geneprod};
  my $components =  $data{$papid}{$section}{$sentnum}{$filename}{component};
  my $toPrint = qq(<tr id="tr_$snumRnum">);
  $toPrint .= &printSelectGeneprod($snumRnum, $geneprods);
  $toPrint .= &printSelectPair($snumRnum, $components);
  $toPrint .= &printNewCompGo($snumRnum, $components);
  $toPrint .= &printEvidenceCode($snumRnum);
  $toPrint .= &printAlreadyCurated($snumRnum);
  $toPrint .= &printDeletion($snumRnum);
  $toPrint .= &printSelectCurator($snumRnum);
  $toPrint .= "</td>";
  return $toPrint;
} # sub showAnnotationRows

sub printSelectGeneprod {
  my ($snumRnum, $geneprods) = @_;
  my @geneprods;
  my (@triplets) = split/\t/, $geneprods;
  foreach my $triplet (@triplets) {
    my ($geneprod, $geneid, $uniprots) = split/\|/, $triplet;
    my @uniprots;
    if ($uniprots =~ m/&/) { (@uniprots) = split/\&/, $uniprots; }
      else { push @uniprots, $uniprots; }
    foreach my $uniprot (@uniprots) {
      my @group = ();
      push @group, $geneprod; push @group, $geneid; push @group, $uniprot;
      my $group = join"|", @group;
      push @geneprods, $group;
    } # foreach my $uniprot (@uniprots)
  } # foreach my $triplet (@triplets)
  unshift @geneprods, "";
  my $size = scalar @geneprods;
  
  my ($i, $j) = $snumRnum =~ m/(\d+)_(\d+)/; 
  my $onclick = '';
  if ($j < $maxAnnotationsPerSentence) {
    my $jPlusOne = $j + 1; my $nextSnumRnum = $i . '_' . $jPlusOne;
    $onclick = qq(onclick="document.getElementById('tr_$nextSnumRnum').style.display = '';"); }
  my $toPrint  = qq(<td><select size="$size" name="geneprod_$snumRnum" id="geneprod_$snumRnum" $onclick; multiple="multiple">);
  foreach my $geneprod (@geneprods) { $toPrint .= "<option>$geneprod</option>"; }
  $toPrint .= qq(</select></td>);
  return $toPrint;
} # sub printSelectGeneprod

sub printSelectPair {
  my ($snumRnum, $components) = @_;
  my (@components) = split/\|/, $components;
  my @pairs;
  foreach my $component (@components) {
    if ($comp_index{$component}) { 
      foreach my $goterm (keys %{ $comp_index{$component}}) {
        my $lcgoterm = lc($goterm); 
        if ($goTermGoId{$lcgoterm}) {
          push @pairs, "$component -- $goTermGoId{$lcgoterm} $goterm"; } } } }
  unshift @pairs, "";
  my $size = scalar @pairs;
  my $toPrint = qq(<td><select size="$size" name="pair_$snumRnum">);
  foreach my $pair (@pairs) { $toPrint .= "<option>$pair</option>"; }
  $toPrint .= qq(</select></td>);
  return $toPrint;
} # sub printSelectPair

sub printNewCompGo {
  my ($snumRnum, $components) = @_;
  my (@components) = split/\|/, $components;
  my $toPrint = qq(<td>component <input size="20" name="component_new_$snumRnum"><br/>);
  unshift @components, "";
  $toPrint .= qq(<select size="1" name="component_list_$snumRnum">);
  foreach my $comp (@components) { $toPrint .= "<option>$comp</option>"; }
  $toPrint .= qq(</select><br/>);
  $toPrint .= qq(<div class="ui-widget"> <label for="goterm_$snumRnum">go term </label><input size="20" name="goterm_$snumRnum" id="goterm_$snumRnum" /> </div>);
  return $toPrint;
} # sub printNewCompGo

sub printEvidenceCode {
  my ($snumRnum, $rownum) = @_;
  my $toPrint = qq(<td>evidence code );
  my @ecs = qw(IDA IPI); my $ddsize = scalar(@ecs); my $selected = qq(selected="selected");
  $toPrint .= qq(<select size="$ddsize" name="evidencecode_$snumRnum">);
  foreach my $ec (@ecs) { 
    if ($ec eq 'IDA') { $selected = qq(selected="selected"); } else { $selected = ''; }
    $toPrint .= "<option $selected>$ec</option>"; }
  $toPrint .= qq(</select><br/>);
  $toPrint .= qq(with <input size="20" name="with_$snumRnum"><br/>);
  return $toPrint;
} # sub printEvidenceCode

sub printDeletion {
  my ($snumRnum) = @_;
  my $toPrint .= qq(<td>VALID</td>);
  return $toPrint;
} # sub printDeletion

sub printAlreadyCurated {
  my ($snumRnum) = @_;
  my $toPrint = qq(<td>);
  $toPrint .= qq(<input type="checkbox" name="alreadycurated_$snumRnum" value="alreadycurated">already curated );
  $toPrint .= qq(</td>);
  return $toPrint;
} # sub printAlreadyCurated


sub printSelectCurator {
  my $toPrint = qq(<td>you now</td>);
  return $toPrint;
} # sub printSelectCurator


sub popCompIndex {
  $result = $dbh->prepare( "SELECT * FROM ccc_component_go_index;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { 
    next unless $row[0]; next unless $row[1];
    $comp_index{$row[0]}{$row[1]}++; } 
} # sub popCompIndex

sub populateCurators {
  $curators{petra}    = 'dicty';
  $curators{robert}   = 'dicty';
  $curators{tanya}    = 'tair';
  $curators{donghui}  = 'tair';
  $curators{kimberly} = 'worm';
  $curators{ranjana}  = 'worm';
  $curatorToEmail{petra}    = 'pfey@northwestern.edu';
  $curatorToEmail{robert}   = 'robert_dodson@northwestern.edu';
  $curatorToEmail{tanya}    = 'vanauken@caltech.edu';
  $curatorToEmail{donghui}  = 'vanauken@caltech.edu';
  $curatorToEmail{kimberly} = 'vanauken@caltech.edu';
  $curatorToEmail{ranjana}  = 'ranjana@caltech.edu';
#     dictyBase - Petra Fey and Robert Dodson
#     TAIR - Tanya Berardini and Donghui Li
#     WormBase - Kimberly Van Auken, Ranjana Kishore (others?) 
} # sub populateCurators


sub printHeader { 
  my ($title) = @_;
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://minerva.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<HEAD>
EndOfText
  print qq(<title>$title</title>\n);
# <link rel="stylesheet" href="http://jqueryui.com/resources/demos/style.css" />	# this doesn't do much
  print <<"EndOfText";
<script src="ccc.js"></script>
<link rel="stylesheet" href="jquery/css/jquery-ui.css" />
<script src="jquery/javascript/jquery-1.9.1.js"></script>
<script src="jquery/javascript/ui/1.10.3/jquery-ui.js"></script>
<style>.ui-autocomplete-loading { background: white url('jquery/images/ui-anim_basic_16x16.gif') right center no-repeat; }</style>
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
EndOfText

  print << "EndOfText";
EndOfText
} # sub printHeader

__END__
