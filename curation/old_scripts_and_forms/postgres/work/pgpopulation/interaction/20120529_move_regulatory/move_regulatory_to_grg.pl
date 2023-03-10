#!/usr/bin/perl -w

# transfer int_type Regulatory data to the grg OA.  do not delete, it will be removed manually.  2012 05 29

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my @oldTables = qw( name nondirectional type geneone variationone transgeneone transgeneonegene otheronetype otherone genetwo variationtwo transgenetwo transgenetwogene othertwotype othertwo curator paper person rnai phenotype remark sentid falsepositive );

my %hash;
my %pgids;
my %tableHasData;

my %intTableToGrgTable;
$intTableToGrgTable{'int_curator'}         = 'grg_curator';
$intTableToGrgTable{'int_geneone'}         = 'grg_transregulator';
$intTableToGrgTable{'int_genetwo'}         = 'grg_transregulated';
$intTableToGrgTable{'int_variationone'}    = 'grg_allele';
$intTableToGrgTable{'int_name'}            = 'grg_intid';
$intTableToGrgTable{'int_paper'}           = 'grg_paper';
$intTableToGrgTable{'int_remark'}          = 'grg_summary';
$intTableToGrgTable{'int_sentid'}          = 'grg_sentid';
# $intTableToGrgTable{'int_phenotype'}       = will be moved manually
# $intTableToGrgTable{'int_type'}            = not needed, all are regulatory

foreach my $table (@oldTables) {
  $result = $dbh->prepare( "SELECT * FROM int_$table WHERE int_$table != '' AND int_$table IS NOT NULL AND joinkey IN (SELECT joinkey FROM int_type WHERE int_type = 'Regulatory')" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $hash{$table}{$row[0]} = $row[1]; $pgids{$row[0]}++; $tableHasData{$table}++; } } }

my $newpgid = 0;
my @highestPgidTables = qw( grg_name grg_curator );
foreach my $table (@highestPgidTables ) {
  $result = $dbh->prepare( "SELECT * FROM $table ORDER BY joinkey::INTEGER DESC;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my @row = $result->fetchrow(); if ($row[0] > $newpgid) { $newpgid = $row[0]; } }
print "PGID $newpgid\n";

my @pgcommands;
foreach my $pgid (sort keys %pgids) {
  $newpgid++;
  my $data = '';
  foreach my $table (@oldTables) {
    next if ($table eq 'type');
    next if ($table eq 'phenotype');
    if ($hash{$table}{$pgid}) { 
      my $newTable = $intTableToGrgTable{"int_$table"};
      $data = $hash{$table}{$pgid}; 
      push @pgcommands, "INSERT INTO $newTable VALUES ('$newpgid', '$data')";
      push @pgcommands, "INSERT INTO ${newTable}_hst VALUES ('$newpgid', '$data')";
    } 
  } # foreach my $table (@oldTables)
} 

foreach my $pgcommand ( @pgcommands ) {
  print "$pgcommand\n";
# UNCOMMENT TO COPY DATA
#   $dbh->do( $pgcommand );
} # foreach my $pgcommand ( @pgcommands )

# generate columns of data that has data and is regulatory
# my $header = join"\t", @oldTables;
# print "$header\n";
# foreach my $pgid (sort keys %pgids) {
#   my $data = '';
#   my @line;
#   foreach my $table (@oldTables) {
#     if ($hash{$table}{$pgid}) { $data = $hash{$table}{$pgid}; } else { $data = ''; }
#     push @line, $data;
#   } # foreach my $table (@oldTables)
#   my $line = join"\t", @line;
#   print "$line\n";
# } # foreach my $pgid (sort keys %pgids)

# show tables that have data
# foreach my $table (sort keys %tableHasData) {
#   print "$table\n";
# } # foreach my $table (sort keys %tableHasData)

# show data for a given table
# my $table = 'sentid';
# my $table = 'nondirectional';
# my $table = 'phenotype';
# foreach my $pgid (sort keys %{ $hash{$table} }) {
#   my $data = $hash{$table}{$pgid};
#   print "$table\t$pgid\t$data\n";
# } # foreach my $pgid (sort keys %{ $hash{$table} })

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

