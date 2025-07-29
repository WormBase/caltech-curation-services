#!/usr/bin/env perl

# get tfp tables into flatfiles for kimberly and shuai https://agr-jira.atlassian.net/browse/SCRUM-5320  
# output files to https://caltech-curation.textpressolab.com/files/pub/kimberly/tfp_for_abc/
# 2025 07 29


use strict;
use LWP::Simple;
use Jex;
use DBI;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
my $result;

my $date = &getSimpleDate();

my @tables = qw( tfp_genestudied tfp_species tfp_strain tfp_variation tfp_transgene );
foreach my $table (@tables) {
  my $outfile = '/usr/caltech_curation_files/pub/kimberly/tfp_for_abc/' . $table . '.tsv';
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
  my $result = $dbh->prepare( "SELECT * FROM $table;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    print OUT qq(WB:WBPaper$row[0]\t$row[1]\n);
  }
  close (OUT) or die "Cannot close $outfile : $!";
}
