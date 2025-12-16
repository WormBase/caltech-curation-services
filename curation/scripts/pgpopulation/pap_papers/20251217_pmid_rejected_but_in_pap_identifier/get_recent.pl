#!/usr/bin/env perl

# find PMIDs that are in the rejected list from manual paper rejection by kimberly, but are also valid PMID in pap_identifier
# 2025 12 16

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %db;
my %rejected;
my %removed;
my %abcfp;
my %any;
$result = $dbh->prepare( "SELECT joinkey, pap_identifier FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { $row[1] =~ s/pmid//g; $db{$row[1]} = $row[0]; 
# print qq($row[1]\t$row[0]\n);
} }

my $rejected_file = 'rejected_pmids';
open (IN, "<$rejected_file") or die "Cannot open $rejected_file : $!";
while (my $line = <IN>) {
  chomp($line);
# print qq(LINE $line LINE\n);
  if ($db{$line}) { print qq(Rejected $line is $db{$line}\n); }
}
close (IN) or die "Cannot close $rejected_file : $!";

my $removed_file = 'removed_pmids';
open (IN, "<$removed_file") or die "Cannot open $removed_file : $!";
while (my $line = <IN>) {
  chomp($line);
# print qq(LINE $line LINE\n);
  if ($db{$line}) {
    $removed{$line}++;
    $any{$line}++;
#     print qq(Removed $line is $db{$line}\n);
  }
}
close (IN) or die "Cannot close $removed_file : $!";

my $wbfp_file = 'WB_false_positive_pmids.txt';
open (IN, "<$wbfp_file") or die "Cannot open $wbfp_file : $!";
while (my $line = <IN>) {
  chomp($line);
# print qq(LINE $line LINE\n);
  if ($db{$line}) {
    $abcfp{$line}++;
    $any{$line}++;
#     print qq(WB FP $line is $db{$line}\n);
  }
}
close (IN) or die "Cannot close $wbfp_file : $!";

foreach my $pmid (sort {$a<=>$b} keys %any) {
  print qq($pmid\t$db{$pmid}\tR $removed{$pmid}\tA $abcfp{$pmid}\n);
}


__END__

how to set directory to output files at curator / web-accessible
  my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";

how to set base url for a form
  my $baseUrl = $ENV{THIS_HOST_AS_BASE_URL} . "pub/cgi-bin/forms";

how to import modules in dockerized system
  use lib qw(  /usr/lib/scripts/perl_modules/ );                  # for general ace dumping functions
  use ace_dumper;

how to queue a bunch of insertions
  my @pgcommands;
  push @pgcommands, qq(INSERT INTO obo_name_hgnc VALUES $name_commands;);
  foreach my $pgcommand (@pgcommands) {
    print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#     $dbh->do($pgcommand);
  } # foreach my $pgcommand (@pgcommands)


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

