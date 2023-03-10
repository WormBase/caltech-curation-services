#!/usr/bin/perl

# cecilia will manually check the output file and rerun this if the output file is wrong.  
# dump all persons to old/persons_<date>.ace and symlink to ~acedb/public_html/cecilia/persons/persons.ace
# for spica cronjob to pick it up for upload.  2009 08 13
#
# set cronjob to dump every Thursday 2 am on 20or30something (dump near end of the month)  2009 08 13
#
# changed to pap dumper (even though pap tables aren't ready yet)  2010 06 22
#
# 0 2 * * thu /home/cecilia/citace_upload/wrapper.pl


use strict;
use Jex;

my $date = &getSimpleDate();
# print "DATE $date\n";

my $directory = '/home/acedb/cecilia/citace_upload';
chdir ($directory) or die "Cannot chdir to $directory : $!";

my $start_time = time;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($start_time);
if ($mday =~ m/^[123]\d/) {                      # only do stuff on 20/30 something for uploads

  my $outfile = "${directory}/old/persons_${date}.ace";
  `${directory}/get_pap_person_ace.pl > $outfile`;

  my $location_of_latest = '/home/acedb/public_html/cecilia/persons/persons.ace';
  unlink ("$location_of_latest") or warn "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
  symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";

}
