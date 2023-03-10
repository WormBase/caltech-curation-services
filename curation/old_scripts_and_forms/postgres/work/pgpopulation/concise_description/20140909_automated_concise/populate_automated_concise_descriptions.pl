#!/usr/bin/perl -w

# populate concise description OA tables with automated values from James.  
# Ranjana will run this manually when James updates the results.  2014 09 10
#
# added con_species and now have separate source files for different species.
# 2015 01 01
#
# have to delete from new tables when removing all data (add species + inferredauto to @pgTables)
# 2015 01 05


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;


my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @pgTables = qw( wbgene curator curhistory desctype desctext paper accession lastupdate species inferredauto );

my @pgidsToDelete;

$result = $dbh->prepare( "SELECT joinkey FROM con_desctype WHERE con_desctype = 'Automated_description' ORDER BY joinkey::INTEGER;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { 
  if ($row[0]) { push @pgidsToDelete, $row[0]; } }

my $highestPgid = 0;
my @pgcommands;
my $pgidsToDelete = join"','", @pgidsToDelete;
foreach my $pgtable (@pgTables) {
  $result = $dbh->prepare( "SELECT * FROM con_$pgtable ORDER BY joinkey::INTEGER DESC" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); if ($row[0] > $highestPgid) { $highestPgid = $row[0]; }
  next if ($pgtable eq 'desctype');		# skip deleting from desctype, which we'll keep for future automated concise descriptions
  push @pgcommands, qq(DELETE FROM con_${pgtable}_hst WHERE joinkey IN ('$pgidsToDelete'));
  push @pgcommands, qq(DELETE FROM con_$pgtable WHERE joinkey IN ('$pgidsToDelete')); 
}


# my $textpressoUrl = 'http://textpresso-dev.caltech.edu/concise_descriptions/semantic_categories/concise_descriptions/OA_concise_descriptions.txt';
# my @urls = ( 'http://textpresso-dev.caltech.edu/concise_descriptions/release/WS247/c_elegans/descriptions/OA_concise_descriptions.WS247.txt', 'http://textpresso-dev.caltech.edu/concise_descriptions/release/WS247/c_briggsae/descriptions/OA_concise_descriptions.WS247.txt' );
# foreach my $textpressoUrl (@urls) { # }


my $releaseUrl = 'http://textpresso-dev.caltech.edu/concise_descriptions/production_release.txt';
my $release = get $releaseUrl;
chomp $release;

my %species;
my $speciesUrl = 'http://textpresso-dev.caltech.edu/concise_descriptions/species.txt';
my $speciesData = get $speciesUrl;
my @lines = split/\n/, $speciesData;
foreach my $line (@lines) {
  my ($subdir, $b, $species, $abbrev) = split/\t/, $line; 
  my $textpressoUrl = 'http://textpresso-dev.caltech.edu/concise_descriptions/release/' . $release . '/' . $subdir . '/descriptions/OA_concise_descriptions.' . $release . '.txt';

  my $textpressoData = get $textpressoUrl;

  my @textpressoData = split/\n/, $textpressoData;
# my $max = 4; my $count = 0;
  foreach my $line (@textpressoData) {
#   $count++; last if ($count > $max);
    my $pgid = '';
    if (scalar @pgidsToDelete) { $pgid = shift @pgidsToDelete; }
      else { 
        $highestPgid++; $pgid = $highestPgid; 
        push @pgcommands, qq(INSERT INTO con_desctype VALUES('$pgid', 'Automated_description')); }
    my ($wbg, $date, $papers, $acc, $desc, $species, $infauto) = split/\t/, $line;
    push @pgcommands, qq(INSERT INTO con_curator_hst VALUES('$pgid', 'WBPerson17622'));
    push @pgcommands, qq(INSERT INTO con_curator_hst VALUES('$pgid', 'WBPerson324'));
    push @pgcommands, qq(INSERT INTO con_curator VALUES('$pgid', 'WBPerson324'));
    push @pgcommands, qq(INSERT INTO con_curhistory VALUES('$pgid', '$pgid'));
    if ($papers) {   $papers =~ s/, /","/g; $papers = '"' . $papers . '"'; 
                     push @pgcommands, qq(INSERT INTO con_paper        VALUES('$pgid', '$papers'));  }
    if ($wbg) {      push @pgcommands, qq(INSERT INTO con_wbgene       VALUES('$pgid', '$wbg'));     }
    if ($desc) {     $desc =~ s/\'/''/g;
                     push @pgcommands, qq(INSERT INTO con_desctext     VALUES('$pgid', '$desc'));    }
    if ($acc) {      push @pgcommands, qq(INSERT INTO con_accession    VALUES('$pgid', '$acc'));     }
    if ($date) {     push @pgcommands, qq(INSERT INTO con_lastupdate   VALUES('$pgid', '$date'));    }
    if ($species) {  push @pgcommands, qq(INSERT INTO con_species      VALUES('$pgid', '$species')); }
    if ($infauto) {  $infauto =~ s/\'/''/g;
                     push @pgcommands, qq(INSERT INTO con_inferredauto VALUES('$pgid', '$infauto')); }
  } # foreach my $line (@textpressoData)
} # foreach my $line (@lines)

foreach my $pgcommand (@pgcommands) {
  print "$pgcommand\n";
# UNCOMMENT TO POPULATE
  $dbh->do( $pgcommand );
} # foreach my $pgcommand (@pgcommands)




__END__

GRANT ALL ON TABLE con_wbgene TO acedb;
GRANT ALL ON TABLE con_curator TO acedb;
GRANT ALL ON TABLE con_curhistory TO acedb;
GRANT ALL ON TABLE con_desctype TO acedb;
GRANT ALL ON TABLE con_desctext TO acedb;
GRANT ALL ON TABLE con_paper TO acedb;
GRANT ALL ON TABLE con_accession TO acedb;
GRANT ALL ON TABLE con_lastupdate TO acedb;
GRANT ALL ON TABLE con_species TO acedb;
GRANT ALL ON TABLE con_inferredauto TO acedb;

GRANT ALL ON TABLE con_wbgene_hst TO acedb;
GRANT ALL ON TABLE con_curator_hst TO acedb;
GRANT ALL ON TABLE con_curhistory_hst TO acedb;
GRANT ALL ON TABLE con_desctype_hst TO acedb;
GRANT ALL ON TABLE con_desctext_hst TO acedb;
GRANT ALL ON TABLE con_paper_hst TO acedb;
GRANT ALL ON TABLE con_accession_hst TO acedb;
GRANT ALL ON TABLE con_lastupdate_hst TO acedb;
GRANT ALL ON TABLE con_species_hst TO acedb;
GRANT ALL ON TABLE con_inferredauto_hst TO acedb;


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

