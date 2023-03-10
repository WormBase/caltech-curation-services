#!/usr/bin/perl -w

# populate transgene report from Mary Ann for Karen.  2013 12 04
#
# J summary :  
# wherever ' + ' convert to '; ' when extracting the genotype from the description.  (Karen changed her mind, don't do that)
# The genotype is whatever is in square brackets after the transgene name (optional space between them) in the Description field.  If there is no match, pretend there is no genotype, but there is a strain and transgene. Genotype goes to trp_summary, anything that was in summary goes to trp_synonym aggregating with what was there before and separating with ' | '.  The summary is only the genotype.  Add only if it's different. 
# Start with transgene name, map to WBTransgene ID from trp_name/trp_publicname.  If no transgene match, add trp_name (generate if it didn't exist) trp_publicname trp_strain and trp_summary.  (no longer trp_cgcremark, she changed her mind about that).  If there is a transgene match only add/change whatever is new/different.
# For now do this for all genotypes, but in future runs only do it if the genotype is different from the trp_summary.  Look at existing trp_gene and trp_drivenbygene (look up correct table names), and compare all gin_locus, gin_synonyms, gin_seqname .  output on 3 columns which ones matched somewhere in the genotype, which had no match, and whether there was no match at all.
# No diff, always run on everything, only do stuff when it's new.
# New entries use MaryAnn as curator.  We don't need to tag updates to existing entries.
# Strain -> trp_strain (pipe)
# Transgene -> map to trp_publicname to see if exists, create new one into trp_publicname if new.
# Description -> get Genotype -> trp_summary  (all previous trp_summary aggregate into trp_synonym)
#
# Documented with Karen.  
# Creates new pgids off of the OA from the hostname that the scripts runs.  Then updates postgres through DBI for the updates.
# Generates multiple out.<file> output files.  2013 12 09
#
# trp_driven_by_gene and trp_gene don't exist anymore.  2017 05 09


use strict;
use diagnostics;
use DBI;
use Net::Domain qw(hostname hostfqdn hostdomain);	# just hostname
use Encode qw( from_to is_utf8 );
use LWP::Simple;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $subdomain = hostname();
my $domain = 'caltech.edu';
my $path = '~postgres/cgi-bin/oa/ontology_annotator.cgi';
my $baseUrl = 'http://' . $subdomain . '.' . $domain . '/' . $path;	# where the OA is for creating new Rows

my $curator = 'two2970';				# mary ann

my $no_genotype_file = 'cgc_transgene_errors';
my $error_file       = 'errors';
my $strains_file     = 'out.strains';
my $summary_file     = 'out.summary';
my $pg_file          = 'out.pg';
open (PG,  ">$pg_file")          or die "Cannot create $pg_file : $!";
open (CGC, ">$no_genotype_file") or die "Cannot create $no_genotype_file : $!";
open (ERR, ">$error_file")       or die "Cannot create $error_file : $!";
open (STR, ">$strains_file")     or die "Cannot create $strains_file : $!";
open (SUM, ">$summary_file")     or die "Cannot create $summary_file : $!";

my %transgeneIgnore;
$transgeneIgnore{"qIs51"}++;
$transgeneIgnore{"qIs48"}++;
$transgeneIgnore{"mIs14"}++;
$transgeneIgnore{"qIs50"}++;

my %cgc;
my $infile = 'transgene_report.txt';
$/ = "";
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $entry = <IN>) {
  chomp $entry;
  my (@lines) = split/\n/, $entry;
  my ($transgene, $strain, $description, $genotype) = ('', '', '', '');
  foreach my $line (@lines) {
    my ($tag, $data) = $line =~ m/^(.*?) : ?(.*)$/;
    if ($tag eq 'Transgene')   { $transgene   = $data; }
    if ($tag eq 'Strain')      { $strain      = $data; }
    if ($tag eq 'Description') { $description = $data;
      if ($description =~ m/$transgene ?(?:contains )?(\[.*?\])/) { $genotype = $1; }
        elsif ($description =~ m/$transgene ?(?:is )?(\[.*?\])/) { $genotype = $1; } }
  } # foreach my $line (@lines)
  next if ($transgeneIgnore{$transgene});
  unless ($genotype) { print CGC "No genotype :\n$entry\n\n"; }
  if ($strain)   { $cgc{$transgene}{strains}{$strain}++;     }
  if ($genotype) { $cgc{$transgene}{genotypes}{$genotype}++; }
} # while (my $entry = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

close (CGC) or die "Cannot close $no_genotype_file : $!";

my %trp;
# my @pgtables = qw( synonym driven_by_gene gene publicname name strain summary );
my @pgtables = qw( synonym publicname name strain summary );
foreach my $table (@pgtables) {
  $result = $dbh->prepare( "SELECT * FROM trp_$table WHERE joinkey NOT IN (SELECT joinkey FROM trp_objpap_falsepos WHERE trp_objpap_falsepos IS NOT NULL)" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $trp{$table}{dtp}{$row[1]}{$row[0]}++;
    $trp{$table}{ptd}{$row[0]} = $row[1]; } } }

my %gin;
my @gintables = qw( locus synonyms seqname );
foreach my $table (@gintables) {
  $result = $dbh->prepare( "SELECT * FROM gin_$table" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $gin{$row[0]}{$row[1]}++; } }

my $summary_new = ''; my $summary_update = '';
# my $count = 0;
foreach my $transgene (sort keys %cgc) {
#   $count++; last if ($count > 399);
  my (@pgids) = sort {$a<=>$b} keys %{ $trp{publicname}{dtp}{$transgene} };		# sort ascending numerically
  my $pgid = ''; my $isNew = ' ';
  if (scalar @pgids > 1) { print ERR "$transgene has multiple pgids @pgids\n"; }
  if (scalar @pgids > 0) { $pgid = shift @pgids; }					# if there are multiple pgids just grab the lowest
  my $pgstrains = ''; my $pgsummary = ''; my $pgsynonyms = '';
  if ($pgid) {
    $pgstrains  = $trp{"strain"}{ptd}{$pgid};  unless ($pgstrains)  { $pgstrains  = ''; }	# split on |
    $pgsummary  = $trp{"summary"}{ptd}{$pgid}; unless ($pgsummary)  { $pgsummary  = ''; }	# this can only have 1 value, no pipe split
    $pgsynonyms = $trp{"synonym"}{ptd}{$pgid}; unless ($pgsynonyms) { $pgsynonyms = ''; }	# split on |
  } else {
    $isNew = 'NEW'; my @created_pgids;
    my $url = $baseUrl . '?action=newRow&newRowAmount=1&datatype=trp&curator_two=' . $curator;
    my $pageNewLine = get $url;
    if ($pageNewLine =~ m/OK\t DIVIDER \t([\d,]+)/) { print "Created pgids $1\n"; (@created_pgids) = split/,/, $1; }
      else { print "Did not get pgid(s) from $url\n"; die; }
    $pgid = shift @created_pgids; 
    &updatePostgres("trp_publicname", $pgid, "$transgene");
    &updatePostgres("trp_laboratory", $pgid, '"CGC"');
  }
  my $cgcstrains = join" | ", sort keys %{ $cgc{$transgene}{strains} };
  if ($cgcstrains ne $pgstrains) {
    my @pgstrains = split/ \| /, $pgstrains;
    my %filter;
    foreach (@pgstrains) { $filter{$_}++; }
    foreach (sort keys %{ $cgc{$transgene}{strains} }) { $filter{$_}++; }
    delete $filter{''};
    my $aggregateStrains = join" | ", sort keys %filter; 
    print STR "$transgene $pgid $isNew\tPG $pgstrains\tCGC $cgcstrains\ttrp_strain NOW $aggregateStrains\n"; 
    if ($pgstrains ne $aggregateStrains) { &updatePostgres("trp_strain", $pgid, $aggregateStrains); }
  }
  my $cgcgenotypes = join" | ", sort keys %{ $cgc{$transgene}{genotypes} };
  if ($cgcgenotypes) {					# do summary / synonym / genematch only if there are cgcgenotypes
    my (@sorted_genotypes) = sort { length $b <=> length $a } keys %{ $cgc{$transgene}{genotypes} };
    my $cgcgenotype = shift @sorted_genotypes;		# take longest one for genotype, leave the rest for synonyms
    unless ($cgcgenotype) { $cgcgenotype = ''; }
    my @pgsynonyms = split/ \| /, $pgsynonyms;
    my %aggregateSynonyms;
    foreach (@sorted_genotypes) { $aggregateSynonyms{$_}++; }
    foreach (@pgsynonyms) {       $aggregateSynonyms{$_}++; }
    my %good; my %bad;
    if ($cgcgenotype ne $pgsummary) {
      my %wbgenes; my $matches = 'NO';
      if ($trp{driven_by_gene}{ptd}{$pgid}) {
        my (@wbgenes) = $trp{driven_by_gene}{ptd}{$pgid} =~ m/WBGene(\d+)/g;
        foreach (@wbgenes) { $wbgenes{$_}++; } }
      if ($trp{gene}{ptd}{$pgid}) {
        my (@wbgenes) = $trp{gene}{ptd}{$pgid} =~ m/WBGene(\d+)/g;
        foreach (@wbgenes) { $wbgenes{$_}++; } }
      foreach my $wbgene (sort keys %wbgenes) {
        foreach my $name (sort keys %{ $gin{$wbgene} }) {
          if ($cgcgenotypes =~ m/$name/) { $good{"WBGene$wbgene"}{$name}++; $matches = 'YES'; }
            else { $bad{"WBGene$wbgene"}{$name}++; } } }
      $aggregateSynonyms{$pgsummary}++;			# pgsummary about to be replaced with cgcgenotype, add it to aggregate summary
      # move $cgcgenotype into trp_summary
    } # if ($cgcgenotype ne $pgsummary)
    delete $aggregateSynonyms{''};
    my $aggregateSynonyms = join" | ", sort keys %aggregateSynonyms; 
    my $to_print = '';
    $to_print .= qq(\n$transgene $pgid $isNew\tPG $pgsummary\tPGSYN $pgsynonyms\n);
    $to_print .= qq(\t\t\t\tCGC $cgcgenotypes\n);
    $to_print .= qq(\t\t$pgid\ttrp_summary NOW $cgcgenotype\n);
    $to_print .= qq(\t\t$pgid\ttrp_synonym NOW $aggregateSynonyms\n);
    if ($pgsummary  ne $cgcgenotype) {       &updatePostgres("trp_summary", $pgid, $cgcgenotype);       }
    if ($pgsynonyms ne $aggregateSynonyms) { &updatePostgres("trp_synonym", $pgid, $aggregateSynonyms); }
    unless (scalar(keys %good)  > 0) { $good{"None"}{""}++; }
    unless (scalar(keys %bad)   > 0) {  $bad{"None"}{""}++; }
    my $good = '';
    foreach my $gene (sort keys %good) {
      my $names = join", ", sort keys %{ $good{$gene} }; 
      $to_print .= qq(\t\t$pgid\tMatched Gene: $gene $names\n); }
    foreach my $gene (sort keys %bad) {
      my $names = join", ", sort keys %{ $bad{$gene} }; 
      $to_print .= qq(\t\t$pgid\tGene Synonyms: $gene $names\n); }
    if ($isNew eq ' ') { $summary_update .= $to_print; }
      else { $summary_new .= $to_print; }
  } # if ($cgcgenotypes)
} # foreach my $transgene (sort keys %cgc)
print SUM $summary_new;
print SUM $summary_update;

close (ERR) or die "Cannot close $error_file : $!";
close (STR) or die "Cannot close $strains_file : $!";
close (SUM) or die "Cannot close $summary_file : $!";
close (PG)  or die "Cannot close $pg_file : $!";

sub updatePostgres {
  my ($table, $joinkey, $value) = @_;
  if ($value =~ m/\'/) { $value =~ s/\'/''/g; }
  if ($value =~ m/\\/) { $value =~ s/\\/\\\\/g; }
  my @pgcommands = ();
  push @pgcommands, "DELETE FROM $table WHERE joinkey = '$joinkey'"; 
  push @pgcommands, "INSERT INTO $table VALUES ('$joinkey', E'$value');";
  push @pgcommands, "INSERT INTO ${table}_hst VALUES ('$joinkey', E'$value');";
  foreach my $pgcommand (@pgcommands) {
    my $result2 = $dbh->do( $pgcommand );
    print PG "$pgcommand\n";
  } # foreach my $pgcommand (@pgcommands)
} # sub updatePostgres

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

