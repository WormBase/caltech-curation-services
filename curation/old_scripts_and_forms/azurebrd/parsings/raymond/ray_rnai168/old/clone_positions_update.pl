#!/usr/bin/perl

use strict;
use Getopt::Long;

my $LAB = 'UNKNOWN';

GetOptions("lab=s" => \$LAB,) or die <<USAGE;
GetOptions() or die <<USAGE;
Usage: $0 [options] <clone_positions_file>

Generate an .ace file containing updates on clone positions.

 Options: -lab <lab> specify lab prefix
USAGE
;

while (<>) {
  chomp;
  my ($clone,$canonical,$start,$end) = split "\t";
  my $length = $end-$start+1;
  print <<END;
Sequence : $canonical
-D Nongenomic $clone

Sequence : $canonical
Nongenomic $clone $start $end

Sequence : $clone
-D RNAi "$LAB:$clone"

Sequence : $clone
RNAi "$LAB:$clone" 1 $length

END

}
