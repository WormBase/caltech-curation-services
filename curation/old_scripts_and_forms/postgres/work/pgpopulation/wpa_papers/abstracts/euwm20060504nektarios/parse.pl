#!/usr/bin/perl

# process Nektarios's horrible .rtf file after converting it to text and
# manually adding BREAKBREAK to separate entries and removing author
# affiliation.  This still has problems with stuff like <92> and so forth.
# 2006 05 04

use lib qw( /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw ( processWormbook );

use strict;

my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor, $fulltext_url);

$journal = 'European Worm Meeting';
$year = '2006';
$type = 'Meeting Abstract';

my $starttime = time;

my $infile = 'Abstracts_EWM2006.txt';
undef $/;
open (IN, "<$infile") or die "Cannot open $infile : $!";
my $allfile = <IN>;
close (IN) or die "Cannot close $infile : $!";

my (@abs) = split/\n\nBREAKBREAK\n\n/, $allfile;

my $counter = 0;
foreach my $abs (@abs) {
  $counter++;
  my $identifier = 'euwm06abs' . $counter;
  if ($abs =~ m/^\s*?(\w.+?)\n\s+(\w.+?)\n\s+([.\n\f]*)$/m) {
    $title = $1; my $auths = $2; my $rest = $3;
#     print "TITLE $title\n";
    if ($auths =~ m/\d+,\d+/) { $auths =~ s/\d+,\d+//g; }
    if ($auths =~ m/\d+/) { $auths =~ s/\d+//g; }
    if ($auths =~ m/\sand\s/) { $auths =~ s/\sand\s/, /g; }
    if ($auths =~ m/\s\&\s/) { $auths =~ s/\s\&\s/, /g; }
#     print "AUTHS $auths\n";
    my (@auths) = split/,/, $auths;
    $authors = '';
    foreach my $auth (@auths) { 
      $auth = &filterSpaces($auth);
      if ($auth) { 
#         print "AUTH $auth\n"; 
        $authors .= $auth . '//';
      }
    }
    $authors =~ s/\/\/$//;
    if ($authors =~ m/\t/) { $authors =~ s/\t//g; }
#     print "AUTHS $authors\n";

    $abs =~ s/$title//g;
    $abs =~ s/$auths//g;
    $title = &filterSpaces($title);
    $authors = &filterSpaces($authors);
    $abs = &filterSpaces($abs);
#     print "ABS $abs\n\n";

    my $line = "$identifier\t$authors\t$title\t$journal\t$volume\t$pages\t$year\t$abs\t$genes\t$type\t$editor\t$fulltext_url";
    print "$line\n";
    &processWormbook( 'two649', 'wormbook', $line );	# 649 is Nektarios
  }
}

my $endtime = time;
my $difftime = $endtime - $starttime;
print "Diff time is $difftime seconds\n";

sub filterSpaces {
  my $entry = shift;
  if ($entry =~ m/\n+/m) { $entry =~ s/\n+/. /mg; }
  if ($entry =~ m/\t+/m) { $entry =~ s/\t+/. /mg; }
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
  return $entry;
} # sub filterSpaces


__END__

DELETE FROM wpa WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_journal WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_volume WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_abstract WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2006-05-04 20:15:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2006-05-04 20:15:00';

