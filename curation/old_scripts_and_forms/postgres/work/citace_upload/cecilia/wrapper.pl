#!/usr/bin/perl

# wrapper script to create directory if necesasry, dump full dump from postgres
# into Juancarlos_full_date.ace, then diff with previously latest full dump
# with find_diff.pl into Cecilia_full_date.ace  2005 05 05
#
# set cronjob to dump every Friday 2 am on 20or30something (dump near end of the month)
# 0 2 * * fri /home/postgres/work/citace_upload/cecilia/wrapper.pl
#
# No longer using this, moved to /home/acedb/cecilia/citace_upload/wrapper.pl
# so Cecilia can rerun it if necessary.  2009 08 13


use strict;
use Jex;

my $date = &getSimpleDate();
# print "DATE $date\n";

my $directory = '/home/postgres/work/citace_upload/cecilia';
chdir ($directory) or die "Cannot chdir to $directory : $!";


my $start_time = time;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($start_time);
if ($mday =~ m/^[23]\d/) {                      # only do stuff on 20/30 something for uploads

  my $outfile = "${directory}/old/persons_${date}.ace";
  `${directory}/get_wpa_person_ace.pl > $outfile`;

  my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/persons.ace';
  unlink ("$location_of_latest") or warn "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
  symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";

}
