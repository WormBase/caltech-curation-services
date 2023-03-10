#!/usr/bin/perl -w
#
# Look at concise_description data to get idea of how many created per week.  
# How many total created per week.  How many changed per week.
# Check by week by comparing timestamp of car_lastcurator against current
# output of time.  2004 11 04
# Change format of time to more human readable.  Mail to Erich, Kimberly, 
# and Paul.  Set a cronjob for Mondays at 2am.  2004 11 05
#
# Added Carol.  2005 06 20
# Set a cronjob for Mondays at 2am (again since it got lost).  2005 06 20
#
# Take Sanger off the email list.  For Anthony.  2005 12 13
#
# The week count was off, showing the right data, but referring to the wrong
# set of weeks.  2006 06 05
#
# Changed to 1 / 5 / 52 weeks ago format.  2009 06 07
#
# Was getting stats wrong, should have been checking :
#     if ($time > $week_ago) { $time_group = 1; }
#     elsif ($time > $fweek_ago) { $time_group = 5; }
#     elsif ($time > $year_ago) { $time_group = 52; }
#     else { $time_group = 53; }
# Should have been skipping genes that already were acconted for and getting them
# in descending order.   2009 12 22
#
# removed erich  2010 06 23
#
# changed for con_ tables.  2012 06 04
#
# removed from cronjob for Kimberly  2018 08 13



# inside :
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wrapper.sh
# 2009 04 23


use strict;
use diagnostics;
use Time::Local;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";




my $outfile = "/home/postgres/work/get_stuff/for_erich/weekly_concise_summaries/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;
my %perWeek;
# my $result = $dbh->prepare( "SELECT * FROM car_lastcurator WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp DESC;" );	# only get wbgene values
my $result = $dbh->prepare( "SELECT con_wbgene.con_wbgene, con_wbgene.joinkey, con_lastupdate.con_lastupdate FROM con_wbgene, con_lastupdate WHERE con_wbgene.joinkey = con_lastupdate.joinkey ORDER BY con_lastupdate DESC ;" );	# new con_ tables
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    next if ($theHash{key_gene}{$row[0]});	# skip genes that already went in
    push @{ $theHash{key_gene}{$row[0]} }, $row[2]; 
    push @{ $theHash{key_time}{$row[2]} }, $row[0]; }
}

my $cur_time = time;
my $week_in_secs = 86400*7;
my $week_ago = $cur_time - $week_in_secs;
my $fweek_ago = $cur_time - 5 * $week_in_secs;
my $year_ago = $cur_time - 52 * $week_in_secs;

# print "CT $cur_time 1 $week_ago 5 $fweek_ago 52 $year_ago\n";

foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbgene (@{ $theHash{key_time}{$timestamp}}) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = (0, 0, 0, 0, 0, 0);
    if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/; }
      elsif ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) {
        ($year, $month, $mday) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/; }
      else { next; }			# not a date
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);

    my $time_group = 0;
    if ($time > $week_ago) { $time_group = 1; }
    elsif ($time > $fweek_ago) { $time_group = 5; }
    elsif ($time > $year_ago) { $time_group = 52; }
    else { $time_group = 53; }

# print "TG $time_group TIME $time TS $timestamp G $wbgene\n";

#     my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
#     my $cur_minus_weeks = $cur_time;
#     while ($time < $cur_minus_weeks) {
#       $cur_minus_weeks -= $week_in_secs;
#       $weeks_back++;
#     }

    unless ($perWeek{changed}{$time_group}{$wbgene}) {
      $perWeek{changed}{$time_group}{$wbgene}++;
      push @{ $perWeek{changed}{count}{$time_group} }, $wbgene; }

    unless ($perWeek{created}{gene}{$wbgene}) { 
      $perWeek{created}{gene}{$wbgene} = $time_group;
      push @{ $perWeek{created}{count}{$time_group} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

my $total = 0;
foreach my $weeks_back (reverse sort {$b<=>$a} keys %{ $perWeek{created}{count} }) {
  my $time = $cur_time - ($weeks_back * $week_in_secs);
  my $convertedTime = &convertTime($time);
  my $newly_created = scalar@{ $perWeek{created}{count}{$weeks_back} };
  my $newly_changed = scalar@{ $perWeek{changed}{count}{$weeks_back} };
  $total += $newly_created;
  if ($weeks_back == 53) { 
    printf OUT "All time : \tCreated $newly_created\tChanged $newly_changed\tTotal $total\n", $weeks_back;
  } else {
    printf OUT "Week ending in $convertedTime (%03d weeks ago)\tCreated $newly_created\tChanged $newly_changed\tTotal $total\n", $weeks_back;
  } 
#   if ($weeks_back > 16) { 
#     foreach my $wbgene ( @{ $perWeek{created}{count}{$weeks_back} } ) {
#       print "WBGene $wbgene\n"; } }
} # foreach my $weeks_back (sort keys %{ $perWeek{created}{count} })

# print OUT "\n\n";
# 
# foreach my $weeks_back (reverse sort {$b<=>$a} keys %{ $perWeek{changed}{count} }) {
#   my $time = $cur_time - ($weeks_back * $week_in_secs);
#   my $convertedTime = &convertTime($time);
#   my $newly_changed = scalar@{ $perWeek{changed}{count}{$weeks_back} };
#   printf OUT "Week ending in $convertedTime (%03d weeks ago)\tChanged $newly_changed\n", $weeks_back;
# } # foreach my $weeks_back (sort {$a<=>$b} keys %{ $perWeek{changed}{count} })
  
close (OUT) or die "Cannot close $outfile : $!";

$/ = undef;
open(IN, "<$outfile") or die "Cannot open $outfile : $!";
my $body = <IN>;
close (IN) or die "Cannot close $outfile : $!";

my $user = 'azurebrd@ugcs.caltech.edu';
# my $email = 'azurebrd@minerva.caltech.edu';
# my $email = 'emsch@its.caltech.edu, bastiani@its.caltech.edu, vanauken@its.caltech.edu, pws@its.caltech.edu, sanger@wormbase.org';
# my $email = 'sanger@wormbase.org';
# my $email = 'emsch@its.caltech.edu, vanauken@its.caltech.edu, pws@its.caltech.edu';
my $email = 'vanauken@its.caltech.edu, pws@its.caltech.edu';	# removed erich  2010 06 23
# my $email = 'azurebrd@tazendra.caltech.edu';
my $subject = 'Automated Concise Description Stat output';

&mailer($user, $email, $subject, $body);

sub convertTime {
  my $time = shift;
  my ($day, $month, $year) = (localtime $time)[3,4,5];
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  $year += 1900;
  if ($day < 10) { $day = '0' . $day; }
  my $convertedTime = "$months[$month] $day $year";
  return $convertedTime;
} # sub convertTime


# foreach my $wbgene (sort keys %theHash) {
#   foreach my $timestamp (@{ $theHash{$wbgene}}) {
#     my ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
#     my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);
#     my $weeks_back = 0;
#     my $cur_minus_weeks = $cur_time;
#     while ($time < $cur_minus_weeks) {
#       $cur_minus_weeks -= $week_in_secs;
#       $weeks_back++;
#     }
#     $perWeek{$weeks_back}{existed}{$wbgene}++;
#   }
# #   print OUT "$wbgene $weeks_back $time $theHash{$wbgene}\n";
# } # foreach my $wbgene (sort keys %theHash)
# 
# foreach my $weeks (sort { $a <=> $b } keys %perWeek) {
#   print OUT "At week $weeks, there were $perWeek{$weeks} entries\n"; 
# } # foreach my $weeks (sort keys %perWeek)

