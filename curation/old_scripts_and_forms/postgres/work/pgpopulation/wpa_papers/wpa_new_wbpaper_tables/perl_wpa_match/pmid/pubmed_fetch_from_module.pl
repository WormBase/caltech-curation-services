#!/usr/bin/perl -w

# Purpose: Read in PubMed identifiers. Generate url link to XML 
#          abstract page on PubMed website, download page and extract the PubMed 
#          citation info for each paper. Split citation info by type and output 
#          to corresponding directory. Download online text if available.
# Author:  Eimear Kenny and Hans-Michael Muller
# Date:    April 2005 / June 2005
#
##############################################################################
#
# Developed at /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/pubmed_fetch/
#
# Give as parameter a file with pmid numbers, or the word ``update'' to update
# WBPapers with PMIDs missing volume or pages.
# Use the wpa_match.pm module at 
# /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match/wpa_match.pm 
# 2005 08 16



if (@ARGV < 1) { die "

USAGE: $0 <file with current pmids | update>



SAMPLE INPUT:  $0 elegans.pmid 	(list of pmids)
            :  $0 update  (update current pmids missing volume or pages)
\n
";}
##############################################################################

use strict;

use lib qw( /home/postgres/work/pgpopulation/wpa_papers/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw( processPubmed );

use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %pmids = ();

my $pmidlist = $ARGV[0]; # Pubmed identifiers

if ($pmidlist eq 'update') {
  print "UPDATE\n";
  &getWpaPmidMissingVolumePages();
} else {
  my @aux = getpmidlist($pmidlist);
  foreach my $id (@aux) { $pmids{$id}++ ; }
}

my $pmid_list = join"\t", @{ [ keys %pmids ] };
&processPubmed($pmid_list);


sub getWpaPmidMissingVolumePages {
  my %papers;
  my $result = $conn->exec( "SELECT * FROM wpa ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      if ($row[3] eq 'valid') { $papers{join}{$row[0]} = $row[1]; }
      else { $papers{join}{$row[0]} = ''; } } }
  $result = $conn->exec( "SELECT * FROM wpa_identifier WHERE wpa_identifier ~ 'pmid';" );
  while (my @row = $result->fetchrow) {
    if ($papers{join}{$row[0]}) {
      my $joinkey = $row[0]; my $pmid = $row[1]; $pmid =~ s/pmid//g;
      my $result2 = $conn->exec( "SELECT * FROM wpa_volume WHERE joinkey = '$joinkey';" );
      my @row2 = $result2->fetchrow;
      unless ($row2[1]) { $pmids{$pmid}++; }
      $result2 = $conn->exec( "SELECT * FROM wpa_pages WHERE joinkey = '$joinkey';" );
      @row2 = $result2->fetchrow;
      unless ($row2[1]) { $pmids{$pmid}++; }
    }
  }
} # sub getWpaPmidMissingVolumePages




sub getpmidlist {
  my $fn = shift;
  my @ret = ();
  open (IN, "<$fn");
  while (my $line = <IN>) {
    chomp($line);
    push @ret, $line; }
  close (IN);
  return @ret;
} # sub getpmidlist



__END__

# SELECT * FROM wpa_author_index_author_id_seq;
# SELECT setval('wpa_author_index_author_id_seq', 74426);

pg_deleting :	# CHANGE DATE IF USING THIS !
# SELECT * FROM wpa WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_title WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_identifier WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_journal WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_volume WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_pages WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_year WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_type WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_abstract WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_gene WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_author WHERE wpa_timestamp > '2005-08-15 18:30:00';
# SELECT * FROM wpa_author_index WHERE wpa_timestamp > '2005-08-15 18:30:00';

# wget "http://tazendra.caltech.edu/~postgres/cgi-bin/wbpaper_editor.cgi?number=$data&action=Enter+PMIDs+%21&curator_name=Tuco&pmids=16043310-16042554-16042417-16041374-16040202-16040138-16039072-16038100-16038089-16037210-16033884-16033794-16028834-16027367-16025342-16024819-16024786-16023097-16022603-16020796"
