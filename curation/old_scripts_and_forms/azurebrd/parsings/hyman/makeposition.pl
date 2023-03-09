#!/usr/bin/perl
# This file makes the proper hyman.sequences file.  The other one fails to catch
# entries with superfluous hyphens.

# $sequences = "hyman.sequences";
$hymanold = "hyman.old";
$outfile = "hyman.sequences2";

# open (SEQ, "$sequences") or die "Cannot open $sequences : $!";
open (HYM, "$hymanold") or die "Cannot open $hymanold : $!";
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

# while (<SEQ>) {
#   if ($_ =~ m/^RNAi TH:.*? (\d{1,}) (\d{1,})$/) {
#     $position = "${1}" . "-" . "${2}";
# print "$position\n";
#     $HoA{$position}++;
#   }
# }

$/ = "";

while (<HYM>) {
  if ($_ =~ m/^RNAi: (.*?)$/m) {
    $rnai = $1;
  }
  if ($_ =~ m/^Position: (.*?): (-){0,}(\d{1,})(-){1,}(\d{1,})$/m) {
    print OUT "Sequence $1\n";
    print OUT "RNAi TH:$rnai $3 $5\n\n";
    $i++;
    # $position = $1;
# print "$position\n";
    # $HoA{$position}++;
  }
}
print "$i\n";

# foreach $_ (sort keys %HoA) {
#   if ($HoA{$_} != 2) { print OUT "$_, $HoA{$_}\n"; }
# }

# close (SEQ) or die "Cannot close $sequences : $!";
close (HYM) or die "Cannot close $hymanold : $!";
close (OUT) or die "Cannot close $outfile : $!";
