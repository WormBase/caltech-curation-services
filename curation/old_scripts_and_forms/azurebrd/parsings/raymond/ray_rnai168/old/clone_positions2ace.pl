#!/usr/bin/perl

use strict;
use Getopt::Long;

my $LAB = 'UNKNOWN';
my $METHOD = "cDNA_for_RNAi";
my $REMARK = 'EST clone used in RNAi assay';

GetOptions("lab=s" => \$LAB,
	   'method=s' => \$METHOD,
	   'remark=s' => \$REMARK) or die <<USAGE;
Usage: $0 [options] <clone_positions_file>

Generate .ace file containing clone positions for RNAis that use
cDNA as reagent.

 Options:
      -lab  <lab>       specify lab name
      -method <method>  change method
      -remark <remark>  change remark

Default lab    = $LAB
Default method = $METHOD
Default remark = $REMARK
USAGE
;

while (<>) {
  chomp;
  my ($clone,$canonical,$start,$end) = split "\t";
  my $length = $end-$start+1;
  print <<END;
Sequence : $canonical
Nongenomic $clone $start $end

Sequence : $clone
RNAi "$LAB:$clone" 1 $length
Method "$METHOD"
From_Laboratory "$LAB"
Remark "$REMARK"

END

}
