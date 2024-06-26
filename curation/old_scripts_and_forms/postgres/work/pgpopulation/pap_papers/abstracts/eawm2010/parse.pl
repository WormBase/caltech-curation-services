#!/usr/bin/perl

# for Daniel / Jane.  Daniel sent a dos file, so reading by paragraphs didn't work, use
# dos2unix wbg_18.1.txt  
# to convert to good format
# Entered data  2010 01 20
#
# converted for pap_ tables's pap_match.pm  &processArrayOfHashes  2010 04 13
#
# edited for east asia worm meeting 4 in 2010.  2010 04 19


use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use pap_match qw ( processArrayOfHashes );

use strict;
use diagnostics;

my @array_of_hashes;

my $infile = 'east_asia_4';
# my $infile = 'wbg_sample';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $count = 0;
my $junk_line = <IN>;
while (my $line = <IN>) {
#   $count++; last if ($count > 3);
  chomp $line;
  my @authors;
  my ($identifier, @stuff) = split/\t/, $line;
  for (my $i = 23; $i < 62; $i = $i+3 ) {
    if ($stuff[$i]) {
      my $author = "$stuff[$i] $stuff[$i+1]";
      $author =~ s/_/ /g;
      $author =~ s/\s+/ /g;
      push @authors, $author; } }
  my $title = $stuff[63];
  my $abstract = $stuff[64];
  if ($title =~ m/^\s*\"\s*/) { $title =~ s/^\s*\"\s*//; }
  if ($title =~ m/\s*\"\s*$/) { $title =~ s/\s*\"\s*$//; }
  if ($abstract =~ m/^\s*\"\s*/) { $abstract =~ s/^\s*\"\s*//; }
  if ($abstract =~ m/\s*\"\s*$/) { $abstract =~ s/\s*\"\s*$//; }
  $identifier = 'eawm2010_ab' . $identifier; 
  my $journal = 'East Asia Worm Meeting';
  my $year = '2010';
  my $month = '7';
  my $type = 'Meeting_abstract';
  my $status = 'valid';
  my $primary_data = 'not_designated';

  print "identifier: $identifier\n";
  print "status: $status\n";
  print "primary_data: $primary_data\n";
  print "title: $title\n";
  print "journal: $journal\n";
  print "year: $year\n";
  print "month: $month\n";
  print "type: $type\n";
  foreach my $author (@authors) { print "author: $author\n"; }
  print "abstract: $abstract\n\n";

  my %hash;
  my @identifier; push @identifier, $identifier; $hash{'identifier'} = \@identifier;
  $hash{'status'} = $status;
  $hash{'primary_data'} = $primary_data;
  if ($title) { $hash{'title'} = $title; }
  $hash{'journal'} = $journal;
  $hash{'year'} = $year;
  $hash{'month'} = $month;
  my @type = (); push @type, $type; $hash{'type'} = \@type;
  $hash{'author'} = \@authors;
  if ($abstract) { $hash{'abstract'} = $abstract; }
  push @array_of_hashes, \%hash;
}


my $curator_id = 'two736';
my $timestamp = "CURRENT_TIMESTAMP";
# my $timestamp = "'2010-04-12 12:00'";		# alternate format

&processArrayOfHashes($curator_id, $timestamp, \@array_of_hashes);

__END__

DELETE FROM pap_identifier WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_status WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_primary_data WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_title WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_journal WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_year WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_month WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_type WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_author WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_abstract WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM pap_gene WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_identifier WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_status WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_primary_data WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_title WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_journal WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_year WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_month WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_type WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_author WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_abstract WHERE pap_timestamp > '2010-07-19 14:55';
DELETE FROM h_pap_gene WHERE pap_timestamp > '2010-07-19 14:55';


  next unless ($entry =~ m/title\t(.*)/);
  my %hash;
  my ($title) = $entry =~ m/title\t(.*)/;
  if ($title) { $hash{'title'} = $title; }
  my ($volume) = $entry =~ m/volume\t(.*)/;
  if ($volume) { $hash{'volume'} = $volume; }
  my ($pages) = $entry =~ m/page\t(.*)/;
  if ($pages) { $hash{'pages'} = $pages; }
  $hash{'journal'} = "Worm Breeder's Gazette";
  $hash{'status'} = 'valid';
  $hash{'primary_data'} = 'not_designated';

  my ($affiliation) = $entry =~ m/affiliation\t(.*)/;
  if ($affiliation) { my @affiliation; push @affiliation, $affiliation; $hash{'affiliation'} = \@affiliation; }
  my ($fulltext_url) = $entry =~ m/url\t(.*)/;
  if ($fulltext_url) { my @fulltext_url; push @fulltext_url, $fulltext_url; $hash{'fulltext_url'} = \@fulltext_url; }
  my ($authors) = $entry =~ m/author\t(.*)/;
  if ($authors) { 
    my (@authors) = split/\/\//, $authors; $hash{'author'} = \@authors; }
  $count++;
  my $identifier = 'wbg.test.' . &padZeros($count);
  my @identifier; push @identifier, $identifier; $hash{'identifier'} = \@identifier;
  my @type = (); push @type, 'Gazette_article'; $hash{'type'} = \@type;
  push @array_of_hashes, \%hash;
}
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";


my $curator_id = 'two736';
my $timestamp = "CURRENT_TIMESTAMP";
# my $timestamp = "'2010-04-12 12:00'";		# alternate format

&processArrayOfHashes($curator_id, $timestamp, \@array_of_hashes);



sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros

my %single;
$single{'status'}++;
$single{'title'}++;
$single{'journal'}++;
$single{'publisher'}++;
$single{'volume'}++;
$single{'pages'}++;
$single{'year'}++;
$single{'month'}++;
$single{'day'}++;
$single{'pubmed_final'}++;
$single{'primary_data'}++;
$single{'abstract'}++;

my %multi;
$multi{'editor'}++;
$multi{'type'}++;
$multi{'author'}++;
$multi{'affiliation'}++;
$multi{'fulltext_url'}++;
$multi{'contained_in'}++;
$multi{'gene'}++;
$multi{'identifier'}++;
$multi{'ignore'}++;
$multi{'remark'}++;
$multi{'erratum_in'}++;
$multi{'internal_comment'}++;
$multi{'curation_flags'}++;
$multi{'electronic_path'}++;
$multi{'author_possible'}++;
$multi{'author_sent'}++;
$multi{'author_verified'}++;


# foreach my $hash_ref (@array_of_hashes) {
#   my %hash = %$hash_ref;
#   foreach my $table (sort keys %hash) {
#     if ($multi{$table}) {  
#         my $array_ref = $hash{$table};
#         my @array = @$array_ref;
#         foreach my $data (@array) {
#           print "MULTI pap_$table $data\n"; } }
#       else {
#         my $data = $hash{$table};
#         print "SINGLE pap_$table $data\n"; }
#   } # foreach my $table (sort keys %hash)
# } # foreach my $hash_ref (@array_of_hashes)
 


__END__


# title	Editorial: The Return of The Worm Breeder's Gazette
# volume	18
# number	1
# date	December 2009
# page	2
# author	Chalfie, Martin
# affiliation	Department of Biological Sciences, Columbia University, New York NY
# url	http://www.wormbook.org/wbg/volumes/volume-18-number-1/pdf/wbg18.1_1.pdf
# 
# title	Counting endogenous mRNA molecules in C. elegans
# volume	18
# number	1
# date	December 2009
# page	3
# author	Kim, Dong hyun//van Oudenaarden, Alexander
# affiliation	Department of Physics and Biology, Massachusetts Institute of Technology, Cambridge MA
# url	http://www.wormbook.org/wbg/volumes/volume-18-number-1/pdf/wbg18.1_2.pdf


__END__

sub filterSpaces {
  my $entry = shift;
  if ($entry =~ m/\n+/m) { $entry =~ s/\n+/ /mg; }	# this used to put in .
  if ($entry =~ m/\t+/m) { $entry =~ s/\t+/ /mg; }	# this used to put in .
  if ($entry =~ m/\s+\.\s+/m) { $entry =~ s/\s+\.\s+/ /mg; }
  if ($entry =~ m/^\n+/m) { $entry =~ s/^\n+//mg; }
  if ($entry =~ m/\n+$/m) { $entry =~ s/\n+$//mg; }
  if ($entry =~ m/^\r+/m) { $entry =~ s/^\r+//mg; }
  if ($entry =~ m/\r+$/m) { $entry =~ s/\r+$//mg; }
  if ($entry =~ m/^\f+/m) { $entry =~ s/^\f+//mg; }
  if ($entry =~ m/\f+$/m) { $entry =~ s/\f+$//mg; }
  if ($entry =~ m/^\.\s+/) { $entry =~ s/^\.\s+//g; }
  if ($entry =~ m/^\s+/) { $entry =~ s/^\s+//g; }
  if ($entry =~ m/\s+$/) { $entry =~ s/\s+$//g; }
  if ($entry =~ m/ {2,}/) { $entry =~ s/ {2,}/ /g; }
  return $entry;
} # sub filterSpaces


