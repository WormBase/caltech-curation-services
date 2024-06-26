#!/usr/bin/env perl

# take data generated by
# curation/old_scripts_and_forms/postgres/work/pgpopulation/allele_phenotype/20240503_tazendra_transfer/generate_data_from_tazendra.pl
# generate new pgids for it, and add to database.  2024 05 04
#
# another set from Chris with older pgids.  2024 05 18

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

# my $offset = '62670';	# 2024 05 03
my $offset = '62610';	# 2024 05 18

$result = $dbh->prepare( "SELECT * FROM app_curator ORDER BY joinkey::integer DESC LIMIT 1" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
my @row = $result->fetchrow();
my $lowest = $row[0];
print qq(LOW $lowest\n);

my @pgcommands;

my $count = 0;
# my $infile = 'taz_app_data.tsv';
# my $infile = 'taz_app_data_20240503.tsv';
my $infile = 'taz_app_data_20240518.tsv';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
#   $count++; last if ($count > 1);
  chomp $line;
  my ($table, $old_pgid, $data, $ts) = split/\t/, $line;
  my $diff = $old_pgid - $offset;
  my $new_pgid = $lowest + $diff + 1;
  push @pgcommands, qq(INSERT INTO $table VALUES ('$new_pgid', '$data', '$ts'););
}
close (IN) or die "Cannot close $infile : $!";

foreach my $pgcommand (@pgcommands) {
  print qq($pgcommand\n);
# UNCOMMENT TO POPULATE
#   $dbh->do( $pgcommand );
}

