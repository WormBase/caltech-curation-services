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
# Switched to look like allele-phenotype, i.e. 52 / 5 / 1 weeks ago only.  2009 07 06
#
#
# Updated for Anatomy Function curation stats.  Email Raymond, Paul. 
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/anatomy_function_stats/get_recent.pl
# 2007 05 24
#
# moved inside :
# 0 2 * * mon /home/postgres/work/get_stuff/for_paul/curation_stats/wrapper.sh
# 2009 04 23


use strict;
use diagnostics;
use Time::Local;
use Jex;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";




my $outfile = "/home/postgres/work/get_stuff/for_paul/curation_stats/anatomy_function_stats/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %theHash;
my %perWeek;
my $result = $dbh->prepare( "SELECT wbb_wbbtf, wbb_timestamp FROM wbb_wbbtf ORDER BY wbb_timestamp;" );	# only get wbgene values
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    push @{ $theHash{key_gene}{$row[0]} }, $row[1]; 
    
    push @{ $theHash{key_time}{$row[1]} }, $row[0]; }
}

my $cur_time = time;
my $week_in_secs = 86400*7;
my $week_ago = $cur_time - $week_in_secs;
my $fweek_ago = $cur_time - 5 * $week_in_secs;
my $year_ago = $cur_time - 52 * $week_in_secs;


foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
#   foreach my $wbgene (@{ $theHash{key_time}{$timestamp}}) { # }
  foreach my $pgdbid (@{ $theHash{key_time}{$timestamp}}) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);

# new 2009 07 06
    my $time_group = 0;
    if ($time < $year_ago) { $time_group = 52; }
    elsif ($time < $fweek_ago) { $time_group = 5; }
    else { $time_group = 1; }
    unless ($perWeek{created}{pgdbid}{exists}{$pgdbid}) {
      $perWeek{created}{pgdbid}{exists}{$pgdbid} = $time_group;
      push @{ $perWeek{created}{pgdbid}{tgroup}{$time_group} }, $pgdbid; }
    my $name = $pgdbid;
    unless ($perWeek{created}{name}{exists}{$name}) {
      $perWeek{created}{name}{exists}{$name} = $time_group;
      push @{ $perWeek{created}{name}{tgroup}{$time_group} }, $name; }
#     my $paper = $theHash{paper}{$pgdbid};
#     next unless $paper;
#     unless ($perWeek{created}{paper}{exists}{$paper}) {
#       $perWeek{created}{paper}{exists}{$paper} = $time_group;
#       push @{ $perWeek{created}{paper}{tgroup}{$time_group} }, $paper; }

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
undef $/;
my $cgi_file = '/home/postgres/public_html/cgi-bin/anatomy_function.cgi';
open (IN, "<$cgi_file") or die "Cannot open $cgi_file : $!";
my $all_cgi = <IN>; $/ = "\n";
close (IN) or die "Cannot close $cgi_file : $!";
my ($pgpar) = $all_cgi =~ m/my \@PGparameters = qw\( (.*?) \)/;
my @pgpar = split/\s+/, $pgpar;
foreach my $table (@pgpar) {
  $table = 'wbb_' . $table;
  $result = $dbh->prepare( "SELECT joinkey, wbb_timestamp FROM $table ORDER BY wbb_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { 
    next unless ($row[1]);
    if ($row[0]) { $theHash{key_time}{$row[1]}{$row[0]}++; } } }
  
foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
#   foreach my $wbgene (sort keys %{ $theHash{key_time}{$timestamp} }) { # }
  foreach my $pgdbid (sort keys %{ $theHash{key_time}{$timestamp} }) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = (0,0,0,0,0,0);
    if ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/) {
        ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/; }
      elsif ($timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/) { ($year, $month, $mday) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2})/; }
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);

# new
    my $time_group = 0;
    if ($time < $year_ago) { $time_group = 52; }
    elsif ($time < $fweek_ago) { $time_group = 5; }
    else { $time_group = 1; }
    unless ($perWeek{changed}{pgdbid}{exists}{$pgdbid}) {
      $perWeek{changed}{pgdbid}{exists}{$pgdbid} = $time_group;
      push @{ $perWeek{changed}{pgdbid}{tgroup}{$time_group} }, $pgdbid; }

# old
#     my $weeks_back = -1;		# loop will set to week zero, which is where we want it to start
#     my $cur_minus_weeks = $cur_time;
#     while ($time < $cur_minus_weeks) {
#       $cur_minus_weeks -= $week_in_secs;
#       $weeks_back++; }
#     unless ($perWeek{changed}{$weeks_back}{$wbgene}) {
#       $perWeek{changed}{$weeks_back}{$wbgene}++;
#       push @{ $perWeek{changed}{count}{$weeks_back} }, $wbgene; }
  } # foreach my $timestamp (@{ $theHash{$wbgene}})
} # foreach my $wbgene (sort keys %{ $theHash{key_time} })

my $total = 0; my @lines;
# foreach my $weeks_back (reverse sort {$b<=>$a} keys %{ $perWeek{created}{count} }) { # }
foreach my $weeks_back (sort {$b<=>$a} keys %{ $perWeek{created}{pgdbid}{tgroup} }) {
  my $time = $cur_time - ($weeks_back * $week_in_secs);
  my $convertedTime = &convertTime($time);
# new
  my $newly_created = scalar(@{ $perWeek{created}{pgdbid}{tgroup}{$weeks_back}} );
  my $newly_changed = scalar(@{ $perWeek{changed}{pgdbid}{tgroup}{$weeks_back}} );
  my $newly_name = scalar(@{ $perWeek{created}{name}{tgroup}{$weeks_back}} );
#   my $newly_paper = scalar(@{ $perWeek{created}{paper}{tgroup}{$weeks_back}} );
  $total += $newly_created;
  my $weeks =  sprintf("%02d", $weeks_back);
#   push @lines, "Week ending in $convertedTime ($weeks weeks ago)\tCreated $newly_created\t Changed $newly_changed\tnew variations $newly_name\tnew papers $newly_paper\t Total $total\n";
  push @lines, "Week ending in $convertedTime ($weeks weeks ago)\tCreated $newly_created\t Changed $newly_changed\tnew variations $newly_name\t Total $total\n";

# old
#   my $newly_created = scalar@{ $perWeek{created}{count}{$weeks_back} };
#   $total += $newly_created;
#   printf OUT "Week ending in $convertedTime (%03d weeks ago)\tCreated $newly_created\tTotal $total\n", $weeks_back;

#   if ($weeks_back > 16) { 
#     foreach my $wbgene ( @{ $perWeek{created}{count}{$weeks_back} } ) {
#       print "WBGene $wbgene\n"; } }
} # foreach my $weeks_back (sort keys %{ $perWeek{created}{count} })

# old
# print OUT "\n\n";
# 
# foreach my $weeks_back (reverse sort {$b<=>$a} keys %{ $perWeek{changed}{count} }) {
#   my $time = $cur_time - ($weeks_back * $week_in_secs);
#   my $convertedTime = &convertTime($time);
#   my $newly_changed = scalar@{ $perWeek{changed}{count}{$weeks_back} };
#   printf OUT "Week ending in $convertedTime (%03d weeks ago)\tChanged $newly_changed\n", $weeks_back;
# } # foreach my $weeks_back (sort {$a<=>$b} keys %{ $perWeek{changed}{count} })

# new
foreach my $line (reverse @lines) { print OUT $line; }
  
close (OUT) or die "Cannot close $outfile : $!";

$/ = undef;
open(IN, "<$outfile") or die "Cannot open $outfile : $!";
my $body = <IN>;
close (IN) or die "Cannot close $outfile : $!";

my $user = 'azurebrd@ugcs.caltech.edu';
# my $email = 'azurebrd@minerva.caltech.edu';
# my $email = 'emsch@its.caltech.edu, bastiani@its.caltech.edu, vanauken@its.caltech.edu, pws@its.caltech.edu, sanger@wormbase.org';
# my $email = 'sanger@wormbase.org';
my $email = 'raymond@its.caltech.edu, pws@its.caltech.edu';
my $subject = 'Automated Anatomy Function curation Stat output';

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

