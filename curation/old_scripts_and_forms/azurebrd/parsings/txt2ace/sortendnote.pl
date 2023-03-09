#!/usr/bin/perl
#
# Program to sort the endnote file

$endin = "test.endnote";
$endout = "new.endnote";

open (IN, "$endin") || die "cannot open $infile : $!"; 	 	# open read
open (OUT, ">$endout") || die "cannot create $outfile : $!"; 	# open write

$three = "000";
$two = "00";
$one = "0";
$zero = "";

while (<IN>) {
  chomp;
  m/([^\t]+)\t/;
  $number = $1;
  if (length($number) == 1) {
    $number = "000".$number;
  } elsif (length($number) == 2) {
    $number = "00".$number;
  } elsif (length($number) == 3) {
    $number = "0".$number;
  } elsif (length($number) == 4) {
    $number = "".$number;
  }
  print "$number \n";
  $blah = $number . " " . $_;
  @inarray = (@inarray, $blah);
}
  

# while (<IN>) {
#   chomp;
#   @muck = split(/\s+/, $_);
#   print "$_ \n";
#   if (length($muck[0]) == 1) {
#     @muck = ($three, @muck);
#   } elsif (length($muck[0]) == 2) {
#     @muck = ($two, @muck);
#   } elsif (length($muck[0]) == 3) {
#     @muck = ($one, @muck);
#   } elsif (length($muck[0]) == 4) {
#     @muck = ($zero, @muck);
#   }
#   $muck[0] = join ("", $muck[0], $muck[1]);
#   $muck[1] = "";
#   $_ = join(" ", @muck);
#   @inarray = (@inarray, $_);
#   print "$_ \n";
# }

@outarray = sort (@inarray);

foreach $_ (@outarray) {
  print OUT "$_ \n";
}

close (IN) || die "cannot close $infile : $!";			# close read
close (OUT) || die "cannot close $outfile : $!";		# close write
  
