#!/usr/bin/perl -w
#
# write a perl job to have cron do a daily (tuesday - saturday 2am) dump of the testdb.
# 2002 03 12
#
# temp file to work on, to make dumps and then move the old dumps to the old_dumps/ 
# directory.  (basically get the date, and then previous date, and move that one)
# 2002 03 12 

use strict;

my $date = &GetDate();
print "date : $date\n";
`pg_dump testdb > testdb.dump.$date`;

sub getYest {                           # begin getYest
  my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
                                        # set array of days
  my @months = qw(January February March April May June
          July August September October November December);
                                        # set array of months
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  my $shortdate = "$mday/$sam/$year";   # get final date
  my $ampm = "AM";                      # fiddle with am or pm
  if ($hour eq 12) { $ampm = "PM"; }    # PM if noon
  if ($hour eq 0) { $hour = "12"; }     # AM if midnight
  if ($hour > 12) {                     # get hour right from 24
    $hour = ($hour - 12);
    $ampm = "PM";                       # reset PM if after noon
  }
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "$days[$wday], $mday $months[$mon] $year";
                                        # set current date
#   my $date = $todaydate . " $hour\:$min $ampm";
  if ($sam < 10) { $sam = '0' . $sam; }
  my $date = $year . $sam . $mday . '0200';
                                        # set final date
  return $date;
} # sub getYest                         # end getYest


sub GetDate {                           # begin GetDate
  my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
                                        # set array of days
  my @months = qw(January February March April May June
          July August September October November December);
                                        # set array of months
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  my $shortdate = "$mday/$sam/$year";   # get final date
  my $ampm = "AM";                      # fiddle with am or pm
  if ($hour eq 12) { $ampm = "PM"; }    # PM if noon
  if ($hour eq 0) { $hour = "12"; }     # AM if midnight
  if ($hour > 12) {                     # get hour right from 24
    $hour = ($hour - 12);
    $ampm = "PM";                       # reset PM if after noon
  }
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "$days[$wday], $mday $months[$mon] $year";
                                        # set current date
#   my $date = $todaydate . " $hour\:$min $ampm";
  if ($sam < 10) { $sam = '0' . $sam; }
  my $date = $year . $sam . $mday . '0200';
                                        # set final date
# fix this to warn of date, then mv previous entry
#   my $other_date;
#   if ($days[$wday] eq 'Tuesday') { print "Tuesday \n"; }
  return $date;
} # sub GetDate                         # end GetDate

