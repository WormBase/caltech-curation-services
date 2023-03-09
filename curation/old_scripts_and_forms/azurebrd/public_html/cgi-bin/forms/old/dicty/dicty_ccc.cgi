#!/usr/bin/perl -w

# DICTY ccc go curation

# Read sentences from flatfile.  By default look at last sentence (joinkey)
# entered in ggi_gene_gene_interaction, and read the next sentence.  Either :
# click on no genes and (No_interaction / Possible_genetic / Possible_non-genetic)
# or click on two genes and click on any other option.  Go back and reselect
# options to enter more than 3 connections / sentence. 
# New option to dump out last 10 sentences with connections.
# New option to search by sentence number.  2006 03 14
#
# Adapting for ccc go curation from gene_gene_inteaction.cgi  2007 03 15
#
# Created &addToGo($gene, $paps, $goterm); to add positive data to the GO
# curation got_ tables.  If an entry already exists, enter data, otherwise make
# a link to the go curation form to create the entry (for synonym data and so
# forth).  2007 04 27
#
# Added option of different source files, recreated the ccc_gene_comp_go table
# to allow a ccc_source_file column.  Made a symlink to the directory with the
# source files to make an html link to them in the form.  Will set up a script
# to redo this every week.  2007 07 18
#
# Set src_file_name on options as default value in case it's been changed.
# 2007 08 01
# 
# Fixed showing sentence, which wasn't working from an extra column in the file
# data.  
# Sorting by paper -> sentence -> score, instead of paper -> score -> sentence
# Added a checkbox for ``add to go form data'', and only do &addToGo($gene, $paps,
# $goterm); if the checkbox is checked on.  (for those sentences and not all the
# other ones).
# For Kimberly.  2008 03 07
#
# Added search of paper in source files for Kimberly.  2008 04 10
#
# Broke up sentences to have their own radio buttons for ``goterm''
# curate_radio, instead of separate buttons for those choices, since each
# sentence needed its own.  2008 04 14
#
# Changed to work with phenote tables.  2008 07 30
#
# Read data from /home2/postgres/work/pgpopulation/ccc_gocuration/sentences/
# since the files were taking up too much space. 
# Read in bad proteins and bad components, excluded from already being annotated.
# 2009 05 25
#
# Was adding $src_file_name instead of $ccc_src_file to ccc_gene_comp_go
# ccc_source_file column.
# Was adding marked up link to wormbase dev into ccc_gene_comp_go
# ccc_paper_sentence column.  2010 02 14
#
# added  &dumpAnnotationFile() to dump 3 column output based on 
# Kimberly specs  2011 01 21
#
# now  $src_file_name = 'results_2_2008_not_geneassociation';
# instead of  localization_cell_components_082208  being brown, now it's CCC_TAIR 
#   being brown.  2011 03 15
#
# wrote  &getSourceFiles()  to get an array of all results_ files in directory and
# subdirectories.  script now gets files from subdirectories.  2011 06 07
#
# more changes to deal with subdirectories.  it's storing in postgres just the 
# filename, not also the subdirectory, so when querying for what it's already done
# it needs to query for that.  2011 06 10
#
# split comments into ccc_comment for WB and ccc_tair_comment for TAIR.  This new
# ccc_tair_comment tables has a second column for the source file.
# the source file used to have the file name, but not the directory, now it parses
# the subdirectory as well from the file that it's reading.  2011 11 17
#
# changed from tair to dicty.  2012 03 05
#
# searching for joinkey look at substring on just the filename instead of exact
# match because data entered is now subdir+filename, but old data is just filename,
# so cannot match exactly on subdir+filename.  2012 09 29


use strict;
use CGI;
use DBI;
use Jex;
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $query = new CGI;

my $src_directory = '/home/azurebrd/public_html/cgi-bin/data/dicty_ccc_datafiles/';
# my $src_file_name = 'results_2_2008_not_geneassociation';
my (@src_files) = &getSourceFiles();
# my $src_file_name = $src_files[0];		# to load a file by default
my $src_file_name = '';
my $src_file = $src_directory . $src_file_name;

my $data_url = 'http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/dicty_ccc_datafiles/';

my %comp_index;		# component to goterm index that have already been added to postgres
&popCompIndex();	# populate %comp_index;

my %symbolToLocus;	# dicty symbols that map to locus
&popSymbolToLocus();	# populate %symbolToLocus;
sub popSymbolToLocus {
#   my $infile = $src_directory . 'gene_aliases.20101027';
  my $infile = $src_directory . 'gene_aliases';			# use symlink to yuling can update it 2011 08 01
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  my $header = <IN>;
  while (my $line = <IN>) {
    my @line = split/\t/, $line;
    $symbolToLocus{$line[1]}{$line[0]}++; }
  close (IN) or die "Cannot close $infile : $!";
} # sub popSymbolToLocus

&printHeader('gene component goterm');
&process();
&printFooter();

sub changeSourceFile {
  my ($var, $oop) = &getHtmlVar($query, 'source_file');
  if ($oop) { $src_file_name = $oop; $src_file = $src_directory . $src_file_name; }
} # sub changeSourceFile

sub findPapSourceFile { 
  my ($var, $paper) = &getHtmlVar($query, 'pap_sfile_search');
#   my (@src_files) = </home/postgres/work/pgpopulation/ccc_gocuration/recent_sentences_file.*>;
#   my (@src_files) = <${src_directory}results_*>;
#   my (@src_files) = &getSourceFiles();
  my @good_files;
  foreach my $src_file (reverse @src_files) { 
    $/ = undef;
    open (IN, "<${src_directory}$src_file") or die "Cannot open ${src_directory}src_file : $!";
    my $all_file = <IN>;
    close (IN) or die "Cannot close $src_directory}src_file : $!";
    if ($all_file =~ m/ P $paper S /) { 
#       $src_file =~ s/$src_directory//g; 
      print "Match for $paper in sourcefile <A HREF=\"${data_url}$src_file\" target=\"new\">$src_file</A><BR>\n"; } }
} # sub findPapSourceFile

sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  if ($action) {
    if ($action eq "Submit !") { &newEntry(); }
    elsif ($action eq "Source File !") { &changeSourceFile(); }
    elsif ($action eq "Dump Annotation File") { &dumpAnnotationFile(); }

#     elsif ($action eq "Already !") { &newEntry('already curated'); }
#     elsif ($action eq "Not GO !") { &newEntry('not go curatable'); }
#     elsif ($action eq "Scrambled Sentence !") { &newEntry('scrambled sentence'); }
#     elsif ($action eq "False Positive !") { &newEntry('false positive'); }
#     elsif ($action eq "Dump 10 !") { &dump10(); } 
    elsif ($action eq "Search Pap Source !") { &findPapSourceFile(); } 
  }
  return if ($action eq "Search Pap Source !"); 
  return if ($action eq "Dump Annotation File"); 

  &changeSourceFile();		# always check the sourcefile since it defaults to original list

  my $sentence = 0;

  my ($just_the_file_name) = $src_file_name =~ m/\/(.*?)$/;

#   my $result = $dbh->prepare( "SELECT joinkey FROM ccc_dicty_gene_comp_go WHERE ccc_source_file = '$src_file_name' ORDER BY joinkey DESC;" );
  my $result = $dbh->prepare( "SELECT joinkey FROM ccc_dicty_gene_comp_go WHERE ccc_source_file ~ '$just_the_file_name' ORDER BY joinkey DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   print "SELECT joinkey FROM ccc_dicty_gene_comp_go WHERE ccc_source_file = '$src_file_name' ORDER BY joinkey DESC;\n";
  print "SELECT joinkey FROM ccc_dicty_gene_comp_go WHERE ccc_source_file ~ '$just_the_file_name' ORDER BY joinkey DESC;\n";
  my @row = $result->fetchrow;
  if ($row[0]) { $sentence = $row[0]; }
#   $sentence = 2617;

  if ($action) { if ($action eq "Search !") { (my $var, $sentence) = &getHtmlVar($query, "sent_search"); $sentence--; } }

  my $sentence_count;
  my $sent_line; my $paper; my @lines; my $abs; my $title;
#   unless (-e $src_file) { $src_file = shift @src_file; }
  if (-e $src_file) {
    open (IN, "<$src_file") or die "Cannot open $src_file : $!";
    for ( 1 .. $sentence ) { <IN>; $sentence_count++; }
    $sent_line = <IN>;
#     ($paper) = $sent_line =~ m/(WBPaper\d+)/;
    ($paper) = $sent_line =~ m/ P (\d+) S /;
    @lines; $abs = ''; $title = '';
    ($title) = get "http://textpresso-dev.caltech.edu/cgi-bin/azurebrd/biblio.cgi?organism=dicty&field=title&paper=$paper";
    ($abs) = get "http://textpresso-dev.caltech.edu/cgi-bin/azurebrd/biblio.cgi?organism=dicty&field=abstract&paper=$paper";
    push @lines, $sent_line;
    while ($sent_line = <IN>) {
      if ($sent_line =~ m/\d+\tS \d+ P $paper S/) { push @lines, $sent_line; $sentence_count++; }
#       elsif ($sent_line =~ m/ABSTRACT/) { if ($sent_line =~ m/ABSTRACT\t$paper\t(.*?)$/) { $abs = $1; } }
#       elsif ($sent_line =~ m/TITLE/) { if ($sent_line =~ m/TITLE\t$paper\t(.*?)$/) { $title = $1; } }
      else { $sentence_count++; }
    } # while ($sent_line = <IN>)
    close (IN) or die "Cannot close $src_file : $!";
  }
  print "<FORM METHOD=POST ACTION=\"dicty_ccc.cgi\">\n";
  print "Make connections : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Submit !\">\n"; 
#   print "Make connections : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Submit !\">\n"; 
#   print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Already Curated : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Already !\">\n"; 
#   print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Not GO curatable : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Not GO !\"><BR>\n"; 
#   print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;False Positive : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"False Positive !\">\n"; 
#   print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Scrambled Sentence : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Scrambled Sentence !\"><BR>\n"; 
#   print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Dump last 10 sentences : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Dump 10 !\">\n"; 
  print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Search for sentence : <INPUT NAME=\"sent_search\"><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Search !\"><BR>\n"; 
  print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Search for paper in source files : <INPUT NAME=\"pap_sfile_search\"><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Search Pap Source !\"><BR>\n"; 
  my $text = "Title : $title<BR>Abstract : $abs<BR>\n";
  $text =~ s/<protein_celegans>(.*?)<\/protein_celegans>/<FONT COLOR='blue'>$1<\/FONT>/g;
  $text =~ s/<dicty_genes>(.*?)<\/dicty_genes>/<FONT COLOR='blue'>$1<\/FONT>/g;
#   $text =~ s/<localization_cell_components_082208>(.*?)<\/localization_cell_components_082208>/<FONT COLOR='brown'>$1<\/FONT>/g;
  $text =~ s/<CCC_TAIR>(.*?)<\/CCC_TAIR>/<FONT COLOR='brown'>$1<\/FONT>/g;
  $text =~ s/<localization_verbs_082208>(.*?)<\/localization_verbs_082208>/<FONT COLOR='green'>$1<\/FONT>/g;
  $text =~ s/<localization_other_082208>(.*?)<\/localization_other_082208>/<FONT COLOR='orange'>$1<\/FONT>/g;
  print $text;
  print "<TABLE>\n";
  print "<tr><td>Gene/Protein Name</td><td>Component Term in Sentence</td><td>CC Term in GO</td><td><FONT COLOR='blue'>blue = gene product</font>, <FONT COLOR='green'>green = verb</font>, <FONT COLOR='orange'>orange = assay term</font>, and <FONT COLOR='brown'>red/brown = component term</font></td></tr>\n";

  my $box = 0;
  foreach my $line (@lines) {
    $line = $src_file_name . "\t" . $line;
    $box++;
    &newReadSentence($src_file, $line, $box); } 
  print "<INPUT TYPE=HIDDEN NAME=box_count VALUE=\"$box\">\n";
  print "</TABLE>\n";
  print "Make connections : <INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Submit !\"><BR>\n"; 
  print "Enter comments for this sentence here : <TEXTAREA NAME=comment ROWS=4 COLS=80></TEXTAREA><BR>\n";
  print "There are $sentence_count sentences in the sourcefile <A HREF=\"${data_url}$src_file_name\" target=\"new\">$src_file</A><BR>\n";
#   my (@src_files) = &getSourceFiles();
#   my (@src_files) = <${src_directory}results_*>;
#   foreach (reverse @src_files) { $_ =~ s/$src_directory//g; }
  print "Select a source_file : <SELECT NAME=\"source_file\" SIZE=1>\n";
#   if ($src_file_name) { print "<OPTION>$src_file_name</OPTION>\n"; }
  foreach (reverse @src_files) { 
    if ($src_file_name eq $_) { print "      <OPTION selected=\"selected\">$_</OPTION>\n"; }
      else { print "      <OPTION>$_</OPTION>\n"; } }
  print "    </SELECT>\n ";
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Source File !\"><BR>\n"; 
  print "<INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Dump Annotation File\"><BR>\n"; 
  print "</FORM>\n";

} # sub process

sub getSourceFiles {
  my (@array) = <${src_directory}results_*>;
  my @directory; my @file;
  foreach (@array) {
    if (-d $_) { push @directory, $_; }
    if (-f $_) { push @file, $_; }
  } # foreach (@array)
  foreach (@directory) {
    my @array = <$_/*>;
    foreach (@array) {
      if (-d $_) { push @directory, $_; }
      if (-f $_) { push @file, $_; }
  } }
  foreach (reverse @file) { $_ =~ s/$src_directory//g; }
#   my $files = join", ", @file; print "FILE $files FILE<br>";
  return @file;
} # sub getSourceFiles

sub dumpAnnotationFile {		# dump 3 column output based on Kimberly specs  2011 01 21
  my $obo_file_url = 'http://www.geneontology.org/ontology/obo_format_1_2/gene_ontology_ext.obo';
  my $obo_file = get $obo_file_url;
  my %go_map;
  my (@entries) = split/\[Term\]/, $obo_file;
  foreach my $entry (@entries) {
    my $id; my $name;
    if ($entry =~ m/id: (.*)/) { $id = $1; }
    if ($entry =~ m/name: (.*)/) { $name = $1; }
    $go_map{$name} = $id; }

#   my $infile = $src_directory . 'gene_aliases';			# use symlink to yuling can update it 2011 08 01
#   $/ = undef;
#   open (IN, "<$infile") or die "Cannot open $infile : $!";
#   my $gene_file = <IN>;
#   close (IN) or die "Cannot close $infile : $!";
#   $/ = "\n";
  my $gene_file_url = 'ftp://ftp.arabidopsis.org/home/tair/Genes/gene_aliases.latest.txt';
  my $gene_file = get $gene_file_url;
  my %gene_matches;
  my (@lines) = split/\n/, $gene_file;
  foreach my $line (@lines) {
    my ($id, $symbol, $fullname) = split/\t/, $line;
    ($fullname) = lc($fullname);
    ($symbol) = lc($symbol);
    $gene_matches{$symbol} = $id;
    $gene_matches{$fullname} = $id; }

  my $result = $dbh->prepare( "SELECT * FROM ccc_dicty_gene_comp_go WHERE ccc_gene IS NOT NULL AND ccc_goterm IS NOT NULL;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my ($a, $filename, $ccc_paper_sentence, $gene, $component, $goterm, $timestamp) = @row;
    ($timestamp) = $timestamp =~ m/^(\d{4}\-\d{2}\-\d{2})/;
    my ($paper) = $ccc_paper_sentence =~ m/P (\d+) S/;
    my $paperID = 'DICTY:' . $paper;
    my $genename = '';
    my ($lcgene) = lc($gene);
    if ($gene =~ m/ : (\w+)/) { $genename = $1; } 
    elsif ($gene_matches{$gene}) { $genename = $gene_matches{$gene}; }
    elsif ($gene_matches{$lcgene}) { $genename = $gene_matches{$lcgene}; }
    my $goid = '';
    if ($go_map{$goterm}) { $goid = $go_map{$goterm}; }
    print "$genename\t$goid\t$paperID\t$timestamp\t$filename<br />\n";
  } # while (my @row = $result->fetchrow)
} # sub dumpAnnotationFile

# NOT being used
# sub dump10 {
#   my $sentence = 0;
#   my ($just_the_file_name) = $src_file_name =~ m/\/(.*?)$/;
# #   my $result = $dbh->prepare( "SELECT joinkey FROM ccc_dicty_gene_comp_go WHERE ccc_source_file = '$src_file_name' ORDER BY joinkey DESC;" );
#   my $result = $dbh->prepare( "SELECT joinkey FROM ccc_dicty_gene_comp_go WHERE ccc_source_file = '$just_the_file_name' ORDER BY joinkey DESC;" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#   my @row = $result->fetchrow; if ($row[0]) { $sentence = $row[0]; } $sentence -= 10;
#   open (IN, "<$src_file") or die "Cannot open $src_file : $!";
#   for ( 1 .. $sentence ) { <IN>; }
#   for my $sent ( ($sentence + 1) .. ($sentence + 10) ) {
#     my $sentence = <IN>; 
#     print "SENT $sentence\n";
# #     print "SELECT * FROM ccc_dicty_gene_comp_go WHERE joinkey = '$sent';<BR>\n";
# #   my $result = $dbh->prepare( "SELECT * FROM ccc_dicty_gene_comp_go WHERE ccc_source_file = '$src_file_name' AND joinkey = '$sent';" );
#   my $result = $dbh->prepare( "SELECT * FROM ccc_dicty_gene_comp_go WHERE ccc_source_file = '$just_the_file_name' AND joinkey = '$sent';" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#     while (my @row = $result->fetchrow) { print "$row[2]\t$row[3]\t$row[4]<BR>\n"; }
#     print "<P>\n"; }
# } # sub dump10

sub newEntry {
#   my $goterm = shift;
  print "You've entered stuff : <BR>\n";
  my $badData = 0; my @pgcommands;
  my ($var, my $paps) = &getHtmlVar($query, "paps");
  ($var, my $box_count) = &getHtmlVar($query, "box_count");

  for my $box ( 1 .. $box_count ) {
    ($var, my $sentid) = &getHtmlVar($query, "sentid_$box");
# print "BOX $box S $sentid E<BR>\n";
    ($var, my $ccc_src_file) = &getHtmlVar($query, "ccc_src_file");

    ($var, my $comment) = &getHtmlVar($query, "comment");
#     if ($comment) { push @pgcommands, "INSERT INTO ccc_comment VALUES ('$sentid', '$comment', CURRENT_TIMESTAMP);"; }
    if ($comment) { push @pgcommands, "INSERT INTO ccc_dicty_comment VALUES ('$sentid', '$ccc_src_file', '$comment', CURRENT_TIMESTAMP);"; }

    ($var, my $goterm) = &getHtmlVar($query, "curate_radio_$box");
#     if ( ($goterm eq 'already curated') || ($goterm eq 'not go curatable') || ($goterm eq 'scrambled sentence') || ($goterm eq 'false positive') ) # require already curated to have protein and component  for Kimberly  2009 05 21
    if ( ($goterm eq 'not go curatable') || ($goterm eq 'scrambled sentence') || ($goterm eq 'false positive') ) {
      push @pgcommands, "INSERT INTO ccc_dicty_gene_comp_go VALUES ('$sentid', '$ccc_src_file', '$paps', NULL, NULL, '$goterm', CURRENT_TIMESTAMP);"; }
    else {
        ($var, my $gene) = &getHtmlVar($query, "gene_$box");
        my @genes; if ($gene) { (@genes) = $query->param("gene_$box"); } $gene = join", ", @genes;	# get separate genes if multiple chosen
        ($var, my $component) = &getHtmlVar($query, "component_$box");
        unless ( ($goterm eq 'already goterm') || ($goterm eq 'not go curatable') || ($goterm eq 'scrambled sentence') || ($goterm eq 'false positive') ) {
          ($var, $goterm) = &getHtmlVar($query, "goterm_$box");
          ($var, my $new_goterm) = &getHtmlVar($query, "new_goterm_$box");
          ($var, my $new_component) = &getHtmlVar($query, "new_component_$box");
          my $add_term_flag = 0;		# add to ccc_component_go_index if there's a new component or new goterm or both 2011 06 22
          if ($new_component) { $component = $new_component; $add_term_flag++; }
          if ($new_goterm) { $goterm = $new_goterm; $add_term_flag++; }
          if ($add_term_flag) { &addTerm($component, $new_goterm); } }
    
        print "Gene $gene Component $component GO_term $goterm Paper-Sentence $paps SentenceID $sentid<BR>\n";
        if ($goterm) {
#           unless ( ($goterm eq 'already curated') || ($goterm eq 'not go curatable') || ($goterm eq 'scrambled sentence') || ($goterm eq 'false positive') ) # require already curated to have protein and component  for Kimberly  2009 05 21
          unless ( ($goterm eq 'not go curatable') || ($goterm eq 'scrambled sentence') || ($goterm eq 'false positive') ) {	# already curated to have protein and component  for Kimberly  2009 05 21
            unless ($gene) { print "<FONT COLOR=red>ERROR $goterm has no gene</FONT><BR>\n"; $badData++; } 
            unless ($component) { print "<FONT COLOR=red>ERROR $goterm has no component</FONT><BR>\n"; $badData++; } 
            unless ($badData) {
              foreach my $each_gene (@genes) {			# for each of the chosen genes from the select
                push @pgcommands, "INSERT INTO ccc_dicty_gene_comp_go VALUES ('$sentid', '$ccc_src_file', '$paps', '$each_gene', '$component', '$goterm', CURRENT_TIMESTAMP);"; } } }
        }
      } } # for my $box ( 1 .. $box_count )
    
  if ($badData) { print "<FONT COLOR=red>Click BACK, fix the bad data, and resubmit</FONT><P><P>\n"; return; }
    else {
      foreach my $pgcommand (@pgcommands) {
# UNCOMMENT THIS
        my $result = $dbh->prepare( "$pgcommand" );
        $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
        print "<FONT COLOR='green'>$pgcommand</FONT><BR>\n"; } }
  print "<P>\n";
} # sub newEntry

sub addTerm {
  my ($component, $goterm) = @_;
  unless ($comp_index{$component}{$goterm}) {
    print "<FONT COLOR='blue'>Adding</FONT> new <FONT COLOR='orange'>$goterm</FONT> - <FONT COLOR='brown'>$component</FONT> relationship to index<BR>\n";
    my $result = $dbh->do( "INSERT INTO ccc_component_go_index VALUES ('$component', '$goterm');" ); }
} # sub addTerm

sub popCompIndex {
  my $result = $dbh->prepare( "SELECT * FROM ccc_component_go_index;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $comp_index{$row[0]}{$row[1]}++; }
} # sub popCompIndex

sub newReadSentence {
  my ($src_file, $line, $box) = @_;
  $src_file =~ s|/home/azurebrd/public_html/cgi-bin/data/dicty_ccc_datafiles/||;
  my ($junk, $junk2, $sentid, $paps, $genes, $components, $text, $badProt, $badComp) = split/\t/, $line;

#   my ($src_file, $line_count, $genes, $components, $text) = split/\t/, $line;
#   my ($paps) = $line_count =~ m/(WBPaper\d+)/;
# print "S $src_file LINE $sentid PAPS $paps GENES $genes COMPONENTS $components TEXT $text E<BR>\n";
  my (@genes) = split/, /, $genes;
  my (@components) = split/, /, $components;
  my %goTerms;
  foreach my $comp (@components) {
    if ($comp_index{$comp}) { foreach my $goterm (keys %{ $comp_index{$comp}}) { $goTerms{$goterm}++; } } }

  $text =~ s/<protein_celegans>(.*?)<\/protein_celegans>/<FONT COLOR='blue'>$1<\/FONT>/g;
  $text =~ s/<dicty_genes>(.*?)<\/dicty_genes>/<FONT COLOR='blue'>$1<\/FONT>/g;
#   $text =~ s/<localization_cell_components_082208>(.*?)<\/localization_cell_components_082208>/<FONT COLOR='brown'>$1<\/FONT>/g;
  $text =~ s/<CCC_TAIR>(.*?)<\/CCC_TAIR>/<FONT COLOR='brown'>$1<\/FONT>/g;
  $text =~ s/<localization_verbs_082208>(.*?)<\/localization_verbs_082208>/<FONT COLOR='green'>$1<\/FONT>/g;
  $text =~ s/<localization_other_082208>(.*?)<\/localization_other_082208>/<FONT COLOR='orange'>$1<\/FONT>/g;
  $text =~ s/<localization_experimental_082208>(.*?)<\/localization_experimental_082208>/<FONT COLOR='orange'>$1<\/FONT>/g;

#   foreach my $symbol (@genes) { print "SYM $symbol<br>\n"; }

  print "<TR>\n";
  print "<TD><SELECT NAME=\"gene_$box\" SIZE=12 multiple=\"multiple\">\n";
  print "      <OPTION> </OPTION>\n";
  foreach my $symbol (@genes) { 
#     print "      <OPTION>$symbol</OPTION>\n";	# no longer show symbols that don't map to loci 2011 06 22
    foreach my $locus (sort keys %{ $symbolToLocus{$symbol} }) { 
      print "      <OPTION>$symbol : $locus</OPTION>\n"; } }
  print "    </SELECT></TD>\n ";

  print "<TD><INPUT NAME=\"new_component_$box\" SIZE=30><SELECT NAME=\"component_$box\" SIZE=10>\n";
  print "      <OPTION > </OPTION>\n";
  foreach (@components) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n ";

  print "<TD><INPUT NAME=\"new_goterm_$box\" SIZE=30><BR><SELECT NAME=\"goterm_$box\" SIZE=10>\n";
  foreach (sort keys %goTerms) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n ";


  my $paps_link = $paps;
  my ($paper) = $paps_link =~ m/ P (\d+) S /;
#   my $tair_paper_url = 'http://germany.tairgroup.org:8090/pub/DisplayArticle?article_id=';
  my $dicty_paper_url = 'http://www.ncbi.nlm.nih.gov/pubmed?term=';
  $paps_link =~ s/$paper/<a href=\"${dicty_paper_url}$paper\" target=\"new\">$paper<\/a>/g;		# link paper to tair website
  print "<TD>curate<INPUT TYPE=radio NAME=\"curate_radio_$box\" VALUE=\"curate\">&nbsp;&nbsp;<br/>";
  print "already curated<INPUT TYPE=radio NAME=\"curate_radio_$box\" VALUE=\"already curated\">&nbsp;&nbsp;<br/>";
  print "scrambled sentence<INPUT TYPE=radio NAME=\"curate_radio_$box\" VALUE=\"scrambled sentence\">&nbsp;&nbsp;<br/>";
  print "false positive<INPUT TYPE=radio NAME=\"curate_radio_$box\" VALUE=\"false positive\">&nbsp;&nbsp;<br/>";
  print "not go curatable<INPUT TYPE=radio NAME=\"curate_radio_$box\" VALUE=\"not go curatable\">&nbsp;&nbsp;<br/>";
#   print "Add To Go : <INPUT NAME=\"add_to_go_$box\" TYPE=CHECKBOX VALUE=\"checked\"><BR>\n";
  print "SentenceID $sentid -- $paps_link<BR>$text<br /><span style=\"color:red\">already done : $badProt $badComp</span></TD>\n";
  print "<INPUT TYPE=HIDDEN NAME=\"sentid_$box\" VALUE=\"$sentid\">\n";
  print "<INPUT TYPE=HIDDEN NAME=paps VALUE=\"$paps\">\n";
  print "<INPUT TYPE=HIDDEN NAME=ccc_src_file VALUE=\"$src_file\">\n";
  print "</TR>\n";
} # sub newReadSentence



__END__

sub readSentence {
  my ($sentence, $line, $count) = @_;
  $sentence++;
#   print "SENT $sentence SENT<BR>\n";
#   my ($src_file, $line_count, $paps, $genes, $components, $text) = split/\t/, $line;
  my ($src_file, $line_count, $genes, $components, $text) = split/\t/, $line;
  my ($paps) = $line_count =~ m/(WBPaper\d+)/;
print "S $src_file LINE $line_count PAPS $paps GENES $genes COMPONENTS $components TEXT $text E<BR>\n";
#   unless ($line_count == $sentence) { print "<FONT COLOR='red'>ERROR between sentence count in line read $sentence and sentence ID $line_count.</FONT><BR>\n"; }
  my (@genes) = split/, /, $genes;
  my (@components) = split/, /, $components;
  my %goTerms;
  foreach my $comp (@components) {
    if ($comp_index{$comp}) { foreach my $goterm (keys %{ $comp_index{$comp}}) { $goTerms{$goterm}++; } } }

  $text =~ s/<protein_celegans>(.*?)<\/protein_celegans>/<FONT COLOR='blue'>$1<\/FONT>/g;
  $text =~ s/<genes_arabidopsis>(.*?)<\/genes_arabidopsis>/<FONT COLOR='blue'>$1<\/FONT>/g;
  $text =~ s/<localization_cell_components_012607>(.*?)<\/localization_cell_components_012607>/<FONT COLOR='brown'>$1<\/FONT>/g;
  $text =~ s/<localization_verbs_012607>(.*?)<\/localization_verbs_012607>/<FONT COLOR='green'>$1<\/FONT>/g;
  $text =~ s/<localization_other_012607>(.*?)<\/localization_other_012607>/<FONT COLOR='orange'>$1<\/FONT>/g;
  $text =~ s/<localization_experimental_082208>(.*?)<\/localization_experimental_082208>/<FONT COLOR='orange'>$1<\/FONT>/g;

  print "<TR>\n";
  print "<TD><SELECT NAME=\"gene_$count\" SIZE=12>\n";
  print "      <OPTION> </OPTION>\n";
  foreach (@genes) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n ";

  print "<TD><SELECT NAME=\"component_$count\" SIZE=12>\n";
  print "      <OPTION > </OPTION>\n";
  foreach (@components) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n ";

  print "<TD><INPUT NAME=\"new_goterm_$count\" SIZE=30><BR><SELECT NAME=\"goterm_$count\" SIZE=10>\n";
  foreach (sort keys %goTerms) { print "      <OPTION>$_</OPTION>\n"; }
  print "    </SELECT></TD>\n ";

  if ($paps =~ m/WBPaper\d{8}/) { $paps =~ s/(WBPaper\d{8})/<A HREF=http:\/\/dev.wormbase.org\/db\/misc\/paper?name=$1;class=Paper TARGET=new>$1<\/A>/g; }			# link paper to dev.wormbase  2007 08 14
  print "<TD>SentenceID $sentence -- $paps<BR><BR>$text</TD>\n";
  print "<INPUT TYPE=HIDDEN NAME=ccc VALUE=\"$sentence\">\n";
  print "<INPUT TYPE=HIDDEN NAME=paps VALUE=\"$paps\">\n";
  print "<INPUT TYPE=HIDDEN NAME=ccc_src_file VALUE=\"$src_file\">\n";
  print "</TR>\n";
} # sub readSentence

CREATE TABLE ccc_dicty_comment (
    joinkey integer,
    ccc_source_file text,
    ccc_dicty_comment text,
    ccc_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone
);
ALTER TABLE public.ccc_dicty_comment OWNER TO postgres;
REVOKE ALL ON TABLE ccc_dicty_comment FROM PUBLIC;
REVOKE ALL ON TABLE ccc_dicty_comment FROM postgres;
GRANT ALL ON TABLE ccc_dicty_comment TO postgres;
GRANT SELECT ON TABLE ccc_dicty_comment TO acedb;
GRANT ALL ON TABLE ccc_dicty_comment TO apache;
GRANT ALL ON TABLE ccc_dicty_comment TO azurebrd;
GRANT ALL ON TABLE ccc_dicty_comment TO "www-data";


CREATE TABLE ccc_dicty_gene_comp_go (
    joinkey integer,
    ccc_source_file text,
    ccc_paper_sentence text,
    ccc_gene text,
    ccc_component text,
    ccc_goterm text,
    ccc_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone
);
ALTER TABLE public.ccc_dicty_gene_comp_go OWNER TO postgres;

CREATE INDEX ccc_dicty_gene_comp_go_idx ON ccc_dicty_gene_comp_go USING btree (joinkey);
REVOKE ALL ON TABLE ccc_dicty_gene_comp_go FROM PUBLIC;
REVOKE ALL ON TABLE ccc_dicty_gene_comp_go FROM postgres;
GRANT ALL ON TABLE ccc_dicty_gene_comp_go TO postgres;
GRANT SELECT ON TABLE ccc_dicty_gene_comp_go TO acedb;
GRANT ALL ON TABLE ccc_dicty_gene_comp_go TO apache;
GRANT ALL ON TABLE ccc_dicty_gene_comp_go TO azurebrd;
GRANT ALL ON TABLE ccc_dicty_gene_comp_go TO "www-data";

