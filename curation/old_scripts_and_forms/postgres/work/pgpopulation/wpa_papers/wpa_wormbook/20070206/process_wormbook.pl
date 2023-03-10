#!/usr/bin/perl

# Create a method for entering WormBook entries as processed by Igor.
# This creates In_book entries (for WormBook)  and uses wpa_match.pm
# which has a new section to deal with wormbook data, and also now 
# includes editor and fulltext_url options.  2006 04 28
#
# Fixed WormBook type.  2007 02 06

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw( processWormbook );

use strict;

$/ = "";
my ($wormbook, $authors, $title, $journal, $volume, $pages, $year, $abstract, $genes, $type, $editor);

my %tags;

my $counter = 29009;			# put highest wpa here, to create from next one

# my $infile = 'wormbook_chapters_04_27_2006.txt';
my $infile = 'new_wormbook_chapters_authors.txt';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $para = <IN>) {
  $counter++;
  my %entry;
  my (@lines) = split/\n/, $para;
  foreach my $line (@lines) {
    my ($tag) = $line =~ m/^(\w+)\s/;
    my $num = $counter;
    if ($tag eq 'In_book') { $line =~ s/^In_book\s+//g; $num .= '.2'; }
    if ($line =~ m/^Title\t\"(.*)\"$/) { $entry{$num}{title} = $1; }
    if ($line =~ m/^DOI\t\"(.*)\"$/) { $entry{$num}{wormbook} = $1; }
    if ($line =~ m/^Abstract\t\"(.*)\"$/) { $entry{$num}{abstract} = $1; }
    if ($line =~ m/^Editor\t\"(.*)\"$/) { $entry{$num}{editor} = $1; }
    if ($line =~ m/^Remark\t\"(.*)\"$/) { next if ($num =~ m/\.2/); $entry{$num}{remark} = $1; }	# skip remarks in In_book
    if ($line =~ m/^URL\t\"(.*)\"$/) { $entry{$num}{fulltext_url} = $1; }
    if ($line =~ m/^Year\t(.*)$/) { $entry{$num}{year} = $1; }
    if ($line =~ m/^Type\t\"(.*)\"$/) { if ($1 eq 'WormBook') { $entry{$num}{type} = $1; } else { print "ERROR $1 not the expected type\n"; } }
    if ($line =~ m/^Author\t\"(.*)\"$/) { $entry{$num}{authors} .= $1 . '//'; }
  } # foreach my $line (@lines)
  foreach my $num (sort keys %entry) {
    my $authors = $entry{$num}{authors}; $authors =~ s/\/\/$//; 
    my $line = "$entry{$num}{wormbook}\t$authors\t$entry{$num}{title}\t$journal\t$volume\t$pages\t$entry{$num}{year}\t$entry{$num}{abstract}\t$genes\t$entry{$num}{type}\t$entry{$num}{editor}\t$entry{$num}{fulltext_url}";
    print "$line\n";
    &processWormbook( 'two22', 'wormbook', $line, $num );	# two22 is Igor
  }
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";


__END__

foreach my $tag (sort keys %tags) { print "TAG $tag\n"; }

TAG Abstract
TAG Author
TAG In_book
TAG PDF
TAG Title
TAG URL
TAG Year

DELETE FROM wpa WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_title WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_identifier WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_year WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_type WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_author WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_fulltext_url WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_in_book WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_editor WHERE wpa_timestamp > '2006-04-28 20:15:00';
DELETE FROM wpa_author_index WHERE wpa_timestamp > '2006-04-28 20:15:00';
