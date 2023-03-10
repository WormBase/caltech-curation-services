#!/usr/bin/perl

# search pubmed for ``elegans'' get list of PMIDs higher than our current list, read in xml files 
# we already got and exclude those, read in rejected pmids and exclude those, read in pmids that
# are in postgres and exclude those.  get the xml from the remaining ones and put in xml directory.
#
# updated to get the 94 papers that have a pmid in identifier, but no pubmed_final status, meaning we don't have the xml.  2010 07 13


use strict;
use diagnostics;
use LWP::UserAgent;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result;

my $directory = '/home/postgres/work/pgpopulation/wpa_papers/wpa_pubmed_final';
chdir ($directory) or die "Cannot chdir to $directory : $!";

my %pmids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid' AND joinkey NOT IN (SELECT joinkey FROM pap_pubmed_final) ORDER BY joinkey;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  $row[1] =~ s/pmid//;
  $pmids{$row[1]}{$row[0]}++; }

my $count = 0;
my $sleep = 0;
foreach my $pmid (sort {$a<=>$b} keys %pmids) {
  if ($sleep) { &slp(); }			# if flagged to sleep, wait
  unless ($sleep) { $sleep++; }			# first time through don't sleep
  $count++;					# count how many have downloaded so far
  my @lc = localtime;				# comply with NCBI's requirement of doing it at night
  while ( ($count > 100) && ($lc[2] < 18) && ($lc[2] > 2) ) {	# if already got 100 and earlier than 6pm and later than 2am, wait 10 minutes
# according to http://eutils.ncbi.nlm.nih.gov/entrez/query/static/eutils_help.html#UserSystemRequirements
    sleep 600;
    $count = 0;
    @lc = localtime; }
  my $url = "http\:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/efetch\.fcgi\?db\=pubmed\&id\=$pmid\&retmode\=xml";
#   print "getting $url\n";
  my $page = getPubmedPage($url);
  my $outfile = $directory . "/94/$pmid";
#   print "writing $pmid to $outfile\n";
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  print OUT $page;
  close (OUT) or die "Cannot close $outfile : $!";
  my $set_to = 'not_final';
  if ($page =~ m/Status=\"MEDLINE\"/) { $set_to = 'final'; }

#   foreach my $joinkey (sort keys %{ $pmids{$pmid} }) {
#     $result = $dbh->do( "DELETE FROM wpa_pubmed_final WHERE wpa_pubmed_final = '$pmid' AND joinkey = '$joinkey';" );
#     $result = $dbh->do( "INSERT INTO wpa_pubmed_final VALUES ('$joinkey', '$set_to', NULL, 'valid', 'two1823');" );
#     $result = $dbh->do( "INSERT INTO wpa_pubmed_final_hst VALUES ('$joinkey', '$pmid', NULL, 'invalid', 'two1823');" );
#     $result = $dbh->do( "INSERT INTO wpa_pubmed_final_hst VALUES ('$joinkey', '$set_to', NULL, 'valid', 'two1823');" );
# #   $result = $dbh->do( "UPDATE wpa_pubmed_final SET wpa_pubmed_final = '$set_to' WHERE wpa_pubmed_final = 'pmid$pmid';" );
# #   $result = $dbh->do( "UPDATE wpa_pubmed_final_hst SET wpa_pubmed_final_hst = '$set_to' WHERE wpa_pubmed_final_hst = 'pmid$pmid';" )
#   } # foreach my $joinkey (sort keys %{ $pmids{$pmid} })

  
# # #   $link_text .= &processPubmedPage($page, $pmid, $two_number, $not_first_pass);	# DON'T DO THIS HERE, let Kimberly click in on form
} # foreach my $pmid (sort keys %pmids)

sub getPubmedPage {
    my $u = shift;
    my $page = "";
    my $ua = LWP::UserAgent->new(timeout => 30); # instantiates a new user agent
    my $request = HTTP::Request->new(GET => $u); # grabs url
    my $response = $ua->request($request);       # checks url, dies if not valid.
#    die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
    $page = $response->content;    #splits by line
    $page = &filterForeign($page);
    return $page;
} # sub getPubmedPage

sub slp {
#     my $rand = int(rand 15) + 5;	# random 5-20 seconds
#     my $rand = 5;			# just 5 seconds
    my $rand = 2;
#     print LOG "Sleeping for $rand seconds...\n";
    sleep $rand;
# 
#     print LOG "done.\n";
} # sub slp

sub filterForeign {		# take out foreign characters before they can get into postgres  for Cecilia  2006 05 04
  my $change = shift;
  if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
    if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
    if ($change =~ m/„/) { $change =~ s/„/"/g; }
    if ($change =~ m/…/) { $change =~ s/…/.../g; }
    if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
    if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
    if ($change =~ m/‹/) { $change =~ s/‹/</g; }
    if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
    if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
    if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
    if ($change =~ m/’/) { $change =~ s/’/'/g; }
    if ($change =~ m/“/) { $change =~ s/“/"/g; }
    if ($change =~ m/”/) { $change =~ s/”/"/g; }
    if ($change =~ m/—/) { $change =~ s/—/-/g; }
    if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
    if ($change =~ m/š/) { $change =~ s/š/s/g; }
    if ($change =~ m/›/) { $change =~ s/›/>/g; }
    if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
    if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
    if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
    if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
    if ($change =~ m/«/) { $change =~ s/«/"/g; }
    if ($change =~ m/­/) { $change =~ s/­/-/g; }
    if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
    if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
    if ($change =~ m/·/) { $change =~ s/·/-/g; }
    if ($change =~ m/»/) { $change =~ s/»/"/g; }
    if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
    if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
    if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
    if ($change =~ m/À/) { $change =~ s/À/A/g; }
    if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
    if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
    if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
    if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
    if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
    if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
    if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
    if ($change =~ m/È/) { $change =~ s/È/E/g; }
    if ($change =~ m/É/) { $change =~ s/É/E/g; }
    if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
    if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
    if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
    if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
    if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
    if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
    if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
    if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
    if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
    if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
    if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
    if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
    if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
    if ($change =~ m/×/) { $change =~ s/×/x/g; }
    if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
    if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
    if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
    if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
    if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
    if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
    if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
    if ($change =~ m/à/) { $change =~ s/à/a/g; }
    if ($change =~ m/á/) { $change =~ s/á/a/g; }
    if ($change =~ m/â/) { $change =~ s/â/a/g; }
    if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
    if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
    if ($change =~ m/å/) { $change =~ s/å/a/g; }
    if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
    if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
    if ($change =~ m/è/) { $change =~ s/è/e/g; }
    if ($change =~ m/é/) { $change =~ s/é/e/g; }
    if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
    if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
    if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
    if ($change =~ m/í/) { $change =~ s/í/i/g; }
    if ($change =~ m/î/) { $change =~ s/î/i/g; }
    if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
    if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
    if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
    if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
    if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
    if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
    if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
    if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
    if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
    if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
    if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
    if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
    if ($change =~ m/û/) { $change =~ s/û/u/g; }
    if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
    if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
  }
  if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; }
  return $change;
} # sub filterForeign


__END__



# THIS SECTION looks at xml we already have, and if it's final, sets those pmid values to final under wpa_pubmed_final
# my $other_directory = '/home/postgres/work/pgpopulation/wpa_papers/pmid_downloads';
# my (@xml) = <$other_directory/xml/*>;
# my (@donexml) = <$other_directory/done/*>;
# my %already_have;
# $/ = undef;
# foreach my $xml (@xml, @donexml) {
#   open (IN, $xml) or die "Cannot open $xml : $!";
#   my $filedata = <IN>;
#   close (IN) or die "Cannot close $xml : $!";
#   my ($pmid) = $xml =~ m/(\d+)$/;
#   if ($filedata =~ m/Status=\"MEDLINE\"/) { $already_have{$pmid}++; }
# }
# $/ = "\n";
# 
# foreach my $pmid_final (sort {$a<=>$b} keys %already_have) {
#   $result = $dbh->do( "UPDATE wpa_pubmed_final SET wpa_pubmed_final = 'final' WHERE wpa_pubmed_final = 'pmid$pmid_final';" );
#   $result = $dbh->do( "UPDATE wpa_pubmed_final_hst SET wpa_pubmed_final_hst = 'final' WHERE wpa_pubmed_final_hst = 'pmid$pmid_final';" );
# }
# END THIS SECTION

__END__

#   my $result = $dbh->prepare( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
#   $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 

my %pmids;
my $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
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


my $keyword_name = 'elegans';
my $url = "http:\/\/eutils\.ncbi\.nlm\.nih\.gov\/entrez\/eutils\/esearch\.fcgi\?db\=pubmed\&term\=$keyword_name\&retmax=100000000";
my $page = getPubmedPage($url);
my @pmid_tags = $page =~ /\<Id\>(\d+)\<\/Id\>/gi;
my @pmids;
foreach (@pmid_tags) { 
  next if ($_ < $highest);			# skip if older than a more recent one
  unless ($pmids{$_}) { push @pmids, $_; } }

# foreach my $pmid (@pmids) { print "PMID $pmid\n"; }

my $result = $conn->exec( "SELECT * FROM two_comment WHERE two_comment ~ 'elegans';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)


