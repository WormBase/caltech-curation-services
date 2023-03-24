#!/usr/bin/env perl
#
# write a perl job to have cron do a daily (tuesday - saturday 2am) dump of the testdb.
# 2002 03 12
#
# have a symlink to latest dump.  if new dump is not different from latest dump, delete it;
# if it is different, then remove the symlink and recreate it linking to the latest dump.
# check old_dumps/, and if the first 6 digits of the date (year and month) don't match any
# entries, copy it to old_dumps/ for backup (to keep the earliest dump of each month).
# check all dumps in the 2000 millenium, sort (by default by date because of the naming
# structure) and only keep the oldest 5, deleting all the rest.  2004 05 21
#
# Tried to fix it, essentially made no changes, it seems to work, but it wasn't.
# Hopefully it's working now somehow.  2004 09 16
#
# Added a while sleep 60 and output from `  2004 10 27
#
# Diffing files was running out of memory since 202010060200.  2021 03 25
#
# Dockerized, but pg_dump doesn't work.  2023 03 23


use strict;
use Dotenv -load => '/usr/lib/.env';

my $directory = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/cronjobs/pgdumps/';
# my $directory = '/home/postgres/work/pgdumps';
chdir($directory) or die "Cannot go to $directory ($!)";

my $dbname = $ENV{PSQL_DATABASE};

my $date = &GetDate();
# print "$date\n";
# my $out = 0;
# $out = `/usr/bin/pg_dump testdb > /home/postgres/work/pgdumps/testdb.dump.$date`;
# while ($out == 0) { sleep 60; }
# print "OUT $out OUT\n";

`/usr/bin/pg_dump $dbname > $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}/cronjobs/pgdumps/${dbname}.dump.$date`;
# `/usr/bin/pg_dump testdb > /home/postgres/work/pgdumps/testdb.dump.$date`;

# my $diff = `diff testdb.dump.latest testdb.dump.$date`;	# this was running out of memory since 202010060200  2021 03 25
my $diff = 0;
my $md5sumLatest = `md5sum ${dbname}.dump.latest`;
# my $md5sumLatest = `md5sum testdb.dump.latest`;
# print qq(MD5 $md5sumLatest E\n);
my $md5sumNew = `md5sum ${dbname}.dump.$date`;
# my $md5sumNew = `md5sum testdb.dump.$date`;
# print qq(MD5 $md5sumNew E\n);
if ($md5sumNew ne $md5sumLatest) { $diff = 1; }

if ($diff) {				# new dump is different
# print "DIFF\n";
  unlink ("${dbname}.dump.latest") or die "Cannot unlink : $!";	# unlink symlink to latest
  symlink("${dbname}.dump.$date", "testdb.dump.latest") or warn "cannot symlink : $!";
#   unlink ("testdb.dump.latest") or die "Cannot unlink : $!";	# unlink symlink to latest
#   symlink("testdb.dump.$date", "testdb.dump.latest") or warn "cannot symlink : $!";
					# link newest dump to latest
} else {
  `rm ${dbname}.dump.$date`;		# new dump is the same, delete it
#   `rm testdb.dump.$date`;		# new dump is the same, delete it
# print "NOT DIFF\n";
} # if($diff)

my $current_dump = '${dbname}.dump.' . $date;
# my $current_dump = 'testdb.dump.' . $date;
my @old_dumps = <$ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}/cronjobs/pgdumps/old/*>;
# my @old_dumps = </home2/postgres/work/pgdumps/old/*>;
my %old_dumps;
foreach my $old_dump (@old_dumps) { 
  $old_dump =~ m/(${dbname}\.dump\.\d{6})/;
  # $old_dump =~ m/(testdb\.dump\.\d{6})/;
  $old_dumps{$1}++; }
my ($back_it_up) = $current_dump =~ m/(${dbname}\.dump\.\d{6})/;
# my ($back_it_up) = $current_dump =~ m/(testdb\.dump\.\d{6})/;
# print "BACK IT UP $back_it_up BACK IT UP\n";
unless ($old_dumps{$back_it_up}) { 
#   print "COPY $current_dump TO OLD\n";
  `cp $current_dump /home2/postgres/work/pgdumps/old/`; }

my @current_dumps = <$ENV{CALTECH_CURATION_FILES_INTERNAL_PATH}/cronjobs/pgdumps/${dbname}.dump.2*>;
# my @current_dumps = </home/postgres/work/pgdumps/testdb.dump.2*>;
my @ordered_dumps = sort @current_dumps;
my @dumps_to_save = ();
while (scalar(@dumps_to_save) < 5) { push @dumps_to_save, pop @ordered_dumps; }
if (@ordered_dumps) { while (@ordered_dumps) { 
  my $bad = pop @ordered_dumps; 
#   print "BAD $bad\n"; 
  `rm $bad`; } }




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
  if ($mday < 10) { $mday = '0' . $mday; }
  my $date = $year . $sam . $mday . '0200';
                                        # set final date
  return $date;
} # sub GetDate                         # end GetDate

