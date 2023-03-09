#!/usr/bin/perl

use strict;
use diagnostics;
 
# binmode STDOUT, ":utf8";
# use utf8;
use JSON;

my %uberName;
$uberName{"UBERON:0001009"} = "circulatory system";
$uberName{"UBERON:0001007"} = "digestive system";
$uberName{"UBERON:0000949"} = "endocrine system";
$uberName{"UBERON:0001008"} = "renal system";
$uberName{"UBERON:0002330"} = "exocrine system";
$uberName{"UBERON:0002193"} = "hemolymphoid system";
$uberName{"UBERON:0002416"} = "integumental system";
$uberName{"UBERON:0002423"} = "hepatobiliary system";
$uberName{"UBERON:0002204"} = "musculoskeletal system";
$uberName{"UBERON:0001016"} = "nervous system";
$uberName{"UBERON:0000990"} = "reproductive system";
$uberName{"UBERON:0001004"} = "respiratory system";
$uberName{"UBERON:0001032"} = "sensory system";
$uberName{"UBERON:0005726"} = "chemosensory system";
$uberName{"UBERON:0007037"} = "mechanosensory system";
$uberName{"UBERON:0002105"} = "vestibuloauditory system";
$uberName{"UBERON:0002104"} = "visual system";
$uberName{"UBERON:0000924"} = "ectoderm";
$uberName{"UBERON:0000925"} = "endoderm";
$uberName{"UBERON:0000926"} = "mesoderm";
$uberName{"UBERON:0003104"} = "mesenchyme";
$uberName{"UBERON:0001013"} = "adipose tissue";
$uberName{"UBERON:0000026"} = "appendage";
$uberName{"UBERON:0016887"} = "entire extraembryonic component";
$uberName{"UBERON:6005023"} = "imaginal precursor";
$uberName{"UBERON:0002539"} = "pharyngeal arch";
$uberName{"Other"}          = "other";
 
my $json;
{
  local $/; #Enable 'slurp' mode
  open my $fh, "<", "WB_1.0.0.7_expression.json";
  $json = <$fh>;
  close $fh;
}
my $data = decode_json($json);
my %data = %$data;

my %whereCount;
foreach my $entry (@{ $data{"data"} }) {
  unless($$entry{"whereExpressed"}) { print qq($entry missing whereExpressed\n); }
  my $where = $$entry{"whereExpressed"}{"whereExpressedStatement"};
  foreach my $subentry (@{ $$entry{"whereExpressed"}{"anatomcialStructureUberonSlimTermIds"} }) {
    if ($$subentry{'uberonTerm'}) { 
      $whereCount{$$subentry{'uberonTerm'}}{$where}++;
# if ($$subentry{'uberonTerm'} eq 'UBERON:0001008') { print qq(UB $$subentry{'uberonTerm'} -- $where\n); }
    }
  }
#   my $uberon = $$entry{"whereExpressed"}{"anatomcialStructureUberonSlimTermIds"};
#   print qq($$entry{"whereExpressed"}\n);
}

foreach my $uberTerm (sort keys %whereCount) {
  foreach my $where (sort keys %{ $whereCount{$uberTerm} }) {
    print qq($uberName{$uberTerm}\t$where\t$whereCount{$uberTerm}{$where}\n); 
  }
}

# print qq($data{"data"}[0]{"assay"}\n);


