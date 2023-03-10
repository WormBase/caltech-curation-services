#!/usr/bin/perl

# gene-go curation status


use strict;
use CGI;
use Jex;		# printHeader printFooter getHtmlVar getDate getSimpleDate mailer
use LWP::UserAgent;	# getting sanger files for querying
use LWP::Simple;	# get the PhenOnt.obo from a cgi
use DBI;
use Tie::IxHash;

use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::File;

my %curator;

my $query = new CGI;	# new CGI form
my $result;
my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my %curators;                           # $curators{two}{two#} = std_name ; $curators{std}{std_name} = two#


sub printHtmlHeader {
  print <<"EndOfText";
Content-type: text/html\n\n

<HTML>
<HEAD>
<LINK rel="stylesheet" type="text/css" href="http://minerva.caltech.edu/~azurebrd/stylesheets/wormbase.css">
<title>Gene - GO Curation Status</title>
  <script type="text/javascript" src="js/jquery-1.9.1.min.js"></script>
  <script type="text/javascript" src="js/jquery.tablesorter.min.js"></script>
  <script type="text/javascript">\$(document).ready(function() { \$("#bpsortabletable").tablesorter(); \$("#mfsortabletable").tablesorter(); \$("#ccsortabletable").tablesorter(); } );</script>
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
</body></html>

EndOfText
} # sub printHtmlHeader

my %gpi;
my %gpad;
my %gin;

my @aspects = qw( BP MF CC );
# my @aspects = qw( BP );

# &printHeader('Community Curation Tracker');
&process();

sub process {
  my ($var, $action) = &getHtmlVar($query, 'action');
  unless ($action) { $action = ''; }
  if ($action eq '') { &frontPage(); }		
    else { 						# Form Button
#     if ($action eq 'Mass Email Tracker') { 1; }
#       else { 
#         &printHtmlHeader();
#         print qq(ACTION : $action : ACTION <a href="gene_go_curation_status.cgi">start over</a><br/>\n); 
#       }
# 
      if ($action eq 'Show Data') {                        &mainPage();               }
#       elsif ($action eq 'Concise Description Ready') {   &readyToGo('con');         }	
#       elsif ($action eq 'Concise Description Tracker') { &tracker('con');           }	
#       elsif ($action eq 'generate email') {              &generateEmail();          }
#       elsif ($action eq 'skip paper') {                  &skipPaper();              }
#       elsif ($action eq 'send email') {                  &sendEmail();              }
#       elsif ($action eq 'ajaxUpdate') {                  &ajaxUpdate();             }
#       elsif ($action eq 'Mass Email') {                  &massEmail();              }
# #       elsif ($action eq 'Send Mass Emails') {            &sendMassEmails();         }
#       elsif ($action eq 'Generate Mass Email File') {    &generateMassEmailFile();  }
#       elsif ($action eq 'Mass Email Tracker') {          &massEmailTracker();       }
# #       elsif ($action eq 'Mass Email Tracker') {          &massEmailTracker('html'); }
# #       elsif ($action eq 'Mass Email Tracker Text') {     &massEmailTracker('text'); }
# #     print "ACTION : $action : ACTION<BR>\n"; 
  } # else # if ($action eq '') { &printHtmlForm(); }
#   if ($action eq 'Mass Email Tracker') { 1; }
#     else { &printHtmlFooter(); }
} # sub process

sub mainPage {
  &printHtmlHeader();
#   my $date = &getPgDate; my ($thisyear) = $date =~ m/^(\d{4})/;
#   print qq(<FORM METHOD="POST" ACTION="gene_go_curation_status.cgi">\n);
  my ($var, $curator_id)          = &getHtmlVar($query, 'curator_id');
  unless ($curator_id) { print "ERROR NO CURATOR<br />\n"; return; }
  &updateCurator($curator_id);

  &populateGpad();
  &populateGpi();
#   my $before = time;
  &populateGin();
#   my $after = time;
#   my $diff = $after - $before;
#   print qq($diff seconds in gin postgres queries<br>);
  my $count = 0;
  foreach my $aspect (@aspects) {
    my $tableId = lc($aspect) . 'sortabletable';
    print qq(Genes in GPI with UniprotKB lacking $aspect :<br/>\n);
    print qq(<table id="$tableId" style="border-style: none;" border="1">\n);
    print qq(<thead><tr><th>wbgene</th><th>locus</th><th>sequence</th><th>paper count</th><th>papers</th></tr></thead><tbody>\n); 
    foreach my $wbgene (sort keys %gpi) {
      next if ($gpad{$wbgene}{$aspect});
      my @papers = sort keys %{ $gin{$wbgene}{paper} };
      my $countPapers = scalar @papers;
      my @paperLinks;
      foreach my $paper (@papers) { 
        my $joinkey = $paper; $joinkey =~ s/WBPaper//;
        my $link = qq(<a href="paper_editor.cgi?curator_id=$curator_id&action=Search&data_number=$joinkey" target="_blank">$paper</a>);
        push @paperLinks, $link;
      }
      my $papers = join", ", @paperLinks;
#       my $papers = join", ", @papers;
# UNDO
#      $papers = '';
#       $count++; next if ($count > 50);
      print qq(<tr><td><a href="http://www.wormbase.org/species/c_elegans/gene/$wbgene" target="_blank">$wbgene</a></td><td>$gin{$wbgene}{locus}</td><td>$gin{$wbgene}{sequence}</td><td>$countPapers</td><td>$papers</td></tr>\n);
    }
#     print qq(<tr><td>1234</td><td>abc-1</td><td>CE92348</td><td><a href="linkPaper1234">8</a></td></tr>\n);
#     print qq(<tr><td>8234</td><td>let-1</td><td>CE92348</td><td><a href="linkPaper8234">10</a></td></tr>\n);
#     print qq(<tr><td>3234</td><td>zyc-1</td><td>CE92348</td><td><a href="linkPaper3234">3</a></td></tr>\n);
#     print qq(<tr><td>2234</td><td>pie-1</td><td>CE92348</td><td><a href="linkPaper2234">5</a></td></tr>\n);
    print "</TABLE><br/><br/>\n";
  }
} # sub mainPage

sub populateGin {
  my @joinkeys;
#   my $before = time;
  foreach my $wbgene (sort keys %gpi) { 
    my $queryIt = 0;
    foreach my $aspect (@aspects) {
      unless ($gpad{$wbgene}{$aspect}) { $queryIt++; } }
    if ($queryIt) {
      $wbgene =~ s/WBGene//; push @joinkeys, $wbgene;
    }
  }
#   my $after = time;
#   my $diff = $after - $before;
#   print qq($diff seconds in gpi postgres queries<br>);
  my $joinkeys = join"', '", @joinkeys;
#   print qq($joinkeys<br>\n);
#   my $before = time;
  $result = $dbh->prepare( "SELECT joinkey, gin_locus FROM gin_locus WHERE joinkey IN ('$joinkeys')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my $wbgene = 'WBGene' . $row[0];
    $gin{$wbgene}{'locus'} = $row[1]; } }
#   my $after = time;
#   my $diff = $after - $before;
#   print qq($diff seconds in locus postgres queries<br>);
#   my $before = time;
  $result = $dbh->prepare( "SELECT joinkey, gin_sequence FROM gin_sequence WHERE joinkey IN ('$joinkeys')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my $wbgene = 'WBGene' . $row[0];
    $gin{$wbgene}{'sequence'} = $row[1]; } }
#   my $after = time;
#   my $diff = $after - $before;
#   print qq($diff seconds in sequence postgres queries<br>);
#   my $before = time;
#   $result = $dbh->prepare( "SELECT joinkey, pap_gene FROM pap_gene WHERE pap_gene IN ('$joinkeys')" );
  $result = $dbh->prepare( "SELECT joinkey, pap_gene FROM pap_gene" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my $wbpaper = 'WBPaper' . $row[0];
    my $wbgene  = 'WBGene' . $row[1];
    $gin{$wbgene}{paper}{$wbpaper}++; } }
#   my $after = time;
#   my $diff = $after - $before;
#   print qq($diff seconds in paper postgres queries<br>);
}

sub populateGpad {
  my %aspect;
  $aspect{'involved_in'}                 = 'BP';
  $aspect{'acts_upstream_of'}            = 'BP';
  $aspect{'acts_upstream_of_or_within'}  = 'BP';
  $aspect{'enables'}                     = 'MF';
  $aspect{'contributes_to'}              = 'MF';
  $aspect{'part_of'}                     = 'CC';
  $aspect{'colocalizes_with'}            = 'CC';
  my $url = 'http://snapshot.geneontology.org/annotations/wb.gpad.gz';
  my $zipfile = 'data/wb.gpad.gz';
  getstore($url, $zipfile);
  my $file = 'data/wb.gpad';
  gunzip $zipfile => $file or die "gunzip failed: $GunzipError\n";
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $line = <IN>) {
    my ($junk, $wbgene, $relation, @stuff) = split/\t/, $line;
    if ($aspect{$relation}) { $gpad{$wbgene}{$aspect{$relation}}++; }
#     print qq(LINE $line<br>\n);
  }
  close (IN) or die "Cannot close $file : $!";
#   my $data = get $url;
#   my @lines = split/\n/, $file;
#   foreach my $line (@lines) {
#     print qq(LINE $line<br>\n);
#   } # foreach my $line (@lines)
} # sub populateGpad

sub populateGpi {
  my $url = 'ftp://ftp.wormbase.org/pub/wormbase/species/c_elegans/PRJNA13758/annotation/gene_product_info/c_elegans.PRJNA13758.current_development.gene_product_info.gpi.gz';
  my $zipfile = 'data/c_elegans.PRJNA13758.current_development.gene_product_info.gpi.gz';
  getstore($url, $zipfile);
  my $file = 'data/c_elegans.PRJNA13758.current_development.gene_product_info.gpi';
  gunzip $zipfile => $file or die "gunzip failed: $GunzipError\n";
  open (IN, "<$file") or die "Cannot open $file : $!";
#   my $count = 0;
  while (my $line = <IN>) {
    my @line = split/\t/, $line;
    my $col2 = $line[1];
    my $col9 = $line[8];
    if ($col9 =~ m/^UniProtKB:/) { 
      if ($col2 =~ m/^WBGene/) { 
        $gpi{$col2}++; } }
#     print qq(LINE $line<br>\n);
#     $count++; last if ($count > 10);
  }
  close (IN) or die "Cannot close $file : $!";
} # sub populateGpi

sub frontPage {		# show main menu page
  &printHtmlHeader();
  my $date = &getPgDate; my ($thisyear) = $date =~ m/^(\d{4})/;
  print qq(<form method="post" action="gene_go_curation_status.cgi"\n>);
  print "<table border=0 cellspacing=5>\n";

#   my @curator_list = qw( two42118 two1270 two1843 );	# Marie-Claire and Jane Mendel, removed 2020 03 20

  my @curator_list = qw( two1843 );
#   my @curator_list = ('', 'Juancarlos Chan', 'Wen Chen', 'Jae Cho', 'Paul Davis', 'Ruihua Fang', 'Jolene S. Fernandes', 'Chris', 'Marie-Claire Harrison', 'Kevin Howe',  'Ranjana Kishore', 'Raymond Lee', 'Cecilia Nakamura', 'Michael Paulini', 'Gary C. Schindelman', 'Erich Schwarz', 'Paul Sternberg', 'Mary Ann Tuli', 'Kimberly Van Auken', 'Qinghua Wang', 'Xiaodong Wang', 'Karen Yook', 'Margaret Duesbury', 'Tuco', 'Anthony Rogers', 'Theresa Stiernagle', 'Gary Williams' );
  my $select_size = scalar @curator_list + 1;
  print "<tr><td colspan=\"2\">Select your Name : <select name=\"curator_id\" size=\"$select_size\">\n";
  print "<option value=\"\"></option>\n";

  &populateCurators();
  my $ip = $query->remote_host();                               # select curator by IP if IP has already been used
  my $curator_by_ip = '';
  my $result = $dbh->prepare( "SELECT * FROM two_curator_ip WHERE two_curator_ip = '$ip';" ); $result->execute; my @row = $result->fetchrow;
  if ($row[0]) { $curator_by_ip = $row[0]; }

  foreach my $joinkey (@curator_list) {                         # display curators in alphabetical (array) order, if IP matches existing ip record, select it
    my $curator = 0;
    if ($curators{two}{$joinkey}) { $curator = $curators{two}{$joinkey}; }
    if ($joinkey eq $curator_by_ip) { print "<option value=\"$joinkey\" selected=\"selected\">$curator</option>\n"; }
      else { print "<option value=\"$joinkey\" >$curator</option>\n"; } }
  print "</select></td>";
  print "<td><input type=submit name=action value=\"Show Data\"></td>\n";
  print "</tr>";
  print "</table>\n";
  print "</form>\n";
} # sub frontPage

sub populateCurators {
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

