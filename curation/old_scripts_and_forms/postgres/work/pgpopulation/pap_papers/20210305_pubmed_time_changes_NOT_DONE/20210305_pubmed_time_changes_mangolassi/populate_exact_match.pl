#!/usr/bin/perl -w

# Take json files generated from pubmed xml for Alliance ingest, and compare pg data with PMIDs to see how much it's changed.
#
# json from converting pubmed xml at alliance stored at 
# /home2/postgres/work/pgpopulation/pap_papers/20210305_pubmed_time_changes/pubmed_json/
#
# get new file like :
# scp -i /home/postgres/.ssh/id_rsa_wdev azurebrd@dev.wormbase.org:git/agr_literature_service_demo/src/xml_processing/alliance_pubmed_json.tar.gz /home2/postgres/work/pgpopulation/pap_papers/20210305_pubmed_time_changes
# pushd /home2/postgres/work/pgpopulation/pap_papers/20210305_pubmed_time_changes
# mv pubmed_json/ pubmed_json_<other_date>/
# tar zvxf alliance_pubmed_json.tar.gz
#
# For Kimberly.  2021 03 05

 

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use JSON;
# use Jex;

use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use pap_match qw( filterForeign );


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgcommands;
my @delete_tables = ('standardname', 'lastname', 'firstname', 'firstinit', 'collectivename', 'orcid', 'rank', 'affiliation');
foreach my $table (@delete_tables) {
  push @pgcommands, qq(DELETE FROM pap_author_$table;);
}


my %valid;
$result = $dbh->prepare( "SELECT joinkey FROM  pap_status WHERE pap_status = 'valid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $valid{$row[0]}++; }

my %papPmids;
$result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next unless $valid{$row[0]};
    my $pmid = $row[1];
    $pmid =~ s/pmid//;
    $papPmids{$row[0]} = $pmid;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $joinkeys = join"','", sort keys %papPmids;

my %pap_authors;
my %aids;
$result = $dbh->prepare( "SELECT * FROM pap_author WHERE joinkey IN ('$joinkeys')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[2]) {
    $pap_authors{$row[0]}{$row[2]} = $row[1];
    $aids{$row[1]}++;
  }
}

my %aidToName;
my $aids = join"','", sort keys %aids;
$result = $dbh->prepare( "SELECT * FROM pap_author_index WHERE author_id IN ('$aids')" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  $aidToName{$row[0]} = $row[1];
}

binmode STDOUT, ':utf8';

my $countFile = 'authorCountDifferent'; 
my $authDiffFile = 'authorNamesDifferent'; 
my $authExactFile = 'authorExactMatch'; 
my $authLastnameFile = 'authorLastnameMatch'; 
my $authNoMatchFile = 'authorNoMatch'; 
my $authNameManyAids = 'authorNameToManyAuthorIds'; 
my $goodFile = 'goodPaper'; 
my $missingFile = 'missingPubmed'; 


open (CNT, ">$countFile") or die "Cannot create $countFile : $!";
open (DFF, ">$authDiffFile") or die "Cannot create $authDiffFile : $!";
open (EXA, ">$authExactFile") or die "Cannot create $authExactFile : $!";
open (LAS, ">$authLastnameFile") or die "Cannot create $authLastnameFile : $!";
open (NOM, ">$authNoMatchFile") or die "Cannot create $authNoMatchFile : $!";
open (AID, ">$authNameManyAids") or die "Cannot create $authNameManyAids : $!";
open (GOO, ">$goodFile") or die "Cannot create $goodFile : $!";
open (MIS, ">$missingFile") or die "Cannot create $missingFile : $!";

my %counts;
$counts{goo} = 0;
$counts{cnt} = 0;
$counts{exa} = 0;
$counts{las} = 0;
$counts{nom} = 0;
$counts{mis} = 0;

# my $amountToProcess = 3;
my $amountToProcess = 399999999;
# my $amountToProcess = 3999;
my $count = 0;
$/ = undef;
foreach my $joinkey (sort keys %papPmids) {
  $count++;
  last if ($count > $amountToProcess);
  my $pmid = $papPmids{$joinkey};
# UNDO
#   next unless ($pmid eq '8514766');
#   next unless ($pmid eq '32626844');
  my $file = '/home2/postgres/work/pgpopulation/pap_papers/20210305_pubmed_time_changes/pubmed_json/' . $pmid . '.json';
  if (-e $file) {

     my @pgAuthorsOrig;
     my %pgauthors;
     my %pgAuthorsOrig;
     foreach my $order (sort {$a<=>$b} keys %{ $pap_authors{$joinkey} }) {
       my $aid = $pap_authors{$joinkey}{$order};
       my $name = $aidToName{$aid};
#        $pgauthors[$order-1] = $name;
       push @pgAuthorsOrig, $name;
       $pgAuthorsOrig{$name}++;
#        $pgauthors{$name}++;
#        if ($pgauthors{$name}) { 
#          print qq(WARNING author name $name exist for key $aid and $pgauthors{$name}\n); }
#        $pgauthors{$name} = $aid;
       $pgauthors{$name}{$aid}++;
     } # foreach my $order (sort {$a<=>$b} keys %pap_authors)
     my $pgAuthorsOrig = join" | ", @pgAuthorsOrig;
     my $pgCount = scalar @pgAuthorsOrig;

     open (IN, "<$file") or die "Cannot open $file : $!";
     my $json = <IN>;
     my $data = decode_json($json);
#      print qq(WBPaper$joinkey\t$pmid\tfound\n);
     my @xmlAuthorsOrig = ();
     my @exactMatchAuthors = ();
     my @lastnameMatchedAuthors = ();
     my @noMatchAuthors = ();
     foreach my $authEntry (@{ $$data{'authors'} }) {
       my ($order, $lastname, $firstinit, $firstname, $collective, $orcid, $standardname) = ('', '', '', '', '', '', '');
       if ($$authEntry{'authorRank'}) {     $order      = $$authEntry{'authorRank'}; }
       my @affiliation = (); my $affiliation = '';
       if ($$authEntry{'lastname'}) {       $lastname       = $$authEntry{'lastname'};       }
       if ($$authEntry{'firstinit'}) {      $firstinit      = $$authEntry{'firstinit'};      }
       if ($$authEntry{'firstname'}) {      $firstname      = $$authEntry{'firstname'};      }
       if ($$authEntry{'collectivename'}) { $collective     = $$authEntry{'collectivename'}; }	# 30028196
       if ($$authEntry{'name'}) {           $standardname   = $$authEntry{'name'};           }
       if ($$authEntry{'orcid'}) {          $orcid          = $$authEntry{'orcid'};          }
       if ($$authEntry{'affiliation'}) {
         for my $an_affiliation (@{ $$authEntry{'affiliation'} }) { push @affiliation, $an_affiliation; }
         $affiliation = join"\|", @affiliation; }

       if ($lastname) {
         utf8::encode($lastname) if is_utf8($lastname);	# same as     Encode::_utf8_off($lastname);
#          $lastname = &filterForeign($lastname); 
       }
       if ($firstinit) {
         utf8::encode($firstinit) if is_utf8($firstinit);	# same as     Encode::_utf8_off($firstinit);
#          $firstinit = &filterForeign($firstinit); 
       }
       if ($firstname) {
         utf8::encode($firstname) if is_utf8($firstname);	# same as     Encode::_utf8_off($firstname);
#          $firstname = &filterForeign($firstname); 
       }
       if ($collective) {
         utf8::encode($collective) if is_utf8($collective);	# same as     Encode::_utf8_off($collective);
#          $collective = &filterForeign($collective); 
       }
       utf8::encode($standardname) if is_utf8($standardname);		# same as     Encode::_utf8_off($standardname);
       my $author = $standardname;
       if ($lastname && $firstinit) {
         $author = qq($lastname $firstinit); 
         $standardname = qq($firstname $lastname); }
       elsif ($lastname) {
         $author = qq($lastname);
         $standardname = qq($lastname); }
       elsif ($collective) {
         $author = qq($collective);
         $standardname = qq($collective); }
       $author = &filterForeign($author);
#        next if ($standardname eq ' ');
       $xmlAuthorsOrig[$order-1] = &filterForeign($author);
#        $xmlAuthorsOrig[$order-1] = $standardname;
       my $exactMatched = 0;
       my $lastnameMatched = 0;
       foreach my $name (sort keys %pgauthors) {
#          print qq(checkExactMatch $name, $lastname, $firstinit, $firstname\n);
         my ($exactMatch) = &checkExactMatch($name, $lastname, $firstinit, $firstname, $collective);
         if ($exactMatch) {
           if (scalar keys %{ $pgauthors{$name} } == 1) {
             my $aid = join", ", sort keys %{ $pgauthors{$name} };
#              print qq(EXACT $name to AuthorID $aid rename to $standardname\n);
             &transferToNewTables($joinkey, $pmid, $aid, $name, $lastname, $firstinit, $firstname, $collective, $standardname, $orcid, $order, $affiliation);
             delete $pgauthors{$name};
             $exactMatched++; 
             last;
           } else {		# too many authors with the same name
             my $aids = join", ", sort keys %{ $pgauthors{$name} };
             print AID qq($joinkey $pmid\tpubmed name\t$standardname\texact matches\tauthor name\t$name\tbut has multiple AuthorIDs\t$aids\n);
           }
         }
       } # foreach my $name (sort keys %pgauthors)
       unless ($exactMatched) {
         if ($lastname) {
           foreach my $name (sort keys %pgauthors) {
             my $lcname = lc($name);
             my $lclast = lc($lastname);
             $lclast = &filterForeign($lclast);
#              print qq(LCN $lcname LCL $lclast E\n);
             if ($lcname =~ m/$lclast/) {
#                print qq(MATCHED LCN $lcname LCL $lclast E\n);
               delete $pgauthors{$name};
               $lastnameMatched++; 
               last;
             }
           } # foreach my $name (sort keys %pgauthors)
         } # if ($lastname)
       } # unless ($exactMatched)
       if ($exactMatched) { push @exactMatchAuthors, $standardname; }
         elsif ($lastnameMatched) { push @lastnameMatchedAuthors, $standardname; }
         else { push @noMatchAuthors, $standardname; }
#        print qq(WBPaper$joinkey\t$pmid\t$order\t$standardname\n);
     } # foreach my $authEntry (@{ $data{'authors'} })
     my $xmlAuthorsOrig = ''; my $jsonCount = 0;
     for my $i (0 .. $#xmlAuthorsOrig) {
       unless (defined $xmlAuthorsOrig[$i]) { $xmlAuthorsOrig[$i] = ''; }
     }
#      foreach my $aut (@xmlAuthorsOrig) {
#          unless (defined $aut) { print qq($joinkey\t$pmid\tUNDEF\n); }
#      } # foreach my $aut (@xmlAuthorsOrig)

     if ( scalar @xmlAuthorsOrig > 0) {
       foreach my $aut (@xmlAuthorsOrig) {
         unless (defined $aut) { print qq($joinkey\t$pmid\tUNDEF\n); }
       } # foreach my $aut (@xmlAuthorsOrig)
       $jsonCount = scalar @xmlAuthorsOrig;
       $xmlAuthorsOrig = join" | ", @xmlAuthorsOrig; }

# #      unless (is_utf8($authors)) { from_to($authors, "iso-8859-1", "utf8"); }
# #      from_to($authors, "iso-8859-1", "utf8");
#      utf8::encode($authors) if is_utf8($authors);	# same as     Encode::_utf8_off($authors);
#      $authors = &filterForeign($authors);

     my $exactMatchAuthors = join" | ", @exactMatchAuthors;
     my $lastnameMatchedAuthors = join" | ", @lastnameMatchedAuthors;
     my $noMatchAuthors = join" | ", @noMatchAuthors;

     my $noMatchPgAuthors = join" | ", sort keys %pgauthors;

#     if ($authors =~ m/ö/) { 
#       print qq(AUT has O $authors\n);
#       $authors =~ s/ö/o/g; }
#     if ($authors =~ m/ü/) {
#       print qq(AUT has U $authors\n);
#       $authors =~ s/ü/u/g; }
 
     my $lcxmlAuthorsOrig = lc($xmlAuthorsOrig);
     my $lcpgAuthorsOrig = lc($pgAuthorsOrig);

     if ($jsonCount != $pgCount) {
       $counts{cnt}++;
       print CNT qq(WBPaper$joinkey\t$pmid\tPGCOUNT\t$pgCount\tXMLCOUNT\t$jsonCount\n);
#        print CNT qq(WBPaper$joinkey\t$pmid\tPG\t$pgAuthorsOrig\tXML\t$xmlAuthorsOrig\n);
       print CNT qq(WBPaper$joinkey\t$pmid\tPG\toriginal\t$pgAuthorsOrig\n);
       print CNT qq(WBPaper$joinkey\t$pmid\tXML\toriginal\t$xmlAuthorsOrig\n);
       print CNT qq(WBPaper$joinkey\t$pmid\tXML\texactMatch\t$exactMatchAuthors\n);
       print CNT qq(WBPaper$joinkey\t$pmid\tXML\tlastnameMatch\t$lastnameMatchedAuthors\n);
       print CNT qq(WBPaper$joinkey\t$pmid\tXML\tnoMatchAuthors\t$noMatchAuthors\n);
       print CNT qq(WBPaper$joinkey\t$pmid\tPG\tnoMatchAuthors\t$noMatchPgAuthors\n);
       print CNT "\n"; }
     if ($lcxmlAuthorsOrig ne $lcpgAuthorsOrig) {
#        print qq(BAD WBPaper$joinkey\t$pmid\t$lcxmlAuthorsOrig\t$lcpgAuthorsOrig\n);
       if ($noMatchPgAuthors || $noMatchAuthors) {
         $counts{nom}++;
         print NOM qq(WBPaper$joinkey\t$pmid\tPG\toriginal\t$pgAuthorsOrig\n);
         print NOM qq(WBPaper$joinkey\t$pmid\tXML\toriginal\t$xmlAuthorsOrig\n);
         print NOM qq(WBPaper$joinkey\t$pmid\tXML\texactMatch\t$exactMatchAuthors\n);
         print NOM qq(WBPaper$joinkey\t$pmid\tXML\tlastnameMatch\t$lastnameMatchedAuthors\n);
         print NOM qq(WBPaper$joinkey\t$pmid\tXML\tnoMatchAuthors\t$noMatchAuthors\n);
         print NOM qq(WBPaper$joinkey\t$pmid\tPG\tnoMatchAuthors\t$noMatchPgAuthors\n);
         print NOM "\n"; }
       elsif ($lastnameMatchedAuthors) {
         $counts{las}++;
         print LAS qq(WBPaper$joinkey\t$pmid\tPG\toriginal\t$pgAuthorsOrig\n);
         print LAS qq(WBPaper$joinkey\t$pmid\tXML\toriginal\t$xmlAuthorsOrig\n);
         print LAS qq(WBPaper$joinkey\t$pmid\tXML\texactMatch\t$exactMatchAuthors\n);
         print LAS qq(WBPaper$joinkey\t$pmid\tXML\tlastnameMatch\t$lastnameMatchedAuthors\n); 
         print LAS "\n"; }
       elsif ($exactMatchAuthors) {
         $counts{exa}++;
         print EXA qq(WBPaper$joinkey\t$pmid\tPG\toriginal\t$pgAuthorsOrig\n);
         print EXA qq(WBPaper$joinkey\t$pmid\tXML\toriginal\t$xmlAuthorsOrig\n);
         print EXA qq(WBPaper$joinkey\t$pmid\tXML\texactMatch\t$exactMatchAuthors\n);
         print EXA "\n"; }
#        print DFF qq(WBPaper$joinkey\t$pmid\tPG\t$pgAuthorsOrig\tXML\t$xmlAuthorsOrig\n);
       $counts{dff}++;
       print DFF qq(WBPaper$joinkey\t$pmid\tPG\toriginal\t$pgAuthorsOrig\n);
       print DFF qq(WBPaper$joinkey\t$pmid\tXML\toriginal\t$xmlAuthorsOrig\n);
       print DFF qq(WBPaper$joinkey\t$pmid\tXML\texactMatch\t$exactMatchAuthors\n);
       print DFF qq(WBPaper$joinkey\t$pmid\tXML\tlastnameMatch\t$lastnameMatchedAuthors\n);
       print DFF qq(WBPaper$joinkey\t$pmid\tXML\tnoMatchAuthors\t$noMatchAuthors\n);
       print DFF qq(WBPaper$joinkey\t$pmid\tPG\tnoMatchAuthors\t$noMatchPgAuthors\n);
       print DFF "\n"; }
     else {
       $counts{goo}++;
       print GOO qq(WBPaper$joinkey\t$pmid\tGOOD\n); }
#      print qq(WBPaper$joinkey\t$pmid\t$authors\n);
#      print qq(WBPaper$joinkey\t$pmid\t$authors\n);
  } else {
    $counts{mis}++;
    print MIS qq(WBPaper$joinkey\t$pmid\tNo XML found\n);
  }
}

print qq(good\t$counts{goo}\n);
print qq(authorCount\t$counts{cnt}\n);
print qq(exact\t$counts{exa}\n);
print qq(lastname\t$counts{las}\n);
print qq(nomatch\t$counts{nom}\n);
print qq(missing\t$counts{mis}\n);

close (CNT) or die "Cannot close $countFile : $!";
close (DFF) or die "Cannot close $authDiffFile : $!";
close (EXA) or die "Cannot close $authExactFile : $!";
close (LAS) or die "Cannot close $authLastnameFile : $!";
close (NOM) or die "Cannot close $authNoMatchFile : $!";
close (AID) or die "Cannot close $authNameManyAids : $!";
close (GOO) or die "Cannot close $goodFile : $!";
close (MIS) or die "Cannot close $missingFile : $!";

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do($pgcommand);
} # foreach my $pgcommand (@pgcommands)

sub transferToNewTables {
  my ($joinkey, $pmid, $aid, $oldname, $lastname, $firstinit, $firstname, $collectivename, $standardname, $orcid, $rank, $affiliation) = @_;
  if ($standardname) {   &addToPg($aid, 'standardname', $standardname);     }
  if ($lastname) {       &addToPg($aid, 'lastname', $lastname);             }
  if ($firstname) {      &addToPg($aid, 'firstname', $firstname);           }
  if ($firstinit) {      &addToPg($aid, 'firstinit', $firstinit);           }
  if ($collectivename) { &addToPg($aid, 'collectivename', $collectivename); }
  if ($orcid) {          &addToPg($aid, 'orcid', $orcid);                   }
  if ($rank) {           &addToPg($aid, 'rank', $rank);                     }
  if ($affiliation) {    &addToPg($aid, 'affiliation', $affiliation);       }
#   print qq($joinkey, $pmid, $aid convert $oldname to $standardname\n);
} # sub transferToNewTables

sub addToPg {
  my ($aid, $table, $data) = @_;
#   ($data) = &filterForPg($data);
  if ($data =~ m/\'/) { $data =~ s/\'/''/g; }
  push @pgcommands, qq(INSERT INTO pap_author_$table VALUES ('$aid', E'$data', NULL, 'two1823'););
}


sub checkExactMatch {
  my ($name, $lastname, $firstinit, $firstname, $collective) = @_;
  if ($name =~ m/,/) { $name =~ s/,//g; }	# take out commas from pg name
  if ($name =~ m/\./) { $name =~ s/\.//g; }	# take out periods from pg name

  $lastname = &filterForeign($lastname); 
  $firstinit = &filterForeign($firstinit); 
  $firstname = &filterForeign($firstname); 
  $collective = &filterForeign($collective); 

  my $lcname = '';
  my $lclast = '';
  my $lcfin = '';
  my $lcfir = '';
  my $lccoll = '';
  if ($collective) { $lccoll = lc($collective); }
  if ($name) { $lcname = lc($name); }
  if ($lastname) { $lclast = lc($lastname); }
  if ($firstinit) { $lcfin = lc($firstinit); }
  if ($firstname) { $lcfir = lc($firstname); }
  if ($lastname) {
    my $lctest = $lclast . ' ' . $lcfin;
    my ($result) = &checkLcExact($lcname, $lctest);
    if ($result) { return $result; }
    $lctest = $lclast . ' ' . $lcfir;
    ($result) = &checkLcExact($lcname, $lctest);
    if ($result) { return $result; }
    $lctest = $lcfir . ' ' . $lclast;
    ($result) = &checkLcExact($lcname, $lctest);
    if ($result) { return $result; }
    $lctest = $lcfin . ' ' . $lclast;
    ($result) = &checkLcExact($lcname, $lctest);
    if ($result) { return $result; }
  } elsif ($collective) {
    ($result) = &checkLcExact($lcname, $lccoll);
    if ($result) { return $result; }
  }
  return 0;
}

sub checkLcExact {
  my ($lcname, $lctest) = @_;
#   print qq(COMPARE $lcname WITH $lctest END\n);
  if ($lcname eq $lctest) { 
#       print qq(EXACT COMPARE $lcname WITH $lctest END\n);
      return 1; }
    else { return 0; }
}
