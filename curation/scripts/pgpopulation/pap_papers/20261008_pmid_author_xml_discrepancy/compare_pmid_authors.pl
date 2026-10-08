#!/usr/bin/env perl

# compare pap_author / pap_author_index author lists against the pubmed xml files they came from.
# for every pmid in pap_identifier that has at least one xml file, parse authors the same way
# pap_match.pm does (LastName + Initials, through Jex::filterForPg), and report pmids where the
# db list doesn't match any of the xml files.  2026 10 08
#
# run inside the curation container :
# docker exec caltech-curation-services-main-curation-1 bash -c 'cd /usr/lib/scripts/pgpopulation/pap_papers/20261008_pmid_author_xml_discrepancy && ./compare_pmid_authors.pl'


# a pap_author should only exist in a single paper, make a report of how many papers have authors in a different paper, and how many authors exist in multiple papers.  also note how many of those have a PMID vs don't
# result
#  The script reads authors from the XML the same way pap_match.pm does (LastName + Initials) and compares them with the names in pap_author → pap_author_index, in order. It
#   checks every XML copy in pmid_downloads/done, pmid_downloads_before_prod_live/done and wpa_pubmed_final/xml. A PMID counts as a discrepancy only if it matches none of
#   them.
# 
#   ┌──────────────────────────────────┬────────┐
#   │                                  │ count  │
#   ├──────────────────────────────────┼────────┤
#   │ PMIDs that match                 │ 30,535 │
#   ├──────────────────────────────────┼────────┤
#   │ PMIDs with a discrepancy         │ 5,423  │
#   ├──────────────────────────────────┼────────┤
#   │ PMIDs with no XML file (skipped) │ 1,739  │
#   └──────────────────────────────────┴────────┘
# 
#   There is one row for each discrepant PMID and XML file. It shows the category, the first position where they differ (the DB name and the XML name there), the curators,
#   and the full author lists. Two flag columns help sort it: pubmed_loaded_only (every author row is from two10877, the PubMed loader) and shared_author_ids.
# 
#   ┌────────────────────────────────┬─────────────────────────┬────────────────────┐
#   │            category            │ loaded from PubMed only │ some curator edits │
#   ├────────────────────────────────┼─────────────────────────┼────────────────────┤
#   │ names differ                   │ 865                     │ 2,216              │
#   ├────────────────────────────────┼─────────────────────────┼────────────────────┤
#   │ case/punctuation/accent only   │ 1,618                   │ 375                │
#   ├────────────────────────────────┼─────────────────────────┼────────────────────┤
#   │ count differs                  │ 56                      │ 168                │
#   ├────────────────────────────────┼─────────────────────────┼────────────────────┤
#   │ order differs                  │ 17                      │ 53                 │
#   ├────────────────────────────────┼─────────────────────────┼────────────────────┤
#   │ no XML authors / no DB authors │ 11 / 0                  │ 37 / 7             │
#   └────────────────────────────────┴─────────────────────────┴────────────────────┘
# 
#   What the data shows:
#   - Most PubMed-loaded discrepancies come from later PubMed corrections. pap_match.pm only writes authors when a paper is created (Genetics papers excepted), so the XML can
#     be newer than the database. Examples: Signe White P → White PS, Ke Larsson J → Larsson JK, Lejeune F → Lejeune FX.
#   - Accent-only differences: many come from XML entities such as Garc&#xed;a. pap_match.pm stores these without decoding them, but some database entries were later fixed by
#     hand. I only grouped the accent and entity cases into their own category; their rows are still in the report.
#   - Curator-edited papers (two1841, two480, two1843 and others) mostly reflect deliberate edits or the old wpa-era data, so they're likely less important.

# result 2
# In the current pap_author table, 14 author IDs are attached to more than one paper. Each of them is in exactly two papers, and 12 papers are involved in total.
# 
#   ┌─────────────┬────────┬─────────────────────────────────────────────┐
#   │             │ papers │                 author IDs                  │
#   ├─────────────┼────────┼─────────────────────────────────────────────┤
#   │ Have a PMID │ 6      │ 6 (in every case, both papers have a PMID)  │
#   ├─────────────┼────────┼─────────────────────────────────────────────┤
#   │ No PMID     │ 6      │ 8 (in every case, neither paper has a PMID) │
#   └─────────────┴────────┴─────────────────────────────────────────────┘
# 
#   No author ID links a paper that has a PMID to one that doesn't. The 14 IDs come from three separate loads:
#   - 2005-08-03, two1823, with PMIDs: 74940 (Kirchhausen T) is on 00012862 and 00012863. 75782 (Desbordes SC) is on 00013325 and 00013333.
#   - 2006-11-07, two1823, no PMIDs: 84509–84512 are on 00028664 and 00028665. 84634–84635 are on 00028693 and 00028694. 84680–84681 are on 00028706 and 00028707.
#   - 2023-05-31, two10877, with PMIDs: 270390–270393 are on 00065401 (pmid27154433) and 00065547 (pmid33725803).
# 
#   The 2023 case is wrong data, not a harmless duplicate. Those four IDs' names in pap_author_index (Curtis C, Landis GN, Folk D, Wehr NB) match the XML for 27154433, which
#   belongs to 00065401. The XML for 33725803 lists Sasata, Reed, Loewen and Covello, so 00065547 is pointing at another paper's authors. Both papers were loaded the same
#   day, at 13:10 and 13:31. I think two runs of pap_match.pm each started from the same highest author ID, which it reads only once when it loads, but I haven't confirmed
#   that.
# 
#   h_pap_author has many more: 197 author IDs have been attached to more than one paper at some point, across 103 papers. 58 of those papers have a PMID and 45 don't. Of the
#   197 IDs, 20 are only in papers with a PMID, 14 only in papers without one, and 163 in a mix of both. Most of these no longer show up in pap_author, so they're mostly
#   past history rather than current problems. I haven't looked into why they happened.
# 
#   I haven't changed anything. Fixing 00065547 would mean creating new author IDs for its real authors.
# 
#   Files are in curation/scripts/pgpopulation/pap_papers/20261008_pmid_author_xml_discrepancy/:
#   - shared_author_ids.pap_author.20261008.tsv: 28 rows, one for each author ID and paper pair in the current table, with order, curator, timestamp, name and PMID.
#   - shared_author_ids.h_pap_author.20261008.tsv: 678 rows from the history table, with the same columns plus in_current_pap_author.


use strict;
use warnings;
use DBI;
use Jex;
use HTML::Entities;
use Unicode::Normalize;
use Encode;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";

my $base = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/postgres/pgpopulation/pap_papers';
my @xml_dirs = ( "$base/pmid_downloads/done", "$base/pmid_downloads_before_prod_live/done", "$base/wpa_pubmed_final/xml" );

my %xml_files;					# pmid without leading zeros => array of file paths
foreach my $dir (@xml_dirs) {
  opendir (my $dh, $dir) or die "Cannot open $dir : $!";
  foreach my $file (readdir $dh) {
    next unless ($file =~ m/^\d+$/);
    my $pmid = $file; $pmid =~ s/^0+//;
    push @{ $xml_files{$pmid} }, "$dir/$file"; }
  closedir ($dh); }

my %pmid_joinkey;
my $result = $dbh->prepare( "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ '^pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  my ($pmid) = $row[1] =~ m/^pmid0*(\d+)/;
  next unless $pmid;
  push @{ $pmid_joinkey{$pmid} }, $row[0]; }

my %aid_joinkeys;				# author_id => joinkeys using it, to flag ids shared by several papers
my $result_shared = $dbh->prepare( "SELECT pap_author, joinkey FROM pap_author WHERE pap_author IN (SELECT pap_author FROM pap_author GROUP BY pap_author HAVING count(DISTINCT joinkey) > 1)" );
$result_shared->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result_shared->fetchrow) { $aid_joinkeys{$row[0]}{$row[1]}++; }

my %db_authors;					# joinkey => array of [ order, author_id, name, curator ]
$result = $dbh->prepare( "SELECT pap_author.joinkey, pap_author.pap_order, pap_author.pap_author, pap_author_index.pap_author_index, pap_author.pap_curator FROM pap_author LEFT JOIN (SELECT DISTINCT ON (author_id) author_id, pap_author_index FROM pap_author_index ORDER BY author_id, pap_timestamp DESC) pap_author_index ON pap_author.pap_author = pap_author_index.author_id ORDER BY pap_author.joinkey, pap_author.pap_order" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  push @{ $db_authors{$row[0]} }, [ $row[1], $row[2], (defined $row[3] ? $row[3] : ''), $row[4] ]; }

sub xmlAuthors {				# same parsing as pap_match.pm processPubmedPage
  my $file = shift;
  open (my $fh, '<', $file) or die "Cannot open $file : $!";
  my $page = do { local $/; <$fh> };
  close ($fh);
  $page =~ s/\n//g;
  my @xml_authors = $page =~ /\<Author.*?\>(.+?)\<\/Author\>/ig;
  my @authors;
  foreach (@xml_authors) {
    my ($lastname, $initials) = $_ =~ /\<LastName\>(.+?)\<\/LastName\>.+\<Initials\>(.+?)\<\/Initials\>/i;
    $lastname = '' unless defined $lastname; $initials = '' unless defined $initials;
    my $author = $lastname . " " . $initials;
    ($author) = &filterForPg($author);
    $author =~ s/''/'/g;			# filterForPg escapes quotes for the insert, db holds the single quote
    push @authors, $author; }
  return grep { $_ ne '' } @authors; }		# changeXmlPg skips empty entries

sub norm {					# decode xml entities, strip accents, case and punctuation
  my $s = shift;
  $s = decode('UTF-8', $s, Encode::FB_DEFAULT) unless utf8::is_utf8($s);
  $s = decode_entities($s);
  $s = NFKD($s); $s =~ s/\p{Mn}//g;
  $s =~ s/\x{df}/ss/g;				# German sharp s
  $s = lc $s; $s =~ s/[^a-z0-9]//g;
  return $s; }

my %count;
my $date = &getSimpleDate();
my $outfile = "pmid_author_discrepancies.$date.tsv";
open (my $out, '>', $outfile) or die "Cannot create $outfile : $!";
print $out join("\t", qw( pmid joinkey category pubmed_loaded_only shared_author_ids db_count xml_count first_diff_position db_author_at_diff xml_author_at_diff db_curators xml_file db_authors xml_authors )) . "\n";

foreach my $pmid (sort { $a <=> $b } keys %pmid_joinkey) {
  unless ($xml_files{$pmid}) { $count{'no xml file'}++; next; }
  foreach my $joinkey (sort @{ $pmid_joinkey{$pmid} }) {
    my @db = $db_authors{$joinkey} ? @{ $db_authors{$joinkey} } : ();
    my @db_names = map { $_->[2] } @db;
    my %curators; $curators{$_->[3]}++ foreach @db;
    my $db_join = join(' | ', @db_names);

    my @compared;				# [ file, category, \@xml ]
    my $matched = 0;
    foreach my $file (@{ $xml_files{$pmid} }) {
      my @xml = &xmlAuthors($file);
      my $xml_join = join(' | ', @xml);
      if ($db_join eq $xml_join) { $matched++; last; }
      my $category;
      if (!@db) { $category = 'no db authors'; }
      elsif (!@xml) { $category = 'no xml authors'; }
      elsif (scalar @db != scalar @xml) { $category = 'count differs'; }
      elsif (join('|', map { &norm($_) } @db_names) eq join('|', map { &norm($_) } @xml)) { $category = 'case/punctuation/accent only'; }
      elsif (join('|', sort @db_names) eq join('|', sort @xml)) { $category = 'order differs'; }
      else { $category = 'names differ'; }
      push @compared, [ $file, $category, \@xml ]; }
    if ($matched) { $count{'match'}++; next; }
    my $pubmed_only = ((scalar keys %curators == 1) && $curators{'two10877'}) ? 'yes' : 'no';
    my %shared_with;
    foreach my $a (@db) { next unless $aid_joinkeys{$a->[1]};
      foreach my $jk (keys %{ $aid_joinkeys{$a->[1]} }) { $shared_with{"$a->[1]:$jk"}++ unless $jk eq $joinkey; } }
    my $shared = join(',', sort keys %shared_with);

    foreach my $c (@compared) {
      my ($file, $category, $xml_ref) = @$c;
      my @xml = @$xml_ref;
      my $max = (scalar @db_names > scalar @xml) ? scalar @db_names : scalar @xml;
      my ($pos, $db_at, $xml_at) = ('', '', '');
      for my $i (0 .. $max - 1) {
        my $d = defined $db_names[$i] ? $db_names[$i] : ''; my $x = defined $xml[$i] ? $xml[$i] : '';
        if ($d ne $x) { $pos = $i + 1; $db_at = $d; $xml_at = $x; last; } }
      (my $short_file = $file) =~ s/^\Q$base\E\///;
      print $out join("\t", $pmid, $joinkey, $category, $pubmed_only, $shared, scalar @db_names, scalar @xml, $pos, $db_at, $xml_at,
        join(',', map { "$_:$curators{$_}" } sort keys %curators), $short_file, $db_join, join(' | ', @xml)) . "\n"; }
    $count{'discrepant pmid'}++;
    $count{"category (first file): $compared[0][1]"}++;
    $count{"category (first file, pubmed_loaded_only=$pubmed_only): $compared[0][1]"}++;
    if ($shared) { $count{'pmids with author_ids shared with another paper'}++; } } }
close ($out);

foreach my $k (sort keys %count) { print "$k\t$count{$k}\n"; }
print "output in $outfile\n";
