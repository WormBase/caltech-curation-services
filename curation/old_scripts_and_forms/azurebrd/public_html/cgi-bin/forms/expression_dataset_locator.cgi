#!/usr/bin/perl 

# Query Spell data
#
# For Wen.  2017 07 25
#
# Wen only wants html output.  Link to FTP URL.  Topics are optional.  2017 07 26

# http://tazendra.caltech.edu/~azurebrd/cgi-bin/forms/expression_dataset_locator.cgi



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

my $file_source = '/home/acedb/wen/simplemine/all_SPELL_datasets.csv';
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

  print qq(This tool allows browsing and downloading of data from ~7,000 genomic expression analyses published in ~400 nematode research articles. The search may combine specific platforms, species, tissues and research topics. For example, choosing 'RNAseq', 'C. elegans', 'Whole Animal' and 'aging' will return C. elegans RNAseq datasets related to aging, done in whole animals. Not making any selection is equivalent to choosing all. For example, if no "Platform" is specified, results from all platforms will be displayed. Likewise, choosing 'RNAseq' and 'proteomics' will return both RNAseq and proteomics datasets.<br/><br/>);

  print qq(Our complete dataset collection is available for direct <a target="_blank" href="ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/AllDatasetsDownload.tgz">download</a>.<br/><br/>);  

#   print qq(This application allows users to browse and download data from ~7,000 genomic expression analysis published in ~400 nematode research articles.<br/><br/>\n);
#   print qq(The search may combine specific platforms, species, tissues and research topics. For example, by selecting "RNAseq", "C. elegans", "Whole Animal" and "aging", users will find C. elegans RNAseq datasets related to aging, done in whole animals.<br/><br/>\n);
#   print qq(Not making any selection is equivalent to choosing all. For example, without specifying "Platform", results from all platforms will be displayed. If users choose "RNAseq" and "proteomics", the result will display both RNAseq and proteomics datasets.<br/><br/>\n);

#   print qq(Gene mappings to gene identifiers, Tissue-LifeStage, RNAi-Phenotype, Allele-Phenotype, ConciseDescription.<br/><br/>);
  print qq(<form method="post" action="expression_dataset_locator.cgi" enctype="multipart/form-data">\n);

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
    $line =~ s/$url/<a href="$url">$url<\/a>/;
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


Dataset ID	Dataset Name	WormBase Paper ID	Method	Species	Tissue	Topics	Title	URL
1	WBPaper00042241.bma.rs.paper	WBPaper00042241	Method: RNAseq	Species: Brugia malayi	Whole Animal	N.A.	A deep sequencing approach to comparatively analyze the transcriptome of lifecycle stages of the filarial worm, Brugia malayi.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042241.bma.rs.paper
2	WBPaper00032529.cbn.rs.paper	WBPaper00032529	Method: RNAseq	Species: Caenorhabditis brenneri	Tissue Specific	N.A.	Massively parallel sequencing of the polyadenylated transcriptome of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032529.cbn.rs.paper
3	WBPaper00041689.cbn.rs.paper	WBPaper00041689	Method: RNAseq	Species: Caenorhabditis brenneri	Whole Animal	N.A.	Simplification and desexualization of gene expression in self-fertile nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041689.cbn.rs.paper
4	WBPaper00045465.cbn.rs.paper	WBPaper00045465	Method: RNAseq	Species: Caenorhabditis brenneri	Whole Animal	N.A.	Conserved translatome remodeling in nematode species executing a shared developmental transition.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045465.cbn.rs.paper
5	WBPaper00046067.cbn.rs.paper	WBPaper00046067	Method: RNAseq	Species: Caenorhabditis brenneri	Whole Animal	N.A.	Comparative population genomics in animals uncovers the determinants of genetic diversity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046067.cbn.rs.paper
6	WBPaper00032529.cbg.rs.paper	WBPaper00032529	Method: RNAseq	Species: Caenorhabditis briggsae	Tissue Specific	N.A.	Massively parallel sequencing of the polyadenylated transcriptome of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032529.cbg.rs.paper
7	WBPaper00041271.cbg.rs.paper	WBPaper00041271	Method: RNAseq	Species: Caenorhabditis briggsae	Whole Animal	N.A.	RNA-seq analysis of the C. briggsae transcriptome.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041271.cbg.rs.paper
8	WBPaper00041689.cbg.rs.paper	WBPaper00041689	Method: RNAseq	Species: Caenorhabditis briggsae	Whole Animal	N.A.	Simplification and desexualization of gene expression in self-fertile nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041689.cbg.rs.paper
9	WBPaper00044760.cbg.rs.paper	WBPaper00044760	Method: RNAseq	Species: Caenorhabditis briggsae	Whole Animal	N.A.	Conservation of mRNA and protein expression during development of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044760.cbg.rs.paper
10	WBPaper00045465.cbg.rs.paper	WBPaper00045465	Method: RNAseq	Species: Caenorhabditis briggsae	Whole Animal	N.A.	Conserved translatome remodeling in nematode species executing a shared developmental transition.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045465.cbg.rs.paper
11	WBPaper00004349.ce.mr.paper	WBPaper00004349	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A global profile of germline gene expression in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00004349.ce.mr.paper
12	WBPaper00004386.ce.mr.paper	WBPaper00004386	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: developmental process	Genomic analysis of gene expression in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00004386.ce.mr.paper
13	WBPaper00004489.ce.mr.paper	WBPaper00004489	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: Wnt signaling pathway	Genome-wide analysis of developmental and sex-regulated gene expression profiles in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00004489.ce.mr.paper
14	WBPaper00005056.ce.mr.paper	WBPaper00005056	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Regulation of organogenesis by the Caenorhabditis elegans FoxA protein PHA-4.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005056.ce.mr.paper
15	WBPaper00005280.ce.mr.paper	WBPaper00005280	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Identification of a novel cis-regulatory element involved in the heat shock response in Caenorhabditis elegans using microarray gene expression and computational methods.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005280.ce.mr.paper
16	WBPaper00005303.ce.mr.paper	WBPaper00005303	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A global analysis of Caenorhabditis elegans operons.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005303.ce.mr.paper
17	WBPaper00005356.ce.mr.paper	WBPaper00005356	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Identification of genes expressed in C. elegans touch receptor neurons.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005356.ce.mr.paper
18	WBPaper00005376.ce.mr.paper	WBPaper00005376	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: vulval development	Downstream targets of let-60 Ras in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005376.ce.mr.paper
19	WBPaper00005432.ce.mr.paper	WBPaper00005432	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	A survival pathway for Caenorhabditis elegans with a blocked unfolded protein response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005432.ce.mr.paper
20	WBPaper00005475.ce.mr.paper	WBPaper00005475	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Transcriptional profile of aging in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005475.ce.mr.paper
21	WBPaper00005767.ce.mr.paper	WBPaper00005767	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: embryo development	Composition and dynamics of the Caenorhabditis elegans early embryonic transcriptome.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005767.ce.mr.paper
22	WBPaper00005859.ce.mr.paper	WBPaper00005859	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Global analysis of dauer gene expression in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005859.ce.mr.paper
23	WBPaper00005976.ce.mr.paper	WBPaper00005976	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Genes that act downstream of DAF-16 to influence the lifespan of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005976.ce.mr.paper
24	WBPaper00006390.ce.mr.paper	WBPaper00006390	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide germline-enriched and sex-biased expression profiles in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00006390.ce.mr.paper
25	WBPaper00013462.ce.mr.paper	WBPaper00013462	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Microarray analysis of gene expression with age in individual nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00013462.ce.mr.paper
26	WBPaper00024278.ce.mr.paper	WBPaper00024278	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Shared transcriptional signature in Caenorhabditis elegans Dauer larvae and long-lived daf-2 mutants implicates detoxification system in longevity assurance.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00024278.ce.mr.paper
27	WBPaper00024393.ce.mr.paper	WBPaper00024393	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: dauer larval development	Regulation of signaling genes by TGFbeta during entry into dauer diapause in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00024393.ce.mr.paper
28	WBPaper00024532.ce.mr.paper	WBPaper00024532	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Monomethyl branched-chain fatty acids play an essential role in Caenorhabditis elegans development.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00024532.ce.mr.paper
29	WBPaper00024654.ce.mr.paper	WBPaper00024654	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Translation of a small subset of Caenorhabditis elegans mRNAs is dependent on a specific eukaryotic translation initiation factor 4E isoform.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00024654.ce.mr.paper
30	WBPaper00024671.ce.mr.paper	WBPaper00024671	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: sensory perception of smell	Identification of thermosensory and olfactory neuron-specific genes via expression profiling of single neuron types.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00024671.ce.mr.paper
31	WBPaper00025032.ce.mr.paper	WBPaper00025032	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: cell fate specification	The homeodomain protein PAL-1 specifies a lineage-specific regulatory network in the C. elegans embryo.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00025032.ce.mr.paper
32	WBPaper00025141.ce.mr.paper	WBPaper00025141	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	A gene expression fingerprint of C. elegans embryonic motor neurons.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00025141.ce.mr.paper
33	WBPaper00026596.ce.mr.paper	WBPaper00026596	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Roles of the HIF-1 hypoxia-inducible factor during hypoxia response in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026596.ce.mr.paper
34	WBPaper00026714.ce.mr.paper	WBPaper00026714	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Using microarrays to facilitate positional cloning: identification of tomosyn as an inhibitor of neurosecretion.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026714.ce.mr.paper
35	WBPaper00026820.ce.mr.paper	WBPaper00026820	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Expression profiling of five different xenobiotics using a Caenorhabditis elegans whole genome microarray.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026820.ce.mr.paper
36	WBPaper00026830.ce.mr.paper	WBPaper00026830	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	Genetic interactions due to constitutive and inducible gene regulation mediated by the unfolded protein response in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026830.ce.mr.paper
37	WBPaper00026950.ce.mr.paper	WBPaper00026950	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Comparative analysis of SAGE and microarray technologies for global transcription profiling of development in Caenorhabditis elegans	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026950.ce.mr.paper
38	WBPaper00026980.ce.mr.paper	WBPaper00026980	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: gene expression	Chromosomal clustering and GATA transcriptional regulation of intestine-expressed genes in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026980.ce.mr.paper
39	WBPaper00027104.ce.mr.paper	WBPaper00027104	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Identification of novel target genes of CeTwist and CeE/DA.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00027104.ce.mr.paper
40	WBPaper00027111.ce.mr.paper	WBPaper00027111	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Interacting endogenous and exogenous RNAi pathways in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00027111.ce.mr.paper
41	WBPaper00027722.ce.mr.paper	WBPaper00027722	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genomic clusters, putative pathogen recognition molecules, and antimicrobial genes are induced by infection of C. elegans with M. nematophilum.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00027722.ce.mr.paper
42	WBPaper00027758.ce.mr.paper	WBPaper00027758	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Promotion of oogenesis and embryogenesis in the C. elegans gonad by EFL-1/DPL-1 (E2F) does not require LIN-35 (pRB).	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00027758.ce.mr.paper
43	WBPaper00028482.ce.mr.paper	WBPaper00028482	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	A conserved role for a GATA transcription factor in regulating epithelial innate immune responses.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028482.ce.mr.paper
44	WBPaper00028564.ce.mr.paper	WBPaper00028564	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Delayed development and lifespan extension as features of metabolic lifestyle alteration in C. elegans under dietary restriction.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028564.ce.mr.paper
45	WBPaper00028789.ce.mr.paper	WBPaper00028789	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	p38 MAPK regulates expression of immune response genes and contributes to longevity in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028789.ce.mr.paper
46	WBPaper00028949.ce.mr.paper	WBPaper00028949	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Identification of ciliary and ciliopathy genes in Caenorhabditis elegans through comparative genomics.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028949.ce.mr.paper
47	WBPaper00028962.ce.mr.paper	WBPaper00028962	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Mapping determinants of gene expression plasticity by genetical genomics in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028962.ce.mr.paper
48	WBPaper00029190.ce.mr.paper	WBPaper00029190	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Transcriptome profiling of the C. elegans Rb ortholog reveals diverse developmental roles.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029190.ce.mr.paper
49	WBPaper00029226.ce.mr.paper	WBPaper00029226	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: developmental process	Transcriptional repressor and activator activities of SMA-9 contribute differentially to BMP-related signaling outputs.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029226.ce.mr.paper
50	WBPaper00029334.ce.mr.paper	WBPaper00029334	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Decline of nucleotide excision repair capacity in aging Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029334.ce.mr.paper
51	WBPaper00029437.ce.mr.paper	WBPaper00029437	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	Genes misregulated in C. elegans deficient in Dicer, RDE-4, or RDE-1 are enriched for innate immunity genes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029437.ce.mr.paper
52	WBPaper00030811.ce.mr.paper	WBPaper00030811	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Toxicogenomic analysis of Caenorhabditis elegans reveals novel genes and pathways involved in the resistance to cadmium toxicity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00030811.ce.mr.paper
53	WBPaper00031003.ce.mr.paper	WBPaper00031003	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: somatic muscle development	The embryonic muscle transcriptome of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031003.ce.mr.paper
54	WBPaper00031662.ce.mr.paper	WBPaper00031662	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genomic response of the nematode Caenorhabditis elegans to spaceflight.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031662.ce.mr.paper
55	WBPaper00032062.ce.mr.paper	WBPaper00032062	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	An elt-3/elt-5/elt-6 GATA transcription circuit guides aging in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032062.ce.mr.paper
56	WBPaper00032165.ce.mr.paper	WBPaper00032165	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Age-related behaviors have distinct transcriptional profiles in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032165.ce.mr.paper
57	WBPaper00032948.ce.mr.paper	WBPaper00032948	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	RNA Pol II accumulates at promoters of growth genes during developmental arrest.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032948.ce.mr.paper
58	WBPaper00034739.ce.mr.paper	WBPaper00034739	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: dauer larval development	Natural variation in gene expression in the early development of dauer larvae of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00034739.ce.mr.paper
59	WBPaper00028809.ce.mr.paper	WBPaper00028809	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	BIR-1, the homologue of human Survivin, regulates expression of developmentally active collagen genes in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028809.ce.mr.paper
60	WBPaper00029115.ce.mr.paper	WBPaper00029115	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	UNC-4 represses CEH-12/HB9 to specify synaptic inputs to VA motor neurons in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029115.ce.mr.paper
61	WBPaper00030839.ce.mr.paper	WBPaper00030839	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Cell-specific microarray profiling experiments reveal a comprehensive picture of gene expression in the C. elegans nervous system.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00030839.ce.mr.paper
62	WBPaper00031070.ce.mr.paper	WBPaper00031070	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Whole genome microarray analysis of C. elegans rrf-3 and eri-1 mutants.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031070.ce.mr.paper
63	WBPaper00031379.ce.mr.paper	WBPaper00031379	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Metabolic pathway profiling of mitochondrial respiratory chain mutants in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031379.ce.mr.paper
64	WBPaper00031525.ce.mr.paper	WBPaper00031525	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Pairing of competitive and topologically distinct regulatory modules enhances patterned gene expression.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031525.ce.mr.paper
65	WBPaper00031532.ce.mr.paper	WBPaper00031532	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Complementary RNA amplification methods enhance microarray identification of transcripts expressed in the C. elegans nervous system.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031532.ce.mr.paper
66	WBPaper00031703.ce.mr.paper	WBPaper00031703	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Haem homeostasis is regulated by the conserved and concerted functions of HRG-1 proteins.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031703.ce.mr.paper
67	WBPaper00031832.ce.mr.paper	WBPaper00031832	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: metabolic process	Coordinated regulation of intestinal functions in C. elegans by LIN-35/Rb and SLR-2.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031832.ce.mr.paper
68	WBPaper00032022.ce.mr.paper	WBPaper00032022	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: programmed cell death	Transcriptional profiling in C. elegans suggests DNA damage dependent apoptosis as an ancient function of the p53 family.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032022.ce.mr.paper
69	WBPaper00032425.ce.mr.paper	WBPaper00032425	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	RNA interference and retinoblastoma-related genes are required for repression of endogenous siRNA targets in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032425.ce.mr.paper
70	WBPaper00032430.ce.mr.paper	WBPaper00032430	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Signalling through RHEB-1 mediates intermittent fasting-induced longevity in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032430.ce.mr.paper
71	WBPaper00032528.ce.mr.paper	WBPaper00032528	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Differential chromatin marking of introns and expressed exons by H3K36me3.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032528.ce.mr.paper
72	WBPaper00032976.ce.mr.paper	WBPaper00032976	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: dosage compensation by hypoactivation of X chromosome	A condensin-like dosage compensation complex acts at a distance to control expression throughout the genome.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032976.ce.mr.paper
73	WBPaper00033099.ce.mr.paper	WBPaper00033099	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Distinct patterns of gene and protein expression elicited by organophosphorus pesticides in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033099.ce.mr.paper
74	WBPaper00034636.ce.mr.paper	WBPaper00034636	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Low-intensity microwave irradiation does not substantially alter gene expression in late larval and adult Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00034636.ce.mr.paper
75	WBPaper00034661.ce.mr.paper	WBPaper00034661	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Ecotoxicity of silver nanoparticles on the soil nematode Caenorhabditis elegans using functional ecotoxicogenomics.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00034661.ce.mr.paper
76	WBPaper00034757.ce.mr.paper	WBPaper00034757	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Oxidative stress and longevity in Caenorhabditis elegans as mediated by SKN-1.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00034757.ce.mr.paper
77	WBPaper00034761.ce.mr.paper	WBPaper00034761	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A multiparameter network reveals extensive divergence between C. elegans bHLH transcription factors.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00034761.ce.mr.paper
78	WBPaper00035197.ce.mr.paper	WBPaper00035197	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: gene expression	C. elegans dysferlin homolog fer-1 is expressed in muscle, and fer-1 mutations initiate altered gene expression of muscle enriched genes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035197.ce.mr.paper
79	WBPaper00035227.ce.mr.paper	WBPaper00035227	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Bio-electrospraying the nematode Caenorhabditis elegans: studying whole-genome transcriptional responses and key life cycle parameters.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035227.ce.mr.paper
80	WBPaper00035429.ce.mr.paper	WBPaper00035429	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Nucleotide excision repair genes are expressed at low levels and are not detectably inducible in Caenorhabditis elegans somatic tissues, but their function is required for normal adult life after UVC exposure.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035429.ce.mr.paper
81	WBPaper00035588.ce.mr.paper	WBPaper00035588	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Comprehensive discovery of endogenous Argonaute binding sites in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035588.ce.mr.paper
82	WBPaper00035873.ce.mr.paper	WBPaper00035873	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genetic and physiological activation of osmosensitive gene expression mimics transcriptional signatures of pathogen infection in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035873.ce.mr.paper
83	WBPaper00035891.ce.mr.paper	WBPaper00035891	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	bZIP transcription factor zip-2 mediates an early response to Pseudomonas aeruginosa infection in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035891.ce.mr.paper
84	WBPaper00035892.ce.mr.paper	WBPaper00035892	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A conserved PMK-1/p38 MAPK is required in caenorhabditis elegans tissue-specific immune response to Yersinia pestis infection.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035892.ce.mr.paper
85	WBPaper00035905.ce.mr.paper	WBPaper00035905	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Genome-wide analysis of mRNA targets for Caenorhabditis elegans FBF, a conserved stem cell regulator.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035905.ce.mr.paper
86	WBPaper00035973.ce.mr.paper	WBPaper00035973	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The microRNA miR-124 controls gene expression in the sensory nervous system of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035973.ce.mr.paper
87	WBPaper00036090.ce.mr.paper	WBPaper00036090	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Dynamic O-GlcNAc cycling at promoters of Caenorhabditis elegans genes regulating longevity, stress, and immunity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036090.ce.mr.paper
88	WBPaper00036135.ce.mr.paper	WBPaper00036135	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A two-tiered compensatory response to loss of DNA repair modulates aging and stress response pathways.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036135.ce.mr.paper
89	WBPaper00036291.ce.mr.paper	WBPaper00036291	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: programmed cell death	Loss of Caenorhabditis elegans UNG-1 uracil-DNA glycosylase affects apoptosis in response to DNA damaging agents.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036291.ce.mr.paper
90	WBPaper00036375.ce.mr.paper	WBPaper00036375	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: cell fate specification	Time-lapse imaging and cell-specific expression profiling reveal dynamic branching and molecular determinants of a multi-dendritic nociceptor in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036375.ce.mr.paper
91	WBPaper00036383.ce.mr.paper	WBPaper00036383	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Members of the H3K4 trimethylation complex regulate lifespan in a germline-dependent manner in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036383.ce.mr.paper
92	WBPaper00036464.ce.mr.paper	WBPaper00036464	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Distinct pathogenesis and host responses during infection of C. elegans by P. aeruginosa and S. aureus.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036464.ce.mr.paper
93	WBPaper00037086.ce.mr.paper	WBPaper00037086	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Biotin starvation with adequate glucose provision causes paradoxical changes in fuel metabolism gene expression similar in rat (Rattus norvegicus), nematode (Caenorhabditis elegans) and yeast (Saccharomyces cerevisiae).	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037086.ce.mr.paper
94	WBPaper00037611.ce.mr.paper	WBPaper00037611	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	GLD-2/RNP-8 cytoplasmic poly(A) polymerase is a broad-spectrum regulator of the oogenesis program.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037611.ce.mr.paper
95	WBPaper00037695.ce.mr.paper	WBPaper00037695	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide analysis of light- and temperature-entrained circadian transcripts in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037695.ce.mr.paper
96	WBPaper00037704.ce.mr.paper	WBPaper00037704	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Characterization of the xenobiotic response of Caenorhabditis elegans to the anthelmintic drug albendazole and the identification of novel drug glucoside metabolites.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037704.ce.mr.paper
97	WBPaper00037765.ce.mr.paper	WBPaper00037765	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Different Mi-2 complexes for various developmental functions in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037765.ce.mr.paper
98	WBPaper00037901.ce.mr.paper	WBPaper00037901	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A quantitative RNA code for mRNA target selection by the germline fate determinant GLD-1.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037901.ce.mr.paper
99	WBPaper00038060.ce.mr.paper	WBPaper00038060	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Overexpression of SUMO perturbs the growth and development of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038060.ce.mr.paper
100	WBPaper00038172.ce.mr.paper	WBPaper00038172	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Lifespan extension induced by AMPK and calcineurin is mediated by CRTC-1 and CREB.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038172.ce.mr.paper
101	WBPaper00038180.ce.mr.paper	WBPaper00038180	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	An MLL/COMPASS subunit functions in the C. elegans dosage compensation complex to target X chromosomes for transcriptional regulation of gene expression.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038180.ce.mr.paper
102	WBPaper00038304.ce.mr.paper	WBPaper00038304	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	Neuronal GPCR controls innate immunity by regulating noncanonical unfolded protein response genes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038304.ce.mr.paper
103	WBPaper00038427.ce.mr.paper	WBPaper00038427	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Chromosome-biased binding and gene regulation by the Caenorhabditis elegans DRM complex.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038427.ce.mr.paper
104	WBPaper00038462.ce.mr.paper	WBPaper00038462	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	A decline in p38 MAPK signaling underlies immunosenescence in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038462.ce.mr.paper
105	WBPaper00039792.ce.mr.paper	WBPaper00039792	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Regulation of behavioral plasticity by systemic temperature signaling in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00039792.ce.mr.paper
106	WBPaper00039851.ce.mr.paper	WBPaper00039851	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	Candida albicans infection of Caenorhabditis elegans induces antifungal immune defenses.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00039851.ce.mr.paper
107	WBPaper00039866.ce.mr.paper	WBPaper00039866	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Transcriptional profiling of C. elegans DAF-19 uncovers a ciliary base-associated protein and a CDK/CCRK/LF2p-related kinase required for intraflagellar transport.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00039866.ce.mr.paper
108	WBPaper00040185.ce.mr.paper	WBPaper00040185	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	NHR-23 dependent collagen and hedgehog-related genes required for molting.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040185.ce.mr.paper
109	WBPaper00040327.ce.mr.paper	WBPaper00040327	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Transgenerational epigenetic inheritance of longevity in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040327.ce.mr.paper
110	WBPaper00040420.ce.mr.paper	WBPaper00040420	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Shared gene expression in distinct neurons expressing common selector genes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040420.ce.mr.paper
111	WBPaper00040603.ce.mr.paper	WBPaper00040603	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Caenorhabditis elegans RNA-processing protein TDP-1 regulates protein homeostasis and life span.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040603.ce.mr.paper
112	WBPaper00040730.ce.mr.paper	WBPaper00040730	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Heme utilization in the Caenorhabditis elegans hypodermal cells is facilitated by heme-responsive gene-2.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040730.ce.mr.paper
113	WBPaper00040808.ce.mr.paper	WBPaper00040808	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The transcriptional response of Caenorhabditis elegans to Ivermectin exposure identifies novel genes involved in the response to reduced food intake.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040808.ce.mr.paper
114	WBPaper00040821.ce.mr.paper	WBPaper00040821	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: programmed cell death	Toxicogenomic responses of the model organism Caenorhabditis elegans to gold nanoparticles.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040821.ce.mr.paper
115	WBPaper00040925.ce.mr.paper	WBPaper00040925	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	RIP-chip-SRM--a new combinatorial large-scale approach identifies a set of translationally regulated bantam/miR-58 targets in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040925.ce.mr.paper
116	WBPaper00040963.ce.mr.paper	WBPaper00040963	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Meta-Analysis of Global Transcriptomics Suggests that Conserved Genetic Pathways are Responsible for Quercetin and Tannic Acid Mediated Longevity in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040963.ce.mr.paper
117	WBPaper00041002.ce.mr.paper	WBPaper00041002	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The Nematode Caenorhabditis elegans, Stress and Aging: Identifying the Complex Interplay of Genetic Pathways Following the Treatment with Humic Substances.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041002.ce.mr.paper
118	WBPaper00041163.ce.mr.paper	WBPaper00041163	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	Genomic analysis of immune response against Vibrio cholerae hemolysin in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041163.ce.mr.paper
119	WBPaper00041191.ce.mr.paper	WBPaper00041191	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Function, targets, and evolution of Caenorhabditis elegans piRNAs.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041191.ce.mr.paper
120	WBPaper00041211.ce.mr.paper	WBPaper00041211	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Stimulation of host immune defenses by a small molecule protects C. elegans from bacterial infection.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041211.ce.mr.paper
121	WBPaper00041267.ce.mr.paper	WBPaper00041267	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genes down-regulated in spaceflight are involved in the control of longevity in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041267.ce.mr.paper
122	WBPaper00041370.ce.mr.paper	WBPaper00041370	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mitochondrial unfolded protein response	Mitochondrial import efficiency of ATFS-1 regulates mitochondrial UPR activation.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041370.ce.mr.paper
123	WBPaper00041906.ce.mr.paper	WBPaper00041906	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Anti-inflammatory Lactobacillus rhamnosus CNCM I-3690 strain protects against oxidative stress and increases lifespan in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041906.ce.mr.paper
124	WBPaper00041939.ce.mr.paper	WBPaper00041939	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Effects of early life exposure to ultraviolet C radiation on mitochondrial DNA content, transcription, ATP production, and oxygen consumption in developing Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041939.ce.mr.paper
125	WBPaper00041960.ce.mr.paper	WBPaper00041960	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A fasting-responsive signaling pathway that extends life span in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041960.ce.mr.paper
126	WBPaper00042067.ce.mr.paper	WBPaper00042067	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The Caenorhabditis elegans JNK signaling pathway activates expression of stress response genes by derepressing the Fos/HDAC repressor complex.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042067.ce.mr.paper
127	WBPaper00042128.ce.mr.paper	WBPaper00042128	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	GEI-8, a homologue of vertebrate nuclear receptor corepressor NCoR/SMRT, regulates gonad development and neuronal functions in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042128.ce.mr.paper
128	WBPaper00042178.ce.mr.paper	WBPaper00042178	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Genome-wide microarrray analysis reveals roles for the REF-1 family member HLH-29 in ferritin synthesis and peroxide stress response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042178.ce.mr.paper
129	WBPaper00042204.ce.mr.paper	WBPaper00042204	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Integration of metabolic and gene regulatory networks modulates the C. elegans dietary response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042204.ce.mr.paper
130	WBPaper00042234.ce.mr.paper	WBPaper00042234	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Active transcriptomic and proteomic reprogramming in the C. elegans nucleotide excision repair mutant xpa-1.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042234.ce.mr.paper
131	WBPaper00042258.ce.mr.paper	WBPaper00042258	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Diet-induced developmental acceleration independent of TOR and insulin in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042258.ce.mr.paper
132	WBPaper00042331.ce.mr.paper	WBPaper00042331	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Molecular characterization of toxicity mechanism of single-walled carbon nanotubes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042331.ce.mr.paper
133	WBPaper00042340.ce.mr.paper	WBPaper00042340	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Alterations in gene expression in Caenorhabditis elegans associated with organophosphate pesticide intoxication and recovery.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042340.ce.mr.paper
134	WBPaper00042404.ce.mr.paper	WBPaper00042404	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A cocoa peptide protects Caenorhabditis elegans from oxidative stress and -amyloid peptide toxicity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042404.ce.mr.paper
135	WBPaper00042574.ce.mr.paper	WBPaper00042574	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Competition between virus-derived and endogenous small RNAs regulates gene expression in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042574.ce.mr.paper
136	WBPaper00043980.ce.mr.paper	WBPaper00043980	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genomic analysis of stress response against arsenic in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00043980.ce.mr.paper
137	WBPaper00044163.ce.mr.paper	WBPaper00044163	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	DNA damage leads to progressive replicative decline but extends the life span of long-lived mutant animals.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044163.ce.mr.paper
138	WBPaper00044197.ce.mr.paper	WBPaper00044197	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	SUMOylation is essential for sex-specific assembly and function of the Caenorhabditis elegans dosage compensation complex on X chromosomes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044197.ce.mr.paper
139	WBPaper00044535.ce.mr.paper	WBPaper00044535	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Males shorten the life span of C. elegans hermaphrodites via secreted compounds.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044535.ce.mr.paper
140	WBPaper00044545.ce.mr.paper	WBPaper00044545	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Opposing activities of DRM and MES-4 tune gene expression and X-chromosome repression in Caenorhabditis elegans germ cells.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044545.ce.mr.paper
141	WBPaper00044857.ce.mr.paper	WBPaper00044857	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: Wnt signaling pathway	Use of an activated beta-catenin to identify Wnt pathway target genes in caenorhabditis elegans, including a subset of collagen genes expressed in late larval development.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044857.ce.mr.paper
142	WBPaper00045263.ce.mr.paper	WBPaper00045263	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The intrinsic apoptosis pathway mediates the pro-longevity response to mitochondrial ROS in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045263.ce.mr.paper
143	WBPaper00045374.ce.mr.paper	WBPaper00045374	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Integrative assessment of benzene exposure to Caenorhabditis elegans using computational behavior and toxicogenomic analyses.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045374.ce.mr.paper
144	WBPaper00045437.ce.mr.paper	WBPaper00045437	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Toxic-selenium and low-selenium transcriptomes in Caenorhabditis elegans: toxic selenium up-regulates oxidoreductase and down-regulates cuticle-associated genes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045437.ce.mr.paper
145	WBPaper00045802.ce.mr.paper	WBPaper00045802	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Translational control of the oogenic program by components of OMA ribonucleoprotein particles in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045802.ce.mr.paper
146	WBPaper00045807.ce.mr.paper	WBPaper00045807	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Neurotoxic action of microcystin-LR is reflected in the transcriptional stress response of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045807.ce.mr.paper
147	WBPaper00045960.ce.mr.paper	WBPaper00045960	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Dynamically-expressed prion-like proteins form a cuticle in the pharynx of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045960.ce.mr.paper
148	WBPaper00046083.ce.mr.paper	WBPaper00046083	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Conserved nutrient sensor O-GlcNAc transferase is integral to C. elegans pathogen-specific immunity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046083.ce.mr.paper
149	WBPaper00046102.ce.mr.paper	WBPaper00046102	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Identifying A-specific pathogenic mechanisms using a nematode model of Alzheimer's disease.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046102.ce.mr.paper
150	WBPaper00046496.ce.mr.paper	WBPaper00046496	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Rifampicin reduces advanced glycation end products and activates DAF-16 to increase lifespan in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046496.ce.mr.paper
151	WBPaper00046523.ce.mr.paper	WBPaper00046523	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Pharmacologic targeting of sirtuin and PPAR signaling improves longevity and mitochondrial physiology in respiratory chain complex I mutant Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046523.ce.mr.paper
152	WBPaper00046548.ce.mr.paper	WBPaper00046548	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The nuclear receptor DAF-12 regulates nutrient metabolism and reproductive growth in nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046548.ce.mr.paper
153	WBPaper00046639.ce.mr.paper	WBPaper00046639	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Gene expression profiling to investigate tyrosol-induced lifespan extension in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046639.ce.mr.paper
154	WBPaper00046678.ce.mr.paper	WBPaper00046678	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A Lipid-TORC1 Pathway Promotes Neuronal Development and Foraging Behavior under Both Fed and Fasted Conditions in C.elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046678.ce.mr.paper
155	WBPaper00046853.ce.mr.paper	WBPaper00046853	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Adsorbable organic bromine compounds (AOBr) in aquatic samples: a nematode-based toxicogenomic assessment of the exposure hazard.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046853.ce.mr.paper
156	WBPaper00046887.ce.mr.paper	WBPaper00046887	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: Wnt signaling pathway	Identification of Wnt Pathway Target Genes Regulating the Division and Differentiation of Larval Seam Cells and Vulval Precursor Cells in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046887.ce.mr.paper
157	WBPaper00047021.ce.mr.paper	WBPaper00047021	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A systems toxicology approach on the mechanism of uptake and toxicity of MWCNT in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00047021.ce.mr.paper
158	WBPaper00047070_1.ce.mr.paper	WBPaper00047070_1	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	DAF-16/FOXO and EGL-27/GATA promote developmental growth in response to persistent somatic DNA damage.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00047070_1.ce.mr.paper
159	WBPaper00047070_2.ce.mr.paper	WBPaper00047070_2	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	DAF-16/FOXO and EGL-27/GATA promote developmental growth in response to persistent somatic DNA damage.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00047070_2.ce.mr.paper
160	WBPaper00048490.ce.mr.paper	WBPaper00048490	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	s-Adenosylmethionine Levels Govern Innate Immunity through Distinct Methylation-Dependent Pathways.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048490.ce.mr.paper
161	WBPaper00048530.ce.mr.paper	WBPaper00048530	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The Conserved G-Protein Coupled Receptor FSHR-1 Regulates Protective Host Responses to Infection and Oxidative Stress.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048530.ce.mr.paper
162	WBPaper00048563.ce.mr.paper	WBPaper00048563	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Transcriptional Control of Synaptic Remodeling through Regulated Expression of an Immunoglobulin Superfamily Protein.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048563.ce.mr.paper
163	WBPaper00048637.ce.mr.paper	WBPaper00048637	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The tumor suppressor Rb critically regulates starvation-induced stress response in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048637.ce.mr.paper
164	WBPaper00048762.ce.mr.paper	WBPaper00048762	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genomic Analyses of Sperm Fate Regulator Targets Reveal a Common Set of Oogenic mRNAs in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048762.ce.mr.paper
165	WBPaper00048771.ce.mr.paper	WBPaper00048771	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Spatial and temporal translational control of germ cell mRNAs via an eIF4E isoform, IFE-1.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048771.ce.mr.paper
166	WBPaper00048989.ce.mr.paper	WBPaper00048989	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A network pharmacology approach reveals new candidate caloric restriction mimetics in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048989.ce.mr.paper
167	WBPaper00049311.ce.mr.paper	WBPaper00049311	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Distinct transcriptomic responses of Caenorhabditis elegans to pristine and sulfidized silver nanoparticles.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049311.ce.mr.paper
168	WBPaper00049364.ce.mr.paper	WBPaper00049364	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A Systems Approach to Reverse Engineer Lifespan Extension by Dietary Restriction.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049364.ce.mr.paper
169	WBPaper00049417.ce.mr.paper	WBPaper00049417	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The Probiotic Strain Bifidobacterium animalis subsp. lactis CECT 8145 Reduces Fat Content and Modulates Lipid Metabolism and Antioxidant Response in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049417.ce.mr.paper
170	WBPaper00049538.ce.mr.paper	WBPaper00049538	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mitochondrial unfolded protein response	Maintenance and propagation of a deleterious mitochondrial genome by the mitochondrial unfolded protein response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049538.ce.mr.paper
171	WBPaper00050079.ce.mr.paper	WBPaper00050079	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A High-Content, Phenotypic Screen Identifies Fluorouridine as an Inhibitor of Pyoverdine Biosynthesis and Pseudomonas aeruginosa Virulence.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00050079.ce.mr.paper
172	WBPaper00033126.ce.mr.paper	WBPaper00033126	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	IRE-1 and HSP-4 contribute to energy homeostasis via fasting-induced lipases in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033126.ce.mr.paper
173	WBPaper00033206.ce.mr.paper	WBPaper00033206	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The polycomb complex protein mes-2/E(z) promotes the transition from developmental plasticity to differentiation in C. elegans embryos.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033206.ce.mr.paper
174	WBPaper00035187.cbg.mr.paper	WBPaper00035187	Method: microarray	Species: Caenorhabditis briggsae	Whole Animal	N.A.	Comparison of diverse developmental transcriptomes reveals that coexpression of gene neighbors is not evolutionarily conserved.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035187.cbg.mr.paper
175	WBPaper00035187.ce.mr.paper	WBPaper00035187	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Comparison of diverse developmental transcriptomes reveals that coexpression of gene neighbors is not evolutionarily conserved.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035187.ce.mr.paper
176	WBPaper00035269.ce.mr.paper	WBPaper00035269	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	CDE-1 affects chromosome segregation through uridylation of CSR-1-bound siRNAs.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035269.ce.mr.paper
177	WBPaper00036130.ce.mr.paper	WBPaper00036130	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: regulation of pre-miRNA processing	MicroRNA-directed siRNA biogenesis in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036130.ce.mr.paper
178	WBPaper00036256.ce.mr.paper	WBPaper00036256	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	Insulin/IGF-1 signaling mutants reprogram ER stress response regulators to promote longevity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036256.ce.mr.paper
179	WBPaper00037624.ce.mr.paper	WBPaper00037624	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	ETS-4 is a transcriptional regulator of life span in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037624.ce.mr.paper
180	WBPaper00037680.ce.mr.paper	WBPaper00037680	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Selection at linked sites shapes heritable phenotypic variation in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037680.ce.mr.paper
181	WBPaper00037682.ce.mr.paper	WBPaper00037682	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: programmed cell death	TGF- and insulin signaling regulate reproductive aging via oocyte and germline quality maintenance.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037682.ce.mr.paper
182	WBPaper00038237.ce.mr.paper	WBPaper00038237	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Co-regulation of the DAF-16 target gene, cyp-35B1/dod-13, by HSF-1 in C. elegans dauer larvae and daf-2 insulin pathway mutants.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038237.ce.mr.paper
183	WBPaper00038519.ce.mr.paper	WBPaper00038519	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: RNA interference	The effectiveness of RNAi in Caenorhabditis elegans is maintained during spaceflight.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038519.ce.mr.paper
184	WBPaper00039878.ce.mr.paper	WBPaper00039878	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Extension of lifespan in C. elegans by naphthoquinones that act through stress hormesis mechanisms.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00039878.ce.mr.paper
185	WBPaper00040116.ce.mr.paper	WBPaper00040116	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Lifespan-extending effects of royal jelly and its related substances on the nematode Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040116.ce.mr.paper
186	WBPaper00040184.ce.mr.paper	WBPaper00040184	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The evolutionarily conserved longevity determinants HCF-1 and SIR-2.1/SIRT1 collaborate to regulate DAF-16/FOXO.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040184.ce.mr.paper
187	WBPaper00040410.ce.mr.paper	WBPaper00040410	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Novel roles of Caenorhabditis elegans heterochromatin protein HP1 and linker histone in the regulation of innate immune gene expression.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040410.ce.mr.paper
188	WBPaper00040426.ce.mr.paper	WBPaper00040426	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Caenorhabditis elegans cyclin D/CDK4 and cyclin E/CDK2 induce distinct cell cycle re-entry programs in differentiated muscle cells.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040426.ce.mr.paper
189	WBPaper00040823.ce.mr.paper	WBPaper00040823	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	The microRNA pathway controls germ cell proliferation and differentiation in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040823.ce.mr.paper
190	WBPaper00041174.ce.mr.paper	WBPaper00041174	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A genomic bias for genotype-environment interactions in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041174.ce.mr.paper
191	WBPaper00041190.cbg.mr.paper	WBPaper00041190	Method: microarray	Species: Caenorhabditis briggsae	Whole Animal	N.A.	Developmental milestones punctuate gene expression in the Caenorhabditis embryo.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041190.cbg.mr.paper
192	WBPaper00041190.cbn.mr.paper	WBPaper00041190	Method: microarray	Species: Caenorhabditis brenneri	Whole Animal	N.A.	Developmental milestones punctuate gene expression in the Caenorhabditis embryo.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041190.cbn.mr.paper
193	WBPaper00041190.cja.mr.paper	WBPaper00041190	Method: microarray	Species: Caenorhabditis japonica	Whole Animal	N.A.	Developmental milestones punctuate gene expression in the Caenorhabditis embryo.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041190.cja.mr.paper
194	WBPaper00041190.cre.mr.paper	WBPaper00041190	Method: microarray	Species: Caenorhabditis remanei	Whole Animal	N.A.	Developmental milestones punctuate gene expression in the Caenorhabditis embryo.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041190.cre.mr.paper
195	WBPaper00041190.ce.mr.paper	WBPaper00041190	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Developmental milestones punctuate gene expression in the Caenorhabditis embryo.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041190.ce.mr.paper
196	WBPaper00041207.ce.mr.paper	WBPaper00041207	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Divergent gene expression in the conserved dauer stage of the nematodes Pristionchus pacificus and Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041207.ce.mr.paper
197	WBPaper00041207.ppa.mr.paper	WBPaper00041207	Method: microarray	Species: Pristionchus pacificus	Whole Animal	N.A.	Divergent gene expression in the conserved dauer stage of the nematodes Pristionchus pacificus and Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041207.ppa.mr.paper
198	WBPaper00041466.ppa.mr.paper	WBPaper00041466	Method: microarray	Species: Pristionchus pacificus	Whole Animal	N.A.	Genome-wide analysis of germline signaling genes regulating longevity and innate immunity in the nematode Pristionchus pacificus.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041466.ppa.mr.paper
199	WBPaper00041606.ce.mr.paper	WBPaper00041606	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	System wide analysis of the evolution of innate immunity in the nematode model species Caenorhabditis elegans and Pristionchus pacificus.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041606.ce.mr.paper
200	WBPaper00041606.ppa.mr.paper	WBPaper00041606	Method: microarray	Species: Pristionchus pacificus	Whole Animal	Topic: innate immune response	System wide analysis of the evolution of innate immunity in the nematode model species Caenorhabditis elegans and Pristionchus pacificus.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041606.ppa.mr.paper
201	WBPaper00041609.ce.mr.paper	WBPaper00041609	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Transcriptional repression of Hox genes by C. elegans HP1/HPL and H1/HIS-24.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041609.ce.mr.paper
202	WBPaper00042548.ce.mr.paper	WBPaper00042548	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Functional analysis of neuronal microRNAs in Caenorhabditis elegans dauer formation by combinational genetics and Neuronal miRISC immunoprecipitation.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042548.ce.mr.paper
203	WBPaper00044005.ce.mr.paper	WBPaper00044005	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	PQM-1 complements DAF-16 as a key transcriptional regulator of DAF-2-mediated development and longevity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044005.ce.mr.paper
204	WBPaper00044013.ce.mr.paper	WBPaper00044013	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	New role for DCR-1/dicer in Caenorhabditis elegans innate immunity against the highly virulent bacterium Bacillus thuringiensis DB27.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044013.ce.mr.paper
205	WBPaper00044030.ce.mr.paper	WBPaper00044030	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The NHR-8 nuclear receptor regulates cholesterol and bile acid homeostasis in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044030.ce.mr.paper
206	WBPaper00044316.ce.mr.paper	WBPaper00044316	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Comparative toxicogenomic responses of mercuric and methyl-mercury.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044316.ce.mr.paper
207	WBPaper00044578.ce.mr.paper	WBPaper00044578	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Molecular strategies of the Caenorhabditis elegans dauer larva to survive extreme desiccation.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044578.ce.mr.paper
208	WBPaper00044939.ce.mr.paper	WBPaper00044939	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A variant in the neuropeptide receptor npr-1 is a major determinant of Caenorhabditis elegans growth and physiology.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044939.ce.mr.paper
209	WBPaper00045036.ce.mr.paper	WBPaper00045036	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A novel kinase regulates dietary restriction-mediated longevity in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045036.ce.mr.paper
210	WBPaper00045417.ce.mr.paper	WBPaper00045417	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: Wnt signaling pathway	The Wnt receptor Ryk reduces neuronal and cell survival capacity by repressing FOXO activity during the early phases of mutant huntingtin pathogenicity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045417.ce.mr.paper
211	WBPaper00045571.ce.mr.paper	WBPaper00045571	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: aging	A functional genomic screen for evolutionarily conserved genes required for lifespan and immunity in germline-deficient C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045571.ce.mr.paper
212	WBPaper00045861.ce.mr.paper	WBPaper00045861	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	The SET-2/SET1 histone H3K4 methyltransferase maintains pluripotency in the Caenorhabditis elegans germline.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045861.ce.mr.paper
213	WBPaper00045918.ce.mr.paper	WBPaper00045918	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Recovery from an acute infection in C. elegans requires the GATA transcription factor ELT-2.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045918.ce.mr.paper
214	WBPaper00046212.ce.mr.paper	WBPaper00046212	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Natural RNA interference directs a heritable response to the environment.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046212.ce.mr.paper
215	WBPaper00046643.ce.mr.paper	WBPaper00046643	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	The principle of antagonism ensures protein targeting specificity at the endoplasmic reticulum.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046643.ce.mr.paper
216	WBPaper00048657.ce.mr.paper	WBPaper00048657	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Natural Variation in plep-1 Causes Male-Male Copulatory Behavior in C.elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048657.ce.mr.paper
217	WBPaper00048990.ce.mr.paper	WBPaper00048990	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The Mediator Kinase Module Restrains Epidermal Growth Factor Receptor Signaling and Represses Vulval Cell Fate Specification in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048990.ce.mr.paper
218	WBPaper00049336.ce.mr.paper	WBPaper00049336	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Sleep-active neuron specification and sleep induction require FLP-11 neuropeptides to systemically induce sleep.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049336.ce.mr.paper
219	WBPaper00049380.ce.mr.paper	WBPaper00049380	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: programmed cell death	Natural Genetic Variation Influences Protein Abundances in C. elegans Developmental Signalling Pathways.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049380.ce.mr.paper
220	WBPaper00049736.ce.mr.paper	WBPaper00049736	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Sperm Affects Head Sensory Neuron in Temperature Tolerance of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00049736.ce.mr.paper
221	WBPaper00050096.ce.mr.paper	WBPaper00050096	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Role of GATA transcription factor ELT-2 and p38 MAPK PMK-1 in recovery from acute P. aeruginosa infection in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00050096.ce.mr.paper
222	WBPaper00035654.ce.mr.paper	WBPaper00035654	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Global microRNA expression profiling of Caenorhabditis elegans Parkinson's disease models.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035654.ce.mr.paper
223	WBPaper00035664.ce.mr.paper	WBPaper00035664	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Many families of C. elegans microRNAs are not essential for development or viability.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035664.ce.mr.paper
224	WBPaper00038519_2.ce.mr.paper	WBPaper00038519_2	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: RNA interference	The effectiveness of RNAi in Caenorhabditis elegans is maintained during spaceflight.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038519_2.ce.mr.paper
225	WBPaper00040911.ce.mr.paper	WBPaper00040911	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: regulation of pre-miRNA processing	Developmental characterization of the microRNA-specific C. elegans Argonautes alg-1 and alg-2.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040911.ce.mr.paper
226	WBPaper00040932.ce.mr.paper	WBPaper00040932	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	lin-28 controls the succession of cell fate choices via two distinct activities.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040932.ce.mr.paper
227	WBPaper00045807_2.ce.mr.paper	WBPaper00045807_2	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Neurotoxic action of microcystin-LR is reflected in the transcriptional stress response of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045807_2.ce.mr.paper
228	WBPaper00006488.ce.mr.paper	WBPaper00006488	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	TLR-independent control of innate immunity in Caenorhabditis elegans by the TIR domain adaptor protein TIR-1, an ortholog of human SARM.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00006488.ce.mr.paper
229	WBPaper00029387.ce.mr.paper	WBPaper00029387	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Cytochrome P450s and short-chain dehydrogenases mediate the toxicogenomic response of PCB52 in the nematode Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029387.ce.mr.paper
230	WBPaper00032031_2.ce.mr.paper	WBPaper00032031_2	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Anti-fungal innate immunity in C. elegans is enhanced by evolutionary diversification of antimicrobial peptides.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032031_2.ce.mr.paper
231	WBPaper00033070.ce.mr.paper	WBPaper00033070	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Gene expression profiling to characterize sediment toxicity--a pilot study using Caenorhabditis elegans whole genome microarrays.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033070.ce.mr.paper
232	WBPaper00035408.ce.mr.paper	WBPaper00035408	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The C. elegans dosage compensation complex propagates dynamically and independently of X chromosome sequence.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035408.ce.mr.paper
233	WBPaper00035479.ce.mr.paper	WBPaper00035479	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Glucose shortens the life span of C. elegans by downregulating DAF-16/FOXO activity and aquaporin gene expression.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035479.ce.mr.paper
234	WBPaper00036123.ce.mr.paper	WBPaper00036123	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	Linking toxicant physiological mode of action with induced gene expression changes in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036123.ce.mr.paper
235	WBPaper00037131.ce.mr.paper	WBPaper00037131	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The histone H3K36 methyltransferase MES-4 acts epigenetically to transmit the memory of germline gene expression to progeny.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037131.ce.mr.paper
236	WBPaper00037949.ce.mr.paper	WBPaper00037949	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	High nucleosome occupancy is encoded at X-linked gene promoters in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037949.ce.mr.paper
237	WBPaper00041876.ce.mr.paper	WBPaper00041876	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genes that act downstream of sensory neurons to influence longevity, dauer formation, and pathogen responses in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041876.ce.mr.paper
238	WBPaper00044638.ce.mr.paper	WBPaper00044638	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Germline signaling mediates the synergistically prolonged longevity produced by double mutations in daf-2 and rsks-1 in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044638.ce.mr.paper
239	WBPaper00046104.ce.mr.paper	WBPaper00046104	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Defining heterochromatin in C. elegans through genome-wide analysis of the heterochromatin protein 1 homolog HPL-2.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046104.ce.mr.paper
240	WBPaper00038011.ce.mr.paper	WBPaper00038011	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Few gene expression differences between C. elegans grown in liquid versus on plates	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038011.ce.mr.paper
241	WBPaper00005124.ce.mr.paper	WBPaper00005124	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Caenorhabditis elegans as an environmental monitor using DNA microarray analysis.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005124.ce.mr.paper
242	WBPaper00005428.ce.mr.paper	WBPaper00005428	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: gene expression	Chromosomal clustering of muscle-expressed genes in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005428.ce.mr.paper
243	WBPaper00005751.ce.mr.paper	WBPaper00005751	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Gene expression analysis in a transgenic Caenorhabditis elegans Alzheimer's disease model.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005751.ce.mr.paper
244	WBPaper00025192.ce.mr.paper	WBPaper00025192	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Regulation of tissue-specific and extracellular matrix-related genes by a class I histone deacetylase.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00025192.ce.mr.paper
245	WBPaper00026929.ce.mr.paper	WBPaper00026929	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	A role for SIR-2.1 regulation of ER stress response genes in determining C. elegans life span.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026929.ce.mr.paper
246	WBPaper00028948.ce.mr.paper	WBPaper00028948	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: cell death	Regulation of developmental rate and germ cell proliferation in Caenorhabditis elegans by the p53 gene network.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028948.ce.mr.paper
247	WBPaper00029087.ce.mr.paper	WBPaper00029087	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Differential gene expression of Caenorhabditis elegans grown on unmethylated sterols or 4alpha-methylsterols.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00029087.ce.mr.paper
248	WBPaper00030985.ce.mr.paper	WBPaper00030985	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide investigation reveals pathogen-specific and shared signatures in the response of Caenorhabditis elegans to infection.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00030985.ce.mr.paper
249	WBPaper00031850.ce.mr.paper	WBPaper00031850	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: stress response to metal ion	The Mediator subunit MDT-15 confers metabolic adaptation to ingested material.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031850.ce.mr.paper
250	WBPaper00004966.ce.mr.paper	WBPaper00004966	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	A systematic gene expression screen of Caenorhabditis elegans cytochrome P450 genes reveals CYP35 as strongly xenobiotic inducible.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00004966.ce.mr.paper
251	WBPaper00005896.ce.mr.paper	WBPaper00005896	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Transcriptional outputs of the Caenorhabditis elegans forkhead protein DAF-16.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00005896.ce.mr.paper
252	WBPaper00006465.ce.mr.paper	WBPaper00006465	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Ethanol-response genes and their regulation analyzed by a microarray and comparative genomic approach in the nematode Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00006465.ce.mr.paper
253	WBPaper00013489.ce.mr.paper	WBPaper00013489	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: sensory organ development	Identification of C. elegans sensory ray genes using whole-genome expression profiling.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00013489.ce.mr.paper
254	WBPaper00024375.ce.mr.paper	WBPaper00024375	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genetic analysis of pathways regulated by the von Hippel-Lindau tumor suppressor in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00024375.ce.mr.paper
255	WBPaper00025099.ce.mr.paper	WBPaper00025099	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The transcriptional consequences of mutation and natural selection in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00025099.ce.mr.paper
256	WBPaper00026952.ce.mr.paper	WBPaper00026952	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The Caenorhabditis elegans heterochronic regulator LIN-14 is a novel transcription factor that controls the developmental timing of transcription from the insulin/insulin-like growth factor gene ins-33 by direct DNA binding.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00026952.ce.mr.paper
257	WBPaper00028483.ce.mr.paper	WBPaper00028483	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: gene expression	MES-4: an autosome-associated histone methyltransferase that participates in silencing the X chromosomes in the C. elegans germ line.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028483.ce.mr.paper
258	WBPaper00028788.ce.mr.paper	WBPaper00028788	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: meiotic cell cycle	Expression profiling of MAP kinase-mediated meiotic progression in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00028788.ce.mr.paper
259	WBPaper00031477.ce.mr.paper	WBPaper00031477	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: P granule organization	DEPS-1 promotes P-granule assembly and RNA interference in C. elegans germ cells.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031477.ce.mr.paper
260	WBPaper00032276.ce.mr.paper	WBPaper00032276	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Pseudomonas aeruginosa suppresses host immunity by activating the DAF-2 insulin-like signaling pathway in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032276.ce.mr.paper
261	WBPaper00036429.ce.mr.paper	WBPaper00036429	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide analysis of germ cell proliferation in C.elegans identifies VRK-1 as a key regulator of CEP-1/p53.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036429.ce.mr.paper
262	WBPaper00044091.ce.mr.paper	WBPaper00044091	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Burkholderia pseudomallei suppresses Caenorhabditis elegans immunity by specific degradation of a GATA transcription factor.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044091.ce.mr.paper
263	WBPaper00006365.ce.mr.paper	WBPaper00006365	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Comparing genomic expression patterns across species identifies shared transcriptional profile in aging.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00006365.ce.mr.paper
264	WBPaper00027339.ce.mr.paper	WBPaper00027339	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	The nuclear hormone receptor DAF-12 has opposing effects on Caenorhabditis elegans lifespan and regulates genes repressed in multiple long-lived worms.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00027339.ce.mr.paper
265	WBPaper00031252.ce.mr.paper	WBPaper00031252	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: regulation of pre-miRNA processing	Systematic identification of C. elegans miRISC proteins, miRNAs, and mRNA targets by their interactions with GW182 proteins AIN-1 and AIN-2.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031252.ce.mr.paper
266	WBPaper00032031.ce.mr.paper	WBPaper00032031	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Anti-fungal innate immunity in C. elegans is enhanced by evolutionary diversification of antimicrobial peptides.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032031.ce.mr.paper
267	WBPaper00033094.ce.mr.paper	WBPaper00033094	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: defense response	Antifungal innate immunity in C. elegans: PKCdelta links G protein signaling and a conserved p38 MAPK cascade.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033094.ce.mr.paper
268	WBPaper00033101.ce.mr.paper	WBPaper00033101	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: germ-line stem cell population maintenance	A C. elegans LSD1 demethylase contributes to germline immortality by reprogramming epigenetic memory.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033101.ce.mr.paper
269	WBPaper00033444.ce.mr.paper	WBPaper00033444	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Caenorhabditis elegans genomic response to soil bacteria predicts environment-specific genetic effects on life history traits.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00033444.ce.mr.paper
270	WBPaper00035084.ce.mr.paper	WBPaper00035084	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Systematic analysis of dynamic miRNA-target interactions during C. elegans development.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035084.ce.mr.paper
271	WBPaper00035424.ce.mr.paper	WBPaper00035424	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Single-cell transcriptional analysis of taste sensory neuron pair in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035424.ce.mr.paper
272	WBPaper00035504.ce.mr.paper	WBPaper00035504	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Divergent mechanisms controlling hypoxic sensitivity and lifespan by the DAF-2/insulin/IGF-receptor pathway.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035504.ce.mr.paper
273	WBPaper00035560.ce.mr.paper	WBPaper00035560	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Fatty acid composition and gene expression profiles are altered in aryl hydrocarbon receptor-1 mutant Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00035560.ce.mr.paper
274	WBPaper00036286.ce.mr.paper	WBPaper00036286	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide gene expression regulation as a function of genotype and age in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036286.ce.mr.paper
275	WBPaper00037113.ce.mr.paper	WBPaper00037113	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide gene expression analysis in response to organophosphorus pesticide chlorpyrifos and diazinon in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037113.ce.mr.paper
276	WBPaper00037147.ce.mr.paper	WBPaper00037147	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Insulin-like signaling determines survival during stress via posttranscriptional mechanisms in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037147.ce.mr.paper
277	WBPaper00037849.ce.mr.paper	WBPaper00037849	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Regulation of C. elegans presynaptic differentiation and neurite branching via a novel signaling pathway initiated by SAM-10.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037849.ce.mr.paper
278	WBPaper00038168.ce.mr.paper	WBPaper00038168	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	synMuv B proteins antagonize germline fate in the intestine and ensure C. elegans survival.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038168.ce.mr.paper
279	WBPaper00039835.ce.mr.paper	WBPaper00039835	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: aging	Life span extension via eIF4G inhibition is mediated by posttranscriptional remodeling of stress response gene expression in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00039835.ce.mr.paper
280	WBPaper00040210.ce.mr.paper	WBPaper00040210	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Gene expression modifications by temperature-toxicants interactions in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040210.ce.mr.paper
281	WBPaper00040858.ce.mr.paper	WBPaper00040858	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Aging Uncouples Heritability and Expression-QTL in Caenorhabditis elegans	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040858.ce.mr.paper
282	WBPaper00040985.ce.mr.paper	WBPaper00040985	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	Topic: defense response	Systematic analysis of tissue-restricted miRISCs reveals a broad role for microRNAs in suppressing basal activity of the C. elegans pathogen response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040985.ce.mr.paper
283	WBPaper00040990.ce.mr.paper	WBPaper00040990	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	Dissociation of immune responses from pathogen colonization supports pattern recognition in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040990.ce.mr.paper
284	WBPaper00040998.ce.mr.paper	WBPaper00040998	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Coordinate regulation of lipid metabolism by novel nuclear receptor partnerships.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040998.ce.mr.paper
285	WBPaper00041300.ce.mr.paper	WBPaper00041300	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Radiation-induced genomic instability in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041300.ce.mr.paper
286	WBPaper00041688.ce.mr.paper	WBPaper00041688	Method: microarray	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Antagonism between MES-4 and Polycomb repressive complex 2 promotes appropriate gene expression in C. elegans germ cells.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041688.ce.mr.paper
287	WBPaper00045015.ce.mr.paper	WBPaper00045015	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	N.A.	Defects in the C. elegans acyl-CoA synthase, acs-3, and nuclear hormone receptor, nhr-25, cause sensitivity to distinct, but overlapping stresses.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045015.ce.mr.paper
288	WBPaper00046858.ce.mr.paper	WBPaper00046858	Method: microarray	Species: Caenorhabditis elegans	Whole Animal	Topic: innate immune response	The Developmental Intestinal Regulator ELT-2 Controls p38-Dependent Immune Responses in Adult C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046858.ce.mr.paper
289	WBPaper00044128.ce.ms.paper	WBPaper00044128	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	Reduced insulin/insulin-like growth factor-1 signaling and dietary restriction inhibit translation but preserve muscle mass in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044128.ce.ms.paper
290	WBPaper00045460.ce.ms.paper	WBPaper00045460	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	Topic: response to unfolded protein	Intestinal amino acid availability via PEPT-1 affects TORC1/2 signaling and the unfolded protein response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045460.ce.ms.paper
291	WBPaper00046217.ce.ms.paper	WBPaper00046217	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	Comparison of proteomic and metabolomic profiles of mutants of the mitochondrial respiratory chain in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046217.ce.ms.paper
292	WBPaper00046795.ce.ms.paper	WBPaper00046795	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	Global Proteomics Analysis of the Response to Starvation in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046795.ce.ms.paper
293	WBPaper00046981.ce.ms.paper	WBPaper00046981	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	Lipidomic and proteomic analysis of Caenorhabditis elegans lipid droplets and identification of ACS-4 as a lipid droplet-associated protein.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046981.ce.ms.paper
294	WBPaper00048573.ce.ms.paper	WBPaper00048573	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	NeuCode Labeling in Nematodes: Proteomic and Phosphoproteomic Impact of Ascaroside Treatment in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048573.ce.ms.paper
295	WBPaper00048910.ce.ms.paper	WBPaper00048910	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	Conserved mRNA-binding proteomes in eukaryotic organisms.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00048910.ce.ms.paper
296	WBPaper00050091.ce.ms.paper	WBPaper00050091	Method: proteomics	Species: Caenorhabditis elegans	Whole Animal	N.A.	Polar Positioning of Phase-Separated Liquid Compartments in Cells Regulated by an mRNA Competition Mechanism.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00050091.ce.ms.paper
297	WBPaper00031443.ce.rs.paper	WBPaper00031443	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Whole-genome sequencing and variant discovery in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00031443.ce.rs.paper
298	WBPaper00032006.ce.rs.paper	WBPaper00032006	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Transcriptome analysis for Caenorhabditis elegans based on novel expressed sequence tags.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032006.ce.rs.paper
299	WBPaper00037732.ce.rs.paper	WBPaper00037732	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Scaffolding a Caenorhabditis nematode genome with RNA-seq.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037732.ce.rs.paper
300	WBPaper00037948.ce.rs.paper	WBPaper00037948	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Multimodal RNA-seq using single-strand, double-strand, and CircLigase-based capture yields a refined and extended description of the C. elegans transcriptome.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037948.ce.rs.paper
301	WBPaper00037953.ce.rs.paper	WBPaper00037953	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Integrative analysis of the Caenorhabditis elegans genome by the modENCODE project.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037953.ce.rs.paper
302	WBPaper00038226.ce.rs.paper	WBPaper00038226	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	EGO-1, a C. elegans RdRP, modulates gene expression via production of mRNA-templated short antisense RNAs.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00038226.ce.rs.paper
303	WBPaper00040379.ce.rs.paper	WBPaper00040379	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Wobble base-pairing slows in vivo translation elongation in metazoans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040379.ce.rs.paper
304	WBPaper00040959.ce.rs.paper	WBPaper00040959	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Impaired insulin/IGF1 signaling extends life span by promoting mitochondrial L-proline catabolism to induce a transient ROS signal.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00040959.ce.rs.paper
305	WBPaper00041010.ce.rs.paper	WBPaper00041010	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Nutritional control of mRNA isoform expression during developmental arrest and recovery in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041010.ce.rs.paper
306	WBPaper00041119.ce.rs.paper	WBPaper00041119	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Multiple insert size paired-end sequencing for deconvolution of complex transcriptomes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041119.ce.rs.paper
307	WBPaper00041361.ce.rs.paper	WBPaper00041361	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Contributions of mRNA abundance, ribosome loading, and post- or peri-translational effects to temporal repression of C. elegans heterochronic miRNA targets.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041361.ce.rs.paper
308	WBPaper00041549.ce.rs.paper	WBPaper00041549	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Functional transcriptomics of a migrating cell in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041549.ce.rs.paper
309	WBPaper00041689.ce.rs.paper	WBPaper00041689	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Simplification and desexualization of gene expression in self-fertile nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041689.ce.rs.paper
310	WBPaper00041697.ce.rs.paper	WBPaper00041697	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	The p38 MAPK PMK-1 shows heat-induced nuclear translocation, supports chaperone expression, and affects the heat tolerance of Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041697.ce.rs.paper
311	WBPaper00042034.ce.rs.paper	WBPaper00042034	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Bacterial nitric oxide extends the lifespan of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042034.ce.rs.paper
312	WBPaper00042179.ce.rs.paper	WBPaper00042179	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Mitochondrial hormesis links low-dose arsenite exposure to lifespan extension.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042179.ce.rs.paper
313	WBPaper00042296.ce.rs.paper	WBPaper00042296	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	DAF-16 employs the chromatin remodeller SWI/SNF to promote stress resistance and longevity.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042296.ce.rs.paper
314	WBPaper00042361.ce.rs.paper	WBPaper00042361	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Functional transcriptomic analysis of the role of MAB-5/Hox in Q neuroblast migration in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00042361.ce.rs.paper
315	WBPaper00044037.ce.rs.paper	WBPaper00044037	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Dietary restriction induced longevity is mediated by nuclear receptor NHR-62 in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044037.ce.rs.paper
316	WBPaper00044260.ce.rs.paper	WBPaper00044260	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Role of sirtuins in lifespan regulation is linked to methylation of nicotinamide.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044260.ce.rs.paper
317	WBPaper00044391.ce.rs.paper	WBPaper00044391	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Large-scale detection of in vivo transcription errors.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044391.ce.rs.paper
318	WBPaper00044426.ce.rs.paper	WBPaper00044426	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Neuronal ROS signaling rather than AMPK/sirtuin-mediated energy sensing links dietary restriction to lifespan extension.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044426.ce.rs.paper
319	WBPaper00044616.ce.rs.paper	WBPaper00044616	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Argonautes promote male fertility and provide a paternal memory of germline gene expression in C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044616.ce.rs.paper
320	WBPaper00044760.ce.rs.paper	WBPaper00044760	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Conservation of mRNA and protein expression during development of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044760.ce.rs.paper
321	WBPaper00044786.ce.rs.paper	WBPaper00044786	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Genome-wide analysis links emerin to neuromuscular junction activity in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044786.ce.rs.paper
322	WBPaper00044827.ce.rs.paper	WBPaper00044827	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	The dsRBP and inactive editor ADR-1 utilizes dsRNA binding to regulate A-to-I RNA editing across the C. elegans transcriptome.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044827.ce.rs.paper
323	WBPaper00044954.ce.rs.paper	WBPaper00044954	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Characterisation of Caenorhabditis elegans sperm transcriptome and proteome.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00044954.ce.rs.paper
324	WBPaper00045017.ce.rs.paper	WBPaper00045017	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	DRE-1/FBXO11-dependent degradation of BLMP-1/BLIMP-1 governs C. elegans developmental timing and maturation.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045017.ce.rs.paper
325	WBPaper00045316.ce.rs.paper	WBPaper00045316	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	The influences of PRG-1 on the expression of small RNAs and mRNAs.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045316.ce.rs.paper
326	WBPaper00045350.ce.rs.paper	WBPaper00045350	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	A pair of RNA-binding proteins controls networks of splicing events contributing to specialization of neural cell types.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045350.ce.rs.paper
327	WBPaper00045359.ce.rs.paper	WBPaper00045359	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Paternal RNA contributions in the Caenorhabditis elegans zygote.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045359.ce.rs.paper
328	WBPaper00045465.ce.rs.paper	WBPaper00045465	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Conserved translatome remodeling in nematode species executing a shared developmental transition.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045465.ce.rs.paper
329	WBPaper00045521.ce.rs.paper	WBPaper00045521	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	Topic: oogenesis	A new dataset of spermatogenic vs. oogenic transcriptomes in the nematode Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045521.ce.rs.paper
330	WBPaper00045618.ce.rs.paper	WBPaper00045618	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Competence for chemical reprogramming of sexual fate correlates with an intersexual molecular signature in Caenorhabditis elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045618.ce.rs.paper
331	WBPaper00045705.ce.rs.paper	WBPaper00045705	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Alternative 3' UTR selection controls PAR-5 homeostasis and cell polarity in C. elegans embryos.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045705.ce.rs.paper
332	WBPaper00045934.ce.rs.paper	WBPaper00045934	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Expression profile of Caenorhabditis elegans mutant for the Werner syndrome gene ortholog reveals the impact of vitamin C on development to increase life span.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045934.ce.rs.paper
333	WBPaper00045971.ce.rs.paper	WBPaper00045971	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	Topic: mRNA splicing via endonucleolytic cleavage and ligation involved in unfolded protein response	The RtcB RNA ligase is an essential component of the metazoan unfolded protein response.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045971.ce.rs.paper
334	WBPaper00045985.ce.rs.paper	WBPaper00045985	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Functional characterization of C. elegans Y-box-binding proteins reveals tissue-specific functions and a critical role in the formation of polysomes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045985.ce.rs.paper
335	WBPaper00046121.ce.rs.paper	WBPaper00046121	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	Spatiotemporal transcriptomics reveals the evolutionary history of the endoderm germ layer.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046121.ce.rs.paper
336	WBPaper00046511.ce.rs.paper	WBPaper00046511	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	The genome and transcriptome of the zoonotic hookworm Ancylostoma ceylanicum identify infection-specific gene families.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046511.ce.rs.paper
337	WBPaper00046805.ce.rs.paper	WBPaper00046805	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	CSR-1 and P granules suppress sperm-specific transcription in the C. elegans germline.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046805.ce.rs.paper
338	WBPaper00050230.ce.rs.paper	WBPaper00050230	Method: RNAseq	Species: Caenorhabditis elegans	Whole Animal	N.A.	Comparative genomics of Steinernema reveals deeply conserved gene regulatory networks.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00050230.ce.rs.paper
339	WBPaper00050344.ce.rs.paper	WBPaper00050344	Method: RNAseq	Species: Caenorhabditis elegans	Tissue Specific	N.A.	The tubulin repertoire of C. elegans sensory neurons and its context-dependent role in process outgrowth.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00050344.ce.rs.paper
340	WBPaper00032529.cja.rs.paper	WBPaper00032529	Method: RNAseq	Species: Caenorhabditis japonica	Tissue Specific	N.A.	Massively parallel sequencing of the polyadenylated transcriptome of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032529.cja.rs.paper
341	WBPaper00041689.cja.rs.paper	WBPaper00041689	Method: RNAseq	Species: Caenorhabditis japonica	Whole Animal	N.A.	Simplification and desexualization of gene expression in self-fertile nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041689.cja.rs.paper
342	WBPaper00032529.cre.rs.paper	WBPaper00032529	Method: RNAseq	Species: Caenorhabditis remanei	Tissue Specific	N.A.	Massively parallel sequencing of the polyadenylated transcriptome of C. elegans.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00032529.cre.rs.paper
343	WBPaper00041689.cre.rs.paper	WBPaper00041689	Method: RNAseq	Species: Caenorhabditis remanei	Whole Animal	N.A.	Simplification and desexualization of gene expression in self-fertile nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00041689.cre.rs.paper
344	WBPaper00045465.cre.rs.paper	WBPaper00045465	Method: RNAseq	Species: Caenorhabditis remanei	Whole Animal	N.A.	Conserved translatome remodeling in nematode species executing a shared developmental transition.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045465.cre.rs.paper
345	WBPaper00046092.cre.rs.paper	WBPaper00046092	Method: RNAseq	Species: Caenorhabditis remanei	Whole Animal	N.A.	Rapid evolution of phenotypic plasticity and shifting thresholds of genetic assimilation in the nematode Caenorhabditis remanei.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00046092.cre.rs.paper
346	WBPaper01000000.ovo.rs.paper	WBPaper01000000	Method: RNAseq	Species: Onchocerca volvulus	Whole Animal	N.A.	N.A.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper01000000.ovo.rs.paper
347	WBPaper00036038.ppa.rs.paper	WBPaper00036038	Method: RNAseq	Species: Pristionchus pacificus	Whole Animal	N.A.	Proteogenomics of Pristionchus pacificus reveals distinct proteome structure of nematode models.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00036038.ppa.rs.paper
348	WBPaper00045232.ppa.rs.paper	WBPaper00045232	Method: RNAseq	Species: Pristionchus pacificus	Whole Animal	N.A.	Sex-biased gene expression and evolution of the x chromosome in nematodes.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00045232.ppa.rs.paper
349	WBPaper00000001.sra.rs.paper	WBPaper00000001	Method: RNAseq	Species: Strongyloides ratti	Whole Animal	N.A.	N.A.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00000001.sra.rs.paper
350	WBPaper00037950.ce.tr.paper	WBPaper00037950	Method: tiling array	Species: Caenorhabditis elegans	Tissue Specific	N.A.	TilingArray: A spatial and temporal map of C. elegans gene expression.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037950.ce.tr.paper
351	WBPaper00037953.ce.tr.paper	WBPaper00037953	Method: tiling array	Species: Caenorhabditis elegans	Tissue Specific	N.A.	TilingArray: Integrative analysis of the Caenorhabditis elegans genome by the modENCODE project.	ftp://caltech.wormbase.org/pub/wormbase/spell_download/datasets/WBPaper00037953.ce.tr.paper
