#!/usr/bin/env perl

# 2024 10 21 for wobr tea.cgi to look up gene names.  


# Set to cronjob to update everyday.
# 0 4 * * * /usr/lib/scripts/cronjobs/get_gin_names.pl


use strict;
use diagnostics;
use DBI;
use Jex;

use Dotenv -load => '/usr/lib/.env';


my $directory =  $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . "/pub/gin_names";
chdir($directory) or die "Cannot go to $directory ($!)";

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";


my $result;

my %geneNameToId; my %geneIdToName;
# my @tables = qw( gin_locus );
my @tables = qw( gin_wbgene gin_seqname gin_synonyms gin_locus );
# my @tables = qw( gin_seqname gin_synonyms gin_locus );
foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM $table;" );
  $result->execute();
  while (my @row = $result->fetchrow()) {
    my $id                 = "WBGene" . $row[0];
    my $name               = $row[1];
    my ($lcname)           = lc($name);
    $geneIdToName{$id}     = $name;
#      $geneNameToId{$lcname} = $id;
    $geneNameToId{$name}   = $id; } }

my $outfile = $directory . '/gin_names.txt';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";
foreach my $name (sort { $geneNameToId{$a} cmp $geneNameToId{$b} } keys %geneNameToId) {
  my $id = $geneNameToId{$name};
  my $primary = '';
  if ($geneIdToName{$id} eq $name) { $primary = 'primary'; }
  print OUT qq($id\t$name\t$primary\n);
} # foreach my $name (sort keys %geneNameToId)
close (OUT) or die "Cannot close $outfile : $!";

