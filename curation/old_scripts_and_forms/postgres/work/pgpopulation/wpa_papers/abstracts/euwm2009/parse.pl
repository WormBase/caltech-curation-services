#!/usr/bin/perl

# Enter Australian Worm Meeting data.  Some Authors were munged and had to hand
# edit the input file.  2007 05 26
#
# Modified for EUWM2009, manually fixed all word.doc crap entries into \n\n\n\n
# format with Title\n\nAuthors(comma separated)\n\nAbstract  2009 09 23
#
# entered for live run, ran out of memory at around 68 entries.  2009 09 24
#
# William Schaffer didn't want them in WormBase after all.  Removed.  2009 09 24

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw ( processWormbook );

use strict;

my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);

$journal = 'European Worm Neurobiology Meeting';
$year = '2009';
$type = 'Meeting Abstract';

my $starttime = time;

my $infile = 'European_Worm_Neurobiology-meeting2009.partial';
undef $/;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";

my (@abs) = split/\n\n\n\n/, $allfile;

# Transformation of Parastrongyloides trichosuri, a parasitic nematode
# 
# Grant, W.N.1, Shuttleworth, G.2, Newton-Howes, J.2 and Grant, K.I.1
# 1Genetics Department, La Trobe University, Bundoora, Australia
# 2The Hopkirk Research Institute, AgResearch Ltd., Palmerston North, New Zealand


my $counter = 0;
# $abs[0] =~ s/^\d+//; 
foreach my $abs (@abs) {
  $counter++;
  my $identifier = 'euwm09abs' . &padZeros($counter);
#   print "ABS $abs ABS\n";
#   if ($abs =~ m/^\s*(.*?)\n\n(.+?)\n\n(.+)$/sm) {
#   if ($abs =~ m/^\s*?(\w.+?)\n\s+(\w.+?)\n\s+([.\n\f]*)$/m)
  if (1) {		# not sure what to test for
    ($title, my $auths, my @abst) = split/\n\n/, $abs;
    my $abst = join"\n\n", @abst;
#     $title = $1; my $auths = $2; my $abst = $3;
    print "TITLE $title\n";
#     my (@alines) = split/\n/, $auths;
#     $auths = shift @alines;
#     if ($auths =~ m/\d+,\d+/) { $auths =~ s/\d+,\d+//g; }
#     if ($auths =~ m/\d+/) { $auths =~ s/\d+//g; }
#     if ($auths =~ m/\sand\s/) { $auths =~ s/\sand\s/, /g; }
#     if ($auths =~ m/\s\&\s/) { $auths =~ s/\s\&\s/, /g; }
    my (@auths) = split/,/, $auths;
    $authors = '';
    foreach my $auth (@auths) { 
      $auth = &filterSpaces($auth);
      if ($auth =~ m/[^ \-\w]/) { $auth =~ s/[^ \-\w]//g; }
      if ($auth =~ m/\d+/) { $auth =~ s/\d+//g; }
      if ($auth) { 
#         print "AUTH $auth\n"; 
        $authors .= $auth . '//';
      }
    }
    $authors =~ s/\/\/$//;
    if ($authors =~ m/\t/) { $authors =~ s/\t//g; }
    print "AUTHS $authors\n";

#     $abs =~ s/$title//g;
#     $abs =~ s/$auths//g;
    $title = &filterSpaces($title);
    $authors = &filterSpaces($authors);
    $abst = &filterSpaces($abst);
    print "ABS $abst\n\n";

    my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abst\t$genes\t$type\t$editor\t$fulltext_url";
    print "$line\n\n";
# UNCOMMENT TO CREATE
#     &processWormbook( 'two1', 'wormbook', $line );	
# #     &processWormbook( 'two480', 'wormbook', $line );	# 480 is Tuco
  } else { print "NO MATCH $abs\n"; }
}

my $endtime = time;
my $difftime = $endtime - $starttime;
print "Diff time is $difftime seconds\n";

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

sub padZeros {
  my $joinkey = shift;
  if ($joinkey =~ m/^0+/) { $joinkey =~ s/^0+//g; }
  if ($joinkey < 10) { $joinkey = '000' . $joinkey; }
  elsif ($joinkey < 100) { $joinkey = '00' . $joinkey; }
  elsif ($joinkey < 1000) { $joinkey = '0' . $joinkey; }
  return $joinkey;
} # sub padZeros



__END__

DELETE FROM wpa WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_journal WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_volume WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_abstract WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_gene WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2009-09-24 13:52:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2009-09-24 13:52:00';


