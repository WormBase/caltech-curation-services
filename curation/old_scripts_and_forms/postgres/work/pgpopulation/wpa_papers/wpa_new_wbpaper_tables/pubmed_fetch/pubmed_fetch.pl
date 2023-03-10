#!/usr/bin/perl -w

# Purpose: Read in PubMed identifiers. Generate url link to XML 
#          abstract page on PubMed website, download page and extract the PubMed 
#          citation info for each paper. Split citation info by type and output 
#          to corresponding directory. Download online text if available.
# Author:  Eimear Kenny and Hans-Michael Muller
# Date:    April 2005 / June 2005

if (@ARGV < 1) { die "

USAGE: $0 <file with current pmids | update>



SAMPLE INPUT:  $0 elegans.pmid 	(list of pmids)
            :  $0 elegans.pmid  (update current pmids missing volume or pages)
\n
";}
##############################################################################

use strict;
use File::Basename;
use HTTP::Request;
use LWP::UserAgent;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %pmids = ();

my $pmidlist = $ARGV[0]; # Pubmed identifiers

if ($pmidlist eq 'update') {
  print "UPDATE\n";
  &getWpaPmid();
} else {
  my @aux = getpmidlist($pmidlist);
  foreach my $id (@aux) { $pmids{$id}++ ; }
}


sub getWpaPmid {
  my %papers;
  my $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      if ($row[3] eq 'valid') { $papers{join}{$row[0]} = $row[1]; }
      else { $papers{join}{$row[0]} = ''; } } }
  $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
  while (my @row = $result->fetchrow) {
    if ($papers{join}{$row[0]}) {
      my $joinkey = $row[0]; my $pmid = $row[1]; $pmid =~ s/pmid//g;
      my $result2 = $conn->exec( "SELECT * FROM wpa_volume WHERE joinkey = '$joinkey';" );
      my @row2 = $result2->fetchrow;
      unless ($row2[1]) { $pmids{$pmid}++; }
      $result2 = $conn->exec( "SELECT * FROM wpa_pages WHERE joinkey = '$joinkey';" );
      @row2 = $result2->fetchrow;
      unless ($row2[1]) { $pmids{$pmid}++; }
    }
  }
} # sub getWpaPmid


my $date = &getSimpleSecDate();
my $pgfile = 'pgfile.pg.' . $date;
open (PG, ">$pgfile") or die "Cannot create $pgfile : $!";
my $outfile = 'outfile.' . $date;
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $sleep = 0;
foreach my $pmid (sort keys %pmids) {
  if ($sleep) { &slp(); }		# if flagged to sleep, wait
  unless ($sleep) { $sleep++; }		# first time through don't sleep
    # comply with NCBI's requirement of doing it at night
#     my @lc = localtime;
#     while ($lc[2] < 18) {
# 	sleep 600;
# 	@lc = localtime;
#     }
  my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$pmid\&retmode\=xml";
  my $page = getwebpage($url);
  &dumppubmedinfo($page, $pmid);
} # foreach my $pmid (sort keys %pmids)

close (OUT) or die "Cannot close $outfile : $!";
close (PG) or die "Cannot close $pgfile : $!";

exit(0);

###SUBROUTINES

sub getpmidlist {
  my $fn = shift;
  my @ret = ();
  open (IN, "<$fn");
  while (my $line = <IN>) {
    chomp($line);
    push @ret, $line; }
  close (IN);
  return @ret;
} # sub getpmidlist


sub dumppubmedinfo {
  my $page = shift;
  my $pmid = shift;

  $page =~ s/\n//g;
  return if $page =~ /\<Error\>.+?\<\/Error\>/i;
  
  print OUT "PMID : $pmid ";

  my $joinkey = '';
  my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier = 'pmid$pmid';" );
  my @row = $result->fetchrow;  if ($row[0]) { $joinkey = $row[0]; } 
  if ($joinkey) { print OUT "matches WBPaper$joinkey\n"; }
    else { print OUT "does not match in wpa_identifier\n"; }

  my ($title) = $page =~ /\<ArticleTitle\>(.+?)\<\/ArticleTitle\>/i;   
  if ($title) { &checkPg($joinkey, 'title', 'wpa_title', $title); }

  my ($journal) = $page =~ /<MedlineTA>(.+?)\<\/MedlineTA\>/i;
  if ($journal) { &checkPg($joinkey, 'journal', 'wpa_journal', $journal); }
  
  my ($volume) = $page =~ /\<Volume\>(.+?)\<\/Volume\>/i;   
  if ($volume) { &checkPg($joinkey, 'volume', 'wpa_volume', $volume); }
  
  my ($pagenum) = $page =~ /\<MedlinePgn\>(.+?)\<\/MedlinePgn\>/i;   
  if ($pagenum) { &checkPg($joinkey, 'pages', 'wpa_pages', $pagenum); }
  
  my ($PubDate) = $page =~ /\<PubDate\>(.+?)\<\/PubDate\>/i;
  my ($pubyear) = $PubDate =~ /\<Year\>(.+?)\<\/Year\>/i;
  if ($pubyear) { &checkPg($joinkey, 'year', 'wpa_year', $pubyear); }

  my ($type) = $page =~ /\<PublicationType\>(.+?)\<\/PublicationType\>/i;
  if ($type) { &checkPg($joinkey, 'type', 'wpa_type', $type); }
  
  my ($abstract) = $page =~ /\<AbstractText\>(.+?)\<\/AbstractText\>/i;
  if ($abstract) { &checkPg($joinkey, 'abstract', 'wpa_abstract', $abstract); }
  
  my @authors = $page =~ /\<Author.*?\>(.+?)\<\/Author\>/ig;
  my $authors = "";
  foreach (@authors){
      my ($lastname, $initials) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>.+\<Initials\>(.+?)\<\/Initials\>/i;
      $authors .= $lastname . " " . $initials . "\n"; }
  if ($authors) { &checkPg($joinkey, 'author', 'wpa_author', $authors); }
  
  print OUT "\n";
} # sub dumppubmedinfo

sub checkPg {
  my ($joinkey, $type, $pgtable, $pm_value) = @_;
  my $result = $conn->exec( "SELECT * FROM $pgtable WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp DESC;" );
  my @row = $result->fetchrow;
  if ($row[0]) {
      if ($row[3] eq 'valid') { 
          print OUT "$type value -= $row[1] =- already in, ignoring -= $pm_value =-.\n"; }
        else { &addPg($joinkey, $pgtable, $pm_value); } }
    else { &addPg($joinkey, $pgtable, $pm_value); }
} # sub checkPg

sub addPg {
  my ($joinkey, $pgtable, $pm_value) = @_;
  my $pg_command = '';
  if ($pgtable eq 'wpa_author') {
    my (@authors) = split/\n/, $pm_value;
    my $result = $conn->exec( "SELECT wpa_order FROM wpa_author WHERE joinkey = '$joinkey' ORDER BY wpa_order DESC; " );
    my @row = $result->fetchrow; my $author_rank = $row[0];	# get highest author_rank
#       $result = $conn->exec( "SELECT last_value FROM wpa_author_index_author_id_seq;");	# wbpaper_editor.cgi doesn't use sequence, we don't either
    $result = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");
    @row = $result->fetchrow; my $auth_joinkey = $row[0];	# get highest author_id
    foreach my $author (@authors) {
      $auth_joinkey++; $author_rank++;
      my $result = $conn->exec( "SELECT author_id FROM wpa_author_index ORDER BY author_id DESC;");
      $result = $conn->exec( "INSERT INTO wpa_author_index VALUES ($auth_joinkey, '$author', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);");
      print PG "INSERT INTO wpa_author_index VALUES ($auth_joinkey, '$author', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);\n";
      $result = $conn->exec( "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', 'two1823', CURRENT_TIMESTAMP);");
      print PG "INSERT INTO wpa_author VALUES ('$joinkey', '$auth_joinkey', $author_rank, 'valid', 'two1823', CURRENT_TIMESTAMP);\n";

      print OUT "add author $joinkey $pgtable $auth_joinkey $author\n"; } } 
  else {
    if ( ($pgtable eq 'wpa_year') || ($pgtable eq 'wpa_title') || ($pgtable eq 'wpa_journal') ) { 1; }
    elsif ($pgtable eq 'wpa_volume') { 
      if ($pm_value =~ m/\-/) { $pm_value =~ s/\-+/\/\//g; } if ($pm_value =~ m/\s+/) { $pm_value =~ s/\s+/\/\//g; } }
    elsif ($pgtable eq 'wpa_pages') {
      if ($pm_value =~ m/^(\d+)[\s\-]+(\d+)/) { 
        my $first = $1; my $second = $2;
        if ($second < $first) {
          my @second = split//, $second ; my $count = scalar( @second );
          my @first = split//, $first; for (1 .. $count) { pop @first; }
          my $full_second = join"", @first; $second = $full_second . $second; }
        $pm_value = $first . '//' . $second; } }
    elsif ($pgtable eq 'wpa_abstract') {
      if ($pm_value =~ m/\n/) { $pm_value =~ s/\n/ /g; }
      if ($pm_value =~ m/\s+$/) { $pm_value =~ s/\s+$//; }
      if ($pm_value =~ m/\s+/) { $pm_value =~ s/\s+/ /g; }
      if ($pm_value =~ m/\\/) { $pm_value =~ s/\\//g; }             # get rid of all backslashes
      if ($pm_value =~ m/^\"\s*(.*?)\s*\"$/) { $pm_value = $1; }    # get rid of surrounding doublequotes
      if ($pm_value =~ m/\'/) { $pm_value =~ s/\'/''/g; } }
    elsif ($pgtable eq 'wpa_type') {
      if ($pm_value eq 'Comment') { $pm_value = '10'; }			# comment
      elsif ($pm_value eq 'Editorial') { $pm_value = '13'; }		# editorial
      elsif ($pm_value eq 'Journal Article') { $pm_value = '1'; }	# article
      elsif ($pm_value eq 'Newspaper Article') { $pm_value = '1'; }	# article
      elsif ($pm_value eq 'Letter') { $pm_value = '11'; }		# letter
      elsif ($pm_value eq 'News') { $pm_value = '6'; }			# news
      elsif ($pm_value eq 'Published Erratum') { $pm_value = '15'; }	# erratum
      elsif ($pm_value =~ m/Review/) { $pm_value = '2'; }		# review
      else { $pm_value = '17'; } }					# other
    else { 1; }
    $pg_command = "INSERT INTO $pgtable VALUES ('$joinkey', '$pm_value', NULL, 'valid', 'two1823', CURRENT_TIMESTAMP);"; 
    my $result = $conn->exec( $pg_command );
    print PG "$pg_command\n"; 
    print OUT "add $joinkey $pgtable $pm_value\n";
  }
} # sub addPg

sub getwebpage {
    my $u = shift;
    my $page = "";
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
#    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    
    $page = $response->content;    #splits by line
#     &slp();					# sleep in foreach loop instead
    return $page;
} # sub getwebpage

sub slp {
#     my $rand = int(rand 15) + 5;	# random 5-20 seconds
    my $rand = 5;			# just 5 seconds
    print OUT "Sleeping for $rand seconds...\n";
    sleep $rand;
    print OUT "done.\n";
} # sub slp


__END__

# SELECT * FROM wpa_author_index_author_id_seq;
# SELECT setval('wpa_author_index_author_id_seq', 74426);

pg_deleting :	# CHANGE DATE IF USING THIS !
# DELETE FROM wpa_title WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_journal WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_volume WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_pages WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_year WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_type WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_abstract WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_author WHERE wpa_timestamp > '2005-08-03 16:20:00';
# DELETE FROM wpa_author_index WHERE wpa_timestamp > '2005-08-03 16:20:00';
