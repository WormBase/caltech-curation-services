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
# Updated to 1 / 5 / 52 weeks ago.  Still a lot of redundant code from each week version.
# 2009 07 06
#
#
# Updated for WBPerson to Author curation stats.  Email Cecilia, Paul. 
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wbpaper_author_person_stats/get_recent.pl
# 2007 05 24
#
# Changed from wpa tables to pap tables, although pap tables not live yet.  2010 06 23
#
# 
# moved inside :
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wrapper.sh
# 2009 04 23


use strict;
use diagnostics;
use DBI;
use Time::Local;
use Jex;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my $outfile = "/home/postgres/work/get_stuff/for_paul/curation_stats/wbpaper_author_person_stats/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;
my %perWeek;
my %valid;
my $result = '';

# $result = $dbh->prepare( "SELECT wpa_author, wpa_valid, wpa_timestamp FROM wpa_author WHERE wpa_author IS NOT NULL ORDER BY wpa_timestamp;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   if ($row[1] eq 'valid') { 
#     $valid{$row[0]}++; } else { delete $valid{$row[1]}; } }

# $result = $dbh->prepare( "SELECT wpa_author, wpa_timestamp FROM wpa_author WHERE wpa_author IS NOT NULL ORDER BY wpa_timestamp;" );
# $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
# while (my @row = $result->fetchrow) {
#   next unless $valid{$row[0]};
#   push @{ $theHash{key_gene}{$row[0]} }, $row[1]; 
#   push @{ $theHash{key_time}{$row[1]} }, $row[0]; }

$result = $dbh->prepare( "SELECT pap_author, pap_timestamp FROM pap_author ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  push @{ $theHash{key_gene}{$row[0]} }, $row[1]; 
  push @{ $theHash{key_time}{$row[1]} }, $row[0]; }

my $cur_time = time;
my $week_in_secs = 86400*7;
my $week_ago = $cur_time - $week_in_secs;
my $fweek_ago = $cur_time - 5 * $week_in_secs;
my $year_ago = $cur_time - 52 * $week_in_secs;

foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbgene (@{ $theHash{key_time}{$timestamp}}) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);

    my $time_group = 0;
    if ($time < $year_ago) { $time_group = 52; }
    elsif ($time < $fweek_ago) { $time_group = 5; }
    else { $time_group = 1; }
    unless ($perWeek{created}{gene}{$wbgene}) { 
      $perWeek{created}{gene}{$wbgene} = $time_group;
      push @{ $perWeek{created}{count}{$time_group} }, $wbgene; }

# old
#     my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
#     my $cur_minus_weeks = $cur_time;
#     while ($time < $cur_minus_weeks) {
#       $cur_minus_weeks -= $week_in_secs;
#       $weeks_back++; }
#     unless ($perWeek{created}{gene}{$wbgene}) { 
#       $perWeek{created}{gene}{$wbgene} = $weeks_back;
#       push @{ $perWeek{created}{count}{$weeks_back} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

%theHash = ();
# $result = $dbh->prepare( "SELECT author_id, wpa_author_possible, wpa_timestamp FROM wpa_author_possible WHERE wpa_author_possible ~ 'two' ORDER BY wpa_timestamp;" );
$result = $dbh->prepare( "SELECT author_id, pap_author_possible, pap_timestamp FROM pap_author_possible WHERE pap_author_possible ~ 'two' ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
#   next unless $valid{$row[0]};
  push @{ $theHash{key_gene}{$row[0]} }, $row[2]; 
  push @{ $theHash{key_time}{$row[2]} }, $row[0]; }
  
foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbgene (@{ $theHash{key_time}{$timestamp} }) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = (0,0,0,0,0,0);
    if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/; }
      elsif ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { ($year, $month, $mday) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/; }
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);

    my $time_group = 0;
    if ($time < $year_ago) { $time_group = 52; }
    elsif ($time < $fweek_ago) { $time_group = 5; }
    else { $time_group = 1; }
    unless ($perWeek{connected}{$time_group}{$wbgene}) { 
      $perWeek{connected}{$time_group}{$wbgene}++;
      push @{ $perWeek{connected}{count}{$time_group} }, $wbgene; }

# old
#     my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
#     my $cur_minus_weeks = $cur_time;
#     while ($time < $cur_minus_weeks) {
#       $cur_minus_weeks -= $week_in_secs;
#       $weeks_back++; }
#     unless ($perWeek{connected}{$weeks_back}{$wbgene}) {
#       $perWeek{connected}{$weeks_back}{$wbgene}++;
#       push @{ $perWeek{connected}{count}{$weeks_back} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

%theHash = ();
# $result = $dbh->prepare( "SELECT author_id, wpa_author_verified, wpa_timestamp FROM wpa_author_verified WHERE wpa_author_verified ~ 'YES' ORDER BY wpa_timestamp;" );
$result = $dbh->prepare( "SELECT author_id, pap_author_verified, pap_timestamp FROM pap_author_verified WHERE pap_author_verified ~ 'YES' ORDER BY pap_timestamp;" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
#   next unless $valid{$row[0]};
  push @{ $theHash{key_gene}{$row[0]} }, $row[2]; 
  push @{ $theHash{key_time}{$row[2]} }, $row[0]; }
  
foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbgene (@{ $theHash{key_time}{$timestamp} }) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = (0,0,0,0,0,0);
    if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/; }
      elsif ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { ($year, $month, $mday) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/; }
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);

    my $time_group = 0;
    if ($time < $year_ago) { $time_group = 52; }
    elsif ($time < $fweek_ago) { $time_group = 5; }
    else { $time_group = 1; }
    unless ($perWeek{verified}{$time_group}{$wbgene}) {
      $perWeek{verified}{$time_group}{$wbgene}++;
      push @{ $perWeek{verified}{count}{$time_group} }, $wbgene; }

#     my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
#     my $cur_minus_weeks = $cur_time;
#     while ($time < $cur_minus_weeks) {
#       $cur_minus_weeks -= $week_in_secs;
#       $weeks_back++; }
#     unless ($perWeek{verified}{$weeks_back}{$wbgene}) {
#       $perWeek{verified}{$weeks_back}{$wbgene}++;
#       push @{ $perWeek{verified}{count}{$weeks_back} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

my $total = 0;


my $highest = 0;
# foreach my $weeks_back (sort {$b<=>$a} keys %{ $perWeek{created}{count} }) {
#   if ($weeks_back > $highest) { $highest = $weeks_back; } }

foreach my $weeks_back (reverse sort {$b<=>$a} keys %{ $perWeek{created}{count} }) {
# for my $weeks_back ( 0 .. $highest ) { # }
# for my $weeks_back ( reverse ( 0 .. $highest ) ) { # } # recent last
#   print "WB $weeks_back WB\n";
  my $time = $cur_time - ($weeks_back * $week_in_secs);
  my $convertedTime = &convertTime($time);
  my $newly_created = 0;
  if ( $perWeek{created}{count}{$weeks_back}) { $newly_created = scalar@{ $perWeek{created}{count}{$weeks_back} }; }
#   print "NEWLY $newly_created CREATED\n";
  $total += $newly_created;
  my $connected = 0;
  if ($perWeek{connected}{count}{$weeks_back}) { $connected = scalar@{ $perWeek{connected}{count}{$weeks_back} }; }
  my $verified = 0;
  if ($perWeek{verified}{count}{$weeks_back}) { $verified = scalar@{ $perWeek{verified}{count}{$weeks_back} }; }
  printf OUT "Week ending in $convertedTime (%03d weeks ago)\tCreated $newly_created\tTotal $total \tConnected $connected\tVerified YES $verified\n", $weeks_back;
#   if ($weeks_back > 16) { 
#     foreach my $wbgene ( @{ $perWeek{created}{count}{$weeks_back} } ) {
#       print "WBGene $wbgene\n"; } }
} # for my $weeks_back ( $highest .. 0 )

# print OUT "\n\n";
# 
# foreach my $weeks_back (sort {$b<=>$a} keys %{ $perWeek{changed}{count} }) {
#   my $time = $cur_time - ($weeks_back * $week_in_secs);
#   my $convertedTime = &convertTime($time);
#   my $newly_changed = scalar@{ $perWeek{changed}{count}{$weeks_back} };
#   my $created = 0;
#   if ($perWeek{created}{count}{$weeks_back}) { $created = scalar@{ $perWeek{created}{count}{$weeks_back} }; }
#   my $only_changed = $newly_changed - $created; 
#   printf OUT "Week ending in $convertedTime (%03d weeks ago)\tChanged $newly_changed ($only_changed)\n", $weeks_back;
# } # foreach my $weeks_back (sort {$a<=>$b} keys %{ $perWeek{changed}{count} })
  
close (OUT) or die "Cannot close $outfile : $!";

$/ = undef;
open(IN, "<$outfile") or die "Cannot open $outfile : $!";
my $body = <IN>;
close (IN) or die "Cannot close $outfile : $!";

my $user = 'azurebrd@ugcs.caltech.edu';
# my $email = 'azurebrd@tazendra.caltech.edu';
# my $email = 'emsch@its.caltech.edu, bastiani@its.caltech.edu, vanauken@its.caltech.edu, pws@its.caltech.edu, sanger@wormbase.org';
# my $email = 'sanger@wormbase.org';
my $email = 'cecilia@tazendra.caltech.edu, pws@its.caltech.edu';
my $subject = 'Automated WBPerson to Author Stat output';

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

