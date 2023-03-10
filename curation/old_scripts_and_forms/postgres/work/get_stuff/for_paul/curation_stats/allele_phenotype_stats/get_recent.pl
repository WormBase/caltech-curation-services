#!/usr/bin/perl -w

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
# Added Jolene and Karen, for Gary.  2007 09 05
#
#
#
# Updated for Allele Phenotype curation stats.  Email Gary, Paul. 
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/allele_phenotype_stats/get_recent.pl
# 2007 05 24
# 
# moved inside :
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wrapper.sh
# 2009 04 23


use strict;
use diagnostics;
use Pg;
use Time::Local;
use Jex;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_paul/curation_stats/allele_phenotype_stats/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;
my %perWeek;
my $result = $conn->exec( "SELECT * FROM alp_tempname  ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    push @{ $theHash{key_gene}{$row[0]} }, $row[2]; 
    push @{ $theHash{key_time}{$row[2]} }, $row[0]; }
}

my $cur_time = time;
my $week_in_secs = 86400*7;

foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbgene (@{ $theHash{key_time}{$timestamp}}) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);
    my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
    my $cur_minus_weeks = $cur_time;
    while ($time < $cur_minus_weeks) {
      $cur_minus_weeks -= $week_in_secs;
      $weeks_back++; }
    unless ($perWeek{created}{gene}{$wbgene}) { 
      $perWeek{created}{gene}{$wbgene} = $weeks_back;
      push @{ $perWeek{created}{count}{$weeks_back} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

%theHash = ();
$result = $conn->exec( "SELECT * FROM alp_term ORDER BY alp_timestamp;" );
while (my @row = $result->fetchrow) { 
  next unless ($row[4]);
  if ($row[0]) { $theHash{key_time}{$row[4]}{$row[0]}++; } }

foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbgene (sort keys %{ $theHash{key_time}{$timestamp} }) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = (0,0,0,0,0,0);
    if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/; }
      elsif ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { ($year, $month, $mday) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/; }
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);
    my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
    my $cur_minus_weeks = $cur_time;
    while ($time < $cur_minus_weeks) {
      $cur_minus_weeks -= $week_in_secs;
      $weeks_back++; }
    unless ($perWeek{changed}{$weeks_back}{$wbgene}) {
      $perWeek{changed}{$weeks_back}{$wbgene}++;
      push @{ $perWeek{changed}{count}{$weeks_back} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

my $total = 0;
foreach my $weeks_back (sort {$b<=>$a} keys %{ $perWeek{created}{count} }) {
  my $time = $cur_time - ($weeks_back * $week_in_secs);
  my $convertedTime = &convertTime($time);
  my $newly_created = scalar@{ $perWeek{created}{count}{$weeks_back} };
  $total += $newly_created;
  printf OUT "Week ending in $convertedTime (%03d weeks ago)\tCreated $newly_created\tTotal $total\n", $weeks_back;
#   if ($weeks_back > 16) { 
#     foreach my $wbgene ( @{ $perWeek{created}{count}{$weeks_back} } ) {
#       print "WBGene $wbgene\n"; } }
} # foreach my $weeks_back (sort keys %{ $perWeek{created}{count} })

print OUT "\n\n";

foreach my $weeks_back (sort {$b<=>$a} keys %{ $perWeek{changed}{count} }) {
  my $time = $cur_time - ($weeks_back * $week_in_secs);
  my $convertedTime = &convertTime($time);
  my $newly_changed = scalar@{ $perWeek{changed}{count}{$weeks_back} };
  printf OUT "Week ending in $convertedTime (%03d weeks ago)\tChanged $newly_changed\n", $weeks_back;
} # foreach my $weeks_back (sort {$a<=>$b} keys %{ $perWeek{changed}{count} })
  
close (OUT) or die "Cannot close $outfile : $!";

$/ = undef;
open(IN, "<$outfile") or die "Cannot open $outfile : $!";
my $body = <IN>;
close (IN) or die "Cannot close $outfile : $!";

my $user = 'azurebrd@ugcs.caltech.edu';
# my $email = 'azurebrd@minerva.caltech.edu';
# my $email = 'emsch@its.caltech.edu, bastiani@its.caltech.edu, vanauken@its.caltech.edu, pws@its.caltech.edu, sanger@wormbase.org';
# my $email = 'sanger@wormbase.org';
# my $email = 'garys@its.caltech.edu, pws@its.caltech.edu';
my $email = 'garys@its.caltech.edu, pws@its.caltech.edu, kyook@its.caltech.edu, jolenef@its.caltech.edu';
my $subject = 'Automated Allele-Phenotype curation Stat output';

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

