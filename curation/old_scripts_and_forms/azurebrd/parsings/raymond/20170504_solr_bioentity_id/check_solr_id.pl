#!/usr/bin/perl

# test id vs bioentity_internal_id in solr for Raymond.  2017 05 04

use strict;
use LWP::Simple;
use JSON;

my $json = JSON->new->allow_nonref;


my $start = 0;
my $end = 922308;
# my $end = 2308;

while ($start < $end) {
  my $url = 'http://131.215.12.204:8080/solr/biggo/select?qt=standard&fl=id,bioentity_internal_id&version=2.2&wt=json&rows=1000&start=' . $start . '&indent=on&q=*:*&fq=document_category:%22bioentity%22';
  print qq(URL $url\n);

  my $page_data = get $url;
  unless ($page_data) { last; }
  my $perl_scalar = $json->decode( $page_data );
  my %jsonHash = %$perl_scalar;

  foreach my $geneHash (@{ $jsonHash{"response"}{"docs"} }) {
    my %geneHash = %$geneHash;
    my $biid = $geneHash{bioentity_internal_id} || '-';
    my $id = $geneHash{id} || '-';
    my ($stripped) = $id =~ m/:(.*)/;
    unless ($stripped eq $biid) { print qq($biid NOT $id\n); }
  }
  $start += 1000;
}
