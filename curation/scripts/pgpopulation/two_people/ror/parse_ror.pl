#!/usr/bin/env perl

# parse ror data to compare against institutions

# ror dataset maintained by  https://zenodo.org/records/15132361
# 2025 04 03 dataset  https://zenodo.org/records/15132361/files/v1.63-2025-04-03-ror-data.zip?download=1

# WB has 75215 Institution entries, 13816 of those are unique strings
# 6358 unambiguous matches, and 335 matches that match to multiple ROR IDs.
# 7458 Institutions don't match exactly.  2025 04 11


use strict;
use diagnostics;
use DBI;
use JSON;
use Data::Dumper;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';


my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my $json_file = 'v1.63-2025-04-03-ror-data.json';
# my $json_file = 'sample.json';

# Read the file content
open my $fh, '<', $json_file or die "Cannot open $json_file: $!";
local $/;  # Slurp mode to read the entire file
my $json_text = <$fh>;
close $fh;

# Decode JSON into Perl hash
my $json = JSON->new->utf8;
my $data = $json->decode($json_text);

my %rorNameToId;
my %rorSimpleNameToId;
my %rorIdToName;
my %ambiguousRorName;
foreach my $entry_ref (@$data) {
  my %entry = %$entry_ref;
#   if ($entry{'id'}) { print qq(ID $entry{'id'}\n); }
#   if ($entry{'name'}) { print qq(NAME $entry{'name'}\n); }
  if ($entry{'id'} && $entry{'name'}) { 
    push @{ $rorNameToId{$entry{'name'}} }, $entry{'id'};
    push @{ $rorIdToName{$entry{'id'}} }, $entry{'name'};
    my $lcname = &simplify($entry{'name'});
    push @{ $rorSimpleNameToId{$lcname} }, $entry{'id'};
  }
}

# check whole dataset for ambiguity, there's ambiguity in name to id, but id to name is all good
# foreach my $id (sort keys %rorIdToName) {
#   my $count = scalar @{ $rorIdToName{$id} };
#   if ($count > 1) { print qq($id\t$count\t@{ $rorIdToName{$id} }\n); }
# }
# 
# foreach my $name (sort keys %rorNameToId) {
#   my $count = scalar @{ $rorNameToId{$name} };
#   if ($count > 1) { 
#     $ambiguousRorName{$name}++;
# #     print qq($name\t$count\t@{ $rorNameToId{$name} }\n);
#   }
# }
# 
# foreach my $name (sort keys %rorSimpleNameToId) {
#   my $count = scalar @{ $rorSimpleNameToId{$name} };
#   if ($count > 1) { 
#     $ambiguousRorName{$name}++;
# #     print qq($name\t$count\t@{ $rorSimpleNameToId{$name} }\n);
#   }
# }
 
# print all json data
# print Dumper($data);

my %institutes;
$result = $dbh->prepare( "SELECT DISTINCT(two_institution) FROM two_institution ;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) {
    my $fullinst = $row[0];
    $institutes{$fullinst}++;
    my (@parts) = split(/;/, $fullinst);
    my $partinst = $parts[0];
    my $lcname = &simplify($fullinst);
    my $lcpart = &simplify($partinst);
    if ($rorSimpleNameToId{$lcname}) {
        my $count = scalar @{ $rorSimpleNameToId{$lcname} };
        if ($count > 1) {
          print qq(AMBIGUOUS1 $fullinst IS @{ $rorSimpleNameToId{$lcname} }\n); }
        else {
          print qq(GOOD $fullinst IS @{ $rorSimpleNameToId{$lcname} }\n); } }
      elsif ($rorSimpleNameToId{$lcpart}) {
        my $count = scalar @{ $rorSimpleNameToId{$lcpart} };
        if ($count > 1) {
          print qq(AMBIGUOUS2 $fullinst IS @{ $rorSimpleNameToId{$lcpart} }\n); }
        else {
          print qq(GOOD $fullinst IS @{ $rorSimpleNameToId{$lcpart} }\n); } }
      else { print qq(NO MATCH $row[0]\n); }
  } # if ($row[0])
} # while (@row = $result->fetchrow)

sub simplify {
  my $string = shift;
  $string = lc($string);
  $string =~ s/[^a-z]//g;
  return $string;
}
