#!/usr/bin/env perl

# Query Spell data
#
# For Wen.  2017 07 25
#
# Wen only wants html output.  Link to FTP URL.  Topics are optional.  2017 07 26
# 
# Dockerized.  2023 09 15
#
# Adapted for Macaque for Wen.  2024 02 15

# https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/EDLMaca.cgi



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
my $file_source = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} .  '/pub/wen/maca/EDLMaca/all_MACA_datasets.csv';
my %hash;
my ($dataHeader) = &processFile();

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
  my $anyTopicOk = 0;
  unless (scalar @methods > 0) { (@methods) = sort keys %{ $hash{method}  };  }
  unless (scalar @species > 0) { (@species) = sort keys %{ $hash{species} };  }
  unless (scalar @tissues > 0) { (@tissues) = sort keys %{ $hash{tissue}  };  }
  unless (scalar @topics > 0)  { (@topics)  = sort keys %{ $hash{topics}  }; $anyTopicOk++; }
#   if (scalar @methods > 0) { $requiredFields++; } else { (@methods) = sort keys %{ $hash{method}  };  }
#   if (scalar @species > 0) { $requiredFields++; } else { (@species) = sort keys %{ $hash{species} };  }
#   if (scalar @tissues > 0) { $requiredFields++; } else { (@tissues) = sort keys %{ $hash{tissue}  };  }
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
    foreach my $line (keys %{ $hash{tissue}{$tissue} }) { $lines{$line}{tissue}++; } }
  foreach my $topic (@topics) {   
    foreach my $line (keys %{ $hash{topics}{$topic} }) { $lines{$line}{topic}++; } }
  foreach my $line (sort keys %lines) {
#     $output .= qq(REQ $requiredFields LINE $line V $lines{$line} E<br>\n); 
#     if ($lines{$line} >= $requiredFields) {
    if ( ($lines{$line}{method}) && ($lines{$line}{species}) && ($lines{$line}{tissue}) && ( ($lines{$line}{topic}) || $anyTopicOk ) ) {
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

  my $maca_header_file = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} .  '/pub/wen/maca/EDLMaca/header';
  my $maca_header = '';
  $/ = undef;
  open (IN, "<$maca_header_file") or warn "Cannot open $maca_header_file : $!";
  my $maca = <IN>;
  close (IN) or warn "Cannot close $maca_header_file : $!";
  
  print qq($maca<br/><br/>\n);

#   print qq(This tool allows browsing and downloading of data from ~7,000 genomic expression analyses published in ~400 nematode research articles. The search may combine specific platforms, species, tissues and research topics. For example, choosing 'RNAseq', 'C. elegans', 'Whole Animal' and 'aging' will return C. elegans RNAseq datasets related to aging, done in whole animals. Not making any selection is equivalent to choosing all. For example, if no "Platform" is specified, results from all platforms will be displayed. Likewise, choosing 'RNAseq' and 'proteomics' will return both RNAseq and proteomics datasets.<br/><br/>);
# 
#   print qq(Our complete dataset collection is available for direct <a target="_blank" href="ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/AllDatasetsDownload.tgz">download</a>.<br/><br/>);  

#   print qq(This application allows users to browse and download data from ~7,000 genomic expression analysis published in ~400 nematode research articles.<br/><br/>\n);
#   print qq(The search may combine specific platforms, species, tissues and research topics. For example, by selecting "RNAseq", "C. elegans", "Whole Animal" and "aging", users will find C. elegans RNAseq datasets related to aging, done in whole animals.<br/><br/>\n);
#   print qq(Not making any selection is equivalent to choosing all. For example, without specifying "Platform", results from all platforms will be displayed. If users choose "RNAseq" and "proteomics", the result will display both RNAseq and proteomics datasets.<br/><br/>\n);

#   print qq(Gene mappings to gene identifiers, Tissue-LifeStage, RNAi-Phenotype, Allele-Phenotype, ConciseDescription.<br/><br/>);
  print qq(<form method="post" action="EDLMaca.cgi" enctype="multipart/form-data">\n);

#   print qq(1. Method, optionally specify one or more methods.<br/>\n);
  print qq(1. Choose platform<br/>\n);
#   print qq(<select name="method"><option></option>);
#   foreach my $method (sort keys %{ $hash{method} }) { print qq(<option>$method</option>); }
#   print qq(</select><br/>);
  foreach my $method (sort keys %{ $hash{method} }) { 
    my $label = $method; $label =~ s/Method: //;
    print qq(<input type="checkbox" name="method" value="$method"> $label<br/>); }
  print qq(<br/>\n);

#   print qq(2. Species, optionally specify one or more species.<br/>\n);
  print qq(2. Choose Species<br/>\n);
#   print qq(<select name="species"><option></option>);
#   foreach my $species (sort keys %{ $hash{species} }) { print qq(<option>$species</option>); }
#   print qq(</select><br/>);
  foreach my $species (sort keys %{ $hash{species} }) {
    my $label = $species; $label =~ s/Species: //;
    print qq(<input type="checkbox" name="species" value="$species"> $label<br/>); }
  print qq(<br/>\n);

#   print qq(3. Tissue, optionally specify Tissue Specific, Whole Animal, or Both.<br/>\n);
  print qq(3. Choose Tissue Specificity<br/>\n);
  foreach my $tissue (sort keys %{ $hash{tissue} }) { print qq(<input type="checkbox" name="tissue" value="$tissue"> $tissue<br/>); }
  print qq(<br/>\n);

#   print qq(4. Topic, optionally choose one or more topics.<br/>\n);
  print qq(4. Choose Topic<br/>\n);
  foreach my $topics (sort keys %{ $hash{topics} }) { 
    if ($topics) { 
      my $label = $topics; $label =~ s/Topic: //;
      print qq(<input type="checkbox" name="topics" value="$topics"> $label<br/>); } }

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

sub processFile {
  open (IN, "<$file_source") or die "Cannot open $file_source : $!";
  my $header = <IN>;
  my $count = 0;
  while (my $line = <IN>) {
    chomp $line;
    $count++;
    my ($dataid, $dataname, $paper, $method, $species, $tissue, $topics, $title, $url) = split/\t/, $line;
    if ($url) {
      $line =~ s/$url/<a href="$url">$url<\/a>/; }
    $hash{line}{$count} = $line;
    $hash{method}{$method}{$count}++;
    $hash{species}{$species}{$count}++;
    $hash{tissue}{$tissue}{$count}++;
#     if ($topics) { $hash{topics}{$topics}{$count}++; }
#     $hash{topics}{$topics}{$count}++;
    my (@topics) = split/\|/, $topics;
    foreach my $topic (@topics) { $hash{topics}{$topic}{$count}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $file_source : $!";
  return $header;
# Dataset ID	Dataset Name	WormBase Paper ID	Method	Species	Tissue	Topics	Title	URL
} # sub processFile


