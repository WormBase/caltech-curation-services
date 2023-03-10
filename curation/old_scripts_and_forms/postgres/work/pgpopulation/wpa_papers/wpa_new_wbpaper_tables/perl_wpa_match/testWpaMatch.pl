#!/usr/bin/perl

# simple call to wpa_match, will attempt to read in the pmid and process into postgres
# with Juancarlos's WBPersonID for two_curator  2006 10 10

use strict;

use lib qw( /home/postgres/work/pgpopulation/wpa_new_wbpaper_tables/perl_wpa_match );
use wpa_match qw( processPubmed processForm );


#   my @pmids = qw( 16306402 );
  my @pmids = qw( 15163769 );
  my $pmid_list = join"\t", @pmids;
  print "Processing $pmid_list.<BR><BR>\n";
  my ($link_text) = &processPubmed($pmid_list, 'two1823', 'functional_annotation');
  print "$link_text\n";
