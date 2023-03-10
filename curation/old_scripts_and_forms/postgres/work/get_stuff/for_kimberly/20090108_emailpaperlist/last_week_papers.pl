#!/usr/bin/perl -w

# get new papers from last week   2009 01 08
#
# update from wpa tables to pap tables even though it's not live  2010 06 23
#
# replaced by svm, took out of cronjob  2010 06 24


use strict;
use diagnostics;
use Time::Local;
use Pg;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $dir = '/home/postgres/work/get_stuff/for_kimberly/20090108_emailpaperlist';
chdir($dir) or die "Cannot switch to $dir : $!";


my $time = time;
my $start_sec = $time - 86400 * 7;
my $start_date = toDate($start_sec);
my $body = '';
# my $result = $conn->exec( "SELECT joinkey FROM wpa WHERE wpa_timestamp > '$start_date' ORDER BY wpa;" );
my $result = $conn->exec( "SELECT joinkey FROM pap_status WHERE pap_timestamp > '$start_date' and pap_status = 'valid';" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
     my ($title) = getTitle($row[0]);
     $body .= "WBPaper$row[0]\t$title\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

my $user = "kimberly's weekly paper email";
my $email = 'vanauken@caltech.edu';
my $subject = "kimberly's weekly paper email";
&mailer($user, $email, $subject, $body);

my $outfile = 'last_week_papers';
open(OUT, ">$outfile") or die "Cannot open $outfile : $!";
print OUT "$body\n";
close(OUT) or die "Cannot close $outfile : $!";

sub getTitle {
  my $joinkey = shift;
  my $title = '';
  my $result = $conn->exec( "SELECT * FROM wpa_title WHERE joinkey = '$joinkey' ORDER BY wpa_timestamp;" );
  while (my @row = $result->fetchrow) {
    $title = $row[1]; 
#     if ($row[3] eq 'valid') { $title = $row[1]; } else { $title = ''; }
  } # while (my @row = $result->fetchrow)
  return $title;
}

sub toSeconds {
  my $date = shift;
  my ($year, $mon, $day) = $date =~ m/^(\d\d\d\d)(\d\d)(\d\d)/;
  $mon -= 1;
  my $now = &timelocal(0,0,0,$day,$mon,$year);
  return $now;
}

sub toDate {
  my $time = shift;                     # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  if ($hour < 10) { $hour = "0$hour"; } # add a zero if needed
  if ($min < 10) { $min = "0$min"; } # add a zero if needed
  if ($sec < 10) { $sec = "0$sec"; } # add a zero if needed
  my $shortdate = "${year}-${sam}-${mday} ${hour}:${min}:${sec}";   # get final date
  return $shortdate;
}

__END__

