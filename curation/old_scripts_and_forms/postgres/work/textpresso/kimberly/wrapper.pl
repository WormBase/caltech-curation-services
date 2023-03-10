#!/usr/bin/perl

# get a dump of all ccc_sentences, then diff newest set with previous set and
# write name of latest file in a file for tazendra script to get.  run every
# monday at 2am
# 0 2 * * mon /home/azurebrd/work/get_kimberly_go_gene_component_verb_localization/wrapper.pl


use strict;

my $directory = '/home/azurebrd/work/get_kimberly_go_gene_component_verb_localization';

chdir $directory or die "Cannot change directory to $directory : $!";

my $date = &getSimpleMinDate();
my $outfile = 'good_sentences_file.' . $date;
print "$outfile\n";

`./get_go_gene_component.pl > /var/www/html/azurebrd/ccc_datafiles/$outfile`;
`./get_recentsent.pl`;



sub getSimpleMinDate {                  # begin getSimpleDate
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
  my $shortdate = "${year}${sam}${mday}.${hour}${min}";   # get final date
  return $shortdate;
} # sub getSimpleMinDate                        # end getSimpleDate

