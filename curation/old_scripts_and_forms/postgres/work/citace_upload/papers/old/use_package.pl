#!/usr/bin/perl

# use the get_paper_ace.pm module from /home/postgres/work/citace_upload/papers/ 
# to dump the papers, abstracts (LongText objects), and errors associated with
# them.  2005 07 13
#
# Change to default get all papers, not just valid ones.  2005 11 10
#
# Change to default get only valid papers to -D merged papers from citace.  
# For Andrei.  2006 05 24
#
# Setting cronjob to dump every week, but only create data on 20something or 
# 30something (upload always near end of month)    2009 01 22
#
# # 0 2 * * fri /home/postgres/work/citace_upload/papers/use_package.pl
# inside 
# 0 2 * * thu /home/postgres/work/citace_upload/wrapper.sh




use strict;
use Jex;

my $date = &getSimpleSecDate();
my $start_time = time;
my $estimate_time = time + 197;
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($estimate_time);             # get time
if ($sec < 10) { $sec = "0$sec"; }    # add a zero if needed
if ($min < 10) { $min = "0$min"; }    # add a zero if needed
# print "START $date -> Estimate $hour:$min:$sec\n";

$date = &getSimpleDate();

my $directory = '/home/postgres/work/citace_upload/papers';
chdir ($directory) or die "Cannot chdir to $directory : $!";

use lib qw( /home/postgres/work/citace_upload/papers/ );
use get_paper_ace;

if ($mday =~ m/^[23]\d/) {			# only do stuff on 20/30 something for uploads

  my $outfile = $directory . '/out/papers.ace.' . $date;
  my $outlong = $directory . '/out/abstracts.ace.' . $date;
  my $errfile = $directory . '/out/err.out.' . $date;
  open (OUT, ">$outfile") or die "Cannot create $outfile : $!\n";
  open (LON, ">$outlong") or die "Cannot create $outlong : $!\n";
  open (ERR, ">$errfile") or die "Cannot create $errfile : $!\n";
  
  
  # my ($all_entry, $long_text, $err_text) = &getPaper('00031342');
  my ($all_entry, $long_text, $err_text) = &getPaper('valid');
  # my ($all_entry, $long_text, $err_text) = &getPaper('all');
  
  print OUT "$all_entry\n";
  print LON "$long_text\n";
  print ERR "$err_text\n";
  
  close (OUT) or die "Cannot close $outfile : $!";
  close (LON) or die "Cannot close $outlong : $!";
  close (ERR) or die "Cannot close $errfile : $!";
  
  $date = &getSimpleSecDate();
  my $end_time = time;
  my $diff_time = $end_time - $start_time;
  # print "DIFF $diff_time\n";
  # print "END $date\n";

  my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/papers.ace';
  unlink ("$location_of_latest") or warn "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
  symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";
  $location_of_latest = '/home/postgres/public_html/cgi-bin/data/abstracts.ace';
  unlink ("$location_of_latest") or warn "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
  symlink("$outlong", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";


}
