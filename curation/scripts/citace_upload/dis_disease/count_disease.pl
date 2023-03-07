#!/usr/bin/env perl

# count stats for concise description for Ranjana
# http://wiki.wormbase.org/index.php/OA_and_scripts_for_disease_data#Counting_script_specifications
# 2014 03 23
#
# fixed count of papers that are expmod / disrel to only count them once, no matter how many times 
# they show up in different pgid rows.
# sort papers into either review or nonreview, and for any papers that show up on expmod or disrel
# sort into review vs nonreview and print out counts and lists.  for Ranjana  2014 09 15


use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %hash;
my $count_gene_entries = 0;
$result = $dbh->prepare( "SELECT * FROM dis_wbgene" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $count_gene_entries++;
    $hash{wbgene}{$row[1]}{$row[0]}++; } }
print qq(No. of genes in dis_wbgene $count_gene_entries\n);
foreach my $gene (sort keys %{ $hash{wbgene} }) {
  my (@pgids) = sort keys %{ $hash{wbgene}{$gene} };
  if (scalar @pgids > 1) { print qq($gene has mapping to pgids @pgids\n); }
} # foreach my $gene (sort keys %{ $hash{wbgene} })
my $count_unique_gene_entries = scalar keys %{ $hash{wbgene} };
print qq(No. of unique genes in dis_wbgene $count_unique_gene_entries\n);

my %doid; my $count_any_doid = 0;
$result = $dbh->prepare( "SELECT * FROM dis_humandoid" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@doid) = $row[1] =~ m/(DOID:\d+)/g;
    foreach (@doid) { $doid{$_}++; $count_any_doid++; } } }
print qq(count all DO_terms $count_any_doid\n); 
my $count_unique_doid = scalar keys %doid;
print qq(count unique DO_terms $count_unique_doid\n); 

my %unique_papers_any;
my %unique_papers_expmod;
my %unique_papers_disrel;
my %unique_papers_review; my %unique_papers_nonreview;
my %papIsReview;
$result = $dbh->prepare( "SELECT * FROM pap_type WHERE pap_type = '2'" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { $papIsReview{"WBPaper$row[0]"}++; }


$result = $dbh->prepare( "SELECT * FROM dis_paperexpmod" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@paperexpmod) = $row[1] =~ m/(WBPaper\d+)/g;
    foreach (@paperexpmod) { 
      if ($papIsReview{$_}) { $unique_papers_review{$_}++; } else { $unique_papers_nonreview{$_}++; }
      $unique_papers_expmod{$_}++; $unique_papers_any{$_}++; } } }
my $count_any_paperexpmod = scalar keys %unique_papers_expmod;
print qq(count any paper exp mod $count_any_paperexpmod\n); 

my $count_descriptions = 0;
$result = $dbh->prepare( "SELECT COUNT(*) FROM dis_diseaserelevance" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $count_descriptions = $row[0]; } }
print qq(count disease descriptions : $count_descriptions\n);

my $count_genedisrel = 0;
$result = $dbh->prepare( "SELECT * FROM dis_genedisrel" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@genedisrel) = $row[1] =~ m/(\d+)/g;
    foreach (@genedisrel) { $count_genedisrel++; } } }
print qq(count omim gene disrel : $count_genedisrel\n);

my %omim;
$result = $dbh->prepare( "SELECT * FROM dis_dbdisrel" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@omim) = $row[1] =~ m/(\d+)/g; foreach (@omim) { $omim{$row[0]}{$_}++; } } }
$result = $dbh->prepare( "SELECT * FROM dis_dbexpmod" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@omim) = $row[1] =~ m/(\d+)/g; foreach (@omim) { $omim{$row[0]}{$_}++; } } }
my $count_omim_connected = 0;
foreach my $pgid (sort keys %omim) { foreach my $omim (sort keys %{ $omim{$pgid} }) { $count_omim_connected++; } }
print qq(Count omim diseases connected : $count_omim_connected\n);


$result = $dbh->prepare( "SELECT * FROM dis_paperdisrel" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[1]) { 
    my (@paperdisrel) = $row[1] =~ m/(WBPaper\d+)/g;
    foreach (@paperdisrel) { 
      if ($papIsReview{$_}) { $unique_papers_review{$_}++; } else { $unique_papers_nonreview{$_}++; }
      $unique_papers_disrel{$_}++; $unique_papers_any{$_}++; } } }
my $count_any_paperdisrel = scalar keys %unique_papers_disrel;
print qq(count any paper dis rel $count_any_paperdisrel\n); 


my $count_unique_papers_any = scalar keys %unique_papers_any;
print qq(count unique papers disrel or expmod : $count_unique_papers_any\n);

my $count_unique_papers_review = scalar keys %unique_papers_review;
print qq(count unique papers disrel or expmod that are review : $count_unique_papers_review\n);

my $count_unique_papers_nonreview = scalar keys %unique_papers_nonreview;
print qq(count unique papers disrel or expmod that are not review : $count_unique_papers_nonreview\n);

print qq(\nList of unique papers disrel or expmod that are review :\n);
foreach my $paper (sort keys %unique_papers_review) { print "$paper\n"; }

print qq(\nList of unique papers disrel or expmod that are not review :\n);
foreach my $paper (sort keys %unique_papers_nonreview) { print "$paper\n"; }

