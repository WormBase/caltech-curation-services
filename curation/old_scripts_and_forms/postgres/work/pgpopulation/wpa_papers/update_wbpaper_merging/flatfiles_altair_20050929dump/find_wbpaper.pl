#!/usr/bin/perl

# read all objects from all dumps, and print out the object headers and lines with WBPaper.
# 2005 09 15
#
# Usage : ./find_wbpaper.pl
# Operates on : /home/citace/citace/flatfiles/dump_*
# Creates : wbpaper.ace			2005 09 28

my $outfile = 'wbpaper.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";

my $start = &getSimpleSecDate();
my $stime = time;
print OUT "START $start $stime START\n";

$/ = "";
my @flatfiles = </home/citace/citace/flatfiles/dump_*>;
foreach my $file (@flatfiles) {
  open (IN, "<$file") or die "Cannot open $file : $!";
  while (my $paragraph = <IN>) {
    if ($paragraph =~ m/WBPaper/) { 
      my @lines = split/\n/, $paragraph;
      my $header = shift @lines;
      print OUT "$header\n";
      foreach my $line (@lines) {
        if ($line =~ m/WBPaper/) { 
          print OUT "$line\n"; } }
      print OUT "\n";
    } # if ($paragraph =~ m/WBPaper/) 
  } # while (my $paragraph = <IN>)
  close (IN) or die "Cannot close $file : $!";
} # foreach my $file (@flatfiles)

my $end = &getSimpleSecDate();
my $etime = time;
my $diff = $etime - $stime;
print OUT "END $end $etime $diff END\n";

close (OUT) or die "Cannot close $outfile : $!";

sub getSimpleSecDate {                  # begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}.${hour}${min}${sec}";   # get final date
  return $shortdate;
} # sub getSimpleSecDate
