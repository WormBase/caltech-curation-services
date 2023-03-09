#!/usr/bin/perl -T

# This CGI has cookie functionality.
#
# It tests whether a $cookie_name exists, if so, displays it.  If not, it sets
# that cookie by appending to the header.  Commented out stuff is for session
# only vs expiration time, and for GMT time instead of PST time.  2003 02 18

use strict;
use CGI;
use Jex;	# cshlNew

my $time = &getCookDate(20);

my ($header, $footer) = &cshlNew('cookie yum yum');

my $q = new CGI;

my $cookie_name = 'fifth';		# pick the name of the cookie

my $fourth = $q->cookie( -name => "$cookie_name" );
					# check if cookie exists

# This section prints header if there's a cookie, else prints header with cookie named fourth 
if ($fourth) { 				# if cookie exists, print it
  $header =~ s/^.*<html>/Content-type: text\/html\n\n<html>/s;
					# somehow $header won't work on this CGI without this
  print "$header\n";			# print header
  print "Cookie Found<BR>\n";		# explanation text
} else {				# if it doesn't, set it
  # This cookie is a session only cookie
#   $header =~ s/^.*<html>/Set-Cookie: $cookie_name=$time\nContent-type: text\/html\n\n<html>/s;
  # This cookie has an actual expiration date
  $header =~ s/^.*<html>/Set-Cookie: $cookie_name=$time; expires=$time\nContent-type: text\/html\n\n<html>/s;
  print "$header\n";			# print header with cookie
  print "Setting Cookie $time<BR>\n";	# explanation text
} # else # if ($fourth)

my $date = &getDate();

# my $gmt_date = &getCookDate(0);

print	$q->h1( "Cookie Good" );
print "<TABLE border=2 cellspacing=5>\n";
print "<TR><TD>CURRENT DATE : </TD><TD>$date</TD>\n";
# print "<TR><TD>GMT DATE : </TD><TD>$gmt_date</TD>\n";
print "<TR><TD>COOKIE EXPIRES : </TD><TD>$fourth</TD>\n";
print "</TABLE>\n";
print $footer;

sub getCookDate {			# get cookie date (parameter is expiration time)
  my $expires = shift;
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
#   my $time_diff = 8 * 60 * 60;		# 8 hours * 60 mins * 60 sec = difference to GMT
#   my $time = time;			# set time
#   my $gmt = $time + $time_diff;		# set to gmt
  my $time = time;
  $time += $expires;			# add extra secs to it for expiration
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);
			  		# get time
  if ($hour < 10) { $hour = "0$hour"; }	# add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
#   my $date = "$days[$wday], ${mday}-${months[$mon]}-${year} $hour\:$min\:$sec GMT";
  my $date = "$days[$wday], ${mday}-${months[$mon]}-${year} $hour\:$min\:$sec PST";
  return $date;
} # sub getCookDate

sub getDate {                           # begin getDate
					# get current date
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
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $todaydate = "$days[$wday], $mday $months[$mon] $year";
                                        # set current date
  my $date = $todaydate . " $hour\:$min\:$sec $ampm";
                                        # set final date
  return $date;
} # sub getDate                         # end getDate
