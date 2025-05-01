#!/usr/bin/env perl 

# get back dead or renamed genes

# test with
# kap-1
# ref-2
# WBGene00000194
# goa-1
# eat-16
# WBGene00000359
# Y105E8B.m
# WBGene00006454
#
# First pass.  For Wen.  2020 07 22
#
# Source file has Valid, Ambiguous, and Obsolete now.  2020 07 23
#
# New file source with gene status in its own column.  2020 07 27
#
# Added link to source data for users to download.  2020 08 06
#
# Updated link to source data for users to download.  2025 05 01



use Jex;			# untaint, getHtmlVar, cshlNew, getPgDate
use strict;
use diagnostics;
use CGI;
use LWP::UserAgent;		# for variation_nameserver file
use LWP::Simple;		# for simple gets
use DBI;
use Tie::IxHash;
use Dotenv -load => '/usr/lib/.env';

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";

my $result;

my $ua = new LWP::UserAgent;


my $query = new CGI;
my $host = $query->remote_host();		# get ip address

my $files_path_base = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/pub/wen/simplemine/GeneNameSanitizer/';
# my $files_path_base = '/home/acedb/wen/simplemine/GeneNameSanitizer/';
# my $sourceFile = '/home/acedb/wen/simplemine/GeneNameSanitizer/GeneNameHistory.csv';

&process();                     # see if anything clicked

sub process {                   # see if anything clicked
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'query list') {                     &queryListTextarea(); }
    elsif ($action eq 'query uploaded file') {       &queryListUploadedFile(); }
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
  &queryList($geneInput);
} # sub queryListUploadedFile

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
      print qq(Content-Disposition: attachment; filename="gene_name_sanitizer_results.txt"\n\n); }
    elsif ($outputFormat eq 'plain') {
      print "Content-type: text/plain\n\n"; }
    elsif ($outputFormat eq 'html') {
      print "Content-type: text/html\n\n"; }
    else {
      print qq(Content-type: application/x-download\n);
      print qq(Content-Disposition: attachment; filename="gene_name_sanitizer_results.txt"\n\n); }

  my $output = '';

  my $additionalOutput = "";
#   my $geneNameToIdHashref = &populateGeneMap();
#   my %geneNameToId        = %$geneNameToIdHashref;
#   my ($errMessage, $dataMapHashref, $geneNameToIdHashref) = &populateFromAthena(\@files);
#   my ($errMessage, $dataMapHashref, $geneNameToIdHashref) = &populateFromAthena($species, $caseSensitiveToggle);

  my ($errMessage, $dataMapHashref, $headers) = &populateGeneNameHistory();
  $output .= qq($headers\n);

  my %dataMap          = %$dataMapHashref;

  if ($geneInput =~ m/[^\w\d\.\-\(\)\/]/) { $geneInput =~ s/[^\w\d\.\-\(\)\/]+/ /g; }
  my (@genes) = split/\s+/, $geneInput;
  my %alreadyEntered;

# To display in sections if data was broken up that way  2020 07 23 way
#   my (@headers) = split/\t/, $headers;
#   for (my $i = 1; $i <= $#headers; $i++) { 
#     my $section = '';
# #     $headers{$i} = $headers[$i]; 
#     foreach my $geneEntered (@genes) {
#       my ($gene) = lc($geneEntered);
# #       my ($gene) = $geneEntered;
#       next if ($alreadyEntered{$gene});
#       if ($dataMap{$gene}{$i}) { 
#         $alreadyEntered{$gene}++;
#         $section .= qq($geneEntered\t$dataMap{$gene}{$i}\n);
#       }
#     }
#     if ($section) { 
#       $output .= qq(<b>Part $i</b>\t$headers[$i]\n);
#       $output .= qq($section);
#       $output .= qq(\t\n);
#     }
#   }

  foreach my $geneEntered (@genes) {
    my ($gene) = lc($geneEntered);
#     my ($gene) = $geneEntered;
    next if ($alreadyEntered{$gene});
    if ($dataMap{$gene}) { 
      $alreadyEntered{$gene}++;
      $output .= qq($dataMap{$gene}\n);
    }
  }
  foreach my $geneEntered (@genes) {
    my ($gene) = lc($geneEntered);
#     my ($gene) = $geneEntered;
    next if ($alreadyEntered{$gene});
    $output .= qq($geneEntered\tNot Found\n);
  }

#   my $section = '';
#   if ($section) { 
#     $output .= qq(<b>Part 4</b>\tNot Found\n);
#     $output .= qq($section);
#   }



# # for concise description, removed 2018 10 02
# #   ($var, my $concisedescriptionFlag)        = &getHtmlVar($query, "Concise Description");
# #   if ($concisedescriptionFlag) {
# #     ($dataMapHashref)    = &populateConcise(\%dataMap);
# #     %dataMap             = %$dataMapHashref; }
# #   my $dataHeader = qq(Your Input\tGene);
#   my $dataHeader = qq(Your Input);
# #   foreach my $file (@files, "Concise") { $dataHeader .= "\t$dataMap{$file}{header}"; }
#   foreach my $header (@headers) { $dataHeader .= "\t$header"; }
# #   foreach my $file ("Concise") {  $dataHeader .= "\t$dataMap{$file}{header}"; }
# # for concise description, removed 2018 10 02
# #   if ($concisedescriptionFlag) {
# #     push @headers, "Concise";
# #     $dataHeader .= "\t$dataMap{Concise}{header}"; }
#   $output .= qq($dataHeader\n);
#   
#   if ($geneInput =~ m/[^\w\d\.\-\(\)\/]/) { $geneInput =~ s/[^\w\d\.\-\(\)\/]+/ /g; }
#   my (@genes) = split/\s+/, $geneInput;
#   my %alreadyEntered;
#   foreach my $geneEntered (@genes) {
# #     my ($gene) = lc($geneEntered);
#     my ($gene) = $geneEntered;
#     next if ( ($alreadyEntered{$gene}) && ($duplicatesToggle eq 'merge') );
#     my $geneId = 'not found';
#     my $geneData;
# 
# #     if ($geneNameToId{$gene}) {
# # #         $geneId = $geneNameToId{$gene};
# #         my $count = 0; my $thisEntry;
# #         foreach my $geneId (sort keys %{ $geneNameToId{$gene} }) {
# #           $geneData = ''; $count++;
# #           foreach my $header (@headers) {
# #             if ($dataMap{$header}{$geneId}) {
# #                 $geneData .= "\t$dataMap{$header}{$geneId}"; }
# #               else {
# #                 $geneData .= "\tN.A."; }
# #           } # foreach my $header (@files, "Concise")
# #           $thisEntry .= qq(${geneEntered}$geneData\n);
# #         } # foreach my $geneId (sort keys %{ $geneNameToId{$gene} })
# #         if ($count == 1) { $output .= $thisEntry; }
# #           else { 
# #             $output .= qq($geneEntered\tMultiple entries : $count\n);
# #             unless ($alreadyEntered{$gene}) {			# Chris doesn't want duplicate entries that have multiple genes to show up duplicate times at the bottom
# #               $additionalOutput .= qq($thisEntry); } }
#       if ($dataMap{$gene}) {
#         $output .= qq($dataMap{$gene}\n)
#       }
#       else {
#         $geneData = "not found";
#         $output .= qq($geneEntered\t$geneData\n); }
#     $alreadyEntered{$gene}++;
# #     $output .= qq($geneEntered\t$geneData\n);
#   } # foreach my $gene (@genes)
#   if ($additionalOutput) { 
#     $output .= "Multiple Output Below\n";
#     $output .= $additionalOutput; }



  if ($output =~ m/\n$/) { $output =~ s/\n$//; }
  if ($outputFormat eq 'html') {
    $output =~ s|\t|</td><td style="max-width:50ch; vertical-align: top; overflow-wrap: break-word; height: 20px; border: 1px solid black">|g;
    $output =~ s|\n|</td></tr>\n<tr><td style="max-width:50ch; vertical-align: top; overflow-wrap: break-word; height: 20px; border: 1px solid black">|g;
    $output = qq(<table style="border: 1px solid black; border-collapse: collapse"><tr><td style="max-width:50ch; vertical-align: top; overflow-wrap: break-word; height: 20px; border: 1px solid black">$output</td></tr></table>); }
  print qq($output);
} # sub queryList

sub frontPage {
  print "Content-type: text/html\n\n";
  my $title = 'Gene Name Sanitizer';
  my ($header, $footer) = &cshlNew($title);
  print "$header\n";		# make beginning of HTML page
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  &showSanitizeForm();
  print "$footer"; 		# make end of HTML page
} # sub frontPage


sub showSanitizeForm {
  print qq(<h3>Gene Name Sanitizer</h3><br/>\n);
#   print qq(Easy Retrieval of <a href="https://wiki.wormbase.org/index.php/UserGuide:SimpleMine" target="_blank">Essential Gene Information</a><br/><br/>);
#   print qq(Screen a list of gene identifiers to locate deprecated or controversial gene names.<br/><br/>Examples of how gene names can change:<br/><br/>Example 1: WBGene00000087: Merged into axe-4(WBGene00006454) on 2008-10-20. WBGene00000087 was previously the uncloned version of aex-4.<br/><br/>Example 2: ref-1: Public Name for WBGene00004334. It may also refer to aly-1(WBGene00000120) before the latter was renamed on 2005-04-27.<br/><br/>\n);

  print qq(<b>Screen a list of C. elegans gene names and identifiers to find whether they were renamed, merged, split, or share sequence with another gene.</b><br/>);
  print qq(Example 1: WBGene00000087 was merged into WBGene00006454 on 2008-10-20. This gene ID was previously the uncloned version of aex-4.<br/>);
  print qq(Example 2: ref-1 is the public name for WBGene00004334. It may also refer to WBGene00000120 (aly-1) before the latter was renamed on 2005-04-27.<br/>);
  print qq(Example 3: B0564.1 is the sequence name for both WBGene00007201 (exos-4.1) and WBGene00044083 (tin-9.2). These two genes share sequences.<br/><br/>);
#   print qq(Download source data for all genes <a href="../data/GeneNameHistory.csv">here</a>.<br/><br/>);	# does not work with wormbase reverse proxy 2021 04 29
#   print qq(Download source data for all genes <a href="http://tazendra.caltech.edu/~azurebrd/cgi-bin/data/GeneNameHistory.csv">here</a>.<br/><br/>);
  print qq(Download source data for all genes <a href="http://caltech.wormbase.org/pub/wormbase/spell_download/tables/GeneNameHistory.csv">here</a>.<br/><br/>);

  print qq(<form method="post" action="gene_sanitizer.cgi" enctype="multipart/form-data">\n);

  my ($var, $geneInput)  = &getHtmlVar($query, 'geneInput');

#   my ($var, $species)  = &getHtmlVar($query, 'species');
#   unless ($species) { $species = 'c_elegans'; }
# 
#   my %species;
#   tie %species, "Tie::IxHash";
#   %species = (
#     "b_malayi" => "Brugia malayi",
#     "c_brenneri" => "Caenorhabditis brenneri",
#     "c_briggsae" => "Caenorhabditis briggsae",
#     "c_elegans" => "Caenorhabditis elegans",
#     "c_japonica" => "Caenorhabditis japonica",
#     "c_remanei" => "Caenorhabditis remanei",
#     "o_volvulus" => "Onchocerca volvulus",
#     "p_pacificus" => "Pristionchus pacificus",
#     "s_ratti" => "Strongyloides ratti",
#     "mix" => "Any species (slow)"
#   );
#   my $select_size = scalar keys %species;
# #   $select_size++;                       # to account for any species added at the end
#   print qq(<span style="font-weight:bold">Step 1: Select species of the genes that you will enter (Required)</span>\n);
#   print qq(<span style="color: rgb(6, 199, 41); font-weight: bold; cursor: pointer;" title="'Any Species' search will return matches in all species with much longer time to load the results." onmouseover="this.style.cursor='pointer'" onclick="if (document.getElementById('species_help').style.display === 'none') { document.getElementById('species_help').style.display = ''; } else { document.getElementById('species_help').style.display = 'none'; } ">?</span><br>\n);
#   print qq(<span id="species_help" style="display: none; font-weight:normal">"Any Species" search will return matches in all species with much longer time to load the results.<br></span>\n);
#   print qq(<select id="species" name="species" size="$select_size" onchange="document.getElementById('query_list').disabled=false; document.getElementById('query_list_text').style.display='none'; document.getElementById('query_uploaded_file').disabled=false; document.getElementById('query_uploaded_file_text').style.display='none';">);
# #   foreach my $speciesOption (sort { $species{$a} cmp $species{$b} } keys %species) {
#   foreach my $speciesOption (keys %species) {
#     my $selected = ''; if ($speciesOption eq $species) { $selected = 'selected="selected"'; }
#     print qq(<option $selected value="$speciesOption">$species{$speciesOption}</option>);
#   }
# #   print qq(<option value="mix">Any species (slow)</option>);
#   print qq(</select>\n);
#   print qq(<br/><br/>\n);

#   print qq(<span style="font-weight:bold">Step 2: Choose input/output format</span><br/>);
#   print qq(<input type="radio" name="caseSensitiveToggle" value="caseInsensitive" checked="checked"> case insensitive input<br/>);
#   print qq(<input type="radio" name="caseSensitiveToggle" value="caseSensitive"> case sensitive input<br/>);
#   print qq(<br/>);

  print qq(<input type="radio" name="outputFormat" value="html" checked="checked"> display results in HTML format<br/>);
  print qq(<input type="radio" name="outputFormat" value="download"> download results as a tab-delimited file);
  print qq(<span style="color: rgb(6, 199, 41); font-weight: bold; cursor: pointer;" title="Some data fields may contain too many contents to fit into a cell in Excel. To avoid Excel converting some gene names (such as mar-5 and oct-1) into dates, the cell format has to be 'text' rather than 'general'." onmouseover="this.style.cursor='pointer'" onclick="if (document.getElementById('download_help').style.display === 'none') { document.getElementById('download_help').style.display = ''; } else { document.getElementById('download_help').style.display = 'none'; } ">?</span><br>\n);
  print qq(<span id="download_help" style="display: none; font-weight:normal">Some data fields may contain too many contents to fit into a cell in Excel. To avoid Excel converting some gene names (such as mar-5 and oct -1) into dates, the cell format has to be 'text' rather than 'general'.<br></span>\n);
  print qq(<br/>);

#   print qq(<input type="radio" name="duplicatesToggle" value="merge" checked="checked"> merge duplicate gene entries in results<br/>);
#   print qq(<input type="radio" name="duplicatesToggle" value="duplicates"> keep duplicate gene entries in results<br/>);
#   print qq(<br/>);
# 
#   print qq(<span style="font-weight:bold">Step 3: Choose types of information to retrieve</span><br/>);
#   my %columns;
#   tie %columns, "Tie::IxHash";
#   my $filepath = $files_path_base . 'headers';                        # to get from local files
# #   my $filepath = $files_path_base . 'headers';                        # to get from local files
#   open (IN, "<$filepath") or die "Cannot open $filepath : $!";
#   my $header = <IN>;
#   chomp $header;
#   close (IN) or die "Cannot close $filepath : $!";
#   my (@columns) = split/\t/, $header;
#   foreach (@columns) { $columns{$_}++; }
#   delete $columns{'Gene'};                              # not sure why need to delete this
#   my $headers = join"\t", keys %columns;
#   print qq(<input type="hidden" name="headers" value="$headers"/>);
#   print qq(<input type="checkbox" id="select all" name="select all" value="select all" checked="checked" onclick="var inputs = document.getElementsByTagName('input'); for(var i = 0; i < inputs.length; i++) { if(inputs[i].type == 'checkbox') { inputs[i].checked = document.getElementById('select all').checked; } }"> Set All Checkboxes<br/><br/>);      # set state of all checkboxes to this state
#   foreach my $column (keys %columns) {
#     print qq(<input type="checkbox" name="$column" value="$column" checked="checked"> $column<br/>); }
#   print qq(<br/>\n);

#   print qq(<span style="font-weight:bold">Step 4: Query <input type="submit" name="action" id="query_all" value="all genes in this species"> or</span><br/>\n);

#   print qq(Enter or upload a list of gene names here (one gene per line)<br/>);
  print qq(Screen a list of CGC name, Sequence name or WormBase Gene IDs (one gene per line)<br/>);

#   print qq((For example:  goa-1, C26C6.2, CELE_C26C6.2, CE05311, NM_059707.6, NP_492108.1)<br/>);
#   print qq(<span style="font-weight:bold">Step 4: Enter or upload a list of gene names here</span><br/>);
#   print qq(One gene per line, enter official MOD gene names or IDs, NCBI, UniProt, PANTHER or ENSEMBL IDs)<br/>);  # some genes have spaces in them, e.g. fly gene "suppressor of white-apricot"

#   print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="80" placeholder="goa-1\nC26C6.2\nCELE_C26C6.2\nCE05311\nNM_059707.6\nNP_492108.1">$geneInput</textarea><br/>\n);
  print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="80" placeholder="kap-1\nref-2\nWBGene00000194\ngoa-1\neat-16\nWBGene00000359\nY105E8B.m\nWBGene00006454">$geneInput</textarea><br/>\n);

#   print qq(<br/><input type="submit" name="action" id="query_list" value="query list" disabled><span id="query_list_text">Select a species to enable this button</span><br/>\n);
  print qq(<br/><input type="submit" name="action" id="query_list" value="query list"><br/>\n);
  print qq(<br/><br/>\n);
  print qq(Upload a file with gene names :<br/>);
  print qq(<input type="file" name="geneNamesFile" /><br/>);
#   print qq(<br/><input type="submit" name="action" id="query_uploaded_file" value="query uploaded file" disabled><span id="query_uploaded_file_text">Select a species to enable this button</span><br/>\n);
#   print qq(<br/><input type="submit" name="action" id="query_uploaded_file" value="query uploaded file"><span id="query_uploaded_file_text">Select a species to enable this button</span><br/>\n);
  print qq(<br/><input type="submit" name="action" id="query_uploaded_file" value="query uploaded file"><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query all C elegans"><br/>\n);
  print qq(<br/><br/>);

  print qq(</form>\n);


} # sub showSanitizeForm

sub populateGeneNameHistory {
  my $infile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/pub/wen/simplemine/GeneNameSanitizer/GeneNameHistory.csv';
  # my $infile = '/home/acedb/wen/simplemine/GeneNameSanitizer/GeneNameHistory.csv';
  my $errMessage;
  my %dataMap;
  my %headers;
  open (IN, "<$infile") or die "Cannot open $infile ; $!";
  my $headers = <IN>;
  chomp $headers;
#   my (@headers) = split/\t/, $headers;
#   for (my $i = 0; $i <= $#headers; $i++) { $headers{$i} = $headers[$i]; }
  while (my $line = <IN>) {
    chomp $line;
    my (@line) = split/\t/, $line;
    my $lcname = lc($line[0]);
#     for (my $i = 0; $i <= $#line; $i++) { $dataMap{$lcname}{$i} = $line[$i]; }
    $dataMap{$lcname} = $line;
  } # while (my $line = <IN>)
#   Gene Name       Valid and Unique Identifier     Ambiguous Identifier    Obsolete Identifier
  close (IN) or die "Cannot close $infile ; $!";
  return ($errMessage, \%dataMap, $headers);
}

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
          $dataMap{$wbgene} = $line;
#           for my $i (0 .. $#data) {
#             $dataMap{$columns[$i]}{$wbgene} = $data[$i]; }

    } }
  } # foreach my $file (@files)
  return ($errMessage, \%dataMap, \%geneNameToId);
} # sub populateFromAthena



