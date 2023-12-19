#!/usr/bin/env perl

# parse journal_with_permission at Caltech to see with papers exist, get the AGRKB resource_title, and check mappings.


use strict;
use JSON;
use DBI;
use Encode qw( from_to is_utf8 );
use LWP::Simple;
use Jex;
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my %journal_has_permission;                       # for image_overview below
my $infile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/daniela/picture_curatable/journal_with_permission';
# my $infile = '/home/acedb/draciti/picture_curatable/journal_with_permission';
open (IN, "$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) { chomp $line; $journal_has_permission{$line}++; }
close (IN) or die "Cannot close $infile : $!";

my $count = 0;
my %journalToPaper;
my %paperToJournal;
my %uniq_diff;
foreach my $journal (sort keys %journal_has_permission) {
  print qq(processing $journal\n);
  $result = $dbh->prepare( "SELECT * FROM pap_journal WHERE pap_journal = '$journal';" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $count++;
#       last if $count > 5;
      $paperToJournal{$row[0]} = $journal;
      $journalToPaper{$journal}{$row[0]}++;
      my $abc_resource_title = &getAbcResource($row[0]);
      my $diff = 'same';
      if ($abc_resource_title ne $journal) { 
        $uniq_diff{qq($journal\t$abc_resource_title)}++;
        $diff = 'diff';
      }
      print qq($diff\t$row[0]\t$journal\t$abc_resource_title\n); 
  } }
}
print qq($count\n);
print qq(\nuniquely different things at Caltech vs ABC\n);
foreach my $uniq_diff (sort keys %uniq_diff) {
  print qq($uniq_diff\n);
}

sub getAbcResource {
  my ($joinkey) = @_;
  my $url = 'https://literature-rest.alliancegenome.org/reference/by_cross_reference/WB:WBPaper' . $joinkey;
  my $content = get $url;
  unless ($content) { return qq($joinkey not found at ABC\n); }
  my $jsonHash = decode_json( $content );
  my %jsonHash = %$jsonHash;
  if ($jsonHash{'resource_title'}) { return $jsonHash{'resource_title'}; }
    else { return "no resource at ABC"; }
} # sub getAbcResource

