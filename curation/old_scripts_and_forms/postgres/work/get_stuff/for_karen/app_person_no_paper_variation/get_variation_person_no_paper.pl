#!/usr/bin/perl -w

# query for app_ entries with person and no paper
#
# search by mapping WBVariation to variation name, searching keyword on textpresso, get xml results to get papers, see possible persons connected to those papers, and list as matches those that correspond to the person in person evidence.  2014 06 26

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $textpressoBase = 'http://textpresso-www.cacr.caltech.edu/cgi-bin/celegans/';

my %varToPerson;		# wbvar -> persons -> pgid
my $result = $dbh->prepare( "SELECT app_variation.joinkey, app_variation.app_variation, app_person.app_person FROM app_variation, app_person WHERE app_variation.joinkey = app_person.joinkey AND app_variation.joinkey NOT IN (SELECT joinkey FROM app_paper) AND app_person.app_person ~ 'WBPerson261'" );
# my $result = $dbh->prepare( "SELECT app_variation.joinkey, app_variation.app_variation, app_person.app_person FROM app_variation, app_person WHERE app_variation.joinkey = app_person.joinkey AND app_variation.joinkey NOT IN (SELECT joinkey FROM app_paper) " );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $varToPerson{$row[1]}{$row[2]}{$row[0]}++; } }

my %allVarname;
my %varToVarname;

my %allLocus;
my %varToGene;
my %varToWBGene;
my %varToLocus;

foreach my $wbvar (sort keys %varToPerson) { 
  $result = $dbh->prepare( "SELECT * FROM obo_data_variation WHERE joinkey = '$wbvar'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my %genes;
  my $persons = join", ", sort keys %{ $varToPerson{$wbvar} };
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    if ($row[1] =~ m/name: "([^"]*)"/) { 
      my $name = $1;
      next if ($name =~ m/WBVar/);
      $varToVarname{$wbvar}{$1}++;
      $allVarname{$1}++; }
    if ($row[1] =~ m/gene: "([^"]*)"/) {
      my (@genes) = $row[1] =~ m/gene: "([^"]*)"/g; 
      foreach (@genes) { $genes{$_}++; }
      foreach my $gene (@genes) { 
# if ($gene =~ m/acdh-10/) { print "$gene\t$persons\n"; }
        $varToGene{$wbvar}{$gene}++; 
        my ($wbgene, $locus) = split/ /, $gene;
        if ($locus) {
          $allLocus{$locus}++; 
          $varToLocus{$wbvar}{$locus}++; }
        if ($wbgene) {
          $varToWBGene{$wbvar}{$wbgene}++; }
      } # foreach my $gene (@genes)
    } # if ($row[1] =~ m/gene: "([^"]*)"/)
  } }
#   if (scalar keys %genes > 0) { 
#     foreach my $gene (sort keys %genes) {
#       print qq(MATCH\t$wbvar\t$gene\t$persons\n);
#     } # foreach my $gene (@genes)
#   } else {
#     print qq(FAIL\t$wbvar\tno gene\t$persons\n);
#   } 
} # foreach my $wbvar (sort keys %varToPerson) 


# search by mapping WBVariation to variation name, searching keyword on textpresso, get xml results to get papers, see possible persons connected to those papers, and list as matches those that correspond to the person in person evidence.

my %varnameToPaper;
my $count = 0;
foreach my $varname (sort keys %allVarname) {
  $count++;
#   print "$varname\n";
  my $url = $textpressoBase . 'search?searchstring=' . $varname . ';cat1=Select%20category%201%20from%20list%20above;cat2=Select%20category%202%20from%20list%20above;cat3=Select%20category%203%20from%20list%20above;cat4=Select%20category%204%20from%20list%20above;cat5=Select%20category%205%20from%20list%20above;search=Search!;exactmatch=on;searchsynonyms=on;literature=C.%20elegans;target=abstract;target=body;target=title;target=introduction;target=materials;target=results;target=discussion;target=conclusion;target=acknowledgments;target=references;sentencerange=sentence;sort=score%20%28hits%29;mode=boolean;authorfilter=;journalfilter=;yearfilter=;docidfilter=;';
  my $page = get $url;
  if ($page =~ m/href="(exportxml\?mode=[^"]*)"/) { 
    my $xmlUrl = $textpressoBase . $1;
#     print "LINK $xmlUrl LINK\n"; 
    my $xml = get $xmlUrl;
    my (@papers) = $xml =~ m/(WBPaper\d+)/g;
    foreach my $paper (@papers) {
#     print "VN $varname PAPER $paper\n";
      $varnameToPaper{$varname}{$paper}++;
    } # foreach my $paper (@papers)
  } # if ($page =~ m/href="(exportxml\?mode=[^"]*)"/) 
#   print "PAGE $page PAGE";
#   last if ($count > 9);				# to only try a small set, since textpresso query is a bit slow
} # foreach my $gene (sort keys %allLocus)

foreach my $wbvar (sort keys %varToPerson) {
  my %persons;
  foreach my $persons (sort keys %{ $varToPerson{$wbvar} }) {
    my (@persons) = $persons =~ m/(WBPerson\d+)/g;
    foreach my $wbperson (@persons) { my $two = $wbperson; $two =~ s/WBPerson/two/; $persons{$two}++; }
    my $pgids = join", ", sort keys %{ $varToPerson{$wbvar}{$persons} };
  } # foreach my $persons (sort keys %{ $varToPerson{$wbvar} })
  foreach my $varname (sort keys %{ $varToVarname{$wbvar} }) {  
    foreach my $paper (sort keys %{ $varnameToPaper{$varname} }) {
#       print "VN $varname P $paper E\n";
      my ($joinkey) = $paper =~ m/WBPaper(\d+)/;
      my $pgquery = "SELECT * FROM pap_author_possible WHERE author_id IN (SELECT pap_author FROM pap_author WHERE joinkey = '$joinkey')";
#       print "$pgquery\n";
      $result = $dbh->prepare( $pgquery );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) { if ($row[0]) {
#         print "@row\n";
        if ($persons{$row[1]}) { print "MATCH\t$wbvar\t$varname\t$paper\t$row[1]\n"; }
      } }
    } # foreach my $paper (sort keys %{ $varnameToPaper{$varname} })
  } # foreach my $varname (sort keys %{ $varToVarname{$wbvar} })
} # foreach my $wbvar (sort keys %varToPerson)


__END__

# this was to map variation to a gene / locus, and textpresso search on the locus.  the resulting papers that were verified by the same person were too many.

# my %locusToPaper;
# my $count = 0;
# foreach my $locus (sort keys %allLocus) {
#   $count++;
# #   print "$locus\n";
#   my $url = $textpressoBase . 'search?searchstring=' . $locus . ';cat1=Select%20category%201%20from%20list%20above;cat2=Select%20category%202%20from%20list%20above;cat3=Select%20category%203%20from%20list%20above;cat4=Select%20category%204%20from%20list%20above;cat5=Select%20category%205%20from%20list%20above;search=Search!;exactmatch=on;searchsynonyms=on;literature=C.%20elegans;target=abstract;target=body;target=title;target=introduction;target=materials;target=results;target=discussion;target=conclusion;target=acknowledgments;target=references;sentencerange=sentence;sort=score%20%28hits%29;mode=boolean;authorfilter=;journalfilter=;yearfilter=;docidfilter=;';
#   my $page = get $url;
#   if ($page =~ m/href="(exportxml\?mode=[^"]*)"/) { 
# #     print "LINK $1 LINK\n"; 
#     my $xmlUrl = $textpressoBase . $1;
#     my $xml = get $xmlUrl;
#     my (@papers) = $xml =~ m/(WBPaper\d+)/g;
#     foreach my $paper (@papers) {
#       $locusToPaper{$locus}{$paper}++;
#     } # foreach my $paper (@papers)
#   } # if ($page =~ m/href="(exportxml\?mode=[^"]*)"/) 
# #   print "PAGE $page PAGE";
#   last if ($count > 9);
# } # foreach my $gene (sort keys %allLocus)
#
# foreach my $wbvar (sort keys %varToPerson) {
#   my %persons;
#   foreach my $persons (sort keys %{ $varToPerson{$wbvar} }) {
#     my (@persons) = $persons =~ m/(WBPerson\d+)/g;
#     foreach my $wbperson (@persons) { my $two = $wbperson; $two =~ s/WBPerson/two/; $persons{$two}++; }
#     my $pgids = join", ", sort keys %{ $varToPerson{$wbvar}{$persons} };
#   } # foreach my $persons (sort keys %{ $varToPerson{$wbvar} })
#   foreach my $locus (sort keys %{ $varToLocus{$wbvar} }) {  
#     foreach my $paper (sort keys %{ $locusToPaper{$locus} }) {
#       my ($joinkey) = $paper =~ m/WBPaper(\d+)/;
#       my $pgquery = "SELECT * FROM pap_author_possible WHERE author_id IN (SELECT pap_author FROM pap_author WHERE joinkey = '$joinkey')";
# #       print "$pgquery\n";
#       $result = $dbh->prepare( $pgquery );
#       $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
#       while (my @row = $result->fetchrow) { if ($row[0]) {
# # print "@row\n";
#         if ($persons{$row[1]}) { print "MATCH\t$wbvar\t$locus\t$paper\t$row[1]\n"; }
#       } }
#     } # foreach my $paper (sort keys %{ $locusToPaper{$locus} })
#   } # foreach my $locus (sort keys %{ $varToLocus{$wbvar} })
# } # foreach my $wbvar (sort keys %varToPerson)



__END__

http://textpresso-www.cacr.caltech.edu/cgi-bin/celegans/search?searchstring=acr-19;cat1=Select%20category%201%20from%20list%20above;cat2=Select%20category%202%20from%20list%20above;cat3=Select%20category%203%20from%20list%20above;cat4=Select%20category%204%20from%20list%20above;cat5=Select%20category%205%20from%20list%20above;search=Search!;exactmatch=on;searchsynonyms=on;literature=C.%20elegans;target=abstract;target=body;target=title;target=introduction;target=materials;target=results;target=discussion;target=conclusion;target=acknowledgments;target=references;sentencerange=sentence;sort=score%20%28hits%29;mode=boolean;authorfilter=;journalfilter=;yearfilter=;docidfilter=;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=131.215.52.76", "", "") or die "Cannot connect to database!\n";	# for remote access

my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

$result->execute("doesn't") or die "Cannot prepare statement: $DBI::errstr\n"; 
my $var = "doesn't";
$result->execute($var) or die "Cannot prepare statement: $DBI::errstr\n"; 

my $data = 'data';
unless (is_utf8($data)) { from_to($data, "iso-8859-1", "utf8"); }

my $result = $dbh->do( "DELETE FROM friend WHERE firstname = 'bl\"ah'" );
(also do for INSERT and UPDATE if don't have a variable to interpolate with ? )

can cache prepared SELECTs with $dbh->prepare_cached( &c. );

if ($result->rows == 0) { print "No names matched.\n\n"; }	# test if no return

$result->finish;	# allow reinitializing of statement handle (done with query)
$dbh->disconnect;	# disconnect from DB

http://209.85.173.132/search?q=cache:5CFTbTlhBGMJ:www.perl.com/pub/1999/10/DBI.html+dbi+prepare+execute&cd=4&hl=en&ct=clnk&gl=us

interval stuff : 
SELECT * FROM afp_passwd WHERE joinkey NOT IN (SELECT joinkey FROM afp_lasttouched) AND joinkey NOT IN (SELECT joinkey FROM cfp_curator) AND afp_timestamp < CURRENT_TIMESTAMP - interval '21 days' AND afp_timestamp > CURRENT_TIMESTAMP - interval '28 days';

casting stuff to substring on other types :
SELECT * FROM afp_passwd WHERE CAST (afp_timestamp AS TEXT) ~ '2009-05-14';

to concatenate string to query result :
  SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid';
to get :
  SELECT DISTINCT(gop_paper_evidence) FROM gop_paper_evidence WHERE gop_paper_evidence NOT IN (SELECT 'WBPaper' || joinkey FROM pap_identifier WHERE pap_identifier ~ 'pmid') AND gop_paper_evidence != '';

