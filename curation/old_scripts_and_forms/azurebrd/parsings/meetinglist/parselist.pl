#!/usr/bin/perl

$infile = "/home/azurebrd/work/meetinglist/Conf_Payment_Status.txt";

open(IN, "$infile") or die "Cannot open $infile : $!";

while(<IN>) {
  ($lastname, $firstname, $a, $institute, $b, $c, $d, $e, $f, $department,
    $street, $city, $state, $zipcode, $country, $g, $h, $i, $j) = split/\t/;
  print "$lastname, $firstname : $street; $city, $state: $zipcode, $country\n";
}
