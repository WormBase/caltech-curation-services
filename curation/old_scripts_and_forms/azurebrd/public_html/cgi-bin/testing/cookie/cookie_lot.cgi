#!/usr/bin/perl -T

use strict;
use CGI;
use Jex;	# cshlNew

my $gmt = &getCookDate();

my ($header, $footer) = &cshlNew('cookie yum yum');
# $header =~ s/^.*<html>/Content-type: text\/html\n\n<html>/s;
# $header =~ s/^.*<html>/Set-Cookie: fourth=Fri, 14-Feb-2003 16:40:28 PST; expires=Fri, 14-Feb-2003 16:40:28 PST\nContent-type: text\/html\n\n<html>/s;

my $q = new CGI;

# my $cart_id = $q->cookie( -name => "cart_id" ) || set_cookie( $q );
# my $third_cookie = $q->cookie( -name => "third" ) || set_third( $q );

# my $other_cookie = $q->cookie(	-name => "temp_thing",
# 				-value => $q->server_name . " blah blah blah",
# 				-expires => "+10m",
# 				-path => "/~azurebrd/cgi-bin/testing/" );

my $fourth = $q->cookie( -name => "fourth" );	# check if cookie exists

if ($fourth) { 			# if cookie exists, print it
  $header =~ s/^.*<html>/Content-type: text\/html\n\n<html>/s;
				# somehow $header won't work on this CGI without this
  print "$header\n";
  print "Cookie Found<BR>\n";
} else {			# if it doesn't, set it
  my $date = &getDate();
# This cookie is a session only cookie
#   $header =~ s/^.*<html>/Set-Cookie: fourth=$gmt\nContent-type: text\/html\n\n<html>/s;
# This cookie has an actual expiration date
  $header =~ s/^.*<html>/Set-Cookie: fourth=$gmt; expires=$gmt\nContent-type: text\/html\n\n<html>/s;
  print "$header\n";

#   my $fourth = $q->cookie(	-name => "fourth",
# 				-value => $date,
# 				-expires => "+20s",
# 				-path => "/~azurebrd/cgi-bin/testing/" );
#   <meta http-equiv="Set-Cookie" content="$fourth">
#   &printHeader('new title');
#   $header =~ s/<\/head>/    <meta http-equiv="Set-Cookie" content="$fourth">\n<\/head>/;
#   print	$q->header( -type => "text/html", cookie=> $fourth );

  print "Setting Cookie $gmt<BR>\n";
}

# print	$q->header( -type => "text/html" );
# print	$q->header( -type => "text/html", cookie=> $cart_id, cookie=> $other_cookie );
# print	$q->header( -type => "text/html", cookie=> $other_cookie );
# print	$q->start_html( "Cookie Good" );
# my $other_cookie2 = $q->cookie( -name => "temp_thing" );

my $fourth_cookie = $q->cookie( -name => "fourth" ); 
my $date = &getDate();

print	$q->h1( "Cookie Good" );
print "<TABLE border=2 cellspacing=5>\n";
print "<TR><TD>CURRENT DATE : </TD><TD>$date</TD>\n";
print "<TR><TD>GMT DATE : </TD><TD>$gmt</TD>\n";
print "<TR><TD>COOKIE EXPIRES : </TD><TD>$fourth_cookie</TD>\n";
# print "<TR><TD>COOKIE DATE : </TD><TD>$other_cookie</TD>\n";
# print "<TR><TD>COOKIE DATE : </TD><TD>$third_cookie</TD>\n";
# print "<TR><TD>OTHER : </TD><TD>$other_cookie2</TD>\n";
print "</TABLE>\n";
#         $q->p( "CART ID : " . $cart_id ),
print $footer;
# print	$q->end_html;

sub getCookDate {
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
  my $time_diff = 8 * 60 * 60;		# 8 hours + 60 mins + 60 sec
  my $time = time;                      # set time
  my $gmt = $time + $time_diff;
  $gmt += 20;				# add 20 secs to it
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($gmt);             # get time
  if ($hour < 10) { $hour = "0$hour"; }    # add a zero if needed
  if ($min < 10) { $min = "0$min"; }    # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
  $year = 1900+$year;                   # get right year in 4 digit form
  my $date = "$days[$wday], ${mday}-${months[$mon]}-${year} $hour\:$min\:$sec GMT";
  return $date;
} # sub getCookDate

sub getDate {                           # begin getDate
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












sub printHeader {

  my ($title) = @_;
  my $date = &getDate();
  my $fourth = $q->cookie(	-name => "fourth",
# 				-value => "bob",
				-value => $date,
				-expires => "+20s",
				-path => "/~azurebrd/cgi-bin/testing/" );

  print <<"EndOfText";
Set-Cookie: fourth=Fri, 14-Feb-2003 16:36:58 PST; expires=Fri, 14-Feb-2003 16:36:58 PST
Content-Type: text/html; charset=ISO-8859-1

<HTML>
<LINK rel="stylesheet" type="text/css" href="http://minerva.caltech.edu/~azurebrd/stylesheets/wormbase.css">

<HEAD>
EndOfText
  print "<TITLE>$title</TITLE>";
  print <<"EndOfText";
</HEAD>

<BODY bgcolor=#aaaaaa text=#000000 link=cccccc alink=eeeeee vlink=bbbbbb>
<HR>
EndOfText
} # sub printHeader

sub set_third {
  my $q = shift;
  my $date = &getDate();
  my $server = $q->server_name;
  my $third = $q->cookie(	-name => "third",
				-value => $date,
				-expires => "+10s",
				-path => "/~azurebrd/cgi-bin/testing/" );
  print $q->redirect ( -url => "http://$server/~azurebrd/cgi-bin/testing/cookie_test.cgi",
		       -cookie => $third );
  exit;
} # sub set_third

sub set_cookie {
  my $q = shift;
  my $server = $q->server_name;
  my $cart_id = unique_id();
  my $cookie = $q->cookie( -name => "cart_id",
			   -value => $cart_id,
			   -path => "/~azurebrd/cgi-bin/testing/" );
  print $q->redirect ( -url => "http://$server/~azurebrd/cgi-bin/testing/cookie_test.cgi",
		       -cookie => $cookie );
  print "SERVER : $server<BR>\n";
  exit;
} # sub set_cookie




sub unique_id {
  return $ENV{UNIQUE_ID} if exists $ENV{UNIQUE_ID};

  require Digest::MD5;

  my $md5 = new Digest::MD5;
  my $remote = $ENV{REMOTE_ADDR} . $ENV{REMOTE_PORT};

  my $id = $md5->md5_base64( time, $$, $remote );
  $id =~ tr|+/=|-_.|;
  return $id;
}


