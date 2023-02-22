#!/usr/bin/env perl 

# Query by list of gene names on text tables for RNAseq expression values.
#
# adapted simplemine.cgi for rnaseq data.  2018 09 28
#
# added filters for strain, life stage, tissue, treatment.  2019 04 19
#
# File location of WBGeneName.csv moved.  2020 09 01

# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/fpkmmine.cgi


# sample
#
# c_brenneri
# Cbn-fem-2
# CBN26126
# 
# c_elegans
# abc-1
# let-60
# daf-2


use Jex;			# untaint, getHtmlVar, cshlNew, getPgDate
use strict;
use diagnostics;
use CGI;
use LWP::UserAgent;		# for variation_nameserver file
use LWP::Simple;		# for simple gets
# use DBI;
use Tie::IxHash;
use Dotenv -load => '/usr/lib/.env';

# my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $ua = new LWP::UserAgent;


my $query = new CGI;
my $host = $query->remote_host();		# get ip address

my %speciesHash = (
  "c_briggsae" => "Caenorhabditis briggsae",
  "c_brenneri" => "Caenorhabditis brenneri",
  "c_japonica" => "Caenorhabditis japonica",
  "c_remanei" => "Caenorhabditis remanei",
  "c_elegans" => "Caenorhabditis elegans",
  "p_pacificus" => "Pristionchus pacificus",
  "b_malayi" => "Brugia malayi",
  "o_volvulus" => "Onchocerca volvulus",
  "s_ratti" => "Strongyloides ratti" );


my %geneNameToId;
&populateGeneNameToId();

my %sampleInfo;
my $sampleHeaders;
&populateSampleInfo();

sub populateSampleInfo {
  my $file = '/home/acedb/wen/simplemine/FPKM/RNAseqSample.csv';
  open (IN, "<$file") or die "Cannot open $file : $!";
  $sampleHeaders = <IN>;
  chomp $sampleHeaders;
  while (my $line = <IN>) {
    chomp $line;
    my ($sample, @rest) = split/\t/, $line;
    $sampleInfo{$sample} = $line;
  }
  close (IN) or die "Cannot close $file : $!";
}

sub populateGeneNameToId {
#   my $file = '/home/acedb/wen/simplemine/sourceFile/WBGeneName.csv';
  my $file = '/home/acedb/wen/simplemine/FPKM/WBGeneName.csv';		# moved files around 2020 09 01
  $/ = undef;
  open (IN, "<$file") or die "Cannot open $file : $!";
  my $data = <IN>;
  close (IN) or die "Cannot close $file : $!";
  $/ = "\n";
  my (@lines) = split/\n/, $data;
  foreach my $i (0 .. $#lines) {
    my $line = $lines[$i];
    chomp $line;
    my ($wbgene, @rest) = split/\t/, $line;
    my $lcwbgene = lc($wbgene);
    $geneNameToId{$lcwbgene}{$wbgene}++;
    foreach my $category (@rest) {
      my (@indNames) = split/,/, $category;
      foreach my $name (@indNames) {
        $name =~ s/^\s+//; $name =~ s/\s+$//;
        unless ($name eq 'N.A.') { 
          my $lcname = lc($name);
          $geneNameToId{$lcname}{$wbgene}++; } } } } }

# my $base_url = 'http://athena.caltech.edu/fragmine/';	# replaced with ftp 2016 06 03
# my $base_url = 'ftp://caltech.wormbase.org/pub/wormbase/simpleMine/';	# replaced with local files 2016 06 09
my $files_path = '/home/acedb/wen/simplemine/FPKM/';
# my (@filesfull) = <${files_path}/*.csv>;		# get all .csv files for Wen.  2018 02 26
# my @files; foreach my $file (sort @filesfull) { $file =~ s/$files_path\///; push @files, $file; }
# my @files = qw( WBGeneName.csv RNAiAllelePheno.csv GeneTissueLifeStage.csv GeneDiseaseHumanOrtholog.csv GeneReference.csv GeneAllele.csv );

&process();                     # see if anything clicked

sub process {                   # see if anything clicked
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'query list') {                     &queryListTextarea(); }
    elsif ($action eq 'query uploaded file') {       &queryListUploadedFile(); }
#     elsif ($action eq 'query all C elegans') {       &queryListCelegansFile(); }
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

# sub queryListCelegansFile {				# from a flat file that Wen generates  2017 10 09
#   my $infile = $files_path . 'AllCelegansGenes.txt';
#   $/ = undef;
#   open (IN, "$infile") or die "Cannot open $infile : $!";
#   my $geneInput = <IN>;
#   close (IN) or die "Cannot close $infile : $!";
#   $/ = "\n";
#   &queryList($geneInput);
# } # sub queryListUploadedFile

# sub populateConcise {
#   my ($dataMapHashref)    = @_;
#   my %dataMap             = %$dataMapHashref;
#   my $file                = 'Concise';
#   $dataMap{$file}{header} = qq(Description Type\tDescription Text);
#   $dataMap{$file}{count}  = 2;
#   my $result = $dbh->prepare( "SELECT con_wbgene.con_wbgene, con_desctype.con_desctype, con_desctext.con_desctext FROM con_desctext, con_desctype, con_wbgene WHERE con_wbgene.joinkey = con_desctype.joinkey AND con_wbgene.joinkey = con_desctext.joinkey AND con_wbgene.joinkey NOT IN (SELECT joinkey FROM con_nodump WHERE con_nodump = 'NO DUMP');" );
#   $result->execute();
#   my %concise;
#   while (my @row = $result->fetchrow()) {
#     my $wbgene   = $row[0];
#     my $desctype = $row[1];
#     my $desctext = $row[2];
#     if ($desctext =~ m/\n/) { $desctext =~ s/\n/ /g; }
#     $concise{$wbgene}{$desctype} = $desctext;	# only look at concise or automated, only display one, prioritizing concise
#   }
#   foreach my $wbgene (sort keys %concise) {
#     if ($concise{$wbgene}{Concise_description}) {
# #         push @{ $dataMap{$wbgene} }, qq($wbgene\tConcise_description\t$concise{$wbgene}{Concise_description});
#         $dataMap{$file}{$wbgene} = qq(Concise_description\t$concise{$wbgene}{Concise_description}); }
#       elsif ($concise{$wbgene}{Automated_description}) {
# #         push @{ $dataMap{$wbgene} }, qq($wbgene\tAutomated_description\t$concise{$wbgene}{Automated_description});
#         $dataMap{$file}{$wbgene} = qq(Automated_description\t$concise{$wbgene}{Automated_description}); } }
#   return \%dataMap;
# } # sub populateConcise


# sub populateFromAthena {
#   my ($filesHref) = @_;
#   my (@files) = @$filesHref;
#   my $errMessage;
# #   my $fullHeader = '';
#   my %dataMap;
#   my %geneNameToId;
#   foreach my $file (@files) {
# #     my $dataUrl = $base_url . $file;			# to get from Athena or ftp
# #     my $data    = get $dataUrl;			# to get from Athena or ftp
#     my $filepath = $files_path . $file;			# to get from local files
#     $/ = undef;
#     open (IN, "<$filepath") or die "Cannot open $filepath : $!";
#     my $data = <IN>;
#     close (IN) or die "Cannot close $filepath : $!";
#     $/ = "\n";
#     my (@lines) = split/\n/, $data;
#     my @columns = ();
#     foreach my $i (0 .. $#lines) {
#       my $line = $lines[$i];
#       chomp $line;
#       my ($wbgene, @rest) = split/\t/, $line;
# #       my $data = join"\t", @rest;
#       if ($i == 0) {
# #           $fullHeader .= $data; 
#           my $count = scalar(@rest);
# #           (@columns) = @rest;
# # to keep first column as data from files
#           (@columns) = split/\t/, $line;
#           $dataMap{$file}{header} = $data;
#           $dataMap{$file}{count}  = $count;
#         }
#         else {
#           if ($file eq 'WBGeneName.csv') {
#             my $lcwbgene = lc($wbgene);
# #             $geneNameToId{$lcwbgene} = $wbgene;
#             $geneNameToId{$lcwbgene}{$wbgene}++;
#             foreach my $category (@rest) {
#               my (@indNames) = split/,/, $category;
#               foreach my $name (@indNames) {
#                 $name =~ s/^\s+//; $name =~ s/\s+$//;
#                 unless ($name eq 'N.A.') { 
#                   my $lcname = lc($name);
# #                   $geneNameToId{$lcname} = $wbgene;
#                   $geneNameToId{$lcname}{$wbgene}++; } } } }
# #           $dataMap{$file}{$wbgene} = $data; 
# 
# #           my (@data) = split/\t/, $data;
# #           for my $i (0 .. $#data) {
# #             $dataMap{$columns[$i]}{$wbgene} = $data[$i]; }
# # to keep first column as data from files
#           my (@data) = split/\t/, $line;
#           for my $i (0 .. $#data) {
#             $dataMap{$columns[$i]}{$wbgene} = $data[$i]; }
# 
#     } }
#   } # foreach my $file (@files)
#   return ($errMessage, \%dataMap, \%geneNameToId);
# } # sub populateFromAthena

sub queryList {
  my ($geneInput) = @_;					# gene list from form textarea or uploaded file
#   print "Content-type: text/html\n\n";
  my ($var, $outputFormat)       = &getHtmlVar($query, 'outputFormat');
  ($var, my $duplicatesToggle)   = &getHtmlVar($query, 'duplicatesToggle');
  ($var, my $species)  		 = &getHtmlVar($query, 'species');
  ($var, my $strain_filter)  	 = &getHtmlVar($query, 'strain_filter');
  ($var, my $lifestage_filter)   = &getHtmlVar($query, 'lifestage_filter');
  ($var, my $tissue_filter)  	 = &getHtmlVar($query, 'tissue_filter');
  ($var, my $treatment_filter)   = &getHtmlVar($query, 'treatment_filter');
  ($var, my $possibleheaders)    = &getHtmlVar($query, 'headers');
  my @possibleheaders = split/\t/, $possibleheaders;
  my @headers;
  foreach my $header (@possibleheaders) {
    ($var, my $headervalue)        = &getHtmlVar($query, $header);
    if ($headervalue) { push @headers, $header; } }
  unless ($outputFormat) { $outputFormat = 'download'; }
  if ($outputFormat eq 'download') {
      print qq(Content-type: application/x-download\n);
      print qq(Content-Disposition: attachment; filename="fpkmmine_results.txt"\n\n); }
    elsif ($outputFormat eq 'plain') {
      print "Content-type: text/plain\n\n"; }
    elsif ($outputFormat eq 'html') {
      print "Content-type: text/html\n\n"; }
    else {
      print qq(Content-type: application/x-download\n);
      print qq(Content-Disposition: attachment; filename="fpkmmine_results.txt"\n\n); }
  my $output = '';

#   my $additionalOutput = "";
# #   my $geneNameToIdHashref = &populateGeneMap();
# #   my %geneNameToId        = %$geneNameToIdHashref;
# #   my ($errMessage, $dataMapHashref, $geneNameToIdHashref) = &populateFromAthena(\@files);
# #   my %dataMap          = %$dataMapHashref;
# #   my %geneNameToId     = %$geneNameToIdHashref;
#   ($var, my $concisedescriptionFlag)        = &getHtmlVar($query, "Concise Description");
#   if ($concisedescriptionFlag) {
#     ($dataMapHashref)    = &populateConcise(\%dataMap);
#     %dataMap             = %$dataMapHashref; }
# #   my $dataHeader = qq(Your Input\tGene);
#   my $dataHeader = qq(Your Input);
# #   foreach my $file (@files, "Concise") { $dataHeader .= "\t$dataMap{$file}{header}"; }
#   foreach my $header (@headers) { $dataHeader .= "\t$header"; }
# #   foreach my $file ("Concise") {  $dataHeader .= "\t$dataMap{$file}{header}"; }
#   if ($concisedescriptionFlag) {
#     push @headers, "Concise";
#     $dataHeader .= "\t$dataMap{Concise}{header}"; }
#   $output .= qq($dataHeader\n);

  if ($geneInput =~ m/[^\w\d\.\-\(\)\/]/) { $geneInput =~ s/[^\w\d\.\-\(\)\/]+/ /g; }
  my (@genes) = split/\s+/, $geneInput;
  my %alreadyEntered;
  my $headerLine = $sampleHeaders;
  my $geneCount = 0;
  my %dataGenes;
  my @badGenes;
  foreach my $geneEntered (@genes) {
# print qq(GE $geneEntered E<br>);
    my ($gene) = lc($geneEntered);
# print qq(G $gene E<br>);
    next if ( ($alreadyEntered{$gene}) && ($duplicatesToggle eq 'merge') );
    $alreadyEntered{$gene}++;
    if ($geneNameToId{$gene}) {
        foreach my $geneId (sort keys %{ $geneNameToId{$gene} }) {
# print qq(GNTI $geneId E<br>);
          $dataGenes{$geneId}{$geneEntered}++;
          last if (scalar keys %dataGenes > 100);
      } }
      else { push @badGenes, $geneEntered; } }

  my $badGenes = join", ", @badGenes;
  if ($badGenes) {
    $output .= qq(These genes do not map to a gene for $species : $badGenes\n); }

  my %geneToSample;
  my %sampleHasData;
  foreach my $geneId (sort keys %dataGenes) {
    my $geneNames = join", ", sort keys %{ $dataGenes{$geneId} };
    $sampleHeaders .= "\t$geneId ($geneNames)";
    my $file = $files_path . $species . '/' . $geneId . '.csv';
#     print qq(F $file F<br>);
    if (-e $file) {
      open (IN, "<$file") or die "Cannot open $file : $!";
      my $headerLine = <IN>;
      while (my $line = <IN>) {
        chomp $line;
        my ($sample, $value) = split/\t/, $line;
        $sampleHasData{$sample}++;
        $geneToSample{$geneId}{$sample} = $value;
      } # while (my $line = <IN>)
      close (IN) or die "Cannot close $file : $!";
  } }
  $output .= qq($sampleHeaders\n);
  foreach my $sample (sort keys %sampleHasData) {
    unless ($sampleInfo{$sample}) { 
      next;							# skip samples without info.  Wen 2018 10 01
#       $output .= qq($sample\tDoes\tnot\thave\tdata\t\t); 	# error message instead
    }
    my ($sampleName, $sampleSpecies, $sampleStrain, $sampleLifestage, $sampleTissue, $sampleTreatment, $sampleTitle) = split/\t/, $sampleInfo{$sample};
# Sample Name     Species Strain  Life Stage      Tissue  Treatment       Title
    my $filterSkip = 0;
    if ($strain_filter) {    if ($strain_filter    ne 'No filter') { 
      if ($strain_filter eq 'Wild type/isolate') {
          if ( ($sampleStrain !~ 'Wild type') &&
               ($sampleStrain !~ 'Wild isolate') )    { $filterSkip++; } }
        else {
          if ($sampleStrain !~ $strain_filter)    { $filterSkip++; } } } }
    if ($lifestage_filter) { if ($lifestage_filter ne 'No filter') { if ($sampleLifestage !~ $lifestage_filter) { $filterSkip++; } } }
    if ($tissue_filter) {    if ($tissue_filter    ne 'No filter') { if ($sampleTissue !~ $tissue_filter)    { $filterSkip++; } } }
    if ($treatment_filter) { if ($treatment_filter ne 'No filter') { if ($sampleTreatment !~ $treatment_filter) { $filterSkip++; } } }
    next if ($filterSkip > 0);
    $output .= qq($sampleInfo{$sample});
    foreach my $geneId (sort keys %dataGenes) { 
      my $value = '';
      if ($geneToSample{$geneId}{$sample}) { $value = $geneToSample{$geneId}{$sample}; }
      $output .= "\t$value";
    } # foreach my $geneId (sort keys %dataGenes)
    $output .= "\n";
  }
  
#   my %sampleHasData
#     $sampleInfo{$sample} = $line;
   
#   if ($geneInput =~ m/[^\w\d\.\-\(\)\/]/) { $geneInput =~ s/[^\w\d\.\-\(\)\/]+/ /g; }
#   my (@genes) = split/\s+/, $geneInput;
#   my %alreadyEntered;
#   foreach my $geneEntered (@genes) {
#     my ($gene) = lc($geneEntered);
# print qq(GENE $gene GENE<br>);
#     next if ( ($alreadyEntered{$gene}) && ($duplicatesToggle eq 'merge') );
#     my $geneId = 'not found';
#     my $geneData;
#     if ($geneNameToId{$gene}) {
#         my $count = 0; my $thisEntry;
#         foreach my $geneId (sort keys %{ $geneNameToId{$gene} }) {
#           $geneData = ''; $count++;
# print qq(GENE $gene GID $geneId GENE<br>);
# #           foreach my $header (@headers) {
# #             if ($dataMap{$header}{$geneId}) {
# #                 $geneData .= "\t$dataMap{$header}{$geneId}"; }
# #               else {
# #                 $geneData .= "\tN.A."; }
# #           } # foreach my $header (@files, "Concise")
#           $thisEntry .= qq(${geneEntered}$geneData\n);
#         } # foreach my $geneId (sort keys %{ $geneNameToId{$gene} })
#         if ($count == 1) { $output .= $thisEntry; }
#           else { 
#             $output .= qq($geneEntered\tMultiple entries : $count\n);
# #             unless ($alreadyEntered{$gene}) {			# Chris doesn't want duplicate entries that have multiple genes to show up duplicate times at the bottom
# #               $additionalOutput .= qq($thisEntry); } 
#           }
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
    $output =~ s|\t|</td><td style="max-width:50ch;">|g;
    $output =~ s|\n|</td></tr>\n<tr><td style="max-width:50ch;">|g;
    $output = qq(<table border="1"><tr><td style="max-width:50ch;">$output</td></tr></table>); }
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
  print qq(<h3>RNAseq FPKM Gene Search</h3><br/>\n);
  print qq(This tool allows users to enter or upload a list of genes from one of the selected species to get an HTML or Excel file with their FPKM (Fragments Per Kilobase of transcript per Million mapped reads) values in all RNAseq experiments that WormBase annotated. Users can set up filters to refine the results according to Strain, Life stage, tissue specificity, or treatment.<br/><br/>\n);
#   print qq(This tool allows users to enter or upload a list of genes from one of the selected species to get an HTML or Excel file with their FPKM values in all RNAseq experiments that WormBase annotated. Users can set up filters to refine the results according to Strain, Life stage, tissue specificity, or treatment.<br/><br/>\n);
#   print qq(Gene mappings to gene identifiers, Tissue-LifeStage, RNAi-Phenotype, Allele-Phenotype, ConciseDescription.<br/><br/>);
  print qq(<form method="post" action="fpkmmine.cgi" enctype="multipart/form-data">\n);
#   my $select_size = scalar @files;
#   print qq(Select your datatype :<br>\n);
#   print qq(<select name="sourceFile" size="$select_size">);
#   foreach my $file (@files) {
#     print qq(<option>$file</option>);
#   } # foreach my $file (@files)
#   print qq(</select>\n);
#   print qq(<br/><br/>\n);
#   print qq(Enter list of gene names here (one gene per line, or separate with spaces, not punctuation) :<br/>);
  print qq(Select a species :<br/>);
  print qq(<select name="species" size="1">);
  foreach my $species (sort keys %speciesHash) {
    if ($species eq 'c_elegans') { print qq(<option value="$species" selected="selected">$speciesHash{$species}</option>); }
      else {                       print qq(<option value="$species">$speciesHash{$species}</option>); }
  } # foreach my $file (@files)
  print qq(</select>\n);
  print qq(<br/><br/>\n);
  print qq(Enter list of gene names here (maximum 100) :<br/>);
  print qq(<table><tr><td>);
  print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="40"></textarea>\n);
  print qq(</td><td valign="top">);

  print qq(Strain filter<br/>);
  my @strain_filter = ( "No filter", "Wild type/isolate", "Mutant", "Unclassified" );
  print qq(<select name="strain_filter" size="1">);
  foreach my $option (@strain_filter) { print qq(<option>$option</option>); }
  print qq(</select><br/><br/>);
  print qq(Life Stage filter<br/>);
  my @lifestage_filter = ( "No filter", "Embryo", "Larva", "Adult", "Mixed stages", "Unclassified");
  print qq(<select name="lifestage_filter" size="1">);
  foreach my $option (@lifestage_filter) { print qq(<option>$option</option>); }
  print qq(</select><br/><br/>);
  print qq(Tissue filter<br/>);
  my @tissue_filter = ( "No filter", "Whole animal", "Tissue specific");
  print qq(<select name="tissue_filter" size="1">);
  foreach my $option (@tissue_filter) { print qq(<option>$option</option>); }
  print qq(</select><br/><br/>);
  print qq(Treatment \(controls included\) filter<br/>);
  my @treatment_filter = ( "No filter", "Chemical response", "Food response", "Immune response", "RNAi", "Temperature stimulus", "No treatment", "Unclassified" );
  print qq(<select name="treatment_filter" size="1">);
  foreach my $option (@treatment_filter) { print qq(<option>$option</option>); }
  print qq(</select><br/><br/>);

  print qq(</td></tr></table>);
  print qq(<input type="submit" name="action" value="query list"><br/>\n);
  print qq(<br/><br/>\n);
  print qq(Upload a file with gene names :<br/>);
  print qq(<input type="file" name="geneNamesFile" /><br/>);
  print qq(<input type="submit" name="action" value="query uploaded file"><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query all C elegans"><br/>\n);
  print qq(<br/><br/>);
  print qq(<input type="radio" name="outputFormat" value="download" checked="checked"> download<br/>);
  print qq(<input type="radio" name="outputFormat" value="html"> html<br/>);
  print qq(<br/>);
  print qq(<input type="radio" name="duplicatesToggle" value="merge" checked="checked"> merge duplicate genes<br/>);
  print qq(<input type="radio" name="duplicatesToggle" value="duplicates"> allow duplicate genes<br/><br/>);


  print qq(<br/>);
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
#   print qq(<input type="checkbox" name="Concise Description" value="Concise Description" checked="checked"> Concise Description<br/>);				# not part of general headers, comes from postgres

  print qq(</form>\n);
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
