#!/usr/bin/env perl

# Query Spell data
#
# For Wen.  2017 07 25
#
# Wen only wants html output.  Link to FTP URL.  Topics are optional.  2017 07 26
# 
# Dockerized.  2023 09 15
#
# split tissues like topics.  2025 10 22
#
# wen created a file for counts by category, from Raymond sugggestion.  display in table now.  2025 11 02
#
# Add WormBase Processed Data for Wen.  2025 11 03
#
# Get description of website from flatfile for Wen.
# New textarea for keyword, comma-separated, using any substring match against source file.  2026 01 13

# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/expression_dataset_locator.cgi
# https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/expression_dataset_locator.cgi



use Jex;			# untaint, getHtmlVar, cshlNew, getPgDate
use strict;
use diagnostics;
use CGI;
use LWP::UserAgent;		# for variation_nameserver file
use LWP::Simple;		# for simple gets
use DBI;
use Tie::IxHash;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# my $thishost = $ENV{THIS_HOST_AS_BASE_URL};
# my $baseUrl = $ENV{THIS_HOST_AS_BASE_URL} . "pub/cgi-bin/forms";

my $ua = new LWP::UserAgent;


my $query = new CGI;
my $host = $query->remote_host();		# get ip address

# my $file_source = '/home/acedb/wen/simplemine/all_SPELL_datasets.csv';
my $file_source = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} .  '/pub/wen/simplemine/expressionDatasetLocator/all_SPELL_datasets.csv';
my $file_category_count = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} .  '/pub/wen/simplemine/expressionDatasetLocator/categoryCount.csv';
my $file_description = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} .  '/pub/wen/simplemine/expressionDatasetLocator/description.txt';
my %hash;
my ($dataHeader) = &processFiles();

&process();                     # see if anything clicked

sub process {                   # see if anything clicked
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }

  if ($action eq 'show datasets') {                     &querySpell(); }
    else { &frontPage(); }
}


sub querySpell {
#   my ($geneInput) = @_;					# gene list from form textarea or uploaded file
  my ($var, $outputFormat)   = &getHtmlVar($query, 'outputFormat');
#   ($var, my $possibleheaders)        = &getHtmlVar($query, 'headers');
#   my @possibleheaders = split/\t/, $possibleheaders;
#   my @headers;
#   foreach my $header (@possibleheaders) {
#     ($var, my $headervalue)        = &getHtmlVar($query, $header);
#     if ($headervalue) { push @headers, $header; } }
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
#   my $dataHeader = qq(Dataset ID	Dataset Name	WormBase Paper ID	Method	Species	Tissue	Topics	Title	URL);

  my $requiredFields = 0;
#   ($var, my $method)        = &getHtmlVar($query, 'method');
#   ($var, my $species)       = &getHtmlVar($query, 'species');
  my @methods               = $query->param('method');
  my @species               = $query->param('species');
  my @tissues               = $query->param('tissue');
  my @topics                = $query->param('topics');
  my @wbProcessed           = $query->param('wbProcessed');
  my $anyTopicOk = 0;
  unless (scalar @methods > 0)      { (@methods)      = sort keys %{ $hash{method}  };  }
  unless (scalar @species > 0)      { (@species)      = sort keys %{ $hash{species} };  }
  unless (scalar @tissues > 0)      { (@tissues)      = sort keys %{ $hash{tissues}  };  }
  unless (scalar @topics > 0)       { (@topics)       = sort keys %{ $hash{topics}  }; $anyTopicOk++; }
  unless (scalar @wbProcessed > 0)  { (@wbProcessed)  = sort keys %{ $hash{wbProcessed}  }; }
  ($var, my $keywords)      = &getHtmlVar($query, 'keywords');
  my (@keywords) = split/,/, $keywords;
  s/^\s+|\s+$//g for @keywords;
  my $anyKeywordOk = @keywords ? 0 : 1;
#   if (scalar @methods > 0) { $requiredFields++; } else { (@methods) = sort keys %{ $hash{method}  };  }
#   if (scalar @species > 0) { $requiredFields++; } else { (@species) = sort keys %{ $hash{species} };  }
#   if (scalar @tissues > 0) { $requiredFields++; } else { (@tissues) = sort keys %{ $hash{tissues}  };  }
#   if (scalar @topics > 0)  { $requiredFields++; } else { (@topics)  = sort keys %{ $hash{topics}  };  }
#   $requiredFields = 4;
#   print qq(M $method<br/>\n);
#   print qq(S $species<br/>\n);
#   foreach my $method (@methods) {  print qq(M $method<br/>\n);  }
#   foreach my $species (@species) { print qq(S $species<br/>\n); }
#   foreach my $tissue (@tissues) {  print qq(I $tissue<br/>\n);  }
#   foreach my $topic (@topics) {    print qq(O $topic<br/>\n);   }

#   my $tpc = join"--", @topics; 
#   $output .= qq(TOPIC $tpc E<br>\n); 

  my %lines;
#   foreach my $line (keys %{ $hash{method}{$method} }) { $lines{$line}++; }
#   foreach my $line (keys %{ $hash{species}{$species} }) { $lines{$line}++; }
  foreach my $method (@methods) { 
    foreach my $line (keys %{ $hash{method}{$method} }) { $lines{$line}{method}++; } }
  foreach my $species (@species) { 
    foreach my $line (keys %{ $hash{species}{$species} }) { $lines{$line}{species}++; } }
  foreach my $tissue (@tissues) { 
    foreach my $line (keys %{ $hash{tissues}{$tissue} }) { $lines{$line}{tissue}++; } }
  foreach my $topic (@topics) {   
    foreach my $line (keys %{ $hash{topics}{$topic} }) { $lines{$line}{topic}++; } }
  foreach my $wbProcessed (@wbProcessed) {   
    foreach my $line (keys %{ $hash{wbProcessed}{$wbProcessed} }) { $lines{$line}{wbProcessed}++; } }

  foreach my $keyword (@keywords) {
    foreach my $text (keys %{ $hash{keyword} }) {
      if ($text =~ /\Q$keyword\E/i) {
        foreach my $line (keys %{ $hash{keyword}{$text} }) {
          $lines{$line}{keyword}++; } } } }
  # $hash{keyword}{$url}{$count}++;

  foreach my $line (sort keys %lines) {
#     $output .= qq(REQ $requiredFields LINE $line V $lines{$line} E<br>\n); 
#     if ($lines{$line} >= $requiredFields) { # }
    if ( ($lines{$line}{method}) && ($lines{$line}{species}) && ($lines{$line}{tissue}) && ($lines{$line}{wbProcessed}) && 
         ( ($lines{$line}{keyword}) || $anyKeywordOk ) &&
         ( ($lines{$line}{topic}) || $anyTopicOk ) ) {
      my $line = $hash{line}{$line};
      $output .= qq($line\n);
    }
# else { $output .= qq(REQ $requiredFields LINE $line V $lines{$line} E<br>\n); }
  }

  if ($output) {
    $output = qq($dataHeader\n$output);
  } else {
    $output = qq(Your query did not retrieve any result. Please contact help (at) wormbase.org if you think any datasets are missing in our collection.);
  }

  if ($outputFormat eq 'html') {
    $output =~ s|\t|</td><td>|g;
    $output =~ s|\n|</td></tr>\n<tr><td>|g;
    $output = qq(<table border="1"><tr><td>$output</td></tr></table>); }
  print qq($output);
} # sub querySpell

sub frontPage {
  print "Content-type: text/html\n\n";
#   my $title = 'Genomic Expression Data Download';
  my $title = 'Expression Dataset Locator';
  my ($header, $footer) = &cshlNew($title);
  print "$header\n";		# make beginning of HTML page
  my $action;                   # what user clicked
  unless ($action = $query->param('action')) { $action = 'none'; }
  &showSpellForm();
  print "$footer"; 		# make end of HTML page
} # sub frontPage


sub showSpellForm {
#   print qq(<h3>Genomic Expression Data Download</h3><br/>\n);
  print qq(<h3>Expression Dataset Locator</h3><br/>\n);

#   print qq(This tool allows browsing and downloading of data from ~7,000 genomic expression analyses published in ~400 nematode research articles. The search may combine specific platforms, species, tissues and research topics. For example, choosing 'RNAseq', 'C. elegans', 'Whole Animal' and 'aging' will return C. elegans RNAseq datasets related to aging, done in whole animals. Not making any selection is equivalent to choosing all. For example, if no "Platform" is specified, results from all platforms will be displayed. Likewise, choosing 'RNAseq' and 'proteomics' will return both RNAseq and proteomics datasets.<br/><br/>);
  print qq($hash{description}\n);

  print qq(Our complete dataset collection is available for direct <a target="_blank" href="ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/AllDatasetsDownload.tgz">download</a>.<br/><br/>);  

#   print qq(This application allows users to browse and download data from ~7,000 genomic expression analysis published in ~400 nematode research articles.<br/><br/>\n);
#   print qq(The search may combine specific platforms, species, tissues and research topics. For example, by selecting "RNAseq", "C. elegans", "Whole Animal" and "aging", users will find C. elegans RNAseq datasets related to aging, done in whole animals.<br/><br/>\n);
#   print qq(Not making any selection is equivalent to choosing all. For example, without specifying "Platform", results from all platforms will be displayed. If users choose "RNAseq" and "proteomics", the result will display both RNAseq and proteomics datasets.<br/><br/>\n);

#   print qq(Gene mappings to gene identifiers, Tissue-LifeStage, RNAi-Phenotype, Allele-Phenotype, ConciseDescription.<br/><br/>);
  print qq(<form method="post" action="expression_dataset_locator.cgi" enctype="multipart/form-data">\n);

  print qq(<table>\n);
#   print qq(1. Method, optionally specify one or more methods.<br/>\n);
  print qq(<tr><td>1. Choose platform</td><td>Count</td></tr>\n);
#   print qq(<select name="method"><option></option>);
#   foreach my $method (sort keys %{ $hash{method} }) { print qq(<option>$method</option>); }
#   print qq(</select><br/>);
  foreach my $method (sort keys %{ $hash{method} }) { 
    my $label = $method; $label =~ s/Method: //;
    print qq(<tr><td><input type="checkbox" name="method" value="$method"> $label</td><td>$hash{catcount}{$label}</td></tr>); }
  print qq(<tr><td>&nbsp;</td</tr>\n);

#   print qq(2. Species, optionally specify one or more species.<br/>\n);
  print qq(<tr><td>2. Choose Species</td><td>Count</td></tr>\n);
#   print qq(<select name="species"><option></option>);
#   foreach my $species (sort keys %{ $hash{species} }) { print qq(<option>$species</option>); }
#   print qq(</select><br/>);
  foreach my $species (sort keys %{ $hash{species} }) {
    my $label = $species; $label =~ s/Species: //;
    print qq(<tr><td><input type="checkbox" name="species" value="$species"> $label</td><td>$hash{catcount}{$label}</td></tr>); }
#   print qq(<br/>\n);
  print qq(<tr><td>&nbsp;</td</tr>\n);

#   print qq(3. Tissue, optionally specify Tissue Specific, Whole Animal, or Both.<br/>\n);
  print qq(<tr><td>3. Choose Tissue Specificity</td><td>Count</td></tr>\n);
  foreach my $tissue (sort keys %{ $hash{tissues} }) {
    print qq(<tr><td><input type="checkbox" name="tissue" value="$tissue"> $tissue</td><td>$hash{catcount}{$tissue}</td></tr>); }
#   print qq(<br/>\n);
  print qq(<tr><td>&nbsp;</td</tr>\n);

#   print qq(4. Topic, optionally choose one or more topics.<br/>\n);
  print qq(<tr><td>4. Choose Topic</td><td>Count</td></tr>\n);
  foreach my $topics (sort keys %{ $hash{topics} }) { 
    if ($topics) { 
      my $label = $topics; $label =~ s/Topic: //;
      print qq(<tr><td><input type="checkbox" name="topics" value="$topics"> $label</td><td>$hash{catcount}{$label}</td></tr>); } }
  print qq(<tr><td>&nbsp;</td</tr>\n);

  print qq(<tr><td>5. WormBase Processed Data</td><td>Count</td></tr>\n);
  foreach my $wbProcessed (sort keys %{ $hash{wbProcessed} }) { 
    if ($wbProcessed) { 
      my $label = $wbProcessed;
      print qq(<tr><td><input type="checkbox" name="wbProcessed" value="$wbProcessed"> $label</td><td>$hash{catcount}{$label}</td></tr>); } }
  print qq(<tr><td>&nbsp;</td</tr>\n);

  print qq(<tr><td>6. Contain keywords or accession numbers</td></tr>\n);
  print qq(<tr><td>comma-separated keywords, e.g. GSE280222, daf-2</td></tr>\n);
  print qq(<tr><td colspan=2><textarea id="keywords" name="keywords" rows="10" cols="60"></textarea></td></tr>\n);

  print qq(</table>\n);


#   print qq(Enter list of gene names here :<br/>);
#   print qq(<textarea id="geneInput" name="geneInput" rows="20" cols="80"></textarea><br/>\n);
#   print qq(<br/><input type="submit" name="action" value="query list"><br/>\n);
#   print qq(<br/><br/>\n);

#   print qq(Upload a file with gene names :<br/>);
#   print qq(<input type="file" name="geneNamesFile" /><br/>);
#   print qq(<br/><input type="submit" name="action" value="query uploaded file"><br/>\n);
#   print qq(<br/><br/>);


#   print qq(<br/><br/>);
#   print qq(<input type="radio" name="outputFormat" value="download" checked="checked"> download<br/>);
#   print qq(<input type="radio" name="outputFormat" value="html"> html<br/>);
  print qq(<input type="hidden" name="outputFormat" value="html">);

  print qq(<br/><input type="submit" name="action" value="show datasets"><br/><br/>\n);

  print qq(</form>\n);
#   print qq(Download all datasets. These are gene-centric, log2 transformed data, mapped to the current genome: <a href="ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/AllDatasetsDownload.tgz">ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/AllDatasetsDownload.tgz</a><br/><br/>\n);
#   print qq(Download all microarray datasets that are based on probes: <a href="ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/MrDataProbeCentric.tgz">ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/MrDataProbeCentric.tgz</a><br/><br/>\n);

} # sub showSpellForm

sub processFiles {
  open (IN, "<$file_category_count") or die "Cannot open $file_category_count : $!";
  while (my $line = <IN>) {
    chomp $line;
    my ($category, $count) = split/\t/, $line;
    $hash{catcount}{$category} = $count;
  }
  close (IN) or die "Cannot close $file_category_count : $!";

  open (IN, "<$file_description") or die "Cannot open $file_description : $!";
  while (my $line = <IN>) {
    chomp $line;
    $hash{description} .= $line . '<br/>';
  }
  close (IN) or die "Cannot close $file_category_count : $!";

  open (IN, "<$file_source") or die "Cannot open $file_source : $!";
  my $header = <IN>;
  my $count = 0;
  while (my $line = <IN>) {
    chomp $line;
    $count++;
    my ($dataid, $dataname, $paper, $method, $species, $tissues, $topics, $title, $wbProcessed, $url) = split/\t/, $line;
    if ($url) {
      $hash{keyword}{$url}{$count}++;
      $line =~ s/$url/<a href="$url">$url<\/a>/; }
    $hash{keyword}{$dataid}{$count}++;
    $hash{keyword}{$dataname}{$count}++;
    $hash{keyword}{$paper}{$count}++;
    $hash{keyword}{$method}{$count}++;
    $hash{keyword}{$species}{$count}++;
    $hash{keyword}{$tissues}{$count}++;
    $hash{keyword}{$topics}{$count}++;
    $hash{keyword}{$title}{$count}++;
    $hash{keyword}{$wbProcessed}{$count}++;
    $hash{line}{$count} = $line;
    $hash{method}{$method}{$count}++;
    $hash{species}{$species}{$count}++;
#     $hash{tissue}{$tissue}{$count}++;
    my (@tissues) = split/\|/, $tissues;
    foreach my $tissue (@tissues) { $hash{tissues}{$tissue}{$count}++; }
#     if ($topics) { $hash{topics}{$topics}{$count}++; }
#     $hash{topics}{$topics}{$count}++;
    my (@topics) = split/\|/, $topics;
    foreach my $topic (@topics) { $hash{topics}{$topic}{$count}++; }
    my (@wbProcessed) = split/\|/, $wbProcessed;
    foreach my $wbProcessed (@wbProcessed) { $hash{wbProcessed}{$wbProcessed}{$count}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $file_source : $!";
  return $header;
# Dataset ID	Dataset Name	WormBase Paper ID	Method	Species	Tissue	Topics	Title	URL

} # sub processFiles


