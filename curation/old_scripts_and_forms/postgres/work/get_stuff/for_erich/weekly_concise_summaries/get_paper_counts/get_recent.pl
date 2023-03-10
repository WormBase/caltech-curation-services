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
# Modified this to count all papers instead of genes.  2005 06 21

use strict;
use diagnostics;
use Pg;
use Time::Local;
use Jex;
use LWP::UserAgent;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "/home/postgres/work/get_stuff/for_erich/weekly_concise_summaries/get_paper_counts/outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

my %convertToWBPaper;

&readConvertions;

my %theHash;
my %perWeek;
my @pgtables = qw(car_con_ref1 car_con_ref_paper
car_exp1_ref1
car_exp2_ref1
car_exp3_ref1
car_exp4_ref1
car_exp5_ref1
car_exp6_ref1
car_gen1_ref1
car_gen2_ref1
car_gen3_ref1
car_gen4_ref1
car_gen5_ref1
car_gen6_ref1
car_ort1_ref1
car_ort2_ref1
car_ort3_ref1
car_ort4_ref1
car_ort5_ref1
car_ort6_ref1
car_oth1_ref1
car_oth2_ref1
car_oth3_ref1
car_oth4_ref1
car_oth5_ref1
car_oth6_ref1
car_phy1_ref1
car_phy2_ref1
car_phy3_ref1
car_phy4_ref1
car_phy5_ref1
car_phy6_ref1
);
foreach my $pgtable (@pgtables) {
  my $result = $conn->exec( "SELECT * FROM $pgtable WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp;" );	# only get wbgene values
  while (my @row = $result->fetchrow) {
    if ($row[1]) { 
      my @papers = split/, /, $row[1];
      foreach my $paper (@papers) {
        if ($paper =~ m/\s/) { $paper =~ s/\s//g; }
        if ($paper =~ m/,/) { $paper =~ s/,//g; }
        if ($paper =~ m/\.$/) { $paper =~ s/\.$//; }
        if ($convertToWBPaper{$paper}) {
          $paper = $convertToWBPaper{$paper};
          push @{ $theHash{key_gene}{$paper} }, $row[2]; 
          push @{ $theHash{key_time}{$row[2]} }, $paper; }
        elsif ($paper =~ m/WBPaper/) {
          push @{ $theHash{key_gene}{$paper} }, $row[2]; 
          push @{ $theHash{key_time}{$row[2]} }, $paper; }
        else { print "NO WBPaper convertion for $paper\n"; }
  } } }
} # foreach my $pgtable (@pgtables)

my @pgtables2 = qw(
car_seq_ref_paper
car_phe_ref_paper
car_oth_ref_paper
car_mol_ref_paper
car_fpa_ref_paper
car_fpi_ref_paper
car_exp_ref_paper
car_bio_ref_paper
);
foreach my $pgtable (@pgtables2) {
  my $result = $conn->exec( "SELECT * FROM $pgtable WHERE joinkey ~ 'WBGene' AND joinkey != 'WBGene00000000' ORDER BY car_timestamp;" );	# only get wbgene values
  while (my @row = $result->fetchrow) {
    if ($row[2]) { 
      my @papers = split/, /, $row[2];
      foreach my $paper (@papers) {
        if ($paper =~ m/\s/) { $paper =~ s/\s//g; }
        if ($paper =~ m/,/) { $paper =~ s/,//g; }
        if ($paper =~ m/\.$/) { $paper =~ s/\.$//; }
        if ($convertToWBPaper{$paper}) {
          $paper = $convertToWBPaper{$paper};
          push @{ $theHash{key_gene}{$paper} }, $row[3]; 
          push @{ $theHash{key_time}{$row[3]} }, $paper; }
        elsif ($paper =~ m/WBPaper/) {
          push @{ $theHash{key_gene}{$paper} }, $row[3]; 
          push @{ $theHash{key_time}{$row[3]} }, $paper; }
        else { print "NO WBPaper convertion for $paper\n"; }
  } } }
} # foreach my $pgtable (@pgtables)

my $cur_time = time;
my $week_in_secs = 86400*7;

foreach my $timestamp (sort keys %{ $theHash{key_time} }) {
  foreach my $wbpaper (@{ $theHash{key_time}{$timestamp}}) {
    my ($year, $month, $mday, $hours, $minutes, $seconds) = $timestamp =~ m/^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
    $month--;
    my $time = timelocal($seconds, $minutes, $hours, $mday, $month, $year);
    my $weeks_back = 0;
    my $cur_minus_weeks = $cur_time;
    while ($time < $cur_minus_weeks) {
      $cur_minus_weeks -= $week_in_secs;
      $weeks_back++; }

#     unless ($perWeek{changed}{$weeks_back}{$wbpaper}) {
#       $perWeek{changed}{$weeks_back}{$wbpaper}++;
#       push @{ $perWeek{changed}{count}{$weeks_back} }, $wbpaper; }

    unless ($perWeek{created}{paper}{$wbpaper}) { 
      $perWeek{created}{paper}{$wbpaper} = $weeks_back;
      push @{ $perWeek{created}{count}{$weeks_back} }, $wbpaper; }
  } # foreach my $timestamp (@{ $theHash{$wbpaper}})
} # foreach my $wbpaper (sort keys %{ $theHash{key_time} })

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

# foreach my $weeks_back (sort {$b<=>$a} keys %{ $perWeek{changed}{count} }) {
#   my $time = $cur_time - ($weeks_back * $week_in_secs);
#   my $convertedTime = &convertTime($time);
#   my $newly_changed = scalar@{ $perWeek{changed}{count}{$weeks_back} };
#   printf OUT "Week ending in $convertedTime (%03d weeks ago)\tChanged $newly_changed\n", $weeks_back;
# } # foreach my $weeks_back (sort {$a<=>$b} keys %{ $perWeek{changed}{count} })
  
close (OUT) or die "Cannot close $outfile : $!";

# $/ = undef;
# open(IN, "<$outfile") or die "Cannot open $outfile : $!";
# my $body = <IN>;
# close (IN) or die "Cannot close $outfile : $!";

# my $user = 'azurebrd@ugcs.caltech.edu';
# # my $email = 'azurebrd@minerva.caltech.edu';
# my $email = 'emsch@its.caltech.edu, bastiani@its.caltech.edu, vanauken@its.caltech.edu, pws@its.caltech.edu, sanger@wormbase.org';
# # my $email = 'sanger@wormbase.org';
# my $subject = 'Automated Concise Description Stat output';
# 
# &mailer($user, $email, $subject, $body);

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

sub readConvertions {
#   my $u = "http://tazendra.caltech.edu/~acedb/paper2wbpaper.txt";
  my $u = "http://tazendra.caltech.edu/~postgres/cgi-bin/wpa_xref_backwards.cgi";
  my $ua = LWP::UserAgent->new(timeout => 30); #instantiates a new user agent
  my $request = HTTP::Request->new(GET => $u); #grabs url
  my $response = $ua->request($request);       #checks url, dies if not valid.
  die "Error while getting ", $response->request->uri," -- ", $response->status_line, "\nAborting" unless $response-> is_success;
  my @tmp = split /\n/, $response->content;    #splits by line
  foreach (@tmp) {
    if ($_ =~m/^(.*?)\t(.*?)$/) {
      $convertToWBPaper{$1} = $2; } }
} # sub readConvertions

