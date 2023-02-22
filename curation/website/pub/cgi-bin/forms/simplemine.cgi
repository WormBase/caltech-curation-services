#!/usr/bin/perl 

# Query by list of gene names on text tables.
#
# For Wen, sort of for Chris.  2015 07 30
#
# Don't need to read file to tempfile, just to variable.  2015 12 17
#
# Changed to ftp://caltech.wormbase.org/pub/wormbase/simpleMine/ instead
# of athena for Wen.  Now has dead/live gene status.  2016 05 20
#
# Changed output to be downloadable text file for Chris.  2016 05 20
#
# Change default from blank to 'N.A.' for Concise Description fields. For Wen.  2016 06 03
#
# Changed source of files from ftp to local files in wen's directory.  2016 06 09
#
# Names can map to multiple genes (e.g. A0A0M6VD87), now display all matching WBGenes.  2016 06 15
#
# Individual columns in WBGeneName.csv can have multiple comma-separated names, account for that.  2016 08 04
#
# Had an extra tab in the output, shifting things over.  Also option to download vs html.  2016 08 30
#
# Fixed some formatting with 'not found' having extra row, and entered names with multiple 
# geneIds having their geneData not cleared between geneIds.  2016 10 04
#
# Allow toggling of most columns to show or not show.  2016 04 06
#
# Was skipping first column from files because it just had the WBGene, now using it as a valid data column.  2017 06 16
#
# Wen added a new reference file, GeneReference.csv
# queryListCelegansFile to query from a list of all C elegans genes for Wen.  2017 10 09
#
# 'Set All Checkboxes' checkbox sets state of all checkboxes to match this checkbox, for Chris.
# Concise Description is now an optional set of data, for Chris.  2017 10 11
#
# 
# Get all .csv files for Wen.  2018 02 26
#
# If a user input maps to multiple genes, say multiple entries, and put the entries at the end,
# to allow the output format to match the user input.  2018 03 09
#
# Concise description removed for Wen and Ranjana.  2018 10 02
#
# Split into multiple species file, using form like agr_simplemine.  mix file is 2.8G, so uses
# 100% cpu and the browser hangs, could try not splitting the file on linebreak, or reading 
# each file in sequence instead of all at once.  2020 06 12
#
# can pass inputs for species and genes, like
# http://mangolassi.caltech.edu/~azurebrd/cgi-bin/forms/simplemine.cgi?geneInput=blah&species=mix
# 2020 07 13

# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/simplemine.cgi

# http://mangolassi.caltech.edu/~azurebrd/cgi-bin/forms/simplemine.cgi?species=mix&action=query+list&caseSensitiveToggle=caseInsensitive&outputFormat=html&duplicatesToggle=merge&headers=WormBase+Gene+ID%09Public+Name%09Species%09Sequence+Name%09Other+Name%09Transcript%09Operon%09WormPep%09Protein+Domain%09Uniprot%09Reference+Uniprot+ID%09TreeFam%09RefSeq_mRNA%09RefSeq_protein%09Genetic+Map+Position%09RNAi+Phenotype+Observed%09Allele+Phenotype+Observed%09Coding_exon+Non_silent+Allele%09Interacting+Gene%09Expr_pattern+Tissue%09Genomic+Study+Tissue%09Expr_pattern+LifeStage%09Genomic+Study+LifeStage%09Disease+Info%09Human+Ortholog%09Reference%09Gene+Ontology+Association%09Concise+Description%09Automated+Description%09Expression+Cluster+Summary&select+all=select+all&WormBase+Gene+ID=WormBase+Gene+ID&Public+Name=Public+Name&Species=Species&Sequence+Name=Sequence+Name&Other+Name=Other+Name&Transcript=Transcript&Operon=Operon&WormPep=WormPep&Protein+Domain=Protein+Domain&Uniprot=Uniprot&Reference+Uniprot+ID=Reference+Uniprot+ID&TreeFam=TreeFam&RefSeq_mRNA=RefSeq_mRNA&RefSeq_protein=RefSeq_protein&Genetic+Map+Position=Genetic+Map+Position&RNAi+Phenotype+Observed=RNAi+Phenotype+Observed&Allele+Phenotype+Observed=Allele+Phenotype+Observed&Coding_exon+Non_silent+Allele=Coding_exon+Non_silent+Allele&Interacting+Gene=Interacting+Gene&Expr_pattern+Tissue=Expr_pattern+Tissue&Genomic+Study+Tissue=Genomic+Study+Tissue&Expr_pattern+LifeStage=Expr_pattern+LifeStage&Genomic+Study+LifeStage=Genomic+Study+LifeStage&Disease+Info=Disease+Info&Human+Ortholog=Human+Ortholog&Reference=Reference&Gene+Ontology+Association=Gene+Ontology+Association&Concise+Description=Concise+Description&Automated+Description=Automated+Description&Expression+Cluster+Summary=Expression+Cluster+Summary&geneInput=let-60&geneNamesFile=
# sample
# B0213.1
# zxcv
# B0524.7
# B0564.1
# B0213.1
# let-60
# abc-1


use Jex;			# untaint, getHtmlVar, cshlNew, getPgDate
use strict;
use diagnostics;
use CGI;
use LWP::UserAgent;		# for variation_nameserver file
use LWP::Simple;		# for simple gets
use DBI;
use Tie::IxHash;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $ua = new LWP::UserAgent;


my $query = new CGI;
my $host = $query->remote_host();		# get ip address

# my $base_url = 'http://athena.caltech.edu/fragmine/';	# replaced with ftp 2016 06 03
# my $base_url = 'ftp://caltech.wormbase.org/pub/wormbase/simpleMine/';	# replaced with local files 2016 06 09
my $files_path = '/home/acedb/wen/simplemine/sourceFile/';
my $files_path_base = '/home/acedb/wen/simplemine/sourceFile/';

my (@filesfull) = <${files_path}/*.csv>;		# get all .csv files for Wen.  2018 02 26
my @files; foreach my $file (sort @filesfull) { $file =~ s/$files_path\///; push @files, $file; }
# my @files = qw( WBGeneName.csv RNAiAllelePheno.csv GeneTissueLifeStage.csv GeneDiseaseHumanOrtholog.csv GeneReference.csv GeneAllele.csv );

&process();                     # see if anything clicked

sub process {                   # see if anything clicked
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'query list') {                     &queryListTextarea(); }
    elsif ($action eq 'query uploaded file') {       &queryListUploadedFile(); }
    elsif ($action eq 'all genes in this species') { &queryListCelegansFile(); }
    else { &frontPage(); }
}

sub queryListTextarea {
  my ($var, $geneInput)   = &getHtmlVar($query, 'geneInput');
  &queryList($geneInput);
} # sub queryListTextarea

sub queryListUploadedFile {
  my $upload_filehandle = $query->upload("geneNamesFile");
  my $geneInput = '';
  while ( <$upload_filehandle> ) { $geneInput .= $_; }	# add directly to variable, no need for temp file
#   my $date = &getSimpleSecDate() + rand();		# probabilistically unique file
#   my $tempfile = '/tmp/fraqmine_upload_' . $date;	# temporary file location
#   open ( UPLOADFILE, ">$tempfile" ) or die "Cannot create $tempfile : $!";
#   binmode UPLOADFILE;
#   while ( <$upload_filehandle> ) { print UPLOADFILE; }
#   close UPLOADFILE or die "Cannot close $tempfile : $!";
#   $/ = undef;
#   open (IN, "$tempfile") or die "Cannot open $tempfile : $!";
#   my $geneInput = <IN>;
#   close (IN) or die "Cannot close $tempfile : $!";
#   $/ = "\n";
#   if (-e $tempfile) { unlink($tempfile); }		# remove tempfile
  &queryList($geneInput);
} # sub queryListUploadedFile

sub queryListCelegansFile {				# from a flat file that Wen generates  2017 10 09
#   my $infile = $files_path . 'AllCelegansGenes.txt';
  (my $var, my $species)              = &getHtmlVar($query, 'species');
  my $infile = $files_path_base . $species . '/GeneName.csv';
#   $/ = undef;
  my $geneInput = '';
  open (IN, "$infile") or die "Cannot open $infile : $!";
  my $fileHeader = <IN>;
  while (my $line = <IN>) {
    chomp $line;
    my (@line) = split/\t/, $line;
    $geneInput .= "$line[0]\n";
  }
  close (IN) or die "Cannot close $infile : $!";
#   $/ = "\n";
  &queryList($geneInput);
} # sub queryListCelegansFile

sub populateConcise {
  my ($dataMapHashref)    = @_;
  my %dataMap             = %$dataMapHashref;
  my $file                = 'Concise';
  $dataMap{$file}{header} = qq(Description Type\tDescription Text);
  $dataMap{$file}{count}  = 2;
  my $result = $dbh->prepare( "SELECT con_wbgene.con_wbgene, con_desctype.con_desctype, con_desctext.con_desctext FROM con_desctext, con_desctype, con_wbgene WHERE con_wbgene.joinkey = con_desctype.joinkey AND con_wbgene.joinkey = con_desctext.joinkey AND con_wbgene.joinkey NOT IN (SELECT joinkey FROM con_nodump WHERE con_nodump = 'NO DUMP');" );
  $result->execute();
  my %concise;
  while (my @row = $result->fetchrow()) {
    my $wbgene   = $row[0];
    my $desctype = $row[1];
    my $desctext = $row[2];
    if ($desctext =~ m/\n/) { $desctext =~ s/\n/ /g; }
    $concise{$wbgene}{$desctype} = $desctext;	# only look at concise or automated, only display one, prioritizing concise
  }
  foreach my $wbgene (sort keys %concise) {
    if ($concise{$wbgene}{Concise_description}) {
#         push @{ $dataMap{$wbgene} }, qq($wbgene\tConcise_description\t$concise{$wbgene}{Concise_description});
        $dataMap{$file}{$wbgene} = qq(Concise_description\t$concise{$wbgene}{Concise_description}); }
      elsif ($concise{$wbgene}{Automated_description}) {
#         push @{ $dataMap{$wbgene} }, qq($wbgene\tAutomated_description\t$concise{$wbgene}{Automated_description});
        $dataMap{$file}{$wbgene} = qq(Automated_description\t$concise{$wbgene}{Automated_description}); } }
  return \%dataMap;
} # sub populateConcise


sub populateFromAthena {
#   my ($filesHref) = @_;
#   my (@files) = @$filesHref;

  my ($species, $caseSensitiveToggle) = @_;
  my $files_path = $files_path_base . $species . '/';
  my (@filesfull) = <${files_path}*.csv>;               # get all .csv files for Wen.  2018 02 26
  my @files; foreach my $file (sort @filesfull) { $file =~ s/$files_path//; push @files, $file; }
  my $errMessage;
  my %dataMap;
  my %geneNameToId;

  foreach my $file (@files) {
#     my $dataUrl = $base_url . $file;			# to get from Athena or ftp
#     my $data    = get $dataUrl;			# to get from Athena or ftp
    my $filepath = $files_path . $file;			# to get from local files
    $/ = undef;
    open (IN, "<$filepath") or die "Cannot open $filepath : $!";
    my $data = <IN>;
    close (IN) or die "Cannot close $filepath : $!";
    $/ = "\n";
    my (@lines) = split/\n/, $data;
    my @columns = ();
    foreach my $i (0 .. $#lines) {
      my $line = $lines[$i];
      chomp $line;
      my ($wbgene, @rest) = split/\t/, $line;
#       my $data = join"\t", @rest;
      if ($i == 0) {
#           $fullHeader .= $data; 
          my $count = scalar(@rest);
#           (@columns) = @rest;
# to keep first column as data from files
          (@columns) = split/\t/, $line;
          $dataMap{$file}{header} = $data;
          $dataMap{$file}{count}  = $count;
        }
        else {
#           if ($file eq 'WBGeneName.csv') {
          if ($file eq 'GeneName.csv') {
            my $lcwbgene = lc($wbgene);
#             $geneNameToId{$lcwbgene} = $wbgene;
            $geneNameToId{$lcwbgene}{$wbgene}++;
            foreach my $category (@rest) {
              my (@indNames) = split/,/, $category;
              foreach my $name (@indNames) {
                $name =~ s/^\s+//; $name =~ s/\s+$//;
                unless ($name eq 'N.A.') { 
                  my $lcname = lc($name);
#                   $geneNameToId{$lcname} = $wbgene;
                  $geneNameToId{$lcname}{$wbgene}++; } } } }
#           $dataMap{$file}{$wbgene} = $data; 

#           my (@data) = split/\t/, $data;
#           for my $i (0 .. $#data) {
#             $dataMap{$columns[$i]}{$wbgene} = $data[$i]; }
# to keep first column as data from files
          my (@data) = split/\t/, $line;
          for my $i (0 .. $#data) {
            $dataMap{$columns[$i]}{$wbgene} = $data[$i]; }

    } }
  } # foreach my $file (@files)
  return ($errMessage, \%dataMap, \%geneNameToId);
} # sub populateFromAthena

sub queryList {
  my ($geneInput) = @_;					# gene list from form textarea or uploaded file
#   print "Content-type: text/html\n\n";
  my ($var, $outputFormat)         = &getHtmlVar($query, 'outputFormat');
  ($var, my $caseSensitiveToggle)  = &getHtmlVar($query, 'caseSensitiveToggle');
  ($var, my $duplicatesToggle)     = &getHtmlVar($query, 'duplicatesToggle');
  ($var, my $possibleheaders)      = &getHtmlVar($query, 'headers');
  ($var, my $species)              = &getHtmlVar($query, 'species');
  my @possibleheaders = split/\t/, $possibleheaders;
  my @headers;
  foreach my $header (@possibleheaders) {
    ($var, my $headervalue)        = &getHtmlVar($query, $header);
    if ($headervalue) { push @headers, $header; } }
  unless ($outputFormat) { $outputFormat = 'download'; }
  if ($outputFormat eq 'download') {
      print qq(Content-type: application/x-download\n);
      print qq(Content-Disposition: attachment; filename="simplemine_results.txt"\n\n); }
    elsif ($outputFormat eq 'plain') {
      print "Content-type: text/plain\n\n"; }
    elsif ($outputFormat eq 'html') {
      print "Content-type: text/html\n\n"; }
    else {
      print qq(Content-type: application/x-download\n);
      print qq(Content-Disposition: attachment; filename="simplemine_results.txt"\n\n); }
  my $output = '';
  my $additionalOutput = "";
#   my $geneNameToIdHashref = &populateGeneMap();
#   my %geneNameToId        = %$geneNameToIdHashref;
#   my ($errMessage, $dataMapHashref, $geneNameToIdHashref) = &populateFromAthena(\@files);
  my ($errMessage, $dataMapHashref, $geneNameToIdHashref) = &populateFromAthena($species, $caseSensitiveToggle);

  my %dataMap          = %$dataMapHashref;
  my %geneNameToId     = %$geneNameToIdHashref;
# for concise description, removed 2018 10 02
#   ($var, my $concisedescriptionFlag)        = &getHtmlVar($query, "Concise Description");
#   if ($concisedescriptionFlag) {
#     ($dataMapHashref)    = &populateConcise(\%dataMap);
#     %dataMap             = %$dataMapHashref; }
#   my $dataHeader = qq(Your Input\tGene);
  my $dataHeader = qq(Your Input);
#   foreach my $file (@files, "Concise") { $dataHeader .= "\t$dataMap{$file}{header}"; }
  foreach my $header (@headers) { $dataHeader .= "\t$header"; }
#   foreach my $file ("Concise") {  $dataHeader .= "\t$dataMap{$file}{header}"; }
# for concise description, removed 2018 10 02
#   if ($concisedescriptionFlag) {
#     push @headers, "Concise";
#     $dataHeader .= "\t$dataMap{Concise}{header}"; }
  $output .= qq($dataHeader\n);
  
  if ($geneInput =~ m/[^\w\d\.\-\(\)\/]/) { $geneInput =~ s/[^\w\d\.\-\(\)\/]+/ /g; }
  my (@genes) = split/\s+/, $geneInput;
  my %alreadyEntered;
  foreach my $geneEntered (@genes) {
    my ($gene) = lc($geneEntered);
    next if ( ($alreadyEntered{$gene}) && ($duplicatesToggle eq 'merge') );
    my $geneId = 'not found';
    my $geneData;
    if ($geneNameToId{$gene}) {
#         $geneId = $geneNameToId{$gene};
        my $count = 0; my $thisEntry;
        foreach my $geneId (sort keys %{ $geneNameToId{$gene} }) {
          $geneData = ''; $count++;
          foreach my $header (@headers) {
            if ($dataMap{$header}{$geneId}) {
                $geneData .= "\t$dataMap{$header}{$geneId}"; }
              else {
                $geneData .= "\tN.A."; }
          } # foreach my $header (@files, "Concise")
          $thisEntry .= qq(${geneEntered}$geneData\n);
        } # foreach my $geneId (sort keys %{ $geneNameToId{$gene} })
        if ($count == 1) { $output .= $thisEntry; }
          else { 
            $output .= qq($geneEntered\tMultiple entries : $count\n);
            unless ($alreadyEntered{$gene}) {			# Chris doesn't want duplicate entries that have multiple genes to show up duplicate times at the bottom
              $additionalOutput .= qq($thisEntry); } }
      }
      else {
        $geneData = "not found";
        $output .= qq($geneEntered\t$geneData\n); }
    $alreadyEntered{$gene}++;
#     $output .= qq($geneEntered\t$geneData\n);
  } # foreach my $gene (@genes)
  if ($additionalOutput) { 
    $output .= "Multiple Output Below\n";
    $output .= $additionalOutput; }
  if ($output =~ m/\n$/) { $output =~ s/\n$//; }
  if ($outputFormat eq 'html') {
    $output =~ s|\t|</td><td style="max-width:50ch; vertical-align: top; overflow-wrap: break-word">|g;
    $output =~ s|\n|</td></tr>\n<tr><td style="max-width:50ch; vertical-align: top; overflow-wrap: break-word">|g;
    $output = qq(<table border="1"><tr><td style="max-width:50ch; vertical-align: top; overflow-wrap: break-word">$output</td></tr></table>); }
  print qq($output);
} # sub queryList

sub frontPage {
  print "Content-type: text/html\n\n";
  my $title = 'Simple Mine';
  my ($header, $footer) = &cshlNew($title);
  print "$header\n";		# make beginning of HTML page
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  &showFraqForm();
  print "$footer"; 		# make end of HTML page
} # sub frontPage

# sub populateGeneMap {
#   my %geneNameToId;
#   my @tables = qw( gin_wbgene gin_seqname gin_synonyms gin_locus );
# #   my @tables = qw( gin_seqname gin_synonyms gin_locus );
#   foreach my $table (@tables) {
#     my $result = $dbh->prepare( "SELECT * FROM $table;" );
#     $result->execute();
#     while (my @row = $result->fetchrow()) {
#       my $id                 = "WBGene" . $row[0];
#       my $name               = $row[1];
#       my ($lcname)           = lc($name);
#       $geneNameToId{$lcname} = $id; } }
#   return \%geneNameToId;
# } # sub populateGeneMap
 

sub showFraqForm {
  print qq(<h3>Simple Gene Queries</h3><br/>\n);
#   print qq(Gene mappings to gene identifiers, Tissue-LifeStage, RNAi-Phenotype, Allele-Phenotype, ConciseDescription.<br/><br/>);
  print qq(Easy Retrieval of <a href="https://wiki.wormbase.org/index.php/UserGuide:SimpleMine" target="_blank">Essential Gene Information</a><br/><br/>);
  print qq(<form method="post" action="simplemine.cgi" enctype="multipart/form-data">\n);
#   my $select_size = scalar @files;
#   print qq(Select your datatype :<br>\n);
#   print qq(<select name="sourceFile" size="$select_size">);
#   foreach my $file (@files) {
#     print qq(<option>$file</option>);
#   } # foreach my $file (@files)
#   print qq(</select>\n);
#   print qq(<br/><br/>\n);
#   print qq(Enter list of gene names here (one gene per line, or separate with spaces, not punctuation) :<br/>);

#   print qq(Enter list of gene names here :<br/>);
#   print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="80"></textarea><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query list"><br/>\n);
#   print qq(<br/><br/>\n);
#   print qq(Upload a file with gene names :<br/>);
#   print qq(<input type="file" name="geneNamesFile" /><br/>);
#   print qq(<br/><input type="submit" name="action" value="query uploaded file"><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query all C elegans"><br/>\n);
#   print qq(<br/><br/>);
#   print qq(<input type="radio" name="outputFormat" value="download" checked="checked"> download<br/>);
#   print qq(<input type="radio" name="outputFormat" value="html"> html<br/>);
#   print qq(<br/>);
#   print qq(<input type="radio" name="duplicatesToggle" value="merge" checked="checked"> merge duplicate genes<br/>);
#   print qq(<input type="radio" name="duplicatesToggle" value="duplicates"> allow duplicate genes<br/>);
# 
#   print qq(<br/>);
#   my %columns;
#   tie %columns, "Tie::IxHash";
#   foreach my $file (@files) {
#     my $filepath = $files_path . $file;			# to get from local files
#     open (IN, "<$filepath") or die "Cannot open $filepath : $!";
#     my $header = <IN>;
#     chomp $header;
#     close (IN) or die "Cannot close $filepath : $!";
#     my (@columns) = split/\t/, $header;
#     foreach (@columns) { $columns{$_}++; } }
#   delete $columns{'Gene'};				# not sure why need to delete this
# #   $columns{"Concise Description"}++;			# coming from postgres
#   my $headers = join"\t", keys %columns;
#   print qq(<input type="hidden" name="headers" value="$headers"/>);
#   print qq(<input type="checkbox" id="select all" name="select all" value="select all" checked="checked" onclick="var inputs = document.getElementsByTagName('input'); for(var i = 0; i < inputs.length; i++) { if(inputs[i].type == 'checkbox') { inputs[i].checked = document.getElementById('select all').checked; } }"> Set All Checkboxes<br/><br/>);	# set state of all checkboxes to this state
#   foreach my $column (keys %columns) {
#     print qq(<input type="checkbox" name="$column" value="$column" checked="checked"> $column<br/>); }
# # for concise description, removed 2018 10 02
# #   print qq(<input type="checkbox" name="Concise Description" value="Concise Description" checked="checked"> Concise Description<br/>);				# not part of general headers, comes from postgres
# 
#   print qq(</form>\n);

  my ($var, $geneInput)  = &getHtmlVar($query, 'geneInput');
  my ($var, $species)  = &getHtmlVar($query, 'species');
  unless ($species) { $species = 'c_elegans'; }

  my %species;
  tie %species, "Tie::IxHash";
  %species = (
    "b_malayi" => "Brugia malayi",
    "c_brenneri" => "Caenorhabditis brenneri",
    "c_briggsae" => "Caenorhabditis briggsae",
    "c_elegans" => "Caenorhabditis elegans",
    "c_japonica" => "Caenorhabditis japonica",
    "c_remanei" => "Caenorhabditis remanei",
    "o_volvulus" => "Onchocerca volvulus",
    "p_pacificus" => "Pristionchus pacificus",
    "s_ratti" => "Strongyloides ratti",
    "mix" => "Any species (slow)"
  );
  my $select_size = scalar keys %species;
#   $select_size++;                       # to account for any species added at the end
  print qq(<span style="font-weight:bold">Step 1: Select species of the genes that you will enter (Required)</span>\n);
  print qq(<span style="color: rgb(6, 199, 41); font-weight: bold; cursor: pointer;" title="'Any Species' search will return matches in all species with much longer time to load the results." onmouseover="this.style.cursor='pointer'" onclick="if (document.getElementById('species_help').style.display === 'none') { document.getElementById('species_help').style.display = ''; } else { document.getElementById('species_help').style.display = 'none'; } ">?</span><br>\n);
  print qq(<span id="species_help" style="display: none; font-weight:normal">"Any Species" search will return matches in all species with much longer time to load the results.<br></span>\n);
  print qq(<select id="species" name="species" size="$select_size" onchange="document.getElementById('query_list').disabled=false; document.getElementById('query_list_text').style.display='none'; document.getElementById('query_uploaded_file').disabled=false; document.getElementById('query_uploaded_file_text').style.display='none';">);
#   foreach my $speciesOption (sort { $species{$a} cmp $species{$b} } keys %species) {
  foreach my $speciesOption (keys %species) {
    my $selected = ''; if ($speciesOption eq $species) { $selected = 'selected="selected"'; }
    print qq(<option $selected value="$speciesOption">$species{$speciesOption}</option>);
  }
#   print qq(<option value="mix">Any species (slow)</option>);
  print qq(</select>\n);
  print qq(<br/><br/>\n);

  print qq(<span style="font-weight:bold">Step 2: Choose input/output format</span><br/>);
  print qq(<input type="radio" name="caseSensitiveToggle" value="caseInsensitive" checked="checked"> case insensitive input<br/>);
  print qq(<input type="radio" name="caseSensitiveToggle" value="caseSensitive"> case sensitive input<br/>);
  print qq(<br/>);

  print qq(<input type="radio" name="outputFormat" value="html" checked="checked"> display results in HTML format<br/>);
  print qq(<input type="radio" name="outputFormat" value="download"> download results as a tab-delimited file);
  print qq(<span style="color: rgb(6, 199, 41); font-weight: bold; cursor: pointer;" title="Some data fields may contain too many contents to fit into a cell in Excel. To avoid Excel converting some gene names (such as mar-5 and oct-1) into dates, the cell format has to be 'text' rather than 'general'." onmouseover="this.style.cursor='pointer'" onclick="if (document.getElementById('download_help').style.display === 'none') { document.getElementById('download_help').style.display = ''; } else { document.getElementById('download_help').style.display = 'none'; } ">?</span><br>\n);
  print qq(<span id="download_help" style="display: none; font-weight:normal">Some data fields may contain too many contents to fit into a cell in Excel. To avoid Excel converting some gene names (such as mar-5 and oct -1) into dates, the cell format has to be 'text' rather than 'general'.<br></span>\n);
  print qq(<br/>);

  print qq(<input type="radio" name="duplicatesToggle" value="merge" checked="checked"> merge duplicate gene entries in results<br/>);
  print qq(<input type="radio" name="duplicatesToggle" value="duplicates"> keep duplicate gene entries in results<br/>);
  print qq(<br/>);

  print qq(<span style="font-weight:bold">Step 3: Choose types of information to retrieve</span><br/>);
  my %columns;
  tie %columns, "Tie::IxHash";

# from a multi-line category file
  my $filepath = '/home/acedb/wen/simplemine/multiSpeSimpleMine/category_headers';
  open (IN, "<$filepath") or die "Cannot open $filepath : $!";
  while (my $line = <IN>) {
    chomp $line;
    my @line = split/\t/, $line;
    my $category = shift @line;
    print qq(<br/><span style="font-style: italic">$category</span><br/>\n);
    foreach my $column (@line) {
      next unless $column;
      $columns{$column}++;
      print qq(<input type="checkbox" name="$column" value="$column" checked="checked"> $column<br/>); }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $filepath : $!";
  print qq(<br/>);

# from a single line source file
#   my $filepath = $files_path_base . 'headers';                        # to get from local files
#   open (IN, "<$filepath") or die "Cannot open $filepath : $!";
#   my $header = <IN>;
#   chomp $header;
#   close (IN) or die "Cannot close $filepath : $!";
#   my (@columns) = split/\t/, $header;
#   foreach (@columns) { $columns{$_}++; }
#   delete $columns{'Gene'};                              # not sure why need to delete this
#   foreach my $column (keys %columns) {
#     print qq(<input type="checkbox" name="$column" value="$column" checked="checked"> $column<br/>); }

  my $headers = join"\t", keys %columns;
  print qq(<input type="hidden" name="headers" value="$headers"/>);
  print qq(<input type="checkbox" id="select all" name="select all" value="select all" checked="checked" onclick="var inputs = document.getElementsByTagName('input'); for(var i = 0; i < inputs.length; i++) { if(inputs[i].type == 'checkbox') { inputs[i].checked = document.getElementById('select all').checked; } }"> Set All Checkboxes<br/><br/>);      # set state of all checkboxes to this state

  print qq(<br/>\n);
  print qq(<span style="font-weight:bold">Step 4: Query <input type="submit" name="action" id="query_all" value="all genes in this species"> or</span><br/>\n);
  print qq(Enter or upload a list of gene names here (one gene per line)<br/>);
#   print qq((For example:  goa-1, C26C6.2, CELE_C26C6.2, CE05311, NM_059707.6, NP_492108.1)<br/>);
#   print qq(<span style="font-weight:bold">Step 4: Enter or upload a list of gene names here</span><br/>);
#   print qq(One gene per line, enter official MOD gene names or IDs, NCBI, UniProt, PANTHER or ENSEMBL IDs)<br/>);  # some genes have spaces in them, e.g. fly gene "suppressor of white-apricot"
  print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="80" placeholder="goa-1\nC26C6.2\nCELE_C26C6.2\nCE05311\nNM_059707.6\nNP_492108.1">$geneInput</textarea><br/>\n);
#   print qq(<br/><input type="submit" name="action" id="query_list" value="query list" disabled><span id="query_list_text">Select a species to enable this button</span><br/>\n);
  print qq(<br/><input type="submit" name="action" id="query_list" value="query list"><br/>\n);
  print qq(<br/><br/>\n);
  print qq(Upload a file with gene names :<br/>);
  print qq(<input type="file" name="geneNamesFile" /><br/>);
#   print qq(<br/><input type="submit" name="action" id="query_uploaded_file" value="query uploaded file" disabled><span id="query_uploaded_file_text">Select a species to enable this button</span><br/>\n);
  print qq(<br/><input type="submit" name="action" id="query_uploaded_file" value="query uploaded file"><span id="query_uploaded_file_text">Select a species to enable this button</span><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query all C elegans"><br/>\n);
  print qq(<br/><br/>);

  print qq(</form>\n);


#   print qq(Enter list of gene names here :<br/>);
#   print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="80"></textarea><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query list"><br/>\n);
#   print qq(<br/><br/>\n);
#   print qq(Upload a file with gene names :<br/>);
#   print qq(<input type="file" name="geneNamesFile" /><br/>);
#   print qq(<br/><input type="submit" name="action" value="query uploaded file"><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query all C elegans"><br/>\n);
#   print qq(<br/><br/>);
#   print qq(<input type="radio" name="outputFormat" value="download" checked="checked"> download<br/>);
#   print qq(<input type="radio" name="outputFormat" value="html"> html<br/>);
#   print qq(<br/>);
#   print qq(<input type="radio" name="duplicatesToggle" value="merge" checked="checked"> merge duplicate genes<br/>);
#   print qq(<input type="radio" name="duplicatesToggle" value="duplicates"> allow duplicate genes<br/>);
# 
#   print qq(<br/>);
#   my %columns;
#   tie %columns, "Tie::IxHash";
#   foreach my $file (@files) {
#     my $filepath = $files_path . $file;			# to get from local files
#     open (IN, "<$filepath") or die "Cannot open $filepath : $!";
#     my $header = <IN>;
#     chomp $header;
#     close (IN) or die "Cannot close $filepath : $!";
#     my (@columns) = split/\t/, $header;
#     foreach (@columns) { $columns{$_}++; } }
#   delete $columns{'Gene'};				# not sure why need to delete this
# #   $columns{"Concise Description"}++;			# coming from postgres
#   my $headers = join"\t", keys %columns;
#   print qq(<input type="hidden" name="headers" value="$headers"/>);
#   print qq(<input type="checkbox" id="select all" name="select all" value="select all" checked="checked" onclick="var inputs = document.getElementsByTagName('input'); for(var i = 0; i < inputs.length; i++) { if(inputs[i].type == 'checkbox') { inputs[i].checked = document.getElementById('select all').checked; } }"> Set All Checkboxes<br/><br/>);	# set state of all checkboxes to this state
#   foreach my $column (keys %columns) {
#     print qq(<input type="checkbox" name="$column" value="$column" checked="checked"> $column<br/>); }
# # for concise description, removed 2018 10 02
# #   print qq(<input type="checkbox" name="Concise Description" value="Concise Description" checked="checked"> Concise Description<br/>);				# not part of general headers, comes from postgres
# 
#   print qq(</form>\n);
} # sub showFraqForm


sub showIp {
  print "Content-type: text/html\n\n";
  my $title = 'Your IP';
  my ($header, $footer) = &cshlNew($title);
  print "$header\n";		# make beginning of HTML page
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  print "Your IP is : $host<BR>\n";
  print "$footer"; 		# make end of HTML page
} # sub showIp

__END__

#   my ($var, $sourceFile)  = &getHtmlVar($query, 'sourceFile');
#   my %dataMap;
#   my $dataHeader;
#   if ($sourceFile eq 'GeneTissueLifeStage') {
#       my $dataUrl = 'http://athena.caltech.edu/GeneTissueLifeStage/GeneTissueLifeStage.csv';
#       my $data    = get $dataUrl;
#       my (@lines) = split/\n/, $data;
#       $dataHeader = shift @lines;
#       foreach my $line (@lines) {
#         chomp $line;
#         my ($wbgene, @rest) = split/\t/, $line;
#         push @{ $dataMap{$wbgene} }, $line; } }
#     elsif ($sourceFile eq 'ConciseDescription') {
#       $dataHeader = qq(Gene ID\tDescription Type\tDescription Text);
#       my $result = $dbh->prepare( "SELECT con_wbgene.con_wbgene, con_desctype.con_desctype, con_desctext.con_desctext FROM con_desctext, con_desctype, con_wbgene WHERE con_wbgene.joinkey = con_desctype.joinkey AND con_wbgene.joinkey = con_desctext.joinkey AND con_wbgene.joinkey NOT IN (SELECT joinkey FROM con_nodump WHERE con_nodump = 'NO DUMP');" );
#       $result->execute();
#       my %concise;
#       while (my @row = $result->fetchrow()) {
#         my $wbgene   = $row[0];
#         my $desctype = $row[1];
#         my $desctext = $row[2];
#         $concise{$wbgene}{$desctype} = $desctext;	# only look at concise or automated, only display one, prioritizing concise
#       }
#       foreach my $wbgene (sort keys %concise) {
#         if ($concise{$wbgene}{Concise_description}) {
#             push @{ $dataMap{$wbgene} }, qq($wbgene\tConcise_description\t$concise{$wbgene}{Concise_description}); }
#           elsif ($concise{$wbgene}{Automated_description}) {
#           push @{ $dataMap{$wbgene} }, qq($wbgene\tAutomated_description\t$concise{$wbgene}{Automated_description}); } } }
#     elsif ($sourceFile eq 'RNAiPhenotype') {
#       my $dirListUrl = 'ftp://ftp.wormbase.org/pub/wormbase/releases/current-development-release/ONTOLOGY/';
#       my $dirList    = get $dirListUrl;
#       my ($filename) = $dirList =~ m/(rnai_phenotypes.WS\d+.wb)/;
#       my $fileUrl    = $dirListUrl . $filename;
#       my $data       = get $fileUrl;
#       my (@lines)    = split/\n/, $data;
#       $dataHeader    = '';	# no header in this file
#       foreach my $line (@lines) {
#         chomp $line;
#         my ($wbgene, @rest) = split/\t/, $line;
#         push @{ $dataMap{$wbgene} }, $line; } }
#     else { print qq(You must select a valid datatype\n\n); }
