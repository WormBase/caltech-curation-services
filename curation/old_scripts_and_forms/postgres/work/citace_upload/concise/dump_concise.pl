#!/usr/bin/perl -w

# dump .ace file for concise description based on con_ tables.  2011 07 27
#
# arrange data by tag so it dumps in tag order for Kimberly.
# lastupdate is a datetype, not timestamp, so parse into that format when 
# reading it.  2011 08 31
#
# added OMIM dump for Database tag.  2011 09 26
#
# fixed OMIM data not having OMIM: in front.  2011 11 29
#
# added doublequotes around Accession_evidence.  2011 12 02
#
# removed con_genereg table for Kimberly and Ranjana  2013 03 05
#
# skip automated tag if there's a concise tag, for Ranjana  2015 01 01
#
# no longer skip automated tag if there's a concise tag, for Ranjana  2018 02 27

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my %data;

# my @tables = qw( wbgene desctype desctext paper accession lastupdate nodump person exprtext rnai genereg microarray );
my @tables = qw( wbgene desctype desctext paper accession lastupdate nodump inferredauto person exprtext rnai microarray );
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM con_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    if ($table eq 'lastupdate') { if ($row[1]) { if ($row[1] =~ m/^(\d{4}\-\d{2}\-\d{2})/) { $row[1] = $1; } } }
    $data{$table}{$row[0]} = $row[1]; }
} # foreach my $table (@tables)

my $result = $dbh->prepare( "SELECT * FROM con_curator_hst" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[1]) { $data{curator}{$row[0]}{$row[1]}++; } }

# my @evi_types = qw( paper person accession exprtext rnai genereg microarray lastupdate );
my @evi_types = qw( paper inferredauto person accession exprtext rnai microarray lastupdate );
my %eviToTag;
$eviToTag{paper}        = 'Paper_evidence';
$eviToTag{person}       = 'Person_evidence';
$eviToTag{inferredauto} = 'Inferred_automatically';
$eviToTag{accession}    = 'Accession_evidence';
$eviToTag{exprtext}     = 'Expr_pattern_evidence';
$eviToTag{rnai}         = 'RNAi_evidence';
# $eviToTag{genereg}      = 'Gene_regulation_evidence';
$eviToTag{microarray}   = 'Microarray_results_evidence';
$eviToTag{lastupdate}   = 'Date_last_updated';
$eviToTag{curator}      = 'Curator_confirmed';

my %gin;
$result = $dbh->prepare( "SELECT * FROM gin_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gin{exists}{$row[1]}++; }
$result = $dbh->prepare( "SELECT * FROM gin_dead" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $gin{dead}{"WBGene$row[0]"}++; }
my %error_filter;

my %ace;
foreach my $joinkey (sort keys %{ $data{wbgene} }) {
  next if ($data{nodump}{$joinkey});			# skip no dump
  my $wbgene  = $data{wbgene}{$joinkey};
  unless ($gin{exists}{$wbgene}) { $error_filter{"// $wbgene does not exist in nameserver / gin_ tables\n"}++; next; }
  if ($gin{dead}{$wbgene}) { $error_filter{"// $wbgene is dead\n"}++; next; }
  next unless ($data{desctype}{$joinkey});		# skip without type
  next unless ($data{desctext}{$joinkey});		# skip without text
  my $text    = $data{desctext}{$joinkey};
  if ($text =~ m/\n/) { $text =~ s/\n/ /g; }		# replace newlines with spaces
  my $tag     = $data{desctype}{$joinkey};
  my %evi;
  foreach my $evi_table (@evi_types) {
    next unless ($data{$evi_table}{$joinkey});
    my @data = ();
    if ($evi_table eq 'inferredauto') { push @data, $data{$evi_table}{$joinkey}; }
      else { (@data) = split/,/, $data{$evi_table}{$joinkey}; }
    foreach my $data (@data) {
      if ($data =~ m/^\"/) { $data =~ s/^\"//; }
      if ($data =~ m/\"$/) { $data =~ s/\"$//; }
      if ($data =~ m/^\s+/) { $data =~ s/^\s+//; }
      if ($data =~ m/\s+$/) { $data =~ s/\s+$//; }
      if ($data =~ m/\n/) { $data =~ s/\n/ /g; }
      if ($data) { $evi{$evi_table}{$data}++; }
    } # foreach my $data (@data)
  } # foreach my $evi_table (@evi_types)
  foreach my $curator (sort keys %{ $data{curator}{$joinkey} }) { $evi{curator}{$curator}++; }

  if ( ($tag eq 'Concise_description') || ($tag eq 'Provisional_description') ) { $ace{$wbgene}{$tag}{"$tag\t\"$text\""}++; } # only for those two tags make lines without evidences
  next if ($tag eq 'Provisional_description');		# only tag, no evidence;
  if ($tag eq 'Concise_description') { $tag = 'Provisional_description'; }	# Concise data have evidence under Provisional_description
  foreach my $eviType (sort keys %evi) {
    my $subtag = $eviToTag{$eviType};
    foreach my $evi (sort keys %{ $evi{$eviType} }) {
      if ($subtag eq 'Accession_evidence') { $evi =~ s/:/" "/g; }		# for interpro and ensembl
      if ($evi =~ m/OMIM:(\d+)/) { $ace{$wbgene}{$tag}{"Database\t\"OMIM\"\t\"Accession_number\"\t\"OMIM:$1\""}++; }
      $ace{$wbgene}{$tag}{"$tag\t\"$text\"\t$subtag\t\"$evi\""}++;
    } # foreach my $evi (sort keys %{ $evi{$eviType} })
  } # foreach my $eviType (sort keys %evi)
} # foreach my $joinkey (sort { $data{wbgene}{$a} <=> $data{wbgene}{$b} } keys %{ $data{wbgene} })

foreach my $errorline (sort keys %error_filter) { print $errorline; }
print "\n";

my @tags_to_print = qw( Concise_description Automated_description Human_disease_relevance Provisional_description Sequence_features Functional_pathway Functional_physical_interaction Biological_process Molecular_function Expression Other_description );
foreach my $wbgene (sort keys %ace) {
  print "Gene : \"$wbgene\"\n";
  foreach my $tag (@tags_to_print) {
    if ($ace{$wbgene}{$tag}) {
#       next if ( ($tag eq 'Automated_description') && ($ace{$wbgene}{'Concise_description'}) );	# skip Automated if Concise exists.  for Ranjana 2015 01 01	# don't want this anymore.  2018 02 27
      foreach my $line (sort keys %{ $ace{$wbgene}{$tag} }) { print "$line\n"; } } }
  print "\n";
} # foreach my $wbgene (sort keys %ace)


# size of bigtext
# # wbgene00000001 has provisional stuff that was overwritten, erase NULL in parsing
# # nodump 
# # get no_curator curator into OA
# # put no_curator curators into person_evidence
# # lastupdate for non-concise/humandisease based on latest timestamp from desctext in car_ tables

# # constraints
# # wbgene, curator, desctype, desctext, lastupdate


# try to group by wbgene
# skip no dump rows
# concise      to Concise_description       without evidence
# concise      to Provisional_description   with    evidence
# provisional  to Provisional_description   without evidence
# humandisease to Human_disease_relevance   with    evidence
# others too   to whatever                  with    evidence


__END__


my $result = $dbh->prepare( "SELECT * FROM two_comment WHERE two_comment ~ ?" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

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

