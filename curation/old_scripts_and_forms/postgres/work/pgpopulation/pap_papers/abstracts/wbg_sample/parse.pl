#!/usr/bin/perl

# for Daniel / Jane.  Daniel sent a dos file, so reading by paragraphs didn't work, use
# dos2unix wbg_18.1.txt  
# to convert to good format
# Entered data  2010 01 20
#
# converted for pap_ tables's pap_match.pm  &processArrayOfHashes  2010 04 13
#
# read in 18.2 and 18.3  2011 01 18
#
# dos2unix not in ubuntu.  synaptic install tofrodos
# fromdos wbg_19.1.txt 
# sample data. 2012 02 09
#
# added curation_flags for 'author_person'  2012 02 10

# BEFORE RUNNING  be sure to convert  fromdos <inputfile>  2012 02 09
# BEFORE RUNNING  or convert with vim :%s///g  :set ff=unix    2012 08 14

use lib qw( /home/postgres/work/pgpopulation/pap_papers/new_papers );
use pap_match qw ( processArrayOfHashes );

use strict;

my @array_of_hashes;

$/ = '';
# my $infile = 'wbg_sample';
# my $infile = 'wbg_18.1.txt';
# my $infile = 'wbg_18.2.txt';
# my $infile = 'wbg_18.3.txt';
# my $infile = 'wbg_18.4.txt';
# my $infile = 'wbg_19.1.txt';
# my $infile = 'wbg_19.2.txt';
my $infile = 'wbg_19.3.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $count = 0;
while (my $entry = <IN>) {
  next unless ($entry =~ m/title\t(.*)/i);
  my %hash;
  my ($title) = $entry =~ m/title\t(.*)/i;
  if ($title) { $hash{'title'} = $title; }
  my ($volume) = $entry =~ m/volume\t(.*)/i;
  if ($volume) { $hash{'volume'} = $volume; }
  my ($pages) = $entry =~ m/page\t(.*)/i;
  if ($pages) { $hash{'pages'} = $pages; }
  my ($year) = $entry =~ m/year\t(.*)/i;
  if ($year) { $hash{'year'} = $year; }
  my ($month) = $entry =~ m/month\t(.*)/i;
  if ($month) { 
    if ($month =~ m/^0/) { $month =~ s/^0+//; }
    $hash{'month'} = $month; }
  $hash{'journal'} = "Worm Breeder's Gazette";
  $hash{'status'} = 'valid';
  $hash{'primary_data'} = 'not_designated';

  my (@affiliation) = $entry =~ m/affiliation\t(.*)/ig;
  if ($affiliation[0]) { $hash{'affiliation'} = \@affiliation; }
  my (@fulltext_url) = $entry =~ m/url\t(.*)/ig;
  if ($fulltext_url[0]) { $hash{'fulltext_url'} = \@fulltext_url; }
#   my ($affiliation) = $entry =~ m/affiliation\t(.*)/;
#   if ($affiliation) { my @affiliation; push @affiliation, $affiliation; $hash{'affiliation'} = \@affiliation; }
#   my ($fulltext_url) = $entry =~ m/url\t(.*)/;
#   if ($fulltext_url) { my @fulltext_url; push @fulltext_url, $fulltext_url; $hash{'fulltext_url'} = \@fulltext_url; }
  my ($authors) = $entry =~ m/author\t(.*)/i;
  if ($authors) { 
    my (@authors) = split/\/\//, $authors; $hash{'author'} = \@authors; }
  $count++;
#   my $identifier = 'wbg.test.' . &padZeros($count);
#   my $identifier = 'wbg18.2.' . &padZeros($count);
#   my $identifier = 'wbg18.3.' . &padZeros($count);
#   my $identifier = 'wbg18.4.' . &padZeros($count);
#   my $identifier = 'wbg19.1.' . &padZeros($count);
#   my $identifier = 'wbg19.2.' . &padZeros($count);
  my $identifier = 'wbg19.3.' . &padZeros($count);
  my @identifier; push @identifier, $identifier; $hash{'identifier'} = \@identifier;
  my @type = (); push @type, 'Gazette_article'; $hash{'type'} = \@type;
  my @curation_flags = (); push @curation_flags, 'author_person'; $hash{'curation_flags'} = \@curation_flags;
  push @array_of_hashes, \%hash;
}
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";


my $curator_id = 'two736';
my $timestamp = "CURRENT_TIMESTAMP";
# my $timestamp = "'2010-04-12 12:00'";		# alternate format

# BEFORE RUNNING  convert with vim :%s///g  :set ff=unix    2012 08 14
# UNCOMMENT TO RUN
# &processArrayOfHashes($curator_id, $timestamp, \@array_of_hashes);



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


