#!/usr/bin/env perl

# get mapping of possible author and person names, to match against each other by person_editor.cgi
# 2023 04 03

# 0 4 * * * /usr/lib/scripts/cronjobs/author_person_possible/get_author_person_possible.pl


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use JSON;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %aka_hash = &getAkaHash();
my $json = encode_json \%aka_hash;
my $outfile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/cronjobs/author_person_possible/two_aka_hash.json";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
print OUT $json;
close (OUT) or die "Cannot close $outfile : $!";

sub getAkaHash {
  my %filter; my %aka_hash;
  my @tables = qw (first middle last);
  foreach my $table (@tables) {
    $result = $dbh->prepare ( "SELECT * FROM two_aka_${table}name WHERE two_aka_${table}name IS NOT NULL AND two_aka_${table}name != 'NULL' AND two_aka_${table}name != '' AND joinkey IN (SELECT joinkey FROM two_status WHERE two_status = 'Valid');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      my $joinkey = $row[0];
      $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;     # take out spaces in front and back
      $row[2] =~ s/[\,\.]//g;                         # take out commas and dots
      $row[2] =~ s/_/ /g;                             # replace underscores for spaces
      $row[2] = lc($row[2]);                          # for full values (lowercase it)
      $row[0] =~ s/two//g;                            # take out the 'two' from the joinkey
      $filter{$row[0]}{$table}{$row[2]}++;
      unless ($table eq 'last') {                     # look at initials for first and middle but not last name
        my ($init) = $row[2] =~ m/^(\w)/;             # for initials
        if ($init) { $filter{$row[0]}{$table}{$init}++; } } }
    $result = $dbh->prepare ( "SELECT * FROM two_${table}name WHERE two_${table}name IS NOT NULL AND two_${table}name != 'NULL' AND two_${table}name != '' AND joinkey IN (SELECT joinkey FROM two_status WHERE two_status = 'Valid');" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while ( my @row = $result->fetchrow ) {
      my $joinkey = $row[0];
      $row[2] =~ s/^\s+//g; $row[2] =~ s/\s+$//g;     # take out spaces in front and back
      $row[2] =~ s/[\,\.]//g;                         # take out commas and dots
      $row[2] =~ s/_/ /g;                             # replace underscores for spaces
      $row[2] = lc($row[2]);                          # for full values (lowercase it)
      $row[0] =~ s/two//g;                            # take out the 'two' from the joinkey
      $filter{$row[0]}{$table}{$row[2]}++;
      unless ($table eq 'last') {
        my ($init) = $row[2] =~ m/^(\w)/;             # for initials
        if ($init) {
          $filter{$row[0]}{$table}{$init}++; } } }
  } # foreach my $table (@tables)

  my $possible;
  foreach my $person (sort keys %filter) {
    foreach my $last (sort keys %{ $filter{$person}{last}} ) {
      foreach my $first (sort keys %{ $filter{$person}{first}} ) {
        $possible = "$last $first"; $aka_hash{$possible}{$person}++;
        $possible = "$first $last"; $aka_hash{$possible}{$person}++;
        if ( $filter{$person}{middle} ) {               # Middle name okay if last first middle or first middle last  2007 02 22
          foreach my $middle (sort keys %{ $filter{$person}{middle}} ) {
            $possible = "$last $first $middle"; $aka_hash{$possible}{$person}++;
            $possible = "$last ${first}$middle"; $aka_hash{$possible}{$person}++;
            $possible = "$first $middle $last"; $aka_hash{$possible}{$person}++;
            $possible = "${first}$middle $last"; $aka_hash{$possible}{$person}++; } } } } }
  return %aka_hash;
} # sub getAkaHash

__END__

$result = $dbh->prepare( "SELECT * FROM two_comment LIMIT 5" );
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

how to set directory to output files at curator / web-accessible
  my $outDir = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/citace_upload/karen/";

how to set base url for a form
  my $baseUrl = $ENV{THIS_HOST} . "pub/cgi-bin/forms";

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

