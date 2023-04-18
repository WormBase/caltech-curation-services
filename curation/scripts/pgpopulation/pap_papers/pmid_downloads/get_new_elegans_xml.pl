#!/usr/bin/env perl

# search pubmed for ``elegans'' get list of PMIDs higher than our current list, read in xml files 
# we already got and exclude those, read in rejected pmids and exclude those, read in pmids that
# are in postgres and exclude those.  get the xml from the remaining ones and put in xml directory.
# for Kimberly and Ruihua and Arun.  2009 02 13
#
# changed from wpa to pap tables, although they aren't live yet.  2010 06 23
#
# changed cronjob from 6am to 1am since if after 4am, it must sleep after 100 downloads.  
# 2010 07 19
#
# added &populateNotfinal(); which looks at the (currently 573) pmids in pap_identifier
# with pubmed_final != 'final' and sends them in to look for updates.  Only runs this on the 19th
# of each month.  (also change pap_match.pm to not care about owner, and allow 3 different
# status instead of just MEDLINE.  2010 07 27
# 
# call  &getPubmedPage($url)  from pap_match.pm to consolidate code.  2011 05 02
#
# added removed_pmids to list of existing %pmids to ignore.  2011 05 09
#
# tacked on updating of DOIs from PMIDs using 
#   `/home/postgres/work/pgpopulation/pap_papers/20140107_doi_from_pmid/get_doi_from_pmid.pl`;
# for Kimberly.  2014 01 10
#
# 0 1 * * * /home/postgres/work/pgpopulation/wpa_papers/pmid_downloads/get_new_elegans_xml.pl
#
# Dockerized. 2023 04 17
#
# 0 1 * * * /usr/lib/scripts/pgpopulation/pap_papers/pmid_downloads/get_new_elegans_xml.pl


use strict;
use diagnostics;
use LWP::UserAgent;
use DBI;
use Jex;

# use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use lib qw(  /usr/lib/scripts/perl_modules/ );                      # for paper matching and generating 
use pap_match qw( getPubmedPage processXmlIds );

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";


# my $directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads';
my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/postgres/pgpopulation/pap_papers/pmid_downloads";
chdir ($directory) or die "Cannot chdir to $directory : $!";

my %pmids;
# my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) { $row[1] =~ s/pmid//; $pmids{$row[1]}++; }

my $highest = 19204375;							# most recent true positive 2009 02 12
# foreach (keys %pmids) { if ($_ > $highest) { $highest = $_; } }	# this won't work, stuff like 94222994 are not correct, should be 8169328
# print "highest $highest\n";						# got transfered from med94222994 to pmid94222994 erroneously

my @read_pmids = <$directory/xml/*>;					# read in download pmids
foreach (@read_pmids) { my ($pmid) = $_ =~ m/(\d+)$/; $pmids{$pmid}++; }

my $rejected_file = $directory . "/rejected_pmids";
open (IN, "<$rejected_file") or die "Cannot read $rejected_file : $!";
while (<IN>) { chomp; $pmids{$_}++; }					# account for rejected pmids
close (IN) or die "Cannot close $rejected_file : $!";

my $removed_file = $directory . "/removed_pmids";
open (IN, "<$removed_file") or die "Cannot read $removed_file : $!";
while (<IN>) { chomp; $pmids{$_}++; }					# account for removed pmids
close (IN) or die "Cannot close $removed_file : $!";


my $keyword_name = 'elegans';
my $url = "https:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/esearch\.fcgi\?db\=pubmed\&term\=$keyword_name\&retmax=100000000";
my $page = getPubmedPage($url);
my @pmid_tags = $page =~ /\<Id\>(\d+)\<\/Id\>/gi;
my @pmids;
foreach (@pmid_tags) { 
  next if ($_ < $highest);			# skip if older than a more recent one
  unless ($pmids{$_}) { push @pmids, $_; } }

# foreach my $pmid (@pmids) { print "PMID $pmid\n"; }

my $count = 0;
my $sleep = 1;					# always sleep first, since getting list above as well
foreach my $pmid (@pmids) {
  if ($sleep) { &slp(); }			# if flagged to sleep, wait
  unless ($sleep) { $sleep++; }			# first time through don't sleep
  $count++;					# count how many have downloaded so far
  my @lc = localtime;				# comply with NCBI's requirement of doing it at night
  while ( ($count > 100) && ($lc[2] > 4) && ($lc[2] < 18) ) {	# if already got 100 and between 4am and 6pm, wait 10 minutes
    sleep 600;
    $count = 0;
    @lc = localtime; }
  my $url = "https\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$pmid\&retmode\=xml";
#   print "getting $url\n";
  my $page = getPubmedPage($url);
  next if ($page =~ m/XML not found for id/);	# skip entries that don't have xml  2010 06 08
  my $outfile = $directory . "/xml/$pmid";
#   print "writing $pmid to $outfile\n";
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $page;
  close (OUT) or die "Cannot close $outfile : $!";
  
# # #   $link_text .= &processPubmedPage($page, $pmid, $two_number, $not_first_pass);	# DON'T DO THIS HERE, let Kimberly click in on form
} # foreach my $pmid (sort keys %pmids)

&populateNotfinal();


sub populateNotfinal {
  my ($date) = &getSimpleDate();
  return unless ($date =~ m/19$/);	# only run this on the 19th of the month
  my %pmids;
  my $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey IN (SELECT joinkey FROM pap_pubmed_final WHERE pap_pubmed_final != 'final');");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $row[1] =~ s/pmid//; $pmids{$row[1]}++; }
#   my @list = ();
  my $list = join"\t", keys %pmids;
  my $functional_flag = ''; my $curator_id = 'two1823';
  if ($list) {
    my ($link_text) = &processXmlIds($curator_id, $functional_flag, $list);
#     print "$link_text\n";
  }
    # when updaing pubmed not final, also get the DOIs with this script.  for Kimberly.  2014 01 10
  `/home/postgres/work/pgpopulation/pap_papers/20140107_doi_from_pmid/get_doi_from_pmid.pl`;
} # sub populateNotfinal


# call this from pap_match.pm to consolidate code
#
# sub getPubmedPage {
#     my $u = shift;
#     my $page = "";
#     my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
#     my $request = HTTP::Request->new(GET => $u); # grabs url
#     my $response = $ua->request($request);       # checks url, dies if not valid.
# #    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
#     $page = $response->content;    #splits by line
#     $page = &filterForeign($page);
#     return $page;
# } # sub getPubmedPage
# 
# sub filterForeign {		# take out foreign characters before they can get into postgres  for Cecilia  2006 05 04
#   my $change = shift;
#   if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
#     if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
#     if ($change =~ m/„/) { $change =~ s/„/"/g; }
#     if ($change =~ m/…/) { $change =~ s/…/.../g; }
#     if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
#     if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
#     if ($change =~ m/‹/) { $change =~ s/‹/</g; }
#     if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
#     if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
#     if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
#     if ($change =~ m/’/) { $change =~ s/’/'/g; }
#     if ($change =~ m/“/) { $change =~ s/“/"/g; }
#     if ($change =~ m/”/) { $change =~ s/”/"/g; }
#     if ($change =~ m/—/) { $change =~ s/—/-/g; }
#     if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
#     if ($change =~ m/š/) { $change =~ s/š/s/g; }
#     if ($change =~ m/›/) { $change =~ s/›/>/g; }
#     if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
#     if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
#     if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
#     if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
#     if ($change =~ m/«/) { $change =~ s/«/"/g; }
#     if ($change =~ m/­/) { $change =~ s/­/-/g; }
#     if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
#     if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
#     if ($change =~ m/·/) { $change =~ s/·/-/g; }
#     if ($change =~ m/»/) { $change =~ s/»/"/g; }
#     if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
#     if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
#     if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
#     if ($change =~ m/À/) { $change =~ s/À/A/g; }
#     if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
#     if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
#     if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
#     if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
#     if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
#     if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
#     if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
#     if ($change =~ m/È/) { $change =~ s/È/E/g; }
#     if ($change =~ m/É/) { $change =~ s/É/E/g; }
#     if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
#     if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
#     if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
#     if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
#     if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
#     if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
#     if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
#     if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
#     if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
#     if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
#     if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
#     if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
#     if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
#     if ($change =~ m/×/) { $change =~ s/×/x/g; }
#     if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
#     if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
#     if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
#     if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
#     if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
#     if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
#     if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
#     if ($change =~ m/à/) { $change =~ s/à/a/g; }
#     if ($change =~ m/á/) { $change =~ s/á/a/g; }
#     if ($change =~ m/â/) { $change =~ s/â/a/g; }
#     if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
#     if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
#     if ($change =~ m/å/) { $change =~ s/å/a/g; }
#     if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
#     if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
#     if ($change =~ m/è/) { $change =~ s/è/e/g; }
#     if ($change =~ m/é/) { $change =~ s/é/e/g; }
#     if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
#     if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
#     if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
#     if ($change =~ m/í/) { $change =~ s/í/i/g; }
#     if ($change =~ m/î/) { $change =~ s/î/i/g; }
#     if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
#     if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
#     if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
#     if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
#     if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
#     if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
#     if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
#     if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
#     if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
#     if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
#     if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
#     if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
#     if ($change =~ m/û/) { $change =~ s/û/u/g; }
#     if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
#     if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
#   }
#   if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; }
#   return $change;
# } # sub filterForeign

sub slp {
#     my $rand = int(rand 15) + 5;	# random 5-20 seconds
    my $rand = 5;			# just 5 seconds
#     print LOG "Sleeping for $rand seconds...\n";
    sleep $rand;
#     print LOG "done.\n";
} # sub slp


__END__

my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ 'elegans';" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)



2010 07 18

left these 2 to try later :
20550938
20553489

updated all of these :
  my @list = qw ( 19764929 19765384 19765664 19769407 19770033 19771329 19773360 19773421 19774399 19776148 19776402 19778439 19778968 19779035 19779462 19779626 19781942 19783783 19783819 19785996 19793063 19794415 19796644 19796679 19797044 19797046 19797165 19797623 19798442 19798448 19799769 19799893 19800275 19801531 19801543 19801673 19802703 19804893 19805813 19806188 19807690 19808878 19809494 19810719 19815017 19816564 19818340 19818806 19824103 19826081 19826475 19828039 19828440 19828452 19829076 19832992 19836240 19836342 19836423 19837372 19837596 19839723 19840506 19841733 19841879 19842065 19844570 19846291 19846659 19846761 19847164 19849843 19850127 19850480 19851044 19851459 19851507 19853451 19855022 19855391 19855932 19856273 19858195 19858203 19859568 19860833 19861158 19861400 19875417 19875490 19875982 19878311 19879147 19879842 19879847 19879883 19880746 19883616 19883620 19883650 19886811 19887089 19888333 19889367 19889840 19889842 19889970 19893607 19896359 19896361 19896458 19896831 19896925 19896942 19896965 19898485 19898486 19899809 19900588 19901071 19901328 19901535 19903886 19906646 19906855 19906858 19907651 19909360 19910365 19913286 19913287 19915141 19915558 19915647 19916504 19917084 19917307 19918070 19920077 19920340 19921263 19922851 19922852 19922876 19923212 19923320 19923324 19923421 19923914 19924247 19924289 19924292 19924784 19927169 19928531 19936019 19936206 19940149 19942656 19945372 19946467 19948065 19952100 19952414 19952740 19954190 19955089 19956737 19957275 19963872 19964674 19965065 19965511 19966272 19966274 19966278 19967110 20002199 20004187 20005870 20005871 20008556 20008570 20008572 20010541 20011101 20011506 20011587 20012092 20013198 20015380 20019812 20022236 20023164 20023410 20026024 20027209 20029439 20029447 20036200 20036653 20038629 20040490 20040592 20041123 20041217 20041717 20042118 20045373 20045492 20047968 20049741 20052290 20052906 20053814 20057358 20058704 20059450 20059771 20059959 20059995 20062054 20062519 20062796 20066250 20067578 20069382 20070610 20074054 20075016 20077185 20079644 20080172 20080700 20081028 20081192 20081220 20081368 20081824 20087441 20088888 20090166 20090912 20090917 20091141 20091272 20096306 20096582 20099897 20100350 20100800 20103786 20105303 20106816 20107519 20107598 20109220 20109657 20110331 20110332 20110612 20110777 20111596 20111601 20116245 20116306 20122407 20122916 20123895 20123904 20126385 20126679 20126682 20129106 20129939 20130186 20131599 20133524 20133583 20133686 20133860 20133945 20135027 20137949 20137951 20138173 20139188 20140027 20141168 20142496 20144767 20144993 20146810 20146825 20147044 20147045 20147168 20147373 20147885 20148972 20149226 20149821 20149852 20150279 20150540 20153198 20154121 20154140 20156452 20157538 20157560 20157589 20159158 20162234 20163716 20164922 20167133 20173856 20174564 20176573 20176933 20178641 20178781 20180830 20181741 20182512 20183532 20188074 20188671 20188721 20188723 20193124 20193738 20194457 20194475 20200231 20203049 20203177 20203659 20205586 20206647 20207731 20207739 20208402 20211011 20215646 20220099 20220101 20220131 20223220 20223759 20223951 20226563 20226672 20227363 20230813 20230814 20231383 20231450 20237193 20297738 20298221 20298434 20300655 20305638 20332814 20332815 20335356 20335358 20335372 20336132 20336409 20339898 20346274 20346720 20346755 20346955 20350301 20350530 20351174 20354064 20354150 20359305 20361867 20361874 20364145 20364149 20368426 20368449 20371247 20380830 20383014 20385102 20385555 20388732 20388734 20390127 20392036 20392744 20392746 20392961 20395364 20398248 20400959 20409821 20409822 20412057 20413530 20415851 20418868 20420710 20421425 20421990 20423335 20427513 20429368 20430011 20430749 20431118 20431119 20431121 20434985 20434987 20436454 20436474 20436480 20441590 20448153 20453865 20454681 20460307 20469639 20497576 20498281 20499679 20501595 20506834 20510931 20512140 20520707 20530210 20530551 20534671);
