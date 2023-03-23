#!/usr/bin/perl 

use strict;
use diagnostics;
use LWP::Simple;
use LWP::UserAgent;		# for elsevier stuff
# use Encode qw( from_to is_utf8 );

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
$ua->agent('Mozilla/4.0');

# my $root_infile = 'Development/Development';
# my $root_infile = 'JBC/JBC';
# my $root_infile = 'Mol_Biol_Cell/Molbiolcell';
# my $root_infile = 'GenesDev/GenesDev';
# my $root_infile = 'Thecompanyofbiologists/Thecompanyofbiologists';
# my $root_infile = 'JCellBiol/JCellBiol';
# my $root_infile = 'Cell/Cell';
# my $root_infile = 'Neuron/Neuron';
# my $root_infile = 'CurrBiol/CurrBiol';
# my $root_infile = 'DevCell/DevCell';
# my $root_infile = 'MolCell/MolCell';
# my $root_infile = 'BiochemBiophysResCommun/BiochemBiophysResCommun';
# my $root_infile = 'Gene/Gene';
# my $root_infile = 'JMolBiol/JMolBiol';
# my $root_infile = 'MechDev/MechDev';
my $root_infile = 'Science/Science';

my %onlyThesePapers;
&populateOnlyThesePapers();

sub populateOnlyThesePapers {	# to restrict the script to work on only those paper IDs, enter them in the hash below.
#   $onlyThesePapers{"WBPaper00001812"}++;
} # sub populateOnlyThesePapers


$/ = undef;
my $infile = $root_infile . '.xml';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

my (@entries) = split/<PubmedArticle>/, $allfile;

my %pmid_to_wbpaper;
$/ = "";
$infile = $root_infile . '.ace';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  my ($wbp, $pmid);
  if ($para =~ m/\"(WBPaper\d{8})\"/) { $wbp = $1; }
  if ($para =~ m/\"PMID\"\s\"(\d+)\"/) { $pmid = $1; }
  $pmid_to_wbpaper{$pmid} = $wbp;
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";


my $maxToProcess = 1000;
# my $maxToProcess = 2;

my $count = 0;
foreach my $entry (@entries) {
  my ($pmid, $vol, $issue, $medpg, $doi);
  if ($entry =~ m/<PMID[^>]*?>(.*?)<\/PMID>/) { $pmid = $1; }
  if ($entry =~ m/<Volume>(.*?)<\/Volume>/) { $vol = $1; }
  if ($entry =~ m/<Issue>(.*?)<\/Issue>/) { $issue = $1; $issue =~ s/Pt //;}
  if ($entry =~ m/<MedlinePgn>(.*?)<\/MedlinePgn>/) { $medpg = $1; }
  if ($entry =~ m/<ArticleId IdType="pii">(.*?)<\/ArticleId>/) { $doi = $1; $doi =~ s/\W//g; }
  if ($medpg) { if ($medpg =~ m/\-.*/) { $medpg =~ s/\-.*$//; } }
  if ($vol && $issue && $medpg && $pmid) { 
    $count++;
    last if ($count > $maxToProcess);
    my $url_constructor = $vol . '/' . $issue . '/' . $medpg;

    if ($root_infile eq 'Cell/Cell') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'Neuron/Neuron') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'CurrBiol/CurrBiol') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'DevCell/DevCell') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'MolCell/MolCell') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'BiochemBiophysResCommun/BiochemBiophysResCommun') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'Gene/Gene') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'JMolBiol/JMolBiol') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
    if ($root_infile eq 'MechDev/MechDev') { unless ($doi) { print "ERR no doi for $entry\n"; }; $url_constructor = $doi; }	# this applies to all Elsevier journals
        
    &processPmid($pmid, $url_constructor);
  }
#     else { print "ERR V $vol I $issue M $medpg FOR ENTRY $entry\n"; }
}

sub processPmid {
  my ($pmid, $url_constructor) = @_;
  my $url = '';
  my $paper_dir = $pmid;  
  if ($pmid_to_wbpaper{$pmid}) { $paper_dir = $pmid_to_wbpaper{$pmid}; }
#   return unless ($onlyThesePapers{$paper_dir});	# To only get from a hardcoded list 2011 06 27
#   return unless ($paper_dir eq 'WBPaper00005938');	# sample that wasn't working 2011 06 27
#   return unless ($paper_dir eq 'WBPaper00025218');	# sample that wasn't working 2011 05 26
#   return unless ($paper_dir eq 'WBPaper00002785');
  print "$paper_dir\t$pmid\t$url_constructor\n";

  unless (-d $paper_dir) { `mkdir $paper_dir`; }

  &getUrlAndFigures($url_constructor, $paper_dir, $pmid);
  
  my $outfile = $paper_dir . '/' . 'url_accession.txt';
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT "$url_constructor\n";
  close (OUT) or die "Cannot close $outfile : $!";
  sleep(2);
#   print $all_figs_page;
#   print "DIVIDER\n\n\n";
} # sub processPmid

sub getUrlAndFigures {
  my ($url_constructor, $paper_dir, $pmid) = @_;
  my $url = '';
  if ($root_infile eq 'Development/Development') {
    $url = 'http://dev.biologists.org/content/' . $url_constructor . '.figures-only'; }
  elsif ($root_infile eq 'JBC/JBC') {
    $url = 'http://www.jbc.org/content/' . $url_constructor . '.long'; }
  elsif ($root_infile eq 'GenesDev/GenesDev') {
    $url = 'http://genesdev.cshlp.org/content/' . $url_constructor . '.full'; }
  elsif ($root_infile eq 'Mol_Biol_Cell/Molbiolcell') {
    $url = 'http://www.molbiolcell.org/cgi/content/full/' . $url_constructor; }
  elsif ($root_infile eq 'Thecompanyofbiologists/Thecompanyofbiologists') {
    $url = 'http://jcs.biologists.org/content/' . $url_constructor . '.long'; }
  elsif ($root_infile eq 'JCellBiol/JCellBiol') {
    $url = 'http://jcb.rupress.org/content/' . $url_constructor . '.long'; }
  elsif ($root_infile eq 'Cell/Cell') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'Neuron/Neuron') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'CurrBiol/CurrBiol') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'DevCell/DevCell') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'MolCell/MolCell') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'BiochemBiophysResCommun/BiochemBiophysResCommun') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'Gene/Gene') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'JMolBiol/JMolBiol') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'MechDev/MechDev') {
    $url = 'http://www.sciencedirect.com/science/article/pii/' . $url_constructor; }
  elsif ($root_infile eq 'Science/Science') {
    $url = 'http://www.sciencemag.org/content/' . $url_constructor . '.long'; }
  unless ($url) { print "No URL for $url_constructor $paper_dir $pmid\n"; }
#   my $all_figs_page = get $url;
  my $all_figs_page;
  my $response = $ua->get($url);
  if ($response->is_success) { $all_figs_page = $response->decoded_content; }
# print "URL $url U\n";
# if ( $all_figs_page =~ m/<div class="fig\-caption">(.*?)<\/div>/sg ) { print "MATCH\n"; }
# print "ALL $all_figs_page FIGS\n";

  if ( ($root_infile eq 'Development/Development') || ($root_infile eq 'JBC/JBC') || ($root_infile eq 'Thecompanyofbiologists/Thecompanyofbiologists') || ($root_infile eq 'JCellBiol/JCellBiol' || ($root_infile eq 'Science/Science') ) ) {
    unless ($all_figs_page) { print "This URL was not found $url\n"; }
    my (@figcaptions) = $all_figs_page =~ m/<div class=\"fig\-caption\">(.*?)<\/div>/sg;
    foreach my $figcap (@figcaptions) {
#       print "FIGCAP $figcap\n\n\n";
      my ($number, $text);
      if ($root_infile eq 'Development/Development') {
        if ($figcap =~ m/<span class="fig\-label">.*?Fig\. (\d+)\..*?<\/span>/s) { $number = $1; } }
      elsif ($root_infile eq 'JBC/JBC') {
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+)\..*?<\/span>/s) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+).*?<\/span>/is) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+)\..*?<\/span>/s) { $number = $1; }
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+).*?<\/span>/s) { $number = $1; } }
      elsif ($root_infile eq 'GenesDev/GenesDev') {
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+)\..*?<\/span>/s) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+).*?<\/span>/is) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+)\..*?<\/span>/s) { $number = $1; }
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+).*?<\/span>/s) { $number = $1; } }
      elsif ($root_infile eq 'Thecompanyofbiologists/Thecompanyofbiologists') {
        if ($figcap =~ m/<span class="fig\-label">.*?Fig\. (\d+)\..*?<\/span>/s) { $number = $1; } }
      elsif ($root_infile eq 'JCellBiol/JCellBiol') {
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+)\..*?<\/span>/s) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        if ($figcap =~ m/<span class="fig\-label">.*?FIGURE (\d+).*?<\/span>/is) { $number = $1; } # this doesn't always work, like for WBPaper00025218
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+)\..*?<\/span>/s) { $number = $1; }
        elsif ($figcap =~ m/<span class="fig\-label">.*?(\d+).*?<\/span>/s) { $number = $1; } }
      elsif ($root_infile eq 'Science/Science') {
        if ($figcap =~ m/<span class="fig\-label">.*?Fig\. (\d+)\..*?<\/span>/s) { $number = $1; } }
        
      if ($figcap =~ m/<p[^>]*?>(.*?)<\/p>/s) { $text = $1; }
      if ($text =~ m/<[^>]*>/) { $text =~ s/<[^>]*>//g; }
#       if ($text) { unless (is_utf8($text)) { from_to($text, "iso-8859-1", "utf8"); } }           # may have non utf8 stuff
#       print "$number\t$text\n";
      my $outfile = $paper_dir . '/' . 'F' . $number . '.large.txt';
      open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
      print OUT "Figure $number. ";
      $text =~ s/\n/ /g;
      $text =~ s/ +/ /g;
      print OUT $text;
      close (OUT) or die "Cannot close $outfile : $!";
      my $image_url = '';
      if ($root_infile eq 'Development/Development') {
        $image_url = 'http://dev.biologists.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      elsif ($root_infile eq 'Thecompanyofbiologists/Thecompanyofbiologists') {
        $image_url = 'http://jcs.biologists.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      elsif ($root_infile eq 'JBC/JBC') {
        $image_url = 'http://www.jbc.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      elsif ($root_infile eq 'GenesDev/GenesDev') {
        $image_url = 'http://genesdev.cshlp.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      elsif ($root_infile eq 'JCellBiol/JCellBiol') {
        $image_url = 'http://jcb.rupress.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
      elsif ($root_infile eq 'Science/Science') {
        $image_url = 'http://www.sciencemag.org/content/' . $url_constructor . '/F' . $number . '.large.jpg'; }
     print "$image_url\n";
      my $image = get $image_url;
      $outfile = $paper_dir . '/' . 'F' . $number . '.large.jpg';
      open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
      print OUT $image;
      close (OUT) or die "Cannot close $outfile : $!";
    }
  }
  elsif ($root_infile eq 'Mol_Biol_Cell/Molbiolcell') {
    my (@figcaptions) = $all_figs_page =~ m/<STRONG>View larger version<\/STRONG> \(\d+[A-Z]+\):\n?<BR>\n?<NOBR><A HREF=\"(.*?)\">/sg;
    unless ($figcaptions[0]) { print "ERROR no match to figure captions\n"; }
    foreach my $figcap (@figcaptions) {
      my $fig_link_url = 'http://www.molbiolcell.org' . $figcap;
      my $fig_link_page = get $fig_link_url;
      sleep(60);
# print "FIG $fig_link_page END FIG\n";
      my $number = 0;
      if ($fig_link_page =~ m/<STRONG>Figure (\d+).<\/STRONG>/i) { $number = $1; }
      elsif ($fig_link_page =~ m/<STRONG>Figure (\d+).*?<\/STRONG>/i) { $number = $1; }
      elsif ($fig_link_page =~ m/<STRONG><B>Figure (\d+).<\/B><\/STRONG>/i) { $number = $1; }
      else { print "ERROR No match to figure number in $fig_link_page\n"; }
      my $text = '';
        # If it's not getting the correct captions, try to switch the next two lines  2011 07 06
      if ($fig_link_page =~ m/(<STRONG>Fig.*?)<BR CLEAR=LEFT>/si) { $text = $1; }
        elsif ($fig_link_page =~ m/<BR CLEAR=left>(.*?)<P>/si) { $text = $1; }
      if ($text) {
        my $outfile = $paper_dir . '/' . 'F' . $number . '.large.html';
        open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
        print OUT "Figure $number. ";
        $text =~ s/\n/ /g;
        $text =~ s/ +/ /g;
        print OUT $text;
        close (OUT) or die "Cannot close $outfile : $!"; }
      my $image_url = '';
      if ($fig_link_page =~ m/Click on image to view larger version\.<P>\n<BR><A HREF=\"(.*?)\"><IMG/si) { $image_url = 'http://molbiolcell.org' . $1; }
        elsif ($fig_link_page =~ m/<A HREF=\"(\/content.*?)\">.View Larger Version/si) { $image_url = 'http://molbiolcell.org' . $1; }
      if ($image_url) {
#         print "DOWNLOADING $image_url IMAGE\n";
        my $image = get $image_url;
        sleep(60);
        my $outfile = $paper_dir . '/' . 'F' . $number . '.large.jpg';
        open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
        print OUT $image;
        close (OUT) or die "Cannot close $outfile : $!";
      }
    } # foreach my $figcap (@figcaptions)
  } # elsif ($root_infile eq 'Mol_Biol_Cell/Molbiolcell')
  elsif ($root_infile eq 'Cell/Cell' || $root_infile eq 'Neuron/Neuron' || $root_infile eq 'CurrBiol/CurrBiol' || $root_infile eq 'DevCell/DevCell' || $root_infile eq 'MolCell/MolCell') {
    my (@lines) = split/\n/, $all_figs_page;
# print "ALL $all_figs_page ENDALL\n";
    my %figures; my %captions;
    foreach my $line (@lines) {
      if ($line =~ m/<div id="labelCaptionfig(.*?)"><div class="nodefault">(.*?)<div><!--comment--><\/div>/i) {
        my (@pairs) = $line =~ m/<div id="labelCaptionfig(.*?)"><div class="nodefault">(.*?)<div><!--comment--><\/div>/ig;
        while (@pairs) { my $capnum = shift @pairs; my $caption = shift @pairs; $captions{$capnum}{$caption}++; } }
      if ($line =~ m/openStrippedNS\('([^']*?isHiQual=Y[^']*?)'.*?Figure.*?(S?\d+)/i) {
          my (@pairs) = $line =~ m/openStrippedNS\('([^']*?isHiQual=Y[^']*?)'.*?Figure.*?(S?\d+)/ig;
          while (@pairs) { my $jpgurl = shift @pairs; my $fignum = shift @pairs; $figures{$fignum}{$jpgurl}++; } } }
    foreach my $capnum (sort keys %captions) {
      foreach my $caption (sort keys %{ $captions{$capnum} }) {
        my $outfile = $paper_dir . '/' . 'F' . $capnum . '.html';
        open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
        print OUT "Figure $capnum. ";
        print OUT $caption;
        close (OUT) or die "Cannot close $outfile : $!";
      } # foreach my $caption (sort keys %{ $captions{$capnum} }
    } # foreach my $capnum (sort keys %captions)
# COMMENT OUT TO skip getting pictures
    foreach my $fignum (sort keys %figures) {
      foreach my $jpgurl (sort keys %{ $figures{$fignum} }) {
        print "$fignum $jpgurl\n";
        next unless ($jpgurl =~ m/isHiQual=Y/);		# comment this out if the journal doesn't have HiQual pictures
        $jpgurl =~ s/amp;//g;
        my $baseurl = 'http://www.sciencedirect.com/'; 
        my $imageholderurl = $baseurl . $jpgurl;
        my $response = $ua->get($imageholderurl);
        sleep(10);
# print "GET $imageholderurl END\n";
        if ($response->is_success) {
          my $outfile = $paper_dir . '/' . 'F' . $fignum . '.jpg';
          open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
          print OUT $response->content;
          close (OUT) or die "Cannot close $outfile : $!"; }
        print "$fignum : $jpgurl\n";
      }
    } # foreach my $fignum (sort {$a<=>$b} keys %figures)
  } # elsif ($root_infile eq 'Cell/Cell')
# WHENEVER THE JOURNAL PAGE DOES NOT HAVE HIGH QUALITY PICTURES USE THE FOLLOWING SUBROUTINE
  elsif ($root_infile eq 'BiochemBiophysResCommun/BiochemBiophysResCommun' || $root_infile eq 'Gene/Gene' || $root_infile eq 'JMolBiol/JMolBiol' || $root_infile eq 'MechDev/MechDev') {
    my (@lines) = split/\n/, $all_figs_page;
# print "ALL $all_figs_page ENDALL\n";
    my %figures; my %captions;
    foreach my $line (@lines) {
      if ($line =~ m/<div id="labelCaptionfig(.*?)"><div class="nodefault">(.*?)<div><!--comment--><\/div>/i) {
        my (@pairs) = $line =~ m/<div id="labelCaptionfig(.*?)"><div class="nodefault">(.*?)<div><!--comment--><\/div>/ig;
        while (@pairs) { my $capnum = shift @pairs; my $caption = shift @pairs; $captions{$capnum}{$caption}++; } }
      if ($line =~ m/openStrippedNS\('(.*?)','labelCaptionfig(\d+)/i) { 
        my (@pairs) = $line =~ m/openStrippedNS\('(.*?)','labelCaptionfig(\d+)/ig;
        while (@pairs) { my $jpgurl = shift @pairs; my $fignum = shift @pairs; $figures{$fignum}{$jpgurl}++; } } }
    foreach my $capnum (sort keys %captions) {
      foreach my $caption (sort keys %{ $captions{$capnum} }) {
        my $outfile = $paper_dir . '/' . 'F' . $capnum . '.html';
        open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
        print OUT "Figure $capnum. ";
        print OUT $caption;
        close (OUT) or die "Cannot close $outfile : $!";
      } # foreach my $caption (sort keys %{ $captions{$capnum} }
    } # foreach my $capnum (sort keys %captions)
# COMMENT OUT TO skip getting pictures
    foreach my $fignum (sort keys %figures) {
      foreach my $cacheLinkUrl (sort keys %{ $figures{$fignum} }) {
        print "$fignum $cacheLinkUrl\n";
        $cacheLinkUrl =~ s/amp;//g;
        my $baseurl = 'http://www.sciencedirect.com/'; 
        my $imageholderurl = $baseurl . $cacheLinkUrl;
        my $response = $ua->get($imageholderurl);
        sleep(10);
        if ($response->content =~ m/<img src=\"(http:\/\/www.sciencedirect.com\/cache\/MiamiImageURL.*?)\"\/>/) {
print "fignum $1\n";
          $response = $ua->get($1);
          sleep(10);
        }
        if ($response->is_success) {
          my $outfile = $paper_dir . '/' . 'F' . $fignum . '.jpg';
          open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
          print OUT $response->content;
          close (OUT) or die "Cannot close $outfile : $!"; }
      }
    } # foreach my $fignum (sort {$a<=>$b} keys %figures)
  } # elsif ($root_infile eq 'Cell/Cell')
} # sub getFromFiguresOnly
